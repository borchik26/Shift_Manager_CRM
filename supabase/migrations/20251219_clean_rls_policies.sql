-- Clean up conflicting RLS policies and start fresh
-- First, list all existing policies
SELECT policyname FROM pg_policies WHERE tablename = 'profiles';

-- Drop ALL existing policies
DROP POLICY IF EXISTS "Users can read own profile" ON public.profiles;
DROP POLICY IF EXISTS "Users can update own profile" ON public.profiles;
DROP POLICY IF EXISTS "Managers can read all profiles" ON public.profiles;
DROP POLICY IF EXISTS "Managers can update user status" ON public.profiles;
DROP POLICY IF EXISTS "Managers can delete users" ON public.profiles;
DROP POLICY IF EXISTS "Authenticated users can create employees" ON public.profiles;
DROP POLICY IF EXISTS "Allow managers to insert profiles" ON public.profiles;

-- Recreate clean policies
-- 1. SELECT: Users read their own profile
CREATE POLICY "select_own_profile"
  ON public.profiles
  FOR SELECT
  USING (auth.uid() = id);

-- 2. SELECT: Managers read all profiles (direct check without recursion)
CREATE POLICY "select_all_if_manager"
  ON public.profiles
  FOR SELECT
  USING (
    auth.uid() IN (
      SELECT id FROM auth.users 
      WHERE raw_user_meta_data->>'role' = 'manager'
    )
  );

-- 3. UPDATE: Users update their own profile
CREATE POLICY "update_own_profile"
  ON public.profiles
  FOR UPDATE
  USING (auth.uid() = id)
  WITH CHECK (auth.uid() = id);

-- 4. UPDATE: Managers update any profile
CREATE POLICY "update_any_if_manager"
  ON public.profiles
  FOR UPDATE
  USING (
    auth.uid() IN (
      SELECT id FROM auth.users 
      WHERE raw_user_meta_data->>'role' = 'manager'
    )
  )
  WITH CHECK (
    auth.uid() IN (
      SELECT id FROM auth.users 
      WHERE raw_user_meta_data->>'role' = 'manager'
    )
  );

-- 5. DELETE: Managers delete any profile
CREATE POLICY "delete_any_if_manager"
  ON public.profiles
  FOR DELETE
  USING (
    auth.uid() IN (
      SELECT id FROM auth.users 
      WHERE raw_user_meta_data->>'role' = 'manager'
    )
  );

-- 6. INSERT: Allow all authenticated users to insert
-- Validation happens in BEFORE INSERT trigger
CREATE POLICY "insert_if_authenticated"
  ON public.profiles
  FOR INSERT
  WITH CHECK (auth.uid() IS NOT NULL);
