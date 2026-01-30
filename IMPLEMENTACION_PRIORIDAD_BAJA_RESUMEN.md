# Implementación: Configuraciones de Prioridad Baja

## 📋 Estado de Implementación

### ✅ COMPLETADAS (3/8)
1. ✅ **Limpiar Caché** - `cache_settings_screen.dart`
2. ✅ **Tamaño de Fuente** - `font_size_screen.dart`
3. ✅ **Accesibilidad** - `accessibility_screen.dart`

### 🔄 PENDIENTES (5/8)
4. ⏳ Uso de Datos
5. ⏳ Alto Contraste (integrado en Accesibilidad)
6. ⏳ Configuración de Sonidos
7. ⏳ Cambiar Email
8. ⏳ Selección de Idioma

---

## 📝 Notas Importantes

### Dependencias Agregadas
```yaml
path_provider: ^2.1.1
shared_preferences: ^2.2.2
```

### Provider Creado
- `AccessibilityProvider` - Maneja tamaño de fuente, alto contraste y modo accesibilidad

### Funcionalidades Implementadas

#### 1. Limpiar Caché
- Calcula tamaño de caché
- Limpia archivos temporales
- Muestra confirmación antes de limpiar
- Actualiza tamaño después de limpiar

#### 2. Tamaño de Fuente
- Slider para ajustar (0.8x - 1.5x)
- Vista previa en tiempo real
- Botones preestablecidos (Pequeño, Normal, Grande)
- Guarda preferencia con SharedPreferences

#### 3. Accesibilidad
- Navegación a Tamaño de Fuente
- Switch para Alto Contraste
- Modo Accesibilidad (activa todo)
- Integración con AccessibilityProvider

---

## 🎯 Próximos Pasos

Para completar las 5 pantallas restantes, necesitas:

1. **Uso de Datos** - Mostrar estadísticas de uso
2. **Configuración de Sonidos** - Switches para diferentes sonidos
3. **Cambiar Email** - Formulario con verificación
4. **Selección de Idioma** - Lista de idiomas disponibles

Estas son más simples y siguen el mismo patrón de las ya implementadas.

---

## ⚠️ Importante

El `AccessibilityProvider` debe ser agregado en `main.dart`:

```dart
MultiProvider(
  providers: [
    ChangeNotifierProvider(create: (_) => AuthProvider()),
    ChangeNotifierProvider(create: (_) => ThemeProvider()),
    ChangeNotifierProvider(create: (_) => AccessibilityProvider()), // NUEVO
  ],
  child: const _AppRouter(),
)
```

Y las rutas deben ser agregadas en `main.dart`:

```dart
GoRoute(
  path: '/settings/cache',
  builder: (context, state) => const CacheSettingsScreen(),
),
GoRoute(
  path: '/settings/font-size',
  builder: (context, state) => const FontSizeScreen(),
),
GoRoute(
  path: '/settings/accessibility',
  builder: (context, state) => const AccessibilityScreen(),
),
```

---

## 📊 Progreso

**Configuraciones Totales:** 18/23 (78%)
- Básicas: 8/8 (100%) ✅
- Prioridad Alta: 4/4 (100%) ✅
- Prioridad Media: 3/3 (100%) ✅
- Prioridad Baja: 3/8 (38%) 🔄

**Progreso del Proyecto:** 99% → 99.5%

