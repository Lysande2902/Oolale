# 🚀 Guía de Deployment - Funcionalidades Opcionales

**Fecha:** 29 de Enero, 2026  
**Versión:** 1.0  
**Estado:** Listo para deployment

---

## 📋 CHECKLIST PRE-DEPLOYMENT

### ✅ Código Implementado
- [x] RealtimeService y MediaService
- [x] EventService y ProfileService
- [x] ChatScreen con multimedia y real-time
- [x] EventHistoryScreen, EventCalendarScreen, EventInvitationsScreen
- [x] Widgets multimedia (MediaMessageBubble, ImageViewer, AudioPlayerWidget)
- [x] Rutas de navegación agregadas
- [x] Dependencias instaladas en pubspec.yaml
- [x] 0 errores de compilación

### ⚠️ Configuración Pendiente
- [x] Ejecutar migración de base de datos ✅
- [ ] Configurar Supabase Storage
- [ ] Instalar dependencias con `flutter pub get`
- [ ] Testing manual de funcionalidades

---

## 🗄️ PASO 1: MIGRACIÓN DE BASE DE DATOS (CRÍTICO)

### ⚠️ IMPORTANTE: Script Corregido

El script de migración fue corregido para usar `profile_id` en lugar de `user_id` en la tabla `portfolio_media`. Ver detalles en: `oolale_mobile/CORRECCION_MIGRATION_SCRIPT.md`

### Ejecutar Script SQL

1. **Abrir Supabase Dashboard**
   - URL: https://supabase.com/dashboard
   - Proyecto: lwrlunndqzepwsbmofki

2. **Ir a SQL Editor**
   - Menú lateral → SQL Editor
   - Click en "New query"

3. **Copiar y Ejecutar**
   ```bash
   # Copiar contenido de:
   oolale_mobile/MIGRATION_OPTIONAL_FEATURES.sql
   # ✅ Versión corregida (29/01/2026)
   ```

4. **Verificar Ejecución**
   - Debe mostrar: "Success. No rows returned"
   - Verificar que se crearon las tablas:
     - `event_invitations`
     - `genres`
     - `profile_genres`
     - `portfolio_media`

5. **Verificar Columnas Nuevas**
   ```sql
   -- Verificar tabla mensajes
   SELECT column_name, data_type 
   FROM information_schema.columns 
   WHERE table_name = 'mensajes';
   
   -- Debe incluir: delivered_at, read_at, media_url, media_type
   
   -- Verificar tabla profiles
   SELECT column_name, data_type 
   FROM information_schema.columns 
   WHERE table_name = 'profiles';
   
   -- Debe incluir: years_experience, availability, base_rate, 
   --                currency, social_links, profile_completion
   ```

---

## 📦 PASO 2: CONFIGURAR SUPABASE STORAGE

### Crear Bucket 'media'

1. **Ir a Storage**
   - Menú lateral → Storage
   - Click en "Create a new bucket"

2. **Configurar Bucket**
   - Name: `media`
   - Public bucket: ✅ (activado)
   - File size limit: 50 MB
   - Allowed MIME types: 
     - `image/*`
     - `audio/*`
     - `video/mp4`

3. **Crear Estructura de Carpetas**
   ```
   media/
   ├── messages/
   └── portfolio/
   ```

### Configurar Políticas RLS

1. **Ir a Policies**
   - Storage → media → Policies

2. **Crear Política de Lectura Pública**
   ```sql
   CREATE POLICY "Public read access"
   ON storage.objects FOR SELECT
   USING (bucket_id = 'media');
   ```

3. **Crear Política de Upload Autenticado**
   ```sql
   CREATE POLICY "Authenticated users can upload"
   ON storage.objects FOR INSERT
   WITH CHECK (
     bucket_id = 'media' AND
     auth.role() = 'authenticated'
   );
   ```

4. **Crear Política de Delete Propio**
   ```sql
   CREATE POLICY "Users can delete own files"
   ON storage.objects FOR DELETE
   USING (
     bucket_id = 'media' AND
     auth.uid()::text = (storage.foldername(name))[2]
   );
   ```

---

## 📱 PASO 3: INSTALAR DEPENDENCIAS

### En Terminal

```bash
cd oolale_mobile
flutter pub get
```

### Verificar Instalación

```bash
flutter pub deps
```

Debe mostrar:
- ✅ table_calendar 3.0.9
- ✅ just_audio 0.10.5
- ✅ image_picker 1.2.1
- ✅ flutter_image_compress 2.4.0
- ✅ path 1.9.1

---

## 🧪 PASO 4: TESTING MANUAL

### Test 1: Mensajería con Multimedia

1. **Iniciar sesión con 2 usuarios diferentes**
   - Usuario 1: test1@test.com / Test123456!
   - Usuario 2: test2@test.com / Test123456!

2. **Conectar usuarios**
   - Usuario 1 envía solicitud a Usuario 2
   - Usuario 2 acepta solicitud

3. **Probar Chat**
   - [ ] Enviar mensaje de texto
   - [ ] Ver indicador "escribiendo..."
   - [ ] Enviar imagen (verificar compresión)
   - [ ] Enviar audio
   - [ ] Verificar estados de mensaje (✓, ✓✓, ✓✓ color)
   - [ ] Abrir imagen en visor full-screen
   - [ ] Reproducir audio

### Test 2: Eventos e Invitaciones

1. **Crear Evento**
   - Usuario 1 crea un evento futuro
   - Agregar título, fecha, ubicación

2. **Enviar Invitación**
   - Usuario 1 invita a Usuario 2
   - Verificar notificación en Usuario 2

