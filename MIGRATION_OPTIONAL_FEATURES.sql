-- ═══════════════════════════════════════════════════════════════════════════════
-- MIGRACIÓN DE BASE DE DATOS - FUNCIONALIDADES OPCIONALES
-- ═══════════════════════════════════════════════════════════════════════════════
-- Fecha: 29 de Enero, 2026
-- Proyecto: Óolale Mobile
-- Descripción: Migración para soportar funcionalidades opcionales
-- ═══════════════════════════════════════════════════════════════════════════════

-- ═══════════════════════════════════════════════════════════════════════════════
-- PARTE 1: MENSAJERÍA EN TIEMPO REAL
-- ═══════════════════════════════════════════════════════════════════════════════

-- Agregar columnas para estados de mensaje y multimedia
ALTER TABLE mensajes 
ADD COLUMN IF NOT EXISTS delivered_at TIMESTAMPTZ,
ADD COLUMN IF NOT EXISTS read_at TIMESTAMPTZ,
ADD COLUMN IF NOT EXISTS media_url TEXT,
ADD COLUMN IF NOT EXISTS media_type TEXT CHECK (media_type IN ('image', 'audio', NULL));

-- Índices para mejorar performance de queries
CREATE INDEX IF NOT EXISTS idx_mensajes_delivered_at ON mensajes(delivered_at);
CREATE INDEX IF NOT EXISTS idx_mensajes_read_at ON mensajes(read_at);
CREATE INDEX IF NOT EXISTS idx_mensajes_media_type ON mensajes(media_type) WHERE media_type IS NOT NULL;

COMMENT ON COLUMN mensajes.delivered_at IS 'Timestamp cuando el mensaje fue entregado al destinatario';
COMMENT ON COLUMN mensajes.read_at IS 'Timestamp cuando el mensaje fue leído por el destinatario';
COMMENT ON COLUMN mensajes.media_url IS 'URL del archivo multimedia adjunto (imagen o audio)';
COMMENT ON COLUMN mensajes.media_type IS 'Tipo de multimedia: image, audio, o NULL para texto simple';

-- ═══════════════════════════════════════════════════════════════════════════════
-- PARTE 2: GESTIÓN COMPLETA DE EVENTOS
-- ═══════════════════════════════════════════════════════════════════════════════

-- Tabla de invitaciones a eventos
CREATE TABLE IF NOT EXISTS event_invitations (
  id SERIAL PRIMARY KEY,
  event_id INTEGER NOT NULL REFERENCES gigs(id) ON DELETE CASCADE,
  musician_id UUID NOT NULL REFERENCES profiles(id) ON DELETE CASCADE,
  organizer_id UUID NOT NULL REFERENCES profiles(id) ON DELETE CASCADE,
  status TEXT NOT NULL DEFAULT 'pending' CHECK (status IN ('pending', 'accepted', 'declined')),
  created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  UNIQUE(event_id, musician_id)
);

-- Índices para invitaciones
CREATE INDEX IF NOT EXISTS idx_event_invitations_event_id ON event_invitations(event_id);
CREATE INDEX IF NOT EXISTS idx_event_invitations_musician_id ON event_invitations(musician_id);
CREATE INDEX IF NOT EXISTS idx_event_invitations_organizer_id ON event_invitations(organizer_id);
CREATE INDEX IF NOT EXISTS idx_event_invitations_status ON event_invitations(status);

COMMENT ON TABLE event_invitations IS 'Invitaciones a eventos enviadas a músicos';
COMMENT ON COLUMN event_invitations.status IS 'Estado de la invitación: pending, accepted, declined';

-- Trigger para actualizar updated_at
CREATE OR REPLACE FUNCTION update_event_invitations_updated_at()
RETURNS TRIGGER AS $$
BEGIN
  NEW.updated_at = NOW();
  RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER trigger_update_event_invitations_updated_at
BEFORE UPDATE ON event_invitations
FOR EACH ROW
EXECUTE FUNCTION update_event_invitations_updated_at();

-- ═══════════════════════════════════════════════════════════════════════════════
-- PARTE 3: PERFIL DE MÚSICO COMPLETO
-- ═══════════════════════════════════════════════════════════════════════════════

