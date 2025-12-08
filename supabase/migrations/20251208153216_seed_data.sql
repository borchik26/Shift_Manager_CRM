-- =====================================================
-- CRM Shift Manager - Seed Data (Development/Testing)
-- =====================================================
-- Creates test users for development
-- IMPORTANT: This is for LOCAL DEVELOPMENT ONLY
-- =====================================================

-- Note: In production, users will register via the app
-- and be approved by managers. This seed is only for testing.

-- =====================================================
-- SEED DATA: Test Manager
-- =====================================================
-- Email: manager@test.com
-- Password: TestPass123! (set via Supabase Studio or Auth API)

-- We cannot directly insert into auth.users via SQL in production
-- But for local development with Supabase CLI, we can use this approach:

-- For now, we'll just create profile entries
-- Users must be created via Supabase Auth signup first

-- =====================================================
-- SEED DATA: Sample Employees (for MockData compatibility)
-- =====================================================

-- This will create sample profiles that can be linked
-- to auth.users when they register with matching emails

-- Note: Since we have a trigger that creates profiles on auth.users insert,
-- we don't need to pre-create profiles here.
-- Instead, this file documents the test accounts to create.

-- =====================================================
-- TEST ACCOUNTS TO CREATE VIA SUPABASE AUTH
-- =====================================================

-- 1. Manager Account
-- Email: manager@test.com
-- Password: TestPass123!
-- After signup, manually update profile:
-- UPDATE public.profiles SET role = 'manager', status = 'active' WHERE email = 'manager@test.com';

-- 2. Employee Accounts (for testing)
-- Email: employee1@test.com, Password: TestPass123!
-- Email: employee2@test.com, Password: TestPass123!
-- Email: employee3@test.com, Password: TestPass123!
-- After signup by manager, update status:
-- UPDATE public.profiles SET status = 'active' WHERE email LIKE 'employee%@test.com';

-- =====================================================
-- HELPER: Manual Profile Update Function (Development)
-- =====================================================

CREATE OR REPLACE FUNCTION create_test_manager_if_not_exists()
RETURNS VOID AS $$
DECLARE
  manager_email TEXT := 'manager@test.com';
  manager_exists BOOLEAN;
BEGIN
  -- Check if manager already exists
  SELECT EXISTS(
    SELECT 1 FROM public.profiles WHERE email = manager_email
  ) INTO manager_exists;

  -- If manager doesn't exist, this means they haven't signed up yet
  -- We can't create them automatically due to auth.users constraints

  -- If manager exists, ensure they have correct role
  IF manager_exists THEN
    UPDATE public.profiles
    SET
      role = 'manager',
      status = 'active',
      full_name = 'Test Manager'
    WHERE email = manager_email;

    RAISE NOTICE 'Manager account updated: %', manager_email;
  ELSE
    RAISE NOTICE 'Manager account not found. Please sign up via app with: %', manager_email;
  END IF;
END;
$$ LANGUAGE plpgsql;

-- =====================================================
-- DOCUMENTATION: Setup Instructions
-- =====================================================

-- Step 1: Start local Supabase
-- supabase start

-- Step 2: Apply migrations
-- supabase db reset

-- Step 3: Open Supabase Studio
-- http://localhost:54323

-- Step 4: Create test manager via SQL Editor:
/*
-- Create auth user (in Supabase Studio SQL Editor)
INSERT INTO auth.users (
  instance_id,
  id,
  aud,
  role,
  email,
  encrypted_password,
  email_confirmed_at,
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
  gen_random_uuid(),
  'authenticated',
  'authenticated',
  'manager@test.com',
  crypt('TestPass123!', gen_salt('bf')), -- requires pgcrypto extension
  NOW(),
  '{"provider":"email","providers":["email"]}',
  '{"full_name":"Test Manager","role":"manager"}',
  NOW(),
  NOW(),
  '',
  '',
  '',
  ''
);

-- Update profile to manager
UPDATE public.profiles
SET role = 'manager', status = 'active'
WHERE email = 'manager@test.com';
*/

-- Step 5: Or use Supabase Auth API (recommended)
-- Use the app's signup flow with metadata:
-- { "full_name": "Test Manager", "role": "manager" }

-- Step 6: Manually activate the first manager via SQL:
-- UPDATE public.profiles SET status = 'active', role = 'manager' WHERE email = 'manager@test.com';

COMMENT ON FUNCTION create_test_manager_if_not_exists() IS 'Helper function to setup test manager account (development only)';
