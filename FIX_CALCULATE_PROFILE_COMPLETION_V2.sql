-- ============================================
-- FIX V2: Corregir función calculate_profile_completion
-- Error: jsonb_object_keys() retorna un SET, no se puede usar en AND
-- Fecha: 30 de Enero, 2026
-- ============================================

-- Eliminar función existente
DROP FUNCTION IF EXISTS calculate_profile_completion(uuid);

-- Recrear función con lógica corregida para redes sociales
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

-- Verificar que la función se creó correctamente
SELECT 
  routine_name, 
  routine_type,
  data_type as return_type
FROM information_schema.routines 
WHERE routine_name = 'calculate_profile_completion';

-- Comentario en la función
COMMENT ON FUNCTION calculate_profile_completion(UUID) IS 
'Calcula el porcentaje de completitud del perfil (0-100) evaluando 20 campos: 7 básicos, 4 musicales, 5 de disponibilidad/tarifas, y 4 de redes sociales';

-- ============================================
-- FIN DEL SCRIPT
-- ============================================
