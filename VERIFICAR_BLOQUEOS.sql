-- ============================================
-- SCRIPT DE VERIFICACIÓN: Sistema de Bloqueos
-- ============================================
-- Fecha: 30 de Enero, 2026
-- Propósito: Diagnosticar y verificar el sistema de bloqueos
-- ============================================

-- ============================================
-- 1. VERIFICAR EXISTENCIA DE TABLAS
-- ============================================

SELECT 
    '1. Verificación de Tablas' as seccion,
    table_name,
    CASE 
        WHEN table_name = 'usuarios_bloqueados' THEN '✅ CORRECTO'
        WHEN table_name = 'bloqueos' THEN '⚠️ TABLA ANTIGUA (no usar)'
        ELSE '❓ DESCONOCIDO'
    END as estado
FROM information_schema.tables 
WHERE table_schema = 'public' 
AND table_name IN ('bloqueos', 'usuarios_bloqueados')
ORDER BY table_name;

-- ============================================
-- 2. ESTRUCTURA DE LA TABLA CORRECTA
-- ============================================

SELECT 
    '2. Estructura de usuarios_bloqueados' as seccion,
    column_name,
    data_type,
    is_nullable,
    column_default
FROM information_schema.columns
WHERE table_name = 'usuarios_bloqueados'
ORDER BY ordinal_position;

-- ============================================
-- 3. ESTADÍSTICAS DE BLOQUEOS
-- ============================================

SELECT 
    '3. Estadísticas Generales' as seccion,
    COUNT(*) as total_registros,
    COUNT(CASE WHEN activo = TRUE THEN 1 END) as bloqueos_activos,
    COUNT(CASE WHEN activo = FALSE THEN 1 END) as bloqueos_inactivos,
    COUNT(DISTINCT usuario_id) as usuarios_que_bloquearon,
    COUNT(DISTINCT bloqueado_id) as usuarios_bloqueados
FROM usuarios_bloqueados;

-- ============================================
-- 4. ÚLTIMOS 10 BLOQUEOS
-- ============================================

SELECT 
    '4. Últimos Bloqueos' as seccion,
    ub.id,
    bloqueador.nombre_artistico as quien_bloquea,
    bloqueado.nombre_artistico as quien_es_bloqueado,
    ub.motivo_bloqueo,
    ub.activo,
    ub.bloqueado_en,
    ub.desbloqueado_en
FROM usuarios_bloqueados ub
LEFT JOIN profiles bloqueador ON ub.usuario_id = bloqueador.id
LEFT JOIN profiles bloqueado ON ub.bloqueado_id = bloqueado.id
ORDER BY ub.created_at DESC
LIMIT 10;

-- ============================================
-- 5. BLOQUEOS POR MOTIVO
-- ============================================

SELECT 
    '5. Bloqueos por Motivo' as seccion,
    motivo_bloqueo,
    COUNT(*) as cantidad,
    COUNT(CASE WHEN activo = TRUE THEN 1 END) as activos
FROM usuarios_bloqueados
GROUP BY motivo_bloqueo
ORDER BY cantidad DESC;

-- ============================================
-- 6. USUARIOS CON MÁS BLOQUEOS REALIZADOS
-- ============================================

SELECT 
    '6. Top Usuarios que Bloquean' as seccion,
    p.nombre_artistico,
    p.id as usuario_id,
    COUNT(*) as total_bloqueos,
    COUNT(CASE WHEN ub.activo = TRUE THEN 1 END) as bloqueos_activos
FROM usuarios_bloqueados ub
JOIN profiles p ON ub.usuario_id = p.id
GROUP BY p.id, p.nombre_artistico
ORDER BY total_bloqueos DESC
LIMIT 10;

-- ============================================
-- 7. USUARIOS MÁS BLOQUEADOS
-- ============================================

SELECT 
    '7. Top Usuarios Bloqueados' as seccion,
    p.nombre_artistico,
    p.id as usuario_id,
    COUNT(*) as veces_bloqueado,
    COUNT(CASE WHEN ub.activo = TRUE THEN 1 END) as bloqueos_activos
