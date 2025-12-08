


SET statement_timeout = 0;
SET lock_timeout = 0;
SET idle_in_transaction_session_timeout = 0;
SET client_encoding = 'UTF8';
SET standard_conforming_strings = on;
SELECT pg_catalog.set_config('search_path', '', false);
SET check_function_bodies = false;
SET xmloption = content;
SET client_min_messages = warning;
SET row_security = off;


CREATE EXTENSION IF NOT EXISTS "pg_net" WITH SCHEMA "extensions";






COMMENT ON SCHEMA "public" IS 'standard public schema';



CREATE EXTENSION IF NOT EXISTS "pg_graphql" WITH SCHEMA "graphql";






CREATE EXTENSION IF NOT EXISTS "pg_stat_statements" WITH SCHEMA "extensions";






CREATE EXTENSION IF NOT EXISTS "pgcrypto" WITH SCHEMA "extensions";






CREATE EXTENSION IF NOT EXISTS "supabase_vault" WITH SCHEMA "vault";






CREATE EXTENSION IF NOT EXISTS "uuid-ossp" WITH SCHEMA "extensions";






CREATE OR REPLACE FUNCTION "public"."check_shift_overlap"() RETURNS "trigger"
    LANGUAGE "plpgsql"
    AS $$
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
$$;


ALTER FUNCTION "public"."check_shift_overlap"() OWNER TO "postgres";


COMMENT ON FUNCTION "public"."check_shift_overlap"() IS 'Prevents creating overlapping shifts for the same employee';



CREATE OR REPLACE FUNCTION "public"."create_test_manager_if_not_exists"() RETURNS "void"
    LANGUAGE "plpgsql"
    AS $$
DECLARE
  manager_email TEXT := 'manager@test.com';
  manager_exists BOOLEAN;
BEGIN
  -- Check if manager already exists
  SELECT EXISTS(
    SELECT 1 FROM public.profiles WHERE email = manager_email
  ) INTO manager_exists;

  -- If manager doesn't exist, this means they haven't signed up yet
  -- We can't create them automatically due to auth.users constraints

  -- If manager exists, ensure they have correct role
  IF manager_exists THEN
    UPDATE public.profiles
    SET
      role = 'manager',
      status = 'active',
      full_name = 'Test Manager'
    WHERE email = manager_email;

    RAISE NOTICE 'Manager account updated: %', manager_email;
  ELSE
    RAISE NOTICE 'Manager account not found. Please sign up via app with: %', manager_email;
  END IF;
END;
$$;


ALTER FUNCTION "public"."create_test_manager_if_not_exists"() OWNER TO "postgres";


COMMENT ON FUNCTION "public"."create_test_manager_if_not_exists"() IS 'Helper function to setup test manager account (development only)';



CREATE OR REPLACE FUNCTION "public"."get_current_user_role"() RETURNS "text"
    LANGUAGE "sql" SECURITY DEFINER
    AS $$
  SELECT role FROM public.profiles WHERE id = auth.uid();
$$;


ALTER FUNCTION "public"."get_current_user_role"() OWNER TO "postgres";


CREATE OR REPLACE FUNCTION "public"."handle_new_user"() RETURNS "trigger"
    LANGUAGE "plpgsql" SECURITY DEFINER
    AS $$
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
$$;


ALTER FUNCTION "public"."handle_new_user"() OWNER TO "postgres";


COMMENT ON FUNCTION "public"."handle_new_user"() IS 'Auto-creates profile with pending status when user signs up';



CREATE OR REPLACE FUNCTION "public"."is_manager"("user_id" "uuid") RETURNS boolean
    LANGUAGE "plpgsql" SECURITY DEFINER
    AS $$
BEGIN
  RETURN EXISTS (
    SELECT 1 FROM public.profiles
    WHERE id = user_id AND role = 'manager'
  );
END;
$$;


ALTER FUNCTION "public"."is_manager"("user_id" "uuid") OWNER TO "postgres";


CREATE OR REPLACE FUNCTION "public"."log_deletion"() RETURNS "trigger"
    LANGUAGE "plpgsql"
    AS $$
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
$$;


ALTER FUNCTION "public"."log_deletion"() OWNER TO "postgres";


