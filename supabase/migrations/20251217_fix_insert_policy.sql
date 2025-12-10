-- Allow authenticated users to insert profiles
-- App-level role validation + trigger validation ensures only managers can create
DROP POLICY IF EXISTS "Managers can create profiles" ON public.profiles;
DROP POLICY IF EXISTS "Allow managers to insert profiles" ON public.profiles;
DROP POLICY IF EXISTS "Authenticated users can insert profiles" ON public.profiles;

-- Permissive: authenticated users can attempt to insert
-- Restrictive validation happens in application + before trigger
CREATE POLICY "Authenticated users can create employees"
  ON public.profiles
  FOR INSERT
  WITH CHECK (auth.uid() IS NOT NULL);

-- Create a BEFORE INSERT trigger to validate user is manager
CREATE OR REPLACE FUNCTION public.validate_employee_creator()
RETURNS TRIGGER AS $$
DECLARE
  creator_role text;
BEGIN
  -- Get the role of the user trying to insert
  SELECT role INTO creator_role
  FROM public.profiles
  WHERE id = auth.uid()
  LIMIT 1;
  
  -- Only allow if creator is a manager
  IF creator_role != 'manager' THEN
    RAISE EXCEPTION 'Only managers can create new employee profiles';
  END IF;
  
  RETURN NEW;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- Drop existing trigger if it exists
DROP TRIGGER IF EXISTS validate_employee_creator_trigger ON public.profiles;

-- Create trigger
CREATE TRIGGER validate_employee_creator_trigger
  BEFORE INSERT ON public.profiles
  FOR EACH ROW
  WHEN (NEW.role = 'employee')
  EXECUTE FUNCTION public.validate_employee_creator();
