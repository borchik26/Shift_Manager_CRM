-- =====================================================
-- Demo Seed Data for Development
-- =====================================================

-- Insert demo branches
INSERT INTO public.branches (id, name) VALUES
  ('11111111-1111-1111-1111-111111111111', 'Центральный офис'),
  ('22222222-2222-2222-2222-222222222222', 'Филиал "Север"'),
  ('33333333-3333-3333-3333-333333333333', 'Филиал "Юг"')
ON CONFLICT (id) DO NOTHING;

-- Insert demo positions
INSERT INTO public.positions (id, name, hourly_rate) VALUES
  ('aaaaaaaa-aaaa-aaaa-aaaa-aaaaaaaaaaaa', 'Менеджер', 500.00),
  ('bbbbbbbb-bbbb-bbbb-bbbb-bbbbbbbbbbbb', 'Продавец', 300.00),
  ('cccccccc-cccc-cccc-cccc-cccccccccccc', 'Кассир', 250.00),
  ('dddddddd-dddd-dddd-dddd-dddddddddddd', 'Администратор', 400.00),
  ('eeeeeeee-eeee-eeee-eeee-eeeeeeeeeeee', 'Старший продавец', 350.00)
ON CONFLICT (id) DO NOTHING;

-- =====================================================
-- Demo Users (for testing purposes)
-- =====================================================
-- NOTE: In production, users should be created via Supabase Auth API
--
-- Demo accounts:
-- 1. Manager: manager@test.com / TestPass123!
-- 2. Employee 1: employee1@test.com / TestPass123!
-- 3. Employee 2: employee2@test.com / TestPass123!
--
-- To create these users in LOCAL development, use Supabase Studio or:
--   supabase auth users create manager@test.com --password TestPass123!
--
-- For REMOTE production, use Admin API:
--   curl -X POST "YOUR_SUPABASE_URL/auth/v1/admin/users" \
--     -H "apikey: SERVICE_ROLE_KEY" \
--     -H "Content-Type: application/json" \
--     -d '{"email":"manager@test.com","password":"TestPass123!","email_confirm":true,"user_metadata":{"role":"manager","full_name":"Demo Manager"}}'
-- =====================================================

-- Insert demo profiles (only if auth.users exist)
-- These will be linked to actual auth users created separately
DO $$
DECLARE
  manager_id UUID;
  employee1_id UUID;
  employee2_id UUID;
BEGIN
  -- Try to find existing auth users
  SELECT id INTO manager_id FROM auth.users WHERE email = 'manager@test.com' LIMIT 1;
  SELECT id INTO employee1_id FROM auth.users WHERE email = 'employee1@test.com' LIMIT 1;
  SELECT id INTO employee2_id FROM auth.users WHERE email = 'employee2@test.com' LIMIT 1;

  -- Only insert profiles if auth users exist
  IF manager_id IS NOT NULL THEN
    INSERT INTO public.profiles (id, email, first_name, last_name, role, status, branch_id)
    VALUES (manager_id, 'manager@test.com', 'Demo', 'Manager', 'manager', 'active', '11111111-1111-1111-1111-111111111111')
    ON CONFLICT (id) DO UPDATE SET
      first_name = EXCLUDED.first_name,
      last_name = EXCLUDED.last_name,
      role = EXCLUDED.role,
      status = EXCLUDED.status,
      branch_id = EXCLUDED.branch_id;
  END IF;

  IF employee1_id IS NOT NULL THEN
    INSERT INTO public.profiles (id, email, first_name, last_name, role, status, branch_id)
    VALUES (employee1_id, 'employee1@test.com', 'Иван', 'Иванов', 'employee', 'active', '11111111-1111-1111-1111-111111111111')
    ON CONFLICT (id) DO UPDATE SET
      first_name = EXCLUDED.first_name,
      last_name = EXCLUDED.last_name,
      role = EXCLUDED.role,
      status = EXCLUDED.status,
      branch_id = EXCLUDED.branch_id;
  END IF;

  IF employee2_id IS NOT NULL THEN
    INSERT INTO public.profiles (id, email, first_name, last_name, role, status, branch_id)
    VALUES (employee2_id, 'employee2@test.com', 'Мария', 'Петрова', 'employee', 'active', '22222222-2222-2222-2222-222222222222')
    ON CONFLICT (id) DO UPDATE SET
      first_name = EXCLUDED.first_name,
      last_name = EXCLUDED.last_name,
      role = EXCLUDED.role,
      status = EXCLUDED.status,
      branch_id = EXCLUDED.branch_id;
  END IF;

  -- Insert demo shifts only if employees exist
  IF employee1_id IS NOT NULL THEN
    INSERT INTO public.shifts (employee_id, start_time, end_time, role_title, location, status, hourly_rate)
    VALUES
      (employee1_id, NOW() + INTERVAL '1 day', NOW() + INTERVAL '1 day 8 hours', 'Продавец', 'Центральный офис', 'confirmed', 300.00),
      (employee1_id, NOW() + INTERVAL '2 days', NOW() + INTERVAL '2 days 8 hours', 'Продавец', 'Центральный офис', 'confirmed', 300.00)
    ON CONFLICT DO NOTHING;
  END IF;

  IF employee2_id IS NOT NULL THEN
    INSERT INTO public.shifts (employee_id, start_time, end_time, role_title, location, status, hourly_rate, is_night_shift)
    VALUES
      (employee2_id, NOW() + INTERVAL '1 day', NOW() + INTERVAL '1 day 12 hours', 'Старший продавец', 'Филиал "Север"', 'confirmed', 350.00, false),
      (employee2_id, NOW() + INTERVAL '3 days 20 hours', NOW() + INTERVAL '4 days 4 hours', 'Старший продавец', 'Филиал "Север"', 'confirmed', 350.00, true)
    ON CONFLICT DO NOTHING;
  END IF;

END $$;

-- Success message
DO $$
BEGIN
  RAISE NOTICE 'Demo seed data has been inserted successfully!';
  RAISE NOTICE 'If you need to create test users, use Supabase Studio or CLI';
END $$;
