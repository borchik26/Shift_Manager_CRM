-- =====================================================
-- Fix Schema Inconsistencies
-- =====================================================
-- Adds missing fields to match Flutter models

-- 1. Add position field to profiles
ALTER TABLE public.profiles
ADD COLUMN position TEXT DEFAULT 'Сотрудник' NOT NULL;

COMMENT ON COLUMN public.profiles.position IS 'Employee position/job title';

-- 2. Add missing fields to shifts
ALTER TABLE public.shifts
ADD COLUMN is_night_shift BOOLEAN DEFAULT FALSE NOT NULL,
ADD COLUMN employee_preferences TEXT,
ADD COLUMN hourly_rate NUMERIC(10, 2) DEFAULT 0;

COMMENT ON COLUMN public.shifts.is_night_shift IS 'Indicates if this is a night shift';
COMMENT ON COLUMN public.shifts.employee_preferences IS 'Employee wishes/preferences for this shift';
COMMENT ON COLUMN public.shifts.hourly_rate IS 'Hourly rate for this specific shift (can override profile rate)';

-- 3. Update index for position
CREATE INDEX idx_profiles_position ON public.profiles(position);
