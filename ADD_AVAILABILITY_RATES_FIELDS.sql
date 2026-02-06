-- ============================================
-- FASE 3 - DÍA 9: DISPONIBILIDAD Y TARIFAS
-- Script para agregar campos de disponibilidad y tarifas a profiles
-- Fecha: 30 de Enero, 2026
-- ============================================

-- 1. AGREGAR COLUMNAS A LA TABLA PROFILES
-- ============================================

-- Disponibilidad semanal (JSON con días y horarios)
ALTER TABLE profiles 
ADD COLUMN IF NOT EXISTS disponibilidad_semanal JSONB DEFAULT '{}'::jsonb;

-- Tarifa base por hora (opcional, solo para eventos pagados)
ALTER TABLE profiles 
ADD COLUMN IF NOT EXISTS tarifa_base NUMERIC(10,2) DEFAULT NULL;

-- Tarifa mínima (opcional)
ALTER TABLE profiles 
ADD COLUMN IF NOT EXISTS tarifa_minima NUMERIC(10,2) DEFAULT NULL;

-- Tarifa máxima (opcional)
ALTER TABLE profiles 
ADD COLUMN IF NOT EXISTS tarifa_maxima NUMERIC(10,2) DEFAULT NULL;

-- Moneda (MXN, USD, EUR, etc.)
ALTER TABLE profiles 
ADD COLUMN IF NOT EXISTS moneda TEXT DEFAULT 'MXN';

-- Tipos de eventos que acepta (array)
ALTER TABLE profiles 
ADD COLUMN IF NOT EXISTS tipos_eventos_acepta TEXT[] DEFAULT '{}';

-- Disponible para eventos pagados
ALTER TABLE profiles 
ADD COLUMN IF NOT EXISTS acepta_eventos_pagados BOOLEAN DEFAULT true;

-- Disponible para eventos de práctica/jam
ALTER TABLE profiles 
ADD COLUMN IF NOT EXISTS acepta_eventos_practica BOOLEAN DEFAULT true;

-- Notas adicionales sobre disponibilidad
ALTER TABLE profiles 
ADD COLUMN IF NOT EXISTS notas_disponibilidad TEXT DEFAULT NULL;

-- 2. CREAR ÍNDICES
-- ============================================

-- Índice GIN para búsqueda en disponibilidad_semanal (JSONB)
CREATE INDEX IF NOT EXISTS idx_profiles_disponibilidad_semanal 
ON profiles USING GIN (disponibilidad_semanal);

-- Índice para tarifa_base (útil para filtros de rango)
CREATE INDEX IF NOT EXISTS idx_profiles_tarifa_base 
ON profiles (tarifa_base) WHERE tarifa_base IS NOT NULL;

-- Índice GIN para tipos de eventos
CREATE INDEX IF NOT EXISTS idx_profiles_tipos_eventos 
ON profiles USING GIN (tipos_eventos_acepta);

-- Índice para eventos pagados
CREATE INDEX IF NOT EXISTS idx_profiles_acepta_pagados 
ON profiles (acepta_eventos_pagados) WHERE acepta_eventos_pagados = true;

-- Índice para eventos de práctica
CREATE INDEX IF NOT EXISTS idx_profiles_acepta_practica 
ON profiles (acepta_eventos_practica) WHERE acepta_eventos_practica = true;

-- 3. FUNCIÓN PARA BÚSQUEDA POR DISPONIBILIDAD
-- ============================================

