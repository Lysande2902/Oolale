-- ============================================
-- MIGRATION: Complete Systems (Profiles, Messaging, Events)
-- SAFE VERSION - Handles existing objects gracefully
-- Purpose: Add missing columns and tables for 100% completion
-- ============================================

-- ============================================
-- 1. PROFILES SYSTEM - Add missing columns
-- ============================================

-- Add years of experience
DO $$ 
BEGIN
  IF NOT EXISTS (
    SELECT 1 FROM information_schema.columns 
    WHERE table_name = 'profiles' AND column_name = 'years_experience'
  ) THEN
    ALTER TABLE profiles ADD COLUMN years_experience INTEGER DEFAULT 0;
  END IF;
END $$;

-- Add base rate and currency
DO $$ 
BEGIN
  IF NOT EXISTS (
    SELECT 1 FROM information_schema.columns 
    WHERE table_name = 'profiles' AND column_name = 'base_rate'
  ) THEN
    ALTER TABLE profiles ADD COLUMN base_rate DECIMAL(10,2) DEFAULT 0.0;
  END IF;
END $$;

DO $$ 
BEGIN
  IF NOT EXISTS (
    SELECT 1 FROM information_schema.columns 
    WHERE table_name = 'profiles' AND column_name = 'currency'
  ) THEN
    ALTER TABLE profiles ADD COLUMN currency VARCHAR(3) DEFAULT 'MXN';
  END IF;
END $$;

-- Add availability (JSON object with days of week)
DO $$ 
BEGIN
  IF NOT EXISTS (
    SELECT 1 FROM information_schema.columns 
    WHERE table_name = 'profiles' AND column_name = 'availability'
  ) THEN
    ALTER TABLE profiles ADD COLUMN availability JSONB DEFAULT '{}'::jsonb;
  END IF;
END $$;

-- Add social links (JSON object with platform URLs)
DO $$ 
BEGIN
  IF NOT EXISTS (
    SELECT 1 FROM information_schema.columns 
    WHERE table_name = 'profiles' AND column_name = 'social_links'
  ) THEN
    ALTER TABLE profiles ADD COLUMN social_links JSONB DEFAULT '{}'::jsonb;
  END IF;
END $$;

-- Add profile completion percentage
DO $$ 
BEGIN
  IF NOT EXISTS (
    SELECT 1 FROM information_schema.columns 
    WHERE table_name = 'profiles' AND column_name = 'profile_completion'
  ) THEN
    ALTER TABLE profiles ADD COLUMN profile_completion INTEGER DEFAULT 0;
  END IF;
END $$;

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
DO $$ 
BEGIN
  IF NOT EXISTS (
    SELECT 1 FROM information_schema.columns 
    WHERE table_name = 'intercom' AND column_name = 'read_at'
  ) THEN
    ALTER TABLE intercom ADD COLUMN read_at TIMESTAMP;
  END IF;
END $$;

-- Add delivered_at timestamp for messages
DO $$ 
BEGIN
  IF NOT EXISTS (
    SELECT 1 FROM information_schema.columns 
    WHERE table_name = 'intercom' AND column_name = 'delivered_at'
  ) THEN
    ALTER TABLE intercom ADD COLUMN delivered_at TIMESTAMP;
  END IF;
END $$;

-- Add media support
DO $$ 
BEGIN
  IF NOT EXISTS (
    SELECT 1 FROM information_schema.columns 
    WHERE table_name = 'intercom' AND column_name = 'media_url'
  ) THEN
    ALTER TABLE intercom ADD COLUMN media_url TEXT;
  END IF;
END $$;

DO $$ 
BEGIN
  IF NOT EXISTS (
    SELECT 1 FROM information_schema.columns 
    WHERE table_name = 'intercom' AND column_name = 'media_type'
  ) THEN
    ALTER TABLE intercom ADD COLUMN media_type VARCHAR(20);
  END IF;
END $$;

-- Create index for faster unread message queries
CREATE INDEX IF NOT EXISTS idx_intercom_unread 
ON intercom(destinatario_id, leido) 
WHERE leido = false;

-- ============================================
-- 3. EVENTS SYSTEM - Add invitations and lineup
-- ============================================

-- Add lineup array to gigs table (list of participant UUIDs)
DO $$ 
BEGIN
  IF NOT EXISTS (
    SELECT 1 FROM information_schema.columns 
    WHERE table_name = 'gigs' AND column_name = 'lineup'
  ) THEN
    ALTER TABLE gigs ADD COLUMN lineup UUID[] DEFAULT ARRAY[]::UUID[];
  END IF;
END $$;

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
-- 4. HELPER FUNCTIONS
-- ============================================

-- Drop and recreate function to calculate profile completion percentage
DROP FUNCTION IF EXISTS calculate_profile_completion(UUID);

CREATE FUNCTION calculate_profile_completion(user_id UUID)
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
  IF EXISTS (SELECT 1 FROM portfolio_media WHERE profile_id = user_id) THEN
    completed_fields := completed_fields + 1;
  END IF;
  
  completion := (completed_fields * 100) / total_fields;
  
  RETURN completion;
END;
$$ LANGUAGE plpgsql;

-- Drop and recreate trigger function
DROP FUNCTION IF EXISTS update_profile_completion() CASCADE;

CREATE FUNCTION update_profile_completion()
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
-- 5. PERMISSIONS (Supabase RLS)
-- ============================================

-- Enable RLS on new tables
ALTER TABLE profile_genres ENABLE ROW LEVEL SECURITY;
ALTER TABLE event_invitations ENABLE ROW LEVEL SECURITY;

-- Drop existing policies if they exist
DROP POLICY IF EXISTS "Users can view all genres" ON profile_genres;
DROP POLICY IF EXISTS "Users can manage their own genres" ON profile_genres;
DROP POLICY IF EXISTS "Users can view their invitations" ON event_invitations;
DROP POLICY IF EXISTS "Organizers can create invitations" ON event_invitations;
DROP POLICY IF EXISTS "Musicians can update their invitations" ON event_invitations;

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

-- Success message
DO $$
BEGIN
  RAISE NOTICE '✅ Migration completed successfully!';
  RAISE NOTICE '📊 New columns added to profiles table';
  RAISE NOTICE '📊 New tables created: profile_genres, event_invitations';
  RAISE NOTICE '📊 Functions and triggers created';
  RAISE NOTICE '🔒 RLS policies configured';
END $$;
