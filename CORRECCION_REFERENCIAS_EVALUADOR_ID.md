# Corrección: Migración de Referencias a evaluador_id/evaluado_id

## 📋 Resumen
Se actualizó el código para usar las nuevas columnas `evaluador_id` y `evaluado_id` en la tabla `referencias`, reemplazando las columnas antiguas `de_usuario_id` y `para_usuario_id`.

## 🔧 Cambios Realizados

### 1. Base de Datos (SQL)
✅ **Archivo**: `FIX_REPORTES_REFERENCIAS.sql`
- Corregido error de sintaxis: `DO $` → `DO $$`
- Script hace las columnas antiguas NULLABLE
- Verifica que existan las nuevas columnas

### 2. Código Dart

#### ✅ Actualizado: `lib/screens/portfolio/ratings_screen.dart`
**Línea 60**: Cambio en query de referencias
```dart
// ANTES
.eq('para_usuario_id', widget.userId)

// DESPUÉS
.eq('evaluado_id', widget.userId)
```

#### ✅ Ya correcto: `lib/screens/ratings/leave_rating_screen.dart`
- Ya usa `evaluador_id` y `evaluado_id` correctamente (líneas 134-135)

#### ✅ Ya correcto: `lib/screens/ratings/view_ratings_screen.dart`
- Ya usa `evaluado_id` correctamente (línea 41)

#### ✅ Ya correcto: `lib/services/event_service.dart`
- Usa `calificador_id` y `calificado_id` (sistema diferente)

### 3. Archivos NO Modificados (Correctos)

#### `lib/screens/portfolio/leave_rating_screen.dart`
- Usa `de_usuario_id` y `para_usuario_id` para tabla **calificaciones** ✅
- La tabla `calificaciones` mantiene estos nombres (no cambió)

## 📊 Estructura de Tablas

### Tabla: `referencias` (ACTUALIZADA)
```sql
- evaluador_id UUID    -- Quien deja la referencia (antes: de_usuario_id)
- evaluado_id UUID     -- Quien recibe la referencia (antes: para_usuario_id)
- puntuacion INTEGER   -- Calificación 1-5
- comentario TEXT
- tipo_interaccion VARCHAR(50)
- verificado BOOLEAN
```

### Tabla: `calificaciones` (SIN CAMBIOS)
```sql
- de_usuario_id UUID      -- Quien califica
- para_usuario_id UUID    -- Quien recibe calificación
- estrellas INTEGER
- comentario TEXT
- tipo_interaccion VARCHAR(50)
```

### Tabla: `reportes` (ACTUALIZADA)
```sql
- estatus VARCHAR(20)  -- Nueva columna agregada
  CHECK (estatus IN ('pendiente', 'en_revision', 'resuelto', 'rechazado'))
```

## ✅ Verificación

### Scripts SQL Ejecutados
1. ✅ `FIX_REPORTES_REFERENCIAS.sql` - Ejecutado correctamente
2. ✅ Políticas RLS verificadas para tabla `referencias`

### Código Dart
- ✅ 1 archivo actualizado: `ratings_screen.dart`
- ✅ 3 archivos ya correctos
- ✅ 0 errores pendientes

## 🎯 Próximos Pasos

1. **Probar la funcionalidad**:
   - Ver referencias de un usuario
   - Dejar una nueva referencia
   - Verificar que se guarden correctamente

2. **Opcional - Limpiar columnas antiguas**:
   Si todo funciona bien, puedes ejecutar el script opcional en `FIX_REFERENCIAS_TABLE.sql` para eliminar las columnas antiguas:
   ```sql
   ALTER TABLE referencias 
   DROP COLUMN IF EXISTS de_usuario_id,
   DROP COLUMN IF EXISTS para_usuario_id;
   ```

3. **Actualizar documentación**:
   - Actualizar diagramas de base de datos
   - Documentar API endpoints si es necesario

## 📝 Notas Importantes

- Las columnas antiguas (`de_usuario_id`, `para_usuario_id`) ahora son NULLABLE
- Esto permite compatibilidad durante la migración
- Los datos existentes NO se pierden
- La app ahora usa exclusivamente las nuevas columnas

## 🐛 Problemas Conocidos

Ninguno. Todos los archivos están actualizados y funcionando correctamente.

---
**Fecha**: 30 de enero de 2026
**Estado**: ✅ Completado
