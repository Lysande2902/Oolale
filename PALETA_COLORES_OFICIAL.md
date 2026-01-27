# 🎨 Paleta de Colores Oficial - Óolale Mobile

Última actualización: **Enero 27, 2026**

Esta es la paleta de colores oficial implementada en todo el proyecto oolale_mobile para mantener consistencia de marca.

## 🟢 COLOR PRINCIPAL (Brand Signature)

| Variable | Valor | Hex | Uso |
|----------|-------|-----|-----|
| `primaryColor` | `Color(0xFF009688)` | #009688 | Teal/Verde-Azulado - Botones principales, acentos, links |
| `primaryDark` | `Color(0xFF00796B)` | #00796B | Teal Oscuro - Hover, estados activos |
| `primaryLight` | `Color(0xFF4DB6AC)` | #4DB6AC | Teal Claro - Fondos suaves, badges |

## 🟡 COLORES DE ESTADO (Semánticos)

| Variable | Valor | Hex | Uso |
|----------|-------|-----|-----|
| `successColor` | `Color(0xFF4CAF50)` | #4CAF50 | Verde Éxito - Validaciones correctas, pagos completados |
| `warningColor` | `Color(0xFFFF9800)` | #FF9800 | Naranja Advertencia - Reportes pendientes, alertas |
| `errorColor` | `Color(0xFFF44336)` | #F44336 | Rojo Error - Errores, eliminaciones, campos inválidos |
| `infoColor` | `Color(0xFF2196F3)` | #2196F3 | Azul Información - Tooltips, ayuda, información |

## ⬛ FONDOS OSCUROS (Dark Theme)

| Variable | Valor | Hex | Uso |
|----------|-------|-----|-----|
| `backgroundColor` | `Color(0xFF0A0A0A)` | #0A0A0A | Fondo Principal Body |
| `cardColor` | `Color(0xFF121212)` | #121212 | Fondo Tarjetas y Paneles |
| `bgDarkSecondary` | `Color(0xFF1A1A1A)` | #1A1A1A | Fondo Secundario |
| `bgDarkTertiary` | `Color(0xFF2A2A2A)` | #2A2A2A | Hover, Estados Terciarios |

## ⬜ COLORES DE TEXTO (Dark Theme)

| Variable | Valor | Hex | Uso |
|----------|-------|-----|-----|
| `textPrimary` | `Colors.white` | #FFFFFF | Texto Principal - Títulos, contenido |
| `textSecondary` | `Color(0xFFB0B0B0)` | #B0B0B0 | Texto Secundario - Descripciones |
| `textMuted` | `Color(0xFF808080)` | #808080 | Texto Apagado - Placeholders, fechas |

## 🟫 BORDES Y ACENTOS

| Variable | Valor | Hex | Uso |
|----------|-------|-----|-----|
| `borderColor` | `Color(0xFF333333)` | #333333 | Bordes en tema oscuro |
| `borderGlow` | `Color(0xFF009688)` | #009688 | Bordes con glow del color principal |
| `accentColor` | `Color(0xFFFFC107)` | #FFC107 | Gold - Toques premium (legacy) |
| `aquamarineColor` | `Color(0xFF06B6D4)` | #06B6D4 | Cyan - Alternativo (legacy) |

---

## 📍 UBICACIÓN DE DEFINICIONES

```
lib/config/constants.dart  → Definición principal de colores
lib/main.dart              → Temas de Material Design
lib/providers/theme_provider.dart → Gestión de tema (light/dark)
```

## ✅ CHECKLIST DE IMPLEMENTACIÓN

- [x] AppConstants actualizado con paleta oficial
- [x] main.dart tema oscuro configurado
- [x] Colores semánticos en pantallas (hiring, wallet, etc.)
- [x] Errores y advertencias usando colores correctos
- [x] Éxitos usando successColor (#4CAF50)
- [x] Información usando infoColor (#2196F3)

## 🔄 MIGRACIONES REALIZADAS

### Cambios principales:
- ❌ `primaryColor` (viejo: #1DB584) → ✅ `primaryColor` (#009688)
- ❌ `Colors.green` → ✅ `successColor` (#4CAF50)
- ❌ `Colors.redAccent` → ✅ `errorColor` (#F44336)
- ❌ `Colors.orange` → ✅ `warningColor` (#FF9800) o `infoColor` (#2196F3)
- ❌ `Colors.grey` (en tooltips) → ✅ `textMuted` (#808080)

## 📝 GUÍA PARA FUTUROS DESARROLLADORES

**SIEMPRE usa las constantes en lugar de colores hardcodeados:**

```dart
// ✅ CORRECTO
backgroundColor: AppConstants.primaryColor,
color: AppConstants.successColor,

// ❌ INCORRECTO
backgroundColor: Color(0xFF009688),
color: Colors.green,
```

**Para estados específicos:**
- ✅ Éxito → `AppConstants.successColor`
- ✅ Error → `AppConstants.errorColor`
- ✅ Advertencia → `AppConstants.warningColor`
- ✅ Información → `AppConstants.infoColor`
- ✅ Principal → `AppConstants.primaryColor`

---

**Mantener esta paleta de colores es crucial para la identidad visual de Óolale** 🎵
