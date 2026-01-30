# 🔍 Solución: Perfil No Se Ve Aunque Tiene Datos

## Problema
El perfil no muestra los datos (nombre, bio, ubicación, instrumento) aunque al editar se ve que sí existen en la base de datos.

## Diagnóstico Paso a Paso

### Paso 1: Verificar Datos en Supabase

1. Ve a: https://supabase.com/dashboard/project/lwrlunndqzepwsbmofki/sql/new

2. Copia y pega el contenido del archivo `DIAGNOSTICO_PERFIL_DISPLAY.sql`

3. **IMPORTANTE:** Reemplaza `'salas@gmail.com'` con tu email en TODAS las queries (hay 7 lugares)

4. Click en "Run"

5. **Revisa los resultados:**
   - ✅ **PERFIL EXISTE**: Debe mostrar tu perfil con todos los datos
   - ✅ **VALORES NULL**: Debe mostrar ✅ en todos los campos que editaste
   - ✅ **INSTRUMENTOS**: Debe mostrar los instrumentos que agregaste
   - ✅ **ESTADÍSTICAS**: Puede ser 0, está bien
   - ✅ **BADGES**: Según tu configuración
   - ✅ **ÚLTIMA ACTUALIZACIÓN**: Debe ser reciente (menos de 1 hora)

### Paso 2: Verificar Logs en Flutter

1. **Detén la app** si está corriendo (presiona `q` en la terminal)

2. **Reinicia la app:**
   ```cmd
   cd oolale_mobile
   flutter run
   ```

3. **Inicia sesión** con tu usuario

4. **Ve al tab de Perfil** (último icono del bottom nav)

5. **Busca en los logs** (terminal de Flutter) estas líneas:
   ```
   🔍 LOAD PROFILE: Starting for userId=...
   ✅ LOAD PROFILE: Profile found
      - nombre_artistico: [tu nombre]
      - bio: [tu bio]
      - ubicacion: [tu ubicación]
      - instrumento_principal: [tu instrumento]
      - foto_perfil: [url o null]
   ✅ LOAD PROFILE: Setting state with data
   ✅ LOAD PROFILE: State updated successfully
   🎨 RENDER: Building header
      - nombre_artistico: [tu nombre]
      - foto_perfil: [url o null]
      - ubicacion: [tu ubicación]
   🎨 RENDER: Building bio card
      - bio from data: [tu bio]
      - bio to display: [tu bio]
   ```

### Paso 3: Interpretar los Logs

#### ✅ CASO 1: Los logs muestran los datos correctamente
Si ves tus datos en los logs pero NO en la pantalla:
- **Problema:** Error de renderizado o tema visual
- **Solución:** Ir al Paso 4

#### ❌ CASO 2: Los logs muestran NULL o datos vacíos
Si ves `null` o valores vacíos en los logs:
- **Problema:** Los datos no están en la base de datos
- **Solución:** Ir al Paso 5

#### ❌ CASO 3: No aparecen los logs
Si no ves ningún log de "LOAD PROFILE":
- **Problema:** La pantalla no se está cargando
- **Solución:** Ir al Paso 6

### Paso 4: Problema de Renderizado (datos en logs, no en pantalla)

Si los logs muestran los datos pero la pantalla está en blanco:

1. **Verifica el tema:**
   - ¿El texto es blanco sobre fondo blanco?
   - ¿El texto es negro sobre fondo negro?

2. **Prueba cambiar el tema:**
   - Ve a Configuración
   - Cambia entre tema claro/oscuro
   - Regresa al perfil

3. **Toma screenshot:**
   - Toma captura de pantalla del perfil
   - Compártela para ver si hay elementos invisibles

### Paso 5: Datos No Están en la Base de Datos

Si los logs muestran NULL:

1. **Edita el perfil de nuevo:**
   - Click en "Editar Perfil"
   - Verifica que los campos tengan datos
   - Si están vacíos, llénalos de nuevo
   - Click en "Guardar"

2. **Busca en los logs:**
   ```
   SAVE: Starting save for user ...
   SAVE: nombre_artistico: [tu nombre]
   SAVE: bio: [tu bio]
   SAVE: ubicacion: [tu ubicación]
   SAVE: instrumento_principal: [tu instrumento]
   SAVE: Profile updated successfully: [...]
   ```

3. **Si ves `[]` (array vacío) en el último log:**
   - El UPDATE no encontró el registro
   - Ejecuta el script `FIX_PROFILE_CREATION.sql` en Supabase
   - Reinicia la app

4. **Si ves los datos en el último log:**
   - El guardado fue exitoso
   - Regresa al perfil
   - Debe mostrarse ahora

### Paso 6: Pantalla No Se Carga

Si no aparecen logs de "LOAD PROFILE":

1. **Verifica que estás en la pantalla correcta:**
   - Debe ser el último tab del bottom navigation
   - El título debe decir tu nombre o "Perfil"

