# Solución al Problema del Perfil que No Se Actualiza

## 🔍 Diagnóstico del Problema

Cuando editas el perfil y guardas, los cambios no se reflejan visualmente porque:

1. **El perfil no existe en la base de datos** - Los usuarios nuevos no tienen un registro en la tabla `profiles`
2. **El trigger no está activo** - No se crea automáticamente el perfil al registrarse
3. **Vista pública usa columnas incorrectas** - La pantalla de vista previa usaba `avatar_url` y `bio_rider` en lugar de `foto_perfil` y `bio`

## ✅ Solución Paso a Paso

### Paso 1: Ejecutar el Script de Fix en Supabase

1. Ve a: https://supabase.com/dashboard/project/lwrlunndqzepwsbmofki/sql/new

2. Copia y pega el contenido del archivo `FIX_PROFILE_CREATION.sql`

3. Click en "Run"

4. Verifica que el resultado muestre:
   - ✅ Trigger creado correctamente
   - ✅ Perfiles creados para usuarios sin perfil
   - ✅ Lista de usuarios con su estado de perfil

### Paso 2: Verificar que el Perfil Existe

Ejecuta esta query en Supabase SQL Editor:

```sql
SELECT 
  u.id,
  u.email,
  p.nombre_artistico,
  p.bio,
  p.ubicacion,
  p.instrumento_principal
FROM auth.users u
LEFT JOIN public.profiles p ON u.id = p.id
WHERE u.email = 'salas@gmail.com';  -- Reemplaza con tu email
```

Deberías ver:
- ✅ Un registro con tu email
- ✅ El perfil con datos (aunque sean NULL está bien)

### Paso 3: Reiniciar la App

1. Detén la app (presiona `q` en la terminal de Flutter)
2. Ejecuta nuevamente: `flutter run`
3. Inicia sesión con tu usuario

### Paso 4: Editar y Verificar

1. Ve al tab de **Perfil** (último icono del bottom nav)
2. Click en **"Editar Perfil"**
3. Cambia el **Nombre Artístico** a algo diferente (ej: "Mi Nombre Test")
4. Agrega una **Bio** (ej: "Esta es mi bio de prueba")
5. Agrega una **Ubicación** (ej: "Ciudad de México")
6. Agrega un **Instrumento Principal** (ej: "Guitarra")
7. Click en **"Guardar"**
8. Vuelve atrás

**Resultado esperado:**
- ✅ El nombre artístico debe aparecer en grande en el perfil
- ✅ La bio debe aparecer en la sección "Bio"
- ✅ La ubicación debe aparecer con el icono de ubicación
- ✅ El instrumento principal debe aparecer en su tarjeta

### Paso 5: Verificar Vista Previa (Icono del Ojito 👁️)

1. En tu perfil, click en el **icono del ojito** (👁️) al lado de "Editar Perfil"
2. Verifica que se muestre:
   - ✅ Tu foto de perfil
   - ✅ Tu nombre artístico
   - ✅ Tu ubicación con icono
   - ✅ Tu calificación (si tienes)
   - ✅ Badges de "Disponible" o "PREMIUM" (si aplica)
   - ✅ Tu instrumento principal en su tarjeta
   - ✅ Tu bio completa
   - ✅ Tus instrumentos en "Mi Equipo"

## 🐛 Si Aún No Funciona

### Verificar los Logs

Busca en los logs de Flutter:

```
SAVE: Profile updated successfully: [...]
```

Si ves `[]` (array vacío), significa que el UPDATE no encontró el registro.

### Crear el Perfil Manualmente

Si el script no funcionó, crea el perfil manualmente:

```sql
INSERT INTO public.profiles (id, email, nombre_artistico)
SELECT 
  id,
  email,
  SPLIT_PART(email, '@', 1)
FROM auth.users
WHERE email = 'salas@gmail.com'  -- Reemplaza con tu email
ON CONFLICT (id) DO NOTHING;
```

### Verificar que el UPDATE Funciona

Ejecuta esto en Supabase:

```sql
UPDATE public.profiles
SET nombre_artistico = 'Test Manual'
WHERE id = (SELECT id FROM auth.users WHERE email = 'salas@gmail.com');

-- Verificar
SELECT * FROM public.profiles 
WHERE id = (SELECT id FROM auth.users WHERE email = 'salas@gmail.com');
```

