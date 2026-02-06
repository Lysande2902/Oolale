-- ============================================
-- CONFIGURACIÓN DE NOTIFICACIONES AUTOMÁTICAS
-- Óolale Mobile - Sistema de Push Notifications
-- ============================================

-- Este script configura el sistema completo de notificaciones automáticas
-- que se envían cuando ocurren eventos en la aplicación.

-- ============================================
-- PASO 1: Habilitar la extensión HTTP
-- ============================================

-- Esta extensión permite hacer llamadas HTTP desde PostgreSQL
CREATE EXTENSION IF NOT EXISTS http;
CREATE EXTENSION IF NOT EXISTS pg_net;

-- ============================================
-- PASO 2: Crear tabla de configuración
-- ============================================

-- Tabla para almacenar la configuración de Firebase
CREATE TABLE IF NOT EXISTS firebase_config (
    id SERIAL PRIMARY KEY,
    server_key TEXT NOT NULL, -- Server Key de Firebase (legacy)
    project_id TEXT NOT NULL, -- ID del proyecto Firebase
    created_at TIMESTAMP DEFAULT NOW(),
    updated_at TIMESTAMP DEFAULT NOW()
);

-- Insertar configuración (DEBES ACTUALIZAR ESTOS VALORES)
-- Obtén el Server Key desde: Firebase Console → Project Settings → Cloud Messaging → Server Key
INSERT INTO firebase_config (server_key, project_id) 
VALUES (
    'TU_SERVER_KEY_AQUI', -- Reemplazar con tu Server Key
    'oolale' -- Tu project ID
) ON CONFLICT DO NOTHING;

-- ============================================
-- PASO 3: Función para enviar notificación push
-- ============================================

CREATE OR REPLACE FUNCTION send_push_notification(
    p_user_id UUID,
    p_title TEXT,
    p_body TEXT,
    p_notification_type TEXT,
    p_data JSONB DEFAULT '{}'::jsonb
)
RETURNS BOOLEAN AS $$
DECLARE
    v_token TEXT;
    v_server_key TEXT;
    v_response TEXT;
    v_notification_id UUID;
BEGIN
    -- Obtener el server key de Firebase
    SELECT server_key INTO v_server_key FROM firebase_config LIMIT 1;
    
    IF v_server_key IS NULL OR v_server_key = 'TU_SERVER_KEY_AQUI' THEN
        RAISE NOTICE 'Firebase Server Key no configurado';
        RETURN FALSE;
    END IF;
    
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
    
    -- Obtener todos los tokens del usuario (puede tener múltiples dispositivos)
    FOR v_token IN 
        SELECT token 
        FROM tokens_dispositivo 
        WHERE user_id = p_user_id 
        AND token IS NOT NULL
    LOOP
        BEGIN
            -- Enviar notificación a Firebase Cloud Messaging
            SELECT content INTO v_response
            FROM http((
                'POST',
                'https://fcm.googleapis.com/fcm/send',
                ARRAY[
                    http_header('Authorization', 'key=' || v_server_key),
                    http_header('Content-Type', 'application/json')
                ],
                'application/json',
                json_build_object(
                    'to', v_token,
                    'priority', 'high',
                    'notification', json_build_object(
                        'title', p_title,
                        'body', p_body,
                        'sound', 'default',
                        'badge', '1',
                        'click_action', 'FLUTTER_NOTIFICATION_CLICK'
                    ),
                    'data', p_data || jsonb_build_object(
                        'type', p_notification_type,
                        'notification_id', v_notification_id,
                        'click_action', 'FLUTTER_NOTIFICATION_CLICK'
                    )
                )::text
            )::http_request);
            
            RAISE NOTICE 'Notificación enviada a token: %', LEFT(v_token, 20) || '...';
            
        EXCEPTION WHEN OTHERS THEN
            RAISE NOTICE 'Error enviando notificación: %', SQLERRM;
        END;
    END LOOP;
    
    RETURN TRUE;
    
EXCEPTION WHEN OTHERS THEN
    RAISE NOTICE 'Error en send_push_notification: %', SQLERRM;
    RETURN FALSE;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- ============================================
-- PASO 4: Triggers para eventos automáticos
-- ============================================

-- ----------------------------------------
-- 4.1 NOTIFICACIÓN: Nueva solicitud de conexión
-- ----------------------------------------

CREATE OR REPLACE FUNCTION notify_connection_request()
RETURNS TRIGGER AS $$
DECLARE
    v_sender_name TEXT;
