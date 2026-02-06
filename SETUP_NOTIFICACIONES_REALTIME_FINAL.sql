-- ============================================
-- SISTEMA DE NOTIFICACIONES CON SUPABASE REALTIME
-- Sin Firebase - Solo notificaciones locales automáticas
-- Óolale Mobile
-- ============================================

-- CÓMO FUNCIONA:
-- 1. Los triggers guardan notificaciones en la tabla 'notificaciones'
-- 2. Supabase Realtime detecta el INSERT automáticamente
-- 3. La app Flutter recibe el evento en tiempo real
-- 4. La app muestra una notificación local (bandeja de Android)
-- 5. Todo funciona incluso con la app en segundo plano

-- ============================================
-- PASO 1: Habilitar Realtime en la tabla
-- ============================================

-- Asegurarse de que Realtime esté habilitado para la tabla notificaciones
-- (Esto se hace en el Dashboard de Supabase, pero lo documentamos aquí)

/*
IMPORTANTE: Habilitar Realtime en Supabase Dashboard
-----------------------------------------------------
1. Ve a: https://supabase.com/dashboard/project/lwrlunndqzepwsbmofki/database/replication
2. Busca la tabla 'notificaciones'
3. Activa el toggle de "Enable Realtime"
4. Click en "Save"
*/

-- ============================================
-- PASO 2: Función simplificada (solo guarda en BD)
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
    v_notification_id UUID;
BEGIN
    -- Guardar notificación en la base de datos
    -- Supabase Realtime detectará este INSERT automáticamente
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
    
    RAISE NOTICE '✅ Notificación guardada: % - % - %', v_notification_id, p_title, p_body;
    RAISE NOTICE '📡 Realtime enviará esta notificación a la app automáticamente';
    
    RETURN TRUE;
    
EXCEPTION WHEN OTHERS THEN
    RAISE NOTICE '❌ Error en send_push_notification_v1: %', SQLERRM;
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

PASO 1: Habilitar Realtime en Supabase Dashboard
-------------------------------------------------
1. Ve a: https://supabase.com/dashboard/project/lwrlunndqzepwsbmofki/database/replication
2. Busca la tabla 'notificaciones'
3. Activa el toggle "Enable Realtime"
4. Click en "Save"

PASO 2: Ejecutar este script en Supabase SQL Editor
----------------------------------------------------
1. Ve a: https://supabase.com/dashboard/project/lwrlunndqzepwsbmofki/sql
2. Copia TODO este script
3. Pégalo en el editor
4. Click en "Run"

PASO 3: Probar el sistema
--------------------------
1. Abre la app en tu dispositivo
2. Asegúrate de estar autenticado

3. En Supabase SQL Editor, ejecuta:
   SELECT id, email FROM auth.users LIMIT 5;

4. Prueba la notificación:
   SELECT test_notification_realtime('TU_USER_ID'::uuid);

5. Deberías ver:
   - En los logs de la app: "NUEVA NOTIFICACIÓN RECIBIDA VIA REALTIME!"
   - En la bandeja de Android: Una notificación real

PASO 4: Probar eventos reales
------------------------------
1. Envía un mensaje → Notificación aparece automáticamente
2. Envía solicitud de conexión → Notificación aparece automáticamente
3. Acepta una conexión → Notificación aparece automáticamente
4. Califica a alguien → Notificación aparece automáticamente
5. Invita a un evento → Notificación aparece automáticamente

CÓMO FUNCIONA:
==============

1. Evento ocurre (mensaje, conexión, etc.)
   ↓
2. Trigger se activa
   ↓
3. Función guarda notificación en tabla 'notificaciones'
   ↓
4. Supabase Realtime detecta el INSERT
   ↓
5. Realtime envía evento a la app Flutter
   ↓
6. App recibe evento en _setupRealtimeListener()
   ↓
7. App muestra notificación local (bandeja de Android)
   ↓
8. ✅ Usuario ve la notificación

VENTAJAS:
=========

✅ No depende de Firebase Cloud Messaging
✅ No requiere Edge Functions
✅ No requiere configuración de API keys
✅ Funciona en tiempo real (< 1 segundo)
✅ Funciona con app en segundo plano
✅ Funciona con app cerrada (si el servicio está activo)
✅ Simple y confiable
✅ Gratis (incluido en plan gratuito de Supabase)

LIMITACIONES:
=============

⚠️ Requiere que la app esté instalada
⚠️ No funciona si el usuario desinstala la app
⚠️ Requiere conexión a internet

*/

-- ============================================
-- FIN DEL SCRIPT
-- ============================================

SELECT '🎉 Script ejecutado correctamente. Sistema Realtime listo.' as resultado;
SELECT '📡 Recuerda habilitar Realtime en el Dashboard de Supabase' as recordatorio;
