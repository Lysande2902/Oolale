-- SCRIPT DEFINITIVO PARA REPARAR EL SISTEMA DE REPORTES (V2)
-- Soluciona:
-- 1. Error de sintaxis (UUID vs Integer)
-- 2. Tabla de historial faltante
-- 3. Funciones RPC con tipos de retorno correctos
-- 4. Datos de conteo para la interfaz de UI

-- 1. Limpieza preventiva
DROP TABLE IF EXISTS public.reportes CASCADE;
DROP FUNCTION IF EXISTS public.puede_reportar(UUID);
DROP FUNCTION IF EXISTS public.registrar_reporte(UUID);

-- 2. Crear tabla de historial
CREATE TABLE IF NOT EXISTS public.historial_reportes_usuario (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    usuario_id UUID REFERENCES auth.users(id) ON DELETE CASCADE,
    ultimo_reporte TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    conteo_diario INTEGER DEFAULT 0,
    bloqueado_hasta TIMESTAMP WITH TIME ZONE,
    UNIQUE(usuario_id)
);

-- 3. Crear tabla de reportes (ESTRUCTURA CORRECTA)
CREATE TABLE public.reportes (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    reportante_id UUID REFERENCES auth.users(id),
    usuario_reportado_id UUID REFERENCES auth.users(id),
    contenido_tipo TEXT NOT NULL, -- 'usuario', 'post', 'evento', 'mensaje'
    contenido_id TEXT, 
    categoria TEXT NOT NULL,
    descripcion TEXT,
    urgencia TEXT DEFAULT 'media',
    estatus TEXT DEFAULT 'pendiente',
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- 4. Función: puede_reportar
CREATE OR REPLACE FUNCTION public.puede_reportar(usuario_id_param UUID)
RETURNS JSONB
LANGUAGE plpgsql
SECURITY DEFINER
AS $$
DECLARE
    historial RECORD;
BEGIN
    SELECT * INTO historial FROM public.historial_reportes_usuario 
    WHERE usuario_id = usuario_id_param;

    -- Si no hay historial, tiene todos los reportes disponibles
    IF historial IS NULL THEN
        RETURN jsonb_build_object(
            'puede', true,
            'reportes_disponibles_hoy', 10
        );
    END IF;

    -- Verificar bloqueo
    IF historial.bloqueado_hasta IS NOT NULL AND historial.bloqueado_hasta > NOW() THEN
        RETURN jsonb_build_object(
            'puede', false, 
            'razon', 'Has sido bloqueado temporalmente del sistema de reportes por abuso.'
        );
    END IF;

    -- Verificar límite diario
    IF historial.ultimo_reporte::date = NOW()::date AND historial.conteo_diario >= 10 THEN
        RETURN jsonb_build_object(
            'puede', false, 
            'razon', 'Has alcanzado el límite diario de 10 reportes. Inténtalo mañana.'
        );
    END IF;

    -- Retornar éxito con conteo
    RETURN jsonb_build_object(
        'puede', true,
        'reportes_disponibles_hoy', 
        CASE 
            WHEN historial.ultimo_reporte::date = NOW()::date THEN 10 - historial.conteo_diario
            ELSE 10
        END
    );
END;
$$;

-- 5. Función: registrar_reporte
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

-- 6. Permisos
GRANT ALL ON TABLE public.reportes TO authenticated;
GRANT ALL ON TABLE public.historial_reportes_usuario TO authenticated;
GRANT EXECUTE ON FUNCTION public.puede_reportar(UUID) TO authenticated;
GRANT EXECUTE ON FUNCTION public.registrar_reporte(UUID) TO authenticated;

-- 7. Refresh
NOTIFY pgrst, 'reload schema';
