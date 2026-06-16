-- ============================================
-- Manual Fix: RLS + Remaining Compatibility
-- ============================================
-- Run in Supabase SQL Editor after manual_fix_checkout_payment.sql
-- ============================================

BEGIN;

-- 1) Add legacy payment columns used by some mobile service paths
ALTER TABLE public.payments
  ADD COLUMN IF NOT EXISTS provider VARCHAR(50),
  ADD COLUMN IF NOT EXISTS transaction_id VARCHAR(255);

-- 2) Keep aliases synchronized where possible
UPDATE public.payments
SET
  provider = COALESCE(provider, method, payment_method),
  transaction_id = COALESCE(transaction_id, transaction_ref, provider_transaction_id)
WHERE provider IS NULL OR transaction_id IS NULL;

-- 3) Ensure order_status_history accepts both old/new field names
ALTER TABLE public.order_status_history
  ADD COLUMN IF NOT EXISTS note TEXT;

UPDATE public.order_status_history
SET note = COALESCE(note, notes)
WHERE note IS NULL;

-- 4) Orders policies for checkout via backend/service-role and user reads
DROP POLICY IF EXISTS "Users can create own orders" ON public.orders;
CREATE POLICY "Users can create own orders"
  ON public.orders FOR INSERT
  WITH CHECK (
    auth.uid() = buyer_id
    OR auth.role() = 'service_role'
  );

DROP POLICY IF EXISTS "Users can update own orders" ON public.orders;
CREATE POLICY "Users can update own orders"
  ON public.orders FOR UPDATE
  USING (
    auth.uid() = buyer_id
    OR auth.role() = 'service_role'
  );

DROP POLICY IF EXISTS "Service role can manage orders" ON public.orders;
CREATE POLICY "Service role can manage orders"
  ON public.orders FOR ALL
  USING (auth.role() = 'service_role')
  WITH CHECK (auth.role() = 'service_role');

-- 5) Order items policies for create/read via backend/service-role
DROP POLICY IF EXISTS "Users can create own order items" ON public.order_items;
CREATE POLICY "Users can create own order items"
  ON public.order_items FOR INSERT
  WITH CHECK (
    auth.uid() = buyer_id
    OR auth.uid() = farmer_id
    OR auth.role() = 'service_role'
  );

DROP POLICY IF EXISTS "Users can view own order items" ON public.order_items;
CREATE POLICY "Users can view own order items"
  ON public.order_items FOR SELECT
  USING (
    auth.uid() = buyer_id
    OR auth.uid() = farmer_id
    OR auth.role() = 'service_role'
  );

DROP POLICY IF EXISTS "Service role can manage order items" ON public.order_items;
CREATE POLICY "Service role can manage order items"
  ON public.order_items FOR ALL
  USING (auth.role() = 'service_role')
  WITH CHECK (auth.role() = 'service_role');

-- 6) Notifications + Payments + Notification Preferences:
--    reset policies to remove hidden restrictive leftovers
DO $$
DECLARE
  p RECORD;
BEGIN
  FOR p IN
    SELECT schemaname, tablename, policyname
    FROM pg_policies
    WHERE schemaname = 'public'
      AND tablename IN ('notifications', 'payments', 'notification_preferences')
  LOOP
    EXECUTE format('DROP POLICY IF EXISTS %I ON %I.%I', p.policyname, p.schemaname, p.tablename);
  END LOOP;
END $$;

-- Recreate notifications policies
CREATE POLICY "Service role can manage notifications"
  ON public.notifications FOR ALL
  USING (auth.role() = 'service_role')
  WITH CHECK (auth.role() = 'service_role');

CREATE POLICY "Users can manage own notifications"
  ON public.notifications FOR ALL
  USING (auth.uid() = user_id)
  WITH CHECK (auth.uid() = user_id);

-- Recreate payments policies
CREATE POLICY "Service role can manage payments"
  ON public.payments FOR ALL
  USING (auth.role() = 'service_role')
  WITH CHECK (auth.role() = 'service_role');

CREATE POLICY "Users can create own payments"
  ON public.payments FOR INSERT
  WITH CHECK (
    auth.uid() = user_id
    OR auth.role() = 'service_role'
  );

CREATE POLICY "Users can view own payments"
  ON public.payments FOR SELECT
  USING (
    auth.uid() = user_id
    OR auth.role() = 'service_role'
  );

-- Recreate notification_preferences policies
CREATE POLICY "Service role can manage notification preferences"
  ON public.notification_preferences FOR ALL
  USING (auth.role() = 'service_role')
  WITH CHECK (auth.role() = 'service_role');

CREATE POLICY "Users can manage own notification preferences"
  ON public.notification_preferences FOR ALL
  USING (auth.uid() = user_id)
  WITH CHECK (auth.uid() = user_id);

COMMIT;

-- Verification checks
SELECT policyname, tablename
FROM pg_policies
WHERE schemaname = 'public'
  AND tablename IN ('orders', 'order_items', 'notifications', 'payments', 'notification_preferences')
ORDER BY tablename, policyname;

SELECT column_name
FROM information_schema.columns
WHERE table_schema = 'public'
  AND table_name = 'payments'
  AND column_name IN ('provider', 'transaction_id', 'method', 'transaction_ref', 'payment_method');

-- ============================================
-- Extra Diagnostics (safe read-only checks)
-- ============================================

-- A) Confirm RLS is enabled on target tables
SELECT
  n.nspname AS schema_name,
  c.relname AS table_name,
  c.relrowsecurity AS rls_enabled,
  c.relforcerowsecurity AS force_rls
FROM pg_class c
JOIN pg_namespace n ON n.oid = c.relnamespace
WHERE n.nspname = 'public'
  AND c.relname IN ('payments', 'notifications', 'notification_preferences', 'orders', 'order_items')
ORDER BY c.relname;

-- B) Show effective policies and expressions for payments/notifications
SELECT
  schemaname,
  tablename,
  policyname,
  permissive,
  roles,
  cmd,
  qual,
  with_check
FROM pg_policies
WHERE schemaname = 'public'
  AND tablename IN ('payments', 'notifications', 'notification_preferences')
ORDER BY tablename, policyname;

-- C) Quick role visibility check (helps confirm execution context in SQL editor)
SELECT current_user AS sql_user, session_user AS sql_session_user;

-- D) Confirm payments table write privileges exist for common app roles
SELECT
  role_name,
  has_table_privilege(role_name, 'public.payments', 'INSERT') AS can_insert_payments,
  has_table_privilege(role_name, 'public.payments', 'UPDATE') AS can_update_payments
FROM (
  SELECT 'service_role'::text AS role_name
  UNION ALL
  SELECT 'authenticated'::text
  UNION ALL
  SELECT 'anon'::text
) r;
