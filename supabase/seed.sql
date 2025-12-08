-- =====================================================
-- Seed data for development
-- =====================================================
-- Test Manager Account
-- Email: manager@test.com
-- Password: TestPass123!
-- =====================================================

-- Create test manager user in auth.users
-- Password hash is for "TestPass123!" (bcrypt with 10 rounds)
INSERT INTO auth.users (
  id,
  email,
  encrypted_password,
  email_confirmed_at,
  phone_confirmed_at,
  raw_app_meta_data,
  raw_user_meta_data,
  aud
) VALUES (
  '6edc19cd-8e51-4b00-a492-910cd59a0cf3'::uuid,
  'manager@test.com',
  '$2a$10$PcP2BGJ68EHa3xK3xB3gn.VLuFKdj1LDdZQN4aMXaDdKdYpqLOaPi', -- TestPass123!
  now(),
  now(),
  '{"provider":"email","providers":["email"]}',
  '{"full_name":"Test Manager"}',
  'authenticated'
) ON CONFLICT (id) DO NOTHING;

-- Trigger should auto-create profile, but manually ensure it's correct
-- Wait a moment for trigger to fire, then update
UPDATE public.profiles
SET
  role = 'manager',
  status = 'active',
  full_name = 'Test Manager',
  hourly_rate = 0.00
WHERE email = 'manager@test.com';

-- If profile still doesn't exist, insert it manually
INSERT INTO public.profiles (
  id,
  email,
  full_name,
  role,
  status,
  hourly_rate
)
SELECT
  id,
  email,
  'Test Manager',
  'manager',
  'active',
  0.00
FROM auth.users
WHERE email = 'manager@test.com'
  AND NOT EXISTS (
    SELECT 1 FROM public.profiles WHERE email = 'manager@test.com'
  )
ON CONFLICT (id) DO NOTHING;

-- Verify
SELECT email, role, status FROM public.profiles WHERE email = 'manager@test.com';
