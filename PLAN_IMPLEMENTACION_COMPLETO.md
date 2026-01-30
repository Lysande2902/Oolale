# 📋 Plan de Implementación Completo - Funcionalidades Opcionales

**Fecha:** 29 de Enero, 2026  
**Spec:** complete-optional-features  
**Estado:** 📝 PLANIFICADO

---

## 🎯 OBJETIVO

Completar las funcionalidades opcionales de Óolale Mobile para alcanzar el 100% de completitud. El proyecto actualmente está al 91% y estas funcionalidades lo llevarán al 100%.

---

## 📊 RESUMEN DE TAREAS

**Total de Tareas:** 23  
**Completadas:** 1 (4%)  
**Pendientes:** 22 (96%)

**Estimación de Tiempo:** 5-7 días de desarrollo full-time

---

## ✅ FASE 1: MENSAJERÍA EN TIEMPO REAL (9 tareas)

### Estado Actual:
- ✅ RealtimeService y MediaService implementados
- ⚠️ ChatScreen tiene implementación básica de Realtime
- ❌ Faltan: typing indicators, estados de mensaje, multimedia

### Tareas Pendientes:

#### 1.1-1.2: Property Tests (OPCIONAL)
**Prioridad:** Baja  
**Tiempo:** 2-3 horas  
**Descripción:** Tests de propiedades para RealtimeService y MediaService

#### 2: Mejorar ChatScreen con Real-time
**Prioridad:** Alta  
**Tiempo:** 4-6 horas  
**Cambios Necesarios:**
- Integrar RealtimeService en lugar de stream directo
- Agregar indicador de "escribiendo..." (UI + lógica)
- Implementar timeout de 3 segundos para typing
- Agregar timestamps de delivered_at y read_at
- Marcar mensajes como leídos al abrir conversación

**Archivos a Modificar:**
- `lib/screens/messages/chat_screen.dart` (400+ líneas)
- `lib/models/message.dart` (agregar campos)

#### 3: Soporte Multimedia en Chat
**Prioridad:** Alta  
**Tiempo:** 6-8 horas  
**Funcionalidades:**
- Botón de imagen en input
- Botón de audio en input
- Integrar MediaService para uploads
- Progress indicator durante upload
- Thumbnails para imágenes
- Controles de reproducción para audio
- Visor de imagen full-screen
- Manejo de errores y retry

**Archivos a Modificar:**
- `lib/screens/messages/chat_screen.dart` (agregar 200+ líneas)
- Crear `lib/widgets/media_message_bubble.dart`
- Crear `lib/widgets/image_viewer.dart`
- Crear `lib/widgets/audio_player_widget.dart`

#### 4: Indicadores de Estado de Mensaje
**Prioridad:** Media  
**Tiempo:** 2-3 horas  
**Funcionalidades:**
- Icono de "enviado" (✓)
- Icono de "entregado" (✓✓)
- Icono de "leído" (✓✓ en color)
- Actualización automática de estados

**Archivos a Modificar:**
- `lib/screens/messages/chat_screen.dart` (_MessageBubble)

#### 5: Checkpoint - Testing
**Prioridad:** Alta  
**Tiempo:** 2-3 horas  
**Actividades:**
- Testing manual de mensajería
- Verificar typing indicators
- Verificar estados de mensaje
- Verificar upload de multimedia

---

## 🎤 FASE 2: GESTIÓN COMPLETA DE EVENTOS (7 tareas)

### Estado Actual:
- ⚠️ Existe EventsScreen básico
- ⚠️ Existe GigDetailScreen básico
- ❌ Faltan: historial, calendario, invitaciones, RSVP

### Tareas Pendientes:

#### 6: EventService Mejorado
**Prioridad:** Alta  
**Tiempo:** 4-5 horas  
**Funcionalidades:**
- getEventHistory(userId)
- getUpcomingEvents(userId)
- getEventsForDate(date)
- sendInvitations(eventId, musicianIds)
- respondToInvitation(invitationId, status)
- canRateEvent(eventId, userId)
- getParticipantsToRate(eventId, userId)

