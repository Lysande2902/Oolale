# 🚀 DESPLEGAR EDGE FUNCTION PARA NOTIFICACIONES - Paso a Paso

**Fecha:** 6 de Febrero, 2026  
**Tiempo estimado:** 10-15 minutos  
**Dificultad:** Media

---

## 📋 ¿QUÉ VAMOS A HACER?

Como la **API heredada de Firebase está inhabilitada** y solo la **API v1 está habilitada**, necesitamos desplegar una **Edge Function en Supabase** que:

1. Genere tokens JWT con tu Service Account
2. Obtenga Access Tokens de Google OAuth2
3. Envíe notificaciones a Firebase Cloud Messaging API v1

---

## 🎯 PASO 1: Instalar Supabase CLI

### **Windows (usando npm)**

Abre PowerShell o CMD y ejecuta:

```bash
npm install -g supabase
```

### **Verificar instalación**

```bash
supabase --version
```

Deberías ver algo como: `supabase version 1.x.x`

---

## 🔐 PASO 2: Iniciar sesión en Supabase

```bash
supabase login
```

Esto abrirá tu navegador para que inicies sesión con tu cuenta de Supabase.

---

## 📁 PASO 3: Inicializar proyecto Supabase

En la carpeta `oolale_mobile`, ejecuta:

```bash
cd C:\Users\acer\3Warner\oolale_mobile
supabase init
```

Esto creará una carpeta `supabase/` con la estructura necesaria.

---

## 🔧 PASO 4: Crear la Edge Function

```bash
supabase functions new send-notification
```

Esto creará el archivo: `supabase/functions/send-notification/index.ts`

---

## 📝 PASO 5: Copiar el código de la Edge Function

**Opción A: Copiar manualmente**

1. Abre el archivo que acabas de crear: `supabase/functions/send-notification/index.ts`
2. Abre el archivo: `supabase_edge_function_send_notification.ts` (que ya existe en tu proyecto)
3. Copia TODO el contenido de `supabase_edge_function_send_notification.ts`
4. Pégalo en `supabase/functions/send-notification/index.ts`
5. Guarda el archivo

**Opción B: Usar comando (PowerShell)**

```powershell
Copy-Item supabase_edge_function_send_notification.ts supabase\functions\send-notification\index.ts
```

---

## 🔑 PASO 6: Configurar Secrets en Supabase

Necesitas configurar 3 secrets con la información de tu Service Account:

### **6.1 Obtener tu Project Reference**

1. Ve a: https://supabase.com/dashboard
2. Selecciona tu proyecto de Óolale
3. En la URL verás algo como: `https://supabase.com/dashboard/project/[PROJECT_REF]`
4. Copia el `[PROJECT_REF]` (ejemplo: `abcdefghijklmnop`)

### **6.2 Vincular tu proyecto local**

```bash
supabase link --project-ref TU_PROJECT_REF_AQUI
```

Ejemplo:
```bash
supabase link --project-ref abcdefghijklmnop
```

### **6.3 Configurar los secrets**

Ejecuta estos 3 comandos (reemplaza con tus valores reales):

```bash
supabase secrets set FIREBASE_PROJECT_ID=oolale
```

```bash
supabase secrets set FIREBASE_CLIENT_EMAIL=firebase-adminsdk-fbsvc@oolale.iam.gserviceaccount.com
```

