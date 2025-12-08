-- =====================================================
-- CRM Shift Manager - Initial Database Schema
-- =====================================================
-- Based on plan.mdc (-B0? 4: Supabase Integration)
-- =====================================================

-- Enable UUID extension
CREATE EXTENSION IF NOT EXISTS "uuid-ossp";

-- =====================================================
-- 1. PROFILES TABLE (extends auth.users)
-- =====================================================
CREATE TABLE public.profiles (
  id UUID REFERENCES auth.users ON DELETE CASCADE PRIMARY KEY,
  email TEXT UNIQUE NOT NULL,
  full_name TEXT NOT NULL,
  role TEXT CHECK (role IN ('manager', 'employee')) DEFAULT 'employee' NOT NULL,
  status TEXT CHECK (status IN ('pending', 'active', 'blocked')) DEFAULT 'pending' NOT NULL,
  hourly_rate NUMERIC(10, 2) DEFAULT 0 NOT NULL,
  avatar_url TEXT,
  phone TEXT,
  address TEXT,
  branch TEXT,
  hire_date TIMESTAMPTZ DEFAULT NOW(),
  created_at TIMESTAMPTZ DEFAULT NOW() NOT NULL,
  updated_at TIMESTAMPTZ DEFAULT NOW() NOT NULL
);

-- =====================================================
-- 2. SHIFTS TABLE
-- =====================================================
CREATE TABLE public.shifts (
  id UUID DEFAULT uuid_generate_v4() PRIMARY KEY,
  employee_id UUID REFERENCES public.profiles(id) ON DELETE CASCADE NOT NULL,
  start_time TIMESTAMPTZ NOT NULL,
  end_time TIMESTAMPTZ NOT NULL,
  role_title TEXT NOT NULL, -- >;6=>ABL 2 :>=:@5B=>9 A<5=5
  location TEXT, -- $8;80;
  notes TEXT,
  status TEXT CHECK (status IN ('confirmed', 'swap_requested')) DEFAULT 'confirmed' NOT NULL,
  created_at TIMESTAMPTZ DEFAULT NOW() NOT NULL,
  updated_at TIMESTAMPTZ DEFAULT NOW() NOT NULL,

  -- Constraint: end_time must be after start_time
  CONSTRAINT valid_time_range CHECK (end_time > start_time)
);

-- =====================================================
-- 3. SHIFT SWAPS TABLE (>1<5= A<5=0<8)
-- =====================================================
CREATE TABLE public.shift_swaps (
  id UUID DEFAULT uuid_generate_v4() PRIMARY KEY,
  requester_id UUID REFERENCES public.profiles(id) ON DELETE CASCADE NOT NULL, -- B> E>G5B >B40BL
  shift_id UUID REFERENCES public.shifts(id) ON DELETE CASCADE NOT NULL, -- 0:CN A<5=C
  target_employee_id UUID REFERENCES public.profiles(id) ON DELETE SET NULL, -- ><C (>?F8>=0;L=>)
  manager_comment TEXT,
  status TEXT CHECK (status IN ('pending', 'approved', 'rejected')) DEFAULT 'pending' NOT NULL,
  created_at TIMESTAMPTZ DEFAULT NOW() NOT NULL,
  updated_at TIMESTAMPTZ DEFAULT NOW() NOT NULL
);

-- =====================================================
-- 4. AUDIT LOGS TABLE (8AB>@8O 459AB289)
-- =====================================================
CREATE TABLE public.audit_logs (
  id UUID DEFAULT uuid_generate_v4() PRIMARY KEY,
  user_id UUID REFERENCES auth.users(id) ON DELETE SET NULL, -- B> A45;0;
  action TEXT NOT NULL, -- 'CREATE', 'UPDATE', 'DELETE'
  table_name TEXT NOT NULL,
  record_id UUID,
  old_data JSONB, -- !>E@0=O5< A;5?>: 40==KE 4> 87<5=5=8O
  new_data JSONB, -- !>E@0=O5< =>2K5 40==K5
  created_at TIMESTAMPTZ DEFAULT NOW() NOT NULL
);

-- =====================================================
-- INDEXES for Performance
-- =====================================================

-- Profiles
CREATE INDEX idx_profiles_role ON public.profiles(role);
CREATE INDEX idx_profiles_status ON public.profiles(status);
CREATE INDEX idx_profiles_email ON public.profiles(email);

-- Shifts
CREATE INDEX idx_shifts_employee_id ON public.shifts(employee_id);
CREATE INDEX idx_shifts_start_time ON public.shifts(start_time);
CREATE INDEX idx_shifts_status ON public.shifts(status);
CREATE INDEX idx_shifts_location ON public.shifts(location);

-- Shift Swaps
CREATE INDEX idx_shift_swaps_requester_id ON public.shift_swaps(requester_id);
CREATE INDEX idx_shift_swaps_shift_id ON public.shift_swaps(shift_id);
CREATE INDEX idx_shift_swaps_status ON public.shift_swaps(status);

-- Audit Logs
CREATE INDEX idx_audit_logs_user_id ON public.audit_logs(user_id);
CREATE INDEX idx_audit_logs_table_name ON public.audit_logs(table_name);
CREATE INDEX idx_audit_logs_created_at ON public.audit_logs(created_at);

-- =====================================================
-- FUNCTIONS & TRIGGERS
-- =====================================================

-- Function: Update updated_at timestamp
CREATE OR REPLACE FUNCTION update_updated_at_column()
RETURNS TRIGGER AS $$
BEGIN
  NEW.updated_at = NOW();
  RETURN NEW;
END;
$$ LANGUAGE plpgsql;

