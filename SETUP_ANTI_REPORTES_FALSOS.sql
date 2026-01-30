-- ============================================================================
-- SISTEMA DE PROTECCIÓN CONTRA REPORTES FALSOS
-- ============================================================================
-- Ejecuta esto en Supabase SQL Editor

-- 1. Agregar campos de tracking a la tabla reportes (si no existen)
ALTER TABLE reportes 
ADD COLUMN IF NOT EXISTS es_falso BOOLEAN DEFAULT FALSE,
ADD COLUMN IF NOT EXISTS verificado_por UUID REFERENCES profiles(id),
ADD COLUMN IF NOT EXISTS fecha_verificacion TIMESTAMP WITH TIME ZONE,
ADD COLUMN IF NOT EXISTS notas_verificacion TEXT;

-- 2. Tabla de historial de reportes por usuario
CREATE TABLE IF NOT EXISTS historial_reportes_usuario (
    id SERIAL PRIMARY KEY,
    usuario_id UUID NOT NULL REFERENCES profiles(id) ON DELETE CASCADE,
    
    -- Contadores
    total_reportes_enviados INTEGER DEFAULT 0,
    reportes_validos INTEGER DEFAULT 0,
    reportes_falsos INTEGER DEFAULT 0,
    reportes_pendientes INTEGER DEFAULT 0,
    
    -- Puntuación de confiabilidad (0-100)
    puntuacion_confiabilidad INTEGER DEFAULT 100,
    
    -- Estado del usuario
    puede_reportar BOOLEAN DEFAULT TRUE,
    razon_suspension TEXT,
    fecha_suspension TIMESTAMP WITH TIME ZONE,
    fecha_fin_suspension TIMESTAMP WITH TIME ZONE,
    
    -- Límites
    reportes_hoy INTEGER DEFAULT 0,
    reportes_esta_semana INTEGER DEFAULT 0,
    reportes_este_mes INTEGER DEFAULT 0,
    ultima_fecha_reporte TIMESTAMP WITH TIME ZONE,
    
    -- Advertencias
    advertencias_recibidas INTEGER DEFAULT 0,
    ultima_advertencia TIMESTAMP WITH TIME ZONE,
    
    created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP
);

-- 3. Tabla de límites y reglas
CREATE TABLE IF NOT EXISTS reglas_reportes (
    id SERIAL PRIMARY KEY,
    nombre VARCHAR(100) NOT NULL,
    descripcion TEXT,
    
    -- Límites por tiempo
    max_reportes_por_dia INTEGER DEFAULT 5,
    max_reportes_por_semana INTEGER DEFAULT 15,
    max_reportes_por_mes INTEGER DEFAULT 30,
    
    -- Umbrales de suspensión
    umbral_reportes_falsos INTEGER DEFAULT 3, -- 3 reportes falsos = suspensión
    dias_suspension_primera_vez INTEGER DEFAULT 7,
    dias_suspension_segunda_vez INTEGER DEFAULT 30,
    dias_suspension_tercera_vez INTEGER DEFAULT 365, -- 1 año
    
    -- Puntuación
    puntos_perdidos_por_falso INTEGER DEFAULT 20,
    puntos_ganados_por_valido INTEGER DEFAULT 5,
    puntuacion_minima_para_reportar INTEGER DEFAULT 30,
    
    activo BOOLEAN DEFAULT TRUE,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP
);

-- Insertar reglas por defecto
INSERT INTO reglas_reportes (nombre, descripcion) 
VALUES ('Reglas por defecto', 'Configuración inicial del sistema de reportes')
ON CONFLICT DO NOTHING;

-- 4. Función para verificar si un usuario puede reportar
CREATE OR REPLACE FUNCTION puede_reportar(usuario_id_param UUID)
RETURNS TABLE (
    puede BOOLEAN,
    razon TEXT,
    reportes_disponibles_hoy INTEGER
) 
LANGUAGE plpgsql
AS $$
DECLARE
    historial RECORD;
    reglas RECORD;
