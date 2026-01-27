-- ========================================================
-- 🎸 ÓOLALE MOBILE - BASE DE DATOS COMPLETA Y CORREGIDA
-- ========================================================
-- Versión: 3.1 (Corregida)
-- Fecha: 22 Enero 2026
-- ESTE ES EL SCRIPT DEFINITIVO - Ejecutar en Supabase SQL Editor

-- 1. EXTENSIONES
CREATE EXTENSION IF NOT EXISTS "uuid-ossp";

-- 2. TIPOS DE DATOS (Enums)
DO $$ BEGIN
    CREATE TYPE rol_escena AS ENUM ('musico', 'banda', 'productor', 'promotor', 'staff', 'fan');
    CREATE TYPE mood_gig AS ENUM ('ensayo', 'jam_session', 'concierto', 'festival', 'taller', 'sesion_estudio', 'audicion', 'tour');
    CREATE TYPE estatus_vinculo AS ENUM ('pendiente', 'activo', 'bloqueado');
    CREATE TYPE pasarela_pago AS ENUM ('paypal', 'mercadopago');
    CREATE TYPE estatus_pago AS ENUM ('borrador', 'pendiente', 'completado', 'reembolsado', 'fallido');
    CREATE TYPE visibilidad_setlist AS ENUM ('publico', 'privado', 'solo_crew');
EXCEPTION
    WHEN duplicate_object THEN null;
END $$;

-- 3. PERFILES DE USUARIO
CREATE TABLE IF NOT EXISTS public.profiles (
    id UUID REFERENCES auth.users(id) ON DELETE CASCADE PRIMARY KEY,
    nombre_completo TEXT,
    nombre_artistico TEXT,
    slug_url TEXT UNIQUE,
    rol_principal rol_escena DEFAULT 'musico',
    bio_rider TEXT,
    ubicacion_base TEXT,
    avatar_url TEXT,
    banner_url TEXT,
    estatus_headliner BOOLEAN DEFAULT FALSE,
    verificado BOOLEAN DEFAULT FALSE,
    redes_sociales JSONB DEFAULT '{}'::jsonb,
    
    -- Campos adicionales para Discovery
    instrumento_principal TEXT,
    enlace_soundcloud TEXT,
    enlace_youtube TEXT,
    enlace_website TEXT,
    open_to_work BOOLEAN DEFAULT FALSE,
    nivel_badge TEXT DEFAULT 'principiante',
    
    fecha_registro TIMESTAMPTZ DEFAULT NOW(),
    ultimo_online TIMESTAMPTZ DEFAULT NOW()
);

-- 4. CATÁLOGOS
CREATE TABLE IF NOT EXISTS public.gear_catalog (
    id SERIAL PRIMARY KEY,
    nombre TEXT UNIQUE NOT NULL,
    familia TEXT
);

CREATE TABLE IF NOT EXISTS public.generos_catalog (
    id SERIAL PRIMARY KEY,
    nombre TEXT UNIQUE NOT NULL
);

-- 5. RELACIONES PERFIL-GEAR-GÉNEROS
CREATE TABLE IF NOT EXISTS public.perfil_gear (
    perfil_id UUID REFERENCES public.profiles(id) ON DELETE CASCADE,
    gear_id INT REFERENCES public.gear_catalog(id) ON DELETE CASCADE,
    nivel TEXT,
    PRIMARY KEY (perfil_id, gear_id)
);

CREATE TABLE IF NOT EXISTS public.perfil_generos (
    perfil_id UUID REFERENCES public.profiles(id) ON DELETE CASCADE,
    genero_id INT REFERENCES public.generos_catalog(id) ON DELETE CASCADE,
    PRIMARY KEY (perfil_id, genero_id)
);