Si esto funciona, el problema está en la app. Si no funciona, el problema está en la base de datos.

## 📝 Cambios Realizados en el Código

### 1. ProfileScreen
- ✅ Recarga automática al volver de editar perfil
- ✅ Eliminada la etiqueta de "MÚSICO"
- ✅ Muestra ubicación, calificación, badges e instrumento principal

### 2. PublicProfileScreen  
- ✅ Eliminada la etiqueta de "MÚSICO"
- ✅ Corregido: Usa `foto_perfil` en lugar de `avatar_url`
- ✅ Corregido: Usa `bio` en lugar de `bio_rider`
- ✅ Agregada sección de ubicación con icono
- ✅ Agregada sección de calificación con estrellas
- ✅ Agregados badges de "Disponible" y "PREMIUM"
- ✅ Agregada tarjeta de instrumento principal

### 3. HomeScreen
- ✅ Carga el perfil al inicio
- ✅ Manejo robusto de nombres vacíos

### 4. EditProfileScreen
- ✅ Guarda correctamente en la base de datos
- ✅ Logs detallados para debugging
- ✅ Retorna `true` al guardar exitosamente

## 📊 Estructura de la Tabla Profiles

Columnas que SÍ se usan:
- `id` - UUID del usuario
- `email` - Email del usuario
- `nombre_artistico` - Nombre principal (NO `nombre_completo`)
- `bio` - Biografía principal (NO `bio_rider`)
- `foto_perfil` - URL de la foto (NO `avatar_url`)
- `ubicacion` - Ubicación del usuario
- `instrumento_principal` - Instrumento que toca
- `rol_principal` - Rol (musico, banda, staff, fan)
- `open_to_work` - Disponible para trabajar
- `ranking_tipo` - regular o premium
- `verificado` - Si está verificado
- `rating_promedio` - Calificación promedio
- `total_calificaciones` - Número de calificaciones

Columnas que NO se usan (pero existen):
- `avatar_url` - NO SE USA
- `bio_rider` - NO SE USA
- `ubicacion_base` - NO SE USA

## 🎯 Próximos Pasos

Una vez que el perfil funcione correctamente:

1. **Probar con múltiples usuarios** - Registra otro usuario y verifica que su perfil se cree automáticamente
2. **Probar la edición de foto** - Sube una foto de perfil y verifica que se muestre
3. **Probar los instrumentos** - Agrega instrumentos en "Mis Instrumentos"
4. **Verificar la vista pública** - Ve al perfil de otro usuario y verifica que se vea correctamente
5. **Verificar la vista previa** - Usa el icono del ojito para ver cómo te ven otros usuarios

## ❓ Preguntas Frecuentes

**P: ¿Por qué no se creó el perfil automáticamente?**
R: Porque el trigger no estaba activo. El script `FIX_PROFILE_CREATION.sql` lo activa.

**P: ¿Los usuarios antiguos también tendrán perfil?**
R: Sí, el script crea perfiles para todos los usuarios que no tienen.

**P: ¿Qué pasa si registro un usuario nuevo ahora?**
R: Después de ejecutar el script, todos los usuarios nuevos tendrán perfil automáticamente.

**P: ¿Por qué se guarda pero no se ve?**
R: Porque el perfil no existe en la base de datos, entonces el UPDATE no hace nada. Necesitas crear el perfil primero con el script.

**P: ¿Por qué la vista previa (ojito) no mostraba los cambios?**
R: Porque usaba columnas incorrectas (`avatar_url` y `bio_rider`). Ahora usa las correctas (`foto_perfil` y `bio`).

## 🔧 Archivos Modificados

- `lib/screens/profile/profile_screen.dart` - Perfil propio
- `lib/screens/profile/edit_profile_screen.dart` - Edición de perfil
- `lib/screens/profile/public_profile_screen.dart` - Vista pública/previa
- `lib/screens/dashboard/home_screen.dart` - Pantalla principal
- `FIX_PROFILE_CREATION.sql` - Script de corrección
- `ESTRUCTURA_TABLA_PROFILES.md` - Documentación de la tabla
