-- ========================================================
-- 🔔 EXTENSIONES ADICIONALES PARA ÓOLALE MOBILE
-- ========================================================
-- Ejecutar DESPUÉS de SUPABASE_SETUP.sql

-- 1. NOTIFICACIONES (Sistema de Alertas)
-- --------------------------------------------------------
CREATE TABLE IF NOT EXISTS public.notifications (
    id SERIAL PRIMARY KEY,
    user_id UUID REFERENCES public.profiles(id) ON DELETE CASCADE,
    tipo TEXT NOT NULL, -- 'connection_request', 'connection_accepted', 'new_message', 'gig_postulation', 'gig_update'
    titulo TEXT NOT NULL,
    mensaje TEXT,
    leido BOOLEAN DEFAULT FALSE,
    data JSONB, -- Datos adicionales (ej: id del evento, id del usuario)
    created_at TIMESTAMPTZ DEFAULT NOW()
);

CREATE INDEX IF NOT EXISTS idx_notifications_user ON notifications(user_id);
CREATE INDEX IF NOT EXISTS idx_notifications_unread ON notifications(user_id, leido);

-- Habilitar RLS
ALTER TABLE public.notifications ENABLE ROW LEVEL SECURITY;

CREATE POLICY "Ver propias notificaciones" 
    ON public.notifications FOR SELECT 
    USING (auth.uid() = user_id);

CREATE POLICY "Marcar como leído" 
    ON public.notifications FOR UPDATE 
    USING (auth.uid() = user_id);

-- 2. CONTRATACIONES (Hire Musicians)
-- --------------------------------------------------------
CREATE TABLE IF NOT EXISTS public.hirings (
    id SERIAL PRIMARY KEY,
    employer_id UUID REFERENCES public.profiles(id) ON DELETE CASCADE,
    musician_id UUID REFERENCES public.profiles(id) ON DELETE CASCADE,
    tipo_trabajo TEXT NOT NULL, -- 'session', 'tour', 'event', 'recording'
    descripcion TEXT,
    fecha_inicio DATE,
    fecha_fin DATE,
    presupuesto DECIMAL(10,2),
    estado TEXT DEFAULT 'pendiente', -- 'pendiente', 'aceptado', 'rechazado', 'completado'
    notas TEXT,
    created_at TIMESTAMPTZ DEFAULT NOW()
);

-- Habilitar RLS
ALTER TABLE public.hirings ENABLE ROW LEVEL SECURITY;

CREATE POLICY "Ver contrataciones propias" 
    ON public.hirings FOR SELECT 
    USING (auth.uid() = employer_id OR auth.uid() = musician_id);

CREATE POLICY "Crear contrataciones" 
    ON public.hirings FOR INSERT 
    WITH CHECK (auth.uid() = employer_id);

CREATE POLICY "Responder contrataciones" 
    ON public.hirings FOR UPDATE 
    USING (auth.uid() = musician_id);

-- 3. TRIGGERS PARA NOTIFICACIONES AUTOMÁTICAS
-- --------------------------------------------------------

-- Trigger: Notificar cuando alguien se conecta
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

CREATE TRIGGER on_crew_request
    AFTER INSERT ON public.crews
    FOR EACH ROW
    WHEN (NEW.estatus = 'pendiente')
    EXECUTE FUNCTION notify_connection_request();

-- Trigger: Notificar cuando aceptan tu solicitud
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

CREATE TRIGGER on_crew_accepted
    AFTER UPDATE ON public.crews
    FOR EACH ROW
    EXECUTE FUNCTION notify_connection_accepted();

-- Trigger: Notificar cuando alguien se postula a tu evento
CREATE OR REPLACE FUNCTION notify_gig_postulation()
RETURNS TRIGGER AS $$
DECLARE
    organizer_id UUID;
BEGIN
    -- Obtener el organizador del evento
    SELECT organizador_id INTO organizer_id
    FROM public.gigs
    WHERE id = NEW.gig_id;
    
    -- Notificar al organizador
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

CREATE TRIGGER on_gig_postulation
    AFTER INSERT ON public.gig_lineup
    FOR EACH ROW
    EXECUTE FUNCTION notify_gig_postulation();

-- 4. FUNCIÓN HELPER: Marcar todas como leídas
-- --------------------------------------------------------
CREATE OR REPLACE FUNCTION mark_all_notifications_read(p_user_id UUID)
RETURNS void AS $$
BEGIN
    UPDATE public.notifications
    SET leido = true
    WHERE user_id = p_user_id AND leido = false;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;
