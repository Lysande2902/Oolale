# 🎵 INSTRUCCIONES RÁPIDAS - USUARIOS DE PRUEBA

## ⚡ MÉTODO MÁS FÁCIL (Recomendado):

### 1️⃣ Crear usuarios en Supabase Dashboard:

1. Ve a tu proyecto en Supabase
2. Click en **Authentication** → **Users**
3. Click en **"Add User"** (botón verde)
4. Para cada usuario:
   - **Email:** (usa uno de la lista abajo)
   - **Password:** `Test123456!`
   - ✅ Marca **"Auto Confirm User"**
   - Click en **"Create User"**

**Repite 8 veces con estos emails:**
- maria.garcia@test.com
- carlos.mendoza@test.com
- ana.martinez@test.com
- luis.hernandez@test.com
- sofia.ramirez@test.com
- roberto.sanchez@test.com
- diana.lopez@test.com
- miguel.torres@test.com

### 2️⃣ Ejecuta el script de datos:
```
SEED_TEST_DATA.sql
```
Este crea los perfiles, eventos, conexiones, etc.

### 3️⃣ Inicia sesión en la app:

**Contraseña para TODOS:** `Test123456!`

---

## 🔑 CREDENCIALES:

| Email | Contraseña | Perfil |
|-------|-----------|--------|
| maria.garcia@test.com | Test123456! | Guitarrista Premium ⭐ |
| carlos.mendoza@test.com | Test123456! | Baterista ⭐ |
| ana.martinez@test.com | Test123456! | Vocalista |
| luis.hernandez@test.com | Test123456! | Bajista Premium ⭐ |
| sofia.ramirez@test.com | Test123456! | Tecladista |
| roberto.sanchez@test.com | Test123456! | Manager Premium ⭐ |
| diana.lopez@test.com | Test123456! | Saxofonista |
| miguel.torres@test.com | Test123456! | DJ ⭐ |

---

## ✅ ¡Listo!

Ahora puedes iniciar sesión con cualquiera de estos usuarios y ver:
- ✅ Perfiles completos
- ✅ Eventos creados (hoy, esta semana, este mes)
- ✅ Conexiones entre usuarios
- ✅ Posts en el feed
- ✅ Notificaciones
- ✅ Mensajes

---

## 🔍 Verificar que funcionó:

Ejecuta en Supabase SQL Editor:

```sql
-- Ver usuarios creados
SELECT email FROM auth.users WHERE email LIKE '%@test.com';

-- Ver perfiles
SELECT email, nombre_artistico, rol_principal 
FROM profiles 
WHERE email LIKE '%@test.com';

-- Ver eventos
SELECT titulo_bolo, fecha_gig, lugar_ciudad 
FROM gigs 
ORDER BY fecha_gig;
```

---

## 🗑️ Limpiar todo (si quieres empezar de nuevo):

```sql
-- Borrar datos de prueba
DELETE FROM posts WHERE author_id IN (SELECT id FROM profiles WHERE email LIKE '%@test.com');
DELETE FROM notifications WHERE user_id IN (SELECT id FROM profiles WHERE email LIKE '%@test.com');
DELETE FROM gig_lineup WHERE perfil_id IN (SELECT id FROM profiles WHERE email LIKE '%@test.com');
DELETE FROM crews WHERE user_id IN (SELECT id FROM profiles WHERE email LIKE '%@test.com');
DELETE FROM gigs WHERE organizador_id IN (SELECT id FROM profiles WHERE email LIKE '%@test.com');
DELETE FROM profiles WHERE email LIKE '%@test.com';
-- Luego borra los usuarios manualmente en Authentication → Users
```

---

## 💡 TIPS:

- **Auto Confirm User** es importante para que no tengas que confirmar emails
- Todos los usuarios usan la misma contraseña: `Test123456!`
- Puedes crear menos usuarios si quieres (mínimo 3-4 para ver interacciones)
- El script `SEED_TEST_DATA.sql` solo crea datos para usuarios que existan en auth.users
