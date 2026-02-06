-- ============================================
-- FASE 3 - DÍA 8: INFORMACIÓN MUSICAL
-- Script para agregar campos de información musical a profiles
-- Fecha: 30 de Enero, 2026
-- ============================================

-- 1. AGREGAR COLUMNAS A LA TABLA PROFILES
-- ============================================

-- Géneros musicales (array para múltiples géneros)
ALTER TABLE profiles 
ADD COLUMN IF NOT EXISTS generos_musicales TEXT[] DEFAULT '{}';

-- Años de experiencia
ALTER TABLE profiles 
ADD COLUMN IF NOT EXISTS anos_experiencia INTEGER DEFAULT 0;

-- Nivel de habilidad (principiante, intermedio, avanzado, profesional)
ALTER TABLE profiles 
ADD COLUMN IF NOT EXISTS nivel_habilidad TEXT DEFAULT 'principiante'
CHECK (nivel_habilidad IN ('principiante', 'intermedio', 'avanzado', 'profesional'));

-- Idiomas que habla (array para múltiples idiomas)
ALTER TABLE profiles 
ADD COLUMN IF NOT EXISTS idiomas TEXT[] DEFAULT '{}';

-- 2. CREAR ÍNDICES PARA BÚSQUEDA EFICIENTE
-- ============================================

-- Índice GIN para búsqueda en array de géneros musicales
CREATE INDEX IF NOT EXISTS idx_profiles_generos_musicales 
ON profiles USING GIN (generos_musicales);

-- Índice para nivel de habilidad
CREATE INDEX IF NOT EXISTS idx_profiles_nivel_habilidad 
ON profiles (nivel_habilidad);

-- Índice GIN para búsqueda en array de idiomas
CREATE INDEX IF NOT EXISTS idx_profiles_idiomas 
ON profiles USING GIN (idiomas);

-- Índice para años de experiencia (útil para filtros)
CREATE INDEX IF NOT EXISTS idx_profiles_anos_experiencia 
ON profiles (anos_experiencia);

-- 3. ACTUALIZAR VISTA DE PARTICIPANTES DE EVENTOS
-- ============================================

-- Actualizar la vista para incluir los nuevos campos
DROP VIEW IF EXISTS event_participants_with_profiles CASCADE;

CREATE OR REPLACE VIEW event_participants_with_profiles AS
SELECT
  ep.id,
  ep.event_id,
  ep.user_id,
  ep.role,
  ep.confirmed,
  ep.created_at,
  p.nombre_artistico,
  p.avatar_url,
  p.instrumento_principal,
  p.ubicacion,
  p.rating_promedio,
  p.total_calificaciones,
  p.generos_musicales,
  p.anos_experiencia,
  p.nivel_habilidad,
  p.idiomas
FROM event_participants ep
JOIN profiles p ON ep.user_id = p.id;

-- 4. FUNCIÓN PARA BÚSQUEDA AVANZADA DE MÚSICOS
-- ============================================

