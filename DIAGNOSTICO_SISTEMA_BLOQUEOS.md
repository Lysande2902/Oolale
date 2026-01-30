# 🔍 Diagnóstico Completo: Sistema de Bloqueos

**Fecha:** 30 de Enero, 2026  
**Estado:** En Revisión

---

## 📋 Resumen del Problema

**Problema Reportado:**
- Los usuarios bloqueados no aparecen en Configuración > Cuenta > Usuarios Bloqueados
- El usuario reporta haber bloqueado a alguien pero no se muestra en la lista

**Causa Raíz Identificada:**
- ❌ El código usaba tabla `bloqueos` con columnas `bloqueador_id` / `bloqueado_id`
- ✅ La base de datos real usa tabla `usuarios_bloqueados` con columnas `usuario_id` / `bloqueado_id`

---

## 🔧 Correcciones Aplicadas

### 1. **blocked_users_screen.dart** ✅
**Archivo:** `lib/screens/settings/blocked_users_screen.dart`

**Cambios:**
```dart
// ANTES (INCORRECTO)
.from('bloqueos')
.eq('bloqueador_id', myId)

// DESPUÉS (CORRECTO)
.from('usuarios_bloqueados')
.eq('usuario_id', myId)
.eq('activo', true)
```

**Mejoras adicionales:**
- ✅ Agregado filtro `activo = true` para solo mostrar bloqueos activos
- ✅ Desbloqueo marca como `activo: false` en lugar de eliminar
- ✅ Agregados logs de debug (`debugPrint`)
- ✅ Corregida foreign key en el select

---

### 2. **public_profile_screen.dart** ✅
**Archivo:** `lib/screens/profile/public_profile_screen.dart`

**Cambios en 4 lugares:**

#### a) Verificación inicial de bloqueo:
```dart
// ANTES
.from('bloqueos')
.eq('bloqueador_id', myId)

// DESPUÉS
.from('usuarios_bloqueados')
.eq('usuario_id', myId)
.eq('activo', true)
```

#### b) Verificación bidireccional:
```dart
// ANTES
.from('bloqueos')
.or('and(bloqueador_id.eq.$myId,bloqueado_id.eq.$userId),and(bloqueador_id.eq.$userId,bloqueado_id.eq.$myId)')

// DESPUÉS
.from('usuarios_bloqueados')
.or('and(usuario_id.eq.$myId,bloqueado_id.eq.$userId),and(usuario_id.eq.$userId,bloqueado_id.eq.$myId)')
.eq('activo', true)
```

#### c) Crear bloqueo:
```dart
// ANTES
.from('bloqueos').insert({
  'bloqueador_id': myId,
  'bloqueado_id': widget.userId,
})

// DESPUÉS
.from('usuarios_bloqueados').insert({
  'usuario_id': myId,
  'bloqueado_id': widget.userId,
  'motivo_bloqueo': 'manual',
  'activo': true,
})
```

#### d) Desbloquear:
```dart
// ANTES
.from('bloqueos')
.delete()
.eq('bloqueador_id', myId)

// DESPUÉS
.from('usuarios_bloqueados')
.update({
  'activo': false,
  'desbloqueado_en': DateTime.now().toIso8601String(),
})
.eq('usuario_id', myId)
```

---

## 📊 Estructura de Base de Datos

### Tabla: `usuarios_bloqueados`

```sql
CREATE TABLE usuarios_bloqueados (
    id SERIAL PRIMARY KEY,
    usuario_id UUID NOT NULL REFERENCES profiles(id) ON DELETE CASCADE,
    bloqueado_id UUID NOT NULL REFERENCES profiles(id) ON DELETE CASCADE,
    
    -- Razón del bloqueo
    razon VARCHAR(255),
    motivo_bloqueo VARCHAR(50), -- acoso, spam, inapropiado, otro, manual
    
    -- Timestamps
    bloqueado_en TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    desbloqueado_en TIMESTAMP WITH TIME ZONE,
    
    -- Seguimiento
    moderador_id UUID REFERENCES profiles(id),
    activo BOOLEAN DEFAULT TRUE,
    
    created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    CHECK (usuario_id != bloqueado_id)
);
```

**Columnas clave:**
- `usuario_id`: El que bloquea (antes `bloqueador_id`)
- `bloqueado_id`: El que es bloqueado
- `activo`: TRUE = bloqueado, FALSE = desbloqueado
- `bloqueado_en`: Fecha de bloqueo
- `desbloqueado_en`: Fecha de desbloqueo (si aplica)

---

## ⚠️ Archivos Pendientes de Corrección

Los siguientes archivos AÚN usan la tabla incorrecta `bloqueos`:

### Archivos que necesitan corrección:

