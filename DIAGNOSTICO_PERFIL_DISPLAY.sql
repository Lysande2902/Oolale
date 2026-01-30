-- ============================================
-- DIAGNÓSTICO: Perfil No Se Muestra
-- ============================================
-- Este script verifica por qué el perfil no se muestra
-- aunque los datos existen en la base de datos

-- 1. VERIFICAR QUE EL PERFIL EXISTE
-- ============================================
SELECT 
  'PERFIL EXISTE' as verificacion,
  id,
  email,
  nombre_artistico,
  bio,
  ubicacion,
  instrumento_principal,
  foto_perfil,
  created_at,
  updated_at
FROM profiles
WHERE email = 'salas@gmail.com'  -- REEMPLAZA CON TU EMAIL
LIMIT 1;

-- 2. VERIFICAR VALORES NULL
-- ============================================
SELECT 
  'VALORES NULL' as verificacion,
  CASE WHEN nombre_artistico IS NULL THEN '❌ NULL' ELSE '✅ ' || nombre_artistico END as nombre_artistico,
  CASE WHEN bio IS NULL THEN '❌ NULL' ELSE '✅ Tiene bio (' || LENGTH(bio) || ' caracteres)' END as bio,
  CASE WHEN ubicacion IS NULL THEN '❌ NULL' ELSE '✅ ' || ubicacion END as ubicacion,
  CASE WHEN instrumento_principal IS NULL THEN '❌ NULL' ELSE '✅ ' || instrumento_principal END as instrumento_principal,
  CASE WHEN foto_perfil IS NULL THEN '❌ NULL' ELSE '✅ Tiene foto' END as foto_perfil
FROM profiles
WHERE email = 'salas@gmail.com';  -- REEMPLAZA CON TU EMAIL

-- 3. VERIFICAR INSTRUMENTOS (GEAR)
-- ============================================
SELECT 
  'INSTRUMENTOS' as verificacion,
  COUNT(*) as total_instrumentos,
  STRING_AGG(gc.nombre, ', ') as lista_instrumentos
FROM perfil_gear pg
JOIN gear_catalog gc ON pg.gear_id = gc.id
WHERE pg.perfil_id = (SELECT id FROM profiles WHERE email = 'salas@gmail.com');  -- REEMPLAZA CON TU EMAIL

-- 4. VERIFICAR ESTADÍSTICAS
-- ============================================
SELECT 
  'ESTADÍSTICAS' as verificacion,
  (SELECT COUNT(*) FROM gig_lineup WHERE perfil_id = p.id) as eventos,
  (SELECT COUNT(*) FROM connections WHERE conectado_id = p.id AND estatus = 'accepted') as seguidores,
  (SELECT COUNT(*) FROM perfil_gear WHERE perfil_id = p.id) as equipo,
  p.total_calificaciones as ratings,
  p.rating_promedio as rating_promedio
FROM profiles p
WHERE p.email = 'salas@gmail.com';  -- REEMPLAZA CON TU EMAIL

-- 5. VERIFICAR BADGES Y FLAGS
-- ============================================
SELECT 
  'BADGES' as verificacion,
  CASE WHEN open_to_work = true THEN '✅ Disponible' ELSE '❌ No disponible' END as disponible,
  CASE WHEN ranking_tipo = 'premium' THEN '✅ PREMIUM' ELSE '❌ Regular' END as premium,
  CASE WHEN verificado = true THEN '✅ Verificado' ELSE '❌ No verificado' END as verificado,
  CASE WHEN perfil_completo = true THEN '✅ Completo' ELSE '❌ Incompleto' END as perfil_completo
FROM profiles
WHERE email = 'salas@gmail.com';  -- REEMPLAZA CON TU EMAIL

-- 6. VERIFICAR ÚLTIMA ACTUALIZACIÓN
-- ============================================
SELECT 
  'ÚLTIMA ACTUALIZACIÓN' as verificacion,
  updated_at,
  NOW() - updated_at as tiempo_desde_actualizacion,
  CASE 
    WHEN updated_at > NOW() - INTERVAL '1 minute' THEN '✅ Actualizado hace menos de 1 minuto'
    WHEN updated_at > NOW() - INTERVAL '1 hour' THEN '⚠️ Actualizado hace ' || EXTRACT(MINUTE FROM NOW() - updated_at) || ' minutos'
    WHEN updated_at > NOW() - INTERVAL '1 day' THEN '⚠️ Actualizado hace ' || EXTRACT(HOUR FROM NOW() - updated_at) || ' horas'
    ELSE '❌ Actualizado hace más de 1 día'
  END as estado_actualizacion
FROM profiles
WHERE email = 'salas@gmail.com';  -- REEMPLAZA CON TU EMAIL

-- 7. COMPARAR CON OTRO USUARIO (OPCIONAL)
-- ============================================
-- Descomenta esto para comparar con otro usuario que SÍ funciona
/*
SELECT 
  'COMPARACIÓN' as verificacion,
  email,
  nombre_artistico,
  CASE WHEN bio IS NULL THEN 'NULL' ELSE 'Tiene bio' END as bio,
  CASE WHEN ubicacion IS NULL THEN 'NULL' ELSE ubicacion END as ubicacion,
  CASE WHEN instrumento_principal IS NULL THEN 'NULL' ELSE instrumento_principal END as instrumento_principal
FROM profiles
WHERE email IN ('salas@gmail.com', 'otro_usuario@gmail.com')  -- REEMPLAZA CON TU EMAIL Y OTRO
ORDER BY email;
*/

-- ============================================
-- RESULTADO ESPERADO:
-- ============================================
-- Si todo está bien, deberías ver:
-- 1. ✅ Perfil existe con tu email
-- 2. ✅ Todos los campos tienen valores (no NULL)
-- 3. ✅ Lista de instrumentos (si agregaste)
-- 4. ✅ Estadísticas (pueden ser 0)
-- 5. ✅ Badges según tu configuración
-- 6. ✅ Actualizado recientemente

-- ============================================
-- SI VES PROBLEMAS:
-- ============================================
-- ❌ Si nombre_artistico es NULL → Edita el perfil y guarda
-- ❌ Si bio es NULL → Es normal, pero puedes agregar una
-- ❌ Si ubicacion es NULL → Agrega una ubicación
-- ❌ Si instrumento_principal es NULL → Agrega tu instrumento
-- ❌ Si no hay instrumentos → Agrega en "Mi Equipo"
-- ❌ Si updated_at es muy antiguo → Edita y guarda de nuevo
