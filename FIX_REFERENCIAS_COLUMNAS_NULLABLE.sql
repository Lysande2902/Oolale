-- ============================================
-- FIX: Hacer columnas antiguas NULLABLE en referencias
-- ============================================
-- Problema: Las columnas antiguas tienen NOT NULL constraint
-- Solución: Hacer NULLABLE las columnas que ya no se usan
-- ============================================

-- 1. Hacer columnas antiguas NULLABLE
ALTER TABLE referencias 
ALTER COLUMN contenido DROP NOT NULL,
ALTER COLUMN titulo DROP NOT NULL,
ALTER COLUMN de_usuario_id DROP NOT NULL,
ALTER COLUMN para_usuario_id DROP NOT NULL;

-- 2. Verificar cambios
SELECT 
    column_name,
    data_type,
    is_nullable,
    column_default
FROM information_schema.columns
WHERE table_name = 'referencias'
AND column_name IN ('contenido', 'titulo', 'de_usuario_id', 'para_usuario_id', 'evaluador_id', 'evaluado_id', 'comentario', 'puntuacion')
ORDER BY ordinal_position;

-- ============================================
-- RESUMEN
-- ============================================
DO $$
BEGIN
  RAISE NOTICE '========================================';
  RAISE NOTICE 'COLUMNAS ANTIGUAS AHORA SON NULLABLE';
  RAISE NOTICE '========================================';
  RAISE NOTICE '✅ contenido - NULLABLE';
  RAISE NOTICE '✅ titulo - NULLABLE';
  RAISE NOTICE '✅ de_usuario_id - NULLABLE';
  RAISE NOTICE '✅ para_usuario_id - NULLABLE';
  RAISE NOTICE '';
  RAISE NOTICE 'Ahora puedes insertar referencias usando:';
  RAISE NOTICE '- evaluador_id (requerido)';
  RAISE NOTICE '- evaluado_id (requerido)';
  RAISE NOTICE '- puntuacion (requerido)';
  RAISE NOTICE '- comentario (opcional)';
  RAISE NOTICE '- tipo_interaccion (opcional)';
  RAISE NOTICE '========================================';
END $$;