```bash
supabase secrets set FIREBASE_PRIVATE_KEY="-----BEGIN PRIVATE KEY-----
MIIEvQIBADANBgkqhkiG9w0BAQEFAASCBKcwggSjAgEAAoIBAQCxTxt6TKoRZrjV
15+cZKS9/Rhr1t4FvDw625ZNe++cZe+n/oxm9zbYeN3FT+GQcwQZvgKYX8emn0CV
gTuckZSjhUtL38efes0Nny8Wtck+QeDIYy1vuhm9z9nJ64xSXiUyiApbtzT7bVAv
NZHUHFVRxF8wyE3d8+jgApatnXpUaPjIJisiNUszGNOu9GpRaK2Zv/QS9fgn+q4k
M9/pa9qo/aJ1QPL3r0F+3Gf21aQ86HTH/MUAKrsxOnacQZajPfFVpQZiG8Sw0k4E
ACcu0XWYBNjLjlyu0coE07OM4WnjUou1HNrwbCEkJFMvtIwYqrRxSYNspPgeMS7L
qpxFCdghAgMBAAECggEAA3Bieu0m/MqqYdpqafsBP36b1Uaf/Io9vFIDQKo7V+QZ
wX9ES6B2n7z7Zy7xE+9JKHMpI3mzGoIa+3Nb28HumTvV/akf2vHjrYSVghohRrv6
H0TeLh00z9vK0HnpOTVCgTAGjGgZptlETYAbXZr1lC4L/xsZeIk5LnQaZlBoPaAZ
04QQL5ouXqdovOLIV7rpJ4k6p5/lcuNk/dlaLss2JGaBPdEWOYlPJyz9OD54fBGB
8daBST7nx3++cBy0MVXqQMjWRB0br4JM1ZE2WbkRjYn7KpB/R9VGct2QxDGyi9NQ
3QiIqP6Bnu3M5uFzDaI0DbkLLycZtMSv+kAWaxr1AQKBgQDbbmyqdzJEisc/TlWu
2C1jRLargxPJfY2e9Yv9HXISyC7x1QP7FevP+e7BqXX5eQr04pf8bNJq84R8gRpt
Hz0Vr59K9AEflPd9aWipTA0qQI9dyxeD20MBSDWhTh8rHRt+vb3UlZwhYn7lZCpM
tfhVOFYUXYgHzGOaR7p3SZEoYQKBgQDO259Urg89xcrRHVMJaVISR3coN4+YUPy6
v4Q1Cay1jcCJ17t2SJ6s9ZssdfeTF9leS0KSTJDgKHV3oVR3Hu5WO8r27W/mtxvs
MlwYrAdHUTVyB862UjMd//TfKf8+vpb6XhQxOKreXONq44LPKnSbM/9CaQEfxluD
3MQUh5fHwQKBgQCPd55CwhYyrE3jfTMWUy8xxT5t2xC334gV01OI1ZS85PeUlAK7
SrTYUQAizMpepx5byD85Aml9FeSchsihahhFMoNCvVBytrIt5BpS/m9pHbbeyyd/
xX8EupKd+Xb1eF1+u03/TSY8yapQDvJ9H0jTZzcYr6J9/stsltM6pPXsYQKBgAD0
1PzAPUPM2U40M4EUopOBDxT5hMlwfmqingrcu5avTBeXDr/SQCGOlSQUe4uLja64
7FrezcCrjzd5YHmYhAOUDTEtEdpgOFnUNcbLbNEwl+2qCZOgN6pI16n8eLiiivIn
YzKDD48toMOKv70TdiyNhf2ZnK637Q5kA+gQZGxBAoGAboUFX9eVo230RPTRUTXL
Mvpco7h5eP8KGtuA10hWnb4bCaDjcjSorhiqycGekqt27yNg6YOiLTxIhc83GcnR
EDwta4iXEEbBRpKYAHALwyS5Q8xDvhxvTjcuF5YWUmI4W8fsSo9i45LxSBKlAEQ0
kwy2NwNHai8/q5eWmM7fahc=
-----END PRIVATE KEY-----"
```

⚠️ **IMPORTANTE:** El private key debe estar entre comillas dobles y con los saltos de línea `\n` preservados.

---

## 🚀 PASO 7: Desplegar la Edge Function

```bash
supabase functions deploy send-notification
```

Esto desplegará la función en Supabase. Deberías ver:

```
Deploying function send-notification...
Function send-notification deployed successfully!
URL: https://[tu-proyecto].supabase.co/functions/v1/send-notification
```

**Copia esta URL**, la necesitarás en el siguiente paso.

---

## 📊 PASO 8: Actualizar el script SQL

Ahora necesitas actualizar la función SQL para que llame a la Edge Function que acabas de desplegar.

### **8.1 Abrir Supabase SQL Editor**

1. Ve a: https://supabase.com/dashboard
2. Selecciona tu proyecto
3. Click en **"SQL Editor"**
4. Click en **"New query"**

### **8.2 Ejecutar este script**

Reemplaza `TU_URL_EDGE_FUNCTION_AQUI` con la URL que obtuviste en el paso anterior:

```sql
-- ============================================
-- ACTUALIZAR FUNCIÓN PARA USAR EDGE FUNCTION
-- ============================================

CREATE OR REPLACE FUNCTION send_push_notification_v1(
    p_user_id UUID,
    p_title TEXT,
    p_body TEXT,
    p_notification_type TEXT,
    p_data JSONB DEFAULT '{}'::jsonb
)
RETURNS BOOLEAN AS $$
DECLARE
    v_token TEXT;
    v_notification_id UUID;
    v_edge_function_url TEXT := 'TU_URL_EDGE_FUNCTION_AQUI';
    v_response TEXT;
BEGIN
    -- Guardar notificación en la base de datos
    INSERT INTO notificaciones (
        user_id,
        title,
        message,
        type,
        data,
        leido,
        created_at
    ) VALUES (
        p_user_id,
        p_title,
        p_body,
        p_notification_type,
        p_data,
        FALSE,
        NOW()
    ) RETURNING id INTO v_notification_id;
    
    -- Obtener todos los tokens del usuario
    FOR v_token IN 
        SELECT token 
        FROM tokens_dispositivo 
        WHERE user_id = p_user_id 
        AND token IS NOT NULL
    LOOP
        BEGIN
            -- Llamar a la Edge Function
            SELECT content INTO v_response
            FROM http((
                'POST',
                v_edge_function_url,
                ARRAY[
                    http_header('Content-Type', 'application/json'),
                    http_header('Authorization', 'Bearer ' || current_setting('request.jwt.claims', true)::json->>'sub')
                ],
                'application/json',
                json_build_object(
                    'user_id', p_user_id,
                    'title', p_title,
                    'body', p_body,
                    'type', p_notification_type,
                    'data', p_data || jsonb_build_object('token', v_token)
                )::text
            )::http_request);
            
            RAISE NOTICE 'Notificación enviada a token: %', LEFT(v_token, 20) || '...';
            
        EXCEPTION WHEN OTHERS THEN
            RAISE NOTICE 'Error enviando notificación: %', SQLERRM;
        END;
    END LOOP;
    
    RETURN TRUE;
    
EXCEPTION WHEN OTHERS THEN
    RAISE NOTICE 'Error en send_push_notification_v1: %', SQLERRM;
    RETURN FALSE;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- Verificar que la función se actualizó
SELECT '✅ Función actualizada correctamente' as status;
```

