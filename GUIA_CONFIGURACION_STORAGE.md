# 📦 Guía de Configuración de Supabase Storage

**Fecha:** 29 de Enero, 2026  
**Proyecto:** Óolale Mobile  
**Bucket:** media

---

## 🎯 OBJETIVO

Configurar el bucket 'media' en Supabase Storage para almacenar:
- Imágenes y audios de mensajes
- Videos, imágenes y audios del portafolio

---

## 📋 PASO 1: CREAR BUCKET 'MEDIA'

### 1.1 Acceder a Supabase Dashboard

1. Ir a: https://supabase.com/dashboard
2. Seleccionar proyecto: **lwrlunndqzepwsbmofki**
3. En el menú lateral, click en **Storage**

### 1.2 Crear Nuevo Bucket

1. Click en botón **"New bucket"** o **"Create a new bucket"**
2. Configurar el bucket:

```
Name: media
Public bucket: ✅ (ACTIVADO - muy importante)
File size limit: 50 MB
Allowed MIME types: image/*, audio/*, video/mp4
```

3. Click en **"Create bucket"**

### 1.3 Verificar Creación

- El bucket 'media' debe aparecer en la lista de buckets
- Debe tener un ícono de 🌐 indicando que es público

---

## 📂 PASO 2: CREAR ESTRUCTURA DE CARPETAS

### 2.1 Crear Carpeta 'messages'

1. Click en el bucket **'media'**
2. Click en botón **"New folder"** o **"Create folder"**
3. Nombre: `messages`
4. Click en **"Create"**

### 2.2 Crear Carpeta 'portfolio'

1. Repetir el proceso anterior
2. Nombre: `portfolio`
3. Click en **"Create"**

### 2.3 Estructura Final

```
media/
├── messages/     (para imágenes y audios de chat)
└── portfolio/    (para videos, imágenes y audios del portafolio)
```

**Nota:** Las subcarpetas por usuario (ej: `messages/{user_id}/`) se crearán automáticamente cuando los usuarios suban archivos.

---

## 🔒 PASO 3: CONFIGURAR POLÍTICAS RLS

### 3.1 Acceder a Políticas

1. En el bucket 'media', click en **"Policies"** (pestaña superior)
2. O ir a: Storage → media → Policies

### 3.2 Ejecutar Script SQL

1. Ir a **SQL Editor** (menú lateral)
2. Click en **"New query"**
3. Copiar y pegar el contenido de: `oolale_mobile/SETUP_SUPABASE_STORAGE.sql`
4. Click en **"Run"**

### 3.3 Verificar Políticas Creadas

Deberías ver 4 políticas creadas:

| Política | Operación | Descripción |
|----------|-----------|-------------|
| Public read access | SELECT | Cualquiera puede ver archivos |
| Authenticated upload | INSERT | Solo usuarios autenticados pueden subir |
| User update own files | UPDATE | Solo el dueño puede actualizar |
| User delete own files | DELETE | Solo el dueño puede eliminar |

---

## ✅ PASO 4: VERIFICACIÓN

### 4.1 Verificar Bucket

```sql
-- Ejecutar en SQL Editor
SELECT * FROM storage.buckets WHERE name = 'media';
```

Debe retornar:
- `id`: UUID del bucket
- `name`: 'media'
- `public`: true

### 4.2 Verificar Políticas

```sql
-- Ejecutar en SQL Editor
SELECT 
  policyname,
  cmd,
  roles
FROM pg_policies
WHERE tablename = 'objects'
  AND schemaname = 'storage'
ORDER BY policyname;
```

Debe mostrar las 4 políticas creadas.

### 4.3 Probar Upload (Opcional)

1. En Storage → media
2. Click en **"Upload file"**
3. Seleccionar una imagen de prueba
4. Subir a carpeta `messages/`
5. Verificar que se sube correctamente
6. Click en el archivo → **"Copy URL"**
7. Abrir URL en navegador → debe cargar la imagen

---

## 🔍 PASO 5: CONFIGURACIÓN AVANZADA (OPCIONAL)

### 5.1 Límites de Tamaño por Tipo

Si quieres límites diferentes por tipo de archivo:

```sql
-- Ejemplo: Limitar videos a 50MB, imágenes a 10MB, audio a 10MB
-- Esto requiere configuración adicional en el código de la app
```

### 5.2 Compresión Automática

Supabase no ofrece compresión automática, pero la app ya implementa:
- Compresión de imágenes a <2MB (MediaService)
- Validación de tamaño de audio <10MB
- Validación de tamaño de video <50MB