BEGIN
    -- Solo enviar si el estado es 'pending'
    IF NEW.status = 'pending' THEN
        -- Obtener nombre del solicitante
        SELECT artist_name INTO v_sender_name
        FROM profiles
        WHERE user_id = NEW.user_id_1;
        
        -- Enviar notificación al usuario que recibe la solicitud
        PERFORM send_push_notification(
            NEW.user_id_2,
            'Nueva solicitud de conexión',
            v_sender_name || ' quiere conectar contigo',
            'connection_request',
            jsonb_build_object(
                'sender_id', NEW.user_id_1,
                'sender_name', v_sender_name,
                'connection_id', NEW.id
            )
        );
    END IF;
    
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

DROP TRIGGER IF EXISTS on_connection_request ON conexiones;
CREATE TRIGGER on_connection_request
    AFTER INSERT ON conexiones
    FOR EACH ROW
    EXECUTE FUNCTION notify_connection_request();

-- ----------------------------------------
-- 4.2 NOTIFICACIÓN: Conexión aceptada
-- ----------------------------------------

CREATE OR REPLACE FUNCTION notify_connection_accepted()
RETURNS TRIGGER AS $$
DECLARE
    v_accepter_name TEXT;
BEGIN
    -- Solo enviar si cambió de pending a accepted
    IF OLD.status = 'pending' AND NEW.status = 'accepted' THEN
        -- Obtener nombre de quien aceptó
        SELECT artist_name INTO v_accepter_name
        FROM profiles
        WHERE user_id = NEW.user_id_2;
        
        -- Enviar notificación al usuario que envió la solicitud
        PERFORM send_push_notification(
            NEW.user_id_1,
            '¡Conexión aceptada!',
            v_accepter_name || ' aceptó tu solicitud de conexión',
            'connection_accepted',
            jsonb_build_object(
                'accepter_id', NEW.user_id_2,
                'accepter_name', v_accepter_name,
                'connection_id', NEW.id
            )
        );
    END IF;
    
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

DROP TRIGGER IF EXISTS on_connection_accepted ON conexiones;
CREATE TRIGGER on_connection_accepted
    AFTER UPDATE ON conexiones
    FOR EACH ROW
    EXECUTE FUNCTION notify_connection_accepted();

-- ----------------------------------------
-- 4.3 NOTIFICACIÓN: Nuevo mensaje
-- ----------------------------------------

CREATE OR REPLACE FUNCTION notify_new_message()
RETURNS TRIGGER AS $$
DECLARE
    v_sender_name TEXT;
    v_receiver_id UUID;
BEGIN
    -- Obtener nombre del remitente
    SELECT artist_name INTO v_sender_name
    FROM profiles
    WHERE user_id = NEW.sender_id;
    
    -- Determinar el receptor (el que NO es el sender)
    SELECT CASE 
        WHEN NEW.sender_id = c.user_id_1 THEN c.user_id_2
        ELSE c.user_id_1
    END INTO v_receiver_id
    FROM conversaciones c
    WHERE c.id = NEW.conversation_id;
    
    -- Enviar notificación al receptor
    IF v_receiver_id IS NOT NULL THEN
        PERFORM send_push_notification(
            v_receiver_id,
            'Nuevo mensaje de ' || v_sender_name,
            CASE 
                WHEN NEW.message_type = 'text' THEN LEFT(NEW.content, 50)
                WHEN NEW.message_type = 'image' THEN '📷 Imagen'
                WHEN NEW.message_type = 'video' THEN '🎥 Video'
                WHEN NEW.message_type = 'audio' THEN '🎵 Audio'
                ELSE 'Mensaje'
            END,
            'new_message',
            jsonb_build_object(
                'sender_id', NEW.sender_id,
                'sender_name', v_sender_name,
                'conversation_id', NEW.conversation_id,
                'message_id', NEW.id
            )
        );
    END IF;
    
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

DROP TRIGGER IF EXISTS on_new_message ON mensajes;
CREATE TRIGGER on_new_message
    AFTER INSERT ON mensajes
    FOR EACH ROW
    EXECUTE FUNCTION notify_new_message();

-- ----------------------------------------
-- 4.4 NOTIFICACIÓN: Nueva calificación
-- ----------------------------------------

CREATE OR REPLACE FUNCTION notify_new_rating()
RETURNS TRIGGER AS $$
DECLARE
    v_rater_name TEXT;
