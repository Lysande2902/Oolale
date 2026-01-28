-- ============================================
-- SCRIPT DE DATOS DE PRUEBA PARA ÓOLALE
-- ============================================
-- Este script crea usuarios CON ACCESO, perfiles, eventos y datos de prueba
-- para probar la funcionalidad completa de la aplicación

-- CONTRASEÑA PARA TODOS LOS USUARIOS DE PRUEBA: Test123456!

-- ============================================
-- IMPORTANTE: CREAR USUARIOS EN SUPABASE AUTH
-- ============================================
-- Estos usuarios deben crearse primero en Supabase Auth Dashboard
-- o usando la API de Supabase. Aquí están los datos:

/*
USUARIOS DE PRUEBA (Contraseña para todos: Test123456!)

1. maria.garcia@test.com
2. carlos.mendoza@test.com
3. ana.martinez@test.com
4. luis.hernandez@test.com
5. sofia.ramirez@test.com
6. roberto.sanchez@test.com
7. diana.lopez@test.com
8. miguel.torres@test.com

NOTA: Después de crear los usuarios en Auth, ejecuta este script
para crear sus perfiles y datos asociados.
*/

-- ============================================
-- 1. ACTUALIZAR/CREAR PERFILES PARA USUARIOS EXISTENTES
-- ============================================
-- Estos INSERT usarán los IDs de los usuarios que ya existen en auth.users

-- Usuario 1: María García - Guitarrista Premium
INSERT INTO profiles (id, nombre_artistico, bio_rider, instrumento_principal, rol_principal, ubicacion_base, open_to_work, verificado, nivel_badge, avatar_url, slug_url)
SELECT 
  id,
  'María García',
  'Guitarrista profesional con 10 años de experiencia en rock y blues. Disponible para sesiones de grabación y conciertos en vivo.',
  'Guitarra Eléctrica',
  'musico',
  'Ciudad de México, CDMX',
  true,
  true,
  'pro',
  'https://i.pravatar.cc/300?img=1',
  'maria-garcia'
FROM auth.users WHERE email = 'maria.garcia@test.com'
ON CONFLICT (id) DO UPDATE SET
  nombre_artistico = EXCLUDED.nombre_artistico,
  bio_rider = EXCLUDED.bio_rider,
  instrumento_principal = EXCLUDED.instrumento_principal,
  rol_principal = EXCLUDED.rol_principal,
  ubicacion_base = EXCLUDED.ubicacion_base,
  open_to_work = EXCLUDED.open_to_work,
  verificado = EXCLUDED.verificado,
  nivel_badge = EXCLUDED.nivel_badge,
  avatar_url = EXCLUDED.avatar_url,
  slug_url = EXCLUDED.slug_url;

-- Usuario 2: Carlos Mendoza - Baterista
INSERT INTO profiles (id, nombre_artistico, bio_rider, instrumento_principal, rol_principal, ubicacion_base, open_to_work, verificado, nivel_badge, slug_url, avatar_url)
SELECT 
  id,
  'Carlos "El Trueno" Mendoza',
  'Baterista de jazz y funk. He tocado con bandas reconocidas en festivales nacionales. Busco proyectos serios.',
  'Batería',
  'musico',
  'Guadalajara, Jalisco',
  true,
  true,
  'maestro',
  'carlos-mendoza',
  'https://i.pravatar.cc/300?img=11'
FROM auth.users WHERE email = 'carlos.mendoza@test.com'
ON CONFLICT (id) DO UPDATE SET
  nombre_artistico = EXCLUDED.nombre_artistico,
  bio_rider = EXCLUDED.bio_rider,
  instrumento_principal = EXCLUDED.instrumento_principal,
  rol_principal = EXCLUDED.rol_principal,
  ubicacion_base = EXCLUDED.ubicacion_base,
  open_to_work = EXCLUDED.open_to_work,
  verificado = EXCLUDED.verificado,
  nivel_badge = EXCLUDED.nivel_badge,
  slug_url = EXCLUDED.slug_url,
  avatar_url = EXCLUDED.avatar_url;

