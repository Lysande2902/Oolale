-- ============================================================================
-- SCRIPT MAESTRO DE ACTUALIZACIÓN DE FUNCIONES Y TRIGGERS (CORREGIDO)
-- Descartar vista problemática antes de recrearla
-- ============================================================================

-- IMPORTANTE: Eliminamos la vista vieja ANTES de intentar recrearla
DROP VIEW IF EXISTS event_participants_with_profiles;

-- 1. ACTUALIZAR FUNCIÓN DE CREACIÓN DE USUARIO (handle_new_user)
CREATE OR REPLACE FUNCTION public.handle_new_user() 
RETURNS TRIGGER AS $$
BEGIN
  INSERT INTO public.perfiles (id, email, nombre_artistico)
  VALUES (
    new.id, 
    new.email, 
    COALESCE(new.raw_user_meta_data->>'full_name', SPLIT_PART(new.email, '@', 1))
  );
  RETURN new;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- 2. ACTUALIZAR TRIGGER DE CREACIÓN DE AJUSTES POR DEFECTO
CREATE OR REPLACE FUNCTION create_default_settings()
RETURNS TRIGGER AS $$
BEGIN
    -- Crear configuración de notificaciones por defecto
    INSERT INTO configuracion_notificaciones (user_id)
    VALUES (NEW.id)
    ON CONFLICT (user_id) DO NOTHING;
    
    -- Crear configuración de privacidad por defecto
    INSERT INTO configuracion_privacidad (user_id)
    VALUES (NEW.id)
    ON CONFLICT (user_id) DO NOTHING;
    
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

-- Recrear el trigger en la tabla nueva 'perfiles'
DROP TRIGGER IF EXISTS create_default_settings_on_profile ON perfiles;
CREATE TRIGGER create_default_settings_on_profile
    AFTER INSERT ON perfiles
    FOR EACH ROW
    EXECUTE FUNCTION create_default_settings();

-- 3. ACTUALIZAR FUNCIÓN DE SINCRONIZACIÓN DE LINEUP
CREATE OR REPLACE FUNCTION sync_event_lineup()
RETURNS TRIGGER AS $$
BEGIN
  IF NEW.confirmed = true THEN
    -- Agregar a lineup si no está
    UPDATE eventos
    SET lineup = ARRAY(
      SELECT DISTINCT unnest(
        COALESCE(lineup, ARRAY[]::UUID[]) || ARRAY[NEW.user_id]
      )
    )
    WHERE id = NEW.event_id
      AND NOT (NEW.user_id = ANY(COALESCE(lineup, ARRAY[]::UUID[])));
  ELSIF OLD.confirmed = true AND NEW.confirmed = false THEN
    -- Remover de lineup si canceló
    UPDATE eventos
    SET lineup = ARRAY(
      SELECT unnest(lineup)
      WHERE unnest(lineup) != NEW.user_id
    )
    WHERE id = NEW.event_id;
  END IF;
  
  RETURN NEW;
END;
$$ LANGUAGE plpgsql;

-- 4. ACTUALIZAR FUNCIÓN DE COMPLETITUD DE PERFIL
CREATE OR REPLACE FUNCTION calculate_profile_completion(user_id_param UUID)
RETURNS INTEGER
LANGUAGE plpgsql
AS $$
DECLARE
  completion_score INTEGER := 0;
  total_fields INTEGER := 20;
  profile_data RECORD;
  redes_count INTEGER := 0;
BEGIN
  -- Obtener datos del perfil
  SELECT * INTO profile_data
  FROM perfiles
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
  
  -- Redes sociales (4 campos)
  IF profile_data.redes_sociales IS NOT NULL AND profile_data.redes_sociales != '{}'::jsonb THEN
    SELECT COUNT(*) INTO redes_count
    FROM jsonb_object_keys(profile_data.redes_sociales);
    
    IF redes_count >= 1 THEN completion_score := completion_score + 1; END IF;
    IF redes_count >= 2 THEN completion_score := completion_score + 1; END IF;
    IF redes_count >= 3 THEN completion_score := completion_score + 1; END IF;
    IF redes_count >= 4 THEN completion_score := completion_score + 1; END IF;
  END IF;
  
  RETURN ROUND((completion_score::NUMERIC / total_fields::NUMERIC) * 100);
END;
$$;

-- 5. ACTUALIZAR FUNCIÓN DE POSTS ALEATORIOS
CREATE OR REPLACE FUNCTION get_random_posts(limit_count INTEGER DEFAULT 20)
RETURNS TABLE (
  id UUID,
  author_id UUID,
  content TEXT,
  media_url TEXT,
  media_type TEXT,
  likes_count INTEGER,
  created_at TIMESTAMPTZ,
  author JSONB
) 
LANGUAGE plpgsql
AS $$
BEGIN
  RETURN QUERY
  SELECT 
    p.id,
    p.author_id,
    p.content,
    p.media_url,
    p.media_type,
    p.likes_count,
    p.created_at,
    jsonb_build_object(
      'nombre_artistico', pr.nombre_artistico,
      'foto_perfil', pr.foto_perfil
    ) as author
  FROM publicaciones p
  INNER JOIN perfiles pr ON p.author_id = pr.id
  ORDER BY RANDOM()
  LIMIT limit_count;
END;
$$;

-- 6. ACTUALIZAR FUNCIONES DE PARTICIPANTES DE EVENTOS (Helpers)
CREATE OR REPLACE FUNCTION get_event_participant_stats(p_event_id BIGINT)
RETURNS TABLE (
  total_participants BIGINT,
  confirmed_participants BIGINT,
  headliners BIGINT,
  supports BIGINT,
  guests BIGINT,
  crew BIGINT,
  participants BIGINT
) AS $$
BEGIN
  RETURN QUERY
  SELECT
    COUNT(*)::BIGINT as total_participants,
    COUNT(*) FILTER (WHERE confirmed = true)::BIGINT as confirmed_participants,
    COUNT(*) FILTER (WHERE role = 'headliner')::BIGINT as headliners,
    COUNT(*) FILTER (WHERE role = 'support')::BIGINT as supports,
    COUNT(*) FILTER (WHERE role = 'guest')::BIGINT as guests,
    COUNT(*) FILTER (WHERE role = 'crew')::BIGINT as crew,
    COUNT(*) FILTER (WHERE role = 'participant' OR role IS NULL)::BIGINT as participants
  FROM participantes_evento
  WHERE event_id = p_event_id;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- 7. RECREAR VISTA DE PARTICIPANTES (AHORA SÍ FUNCIONARÁ)
CREATE OR REPLACE VIEW event_participants_with_profiles AS
SELECT
  ep.id,
  ep.event_id,
  ep.user_id,
  ep.confirmed,
  ep.role,
  ep.created_at,
  ep.updated_at,
  p.nombre_artistico,
  p.avatar_url,
  p.instrumento_principal,
  p.ubicacion,
  g.titulo_bolo as event_title,
  g.fecha_gig as event_date
FROM participantes_evento ep
JOIN perfiles p ON ep.user_id = p.id
JOIN eventos g ON ep.event_id = g.id;
