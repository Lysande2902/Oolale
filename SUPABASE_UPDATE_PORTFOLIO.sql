-- ========================================================
-- 🎸 ÓOLALE MOBILE - UPDATE PORTFOLIO
-- ========================================================
-- Agregar tabla faltante para el módulo de Portfolio

-- 1. Crear tabla portfolio_media
CREATE TABLE IF NOT EXISTS public.portfolio_media (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    profile_id UUID REFERENCES public.profiles(id) ON DELETE CASCADE NOT NULL,
    titulo TEXT DEFAULT 'Sin título',
    tipo TEXT DEFAULT 'otro', -- 'video', 'audio', 'imagen'
    url TEXT NOT NULL,
    thumbnail_url TEXT,
    vistas INT DEFAULT 0,
    descargas INT DEFAULT 0,
    visibilidad TEXT DEFAULT 'publico', -- 'publico', 'privado'
    created_at TIMESTAMPTZ DEFAULT NOW(),
    updated_at TIMESTAMPTZ DEFAULT NOW()
);

-- 2. Habilitar RLS
ALTER TABLE public.portfolio_media ENABLE ROW LEVEL SECURITY;

-- 3. Políticas de seguridad
-- Cualquiera puede ver items públicos
CREATE POLICY "Ver portfolio público" ON public.portfolio_media 
    FOR SELECT USING (visibilidad = 'publico' OR auth.uid() = profile_id);

-- Solo el dueño puede insertar/editar/borrar
CREATE POLICY "Administrar propio portfolio" ON public.portfolio_media 
    FOR ALL USING (auth.uid() = profile_id);

-- 4. Índices
CREATE INDEX IF NOT EXISTS idx_portfolio_profile ON public.portfolio_media(profile_id);
CREATE INDEX IF NOT EXISTS idx_portfolio_created ON public.portfolio_media(created_at DESC);
