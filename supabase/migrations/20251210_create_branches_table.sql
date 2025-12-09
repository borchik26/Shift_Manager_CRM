-- Migration: Create branches table and update profiles
-- Date: 2025-12-09
-- Description: Add branches table for managing company locations and link to profiles

-- 1. Create branches table
CREATE TABLE IF NOT EXISTS public.branches (
  id UUID PRIMARY KEY DEFAULT extensions.uuid_generate_v4(),
  name TEXT NOT NULL UNIQUE,
  created_at TIMESTAMPTZ DEFAULT NOW() NOT NULL,
  updated_at TIMESTAMPTZ DEFAULT NOW() NOT NULL
);

-- 2. Add indexes
CREATE INDEX idx_branches_name ON public.branches USING btree (name);

-- 3. Add RLS policies (Row Level Security)
ALTER TABLE public.branches ENABLE ROW LEVEL SECURITY;

-- Managers have full access to branches
CREATE POLICY managers_full_access_branches
  ON public.branches
  USING (public.is_manager(auth.uid()));

-- Employees can only view branches
CREATE POLICY employees_view_branches
  ON public.branches
  FOR SELECT
  USING (true); -- All authenticated users can view

-- 4. Add trigger for auto-update updated_at
CREATE OR REPLACE TRIGGER set_updated_at_branches
  BEFORE UPDATE ON public.branches
  FOR EACH ROW
  EXECUTE FUNCTION public.update_updated_at_column();

-- 5. Add audit logging triggers
CREATE OR REPLACE TRIGGER audit_branches_update
  AFTER UPDATE ON public.branches
  FOR EACH ROW
  WHEN (OLD.* IS DISTINCT FROM NEW.*)
  EXECUTE FUNCTION public.log_update();

CREATE OR REPLACE TRIGGER audit_branches_delete
  AFTER DELETE ON public.branches
  FOR EACH ROW
  EXECUTE FUNCTION public.log_deletion();

-- 6. Add new branch_id field to profiles
ALTER TABLE public.profiles
  ADD COLUMN IF NOT EXISTS branch_id UUID REFERENCES public.branches(id) ON DELETE SET NULL;

-- 7. Create index for branch_id
CREATE INDEX IF NOT EXISTS idx_profiles_branch_id ON public.profiles USING btree (branch_id);

-- 8. Keep old branch field for backward compatibility (can be removed later)
-- ALTER TABLE public.profiles DROP COLUMN branch; -- Commented for future cleanup

-- 9. Grant permissions
GRANT ALL ON TABLE public.branches TO postgres;
GRANT ALL ON TABLE public.branches TO anon;
GRANT ALL ON TABLE public.branches TO authenticated;
GRANT ALL ON TABLE public.branches TO service_role;

-- 10. Add comments for documentation
COMMENT ON TABLE public.branches IS 'Company branches/locations';
COMMENT ON COLUMN public.branches.name IS 'Branch name (unique)';
COMMENT ON COLUMN public.profiles.branch_id IS 'Reference to branch (replaces text branch field)';