-- Usuario 3: Ana Martínez - Vocalista
INSERT INTO profiles (id, nombre_artistico, bio_rider, instrumento_principal, rol_principal, ubicacion_base, open_to_work, verificado, nivel_badge, avatar_url, slug_url)
SELECT 
  id,
  'Ana Martínez',
  'Vocalista versátil con rango de soprano. Especializada en pop, R&B y soul. Disponible para colaboraciones.',
  'Voz',
  'musico',
  'Monterrey, Nuevo León',
  true,
  false,
  'principiante',
  'https://i.pravatar.cc/300?img=5',
  'ana-martinez'
FROM auth.users WHERE email = 'ana.martinez@test.com'
ON CONFLICT (id) DO UPDATE SET
  nombre_artistico = EXCLUDED.nombre_artistico,
  bio_rider = EXCLUDED.bio_rider,
  instrumento_principal = EXCLUDED.instrumento_principal,
  rol_principal = EXCLUDED.rol_principal,
  ubicacion_base = EXCLUDED.ubicacion_base,
  open_to_work = EXCLUDED.open_to_work,
  verificado = EXCLUDED.verificado,
  nivel_badge = EXCLUDED.nivel_badge,
  avatar_url = EXCLUDED.avatar_url,
  slug_url = EXCLUDED.slug_url;

-- Usuario 4: Luis Hernández - Bajista Premium
INSERT INTO profiles (id, nombre_artistico, bio_rider, instrumento_principal, rol_principal, ubicacion_base, open_to_work, verificado, nivel_badge, avatar_url, slug_url)
SELECT 
  id,
  'Luis Bass Master',
  'Bajista de sesión con experiencia en múltiples géneros. He trabajado en más de 50 producciones discográficas.',
  'Bajo Eléctrico',
  'musico',
  'Puebla, Puebla',
  true,
  true,
  'pro',
  'https://i.pravatar.cc/300?img=12',
  'luis-hernandez'
FROM auth.users WHERE email = 'luis.hernandez@test.com'
ON CONFLICT (id) DO UPDATE SET
  nombre_artistico = EXCLUDED.nombre_artistico,
  bio_rider = EXCLUDED.bio_rider,
  instrumento_principal = EXCLUDED.instrumento_principal,
  rol_principal = EXCLUDED.rol_principal,
  ubicacion_base = EXCLUDED.ubicacion_base,
  open_to_work = EXCLUDED.open_to_work,
  verificado = EXCLUDED.verificado,
  nivel_badge = EXCLUDED.nivel_badge,
  avatar_url = EXCLUDED.avatar_url,
  slug_url = EXCLUDED.slug_url;

-- Usuario 5: Sofia Ramírez - Tecladista
INSERT INTO profiles (id, nombre_artistico, bio_rider, instrumento_principal, rol_principal, ubicacion_base, open_to_work, verificado, nivel_badge, slug_url, avatar_url)
SELECT 
  id,
  'Sofia Keys',
  'Tecladista y pianista clásica. Especializada en arreglos y producción musical. Busco proyectos creativos.',
  'Piano/Teclado',
  'musico',
  'Querétaro, Querétaro',
  true,
  false,
  'principiante',
  'sofia-ramirez',
  'https://i.pravatar.cc/300?img=9'
FROM auth.users WHERE email = 'sofia.ramirez@test.com'
ON CONFLICT (id) DO UPDATE SET
  nombre_artistico = EXCLUDED.nombre_artistico,
  bio_rider = EXCLUDED.bio_rider,
  instrumento_principal = EXCLUDED.instrumento_principal,
  rol_principal = EXCLUDED.rol_principal,
  ubicacion_base = EXCLUDED.ubicacion_base,
  open_to_work = EXCLUDED.open_to_work,
  verificado = EXCLUDED.verificado,
  nivel_badge = EXCLUDED.nivel_badge,
  slug_url = EXCLUDED.slug_url,
  avatar_url = EXCLUDED.avatar_url;

-- Usuario 6: Roberto Sánchez - Productor/Promotor
INSERT INTO profiles (id, nombre_artistico, bio_rider, instrumento_principal, rol_principal, ubicacion_base, open_to_work, verificado, nivel_badge, avatar_url, slug_url)
SELECT 
  id,
  'Roberto Sánchez',
  'Productor musical y promotor con 15 años en la industria. Busco talento emergente para proyectos profesionales.',
  'N/A',
  'promotor',
  'Ciudad de México, CDMX',
  true,
  true,
  'leyenda',
  'https://i.pravatar.cc/300?img=15',
  'roberto-sanchez'
