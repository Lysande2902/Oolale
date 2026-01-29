-- ============================================
-- SCRIPT DE DATOS DE PRUEBA PARA ÓOLALE
-- ============================================
-- VERSIÓN CORREGIDA - Usa las columnas REALES de tu base de datos
-- Contraseña para todos: Test123456!

-- ============================================
-- IMPORTANTE: CREAR USUARIOS EN SUPABASE AUTH PRIMERO
-- ============================================
/*
USUARIOS DE PRUEBA (Contraseña: Test123456!)

1. maria.garcia@test.com
2. carlos.mendoza@test.com
3. ana.martinez@test.com
4. luis.hernandez@test.com
5. sofia.ramirez@test.com
6. roberto.sanchez@test.com
7. diana.lopez@test.com
8. miguel.torres@test.com
*/

-- ============================================
-- 1. CREAR/ACTUALIZAR PERFILES
-- ============================================
-- Columnas reales: id, email, nombre_artistico, bio, foto_perfil, banner, 
-- ubicacion, pais, open_to_work, ranking_tipo, verificado, instrumento_principal, rol_principal

-- Usuario 1: María García - Guitarrista Premium
INSERT INTO profiles (id, email, nombre_artistico, bio, instrumento_principal, rol_principal, ubicacion, open_to_work, verificado, ranking_tipo, foto_perfil)
SELECT 
  id,
  'maria.garcia@test.com',
  'María García',
  'Guitarrista profesional con 10 años de experiencia en rock y blues. Disponible para sesiones de grabación y conciertos en vivo.',
  'Guitarra Eléctrica',
  'musico',
  'Ciudad de México, CDMX',
  true,
  true,
  'pro',
  'https://i.pravatar.cc/300?img=1'
FROM auth.users WHERE email = 'maria.garcia@test.com'
ON CONFLICT (id) DO UPDATE SET
  nombre_artistico = EXCLUDED.nombre_artistico,
  bio = EXCLUDED.bio,
  instrumento_principal = EXCLUDED.instrumento_principal,
  rol_principal = EXCLUDED.rol_principal,
  ubicacion = EXCLUDED.ubicacion,
  open_to_work = EXCLUDED.open_to_work,
  verificado = EXCLUDED.verificado,
  ranking_tipo = EXCLUDED.ranking_tipo,
  foto_perfil = EXCLUDED.foto_perfil;

-- Usuario 2: Carlos Mendoza - Baterista
INSERT INTO profiles (id, email, nombre_artistico, bio, instrumento_principal, rol_principal, ubicacion, open_to_work, verificado, ranking_tipo, foto_perfil)
SELECT 
  id,
  'carlos.mendoza@test.com',
  'Carlos "El Trueno" Mendoza',
  'Baterista de jazz y funk. He tocado con bandas reconocidas en festivales nacionales. Busco proyectos serios.',
  'Batería',
  'musico',
  'Guadalajara, Jalisco',
  true,
  true,
  'maestro',
  'https://i.pravatar.cc/300?img=11'
FROM auth.users WHERE email = 'carlos.mendoza@test.com'
ON CONFLICT (id) DO UPDATE SET
  nombre_artistico = EXCLUDED.nombre_artistico,
  bio = EXCLUDED.bio,
  instrumento_principal = EXCLUDED.instrumento_principal,
  rol_principal = EXCLUDED.rol_principal,
  ubicacion = EXCLUDED.ubicacion,
  open_to_work = EXCLUDED.open_to_work,
  verificado = EXCLUDED.verificado,
  ranking_tipo = EXCLUDED.ranking_tipo,
  foto_perfil = EXCLUDED.foto_perfil;

