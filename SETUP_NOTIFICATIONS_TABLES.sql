-- ============================================
-- ÓOLALE MOBILE - SISTEMA DE NOTIFICACIONES PUSH
-- ============================================
-- Script de configuración de base de datos para notificaciones
-- Versión: 1.0.0
-- Fecha: 28 Enero 2026
-- ============================================

-- Este script:
-- 1. Crea la tabla device_tokens para almacenar tokens FCM
-- 2. Migra la tabla notifications existente a estructura estándar
-- 3. Configura índices para optimizar rendimiento
-- 4. Establece políticas de seguridad (RLS)
-- 5. Crea funciones auxiliares y triggers

-- ============================================
-- SECCIÓN 1: TABLA device_tokens
-- ============================================

-- Crear tabla para tokens de dispositivos
CREATE TABLE IF NOT EXISTS device_tokens (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  user_id UUID NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
  token TEXT NOT NULL,
  platform TEXT NOT NULL CHECK (platform IN ('android', 'ios', 'web')),
  created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
  updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
  CONSTRAINT unique_user_token UNIQUE(user_id, token)
);

-- Índices para device_tokens
CREATE INDEX IF NOT EXISTS idx_device_tokens_user_id ON device_tokens(user_id);
CREATE INDEX IF NOT EXISTS idx_device_tokens_token ON device_tokens(token);
CREATE INDEX IF NOT EXISTS idx_device_tokens_platform ON device_tokens(platform);
CREATE INDEX IF NOT EXISTS idx_device_tokens_updated_at ON device_tokens(updated_at DESC);

-- Comentarios descriptivos
COMMENT ON TABLE device_tokens IS 'Almacena tokens FCM de dispositivos para envío de notificaciones push';
COMMENT ON COLUMN device_tokens.user_id IS 'Referencia al usuario propietario del dispositivo';
COMMENT ON COLUMN device_tokens.token IS 'Token FCM único del dispositivo';
COMMENT ON COLUMN device_tokens.platform IS 'Plataforma del dispositivo: android, ios o web';
COMMENT ON COLUMN device_tokens.created_at IS 'Fecha de registro inicial del token';
COMMENT ON COLUMN device_tokens.updated_at IS 'Fecha de última actualización del token';

-- ============================================
-- SECCIÓN 2: MIGRACIÓN DE TABLA notifications
-- ============================================

