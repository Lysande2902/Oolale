# 🚀 GUÍA ACTUALIZADA - CÓMO EJECUTAR LA APP

**IMPORTANTE:** Ejecutar en orden exacto

---

## ✅ PASO 1: LIMPIAR BASE DE DATOS

**En Supabase SQL Editor:**

1. Abre https://supabase.com/dashboard
2. Ve a tu proyecto
3. Click en "SQL Editor" (menú izquierdo)
4. Click en "New Query"
5. **Copia y pega TODO el contenido de:**
   ```
   SUPABASE_CLEAN.sql
   ```
6. Click en "Run"
7. Espera a que termine (verás "Success")

**Esto elimina todas las tablas viejas para empezar limpio.**

---

## ✅ PASO 2: CREAR BASE DE DATOS NUEVA

**En Supabase SQL Editor:**

1. Click en "New Query" (otra vez)
2. **Copia y pega TODO el contenido de:**
   ```
   SUPABASE_SETUP_FINAL.sql
   ```
3. Click en "Run"
4. Espera a que termine (puede tardar 10-15 segundos)
5. Verás "Success" ✅

**¡Listo! La base de datos está lista y corregida.**

---

## ✅ PASO 3: EJECUTAR LA APP MÓVIL

1. Abre terminal en la carpeta del proyecto:
   ```bash
   cd c:\Users\acer\3Warner\oolale_mobile
   ```

2. Instala dependencias (solo primera vez):
   ```bash
   flutter pub get
   ```

3. Ejecuta la app:
   ```bash
   flutter run
   ```

4. Selecciona dispositivo:
   - Chrome (para web) - **RECOMENDADO**
   - Android Emulator
   - iPhone Simulator

**¡Listo! La app está corriendo.**

---

## 🧪 PASO 4: PROBAR QUE TODO FUNCIONA

### Test Rápido (5 minutos):

1. **Registro:**
   - Click "Sign Up"
   - Email: `test1@test.com`
   - Password: `test123`
   - Registra

2. **Perfil:**
   - Ve a Perfil (icono persona)
   - Click "Editar"
   - Agrega: Instrumento = "Guitarra"
   - Guarda

3. **Segundo Usuario:**
   - Logout
   - Registra otro: `test2@test.com` / `test123`

4. **Conexión:**
   - Ve a Discovery (lupa)
   - Busca "test1"
   - Click "Conectar"
   - **Logout**
   - Login como `test1@test.com`
   - Ve a Conexiones
   - **Verás solicitud pendiente** ✅
   - Acepta
   - **Verás notificación** ✅

5. **Chat:**
   - Ve a Mensajes
   - Abre chat con test2
   - Escribe: "Hola"
   - **En otra ventana/pestaña:**
   - Login como `test2@test.com`
   - Ve a Mensajes
   - **Verás el mensaje EN TIEMPO REAL** ✅

6. **Evento:**
   - Como test1: Ve a Eventos
   - Click (+)
   - Crea evento: "Jam Session"
   - Como test2: Postúlate
   - Como test1: **Verás notificación** ✅

---

## ⚠️ ORDEN CORRECTO DE SCRIPTS

**IMPORTANTE - Ejecutar en este orden:**

```
1. SUPABASE_CLEAN.sql       ← Limpia todo
2. SUPABASE_SETUP_FINAL.sql ← Crea todo nuevo
3. flutter run              ← Ejecuta la app
```

**NO ejecutar:**
- ❌ `SUPABASE_SETUP.sql` (versión vieja)
- ❌ `SUPABASE_FIX_CRITICAL.sql` (ya no necesario)
- ❌ `SUPABASE_EXTENSIONS.sql` (ya incluido en FINAL)

---

## ❓ SOLUCIÓN DE PROBLEMAS

### Error: "column does not exist"
**Causa:** No ejecutaste SUPABASE_CLEAN.sql primero  
**Solución:**
1. Ejecuta `SUPABASE_CLEAN.sql`
2. Luego ejecuta `SUPABASE_SETUP_FINAL.sql`

### Error: "type already exists"
**Causa:** No se limpiaron los tipos  
**Solución:**
1. Vuelve a ejecutar `SUPABASE_CLEAN.sql`
2. Espera a que termine completamente
3. Ejecuta `SUPABASE_SETUP_FINAL.sql`

### La app no conecta
**Solución:**
1. Verifica en `lib/config/constants.dart`:
   ```dart
   supabaseUrl: 'https://lwrlunndqzepwsbmofki.supabase.co'
   supabaseKey: 'sb_publishable_nF-kOiwfnggVy5hrAxpvYw_bsPk5p7C'
   ```
2. Asegúrate de que sean tus credenciales correctas

### El chat no funciona
**Solución:**
1. Ve a Supabase Dashboard
2. Database → Tables
3. Busca tabla `intercom`
4. Verifica que tenga columnas:
   - `id_mensaje`
   - `id_remitente`
   - `id_destinatario`
   - `fecha_envio`
5. Si no las tiene, vuelve a ejecutar los scripts en orden

---

## 📊 VERIFICACIÓN EN SUPABASE

Después de ejecutar los scripts, verifica en Supabase Dashboard:

**Database → Tables:**
- ✅ profiles
- ✅ gigs
- ✅ gig_lineup
- ✅ intercom (con columnas correctas)
- ✅ crews
- ✅ notifications
- ✅ hirings
- ✅ reports
- ✅ blocks
- ✅ tickets_pagos
- ✅ gear_catalog
- ✅ generos_catalog

**Total: 12 tablas**

---

## 🎯 CHECKLIST COMPLETO

- [ ] `SUPABASE_CLEAN.sql` ejecutado
- [ ] `SUPABASE_SETUP_FINAL.sql` ejecutado
- [ ] 12 tablas creadas en Supabase
- [ ] `flutter pub get` ejecutado
- [ ] App corriendo
- [ ] 2 usuarios registrados
- [ ] Conexión funciona
- [ ] Notificación recibida
- [ ] Chat en tiempo real funciona
- [ ] Evento creado
- [ ] Postulación funciona

**Si todos ✅ = ¡APP 100% FUNCIONAL!** 🎉

---

## 💡 TIPS IMPORTANTES

1. **Siempre ejecuta CLEAN primero** si algo falla
2. **Usa Chrome** para desarrollo (más rápido)
3. **Abre 2 ventanas** para probar realtime
4. **Revisa Supabase Dashboard** para ver datos en vivo

---

## 🆘 SI NADA FUNCIONA

**Último recurso - Reset completo:**

1. En Supabase Dashboard → Settings → Database
2. Scroll hasta "Reset Database" (CUIDADO)
3. O simplemente ejecuta `SUPABASE_CLEAN.sql` de nuevo
4. Luego `SUPABASE_SETUP_FINAL.sql`
5. `flutter run`

---

**¡Ahora sí, todo debería funcionar! 🎸🔥**
