-- ═══════════════════════════════════════════════════════════════════════════════
-- OPTIMIZACIÓN DE BASE DE DATOS - ÍNDICES Y PERFORMANCE
-- ═══════════════════════════════════════════════════════════════════════════════
-- Fecha: 30 de Enero, 2026
-- Proyecto: Óolale Mobile
-- Descripción: Script para optimizar queries con índices adicionales
-- ═══════════════════════════════════════════════════════════════════════════════

-- ═══════════════════════════════════════════════════════════════════════════════
-- PARTE 1: ÍNDICES PARA PROFILES
-- ═══════════════════════════════════════════════════════════════════════════════

-- Índice compuesto para búsqueda por ubicación e instrumento
CREATE INDEX IF NOT EXISTS idx_profiles_ubicacion_instrumento 
ON profiles(ubicacion, instrumento_principal) 
WHERE ubicacion IS NOT NULL AND instrumento_principal IS NOT NULL;

-- Índice para búsqueda por nombre artístico (case-insensitive)
CREATE INDEX IF NOT EXISTS idx_profiles_nombre_artistico_lower 
ON profiles(LOWER(nombre_artistico));

-- Índice para perfiles activos con foto
CREATE INDEX IF NOT EXISTS idx_profiles_active_with_photo 
ON profiles(created_at DESC) 
WHERE foto_perfil IS NOT NULL;

-- Índice para completitud de perfil (para rankings)
CREATE INDEX IF NOT EXISTS idx_profiles_completion_desc 
ON profiles(profile_completion DESC) 
WHERE profile_completion > 0;

COMMENT ON INDEX idx_profiles_ubicacion_instrumento IS 'Optimiza búsqueda por ubicación e instrumento';
COMMENT ON INDEX idx_profiles_nombre_artistico_lower IS 'Optimiza búsqueda case-insensitive por nombre';
COMMENT ON INDEX idx_profiles_active_with_photo IS 'Optimiza listado de perfiles con foto';
COMMENT ON INDEX idx_profiles_completion_desc IS 'Optimiza rankings por completitud';

-- ═══════════════════════════════════════════════════════════════════════════════
-- PARTE 2: ÍNDICES PARA MENSAJES
-- ═══════════════════════════════════════════════════════════════════════════════

-- Índice compuesto para conversaciones (ordenadas por fecha)
CREATE INDEX IF NOT EXISTS idx_mensajes_conversation_date 
ON intercom(remitente_id, destinatario_id, created_at DESC);

-- Índice para mensajes no leídos por usuario
CREATE INDEX IF NOT EXISTS idx_mensajes_unread 
ON intercom(destinatario_id, leido) 
WHERE leido = FALSE;

-- Índice para mensajes con multimedia
CREATE INDEX IF NOT EXISTS idx_mensajes_with_media 
ON intercom(created_at DESC) 
WHERE media_url IS NOT NULL;

COMMENT ON INDEX idx_mensajes_conversation_date IS 'Optimiza carga de conversaciones';
COMMENT ON INDEX idx_mensajes_unread IS 'Optimiza conteo de mensajes no leídos';
COMMENT ON INDEX idx_mensajes_with_media IS 'Optimiza búsqueda de mensajes con multimedia';

-- ═══════════════════════════════════════════════════════════════════════════════
-- PARTE 3: ÍNDICES PARA EVENTOS (GIGS)
-- ═══════════════════════════════════════════════════════════════════════════════

-- Índice compuesto para eventos por lugar y fecha
CREATE INDEX IF NOT EXISTS idx_gigs_lugar_fecha 
ON gigs(lugar_nombre, fecha_gig DESC) 
WHERE lugar_nombre IS NOT NULL;

-- Índice para eventos por organizador (ordenados por fecha)
CREATE INDEX IF NOT EXISTS idx_gigs_organizer_date 
ON gigs(organizador_id, fecha_gig DESC);

-- Índice para eventos por tipo y fecha
CREATE INDEX IF NOT EXISTS idx_gigs_tipo_fecha 
ON gigs(tipo, fecha_gig DESC) 
WHERE tipo IS NOT NULL;

COMMENT ON INDEX idx_gigs_lugar_fecha IS 'Optimiza búsqueda de eventos por lugar y fecha';
COMMENT ON INDEX idx_gigs_organizer_date IS 'Optimiza listado de eventos por organizador';
COMMENT ON INDEX idx_gigs_tipo_fecha IS 'Optimiza filtrado por tipo de evento';