FROM auth.users WHERE email = 'roberto.sanchez@test.com'
ON CONFLICT (id) DO UPDATE SET
  nombre_artistico = EXCLUDED.nombre_artistico,
  bio_rider = EXCLUDED.bio_rider,
  instrumento_principal = EXCLUDED.instrumento_principal,
  rol_principal = EXCLUDED.rol_principal,
  ubicacion_base = EXCLUDED.ubicacion_base,
  open_to_work = EXCLUDED.open_to_work,
  verificado = EXCLUDED.verificado,
  nivel_badge = EXCLUDED.nivel_badge,
  avatar_url = EXCLUDED.avatar_url,
  slug_url = EXCLUDED.slug_url;

-- Usuario 7: Diana López - Saxofonista
INSERT INTO profiles (id, nombre_artistico, bio_rider, instrumento_principal, rol_principal, ubicacion_base, open_to_work, verificado, nivel_badge, slug_url, avatar_url)
SELECT 
  id,
  'Diana Sax',
  'Saxofonista de jazz y música latina. Disponible para eventos corporativos y bodas.',
  'Saxofón',
  'musico',
  'Mérida, Yucatán',
  true,
  false,
  'principiante',
  'diana-lopez',
  'https://i.pravatar.cc/300?img=47'
FROM auth.users WHERE email = 'diana.lopez@test.com'
ON CONFLICT (id) DO UPDATE SET
  nombre_artistico = EXCLUDED.nombre_artistico,
  bio_rider = EXCLUDED.bio_rider,
  instrumento_principal = EXCLUDED.instrumento_principal,
  rol_principal = EXCLUDED.rol_principal,
  ubicacion_base = EXCLUDED.ubicacion_base,
  open_to_work = EXCLUDED.open_to_work,
  verificado = EXCLUDED.verificado,
  nivel_badge = EXCLUDED.nivel_badge,
  slug_url = EXCLUDED.slug_url,
  avatar_url = EXCLUDED.avatar_url;

-- Usuario 8: Miguel Torres - DJ/Productor
INSERT INTO profiles (id, nombre_artistico, bio_rider, instrumento_principal, rol_principal, ubicacion_base, open_to_work, verificado, nivel_badge, avatar_url, slug_url)
SELECT 
  id,
  'DJ Mike Torres',
  'DJ y productor de música electrónica. Especializado en house y techno. He tocado en los mejores clubs del país.',
  'DJ/Producción',
  'productor',
  'Cancún, Quintana Roo',
  true,
  true,
  'maestro',
  'https://i.pravatar.cc/300?img=20',
  'miguel-torres'
FROM auth.users WHERE email = 'miguel.torres@test.com'
ON CONFLICT (id) DO UPDATE SET
  nombre_artistico = EXCLUDED.nombre_artistico,
  bio_rider = EXCLUDED.bio_rider,
  instrumento_principal = EXCLUDED.instrumento_principal,
  rol_principal = EXCLUDED.rol_principal,
  ubicacion_base = EXCLUDED.ubicacion_base,
  open_to_work = EXCLUDED.open_to_work,
  verificado = EXCLUDED.verificado,
  nivel_badge = EXCLUDED.nivel_badge,
  avatar_url = EXCLUDED.avatar_url,
  slug_url = EXCLUDED.slug_url;

-- ============================================
-- 2. CREAR EVENTOS/GIGS
-- ============================================
-- Columnas reales: organizador_id, titulo_bolo, resumen_setlist, tipo, fecha_gig, hora_soundcheck, 
-- lugar_nombre, coordenadas, capacidad_foro, flyer_url, precio_ticket, visibilidad, estatus_bolo, requisitos_tecnicos

-- Evento 1: Concierto de Rock (Hoy)
INSERT INTO gigs (organizador_id, titulo_bolo, resumen_setlist, tipo, fecha_gig, hora_soundcheck, lugar_nombre, capacidad_foro, precio_ticket, visibilidad, estatus_bolo)
SELECT 
  id,
  'Noche de Rock Clásico',
  'Concierto tributo a las bandas legendarias del rock. Buscamos guitarrista y baterista para completar el lineup.',
  'concierto',
  CURRENT_DATE,
  '20:00',
  'Hard Rock Café - Ciudad de México',
  200,
  250.00,
  'publico',
  'programado'
