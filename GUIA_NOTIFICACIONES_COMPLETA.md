# 🔔 GUÍA COMPLETA DE NOTIFICACIONES - Óolale Mobile

**Fecha:** 6 de Febrero, 2026  
**Versión:** 1.0.0  
**Estado:** ✅ Sistema Configurado

---

## 📋 ÍNDICE

1. [Cómo Funcionan las Notificaciones](#1-cómo-funcionan-las-notificaciones)
2. [Tipos de Notificaciones](#2-tipos-de-notificaciones)
3. [Configuración Actual](#3-configuración-actual)
4. [Cómo Probar las Notificaciones](#4-cómo-probar-las-notificaciones)
5. [Solución de Problemas](#5-solución-de-problemas)

---

## 1. CÓMO FUNCIONAN LAS NOTIFICACIONES

### **Sistema de Notificaciones Push**

Las notificaciones en Óolale son **REALES** y funcionan como cualquier app profesional (WhatsApp, Instagram, etc.):

```
┌─────────────────────────────────────────────────────────┐
│  FLUJO DE NOTIFICACIONES                                │
├─────────────────────────────────────────────────────────┤
│                                                          │
│  1. EVENTO EN LA APP                                    │
│     └─> Usuario envía mensaje                           │
│     └─> Usuario envía solicitud de conexión             │
│     └─> Usuario califica                                │
│                                                          │
│  2. BACKEND (Supabase)                                  │
│     └─> Detecta el evento                               │
│     └─> Obtiene token FCM del destinatario              │
│     └─> Envía notificación a Firebase                   │
│                                                          │
│  3. FIREBASE CLOUD MESSAGING                            │
│     └─> Recibe la notificación                          │
│     └─> La envía al dispositivo del usuario             │
│                                                          │
│  4. DISPOSITIVO DEL USUARIO                             │
│     ├─> App cerrada: Notificación en bandeja del sistema│
│     ├─> App en background: Notificación en bandeja      │
│     └─> App abierta: Notificación local dentro de la app│
│                                                          │
│  5. USUARIO TOCA LA NOTIFICACIÓN                        │
│     └─> App se abre en la pantalla correspondiente      │
│                                                          │
└─────────────────────────────────────────────────────────┘
```

### **Componentes del Sistema**

1. **Firebase Cloud Messaging (FCM):** Servicio de Google para enviar notificaciones push
2. **Flutter Local Notifications:** Muestra notificaciones cuando la app está abierta
3. **Supabase:** Backend que envía las notificaciones
4. **Tabla `tokens_dispositivo`:** Almacena los tokens FCM de cada usuario

---

## 2. TIPOS DE NOTIFICACIONES

### **Notificaciones Implementadas**

| Tipo | Descripción | Cuándo se envía | Navegación |
|------|-------------|-----------------|------------|
| `connection_request` | Solicitud de conexión | Cuando alguien te envía solicitud | → Solicitudes pendientes |
| `connection_accepted` | Conexión aceptada | Cuando aceptan tu solicitud | → Lista de conexiones |
| `new_message` | Mensaje nuevo | Cuando recibes un mensaje | → Chat con el usuario |
| `new_rating` | Nueva calificación | Cuando te califican | → Tus calificaciones |
| `event_invitation` | Invitación a evento | Cuando te invitan a un evento | → Detalle del evento |

### **Ejemplo de Notificación**

**En la bandeja del sistema Android:**
```
┌────────────────────────────────────┐
│ 🎸 Óolale                          │
├────────────────────────────────────┤
│ Nueva solicitud de conexión        │
│ Juan Pérez quiere conectar contigo │
│ Hace 2 minutos                     │
└────────────────────────────────────┘
```

**Dentro de la app (sección Notificaciones):**
```
┌────────────────────────────────────┐
│ 🔗 Nueva solicitud de conexión     │
│ Juan Pérez quiere conectar contigo │
│ Hace 2 minutos                     │
│ [Ver solicitud]                    │
└────────────────────────────────────┘
```

---

## 3. CONFIGURACIÓN ACTUAL

### **✅ Lo que YA está configurado:**

1. **Firebase Cloud Messaging**
   - ✅ Proyecto Firebase creado
   - ✅ `google-services.json` configurado
   - ✅ Permisos en AndroidManifest.xml
   - ✅ Inicialización en `main.dart`

2. **Servicio de Notificaciones**
   - ✅ `NotificationService` implementado
   - ✅ Solicitud de permisos
   - ✅ Guardado de tokens FCM
   - ✅ Handlers para foreground/background/terminated
   - ✅ Notificaciones locales configuradas

3. **Tabla en Supabase**
   - ✅ Tabla `tokens_dispositivo` creada
   - ✅ Tabla `notificaciones` creada

4. **Iconos**
   - ✅ Icono de la app generado
   - ✅ Icono de notificaciones configurado

### **❌ Lo que FALTA para que funcionen:**

1. **Backend (Supabase Functions o Edge Functions)**
   - ❌ Función para enviar notificaciones push
   - ❌ Triggers en la base de datos
   - ❌ Integración con Firebase Admin SDK

2. **Configuración de Firebase**
   - ❌ Clave privada del servidor (Service Account)
   - ❌ Configuración en Supabase

---

## 4. CÓMO PROBAR LAS NOTIFICACIONES

### **Opción 1: Prueba Manual con Firebase Console (Rápida)**

Esta opción te permite probar que las notificaciones funcionan SIN necesidad de configurar el backend.

#### **Pasos:**

1. **Instala la app en tu dispositivo:**
   ```cmd
   adb install build\app\outputs\flutter-apk\app-release.apk
   ```

2. **Abre la app y regístrate/inicia sesión**

3. **Obtén tu token FCM:**
   - Abre la app
   - Ve a la consola de Android Studio o usa `adb logcat`
   - Busca el log: `🔑 FCM Token: ...`
   - Copia el token completo

4. **Envía una notificación de prueba desde Firebase Console:**
   - Ve a: https://console.firebase.google.com
   - Selecciona tu proyecto "oolale"
   - Ve a "Cloud Messaging" en el menú lateral
   - Click en "Send your first message"
   - Completa el formulario:
     ```
     Título: Nueva solicitud de conexión
     Texto: Juan Pérez quiere conectar contigo
     ```
   - En "Target", selecciona "FCM registration token"
   - Pega tu token FCM
   - Click en "Test" o "Send"

5. **Verifica:**
   - **App cerrada:** Deberías ver la notificación en la bandeja del sistema
   - **App abierta:** Deberías ver una notificación local
   - **App en background:** Deberías ver la notificación en la bandeja

### **Opción 2: Configurar Backend Completo (Producción)**

Para que las notificaciones se envíen automáticamente cuando ocurren eventos en la app, necesitas configurar el backend.

#### **Requisitos:**

1. **Clave privada de Firebase (Service Account)**
2. **Supabase Edge Function o Cloud Function**
3. **Triggers en la base de datos**

#### **Pasos (Resumen):**

1. **Obtener Service Account de Firebase:**
   - Ve a Firebase Console → Project Settings → Service Accounts
   - Click en "Generate new private key"
   - Descarga el archivo JSON

2. **Crear Edge Function en Supabase:**
   ```typescript
   // supabase/functions/send-notification/index.ts
   import { serve } from "https://deno.land/std@0.168.0/http/server.ts"
   import { createClient } from 'https://esm.sh/@supabase/supabase-js@2'

   serve(async (req) => {
     const { userId, title, body, data } = await req.json()
     
     // Obtener token del usuario
     const supabase = createClient(...)
     const { data: tokens } = await supabase
       .from('tokens_dispositivo')
       .select('token')
       .eq('user_id', userId)
     
     // Enviar notificación a Firebase
     // ... código para enviar a FCM
     
     return new Response(JSON.stringify({ success: true }))
   })
   ```

3. **Crear triggers en Supabase:**
   ```sql
   -- Trigger para enviar notificación cuando hay nueva conexión
   CREATE OR REPLACE FUNCTION notify_new_connection()
   RETURNS TRIGGER AS $$
   BEGIN
     -- Llamar a la Edge Function
     PERFORM net.http_post(
       url := 'https://your-project.supabase.co/functions/v1/send-notification',
       body := json_build_object(
         'userId', NEW.user_id_2,
         'title', 'Nueva solicitud de conexión',
         'body', 'Alguien quiere conectar contigo',
         'data', json_build_object('type', 'connection_request')
       )
     );
     RETURN NEW;
   END;
   $$ LANGUAGE plpgsql;

   CREATE TRIGGER on_new_connection
   AFTER INSERT ON conexiones
   FOR EACH ROW
   EXECUTE FUNCTION notify_new_connection();
   ```

---

## 5. SOLUCIÓN DE PROBLEMAS

### **Problema: No aparecen notificaciones**

**Posibles causas:**

1. **Permisos no otorgados:**
   - Solución: Ve a Configuración → Apps → Óolale → Notificaciones → Activar

2. **Token FCM no guardado:**
   - Verifica en logs: `🔑 FCM Token: ...`
   - Si no aparece, revisa la inicialización de Firebase

3. **Backend no configurado:**
   - Las notificaciones solo funcionan si el backend las envía
   - Usa la Opción 1 (Firebase Console) para probar

4. **App en modo debug:**
   - Compila en release: `flutter build apk --release`

### **Problema: El icono no se ve**

**Solución:**
- Ya está solucionado con `flutter_launcher_icons`
- Recompila la app: `flutter clean && flutter build apk --release`

### **Problema: Notificaciones no navegan correctamente**

**Causa:**
- La navegación desde notificaciones está parcialmente implementada

**Solución:**
- Actualizar `_handleNotificationTap()` en `notification_service.dart`
- Usar GoRouter para navegar a las pantallas correctas

---

## 📊 CHECKLIST DE VERIFICACIÓN

### **Configuración Básica:**
- [x] Firebase inicializado
- [x] google-services.json configurado
- [x] Permisos en AndroidManifest.xml
- [x] NotificationService implementado
- [x] Iconos generados

### **Funcionalidad:**
- [x] App solicita permisos de notificaciones
- [x] Token FCM se guarda en Supabase
- [x] Notificaciones locales funcionan (app abierta)
- [ ] Notificaciones push funcionan (app cerrada) - **Requiere backend**
- [ ] Navegación desde notificaciones - **Parcialmente implementado**

### **Backend (Pendiente):**
- [ ] Edge Function para enviar notificaciones
- [ ] Triggers en base de datos
- [ ] Service Account de Firebase configurado

---

## 🚀 PRÓXIMOS PASOS

### **Para Testing Inmediato:**
1. Usa la **Opción 1** (Firebase Console) para probar notificaciones
2. Verifica que aparecen en la bandeja del sistema
3. Prueba con la app cerrada, abierta y en background

### **Para Producción:**
1. Configura el backend (Edge Functions)
2. Implementa los triggers en Supabase
3. Prueba todos los tipos de notificaciones
4. Implementa navegación completa desde notificaciones

---

## 📝 NOTAS IMPORTANTES

1. **Las notificaciones SON reales** - aparecen en la bandeja del sistema Android como cualquier app profesional

2. **El backend es necesario** - sin backend, las notificaciones no se envían automáticamente (pero puedes probarlas manualmente)

3. **Los iconos ya están configurados** - después de recompilar, el icono de Óolale aparecerá correctamente

4. **La sección de notificaciones dentro de la app** ya existe en `/notifications` y muestra el historial

---

**Última actualización:** 6 de Febrero, 2026