---

## 🧪 PASO 9: Probar el sistema completo

### **9.1 Obtener tu User ID**

```sql
SELECT 
    id as user_id,
    email
FROM auth.users
ORDER BY created_at DESC
LIMIT 5;
```

### **9.2 Enviar notificación de prueba**

```sql
SELECT test_notification_v1('TU_USER_ID_AQUI'::uuid);
```

### **9.3 Verificar en tu dispositivo**

Deberías recibir una notificación push real en tu dispositivo Android.

---

## 🎉 PASO 10: Probar notificaciones automáticas

Ahora las notificaciones se enviarán automáticamente cuando:

1. **Envíes una solicitud de conexión** → El otro usuario recibe notificación
2. **Acepten tu solicitud** → Recibes notificación
3. **Envíes un mensaje** → El receptor recibe notificación
4. **Califiques a alguien** → Esa persona recibe notificación
5. **Invites a un evento** → Los invitados reciben notificación

---

## 🔍 VERIFICAR QUE TODO FUNCIONA

### **Ver logs de la Edge Function**

```bash
supabase functions logs send-notification
```

### **Ver notificaciones en la base de datos**

```sql
SELECT 
    n.title,
    n.message,
    n.type,
    p.artist_name as recipient,
    n.created_at
FROM notificaciones n
JOIN profiles p ON p.user_id = n.user_id
ORDER BY n.created_at DESC
LIMIT 10;
```

---

## 🐛 SOLUCIÓN DE PROBLEMAS

### **Problema 1: Error al desplegar la función**

```bash
# Ver logs detallados
supabase functions deploy send-notification --debug
```

### **Problema 2: La función se desplegó pero no envía notificaciones**

```bash
# Ver logs en tiempo real
supabase functions logs send-notification --follow
```

### **Problema 3: Error de autenticación**

Verifica que los secrets estén configurados correctamente:

```bash
supabase secrets list
```

Deberías ver:
- `FIREBASE_PROJECT_ID`
- `FIREBASE_CLIENT_EMAIL`
- `FIREBASE_PRIVATE_KEY`

---

## ✅ CHECKLIST FINAL

- [ ] Instalé Supabase CLI
- [ ] Inicié sesión en Supabase
- [ ] Inicialicé el proyecto con `supabase init`
- [ ] Creé la Edge Function con `supabase functions new send-notification`
- [ ] Copié el código a `supabase/functions/send-notification/index.ts`
- [ ] Vinculé mi proyecto con `supabase link`
- [ ] Configuré los 3 secrets (PROJECT_ID, CLIENT_EMAIL, PRIVATE_KEY)
- [ ] Desplegué la función con `supabase functions deploy`
- [ ] Actualicé el script SQL con la URL de la Edge Function
- [ ] Probé con `test_notification_v1()`
- [ ] Recibí la notificación en mi dispositivo
- [ ] Probé las notificaciones automáticas

---

## 🎯 RESULTADO FINAL

Si completaste todos los pasos, ahora tienes:

✅ **Edge Function desplegada en Supabase**  
✅ **Notificaciones automáticas usando Firebase API v1**  
✅ **5 tipos de notificaciones configuradas**  
✅ **Sistema completamente funcional**

---

## 📞 COMANDOS ÚTILES

```bash
# Ver todas las funciones desplegadas
supabase functions list

# Ver logs en tiempo real
supabase functions logs send-notification --follow

# Eliminar una función
supabase functions delete send-notification

# Re-desplegar después de cambios
supabase functions deploy send-notification
```

---

**¡Felicidades! 🎉 Tu sistema de notificaciones con API v1 está completo.**

---

**Última actualización:** 6 de Febrero, 2026
