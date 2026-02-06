-- SCRIPT DEFINITIVO PARA REPARAR EL ESQUEMA DE LA BASE DE DATOS
-- Asegura que todas las tablas tengan el nombre correcto en español y existan.

DO $$ 
BEGIN
    -- 1. NOTIFICACIONES
    IF NOT EXISTS (SELECT FROM pg_tables WHERE schemaname = 'public' AND tablename = 'notificaciones') THEN
        IF EXISTS (SELECT FROM pg_tables WHERE schemaname = 'public' AND tablename = 'notifications') THEN
            ALTER TABLE public.notifications RENAME TO notificaciones;
        ELSE
            CREATE TABLE public.notificaciones (
                id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
                user_id UUID REFERENCES auth.users(id) ON DELETE CASCADE,
                tipo TEXT NOT NULL,
                titulo TEXT,
                mensaje TEXT,
                data JSONB DEFAULT '{}'::jsonb,
                leido BOOLEAN DEFAULT false,
                created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
            );
        END IF;
    END IF;

    -- 2. EVENTOS
    IF NOT EXISTS (SELECT FROM pg_tables WHERE schemaname = 'public' AND tablename = 'eventos') THEN
        IF EXISTS (SELECT FROM pg_tables WHERE schemaname = 'public' AND tablename = 'gigs') THEN
            ALTER TABLE public.gigs RENAME TO eventos;
        END IF;
    END IF;

    -- 3. CONEXIONES
    IF NOT EXISTS (SELECT FROM pg_tables WHERE schemaname = 'public' AND tablename = 'conexiones') THEN
        IF EXISTS (SELECT FROM pg_tables WHERE schemaname = 'public' AND tablename = 'connections') THEN
            ALTER TABLE public.connections RENAME TO conexiones;
        END IF;
    END IF;

    -- 4. PERFILES
    IF NOT EXISTS (SELECT FROM pg_tables WHERE schemaname = 'public' AND tablename = 'perfiles') THEN
        IF EXISTS (SELECT FROM pg_tables WHERE schemaname = 'public' AND tablename = 'profiles') THEN
            ALTER TABLE public.profiles RENAME TO perfiles;
        END IF;
    END IF;

    -- 5. CONVERSACIONES
    IF NOT EXISTS (SELECT FROM pg_tables WHERE schemaname = 'public' AND tablename = 'conversaciones') THEN
        IF EXISTS (SELECT FROM pg_tables WHERE schemaname = 'public' AND tablename = 'intercom') THEN
            ALTER TABLE public.intercom RENAME TO conversaciones;
        ELSEIF EXISTS (SELECT FROM pg_tables WHERE schemaname = 'public' AND tablename = 'messages') THEN
            ALTER TABLE public.messages RENAME TO conversaciones;
        END IF;
    END IF;

    -- 6. PUBLICACIONES
    IF NOT EXISTS (SELECT FROM pg_tables WHERE schemaname = 'public' AND tablename = 'publicaciones') THEN
        IF EXISTS (SELECT FROM pg_tables WHERE schemaname = 'public' AND tablename = 'posts') THEN
            ALTER TABLE public.posts RENAME TO publicaciones;
        END IF;
    END IF;

    -- 7. PARTICIPANTES_EVENTO
    IF NOT EXISTS (SELECT FROM pg_tables WHERE schemaname = 'public' AND tablename = 'participantes_evento') THEN
        IF EXISTS (SELECT FROM pg_tables WHERE schemaname = 'public' AND tablename = 'event_participants') THEN
            ALTER TABLE public.event_participants RENAME TO participantes_evento;
        ELSEIF EXISTS (SELECT FROM pg_tables WHERE schemaname = 'public' AND tablename = 'gig_lineup') THEN
            ALTER TABLE public.gig_lineup RENAME TO participantes_evento;
        END IF;
    END IF;

    -- 8. ARCHIVOS_MULTIMEDIA
    IF NOT EXISTS (SELECT FROM pg_tables WHERE schemaname = 'public' AND tablename = 'archivos_multimedia') THEN
        IF EXISTS (SELECT FROM pg_tables WHERE schemaname = 'public' AND tablename = 'portfolio_media') THEN
            ALTER TABLE public.portfolio_media RENAME TO archivos_multimedia;
        END IF;
    END IF;

    -- 9. TOKENS_DISPOSITIVO
    IF NOT EXISTS (SELECT FROM pg_tables WHERE schemaname = 'public' AND tablename = 'tokens_dispositivo') THEN
        IF EXISTS (SELECT FROM pg_tables WHERE schemaname = 'public' AND tablename = 'device_tokens') THEN
            ALTER TABLE public.device_tokens RENAME TO tokens_dispositivo;
        ELSE
            CREATE TABLE public.tokens_dispositivo (
                id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
                user_id UUID REFERENCES auth.users(id) ON DELETE CASCADE,
                token TEXT NOT NULL,
                platform TEXT,
                created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
                UNIQUE(user_id, token)
            );
        END IF;
    END IF;

    -- 10. REFERENCIAS
    IF NOT EXISTS (SELECT FROM pg_tables WHERE schemaname = 'public' AND tablename = 'referencias') THEN
        IF EXISTS (SELECT FROM pg_tables WHERE schemaname = 'public' AND tablename = 'ratings') THEN
            ALTER TABLE public.ratings RENAME TO referencias;
        ELSEIF EXISTS (SELECT FROM pg_tables WHERE schemaname = 'public' AND tablename = 'calificaciones') THEN
            ALTER TABLE public.calificaciones RENAME TO referencias;
        ELSE
            CREATE TABLE public.referencias (
                id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
                remitente_id UUID REFERENCES auth.users(id),
                receptor_id UUID REFERENCES auth.users(id),
                puntuacion INTEGER CHECK (puntuacion >= 1 AND puntuacion <= 5),
                comentario TEXT,
                event_id BIGINT,
                created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
            );
        END IF;
    END IF;

    -- 11. USUARIOS_BLOQUEADOS
    IF NOT EXISTS (SELECT FROM pg_tables WHERE schemaname = 'public' AND tablename = 'usuarios_bloqueados') THEN
        IF EXISTS (SELECT FROM pg_tables WHERE schemaname = 'public' AND tablename = 'blocks') THEN
            ALTER TABLE public.blocks RENAME TO usuarios_bloqueados;
        ELSEIF EXISTS (SELECT FROM pg_tables WHERE schemaname = 'public' AND tablename = 'bloqueos') THEN
            ALTER TABLE public.bloqueos RENAME TO usuarios_bloqueados;
        ELSE
            CREATE TABLE public.usuarios_bloqueados (
                id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
                usuario_id UUID REFERENCES auth.users(id) ON DELETE CASCADE,
                bloqueado_id UUID REFERENCES auth.users(id) ON DELETE CASCADE,
                razon TEXT,
                activo BOOLEAN DEFAULT true,
                created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
                UNIQUE(usuario_id, bloqueado_id)
            );
        END IF;
    END IF;

END $$;

-- Asegurar permisos para las tablas críticas
GRANT ALL ON ALL TABLES IN SCHEMA public TO authenticated;
GRANT ALL ON ALL TABLES IN SCHEMA public TO service_role;
GRANT USAGE, SELECT ON ALL SEQUENCES IN SCHEMA public TO authenticated;
GRANT USAGE, SELECT ON ALL SEQUENCES IN SCHEMA public TO service_role;

-- RECARGAR CACHÉ DE POSTGREST (CRÍTICO)
NOTIFY pgrst, 'reload schema';