-- Usuario 3: Ana Martínez - Vocalista
INSERT INTO profiles (id, email, nombre_artistico, bio, instrumento_principal, rol_principal, ubicacion, open_to_work, verificado, ranking_tipo, foto_perfil)
SELECT 
  id,
  'ana.martinez@test.com',
  'Ana Martínez',
  'Vocalista versátil con rango de soprano. Especializada en pop, R&B y soul. Disponible para colaboraciones.',
  'Voz',
  'musico',
  'Monterrey, Nuevo León',
  true,
  false,
  'principiante',
  'https://i.pravatar.cc/300?img=5'
FROM auth.users WHERE email = 'ana.martinez@test.com'
ON CONFLICT (id) DO UPDATE SET
  nombre_artistico = EXCLUDED.nombre_artistico,
  bio = EXCLUDED.bio,
  instrumento_principal = EXCLUDED.instrumento_principal,
  rol_principal = EXCLUDED.rol_principal,
  ubicacion = EXCLUDED.ubicacion,
  open_to_work = EXCLUDED.open_to_work,
  verificado = EXCLUDED.verificado,
  ranking_tipo = EXCLUDED.ranking_tipo,
  foto_perfil = EXCLUDED.foto_perfil;

-- Usuario 4: Luis Hernández - Bajista Premium
INSERT INTO profiles (id, email, nombre_artistico, bio, instrumento_principal, rol_principal, ubicacion, open_to_work, verificado, ranking_tipo, foto_perfil)
SELECT 
  id,
  'luis.hernandez@test.com',
  'Luis Bass Master',
  'Bajista de sesión con experiencia en múltiples géneros. He trabajado en más de 50 producciones discográficas.',
  'Bajo Eléctrico',
  'musico',
  'Puebla, Puebla',
  true,
  true,
  'pro',
  'https://i.pravatar.cc/300?img=12'
FROM auth.users WHERE email = 'luis.hernandez@test.com'
ON CONFLICT (id) DO UPDATE SET
  nombre_artistico = EXCLUDED.nombre_artistico,
  bio = EXCLUDED.bio,
  instrumento_principal = EXCLUDED.instrumento_principal,
  rol_principal = EXCLUDED.rol_principal,
  ubicacion = EXCLUDED.ubicacion,
  open_to_work = EXCLUDED.open_to_work,
  verificado = EXCLUDED.verificado,
  ranking_tipo = EXCLUDED.ranking_tipo,
  foto_perfil = EXCLUDED.foto_perfil;

-- Usuario 5: Sofia Ramírez - Tecladista
INSERT INTO profiles (id, email, nombre_artistico, bio, instrumento_principal, rol_principal, ubicacion, open_to_work, verificado, ranking_tipo, foto_perfil)
SELECT 
  id,
  'sofia.ramirez@test.com',
  'Sofia Keys',
  'Tecladista y pianista clásica. Especializada en arreglos y producción musical. Busco proyectos creativos.',
  'Piano/Teclado',
  'musico',
  'Querétaro, Querétaro',
  true,
  false,
  'principiante',
  'https://i.pravatar.cc/300?img=9'
FROM auth.users WHERE email = 'sofia.ramirez@test.com'
ON CONFLICT (id) DO UPDATE SET
  nombre_artistico = EXCLUDED.nombre_artistico,
  bio = EXCLUDED.bio,
  instrumento_principal = EXCLUDED.instrumento_principal,
  rol_principal = EXCLUDED.rol_principal,
  ubicacion = EXCLUDED.ubicacion,
  open_to_work = EXCLUDED.open_to_work,
  verificado = EXCLUDED.verificado,
  ranking_tipo = EXCLUDED.ranking_tipo,
  foto_perfil = EXCLUDED.foto_perfil;

-- Usuario 6: Roberto Sánchez - Productor/Promotor
INSERT INTO profiles (id, email, nombre_artistico, bio, instrumento_principal, rol_principal, ubicacion, open_to_work, verificado, ranking_tipo, foto_perfil)
SELECT 
  id,
  'roberto.sanchez@test.com',
  'Roberto Sánchez',
  'Productor musical y promotor con 15 años en la industria. Busco talento emergente para proyectos profesionales.',
  'N/A',
  'promotor',
  'Ciudad de México, CDMX',
  true,
  true,
  'leyenda',
  'https://i.pravatar.cc/300?img=15'
