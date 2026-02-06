-- ============================================
-- FASE 3 - DÍA 10: REDES SOCIALES Y COMPLETITUD
-- Script para agregar campos de redes sociales y completitud a profiles
-- Fecha: 30 de Enero, 2026
-- ============================================

-- 1. AGREGAR COLUMNAS A LA TABLA PROFILES
-- ============================================

-- Links a redes sociales (JSONB con URLs)
ALTER TABLE profiles 
ADD COLUMN IF NOT EXISTS redes_sociales JSONB DEFAULT '{}'::jsonb;

-- Porcentaje de completitud del perfil (0-100)
ALTER TABLE profiles 
ADD COLUMN IF NOT EXISTS completitud_perfil INTEGER DEFAULT 0;

-- Fecha de última actualización del perfil
ALTER TABLE profiles 
ADD COLUMN IF NOT EXISTS ultima_actualizacion TIMESTAMP WITH TIME ZONE DEFAULT NOW();

-- 2. CREAR ÍNDICES
-- ============================================

-- Índice GIN para búsqueda en redes_sociales (JSONB)
CREATE INDEX IF NOT EXISTS idx_profiles_redes_sociales 
ON profiles USING GIN (redes_sociales);

-- Índice para completitud_perfil (útil para filtros y ordenamiento)
CREATE INDEX IF NOT EXISTS idx_profiles_completitud 
ON profiles (completitud_perfil DESC);

-- Índice para ultima_actualizacion (útil para ordenar por recientes)
CREATE INDEX IF NOT EXISTS idx_profiles_ultima_actualizacion 
ON profiles (ultima_actualizacion DESC);

-- 3. FUNCIÓN PARA CALCULAR COMPLETITUD DE PERFIL
-- ============================================

CREATE OR REPLACE FUNCTION calculate_profile_completion(user_id_param UUID)
RETURNS INTEGER
LANGUAGE plpgsql
AS $$
DECLARE
  completion_score INTEGER := 0;
  total_fields INTEGER := 20; -- Total de campos importantes
  profile_data RECORD;
  redes_count INTEGER := 0;
BEGIN
  -- Obtener datos del perfil
  SELECT * INTO profile_data
  FROM profiles
  WHERE id = user_id_param;
  
  IF NOT FOUND THEN
    RETURN 0;
  END IF;
  
  -- Campos básicos (7 campos)
  IF profile_data.nombre_artistico IS NOT NULL AND profile_data.nombre_artistico != '' THEN
    completion_score := completion_score + 1;
  END IF;
  
  IF profile_data.avatar_url IS NOT NULL AND profile_data.avatar_url != '' THEN
    completion_score := completion_score + 1;
  END IF;
  
  IF profile_data.bio IS NOT NULL AND profile_data.bio != '' THEN
    completion_score := completion_score + 1;
  END IF;
  
  IF profile_data.instrumento_principal IS NOT NULL AND profile_data.instrumento_principal != '' THEN
    completion_score := completion_score + 1;
  END IF;
  
  IF profile_data.ubicacion IS NOT NULL AND profile_data.ubicacion != '' THEN
    completion_score := completion_score + 1;
  END IF;
  
  IF profile_data.pais IS NOT NULL AND profile_data.pais != '' THEN
    completion_score := completion_score + 1;
  END IF;
  
  IF profile_data.foto_perfil IS NOT NULL AND profile_data.foto_perfil != '' THEN
    completion_score := completion_score + 1;
  END IF;
  
  -- Información musical (4 campos)
  IF profile_data.generos_musicales IS NOT NULL AND array_length(profile_data.generos_musicales, 1) > 0 THEN
    completion_score := completion_score + 1;
  END IF;
  
  IF profile_data.anos_experiencia IS NOT NULL AND profile_data.anos_experiencia > 0 THEN
    completion_score := completion_score + 1;
  END IF;
  
  IF profile_data.nivel_habilidad IS NOT NULL AND profile_data.nivel_habilidad != '' THEN
    completion_score := completion_score + 1;
  END IF;
  
  IF profile_data.idiomas IS NOT NULL AND array_length(profile_data.idiomas, 1) > 0 THEN
    completion_score := completion_score + 1;
  END IF;
  
  -- Disponibilidad y tarifas (5 campos)
  IF profile_data.disponibilidad_semanal IS NOT NULL AND profile_data.disponibilidad_semanal != '{}'::jsonb THEN
    completion_score := completion_score + 1;
  END IF;
  
  IF profile_data.tarifa_base IS NOT NULL AND profile_data.tarifa_base > 0 THEN
    completion_score := completion_score + 1;
  END IF;
  
  IF profile_data.tipos_eventos_acepta IS NOT NULL AND array_length(profile_data.tipos_eventos_acepta, 1) > 0 THEN
    completion_score := completion_score + 1;
  END IF;
  
  IF profile_data.acepta_eventos_pagados IS NOT NULL THEN
    completion_score := completion_score + 1;
  END IF;
  
  IF profile_data.acepta_eventos_practica IS NOT NULL THEN
    completion_score := completion_score + 1;
  END IF;
  
  -- Redes sociales (4 campos - al menos 2 redes)
  -- CORRECCIÓN: Contar redes sociales de forma correcta
  IF profile_data.redes_sociales IS NOT NULL AND profile_data.redes_sociales != '{}'::jsonb THEN
    -- Contar cuántas redes tiene usando jsonb_object_keys correctamente
    SELECT COUNT(*) INTO redes_count
    FROM jsonb_object_keys(profile_data.redes_sociales);
    
    -- Asignar puntos según cantidad de redes
    IF redes_count >= 1 THEN
      completion_score := completion_score + 1;
    END IF;
    IF redes_count >= 2 THEN
      completion_score := completion_score + 1;
    END IF;
    IF redes_count >= 3 THEN
      completion_score := completion_score + 1;
    END IF;
    IF redes_count >= 4 THEN
      completion_score := completion_score + 1;
    END IF;
  END IF;
  
  -- Calcular porcentaje
  RETURN ROUND((completion_score::NUMERIC / total_fields::NUMERIC) * 100);
