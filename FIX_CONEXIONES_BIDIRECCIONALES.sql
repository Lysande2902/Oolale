-- ============================================
-- FIX: Sistema de Conexiones Bidireccionales
-- ============================================
-- Este script soluciona dos problemas:
-- 1. Agrega columna updated_at faltante
-- 2. Crea conexiones bidireccionales automáticamente
-- ============================================

-- PASO 1: Agregar columna updated_at
-- ============================================
ALTER TABLE conexiones 
ADD COLUMN IF NOT EXISTS updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW();

-- Actualizar registros existentes
UPDATE conexiones 
SET updated_at = created_at 
WHERE updated_at IS NULL;

-- PASO 2: Crear función para actualizar updated_at
-- ============================================
CREATE OR REPLACE FUNCTION update_updated_at_column()
RETURNS TRIGGER AS $$
BEGIN
    NEW.updated_at = NOW();
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

-- PASO 3: Crear trigger para updated_at
-- ============================================
DROP TRIGGER IF EXISTS update_conexiones_updated_at ON conexiones;

CREATE TRIGGER update_conexiones_updated_at
    BEFORE UPDATE ON conexiones
    FOR EACH ROW
    EXECUTE FUNCTION update_updated_at_column();

-- PASO 4: Función para crear conexión bidireccional
-- ============================================
CREATE OR REPLACE FUNCTION crear_conexion_bidireccional()
RETURNS TRIGGER AS $$
BEGIN
    -- Solo actuar cuando se acepta una solicitud
    IF NEW.estatus = 'accepted' AND OLD.estatus = 'pending' THEN
        -- Crear la conexión inversa (si no existe)
        INSERT INTO conexiones (usuario_id, conectado_id, estatus, created_at, updated_at)
        VALUES (NEW.conectado_id, NEW.usuario_id, 'accepted', NOW(), NOW())
        ON CONFLICT DO NOTHING;
        
        -- Si ya existe pero está en otro estado, actualizarla
        UPDATE conexiones
        SET estatus = 'accepted', updated_at = NOW()
        WHERE usuario_id = NEW.conectado_id 
          AND conectado_id = NEW.usuario_id
          AND estatus != 'accepted';
    END IF;
    
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

-- PASO 5: Crear trigger para conexiones bidireccionales
-- ============================================
DROP TRIGGER IF EXISTS trigger_conexion_bidireccional ON conexiones;

CREATE TRIGGER trigger_conexion_bidireccional
    AFTER UPDATE ON conexiones
    FOR EACH ROW
    EXECUTE FUNCTION crear_conexion_bidireccional();

-- PASO 6: Agregar constraint único para evitar duplicados
-- ============================================
-- Primero eliminar duplicados existentes (mantener el más reciente)
WITH duplicados AS (
    SELECT id, 
           ROW_NUMBER() OVER (
               PARTITION BY usuario_id, conectado_id 
               ORDER BY created_at DESC
           ) as rn
    FROM conexiones
)
DELETE FROM conexiones
WHERE id IN (
    SELECT id FROM duplicados WHERE rn > 1
);

-- Crear índice único compuesto
DROP INDEX IF EXISTS idx_conexiones_unique;
CREATE UNIQUE INDEX idx_conexiones_unique 
ON conexiones(usuario_id, conectado_id);

-- PASO 7: Reparar conexiones existentes
-- ============================================
-- Para todas las conexiones aceptadas que no tienen su inversa,
-- crear la conexión bidireccional
INSERT INTO conexiones (usuario_id, conectado_id, estatus, created_at, updated_at)
SELECT 
    c.conectado_id as usuario_id,
    c.usuario_id as conectado_id,
    'accepted' as estatus,
    c.created_at,
    NOW() as updated_at
FROM conexiones c
WHERE c.estatus = 'accepted'
  AND NOT EXISTS (
      SELECT 1 FROM conexiones c2
      WHERE c2.usuario_id = c.conectado_id
        AND c2.conectado_id = c.usuario_id
  )
ON CONFLICT (usuario_id, conectado_id) DO NOTHING;

-- ============================================
-- VERIFICACIÓN
-- ============================================
-- Ejecuta esta query para verificar que funciona:
/*
SELECT 
    c1.usuario_id as user_a,
    c1.conectado_id as user_b,
    c1.estatus as a_to_b_status,
    c2.estatus as b_to_a_status,
    CASE 
        WHEN c2.id IS NULL THEN '❌ FALTA CONEXIÓN INVERSA'
        WHEN c1.estatus = 'accepted' AND c2.estatus = 'accepted' THEN '✅ BIDIRECCIONAL'
        ELSE '⚠️ ESTADOS DIFERENTES'
    END as estado
FROM conexiones c1
LEFT JOIN conexiones c2 
    ON c1.usuario_id = c2.conectado_id 
    AND c1.conectado_id = c2.usuario_id
WHERE c1.estatus = 'accepted'
ORDER BY c1.created_at DESC
LIMIT 20;
*/

-- ============================================
-- RESULTADO ESPERADO
-- ============================================
-- ✅ Columna updated_at agregada
-- ✅ Trigger para actualizar updated_at automáticamente
-- ✅ Trigger para crear conexiones bidireccionales
-- ✅ Índice único para evitar duplicados
-- ✅ Conexiones existentes reparadas
-- ============================================
