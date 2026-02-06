-- ============================================
-- FIX: NOTIFICACIONES CON NOMBRES EN ESPAÑOL
-- Corrige los nombres de columnas para que coincidan con la BD
-- ============================================

-- PASO 1: Función corregida con nombres en español
CREATE OR REPLACE FUNCTION send_push_notification_v1(
    p_user_id UUID,
    p_title TEXT,
    p_body TEXT,
    p_notification_type TEXT,
    p_data JSONB DEFAULT '{}'::jsonb
)
RETURNS BOOLEAN AS $$
DECLARE
    v_notification_id UUID;
BEGIN
    -- Guardar notificación con nombres de columnas en ESPAÑOL
    INSERT INTO notificaciones (
        user_id,
        titulo,      -- ✅ Corregido: era 'title'
        mensaje,     -- ✅ Corregido: era 'message'
        tipo,        -- ✅ Corregido: era 'type'
        data,
        leido,
        created_at
    ) VALUES (
        p_user_id,
        p_title,
        p_body,
        p_notification_type,
        p_data,
        FALSE,
        NOW()
    ) RETURNING id INTO v_notification_id;
    
    RAISE NOTICE '✅ Notificación guardada: % - % - %', v_notification_id, p_title, p_body;
    RAISE NOTICE '📡 Realtime enviará esta notificación a la app automáticamente';
    
    RETURN TRUE;
    
EXCEPTION WHEN OTHERS THEN
    RAISE NOTICE '❌ Error en send_push_notification_v1: %', SQLERRM;
    RETURN FALSE;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- PASO 2: Función de prueba
CREATE OR REPLACE FUNCTION test_notification_realtime(p_user_id UUID)
RETURNS BOOLEAN AS $$
BEGIN
    RETURN send_push_notification_v1(
        p_user_id,
        '🔔 Notificación de prueba',
        'Sistema Realtime configurado correctamente ✅',
        'test',
        '{"test": true, "method": "supabase_realtime"}'::jsonb
    );
END;
$$ LANGUAGE plpgsql;

-- ============================================
-- PASO 3: Triggers corregidos
-- ============================================

-- 3.1 Nueva solicitud de conexión
CREATE OR REPLACE FUNCTION notify_connection_request_v1()
RETURNS TRIGGER AS $$
DECLARE
    v_sender_name TEXT;
BEGIN
    IF NEW.estatus = 'pending' THEN
        SELECT nombre_artistico INTO v_sender_name
        FROM perfiles
        WHERE id = NEW.usuario_id;
        
        PERFORM send_push_notification_v1(
            NEW.conectado_id,
            'Nueva solicitud de conexión',
            v_sender_name || ' quiere conectar contigo',
            'connection_request',
            jsonb_build_object(
                'sender_id', NEW.usuario_id,
                'sender_name', v_sender_name,
                'connection_id', NEW.id
            )
        );
    END IF;
    
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

-- 3.2 Conexión aceptada
CREATE OR REPLACE FUNCTION notify_connection_accepted_v1()
RETURNS TRIGGER AS $$
DECLARE
    v_accepter_name TEXT;
BEGIN
    IF OLD.estatus = 'pending' AND NEW.estatus = 'accepted' THEN
        SELECT nombre_artistico INTO v_accepter_name
        FROM perfiles
        WHERE id = NEW.conectado_id;
        
        PERFORM send_push_notification_v1(
            NEW.usuario_id,
            '¡Conexión aceptada!',
            v_accepter_name || ' aceptó tu solicitud de conexión',
            'connection_accepted',
            jsonb_build_object(
                'accepter_id', NEW.conectado_id,
                'accepter_name', v_accepter_name,
                'connection_id', NEW.id
            )
        );
    END IF;
    
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

-- 3.3 Nuevo mensaje
CREATE OR REPLACE FUNCTION notify_new_message_v1()
RETURNS TRIGGER AS $$
DECLARE
    v_sender_name TEXT;
    v_receiver_id UUID;
BEGIN
    SELECT nombre_artistico INTO v_sender_name
    FROM perfiles
    WHERE id = NEW.remitente_id;
    
    v_receiver_id := NEW.destinatario_id;
    
    IF v_receiver_id IS NOT NULL THEN
        PERFORM send_push_notification_v1(
            v_receiver_id,
            'Nuevo mensaje de ' || v_sender_name,
            CASE 
                WHEN NEW.media_type = 'text' OR NEW.media_type IS NULL THEN LEFT(NEW.contenido, 50)
                WHEN NEW.media_type = 'image' THEN '📷 Imagen'
                WHEN NEW.media_type = 'video' THEN '🎥 Video'
                WHEN NEW.media_type = 'audio' THEN '🎵 Audio'
                ELSE 'Mensaje'
            END,
            'new_message',
            jsonb_build_object(
                'sender_id', NEW.remitente_id,
                'sender_name', v_sender_name,
                'conversation_id', NEW.id,
                'message_id', NEW.id
            )
        );
    END IF;
    
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

-- 3.4 Nueva calificación
CREATE OR REPLACE FUNCTION notify_new_rating_v1()
RETURNS TRIGGER AS $$
DECLARE
    v_rater_name TEXT;
BEGIN
    SELECT nombre_artistico INTO v_rater_name
    FROM perfiles
    WHERE id = NEW.evaluador_id;
    
    PERFORM send_push_notification_v1(
        NEW.evaluado_id,
        'Nueva calificación',
        v_rater_name || ' te ha calificado con ' || NEW.puntuacion || ' estrellas',
        'new_rating',
        jsonb_build_object(
            'rater_id', NEW.evaluador_id,
            'rater_name', v_rater_name,
            'rating', NEW.puntuacion,
            'rating_id', NEW.id
        )
    );
    
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

-- 3.5 Invitación a evento
CREATE OR REPLACE FUNCTION notify_event_invitation_v1()
RETURNS TRIGGER AS $$
DECLARE
    v_event_name TEXT;
    v_organizer_name TEXT;
BEGIN
    SELECT e.titulo_bolo, p.nombre_artistico INTO v_event_name, v_organizer_name
    FROM eventos e
    JOIN perfiles p ON p.id = e.organizador_id
    WHERE e.id = NEW.event_id;
    
    PERFORM send_push_notification_v1(
        NEW.musician_id,
        'Invitación a evento',
        v_organizer_name || ' te invitó a ' || v_event_name,
        'event_invitation',
        jsonb_build_object(
            'event_id', NEW.event_id,
            'event_name', v_event_name,
            'organizer_name', v_organizer_name
        )
    );
    
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

-- ============================================
-- VERIFICACIÓN
-- ============================================

SELECT '✅ Funciones y triggers actualizados con nombres en español' as resultado;
SELECT '🧪 Ahora prueba con: SELECT test_notification_realtime(''TU_USER_ID''::uuid);' as siguiente_paso;