FROM auth.users WHERE email = 'roberto.sanchez@test.com'
ON CONFLICT (id) DO UPDATE SET
  nombre_artistico = EXCLUDED.nombre_artistico,
  bio = EXCLUDED.bio,
  instrumento_principal = EXCLUDED.instrumento_principal,
  rol_principal = EXCLUDED.rol_principal,
  ubicacion = EXCLUDED.ubicacion,
  open_to_work = EXCLUDED.open_to_work,
  verificado = EXCLUDED.verificado,
  ranking_tipo = EXCLUDED.ranking_tipo,
  foto_perfil = EXCLUDED.foto_perfil;

-- Usuario 7: Diana López - Saxofonista
INSERT INTO profiles (id, email, nombre_artistico, bio, instrumento_principal, rol_principal, ubicacion, open_to_work, verificado, ranking_tipo, foto_perfil)
SELECT 
  id,
  'diana.lopez@test.com',
  'Diana Sax',
  'Saxofonista de jazz y música latina. Disponible para eventos corporativos y bodas.',
  'Saxofón',
  'musico',
  'Mérida, Yucatán',
  true,
  false,
  'principiante',
  'https://i.pravatar.cc/300?img=47'
FROM auth.users WHERE email = 'diana.lopez@test.com'
ON CONFLICT (id) DO UPDATE SET
  nombre_artistico = EXCLUDED.nombre_artistico,
  bio = EXCLUDED.bio,
  instrumento_principal = EXCLUDED.instrumento_principal,
  rol_principal = EXCLUDED.rol_principal,
  ubicacion = EXCLUDED.ubicacion,
  open_to_work = EXCLUDED.open_to_work,
  verificado = EXCLUDED.verificado,
  ranking_tipo = EXCLUDED.ranking_tipo,
  foto_perfil = EXCLUDED.foto_perfil;

-- Usuario 8: Miguel Torres - DJ/Productor
INSERT INTO profiles (id, email, nombre_artistico, bio, instrumento_principal, rol_principal, ubicacion, open_to_work, verificado, ranking_tipo, foto_perfil)
SELECT 
  id,
  'miguel.torres@test.com',
  'DJ Mike Torres',
  'DJ y productor de música electrónica. Especializado en house y techno. He tocado en los mejores clubs del país.',
  'DJ/Producción',
  'productor',
  'Cancún, Quintana Roo',
  true,
  true,
  'maestro',
  'https://i.pravatar.cc/300?img=20'
FROM auth.users WHERE email = 'miguel.torres@test.com'
ON CONFLICT (id) DO UPDATE SET
  nombre_artistico = EXCLUDED.nombre_artistico,
  bio = EXCLUDED.bio,
  instrumento_principal = EXCLUDED.instrumento_principal,
  rol_principal = EXCLUDED.rol_principal,
  ubicacion = EXCLUDED.ubicacion,
  open_to_work = EXCLUDED.open_to_work,
  verificado = EXCLUDED.verificado,
  ranking_tipo = EXCLUDED.ranking_tipo,
  foto_perfil = EXCLUDED.foto_perfil;

-- ============================================
-- 2. CREAR EVENTOS/GIGS
-- ============================================
-- Columnas reales: organizador_id, titulo_bolo, resumen_setlist, tipo, fecha_gig, 
-- hora_soundcheck, lugar_nombre, requisitos_tecnicos, estatus_bolo, flyer_url

-- Evento 1: Concierto de Rock (Hoy)
INSERT INTO gigs (organizador_id, titulo_bolo, resumen_setlist, tipo, fecha_gig, hora_soundcheck, lugar_nombre, estatus_bolo)
SELECT 
  id,
  'Noche de Rock Clásico',
  'Concierto tributo a las bandas legendarias del rock. Buscamos guitarrista y baterista para completar el lineup.',
  'concierto',
  CURRENT_DATE,
  '20:00',
  'Hard Rock Café - Ciudad de México',
  'programado'