FROM usuarios_bloqueados ub
JOIN profiles p ON ub.bloqueado_id = p.id
GROUP BY p.id, p.nombre_artistico
ORDER BY veces_bloqueado DESC
LIMIT 10;

-- ============================================
-- 8. VERIFICAR ÍNDICES
-- ============================================

SELECT 
    '8. Índices de la Tabla' as seccion,
    indexname,
    indexdef
FROM pg_indexes
WHERE tablename = 'usuarios_bloqueados'
ORDER BY indexname;

-- ============================================
-- 9. VERIFICAR POLÍTICAS RLS
-- ============================================

SELECT 
    '9. Políticas RLS' as seccion,
    policyname,
    cmd,
    qual,
    with_check
FROM pg_policies
WHERE tablename = 'usuarios_bloqueados'
ORDER BY policyname;

-- ============================================
-- 10. BLOQUEOS RECIENTES (ÚLTIMAS 24 HORAS)
-- ============================================

SELECT 
    '10. Bloqueos Últimas 24h' as seccion,
    COUNT(*) as total,
    COUNT(CASE WHEN activo = TRUE THEN 1 END) as activos,
    COUNT(CASE WHEN activo = FALSE THEN 1 END) as desbloqueados
FROM usuarios_bloqueados
WHERE bloqueado_en >= NOW() - INTERVAL '24 hours';

-- ============================================
-- 11. QUERY PARA DEBUGGING ESPECÍFICO
-- ============================================
-- Reemplaza 'TU-UUID-AQUI' con el UUID del usuario que reporta el problema

/*
SELECT 
    '11. Bloqueos de Usuario Específico' as seccion,
    ub.id,
    ub.usuario_id as quien_bloquea_id,
    bloqueador.nombre_artistico as quien_bloquea,
    ub.bloqueado_id as quien_es_bloqueado_id,
    bloqueado.nombre_artistico as quien_es_bloqueado,
    ub.motivo_bloqueo,
    ub.activo,
    ub.bloqueado_en,
    ub.desbloqueado_en,
    ub.razon
FROM usuarios_bloqueados ub
LEFT JOIN profiles bloqueador ON ub.usuario_id = bloqueador.id
LEFT JOIN profiles bloqueado ON ub.bloqueado_id = bloqueado.id
WHERE ub.usuario_id = 'TU-UUID-AQUI'
ORDER BY ub.bloqueado_en DESC;
*/

-- ============================================
-- 12. VERIFICAR FOREIGN KEYS
-- ============================================

SELECT 
    '12. Foreign Keys' as seccion,
    tc.constraint_name,
    tc.table_name,
    kcu.column_name,
    ccu.table_name AS foreign_table_name,
    ccu.column_name AS foreign_column_name
FROM information_schema.table_constraints AS tc
JOIN information_schema.key_column_usage AS kcu
    ON tc.constraint_name = kcu.constraint_name
    AND tc.table_schema = kcu.table_schema
JOIN information_schema.constraint_column_usage AS ccu
    ON ccu.constraint_name = tc.constraint_name
    AND ccu.table_schema = tc.table_schema
WHERE tc.constraint_type = 'FOREIGN KEY'
    AND tc.table_name = 'usuarios_bloqueados';

-- ============================================
-- FIN DEL SCRIPT DE VERIFICACIÓN
-- ============================================

-- INSTRUCCIONES:
-- 1. Ejecuta este script completo en Supabase SQL Editor
-- 2. Revisa cada sección para identificar problemas
-- 3. Si la tabla 'usuarios_bloqueados' no existe, ejecuta el script de creación
-- 4. Si hay registros en tabla 'bloqueos', necesitas migrar los datos

-- NOTAS:
-- - La tabla correcta es 'usuarios_bloqueados'
-- - Columnas: usuario_id (quien bloquea), bloqueado_id (quien es bloqueado)
-- - Campo 'activo' indica si el bloqueo está vigente
-- - Los desbloqueos marcan activo=false, no eliminan el registro
