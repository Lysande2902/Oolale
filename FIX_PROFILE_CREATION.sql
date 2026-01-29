-- ========================================================
-- FIX: Crear perfiles automáticamente y arreglar usuarios existentes
-- ========================================================

-- 1. CREAR/ACTUALIZAR LA FUNCIÓN del trigger
CREATE OR REPLACE FUNCTION public.handle_new_user() 
RETURNS TRIGGER AS $$
BEGIN
  INSERT INTO public.profiles (id, email, nombre_artistico)
  VALUES (
    new.id, 
    new.email, 
    COALESCE(new.raw_user_meta_data->>'full_name', SPLIT_PART(new.email, '@', 1))
  );
  RETURN new;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- 2. CREAR EL TRIGGER para usuarios nuevos
DROP TRIGGER IF EXISTS on_auth_user_created ON auth.users;

CREATE TRIGGER on_auth_user_created
  AFTER INSERT ON auth.users
  FOR EACH ROW EXECUTE FUNCTION public.handle_new_user();

-- 2. CREAR PERFILES para usuarios que no tienen perfil
-- Esto arregla los usuarios que ya se registraron pero no tienen perfil

INSERT INTO public.profiles (id, email, nombre_artistico)
SELECT 
  u.id,
  u.email,
  COALESCE(u.raw_user_meta_data->>'full_name', SPLIT_PART(u.email, '@', 1))
FROM auth.users u
LEFT JOIN public.profiles p ON u.id = p.id
WHERE p.id IS NULL;

-- 3. VERIFICAR que todos los usuarios tengan perfil
SELECT 
  u.id as user_id,
  u.email,
  p.id as profile_id,
  p.nombre_artistico,
  CASE 
    WHEN p.id IS NULL THEN '❌ SIN PERFIL'
    ELSE '✅ PERFIL OK'
  END as status
FROM auth.users u
LEFT JOIN public.profiles p ON u.id = p.id
ORDER BY u.created_at DESC
LIMIT 20;
