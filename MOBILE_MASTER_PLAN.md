# 📱 PLAN MAESTRO V3.0: Óolale Mobile Experience

**📅 Fecha de Creación:** 19/01/2026  
**🔄 Última Actualización:** 19/01/2026 (21:40)  
**📌 Estado:** FASE 3 (DISCOVERY) SIGUIENTE PASO 🎯  

Este documento detalla exhaustivamente la hoja de ruta para el desarrollo, validación y despliegue de la aplicación móvil Óolale. Se utiliza para marcar el progreso y asegurar que ninguna funcionalidad crítica sea omitida.

---

## 🔐 FASE 1: ACCESO (✅ CÓDIGO LISTO)
- [x] **Login/Registro:** Implementado (Backend & Móvil).

## 👤 FASE 2: PERFIL (✅ CÓDIGO LISTO)
- [x] **Visualización:** Datos, Gear, Redes.
- [x] **Edición:** Pantallas listas.

## 🔍 FASE 3: DISCOVERY (⏳ PENDIENTE)
- [ ] **Búsqueda Avanzada:** Filtros por instrumento/género.
- [ ] **Mapa:** Geolocalización de músicos.

## 📅 FASE 4: EVENTOS (✅ UI LISTA)
- [x] **Listado:** Tarjetas visuales tipo Flyer.
- [x] **Creación:** Pantalla con Flyer Upload y Setlist Manager.
- [ ] **Backend:** Validar conexión final.

## 🛡️ FASE 5: SEGURIDAD (✅ CÓDIGO LISTO)
- [x] **Móvil:** Pantalla de Reporte (`CreateReportScreen`).
- [x] **Backend:** API `/report` y Tablas SQL definidas.
- [x] **Admin Web:** Centro de Moderación y Resolución de casos.

### 1.2 Registro (Sign Up)
- [ ] **Formulario Progresivo:** Pasos claros (Datos básicos -> Perfil Musical -> Foto).
- [ ] **Validaciones:** Email único, contraseña fuerte, edad mínima.
- [ ] **Términos y Condiciones:** Checkbox obligatorio con enlace a legal.

### 1.3 Onboarding (Primera vez)
- [ ] **Walkthrough:** 3 slides explicando la propuesta de valor (Conecta, Toca, Cobra).
- [ ] **Configuración Inicial:** Selección de intereses/géneros para personalizar el feed.
- [ ] **Permisos:** Solicitud explicada de Notificaciones, Ubicación y Cámara.

---

## 👤 FASE 2: IDENTIDAD Y PERFIL (MUSICIAN DNA)
**Objetivo:** Que el perfil sea la carta de presentación definitiva del músico.

### 2.1 Información Visual
- [ ] **Foto de Perfil:** Avatar circular de alta calidad.
- [ ] **Foto de Portada:** Banner personalizable.
- [ ] **Bio:** Texto corto de presentación.
- [ ] **(ID 3) Badges & Nivel:** Indicadores visuales (Verificado, Pro, Top Rated).

### 2.2 Portafolio Multimedia (ID 1)
- [ ] **Audio:** Embed de SoundCloud/Spotify o reproductor nativo de demos (MP3).
- [ ] **Video:** Embed de YouTube/Vimeo o clips cortos nativos.
- [ ] **Galería:** Grid de fotos de presentaciones pasadas.

### 2.3 Inventario y Habilidades
- [ ] **(ID 2) Gear List:** Lista de equipo propio (Amplificadores, PA, Instrumentos).
- [ ] **Instrumentos:** Lista con nivel de dominio (Principiante, Intermedio, Experto).
- [ ] **Géneros:** Tags interactivos.

### 2.4 Estado y Reputación
- [ ] **(ID 4) Open to Work:** Switch visible DE/PARA "Buscando Banda" o "Disponible hoy".
- [ ] **(ID 5) Referencias:** Sistema de reseñas escritas por otros usuarios.
- [ ] **Reputación:** Calificación 0-5 estrellas basada en eventos completados.

---

## 🔍 FASE 3: DISCOVERY Y NETWORKING
**Objetivo:** Encontrar al músico o evento perfecto en segundos.

### 3.1 Motor de Búsqueda 2.0
- [ ] **Búsqueda Global:** Barra única para Usuarios, Bandas y Eventos.
- [ ] **(ID 7) Filtros por Intención:** Jam, Audición, Reemplazo, Profesor.
- [ ] **(ID 10) Filtros Avanzados:** Género, Instrumento, Rango de Precio, Distancia.
- [ ] **(ID 8) Por Disponibilidad:** Filtrar quién está libre en fecha X.

### 3.2 Geolocalización (ID 6)
- [ ] **Mapa de Músicos:** Vista de mapa con pines de usuarios/eventos cercanos.
- [ ] **Radio de Búsqueda:** Selector "Buscar a 5km, 10km, 50km".

