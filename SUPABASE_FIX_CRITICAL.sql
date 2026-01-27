-- ========================================================
-- 🔧 SCRIPT DE CORRECCIÓN CRÍTICA - ÓOLALE MOBILE
-- ========================================================
-- Ejecutar DESPUÉS de SUPABASE_SETUP.sql
-- Corrige inconsistencias de nombres de columnas

-- 1. CORREGIR TABLA INTERCOM (CRÍTICO)
-- --------------------------------------------------------
ALTER TABLE public.intercom 
RENAME COLUMN id TO id_mensaje;

ALTER TABLE public.intercom 
RENAME COLUMN remitente_id TO id_remitente;

ALTER TABLE public.intercom 
RENAME COLUMN destinatario_id TO id_destinatario;

ALTER TABLE public.intercom 
RENAME COLUMN created_at TO fecha_envio;

-- 2. AGREGAR ÍNDICES PARA PERFORMANCE
-- --------------------------------------------------------
CREATE INDEX IF NOT EXISTS idx_intercom_conversation 
ON public.intercom(id_remitente, id_destinatario);

CREATE INDEX IF NOT EXISTS idx_intercom_fecha 
ON public.intercom(fecha_envio DESC);

-- 3. CORREGIR POLÍTICAS RLS
-- --------------------------------------------------------
DROP POLICY IF EXISTS "Intercom solo entre involucrados" ON public.intercom;

CREATE POLICY "Intercom solo entre involucrados" 
    ON public.intercom FOR SELECT 
    USING (auth.uid() = id_remitente OR auth.uid() = id_destinatario);

CREATE POLICY "Enviar mensajes" 
    ON public.intercom FOR INSERT 
    WITH CHECK (auth.uid() = id_remitente);

-- 4. VERIFICACIÓN (Opcional - para debugging)
-- --------------------------------------------------------
DO $$
BEGIN
    RAISE NOTICE 'Verificando estructura de tabla intercom...';
END $$;

SELECT column_name, data_type 
FROM information_schema.columns 
WHERE table_name = 'intercom'
ORDER BY ordinal_position;
