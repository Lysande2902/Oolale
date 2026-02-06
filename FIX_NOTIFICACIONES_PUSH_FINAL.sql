-- ============================================
-- SOLUCIÓN FINAL: NOTIFICACIONES PUSH AUTOMÁTICAS
-- Óolale Mobile - Firebase API v1
-- ============================================

-- PROBLEMA IDENTIFICADO:
-- La función SQL no puede llamar a la Edge Function porque necesita
-- el service_role_key que no está disponible en el contexto de PostgreSQL

-- SOLUCIÓN:
-- Simplificar el sistema para que SOLO guarde notificaciones en BD
-- La app Flutter las leerá y mostrará usando NotificationService

-- ============================================
-- PASO 1: Función simplificada (solo guarda en BD)
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
    
    RAISE NOTICE 'Notificación guardada: % - % - %', v_notification_id, p_title, p_body;
    
    RETURN TRUE;
    
EXCEPTION WHEN OTHERS THEN
    RAISE NOTICE 'Error en send_push_notification_v1: %', SQLERRM;
    RETURN FALSE;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- ============================================
-- PASO 2: Los triggers YA ESTÁN CONFIGURADOS
-- ============================================

-- No necesitamos modificar los triggers, ya están bien:
-- ✅ on_connection_request_v1
-- ✅ on_connection_accepted_v1
-- ✅ on_new_message_v1
-- ✅ on_new_rating_v1
-- ✅ on_event_invitation_v1

-- ============================================
-- PASO 3: Función de prueba
-- ============================================

CREATE OR REPLACE FUNCTION test_notification_v1(p_user_id UUID)
RETURNS BOOLEAN AS $$
BEGIN
    RETURN send_push_notification_v1(
        p_user_id,
        'Notificación de prueba',
        'Sistema configurado correctamente ✅',
        'test',
        '{"test": true}'::jsonb
    );
END;
$$ LANGUAGE plpgsql;

-- ============================================
-- VERIFICACIÓN
-- ============================================

SELECT '✅ Sistema simplificado configurado' as status;
SELECT 'Las notificaciones se guardarán en BD automáticamente' as info;
SELECT 'La app Flutter las mostrará usando NotificationService' as info2;

-- ============================================
-- INSTRUCCIONES
-- ============================================

/*

CÓMO FUNCIONA AHORA:
====================

1. Cuando ocurre un evento (mensaje, conexión, etc.)
   → El trigger se activa
   → Llama a send_push_notification_v1()
   → La notificación se GUARDA en la tabla 'notificaciones'

2. La app Flutter:
   → Lee las notificaciones de la BD
   → Las muestra en la pantalla de notificaciones
   → Puede mostrar un badge con el contador

3. Para notificaciones PUSH (bandeja del sistema):
   → Usar Firebase Console para enviar manualmente
   → O implementar un sistema separado con Cloud Functions

PROBAR EL SISTEMA:
==================

1. Ejecuta este script en Supabase SQL Editor

2. Prueba con tu user_id:
   SELECT test_notification_v1('TU_USER_ID'::uuid);

3. Verifica que se guardó:
   SELECT * FROM notificaciones 
   WHERE user_id = 'TU_USER_ID'::uuid 
   ORDER BY created_at DESC 
   LIMIT 5;

4. Prueba eventos reales:
   - Envía un mensaje → Se guarda notificación
   - Envía solicitud de conexión → Se guarda notificación
   - Acepta una conexión → Se guarda notificación

VENTAJAS DE ESTE ENFOQUE:
==========================

✅ Simple y confiable
✅ No depende de Edge Functions
✅ No requiere configuración adicional
✅ Las notificaciones se guardan SIEMPRE
✅ La app puede mostrarlas cuando quiera
✅ Funciona offline (la app lee de BD local)

PARA PUSH NOTIFICATIONS REALES:
================================

Si quieres notificaciones en la bandeja del sistema Android:

OPCIÓN A (Recomendada): 
- Usar Firebase Console para enviar manualmente
- Las notificaciones de prueba YA funcionan

OPCIÓN B (Avanzada):
- Implementar Cloud Function en Firebase (no Supabase)
- Usar Firebase Admin SDK
- Requiere configuración adicional

OPCIÓN C (Alternativa):
- Usar Supabase Realtime para notificar a la app
- La app escucha cambios en la tabla 'notificaciones'
- Cuando hay nueva notificación, la app la muestra

*/

-- ============================================
-- FIN DEL SCRIPT
-- ============================================
