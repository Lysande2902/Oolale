# ✅ CHECKLIST DE TESTING COMPLETO - Óolale Mobile

**Fecha:** 29 de Enero, 2026  
**Versión:** 1.0.0 (Beta)  
**Progreso Actual:** 80%

---

## 📋 INSTRUCCIONES

Este checklist debe completarse antes de considerar la app lista para producción.

**Cómo usar:**
- [ ] = Pendiente
- [x] = Completado
- [!] = Encontrado bug (documentar)
- [~] = Parcialmente completado

---

## 1️⃣ AUTENTICACIÓN Y REGISTRO

### **Registro de Usuario**
- [ ] Crear cuenta con email y contraseña
- [ ] Validación de email (formato correcto)
- [ ] Validación de contraseña (mínimo 6 caracteres)
- [ ] Mensaje de error si email ya existe
- [ ] Mensaje de éxito al registrarse
- [ ] Redirección automática al dashboard

### **Login**
- [ ] Login con credenciales correctas
- [ ] Mensaje de error con credenciales incorrectas
- [ ] Recordar sesión (no pedir login cada vez)
- [ ] Redirección al dashboard después de login

### **Recuperación de Contraseña**
- [ ] Enviar email de recuperación
- [ ] Mensaje de confirmación
- [ ] Link de recuperación funciona
- [ ] Cambiar contraseña exitosamente

### **Logout**
- [ ] Cerrar sesión correctamente
- [ ] Limpiar datos de sesión
- [ ] Redirección a pantalla de login

---

## 2️⃣ PERFIL DE USUARIO

### **Ver Perfil Propio**
- [ ] Ver nombre artístico
- [ ] Ver bio
- [ ] Ver ubicación
- [ ] Ver instrumento principal
- [ ] Ver calificación promedio
- [ ] Ver número de conexiones
- [ ] Ver badge "Open to Work"
- [ ] Ver badge "Premium" (si aplica)

### **Editar Perfil**
- [ ] Cambiar nombre artístico
- [ ] Cambiar bio
- [ ] Cambiar ubicación
- [ ] Cambiar instrumento
- [ ] Cambiar foto de perfil
- [ ] Guardar cambios exitosamente
- [ ] Ver cambios reflejados inmediatamente

### **Ver Perfil Público (Otro Usuario)**
- [ ] Ver información del usuario
- [ ] Ver calificación promedio
- [ ] Ver botón "Conectar" (si no están conectados)
- [ ] Ver botón "Mensaje" (si están conectados)
- [ ] Ver botón "Calificar"
- [ ] Ver botón "Reportar"
- [ ] Ver botón "Bloquear"
- [ ] Navegar a ver calificaciones

---

## 3️⃣ SISTEMA DE CONEXIONES

### **Enviar Solicitud**
- [ ] Enviar solicitud de conexión
- [ ] Mensaje de confirmación
- [ ] Botón cambia a "Solicitud Enviada"
- [ ] No poder enviar solicitud duplicada

### **Recibir Solicitud**
- [ ] Ver badge de notificación
- [ ] Ver solicitud en lista de pendientes
- [ ] Ver información del solicitante

### **Aceptar Solicitud**
- [ ] Aceptar solicitud exitosamente
- [ ] Solicitud desaparece de pendientes
- [ ] Usuario aparece en lista de conexiones
- [ ] Ahora se pueden enviar mensajes

### **Rechazar Solicitud**
- [ ] Rechazar solicitud exitosamente
- [ ] Solicitud desaparece de pendientes
- [ ] No aparece en lista de conexiones

### **Ver Conexiones**
- [ ] Ver lista completa de conexiones
- [ ] Buscar dentro de conexiones
- [ ] Ver perfil desde conexión
- [ ] Enviar mensaje desde conexión
- [ ] Eliminar conexión

### **Eliminar Conexión**
- [ ] Eliminar conexión exitosamente
- [ ] Confirmación antes de eliminar
- [ ] Usuario desaparece de lista
- [ ] Ya no se pueden enviar mensajes

---

## 4️⃣ SISTEMA DE MENSAJES

### **Restricción de Mensajes**
- [ ] No poder enviar mensaje sin conexión
- [ ] Ver mensaje de error apropiado
- [ ] Poder enviar mensaje con conexión aceptada