**Archivos a Crear:**
- `lib/services/event_service.dart` (300+ líneas)

#### 7: EventHistoryScreen
**Prioridad:** Media  
**Tiempo:** 3-4 horas  
**Funcionalidades:**
- Lista de eventos pasados
- Ordenados por fecha (más reciente primero)
- Indicador de rating status
- Navegación a detalle
- Prompt para calificar
- Empty state

**Archivos a Crear:**
- `lib/screens/events/event_history_screen.dart` (250+ líneas)

#### 8: EventCalendarScreen
**Prioridad:** Media  
**Tiempo:** 4-5 horas  
**Funcionalidades:**
- Vista de calendario mensual
- Highlight de fechas con eventos
- Lista de eventos al seleccionar fecha
- Estado de confirmación
- Indicador de eventos en 24h

**Archivos a Crear:**
- `lib/screens/events/event_calendar_screen.dart` (300+ líneas)

**Dependencias:**
- Agregar `table_calendar: ^3.0.9` a pubspec.yaml

#### 9: EventInvitationsScreen + Mejorar GigDetailScreen
**Prioridad:** Alta  
**Tiempo:** 5-6 horas  
**Funcionalidades:**
- Pantalla de invitaciones pendientes
- Botones Accept/Decline
- Integración con EventService
- Selector de músicos en GigDetailScreen
- Envío de invitaciones

**Archivos a Crear:**
- `lib/screens/events/event_invitations_screen.dart` (250+ líneas)

**Archivos a Modificar:**
- `lib/screens/events/gig_detail_screen.dart` (agregar 100+ líneas)

#### 10: Notificaciones de Eventos
**Prioridad:** Media  
**Tiempo:** 3-4 horas  
**Funcionalidades:**
- Notificación de invitación
- Notificación de recordatorio 24h
- Notificación de actualización
- Notificación de cancelación

**Archivos a Modificar:**
- `lib/services/notification_service.dart` (agregar métodos)

#### 11: Sistema de Calificaciones Post-Evento
**Prioridad:** Media  
**Tiempo:** 3-4 horas  
**Funcionalidades:**
- Prompt después de evento
- Verificación de participación
- Rating obligatorio (1-5)
- Comentario opcional
- Actualización de promedio
- Prevención de duplicados

**Archivos a Modificar:**
- `lib/screens/ratings/leave_rating_screen.dart` (modificar lógica)

#### 12: Checkpoint - Testing
**Prioridad:** Alta  
**Tiempo:** 2-3 horas

---

## 👤 FASE 3: PERFIL DE MÚSICO COMPLETO (7 tareas)

### Estado Actual:
- ⚠️ Existe EditProfileScreen básico
- ⚠️ Existe UnifiedProfileScreen
- ❌ Faltan: géneros, experiencia, disponibilidad, tarifa, redes sociales, portafolio mejorado

### Tareas Pendientes:

#### 13: ProfileService Mejorado
**Prioridad:** Alta  
**Tiempo:** 4-5 horas  
**Funcionalidades:**
- saveGenres(userId, genres)
- getAvailableGenres()
- saveExperienceAndAvailability(userId, years, availability)
- saveBaseRate(userId, amount, currency)
- saveSocialLinks(userId, links)
- calculateProfileCompletion(profile)
- getMissingFields(profile)

**Archivos a Crear:**
- `lib/services/profile_service.dart` (250+ líneas)

#### 14: Mejorar EditProfileScreen
**Prioridad:** Alta  
**Tiempo:** 6-8 horas  
**Funcionalidades:**
- Multi-select de géneros musicales
- Input de años de experiencia
- Selector de disponibilidad (días + horarios)
- Input de tarifa base + selector de moneda
- Inputs de redes sociales (Instagram, YouTube, Spotify, SoundCloud)
- Validación de URLs
- Indicador de progreso de perfil

