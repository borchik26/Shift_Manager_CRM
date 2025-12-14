-- =====================================================
-- Create Test Users for Local Development
-- =====================================================
-- This script creates test auth users with confirmed emails
-- Run this after db reset to create demo accounts

-- Insert test users into auth.users
INSERT INTO auth.users (
  id,
  instance_id,
  email,
  encrypted_password,
  email_confirmed_at,
  raw_app_meta_data,
  raw_user_meta_data,
  created_at,
  updated_at,
  confirmation_token,
  role,
  aud
)
SELECT
  gen_random_uuid(),
  '00000000-0000-0000-0000-000000000000',
  email,
  crypt('TestPass123!', gen_salt('bf')),
  NOW(),
  jsonb_build_object('provider', 'email', 'providers', ARRAY['email']),
  jsonb_build_object('role', role_value, 'first_name', first_name_val, 'last_name', last_name_val),
  NOW(),
  NOW(),
  '',
  'authenticated',
  'authenticated'
FROM (VALUES
  ('manager@test.com', 'manager', 'Demo', 'Manager'),
  ('employee1@test.com', 'employee', 'Иван', 'Иванов'),
  ('employee2@test.com', 'employee', 'Мария', 'Петрова')
) AS users(email, role_value, first_name_val, last_name_val)
WHERE NOT EXISTS (
  SELECT 1 FROM auth.users WHERE auth.users.email = users.email
);

-- Insert corresponding identities
INSERT INTO auth.identities (
  id,
  user_id,
  provider_id,
  identity_data,
  provider,
  last_sign_in_at,
  created_at,
  updated_at
)
SELECT
  gen_random_uuid(),
  u.id,
  u.id::text,
  jsonb_build_object(
    'sub', u.id::text,
    'email', u.email,
    'email_verified', true
  ),
  'email',
  NOW(),
  NOW(),
  NOW()
FROM auth.users u
WHERE u.email IN ('manager@test.com', 'employee1@test.com', 'employee2@test.com')
  AND NOT EXISTS (
    SELECT 1 FROM auth.identities i WHERE i.user_id = u.id
  );

-- Success message
DO $$
BEGIN
  RAISE NOTICE 'Test users created successfully!';
  RAISE NOTICE 'Credentials:';
  RAISE NOTICE '  manager@test.com / TestPass123!';
  RAISE NOTICE '  employee1@test.com / TestPass123!';
  RAISE NOTICE '  employee2@test.com / TestPass123!';
END $$;