-- Agregar columnas faltantes a la tabla existente
DO $$ 
BEGIN
  -- Agregar columna 'type' si no existe (renombrar 'tipo' si existe)
  IF NOT EXISTS (
    SELECT 1 FROM information_schema.columns 
    WHERE table_name = 'notifications' AND column_name = 'type'
  ) THEN
    IF EXISTS (
      SELECT 1 FROM information_schema.columns 
      WHERE table_name = 'notifications' AND column_name = 'tipo'
    ) THEN
      ALTER TABLE notifications RENAME COLUMN tipo TO type;
      RAISE NOTICE 'Columna "tipo" renombrada a "type"';
    ELSE
      ALTER TABLE notifications ADD COLUMN type TEXT;
      RAISE NOTICE 'Columna "type" agregada';
    END IF;
  END IF;

  -- Agregar columna 'title' si no existe (renombrar 'titulo' si existe)
  IF NOT EXISTS (
    SELECT 1 FROM information_schema.columns 
    WHERE table_name = 'notifications' AND column_name = 'title'
  ) THEN
    IF EXISTS (
      SELECT 1 FROM information_schema.columns 
      WHERE table_name = 'notifications' AND column_name = 'titulo'
    ) THEN
      ALTER TABLE notifications RENAME COLUMN titulo TO title;
      RAISE NOTICE 'Columna "titulo" renombrada a "title"';
    ELSE
      ALTER TABLE notifications ADD COLUMN title TEXT;
      RAISE NOTICE 'Columna "title" agregada';
    END IF;
  END IF;

  -- Agregar columna 'body' si no existe (renombrar 'mensaje' si existe)
  IF NOT EXISTS (
    SELECT 1 FROM information_schema.columns 
    WHERE table_name = 'notifications' AND column_name = 'body'
  ) THEN
    IF EXISTS (
      SELECT 1 FROM information_schema.columns 
      WHERE table_name = 'notifications' AND column_name = 'mensaje'
    ) THEN
      ALTER TABLE notifications RENAME COLUMN mensaje TO body;
      RAISE NOTICE 'Columna "mensaje" renombrada a "body"';
    ELSE
      ALTER TABLE notifications ADD COLUMN body TEXT;
      RAISE NOTICE 'Columna "body" agregada';
    END IF;
  END IF;

  -- Agregar columna 'read' si no existe (renombrar 'leido' si existe)
  IF NOT EXISTS (
    SELECT 1 FROM information_schema.columns 
    WHERE table_name = 'notifications' AND column_name = 'read'
  ) THEN
    IF EXISTS (
      SELECT 1 FROM information_schema.columns 
      WHERE table_name = 'notifications' AND column_name = 'leido'
    ) THEN
      ALTER TABLE notifications RENAME COLUMN leido TO read;
      RAISE NOTICE 'Columna "leido" renombrada a "read"';
    ELSE
      ALTER TABLE notifications ADD COLUMN read BOOLEAN DEFAULT FALSE;
      RAISE NOTICE 'Columna "read" agregada';
    END IF;
  END IF;

  -- Agregar columna 'read_at' si no existe
  IF NOT EXISTS (
    SELECT 1 FROM information_schema.columns 
    WHERE table_name = 'notifications' AND column_name = 'read_at'
  ) THEN
    ALTER TABLE notifications ADD COLUMN read_at TIMESTAMP WITH TIME ZONE;
    RAISE NOTICE 'Columna "read_at" agregada';
  END IF;

  -- Asegurar que la columna 'data' existe
  IF NOT EXISTS (
    SELECT 1 FROM information_schema.columns 
    WHERE table_name = 'notifications' AND column_name = 'data'
  ) THEN
    ALTER TABLE notifications ADD COLUMN data JSONB;
    RAISE NOTICE 'Columna "data" agregada';
  END IF;

  -- Asegurar que user_id tiene la referencia correcta
  IF NOT EXISTS (
    SELECT 1 FROM information_schema.table_constraints tc
    JOIN information_schema.constraint_column_usage ccu ON tc.constraint_name = ccu.constraint_name
    WHERE tc.table_name = 'notifications' 
      AND tc.constraint_type = 'FOREIGN KEY'
      AND ccu.column_name = 'user_id'
  ) THEN
    -- Cambiar tipo de columna si es necesario
    IF EXISTS (
      SELECT 1 FROM information_schema.columns 
      WHERE table_name = 'notifications' 
        AND column_name = 'user_id' 
        AND data_type = 'bigint'
    ) THEN
      -- Primero eliminar la columna id si es bigint y crear como UUID
      ALTER TABLE notifications ALTER COLUMN id TYPE UUID USING id::text::uuid;
      ALTER TABLE notifications ALTER COLUMN user_id TYPE UUID USING user_id::text::uuid;
    END IF;
    
    -- Agregar foreign key si no existe
    ALTER TABLE notifications 
      ADD CONSTRAINT fk_notifications_user 
      FOREIGN KEY (user_id) REFERENCES auth.users(id) ON DELETE CASCADE;
    RAISE NOTICE 'Foreign key constraint agregada a user_id';
  END IF;

  RAISE NOTICE 'Migración de tabla notifications completada exitosamente';
END $$;

-- ============================================
-- SECCIÓN 3: ÍNDICES PARA notifications
-- ============================================

-- Crear índices para optimizar queries
CREATE INDEX IF NOT EXISTS idx_notifications_user_id ON notifications(user_id);
CREATE INDEX IF NOT EXISTS idx_notifications_read ON notifications(read) WHERE read = FALSE;
CREATE INDEX IF NOT EXISTS idx_notifications_created_at ON notifications(created_at DESC);
CREATE INDEX IF NOT EXISTS idx_notifications_type ON notifications(type);
CREATE INDEX IF NOT EXISTS idx_notifications_user_unread ON notifications(user_id, read) WHERE read = FALSE;