FROM profiles WHERE email = 'roberto.sanchez@test.com';

-- Evento 2: Jam Session (Esta semana)
INSERT INTO gigs (organizador_id, titulo_bolo, resumen_setlist, tipo, fecha_gig, hora_soundcheck, lugar_nombre, estatus_bolo)
SELECT 
  id,
  'Jam Session de Jazz',
  'Sesión abierta de jazz para músicos de todos los niveles. Trae tu instrumento y únete.',
  'jam_session',
  CURRENT_DATE + INTERVAL '3 days',
  '19:00',
  'Blue Note Jazz Club - Guadalajara',
  'programado'
FROM profiles WHERE email = 'carlos.mendoza@test.com';

-- Evento 3: Festival (Este mes)
INSERT INTO gigs (organizador_id, titulo_bolo, resumen_setlist, tipo, fecha_gig, hora_soundcheck, lugar_nombre, estatus_bolo)
SELECT 
  id,
  'Festival de Música Independiente 2026',
  'Gran festival con 20 bandas emergentes. Buscamos músicos para formar parte del lineup principal.',
  'festival',
  CURRENT_DATE + INTERVAL '15 days',
  '14:00',
  'Parque Fundidora - Monterrey',
  'programado'
FROM profiles WHERE email = 'roberto.sanchez@test.com';

-- Evento 4: Ensayo (Esta semana)
INSERT INTO gigs (organizador_id, titulo_bolo, resumen_setlist, tipo, fecha_gig, hora_soundcheck, lugar_nombre, estatus_bolo)
SELECT 
  id,
  'Ensayo Banda de Covers',
  'Ensayo para nueva banda de covers de rock en español. Necesitamos bajista y tecladista.',
  'ensayo',
  CURRENT_DATE + INTERVAL '5 days',
  '18:00',
  'Estudio de Ensayo "El Refugio" - Puebla',
  'programado'
FROM profiles WHERE email = 'maria.garcia@test.com';

-- Evento 5: Taller (Este mes)
INSERT INTO gigs (organizador_id, titulo_bolo, resumen_setlist, tipo, fecha_gig, hora_soundcheck, lugar_nombre, estatus_bolo)
SELECT 
  id,
  'Taller de Improvisación Vocal',
  'Taller intensivo de técnicas de improvisación para vocalistas. Todos los niveles bienvenidos.',
  'taller',
  CURRENT_DATE + INTERVAL '10 days',
  '10:00',
  'Teatro de la Ciudad - Querétaro',
  'programado'
FROM profiles WHERE email = 'ana.martinez@test.com';

-- Evento 6: Concierto Privado (Este mes)
INSERT INTO gigs (organizador_id, titulo_bolo, resumen_setlist, tipo, fecha_gig, hora_soundcheck, lugar_nombre, estatus_bolo)
SELECT 
  id,
  'Boda Elegante - Música en Vivo',
  'Evento privado que requiere banda de jazz/bossa nova. 4 horas de música.',
  'concierto',
  CURRENT_DATE + INTERVAL '20 days',
  '19:00',
  'Hacienda San Miguel - Mérida',
  'programado'
FROM profiles WHERE email = 'diana.lopez@test.com';

-- Evento 7: Fiesta Electrónica (Este mes)
INSERT INTO gigs (organizador_id, titulo_bolo, resumen_setlist, tipo, fecha_gig, hora_soundcheck, lugar_nombre, estatus_bolo)
SELECT 
  id,
  'Noche Electrónica - Beach Party',
  'Fiesta en la playa con los mejores DJs locales. Buscamos DJ de apertura.',
  'concierto',
  CURRENT_DATE + INTERVAL '12 days',
  '22:00',
  'Coco Bongo Beach Club - Cancún',
  'programado'
