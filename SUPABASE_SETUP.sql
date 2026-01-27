-- ========================================================
-- 🎸 THE MASTER TAPE: ESTRUCTURA COMPLETA ÓOLALE v3.0
-- ========================================================
-- Sistema integral para Músicos, Bandas, Gigs y Producción.
-- Optimizado para Supabase (PostgreSQL) con lenguaje del medio.

-- 1. SETUP DE INSTRUMENTACIÓN (Extensiones y Tipos)
-- --------------------------------------------------------
CREATE EXTENSION IF NOT EXISTS "uuid-ossp";

DO $$ BEGIN
    -- Roles en la escena
    CREATE TYPE rol_escena AS ENUM ('musico', 'banda', 'productor', 'promotor', 'staff', 'fan');
    -- Tipos de bolo / Agenda
    CREATE TYPE mood_gig AS ENUM ('ensayo', 'jam_session', 'concierto', 'festival', 'taller', 'sesion_estudio', 'audicion', 'tour');
    -- Estatus de la Crew (Networking)
    CREATE TYPE estatus_vinculo AS ENUM ('pendiente', 'activo', 'bloqueado');
    -- Pasarelas de Pago Oficiales
    CREATE TYPE pasarela_pago AS ENUM ('paypal', 'mercadopago');
    CREATE TYPE estatus_pago AS ENUM ('borrador', 'pendiente', 'completado', 'reembolsado', 'fallido');
    -- Visualización
    CREATE TYPE visibilidad_setlist AS ENUM ('publico', 'privado', 'solo_crew');
EXCEPTION
    WHEN duplicate_object THEN null;
END $$;

-- 2. CORE: EL LINE-UP (Usuarios y Perfiles)
-- --------------------------------------------------------

-- Tabla: EPK_Master (Perfiles detallados)
CREATE TABLE IF NOT EXISTS public.profiles (
    id UUID REFERENCES auth.users(id) ON DELETE CASCADE PRIMARY KEY,
    nombre_completo TEXT NOT NULL,
    nombre_artistico TEXT,
    slug_url TEXT UNIQUE, -- para oolale.app/tu-nombre-artistico
    rol_principal rol_escena DEFAULT 'musico',
    bio_rider TEXT, -- Biografía / Rider técnico simplificado
    ubicacion_base TEXT,
    avatar_url TEXT,
    banner_url TEXT,
    estatus_headliner BOOLEAN DEFAULT FALSE, -- Premium status
    verificado BOOLEAN DEFAULT FALSE,
    redes_sociales JSONB DEFAULT '{}'::jsonb, -- Enlaces a Spotify, IG, YT
    fecha_registro TIMESTAMPTZ DEFAULT NOW(),
    ultimo_online TIMESTAMPTZ DEFAULT NOW()
);

-- Tabla: Gear_Catalog (Instrumentos/Equipo)
CREATE TABLE IF NOT EXISTS public.gear_catalog (
    id SERIAL PRIMARY KEY,
    nombre TEXT UNIQUE NOT NULL,
    familia TEXT -- ej: 'Cuerdas', 'Daw/Software', 'Percusión'
);

-- Tabla: Playlist_Genres (Géneros musicales)
CREATE TABLE IF NOT EXISTS public.generos_catalog (
    id SERIAL PRIMARY KEY,
    nombre TEXT UNIQUE NOT NULL
);

-- Tabla: Artist_Skills (Relación Perfil - Gear)
CREATE TABLE IF NOT EXISTS public.perfil_gear (
    perfil_id UUID REFERENCES public.profiles(id) ON DELETE CASCADE,
    gear_id INT REFERENCES public.gear_catalog(id) ON DELETE CASCADE,
    nivel TEXT, -- ej: 'Principiante', 'Session Musician', 'Pro'
    PRIMARY KEY (perfil_id, gear_id)
);

-- Tabla: Perfil_Generos (Relación Perfil - Géneros)
CREATE TABLE IF NOT EXISTS public.perfil_generos (
    perfil_id UUID REFERENCES public.profiles(id) ON DELETE CASCADE,
    genero_id INT REFERENCES public.generos_catalog(id) ON DELETE CASCADE,
    PRIMARY KEY (perfil_id, genero_id)
);

-- 3. GESTIÓN: GIGS & TOURS (Eventos)
-- --------------------------------------------------------

-- Tabla: Gig_Board (Cartelera de eventos)
CREATE TABLE IF NOT EXISTS public.gigs (
    id SERIAL PRIMARY KEY,
    organizador_id UUID REFERENCES public.profiles(id) ON DELETE CASCADE NOT NULL,
    titulo_bolo TEXT NOT NULL,
    resumen_setlist TEXT, -- Descripción del evento
    tipo mood_gig DEFAULT 'jam_session',
    fecha_gig DATE NOT NULL,
    hora_soundcheck TIME NOT NULL, -- Hora de la cita / inicio
    lugar_nombre TEXT NOT NULL,
    coordenadas POINT, -- Para mapa en la app
    capacidad_foro INT,
    flyer_url TEXT,
    precio_ticket DECIMAL(10, 2) DEFAULT 0.00,
    visibilidad visibilidad_setlist DEFAULT 'publico',
    estatus_bolo TEXT DEFAULT 'programado', -- 'programado', 'en_vivo', 'terminado', 'cancelado'
    requisitos_tecnicos TEXT, -- Lo que necesitan los músicos
    created_at TIMESTAMPTZ DEFAULT NOW()
);