BEGIN
    -- Obtener historial del usuario (crear si no existe)
    SELECT * INTO historial 
    FROM historial_reportes_usuario 
    WHERE usuario_id = usuario_id_param;
    
    IF NOT FOUND THEN
        -- Crear historial para nuevo usuario
        INSERT INTO historial_reportes_usuario (usuario_id)
        VALUES (usuario_id_param)
        RETURNING * INTO historial;
    END IF;
    
    -- Obtener reglas activas
    SELECT * INTO reglas 
    FROM reglas_reportes 
    WHERE activo = TRUE 
    ORDER BY created_at DESC 
    LIMIT 1;
    
    -- Verificar si está suspendido
    IF NOT historial.puede_reportar THEN
        IF historial.fecha_fin_suspension IS NOT NULL AND 
           historial.fecha_fin_suspension > CURRENT_TIMESTAMP THEN
            RETURN QUERY SELECT 
                FALSE, 
                'Tu cuenta está suspendida por reportes falsos hasta ' || 
                TO_CHAR(historial.fecha_fin_suspension, 'DD/MM/YYYY'),
                0;
            RETURN;
        ELSE
            -- Suspensión expiró, reactivar
            UPDATE historial_reportes_usuario 
            SET puede_reportar = TRUE,
                razon_suspension = NULL,
                fecha_suspension = NULL,
                fecha_fin_suspension = NULL
            WHERE usuario_id = usuario_id_param;
        END IF;
    END IF;
    
    -- Verificar puntuación de confiabilidad
    IF historial.puntuacion_confiabilidad < reglas.puntuacion_minima_para_reportar THEN
        RETURN QUERY SELECT 
            FALSE,
            'Tu puntuación de confiabilidad es muy baja. Contacta a soporte.',
            0;
        RETURN;
    END IF;
    
    -- Resetear contadores si es un nuevo día
    IF historial.ultima_fecha_reporte IS NULL OR 
       DATE(historial.ultima_fecha_reporte) < CURRENT_DATE THEN
        UPDATE historial_reportes_usuario 
        SET reportes_hoy = 0
        WHERE usuario_id = usuario_id_param;
        historial.reportes_hoy := 0;
    END IF;
    
    -- Verificar límite diario
    IF historial.reportes_hoy >= reglas.max_reportes_por_dia THEN
        RETURN QUERY SELECT 
            FALSE,
            'Has alcanzado el límite de reportes por hoy (' || 
            reglas.max_reportes_por_dia || ')',
            0;
        RETURN;
    END IF;
    
    -- Verificar límite semanal
    IF historial.reportes_esta_semana >= reglas.max_reportes_por_semana THEN
        RETURN QUERY SELECT 
            FALSE,
            'Has alcanzado el límite de reportes por semana (' || 
            reglas.max_reportes_por_semana || ')',
            0;
        RETURN;
    END IF;
    
    -- Verificar límite mensual
    IF historial.reportes_este_mes >= reglas.max_reportes_por_mes THEN
        RETURN QUERY SELECT 
            FALSE,
            'Has alcanzado el límite de reportes por mes (' || 
            reglas.max_reportes_por_mes || ')',
            0;
        RETURN;
    END IF;
    
    -- Usuario puede reportar
    RETURN QUERY SELECT 
        TRUE,
        'Puedes reportar',
        (reglas.max_reportes_por_dia - historial.reportes_hoy);
    RETURN;
END;
$$;

-- 5. Función para registrar un nuevo reporte
CREATE OR REPLACE FUNCTION registrar_reporte(usuario_id_param UUID)
RETURNS VOID
LANGUAGE plpgsql
AS $$
BEGIN
    -- Actualizar o crear historial
    INSERT INTO historial_reportes_usuario (
        usuario_id,
        total_reportes_enviados,
        reportes_pendientes,
        reportes_hoy,
        reportes_esta_semana,
        reportes_este_mes,
        ultima_fecha_reporte
    ) VALUES (
        usuario_id_param,
        1,
        1,
        1,
        1,
        1,
        CURRENT_TIMESTAMP
    )
    ON CONFLICT (usuario_id) DO UPDATE SET
        total_reportes_enviados = historial_reportes_usuario.total_reportes_enviados + 1,
        reportes_pendientes = historial_reportes_usuario.reportes_pendientes + 1,
        reportes_hoy = historial_reportes_usuario.reportes_hoy + 1,
        reportes_esta_semana = historial_reportes_usuario.reportes_esta_semana + 1,
        reportes_este_mes = historial_reportes_usuario.reportes_este_mes + 1,
        ultima_fecha_reporte = CURRENT_TIMESTAMP,
        updated_at = CURRENT_TIMESTAMP;