### **Enviar Mensaje**
- [ ] Escribir y enviar mensaje
- [ ] Mensaje aparece en chat
- [ ] Timestamp correcto
- [ ] Scroll automático al último mensaje

### **Recibir Mensaje**
- [ ] Recibir mensaje en tiempo real
- [ ] Notificación de mensaje nuevo
- [ ] Badge de contador actualizado

### **Interfaz de Chat**
- [ ] Mensajes propios alineados a la derecha
- [ ] Mensajes del otro alineados a la izquierda
- [ ] Colores diferentes para cada tipo
- [ ] Timestamps visibles
- [ ] Scroll suave

### **Reportar Conversación**
- [ ] Abrir menú contextual (⋮)
- [ ] Seleccionar "Reportar conversación"
- [ ] Completar formulario de reporte
- [ ] Enviar reporte exitosamente

---

## 5️⃣ SISTEMA DE BLOQUEOS

### **Bloquear Usuario**
- [ ] Bloquear desde perfil público
- [ ] Confirmación antes de bloquear
- [ ] Mensaje de éxito
- [ ] Usuario desaparece del feed
- [ ] Usuario desaparece de búsqueda
- [ ] Usuario desaparece de discovery
- [ ] No se pueden enviar mensajes
- [ ] Conexión eliminada automáticamente

### **Ver Usuarios Bloqueados**
- [ ] Acceder desde configuración
- [ ] Ver lista completa de bloqueados
- [ ] Ver información de cada usuario

### **Desbloquear Usuario**
- [ ] Desbloquear desde lista
- [ ] Confirmación antes de desbloquear
- [ ] Mensaje de éxito
- [ ] Usuario vuelve a aparecer en búsquedas

---

## 6️⃣ SISTEMA DE REPORTES

### **Reportar Usuario**
- [ ] Abrir formulario de reporte desde perfil
- [ ] Seleccionar categoría
- [ ] Seleccionar nivel de urgencia
- [ ] Escribir descripción (obligatorio)
- [ ] Validación de descripción (máx 500 caracteres)
- [ ] Enviar reporte exitosamente
- [ ] Mensaje de confirmación

### **Reportar Post**
- [ ] Abrir menú contextual en post
- [ ] Seleccionar "Reportar"
- [ ] Completar formulario
- [ ] Enviar reporte exitosamente

### **Reportar Evento**
- [ ] Abrir menú contextual en detalle de evento (⋮)
- [ ] Seleccionar "Reportar evento"
- [ ] Completar formulario
- [ ] Enviar reporte exitosamente

### **Reportar Mensaje**
- [ ] Abrir menú contextual en chat (⋮)
- [ ] Seleccionar "Reportar conversación"
- [ ] Completar formulario
- [ ] Enviar reporte exitosamente

### **Límites de Reportes**
- [ ] Verificar límite diario (5 reportes)
- [ ] Mensaje de error al exceder límite
- [ ] Verificar límite semanal (15 reportes)
- [ ] Verificar límite mensual (30 reportes)

---

## 7️⃣ SISTEMA DE CALIFICACIONES

### **Dejar Calificación**
- [ ] Abrir pantalla de calificación
- [ ] Seleccionar estrellas (1-5)
- [ ] Escribir comentario (opcional)
- [ ] Verificación de trabajo conjunto
- [ ] Enviar calificación exitosamente
- [ ] Mensaje de confirmación

### **Ver Calificaciones Recibidas**
- [ ] Ver lista de calificaciones
- [ ] Ver promedio general
- [ ] Ver distribución de estrellas
- [ ] Ver comentarios
- [ ] Ver nombre del calificador
- [ ] Ver fecha de calificación

### **Restricciones**
- [ ] No poder calificar sin trabajo conjunto
- [ ] No poder calificar dos veces al mismo usuario
- [ ] Mensaje de error apropiado

---

## 8️⃣ BÚSQUEDA Y FILTROS

### **Búsqueda Básica**
- [ ] Buscar por nombre
- [ ] Ver resultados en tiempo real
- [ ] Tap en resultado para ver perfil

### **Filtros Avanzados**
- [ ] Abrir panel de filtros
- [ ] Filtrar por tipo (músico/banda/venue)
- [ ] Filtrar por instrumento
- [ ] Filtrar por ubicación
- [ ] Filtrar por calificación (4+, 4.5+)
- [ ] Filtrar por disponibilidad
- [ ] Filtrar por verificados
- [ ] Aplicar múltiples filtros simultáneamente
- [ ] Ver resultados actualizados
- [ ] Limpiar todos los filtros

