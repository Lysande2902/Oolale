# Tutorial: Implementación de ErrorHandler en OOLALE

Este documento sirve como guía para desarrolladores sobre cómo utilizar el sistema centralizado de manejo de errores en la aplicación móvil **OOLALE**.

## 1. El Utility `ErrorHandler`

El archivo `lib/utils/error_handler.dart` es el corazón de nuestro sistema. Proporciona métodos estáticos para loguear errores y mostrarlos al usuario de forma consistente.

### Métodos Principales:

*   `logError(String context, dynamic error, {StackTrace? stackTrace})`: Registra el error en la consola (y en el futuro en un servicio externo como Sentry).
*   `showErrorSnackBar(BuildContext context, dynamic error, {String? customMessage})`: Muestra un SnackBar elegante con el error.
*   `showErrorDialog(BuildContext context, dynamic error, {String? title, VoidCallback? onRetry})`: Muestra un diálogo de error con opción a reintentar.

---

## 2. Cómo Implementar en una Pantalla

### Paso 1: Importar el ErrorHandler

```dart
import '../../utils/error_handler.dart';
```

### Paso 2: Usar try-catch en funciones asíncronas

Siempre envuelve tus llamadas a API (Supabase) en bloques `try-catch`.

#### Ejemplo para Carga de Datos (con Reintento):

```dart
Future<void> _loadData() async {
  setState(() => _isLoading = true);
  try {
    final response = await _supabase.from('tabla').select();
    setState(() {
      _items = response;
      _isLoading = false;
    });
  } catch (e) {
    ErrorHandler.logError('NombrePantalla._loadData', e);
    if (mounted) {
      setState(() => _isLoading = false);
      ErrorHandler.showErrorDialog(
        context,
        e,
        title: 'Error al cargar datos',
        onRetry: _loadData, // Llamada recursiva para reintentar
      );
    }
  }
}
```

#### Ejemplo para Acciones Rápidas (SnackBar):

```dart
Future<void> _deleteItem(String id) async {
  try {
    await _supabase.from('tabla').delete().eq('id', id);
    _loadData();
  } catch (e) {
    ErrorHandler.logError('NombrePantalla._deleteItem', e);
    if (mounted) {
      ErrorHandler.showErrorSnackBar(
        context, 
        e, 
        customMessage: 'No se pudo eliminar el elemento'
      );
    }
  }
}
```

---

## 3. Mejores Prácticas

1.  **Contexto Descriptivo:** Al llamar a `logError`, incluye el nombre de la clase y el método (ej. `ChatScreen._sendMessage`).
2.  **Diferencia de Gravedad:**
    *   Usa `showErrorDialog` para errores que impiden ver la pantalla o completar una acción principal (Guardar, Cargar lista).
    *   Usa `showErrorSnackBar` para errores secundarios o feedback rápido.
3.  **Verificar `mounted`:** Antes de mostrar cualquier UI (Dialog/SnackBar) en un bloque `catch` de una función `async`, verifica siempre `if (mounted)`.
4.  **Mensajes en Español:** El `ErrorHandler` traduce automáticamente errores comunes de red y Supabase al español. Si usas `customMessage`, asegúrate de que esté en español.
5.  **Opción de Reintento:** Siempre que sea posible, ofrece `onRetry` en los diálogos de error para mejorar la experiencia del usuario si hay fallos de red temporales.

---

## 4. Tipos de Errores Manejados

El `ErrorHandler` detecta automáticamente:
*   **SocketException:** Problemas de conexión (Timeout, sin internet).
*   **AuthException:** Problemas de sesión o credenciales.
*   **PostgrestException:** Errores de base de datos.
*   **Errores Genéricos:** Cualquier otro fallo inesperado.