CREATE OR REPLACE FUNCTION "public"."log_update"() RETURNS "trigger"
    LANGUAGE "plpgsql"
    AS $$
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
$$;


ALTER FUNCTION "public"."log_update"() OWNER TO "postgres";


CREATE OR REPLACE FUNCTION "public"."prevent_employee_role_status_change"() RETURNS "trigger"
    LANGUAGE "plpgsql" SECURITY DEFINER
    AS $$
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
$$;


ALTER FUNCTION "public"."prevent_employee_role_status_change"() OWNER TO "postgres";


CREATE OR REPLACE FUNCTION "public"."update_updated_at_column"() RETURNS "trigger"
    LANGUAGE "plpgsql"
    AS $$
BEGIN
  NEW.updated_at = NOW();
  RETURN NEW;
END;
$$;


ALTER FUNCTION "public"."update_updated_at_column"() OWNER TO "postgres";

SET default_tablespace = '';

SET default_table_access_method = "heap";


CREATE TABLE IF NOT EXISTS "public"."audit_logs" (
    "id" "uuid" DEFAULT "extensions"."uuid_generate_v4"() NOT NULL,
    "user_id" "uuid",
    "action" "text" NOT NULL,
    "table_name" "text" NOT NULL,
    "record_id" "uuid",
    "old_data" "jsonb",
    "new_data" "jsonb",
    "created_at" timestamp with time zone DEFAULT "now"() NOT NULL
);


ALTER TABLE "public"."audit_logs" OWNER TO "postgres";


COMMENT ON TABLE "public"."audit_logs" IS 'Audit trail for all data modifications';



CREATE TABLE IF NOT EXISTS "public"."profiles" (
    "id" "uuid" NOT NULL,
    "email" "text" NOT NULL,
    "full_name" "text" NOT NULL,
    "role" "text" DEFAULT 'employee'::"text" NOT NULL,
    "status" "text" DEFAULT 'pending'::"text" NOT NULL,
    "hourly_rate" numeric(10,2) DEFAULT 0 NOT NULL,
    "avatar_url" "text",
    "phone" "text",
    "address" "text",
    "branch" "text",
    "hire_date" timestamp with time zone DEFAULT "now"(),
    "created_at" timestamp with time zone DEFAULT "now"() NOT NULL,
    "updated_at" timestamp with time zone DEFAULT "now"() NOT NULL,
    "position" "text" DEFAULT 'Сотрудник'::"text" NOT NULL,
    CONSTRAINT "profiles_role_check" CHECK (("role" = ANY (ARRAY['manager'::"text", 'employee'::"text"]))),
    CONSTRAINT "profiles_status_check" CHECK (("status" = ANY (ARRAY['pending'::"text", 'active'::"text", 'blocked'::"text"])))
);


ALTER TABLE "public"."profiles" OWNER TO "postgres";


COMMENT ON TABLE "public"."profiles" IS 'User profiles extending auth.users';



COMMENT ON COLUMN "public"."profiles"."status" IS 'pending = waiting manager approval, active = can work, blocked = suspended';



COMMENT ON COLUMN "public"."profiles"."position" IS 'Employee position/job title';



CREATE TABLE IF NOT EXISTS "public"."shift_swaps" (
    "id" "uuid" DEFAULT "extensions"."uuid_generate_v4"() NOT NULL,
    "requester_id" "uuid" NOT NULL,
    "shift_id" "uuid" NOT NULL,
    "target_employee_id" "uuid",
    "manager_comment" "text",
    "status" "text" DEFAULT 'pending'::"text" NOT NULL,
    "created_at" timestamp with time zone DEFAULT "now"() NOT NULL,
    "updated_at" timestamp with time zone DEFAULT "now"() NOT NULL,
    CONSTRAINT "shift_swaps_status_check" CHECK (("status" = ANY (ARRAY['pending'::"text", 'approved'::"text", 'rejected'::"text"])))
);


ALTER TABLE "public"."shift_swaps" OWNER TO "postgres";


COMMENT ON TABLE "public"."shift_swaps" IS 'Shift exchange requests between employees';



