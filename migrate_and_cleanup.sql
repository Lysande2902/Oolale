-- PASO 1: Eliminar tablas obsoletas (versiones antiguas o sin uso)
-- Esto previene conflictos de nombres antes de renombrar las tablas actuales.

DROP TABLE IF EXISTS beneficios_top CASCADE;
DROP TABLE IF EXISTS blocks CASCADE;
DROP TABLE IF EXISTS bloqueos CASCADE;
DROP TABLE IF EXISTS calificaciones CASCADE;
DROP TABLE IF EXISTS canciones_setlist CASCADE;
DROP TABLE IF EXISTS conexiones CASCADE; -- Eliminamos la versión antigua para liberar el nombre
DROP TABLE IF EXISTS conversaciones CASCADE; -- Eliminamos la versión antigua para liberar el nombre
DROP TABLE IF EXISTS eventos CASCADE; -- Eliminamos la versión antigua para liberar el nombre
DROP TABLE IF EXISTS gear_catalog CASCADE;
DROP TABLE IF EXISTS generos CASCADE;
DROP TABLE IF EXISTS generos_catalog CASCADE;
DROP TABLE IF EXISTS genres CASCADE;
DROP TABLE IF EXISTS gig_lineup CASCADE;
DROP TABLE IF EXISTS historial_reportes CASCADE;
DROP TABLE IF EXISTS historial_reportes_usuario CASCADE;
DROP TABLE IF EXISTS instrumentos CASCADE;
DROP TABLE IF EXISTS mensajes CASCADE;
DROP TABLE IF EXISTS notificaciones CASCADE; -- Eliminamos la versión antigua para liberar el nombre
DROP TABLE IF EXISTS pagos_ranking CASCADE;
DROP TABLE IF EXISTS perfil_gear CASCADE;
DROP TABLE IF EXISTS perfil_generos CASCADE;
DROP TABLE IF EXISTS perfiles_generos CASCADE;
DROP TABLE IF EXISTS perfiles_instrumentos CASCADE;
DROP TABLE IF EXISTS postulaciones_evento CASCADE;
DROP TABLE IF EXISTS profile_genres CASCADE;
DROP TABLE IF EXISTS puntuacion_reputacion CASCADE;
DROP TABLE IF EXISTS ranking_top CASCADE;
DROP TABLE IF EXISTS reglas_reportes CASCADE;
DROP TABLE IF EXISTS reports CASCADE;
DROP TABLE IF EXISTS setlists CASCADE;
DROP TABLE IF EXISTS typing_indicators CASCADE;

-- PASO 2: Renombrar tablas activas (Inglés -> Español)

ALTER TABLE IF EXISTS gigs RENAME TO eventos;
ALTER TABLE IF EXISTS connections RENAME TO conexiones;
ALTER TABLE IF EXISTS profiles RENAME TO perfiles;
ALTER TABLE IF EXISTS hirings RENAME TO contrataciones;
ALTER TABLE IF EXISTS posts RENAME TO publicaciones;
ALTER TABLE IF EXISTS event_invitations RENAME TO invitaciones_evento;
ALTER TABLE IF EXISTS event_participants RENAME TO participantes_evento;
ALTER TABLE IF EXISTS notification_settings RENAME TO configuracion_notificaciones;
ALTER TABLE IF EXISTS privacy_settings RENAME TO configuracion_privacidad;
ALTER TABLE IF EXISTS intercom RENAME TO conversaciones;
ALTER TABLE IF EXISTS portfolio_media RENAME TO archivos_multimedia;
ALTER TABLE IF EXISTS device_tokens RENAME TO tokens_dispositivo;
ALTER TABLE IF EXISTS notifications RENAME TO notificaciones; -- Renombrar la tabla activa

-- NOTA: Si tienes funciones (RPCs) o Triggers hardcodeados con los nombres antiguos,
-- deberás actualizarlos manualmente en el editor SQL de Supabase.