-- Comentarios descriptivos
COMMENT ON TABLE notifications IS 'Historial de notificaciones push enviadas a usuarios';
COMMENT ON COLUMN notifications.user_id IS 'Usuario destinatario de la notificación';
COMMENT ON COLUMN notifications.type IS 'Tipo de notificación: connection_request, new_message, new_rating, event_invitation, etc.';
COMMENT ON COLUMN notifications.title IS 'Título de la notificación mostrado al usuario';
COMMENT ON COLUMN notifications.body IS 'Cuerpo del mensaje de la notificación';
COMMENT ON COLUMN notifications.data IS 'Datos adicionales en formato JSON para navegación y contexto';
COMMENT ON COLUMN notifications.read IS 'Indica si la notificación ha sido leída por el usuario';
COMMENT ON COLUMN notifications.read_at IS 'Timestamp de cuando se marcó como leída';

-- ============================================
-- SECCIÓN 4: ROW LEVEL SECURITY (RLS)
-- ============================================

-- Habilitar RLS en ambas tablas
ALTER TABLE device_tokens ENABLE ROW LEVEL SECURITY;
ALTER TABLE notifications ENABLE ROW LEVEL SECURITY;

-- ============================================
-- POLÍTICAS RLS: device_tokens
-- ============================================

-- Eliminar políticas existentes si existen
DROP POLICY IF EXISTS "Users can manage their own tokens" ON device_tokens;
DROP POLICY IF EXISTS "Users can view their own tokens" ON device_tokens;
DROP POLICY IF EXISTS "Users can insert their own tokens" ON device_tokens;
DROP POLICY IF EXISTS "Users can update their own tokens" ON device_tokens;
DROP POLICY IF EXISTS "Users can delete their own tokens" ON device_tokens;

-- Política unificada para gestión completa de tokens propios
CREATE POLICY "users_manage_own_tokens"
  ON device_tokens
  FOR ALL
  TO authenticated
  USING (auth.uid() = user_id)
  WITH CHECK (auth.uid() = user_id);

COMMENT ON POLICY "users_manage_own_tokens" ON device_tokens IS 
  'Permite a los usuarios autenticados gestionar completamente sus propios tokens de dispositivo';

-- ============================================
-- POLÍTICAS RLS: notifications
-- ============================================

-- Eliminar políticas existentes si existen
DROP POLICY IF EXISTS "Users can view their own notifications" ON notifications;
DROP POLICY IF EXISTS "Users can update their own notifications" ON notifications;
DROP POLICY IF EXISTS "System can create notifications" ON notifications;
DROP POLICY IF EXISTS "users_view_own_notifications" ON notifications;
DROP POLICY IF EXISTS "users_update_own_notifications" ON notifications;
DROP POLICY IF EXISTS "system_create_notifications" ON notifications;

-- Política para visualización de notificaciones propias
CREATE POLICY "users_view_own_notifications"
  ON notifications
  FOR SELECT
  TO authenticated
  USING (auth.uid() = user_id);

-- Política para actualización de notificaciones propias (marcar como leída)
CREATE POLICY "users_update_own_notifications"
  ON notifications
  FOR UPDATE
  TO authenticated
  USING (auth.uid() = user_id)
  WITH CHECK (auth.uid() = user_id);

-- Política para que el sistema pueda crear notificaciones para cualquier usuario
CREATE POLICY "system_create_notifications"
  ON notifications
  FOR INSERT
  TO authenticated
  WITH CHECK (true);

-- Comentarios en políticas
COMMENT ON POLICY "users_view_own_notifications" ON notifications IS 
  'Permite a los usuarios ver únicamente sus propias notificaciones';
