# 🚀 CONFIGURAR NOTIFICACIONES AUTOMÁTICAS - Paso a Paso

**Fecha:** 6 de Febrero, 2026  
**Tiempo estimado:** 15-20 minutos  
**Dificultad:** Media

---

## 📋 LO QUE VAS A LOGRAR

Después de seguir esta guía, las notificaciones se enviarán **automáticamente** cuando:
- ✅ Alguien te envía una solicitud de conexión
- ✅ Aceptan tu solicitud de conexión
- ✅ Recibes un mensaje nuevo
- ✅ Alguien te califica
- ✅ Te invitan a un evento

---

## 🎯 PASO 1: Obtener el Server Key de Firebase

### **1.1 Ir a Firebase Console**

1. Abre tu navegador y ve a: https://console.firebase.google.com
2. Inicia sesión con tu cuenta de Google
3. Selecciona el proyecto **"oolale"**

### **1.2 Obtener el Server Key**

1. Click en el ícono de **⚙️ (Settings)** en la parte superior izquierda
2. Selecciona **"Project settings"**
3. Ve a la pestaña **"Cloud Messaging"**
4. Busca la sección **"Cloud Messaging API (Legacy)"**
5. Copia el **"Server key"** (es una cadena larga que empieza con "AAAA...")

**Ejemplo:**
```
Server key: AAAAxxx...xxxyyy (cadena de ~150 caracteres)
```

⚠️ **IMPORTANTE:** Guarda este key en un lugar seguro, lo necesitarás en el siguiente paso.

---

## 🗄️ PASO 2: Ejecutar el Script SQL en Supabase

### **2.1 Abrir Supabase SQL Editor**

1. Ve a: https://supabase.com/dashboard
2. Selecciona tu proyecto de Óolale
3. En el menú lateral, click en **"SQL Editor"**
4. Click en **"New query"**

### **2.2 Ejecutar el Script**

1. Abre el archivo: `SETUP_NOTIFICACIONES_AUTOMATICAS.sql`
2. **Copia TODO el contenido** del archivo
3. **Pégalo** en el SQL Editor de Supabase
4. Click en **"Run"** (botón verde en la esquina inferior derecha)

**Resultado esperado:**
```
Success. No rows returned
```

### **2.3 Actualizar el Server Key**

Ahora necesitas actualizar la configuración con tu Server Key real:

1. En el SQL Editor, ejecuta este comando (reemplaza con tu Server Key):

```sql
UPDATE firebase_config 
SET server_key = 'AAAA_TU_SERVER_KEY_REAL_AQUI',
    updated_at = NOW();
```

2. Click en **"Run"**

**Resultado esperado:**
```
Success. 1 row affected
```

### **2.4 Verificar la configuración**

Ejecuta este comando para verificar:

```sql
SELECT 
    CASE 
        WHEN server_key = 'TU_SERVER_KEY_AQUI' THEN '❌ Server Key NO configurado'
        ELSE '✅ Server Key configurado'
    END as status,
    project_id,
    created_at
FROM firebase_config;
```

**Resultado esperado:**
```
status: ✅ Server Key configurado
project_id: oolale
created_at: 2026-02-06 ...
```

---

## 🧪 PASO 3: Probar el Sistema

### **3.1 Obtener tu User ID**

Primero necesitas tu user_id. Ejecuta en Supabase:

```sql
SELECT 
    id as user_id,
    email,
    created_at
FROM auth.users
ORDER BY created_at DESC
LIMIT 5;
```

Copia tu `user_id` (es un UUID como: `123e4567-e89b-12d3-a456-426614174000`)

### **3.2 Enviar notificación de prueba**

Ejecuta este comando (reemplaza con tu user_id):

```sql
SELECT test_notification('TU_USER_ID_AQUI'::uuid);
```

**Ejemplo:**
```sql
SELECT test_notification('123e4567-e89b-12d3-a456-426614174000'::uuid);
```

**Resultado esperado:**
```
test_notification: true
```

### **3.3 Verificar en tu dispositivo**

**Deberías recibir una notificación que dice:**
```
┌────────────────────────────────────┐
│ 🎸 Óolale                          │
├────────────────────────────────────┤
│ Notificación de prueba             │
│ Si ves esto, el sistema funciona   │
│ correctamente ✅                    │
└────────────────────────────────────┘
```