---

## 🐛 TROUBLESHOOTING

### Error: "Bucket already exists"
**Solución:** El bucket ya fue creado. Continuar con las políticas.

### Error: "Permission denied"
**Solución:** Verificar que el bucket sea público y que las políticas RLS estén creadas.

### Error: "File too large"
**Solución:** Verificar límite de tamaño del bucket (50MB) y del archivo.

### Archivos no se ven públicamente
**Solución:** 
1. Verificar que el bucket sea público (🌐)
2. Verificar política "Public read access"
3. Usar `getPublicUrl()` en el código

### Usuarios no pueden subir archivos
**Solución:**
1. Verificar que el usuario esté autenticado
2. Verificar política "Authenticated upload"
3. Verificar que el token de autenticación sea válido

---

## 📊 ESTRUCTURA DE URLs

### URLs Públicas

Las URLs de los archivos seguirán este formato:

```
https://lwrlunndqzepwsbmofki.supabase.co/storage/v1/object/public/media/{path}
```

Ejemplos:
```
# Imagen de mensaje
https://lwrlunndqzepwsbmofki.supabase.co/storage/v1/object/public/media/messages/user-uuid/image_user-uuid_1234567890.jpg

# Audio de mensaje
https://lwrlunndqzepwsbmofki.supabase.co/storage/v1/object/public/media/messages/user-uuid/audio_user-uuid_1234567890.mp3

# Video de portafolio
https://lwrlunndqzepwsbmofki.supabase.co/storage/v1/object/public/media/portfolio/user-uuid/video_user-uuid_1234567890.mp4
```

---

## 🔐 SEGURIDAD

### Políticas RLS Explicadas

#### 1. Public Read Access
```sql
USING (bucket_id = 'media')
```
- Permite a cualquiera (autenticado o no) ver archivos
- Necesario para que las imágenes se muestren en la app

#### 2. Authenticated Upload
```sql
WITH CHECK (
  bucket_id = 'media' AND
  auth.role() = 'authenticated'
)
```
- Solo usuarios con sesión activa pueden subir
- Previene spam y uploads anónimos

#### 3. User Update/Delete Own Files
```sql
USING (
  bucket_id = 'media' AND
  auth.uid()::text = (storage.foldername(name))[2]
)
```
- Extrae el user_id de la ruta del archivo
- Solo permite modificar si coincide con el usuario autenticado
- Ejemplo: `messages/user-123/file.jpg` → solo user-123 puede modificar

---

## 📱 INTEGRACIÓN CON LA APP

### MediaService

El servicio `MediaService` ya está configurado para usar el bucket 'media':

```dart
// Upload imagen
await _supabase.storage.from('media').upload(
  'messages/$userId/$fileName',
  file,
);

// Get URL pública
final url = _supabase.storage.from('media').getPublicUrl(filePath);

// Delete archivo
await _supabase.storage.from('media').remove([filePath]);
```

### Rutas de Archivos

- **Mensajes:** `messages/{userId}/{fileName}`
- **Portafolio:** `portfolio/{userId}/{fileName}`

---

## ✅ CHECKLIST DE CONFIGURACIÓN

- [ ] Bucket 'media' creado
- [ ] Bucket configurado como público
- [ ] Límite de tamaño: 50MB
- [ ] MIME types permitidos: image/*, audio/*, video/mp4
- [ ] Carpeta 'messages/' creada
- [ ] Carpeta 'portfolio/' creada
- [ ] Script SQL ejecutado (4 políticas)
- [ ] Políticas verificadas en dashboard
- [ ] Prueba de upload realizada
- [ ] URL pública funciona

---

## 🚀 PRÓXIMOS PASOS

Una vez completada la configuración de Storage:

1. **Ejecutar `flutter pub get`** - Instalar dependencias
2. **Testing manual** - Probar upload de imágenes y audio
3. **Verificar compresión** - Confirmar que imágenes se comprimen
4. **Probar eliminación** - Verificar que usuarios pueden eliminar sus archivos

---

## 📞 SOPORTE

### Recursos
- Documentación Supabase Storage: https://supabase.com/docs/guides/storage
- Script SQL: `oolale_mobile/SETUP_SUPABASE_STORAGE.sql`
- Código MediaService: `oolale_mobile/lib/services/media_service.dart`

### Contacto
- Proyecto: Óolale Mobile
- Supabase Project: lwrlunndqzepwsbmofki

---

**Última actualización:** 29 de Enero, 2026  
**Estado:** ✅ LISTO PARA CONFIGURAR