FROM profiles WHERE email = 'miguel.torres@test.com';

-- Evento 8: Evento Pasado
INSERT INTO gigs (organizador_id, titulo_bolo, resumen_setlist, tipo, fecha_gig, hora_soundcheck, lugar_nombre, estatus_bolo)
SELECT 
  id,
  'Concierto de Año Nuevo',
  'Gran concierto de celebración de año nuevo con múltiples artistas.',
  'concierto',
  CURRENT_DATE - INTERVAL '27 days',
  '23:00',
  'Zócalo - Ciudad de México',
  'completado'
FROM profiles WHERE email = 'roberto.sanchez@test.com';

-- ============================================
-- 3. AGREGAR MÚSICOS A EVENTOS (GIG LINEUP)
-- ============================================

-- Agregar María al concierto de rock
INSERT INTO gig_lineup (gig_id, perfil_id, rol_en_gig, asistencia_confirmada)
SELECT g.id, p.id, 'Guitarrista Principal', true
FROM gigs g, profiles p
WHERE g.titulo_bolo = 'Noche de Rock Clásico' 
AND p.email = 'maria.garcia@test.com';

-- Agregar Carlos al jam session
INSERT INTO gig_lineup (gig_id, perfil_id, rol_en_gig, asistencia_confirmada)
SELECT g.id, p.id, 'Baterista', true
FROM gigs g, profiles p
WHERE g.titulo_bolo = 'Jam Session de Jazz' 
AND p.email = 'carlos.mendoza@test.com';

-- Agregar Ana al festival
INSERT INTO gig_lineup (gig_id, perfil_id, rol_en_gig, asistencia_confirmada)
SELECT g.id, p.id, 'Vocalista Principal', true
FROM gigs g, profiles p
WHERE g.titulo_bolo = 'Festival de Música Independiente 2026' 
AND p.email = 'ana.martinez@test.com';

-- Agregar Luis al ensayo
INSERT INTO gig_lineup (gig_id, perfil_id, rol_en_gig, asistencia_confirmada)
SELECT g.id, p.id, 'Bajista', true
FROM gigs g, profiles p
WHERE g.titulo_bolo = 'Ensayo Banda de Covers' 
AND p.email = 'luis.hernandez@test.com';

-- ============================================
-- 4. CREAR CONEXIONES ENTRE USUARIOS (CREWS)
-- ============================================

-- María y Carlos son crew
INSERT INTO crews (perfil_id, target_id, estatus, es_colaboracion)
SELECT p1.id, p2.id, 'activo', true
FROM profiles p1, profiles p2
WHERE p1.email = 'maria.garcia@test.com' 
AND p2.email = 'carlos.mendoza@test.com';

-- Carlos y María (recíproco)
INSERT INTO crews (perfil_id, target_id, estatus, es_colaboracion)
SELECT p1.id, p2.id, 'activo', true
FROM profiles p1, profiles p2
WHERE p1.email = 'carlos.mendoza@test.com' 
AND p2.email = 'maria.garcia@test.com';

-- Luis y Ana son crew
INSERT INTO crews (perfil_id, target_id, estatus, es_colaboracion)
SELECT p1.id, p2.id, 'activo', true
FROM profiles p1, profiles p2
WHERE p1.email = 'luis.hernandez@test.com' 
AND p2.email = 'ana.martinez@test.com';

-- Ana y Luis (recíproco)
INSERT INTO crews (perfil_id, target_id, estatus, es_colaboracion)
SELECT p1.id, p2.id, 'activo', true
FROM profiles p1, profiles p2
WHERE p1.email = 'ana.martinez@test.com' 
AND p2.email = 'luis.hernandez@test.com';

