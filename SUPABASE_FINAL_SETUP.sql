-- ========================================================
-- 🎸 ÓOLALE MOBILE - UNIFICACIÓN DE FUNCIONALIDADES
-- ========================================================

-- 1. Asegurar buckets de Storage
-- Nota: Esto se hace usualmente desde el Dashboard de Supabase, 
-- pero aquí dejamos la referencia de lo que debe existir:
-- BUCKET: 'perfiles' (Público) -> Para Avatares y Banners
-- BUCKET: 'media' (Público) -> Para Portfolio (Fotos, Videos, Audios)

-- 2. Asegurar estructura de Mensajería (Intercom)
CREATE TABLE IF NOT EXISTS public.intercom (
    id BIGSERIAL PRIMARY KEY,
    remitente_id UUID REFERENCES auth.users(id) ON DELETE CASCADE,
    destinatario_id UUID REFERENCES auth.users(id) ON DELETE CASCADE,
    riff_text TEXT NOT NULL,
    leido BOOLEAN DEFAULT false,
    created_at TIMESTAMPTZ DEFAULT NOW()
);

-- RLS para Mensajería
ALTER TABLE public.intercom ENABLE ROW LEVEL SECURITY;

DROP POLICY IF EXISTS "Usuarios ven sus propios mensajes" ON public.intercom;
CREATE POLICY "Usuarios ven sus propios mensajes" ON public.intercom
    FOR SELECT USING (auth.uid() = remitente_id OR auth.uid() = destinatario_id);

DROP POLICY IF EXISTS "Usuarios pueden enviar mensajes" ON public.intercom;
CREATE POLICY "Usuarios pueden enviar mensajes" ON public.intercom
    FOR INSERT WITH CHECK (auth.uid() = remitente_id);

-- 3. Asegurar estructura de Notificaciones
CREATE TABLE IF NOT EXISTS public.notifications (
    id BIGSERIAL PRIMARY KEY,
    user_id UUID REFERENCES auth.users(id) ON DELETE CASCADE,
    titulo TEXT NOT NULL,
    mensaje TEXT,
    tipo TEXT, -- 'mensaje', 'evento', 'conic'
    data JSONB,
    leido BOOLEAN DEFAULT false,
    created_at TIMESTAMPTZ DEFAULT NOW()
);

ALTER TABLE public.notifications ENABLE ROW LEVEL SECURITY;

DROP POLICY IF EXISTS "Usuarios ven sus notificaciones" ON public.notifications;
CREATE POLICY "Usuarios ven sus notificaciones" ON public.notifications
    FOR SELECT USING (auth.uid() = user_id);

-- 4. Índice para mensajes rápidos
CREATE INDEX IF NOT EXISTS idx_intercom_users ON public.intercom(remitente_id, destinatario_id);