CREATE TABLE IF NOT EXISTS "public"."shifts" (
    "id" "uuid" DEFAULT "extensions"."uuid_generate_v4"() NOT NULL,
    "employee_id" "uuid" NOT NULL,
    "start_time" timestamp with time zone NOT NULL,
    "end_time" timestamp with time zone NOT NULL,
    "role_title" "text" NOT NULL,
    "location" "text",
    "notes" "text",
    "status" "text" DEFAULT 'confirmed'::"text" NOT NULL,
    "created_at" timestamp with time zone DEFAULT "now"() NOT NULL,
    "updated_at" timestamp with time zone DEFAULT "now"() NOT NULL,
    "is_night_shift" boolean DEFAULT false NOT NULL,
    "employee_preferences" "text",
    "hourly_rate" numeric(10,2) DEFAULT 0,
    CONSTRAINT "shifts_status_check" CHECK (("status" = ANY (ARRAY['confirmed'::"text", 'swap_requested'::"text"]))),
    CONSTRAINT "valid_time_range" CHECK (("end_time" > "start_time"))
);


ALTER TABLE "public"."shifts" OWNER TO "postgres";


COMMENT ON TABLE "public"."shifts" IS 'Employee work shifts with validation';



COMMENT ON COLUMN "public"."shifts"."status" IS 'confirmed = normal shift, swap_requested = employee wants to swap';



COMMENT ON COLUMN "public"."shifts"."is_night_shift" IS 'Indicates if this is a night shift';



COMMENT ON COLUMN "public"."shifts"."employee_preferences" IS 'Employee wishes/preferences for this shift';



COMMENT ON COLUMN "public"."shifts"."hourly_rate" IS 'Hourly rate for this specific shift (can override profile rate)';



ALTER TABLE ONLY "public"."audit_logs"
    ADD CONSTRAINT "audit_logs_pkey" PRIMARY KEY ("id");



ALTER TABLE ONLY "public"."profiles"
    ADD CONSTRAINT "profiles_email_key" UNIQUE ("email");



ALTER TABLE ONLY "public"."profiles"
    ADD CONSTRAINT "profiles_pkey" PRIMARY KEY ("id");



ALTER TABLE ONLY "public"."shift_swaps"
    ADD CONSTRAINT "shift_swaps_pkey" PRIMARY KEY ("id");



ALTER TABLE ONLY "public"."shifts"
    ADD CONSTRAINT "shifts_pkey" PRIMARY KEY ("id");



CREATE INDEX "idx_audit_logs_created_at" ON "public"."audit_logs" USING "btree" ("created_at");



CREATE INDEX "idx_audit_logs_table_name" ON "public"."audit_logs" USING "btree" ("table_name");



CREATE INDEX "idx_audit_logs_user_id" ON "public"."audit_logs" USING "btree" ("user_id");



CREATE INDEX "idx_profiles_email" ON "public"."profiles" USING "btree" ("email");



CREATE INDEX "idx_profiles_position" ON "public"."profiles" USING "btree" ("position");



CREATE INDEX "idx_profiles_role" ON "public"."profiles" USING "btree" ("role");



CREATE INDEX "idx_profiles_status" ON "public"."profiles" USING "btree" ("status");



CREATE INDEX "idx_shift_swaps_requester_id" ON "public"."shift_swaps" USING "btree" ("requester_id");



CREATE INDEX "idx_shift_swaps_shift_id" ON "public"."shift_swaps" USING "btree" ("shift_id");



CREATE INDEX "idx_shift_swaps_status" ON "public"."shift_swaps" USING "btree" ("status");



CREATE INDEX "idx_shifts_employee_id" ON "public"."shifts" USING "btree" ("employee_id");



CREATE INDEX "idx_shifts_location" ON "public"."shifts" USING "btree" ("location");



CREATE INDEX "idx_shifts_start_time" ON "public"."shifts" USING "btree" ("start_time");



CREATE INDEX "idx_shifts_status" ON "public"."shifts" USING "btree" ("status");



CREATE OR REPLACE TRIGGER "audit_profiles_delete" AFTER DELETE ON "public"."profiles" FOR EACH ROW EXECUTE FUNCTION "public"."log_deletion"();



CREATE OR REPLACE TRIGGER "audit_profiles_update" AFTER UPDATE ON "public"."profiles" FOR EACH ROW WHEN (("old".* IS DISTINCT FROM "new".*)) EXECUTE FUNCTION "public"."log_update"();



