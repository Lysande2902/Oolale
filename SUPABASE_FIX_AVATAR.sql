-- ========================================================
-- 🔧 CORRECCIÓN DE SCHEMA: COLUMNA AVATAR_URL
-- ========================================================

-- 1. Asegurar que la columna 'avatar_url' existe en la tabla profiles
ALTER TABLE public.profiles 
ADD COLUMN IF NOT EXISTS avatar_url TEXT;

-- 2. Asegurar otras columnas que podrían faltar según el error de caché
ALTER TABLE public.profiles 
ADD COLUMN IF NOT EXISTS nombre_artistico TEXT,
ADD COLUMN IF NOT EXISTS bio_rider TEXT,
ADD COLUMN IF NOT EXISTS ubicacion_base TEXT,
ADD COLUMN IF NOT EXISTS instrumento_principal TEXT;

-- 3. Forzar refresco del caché de PostgREST
-- Notificar a PostgREST que el esquema ha cambiado
NOTIFY pgrst, 'reload schema';

-- 4. Verificar que las columnas existan (para tu referencia en el editor)
DO $$
BEGIN
    RAISE NOTICE 'Verificando columnas en profiles...';
END $$;

SELECT column_name, data_type 
FROM information_schema.columns 
WHERE table_name = 'profiles'
AND column_name IN ('avatar_url', 'nombre_artistico', 'bio_rider', 'ubicacion_base', 'instrumento_principal');