-- ═══════════════════════════════════════════════════════════════════════════════
-- PARTE 4: ÍNDICES PARA CONEXIONES
-- ═══════════════════════════════════════════════════════════════════════════════

-- Índice para conexiones pendientes
CREATE INDEX IF NOT EXISTS idx_connections_pending 
ON connections(conectado_id, estatus, created_at DESC) 
WHERE estatus = 'pending';

-- Índice para conexiones aceptadas (amigos)
CREATE INDEX IF NOT EXISTS idx_connections_accepted 
ON connections(usuario_id, conectado_id) 
WHERE estatus = 'accepted';

-- Índice compuesto para verificar conexión existente
CREATE INDEX IF NOT EXISTS idx_connections_check 
ON connections(usuario_id, conectado_id, estatus);

COMMENT ON INDEX idx_connections_pending IS 'Optimiza listado de solicitudes pendientes';
COMMENT ON INDEX idx_connections_accepted IS 'Optimiza listado de amigos';
COMMENT ON INDEX idx_connections_check IS 'Optimiza verificación de conexión existente';

-- ═══════════════════════════════════════════════════════════════════════════════
-- PARTE 5: ÍNDICES PARA CALIFICACIONES (REFERENCIAS)
-- ═══════════════════════════════════════════════════════════════════════════════

-- Índice para calificaciones recibidas (ordenadas por fecha)
CREATE INDEX IF NOT EXISTS idx_referencias_received_date 
ON referencias(evaluado_id, created_at DESC);

-- Índice para promedio de calificaciones
CREATE INDEX IF NOT EXISTS idx_referencias_rating_avg 
ON referencias(evaluado_id, puntuacion) 
WHERE puntuacion IS NOT NULL;

COMMENT ON INDEX idx_referencias_received_date IS 'Optimiza listado de calificaciones recibidas';
COMMENT ON INDEX idx_referencias_rating_avg IS 'Optimiza cálculo de promedio de calificaciones';

-- ═══════════════════════════════════════════════════════════════════════════════
-- PARTE 6: ÍNDICES PARA NOTIFICACIONES
-- ═══════════════════════════════════════════════════════════════════════════════

-- Índice para notificaciones no leídas
CREATE INDEX IF NOT EXISTS idx_notificaciones_unread 
ON notificaciones(usuario_id, leida, created_at DESC) 
WHERE leida = FALSE;

-- Índice para notificaciones por tipo
CREATE INDEX IF NOT EXISTS idx_notificaciones_tipo 
ON notificaciones(usuario_id, tipo, created_at DESC);

COMMENT ON INDEX idx_notificaciones_unread IS 'Optimiza listado de notificaciones no leídas';
COMMENT ON INDEX idx_notificaciones_tipo IS 'Optimiza filtrado por tipo de notificación';

-- ═══════════════════════════════════════════════════════════════════════════════
-- PARTE 7: ÍNDICES PARA PORTAFOLIO
-- ═══════════════════════════════════════════════════════════════════════════════

-- Índice para multimedia pública (ordenada por vistas)
CREATE INDEX IF NOT EXISTS idx_portfolio_public_popular 
ON portfolio_media(vistas DESC, created_at DESC) 
WHERE visibilidad = 'publico';

-- Índice compuesto para búsqueda por perfil y tipo
CREATE INDEX IF NOT EXISTS idx_portfolio_profile_tipo 
ON portfolio_media(profile_id, tipo, created_at DESC);

COMMENT ON INDEX idx_portfolio_public_popular IS 'Optimiza listado de multimedia popular';
COMMENT ON INDEX idx_portfolio_profile_tipo IS 'Optimiza filtrado por tipo en portafolio';

-- ═══════════════════════════════════════════════════════════════════════════════
-- PARTE 8: ÍNDICES PARA BLOQUEOS Y REPORTES
-- ═══════════════════════════════════════════════════════════════════════════════

-- Índice para verificar bloqueos
CREATE INDEX IF NOT EXISTS idx_bloqueos_check 
ON bloqueos(bloqueador_id, bloqueado_id);

-- Índice para reportes pendientes
CREATE INDEX IF NOT EXISTS idx_reportes_pending 
ON reportes(estado, created_at DESC) 
WHERE estado = 'pendiente';

