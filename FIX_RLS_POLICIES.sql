-- ============================================
-- FIX RLS POLICIES FOR usuarios_bloqueados AND referencias
-- ============================================

-- ============================================
-- 1. FIX usuarios_bloqueados TABLE POLICIES
-- ============================================

-- Drop existing policies
DROP POLICY IF EXISTS "Users can view their blocks" ON usuarios_bloqueados;
DROP POLICY IF EXISTS "Users can create blocks" ON usuarios_bloqueados;
DROP POLICY IF EXISTS "Users can update their blocks" ON usuarios_bloqueados;
DROP POLICY IF EXISTS "Users can delete their blocks" ON usuarios_bloqueados;

-- Create new policies
CREATE POLICY "Users can view their blocks"
  ON usuarios_bloqueados FOR SELECT
  USING (usuario_id = auth.uid() OR bloqueado_id = auth.uid());

CREATE POLICY "Users can create blocks"
  ON usuarios_bloqueados FOR INSERT
  WITH CHECK (usuario_id = auth.uid());

CREATE POLICY "Users can update their blocks"
  ON usuarios_bloqueados FOR UPDATE
  USING (usuario_id = auth.uid());

CREATE POLICY "Users can delete their blocks"
  ON usuarios_bloqueados FOR DELETE
  USING (usuario_id = auth.uid());

-- ============================================
-- 2. FIX referencias TABLE POLICIES
-- ============================================

-- Drop existing policies
DROP POLICY IF EXISTS "Users can view all referencias" ON referencias;
DROP POLICY IF EXISTS "Users can view referencias" ON referencias;
DROP POLICY IF EXISTS "Users can create referencias" ON referencias;
DROP POLICY IF EXISTS "Users can update their referencias" ON referencias;
DROP POLICY IF EXISTS "Users can delete their referencias" ON referencias;

-- Create new policies
CREATE POLICY "Users can view all referencias"
  ON referencias FOR SELECT
  USING (true);

CREATE POLICY "Users can create referencias"
  ON referencias FOR INSERT
  WITH CHECK (evaluador_id = auth.uid());

CREATE POLICY "Users can update their referencias"
  ON referencias FOR UPDATE
  USING (evaluador_id = auth.uid());

CREATE POLICY "Users can delete their referencias"
  ON referencias FOR DELETE
  USING (evaluador_id = auth.uid());

-- ============================================
-- VERIFICATION
-- ============================================

-- Verify policies for usuarios_bloqueados
SELECT 
  schemaname,
  tablename,
  policyname,
  permissive,
  roles,
  cmd,
  qual,
  with_check
FROM pg_policies
WHERE tablename = 'usuarios_bloqueados'
ORDER BY policyname;

-- Verify policies for referencias
SELECT 
  schemaname,
  tablename,
  policyname,
  permissive,
  roles,
  cmd,
  qual,
  with_check
FROM pg_policies
WHERE tablename = 'referencias'
ORDER BY policyname;

-- Success message
DO $$
BEGIN
  RAISE NOTICE '✅ RLS Policies fixed successfully!';
  RAISE NOTICE '📊 usuarios_bloqueados: Users can now block/unblock';
  RAISE NOTICE '📊 referencias: Users can now leave ratings';
END $$;
