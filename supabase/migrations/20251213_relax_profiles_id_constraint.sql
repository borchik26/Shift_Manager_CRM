-- Migration: relax profiles.id FK to allow creating employee records without auth.users entry
-- Date: 2025-12-09
-- Description: drop FK profiles_id_fkey and add default uuid_generate_v4() on profiles.id

-- 1) Drop FK to auth.users if exists
DO $$
BEGIN
  IF EXISTS (
    SELECT 1
    FROM information_schema.table_constraints tc
    WHERE tc.constraint_name = 'profiles_id_fkey'
      AND tc.table_name = 'profiles'
  ) THEN
    ALTER TABLE public.profiles
      DROP CONSTRAINT profiles_id_fkey;
  END IF;
END $$;

-- 2) Ensure id has default uuid_generate_v4()
ALTER TABLE public.profiles
  ALTER COLUMN id SET DEFAULT extensions.uuid_generate_v4();
