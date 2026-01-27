-- ========================================================
-- 🎸 ÓOLALE: FEED DE ARTISTAS (POSTS)
-- ========================================================

-- 1. TABLA DE POSTS
CREATE TABLE IF NOT EXISTS public.posts (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    author_id UUID REFERENCES public.profiles(id) ON DELETE CASCADE NOT NULL,
    content TEXT NOT NULL,
    media_url TEXT,
    media_type TEXT, -- 'imagen', 'video'
    likes_count INT DEFAULT 0,
    created_at TIMESTAMPTZ DEFAULT NOW(),
    updated_at TIMESTAMPTZ DEFAULT NOW()
);

-- 2. TABLA DE LIKES (Para evitar que un usuario de like infinitas veces)
CREATE TABLE IF NOT EXISTS public.post_likes (
    post_id UUID REFERENCES public.posts(id) ON DELETE CASCADE,
    user_id UUID REFERENCES public.profiles(id) ON DELETE CASCADE,
    PRIMARY KEY (post_id, user_id)
);

-- 3. HABILITAR RLS
ALTER TABLE public.posts ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.post_likes ENABLE ROW LEVEL SECURITY;

-- Cualquiera puede ver posts
CREATE POLICY "Posts públicos" ON public.posts FOR SELECT USING (true);

-- Solo el autor puede crear/editar/borrar su post
CREATE POLICY "Autores gestionan sus posts" ON public.posts FOR ALL 
USING (auth.uid() = author_id);

-- Gestión de likes
CREATE POLICY "Usuarios gestionan sus propios likes" ON public.post_likes FOR ALL
USING (auth.uid() = user_id);

-- 4. HABILITAR REAL-TIME
DO $$
BEGIN
    IF NOT EXISTS (
        SELECT 1 FROM pg_publication_tables 
        WHERE pubname = 'supabase_realtime' 
        AND schemaname = 'public' 
        AND tablename = 'posts'
    ) THEN
        ALTER PUBLICATION supabase_realtime ADD TABLE public.posts;
    END IF;
END $$;

-- 5. DATOS SEMILLA (Posts iniciales)
INSERT INTO public.posts (author_id, content)
VALUES 
('cd34599b-0151-4ed7-a99c-111853df5ce7', '¡Hola a todos! Estrenando la nueva versión de Óolale. Próximamente nuevas fechas de gira 🎸'),
('cd34599b-0151-4ed7-a99c-111853df5ce7', '¿Alguien busca guitarrista para un evento de Blues este fin de semana? Estoy disponible.')
ON CONFLICT DO NOTHING;
