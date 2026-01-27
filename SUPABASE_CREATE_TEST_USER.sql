-- ========================================================
-- 🎸 ÓOLALE MOBILE - CREATE TEST USER (SQL)
-- ========================================================
-- Este script inserta un usuario de prueba directamente en auth.users
-- La contraseña será "123456"

INSERT INTO auth.users (
    instance_id,
    id,
    aud,
    role,
    email,
    encrypted_password,
    email_confirmed_at,
    recovery_sent_at,
    last_sign_in_at,
    raw_app_meta_data,
    raw_user_meta_data,
    created_at,
    updated_at,
    confirmation_token,
    email_change,
    email_change_token_new,
    recovery_token
) VALUES (
    '00000000-0000-0000-0000-000000000000',
    uuid_generate_v4(),
    'authenticated',
    'authenticated',
    'test@oolale.com',
    crypt('123456', gen_salt('bf')),
    NOW(),
    NOW(),
    NOW(),
    '{"provider":"email","providers":["email"]}',
    '{"full_name":"Test User","rol_principal":"musico"}',
    NOW(),
    NOW(),
    '',
    '',
    '',
    ''
);

-- Nota: El trigger 'on_auth_user_created' se encargará de crear el perfil en public.profiles automáticamente.