-- 6. EVENTOS (GIGS)
CREATE TABLE IF NOT EXISTS public.gigs (
    id SERIAL PRIMARY KEY,
    organizador_id UUID REFERENCES public.profiles(id) ON DELETE CASCADE NOT NULL,
    titulo_bolo TEXT NOT NULL,
    resumen_setlist TEXT,
    tipo mood_gig DEFAULT 'jam_session',
    fecha_gig DATE NOT NULL,
    hora_soundcheck TIME NOT NULL,
    lugar_nombre TEXT NOT NULL,
    coordenadas POINT,
    capacidad_foro INT,
    flyer_url TEXT,
    precio_ticket DECIMAL(10, 2) DEFAULT 0.00,
    visibilidad visibilidad_setlist DEFAULT 'publico',
    estatus_bolo TEXT DEFAULT 'programado',
    requisitos_tecnicos TEXT,
    created_at TIMESTAMPTZ DEFAULT NOW()
);

CREATE TABLE IF NOT EXISTS public.gig_lineup (
    gig_id INT REFERENCES public.gigs(id) ON DELETE CASCADE,
    perfil_id UUID REFERENCES public.profiles(id) ON DELETE CASCADE,
    rol_en_gig TEXT,
    asistencia_confirmada BOOLEAN DEFAULT FALSE,
    PRIMARY KEY (gig_id, perfil_id)
);

-- 7. PAGOS
CREATE TABLE IF NOT EXISTS public.tickets_pagos (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    comprador_id UUID REFERENCES public.profiles(id) ON DELETE SET NULL,
    monto_total DECIMAL(10, 2) NOT NULL,
    divisa TEXT DEFAULT 'MXN',
    pasarela pasarela_pago NOT NULL,
    referencia_pago TEXT,
    estatus estatus_pago DEFAULT 'pendiente',
    detalles_json JSONB,
    created_at TIMESTAMPTZ DEFAULT NOW(),
    updated_at TIMESTAMPTZ DEFAULT NOW()
);

-- 8. NETWORKING (CREWS)
CREATE TABLE IF NOT EXISTS public.crews (
    id SERIAL PRIMARY KEY,
    perfil_id UUID REFERENCES public.profiles(id) ON DELETE CASCADE,
    target_id UUID REFERENCES public.profiles(id) ON DELETE CASCADE,
    estatus estatus_vinculo DEFAULT 'pendiente',
    es_colaboracion BOOLEAN DEFAULT FALSE,
    created_at TIMESTAMPTZ DEFAULT NOW(),
    UNIQUE (perfil_id, target_id)
);

-- 9. MENSAJERÍA (INTERCOM) - ⚠️ CORREGIDO
CREATE TABLE IF NOT EXISTS public.intercom (
    id_mensaje SERIAL PRIMARY KEY,
    id_remitente UUID REFERENCES public.profiles(id) ON DELETE CASCADE,
    id_destinatario UUID REFERENCES public.profiles(id) ON DELETE CASCADE,
    riff_text TEXT NOT NULL,
    adjunto_url TEXT,
    leido BOOLEAN DEFAULT FALSE,
    fecha_envio TIMESTAMPTZ DEFAULT NOW()
);

-- 10. SEGURIDAD - REPORTES
CREATE TABLE IF NOT EXISTS public.reports (
    id SERIAL PRIMARY KEY,
    reporter_id UUID REFERENCES public.profiles(id) ON DELETE CASCADE,
    reported_id UUID REFERENCES public.profiles(id) ON DELETE CASCADE,
    motivo TEXT NOT NULL,
    descripcion TEXT,
    evidencia_url TEXT,
    estado TEXT DEFAULT 'pendiente',
    resolucion_nota TEXT,
    created_at TIMESTAMPTZ DEFAULT NOW(),
    resolved_at TIMESTAMPTZ
);

-- 11. SEGURIDAD - BLOQUEOS
CREATE TABLE IF NOT EXISTS public.blocks (
    id SERIAL PRIMARY KEY,
    blocker_id UUID REFERENCES public.profiles(id) ON DELETE CASCADE,
    blocked_id UUID REFERENCES public.profiles(id) ON DELETE CASCADE,
    created_at TIMESTAMPTZ DEFAULT NOW(),
    UNIQUE(blocker_id, blocked_id)
);

