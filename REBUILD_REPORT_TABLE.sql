-- SCRIPT PARA RECONSTRUIR LA TABLA DE REPORTES CON TIPOS DE DATOS CORRECTOS
-- Esto soluciona el error: invalid input syntax for type integer

-- 1. Eliminar la tabla existente para asegurar una estructura limpia
DROP TABLE IF EXISTS public.reportes CASCADE;

-- 2. Recrear la tabla con UUIDs en lugar de INTEGERS
CREATE TABLE public.reportes (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    reportante_id UUID REFERENCES auth.users(id),
    usuario_reportado_id UUID REFERENCES auth.users(id),
    contenido_tipo TEXT NOT NULL, -- 'usuario', 'post', 'evento', 'mensaje'
    contenido_id TEXT, -- Puede ser UUID o ID de texto según el contenido
    categoria TEXT NOT NULL,
    descripcion TEXT,
    urgencia TEXT DEFAULT 'media',
    estatus TEXT DEFAULT 'pendiente',
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- 3. Asegurar permisos
GRANT ALL ON TABLE public.reportes TO authenticated;
GRANT ALL ON TABLE public.reportes TO service_role;

-- 4. Re-confirmar permisos en historial_reportes_usuario por si acaso
GRANT ALL ON TABLE public.historial_reportes_usuario TO authenticated;
GRANT ALL ON TABLE public.historial_reportes_usuario TO service_role;

-- 5. Recargar esquema (PostgREST)
NOTIFY pgrst, 'reload schema';
