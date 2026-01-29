# 🔔 Guía Completa: Configuración de Firebase y Notificaciones Push

## 📋 Índice
1. [Configuración de Firebase Console](#1-configuración-de-firebase-console)
2. [Configuración en Android](#2-configuración-en-android)
3. [Configuración en iOS](#3-configuración-en-ios)
4. [Instalación de Dependencias](#4-instalación-de-dependencias)
5. [Implementación del Código](#5-implementación-del-código)
6. [Pruebas](#6-pruebas)

---

## 1. Configuración de Firebase Console

### Paso 1.1: Crear Proyecto en Firebase

1. Ve a [Firebase Console](https://console.firebase.google.com/)
2. Click en "Agregar proyecto" o "Add project"
3. Nombre del proyecto: `oolale-mobile` (o el que prefieras)
4. Acepta los términos y click en "Continuar"
5. **Desactiva Google Analytics** (opcional, puedes activarlo después)
6. Click en "Crear proyecto"
7. Espera a que se cree el proyecto (1-2 minutos)
8. Click en "Continuar"

---

### Paso 1.2: Agregar App Android

1. En la página principal del proyecto, click en el ícono de **Android**
2. Completa los campos:
   - **Nombre del paquete de Android**: `com.oolale.oolale_mobile`
     - ⚠️ **IMPORTANTE**: Este debe coincidir exactamente con el `applicationId` en tu `android/app/build.gradle.kts`
   - **Sobrenombre de la app** (opcional): `Óolale Mobile`
   - **Certificado de firma SHA-1** (opcional por ahora, necesario para producción)
3. Click en "Registrar app"

---

### Paso 1.3: Descargar google-services.json

1. Click en "Descargar google-services.json"
2. **Guarda este archivo** - lo necesitarás en el siguiente paso
3. Click en "Siguiente"
4. Click en "Siguiente" (la configuración del SDK la haremos manualmente)
5. Click en "Continuar a la consola"

---

### Paso 1.4: Agregar App iOS (Opcional)

Si vas a compilar para iOS:

1. En la página principal del proyecto, click en el ícono de **iOS**
2. Completa los campos:
   - **ID del paquete de iOS**: `com.oolale.oolaleMobile`
     - ⚠️ **IMPORTANTE**: Este debe coincidir con el Bundle ID en Xcode
   - **Sobrenombre de la app** (opcional): `Óolale Mobile`
3. Click en "Registrar app"
4. Click en "Descargar GoogleService-Info.plist"
5. **Guarda este archivo** - lo necesitarás después
6. Click en "Siguiente" → "Siguiente" → "Continuar a la consola"

---

### Paso 1.5: Habilitar Cloud Messaging

1. En Firebase Console, ve a **Build** → **Cloud Messaging**
2. Si te pide habilitar la API, click en "Habilitar"
3. Espera a que se active (puede tardar unos minutos)

---

## 2. Configuración en Android

### Paso 2.1: Copiar google-services.json

1. Abre tu proyecto en VS Code o tu editor
2. Navega a la carpeta: `android/app/`
3. **Copia el archivo `google-services.json`** que descargaste en esta carpeta
4. La ruta final debe ser: `android/app/google-services.json`

---

### Paso 2.2: Configurar build.gradle (Nivel Proyecto)

Abre el archivo: `android/build.gradle.kts`

Agrega el plugin de Google Services:

```kotlin
plugins {
    id("com.android.application") version "8.1.0" apply false
    id("org.jetbrains.kotlin.android") version "1.9.0" apply false
    // ⬇️ AGREGAR ESTA LÍNEA
    id("com.google.gms.google-services") version "4.4.0" apply false
}
```

---

### Paso 2.3: Configurar build.gradle (Nivel App)

Abre el archivo: `android/app/build.gradle.kts`

**Al FINAL del archivo**, después de `dependencies { ... }`, agrega:

```kotlin
// ⬇️ AGREGAR AL FINAL DEL ARCHIVO
apply(plugin = "com.google.gms.google-services")
```

Dentro del bloque `dependencies`, agrega:

```kotlin
dependencies {
    implementation("androidx.core:core-ktx:1.12.0")
    // ... otras dependencias existentes ...
    
    // ⬇️ AGREGAR ESTAS LÍNEAS
    implementation(platform("com.google.firebase:firebase-bom:32.7.0"))
    implementation("com.google.firebase:firebase-messaging-ktx")
}
```

---

### Paso 2.4: Configurar AndroidManifest.xml

Abre el archivo: `android/app/src/main/AndroidManifest.xml`

Dentro del tag `<application>`, **ANTES del tag `<activity>`**, agrega:

```xml
<application
    android:label="oolale_mobile"
    android:name="${applicationName}"
    android:icon="@mipmap/ic_launcher">
    
    <!-- ⬇️ AGREGAR ESTAS LÍNEAS -->
    <service
        android:name="com.google.firebase.messaging.FirebaseMessagingService"
        android:exported="false">
        <intent-filter>
            <action android:name="com.google.firebase.MESSAGING_EVENT" />
        </intent-filter>
    </service>
    
    <meta-data
        android:name="com.google.firebase.messaging.default_notification_channel_id"
        android:value="high_importance_channel" />
    
    <!-- Actividad existente -->
    <activity
        android:name=".MainActivity"
        ...
```

---

## 3. Configuración en iOS (Opcional)

### Paso 3.1: Copiar GoogleService-Info.plist

1. Abre Xcode
2. Abre el proyecto: `ios/Runner.xcworkspace`
3. En el navegador de archivos (izquierda), click derecho en la carpeta `Runner`
4. Selecciona "Add Files to Runner..."
5. Selecciona el archivo `GoogleService-Info.plist` que descargaste
6. **Asegúrate de marcar**: "Copy items if needed"
7. Click en "Add"

---

### Paso 3.2: Habilitar Push Notifications

1. En Xcode, selecciona el proyecto `Runner` (arriba en el navegador)
2. Selecciona el target `Runner`
3. Ve a la pestaña "Signing & Capabilities"
4. Click en "+ Capability"
5. Busca y agrega "Push Notifications"
6. Click en "+ Capability" nuevamente
7. Busca y agrega "Background Modes"
8. Marca las opciones:
   - ✅ Remote notifications
   - ✅ Background fetch

---

## 4. Instalación de Dependencias

### Paso 4.1: Agregar Dependencias en pubspec.yaml

Abre el archivo: `pubspec.yaml`

En la sección `dependencies`, agrega:

```yaml
dependencies:
  flutter:
    sdk: flutter
  
  # ... otras dependencias existentes ...
  
  # ⬇️ AGREGAR ESTAS LÍNEAS
  firebase_core: ^2.24.2
  firebase_messaging: ^14.7.9
  flutter_local_notifications: ^16.3.0
```

---

### Paso 4.2: Instalar Dependencias

Abre la terminal en la carpeta del proyecto y ejecuta:

```bash
flutter pub get
```

---

### Paso 4.3: Limpiar y Reconstruir (Android)

```bash
cd android
./gradlew clean
cd ..
flutter clean
flutter pub get
```

---

## 5. Implementación del Código

### Paso 5.1: Inicializar Firebase en main.dart

Abre el archivo: `lib/main.dart`

**Al inicio del archivo**, agrega los imports:

```dart
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'services/notification_service.dart';
```

**Modifica la función `main()`**:

```dart
// Handler para notificaciones en background
@pragma('vm:entry-point')
Future<void> _firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  await Firebase.initializeApp();
  debugPrint('Handling background message: ${message.messageId}');
}

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  // ⬇️ AGREGAR ESTAS LÍNEAS
  await Firebase.initializeApp();
  FirebaseMessaging.onBackgroundMessage(_firebaseMessagingBackgroundHandler);
  await NotificationService.initialize();
  
  await Supabase.initialize(
    url: 'TU_SUPABASE_URL',
    anonKey: 'TU_SUPABASE_ANON_KEY',
  );

  runApp(const MyApp());
}
```

---

### Paso 5.2: Crear NotificationService

Ya existe el archivo `lib/services/notification_service.dart`, pero vamos a actualizarlo completamente.

**REEMPLAZA TODO EL CONTENIDO** del archivo con:

```dart
import 'package:flutter/material.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class NotificationService {
  static final FirebaseMessaging _firebaseMessaging = FirebaseMessaging.instance;
  static final FlutterLocalNotificationsPlugin _localNotifications = FlutterLocalNotificationsPlugin();
  static final _supabase = Supabase.instance.client;

  // Inicializar servicio de notificaciones
  static Future<void> initialize() async {
    // Solicitar permisos
    await _requestPermissions();
    
    // Configurar notificaciones locales
    await _setupLocalNotifications();
    
    // Obtener y guardar token FCM
    await _saveDeviceToken();
    
    // Configurar listeners
    _setupMessageHandlers();
  }

  // Solicitar permisos de notificaciones
  static Future<void> _requestPermissions() async {
    NotificationSettings settings = await _firebaseMessaging.requestPermission(
      alert: true,
      badge: true,
      sound: true,
      provisional: false,
    );

    debugPrint('Permisos de notificación: ${settings.authorizationStatus}');
  }

  // Configurar notificaciones locales
  static Future<void> _setupLocalNotifications() async {
    const AndroidInitializationSettings androidSettings = AndroidInitializationSettings('@mipmap/ic_launcher');
    
    const DarwinInitializationSettings iosSettings = DarwinInitializationSettings(
      requestAlertPermission: true,
      requestBadgePermission: true,
      requestSoundPermission: true,
    );

    const InitializationSettings settings = InitializationSettings(
      android: androidSettings,
      iOS: iosSettings,
    );

    await _localNotifications.initialize(
      settings,
      onDidReceiveNotificationResponse: _onNotificationTapped,
    );

    // Crear canal de notificaciones para Android
    const AndroidNotificationChannel channel = AndroidNotificationChannel(
      'high_importance_channel',
      'Notificaciones Importantes',
      description: 'Canal para notificaciones importantes de Óolale',
      importance: Importance.high,
    );

    await _localNotifications
        .resolvePlatformSpecificImplementation<AndroidFlutterLocalNotificationsPlugin>()
        ?.createNotificationChannel(channel);
  }

  // Guardar token del dispositivo en Supabase
  static Future<void> _saveDeviceToken() async {
    try {
      final token = await _firebaseMessaging.getToken();
      final userId = _supabase.auth.currentUser?.id;

      if (token != null && userId != null) {
        debugPrint('FCM Token: $token');
        
        // Guardar token en la tabla device_tokens
        await _supabase.from('device_tokens').upsert({
          'user_id': userId,
          'token': token,
          'platform': 'android', // o 'ios'
          'updated_at': DateTime.now().toIso8601String(),
        });
      }
    } catch (e) {
      debugPrint('Error guardando token: $e');
    }

    // Listener para cuando el token se actualice
    _firebaseMessaging.onTokenRefresh.listen((newToken) async {
      final userId = _supabase.auth.currentUser?.id;
      if (userId != null) {
        await _supabase.from('device_tokens').upsert({
          'user_id': userId,
          'token': newToken,
          'platform': 'android',
          'updated_at': DateTime.now().toIso8601String(),
        });
      }
    });
  }

  // Configurar handlers de mensajes
  static void _setupMessageHandlers() {
    // Cuando la app está en foreground
    FirebaseMessaging.onMessage.listen((RemoteMessage message) {
      debugPrint('Mensaje recibido en foreground: ${message.notification?.title}');
      _showLocalNotification(message);
    });

    // Cuando el usuario toca la notificación (app en background)
    FirebaseMessaging.onMessageOpenedApp.listen((RemoteMessage message) {
      debugPrint('Notificación tocada: ${message.data}');
      _handleNotificationTap(message.data);
    });

    // Verificar si la app se abrió desde una notificación
    _firebaseMessaging.getInitialMessage().then((RemoteMessage? message) {
      if (message != null) {
        debugPrint('App abierta desde notificación: ${message.data}');
        _handleNotificationTap(message.data);
      }
    });
  }

  // Mostrar notificación local
  static Future<void> _showLocalNotification(RemoteMessage message) async {
    RemoteNotification? notification = message.notification;
    AndroidNotification? android = message.notification?.android;

    if (notification != null) {
      await _localNotifications.show(
        notification.hashCode,
        notification.title,
        notification.body,
        const NotificationDetails(
          android: AndroidNotificationDetails(
            'high_importance_channel',
            'Notificaciones Importantes',
            channelDescription: 'Canal para notificaciones importantes de Óolale',
            importance: Importance.high,
            priority: Priority.high,
            icon: '@mipmap/ic_launcher',
          ),
          iOS: DarwinNotificationDetails(
            presentAlert: true,
            presentBadge: true,
            presentSound: true,
          ),
        ),
        payload: message.data.toString(),
      );
    }
  }

  // Manejar tap en notificación local
  static void _onNotificationTapped(NotificationResponse response) {
    debugPrint('Notificación local tocada: ${response.payload}');
    // Aquí puedes navegar a una pantalla específica
  }

  // Manejar tap en notificación (navegación)
  static void _handleNotificationTap(Map<String, dynamic> data) {
    final type = data['type'];
    
    switch (type) {
      case 'connection_request':
        // Navegar a solicitudes de conexión
        debugPrint('Navegar a solicitudes de conexión');
        break;
      case 'new_message':
        // Navegar a chat
        final userId = data['user_id'];
        debugPrint('Navegar a chat con usuario: $userId');
        break;
      case 'new_rating':
        // Navegar a calificaciones
        debugPrint('Navegar a calificaciones');
        break;
      default:
        debugPrint('Tipo de notificación desconocido: $type');
    }
  }

  // Obtener contador de notificaciones no leídas
  static Future<int> getUnreadCount() async {
    try {
      final userId = _supabase.auth.currentUser?.id;
      if (userId == null) return 0;

      final data = await _supabase
          .from('notifications')
          .select('id')
          .eq('user_id', userId)
          .eq('read', false);

      return data.length;
    } catch (e) {
      debugPrint('Error obteniendo contador: $e');
      return 0;
    }
  }

  // Marcar notificación como leída
  static Future<void> markAsRead(String notificationId) async {
    try {
      await _supabase
          .from('notifications')
          .update({'read': true, 'read_at': DateTime.now().toIso8601String()})
          .eq('id', notificationId);
    } catch (e) {
      debugPrint('Error marcando como leída: $e');
    }
  }

  // Marcar todas como leídas
  static Future<void> markAllAsRead() async {
    try {
      final userId = _supabase.auth.currentUser?.id;
      if (userId == null) return;

      await _supabase
          .from('notifications')
          .update({'read': true, 'read_at': DateTime.now().toIso8601String()})
          .eq('user_id', userId)
          .eq('read', false);
    } catch (e) {
      debugPrint('Error marcando todas como leídas: $e');
    }
  }
}
```

---

## 6. Crear Tablas en Supabase

### Paso 6.1: Tabla device_tokens

Ejecuta este SQL en Supabase SQL Editor:

```sql
-- Tabla para guardar tokens de dispositivos
CREATE TABLE IF NOT EXISTS device_tokens (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  user_id UUID REFERENCES auth.users(id) ON DELETE CASCADE,
  token TEXT NOT NULL,
  platform TEXT CHECK (platform IN ('android', 'ios', 'web')),
  created_at TIMESTAMP DEFAULT NOW(),
  updated_at TIMESTAMP DEFAULT NOW(),
  UNIQUE(user_id, token)
);

-- Índices
CREATE INDEX idx_device_tokens_user ON device_tokens(user_id);
CREATE INDEX idx_device_tokens_token ON device_tokens(token);

-- RLS Policies
ALTER TABLE device_tokens ENABLE ROW LEVEL SECURITY;

CREATE POLICY "Users can manage their own tokens"
  ON device_tokens
  FOR ALL
  TO authenticated
  USING (auth.uid() = user_id)
  WITH CHECK (auth.uid() = user_id);
```

---

### Paso 6.2: Tabla notifications

```sql
-- Tabla para guardar notificaciones
CREATE TABLE IF NOT EXISTS notifications (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  user_id UUID REFERENCES auth.users(id) ON DELETE CASCADE,
  type TEXT NOT NULL, -- 'connection_request', 'new_message', 'new_rating', etc.
  title TEXT NOT NULL,
  body TEXT NOT NULL,
  data JSONB, -- Datos adicionales
  read BOOLEAN DEFAULT FALSE,
  read_at TIMESTAMP,
  created_at TIMESTAMP DEFAULT NOW()
);

-- Índices
CREATE INDEX idx_notifications_user ON notifications(user_id);
CREATE INDEX idx_notifications_read ON notifications(read);
CREATE INDEX idx_notifications_created ON notifications(created_at DESC);

-- RLS Policies
ALTER TABLE notifications ENABLE ROW LEVEL SECURITY;

CREATE POLICY "Users can view their own notifications"
  ON notifications
  FOR SELECT
  TO authenticated
  USING (auth.uid() = user_id);

CREATE POLICY "Users can update their own notifications"
  ON notifications
  FOR UPDATE
  TO authenticated
  USING (auth.uid() = user_id)
  WITH CHECK (auth.uid() = user_id);
```

---

## 7. Pruebas

### Paso 7.1: Compilar y Ejecutar

```bash
flutter clean
flutter pub get
flutter run
```

---

### Paso 7.2: Verificar Token

Cuando la app se ejecute, busca en los logs:

```
FCM Token: ey...
```

Copia este token, lo necesitarás para enviar notificaciones de prueba.

---

### Paso 7.3: Enviar Notificación de Prueba desde Firebase Console

1. Ve a Firebase Console → **Cloud Messaging**
2. Click en "Enviar tu primer mensaje" o "Send your first message"
3. Completa:
   - **Título**: "Prueba de Notificación"
   - **Texto**: "Esta es una notificación de prueba"
4. Click en "Enviar mensaje de prueba"
5. Pega el **FCM Token** que copiaste
6. Click en "Probar" o "Test"

Deberías recibir la notificación en tu dispositivo.

---

## 8. Próximos Pasos

Una vez que las notificaciones funcionen:

1. ✅ Implementar pantalla de notificaciones en la app
2. ✅ Agregar badges con contador de no leídas
3. ✅ Crear triggers en Supabase para enviar notificaciones automáticas
4. ✅ Implementar navegación desde notificaciones

---

## 🐛 Solución de Problemas

### Error: "google-services.json not found"
- Verifica que el archivo esté en `android/app/google-services.json`
- Ejecuta `flutter clean` y vuelve a compilar

### Error: "FirebaseApp not initialized"
- Asegúrate de llamar `await Firebase.initializeApp()` en `main()`
- Verifica que los archivos de configuración estén correctamente colocados

### No recibo notificaciones
- Verifica que los permisos estén otorgados
- Revisa los logs para ver si hay errores
- Asegúrate de que el token se esté guardando correctamente

### Error de compilación en Android
- Ejecuta `cd android && ./gradlew clean`
- Verifica que las versiones de las dependencias sean compatibles

---

## 📝 Notas Importantes

- **Tokens FCM**: Se regeneran periódicamente, por eso guardamos el listener `onTokenRefresh`
- **Notificaciones en iOS**: Requieren certificados APNs configurados en Firebase
- **Producción**: Necesitarás configurar el certificado SHA-1 para Android
- **Background**: Las notificaciones en background se manejan automáticamente por Firebase

---

**¿Listo para continuar?** Una vez que hayas completado estos pasos, avísame y continuaremos con la implementación de la UI de notificaciones.
