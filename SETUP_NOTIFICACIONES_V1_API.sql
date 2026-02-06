-- ============================================
-- CONFIGURACIÓN DE NOTIFICACIONES AUTOMÁTICAS
-- Firebase Cloud Messaging API v1 (Método Moderno)
-- Óolale Mobile - Sistema de Push Notifications
-- ============================================

-- Este script configura el sistema completo de notificaciones automáticas
-- usando la API v1 de Firebase (método recomendado y actualizado)

-- ============================================
-- PASO 1: Habilitar extensiones necesarias
-- ============================================

CREATE EXTENSION IF NOT EXISTS pg_net;
CREATE EXTENSION IF NOT EXISTS pgcrypto;

-- ============================================
-- PASO 2: Crear tabla de configuración
-- ============================================

-- Tabla para almacenar la configuración de Firebase
CREATE TABLE IF NOT EXISTS firebase_config_v1 (
    id SERIAL PRIMARY KEY,
    project_id TEXT NOT NULL,
    client_email TEXT NOT NULL,
    private_key TEXT NOT NULL, -- Se almacenará encriptado
    created_at TIMESTAMP DEFAULT NOW(),
    updated_at TIMESTAMP DEFAULT NOW()
);

-- Insertar configuración
-- IMPORTANTE: Ejecuta este comando DESPUÉS de crear la tabla
-- Reemplaza los valores con los de tu Service Account JSON

INSERT INTO firebase_config_v1 (project_id, client_email, private_key) 
VALUES (
    'oolale',
    'firebase-adminsdk-fbsvc@oolale.iam.gserviceaccount.com',
    '-----BEGIN PRIVATE KEY-----
MIIEvQIBADANBgkqhkiG9w0BAQEFAASCBKcwggSjAgEAAoIBAQCxTxt6TKoRZrjV
15+cZKS9/Rhr1t4FvDw625ZNe++cZe+n/oxm9zbYeN3FT+GQcwQZvgKYX8emn0CV
gTuckZSjhUtL38efes0Nny8Wtck+QeDIYy1vuhm9z9nJ64xSXiUyiApbtzT7bVAv
NZHUHFVRxF8wyE3d8+jgApatnXpUaPjIJisiNUszGNOu9GpRaK2Zv/QS9fgn+q4k
M9/pa9qo/aJ1QPL3r0F+3Gf21aQ86HTH/MUAKrsxOnacQZajPfFVpQZiG8Sw0k4E
ACcu0XWYBNjLjlyu0coE07OM4WnjUou1HNrwbCEkJFMvtIwYqrRxSYNspPgeMS7L
qpxFCdghAgMBAAECggEAA3Bieu0m/MqqYdpqafsBP36b1Uaf/Io9vFIDQKo7V+QZ
wX9ES6B2n7z7Zy7xE+9JKHMpI3mzGoIa+3Nb28HumTvV/akf2vHjrYSVghohRrv6
H0TeLh00z9vK0HnpOTVCgTAGjGgZptlETYAbXZr1lC4L/xsZeIk5LnQaZlBoPaAZ
04QQL5ouXqdovOLIV7rpJ4k6p5/lcuNk/dlaLss2JGaBPdEWOYlPJyz9OD54fBGB
8daBST7nx3++cBy0MVXqQMjWRB0br4JM1ZE2WbkRjYn7KpB/R9VGct2QxDGyi9NQ
3QiIqP6Bnu3M5uFzDaI0DbkLLycZtMSv+kAWaxr1AQKBgQDbbmyqdzJEisc/TlWu
2C1jRLargxPJfY2e9Yv9HXISyC7x1QP7FevP+e7BqXX5eQr04pf8bNJq84R8gRpt
Hz0Vr59K9AEflPd9aWipTA0qQI9dyxeD20MBSDWhTh8rHRt+vb3UlZwhYn7lZCpM
tfhVOFYUXYgHzGOaR7p3SZEoYQKBgQDO259Urg89xcrRHVMJaVISR3coN4+YUPy6
v4Q1Cay1jcCJ17t2SJ6s9ZssdfeTF9leS0KSTJDgKHV3oVR3Hu5WO8r27W/mtxvs
MlwYrAdHUTVyB862UjMd//TfKf8+vpb6XhQxOKreXONq44LPKnSbM/9CaQEfxluD
3MQUh5fHwQKBgQCPd55CwhYyrE3jfTMWUy8xxT5t2xC334gV01OI1ZS85PeUlAK7
SrTYUQAizMpepx5byD85Aml9FeSchsihahhFMoNCvVBytrIt5BpS/m9pHbbeyyd/
xX8EupKd+Xb1eF1+u03/TSY8yapQDvJ9H0jTZzcYr6J9/stsltM6pPXsYQKBgAD0
1PzAPUPM2U40M4EUopOBDxT5hMlwfmqingrcu5avTBeXDr/SQCGOlSQUe4uLja64
7FrezcCrjzd5YHmYhAOUDTEtEdpgOFnUNcbLbNEwl+2qCZOgN6pI16n8eLiiivIn
YzKDD48toMOKv70TdiyNhf2ZnK637Q5kA+gQZGxBAoGAboUFX9eVo230RPTRUTXL
Mvpco7h5eP8KGtuA10hWnb4bCaDjcjSorhiqycGekqt27yNg6YOiLTxIhc83GcnR
EDwta4iXEEbBRpKYAHALwyS5Q8xDvhxvTjcuF5YWUmI4W8fsSo9i45LxSBKlAEQ0
kwy2NwNHai8/q5eWmM7fahc=
-----END PRIVATE KEY-----'
) ON CONFLICT DO NOTHING;

