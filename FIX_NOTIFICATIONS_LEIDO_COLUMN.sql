-- Script para agregar la columna 'leido' a la tabla notifications
-- Fecha: 29 de Enero, 2026
-- Propósito: Corregir error "column notifications.leido does not exist"

-- 1. Agregar columna 'leido' si no existe
DO $$ 
BEGIN
    IF NOT EXISTS (
        SELECT 1 
        FROM information_schema.columns 
        WHERE table_name = 'notifications' 
        AND column_name = 'leido'
    ) THEN
        ALTER TABLE notifications 
        ADD COLUMN leido BOOLEAN DEFAULT FALSE NOT NULL;
        
        RAISE NOTICE 'Columna leido agregada exitosamente';
    ELSE
        RAISE NOTICE 'La columna leido ya existe';
    END IF;
END $$;

-- 2. Crear índice para mejorar rendimiento de consultas por leido
CREATE INDEX IF NOT EXISTS idx_notifications_leido 
ON notifications(user_id, leido, created_at DESC);

-- 3. Actualizar notificaciones existentes (marcar todas como no leídas)
UPDATE notifications 
SET leido = FALSE 
WHERE leido IS NULL;

-- 4. Verificar la estructura
SELECT 
    column_name, 
    data_type, 
    is_nullable, 
    column_default
FROM information_schema.columns
WHERE table_name = 'notifications'
ORDER BY ordinal_position;

-- Resultado esperado:
-- La tabla notifications ahora debe tener la columna 'leido' de tipo BOOLEAN
