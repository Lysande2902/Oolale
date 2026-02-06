-- Asegurar que la tabla de notificaciones existe con el nombre correcto y estructura esperada
-- Ejecutar este script si recibes el error "Could not find the table 'public.notificaciones'"

-- 1. Si existe 'notifications', renombrarla
DO $$ 
BEGIN
    IF EXISTS (SELECT FROM pg_tables WHERE schemaname = 'public' AND tablename = 'notifications') THEN
        ALTER TABLE public.notifications RENAME TO notificaciones;
    END IF;
END $$;

-- 2. Si no existe la tabla ni con nombre viejo ni nuevo, crearla
CREATE TABLE IF NOT EXISTS public.notificaciones (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    user_id UUID REFERENCES auth.users(id) ON DELETE CASCADE,
    tipo TEXT NOT NULL,
    titulo TEXT,
    mensaje TEXT,
    data JSONB DEFAULT '{}'::jsonb,
    leido BOOLEAN DEFAULT false,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- 3. Asegurar que los grants existen
GRANT ALL ON TABLE public.notificaciones TO authenticated;
GRANT ALL ON TABLE public.notificaciones TO service_role;
GRANT ALL ON TABLE public.notificaciones TO anon;

-- 4. Habilitar RLS (Opcional, pero recomendado si se usa en producción)
-- ALTER TABLE public.notificaciones ENABLE ROW LEVEL SECURITY;
-- CREATE POLICY "Users can only see their own notifications" ON public.notificaciones
--     FOR SELECT USING (auth.uid() = user_id);

-- 5. Recargar esquema (esto es para PostgREST)
NOTIFY pgrst, 'reload schema';
