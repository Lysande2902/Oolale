-- ============================================
-- CREAR USUARIOS DE PRUEBA - MÉTODO MANUAL
-- ============================================
-- CONTRASEÑA PARA TODOS: Test123456!
-- ============================================

-- OPCIÓN 1: Crear usuarios manualmente en Supabase Dashboard
-- Ve a: Authentication → Users → Add User
-- Crea estos 8 usuarios con contraseña: Test123456!

/*
USUARIOS A CREAR:

1. maria.garcia@test.com
2. carlos.mendoza@test.com
3. ana.martinez@test.com
4. luis.hernandez@test.com
5. sofia.ramirez@test.com
6. roberto.sanchez@test.com
7. diana.lopez@test.com
8. miguel.torres@test.com

CONTRASEÑA PARA TODOS: Test123456!
*/

-- ============================================
-- OPCIÓN 2: Usar la API de Supabase (Recomendado)
-- ============================================
-- Si tienes acceso a la API, puedes usar este código JavaScript:

/*
// Ejecutar en la consola del navegador o en Node.js
const { createClient } = require('@supabase/supabase-js');

const supabase = createClient(
  'TU_SUPABASE_URL',
  'TU_SERVICE_ROLE_KEY' // ¡IMPORTANTE: Usar service_role key, no anon key!
);

const usuarios = [
  'maria.garcia@test.com',
  'carlos.mendoza@test.com',
  'ana.martinez@test.com',
  'luis.hernandez@test.com',
  'sofia.ramirez@test.com',
  'roberto.sanchez@test.com',
  'diana.lopez@test.com',
  'miguel.torres@test.com'
];

async function crearUsuarios() {
  for (const email of usuarios) {
    const { data, error } = await supabase.auth.admin.createUser({
      email: email,
      password: 'Test123456!',
      email_confirm: true
    });
    
    if (error) {
      console.error(`Error creando ${email}:`, error);
    } else {
      console.log(`✅ Usuario creado: ${email}`);
    }
  }
}

crearUsuarios();
*/

-- ============================================
-- VERIFICAR USUARIOS CREADOS
-- ============================================
SELECT 
  email,
  email_confirmed_at,
  created_at
FROM auth.users 
WHERE email LIKE '%@test.com'
ORDER BY email;

-- ============================================
-- SIGUIENTE PASO
-- ============================================
-- Después de crear los usuarios, ejecuta:
-- SEED_TEST_DATA.sql
-- ============================================
