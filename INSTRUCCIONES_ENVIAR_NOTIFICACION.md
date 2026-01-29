# 📱 Cómo Enviar Notificaciones de Prueba - Óolale

## Problema Actual
La API heredada de Firebase Cloud Messaging está inhabilitada, por lo que no podemos usar "Send test message" desde Firebase Console.

## ✅ Solución: Usar API V1 con Postman o cURL

### Paso 1: Obtener el Access Token

1. Ve a: https://console.firebase.google.com/project/oolale/settings/serviceaccounts/adminsdk

2. Click en **"Generate new private key"** (Generar nueva clave privada)

3. Se descargará un archivo JSON. Ábrelo y copia todo su contenido.

4. Ve a: https://developers.google.com/oauthplayground/

5. En la esquina superior derecha, click en el ícono de configuración (⚙️)

6. Marca la casilla **"Use your own OAuth credentials"**

7. En el campo de la izquierda, busca y selecciona:
   ```
   https://www.googleapis.com/auth/firebase.messaging
   ```

8. Click en **"Authorize APIs"**

9. Inicia sesión con tu cuenta de Google (la que tiene acceso al proyecto Firebase)

10. Copia el **Access Token** que aparece

### Paso 2: Enviar la Notificación con cURL

Abre una terminal y ejecuta este comando (reemplaza `YOUR_ACCESS_TOKEN` con el token que copiaste):

```bash
curl -X POST https://fcm.googleapis.com/v1/projects/oolale/messages:send \
  -H "Authorization: Bearer YOUR_ACCESS_TOKEN" \
  -H "Content-Type: application/json" \
  -d '{
    "message": {
      "token": "e87lBJ7aRWGMS_J8QE7z9b:APA91bEDo0gpdLx8XSR9Kh09bsOsvRzFKevp9iiVgD0-3zdPsrtzugmO9GDcTRzB0ac6yNwn7NZBv-9i12kbCwnFex6Cyjh2bzTRCMsRS3mFwkdpRVURCkAU",
      "notification": {
        "title": "Prueba Óolale",
        "body": "Esta es una notificación de prueba"
      },
      "data": {
        "type": "test",
        "message": "Notificación de prueba"
      },
      "android": {
        "priority": "high",
        "notification": {
          "sound": "default",
          "channel_id": "high_importance_channel"
        }
      }
    }
  }'
```

### Paso 3: Verificar

Después de ejecutar el comando:
1. Revisa tu dispositivo Android - debe aparecer la notificación
2. Revisa los logs de Flutter - debe aparecer: `📨 MENSAJE RECIBIDO EN FOREGROUND!`

---

## 🔧 Alternativa: Usar Postman

Si prefieres usar Postman:

1. **Método**: POST

2. **URL**: 
   ```
   https://fcm.googleapis.com/v1/projects/oolale/messages:send
   ```

3. **Headers**:
   ```
   Authorization: Bearer YOUR_ACCESS_TOKEN
   Content-Type: application/json
   ```

4. **Body** (raw JSON):
   ```json
   {
     "message": {
       "token": "e87lBJ7aRWGMS_J8QE7z9b:APA91bEDo0gpdLx8XSR9Kh09bsOsvRzFKevp9iiVgD0-3zdPsrtzugmO9GDcTRzB0ac6yNwn7NZBv-9i12kbCwnFex6Cyjh2bzTRCMsRS3mFwkdpRVURCkAU",
       "notification": {
         "title": "Prueba Óolale",
         "body": "Esta es una notificación de prueba"
       },
       "data": {
         "type": "test",
         "message": "Notificación de prueba"
       },
       "android": {
         "priority": "high",
         "notification": {
           "sound": "default",
           "channel_id": "high_importance_channel"
         }
       }
     }
   }
   ```

5. Click en **Send**

---

## 📝 Notas Importantes

- El Access Token expira después de 1 hora. Si no funciona, genera uno nuevo.
- Asegúrate de que la app esté corriendo en el dispositivo cuando envíes la notificación.
- Revisa los logs de Flutter para ver si la notificación llega.

---

## 🆘 Si Nada Funciona

Si después de todo esto las notificaciones aún no llegan, el problema puede ser:

1. **Configuración de Firebase incorrecta**: Verifica que el `google-services.json` sea el correcto
2. **Token FCM inválido**: Reinicia la app y obtén un nuevo token
3. **Permisos de notificación**: Verifica en Configuración → Apps → Óolale → Notificaciones

---

## ✅ Próximos Pasos

Una vez que las notificaciones funcionen:
1. Implementar el backend para enviar notificaciones automáticas
2. Crear funciones en Supabase para enviar notificaciones cuando ocurran eventos
3. Implementar la navegación cuando el usuario toca una notificación