CREATE OR REPLACE TRIGGER "audit_shifts_delete" AFTER DELETE ON "public"."shifts" FOR EACH ROW EXECUTE FUNCTION "public"."log_deletion"();



CREATE OR REPLACE TRIGGER "audit_shifts_update" AFTER UPDATE ON "public"."shifts" FOR EACH ROW WHEN (("old".* IS DISTINCT FROM "new".*)) EXECUTE FUNCTION "public"."log_update"();



CREATE OR REPLACE TRIGGER "check_employee_role_status_change" BEFORE UPDATE ON "public"."profiles" FOR EACH ROW EXECUTE FUNCTION "public"."prevent_employee_role_status_change"();



CREATE OR REPLACE TRIGGER "prevent_shift_overlap" BEFORE INSERT OR UPDATE ON "public"."shifts" FOR EACH ROW EXECUTE FUNCTION "public"."check_shift_overlap"();



CREATE OR REPLACE TRIGGER "set_updated_at_profiles" BEFORE UPDATE ON "public"."profiles" FOR EACH ROW EXECUTE FUNCTION "public"."update_updated_at_column"();



CREATE OR REPLACE TRIGGER "set_updated_at_shift_swaps" BEFORE UPDATE ON "public"."shift_swaps" FOR EACH ROW EXECUTE FUNCTION "public"."update_updated_at_column"();



CREATE OR REPLACE TRIGGER "set_updated_at_shifts" BEFORE UPDATE ON "public"."shifts" FOR EACH ROW EXECUTE FUNCTION "public"."update_updated_at_column"();



ALTER TABLE ONLY "public"."audit_logs"
    ADD CONSTRAINT "audit_logs_user_id_fkey" FOREIGN KEY ("user_id") REFERENCES "auth"."users"("id") ON DELETE SET NULL;



ALTER TABLE ONLY "public"."profiles"
    ADD CONSTRAINT "profiles_id_fkey" FOREIGN KEY ("id") REFERENCES "auth"."users"("id") ON DELETE CASCADE;



ALTER TABLE ONLY "public"."shift_swaps"
    ADD CONSTRAINT "shift_swaps_requester_id_fkey" FOREIGN KEY ("requester_id") REFERENCES "public"."profiles"("id") ON DELETE CASCADE;



ALTER TABLE ONLY "public"."shift_swaps"
    ADD CONSTRAINT "shift_swaps_shift_id_fkey" FOREIGN KEY ("shift_id") REFERENCES "public"."shifts"("id") ON DELETE CASCADE;



ALTER TABLE ONLY "public"."shift_swaps"
    ADD CONSTRAINT "shift_swaps_target_employee_id_fkey" FOREIGN KEY ("target_employee_id") REFERENCES "public"."profiles"("id") ON DELETE SET NULL;



ALTER TABLE ONLY "public"."shifts"
    ADD CONSTRAINT "shifts_employee_id_fkey" FOREIGN KEY ("employee_id") REFERENCES "public"."profiles"("id") ON DELETE CASCADE;



ALTER TABLE "public"."audit_logs" ENABLE ROW LEVEL SECURITY;


CREATE POLICY "employees_create_swap_requests" ON "public"."shift_swaps" FOR INSERT WITH CHECK ((("requester_id" = "auth"."uid"()) AND (EXISTS ( SELECT 1
   FROM "public"."shifts"
  WHERE (("shifts"."id" = "shift_swaps"."shift_id") AND ("shifts"."employee_id" = "auth"."uid"()))))));



COMMENT ON POLICY "employees_create_swap_requests" ON "public"."shift_swaps" IS 'Employees can request to swap their own shifts';



CREATE POLICY "employees_delete_own_swaps" ON "public"."shift_swaps" FOR DELETE USING ((("requester_id" = "auth"."uid"()) AND ("status" = 'pending'::"text")));



CREATE POLICY "employees_update_own_profile" ON "public"."profiles" FOR UPDATE USING (("id" = "auth"."uid"())) WITH CHECK (("id" = "auth"."uid"()));



COMMENT ON POLICY "employees_update_own_profile" ON "public"."profiles" IS 'Employees can update their profile but not role/status';



