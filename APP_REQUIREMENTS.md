# 🎼 Óolale: El Latido de tu Música - Especificaciones de la App

Este documento detalla mi entendimiento de lo que debe ser la aplicación móvil **Óolale**, centrándose en su propósito, funcionalidades clave y la estructura necesaria para soportar una experiencia premium.

## 🎯 1. Visión General
Óolale es el **backstage digital** definitivo. No es solo una red social, es el "rider" técnico y la agenda de contactos de todo músico, banda y promotor que busca detonar su carrera y profesionalizar sus "gigs".

---

## 🎨 2. Identidad y Estética (Visual Rider)
*   **Concepto:** Premium Dark Mode (Estética de estudio de grabación).
*   **Acróstico Visual:**
    *   **Colores:** Teal (#009688) como la frecuencia alta, Aquamarina (#4DB6AC) para el sustain, y Negro (#0A0A0A) como el silencio base.
    *   **Estilo:** Glassmorphism (paneles acústicos), animaciones rítmicas (`animate_do`) y tarjetas estilo "Flyer de Festival" para eventos.
    *   **Fuentes:** Outfit/Inter (Modernas y dinámicas).

---

## 🛠️ 3. Funcionalidades Core (Setlist de Funciones)

### A. Gestión de Identidad (Perfil del Artista)
*   **Autenticación:** Acceso directo vía Supabase Auth.
*   **EPK (Electronic Press Kit) / Perfil:**
    *   **Gear & Licks:** Instrumentos y habilidades.
    *   **Influencias:** Géneros musicales.
    *   **Bio/Trayectoria:** Tu historia en los escenarios.
    *   **Badge Artist:** Estatus **PRO** (Headliner) o Usuario (Support).

### B. Ecosistema de Eventos (The Gig Board)
*   **Touring:** Descubrimiento de eventos cercanos filtrables por "Mood" musical (Jam session, Ensayo, Concierto, Taller, Audición).
*   **Confirmación:** Asegura tu lugar en el line-up (Confirmados / Interesados).
*   **Promotor Mode:** Publica tus fechas con flyer y requerimientos técnicos.

### C. Networking y Jamming
*   **A&R Search:** Buscador para encontrar al integrante que le falta a tu banda (por instrumento, género o nivel).
*   **Crews:** Sistema de conexiones para armar tu red de contactos.
*   **Intercom (Chat):** Comunicación directa para cuadrar ensayos o cerrar fechas.

---

## 💳 4. Monetización y Pagos (The Box Office)
Óolale utiliza un sistema dual para sus transacciones:
1.  **PayPal:** Para suscripciones internacionales y transacciones rápidas.
2.  **Mercado Pago:** Optimizado para transacciones locales y facilidad regional.

---

## 💾 5. Estructura de Datos (The Master Tape)
Para que el show continúe, gestionaremos en Supabase:
1.  **Profiles:** Datos extendidos del músico.
2.  **Eventos:** La cartelera musical.
3.  **Pagos/Tickets:** Seguimiento de suscripciones y tokens.
4.  **Networking:** Conexiones y Mensajería.

---

## 🚀 5. Diferenciadores Premium
*   **Modo Offline:** Consulta de agenda aunque no haya señal.
*   **PRO Tier:** Visibilidad prioritaria en búsquedas y capacidad de crear eventos ilimitados.
*   **Flyers Dinámicos:** Generación o carga de imágenes de alta calidad para los eventos.

---
*Este documento sirve como base para el script SQL y la implementación de las fases 2 y 3.*