-- Trigger: Auto-update updated_at for profiles
CREATE TRIGGER set_updated_at_profiles
BEFORE UPDATE ON public.profiles
FOR EACH ROW
EXECUTE FUNCTION update_updated_at_column();

-- Trigger: Auto-update updated_at for shifts
CREATE TRIGGER set_updated_at_shifts
BEFORE UPDATE ON public.shifts
FOR EACH ROW
EXECUTE FUNCTION update_updated_at_column();

-- Trigger: Auto-update updated_at for shift_swaps
CREATE TRIGGER set_updated_at_shift_swaps
BEFORE UPDATE ON public.shift_swaps
FOR EACH ROW
EXECUTE FUNCTION update_updated_at_column();

-- =====================================================
-- CRITICAL BUSINESS LOGIC: Shift Overlap Validation
-- =====================================================
-- Prevents creating overlapping shifts for the same employee
CREATE OR REPLACE FUNCTION check_shift_overlap()
RETURNS TRIGGER AS $$
BEGIN
  -- Check if there's an overlapping shift for this employee
  IF EXISTS (
    SELECT 1
    FROM public.shifts
    WHERE employee_id = NEW.employee_id
      AND id != COALESCE(NEW.id, '00000000-0000-0000-0000-000000000000'::UUID) -- Exclude self on update
      AND tstzrange(start_time, end_time) && tstzrange(NEW.start_time, NEW.end_time)
  ) THEN
    RAISE EXCEPTION 'Shift overlaps with an existing shift for this employee';
  END IF;

  RETURN NEW;
END;
$$ LANGUAGE plpgsql;

-- Trigger: Validate shift overlap on INSERT and UPDATE
CREATE TRIGGER prevent_shift_overlap
BEFORE INSERT OR UPDATE ON public.shifts
FOR EACH ROW
EXECUTE FUNCTION check_shift_overlap();

-- =====================================================
-- AUDIT TRIGGERS (02B><0B8G5A:>5 ;>38@>20=85)
-- =====================================================

-- Function: Log deletions to audit_logs
CREATE OR REPLACE FUNCTION log_deletion()
RETURNS TRIGGER AS $$
BEGIN
  INSERT INTO public.audit_logs (
    user_id,
    action,
    table_name,
    record_id,
    old_data
  ) VALUES (
    auth.uid(), -- Current user ID
    'DELETE',
    TG_TABLE_NAME,
    OLD.id,
    row_to_json(OLD)::JSONB
  );

  RETURN OLD;
END;
$$ LANGUAGE plpgsql;

-- Function: Log updates to audit_logs
CREATE OR REPLACE FUNCTION log_update()
RETURNS TRIGGER AS $$
BEGIN
  INSERT INTO public.audit_logs (
    user_id,
    action,
    table_name,
    record_id,
    old_data,
    new_data
  ) VALUES (
    auth.uid(),
    'UPDATE',
    TG_TABLE_NAME,
    NEW.id,
    row_to_json(OLD)::JSONB,
    row_to_json(NEW)::JSONB
  );

  RETURN NEW;
END;
$$ LANGUAGE plpgsql;

-- Audit Triggers for Shifts
CREATE TRIGGER audit_shifts_delete
AFTER DELETE ON public.shifts
FOR EACH ROW
EXECUTE FUNCTION log_deletion();

CREATE TRIGGER audit_shifts_update
AFTER UPDATE ON public.shifts
FOR EACH ROW
WHEN (OLD.* IS DISTINCT FROM NEW.*)
EXECUTE FUNCTION log_update();

-- Audit Triggers for Profiles
CREATE TRIGGER audit_profiles_delete
AFTER DELETE ON public.profiles
FOR EACH ROW
EXECUTE FUNCTION log_deletion();

CREATE TRIGGER audit_profiles_update
AFTER UPDATE ON public.profiles
FOR EACH ROW
WHEN (OLD.* IS DISTINCT FROM NEW.*)
EXECUTE FUNCTION log_update();

-- =====================================================
-- HELPER FUNCTION: Handle new user registration
-- =====================================================
-- Auto-create profile when user signs up via auth.users
CREATE OR REPLACE FUNCTION handle_new_user()
RETURNS TRIGGER AS $$
BEGIN
  INSERT INTO public.profiles (id, email, full_name, role, status)
  VALUES (
    NEW.id,
    NEW.email,
    COALESCE(NEW.raw_user_meta_data->>'full_name', 'New User'),
    COALESCE(NEW.raw_user_meta_data->>'role', 'employee'),
    'pending' -- !>B@C4=8: 645B ?>4B25@645=8O <5=5465@0
  );

  RETURN NEW;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- Trigger: Auto-create profile on signup
CREATE TRIGGER on_auth_user_created
AFTER INSERT ON auth.users
FOR EACH ROW
EXECUTE FUNCTION handle_new_user();

-- =====================================================
-- COMMENTS for Documentation
-- =====================================================
COMMENT ON TABLE public.profiles IS 'User profiles extending auth.users';
COMMENT ON TABLE public.shifts IS 'Employee work shifts with validation';
COMMENT ON TABLE public.shift_swaps IS 'Shift exchange requests between employees';
COMMENT ON TABLE public.audit_logs IS 'Audit trail for all data modifications';

COMMENT ON COLUMN public.profiles.status IS 'pending = waiting manager approval, active = can work, blocked = suspended';
COMMENT ON COLUMN public.shifts.status IS 'confirmed = normal shift, swap_requested = employee wants to swap';
COMMENT ON FUNCTION check_shift_overlap() IS 'Prevents creating overlapping shifts for the same employee';
COMMENT ON FUNCTION handle_new_user() IS 'Auto-creates profile with pending status when user signs up';
