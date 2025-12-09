-- Migration: Fix audit_logs RLS for trigger inserts
-- Date: 2025-12-09
-- Description: Allow audit triggers to insert rows into audit_logs

-- Ensure audit_logs has an insert policy so trigger functions can log changes
DROP POLICY IF EXISTS audit_logs_allow_insert ON public.audit_logs;
CREATE POLICY audit_logs_allow_insert
  ON public.audit_logs
  FOR INSERT
  WITH CHECK (true);
