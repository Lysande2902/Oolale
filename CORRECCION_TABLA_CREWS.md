# Corrección: Tabla 'crews' No Existe

## Problema
```
PostgrestException(message: Could not find the table 'public.crews' in the schema cache, 
code: PGRST205, details: Not Found, hint: Perhaps you meant the table 'public.genres')
```

## Causa
Varios archivos estaban intentando acceder a una tabla llamada `crews` que no existe en la base de datos. La tabla correcta es `connections`.

## Archivos Corregidos

### 1. public_profile_screen.dart
**Antes:**
```dart
final seguidoresData = await _supabase
    .from('crews')
    .select()
    .eq('target_id', widget.userId);
```

**Después:**
```dart
final seguidoresData = await _supabase
    .from('connections')
    .select()
    .eq('conectado_id', widget.userId)
    .eq('estatus', 'accepted');
```

### 2. profile_screen.dart
**Antes:**
```dart
final seguidoresData = await _supabase
    .from('crews')
    .select()
    .eq('target_id', user.id);
```

**Después:**
```dart
final seguidoresData = await _supabase
    .from('connections')
    .select()
    .eq('conectado_id', user.id)
    .eq('estatus', 'accepted');
```

### 3. profile_detail_lists.dart
**Antes:**
```dart
final response = await _supabase
    .from('crews')
    .select('*, profiles:perfil_id(*)') 
    .eq('target_id', widget.userId)
    .range(from, to);
```

**Después:**
```dart
final response = await _supabase
    .from('connections')
    .select('*, profiles:usuario_id(*)') 
    .eq('conectado_id', widget.userId)
    .eq('estatus', 'accepted')
    .range(from, to);
```

### 4. discovery_screen.dart
**Antes:**
```dart
final existing = await _supabase
    .from('crews')
    .select()
    .eq('perfil_id', myId)
    .eq('target_id', targetId)
    .maybeSingle();

await _supabase.from('crews').insert({
  'perfil_id': myId,
  'target_id': targetId,
  'estatus': 'pendiente',
  'es_colaboracion': false,
});
```

**Después:**
```dart
final existing = await _supabase
    .from('connections')
    .select()
    .eq('usuario_id', myId)
    .eq('conectado_id', targetId)
    .maybeSingle();

await _supabase.from('connections').insert({
  'usuario_id': myId,
  'conectado_id': targetId,
  'estatus': 'pending',
});
```

## Cambios Realizados

### Tabla
- ❌ `crews` (no existe)
- ✅ `connections` (tabla correcta)

### Columnas
- ❌ `perfil_id` → ✅ `usuario_id`
- ❌ `target_id` → ✅ `conectado_id`
- ❌ `estatus: 'pendiente'` → ✅ `estatus: 'pending'`
- ❌ `es_colaboracion` → ✅ (eliminado, no existe en connections)

### Filtros Agregados
- ✅ `.eq('estatus', 'accepted')` - Solo contar conexiones aceptadas

## Estado Actual
✅ **0 errores de compilación**
✅ **Todas las referencias a 'crews' eliminadas**
✅ **Usando tabla 'connections' correctamente**

## Próximos Pasos
Ahora puedes:
1. Reiniciar la app con `flutter run`
2. El error de "crews not found" ya no debería aparecer
3. Los contadores de seguidores funcionarán correctamente
4. Las conexiones se crearán en la tabla correcta

## Nota
Este error probablemente venía de código antiguo que usaba una tabla diferente. Ahora todo está alineado con el esquema actual de la base de datos que usa la tabla `connections`.
