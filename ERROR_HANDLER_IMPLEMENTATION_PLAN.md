# Implementación de ErrorHandler - Plan de Ejecución

## ✅ Ya Implementado:
- ✓ `home_screen.dart` - Pantalla principal
- ✓ `unified_profile_screen.dart` - Vista de perfil

## 📋 Por Implementar (Prioridad Alta):

### 1.Pantallas de Eventos (críticas para el negocio)
- [ ] `events_screen.dart` - Lista de eventos
- [ ] `gig_detail_screen.dart` - Detalle de evento
- [ ] `create_event_screen.dart` - Crear evento

### 2. Pantallas de Mensajería
- [ ] `messages_screen.dart` - Lista de conversaciones
- [ ] `chat_screen.dart` - Chat individual

### 3. Pantallas de Portfolio
- [ ] `portfolio_screen.dart` - Galería de medios
- [ ] `upload_media_screen.dart` - Subir archivos

### 4. Pantallas de Calificaciones
- [ ] `leave_rating_screen.dart` - Dejar calificación
- [ ] `view_ratings_screen.dart` - Ver calificaciones

### 5. Pantallas de Búsqueda
- [ ] `search_screen.dart` - Buscar músicos

### 6. Pantallas de Perfil (edición)
- [] `edit_profile_screen.dart` - Editar perfil básico
- [ ] `edit_musical_info_screen.dart` - Info musical
- [ ] `edit_social_links_screen.dart` - Redes sociales

### 7. Pantallas de Conexiones
- [ ] `connections_screen.dart` - Lista de conexiones
- [ ] `connection_requests_screen.dart` - Solicitudes

### 8. Pantallas de Reportes
- [ ] `report_content_screen.dart` - Reportar contenido

### 9. Pantallas de Notificaciones
- [ ] `notifications_screen.dart` - Lista de notificaciones

## 🔧 Patrón de Implementación:

### Paso 1: Agregar import
```dart
import '../../utils/error_handler.dart';
```

### Paso 2: Reemplazar try-catch
```dart
// Antes:
} catch (e) {
  debugPrint('Error: $e');
  if (mounted) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Error')),
    );
  }
}

// Después:
} catch (e) {
  ErrorHandler.logError('ComponentName.methodName', e);
  if (mounted) {
    ErrorHandler.showErrorDialog(
      context,
      e,
      title: 'Error descriptivo',
      onRetry: _methodName, // Opcional
    );
  }
}
```

### Paso 3: Errores de background (no críticos)
```dart
} catch (e) {
  ErrorHandler.logError('ComponentName.method', e);
  // Solo mostrar si NO es error de red
  if (!ErrorHandler.isNetworkError(e) && mounted) {
    ErrorHandler.showErrorSnackBar(context, e);
  }
}
```

## 📊 Progreso:
- Completado: 2/30 pantallas (7%)
- Prioridad Alta: 18 pantallas
- Prioridad Media: 10 pantallas

## ⏱️ Tiempo estimado:
- ~5 segundos por pantalla
- ~2-3 minutos total para todas las pantallas críticas