CREATE OR REPLACE FUNCTION search_musicians_advanced(
  search_text TEXT DEFAULT NULL,
  filter_instrument TEXT DEFAULT NULL,
  filter_genre TEXT DEFAULT NULL,
  filter_skill_level TEXT DEFAULT NULL,
  filter_min_experience INTEGER DEFAULT NULL,
  filter_language TEXT DEFAULT NULL,
  exclude_user_ids UUID[] DEFAULT '{}'::UUID[],
  result_limit INTEGER DEFAULT 50
)
RETURNS TABLE (
  id UUID,
  nombre_artistico TEXT,
  avatar_url TEXT,
  ubicacion TEXT,
  instrumento_principal TEXT,
  generos_musicales TEXT[],
  anos_experiencia INTEGER,
  nivel_habilidad TEXT,
  idiomas TEXT[],
  rating_promedio NUMERIC,
  total_calificaciones INTEGER
)
LANGUAGE plpgsql
AS $$
BEGIN
  RETURN QUERY
  SELECT
    p.id,
    p.nombre_artistico,
    p.avatar_url,
    p.ubicacion,
    p.instrumento_principal,
    p.generos_musicales,
    p.anos_experiencia,
    p.nivel_habilidad,
    p.idiomas,
    p.rating_promedio,
    p.total_calificaciones
  FROM profiles p
  WHERE
    -- Excluir usuarios específicos
    (exclude_user_ids IS NULL OR p.id != ALL(exclude_user_ids))
    -- Búsqueda por texto (nombre o ubicación)
    AND (
      search_text IS NULL 
      OR p.nombre_artistico ILIKE '%' || search_text || '%'
      OR p.ubicacion ILIKE '%' || search_text || '%'
    )
    -- Filtro por instrumento
    AND (filter_instrument IS NULL OR p.instrumento_principal = filter_instrument)
    -- Filtro por género musical (array contains)
    AND (filter_genre IS NULL OR filter_genre = ANY(p.generos_musicales))
    -- Filtro por nivel de habilidad
    AND (filter_skill_level IS NULL OR p.nivel_habilidad = filter_skill_level)
    -- Filtro por experiencia mínima
    AND (filter_min_experience IS NULL OR p.anos_experiencia >= filter_min_experience)
    -- Filtro por idioma (array contains)
    AND (filter_language IS NULL OR filter_language = ANY(p.idiomas))
  ORDER BY p.rating_promedio DESC NULLS LAST, p.total_calificaciones DESC
  LIMIT result_limit;
END;
$$;

-- 5. FUNCIÓN PARA OBTENER ESTADÍSTICAS DE GÉNEROS
-- ============================================

CREATE OR REPLACE FUNCTION get_genre_statistics()
RETURNS TABLE (
  genero TEXT,
  total_musicos BIGINT
)
LANGUAGE sql
AS $$
  SELECT 
    unnest(generos_musicales) as genero,
    COUNT(*) as total_musicos
  FROM profiles
  WHERE generos_musicales IS NOT NULL AND array_length(generos_musicales, 1) > 0
  GROUP BY genero
  ORDER BY total_musicos DESC;
$$;

-- 6. FUNCIÓN PARA OBTENER ESTADÍSTICAS DE NIVEL
-- ============================================

CREATE OR REPLACE FUNCTION get_skill_level_statistics()
RETURNS TABLE (
  nivel TEXT,
  total_musicos BIGINT,
  experiencia_promedio NUMERIC
)
LANGUAGE sql
AS $$
  SELECT 
    nivel_habilidad as nivel,
    COUNT(*) as total_musicos,
    ROUND(AVG(anos_experiencia), 1) as experiencia_promedio
  FROM profiles
  WHERE nivel_habilidad IS NOT NULL
  GROUP BY nivel_habilidad
  ORDER BY 
    CASE nivel_habilidad
      WHEN 'principiante' THEN 1
      WHEN 'intermedio' THEN 2
      WHEN 'avanzado' THEN 3
      WHEN 'profesional' THEN 4
    END;
$$;

-- 7. COMENTARIOS EN LAS COLUMNAS
-- ============================================

COMMENT ON COLUMN profiles.generos_musicales IS 'Array de géneros musicales que toca el músico';
COMMENT ON COLUMN profiles.anos_experiencia IS 'Años de experiencia musical';
COMMENT ON COLUMN profiles.nivel_habilidad IS 'Nivel de habilidad: principiante, intermedio, avanzado, profesional';
COMMENT ON COLUMN profiles.idiomas IS 'Array de idiomas que habla el músico';

-- ============================================
-- FIN DEL SCRIPT
-- ============================================

-- VERIFICACIÓN:
-- SELECT column_name, data_type, column_default 
-- FROM information_schema.columns 
-- WHERE table_name = 'profiles' 
-- AND column_name IN ('generos_musicales', 'anos_experiencia', 'nivel_habilidad', 'idiomas');