2. **Verifica errores en los logs:**
   - Busca líneas rojas en la terminal
   - Busca "ERROR" o "Exception"
   - Comparte el error completo

3. **Reinicia la app:**
   ```cmd
   flutter run
   ```

### Paso 7: Probar Edición y Recarga

1. **Ve al perfil**

2. **Click en "Editar Perfil"**

3. **Cambia algo** (ej: agrega "TEST" al final del nombre)

4. **Click en "Guardar"**

5. **Busca en los logs:**
   ```
   🔄 EDIT: Opening edit screen
   SAVE: Starting save for user ...
   SAVE: Profile updated successfully: [...]
   🔄 EDIT: Returned from edit screen, reloading profile...
   🔍 LOAD PROFILE: Starting for userId=...
   ✅ LOAD PROFILE: Profile found
   ✅ LOAD PROFILE: State updated successfully
   ```

6. **Verifica en la pantalla:**
   - El cambio debe aparecer inmediatamente
   - Si no aparece, hay un problema de renderizado

## Posibles Causas y Soluciones

### Causa 1: Perfil No Existe en la Base de Datos
**Síntoma:** Logs muestran "Profile is NULL"
**Solución:** Ejecutar `FIX_PROFILE_CREATION.sql`

### Causa 2: Datos Son NULL
**Síntoma:** Logs muestran "null" en los campos
**Solución:** Editar perfil y guardar de nuevo

### Causa 3: Problema de Renderizado
**Síntoma:** Logs muestran datos, pantalla en blanco
**Solución:** Cambiar tema, verificar colores

### Causa 4: No Se Recarga Después de Editar
**Síntoma:** Editas pero no se ve el cambio
**Solución:** Ya está corregido con los logs, debe funcionar

### Causa 5: Columnas Incorrectas
**Síntoma:** Logs muestran datos, pero campos específicos no se ven
**Solución:** Ya está corregido, usa `nombre_artistico`, `foto_perfil`, `bio`

## Checklist de Verificación

Marca cada item cuando lo verifiques:

- [ ] Ejecuté `DIAGNOSTICO_PERFIL_DISPLAY.sql` en Supabase
- [ ] Mi perfil existe en la base de datos
- [ ] Los campos tienen valores (no NULL)
- [ ] Reinicié la app con `flutter run`
- [ ] Veo los logs de "LOAD PROFILE" en la terminal
- [ ] Los logs muestran mis datos correctamente
- [ ] Edité el perfil y guardé
- [ ] Veo los logs de "SAVE" exitoso
- [ ] Veo los logs de recarga después de editar
- [ ] Los datos aparecen en la pantalla

## Si Nada Funciona

Si después de todos estos pasos el perfil sigue sin mostrarse:

1. **Copia TODOS los logs** desde que inicias la app hasta que llegas al perfil

2. **Toma screenshots:**
   - Pantalla de perfil (aunque esté en blanco)
   - Pantalla de editar perfil (mostrando que hay datos)
   - Resultado del script SQL en Supabase

3. **Comparte:**
   - Los logs completos
   - Los screenshots
   - Descripción exacta de lo que ves vs lo que esperas ver

## Archivos Relacionados

- `DIAGNOSTICO_PERFIL_DISPLAY.sql` - Script de diagnóstico SQL
- `FIX_PROFILE_CREATION.sql` - Script para crear perfiles faltantes
- `SOLUCION_PROBLEMA_PERFIL.md` - Solución anterior al mismo problema
- `ESTRUCTURA_TABLA_PROFILES.md` - Estructura de la tabla profiles
- `lib/screens/profile/unified_profile_screen.dart` - Pantalla de perfil (con logs)
- `lib/screens/profile/edit_profile_screen.dart` - Pantalla de edición

## Notas Técnicas

### Logs Agregados
Se agregaron logs de depuración en:
- `_loadProfile()` - Carga de datos
- `_buildHeader()` - Renderizado del header
- `_buildBioCard()` - Renderizado de la bio
- `_buildInstrumentCard()` - Renderizado del instrumento
- Botón de editar - Flujo de edición y recarga

### Columnas Correctas
La app usa estas columnas (NO las antiguas):
- ✅ `nombre_artistico` (NO `nombre_completo`)
- ✅ `foto_perfil` (NO `avatar_url`)
- ✅ `bio` (NO `bio_rider`)
- ✅ `ubicacion` (NO `ubicacion_base`)
- ✅ `instrumento_principal`

### Flujo de Recarga
1. Usuario edita perfil
2. EditProfileScreen guarda en Supabase
3. EditProfileScreen retorna
4. UnifiedProfileScreen llama `_loadProfile()`
5. Se cargan datos frescos de Supabase
6. Se actualiza el estado con `setState()`
7. Se re-renderizan los widgets
8. Usuario ve los cambios

Si este flujo no funciona, los logs mostrarán dónde se rompe.
