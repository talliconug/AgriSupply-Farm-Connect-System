-- ============================================
-- Manual Fix: Authenticated Admin Update Policies
-- ============================================
-- Why:
-- If admin endpoints execute with authenticated user context instead of
-- service_role at PostgREST level, updates can return 0 rows under RLS.
-- This adds explicit admin-user policies for users/products updates.
--
-- Run in Supabase SQL Editor for project: ugrraxmjvbujpdzfsvzt
-- ============================================

BEGIN;

ALTER TABLE public.users ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.products ENABLE ROW LEVEL SECURITY;

-- Remove prior admin-auth policies if they exist
DROP POLICY IF EXISTS "Authenticated admins can update users" ON public.users;
DROP POLICY IF EXISTS "Authenticated admins can read users" ON public.users;
DROP POLICY IF EXISTS "Authenticated admins can update products" ON public.products;
DROP POLICY IF EXISTS "Authenticated admins can read products" ON public.products;

-- Authenticated admins can read users
CREATE POLICY "Authenticated admins can read users"
  ON public.users FOR SELECT
  USING (
    EXISTS (
      SELECT 1
      FROM public.users admin_user
      WHERE admin_user.id = auth.uid()
        AND admin_user.role = 'admin'
    )
  );

-- Authenticated admins can update users
CREATE POLICY "Authenticated admins can update users"
  ON public.users FOR UPDATE
  USING (
    EXISTS (
      SELECT 1
      FROM public.users admin_user
      WHERE admin_user.id = auth.uid()
        AND admin_user.role = 'admin'
    )
  )
  WITH CHECK (
    EXISTS (
      SELECT 1
      FROM public.users admin_user
      WHERE admin_user.id = auth.uid()
        AND admin_user.role = 'admin'
    )
  );

-- Authenticated admins can read products
CREATE POLICY "Authenticated admins can read products"
  ON public.products FOR SELECT
  USING (
    EXISTS (
      SELECT 1
      FROM public.users admin_user
      WHERE admin_user.id = auth.uid()
        AND admin_user.role = 'admin'
    )
  );

-- Authenticated admins can update products
CREATE POLICY "Authenticated admins can update products"
  ON public.products FOR UPDATE
  USING (
    EXISTS (
      SELECT 1
      FROM public.users admin_user
      WHERE admin_user.id = auth.uid()
        AND admin_user.role = 'admin'
    )
  )
  WITH CHECK (
    EXISTS (
      SELECT 1
      FROM public.users admin_user
      WHERE admin_user.id = auth.uid()
        AND admin_user.role = 'admin'
    )
  );

COMMIT;

-- Verification
SELECT tablename, policyname, cmd, qual, with_check
FROM pg_policies
WHERE schemaname = 'public'
  AND tablename IN ('users', 'products')
ORDER BY tablename, policyname;
