-- ========================================================
-- 🧹 PASO 1: LIMPIAR BASE DE DATOS
-- ========================================================
-- Ejecutar PRIMERO este script para limpiar todo

-- Desactivar triggers temporalmente
DROP TRIGGER IF EXISTS on_auth_user_created ON auth.users;
DROP TRIGGER IF EXISTS on_crew_request ON public.crews;
DROP TRIGGER IF EXISTS on_crew_accepted ON public.crews;
DROP TRIGGER IF EXISTS on_gig_postulation ON public.gig_lineup;

-- Eliminar funciones
DROP FUNCTION IF EXISTS public.handle_new_artist() CASCADE;
DROP FUNCTION IF EXISTS notify_connection_request() CASCADE;
DROP FUNCTION IF EXISTS notify_connection_accepted() CASCADE;
DROP FUNCTION IF EXISTS notify_gig_postulation() CASCADE;
DROP FUNCTION IF EXISTS mark_all_notifications_read(UUID) CASCADE;

-- Eliminar tablas en orden (respetando foreign keys)
DROP TABLE IF EXISTS public.hirings CASCADE;
DROP TABLE IF EXISTS public.notifications CASCADE;
DROP TABLE IF EXISTS public.blocks CASCADE;
DROP TABLE IF EXISTS public.reports CASCADE;
DROP TABLE IF EXISTS public.intercom CASCADE;
DROP TABLE IF EXISTS public.crews CASCADE;
DROP TABLE IF EXISTS public.tickets_pagos CASCADE;
DROP TABLE IF EXISTS public.gig_lineup CASCADE;
DROP TABLE IF EXISTS public.gigs CASCADE;
DROP TABLE IF EXISTS public.perfil_generos CASCADE;
DROP TABLE IF EXISTS public.perfil_gear CASCADE;
DROP TABLE IF EXISTS public.generos_catalog CASCADE;
DROP TABLE IF EXISTS public.gear_catalog CASCADE;
DROP TABLE IF EXISTS public.profiles CASCADE;

-- Eliminar tipos (enums)
DROP TYPE IF EXISTS visibilidad_setlist CASCADE;
DROP TYPE IF EXISTS estatus_pago CASCADE;
DROP TYPE IF EXISTS pasarela_pago CASCADE;
DROP TYPE IF EXISTS estatus_vinculo CASCADE;
DROP TYPE IF EXISTS mood_gig CASCADE;
DROP TYPE IF EXISTS rol_escena CASCADE;

-- ✅ BASE DE DATOS LIMPIA - Ahora ejecuta SUPABASE_SETUP_FINAL.sql