END;
$$;

-- 4. FUNCIÓN PARA ACTUALIZAR COMPLETITUD AUTOMÁTICAMENTE
-- ============================================

CREATE OR REPLACE FUNCTION update_profile_completion()
RETURNS TRIGGER
LANGUAGE plpgsql
AS $$
DECLARE
  new_completion INTEGER;
BEGIN
  -- Calcular nueva completitud
  new_completion := calculate_profile_completion(NEW.id);
  
  -- Actualizar completitud y fecha
  NEW.completitud_perfil := new_completion;
  NEW.ultima_actualizacion := NOW();
  
  RETURN NEW;
END;
$$;

-- 5. CREAR TRIGGER PARA ACTUALIZAR COMPLETITUD
-- ============================================

DROP TRIGGER IF EXISTS trigger_update_profile_completion ON profiles;

CREATE TRIGGER trigger_update_profile_completion
BEFORE UPDATE ON profiles
FOR EACH ROW
EXECUTE FUNCTION update_profile_completion();

-- 6. FUNCIÓN PARA OBTENER CAMPOS FALTANTES
-- ============================================

CREATE OR REPLACE FUNCTION get_missing_profile_fields(user_id_param UUID)
RETURNS TABLE (
  campo TEXT,
  categoria TEXT,
  prioridad TEXT
)
LANGUAGE plpgsql
AS $$
DECLARE
  profile_data RECORD;
