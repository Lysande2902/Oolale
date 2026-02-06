-- ============================================
-- CONFIGURACIÓN FINAL DE NOTIFICACIONES
-- Con Edge Function desplegada
-- Óolale Mobile - Firebase API v1
-- ============================================

-- IMPORTANTE: La Edge Function ya está desplegada en:
-- https://lwrlunndqzepwsbmofki.supabase.co/functions/v1/send-notification

-- ============================================
-- PASO 1: Habilitar extensión HTTP
-- ============================================

CREATE EXTENSION IF NOT EXISTS http;

-- ============================================
-- PASO 2: Función para enviar notificación usando Edge Function
-- ============================================

CREATE OR REPLACE FUNCTION send_push_notification_v1(
    p_user_id UUID,
    p_title TEXT,
    p_body TEXT,
    p_notification_type TEXT,
    p_data JSONB DEFAULT '{}'::jsonb
)
RETURNS BOOLEAN AS $$
DECLARE
    v_token TEXT;
    v_notification_id UUID;
    v_edge_function_url TEXT := 'https://lwrlunndqzepwsbmofki.supabase.co/functions/v1/send-notification';
    v_response TEXT;
    v_service_role_key TEXT;
BEGIN
    -- Obtener service role key (necesario para llamar a Edge Functions)
    -- NOTA: Debes configurar esto como variable de entorno en Supabase
    v_service_role_key := current_setting('app.settings.service_role_key', true);
    
    -- Guardar notificación en la base de datos
    INSERT INTO notificaciones (
        user_id,
        title,
        message,
        type,
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
    
    -- Obtener todos los tokens del usuario
    FOR v_token IN 
        SELECT token 
        FROM tokens_dispositivo 
        WHERE user_id = p_user_id 
        AND token IS NOT NULL
    LOOP
        BEGIN
            -- Llamar a la Edge Function
            SELECT content INTO v_response
            FROM http((
                'POST',
                v_edge_function_url,
                ARRAY[
                    http_header('Content-Type', 'application/json'),
                    http_header('Authorization', 'Bearer ' || COALESCE(v_service_role_key, ''))
                ],
                'application/json',
                json_build_object(
                    'user_id', p_user_id::text,
                    'title', p_title,
                    'body', p_body,
                    'type', p_notification_type,
                    'data', p_data || jsonb_build_object('token', v_token)
                )::text
            )::http_request);
            
            RAISE NOTICE 'Notificación enviada a token: % - Response: %', LEFT(v_token, 20) || '...', v_response;
            
        EXCEPTION WHEN OTHERS THEN
            RAISE NOTICE 'Error enviando notificación: %', SQLERRM;
        END;
    END LOOP;
    
    RETURN TRUE;
    
EXCEPTION WHEN OTHERS THEN
    RAISE NOTICE 'Error en send_push_notification_v1: %', SQLERRM;
    RETURN FALSE;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- ============================================
-- PASO 3: Triggers para eventos automáticos
-- ============================================

-- ----------------------------------------
-- 3.1 NOTIFICACIÓN: Nueva solicitud de conexión
-- ----------------------------------------

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

DROP TRIGGER IF EXISTS on_connection_request_v1 ON conexiones;
CREATE TRIGGER on_connection_request_v1
    AFTER INSERT ON conexiones
    FOR EACH ROW
    EXECUTE FUNCTION notify_connection_request_v1();

-- ----------------------------------------
-- 3.2 NOTIFICACIÓN: Conexión aceptada
-- ----------------------------------------

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

DROP TRIGGER IF EXISTS on_connection_accepted_v1 ON conexiones;
CREATE TRIGGER on_connection_accepted_v1
    AFTER UPDATE ON conexiones
    FOR EACH ROW
    EXECUTE FUNCTION notify_connection_accepted_v1();

-- ----------------------------------------
-- 3.3 NOTIFICACIÓN: Nuevo mensaje
-- ----------------------------------------

CREATE OR REPLACE FUNCTION notify_new_message_v1()
RETURNS TRIGGER AS $$
DECLARE
    v_sender_name TEXT;
    v_receiver_id UUID;
BEGIN
    -- Obtener nombre del remitente
    SELECT nombre_artistico INTO v_sender_name
    FROM perfiles
    WHERE id = NEW.remitente_id;
    
    -- El receptor es el destinatario_id
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

DROP TRIGGER IF EXISTS on_new_message_v1 ON conversaciones;
CREATE TRIGGER on_new_message_v1
    AFTER INSERT ON conversaciones
    FOR EACH ROW
    EXECUTE FUNCTION notify_new_message_v1();

-- ----------------------------------------
-- 3.4 NOTIFICACIÓN: Nueva calificación/referencia
-- ----------------------------------------

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

DROP TRIGGER IF EXISTS on_new_rating_v1 ON referencias;
CREATE TRIGGER on_new_rating_v1
    AFTER INSERT ON referencias
    FOR EACH ROW
    WHEN (NEW.puntuacion IS NOT NULL)
    EXECUTE FUNCTION notify_new_rating_v1();

-- ----------------------------------------
-- 3.5 NOTIFICACIÓN: Invitación a evento
-- ----------------------------------------

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

DROP TRIGGER IF EXISTS on_event_invitation_v1 ON invitaciones_evento;
CREATE TRIGGER on_event_invitation_v1
    AFTER INSERT ON invitaciones_evento
    FOR EACH ROW
    WHEN (NEW.status = 'pending')
    EXECUTE FUNCTION notify_event_invitation_v1();

-- ============================================
-- PASO 4: Función de prueba
-- ============================================

CREATE OR REPLACE FUNCTION test_notification_v1(p_user_id UUID)
RETURNS BOOLEAN AS $$
BEGIN
    RETURN send_push_notification_v1(
        p_user_id,
        'Notificación de prueba V1',
        'Sistema configurado correctamente con Edge Function ✅',
        'test',
        '{"test": true, "api_version": "v1", "edge_function": true}'::jsonb
    );
END;
$$ LANGUAGE plpgsql;

-- ============================================
-- PASO 5: Verificación
-- ============================================

-- Ver triggers creados
SELECT 
    '✅ Triggers configurados' as status,
    trigger_name,
    event_object_table,
    action_timing
FROM information_schema.triggers
WHERE trigger_name LIKE '%_v1'
ORDER BY event_object_table, trigger_name;

-- ============================================
-- INSTRUCCIONES DE USO
-- ============================================

/*

PASO 1: Ejecutar este script completo en Supabase SQL Editor
------------------------------------------------------------
1. Ve a: https://supabase.com/dashboard/project/lwrlunndqzepwsbmofki/sql
2. Copia TODO este script
3. Pégalo en el editor
4. Click en "Run"

PASO 2: Probar el sistema
--------------------------
1. Obtén tu user_id:
   SELECT id, email FROM auth.users LIMIT 5;

2. Prueba la notificación:
   SELECT test_notification_v1('TU_USER_ID_AQUI'::uuid);

3. Deberías recibir una notificación en tu dispositivo

PASO 3: Verificar logs de la Edge Function
-------------------------------------------
En tu terminal local:
   supabase functions logs send-notification --follow

O en el Dashboard:
   https://supabase.com/dashboard/project/lwrlunndqzepwsbmofki/functions/send-notification/logs

PASO 4: Probar notificaciones automáticas
------------------------------------------
1. Envía una solicitud de conexión → El otro usuario recibe notificación
2. Acepta una solicitud → El solicitante recibe notificación
3. Envía un mensaje → El receptor recibe notificación
4. Califica a alguien → Esa persona recibe notificación
5. Invita a un evento → Los invitados reciben notificación

*/

-- ============================================
-- FIN DEL SCRIPT
-- ============================================

SELECT '🎉 Script ejecutado correctamente. Edge Function lista para enviar notificaciones.' as resultado;