CREATE POLICY "employees_update_own_swaps" ON "public"."shift_swaps" FOR UPDATE USING ((("requester_id" = "auth"."uid"()) AND ("status" = 'pending'::"text"))) WITH CHECK ((("requester_id" = "auth"."uid"()) AND ("status" = ANY (ARRAY['pending'::"text", 'rejected'::"text"]))));



CREATE POLICY "employees_view_own_audit_logs" ON "public"."audit_logs" FOR SELECT USING ((("user_id" = "auth"."uid"()) OR ("record_id" = "auth"."uid"())));



CREATE POLICY "employees_view_own_profile" ON "public"."profiles" FOR SELECT USING (("id" = "auth"."uid"()));



COMMENT ON POLICY "employees_view_own_profile" ON "public"."profiles" IS 'Employees can only view their own profile';



CREATE POLICY "employees_view_own_shifts" ON "public"."shifts" FOR SELECT USING (("employee_id" = "auth"."uid"()));



COMMENT ON POLICY "employees_view_own_shifts" ON "public"."shifts" IS 'Employees can only view their own shifts';



CREATE POLICY "employees_view_related_swaps" ON "public"."shift_swaps" FOR SELECT USING ((("requester_id" = "auth"."uid"()) OR ("target_employee_id" = "auth"."uid"()) OR (EXISTS ( SELECT 1
   FROM "public"."shifts"
  WHERE (("shifts"."id" = "shift_swaps"."shift_id") AND ("shifts"."employee_id" = "auth"."uid"()))))));



CREATE POLICY "managers_full_access_profiles" ON "public"."profiles" USING ("public"."is_manager"("auth"."uid"()));



CREATE POLICY "managers_full_access_shifts" ON "public"."shifts" USING ("public"."is_manager"("auth"."uid"()));



CREATE POLICY "managers_full_access_swaps" ON "public"."shift_swaps" USING ("public"."is_manager"("auth"."uid"()));



CREATE POLICY "managers_view_audit_logs" ON "public"."audit_logs" FOR SELECT USING ("public"."is_manager"("auth"."uid"()));



ALTER TABLE "public"."profiles" ENABLE ROW LEVEL SECURITY;


ALTER TABLE "public"."shift_swaps" ENABLE ROW LEVEL SECURITY;


ALTER TABLE "public"."shifts" ENABLE ROW LEVEL SECURITY;




ALTER PUBLICATION "supabase_realtime" OWNER TO "postgres";





GRANT USAGE ON SCHEMA "public" TO "postgres";
GRANT USAGE ON SCHEMA "public" TO "anon";
GRANT USAGE ON SCHEMA "public" TO "authenticated";
GRANT USAGE ON SCHEMA "public" TO "service_role";































































































































































GRANT ALL ON FUNCTION "public"."check_shift_overlap"() TO "anon";
GRANT ALL ON FUNCTION "public"."check_shift_overlap"() TO "authenticated";
GRANT ALL ON FUNCTION "public"."check_shift_overlap"() TO "service_role";



GRANT ALL ON FUNCTION "public"."create_test_manager_if_not_exists"() TO "anon";
GRANT ALL ON FUNCTION "public"."create_test_manager_if_not_exists"() TO "authenticated";
GRANT ALL ON FUNCTION "public"."create_test_manager_if_not_exists"() TO "service_role";



GRANT ALL ON FUNCTION "public"."get_current_user_role"() TO "anon";
GRANT ALL ON FUNCTION "public"."get_current_user_role"() TO "authenticated";
GRANT ALL ON FUNCTION "public"."get_current_user_role"() TO "service_role";



GRANT ALL ON FUNCTION "public"."handle_new_user"() TO "anon";
GRANT ALL ON FUNCTION "public"."handle_new_user"() TO "authenticated";
GRANT ALL ON FUNCTION "public"."handle_new_user"() TO "service_role";



GRANT ALL ON FUNCTION "public"."is_manager"("user_id" "uuid") TO "anon";
GRANT ALL ON FUNCTION "public"."is_manager"("user_id" "uuid") TO "authenticated";
GRANT ALL ON FUNCTION "public"."is_manager"("user_id" "uuid") TO "service_role";



