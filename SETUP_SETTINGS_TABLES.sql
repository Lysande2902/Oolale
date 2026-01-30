-- ============================================================================
-- SCRIPT: Configuración de Tablas de Ajustes
-- DESCRIPCIÓN: Crea las tablas necesarias para configuraciones de notificaciones
--              y privacidad de usuarios
-- FECHA: 2025
-- ============================================================================

-- ============================================================================
-- TABLA: notification_settings
-- DESCRIPCIÓN: Almacena las preferencias de notificaciones de cada usuario
-- ============================================================================

CREATE TABLE IF NOT EXISTS notification_settings (
    id BIGSERIAL PRIMARY KEY,
    user_id UUID NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
    
    -- Canales
    push_enabled BOOLEAN DEFAULT true,
    email_enabled BOOLEAN DEFAULT true,
    
    -- Tipos de notificaciones
    connection_requests BOOLEAN DEFAULT true,
    event_invitations BOOLEAN DEFAULT true,
    messages BOOLEAN DEFAULT true,
    ratings BOOLEAN DEFAULT true,
    event_reminders BOOLEAN DEFAULT true,
    
    -- Preferencias
    sound_enabled BOOLEAN DEFAULT true,
    vibration_enabled BOOLEAN DEFAULT true,
    
    -- Timestamps
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    
    -- Constraint: Un usuario solo puede tener una configuración
    UNIQUE(user_id)
);

-- Índice para búsquedas rápidas por usuario
CREATE INDEX IF NOT EXISTS idx_notification_settings_user_id 
ON notification_settings(user_id);

-- Comentarios
COMMENT ON TABLE notification_settings IS 'Configuraciones de notificaciones por usuario';
COMMENT ON COLUMN notification_settings.push_enabled IS 'Notificaciones push habilitadas';
COMMENT ON COLUMN notification_settings.email_enabled IS 'Notificaciones por email habilitadas';
COMMENT ON COLUMN notification_settings.connection_requests IS 'Notificar solicitudes de conexión';
COMMENT ON COLUMN notification_settings.event_invitations IS 'Notificar invitaciones a eventos';
COMMENT ON COLUMN notification_settings.messages IS 'Notificar mensajes nuevos';
COMMENT ON COLUMN notification_settings.ratings IS 'Notificar calificaciones nuevas';
COMMENT ON COLUMN notification_settings.event_reminders IS 'Notificar recordatorios de eventos';

-- ============================================================================
-- TABLA: privacy_settings
-- DESCRIPCIÓN: Almacena las preferencias de privacidad de cada usuario
-- ============================================================================

CREATE TABLE IF NOT EXISTS privacy_settings (
    id BIGSERIAL PRIMARY KEY,
    user_id UUID NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
    
    -- Visibilidad del perfil
    profile_visibility VARCHAR(20) DEFAULT 'public' CHECK (profile_visibility IN ('public', 'connections', 'private')),
    
    -- Permisos de mensajes
    message_permissions VARCHAR(20) DEFAULT 'everyone' CHECK (message_permissions IN ('everyone', 'connections', 'nobody')),
    
    -- Actividad
    show_activity BOOLEAN DEFAULT true,
    show_online_status BOOLEAN DEFAULT true,
    show_location BOOLEAN DEFAULT true,
    
    -- Interacciones
    allow_tagging BOOLEAN DEFAULT true,
    show_in_search BOOLEAN DEFAULT true,
    
    -- Timestamps
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    
    -- Constraint: Un usuario solo puede tener una configuración
    UNIQUE(user_id)
);

-- Índice para búsquedas rápidas por usuario
CREATE INDEX IF NOT EXISTS idx_privacy_settings_user_id 
ON privacy_settings(user_id);

-- Índice para búsquedas por visibilidad
CREATE INDEX IF NOT EXISTS idx_privacy_settings_visibility 
ON privacy_settings(profile_visibility);

-- Comentarios
COMMENT ON TABLE privacy_settings IS 'Configuraciones de privacidad por usuario';
COMMENT ON COLUMN privacy_settings.profile_visibility IS 'Quién puede ver el perfil: public, connections, private';
COMMENT ON COLUMN privacy_settings.message_permissions IS 'Quién puede enviar mensajes: everyone, connections, nobody';
COMMENT ON COLUMN privacy_settings.show_activity IS 'Mostrar actividad reciente';
COMMENT ON COLUMN privacy_settings.show_online_status IS 'Mostrar estado en línea';
COMMENT ON COLUMN privacy_settings.show_location IS 'Mostrar ubicación en perfil';
COMMENT ON COLUMN privacy_settings.allow_tagging IS 'Permitir ser etiquetado';
COMMENT ON COLUMN privacy_settings.show_in_search IS 'Aparecer en resultados de búsqueda';

-- ============================================================================
-- FUNCIÓN: Actualizar timestamp de updated_at
-- ============================================================================

CREATE OR REPLACE FUNCTION update_updated_at_column()
RETURNS TRIGGER AS $$
BEGIN
    NEW.updated_at = NOW();
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

-- Triggers para actualizar updated_at automáticamente
DROP TRIGGER IF EXISTS update_notification_settings_updated_at ON notification_settings;
CREATE TRIGGER update_notification_settings_updated_at
    BEFORE UPDATE ON notification_settings
    FOR EACH ROW
    EXECUTE FUNCTION update_updated_at_column();