**Archivos a Modificar:**
- `lib/screens/profile/edit_profile_screen.dart` (agregar 300+ líneas)

**Widgets a Crear:**
- `lib/widgets/genre_selector.dart`
- `lib/widgets/availability_selector.dart`
- `lib/widgets/social_links_input.dart`

#### 15: Indicador de Perfil Completo
**Prioridad:** Media  
**Tiempo:** 2-3 horas  
**Funcionalidades:**
- Cálculo de porcentaje de completitud
- Progress bar para perfiles incompletos
- Badge "Perfil Completo" para 100%
- Sugerencias de campos faltantes

**Archivos a Modificar:**
- `lib/screens/profile/unified_profile_screen.dart` (agregar 100+ líneas)

#### 16: Portafolio Multimedia Mejorado
**Prioridad:** Media  
**Tiempo:** 5-6 horas  
**Funcionalidades:**
- Upload múltiple de media
- Soporte para imágenes, videos (mp4), audio (mp3, wav)
- Validación de tipo y tamaño
- Grid layout
- Media viewer (full screen para imágenes, player para audio/video)
- Funcionalidad de eliminar
- Eliminación de Supabase Storage

**Archivos a Crear/Modificar:**
- `lib/screens/portfolio/portfolio_screen.dart` (reescribir, 400+ líneas)
- `lib/widgets/media_grid.dart`
- `lib/widgets/media_viewer.dart`

#### 17: Actualizar Búsqueda
**Prioridad:** Baja  
**Tiempo:** 2-3 horas  
**Funcionalidades:**
- Filtro por género musical
- Filtro por disponibilidad

**Archivos a Modificar:**
- `lib/screens/dashboard/search_screen.dart` (agregar filtros)

#### 18: Actualizar Display de Perfil
**Prioridad:** Media  
**Tiempo:** 3-4 horas  
**Funcionalidades:**
- Mostrar géneros como chips
- Mostrar años de experiencia
- Mostrar disponibilidad
- Mostrar tarifa o "Tarifa por consultar"
- Mostrar iconos de redes sociales
- Abrir links en navegador externo

**Archivos a Modificar:**
- `lib/screens/profile/unified_profile_screen.dart` (agregar 150+ líneas)

#### 19: Checkpoint - Testing
**Prioridad:** Alta  
**Tiempo:** 2-3 horas

---

## 🔧 FASE 4: INTEGRACIÓN Y TESTING FINAL (4 tareas)

### Tareas Pendientes:

#### 20: Actualizar Schema de Base de Datos
**Prioridad:** CRÍTICA  
**Tiempo:** 2-3 horas  
**Cambios Necesarios:**

**Tabla `mensajes` (messages):**
```sql
ALTER TABLE mensajes ADD COLUMN delivered_at TIMESTAMPTZ;
ALTER TABLE mensajes ADD COLUMN read_at TIMESTAMPTZ;
ALTER TABLE mensajes ADD COLUMN media_url TEXT;
ALTER TABLE mensajes ADD COLUMN media_type TEXT; -- 'image', 'audio', null
```

**Tabla `event_invitations` (nueva):**
```sql
CREATE TABLE event_invitations (
  id SERIAL PRIMARY KEY,
  event_id INTEGER REFERENCES gigs(id) ON DELETE CASCADE,
  musician_id UUID REFERENCES profiles(id) ON DELETE CASCADE,
  organizer_id UUID REFERENCES profiles(id) ON DELETE CASCADE,
  status TEXT DEFAULT 'pending', -- 'pending', 'accepted', 'declined'
  created_at TIMESTAMPTZ DEFAULT NOW(),
  updated_at TIMESTAMPTZ DEFAULT NOW()
);
```

**Tabla `profile_genres` (nueva, many-to-many):**
```sql
CREATE TABLE profile_genres (
  id SERIAL PRIMARY KEY,
  profile_id UUID REFERENCES profiles(id) ON DELETE CASCADE,
  genre TEXT NOT NULL,
  created_at TIMESTAMPTZ DEFAULT NOW()
);

CREATE TABLE genres (
  id SERIAL PRIMARY KEY,
  name TEXT UNIQUE NOT NULL,
  created_at TIMESTAMPTZ DEFAULT NOW()
);
```