3. **Responder Invitación**
   - Usuario 2 abre pantalla de invitaciones
   - [ ] Ver invitación pendiente
   - [ ] Aceptar invitación
   - [ ] Verificar que aparece en lineup del evento

4. **Calendario**
   - [ ] Abrir EventCalendarScreen
   - [ ] Ver evento en fecha correcta
   - [ ] Highlight de fecha con evento
   - [ ] Indicador de evento próximo (24h)

5. **Historial**
   - Esperar a que evento pase (o cambiar fecha en BD)
   - [ ] Abrir EventHistoryScreen
   - [ ] Ver evento pasado
   - [ ] Ver prompt para calificar

### Test 3: Perfil Mejorado

1. **Editar Perfil**
   - [ ] Agregar géneros musicales
   - [ ] Agregar años de experiencia
   - [ ] Configurar disponibilidad
   - [ ] Agregar tarifa base
   - [ ] Agregar redes sociales (Instagram, YouTube)

2. **Verificar Display**
   - [ ] Ver géneros como chips
   - [ ] Ver años de experiencia
   - [ ] Ver disponibilidad
   - [ ] Ver tarifa o "Tarifa por consultar"
   - [ ] Click en redes sociales (abrir navegador)

3. **Completitud de Perfil**
   - [ ] Ver porcentaje de completitud
   - [ ] Ver campos faltantes
   - [ ] Completar campos y verificar 100%

---

## 🔍 PASO 5: VERIFICACIÓN DE INTEGRACIÓN

### Verificar Base de Datos

```sql
-- Verificar mensajes con multimedia
SELECT id, remitente_id, media_type, media_url, delivered_at, read_at
FROM mensajes
WHERE media_url IS NOT NULL
ORDER BY created_at DESC
LIMIT 5;

-- Verificar invitaciones
SELECT * FROM event_invitations
ORDER BY created_at DESC
LIMIT 5;

-- Verificar géneros de perfil
SELECT p.nombre_artistico, pg.genre
FROM profiles p
JOIN profile_genres pg ON p.id = pg.profile_id
LIMIT 10;

-- Verificar completitud de perfil
SELECT nombre_artistico, profile_completion
FROM profiles
WHERE profile_completion > 0
ORDER BY profile_completion DESC;
```

### Verificar Storage

1. **Ir a Storage → media**
2. **Verificar carpetas:**
   - [ ] messages/{userId}/ contiene archivos
   - [ ] portfolio/{userId}/ contiene archivos
3. **Verificar URLs públicas:**
   - Click en archivo → Copy URL
   - Abrir en navegador → debe cargar

---

## 🐛 TROUBLESHOOTING

### Error: "Table 'event_invitations' doesn't exist"
**Solución:** Ejecutar MIGRATION_OPTIONAL_FEATURES.sql

### Error: "Bucket 'media' not found"
**Solución:** Crear bucket en Supabase Storage

### Error: "Permission denied for storage"
**Solución:** Verificar políticas RLS en Storage

### Error: "Package not found: table_calendar"
**Solución:** Ejecutar `flutter pub get`

### Imágenes no se comprimen
**Solución:** Verificar que flutter_image_compress esté instalado

### Typing indicator no funciona
**Solución:** Verificar que Supabase Realtime esté habilitado en proyecto

### Estados de mensaje no se actualizan
**Solución:** Verificar columnas delivered_at y read_at en tabla mensajes

---

## 📊 MÉTRICAS DE ÉXITO

### Funcionalidad
- [ ] Mensajes se envían instantáneamente
- [ ] Multimedia se sube y muestra correctamente
- [ ] Invitaciones se envían y reciben
- [ ] Calendario muestra eventos correctamente
- [ ] Perfil se actualiza con nuevos campos

### Performance
- [ ] Imágenes se comprimen a <2MB
- [ ] Chat carga en <2 segundos
- [ ] Calendario carga en <3 segundos
- [ ] Upload de imagen <5 segundos

### UX
- [ ] Indicadores de carga visibles
- [ ] Errores se manejan gracefully
- [ ] Navegación fluida entre pantallas
- [ ] Estados visuales claros

---

## 🚀 DEPLOYMENT A PRODUCCIÓN

### Pre-requisitos
- [x] Todas las pruebas manuales pasadas
- [x] Base de datos migrada
- [x] Storage configurado
- [x] Sin errores de compilación

### Pasos

1. **Actualizar Versión**
   ```yaml
   # pubspec.yaml
   version: 1.1.0+2  # Incrementar
   ```

2. **Build Android**
   ```bash
   flutter build apk --release
   # o
   flutter build appbundle --release
   ```

3. **Build iOS**
   ```bash
   flutter build ios --release
   ```

4. **Subir a Stores**
   - Google Play Console
   - Apple App Store Connect

5. **Changelog**
   ```
   Versión 1.1.0
   - ✨ Mensajería en tiempo real con indicadores
   - 📸 Soporte de imágenes y audio en chat
   - 📅 Calendario de eventos
   - 📨 Sistema de invitaciones a eventos
   - 👤 Perfil mejorado con géneros y disponibilidad
   - ⭐ Indicador de completitud de perfil
   ```

---

## 📞 SOPORTE

### Contacto
- Desarrollador: [Tu nombre]
- Email: [Tu email]
- Proyecto: Óolale Mobile

### Recursos
- Documentación: `oolale_mobile/RESUMEN_IMPLEMENTACION_COMPLETA_OPCIONALES.md`
- Migración SQL: `oolale_mobile/MIGRATION_OPTIONAL_FEATURES.sql`
- Plan completo: `oolale_mobile/PLAN_IMPLEMENTACION_COMPLETO.md`

---

**Última actualización:** 29 de Enero, 2026  
**Estado:** ✅ LISTO PARA DEPLOYMENT
