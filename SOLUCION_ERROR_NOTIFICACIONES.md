# 🔧 SOLUCIÓN: Error "column notifications.leido does not exist"

**Fecha:** 29 de Enero, 2026  
**Error:** `PostgrestException(message: column notifications.leido does not exist, code: 42703)`  
**Causa:** La tabla `notifications` no tiene la columna `leido`

---

## 🚨 PROBLEMA

La aplicación está intentando usar la columna `leido` en la tabla `notifications` para:
1. Contar notificaciones no leídas (badge en home)
2. Marcar notificaciones como leídas
3. Filtrar notificaciones no leídas
4. Mostrar indicador visual de no leído

**Archivos afectados:**
- `lib/screens/dashboard/home_screen.dart` (línea 192)
- `lib/screens/notifications/notifications_screen.dart` (líneas 91, 134, 187, 262)
- `lib/services/notification_service.dart` (líneas 283, 334)
- `lib/screens/discovery/discovery_screen.dart` (línea 192)

---

## ✅ SOLUCIÓN RÁPIDA

### **Opción 1: Ejecutar Script SQL (RECOMENDADO)**

1. **Abrir Supabase SQL Editor**
   - Ir a tu proyecto en [Supabase](https://supabase.com)
   - Navegar a SQL Editor

2. **Ejecutar el script**
   - Abrir el archivo `FIX_NOTIFICATIONS_LEIDO_COLUMN.sql`
   - Copiar todo el contenido
   - Pegar en SQL Editor
   - Ejecutar (Run)

3. **Verificar**
   - El script agregará la columna `leido` de tipo BOOLEAN
   - Creará un índice para mejorar rendimiento
   - Marcará todas las notificaciones existentes como no leídas

**Script completo:**
```sql
-- 1. Agregar columna 'leido' si no existe
DO $$ 
BEGIN
    IF NOT EXISTS (
        SELECT 1 
        FROM information_schema.columns 
        WHERE table_name = 'notifications' 
        AND column_name = 'leido'
    ) THEN
        ALTER TABLE notifications 
        ADD COLUMN leido BOOLEAN DEFAULT FALSE NOT NULL;
        
        RAISE NOTICE 'Columna leido agregada exitosamente';
    ELSE
        RAISE NOTICE 'La columna leido ya existe';
    END IF;
END $$;

-- 2. Crear índice para mejorar rendimiento
CREATE INDEX IF NOT EXISTS idx_notifications_leido 
ON notifications(user_id, leido, created_at DESC);

-- 3. Actualizar notificaciones existentes
UPDATE notifications 
SET leido = FALSE 
WHERE leido IS NULL;
```

---

### **Opción 2: Crear Columna Manualmente**

Si prefieres hacerlo manualmente en Supabase:

1. **Ir a Table Editor**
   - Seleccionar tabla `notifications`
   - Click en "Add Column"

2. **Configurar columna:**
   - **Name:** `leido`
   - **Type:** `bool` (boolean)
   - **Default value:** `false`
   - **Is nullable:** NO (unchecked)
   - Click "Save"

3. **Crear índice (opcional pero recomendado):**
```sql
CREATE INDEX idx_notifications_leido 
ON notifications(user_id, leido, created_at DESC);
```

---

## 🧪 VERIFICACIÓN

Después de ejecutar el script, verifica que todo funcione:

### **1. Verificar estructura de tabla**
```sql
SELECT 
    column_name, 
    data_type, 
    is_nullable, 
    column_default
FROM information_schema.columns
WHERE table_name = 'notifications'
ORDER BY ordinal_position;
```

**Resultado esperado:**
Debe aparecer la columna `leido` de tipo `boolean` con default `false`

### **2. Probar en la app**
1. Reiniciar la app (hot restart)
2. Navegar al home
3. Verificar que no aparezca el error en logs
4. Verificar que el badge de notificaciones funcione
5. Ir a pantalla de notificaciones
6. Verificar que se puedan marcar como leídas

---

## 📊 ESTRUCTURA ESPERADA DE LA TABLA

Después de aplicar el fix, la tabla `notifications` debe tener:

```
notifications
├── id (uuid, primary key)
├── user_id (uuid, foreign key → profiles.id)
├── tipo (text)
├── titulo (text)
├── mensaje (text)
├── data (jsonb)
├── leido (boolean, default: false) ⭐ NUEVA
├── created_at (timestamp)
└── read_at (timestamp, nullable)
```

---

## 🔍 FUNCIONALIDADES QUE SE ARREGLAN

Una vez aplicado el fix:

✅ **Badge de notificaciones en home**
- Muestra contador de notificaciones no leídas
- Se actualiza automáticamente cada 30 segundos

✅ **Pantalla de notificaciones**
- Muestra indicador visual de no leído (punto amarillo)
- Permite marcar como leída (long press)
- Permite marcar todas como leídas (botón ✓✓)

✅ **Navegación desde notificaciones**
- Al hacer tap, marca automáticamente como leída
- Navega a la pantalla correspondiente

✅ **Menú contextual**
- Long press para ver opciones
- Opción "Marcar como leída" (solo si no está leída)
- Opción "Eliminar"

---

## 🚀 PRÓXIMOS PASOS

Después de aplicar el fix:

1. **Reiniciar la app**
   ```bash
   flutter run
   ```

2. **Probar funcionalidades**
   - Ver badge de notificaciones
   - Marcar como leída
   - Eliminar notificaciones
   - Marcar todas como leídas

3. **Verificar logs**
   - No debe aparecer el error `column notifications.leido does not exist`
   - Debe aparecer: `📦 Notificaciones cargadas: X`

---

## 📝 NOTAS ADICIONALES

### **¿Por qué faltaba esta columna?**
La columna `leido` probablemente no se creó en el script inicial de la base de datos, o se creó con un nombre diferente (como `read` o `is_read`).

### **¿Es seguro ejecutar el script?**
Sí, el script:
- Verifica si la columna ya existe antes de crearla
- No elimina ni modifica datos existentes
- Solo agrega la columna y crea un índice
- Es idempotente (se puede ejecutar múltiples veces sin problemas)

### **¿Afecta a notificaciones existentes?**
No, las notificaciones existentes se marcarán automáticamente como no leídas (`leido = false`), lo cual es el comportamiento esperado.

---

## 🆘 TROUBLESHOOTING

### **Error: "permission denied"**
- Asegúrate de tener permisos de administrador en Supabase
- Ejecuta el script desde el SQL Editor (no desde la app)

### **Error: "relation notifications does not exist"**
- La tabla `notifications` no existe
- Ejecuta primero `SETUP_NOTIFICATIONS_TABLES.sql`

### **El badge sigue sin aparecer**
1. Verifica que la columna se creó correctamente
2. Reinicia la app completamente (no hot reload)
3. Verifica que haya notificaciones en la base de datos
4. Revisa los logs para otros errores

### **Las notificaciones no se marcan como leídas**
1. Verifica que la columna `leido` sea de tipo `boolean`
2. Verifica que el default sea `false`
3. Verifica que no sea nullable
4. Revisa los logs para errores de permisos

---

## ✅ CHECKLIST DE VERIFICACIÓN

- [ ] Script SQL ejecutado exitosamente
- [ ] Columna `leido` creada en tabla `notifications`
- [ ] Índice creado para mejorar rendimiento
- [ ] App reiniciada
- [ ] Error desaparecido de los logs
- [ ] Badge de notificaciones funciona
- [ ] Marcar como leída funciona
- [ ] Marcar todas como leídas funciona
- [ ] Indicador visual de no leído funciona

---

**Última actualización:** 29 de Enero, 2026