✅ **Si la recibiste:** ¡Perfecto! El sistema funciona.  
❌ **Si NO la recibiste:** Ve a la sección de [Solución de Problemas](#solución-de-problemas)

---

## 🎉 PASO 4: Probar Notificaciones Reales

Ahora vamos a probar que las notificaciones se envían automáticamente:

### **4.1 Probar: Solicitud de Conexión**

1. Abre la app en tu dispositivo
2. Busca otro usuario
3. Envía una solicitud de conexión
4. **El otro usuario debería recibir una notificación** 📱

### **4.2 Probar: Mensaje Nuevo**

1. Envía un mensaje a una conexión
2. **La otra persona debería recibir una notificación** 💬

### **4.3 Probar: Calificación**

1. Califica a un usuario
2. **Ese usuario debería recibir una notificación** ⭐

---

## 🔍 VERIFICAR QUE TODO FUNCIONA

### **Ver notificaciones enviadas:**

```sql
SELECT 
    n.title,
    n.message,
    n.type,
    p.artist_name as recipient,
    n.created_at,
    n.leido as read
FROM notificaciones n
JOIN profiles p ON p.user_id = n.user_id
ORDER BY n.created_at DESC
LIMIT 10;
```

### **Ver tokens de dispositivos:**

```sql
SELECT 
    p.artist_name,
    t.platform,
    LEFT(t.token, 30) || '...' as token_preview,
    t.updated_at
FROM tokens_dispositivo t
JOIN profiles p ON p.user_id = t.user_id
ORDER BY t.updated_at DESC;
```

### **Ver triggers activos:**

```sql
SELECT 
    trigger_name,
    event_object_table as table_name,
    action_timing as when_fires
FROM information_schema.triggers
WHERE trigger_name LIKE '%notify%'
ORDER BY event_object_table, trigger_name;
```

**Deberías ver:**
- ✅ `on_connection_request` en tabla `conexiones`
- ✅ `on_connection_accepted` en tabla `conexiones`
- ✅ `on_new_message` en tabla `mensajes`
- ✅ `on_new_rating` en tabla `calificaciones`
- ✅ `on_event_invitation` en tabla `event_participants`

---

## 🐛 SOLUCIÓN DE PROBLEMAS

### **Problema 1: No recibo la notificación de prueba**

**Posibles causas:**

1. **Server Key incorrecto:**
   ```sql
   -- Verificar
   SELECT server_key FROM firebase_config;
   
   -- Si es incorrecto, actualizar
   UPDATE firebase_config 
   SET server_key = 'TU_SERVER_KEY_CORRECTO';
   ```

2. **Token FCM no guardado:**
   ```sql
   -- Verificar que tu token existe
   SELECT * FROM tokens_dispositivo 
   WHERE user_id = 'TU_USER_ID'::uuid;
   ```
   
   Si no aparece:
   - Cierra y abre la app
   - Verifica los logs: `🔑 FCM Token: ...`

3. **Extensión HTTP no habilitada:**
   ```sql
   -- Verificar
   SELECT * FROM pg_extension WHERE extname = 'http';
   
   -- Si no existe, habilitar
   CREATE EXTENSION http;
   ```

### **Problema 2: La notificación de prueba funciona pero las automáticas no**

**Verificar que los triggers están activos:**

```sql
SELECT 
    trigger_name,
    event_object_table,
    action_statement
FROM information_schema.triggers
WHERE trigger_name LIKE '%notify%';
```

Si no aparecen, vuelve a ejecutar el script `SETUP_NOTIFICACIONES_AUTOMATICAS.sql`

### **Problema 3: Error "permission denied for extension http"**

**Solución:**

Necesitas permisos de superusuario. Contacta al soporte de Supabase o ejecuta:

```sql
-- Alternativa: usar pg_net en lugar de http
CREATE EXTENSION IF NOT EXISTS pg_net;
```

Luego modifica la función `send_push_notification` para usar `pg_net` en lugar de `http`.

### **Problema 4: Ver logs de errores**

```sql
-- Ver logs de PostgreSQL (si tienes acceso)
SELECT * FROM pg_stat_statements 
WHERE query LIKE '%send_push_notification%'
ORDER BY calls DESC;
```

---

## 📊 MONITOREO Y ESTADÍSTICAS

### **Notificaciones enviadas hoy:**

```sql
SELECT 
    type,
    COUNT(*) as total,
    COUNT(CASE WHEN leido THEN 1 END) as read,
    COUNT(CASE WHEN NOT leido THEN 1 END) as unread
FROM notificaciones
WHERE created_at >= CURRENT_DATE
GROUP BY type
ORDER BY total DESC;
```

### **Usuarios más activos (que más notificaciones reciben):**

```sql
SELECT 
    p.artist_name,
    COUNT(*) as notifications_received,
    COUNT(CASE WHEN n.leido THEN 1 END) as read,
    MAX(n.created_at) as last_notification
FROM notificaciones n
JOIN profiles p ON p.user_id = n.user_id
WHERE n.created_at >= CURRENT_DATE - INTERVAL '7 days'
GROUP BY p.artist_name
ORDER BY notifications_received DESC
LIMIT 10;
```

### **Tasa de apertura de notificaciones:**

```sql
SELECT 
    type,
    COUNT(*) as total,
    ROUND(100.0 * COUNT(CASE WHEN leido THEN 1 END) / COUNT(*), 2) as open_rate_percent
FROM notificaciones
WHERE created_at >= CURRENT_DATE - INTERVAL '7 days'
GROUP BY type
ORDER BY open_rate_percent DESC;
```

---

## ✅ CHECKLIST FINAL

Marca cada item cuando lo completes:

- [ ] Obtuve el Server Key de Firebase
- [ ] Ejecuté el script SQL en Supabase
- [ ] Actualicé el Server Key en la configuración
- [ ] Verifiqué que el Server Key está configurado
- [ ] Envié una notificación de prueba
- [ ] Recibí la notificación de prueba en mi dispositivo
- [ ] Probé una solicitud de conexión (notificación automática)
- [ ] Probé enviar un mensaje (notificación automática)
- [ ] Verifiqué los triggers en la base de datos
- [ ] Revisé las notificaciones en la tabla

---

## 🎯 RESULTADO FINAL

Si completaste todos los pasos, ahora tienes:

✅ **Notificaciones automáticas funcionando**  
✅ **5 tipos de notificaciones configuradas**  
✅ **Sistema de monitoreo y estadísticas**  
✅ **Logs y debugging habilitados**

---

## 📞 SOPORTE

Si tienes problemas:

1. Revisa la sección de [Solución de Problemas](#solución-de-problemas)
2. Verifica los logs en Supabase
3. Consulta `GUIA_NOTIFICACIONES_COMPLETA.md`
4. Revisa `SISTEMA_MENSAJES_NOTIFICACIONES.md`

---

**¡Felicidades! 🎉 Tu sistema de notificaciones está completo y funcionando.**

---

**Última actualización:** 6 de Febrero, 2026
