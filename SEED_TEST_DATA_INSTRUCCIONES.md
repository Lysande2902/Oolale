# 🎸 INSTRUCCIONES PARA CREAR USUARIOS DE PRUEBA

## ✅ SCRIPT CORREGIDO Y LISTO

El script `SEED_TEST_DATA.sql` ha sido **completamente corregido** para coincidir con el esquema real de la base de datos.

---

## 📋 PASOS PARA EJECUTAR

### **PASO 1: Crear usuarios en Supabase Auth**

Ve a tu proyecto de Supabase → Authentication → Users → "Add user"

Crea estos 8 usuarios (uno por uno):

| Email | Contraseña |
|-------|-----------|
| maria.garcia@test.com | Test123456! |
| carlos.mendoza@test.com | Test123456! |
| ana.martinez@test.com | Test123456! |
| luis.hernandez@test.com | Test123456! |
| sofia.ramirez@test.com | Test123456! |
| roberto.sanchez@test.com | Test123456! |
| diana.lopez@test.com | Test123456! |
| miguel.torres@test.com | Test123456! |

**IMPORTANTE:** Marca la opción "Auto Confirm User" para cada uno.

---

### **PASO 2: Ejecutar el script SQL**

1. Ve a Supabase → SQL Editor
2. Abre el archivo `SEED_TEST_DATA.sql`
3. Copia todo el contenido
4. Pégalo en el editor SQL
5. Haz clic en "Run"

---

## 🎯 QUÉ CREA EL SCRIPT

### **8 Perfiles de Usuarios Diversos:**
- **María García** - Guitarrista Premium (verificada, nivel pro)
- **Carlos Mendoza** - Baterista (verificado, nivel maestro)
- **Ana Martínez** - Vocalista (principiante)
- **Luis Hernández** - Bajista Premium (verificado, nivel pro)
- **Sofia Ramírez** - Tecladista (principiante)
- **Roberto Sánchez** - Productor/Promotor (verificado, nivel leyenda)
- **Diana López** - Saxofonista (principiante)
- **Miguel Torres** - DJ/Productor (verificado, nivel maestro)

### **8 Eventos Variados:**
1. **Noche de Rock Clásico** - HOY (concierto)
2. **Jam Session de Jazz** - En 3 días
3. **Festival de Música Independiente 2026** - En 15 días
4. **Ensayo Banda de Covers** - En 5 días
5. **Taller de Improvisación Vocal** - En 10 días
6. **Boda Elegante** - En 20 días (privado)
7. **Noche Electrónica - Beach Party** - En 12 días
8. **Concierto de Año Nuevo** - Hace 27 días (completado)

### **Conexiones entre Usuarios:**
- María ↔ Carlos (colaboración)
- Luis ↔ Ana (colaboración)
- Sofia ↔ Diana (colaboración)
- Roberto → María, Carlos, Luis, Miguel (seguidor)

### **Músicos en Eventos:**
- María en "Noche de Rock Clásico"
- Carlos en "Jam Session de Jazz"
- Ana en "Festival de Música Independiente"
- Luis en "Ensayo Banda de Covers"

### **Notificaciones:**
- María: "Luis quiere unirse a tu ensayo"
- Carlos: "Sofia quiere conectar contigo"
- Ana: "Nuevo evento en tu área"
- Luis: "Ana aceptó tu solicitud"
- Roberto: "María se unió a tu evento"

---

## 🔧 CORRECCIONES REALIZADAS

### **Problema Original:**
El script intentaba insertar en columnas que no existían en la base de datos:
- ❌ `email` (no existe en profiles)
- ❌ `pais` (no existe)
- ❌ `nombre_completo` (existe pero no se usaba correctamente)
- ❌ `descripcion`, `hora_inicio`, `lugar_ciudad`, `lugar_estado` (no existen en gigs)
- ❌ `user_id` en crews (se llama `perfil_id`)
- ❌ Tabla `posts` (no existe)

### **Solución Aplicada:**
✅ Removí la columna `email` de todos los INSERT
✅ Agregué `slug_url` (requerido para perfiles)
✅ Agregué `avatar_url` para usuarios con fotos
✅ Corregí columnas de `gigs`: `resumen_setlist`, `hora_soundcheck`, `lugar_nombre`, etc.
✅ Cambié `user_id` por `perfil_id` en crews
✅ Cambié `estatus='aceptado'` por `estatus='activo'`
✅ Removí sección de `posts` (tabla no existe)
✅ Cambié `json_build_object` por `jsonb_build_object`
✅ Cambié búsquedas por `email` a búsquedas por `nombre_artistico`

---

## ✅ VERIFICACIÓN

Después de ejecutar el script, verás:

```
Script de datos de prueba ejecutado exitosamente!
total_perfiles: 8
total_eventos: 8
total_conexiones: 9
total_notificaciones: 5
```

---

## 🎮 CÓMO PROBAR

1. Abre la app móvil
2. Inicia sesión con cualquiera de los 8 usuarios
3. Contraseña para todos: **Test123456!**
4. Explora:
   - Dashboard (verás eventos)
   - Conexiones (verás crews)
   - Notificaciones (verás alertas)
   - Perfil (verás datos completos)

---

## 🚨 SI HAY ERRORES

Si el script falla, ejecuta primero:
```sql
SELECT column_name, data_type 
FROM information_schema.columns
WHERE table_schema = 'public' 
AND table_name = 'profiles'
ORDER BY ordinal_position;
```

Esto te mostrará las columnas exactas de tu tabla `profiles` para verificar que coincidan con el script.

---

## 📝 NOTAS IMPORTANTES

- Todos los usuarios tienen la misma contraseña: **Test123456!**
- Los eventos están distribuidos en el tiempo (hoy, esta semana, este mes, pasado)
- Las conexiones son bidireccionales donde corresponde
- Los avatares usan placeholders de pravatar.cc
- Los roles varían: músico, productor, promotor

---

¡Listo para probar! 🎉