FROM profiles WHERE nombre_artistico = 'Roberto Sánchez';

-- Evento 2: Jam Session (Esta semana)
INSERT INTO gigs (organizador_id, titulo_bolo, resumen_setlist, tipo, fecha_gig, hora_soundcheck, lugar_nombre, capacidad_foro, precio_ticket, visibilidad, estatus_bolo)
SELECT 
  id,
  'Jam Session de Jazz',
  'Sesión abierta de jazz para músicos de todos los niveles. Trae tu instrumento y únete.',
  'jam_session',
  CURRENT_DATE + INTERVAL '3 days',
  '19:00',
  'Blue Note Jazz Club - Guadalajara',
  80,
  0.00,
  'publico',
  'programado'
FROM profiles WHERE nombre_artistico = 'Carlos "El Trueno" Mendoza';

-- Evento 3: Festival (Este mes)
INSERT INTO gigs (organizador_id, titulo_bolo, resumen_setlist, tipo, fecha_gig, hora_soundcheck, lugar_nombre, capacidad_foro, precio_ticket, visibilidad, estatus_bolo)
SELECT 
  id,
  'Festival de Música Independiente 2026',
  'Gran festival con 20 bandas emergentes. Buscamos músicos para formar parte del lineup principal.',
  'festival',
  CURRENT_DATE + INTERVAL '15 days',
  '14:00',
  'Parque Fundidora - Monterrey',
  5000,
  500.00,
  'publico',
  'programado'
FROM profiles WHERE nombre_artistico = 'Roberto Sánchez';

-- Evento 4: Ensayo (Esta semana)
INSERT INTO gigs (organizador_id, titulo_bolo, resumen_setlist, tipo, fecha_gig, hora_soundcheck, lugar_nombre, capacidad_foro, precio_ticket, visibilidad, estatus_bolo)
SELECT 
  id,
  'Ensayo Banda de Covers',
  'Ensayo para nueva banda de covers de rock en español. Necesitamos bajista y tecladista.',
  'ensayo',
  CURRENT_DATE + INTERVAL '5 days',
  '18:00',
  'Estudio de Ensayo "El Refugio" - Puebla',
  10,
  0.00,
  'privado',
  'programado'
FROM profiles WHERE nombre_artistico = 'María García';

-- Evento 5: Taller (Este mes)
INSERT INTO gigs (organizador_id, titulo_bolo, resumen_setlist, tipo, fecha_gig, hora_soundcheck, lugar_nombre, capacidad_foro, precio_ticket, visibilidad, estatus_bolo)
SELECT 
  id,
  'Taller de Improvisación Vocal',
  'Taller intensivo de técnicas de improvisación para vocalistas. Todos los niveles bienvenidos.',
  'taller',
  CURRENT_DATE + INTERVAL '10 days',
  '10:00',
  'Teatro de la Ciudad - Querétaro',
  30,
  300.00,
  'publico',
  'programado'
FROM profiles WHERE nombre_artistico = 'Ana Martínez';

-- Evento 6: Concierto Privado (Este mes)
INSERT INTO gigs (organizador_id, titulo_bolo, resumen_setlist, tipo, fecha_gig, hora_soundcheck, lugar_nombre, capacidad_foro, precio_ticket, visibilidad, estatus_bolo)
SELECT 
  id,
  'Boda Elegante - Música en Vivo',
  'Evento privado que requiere banda de jazz/bossa nova. 4 horas de música.',
  'concierto',
  CURRENT_DATE + INTERVAL '20 days',
  '19:00',
  'Hacienda San Miguel - Mérida',
  150,
  0.00,
  'solo_crew',
  'programado'
FROM profiles WHERE nombre_artistico = 'Diana Sax';

-- Evento 7: Fiesta Electrónica (Este mes)
INSERT INTO gigs (organizador_id, titulo_bolo, resumen_setlist, tipo, fecha_gig, hora_soundcheck, lugar_nombre, capacidad_foro, precio_ticket, visibilidad, estatus_bolo)
SELECT 
  id,
  'Noche Electrónica - Beach Party',
  'Fiesta en la playa con los mejores DJs locales. Buscamos DJ de apertura.',
  'concierto',
  CURRENT_DATE + INTERVAL '12 days',
  '22:00',
  'Coco Bongo Beach Club - Cancún',
  800,
  400.00,
  'publico',
  'programado'
