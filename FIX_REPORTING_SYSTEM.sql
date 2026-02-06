-- SCRIPT PARA REPARAR EL SISTEMA DE REPORTES Y SUS FUNCIONES
-- Soluciona el error: relation "historial_reportes_usuario" does not exist

-- 1. Crear la tabla de historial si no existe (algunas funciones la requieren para límites de spam)
CREATE TABLE IF NOT EXISTS public.historial_reportes_usuario (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    usuario_id UUID REFERENCES auth.users(id) ON DELETE CASCADE,
    ultimo_reporte TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    conteo_diario INTEGER DEFAULT 1,
    bloqueado_hasta TIMESTAMP WITH TIME ZONE,
    UNIQUE(usuario_id)
);

-- 2. Asegurar que la tabla principal de reportes existe (ya debería existir por el script definitivo)
CREATE TABLE IF NOT EXISTS public.reportes (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    reportante_id UUID REFERENCES auth.users(id),
    usuario_reportado_id UUID REFERENCES auth.users(id),
    contenido_tipo TEXT, -- 'usuario', 'post', 'evento', 'mensaje'
    contenido_id TEXT,
    categoria TEXT,
    descripcion TEXT,
    urgencia TEXT DEFAULT 'media',
    estatus TEXT DEFAULT 'pendiente',
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- 3. Función para verificar si un usuario puede reportar (Lógica anti-spam)
DROP FUNCTION IF EXISTS public.puede_reportar(UUID);
CREATE OR REPLACE FUNCTION public.puede_reportar(usuario_id_param UUID)
RETURNS JSONB
LANGUAGE plpgsql
SECURITY DEFINER
AS $$
DECLARE
    historial RECORD;
    resultado JSONB;
BEGIN
    -- Obtener historial del usuario
    SELECT * INTO historial FROM public.historial_reportes_usuario 
    WHERE usuario_id = usuario_id_param;

    -- Si no tiene historial, puede reportar
    IF historial IS NULL THEN
        RETURN jsonb_build_object('puede', true);
    END IF;

    -- Verificar si está bloqueado temporalmente por abuso
    IF historial.bloqueado_hasta IS NOT NULL AND historial.bloqueado_hasta > NOW() THEN
        RETURN jsonb_build_object(
            'puede', false, 
            'razon', 'Has enviado demasiados reportes. Inténtalo de nuevo más tarde.'
        );
    END IF;

    -- Verificar límite diario (ejemplo: 10 reportes por día)
    IF historial.ultimo_reporte::date = NOW()::date AND historial.conteo_diario >= 10 THEN
        RETURN jsonb_build_object(
            'puede', false, 
            'razon', 'Has alcanzado el límite diario de reportes (10).'
        );
    END IF;

    RETURN jsonb_build_object(
        'puede', true,
        'reportes_disponibles_hoy', CASE 
            WHEN historial.ultimo_reporte::date = NOW()::date THEN 10 - historial.conteo_diario
            ELSE 10
        END
    );
END;
$$;

-- 4. Función para registrar el uso del sistema de reportes
DROP FUNCTION IF EXISTS public.registrar_reporte(UUID);
CREATE OR REPLACE FUNCTION public.registrar_reporte(usuario_id_param UUID)
RETURNS VOID
LANGUAGE plpgsql
SECURITY DEFINER
AS $$
BEGIN
    INSERT INTO public.historial_reportes_usuario (usuario_id, ultimo_reporte, conteo_diario)
    VALUES (usuario_id_param, NOW(), 1)
    ON CONFLICT (usuario_id) DO UPDATE SET
        conteo_diario = CASE 
            WHEN historial_reportes_usuario.ultimo_reporte::date = NOW()::date 
            THEN historial_reportes_usuario.conteo_diario + 1 
            ELSE 1 
        END,
        ultimo_reporte = NOW();
END;
$$;

-- 5. Dar permisos
GRANT ALL ON TABLE public.historial_reportes_usuario TO authenticated;
GRANT ALL ON TABLE public.historial_reportes_usuario TO service_role;
GRANT ALL ON TABLE public.reportes TO authenticated;
GRANT ALL ON TABLE public.reportes TO service_role;
GRANT EXECUTE ON FUNCTION public.puede_reportar(UUID) TO authenticated;
GRANT EXECUTE ON FUNCTION public.registrar_reporte(UUID) TO authenticated;

-- 6. Refrescar caché
NOTIFY pgrst, 'reload schema';
