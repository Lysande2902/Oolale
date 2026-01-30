-- ═══════════════════════════════════════════════════════════════════════════════
-- CONFIGURACIÓN DE SUPABASE STORAGE - BUCKET 'MEDIA'
-- ═══════════════════════════════════════════════════════════════════════════════
-- Fecha: 29 de Enero, 2026
-- Proyecto: Óolale Mobile
-- Descripción: Políticas RLS para el bucket 'media' de Supabase Storage
-- ═══════════════════════════════════════════════════════════════════════════════

-- NOTA: El bucket 'media' debe ser creado manualmente desde el Dashboard de Supabase
-- Storage → Create bucket → Name: 'media' → Public: YES

-- ═══════════════════════════════════════════════════════════════════════════════
-- POLÍTICAS DE SEGURIDAD PARA STORAGE
-- ═══════════════════════════════════════════════════════════════════════════════

-- Política 1: Lectura pública (cualquiera puede ver archivos)
CREATE POLICY "Public read access for media bucket"
ON storage.objects FOR SELECT
USING (bucket_id = 'media');

-- Política 2: Upload solo para usuarios autenticados
CREATE POLICY "Authenticated users can upload to media bucket"
ON storage.objects FOR INSERT
TO authenticated
WITH CHECK (
  bucket_id = 'media' AND
  auth.role() = 'authenticated'
);

-- Política 3: Usuarios pueden actualizar sus propios archivos
CREATE POLICY "Users can update their own files in media bucket"
ON storage.objects FOR UPDATE
TO authenticated
USING (
  bucket_id = 'media' AND
  auth.uid()::text = (storage.foldername(name))[2]
)
WITH CHECK (
  bucket_id = 'media' AND
  auth.uid()::text = (storage.foldername(name))[2]
);

-- Política 4: Usuarios pueden eliminar sus propios archivos
CREATE POLICY "Users can delete their own files in media bucket"
ON storage.objects FOR DELETE
TO authenticated
USING (
  bucket_id = 'media' AND
  auth.uid()::text = (storage.foldername(name))[2]
);

-- ═══════════════════════════════════════════════════════════════════════════════
-- VERIFICACIÓN DE POLÍTICAS
-- ═══════════════════════════════════════════════════════════════════════════════

-- Verificar que las políticas fueron creadas
SELECT 
  schemaname,
  tablename,
  policyname,
  permissive,
  roles,
  cmd
FROM pg_policies
WHERE tablename = 'objects'
  AND schemaname = 'storage'
ORDER BY policyname;

-- ═══════════════════════════════════════════════════════════════════════════════
-- NOTAS IMPORTANTES
-- ═══════════════════════════════════════════════════════════════════════════════

-- ESTRUCTURA DE CARPETAS ESPERADA:
-- media/
-- ├── messages/
-- │   └── {user_id}/
-- │       ├── image_{user_id}_{timestamp}.jpg
-- │       └── audio_{user_id}_{timestamp}.mp3
-- └── portfolio/
--     └── {user_id}/
--         ├── video_{user_id}_{timestamp}.mp4
--         └── image_{user_id}_{timestamp}.jpg

-- CONFIGURACIÓN DEL BUCKET:
-- - Name: media
-- - Public: YES (para que las URLs sean accesibles públicamente)
-- - File size limit: 50 MB
-- - Allowed MIME types: image/*, audio/*, video/mp4

-- SEGURIDAD:
-- Las políticas RLS aseguran que:
-- 1. Cualquiera puede VER archivos (lectura pública)
-- 2. Solo usuarios autenticados pueden SUBIR archivos
-- 3. Solo el dueño puede ACTUALIZAR sus archivos
-- 4. Solo el dueño puede ELIMINAR sus archivos

-- La estructura de carpetas {user_id}/ asegura que cada usuario
-- solo pueda modificar/eliminar sus propios archivos

-- ═══════════════════════════════════════════════════════════════════════════════
-- RESUMEN
-- ═══════════════════════════════════════════════════════════════════════════════

DO $$
BEGIN
  RAISE NOTICE '';
  RAISE NOTICE '═══════════════════════════════════════════════════════════════';
  RAISE NOTICE '✅ POLÍTICAS DE STORAGE CONFIGURADAS';
  RAISE NOTICE '═══════════════════════════════════════════════════════════════';
  RAISE NOTICE '';
  RAISE NOTICE 'Políticas creadas:';
  RAISE NOTICE '  • Public read access';
  RAISE NOTICE '  • Authenticated upload';
  RAISE NOTICE '  • User update own files';
  RAISE NOTICE '  • User delete own files';
  RAISE NOTICE '';
  RAISE NOTICE 'Bucket: media (debe ser creado manualmente)';
  RAISE NOTICE 'Carpetas: messages/, portfolio/';
  RAISE NOTICE '';
  RAISE NOTICE '═══════════════════════════════════════════════════════════════';
END $$;