1. ✅ **blocked_users_screen.dart** - CORREGIDO
2. ✅ **public_profile_screen.dart** - CORREGIDO
3. ❌ **unified_profile_screen.dart** - PENDIENTE
4. ❌ **rankings_screen.dart** - PENDIENTE
5. ❌ **messages_screen.dart** - PENDIENTE
6. ❌ **chat_screen.dart** - PENDIENTE
7. ❌ **hire_musician_screen.dart** - PENDIENTE
8. ❌ **gig_detail_screen.dart** - PENDIENTE
9. ❌ **events_screen.dart** - PENDIENTE
10. ❌ **search_screen.dart** - PENDIENTE
11. ❌ **home_screen.dart** - PENDIENTE
12. ❌ **discovery_screen.dart** - PENDIENTE

---

## 🧪 Plan de Pruebas

### Prueba 1: Bloquear Usuario
1. Ir al perfil de un usuario
2. Presionar botón "Bloquear"
3. Confirmar acción
4. **Verificar:** Usuario aparece en Configuración > Usuarios Bloqueados

### Prueba 2: Ver Lista de Bloqueados
1. Ir a Configuración > Cuenta > Usuarios Bloqueados
2. **Verificar:** Se muestran todos los usuarios bloqueados
3. **Verificar:** Cada tarjeta muestra: foto, nombre, rol, ubicación

### Prueba 3: Desbloquear Usuario
1. En lista de bloqueados, presionar icono de bloqueo
2. Confirmar desbloqueo
3. **Verificar:** Usuario desaparece de la lista
4. **Verificar:** Puede volver a interactuar con ese usuario

### Prueba 4: Verificación en Base de Datos
```sql
-- Ver usuarios bloqueados por un usuario específico
SELECT 
    ub.id,
    ub.usuario_id,
    ub.bloqueado_id,
    p.nombre_artistico,
    ub.activo,
    ub.bloqueado_en
FROM usuarios_bloqueados ub
JOIN profiles p ON ub.bloqueado_id = p.id
WHERE ub.usuario_id = 'TU-UUID-AQUI'
    AND ub.activo = TRUE
ORDER BY ub.bloqueado_en DESC;
```

---

## 🔍 Comandos de Diagnóstico

### 1. Verificar si existe la tabla correcta:
```sql
SELECT table_name 
FROM information_schema.tables 
WHERE table_schema = 'public' 
AND table_name IN ('bloqueos', 'usuarios_bloqueados');
```

### 2. Ver estructura de la tabla:
```sql
SELECT column_name, data_type, is_nullable
FROM information_schema.columns
WHERE table_name = 'usuarios_bloqueados'
ORDER BY ordinal_position;
```

### 3. Contar bloqueos activos:
```sql
SELECT COUNT(*) as total_bloqueos_activos
FROM usuarios_bloqueados
WHERE activo = TRUE;
```

### 4. Ver todos los bloqueos (activos e inactivos):
```sql
SELECT 
    ub.*,
    bloqueador.nombre_artistico as quien_bloquea,
    bloqueado.nombre_artistico as quien_es_bloqueado
FROM usuarios_bloqueados ub
LEFT JOIN profiles bloqueador ON ub.usuario_id = bloqueador.id
LEFT JOIN profiles bloqueado ON ub.bloqueado_id = bloqueado.id
ORDER BY ub.created_at DESC
LIMIT 20;
```

---

## 📝 Logs de Debug

Los archivos corregidos ahora incluyen logs para facilitar el debugging:

```dart
// Al cargar usuarios bloqueados
debugPrint('🔍 Cargando usuarios bloqueados para: $myId');
debugPrint('📦 Usuarios bloqueados encontrados: ${data.length}');

// Al bloquear
debugPrint('🚫 Bloqueando usuario: $userId');
debugPrint('✅ Usuario bloqueado exitosamente');

// Al desbloquear
debugPrint('🔓 Desbloqueando usuario: $blockId');
debugPrint('✅ Usuario desbloqueado exitosamente');

// En caso de error
debugPrint('❌ Error cargando usuarios bloqueados: $e');
```

---

## ✅ Checklist de Verificación

- [x] Identificar tabla correcta en base de datos
- [x] Corregir `blocked_users_screen.dart`
- [x] Corregir `public_profile_screen.dart`
- [x] Agregar logs de debug
- [x] Agregar filtro `activo = true`
- [x] Cambiar delete por update (soft delete)
- [ ] Corregir archivos restantes
- [ ] Probar bloqueo de usuario
- [ ] Probar visualización de lista
- [ ] Probar desbloqueo
- [ ] Verificar en base de datos

---

## 🎯 Próximos Pasos

1. **Inmediato:** Probar las correcciones aplicadas
2. **Corto plazo:** Corregir los 10 archivos restantes
3. **Mediano plazo:** Crear tests automatizados
4. **Largo plazo:** Agregar analytics de bloqueos

---

## 📞 Soporte

Si el problema persiste después de estas correcciones:

1. Verificar logs en consola (buscar emojis 🔍 🚫 ✅ ❌)
2. Ejecutar queries de diagnóstico en Supabase
3. Verificar que la tabla `usuarios_bloqueados` existe
4. Verificar permisos RLS en Supabase

---

**Estado Final:** ✅ Correcciones principales aplicadas, pendiente verificación completa
