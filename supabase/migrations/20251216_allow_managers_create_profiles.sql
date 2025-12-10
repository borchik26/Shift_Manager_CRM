-- Allow managers to insert new profiles (create new employees)
DROP POLICY IF EXISTS "Managers can create profiles" ON public.profiles;

CREATE POLICY "Managers can create profiles"
  ON public.profiles
  FOR INSERT
  WITH CHECK (
    public.is_manager(auth.uid())
  );

-- Ensure the is_manager function exists
-- (it should exist from migration 20251215_fix_manager_rls_recursion.sql)
