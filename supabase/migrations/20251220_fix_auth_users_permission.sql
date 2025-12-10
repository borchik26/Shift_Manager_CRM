-- Fix: Use is_manager function with row_security = OFF to avoid recursion

DROP POLICY IF EXISTS "select_all_if_manager" ON public.profiles;
DROP POLICY IF EXISTS "update_any_if_manager" ON public.profiles;
DROP POLICY IF EXISTS "delete_any_if_manager" ON public.profiles;

-- Recreate is_manager with row_security = OFF
CREATE OR REPLACE FUNCTION public.is_manager(user_id uuid)
RETURNS BOOLEAN AS $$
DECLARE
  user_role text;
BEGIN
  SET LOCAL row_security = OFF;
  
  SELECT role INTO user_role
  FROM public.profiles
  WHERE id = user_id
  LIMIT 1;
  
  RETURN COALESCE(user_role = 'manager', false);
END;
$$ LANGUAGE plpgsql SECURITY DEFINER SET search_path = public;

-- SELECT: Managers can read all
CREATE POLICY "select_all_if_manager"
  ON public.profiles
  FOR SELECT
  USING (public.is_manager(auth.uid()));

-- UPDATE: Managers can update all
CREATE POLICY "update_any_if_manager"
  ON public.profiles
  FOR UPDATE
  USING (public.is_manager(auth.uid()))
  WITH CHECK (public.is_manager(auth.uid()));

-- DELETE: Managers can delete all
CREATE POLICY "delete_any_if_manager"
  ON public.profiles
  FOR DELETE
  USING (public.is_manager(auth.uid()));