**Tabla `profiles` (agregar columnas):**
```sql
ALTER TABLE profiles ADD COLUMN years_experience INTEGER;
ALTER TABLE profiles ADD COLUMN availability JSONB; -- {days: [], time_ranges: []}
ALTER TABLE profiles ADD COLUMN base_rate DECIMAL(10,2);
ALTER TABLE profiles ADD COLUMN currency TEXT DEFAULT 'MXN';
ALTER TABLE profiles ADD COLUMN social_links JSONB; -- {instagram: '', youtube: '', etc}
ALTER TABLE profiles ADD COLUMN profile_completion INTEGER DEFAULT 0;
```

**Tabla `portfolio_media` (nueva):**
```sql
CREATE TABLE portfolio_media (
  id SERIAL PRIMARY KEY,
  user_id UUID REFERENCES profiles(id) ON DELETE CASCADE,
  url TEXT NOT NULL,
  type TEXT NOT NULL, -- 'image', 'video', 'audio'
  thumbnail TEXT,
  duration INTEGER, -- for audio/video in seconds
  uploaded_at TIMESTAMPTZ DEFAULT NOW()
);
```

**Archivo a Crear:**
- `oolale_mobile/MIGRATION_OPTIONAL_FEATURES.sql`

#### 21: Actualizar Rutas de Navegación
**Prioridad:** Alta  
**Tiempo:** 1-2 horas  
**Rutas a Agregar:**
- `/event-history` → EventHistoryScreen
- `/event-calendar` → EventCalendarScreen
- `/event-invitations` → EventInvitationsScreen
- `/portfolio/:userId` → PortfolioScreen (mejorado)

**Archivos a Modificar:**
- `lib/main.dart` (agregar rutas en GoRouter)

#### 22: Testing de Integración
**Prioridad:** Alta  
**Tiempo:** 4-5 horas  
**Tests a Realizar:**
- Flujo completo de mensajería con real-time
- Flujo de invitación y RSVP a eventos
- Actualización de perfil con todos los campos
- Upload y display de multimedia
- Notificaciones de eventos
- Calendario de eventos
- Cálculo de perfil completo

#### 23: Checkpoint Final
**Prioridad:** CRÍTICA  
**Tiempo:** 2-3 horas  
**Actividades:**
- Revisión completa de funcionalidades
- Testing en dispositivos reales
- Verificación de performance
- Documentación final

---

## 📦 DEPENDENCIAS ADICIONALES REQUERIDAS

```yaml
dependencies:
  table_calendar: ^3.0.9  # Para EventCalendarScreen
  video_player: ^2.10.1   # Ya existe
  chewie: ^1.13.0         # Ya existe
  just_audio: ^0.10.5     # Ya existe
  image_picker: ^1.2.1    # Ya existe
  file_picker: ^10.3.8    # Ya existe
```

---

## 🗄️ CONFIGURACIÓN DE SUPABASE REQUERIDA

### Storage Buckets:
```
media/
├── messages/{userId}/
│   ├── image_*.jpg
│   └── audio_*.mp3
└── portfolio/{userId}/
    ├── image_*.jpg
    ├── video_*.mp4
    └── audio_*.mp3
```

### Políticas de Storage:
Ver `IMPLEMENTACION_FUNCIONALIDADES_OPCIONALES.md` para scripts SQL completos.

---

## 📊 ESTIMACIÓN DE ESFUERZO

| Fase | Tareas | Tiempo Estimado | Prioridad |
|------|--------|-----------------|-----------|
| Fase 1: Mensajería | 9 | 20-25 horas | Alta |
| Fase 2: Eventos | 7 | 24-30 horas | Media |
| Fase 3: Perfil | 7 | 24-30 horas | Media |
| Fase 4: Integración | 4 | 9-13 horas | Crítica |
| **TOTAL** | **27** | **77-98 horas** | - |