### **Ordenamiento**
- [ ] Ordenar por recientes
- [ ] Ordenar por mejor calificados
- [ ] Ordenar por más conexiones
- [ ] Ver resultados reordenados

---

## 9️⃣ SISTEMA DE RANKINGS

### **Navegación**
- [ ] Acceder desde menú de configuración
- [ ] Ver pantalla de rankings

### **Top Rated**
- [ ] Ver lista de mejor calificados
- [ ] Ver medallas para top 3 (🥇🥈🥉)
- [ ] Ver calificación de cada usuario
- [ ] Ver badges (premium, verificado)
- [ ] Tap en usuario para ver perfil

### **Más Conectados**
- [ ] Ver lista de más conectados
- [ ] Ver número de conexiones
- [ ] Ver medallas para top 3

### **Más Activos**
- [ ] Ver lista de más activos
- [ ] Ver número de eventos
- [ ] Ver medallas para top 3

### **Funcionalidad General**
- [ ] Cambiar entre tabs
- [ ] Pull-to-refresh para actualizar
- [ ] Animaciones suaves

---

## 🔟 SISTEMA DE NOTIFICACIONES

### **Ver Notificaciones**
- [ ] Ver badge de contador en home
- [ ] Acceder a pantalla de notificaciones
- [ ] Ver lista de notificaciones

### **Tipos de Notificaciones**
- [ ] Notificación de solicitud de conexión
- [ ] Notificación de mensaje nuevo
- [ ] Notificación de nueva calificación
- [ ] Cada tipo con icono apropiado

### **Acciones**
- [ ] Tap en notificación para navegar
- [ ] Marcar como leída (long press)
- [ ] Eliminar notificación (swipe left)
- [ ] Marcar todas como leídas (botón ✓✓)
- [ ] Menú contextual (long press)

### **Actualización**
- [ ] Actualización automática cada 30s
- [ ] Badge actualizado en tiempo real
- [ ] Pull-to-refresh manual

---

## 1️⃣1️⃣ FEED Y POSTS

### **Ver Feed**
- [ ] Ver posts de usuarios
- [ ] Ver posts aleatorios
- [ ] Scroll infinito
- [ ] Pull-to-refresh

### **Crear Post**
- [ ] Escribir contenido
- [ ] Agregar imagen (opcional)
- [ ] Publicar exitosamente
- [ ] Ver post en feed

### **Interactuar con Posts**
- [ ] Ver información del autor
- [ ] Tap en autor para ver perfil
- [ ] Abrir menú contextual
- [ ] Reportar post

### **Filtrado**
- [ ] Posts de usuarios bloqueados no aparecen
- [ ] Posts propios aparecen

---

## 1️⃣2️⃣ EVENTOS

### **Ver Eventos**
- [ ] Ver lista de eventos
- [ ] Ver información básica
- [ ] Tap para ver detalle

### **Detalle de Evento**
- [ ] Ver toda la información
- [ ] Ver organizador
- [ ] Ver lineup (si hay)
- [ ] Ver fecha y hora
- [ ] Ver ubicación

### **Acciones**
- [ ] Unirse al evento
- [ ] Compartir evento
- [ ] Reportar evento (menú ⋮)
- [ ] Ver perfil del organizador

### **Crear Evento**
- [ ] Completar formulario
- [ ] Agregar flyer (opcional)
- [ ] Publicar exitosamente
- [ ] Ver evento en lista

---

## 1️⃣3️⃣ CONFIGURACIÓN

### **Disponibilidad**
- [ ] Activar "Open to Work"
- [ ] Desactivar "Open to Work"
- [ ] Ver cambio reflejado en perfil

### **Tema**
- [ ] Cambiar a modo oscuro
- [ ] Cambiar a modo claro
- [ ] Tema aplicado en toda la app

### **Navegación**
- [ ] Acceder a editar perfil
- [ ] Acceder a billetera
- [ ] Acceder a rankings
- [ ] Acceder a usuarios bloqueados
- [ ] Acceder a premium

### **Cerrar Sesión**
- [ ] Confirmación antes de cerrar
- [ ] Cerrar sesión exitosamente
- [ ] Redirección a login

---

