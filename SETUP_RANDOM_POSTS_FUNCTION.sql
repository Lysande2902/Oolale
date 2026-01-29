-- Función para obtener posts aleatorios
-- Ejecuta esto en Supabase SQL Editor

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
  FROM posts p
  INNER JOIN profiles pr ON p.author_id = pr.id
  ORDER BY RANDOM()
  LIMIT limit_count;
END;
$$;

-- Dar permisos de ejecución
GRANT EXECUTE ON FUNCTION get_random_posts(INTEGER) TO authenticated;
GRANT EXECUTE ON FUNCTION get_random_posts(INTEGER) TO anon;
