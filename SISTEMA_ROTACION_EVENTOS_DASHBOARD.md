# 🎯 SISTEMA DE ROTACIÓN DE EVENTOS DESTACADOS - DASHBOARD

**Implementado:** Enero 27, 2026  
**Estado:** ✅ COMPLETADO

---

## 📋 Cambios Realizados

Se ha implementado un sistema automático de rotación de eventos en la sección "DESTACADO" del Dashboard de Óolale Mobile.

---

## ✨ Características Implementadas

### 1. **Rotación Automática Cada Minuto**
```dart
// Timer que cambia el evento cada 60 segundos
Timer.periodic(const Duration(seconds: 60), (timer) {
  setState(() {
    _currentFeaturedIndex = (_currentFeaturedIndex + 1) % _trendingGigs.length;
  });
});
```

**Comportamiento:**
- Los eventos se rotan automáticamente cada 60 segundos
- Al llegar al último evento, vuelve al primero (ciclo infinito)
- Se activa solo si hay 4 o más eventos disponibles

### 2. **Visualización de Eventos**

**Antes:**
```
Destacado           4
[Evento 1 - Tarjeta]
```

**Después:**
```
Destacado           2/4
[Evento 2 - Tarjeta rotativa]
● ● ● ●  ← Indicadores de posición
```

### 3. **Indicadores Visuales**
- Números mostrando posición actual (2/4 = evento 2 de 4)
- **Puntos indicadores** debajo de la tarjeta
  - Punto activo (color Teal) = evento actual
  - Puntos inactivos (gris oscuro) = otros eventos

### 4. **Interacción al Click**
```dart
GestureDetector(
  onTap: () => context.push('/gig/${featuredGig['id']}'),
  child: Container(...)
)
```

- Al hacer click en cualquier evento destacado
- Se abre la pantalla de detalles del evento
- Muestra información completa del evento seleccionado

---

## 🔧 Variables Agregadas

```dart
// Rotación de eventos destacados
Timer? _featuredGigTimer;
int _currentFeaturedIndex = 0;
```

---

## 📍 Métodos Agregados

### `_startFeaturedGigRotation()`
```dart
void _startFeaturedGigRotation() {
  // Cancelar timer anterior si existe
  _featuredGigTimer?.cancel();
  
  // Crear nuevo timer que cambia cada 60 segundos (1 minuto)
  _featuredGigTimer = Timer.periodic(const Duration(seconds: 60), (timer) {
    if (mounted && _trendingGigs.isNotEmpty) {
      setState(() {
        _currentFeaturedIndex = (_currentFeaturedIndex + 1) % _trendingGigs.length;
      });
    }
  });
}
```

**Propósito:**
- Inicia la rotación automática de eventos
- Se cancela el timer anterior para evitar conflictos
- Usa `mounted` para evitar errores cuando el widget es desechado

---

## 🎨 Cambios en UI

### Sección Destacado - Antes
```
Destacado           4
┌─────────────────────┐
│  Evento 1           │
│  Ubicación          │
└─────────────────────┘
```

### Sección Destacado - Después
```
Destacado           1/4
┌─────────────────────┐
│  Evento 1           │
│  Ubicación          │
└─────────────────────┘
   ● ● ● ●
   ↑
   Indicadores de rotación
```

**Indicadores de Puntos:**
- Aparecen solo si hay 4 o más eventos
- Se actualizan con cada rotación
- Color Teal (#009688) para evento actual
- Color gris oscuro para otros eventos

---

## 📊 Lógica de Rotación

```
Secuencia temporal:
00:00 → Evento 1 (Index 0) ● ○ ○ ○
01:00 → Evento 2 (Index 1) ○ ● ○ ○
02:00 → Evento 3 (Index 2) ○ ○ ● ○
03:00 → Evento 4 (Index 3) ○ ○ ○ ●
04:00 → Evento 1 (Index 0) ● ○ ○ ○ [Ciclo reinicia]
...
```

---

## ⚙️ Detalles Técnicos

### Condiciones de Activación
```dart
if (gigs.length >= 4) {
  _startFeaturedGigRotation();
}
```

- Se requieren **mínimo 4 eventos** para activar la rotación
- Si hay menos de 4 eventos, se muestra solo el primero

### Cancelación del Timer
```dart
@override
void dispose() {
  _postSubscription?.cancel();
  _postController.dispose();
  _featuredGigTimer?.cancel(); // ← Importantísimo
  super.dispose();
}
```

- El timer se cancela automáticamente al descartar el widget
- Evita memory leaks y comportamientos inesperados

### Actualización Dinámica
```dart
final featuredGig = _trendingGigs.isNotEmpty 
  ? _trendingGigs[_currentFeaturedIndex]  // ← Usa índice rotativo
  : null;
```

- El evento mostrado cambia según `_currentFeaturedIndex`
- Se actualiza automáticamente cada minuto

---

## 🎯 Flujo de Uso

```
1. Dashboard se carga
   ↓
2. Se cargan eventos desde Supabase
   ↓
3. Si hay 4+ eventos → se inicia timer
   ↓
4. Cada 60 segundos: cambiar índice
   ↓
5. Widget se actualiza con nuevo evento
   ↓
6. Usuario ve puntos indicadores actualizados
   ↓
7. Usuario puede hacer click para ver detalles
   ↓
8. Al cerrar pantalla, vuelve al Dashboard
   ↓
9. Rotación continúa donde se quedó
```

---

## ✅ Checklist de Implementación

- [x] Agregar variables de rotación
- [x] Crear método `_startFeaturedGigRotation()`
- [x] Modificar `dispose()` para cancelar timer
- [x] Actualizar `_loadStreamData()` para iniciar timer
- [x] Usar índice rotativo en build
- [x] Agregar indicador numérico (1/4)
- [x] Agregar puntos indicadores
- [x] Verificar que click abre detalles
- [x] Validar con 4+ eventos
- [x] Pruebas de compilación (sin errores)

---

## 📱 Pantalla Afectada

**Archivo:** `lib/screens/dashboard/home_screen.dart`
**Clase:** `_StreamViewState`

---

## 🚀 Próximas Mejoras Opcionales

1. Agregar animación de transición suave entre eventos
2. Permitir navegación manual con swipe
3. Pausar rotación cuando el usuario está viendo detalles
4. Agregar animación de "fade in/out" o slide
5. Mostrar información adicional (fecha, artista) en tooltip

---

## 📝 Notas Importantes

- ⚠️ El timer DEBE cancelarse en `dispose()` para evitar memory leaks
- ⚠️ Se usa `mounted` para evitar errores de setState en widgets desechados
- ⚠️ La rotación solo se activa con 4+ eventos
- ✅ Click en evento abre detalles (ya funcionaba, se mantiene)
- ✅ Indicadores visuales facilitan entender la rotación

---

**Sistema de rotación de eventos implementado y validado.** 🎵
