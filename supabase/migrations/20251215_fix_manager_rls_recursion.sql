-- Fix infinite recursion in manager RLS policy by using auth metadata
-- Drop the problematic policy
DROP POLICY IF EXISTS "Managers can read all profiles" ON public.profiles;

-- Create a helper function to check if user is manager (SECURITY DEFINER to avoid recursion)
CREATE OR REPLACE FUNCTION public.is_manager(user_id uuid)
RETURNS BOOLEAN AS $$
DECLARE
  user_role text;
BEGIN
  -- Get role from auth.users metadata (no RLS on auth.users itself)
  SELECT COALESCE(raw_user_meta_data->>'role', 'employee')
  INTO user_role
  FROM auth.users
  WHERE id = user_id;
  
  RETURN user_role = 'manager';
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- Create new policy for managers that uses the helper function
CREATE POLICY "Managers can read all profiles"
  ON public.profiles
  FOR SELECT
  USING (
    public.is_manager(auth.uid())
  );

-- Allow managers to update user status
CREATE POLICY "Managers can update user status"
  ON public.profiles
  FOR UPDATE
  USING (
    public.is_manager(auth.uid())
  )
  WITH CHECK (
    public.is_manager(auth.uid())
  );

-- Allow managers to delete users
CREATE POLICY "Managers can delete users"
  ON public.profiles
  FOR DELETE
  USING (
    public.is_manager(auth.uid())
  );