**Tiempo Real:** 5-7 días de desarrollo full-time (considerando testing y debugging)

---

## 🎯 ESTRATEGIA DE IMPLEMENTACIÓN RECOMENDADA

### Opción A: Implementación Completa (Recomendada)
1. Completar Fase 4 (Tarea 20) primero - Actualizar schema de BD
2. Implementar Fase 1 completa - Mensajería
3. Implementar Fase 3 completa - Perfil
4. Implementar Fase 2 completa - Eventos
5. Testing final y ajustes

**Ventajas:** Funcionalidades completas y pulidas  
**Tiempo:** 5-7 días

### Opción B: MVP de Funcionalidades Opcionales
1. Actualizar schema de BD (Tarea 20)
2. Solo tareas de prioridad Alta:
   - Tarea 2: ChatScreen mejorado
   - Tarea 3: Multimedia en chat
   - Tarea 6: EventService
   - Tarea 9: Invitaciones
   - Tarea 13: ProfileService
   - Tarea 14: EditProfileScreen mejorado
3. Testing básico

**Ventajas:** Funcionalidades core rápidamente  
**Tiempo:** 2-3 días

### Opción C: Implementación Incremental
1. Actualizar schema de BD
2. Implementar una fase completa por semana
3. Testing continuo
4. Deploy incremental

**Ventajas:** Menor riesgo, feedback continuo  
**Tiempo:** 3-4 semanas

---

## 📝 NOTAS IMPORTANTES

### Consideraciones Técnicas:
- **Realtime:** Supabase Realtime tiene límites de conexiones concurrentes
- **Storage:** Considerar límites de almacenamiento y costos
- **Performance:** Compresión de imágenes es crítica para UX
- **Testing:** Property-based tests son opcionales pero recomendados

### Riesgos Identificados:
1. **Complejidad de Realtime:** Manejo de reconexiones y estados
2. **Upload de Multimedia:** Manejo de archivos grandes y timeouts
3. **Schema Changes:** Requiere migración cuidadosa de datos existentes
4. **Testing:** Funcionalidades de tiempo real son difíciles de testear

### Mitigaciones:
1. Implementar retry logic y manejo de errores robusto
2. Validación de archivos antes de upload, progress indicators
3. Crear scripts de migración con rollback
4. Testing manual exhaustivo, considerar E2E tests

---

## ✅ CRITERIOS DE ACEPTACIÓN

### Mensajería:
- [ ] Mensajes aparecen instantáneamente sin refresh
- [ ] Indicador "escribiendo..." funciona correctamente
- [ ] Estados de mensaje (enviado/entregado/leído) se actualizan
- [ ] Imágenes se comprimen y suben correctamente
- [ ] Audio se reproduce correctamente
- [ ] Errores se manejan gracefully

### Eventos:
- [ ] Historial muestra todos los eventos pasados
- [ ] Calendario muestra eventos correctamente
- [ ] Invitaciones se envían y reciben
- [ ] RSVP actualiza lineup correctamente
- [ ] Notificaciones de eventos funcionan
- [ ] Calificaciones post-evento funcionan

### Perfil:
- [ ] Todos los campos nuevos se guardan correctamente
- [ ] Géneros se muestran como chips
- [ ] Disponibilidad se muestra claramente
- [ ] Tarifa se muestra o "Tarifa por consultar"
- [ ] Redes sociales abren en navegador
- [ ] Portafolio muestra multimedia correctamente
- [ ] Porcentaje de completitud es preciso

---

## 📚 DOCUMENTACIÓN A CREAR

- [ ] Guía de usuario para nuevas funcionalidades
- [ ] Documentación técnica de servicios
- [ ] Scripts de migración de BD
- [ ] Guía de testing
- [ ] Changelog detallado

---

**Última actualización:** 29 de Enero, 2026
