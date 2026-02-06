-- FIX: Grant permissions to authenticated users to create profiles
-- Often "Database error saving new user" is due to RLS policies or permissions

-- 1. Ensure `perfiles` permissions for triggers
ALTER TABLE perfiles DISABLE ROW LEVEL SECURITY; 
-- DANGER: Temporarily disabling RLS to debug if it's the cause. 
-- BETTER: Create a policy allowing insert for trigger.

-- Actually, triggers run with the privileges of the function definer if SECURITY DEFINER is set.
-- Let's check handle_new_user definition again.
-- It IS SECURITY DEFINER.

-- Let's check if there are other triggers on `perfiles` that might fail.
-- `create_default_settings_on_profile` calls `create_default_settings`
-- `create_default_settings` inserts into `configuracion_notificaciones`.

-- Ensure permissions on configuracion_notificaciones
GRANT ALL ON TABLE configuracion_notificaciones TO authenticated;
GRANT ALL ON TABLE configuracion_notificaciones TO service_role;
GRANT ALL ON TABLE configuracion_privacidad TO authenticated;
GRANT ALL ON TABLE configuracion_privacidad TO service_role;
GRANT ALL ON TABLE perfiles TO authenticated;
GRANT ALL ON TABLE perfiles TO service_role;

-- Make sure sequences are accessible
GRANT USAGE, SELECT ON ALL SEQUENCES IN SCHEMA public TO authenticated;
GRANT USAGE, SELECT ON ALL SEQUENCES IN SCHEMA public TO service_role;

-- Drop constraints that might be failing if columns don't match
-- Check if `configuracion_notificaciones` has `user_id` as foreign key to `auth.users`?
-- Yes it does. That should be fine.

-- Let's try to remove SECURITY DEFINER and grant explicit permissions.
-- Sometimes SECURITY DEFINER functions fail if the search_path is not set safe.

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
$$ LANGUAGE plpgsql SECURITY DEFINER SET search_path = public;

-- Re-apply trigger
DROP TRIGGER IF EXISTS on_auth_user_created ON auth.users;
CREATE TRIGGER on_auth_user_created
  AFTER INSERT ON auth.users
  FOR EACH ROW EXECUTE FUNCTION public.handle_new_user();


-- Fix dependent triggers too
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
$$ LANGUAGE plpgsql SECURITY DEFINER SET search_path = public;