CREATE OR REPLACE FUNCTION search_by_availability(
  dia_semana TEXT DEFAULT NULL,
  hora_inicio TIME DEFAULT NULL,
  hora_fin TIME DEFAULT NULL,
  tipo_evento TEXT DEFAULT NULL,
  tarifa_max NUMERIC DEFAULT NULL,
  solo_eventos_pagados BOOLEAN DEFAULT NULL,
  solo_eventos_practica BOOLEAN DEFAULT NULL,
  result_limit INTEGER DEFAULT 50
)
RETURNS TABLE (
  id UUID,
  nombre_artistico TEXT,
  avatar_url TEXT,
  ubicacion TEXT,
  instrumento_principal TEXT,
  tarifa_base NUMERIC,
  tarifa_minima NUMERIC,
  tarifa_maxima NUMERIC,
  moneda TEXT,
  tipos_eventos_acepta TEXT[],
  acepta_eventos_pagados BOOLEAN,
  acepta_eventos_practica BOOLEAN,
  disponibilidad_semanal JSONB,
  rating_promedio NUMERIC
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
    p.tarifa_base,
    p.tarifa_minima,
    p.tarifa_maxima,
    p.moneda,
    p.tipos_eventos_acepta,
    p.acepta_eventos_pagados,
    p.acepta_eventos_practica,
    p.disponibilidad_semanal,
    p.rating_promedio
  FROM profiles p
  WHERE
    -- Filtro por tipo de evento (pagado o práctica)
    (solo_eventos_pagados IS NULL OR p.acepta_eventos_pagados = solo_eventos_pagados)
    AND (solo_eventos_practica IS NULL OR p.acepta_eventos_practica = solo_eventos_practica)
    -- Filtro por tipo de evento específico
    AND (tipo_evento IS NULL OR tipo_evento = ANY(p.tipos_eventos_acepta))
    -- Filtro por tarifa máxima (solo si se especifica)
    AND (tarifa_max IS NULL OR p.tarifa_base IS NULL OR p.tarifa_base <= tarifa_max)
  ORDER BY p.rating_promedio DESC NULLS LAST
  LIMIT result_limit;
END;
$$;

-- 4. FUNCIÓN PARA VERIFICAR DISPONIBILIDAD EN DÍA/HORA
-- ============================================

CREATE OR REPLACE FUNCTION check_availability(
  user_id_param UUID,
  dia_semana TEXT,
  hora_inicio TIME,
  hora_fin TIME
)
RETURNS BOOLEAN
LANGUAGE plpgsql
AS $$
DECLARE
  disponibilidad JSONB;
  dia_disponible BOOLEAN;
BEGIN
  -- Obtener disponibilidad del usuario
  SELECT disponibilidad_semanal INTO disponibilidad
  FROM profiles
  WHERE id = user_id_param;
  
  -- Si no tiene disponibilidad configurada, retornar false
  IF disponibilidad IS NULL OR disponibilidad = '{}'::jsonb THEN
    RETURN false;
  END IF;
  
  -- Verificar si el día está disponible
  dia_disponible := (disponibilidad->dia_semana->>'disponible')::boolean;
  
  IF dia_disponible IS NULL OR dia_disponible = false THEN
    RETURN false;
  END IF;
  
  -- TODO: Aquí se podría agregar lógica más compleja para verificar rangos de horas
  -- Por ahora, si el día está disponible, retornamos true
  
  RETURN true;
END;
$$;

-- 5. FUNCIÓN PARA OBTENER ESTADÍSTICAS DE TARIFAS
-- ============================================

CREATE OR REPLACE FUNCTION get_rate_statistics()
RETURNS TABLE (
  moneda TEXT,
  tarifa_promedio NUMERIC,
  tarifa_minima_global NUMERIC,
  tarifa_maxima_global NUMERIC,
  total_musicos BIGINT
)
LANGUAGE sql
AS $$
  SELECT 
    p.moneda,
    ROUND(AVG(p.tarifa_base), 2) as tarifa_promedio,
    MIN(p.tarifa_base) as tarifa_minima_global,
    MAX(p.tarifa_base) as tarifa_maxima_global,
    COUNT(*) as total_musicos
  FROM profiles p
  WHERE p.tarifa_base IS NOT NULL AND p.tarifa_base > 0
  GROUP BY p.moneda
  ORDER BY total_musicos DESC;
$$;

-- 6. FUNCIÓN PARA OBTENER MÚSICOS DISPONIBLES HOY
-- ============================================

CREATE OR REPLACE FUNCTION get_available_today()
RETURNS TABLE (
  id UUID,
  nombre_artistico TEXT,
  avatar_url TEXT,
  instrumento_principal TEXT,
  ubicacion TEXT,
  tarifa_base NUMERIC,
  moneda TEXT,
  rating_promedio NUMERIC
)
LANGUAGE plpgsql
AS $$
DECLARE
  dia_actual TEXT;
BEGIN
  -- Obtener día actual en español
  dia_actual := CASE EXTRACT(DOW FROM CURRENT_DATE)
    WHEN 0 THEN 'domingo'
    WHEN 1 THEN 'lunes'
    WHEN 2 THEN 'martes'
    WHEN 3 THEN 'miercoles'
    WHEN 4 THEN 'jueves'
    WHEN 5 THEN 'viernes'
    WHEN 6 THEN 'sabado'
  END;
  
  RETURN QUERY
  SELECT
    p.id,
    p.nombre_artistico,
    p.avatar_url,
    p.instrumento_principal,
    p.ubicacion,
    p.tarifa_base,
    p.moneda,
    p.rating_promedio
  FROM profiles p
  WHERE 
    p.disponibilidad_semanal IS NOT NULL
    AND p.disponibilidad_semanal != '{}'::jsonb
    AND (p.disponibilidad_semanal->dia_actual->>'disponible')::boolean = true
  ORDER BY p.rating_promedio DESC NULLS LAST
  LIMIT 50;
END;
$$;

-- 7. COMENTARIOS EN LAS COLUMNAS
-- ============================================

COMMENT ON COLUMN profiles.disponibilidad_semanal IS 'Disponibilidad semanal en formato JSON: {lunes: {disponible: true, horarios: [{inicio: "09:00", fin: "18:00"}]}}';
COMMENT ON COLUMN profiles.tarifa_base IS 'Tarifa base por hora en la moneda especificada (opcional, solo para eventos pagados)';
COMMENT ON COLUMN profiles.tarifa_minima IS 'Tarifa mínima que acepta (opcional)';
COMMENT ON COLUMN profiles.tarifa_maxima IS 'Tarifa máxima que cobra (opcional)';
COMMENT ON COLUMN profiles.moneda IS 'Moneda para las tarifas (MXN, USD, EUR, etc.)';
COMMENT ON COLUMN profiles.tipos_eventos_acepta IS 'Tipos de eventos que acepta: concierto, ensayo, jam, sesion_estudio, boda, corporativo, etc.';
COMMENT ON COLUMN profiles.acepta_eventos_pagados IS 'Si acepta eventos pagados/contrataciones';
COMMENT ON COLUMN profiles.acepta_eventos_practica IS 'Si acepta eventos de práctica/jam sessions sin pago';
COMMENT ON COLUMN profiles.notas_disponibilidad IS 'Notas adicionales sobre disponibilidad y condiciones';

-- ============================================
-- FIN DEL SCRIPT
-- ============================================

-- VERIFICACIÓN:
-- SELECT column_name, data_type, column_default 
-- FROM information_schema.columns 
-- WHERE table_name = 'profiles' 
-- AND column_name IN ('disponibilidad_semanal', 'tarifa_base', 'tipos_eventos_acepta', 'acepta_eventos_pagados', 'acepta_eventos_practica');