COMMENT ON INDEX idx_bloqueos_check IS 'Optimiza verificación de bloqueos';
COMMENT ON INDEX idx_reportes_pending IS 'Optimiza listado de reportes pendientes';

-- ═══════════════════════════════════════════════════════════════════════════════
-- PARTE 9: ANÁLISIS Y VACUUM
-- ═══════════════════════════════════════════════════════════════════════════════

-- Actualizar estadísticas de todas las tablas
ANALYZE profiles;
ANALYZE intercom;
ANALYZE gigs;
ANALYZE connections;
ANALYZE referencias;
ANALYZE notificaciones;
ANALYZE portfolio_media;
ANALYZE bloqueos;
ANALYZE reportes;

-- NOTA: VACUUM no se puede ejecutar en Supabase SQL Editor (requiere autocommit)
-- Si necesitas ejecutar VACUUM, hazlo manualmente en una sesión separada:
-- VACUUM ANALYZE;

-- ═══════════════════════════════════════════════════════════════════════════════
-- PARTE 10: VERIFICACIÓN
-- ═══════════════════════════════════════════════════════════════════════════════

-- Contar índices creados
DO $$
DECLARE
  index_count INTEGER;
BEGIN
  SELECT COUNT(*) INTO index_count
  FROM pg_indexes
  WHERE schemaname = 'public'
  AND indexname LIKE 'idx_%';
  
  RAISE NOTICE '✅ Total de índices en base de datos: %', index_count;
END $$;

-- Verificar tamaño de índices
SELECT
  schemaname,
  tablename,
  indexname,
  pg_size_pretty(pg_relation_size(schemaname||'.'||indexname::regclass)) AS index_size
FROM pg_indexes
WHERE schemaname = 'public'
AND indexname LIKE 'idx_%'
ORDER BY pg_relation_size(schemaname||'.'||indexname::regclass) DESC
LIMIT 10;

-- ═══════════════════════════════════════════════════════════════════════════════
-- RESUMEN DE OPTIMIZACIÓN
-- ═══════════════════════════════════════════════════════════════════════════════

DO $$
BEGIN
  RAISE NOTICE '';
  RAISE NOTICE '═══════════════════════════════════════════════════════════════';
  RAISE NOTICE '✅ OPTIMIZACIÓN DE BASE DE DATOS COMPLETADA';
  RAISE NOTICE '═══════════════════════════════════════════════════════════════';
  RAISE NOTICE '';
  RAISE NOTICE 'Índices creados por tabla:';
  RAISE NOTICE '  • profiles: 4 índices adicionales';
  RAISE NOTICE '  • intercom: 3 índices adicionales';
  RAISE NOTICE '  • gigs: 3 índices adicionales';
  RAISE NOTICE '  • connections: 3 índices adicionales';
  RAISE NOTICE '  • referencias: 2 índices adicionales';
  RAISE NOTICE '  • notificaciones: 2 índices adicionales';
  RAISE NOTICE '  • portfolio_media: 2 índices adicionales';
  RAISE NOTICE '  • bloqueos: 1 índice adicional';
  RAISE NOTICE '  • reportes: 1 índice adicional';
  RAISE NOTICE '';
  RAISE NOTICE 'Total: 21 índices adicionales';
  RAISE NOTICE '';
  RAISE NOTICE 'Optimizaciones aplicadas:';
  RAISE NOTICE '  • Índices compuestos para queries complejas';
  RAISE NOTICE '  • Índices parciales para filtros frecuentes';
  RAISE NOTICE '  • Índices case-insensitive para búsquedas';
  RAISE NOTICE '  • ANALYZE ejecutado en todas las tablas';
  RAISE NOTICE '  • VACUUM debe ejecutarse manualmente si es necesario';
  RAISE NOTICE '';
  RAISE NOTICE 'Mejoras esperadas:';
  RAISE NOTICE '  • Búsquedas 5-10x más rápidas';
  RAISE NOTICE '  • Listados con paginación más eficientes';
  RAISE NOTICE '  • Queries complejas optimizadas';
  RAISE NOTICE '  • Menor uso de CPU en servidor';
  RAISE NOTICE '';
  RAISE NOTICE '═══════════════════════════════════════════════════════════════';
END $$;
