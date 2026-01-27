-- ========================================================
-- 🎸 ÓOLALE: CONFIGURACIÓN INTEGRAL (CHAT + STORAGE + REALTIME)
-- ========================================================

-- 1. ASEGURAR QUE LA TABLA DE CHAT (intercom) EXISTA
-- El app espera: id, remitente_id, destinatario_id, riff_text, leido, created_at
CREATE TABLE IF NOT EXISTS public.intercom (
    id SERIAL PRIMARY KEY,
    remitente_id UUID REFERENCES public.profiles(id) ON DELETE CASCADE,
    destinatario_id UUID REFERENCES public.profiles(id) ON DELETE CASCADE,
    riff_text TEXT NOT NULL,
    adjunto_url TEXT,
    leido BOOLEAN DEFAULT FALSE,
    created_at TIMESTAMPTZ DEFAULT NOW()
);

-- Asegurar RLS en intercom
ALTER TABLE public.intercom ENABLE ROW LEVEL SECURITY;

DROP POLICY IF EXISTS "Intercom solo entre involucrados" ON public.intercom;
CREATE POLICY "Intercom solo entre involucrados" 
    ON public.intercom FOR SELECT 
    USING (auth.uid() = remitente_id OR auth.uid() = destinatario_id);

DROP POLICY IF EXISTS "Enviar mensajes" ON public.intercom;
CREATE POLICY "Enviar mensajes" 
    ON public.intercom FOR INSERT 
    WITH CHECK (auth.uid() = remitente_id);

-- 2. CONFIGURACIÓN DE STORAGE (BUCKETS)
INSERT INTO storage.buckets (id, name, public) 
VALUES 
('avatars', 'avatars', true), 
('portfolio', 'portfolio', true)
ON CONFLICT (id) DO NOTHING;

-- Políticas de Storage para Avatars
DROP POLICY IF EXISTS "Avatars públicos" ON storage.objects;
CREATE POLICY "Avatars públicos" ON storage.objects FOR SELECT USING (bucket_id = 'avatars');

DROP POLICY IF EXISTS "Subida de propio avatar" ON storage.objects;
CREATE POLICY "Subida de propio avatar" ON storage.objects FOR INSERT 
WITH CHECK (bucket_id = 'avatars' AND (storage.foldername(name))[1] = auth.uid()::text);

DROP POLICY IF EXISTS "Update de propio avatar" ON storage.objects;
CREATE POLICY "Update de propio avatar" ON storage.objects FOR UPDATE
USING (bucket_id = 'avatars' AND (storage.foldername(name))[1] = auth.uid()::text);

-- Políticas de Storage para Portfolio
DROP POLICY IF EXISTS "Portfolio público" ON storage.objects;
CREATE POLICY "Portfolio público" ON storage.objects FOR SELECT USING (bucket_id = 'portfolio');

DROP POLICY IF EXISTS "Subida a propio portfolio" ON storage.objects;
CREATE POLICY "Subida a propio portfolio" ON storage.objects FOR INSERT 
WITH CHECK (bucket_id = 'portfolio' AND (storage.foldername(name))[1] = auth.uid()::text);

-- 3. HABILITAR REAL-TIME (WebSockets)
-- Habilita la tabla intercom para recibir actualizaciones en tiempo real
DO $$
BEGIN
    IF NOT EXISTS (
        SELECT 1 FROM pg_publication_tables 
        WHERE pubname = 'supabase_realtime' 
        AND schemaname = 'public' 
        AND tablename = 'intercom'
    ) THEN
        ALTER PUBLICATION supabase_realtime ADD TABLE public.intercom;
    END IF;
END $$;