-- Tabla: Lineup_Asistencia (Participantes en el Gig)
CREATE TABLE IF NOT EXISTS public.gig_lineup (
    gig_id INT REFERENCES public.gigs(id) ON DELETE CASCADE,
    perfil_id UUID REFERENCES public.profiles(id) ON DELETE CASCADE,
    rol_en_gig TEXT, -- ej: 'Guitarra', 'Ingeniero', 'Fan'
    asistencia_confirmada BOOLEAN DEFAULT FALSE,
    PRIMARY KEY (gig_id, perfil_id)
);

-- 4. BUSINESS: THE BOX OFFICE (Pagos)
-- --------------------------------------------------------

-- Tabla: Box_Office (Transacciones)
CREATE TABLE IF NOT EXISTS public.tickets_pagos (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    comprador_id UUID REFERENCES public.profiles(id) ON DELETE SET NULL,
    monto_total DECIMAL(10, 2) NOT NULL,
    divisa TEXT DEFAULT 'MXN',
    pasarela pasarela_pago NOT NULL,
    referencia_pago TEXT, -- ID de PayPal / Mercado Pago
    estatus estatus_pago DEFAULT 'pendiente',
    detalles_json JSONB, -- Para guardar respuesta de la API de pagos
    created_at TIMESTAMPTZ DEFAULT NOW(),
    updated_at TIMESTAMPTZ DEFAULT NOW()
);

-- 5. SOCIAL: CREWS & INTERCOM (Networking)
-- --------------------------------------------------------

-- Tabla: Crews (Contactos/Seguidores)
CREATE TABLE IF NOT EXISTS public.crews (
    id SERIAL PRIMARY KEY,
    perfil_id UUID REFERENCES public.profiles(id) ON DELETE CASCADE, -- El que sigue / conecta
    target_id UUID REFERENCES public.profiles(id) ON DELETE CASCADE, -- El seguido / conectado
    estatus estatus_vinculo DEFAULT 'activo',
    es_colaboracion BOOLEAN DEFAULT FALSE, -- Si es una relación de trabajo o solo seguidor
    created_at TIMESTAMPTZ DEFAULT NOW(),
    UNIQUE (perfil_id, target_id)
);

-- Tabla: Intercom_Messages (Chat)
CREATE TABLE IF NOT EXISTS public.intercom (
    id SERIAL PRIMARY KEY,
    remitente_id UUID REFERENCES public.profiles(id) ON DELETE CASCADE,
    destinatario_id UUID REFERENCES public.profiles(id) ON DELETE CASCADE,
    riff_text TEXT NOT NULL,
    adjunto_url TEXT, -- Para fotos de gear o demos en audio
    leido BOOLEAN DEFAULT FALSE,
    created_at TIMESTAMPTZ DEFAULT NOW()
);

-- 6. TECH: AUTOMATION & SECURITY (RLS)
-- --------------------------------------------------------

-- Trigger: New Artist Signup (Auto-Profile)
CREATE OR REPLACE FUNCTION public.handle_new_artist()
RETURNS TRIGGER AS $$
BEGIN
    INSERT INTO public.profiles (id, nombre_completo, avatar_url, slug_url)
    VALUES (
        NEW.id, 
        COALESCE(NEW.raw_user_meta_data->>'full_name', 'Nuevo Músico'),
        NEW.raw_user_meta_data->>'avatar_url',
        LOWER(REPLACE(COALESCE(NEW.raw_user_meta_data->>'full_name', 'artist-' || SUBSTR(NEW.id::text, 1, 8)), ' ', '-'))
    );
    RETURN NEW;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

CREATE TRIGGER on_auth_user_created
    AFTER INSERT ON auth.users
    FOR EACH ROW EXECUTE PROCEDURE public.handle_new_artist();

-- RLS (Stage Access Control)
ALTER TABLE public.profiles ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.gigs ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.intercom ENABLE ROW LEVEL SECURITY;

CREATE POLICY "Perfiles audibles para todos" ON public.profiles FOR SELECT USING (true);
CREATE POLICY "Artistas editan su propio EPK" ON public.profiles FOR UPDATE USING (auth.uid() = id);

CREATE POLICY "Gigs visibles en el board" ON public.gigs FOR SELECT USING (true);
CREATE POLICY "Solo organizador edita su Gig" ON public.gigs FOR ALL USING (auth.uid() = organizador_id);


DROP POLICY IF EXISTS "Intercom solo entre involucrados" ON public.intercom;
CREATE POLICY "Intercom solo entre involucrados" 
    ON public.intercom FOR SELECT 
    USING (auth.uid() = remitente_id OR auth.uid() = destinatario_id);

-- 7. SOUNDCHECK DATA (Datos Semilla)
-- --------------------------------------------------------
INSERT INTO public.gear_catalog (nombre, familia) VALUES 
('Guitarra Eléctrica', 'Cuerdas'), ('Bajo Eléctrico', 'Cuerdas'), 
('Batería Neumática', 'Percusión'), ('Sintetizador Analógico', 'Teclados'), 
('Voz Principal', 'Viento/Voz'), ('Interfaz de Audio', 'Pro Audio'),
('Mixer Digital', 'Pro Audio');

INSERT INTO public.generos_catalog (nombre) VALUES 
('Rock Alternativo'), ('Jazz Fusión'), ('Electronic Body Music'), 
('Dream Pop'), ('Metal Progresivo'), ('Trap Experimental');