COMMENT ON POLICY "users_update_own_notifications" ON notifications IS 
  'Permite a los usuarios actualizar el estado de sus propias notificaciones';
COMMENT ON POLICY "system_create_notifications" ON notifications IS 
  'Permite al sistema crear notificaciones para cualquier usuario autenticado';

-- ============================================
-- SECCIÓN 5: FUNCIONES AUXILIARES
-- ============================================

-- Eliminar funciones existentes si existen
DROP FUNCTION IF EXISTS clean_old_device_tokens();
DROP FUNCTION IF EXISTS get_unread_notifications_count(UUID);
DROP FUNCTION IF EXISTS mark_all_notifications_read(UUID);

-- Función para limpiar tokens antiguos (mantenimiento)
CREATE OR REPLACE FUNCTION clean_old_device_tokens()
RETURNS TABLE(deleted_count BIGINT)
LANGUAGE plpgsql
SECURITY DEFINER
AS $$
DECLARE
  v_deleted_count BIGINT;
BEGIN
  DELETE FROM device_tokens
  WHERE updated_at < NOW() - INTERVAL '90 days';
  
  GET DIAGNOSTICS v_deleted_count = ROW_COUNT;
  
  RETURN QUERY SELECT v_deleted_count;
END;
$$;

COMMENT ON FUNCTION clean_old_device_tokens IS 
  'Elimina tokens de dispositivos que no se han actualizado en más de 90 días. Retorna el número de tokens eliminados.';

-- Función para obtener contador de notificaciones no leídas
CREATE OR REPLACE FUNCTION get_unread_notifications_count(p_user_id UUID)
RETURNS INTEGER
LANGUAGE plpgsql
SECURITY DEFINER
STABLE
AS $$
DECLARE
  v_count INTEGER;
BEGIN
  SELECT COUNT(*)::INTEGER
  INTO v_count
  FROM notifications
  WHERE user_id = p_user_id
    AND read = FALSE;
  
  RETURN COALESCE(v_count, 0);
END;
$$;

COMMENT ON FUNCTION get_unread_notifications_count IS 
  'Retorna el número de notificaciones no leídas para un usuario específico';

-- Función para marcar todas las notificaciones como leídas
CREATE OR REPLACE FUNCTION mark_all_notifications_read(p_user_id UUID)
RETURNS TABLE(updated_count BIGINT)
LANGUAGE plpgsql
SECURITY DEFINER
AS $$
DECLARE
  v_updated_count BIGINT;
BEGIN
  UPDATE notifications
  SET read = TRUE,
      read_at = NOW()
  WHERE user_id = p_user_id
    AND read = FALSE;
  
  GET DIAGNOSTICS v_updated_count = ROW_COUNT;
  
  RETURN QUERY SELECT v_updated_count;
END;
$$;

COMMENT ON FUNCTION mark_all_notifications_read IS 
  'Marca todas las notificaciones no leídas de un usuario como leídas. Retorna el número de notificaciones actualizadas.';

-- ============================================
-- SECCIÓN 6: TRIGGERS
-- ============================================

-- Función trigger para actualizar updated_at automáticamente
CREATE OR REPLACE FUNCTION update_updated_at_column()
RETURNS TRIGGER
LANGUAGE plpgsql
AS $$
BEGIN
  NEW.updated_at = NOW();
  RETURN NEW;
END;
$$;

-- Trigger para device_tokens
DROP TRIGGER IF EXISTS trigger_device_tokens_updated_at ON device_tokens;
CREATE TRIGGER trigger_device_tokens_updated_at
  BEFORE UPDATE ON device_tokens
  FOR EACH ROW
  EXECUTE FUNCTION update_updated_at_column();

COMMENT ON TRIGGER trigger_device_tokens_updated_at ON device_tokens IS 
  'Actualiza automáticamente el campo updated_at cuando se modifica un registro';

-- ============================================
-- SECCIÓN 7: VERIFICACIÓN DE INSTALACIÓN
-- ============================================