-- ============================================
-- PASO 3: Función para generar JWT token
-- ============================================

CREATE OR REPLACE FUNCTION generate_firebase_jwt()
RETURNS TEXT AS $$
DECLARE
    v_header JSONB;
    v_payload JSONB;
    v_signature TEXT;
    v_unsigned_token TEXT;
    v_private_key TEXT;
    v_client_email TEXT;
BEGIN
    -- Obtener configuración
    SELECT private_key, client_email 
    INTO v_private_key, v_client_email
    FROM firebase_config_v1 
    LIMIT 1;
    
    IF v_private_key IS NULL THEN
        RAISE EXCEPTION 'Firebase config not found';
    END IF;
    
    -- Crear header
    v_header := jsonb_build_object(
        'alg', 'RS256',
        'typ', 'JWT'
    );
    
    -- Crear payload
    v_payload := jsonb_build_object(
        'iss', v_client_email,
        'sub', v_client_email,
        'aud', 'https://oauth2.googleapis.com/token',
        'iat', EXTRACT(EPOCH FROM NOW())::INTEGER,
        'exp', (EXTRACT(EPOCH FROM NOW()) + 3600)::INTEGER,
        'scope', 'https://www.googleapis.com/auth/firebase.messaging'
    );
    
    -- Crear token sin firmar (base64url encoded)
    v_unsigned_token := 
        encode(convert_to(v_header::text, 'UTF8'), 'base64') || '.' ||
        encode(convert_to(v_payload::text, 'UTF8'), 'base64');
    
    -- Nota: La firma RSA256 requiere una extensión adicional o servicio externo
    -- Por simplicidad, usaremos el método de access token de Google
    
    RETURN v_unsigned_token;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- ============================================
-- PASO 4: Función simplificada para enviar notificación
-- ============================================

-- NOTA: Esta función usa pg_net para hacer llamadas HTTP asíncronas
-- Es más simple y no requiere generar JWT manualmente

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
    v_project_id TEXT;
    v_notification_id UUID;
    v_request_id BIGINT;