BEGIN
  -- Obtener datos del perfil
  SELECT * INTO profile_data
  FROM profiles
  WHERE id = user_id_param;
  
  IF NOT FOUND THEN
    RETURN;
  END IF;
  
  -- Campos básicos (alta prioridad)
  IF profile_data.nombre_artistico IS NULL OR profile_data.nombre_artistico = '' THEN
    RETURN QUERY SELECT 'Nombre artístico'::TEXT, 'Básico'::TEXT, 'Alta'::TEXT;
  END IF;
  
  IF profile_data.avatar_url IS NULL OR profile_data.avatar_url = '' THEN
    RETURN QUERY SELECT 'Foto de perfil'::TEXT, 'Básico'::TEXT, 'Alta'::TEXT;
  END IF;
  
  IF profile_data.bio IS NULL OR profile_data.bio = '' THEN
    RETURN QUERY SELECT 'Biografía'::TEXT, 'Básico'::TEXT, 'Alta'::TEXT;
  END IF;
  
  IF profile_data.instrumento_principal IS NULL OR profile_data.instrumento_principal = '' THEN
    RETURN QUERY SELECT 'Instrumento principal'::TEXT, 'Básico'::TEXT, 'Alta'::TEXT;
  END IF;
  
  IF profile_data.ubicacion IS NULL OR profile_data.ubicacion = '' THEN
    RETURN QUERY SELECT 'Ubicación'::TEXT, 'Básico'::TEXT, 'Alta'::TEXT;
  END IF;
  
  IF profile_data.pais IS NULL OR profile_data.pais = '' THEN
    RETURN QUERY SELECT 'País'::TEXT, 'Básico'::TEXT, 'Alta'::TEXT;
  END IF;
  
  -- Información musical (media prioridad)
  IF profile_data.generos_musicales IS NULL OR array_length(profile_data.generos_musicales, 1) IS NULL THEN
    RETURN QUERY SELECT 'Géneros musicales'::TEXT, 'Musical'::TEXT, 'Media'::TEXT;
  END IF;
  
  IF profile_data.anos_experiencia IS NULL OR profile_data.anos_experiencia = 0 THEN
    RETURN QUERY SELECT 'Años de experiencia'::TEXT, 'Musical'::TEXT, 'Media'::TEXT;
  END IF;
  
  IF profile_data.nivel_habilidad IS NULL OR profile_data.nivel_habilidad = '' THEN
    RETURN QUERY SELECT 'Nivel de habilidad'::TEXT, 'Musical'::TEXT, 'Media'::TEXT;
  END IF;
  
  IF profile_data.idiomas IS NULL OR array_length(profile_data.idiomas, 1) IS NULL THEN
    RETURN QUERY SELECT 'Idiomas'::TEXT, 'Musical'::TEXT, 'Media'::TEXT;
  END IF;
  
  -- Disponibilidad (media prioridad)
  IF profile_data.disponibilidad_semanal IS NULL OR profile_data.disponibilidad_semanal = '{}'::jsonb THEN
    RETURN QUERY SELECT 'Disponibilidad semanal'::TEXT, 'Disponibilidad'::TEXT, 'Media'::TEXT;
  END IF;
  
  IF profile_data.tipos_eventos_acepta IS NULL OR array_length(profile_data.tipos_eventos_acepta, 1) IS NULL THEN
    RETURN QUERY SELECT 'Tipos de eventos'::TEXT, 'Disponibilidad'::TEXT, 'Media'::TEXT;
  END IF;
  
  -- Redes sociales (baja prioridad)
  IF profile_data.redes_sociales IS NULL OR profile_data.redes_sociales = '{}'::jsonb THEN
    RETURN QUERY SELECT 'Redes sociales'::TEXT, 'Redes'::TEXT, 'Baja'::TEXT;
  ELSIF (SELECT COUNT(*) FROM jsonb_object_keys(profile_data.redes_sociales)) < 2 THEN
    RETURN QUERY SELECT 'Más redes sociales (mínimo 2)'::TEXT, 'Redes'::TEXT, 'Baja'::TEXT;
  END IF;
  
  -- Tarifas (baja prioridad - opcional)
  IF profile_data.tarifa_base IS NULL OR profile_data.tarifa_base = 0 THEN
    RETURN QUERY SELECT 'Tarifa base (opcional)'::TEXT, 'Tarifas'::TEXT, 'Baja'::TEXT;
  END IF;
  
  RETURN;
END;
$$;

-- 7. FUNCIÓN PARA OBTENER PERFILES MÁS COMPLETOS
-- ============================================

CREATE OR REPLACE FUNCTION get_most_complete_profiles(result_limit INTEGER DEFAULT 50)
RETURNS TABLE (
  id UUID,
  nombre_artistico TEXT,
  avatar_url TEXT,
  ubicacion TEXT,
  instrumento_principal TEXT,
  completitud_perfil INTEGER,
  rating_promedio NUMERIC,
  ultima_actualizacion TIMESTAMP WITH TIME ZONE
)
LANGUAGE sql
AS $$
  SELECT 
    p.id,
    p.nombre_artistico,
    p.avatar_url,
    p.ubicacion,
    p.instrumento_principal,
    p.completitud_perfil,
    p.rating_promedio,
    p.ultima_actualizacion
  FROM profiles p
  WHERE p.completitud_perfil > 0
  ORDER BY p.completitud_perfil DESC, p.rating_promedio DESC NULLS LAST
  LIMIT result_limit;
$$;

-- 8. ACTUALIZAR COMPLETITUD DE TODOS LOS PERFILES EXISTENTES
-- ============================================

-- Actualizar completitud de todos los perfiles
UPDATE profiles
SET completitud_perfil = calculate_profile_completion(id),
    ultima_actualizacion = NOW();

-- 9. COMENTARIOS EN LAS COLUMNAS
-- ============================================

COMMENT ON COLUMN profiles.redes_sociales IS 'Links a redes sociales en formato JSON: {instagram: "url", youtube: "url", spotify: "url", etc.}';
COMMENT ON COLUMN profiles.completitud_perfil IS 'Porcentaje de completitud del perfil (0-100), calculado automáticamente';
COMMENT ON COLUMN profiles.ultima_actualizacion IS 'Fecha de última actualización del perfil';

-- ============================================
-- FIN DEL SCRIPT
-- ============================================

-- VERIFICACIÓN:
-- SELECT column_name, data_type, column_default 
-- FROM information_schema.columns 
-- WHERE table_name = 'profiles' 
-- AND column_name IN ('redes_sociales', 'completitud_perfil', 'ultima_actualizacion');

-- SELECT id, nombre_artistico, completitud_perfil FROM profiles ORDER BY completitud_perfil DESC LIMIT 10;
