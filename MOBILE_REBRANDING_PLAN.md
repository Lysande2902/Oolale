# 🚀 PLAN DE MEJORA: Óolale Mobile

**📅 Fecha:** 22/01/2026  
**📌 Estado:** Iniciando FASE 1  
**🎯 Objetivo:** Mejorar la aplicación móvil `Óolale`, alineada con la estética premium de la web y la robustez del backend `JAMConnect_admins`.

---

## 🎨 FASE 1: IDENTIDAD Y DISEÑO (EN PROCESO)
- [x] **Nombre Oficial:** Óolale, El latido de tu música.
- [x] **Paleta de Colores (Web Match):** 
  - Teal (#009688)
  - Aquamarina (#4DB6AC)
  - Negro (#0A0A0A)
  - Gris (#1A1A1A)
  - Blanco (#FFFFFF)
- [ ] **Tipografía:** Implementar fuentes Sans Serif modernas (Outfit/Inter) para un look premium.

## 🏗️ FASE 2: ALINEACIÓN TÉCNICA (BACKEND SYNC)
- [ ] **Auditoría de Endpoints:** Verificar que `lib/services/api_service.dart` apunte y use los modelos correctos de `JAMConnect_admins`.
- [ ] **Modelos de Datos:** Asegurar que los modelos `Usuario`, `Evento`, `Perfil`, `Mensaje` y `Pago` coincidan con el esquema de Supabase/PostgreSQL.
- [ ] **Autenticación:** Validar el flujo de JWT con el nuevo backend.

## 💎 FASE 3: UI/UX PREMIUM OVERHAUL
- [ ] **Glassmorphism:** Implementar efectos de desenfoque y transparencias en tarjetas y menús, similares a la web.
- [ ] **Animaciones:** Usar `animate_do` y `rive` para micro-interacciones (feedback al pulsar, cargas suaves).
- [ ] **Dashboard Principal:** Rediseñar la pantalla de inicio para que se sienta viva, mostrando eventos cercanos y recomendaciones de músicos.

## 📅 FASE 4: FUNCIONALIDADES CRÍTICAS
- [ ] **Gestor de Eventos:** Finalizar la conexión con el Backend para creación y RSVP de eventos.
- [ ] **Perfil del Músico:** Implementar la visualización del "Musician DNA" (Gear, Instrumentos, Portafolio).
- [ ] **Seguridad & Reportes:** Asegurar que el sistema de reportes funcione de punta a punta.
- [ ] **Pagos:** Integrar el flujo de MercadoPago/PayPal ya preparado en el backend.

---

## 📋 SIGUIENTES PASOS INMEDIATOS
1. **Logo:** Revisar la propuesta generada y aplicarla a los assets del proyecto.
2. **Setup:** Renombrar internamente el proyecto si es necesario (manteniendo la lógica).
3. **Dashboard:** Empezar con el rediseño de la pantalla principal para "wowe-ar" al usuario.