-- 12. NOTIFICACIONES
CREATE TABLE IF NOT EXISTS public.notifications (
    id SERIAL PRIMARY KEY,
    user_id UUID REFERENCES public.profiles(id) ON DELETE CASCADE,
    tipo TEXT NOT NULL,
    titulo TEXT NOT NULL,
    mensaje TEXT,
    leido BOOLEAN DEFAULT FALSE,
    data JSONB,
    created_at TIMESTAMPTZ DEFAULT NOW()
);

-- 13. CONTRATACIONES
CREATE TABLE IF NOT EXISTS public.hirings (
    id SERIAL PRIMARY KEY,
    employer_id UUID REFERENCES public.profiles(id) ON DELETE CASCADE,
    musician_id UUID REFERENCES public.profiles(id) ON DELETE CASCADE,
    tipo_trabajo TEXT NOT NULL,
    descripcion TEXT,
    fecha_inicio DATE,
    fecha_fin DATE,
    presupuesto DECIMAL(10,2),
    estado TEXT DEFAULT 'pendiente',
    notas TEXT,
    created_at TIMESTAMPTZ DEFAULT NOW()
);

-- 14. ÍNDICES PARA PERFORMANCE
CREATE INDEX IF NOT EXISTS idx_intercom_conversation ON public.intercom(id_remitente, id_destinatario);
CREATE INDEX IF NOT EXISTS idx_intercom_fecha ON public.intercom(fecha_envio DESC);
CREATE INDEX IF NOT EXISTS idx_notifications_user ON public.notifications(user_id);
CREATE INDEX IF NOT EXISTS idx_notifications_unread ON public.notifications(user_id, leido);
CREATE INDEX IF NOT EXISTS idx_crews_perfil ON public.crews(perfil_id);
CREATE INDEX IF NOT EXISTS idx_crews_target ON public.crews(target_id);

-- 15. TRIGGER: AUTO-CREAR PERFIL
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

DROP TRIGGER IF EXISTS on_auth_user_created ON auth.users;
CREATE TRIGGER on_auth_user_created
    AFTER INSERT ON auth.users
    FOR EACH ROW EXECUTE PROCEDURE public.handle_new_artist();

-- 16. TRIGGER: NOTIFICAR CONEXIÓN
CREATE OR REPLACE FUNCTION notify_connection_request()
RETURNS TRIGGER AS $$
BEGIN
    INSERT INTO public.notifications (user_id, tipo, titulo, mensaje, data)
    VALUES (
        NEW.target_id,
        'connection_request',
        'Nueva solicitud de conexión',
        'Alguien quiere conectar contigo',
        jsonb_build_object('crew_id', NEW.id, 'requester_id', NEW.perfil_id)
    );
    RETURN NEW;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

DROP TRIGGER IF EXISTS on_crew_request ON public.crews;
CREATE TRIGGER on_crew_request
    AFTER INSERT ON public.crews
    FOR EACH ROW
    WHEN (NEW.estatus = 'pendiente')
    EXECUTE FUNCTION notify_connection_request();

-- 17. TRIGGER: NOTIFICAR ACEPTACIÓN
CREATE OR REPLACE FUNCTION notify_connection_accepted()
RETURNS TRIGGER AS $$
BEGIN
    IF NEW.estatus = 'activo' AND OLD.estatus = 'pendiente' THEN
        INSERT INTO public.notifications (user_id, tipo, titulo, mensaje, data)
        VALUES (
            OLD.perfil_id,
            'connection_accepted',
            '¡Conexión aceptada!',
            'Tu solicitud de conexión fue aceptada',
            jsonb_build_object('crew_id', NEW.id, 'accepter_id', NEW.target_id)
        );
    END IF;
    RETURN NEW;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

DROP TRIGGER IF EXISTS on_crew_accepted ON public.crews;
CREATE TRIGGER on_crew_accepted
    AFTER UPDATE ON public.crews
    FOR EACH ROW
    EXECUTE FUNCTION notify_connection_accepted();

-- 18. TRIGGER: NOTIFICAR POSTULACIÓN
CREATE OR REPLACE FUNCTION notify_gig_postulation()
RETURNS TRIGGER AS $$
DECLARE
    organizer_id UUID;
