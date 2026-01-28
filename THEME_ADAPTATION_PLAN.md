# Plan de Adaptación de Temas

## Objetivo
Adaptar todas las pantallas para que funcionen correctamente en modo claro y oscuro.

## Reglas de Adaptación

### ❌ NO USAR (Colores Hardcodeados):
- `Colors.white`
- `Colors.black`
- `Colors.grey[X]`
- Cualquier color específico que no sea del branding

### ✅ USAR (Colores Adaptativos):
- `ThemeColors.primaryText(context)` - Texto principal
- `ThemeColors.secondaryText(context)` - Texto secundario
- `ThemeColors.hintText(context)` - Hints/placeholders
- `ThemeColors.cardBackground(context)` - Fondo de tarjetas
- `ThemeColors.scaffoldBackground(context)` - Fondo de pantalla
- `ThemeColors.divider(context)` - Divisores/bordes
- `ThemeColors.icon(context)` - Iconos principales
- `AppConstants.primaryColor` - Color de marca (siempre igual)
- `AppConstants.errorColor` - Color de error (siempre igual)

## Pantallas a Adaptar

### Prioridad Alta (Más Usadas)
1. ✅ Dashboard (home_screen.dart)
2. ✅ Events (events_screen.dart)
3. ✅ Search (search_screen.dart)
4. ✅ Profile (profile_screen.dart)
5. ✅ Notifications (notifications_screen.dart)

### Prioridad Media
6. ⏳ Messages (messages_screen.dart, chat_screen.dart)
7. ⏳ Portfolio (portfolio_screen.dart, upload_media_screen.dart)
8. ⏳ Settings (settings_screen.dart)
9. ⏳ Edit Profile (edit_profile_screen.dart)
10. ⏳ Public Profile (public_profile_screen.dart)

### Prioridad Baja
11. ⏳ Auth (login_screen.dart, register_screen.dart)
12. ⏳ Gig Detail (gig_detail_screen.dart)
13. ⏳ Create Event (create_event_screen.dart)
14. ⏳ Connections (connections_screen.dart)
15. ⏳ Premium (subscription_screen.dart)

## Patrón de Reemplazo

### Texto
```dart
// ❌ Antes
Text('Hola', style: TextStyle(color: Colors.white))

// ✅ Después
Text('Hola', style: TextStyle(color: ThemeColors.primaryText(context)))
```

### Iconos
```dart
// ❌ Antes
Icon(Icons.home, color: Colors.white)

// ✅ Después
Icon(Icons.home, color: ThemeColors.icon(context))
```

### Contenedores
```dart
// ❌ Antes
Container(
  color: Colors.grey[900],
  child: Text('Hola', style: TextStyle(color: Colors.white)),
)

// ✅ Después
Container(
  color: ThemeColors.cardBackground(context),
  child: Text('Hola', style: TextStyle(color: ThemeColors.primaryText(context))),
)
```

### Divisores
```dart
// ❌ Antes
Container(width: 1, height: 40, color: Colors.grey[900])

// ✅ Después
Container(width: 1, height: 40, color: ThemeColors.divider(context))
```

## Progreso
- [ ] Dashboard
- [ ] Events
- [ ] Search
- [ ] Profile
- [ ] Notifications
- [ ] Messages
- [ ] Portfolio
- [ ] Settings
- [ ] Edit Profile
- [ ] Public Profile
- [ ] Auth
- [ ] Gig Detail
- [ ] Create Event
- [ ] Connections
- [ ] Premium
