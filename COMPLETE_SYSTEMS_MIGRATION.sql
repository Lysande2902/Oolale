-- ============================================
-- MIGRATION: Complete Systems (Profiles, Messaging, Events)
-- Purpose: Add missing columns and tables for 100% completion
-- ============================================

-- ============================================
-- 1. PROFILES SYSTEM - Add missing columns
-- ============================================

-- Add years of experience
ALTER TABLE profiles 
ADD COLUMN IF NOT EXISTS years_experience INTEGER DEFAULT 0;

-- Add base rate and currency
ALTER TABLE profiles 
ADD COLUMN IF NOT EXISTS base_rate DECIMAL(10,2) DEFAULT 0.0;

ALTER TABLE profiles 
ADD COLUMN IF NOT EXISTS currency VARCHAR(3) DEFAULT 'MXN';

-- Add availability (JSON object with days of week)
ALTER TABLE profiles 
ADD COLUMN IF NOT EXISTS availability JSONB DEFAULT '{}'::jsonb;

-- Add social links (JSON object with platform URLs)
ALTER TABLE profiles 
ADD COLUMN IF NOT EXISTS social_links JSONB DEFAULT '{}'::jsonb;

-- Add profile completion percentage
ALTER TABLE profiles 
ADD COLUMN IF NOT EXISTS profile_completion INTEGER DEFAULT 0;

-- Create profile_genres table for many-to-many relationship
CREATE TABLE IF NOT EXISTS profile_genres (
  id SERIAL PRIMARY KEY,
  profile_id UUID NOT NULL REFERENCES profiles(id) ON DELETE CASCADE,
  genre VARCHAR(50) NOT NULL,
  created_at TIMESTAMP DEFAULT NOW(),
  UNIQUE(profile_id, genre)
);

-- Create index for faster queries
CREATE INDEX IF NOT EXISTS idx_profile_genres_profile_id ON profile_genres(profile_id);

-- ============================================
-- 2. MESSAGING SYSTEM - Add read receipts
-- ============================================

-- Add read_at timestamp for messages
ALTER TABLE intercom 
ADD COLUMN IF NOT EXISTS read_at TIMESTAMP;

-- Add delivered_at timestamp for messages
ALTER TABLE intercom 
ADD COLUMN IF NOT EXISTS delivered_at TIMESTAMP;

-- Add media support
ALTER TABLE intercom 
ADD COLUMN IF NOT EXISTS media_url TEXT;

ALTER TABLE intercom 
ADD COLUMN IF NOT EXISTS media_type VARCHAR(20);

-- Create index for faster unread message queries
CREATE INDEX IF NOT EXISTS idx_intercom_unread 
ON intercom(destinatario_id, leido) 
WHERE leido = false;

-- ============================================
-- 3. EVENTS SYSTEM - Add invitations and lineup
-- ============================================

-- Add lineup array to gigs table (list of participant UUIDs)
ALTER TABLE gigs 
ADD COLUMN IF NOT EXISTS lineup UUID[] DEFAULT ARRAY[]::UUID[];

-- Create event_invitations table
CREATE TABLE IF NOT EXISTS event_invitations (
  id SERIAL PRIMARY KEY,
  event_id INTEGER NOT NULL REFERENCES gigs(id) ON DELETE CASCADE,
  musician_id UUID NOT NULL REFERENCES profiles(id) ON DELETE CASCADE,
  organizer_id UUID NOT NULL REFERENCES profiles(id) ON DELETE CASCADE,
  status VARCHAR(20) DEFAULT 'pending' CHECK (status IN ('pending', 'accepted', 'declined')),
  created_at TIMESTAMP DEFAULT NOW(),
  updated_at TIMESTAMP DEFAULT NOW(),
  UNIQUE(event_id, musician_id)
);

-- Create indexes for event invitations
CREATE INDEX IF NOT EXISTS idx_event_invitations_musician 
ON event_invitations(musician_id, status);

CREATE INDEX IF NOT EXISTS idx_event_invitations_event 
ON event_invitations(event_id);

-- ============================================
-- 4. NOTIFICATIONS - Add event-related types
-- ============================================

-- Notifications table should already exist, but ensure it supports new types
-- Types: 'event_invitation', 'invitation_response', 'event_reminder'

-- ============================================
-- 5. HELPER FUNCTIONS
-- ============================================

-- Drop existing function if it exists
DROP FUNCTION IF EXISTS calculate_profile_completion(UUID);

-- Function to calculate profile completion percentage
CREATE OR REPLACE FUNCTION calculate_profile_completion(user_id UUID)
RETURNS INTEGER AS $$
DECLARE
  completion INTEGER := 0;
  total_fields INTEGER := 11;
  completed_fields INTEGER := 0;
