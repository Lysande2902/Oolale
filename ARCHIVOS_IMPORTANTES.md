# 📂 Archivos Importantes - ÓOLALE Mobile

## 📱 Código de la Aplicación

### Configuración Principal
- `lib/main.dart` - Punto de entrada de la app
- `lib/config/constants.dart` - Constantes y configuración
- `lib/config/theme_colors.dart` - Sistema de colores adaptativo (light/dark)
- `pubspec.yaml` - Dependencias del proyecto

### Providers (Estado Global)
- `lib/providers/auth_provider.dart` - Autenticación
- `lib/providers/theme_provider.dart` - Tema light/dark

### Services (Servicios)
- `lib/services/api_service.dart` - Comunicación con backend
- `lib/services/storage_service.dart` - Almacenamiento local
- `lib/services/storage_service_auth.dart` - Almacenamiento seguro (auth)
- `lib/services/notification_service.dart` - Notificaciones
- `lib/services/payment_service.dart` - Pagos

### Models (Modelos de Datos)
- `lib/models/user.dart` - Usuario
- `lib/models/profile.dart` - Perfil de músico
- `lib/models/event.dart` - Eventos/Gigs
- `lib/models/message.dart` - Mensajes
- `lib/models/conversation.dart` - Conversaciones
- `lib/models/connection.dart` - Conexiones entre usuarios
- `lib/models/notification.dart` - Notificaciones
- `lib/models/post.dart` - Publicaciones
- `lib/models/portfolio_media.dart` - Media del portafolio

### Screens (Pantallas)

#### Autenticación
- `lib/screens/auth/login_screen.dart` - Login
- `lib/screens/auth/register_screen.dart` - Registro
- `lib/screens/auth/forgot_password_screen.dart` - Recuperar contraseña

#### Dashboard
- `lib/screens/dashboard/home_screen.dart` - Pantalla principal
- `lib/screens/dashboard/search_screen.dart` - Búsqueda

#### Perfil
- `lib/screens/profile/profile_screen.dart` - Perfil propio
- `lib/screens/profile/public_profile_screen.dart` - Perfil público
- `lib/screens/profile/edit_profile_screen.dart` - Editar perfil

#### Eventos
- `lib/screens/events/events_screen.dart` - Lista de eventos
- `lib/screens/events/create_event_screen.dart` - Crear evento
- `lib/screens/events/gig_detail_screen.dart` - Detalle de evento

#### Mensajes
- `lib/screens/messages/messages_screen.dart` - Lista de conversaciones
- `lib/screens/messages/chat_screen.dart` - Chat individual

#### Conexiones
- `lib/screens/connections/connections_screen.dart` - Conexiones

#### Portafolio
- `lib/screens/portfolio/portfolio_screen.dart` - Portafolio
- `lib/screens/portfolio/upload_media_screen.dart` - Subir media
- `lib/screens/portfolio/media_detail_screen.dart` - Detalle de media
- `lib/screens/portfolio/ratings_screen.dart` - Calificaciones
- `lib/screens/portfolio/leave_rating_screen.dart` - Dejar calificación

#### Otros
- `lib/screens/discovery/discovery_screen.dart` - Descubrir músicos
- `lib/screens/hiring/hire_musician_screen.dart` - Contratar músico
- `lib/screens/premium/subscription_screen.dart` - Suscripción premium
- `lib/screens/settings/settings_screen.dart` - Configuración
- `lib/screens/settings/wallet_screen.dart` - Billetera
- `lib/screens/notifications/notifications_screen.dart` - Notificaciones
- `lib/screens/reports/create_report_screen.dart` - Crear reporte

---

## 📄 Documentación

### Documentación Principal
- `README.md` - Información general del proyecto
- `README_SETUP.md` - Guía de instalación y configuración
- `RESUMEN_AUTENTICACION.md` - Sistema de autenticación

### Reportes y Estado
- `REPORTE_FINAL_100.md` - Reporte final del proyecto
- `ROADMAP.md` - Roadmap del proyecto
- `APP_REQUIREMENTS.md` - Requerimientos de la app

### Paleta de Colores
- `PALETA_COLORES_OFICIAL.md` - Paleta oficial de colores

---

## 🗄️ Base de Datos

### Scripts SQL Importantes
- `SEED_TEST_DATA_FIXED.sql` - Datos de prueba (USAR ESTE)
- `SEED_TEST_DATA_INSTRUCCIONES.md` - Instrucciones para crear usuarios
- `CREAR_USUARIOS_CON_PASSWORD.sql` - Script para crear usuarios con contraseña

---

## ⚙️ Configuración

### Android
- `android/app/build.gradle.kts` - Configuración de build
- `android/app/src/main/AndroidManifest.xml` - Manifest de Android

### iOS
- `ios/Runner/Info.plist` - Configuración de iOS

---

## 🧪 Testing
- `test/widget_test.dart` - Tests de widgets

---

## 📦 Archivos de Configuración
- `.gitignore` - Archivos ignorados por Git
- `analysis_options.yaml` - Opciones de análisis de código
- `pubspec.lock` - Versiones bloqueadas de dependencias

---

## ⚠️ Archivos que NO debes modificar
- `.dart_tool/` - Herramientas de Dart (generado)
- `.git/` - Repositorio Git
- `.idea/` - Configuración de IDE
- `build/` - Archivos compilados (generado)
- `.flutter-plugins-dependencies` - Dependencias de plugins (generado)
- `.metadata` - Metadata de Flutter (generado)
- `oolale_mobile.iml` - Configuración de IntelliJ (generado)

---

## 🎯 Archivos Clave para Desarrollo

Si vas a trabajar en:

### Autenticación
- `lib/providers/auth_provider.dart`
- `lib/screens/auth/login_screen.dart`
- `lib/screens/auth/register_screen.dart`

### Diseño/UI
- `lib/config/theme_colors.dart`
- `lib/config/constants.dart`

### Backend/API
- `lib/services/api_service.dart`
- `lib/models/` (todos los modelos)

### Nuevas Pantallas
- Crea en `lib/screens/[categoria]/`
- Sigue el patrón de las pantallas existentes

---

## 📝 Notas

- Todos los archivos de análisis antiguos fueron eliminados
- Todos los archivos SQL duplicados fueron eliminados
- Todos los archivos de documentación desactualizados fueron eliminados
- Solo quedan los archivos esenciales y actualizados

---

¿Necesitas ayuda con algún archivo específico?