FROM profiles WHERE nombre_artistico = 'DJ Mike Torres';

-- Evento 8: Evento Pasado
INSERT INTO gigs (organizador_id, titulo_bolo, resumen_setlist, tipo, fecha_gig, hora_soundcheck, lugar_nombre, capacidad_foro, precio_ticket, visibilidad, estatus_bolo)
SELECT 
  id,
  'Concierto de Año Nuevo',
  'Gran concierto de celebración de año nuevo con múltiples artistas.',
  'concierto',
  CURRENT_DATE - INTERVAL '27 days',
  '23:00',
  'Zócalo - Ciudad de México',
  10000,
  0.00,
  'publico',
  'completado'
FROM profiles WHERE nombre_artistico = 'Roberto Sánchez';

-- ============================================
-- 3. AGREGAR MÚSICOS A EVENTOS (GIG LINEUP)
-- ============================================

-- Agregar María al concierto de rock
INSERT INTO gig_lineup (gig_id, perfil_id, rol_en_gig, asistencia_confirmada)
SELECT g.id, p.id, 'Guitarrista Principal', true
FROM gigs g, profiles p
WHERE g.titulo_bolo = 'Noche de Rock Clásico' 
AND p.nombre_artistico = 'María García';

-- Agregar Carlos al jam session
INSERT INTO gig_lineup (gig_id, perfil_id, rol_en_gig, asistencia_confirmada)
SELECT g.id, p.id, 'Baterista', true
FROM gigs g, profiles p
WHERE g.titulo_bolo = 'Jam Session de Jazz' 
AND p.nombre_artistico = 'Carlos "El Trueno" Mendoza';

-- Agregar Ana al festival
INSERT INTO gig_lineup (gig_id, perfil_id, rol_en_gig, asistencia_confirmada)
SELECT g.id, p.id, 'Vocalista Principal', true
FROM gigs g, profiles p
WHERE g.titulo_bolo = 'Festival de Música Independiente 2026' 
AND p.nombre_artistico = 'Ana Martínez';

-- Agregar Luis al ensayo
INSERT INTO gig_lineup (gig_id, perfil_id, rol_en_gig, asistencia_confirmada)
SELECT g.id, p.id, 'Bajista', true
FROM gigs g, profiles p
WHERE g.titulo_bolo = 'Ensayo Banda de Covers' 
AND p.nombre_artistico = 'Luis Bass Master';

-- ============================================
-- 4. CREAR CONEXIONES ENTRE USUARIOS (CREWS)
-- ============================================
-- Columnas reales: perfil_id, target_id, estatus, es_colaboracion

-- María y Carlos son crew
INSERT INTO crews (perfil_id, target_id, estatus, es_colaboracion)
SELECT p1.id, p2.id, 'activo', true
FROM profiles p1, profiles p2
WHERE p1.nombre_artistico = 'María García' 
AND p2.nombre_artistico = 'Carlos "El Trueno" Mendoza';

-- Carlos y María (recíproco)
INSERT INTO crews (perfil_id, target_id, estatus, es_colaboracion)
SELECT p1.id, p2.id, 'activo', true
FROM profiles p1, profiles p2
WHERE p1.nombre_artistico = 'Carlos "El Trueno" Mendoza' 
AND p2.nombre_artistico = 'María García';

-- Luis y Ana son crew
INSERT INTO crews (perfil_id, target_id, estatus, es_colaboracion)
SELECT p1.id, p2.id, 'activo', true
FROM profiles p1, profiles p2
WHERE p1.nombre_artistico = 'Luis Bass Master' 
AND p2.nombre_artistico = 'Ana Martínez';

-- Ana y Luis (recíproco)
INSERT INTO crews (perfil_id, target_id, estatus, es_colaboracion)
SELECT p1.id, p2.id, 'activo', true
FROM profiles p1, profiles p2
WHERE p1.nombre_artistico = 'Ana Martínez' 
AND p2.nombre_artistico = 'Luis Bass Master';

-- Roberto sigue a varios músicos
INSERT INTO crews (perfil_id, target_id, estatus, es_colaboracion)
SELECT p1.id, p2.id, 'activo', false
FROM profiles p1, profiles p2
WHERE p1.nombre_artistico = 'Roberto Sánchez' 
AND p2.nombre_artistico IN ('María García', 'Carlos "El Trueno" Mendoza', 'Luis Bass Master', 'DJ Mike Torres');