BEGIN
  -- Check required fields
  SELECT 
    CASE WHEN nombre_artistico IS NOT NULL AND nombre_artistico != '' THEN 1 ELSE 0 END +
    CASE WHEN foto_perfil IS NOT NULL AND foto_perfil != '' THEN 1 ELSE 0 END +
    CASE WHEN bio IS NOT NULL AND bio != '' THEN 1 ELSE 0 END +
    CASE WHEN instrumento_principal IS NOT NULL AND instrumento_principal != '' THEN 1 ELSE 0 END +
    CASE WHEN ubicacion IS NOT NULL AND ubicacion != '' THEN 1 ELSE 0 END +
    CASE WHEN years_experience > 0 THEN 1 ELSE 0 END +
    CASE WHEN availability IS NOT NULL AND availability::text != '{}'::text THEN 1 ELSE 0 END +
    CASE WHEN base_rate > 0 THEN 1 ELSE 0 END +
    CASE WHEN social_links IS NOT NULL AND social_links::text != '{}'::text THEN 1 ELSE 0 END
  INTO completed_fields
  FROM profiles
  WHERE id = user_id;
  
  -- Check if has genres
  IF EXISTS (SELECT 1 FROM profile_genres WHERE profile_id = user_id) THEN
    completed_fields := completed_fields + 1;
  END IF;
  
  -- Check if has portfolio items
  IF EXISTS (SELECT 1 FROM portfolio WHERE perfil_id = user_id) THEN
    completed_fields := completed_fields + 1;
  END IF;
  
  completion := (completed_fields * 100) / total_fields;
  
  RETURN completion;
END;
$$ LANGUAGE plpgsql;

-- Drop existing trigger function if it exists
DROP FUNCTION IF EXISTS update_profile_completion() CASCADE;

-- Function to update profile completion automatically
CREATE OR REPLACE FUNCTION update_profile_completion()
RETURNS TRIGGER AS $$
BEGIN
  NEW.profile_completion := calculate_profile_completion(NEW.id);
  RETURN NEW;
END;
$$ LANGUAGE plpgsql;

-- Create trigger to auto-update profile completion
DROP TRIGGER IF EXISTS trigger_update_profile_completion ON profiles;
CREATE TRIGGER trigger_update_profile_completion
  BEFORE UPDATE ON profiles
  FOR EACH ROW
  EXECUTE FUNCTION update_profile_completion();

-- ============================================
-- 6. SAMPLE DATA (Optional - for testing)
-- ============================================

-- Add some sample genres
INSERT INTO profile_genres (profile_id, genre)
SELECT id, 'Rock' FROM profiles LIMIT 1
ON CONFLICT (profile_id, genre) DO NOTHING;

-- ============================================
-- 7. PERMISSIONS (Supabase RLS)
-- ============================================

-- Enable RLS on new tables
ALTER TABLE profile_genres ENABLE ROW LEVEL SECURITY;
ALTER TABLE event_invitations ENABLE ROW LEVEL SECURITY;

-- Profile genres policies
CREATE POLICY "Users can view all genres"
  ON profile_genres FOR SELECT
  USING (true);

CREATE POLICY "Users can manage their own genres"
  ON profile_genres FOR ALL
  USING (profile_id = auth.uid());

-- Event invitations policies
CREATE POLICY "Users can view their invitations"
  ON event_invitations FOR SELECT
  USING (musician_id = auth.uid() OR organizer_id = auth.uid());

CREATE POLICY "Organizers can create invitations"
  ON event_invitations FOR INSERT
  WITH CHECK (organizer_id = auth.uid());

CREATE POLICY "Musicians can update their invitations"
  ON event_invitations FOR UPDATE
  USING (musician_id = auth.uid());

-- ============================================
-- MIGRATION COMPLETE
-- ============================================

-- Verify migration
SELECT 
  'profiles' as table_name,
  COUNT(*) as total_records,
  COUNT(CASE WHEN years_experience > 0 THEN 1 END) as with_experience,
  COUNT(CASE WHEN base_rate > 0 THEN 1 END) as with_rate
FROM profiles
UNION ALL
SELECT 
  'profile_genres' as table_name,
  COUNT(*) as total_records,
  COUNT(DISTINCT profile_id) as unique_profiles,
  NULL
FROM profile_genres
UNION ALL
SELECT 
  'event_invitations' as table_name,
  COUNT(*) as total_records,
  COUNT(CASE WHEN status = 'pending' THEN 1 END) as pending,
  COUNT(CASE WHEN status = 'accepted' THEN 1 END) as accepted
FROM event_invitations;