END;
$$;

-- 6. Función para marcar reporte como falso (solo admin)
CREATE OR REPLACE FUNCTION marcar_reporte_falso(
    reporte_id_param INTEGER,
    admin_id_param UUID,
    notas_param TEXT
)
RETURNS VOID
LANGUAGE plpgsql
AS $$
DECLARE
    reportante_id_var UUID;
    historial RECORD;
    reglas RECORD;
    nueva_puntuacion INTEGER;
    dias_suspension INTEGER;
BEGIN
    -- Obtener ID del reportante
    SELECT reportante_id INTO reportante_id_var
    FROM reportes
    WHERE id = reporte_id_param;
    
    IF NOT FOUND THEN
        RAISE EXCEPTION 'Reporte no encontrado';
    END IF;
    
    -- Marcar reporte como falso
    UPDATE reportes
    SET es_falso = TRUE,
        verificado_por = admin_id_param,
        fecha_verificacion = CURRENT_TIMESTAMP,
        notas_verificacion = notas_param,
        estatus = 'rechazado'
    WHERE id = reporte_id_param;
    
    -- Obtener historial y reglas
    SELECT * INTO historial FROM historial_reportes_usuario WHERE usuario_id = reportante_id_var;
    SELECT * INTO reglas FROM reglas_reportes WHERE activo = TRUE ORDER BY created_at DESC LIMIT 1;
    
    -- Actualizar contadores
    UPDATE historial_reportes_usuario
    SET reportes_falsos = reportes_falsos + 1,
        reportes_pendientes = GREATEST(reportes_pendientes - 1, 0),
        puntuacion_confiabilidad = GREATEST(
            puntuacion_confiabilidad - reglas.puntos_perdidos_por_falso, 
            0
        ),
        advertencias_recibidas = advertencias_recibidas + 1,
        ultima_advertencia = CURRENT_TIMESTAMP,
        updated_at = CURRENT_TIMESTAMP
    WHERE usuario_id = reportante_id_var
    RETURNING * INTO historial;
    
    -- Verificar si debe ser suspendido
    IF historial.reportes_falsos >= reglas.umbral_reportes_falsos THEN
        -- Calcular días de suspensión según número de suspensiones previas
        IF historial.advertencias_recibidas <= 3 THEN
            dias_suspension := reglas.dias_suspension_primera_vez;
        ELSIF historial.advertencias_recibidas <= 6 THEN
            dias_suspension := reglas.dias_suspension_segunda_vez;
        ELSE
            dias_suspension := reglas.dias_suspension_tercera_vez;
        END IF;
        
        -- Suspender usuario
        UPDATE historial_reportes_usuario
        SET puede_reportar = FALSE,
            razon_suspension = 'Múltiples reportes falsos detectados',
            fecha_suspension = CURRENT_TIMESTAMP,
            fecha_fin_suspension = CURRENT_TIMESTAMP + (dias_suspension || ' days')::INTERVAL
        WHERE usuario_id = reportante_id_var;
        
        -- TODO: Enviar notificación al usuario
    END IF;
END;
$$;

-- 7. Función para marcar reporte como válido (solo admin)
CREATE OR REPLACE FUNCTION marcar_reporte_valido(
    reporte_id_param INTEGER,
    admin_id_param UUID,
    notas_param TEXT
)
RETURNS VOID
LANGUAGE plpgsql
AS $$
DECLARE
    reportante_id_var UUID;
    reglas RECORD;