-- Sofia y Diana son crew
INSERT INTO crews (perfil_id, target_id, estatus, es_colaboracion)
SELECT p1.id, p2.id, 'activo', true
FROM profiles p1, profiles p2
WHERE p1.nombre_artistico = 'Sofia Keys' 
AND p2.nombre_artistico = 'Diana Sax';

-- Diana y Sofia (recíproco)
INSERT INTO crews (perfil_id, target_id, estatus, es_colaboracion)
SELECT p1.id, p2.id, 'activo', true
FROM profiles p1, profiles p2
WHERE p1.nombre_artistico = 'Diana Sax' 
AND p2.nombre_artistico = 'Sofia Keys';

-- ============================================
-- 5. CREAR NOTIFICACIONES
-- ============================================

-- Notificación para María (alguien se unió a su evento)
INSERT INTO notifications (user_id, tipo, titulo, mensaje, leido, data)
SELECT p.id, 'gig_postulation', 'Nuevo interesado', 'Luis Bass Master quiere unirse a tu ensayo', false, 
  jsonb_build_object('gig_id', (SELECT id FROM gigs WHERE titulo_bolo = 'Ensayo Banda de Covers' LIMIT 1), 'sender_id', (SELECT id FROM profiles WHERE nombre_artistico = 'Luis Bass Master'))
FROM profiles p WHERE p.nombre_artistico = 'María García';

-- Notificación para Carlos (solicitud de conexión)
INSERT INTO notifications (user_id, tipo, titulo, mensaje, leido, data)
SELECT p.id, 'connection_request', 'Nueva solicitud', 'Sofia Keys quiere conectar contigo', false,
  jsonb_build_object('sender_id', (SELECT id FROM profiles WHERE nombre_artistico = 'Sofia Keys'))
FROM profiles p WHERE p.nombre_artistico = 'Carlos "El Trueno" Mendoza';

-- Notificación para Ana (nuevo evento cerca)
INSERT INTO notifications (user_id, tipo, titulo, mensaje, leido, data)
SELECT p.id, 'new_gig', 'Nuevo evento en tu área', 'Festival de Música Independiente 2026 en Monterrey', false,
  jsonb_build_object('gig_id', (SELECT id FROM gigs WHERE titulo_bolo = 'Festival de Música Independiente 2026' LIMIT 1))
FROM profiles p WHERE p.nombre_artistico = 'Ana Martínez';

-- Notificación para Luis (conexión aceptada)
INSERT INTO notifications (user_id, tipo, titulo, mensaje, leido, data)
SELECT p.id, 'connection_accepted', '¡Conexión aceptada!', 'Ana Martínez aceptó tu solicitud de conexión', false,
  jsonb_build_object('sender_id', (SELECT id FROM profiles WHERE nombre_artistico = 'Ana Martínez'))
FROM profiles p WHERE p.nombre_artistico = 'Luis Bass Master';

-- Notificación para Roberto (nuevo músico en evento)
INSERT INTO notifications (user_id, tipo, titulo, mensaje, leido, data)
SELECT p.id, 'gig_postulation', 'Nueva postulación', 'María García se unió a tu evento', false,
  jsonb_build_object('gig_id', (SELECT id FROM gigs WHERE titulo_bolo = 'Noche de Rock Clásico' LIMIT 1), 'sender_id', (SELECT id FROM profiles WHERE nombre_artistico = 'María García'))
FROM profiles p WHERE p.nombre_artistico = 'Roberto Sánchez';

-- ============================================
-- RESUMEN
-- ============================================
-- Este script crea:
-- - 8 usuarios con perfiles completos y diversos
-- - 8 eventos (1 hoy, varios esta semana/mes, 1 pasado)
-- - Conexiones entre usuarios (crews)
-- - Notificaciones de prueba
-- - Lineup de músicos en eventos
-- ============================================

SELECT 'Script de datos de prueba ejecutado exitosamente!' as resultado;
SELECT COUNT(*) as total_perfiles FROM profiles WHERE slug_url LIKE '%-%';
SELECT COUNT(*) as total_eventos FROM gigs;
SELECT COUNT(*) as total_conexiones FROM crews;
SELECT COUNT(*) as total_notificaciones FROM notifications;