BEGIN
    SELECT organizador_id INTO organizer_id
    FROM public.gigs
    WHERE id = NEW.gig_id;
    
    INSERT INTO public.notifications (user_id, tipo, titulo, mensaje, data)
    VALUES (
        organizer_id,
        'gig_postulation',
        'Nueva postulación a tu evento',
        'Un músico quiere unirse a tu lineup',
        jsonb_build_object('gig_id', NEW.gig_id, 'musician_id', NEW.perfil_id)
    );
    RETURN NEW;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

DROP TRIGGER IF EXISTS on_gig_postulation ON public.gig_lineup;
CREATE TRIGGER on_gig_postulation
    AFTER INSERT ON public.gig_lineup
    FOR EACH ROW
    EXECUTE FUNCTION notify_gig_postulation();

-- 19. ROW LEVEL SECURITY (RLS)
ALTER TABLE public.profiles ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.gigs ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.intercom ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.notifications ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.reports ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.hirings ENABLE ROW LEVEL SECURITY;

-- Políticas Profiles
CREATE POLICY "Perfiles públicos" ON public.profiles FOR SELECT USING (true);
CREATE POLICY "Editar propio perfil" ON public.profiles FOR UPDATE USING (auth.uid() = id);

-- Políticas Gigs
CREATE POLICY "Gigs públicos" ON public.gigs FOR SELECT USING (true);
CREATE POLICY "Crear gigs" ON public.gigs FOR INSERT WITH CHECK (auth.uid() = organizador_id);
CREATE POLICY "Editar propios gigs" ON public.gigs FOR UPDATE USING (auth.uid() = organizador_id);

-- Políticas Intercom
CREATE POLICY "Ver propios mensajes" ON public.intercom FOR SELECT 
    USING (auth.uid() = id_remitente OR auth.uid() = id_destinatario);
CREATE POLICY "Enviar mensajes" ON public.intercom FOR INSERT 
    WITH CHECK (auth.uid() = id_remitente);

-- Políticas Notifications
CREATE POLICY "Ver propias notificaciones" ON public.notifications FOR SELECT 
    USING (auth.uid() = user_id);
CREATE POLICY "Marcar como leído" ON public.notifications FOR UPDATE 
    USING (auth.uid() = user_id);

-- Políticas Reports
CREATE POLICY "Crear reportes" ON public.reports FOR INSERT 
    WITH CHECK (auth.uid() = reporter_id);

-- Políticas Hirings
CREATE POLICY "Ver propias contrataciones" ON public.hirings FOR SELECT 
    USING (auth.uid() = employer_id OR auth.uid() = musician_id);
CREATE POLICY "Crear ofertas" ON public.hirings FOR INSERT 
    WITH CHECK (auth.uid() = employer_id);
CREATE POLICY "Responder ofertas" ON public.hirings FOR UPDATE 
    USING (auth.uid() = musician_id);

-- 20. FUNCIÓN HELPER
CREATE OR REPLACE FUNCTION mark_all_notifications_read(p_user_id UUID)
RETURNS void AS $$
BEGIN
    UPDATE public.notifications
    SET leido = true
    WHERE user_id = p_user_id AND leido = false;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- 21. DATOS SEMILLA
INSERT INTO public.gear_catalog (nombre, familia) VALUES 
('Guitarra Eléctrica', 'Cuerdas'), ('Bajo Eléctrico', 'Cuerdas'), 
('Batería', 'Percusión'), ('Sintetizador', 'Teclados'), 
('Voz', 'Viento/Voz'), ('Interfaz de Audio', 'Pro Audio'),
('Mixer Digital', 'Pro Audio')
ON CONFLICT (nombre) DO NOTHING;

INSERT INTO public.generos_catalog (nombre) VALUES 
('Rock'), ('Jazz'), ('Electronic'), 
('Pop'), ('Metal'), ('Hip Hop')
ON CONFLICT (nombre) DO NOTHING;

-- ✅ SCRIPT COMPLETO Y CORREGIDO
