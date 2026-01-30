-- ============================================================================
-- Script: Actualizar Tabla Referencias para Sistema de Calificaciones
-- Descripción: Agrega las columnas necesarias para el sistema de calificaciones
-- Fecha: 29 de enero de 2026
-- ============================================================================

-- 1. Agregar columnas faltantes
ALTER TABLE referencias 
ADD COLUMN IF NOT EXISTS evaluador_id UUID REFERENCES profiles(id) ON DELETE CASCADE,
ADD COLUMN IF NOT EXISTS evaluado_id UUID REFERENCES profiles(id) ON DELETE CASCADE,
ADD COLUMN IF NOT EXISTS puntuacion INTEGER CHECK (puntuacion >= 1 AND puntuacion <= 5),
ADD COLUMN IF NOT EXISTS comentario TEXT,
ADD COLUMN IF NOT EXISTS tipo_interaccion VARCHAR(50) DEFAULT 'evento',
ADD COLUMN IF NOT EXISTS verificado BOOLEAN DEFAULT FALSE;

-- 2. Crear índices para mejorar rendimiento
CREATE INDEX IF NOT EXISTS idx_referencias_evaluador ON referencias(evaluador_id);
CREATE INDEX IF NOT EXISTS idx_referencias_evaluado ON referencias(evaluado_id);
CREATE INDEX IF NOT EXISTS idx_referencias_puntuacion ON referencias(puntuacion);
CREATE INDEX IF NOT EXISTS idx_referencias_verificado ON referencias(verificado);
CREATE INDEX IF NOT EXISTS idx_referencias_tipo ON referencias(tipo_interaccion);

-- 3. Agregar comentarios a las columnas
COMMENT ON COLUMN referencias.evaluador_id IS 'Usuario que deja la calificación';
COMMENT ON COLUMN referencias.evaluado_id IS 'Usuario que recibe la calificación';
COMMENT ON COLUMN referencias.puntuacion IS 'Calificación de 1 a 5 estrellas';
COMMENT ON COLUMN referencias.comentario IS 'Comentario opcional sobre la experiencia';
COMMENT ON COLUMN referencias.tipo_interaccion IS 'Tipo de interacción: evento, colaboracion, etc.';
COMMENT ON COLUMN referencias.verificado IS 'Si trabajaron juntos en algún evento';

-- 4. Verificar que las columnas se crearon correctamente
SELECT 
    column_name, 
    data_type, 
    is_nullable, 
    column_default
FROM information_schema.columns
WHERE table_name = 'referencias'
AND column_name IN ('evaluador_id', 'evaluado_id', 'puntuacion', 'comentario', 'tipo_interaccion', 'verificado')
ORDER BY ordinal_position;

-- ============================================================================
-- Notas:
-- - Este script es idempotente (se puede ejecutar múltiples veces)
-- - Las columnas antiguas (de_usuario_id, para_usuario_id, etc.) se mantienen
-- - Si quieres eliminar las columnas antiguas, ejecuta el script opcional abajo
-- ============================================================================

-- ============================================================================
-- OPCIONAL: Limpiar columnas antiguas (ejecutar solo si estás seguro)
-- ============================================================================
/*
-- Eliminar columnas antiguas que ya no se usan
ALTER TABLE referencias 
DROP COLUMN IF EXISTS de_usuario_id,
DROP COLUMN IF EXISTS para_usuario_id,
DROP COLUMN IF EXISTS titulo,
DROP COLUMN IF EXISTS contenido,
DROP COLUMN IF EXISTS aspectos_positivos,
DROP COLUMN IF EXISTS recomendaciones,
DROP COLUMN IF EXISTS verificada,
DROP COLUMN IF EXISTS fecha_verificacion,
DROP COLUMN IF EXISTS util_count;
*/

-- ============================================================================
-- Verificación Final
-- ============================================================================
-- Ejecuta esto para ver la estructura completa de la tabla
SELECT 
    column_name, 
    data_type, 
    character_maximum_length,
    is_nullable, 
    column_default
FROM information_schema.columns
WHERE table_name = 'referencias'
ORDER BY ordinal_position;