BEGIN
    -- Obtener ID del reportante
    SELECT reportante_id INTO reportante_id_var
    FROM reportes
    WHERE id = reporte_id_param;
    
    IF NOT FOUND THEN
        RAISE EXCEPTION 'Reporte no encontrado';
    END IF;
    
    -- Marcar reporte como válido
    UPDATE reportes
    SET es_falso = FALSE,
        verificado_por = admin_id_param,
        fecha_verificacion = CURRENT_TIMESTAMP,
        notas_verificacion = notas_param,
        estatus = 'confirmado'
    WHERE id = reporte_id_param;
    
    -- Obtener reglas
    SELECT * INTO reglas FROM reglas_reportes WHERE activo = TRUE ORDER BY created_at DESC LIMIT 1;
    
    -- Actualizar contadores y mejorar puntuación
    UPDATE historial_reportes_usuario
    SET reportes_validos = reportes_validos + 1,
        reportes_pendientes = GREATEST(reportes_pendientes - 1, 0),
        puntuacion_confiabilidad = LEAST(
            puntuacion_confiabilidad + reglas.puntos_ganados_por_valido, 
            100
        ),
        updated_at = CURRENT_TIMESTAMP
    WHERE usuario_id = reportante_id_var;
END;
$$;

-- 8. Función para resetear contadores semanales (ejecutar con cron)
CREATE OR REPLACE FUNCTION resetear_contadores_semanales()
RETURNS VOID
LANGUAGE plpgsql
AS $$
BEGIN
    UPDATE historial_reportes_usuario
    SET reportes_esta_semana = 0,
        updated_at = CURRENT_TIMESTAMP;
END;
$$;

-- 9. Función para resetear contadores mensuales (ejecutar con cron)
CREATE OR REPLACE FUNCTION resetear_contadores_mensuales()
RETURNS VOID
LANGUAGE plpgsql
AS $$
BEGIN
    UPDATE historial_reportes_usuario
    SET reportes_este_mes = 0,
        updated_at = CURRENT_TIMESTAMP;
END;
$$;

-- 10. Índices para mejorar performance
CREATE INDEX IF NOT EXISTS idx_historial_reportes_usuario_id ON historial_reportes_usuario(usuario_id);
CREATE INDEX IF NOT EXISTS idx_historial_reportes_puede_reportar ON historial_reportes_usuario(puede_reportar);
CREATE INDEX IF NOT EXISTS idx_historial_reportes_puntuacion ON historial_reportes_usuario(puntuacion_confiabilidad);
CREATE INDEX IF NOT EXISTS idx_reportes_es_falso ON reportes(es_falso);
CREATE INDEX IF NOT EXISTS idx_reportes_verificado ON reportes(verificado_por);

-- 11. Permisos
GRANT SELECT ON historial_reportes_usuario TO authenticated;
GRANT SELECT ON reglas_reportes TO authenticated;
GRANT EXECUTE ON FUNCTION puede_reportar(UUID) TO authenticated;
GRANT EXECUTE ON FUNCTION registrar_reporte(UUID) TO authenticated;

-- Solo admins pueden marcar reportes como falsos/válidos
-- GRANT EXECUTE ON FUNCTION marcar_reporte_falso(INTEGER, UUID, TEXT) TO admin_role;
-- GRANT EXECUTE ON FUNCTION marcar_reporte_valido(INTEGER, UUID, TEXT) TO admin_role;

-- ============================================================================
-- NOTAS DE IMPLEMENTACIÓN
-- ============================================================================

/*
CÓMO FUNCIONA:

1. LÍMITES AUTOMÁTICOS:
   - 5 reportes por día
   - 15 reportes por semana
   - 30 reportes por mes

2. PUNTUACIÓN DE CONFIABILIDAD (0-100):
   - Empieza en 100
   - Pierde 20 puntos por reporte falso
   - Gana 5 puntos por reporte válido
   - Si baja de 30, no puede reportar

3. SUSPENSIONES:
   - 3 reportes falsos = suspensión
   - Primera vez: 7 días
   - Segunda vez: 30 días
   - Tercera vez: 1 año

4. USO EN LA APP:
   - Antes de mostrar pantalla de reporte, llamar: puede_reportar(user_id)
   - Después de enviar reporte, llamar: registrar_reporte(user_id)
   - Admins marcan reportes como falsos/válidos desde panel

5. MANTENIMIENTO:
   - Ejecutar resetear_contadores_semanales() cada lunes
   - Ejecutar resetear_contadores_mensuales() el día 1 de cada mes
   - Usar Supabase Edge Functions o cron jobs
*/