BEGIN
    -- Obtener nombre de quien calificó
    SELECT artist_name INTO v_rater_name
    FROM profiles
    WHERE user_id = NEW.rater_id;
    
    -- Enviar notificación al usuario calificado
    PERFORM send_push_notification(
        NEW.rated_user_id,
        'Nueva calificación',
        v_rater_name || ' te ha calificado con ' || NEW.rating || ' estrellas',
        'new_rating',
        jsonb_build_object(
            'rater_id', NEW.rater_id,
            'rater_name', v_rater_name,
            'rating', NEW.rating,
            'rating_id', NEW.id
        )
    );
    
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

DROP TRIGGER IF EXISTS on_new_rating ON calificaciones;
CREATE TRIGGER on_new_rating
    AFTER INSERT ON calificaciones
    FOR EACH ROW
    EXECUTE FUNCTION notify_new_rating();

-- ----------------------------------------
-- 4.5 NOTIFICACIÓN: Invitación a evento
-- ----------------------------------------

CREATE OR REPLACE FUNCTION notify_event_invitation()
RETURNS TRIGGER AS $$
DECLARE
    v_event_name TEXT;
    v_organizer_name TEXT;
BEGIN
    -- Obtener información del evento
    SELECT e.title, p.artist_name INTO v_event_name, v_organizer_name
    FROM eventos e
    JOIN profiles p ON p.user_id = e.organizer_id
    WHERE e.id = NEW.event_id;
    
    -- Enviar notificación al usuario invitado
    PERFORM send_push_notification(
        NEW.user_id,
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

-- Nota: Este trigger requiere una tabla de invitaciones a eventos
-- Si no existe, créala o ajusta según tu estructura
DROP TRIGGER IF EXISTS on_event_invitation ON event_participants;
CREATE TRIGGER on_event_invitation
    AFTER INSERT ON event_participants
    FOR EACH ROW
    WHEN (NEW.status = 'invited')
    EXECUTE FUNCTION notify_event_invitation();

-- ============================================
-- PASO 5: Función de prueba
-- ============================================

-- Función para probar el sistema de notificaciones
CREATE OR REPLACE FUNCTION test_notification(p_user_id UUID)
RETURNS BOOLEAN AS $$
BEGIN
    RETURN send_push_notification(
        p_user_id,
        'Notificación de prueba',
        'Si ves esto, el sistema funciona correctamente ✅',
        'test',
        '{"test": true}'::jsonb
    );
END;
$$ LANGUAGE plpgsql;

-- ============================================
-- PASO 6: Verificación
-- ============================================

-- Ver configuración actual
SELECT 
    CASE 
        WHEN server_key = 'TU_SERVER_KEY_AQUI' THEN '❌ Server Key NO configurado'
        ELSE '✅ Server Key configurado'
    END as status,
    project_id,
    created_at
FROM firebase_config;

-- Ver triggers creados
SELECT 
    trigger_name,
    event_object_table,
    action_statement
FROM information_schema.triggers
WHERE trigger_name LIKE '%notify%'
ORDER BY event_object_table, trigger_name;

-- ============================================
-- INSTRUCCIONES DE USO
-- ============================================

/*

PASO 1: Obtener Server Key de Firebase
---------------------------------------
1. Ve a: https://console.firebase.google.com
2. Selecciona tu proyecto "oolale"
3. Ve a: Project Settings (⚙️) → Cloud Messaging
4. Copia el "Server key" (en la sección "Cloud Messaging API (Legacy)")

PASO 2: Actualizar la configuración
------------------------------------
UPDATE firebase_config 
SET server_key = 'TU_SERVER_KEY_REAL_AQUI',
    updated_at = NOW();

PASO 3: Probar el sistema
--------------------------
-- Reemplaza con un user_id real de tu base de datos
SELECT test_notification('user-id-aqui'::uuid);

-- Deberías recibir una notificación en tu dispositivo

PASO 4: Verificar logs
-----------------------
-- Ver notificaciones enviadas
SELECT * FROM notificaciones 
ORDER BY created_at DESC 
LIMIT 10;

-- Ver tokens de dispositivos
SELECT 
    user_id,
    platform,
    LEFT(token, 30) || '...' as token_preview,
    updated_at
FROM tokens_dispositivo
ORDER BY updated_at DESC;

*/

-- ============================================
-- FIN DEL SCRIPT
-- ============================================

COMMENT ON FUNCTION send_push_notification IS 'Envía notificación push a través de Firebase Cloud Messaging';
COMMENT ON FUNCTION test_notification IS 'Función de prueba para verificar que las notificaciones funcionan';