-- Verificar que las tablas se crearon correctamente
DO $$
DECLARE
  v_device_tokens_exists BOOLEAN;
  v_notifications_exists BOOLEAN;
  v_device_tokens_count INTEGER;
  v_notifications_count INTEGER;
BEGIN
  -- Verificar existencia de tablas
  SELECT EXISTS (
    SELECT 1 FROM information_schema.tables 
    WHERE table_schema = 'public' AND table_name = 'device_tokens'
  ) INTO v_device_tokens_exists;
  
  SELECT EXISTS (
    SELECT 1 FROM information_schema.tables 
    WHERE table_schema = 'public' AND table_name = 'notifications'
  ) INTO v_notifications_exists;
  
  -- Contar registros
  SELECT COUNT(*) INTO v_device_tokens_count FROM device_tokens;
  SELECT COUNT(*) INTO v_notifications_count FROM notifications;
  
  -- Mostrar resultados
  RAISE NOTICE '========================================';
  RAISE NOTICE 'VERIFICACIÓN DE INSTALACIÓN';
  RAISE NOTICE '========================================';
  RAISE NOTICE 'Tabla device_tokens: %', CASE WHEN v_device_tokens_exists THEN '✓ Existe' ELSE '✗ No existe' END;
  RAISE NOTICE 'Registros en device_tokens: %', v_device_tokens_count;
  RAISE NOTICE 'Tabla notifications: %', CASE WHEN v_notifications_exists THEN '✓ Existe' ELSE '✗ No existe' END;
  RAISE NOTICE 'Registros en notifications: %', v_notifications_count;
  RAISE NOTICE '========================================';
  
  IF v_device_tokens_exists AND v_notifications_exists THEN
    RAISE NOTICE '✓ Instalación completada exitosamente';
  ELSE
    RAISE WARNING '✗ Algunas tablas no se crearon correctamente';
  END IF;
END $$;

-- ============================================
-- QUERIES DE VERIFICACIÓN MANUAL
-- ============================================

-- Descomentar para ejecutar verificaciones manuales

-- Verificar estructura de device_tokens
-- SELECT column_name, data_type, is_nullable, column_default
-- FROM information_schema.columns
-- WHERE table_name = 'device_tokens'
-- ORDER BY ordinal_position;

-- Verificar estructura de notifications
-- SELECT column_name, data_type, is_nullable, column_default
-- FROM information_schema.columns
-- WHERE table_name = 'notifications'
-- ORDER BY ordinal_position;

-- Verificar índices
-- SELECT tablename, indexname, indexdef
-- FROM pg_indexes
-- WHERE schemaname = 'public'
--   AND tablename IN ('device_tokens', 'notifications')
-- ORDER BY tablename, indexname;

-- Verificar políticas RLS
-- SELECT schemaname, tablename, policyname, permissive, roles, cmd, qual, with_check
-- FROM pg_policies
-- WHERE tablename IN ('device_tokens', 'notifications')
-- ORDER BY tablename, policyname;

-- Verificar funciones creadas
-- SELECT routine_name, routine_type, data_type
-- FROM information_schema.routines
-- WHERE routine_schema = 'public'
--   AND routine_name IN ('clean_old_device_tokens', 'get_unread_notifications_count', 'mark_all_notifications_read')
-- ORDER BY routine_name;

-- ============================================
-- FIN DEL SCRIPT
-- ============================================

-- Resumen de cambios aplicados:
-- ✓ Tabla device_tokens creada con estructura completa
-- ✓ Tabla notifications migrada a estructura estándar
-- ✓ Índices optimizados creados en ambas tablas
-- ✓ Políticas RLS configuradas para seguridad
-- ✓ Funciones auxiliares implementadas
-- ✓ Triggers automáticos configurados
-- ✓ Verificación de instalación ejecutada

-- Próximos pasos:
-- 1. Compilar y ejecutar la aplicación Flutter
-- 2. Verificar que los tokens FCM se guardan correctamente
-- 3. Enviar notificación de prueba desde Firebase Console
-- 4. Implementar UI de notificaciones en la aplicación
