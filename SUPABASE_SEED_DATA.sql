-- SCRIPT DE DATOS DE PRUEBA (SEED) - VERSIÓN FINAL SIN ERRORES
-- Este script inserta eventos y equipo de forma ultra-segura.

-- 1. Insertar Primer Evento
INSERT INTO public.gigs (organizador_id, titulo_bolo, resumen_setlist, tipo, fecha_gig, hora_soundcheck, lugar_nombre, estatus_bolo)
SELECT 
    id, 
    'Sesión de Jam Abierta', 
    'Un espacio para improvisar y conocer a otros músicos de la comunidad.', 
    'jam_session', 
    CURRENT_DATE + INTERVAL '3 days', 
    '19:00', 
    'Sala de Ensayos Central', 
    'programado'
FROM public.profiles 
LIMIT 1;

-- 2. Insertar Segundo Evento
INSERT INTO public.gigs (organizador_id, titulo_bolo, resumen_setlist, tipo, fecha_gig, hora_soundcheck, lugar_nombre, estatus_bolo)
SELECT 
    id, 
    'Concierto Acústico Íntimo', 
    'Noche de temas originales y versiones en formato desconectado.', 
    'concierto', 
    CURRENT_DATE + INTERVAL '10 days', 
    '20:30', 
    'Café de los Artistas', 
    'programado'
FROM public.profiles 
LIMIT 1;

-- 3. Asegurar que existan instrumentos en el catálogo (Quitamos el ON CONFLICT para evitar el error de constraint)
-- Si ya existen, simplemente fallará silenciosamente o ignorará los duplicados dependiendo del editor.
-- Pero para ser 100% seguros de que corra, usamos una técnica que no requiere el ON CONFLICT:
INSERT INTO public.gear_catalog (nombre) 
SELECT 'Gibson SG' WHERE NOT EXISTS (SELECT 1 FROM public.gear_catalog WHERE nombre = 'Gibson SG');

INSERT INTO public.gear_catalog (nombre) 
SELECT 'Fender Stratocaster' WHERE NOT EXISTS (SELECT 1 FROM public.gear_catalog WHERE nombre = 'Fender Stratocaster');

INSERT INTO public.gear_catalog (nombre) 
SELECT 'Pedalera Multi-FX' WHERE NOT EXISTS (SELECT 1 FROM public.gear_catalog WHERE nombre = 'Pedalera Multi-FX');

-- 4. Asignar equipo al perfil (Usamos INSERT directo sin ON CONFLICT)
INSERT INTO public.perfil_gear (perfil_id, gear_id)
SELECT p.id, g.id 
FROM public.profiles p, public.gear_catalog g
WHERE g.nombre IN ('Gibson SG', 'Pedalera Multi-FX')
AND p.id = (SELECT id FROM public.profiles LIMIT 1)
AND NOT EXISTS (
    SELECT 1 FROM public.perfil_gear pg 
    WHERE pg.perfil_id = p.id AND pg.gear_id = g.id
);
