-- ========================================================
-- 🎸 ÓOLALE MOBILE - VERIFICACIÓN Y ACTUALIZACIÓN DE ESQUEMA
-- ========================================================
-- Este script asegura que todas las columnas necesarias existan

-- 1. Verificar/Agregar columna instrumento_principal en profiles
DO $$ 
BEGIN
    IF NOT EXISTS (
        SELECT 1 FROM information_schema.columns 
        WHERE table_name = 'profiles' AND column_name = 'instrumento_principal'
    ) THEN
        ALTER TABLE public.profiles ADD COLUMN instrumento_principal TEXT;
    END IF;
END $$;

-- 2. Verificar estructura de tabla gigs (ya debería existir)
-- Si no existe, crearla
CREATE TABLE IF NOT EXISTS public.gigs (
    id BIGSERIAL PRIMARY KEY,
    organizador_id UUID REFERENCES auth.users(id) ON DELETE CASCADE,
    titulo_bolo TEXT NOT NULL,
    resumen_setlist TEXT,
    tipo TEXT DEFAULT 'jam_session',
    fecha_gig DATE NOT NULL,
    hora_soundcheck TIME,
    lugar_nombre TEXT,
    lugar_direccion TEXT,
    requisitos_tecnicos TEXT,
    precio_ticket NUMERIC(10,2),
    flyer_url TEXT,
    estatus_bolo TEXT DEFAULT 'programado',
    created_at TIMESTAMPTZ DEFAULT NOW(),
    updated_at TIMESTAMPTZ DEFAULT NOW()
);

-- 3. Habilitar RLS en gigs si no está habilitado
ALTER TABLE public.gigs ENABLE ROW LEVEL SECURITY;

-- 4. Políticas básicas para gigs (todos pueden ver, solo creador puede editar)
DROP POLICY IF EXISTS "Gigs son públicos" ON public.gigs;
CREATE POLICY "Gigs son públicos" ON public.gigs
    FOR SELECT USING (true);

DROP POLICY IF EXISTS "Usuarios pueden crear gigs" ON public.gigs;
CREATE POLICY "Usuarios pueden crear gigs" ON public.gigs
    FOR INSERT WITH CHECK (auth.uid() = organizador_id);

DROP POLICY IF EXISTS "Organizadores pueden editar sus gigs" ON public.gigs;
CREATE POLICY "Organizadores pueden editar sus gigs" ON public.gigs
    FOR UPDATE USING (auth.uid() = organizador_id);

DROP POLICY IF EXISTS "Organizadores pueden eliminar sus gigs" ON public.gigs;
CREATE POLICY "Organizadores pueden eliminar sus gigs" ON public.gigs
    FOR DELETE USING (auth.uid() = organizador_id);

-- 5. Índices para mejorar performance
CREATE INDEX IF NOT EXISTS idx_gigs_fecha ON public.gigs(fecha_gig);
CREATE INDEX IF NOT EXISTS idx_gigs_organizador ON public.gigs(organizador_id);
CREATE INDEX IF NOT EXISTS idx_gigs_tipo ON public.gigs(tipo);

-- 6. Trigger para updated_at en gigs
CREATE OR REPLACE FUNCTION update_updated_at_column()
RETURNS TRIGGER AS $$
BEGIN
    NEW.updated_at = NOW();
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

DROP TRIGGER IF EXISTS update_gigs_updated_at ON public.gigs;
CREATE TRIGGER update_gigs_updated_at
    BEFORE UPDATE ON public.gigs
    FOR EACH ROW
    EXECUTE FUNCTION update_updated_at_column();

-- ========================================================
-- ✅ VERIFICACIÓN COMPLETADA
-- ========================================================
