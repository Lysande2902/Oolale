-- ============================================
-- VERIFICAR ESTRUCTURA: Referencias y Reportes
-- Este script SÍ se puede ejecutar directamente
-- ============================================

-- 1. Verificar estructura de tabla referencias
SELECT 
    'TABLA: referencias' as info,
    column_name,
    data_type,
    is_nullable,
    column_default
FROM information_schema.columns
WHERE table_name = 'referencias'
ORDER BY ordinal_position;

-- 2. Verificar estructura de tabla reportes
SELECT 
    'TABLA: reportes' as info,
    column_name,
    data_type,
    is_nullable,
    column_default
FROM information_schema.columns
WHERE table_name = 'reportes'
ORDER BY ordinal_position;

-- 3. Verificar estructura de tabla calificaciones
SELECT 
    'TABLA: calificaciones' as info,
    column_name,
    data_type,
    is_nullable,
    column_default
FROM information_schema.columns
WHERE table_name = 'calificaciones'
ORDER BY ordinal_position;

-- 4. Verificar índices de referencias
SELECT 
    'ÍNDICES: referencias' as info,
    indexname,
    indexdef
FROM pg_indexes
WHERE tablename = 'referencias'
ORDER BY indexname;

-- 5. Verificar políticas RLS de referencias
SELECT 
    'POLÍTICAS RLS: referencias' as info,
    policyname,
    permissive,
    roles,
    cmd,
    qual
FROM pg_policies
WHERE tablename = 'referencias'
ORDER BY policyname;

-- 6. Verificar políticas RLS de reportes
SELECT 
    'POLÍTICAS RLS: reportes' as info,
    policyname,
    permissive,
    roles,
    cmd,
    qual
FROM pg_policies
WHERE tablename = 'reportes'
ORDER BY policyname;

-- 7. Contar registros existentes
SELECT 
    'CONTEO DE REGISTROS' as info,
    'referencias' as tabla,
    COUNT(*) as total
FROM referencias
UNION ALL
SELECT 
    'CONTEO DE REGISTROS' as info,
    'reportes' as tabla,
    COUNT(*) as total
FROM reportes
UNION ALL
SELECT 
    'CONTEO DE REGISTROS' as info,
    'calificaciones' as tabla,
    COUNT(*) as total
FROM calificaciones;

-- 8. Verificar constraints de referencias
SELECT 
    'CONSTRAINTS: referencias' as info,
    conname as constraint_name,
    contype as constraint_type,
    pg_get_constraintdef(oid) as definition
FROM pg_constraint
WHERE conrelid = 'referencias'::regclass
ORDER BY conname;

-- ============================================
-- RESUMEN
-- ============================================
DO $$
BEGIN
  RAISE NOTICE '========================================';
  RAISE NOTICE 'VERIFICACIÓN COMPLETADA';
  RAISE NOTICE '========================================';
  RAISE NOTICE 'Revisa los resultados arriba para:';
  RAISE NOTICE '1. Columnas de cada tabla';
  RAISE NOTICE '2. Índices creados';
  RAISE NOTICE '3. Políticas RLS activas';
  RAISE NOTICE '4. Cantidad de registros';
  RAISE NOTICE '5. Constraints y validaciones';
  RAISE NOTICE '========================================';
END $$;
