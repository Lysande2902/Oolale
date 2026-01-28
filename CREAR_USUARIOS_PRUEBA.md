# 🎵 GUÍA PARA CREAR USUARIOS DE PRUEBA EN ÓOLALE

## 📋 PASO 1: Crear Usuarios en Supabase Auth

Antes de ejecutar el script SQL, debes crear estos usuarios en **Supabase Auth Dashboard**:

### Ir a: Supabase Dashboard → Authentication → Users → Add User

Crea estos 8 usuarios con la contraseña: **`Test123456!`**

| Email | Nombre | Rol | Instrumento |
|-------|--------|-----|-------------|
| maria.garcia@test.com | María García | Músico | Guitarra |
| carlos.mendoza@test.com | Carlos Mendoza | Músico | Batería |
| ana.martinez@test.com | Ana Martínez | Músico | Voz |
| luis.hernandez@test.com | Luis Hernández | Músico | Bajo |
| sofia.ramirez@test.com | Sofia Ramírez | Músico | Piano |
| roberto.sanchez@test.com | Roberto Sánchez | Manager | N/A |
| diana.lopez@test.com | Diana López | Músico | Saxofón |
| miguel.torres@test.com | Miguel Torres | Músico | DJ |

### Opción A: Crear manualmente en Dashboard
1. Ve a Authentication → Users
2. Click en "Add User"
3. Ingresa email y contraseña
4. Confirma el email automáticamente (toggle "Auto Confirm User")
5. Repite para cada usuario

### Opción B: Crear con SQL (más rápido)
Ejecuta este script en el SQL Editor de Supabase:

```sql
-- IMPORTANTE: Esto solo funciona si tienes permisos de admin
-- Ejecutar en Supabase SQL Editor

-- Crear usuarios en auth.users
INSERT INTO auth.users (
  instance_id,
  id,
  aud,
  role,
  email,
  encrypted_password,
  email_confirmed_at,
  recovery_sent_at,
  last_sign_in_at,
  raw_app_meta_data,
  raw_user_meta_data,
  created_at,
  updated_at,
  confirmation_token,
  email_change,
  email_change_token_new,
  recovery_token
) VALUES
  (
    '00000000-0000-0000-0000-000000000000',
    gen_random_uuid(),
    'authenticated',
    'authenticated',
    'maria.garcia@test.com',
    crypt('Test123456!', gen_salt('bf')),
    NOW(),
    NOW(),
    NOW(),
    '{"provider":"email","providers":["email"]}',
    '{}',
    NOW(),
    NOW(),
    '',
    '',
    '',
    ''
  );
-- Repite para cada email...
```

## 📋 PASO 2: Ejecutar el Script SQL

Una vez creados los usuarios en Auth, ejecuta el archivo `SEED_TEST_DATA.sql` en el SQL Editor de Supabase.

Este script creará:
- ✅ Perfiles completos para cada usuario
- ✅ 8 eventos diferentes (hoy, esta semana, este mes, pasados)
- ✅ Conexiones entre usuarios
- ✅ Posts en el feed
- ✅ Notificaciones
- ✅ Lineup de músicos en eventos

## 🔐 PASO 3: Iniciar Sesión en la App

Ahora puedes iniciar sesión con cualquiera de estos usuarios:

**Email:** cualquiera de la lista arriba  
**Contraseña:** `Test123456!`

## 📱 Qué Verás en Cada Cuenta

### María García (maria.garcia@test.com)
- ✅ Perfil Premium verificado
- ✅ Guitarrista profesional
- ✅ Organizadora de ensayo
- ✅ Conexiones con Carlos y Roberto
- ✅ Post reciente en feed

### Carlos Mendoza (carlos.mendoza@test.com)
- ✅ Baterista verificado
- ✅ Organizador de jam session
- ✅ Conexiones con María
- ✅ Post sobre jam session

### Ana Martínez (ana.martinez@test.com)
- ✅ Vocalista
- ✅ Participante en festival
- ✅ Conexión con Luis
- ✅ Post de agradecimiento

### Luis Hernández (luis.hernandez@test.com)
- ✅ Bajista Premium verificado
- ✅ Participante en ensayo
- ✅ Conexión con Ana
- ✅ Post sobre tutorial

### Sofia Ramírez (sofia.ramirez@test.com)
- ✅ Tecladista
- ✅ Perfil completo
- ✅ Disponible para trabajo

### Roberto Sánchez (roberto.sanchez@test.com)
- ✅ Manager/Productor Premium verificado
- ✅ Organizador de múltiples eventos
- ✅ Conexiones con varios músicos
- ✅ Post sobre festival

### Diana López (diana.lopez@test.com)
- ✅ Saxofonista
- ✅ Organizadora de boda elegante
- ✅ Perfil completo

### Miguel Torres (miguel.torres@test.com)
- ✅ DJ verificado
- ✅ Organizador de fiesta electrónica
- ✅ Perfil completo

## 🎯 Casos de Uso para Probar

1. **Dashboard/Feed**: Verás posts de diferentes usuarios
2. **Eventos**: Verás eventos de hoy, esta semana, este mes y pasados
3. **Búsqueda**: Busca músicos por instrumento o ubicación
4. **Conexiones**: Algunos usuarios ya están conectados
5. **Notificaciones**: Algunos usuarios tienen notificaciones pendientes
6. **Mensajes**: Puedes iniciar conversaciones entre usuarios conectados

## 🔄 Limpiar Datos de Prueba

Si quieres empezar de nuevo, ejecuta:

```sql
-- CUIDADO: Esto borrará TODOS los datos de prueba
DELETE FROM posts WHERE author_id IN (SELECT id FROM profiles WHERE email LIKE '%@test.com');
DELETE FROM notifications WHERE user_id IN (SELECT id FROM profiles WHERE email LIKE '%@test.com');
DELETE FROM gig_lineup WHERE perfil_id IN (SELECT id FROM profiles WHERE email LIKE '%@test.com');
DELETE FROM crews WHERE user_id IN (SELECT id FROM profiles WHERE email LIKE '%@test.com');
DELETE FROM gigs WHERE organizador_id IN (SELECT id FROM profiles WHERE email LIKE '%@test.com');
DELETE FROM profiles WHERE email LIKE '%@test.com';
-- Luego borra los usuarios en Auth Dashboard manualmente
```

## ✅ Verificación

Para verificar que todo se creó correctamente:

```sql
-- Ver usuarios creados
SELECT email, nombre_artistico, rol_principal, verificado, ranking_tipo 
FROM profiles 
WHERE email LIKE '%@test.com';

-- Ver eventos creados
SELECT titulo_bolo, tipo, fecha_gig, lugar_ciudad, estatus 
FROM gigs 
ORDER BY fecha_gig;

-- Ver conexiones
SELECT 
  p1.nombre_artistico as usuario,
  p2.nombre_artistico as conectado_con,
  c.estatus
FROM crews c
JOIN profiles p1 ON c.user_id = p1.id
JOIN profiles p2 ON c.target_id = p2.id
WHERE p1.email LIKE '%@test.com';

-- Ver posts
SELECT p.nombre_artistico, po.content, po.created_at
FROM posts po
JOIN profiles p ON po.author_id = p.id
WHERE p.email LIKE '%@test.com'
ORDER BY po.created_at DESC;
```

## 🎉 ¡Listo!

Ahora tienes una base de datos completa con usuarios reales que puedes usar para probar todas las funcionalidades de la app.