-- Roberto sigue a varios músicos
INSERT INTO crews (perfil_id, target_id, estatus, es_colaboracion)
SELECT p1.id, p2.id, 'activo', false
FROM profiles p1, profiles p2
WHERE p1.email = 'roberto.sanchez@test.com' 
AND p2.email IN ('maria.garcia@test.com', 'carlos.mendoza@test.com', 'luis.hernandez@test.com', 'miguel.torres@test.com');

-- Sofia y Diana son crew
INSERT INTO crews (perfil_id, target_id, estatus, es_colaboracion)
SELECT p1.id, p2.id, 'activo', true
FROM profiles p1, profiles p2
WHERE p1.email = 'sofia.ramirez@test.com' 
AND p2.email = 'diana.lopez@test.com';

-- Diana y Sofia (recíproco)
INSERT INTO crews (perfil_id, target_id, estatus, es_colaboracion)
SELECT p1.id, p2.id, 'activo', true
FROM profiles p1, profiles p2
WHERE p1.email = 'diana.lopez@test.com' 
AND p2.email = 'sofia.ramirez@test.com';

-- ============================================
-- 5. CREAR NOTIFICACIONES
-- ============================================

-- Notificación para María
INSERT INTO notifications (user_id, tipo, titulo, mensaje, leido, data)
SELECT p.id, 'gig_postulation', 'Nuevo interesado', 'Luis Bass Master quiere unirse a tu ensayo', false, 
  jsonb_build_object('gig_id', (SELECT id FROM gigs WHERE titulo_bolo = 'Ensayo Banda de Covers' LIMIT 1), 'sender_id', (SELECT id FROM profiles WHERE email = 'luis.hernandez@test.com'))
FROM profiles p WHERE p.email = 'maria.garcia@test.com';

-- Notificación para Carlos
INSERT INTO notifications (user_id, tipo, titulo, mensaje, leido, data)
SELECT p.id, 'connection_request', 'Nueva solicitud', 'Sofia Keys quiere conectar contigo', false,
  jsonb_build_object('sender_id', (SELECT id FROM profiles WHERE email = 'sofia.ramirez@test.com'))
FROM profiles p WHERE p.email = 'carlos.mendoza@test.com';

-- Notificación para Ana
INSERT INTO notifications (user_id, tipo, titulo, mensaje, leido, data)
SELECT p.id, 'new_gig', 'Nuevo evento en tu área', 'Festival de Música Independiente 2026 en Monterrey', false,
  jsonb_build_object('gig_id', (SELECT id FROM gigs WHERE titulo_bolo = 'Festival de Música Independiente 2026' LIMIT 1))
FROM profiles p WHERE p.email = 'ana.martinez@test.com';

-- Notificación para Luis
INSERT INTO notifications (user_id, tipo, titulo, mensaje, leido, data)
SELECT p.id, 'connection_accepted', '¡Conexión aceptada!', 'Ana Martínez aceptó tu solicitud de conexión', false,
  jsonb_build_object('sender_id', (SELECT id FROM profiles WHERE email = 'ana.martinez@test.com'))
FROM profiles p WHERE p.email = 'luis.hernandez@test.com';

-- Notificación para Roberto
INSERT INTO notifications (user_id, tipo, titulo, mensaje, leido, data)
SELECT p.id, 'gig_postulation', 'Nueva postulación', 'María García se unió a tu evento', false,
  jsonb_build_object('gig_id', (SELECT id FROM gigs WHERE titulo_bolo = 'Noche de Rock Clásico' LIMIT 1), 'sender_id', (SELECT id FROM profiles WHERE email = 'maria.garcia@test.com'))
FROM profiles p WHERE p.email = 'roberto.sanchez@test.com';

-- ============================================
-- RESUMEN
-- ============================================
SELECT 'Script ejecutado exitosamente!' as resultado;
SELECT COUNT(*) as total_perfiles FROM profiles WHERE email LIKE '%@test.com';
SELECT COUNT(*) as total_eventos FROM gigs;
SELECT COUNT(*) as total_conexiones FROM crews;
SELECT COUNT(*) as total_notificaciones FROM notifications;
