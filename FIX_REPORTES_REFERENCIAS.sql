-- ============================================
-- FIX: Reportes y Referencias - Columnas Faltantes
-- ============================================

-- ============================================
-- 1. FIX TABLA reportes - Agregar columna 'estatus'
-- ============================================

-- Agregar columna estatus si no existe
ALTER TABLE reportes 
ADD COLUMN IF NOT EXISTS estatus VARCHAR(20) DEFAULT 'pendiente' 
CHECK (estatus IN ('pendiente', 'en_revision', 'resuelto', 'rechazado'));

-- ============================================
-- 2. FIX TABLA referencias - Eliminar constraint NOT NULL de columnas viejas
-- ============================================

-- PROBLEMA: La tabla tiene columnas viejas (de_usuario_id, para_usuario_id) con NOT NULL
-- SOLUCIÓN: Hacer estas columnas NULLABLE o eliminarlas

DO $$ 
BEGIN
  -- Verificar si existe 'de_usuario_id' (columna vieja)
  IF EXISTS (
    SELECT 1 FROM information_schema.columns 
    WHERE table_name = 'referencias' AND column_name = 'de_usuario_id'
  ) THEN
    -- Hacer la columna NULLABLE
    ALTER TABLE referencias ALTER COLUMN de_usuario_id DROP NOT NULL;
    RAISE NOTICE '✅ Columna de_usuario_id ahora es NULLABLE';
  END IF;
  
  -- Verificar si existe 'para_usuario_id' (columna vieja)
  IF EXISTS (
    SELECT 1 FROM information_schema.columns 
    WHERE table_name = 'referencias' AND column_name = 'para_usuario_id'
  ) THEN
    -- Hacer la columna NULLABLE
    ALTER TABLE referencias ALTER COLUMN para_usuario_id DROP NOT NULL;
    RAISE NOTICE '✅ Columna para_usuario_id ahora es NULLABLE';
  END IF;
  
  -- Verificar que existan las columnas nuevas
  IF NOT EXISTS (
    SELECT 1 FROM information_schema.columns 
    WHERE table_name = 'referencias' AND column_name = 'evaluador_id'
  ) THEN
    RAISE EXCEPTION 'ERROR: Columna evaluador_id no existe. Ejecuta FIX_REFERENCIAS_TABLE.sql primero';
  END IF;
  
  IF NOT EXISTS (
    SELECT 1 FROM information_schema.columns 
    WHERE table_name = 'referencias' AND column_name = 'evaluado_id'
  ) THEN
    RAISE EXCEPTION 'ERROR: Columna evaluado_id no existe. Ejecuta FIX_REFERENCIAS_TABLE.sql primero';
  END IF;
  
  RAISE NOTICE '✅ Columnas nuevas (evaluador_id, evaluado_id) existen correctamente';
END $$;

-- ============================================
-- 3. VERIFICAR ESTRUCTURA DE TABLAS
-- ============================================

-- Mostrar columnas de tabla reportes
SELECT 
  'reportes' as tabla,
  column_name,
  data_type,
  is_nullable,
  column_default
FROM information_schema.columns
WHERE table_name = 'reportes'
ORDER BY ordinal_position;

-- Mostrar columnas de tabla referencias
SELECT 
  'referencias' as tabla,
  column_name,
  data_type,
  is_nullable,
  column_default
FROM information_schema.columns
WHERE table_name = 'referencias'
ORDER BY ordinal_position;

-- ============================================
-- 4. VERIFICAR POLÍTICAS RLS
-- ============================================

-- Verificar políticas de reportes
SELECT 
  schemaname,
  tablename,
  policyname,
  permissive,
  roles,
  cmd
FROM pg_policies
WHERE tablename = 'reportes'
ORDER BY policyname;

-- Verificar políticas de referencias
SELECT 
  schemaname,
  tablename,
  policyname,
  permissive,
  roles,
  cmd
FROM pg_policies
WHERE tablename = 'referencias'
ORDER BY policyname;

-- ============================================
-- RESUMEN
-- ============================================

DO $$
BEGIN
  RAISE NOTICE '========================================';
  RAISE NOTICE 'RESUMEN DE CORRECCIONES:';
  RAISE NOTICE '========================================';
  RAISE NOTICE '1. ✅ Columna estatus agregada a reportes';
  RAISE NOTICE '2. ℹ️  Tabla referencias usa evaluador_id (correcto)';
  RAISE NOTICE '3. ⚠️  ACCIÓN REQUERIDA: Actualizar código Dart';
  RAISE NOTICE '   - Cambiar de_usuario_id por evaluador_id';
  RAISE NOTICE '========================================';
END $$;
