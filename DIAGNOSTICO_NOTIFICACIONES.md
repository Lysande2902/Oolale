# Diagnóstico de Notificaciones Push - Óolale

## ✅ Estado Actual

### Configuración Completada
- [x] Firebase inicializado correctamente
- [x] Token FCM obtenido: `e87lBJ7aRWGMS_J8QE7z9b:APA91bEDo0gpdLx8XSR9Kh09bsOsvRzFKevp9iiVgD0-3zdPsrtzugmO9GDcTRzB0ac6yNwn7NZBv-9i12kbCwnFex6Cyjh2bzTRCMsRS3mFwkdpRVURCkAU`
- [x] Token guardado en Supabase
- [x] Permisos de notificación: `AuthorizationStatus.authorized`
- [x] NotificationService inicializado correctamente

### Problema Reportado
❌ No se muestra la notificación cuando se envía desde Firebase Console

---

## 🔍 Pasos de Diagnóstico

### 1. Verificar que la app está en foreground
La app debe estar abierta y visible en la pantalla del dispositivo cuando envías la notificación de prueba.

### 2. Revisar logs de Flutter
Después de enviar la notificación, busca en los logs de Flutter:

**Logs esperados si la notificación llega:**
```
📨 ========================================
📨 MENSAJE RECIBIDO EN FOREGROUND!
📨 Message ID: [id]
📨 Notification: [notification object]
📨 Title: Prueba Óolale
📨 Body: Esta es una notificación de prueba
📨 Data: {}
📨 ========================================
🔔 Intentando mostrar notificación local...
   Título: Prueba Óolale
   Cuerpo: Esta es una notificación de prueba
✅ Notificación local mostrada exitosamente
```

**Si NO ves estos logs**, significa que la notificación no está llegando al dispositivo.

### 3. Verificar configuración de Firebase Console

Al enviar la notificación de prueba, asegúrate de:

1. **Ir a**: Firebase Console → Messaging → "Create your first campaign"
2. **Seleccionar**: "Firebase Notification messages"
3. **Llenar**:
   - Notification title: `Prueba Óolale`
   - Notification text: `Esta es una notificación de prueba`
4. **Click en**: "Send test message"
5. **Pegar el token FCM** (el de arriba)
6. **Click en**: "Test"

### 4. Verificar que el token es válido

Ejecuta este comando en la terminal de Flutter para verificar el token actual:

```bash
# En la consola de Flutter, presiona 'r' para hot reload
# Busca en los logs: "🔑 FCM Token: [token]"
```

### 5. Probar con diferentes estados de la app

#### A. App en Foreground (abierta y visible)
- La notificación debe mostrarse como notificación local
- Debe aparecer en la barra de notificaciones de Android

#### B. App en Background (minimizada)
- La notificación debe aparecer automáticamente en la barra de notificaciones
- Al tocarla, debe abrir la app

#### C. App cerrada (terminada)
- La notificación debe aparecer en la barra de notificaciones
- Al tocarla, debe abrir la app

---

## 🛠️ Soluciones Comunes

### Problema 1: Token inválido o expirado
**Solución**: Reinicia la app y obtén un nuevo token

```bash
# Detener la app
flutter run # Volver a ejecutar
# Buscar el nuevo token en los logs
```

### Problema 2: Permisos de notificación denegados
**Solución**: Verifica los permisos en el dispositivo

1. Ve a: Configuración → Apps → Óolale → Notificaciones
2. Asegúrate de que las notificaciones estén habilitadas

### Problema 3: Canal de notificaciones no creado
**Solución**: Ya está implementado en el código, pero verifica los logs:

```
✅ Notificaciones locales configuradas
```

### Problema 4: Firebase no está enviando la notificación
**Solución**: Usa el script de prueba alternativo

```bash
# Edita test_notification.js y agrega tu Server Key
# Luego ejecuta:
node test_notification.js
```

Para obtener el Server Key:
1. Firebase Console → Project Settings (⚙️)
2. Cloud Messaging tab
3. Copia el "Server key"

---

## 📊 Checklist de Verificación

- [ ] La app está corriendo en el dispositivo
- [ ] La app está en foreground (visible en pantalla)
- [ ] El token FCM es el correcto
- [ ] Los permisos de notificación están habilitados
- [ ] Firebase Console muestra "Message sent successfully"
- [ ] Los logs de Flutter muestran "📨 MENSAJE RECIBIDO EN FOREGROUND!"

---

## 🔧 Comandos Útiles

### Ver logs en tiempo real
```bash
# En la terminal donde corre flutter run
# Los logs aparecen automáticamente
```

### Hot reload (aplicar cambios sin reiniciar)
```bash
# Presiona 'r' en la terminal de Flutter
```

### Hot restart (reiniciar la app)
```bash
# Presiona 'R' en la terminal de Flutter
```

### Detener la app
```bash
# Presiona 'q' en la terminal de Flutter
```

---

## 📝 Información de Debug

### Token FCM Actual
```
e87lBJ7aRWGMS_J8QE7z9b:APA91bEDo0gpdLx8XSR9Kh09bsOsvRzFKevp9iiVgD0-3zdPsrtzugmO9GDcTRzB0ac6yNwn7NZBv-9i12kbCwnFex6Cyjh2bzTRCMsRS3mFwkdpRVURCkAU
```

### Usuario de Prueba
- Email: yenglee2006@gmail.com
- User ID: 9ba24d77-6819-4fed-97f4-7b2c66d7fcc7

### Plataforma
- Android (CPH2239)
- Bundle ID: com.oolale.oolale_mobile

---

## 🆘 Próximos Pasos

Si después de seguir todos estos pasos aún no funciona:

1. **Comparte los logs completos** después de enviar la notificación
2. **Verifica en Firebase Console** si hay errores en la sección de Messaging
3. **Prueba con el script Node.js** para descartar problemas con Firebase Console
4. **Verifica la configuración de google-services.json** (debe estar en `android/app/`)

---

## 📚 Referencias

- [Firebase Cloud Messaging - Flutter](https://firebase.flutter.dev/docs/messaging/overview/)
- [Flutter Local Notifications](https://pub.dev/packages/flutter_local_notifications)
- [Debugging FCM](https://firebase.google.com/docs/cloud-messaging/android/client#sample-play)
