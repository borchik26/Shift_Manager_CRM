-- Fix the trigger to disable RLS during validation
DROP TRIGGER IF EXISTS validate_employee_creator_trigger ON public.profiles;
DROP FUNCTION IF EXISTS public.validate_employee_creator();

-- Create BEFORE INSERT trigger that validates manager role
CREATE OR REPLACE FUNCTION public.validate_employee_creator()
RETURNS TRIGGER AS $$
DECLARE
  creator_role text;
BEGIN
  -- Temporarily disable RLS to check creator's role
  SET LOCAL row_security = OFF;
  
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
$$ LANGUAGE plpgsql SECURITY DEFINER SET search_path = public;

-- Create trigger for inserting employee profiles
CREATE TRIGGER validate_employee_creator_trigger
  BEFORE INSERT ON public.profiles
  FOR EACH ROW
  WHEN (NEW.role = 'employee')
  EXECUTE FUNCTION public.validate_employee_creator();