GRANT ALL ON FUNCTION "public"."log_deletion"() TO "anon";
GRANT ALL ON FUNCTION "public"."log_deletion"() TO "authenticated";
GRANT ALL ON FUNCTION "public"."log_deletion"() TO "service_role";



GRANT ALL ON FUNCTION "public"."log_update"() TO "anon";
GRANT ALL ON FUNCTION "public"."log_update"() TO "authenticated";
GRANT ALL ON FUNCTION "public"."log_update"() TO "service_role";



GRANT ALL ON FUNCTION "public"."prevent_employee_role_status_change"() TO "anon";
GRANT ALL ON FUNCTION "public"."prevent_employee_role_status_change"() TO "authenticated";
GRANT ALL ON FUNCTION "public"."prevent_employee_role_status_change"() TO "service_role";



GRANT ALL ON FUNCTION "public"."update_updated_at_column"() TO "anon";
GRANT ALL ON FUNCTION "public"."update_updated_at_column"() TO "authenticated";
GRANT ALL ON FUNCTION "public"."update_updated_at_column"() TO "service_role";


















GRANT ALL ON TABLE "public"."audit_logs" TO "anon";
GRANT ALL ON TABLE "public"."audit_logs" TO "authenticated";
GRANT ALL ON TABLE "public"."audit_logs" TO "service_role";



GRANT ALL ON TABLE "public"."profiles" TO "anon";
GRANT ALL ON TABLE "public"."profiles" TO "authenticated";
GRANT ALL ON TABLE "public"."profiles" TO "service_role";



GRANT ALL ON TABLE "public"."shift_swaps" TO "anon";
GRANT ALL ON TABLE "public"."shift_swaps" TO "authenticated";
GRANT ALL ON TABLE "public"."shift_swaps" TO "service_role";



GRANT ALL ON TABLE "public"."shifts" TO "anon";
GRANT ALL ON TABLE "public"."shifts" TO "authenticated";
GRANT ALL ON TABLE "public"."shifts" TO "service_role";









ALTER DEFAULT PRIVILEGES FOR ROLE "postgres" IN SCHEMA "public" GRANT ALL ON SEQUENCES TO "postgres";
ALTER DEFAULT PRIVILEGES FOR ROLE "postgres" IN SCHEMA "public" GRANT ALL ON SEQUENCES TO "anon";
ALTER DEFAULT PRIVILEGES FOR ROLE "postgres" IN SCHEMA "public" GRANT ALL ON SEQUENCES TO "authenticated";
ALTER DEFAULT PRIVILEGES FOR ROLE "postgres" IN SCHEMA "public" GRANT ALL ON SEQUENCES TO "service_role";






ALTER DEFAULT PRIVILEGES FOR ROLE "postgres" IN SCHEMA "public" GRANT ALL ON FUNCTIONS TO "postgres";
ALTER DEFAULT PRIVILEGES FOR ROLE "postgres" IN SCHEMA "public" GRANT ALL ON FUNCTIONS TO "anon";
ALTER DEFAULT PRIVILEGES FOR ROLE "postgres" IN SCHEMA "public" GRANT ALL ON FUNCTIONS TO "authenticated";
ALTER DEFAULT PRIVILEGES FOR ROLE "postgres" IN SCHEMA "public" GRANT ALL ON FUNCTIONS TO "service_role";






ALTER DEFAULT PRIVILEGES FOR ROLE "postgres" IN SCHEMA "public" GRANT ALL ON TABLES TO "postgres";
ALTER DEFAULT PRIVILEGES FOR ROLE "postgres" IN SCHEMA "public" GRANT ALL ON TABLES TO "anon";
ALTER DEFAULT PRIVILEGES FOR ROLE "postgres" IN SCHEMA "public" GRANT ALL ON TABLES TO "authenticated";
ALTER DEFAULT PRIVILEGES FOR ROLE "postgres" IN SCHEMA "public" GRANT ALL ON TABLES TO "service_role";
































--
-- Dumped schema changes for auth and storage
--

CREATE OR REPLACE TRIGGER "on_auth_user_created" AFTER INSERT ON "auth"."users" FOR EACH ROW EXECUTE FUNCTION "public"."handle_new_user"();