DROP TRIGGER IF EXISTS update_privacy_settings_updated_at ON privacy_settings;
CREATE TRIGGER update_privacy_settings_updated_at
    BEFORE UPDATE ON privacy_settings
    FOR EACH ROW
    EXECUTE FUNCTION update_updated_at_column();

-- ============================================================================
-- FUNCIÓN: Crear configuraciones por defecto al registrar usuario
-- ============================================================================

CREATE OR REPLACE FUNCTION create_default_settings()
RETURNS TRIGGER AS $$
BEGIN
    -- Crear configuración de notificaciones por defecto
    INSERT INTO notification_settings (user_id)
    VALUES (NEW.id)
    ON CONFLICT (user_id) DO NOTHING;
    
    -- Crear configuración de privacidad por defecto
    INSERT INTO privacy_settings (user_id)
    VALUES (NEW.id)
    ON CONFLICT (user_id) DO NOTHING;
    
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

-- Trigger para crear configuraciones al crear perfil
DROP TRIGGER IF EXISTS create_default_settings_on_profile ON profiles;
CREATE TRIGGER create_default_settings_on_profile
    AFTER INSERT ON profiles
    FOR EACH ROW
    EXECUTE FUNCTION create_default_settings();

-- ============================================================================
-- AGREGAR COLUMNAS A TABLA profiles PARA SOFT DELETE
-- ============================================================================

-- Agregar columnas si no existen
DO $$ 
BEGIN
    IF NOT EXISTS (SELECT 1 FROM information_schema.columns 
                   WHERE table_name = 'profiles' AND column_name = 'deleted_at') THEN
        ALTER TABLE profiles ADD COLUMN deleted_at TIMESTAMP WITH TIME ZONE;
    END IF;
    
    IF NOT EXISTS (SELECT 1 FROM information_schema.columns 
                   WHERE table_name = 'profiles' AND column_name = 'is_active') THEN
        ALTER TABLE profiles ADD COLUMN is_active BOOLEAN DEFAULT true;
    END IF;
END $$;

-- Índice para filtrar cuentas activas
CREATE INDEX IF NOT EXISTS idx_profiles_is_active 
ON profiles(is_active) WHERE is_active = true;

-- Comentarios
COMMENT ON COLUMN profiles.deleted_at IS 'Fecha de eliminación de cuenta (soft delete)';
COMMENT ON COLUMN profiles.is_active IS 'Indica si la cuenta está activa';

-- ============================================================================
-- POLÍTICAS RLS (Row Level Security)
-- ============================================================================

-- Habilitar RLS en las tablas
ALTER TABLE notification_settings ENABLE ROW LEVEL SECURITY;
ALTER TABLE privacy_settings ENABLE ROW LEVEL SECURITY;

-- Políticas para notification_settings
DROP POLICY IF EXISTS "Users can view their own notification settings" ON notification_settings;
CREATE POLICY "Users can view their own notification settings"
    ON notification_settings FOR SELECT
    USING (auth.uid() = user_id);

DROP POLICY IF EXISTS "Users can update their own notification settings" ON notification_settings;
CREATE POLICY "Users can update their own notification settings"
    ON notification_settings FOR UPDATE
    USING (auth.uid() = user_id);

DROP POLICY IF EXISTS "Users can insert their own notification settings" ON notification_settings;
CREATE POLICY "Users can insert their own notification settings"
    ON notification_settings FOR INSERT
    WITH CHECK (auth.uid() = user_id);

-- Políticas para privacy_settings
DROP POLICY IF EXISTS "Users can view their own privacy settings" ON privacy_settings;
CREATE POLICY "Users can view their own privacy settings"
    ON privacy_settings FOR SELECT
    USING (auth.uid() = user_id);

DROP POLICY IF EXISTS "Users can update their own privacy settings" ON privacy_settings;
CREATE POLICY "Users can update their own privacy settings"
    ON privacy_settings FOR UPDATE
    USING (auth.uid() = user_id);

DROP POLICY IF EXISTS "Users can insert their own privacy settings" ON privacy_settings;
CREATE POLICY "Users can insert their own privacy settings"
    ON privacy_settings FOR INSERT
    WITH CHECK (auth.uid() = user_id);

-- ============================================================================
-- DATOS DE PRUEBA (OPCIONAL)
-- ============================================================================

-- Crear configuraciones para usuarios existentes que no las tengan
INSERT INTO notification_settings (user_id)
SELECT id FROM auth.users
WHERE id NOT IN (SELECT user_id FROM notification_settings)
ON CONFLICT (user_id) DO NOTHING;

INSERT INTO privacy_settings (user_id)
SELECT id FROM auth.users
WHERE id NOT IN (SELECT user_id FROM privacy_settings)
ON CONFLICT (user_id) DO NOTHING;

-- ============================================================================
-- VERIFICACIÓN
-- ============================================================================

-- Verificar que las tablas se crearon correctamente
SELECT 
    'notification_settings' as tabla,
    COUNT(*) as registros
FROM notification_settings
UNION ALL
SELECT 
    'privacy_settings' as tabla,
    COUNT(*) as registros
FROM privacy_settings;

-- ============================================================================
-- FIN DEL SCRIPT
-- ============================================================================

-- Mensaje de éxito
DO $$
BEGIN
    RAISE NOTICE '✅ Tablas de configuración creadas exitosamente';
    RAISE NOTICE '✅ Políticas RLS configuradas';
    RAISE NOTICE '✅ Triggers configurados';
    RAISE NOTICE '✅ Configuraciones por defecto creadas para usuarios existentes';
END $$;