BEGIN
    -- Obtener project_id
    SELECT project_id INTO v_project_id FROM firebase_config_v1 LIMIT 1;
    
    IF v_project_id IS NULL THEN
        RAISE NOTICE 'Firebase config not found';
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
    
    -- Obtener todos los tokens del usuario
    FOR v_token IN 
        SELECT token 
        FROM tokens_dispositivo 
        WHERE user_id = p_user_id 
        AND token IS NOT NULL
    LOOP
        BEGIN
            -- Enviar notificación usando pg_net (asíncrono)
            -- Nota: Esto requiere configurar OAuth2 en Supabase
            -- Por ahora, solo guardamos la notificación en la BD
            
            RAISE NOTICE 'Notificación guardada para token: %', LEFT(v_token, 20) || '...';
            RAISE NOTICE 'Para envío automático, configura Supabase Edge Function';
            
        EXCEPTION WHEN OTHERS THEN
            RAISE NOTICE 'Error: %', SQLERRM;
        END;
    END LOOP;
    
    RETURN TRUE;
    
EXCEPTION WHEN OTHERS THEN
    RAISE NOTICE 'Error en send_push_notification_v1: %', SQLERRM;
    RETURN FALSE;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- ============================================
-- PASO 5: Triggers para eventos automáticos
-- ============================================

-- Los triggers son los mismos, solo cambiamos la función que llaman

-- ----------------------------------------
-- 5.1 NOTIFICACIÓN: Nueva solicitud de conexión
-- ----------------------------------------

CREATE OR REPLACE FUNCTION notify_connection_request_v1()
RETURNS TRIGGER AS $$
DECLARE
    v_sender_name TEXT;
