-- Migration: Create positions table
-- Date: 2025-12-09
-- Description: Add positions (job titles) table with hourly rate and RLS policies

-- 1. Create positions table
CREATE TABLE IF NOT EXISTS public.positions (
  id UUID PRIMARY KEY DEFAULT extensions.uuid_generate_v4(),
  name TEXT NOT NULL UNIQUE,
  hourly_rate NUMERIC NOT NULL,
  created_at TIMESTAMPTZ DEFAULT NOW() NOT NULL,
  updated_at TIMESTAMPTZ DEFAULT NOW() NOT NULL
);

-- 2. Indexes
CREATE INDEX IF NOT EXISTS idx_positions_name ON public.positions USING btree (name);

-- 3. Enable RLS
ALTER TABLE public.positions ENABLE ROW LEVEL SECURITY;

-- Managers have full access to positions
DROP POLICY IF EXISTS managers_full_access_positions ON public.positions;
CREATE POLICY managers_full_access_positions
  ON public.positions
  USING (public.is_manager(auth.uid()));

-- Employees can view positions
DROP POLICY IF EXISTS employees_view_positions ON public.positions;
CREATE POLICY employees_view_positions
  ON public.positions
  FOR SELECT
  USING (true);

-- 4. Trigger to auto-update updated_at
CREATE OR REPLACE TRIGGER set_updated_at_positions
  BEFORE UPDATE ON public.positions
  FOR EACH ROW
  EXECUTE FUNCTION public.update_updated_at_column();

-- 5. Audit logging triggers
CREATE OR REPLACE TRIGGER audit_positions_update
  AFTER UPDATE ON public.positions
  FOR EACH ROW
  WHEN (OLD.* IS DISTINCT FROM NEW.*)
  EXECUTE FUNCTION public.log_update();

CREATE OR REPLACE TRIGGER audit_positions_delete
  AFTER DELETE ON public.positions
  FOR EACH ROW
  EXECUTE FUNCTION public.log_deletion();

-- 6. Grants
GRANT ALL ON TABLE public.positions TO postgres;
GRANT ALL ON TABLE public.positions TO anon;
GRANT ALL ON TABLE public.positions TO authenticated;
GRANT ALL ON TABLE public.positions TO service_role;

-- 7. Comments
COMMENT ON TABLE public.positions IS 'Job positions with hourly rates';
COMMENT ON COLUMN public.positions.hourly_rate IS 'Hourly rate in base currency';