## 1️⃣4️⃣ NAVEGACIÓN GENERAL

### **Bottom Navigation**
- [ ] Navegar a Home
- [ ] Navegar a Explorar
- [ ] Navegar a Eventos
- [ ] Navegar a Mensajes
- [ ] Navegar a Perfil

### **Navegación entre Pantallas**
- [ ] Todas las transiciones suaves
- [ ] Botón de retroceso funciona
- [ ] No hay pantallas bloqueadas
- [ ] Deep linking funciona (si aplica)

---

## 1️⃣5️⃣ UI/UX

### **Diseño**
- [ ] Colores consistentes
- [ ] Tipografía consistente
- [ ] Espaciado apropiado
- [ ] Iconos claros y visibles

### **Tema Light**
- [ ] Todos los textos legibles
- [ ] Contraste apropiado
- [ ] Colores consistentes

### **Tema Dark**
- [ ] Todos los textos legibles
- [ ] Contraste apropiado
- [ ] Colores consistentes

### **Animaciones**
- [ ] Animaciones suaves
- [ ] No hay lag
- [ ] Transiciones apropiadas

### **Feedback Visual**
- [ ] Loading indicators visibles
- [ ] Mensajes de éxito claros
- [ ] Mensajes de error claros
- [ ] Estados vacíos informativos

---

## 1️⃣6️⃣ RENDIMIENTO

### **Velocidad**
- [ ] App carga en menos de 3 segundos
- [ ] Transiciones sin lag
- [ ] Scroll suave en listas largas
- [ ] Imágenes cargan rápido

### **Memoria**
- [ ] No hay memory leaks
- [ ] App no se cierra inesperadamente
- [ ] Uso de memoria razonable

### **Red**
- [ ] Funciona con conexión lenta
- [ ] Mensajes de error si no hay conexión
- [ ] Retry automático cuando vuelve conexión

---

## 1️⃣7️⃣ SEGURIDAD

### **Autenticación**
- [ ] Tokens seguros
- [ ] Sesión expira apropiadamente
- [ ] No se puede acceder sin login

### **Datos**
- [ ] Datos sensibles encriptados
- [ ] No hay datos expuestos en logs
- [ ] Validación en cliente y servidor

### **Permisos**
- [ ] Solo pide permisos necesarios
- [ ] Explica por qué necesita permisos
- [ ] Funciona sin permisos opcionales

---

## 1️⃣8️⃣ COMPATIBILIDAD

### **Android**
- [ ] Funciona en Android 8.0+
- [ ] Funciona en diferentes tamaños de pantalla
- [ ] Funciona en tablets
- [ ] Orientación portrait y landscape

### **iOS** (si aplica)
- [ ] Funciona en iOS 12.0+
- [ ] Funciona en diferentes modelos de iPhone
- [ ] Funciona en iPad
- [ ] Orientación portrait y landscape

---

## 📊 RESUMEN DE TESTING

### **Estadísticas:**
- Total de tests: 200+
- Completados: [ ] / 200+
- Bugs encontrados: [ ]
- Bugs críticos: [ ]
- Bugs resueltos: [ ]

### **Estado General:**
- [ ] Todos los tests críticos pasados
- [ ] Todos los bugs críticos resueltos
- [ ] App estable y lista para producción

---

## 🐛 BUGS ENCONTRADOS

### **Bug #1:**
- **Descripción:**
- **Severidad:** [ ] Crítico [ ] Alto [ ] Medio [ ] Bajo
- **Pantalla:**
- **Pasos para reproducir:**
- **Estado:** [ ] Pendiente [ ] En progreso [ ] Resuelto

### **Bug #2:**
- **Descripción:**
- **Severidad:** [ ] Crítico [ ] Alto [ ] Medio [ ] Bajo
- **Pantalla:**
- **Pasos para reproducir:**
- **Estado:** [ ] Pendiente [ ] En progreso [ ] Resuelto

*(Agregar más según sea necesario)*

---

## ✅ APROBACIÓN FINAL

- [ ] Todos los tests críticos completados
- [ ] Todos los bugs críticos resueltos
- [ ] Rendimiento aceptable
- [ ] UI/UX pulida
- [ ] Documentación completa
- [ ] Lista para producción

**Aprobado por:** _______________  
**Fecha:** _______________  
**Firma:** _______________

---

**Última actualización:** 29 de Enero, 2026