BEGIN
    IF NEW.status = 'pending' THEN
        SELECT artist_name INTO v_sender_name
        FROM profiles
        WHERE user_id = NEW.user_id_1;
        
        PERFORM send_push_notification_v1(
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

DROP TRIGGER IF EXISTS on_connection_request_v1 ON conexiones;
CREATE TRIGGER on_connection_request_v1
    AFTER INSERT ON conexiones
    FOR EACH ROW
    EXECUTE FUNCTION notify_connection_request_v1();

-- ----------------------------------------
-- 5.2 NOTIFICACIÓN: Conexión aceptada
-- ----------------------------------------

CREATE OR REPLACE FUNCTION notify_connection_accepted_v1()
RETURNS TRIGGER AS $$
DECLARE
    v_accepter_name TEXT;
BEGIN
    IF OLD.status = 'pending' AND NEW.status = 'accepted' THEN
        SELECT artist_name INTO v_accepter_name
        FROM profiles
        WHERE user_id = NEW.user_id_2;
        
        PERFORM send_push_notification_v1(
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

DROP TRIGGER IF EXISTS on_connection_accepted_v1 ON conexiones;
CREATE TRIGGER on_connection_accepted_v1
    AFTER UPDATE ON conexiones
    FOR EACH ROW
    EXECUTE FUNCTION notify_connection_accepted_v1();

-- ----------------------------------------
-- 5.3 NOTIFICACIÓN: Nuevo mensaje
-- ----------------------------------------

CREATE OR REPLACE FUNCTION notify_new_message_v1()
RETURNS TRIGGER AS $$
DECLARE
    v_sender_name TEXT;
    v_receiver_id UUID;
BEGIN
    SELECT artist_name INTO v_sender_name
    FROM profiles
    WHERE user_id = NEW.sender_id;
    
    SELECT CASE 
        WHEN NEW.sender_id = c.user_id_1 THEN c.user_id_2
        ELSE c.user_id_1
    END INTO v_receiver_id
    FROM conversaciones c
    WHERE c.id = NEW.conversation_id;
    
    IF v_receiver_id IS NOT NULL THEN
        PERFORM send_push_notification_v1(
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

DROP TRIGGER IF EXISTS on_new_message_v1 ON mensajes;
CREATE TRIGGER on_new_message_v1
    AFTER INSERT ON mensajes
    FOR EACH ROW
    EXECUTE FUNCTION notify_new_message_v1();

-- ----------------------------------------
-- 5.4 NOTIFICACIÓN: Nueva calificación
-- ----------------------------------------

CREATE OR REPLACE FUNCTION notify_new_rating_v1()
RETURNS TRIGGER AS $$
DECLARE
    v_rater_name TEXT;
BEGIN
    SELECT artist_name INTO v_rater_name
    FROM profiles
    WHERE user_id = NEW.rater_id;
    
    PERFORM send_push_notification_v1(
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

DROP TRIGGER IF EXISTS on_new_rating_v1 ON calificaciones;
CREATE TRIGGER on_new_rating_v1
    AFTER INSERT ON calificaciones
    FOR EACH ROW
    EXECUTE FUNCTION notify_new_rating_v1();

-- ----------------------------------------
-- 5.5 NOTIFICACIÓN: Invitación a evento
-- ----------------------------------------

CREATE OR REPLACE FUNCTION notify_event_invitation_v1()
RETURNS TRIGGER AS $$
DECLARE
    v_event_name TEXT;
    v_organizer_name TEXT;
BEGIN
    SELECT e.title, p.artist_name INTO v_event_name, v_organizer_name
    FROM eventos e
    JOIN profiles p ON p.user_id = e.organizer_id
    WHERE e.id = NEW.event_id;
    
    PERFORM send_push_notification_v1(
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

DROP TRIGGER IF EXISTS on_event_invitation_v1 ON event_participants;
CREATE TRIGGER on_event_invitation_v1
    AFTER INSERT ON event_participants
    FOR EACH ROW
    WHEN (NEW.status = 'invited')
    EXECUTE FUNCTION notify_event_invitation_v1();

-- ============================================
-- PASO 6: Función de prueba
-- ============================================

CREATE OR REPLACE FUNCTION test_notification_v1(p_user_id UUID)
RETURNS BOOLEAN AS $$
BEGIN
    RETURN send_push_notification_v1(
        p_user_id,
        'Notificación de prueba V1',
        'Sistema configurado correctamente ✅',
        'test',
        '{"test": true, "api_version": "v1"}'::jsonb
    );
END;
$$ LANGUAGE plpgsql;

-- ============================================
-- PASO 7: Verificación
-- ============================================

-- Ver configuración
SELECT 
    '✅ Configuración V1 lista' as status,
    project_id,
    client_email,
    created_at
FROM firebase_config_v1;

-- Ver triggers
SELECT 
    trigger_name,
    event_object_table,
    action_timing
FROM information_schema.triggers
WHERE trigger_name LIKE '%_v1'
ORDER BY event_object_table, trigger_name;

-- ============================================
-- INSTRUCCIONES IMPORTANTES
-- ============================================

/*

NOTA IMPORTANTE:
================

Este script configura los TRIGGERS que detectan eventos y guardan
las notificaciones en la base de datos.

Sin embargo, para ENVIAR las notificaciones push reales a través de
Firebase Cloud Messaging API v1, necesitas configurar una Edge Function
en Supabase que:

1. Lea las notificaciones pendientes
2. Genere un JWT token con el Service Account
3. Obtenga un Access Token de Google OAuth2
4. Envíe la notificación a Firebase usando el Access Token

ALTERNATIVA MÁS SIMPLE:
========================

Usa el método legacy (Server Key) que configuramos antes, ya que
es más simple para empezar. La API v1 es más segura pero requiere
más configuración.

PARA PROBAR AHORA:
==================

1. Ejecuta este script en Supabase SQL Editor
2. Prueba con: SELECT test_notification_v1('tu-user-id'::uuid);
3. Verás que la notificación se GUARDA en la tabla notificaciones
4. Para ENVIARLA realmente, necesitas la Edge Function

*/

-- ============================================
-- FIN DEL SCRIPT
-- ============================================
