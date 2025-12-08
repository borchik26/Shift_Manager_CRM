-- =====================================================
-- CRM Shift Manager - Row Level Security Policies
-- =====================================================
-- Implements security rules based on user roles
-- Manager: Full access to everything
-- Employee: Only their own data
-- =====================================================

-- =====================================================
-- ENABLE RLS ON ALL TABLES
-- =====================================================
ALTER TABLE public.profiles ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.shifts ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.shift_swaps ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.audit_logs ENABLE ROW LEVEL SECURITY;

-- =====================================================
-- PROFILES TABLE POLICIES
-- =====================================================

-- Manager: Full access to all profiles
CREATE POLICY "managers_full_access_profiles"
ON public.profiles
FOR ALL
USING (
  EXISTS (
    SELECT 1 FROM public.profiles
    WHERE id = auth.uid() AND role = 'manager'
  )
);

-- Employee: Can view their own profile
CREATE POLICY "employees_view_own_profile"
ON public.profiles
FOR SELECT
USING (
  id = auth.uid()
);

-- Employee: Can update their own profile (limited fields)
-- Note: Role/status changes are prevented by trigger (see below)
CREATE POLICY "employees_update_own_profile"
ON public.profiles
FOR UPDATE
USING (
  id = auth.uid()
)
WITH CHECK (
  id = auth.uid()
);

-- =====================================================
-- SHIFTS TABLE POLICIES
-- =====================================================

-- Manager: Full access to all shifts
CREATE POLICY "managers_full_access_shifts"
ON public.shifts
FOR ALL
USING (
  EXISTS (
    SELECT 1 FROM public.profiles
    WHERE id = auth.uid() AND role = 'manager'
  )
);

-- Employee: Can view their own shifts
CREATE POLICY "employees_view_own_shifts"
ON public.shifts
FOR SELECT
USING (
  employee_id = auth.uid()
);

-- Employee: Cannot create shifts (only managers can)
-- Employee: Cannot update shifts directly (use swap requests)
-- Employee: Cannot delete shifts

-- =====================================================
-- SHIFT SWAPS TABLE POLICIES
-- =====================================================

-- Manager: Full access to all swap requests
CREATE POLICY "managers_full_access_swaps"
ON public.shift_swaps
FOR ALL
USING (
  EXISTS (
    SELECT 1 FROM public.profiles
    WHERE id = auth.uid() AND role = 'manager'
  )
);

-- Employee: Can view swap requests related to them
CREATE POLICY "employees_view_related_swaps"
ON public.shift_swaps
FOR SELECT
USING (
  requester_id = auth.uid()
  OR target_employee_id = auth.uid()
  OR EXISTS (
    SELECT 1 FROM public.shifts
    WHERE id = shift_id AND employee_id = auth.uid()
  )
);

-- Employee: Can create swap requests for their own shifts
CREATE POLICY "employees_create_swap_requests"
ON public.shift_swaps
FOR INSERT
WITH CHECK (
  requester_id = auth.uid()
  AND EXISTS (
    SELECT 1 FROM public.shifts
    WHERE id = shift_id AND employee_id = auth.uid()
  )
);

-- Employee: Can update their own pending swap requests
CREATE POLICY "employees_update_own_swaps"
ON public.shift_swaps
FOR UPDATE
USING (
  requester_id = auth.uid()
  AND status = 'pending'
)
WITH CHECK (
  requester_id = auth.uid()
  AND status IN ('pending', 'rejected') -- Can only set to pending or withdraw
);

-- Employee: Can delete their own pending swap requests
CREATE POLICY "employees_delete_own_swaps"
ON public.shift_swaps
FOR DELETE
USING (
  requester_id = auth.uid()
  AND status = 'pending'
);

-- =====================================================
-- AUDIT LOGS TABLE POLICIES
-- =====================================================

-- Manager: Can view all audit logs
CREATE POLICY "managers_view_audit_logs"
ON public.audit_logs
FOR SELECT
USING (
  EXISTS (
    SELECT 1 FROM public.profiles
    WHERE id = auth.uid() AND role = 'manager'
  )
);

-- Employee: Can view audit logs related to them
CREATE POLICY "employees_view_own_audit_logs"
ON public.audit_logs
FOR SELECT
USING (
  user_id = auth.uid()
  OR record_id = auth.uid() -- For profile changes
);

-- No one can directly modify audit logs (only triggers)
-- Audit logs are INSERT-only via triggers

-- =====================================================
-- HELPER FUNCTION: Get current user role
-- =====================================================
CREATE OR REPLACE FUNCTION get_current_user_role()
RETURNS TEXT AS $$
  SELECT role FROM public.profiles WHERE id = auth.uid();
$$ LANGUAGE SQL SECURITY DEFINER;

-- =====================================================
-- COMMENTS for Documentation
-- =====================================================
COMMENT ON POLICY "managers_full_access_profiles" ON public.profiles IS 'Managers have full CRUD access to all profiles';
COMMENT ON POLICY "employees_view_own_profile" ON public.profiles IS 'Employees can only view their own profile';
COMMENT ON POLICY "employees_update_own_profile" ON public.profiles IS 'Employees can update their profile but not role/status';

COMMENT ON POLICY "managers_full_access_shifts" ON public.shifts IS 'Managers have full CRUD access to all shifts';
COMMENT ON POLICY "employees_view_own_shifts" ON public.shifts IS 'Employees can only view their own shifts';

COMMENT ON POLICY "managers_full_access_swaps" ON public.shift_swaps IS 'Managers can approve/reject swap requests';
COMMENT ON POLICY "employees_create_swap_requests" ON public.shift_swaps IS 'Employees can request to swap their own shifts';

-- =====================================================
-- TRIGGER: Prevent employees from changing own role/status
-- =====================================================
CREATE OR REPLACE FUNCTION prevent_employee_role_status_change()
RETURNS TRIGGER AS $$
DECLARE
  current_user_id UUID;
  user_role TEXT;
BEGIN
  -- Get the current authenticated user ID
  current_user_id := auth.uid();

  -- If no authenticated user (e.g., service role, superuser, migrations), allow all changes
  IF current_user_id IS NULL THEN
    RETURN NEW;
  END IF;

  -- If updating someone else's profile, allow it (RLS will handle permissions)
  IF NEW.id != current_user_id THEN
    RETURN NEW;
  END IF;

  -- Get current user's role
  SELECT role INTO user_role
  FROM public.profiles
  WHERE id = current_user_id;

  -- If user is a manager, allow all changes
  IF user_role = 'manager' THEN
    RETURN NEW;
  END IF;

  -- If user is an employee and trying to change their own role or status, block it
  IF NEW.role != OLD.role OR NEW.status != OLD.status THEN
    RAISE EXCEPTION 'Employees cannot change their own role or status';
  END IF;

  RETURN NEW;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

CREATE TRIGGER check_employee_role_status_change
  BEFORE UPDATE ON public.profiles
  FOR EACH ROW
  EXECUTE FUNCTION prevent_employee_role_status_change();