### 3.3 Gestión de Contactos
- [ ] **Sistema de Solicitud:** Botón "Conectar" (requiere aprobación) vs "Seguir" (unilateral).
- [ ] **(ID 9) Favoritos:** Guardar perfiles en listas personalizadas.
- [ ] **Bloqueos (User-side):** Evitar aparecer en búsquedas de usuarios específicos.

---

## 📅 FASE 4: GIGS, EVENTOS Y AGENDA
**Objetivo:** Gestión completa del ciclo de vida de un evento musical.

### 4.1 Creación de Eventos
- [ ] **Tipos:** Ensayo, Toquín, Audición, Jam Session.
- [ ] **Datos:** Fecha, Hora, Lugar (Google Maps), Cover/Precio.
- [ ] **(ID 13) Calls:** Convocatorias abiertas ("Se busca baterista para este evento").

### 4.2 Gestión del Evento
- [ ] **(ID 12) Setlist Manager:** Lista de canciones colaborativa para el evento.
- [ ] **(ID 11) QR Check-in:** Validación de asistencia mediante escaneo.
- [ ] **Rider Técnico:** PDF o lista de requerimientos técnicos adjunta.

### 4.3 Interacción
- [ ] **RSVP:** Asistiré, Tal vez, No asistiré.
- [ ] **Comentarios:** Muro de discusión del evento.
- [ ] **Compartir:** Generar imagen/link para redes sociales.

---

## 🛡️ FASE 5: SEGURIDAD Y MODERACIÓN (CRÍTICO)
**Objetivo:** Crear un entorno seguro y confiable.

- [ ] **Reportes:** Flujo completo para reportar usuarios/contenido (API conectada).
- [ ] **Bloqueos:** Funcionalidad para silenciar/bloquear usuarios molestos.
- [ ] **Centro de Ayuda:** Preguntas frecuentes (FAQ) y contacto con soporte.
- [ ] **Verificación de Identidad:** Proceso (opcional) de subir ID para obtener badge "Verificado".

---

## 💬 FASE 6: COMUNICACIÓN (CHAT)
**Objetivo:** Coordinación rápida sin salir de la app.

- [ ] **Lista de Conversaciones:** Ordenada por actividad reciente.
- [ ] **Chat 1a1:** Texto, Emojis, Ubicación, Fotos.
- [ ] **Chat Grupal:** Para bandas o eventos (creación automática al crear banda).
- [ ] **Indicadores:** "Escribiendo...", "Leído", "En línea".

---

## 💰 FASE 7: ECONOMÍA Y PAGOS (NUEVO)
**Objetivo:** Monetización para músicos y para la plataforma.

### 7.1 Billetera (Wallet)
- [ ] **Balance:** Ver saldo disponible / pendiente.
- [ ] **Historial:** Lista de transacciones (Ingresos/Egresos).
- [ ] **Métodos de Pago:** Integración (Stripe/PayPal) para agregar tarjetas.
- [ ] **Retiros:** Solicitar transferencia a cuenta bancaria.

### 7.2 Transacciones
- [ ] **(ID 6) Contratación Segura:** Pagar a una banda por un evento (Fondos en garantía/Escrow).
- [ ] **(ID 19) Tip Jar:** Enviar propinas directas a artistas.
- [ ] **Compra de Boletos:** Si el evento tiene cover, pagarlo in-app.
- [ ] **Marketplace (ID 5):** Compra/Venta de equipo usado.

### 7.3 Suscripciones (Monetización App)
- [ ] **Plan Free:** Funcionalidades básicas.
- [ ] **(ID 7) Plan PRO:** Visibilidad aumentada, estadísticas, sin fees en marketplace.
- [ ] **Gestión:** Ver estado de suscripción, renovación, cancelación.

---

## ⚙️ FASE 8: CONFIGURACIONES Y AJUSTES
**Objetivo:** Control total del usuario sobre su experiencia.

### 8.1 Cuenta
- [ ] **Editar Datos:** Email, Teléfono.
- [ ] **Cambiar Contraseña:** Flujo seguro.
- [ ] **Eliminar Cuenta:** Botón de "Danger Zone" (GDPR compliance).
- [ ] **Privacidad:** Modo "Fantasma" (ocultar perfil temporalmente).

### 8.2 Notificaciones (ID 18)
- [ ] **Granularidad:** Switches para Push, Email, SMS.
- [ ] **Categorías:** Mensajes, Nuevos Eventos, Marketing, Seguridad.

### 8.3 Apariencia e Idioma
- [ ] **Tema:** Claro / Oscuro / Sistema.
- [ ] **Idioma:** Español / Inglés.

---

## 🚀 ESTRATEGIA DE DESPLIEGUE

1.  **Alpha Testing:** Funcionalidad Auth + Perfil + Búsqueda Básica.
2.  **Beta Cerrada:** Agregar Eventos y Chat. Validar con grupo pequeño.
3.  **Beta Abierta:** Agregar Pagos y Moderación.
4.  **Lanzamiento V1.0:** Todas las features estables.

---
*Documento vivo. Se debe actualizar conforme se completen hitos.*
