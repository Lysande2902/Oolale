# Guía de Manejo de Errores - Óolale Mobile

## 📱 Mensajes Estandarizados de Error

### 🌐 **Error de Conexión (Sin Internet)**

**SnackBar (mensaje corto):**
```
🌐 Sin conexión a Internet
```

**Diálogo completo:**
```
Título: Sin Conexión
Mensaje: 🌐 Sin conexión a Internet

Verifica tu conexión Wi-Fi o datos móviles e intenta nuevamente.

Botones: [Reintentar] [Cancelar]
```

---

### ⚙️ **Error de Base de Datos/Servidor**

**SnackBar (mensaje corto):**
```
⚙️ Error del servidor
```

**Diálogo completo:**
```
Título: Error
Mensaje: ⚙️ Error del servidor

Estamos trabajando en solucionarlo. Por favor, intenta más tarde.

Botones: [Entendido]
```

---

### ❌ **Error Genérico**

**SnackBar (mensaje corto):**
```
❌ Ocurrió un error. Intenta nuevamente
```

**Diálogo completo:**
```
Título: Error
Mensaje: ❌ Algo salió mal

Por favor, intenta nuevamente en unos momentos.

Botones: [Reintentar] [Entendido]
```

---

## 🔧 Uso del ErrorHandler

### Importar
```dart
import '../../utils/error_handler.dart';
```

### Ejemplo 1: Mostrar SnackBar
```dart
try {
  final data = await _supabase.from('perfiles').select();
} catch (e) {
  if (mounted) {
    ErrorHandler.showErrorSnackBar(context, e);
  }
}
```

### Ejemplo 2: Mostrar Diálogo con botón Reintentar
```dart
try {
  await _loadData();
} catch (e) {
  if (mounted) {
    ErrorHandler.showErrorDialog(
      context,
      e,
      title: 'Error cargando datos',
      onRetry: _loadData, // Función a ejecutar al presionar Reintentar
    );
  }
}
```

### Ejemplo 3: Mensaje personalizado
```dart
try {
  await _uploadImage();
} catch (e) {
  if (mounted) {
    ErrorHandler.showErrorSnackBar(
      context,
      e,
      customMessage: 'Error al subir imagen',
    );
  }
}
```

### Ejemplo 4: Logs de debug
```dart
try {
  // código...
} catch (e, stackTrace) {
  ErrorHandler.logError('HomeScreen._loadPosts', e, stackTrace);
}
```

---

## 🎨 Colores y Estilos

### Errores de Red (Naranja)
- Color: `Colors.orange`
- Icono: `Icons.wifi_off`
- Tono: Advertencia temporal

### Errores de Servidor (Rojo)
- Color: `Colors.red`
- Icono: `Icons.error_outline`
- Tono: Error crítico

### Características visuales:
- SnackBars flotantes con bordes redondeados
- Diálogos con iconos circulares de colores
- Texto legible con jerarquía clara
- Fuente: Google Fonts Outfit

---

## 📋 Detección Automática

El `ErrorHandler` detecta automáticamente el tipo de error:

### Errores de Red detectan:
- `SocketException`
- `Connection timed out`
- `Connection refused`
- `Network unreachable`
- `ClientException`

### Errores de DB detectan:
- `PostgrestException`
- `PGRST` (códigos PostgREST)
- `table not found`
- `column does not exist`
- `schema cache`

---

## ✅ Mejores Prácticas

1. **Siempre verificar `mounted`** antes de mostrar UI
2. **Usar try-catch** en todas las llamadas async a Supabase
3. **Registrar errores** con `ErrorHandler.logError()` para debugging
4. **Proveer botón Reintentar** cuando sea lógico (cargas de datos)
5. **Mensajes en español** consistentes y amigables
6. **No mostrar detalles técnicos** al usuario final

---

## 🔄 Flujo Recomendado

```dart
Future<void> _loadData() async {
  setState(() => _isLoading = true);
  
  try {
    final data = await _supabase.from('tabla').select();
    
    if (mounted) {
      setState(() {
        _data = data;
        _isLoading = false;
      });
    }
  } catch (e, stackTrace) {
    ErrorHandler.logError('_loadData', e, stackTrace);
    
    if (mounted) {
      setState(() => _isLoading = false);
      ErrorHandler.showErrorDialog(
        context,
        e,
        onRetry: _loadData,
      );
    }
  }
}
```
