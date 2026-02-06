-- ============================================
-- UPGRADE MESSAGES SYSTEM
-- Mejoras para sistema de mensajería completo
-- ============================================

-- 1. Agregar columnas de estado si no existen
DO $$
BEGIN
    -- Agregar read_at si no existe
    IF NOT EXISTS (
        SELECT 1 FROM information_schema.columns 
        WHERE table_name = 'intercom' AND column_name = 'read_at'
    ) THEN
        ALTER TABLE intercom ADD COLUMN read_at TIMESTAMPTZ;
    END IF;

    -- Asegurar que delivered_at existe
    IF NOT EXISTS (
        SELECT 1 FROM information_schema.columns 
        WHERE table_name = 'intercom' AND column_name = 'delivered_at'
    ) THEN
        ALTER TABLE intercom ADD COLUMN delivered_at TIMESTAMPTZ;
    END IF;

    -- Agregar leido si no existe (para compatibilidad)
    IF NOT EXISTS (
        SELECT 1 FROM information_schema.columns 
        WHERE table_name = 'intercom' AND column_name = 'leido'
    ) THEN
        ALTER TABLE intercom ADD COLUMN leido BOOLEAN DEFAULT FALSE;
    END IF;
END $$;

-- 2. Crear índices para mejorar rendimiento
CREATE INDEX IF NOT EXISTS idx_intercom_remitente_destinatario 
ON intercom(remitente_id, destinatario_id);

CREATE INDEX IF NOT EXISTS idx_intercom_destinatario_remitente 
ON intercom(destinatario_id, remitente_id);

CREATE INDEX IF NOT EXISTS idx_intercom_created_at 
ON intercom(created_at DESC);

CREATE INDEX IF NOT EXISTS idx_intercom_leido 
ON intercom(destinatario_id, leido) 
WHERE leido = FALSE;

-- 3. Crear función para marcar mensajes como leídos
CREATE OR REPLACE FUNCTION mark_messages_as_read(
    p_user_id UUID,
    p_sender_id UUID
)
RETURNS void AS $$
BEGIN
    UPDATE intercom
    SET 
        leido = TRUE,
        read_at = NOW()
    WHERE 
        destinatario_id = p_user_id 
        AND remitente_id = p_sender_id
        AND leido = FALSE;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- 4. Crear función para obtener conversaciones con último mensaje
CREATE OR REPLACE FUNCTION get_user_conversations(p_user_id UUID)
RETURNS TABLE (
    conversation_id UUID,
    other_user_id UUID,
    other_user_name TEXT,
    other_user_photo TEXT,
    last_message TEXT,
    last_message_time TIMESTAMPTZ,
    unread_count BIGINT,
    is_online BOOLEAN
) AS $$
BEGIN
    RETURN QUERY
    WITH conversations AS (
        SELECT DISTINCT
            CASE 
                WHEN remitente_id = p_user_id THEN destinatario_id
                ELSE remitente_id
            END AS other_user_id
        FROM intercom
        WHERE remitente_id = p_user_id OR destinatario_id = p_user_id
    ),
    last_messages AS (
        SELECT DISTINCT ON (
            CASE 
                WHEN remitente_id = p_user_id THEN destinatario_id
                ELSE remitente_id
            END
        )
            CASE 
                WHEN remitente_id = p_user_id THEN destinatario_id
                ELSE remitente_id
            END AS other_user_id,
            riff_text AS last_msg,
            created_at AS last_time
        FROM intercom
        WHERE remitente_id = p_user_id OR destinatario_id = p_user_id
        ORDER BY 
            CASE 
                WHEN remitente_id = p_user_id THEN destinatario_id
                ELSE remitente_id
            END,
            created_at DESC
    ),
    unread_counts AS (
        SELECT 
            remitente_id AS other_user_id,
            COUNT(*) AS unread
        FROM intercom
        WHERE destinatario_id = p_user_id AND leido = FALSE
        GROUP BY remitente_id
    )
    SELECT
        gen_random_uuid() AS conversation_id,
        c.other_user_id,
        p.nombre_artistico AS other_user_name,
        p.foto_perfil AS other_user_photo,
        lm.last_msg AS last_message,
        lm.last_time AS last_message_time,
        COALESCE(uc.unread, 0) AS unread_count,
        FALSE AS is_online -- TODO: implementar presencia en tiempo real
    FROM conversations c
    LEFT JOIN profiles p ON p.id = c.other_user_id
    LEFT JOIN last_messages lm ON lm.other_user_id = c.other_user_id
    LEFT JOIN unread_counts uc ON uc.other_user_id = c.other_user_id
    ORDER BY lm.last_time DESC NULLS LAST;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- 5. Crear tabla para indicadores de "escribiendo"
CREATE TABLE IF NOT EXISTS typing_indicators (
    id BIGSERIAL PRIMARY KEY,
    conversation_id TEXT NOT NULL,
    user_id UUID NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
    is_typing BOOLEAN DEFAULT FALSE,
    updated_at TIMESTAMPTZ DEFAULT NOW(),
    UNIQUE(conversation_id, user_id)
);

-- Índice para typing_indicators
CREATE INDEX IF NOT EXISTS idx_typing_indicators_conversation 
ON typing_indicators(conversation_id, is_typing);

-- 6. Habilitar RLS en typing_indicators
ALTER TABLE typing_indicators ENABLE ROW LEVEL SECURITY;

-- Política para ver indicadores de escritura
CREATE POLICY "Users can view typing indicators in their conversations"
ON typing_indicators FOR SELECT
USING (
    conversation_id LIKE '%' || auth.uid()::text || '%'
);

-- Política para actualizar indicadores de escritura
CREATE POLICY "Users can update their own typing indicators"
ON typing_indicators FOR ALL
USING (user_id = auth.uid());

-- 7. Trigger para actualizar timestamp de typing_indicators
CREATE OR REPLACE FUNCTION update_typing_indicator_timestamp()
RETURNS TRIGGER AS $$
BEGIN
    NEW.updated_at = NOW();
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER typing_indicator_updated_at
BEFORE UPDATE ON typing_indicators
FOR EACH ROW
EXECUTE FUNCTION update_typing_indicator_timestamp();

-- 8. Función para limpiar indicadores antiguos (más de 5 segundos)
CREATE OR REPLACE FUNCTION cleanup_old_typing_indicators()
RETURNS void AS $$
BEGIN
    UPDATE typing_indicators
    SET is_typing = FALSE
    WHERE is_typing = TRUE 
    AND updated_at < NOW() - INTERVAL '5 seconds';
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- 9. Actualizar mensajes existentes con delivered_at
UPDATE intercom
SET delivered_at = created_at
WHERE delivered_at IS NULL;

COMMENT ON TABLE intercom IS 'Tabla de mensajes entre usuarios con soporte para estados de lectura y multimedia';
COMMENT ON TABLE typing_indicators IS 'Indicadores de escritura en tiempo real para conversaciones';
COMMENT ON FUNCTION mark_messages_as_read IS 'Marca todos los mensajes de un remitente como leídos';
COMMENT ON FUNCTION get_user_conversations IS 'Obtiene todas las conversaciones de un usuario con información del último mensaje';

-- ============================================
-- INSTRUCCIONES DE USO:
-- 1. Ejecutar este script en Supabase SQL Editor
-- 2. Verificar que no hay errores
-- 3. Probar funciones con:
--    SELECT * FROM get_user_conversations('tu-user-id');
-- ============================================