-- Tabla de géneros musicales (catálogo)
CREATE TABLE IF NOT EXISTS genres (
  id SERIAL PRIMARY KEY,
  name TEXT UNIQUE NOT NULL,
  created_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

-- Insertar géneros musicales comunes
INSERT INTO genres (name) VALUES
  ('Rock'),
  ('Pop'),
  ('Jazz'),
  ('Blues'),
  ('Country'),
  ('Reggae'),
  ('Hip Hop'),
  ('R&B'),
  ('Electronic'),
  ('Classical'),
  ('Metal'),
  ('Punk'),
  ('Indie'),
  ('Folk'),
  ('Latin'),
  ('Salsa'),
  ('Cumbia'),
  ('Reggaeton'),
  ('Banda'),
  ('Norteño'),
  ('Mariachi'),
  ('Ranchera'),
  ('Bolero'),
  ('Son'),
  ('Trova')
ON CONFLICT (name) DO NOTHING;

-- Tabla de relación perfil-géneros (many-to-many)
CREATE TABLE IF NOT EXISTS profile_genres (
  id SERIAL PRIMARY KEY,
  profile_id UUID NOT NULL REFERENCES profiles(id) ON DELETE CASCADE,
  genre TEXT NOT NULL,
  created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  UNIQUE(profile_id, genre)
);

-- Índices para géneros
CREATE INDEX IF NOT EXISTS idx_profile_genres_profile_id ON profile_genres(profile_id);
CREATE INDEX IF NOT EXISTS idx_profile_genres_genre ON profile_genres(genre);

COMMENT ON TABLE profile_genres IS 'Géneros musicales asociados a cada perfil de músico';

-- Agregar columnas nuevas a profiles
ALTER TABLE profiles 
ADD COLUMN IF NOT EXISTS years_experience INTEGER CHECK (years_experience >= 0 AND years_experience <= 100),
ADD COLUMN IF NOT EXISTS availability JSONB,
ADD COLUMN IF NOT EXISTS base_rate DECIMAL(10,2) CHECK (base_rate >= 0),
ADD COLUMN IF NOT EXISTS currency TEXT DEFAULT 'MXN' CHECK (currency IN ('MXN', 'USD')),
ADD COLUMN IF NOT EXISTS social_links JSONB,
ADD COLUMN IF NOT EXISTS profile_completion INTEGER DEFAULT 0 CHECK (profile_completion >= 0 AND profile_completion <= 100);

-- Índices para nuevas columnas
CREATE INDEX IF NOT EXISTS idx_profiles_years_experience ON profiles(years_experience) WHERE years_experience IS NOT NULL;
CREATE INDEX IF NOT EXISTS idx_profiles_base_rate ON profiles(base_rate) WHERE base_rate IS NOT NULL;
CREATE INDEX IF NOT EXISTS idx_profiles_profile_completion ON profiles(profile_completion);

COMMENT ON COLUMN profiles.years_experience IS 'Años de experiencia como músico';
COMMENT ON COLUMN profiles.availability IS 'Disponibilidad en formato JSON: {days: [0-6], time_ranges: [{start: "HH:MM", end: "HH:MM"}]}';
COMMENT ON COLUMN profiles.base_rate IS 'Tarifa base por evento';
COMMENT ON COLUMN profiles.currency IS 'Moneda de la tarifa: MXN o USD';
COMMENT ON COLUMN profiles.social_links IS 'Enlaces a redes sociales en formato JSON: {instagram: "", youtube: "", spotify: "", soundcloud: ""}';
COMMENT ON COLUMN profiles.profile_completion IS 'Porcentaje de completitud del perfil (0-100)';

-- ═══════════════════════════════════════════════════════════════════════════════
-- PARTE 4: PORTAFOLIO MULTIMEDIA
-- ═══════════════════════════════════════════════════════════════════════════════

-- Tabla de multimedia del portafolio (usando nombres en español para consistencia)
CREATE TABLE IF NOT EXISTS portfolio_media (
  id SERIAL PRIMARY KEY,
  profile_id UUID NOT NULL REFERENCES profiles(id) ON DELETE CASCADE,
  tipo VARCHAR(20) NOT NULL CHECK (tipo IN ('imagen', 'video', 'audio')),
  titulo VARCHAR(200) NOT NULL DEFAULT 'Sin título',
  descripcion TEXT,
  url_recurso VARCHAR(500) NOT NULL,
  duracion_segundos INTEGER CHECK (duracion_segundos >= 0),
  tamaño_bytes INTEGER,
  thumbnail_url VARCHAR(500),
  
  -- Metadatos
  fecha_creacion TIMESTAMPTZ,
  ubicacion VARCHAR(200),
  
  -- Privacidad
  visibilidad VARCHAR(20) DEFAULT 'publico' CHECK (visibilidad IN ('publico', 'privado', 'amigos')),
  
  -- Stats
  vistas INTEGER DEFAULT 0,
  descargas INTEGER DEFAULT 0,
  compartidos INTEGER DEFAULT 0,
  
  created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  deleted_at TIMESTAMPTZ
);

-- Índices para portafolio
CREATE INDEX IF NOT EXISTS idx_portfolio_media_profile_id ON portfolio_media(profile_id);
CREATE INDEX IF NOT EXISTS idx_portfolio_media_tipo ON portfolio_media(tipo);
CREATE INDEX IF NOT EXISTS idx_portfolio_media_created_at ON portfolio_media(created_at DESC);
CREATE INDEX IF NOT EXISTS idx_portfolio_media_visibilidad ON portfolio_media(visibilidad);

COMMENT ON TABLE portfolio_media IS 'Archivos multimedia del portafolio de cada músico';
COMMENT ON COLUMN portfolio_media.tipo IS 'Tipo de archivo: imagen, video, audio';
COMMENT ON COLUMN portfolio_media.titulo IS 'Título del archivo multimedia';
COMMENT ON COLUMN portfolio_media.url_recurso IS 'URL del archivo en Supabase Storage';
COMMENT ON COLUMN portfolio_media.thumbnail_url IS 'URL del thumbnail (para videos)';
COMMENT ON COLUMN portfolio_media.duracion_segundos IS 'Duración en segundos (para audio y video)';
COMMENT ON COLUMN portfolio_media.visibilidad IS 'Nivel de privacidad: publico, privado, amigos';

-- ═══════════════════════════════════════════════════════════════════════════════
-- PARTE 5: FUNCIONES AUXILIARES
-- ═══════════════════════════════════════════════════════════════════════════════

-- Función para calcular completitud de perfil
CREATE OR REPLACE FUNCTION calculate_profile_completion(profile_id UUID)
RETURNS INTEGER AS $$
DECLARE
  completion INTEGER := 0;
  total_fields INTEGER := 11;
  profile_record RECORD;
  genre_count INTEGER;
  portfolio_count INTEGER;
BEGIN
  -- Obtener datos del perfil
  SELECT * INTO profile_record FROM profiles WHERE id = profile_id;
  
  IF NOT FOUND THEN
    RETURN 0;
  END IF;
  
  -- Contar campos completados
  IF profile_record.nombre_artistico IS NOT NULL AND profile_record.nombre_artistico != '' THEN
    completion := completion + 1;
  END IF;
  
  IF profile_record.bio IS NOT NULL AND profile_record.bio != '' THEN
    completion := completion + 1;
  END IF;
  
  IF profile_record.ubicacion IS NOT NULL AND profile_record.ubicacion != '' THEN
    completion := completion + 1;
  END IF;
  
  IF profile_record.instrumento_principal IS NOT NULL AND profile_record.instrumento_principal != '' THEN
    completion := completion + 1;
  END IF;
  
  IF profile_record.foto_perfil IS NOT NULL AND profile_record.foto_perfil != '' THEN
    completion := completion + 1;
  END IF;
  
  -- Verificar géneros
  SELECT COUNT(*) INTO genre_count FROM profile_genres WHERE profile_genres.profile_id = calculate_profile_completion.profile_id;
  IF genre_count > 0 THEN
    completion := completion + 1;
  END IF;
  
  IF profile_record.years_experience IS NOT NULL THEN
    completion := completion + 1;
  END IF;
  
  IF profile_record.availability IS NOT NULL THEN
    completion := completion + 1;
  END IF;
  
  IF profile_record.base_rate IS NOT NULL THEN
    completion := completion + 1;
  END IF;
  
  IF profile_record.social_links IS NOT NULL AND profile_record.social_links::text != '{}' THEN
    completion := completion + 1;
  END IF;
  
  -- Verificar portafolio
  SELECT COUNT(*) INTO portfolio_count FROM portfolio_media WHERE portfolio_media.profile_id = calculate_profile_completion.profile_id;
  IF portfolio_count > 0 THEN
    completion := completion + 1;
  END IF;
  
  -- Calcular porcentaje
  RETURN (completion * 100 / total_fields);
END;
$$ LANGUAGE plpgsql;

COMMENT ON FUNCTION calculate_profile_completion IS 'Calcula el porcentaje de completitud de un perfil (0-100)';

-- Función para actualizar automáticamente profile_completion
CREATE OR REPLACE FUNCTION update_profile_completion()
RETURNS TRIGGER AS $$
BEGIN
  NEW.profile_completion := calculate_profile_completion(NEW.id);
  RETURN NEW;
END;
$$ LANGUAGE plpgsql;

-- Trigger para actualizar profile_completion automáticamente
DROP TRIGGER IF EXISTS trigger_update_profile_completion ON profiles;
CREATE TRIGGER trigger_update_profile_completion
BEFORE INSERT OR UPDATE ON profiles
FOR EACH ROW
EXECUTE FUNCTION update_profile_completion();

-- ═══════════════════════════════════════════════════════════════════════════════
-- PARTE 6: POLÍTICAS DE SEGURIDAD (RLS)
-- ═══════════════════════════════════════════════════════════════════════════════

-- Habilitar RLS en nuevas tablas
ALTER TABLE event_invitations ENABLE ROW LEVEL SECURITY;
ALTER TABLE profile_genres ENABLE ROW LEVEL SECURITY;
ALTER TABLE portfolio_media ENABLE ROW LEVEL SECURITY;

-- Políticas para event_invitations
CREATE POLICY "Users can view their own invitations"
ON event_invitations FOR SELECT
TO authenticated
USING (musician_id = auth.uid() OR organizer_id = auth.uid());

CREATE POLICY "Organizers can create invitations"
ON event_invitations FOR INSERT
TO authenticated
WITH CHECK (organizer_id = auth.uid());

CREATE POLICY "Musicians can update their invitations"
ON event_invitations FOR UPDATE
TO authenticated
USING (musician_id = auth.uid())
WITH CHECK (musician_id = auth.uid());

-- Políticas para profile_genres
CREATE POLICY "Anyone can view genres"
ON profile_genres FOR SELECT
TO authenticated
USING (true);

CREATE POLICY "Users can manage their own genres"
ON profile_genres FOR ALL
TO authenticated
USING (profile_id = auth.uid())
WITH CHECK (profile_id = auth.uid());

-- Políticas para portfolio_media
CREATE POLICY "Anyone can view portfolio media"
ON portfolio_media FOR SELECT
TO authenticated
USING (true);

CREATE POLICY "Users can manage their own portfolio"
ON portfolio_media FOR ALL
TO authenticated
USING (profile_id = auth.uid())
WITH CHECK (profile_id = auth.uid());

-- ═══════════════════════════════════════════════════════════════════════════════
-- PARTE 7: ACTUALIZAR PERFILES EXISTENTES
-- ═══════════════════════════════════════════════════════════════════════════════

-- Actualizar profile_completion para todos los perfiles existentes
UPDATE profiles SET profile_completion = calculate_profile_completion(id);

-- ═══════════════════════════════════════════════════════════════════════════════
-- PARTE 8: VERIFICACIÓN
-- ═══════════════════════════════════════════════════════════════════════════════

-- Verificar que todas las tablas existen
DO $$
BEGIN
  ASSERT (SELECT COUNT(*) FROM information_schema.tables WHERE table_name = 'event_invitations') = 1, 
    'Tabla event_invitations no fue creada';
  ASSERT (SELECT COUNT(*) FROM information_schema.tables WHERE table_name = 'genres') = 1, 
    'Tabla genres no fue creada';
  ASSERT (SELECT COUNT(*) FROM information_schema.tables WHERE table_name = 'profile_genres') = 1, 
    'Tabla profile_genres no fue creada';
  ASSERT (SELECT COUNT(*) FROM information_schema.tables WHERE table_name = 'portfolio_media') = 1, 
    'Tabla portfolio_media no fue creada';
  
  RAISE NOTICE '✅ Todas las tablas fueron creadas exitosamente';
END $$;

-- Verificar que todas las columnas existen
DO $$
BEGIN
  ASSERT (SELECT COUNT(*) FROM information_schema.columns 
    WHERE table_name = 'mensajes' AND column_name = 'delivered_at') = 1,
    'Columna mensajes.delivered_at no fue creada';
  ASSERT (SELECT COUNT(*) FROM information_schema.columns 
    WHERE table_name = 'mensajes' AND column_name = 'read_at') = 1,
    'Columna mensajes.read_at no fue creada';
  ASSERT (SELECT COUNT(*) FROM information_schema.columns 
    WHERE table_name = 'mensajes' AND column_name = 'media_url') = 1,
    'Columna mensajes.media_url no fue creada';
  ASSERT (SELECT COUNT(*) FROM information_schema.columns 
    WHERE table_name = 'mensajes' AND column_name = 'media_type') = 1,
    'Columna mensajes.media_type no fue creada';
    
  ASSERT (SELECT COUNT(*) FROM information_schema.columns 
    WHERE table_name = 'profiles' AND column_name = 'years_experience') = 1,
    'Columna profiles.years_experience no fue creada';
  ASSERT (SELECT COUNT(*) FROM information_schema.columns 
    WHERE table_name = 'profiles' AND column_name = 'availability') = 1,
    'Columna profiles.availability no fue creada';
  ASSERT (SELECT COUNT(*) FROM information_schema.columns 
    WHERE table_name = 'profiles' AND column_name = 'base_rate') = 1,
    'Columna profiles.base_rate no fue creada';
  ASSERT (SELECT COUNT(*) FROM information_schema.columns 
    WHERE table_name = 'profiles' AND column_name = 'currency') = 1,
    'Columna profiles.currency no fue creada';
  ASSERT (SELECT COUNT(*) FROM information_schema.columns 
    WHERE table_name = 'profiles' AND column_name = 'social_links') = 1,
    'Columna profiles.social_links no fue creada';
  ASSERT (SELECT COUNT(*) FROM information_schema.columns 
    WHERE table_name = 'profiles' AND column_name = 'profile_completion') = 1,
    'Columna profiles.profile_completion no fue creada';
  
  RAISE NOTICE '✅ Todas las columnas fueron creadas exitosamente';
END $$;

-- Verificar que los géneros fueron insertados
DO $$
DECLARE
  genre_count INTEGER;
BEGIN
  SELECT COUNT(*) INTO genre_count FROM genres;
  ASSERT genre_count >= 20, 'No se insertaron suficientes géneros musicales';
  RAISE NOTICE '✅ % géneros musicales insertados', genre_count;
END $$;

-- ═══════════════════════════════════════════════════════════════════════════════
-- RESUMEN DE MIGRACIÓN
-- ═══════════════════════════════════════════════════════════════════════════════

DO $$
BEGIN
  RAISE NOTICE '';
  RAISE NOTICE '═══════════════════════════════════════════════════════════════';
  RAISE NOTICE '✅ MIGRACIÓN COMPLETADA EXITOSAMENTE';
  RAISE NOTICE '═══════════════════════════════════════════════════════════════';
  RAISE NOTICE '';
  RAISE NOTICE 'Tablas creadas:';
  RAISE NOTICE '  • event_invitations';
  RAISE NOTICE '  • genres';
  RAISE NOTICE '  • profile_genres';
  RAISE NOTICE '  • portfolio_media';
  RAISE NOTICE '';
  RAISE NOTICE 'Columnas agregadas a mensajes:';
  RAISE NOTICE '  • delivered_at';
  RAISE NOTICE '  • read_at';
  RAISE NOTICE '  • media_url';
  RAISE NOTICE '  • media_type';
  RAISE NOTICE '';
  RAISE NOTICE 'Columnas agregadas a profiles:';
  RAISE NOTICE '  • years_experience';
  RAISE NOTICE '  • availability';
  RAISE NOTICE '  • base_rate';
  RAISE NOTICE '  • currency';
  RAISE NOTICE '  • social_links';
  RAISE NOTICE '  • profile_completion';
  RAISE NOTICE '';
  RAISE NOTICE 'Funciones creadas:';
  RAISE NOTICE '  • calculate_profile_completion()';
  RAISE NOTICE '  • update_profile_completion()';
  RAISE NOTICE '';
  RAISE NOTICE 'Políticas de seguridad (RLS) configuradas';
  RAISE NOTICE '';
  RAISE NOTICE '═══════════════════════════════════════════════════════════════';
END $$;
