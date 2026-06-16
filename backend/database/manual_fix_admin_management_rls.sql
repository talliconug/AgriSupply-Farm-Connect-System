-- ============================================
-- Manual Fix: Admin Management RLS (users/products)
-- ============================================
-- Why:
-- Admin API update endpoints currently return:
-- "Cannot coerce the result to a single JSON object"
-- This usually means UPDATE returned zero rows due RLS policy mismatch.
--
-- Run this in Supabase SQL Editor for project: ugrraxmjvbujpdzfsvzt
-- ============================================

BEGIN;

-- Ensure RLS is enabled
ALTER TABLE public.users ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.products ENABLE ROW LEVEL SECURITY;

-- Remove stale service-role management policies if present
DROP POLICY IF EXISTS "Service role can manage users" ON public.users;
DROP POLICY IF EXISTS "Service role can manage products" ON public.products;

-- Allow backend service-role key to fully manage users/products
CREATE POLICY "Service role can manage users"
  ON public.users FOR ALL
  USING (auth.role() = 'service_role')
  WITH CHECK (auth.role() = 'service_role');

CREATE POLICY "Service role can manage products"
  ON public.products FOR ALL
  USING (auth.role() = 'service_role')
  WITH CHECK (auth.role() = 'service_role');

COMMIT;

-- Verification
SELECT tablename, policyname, cmd, qual, with_check
FROM pg_policies
WHERE schemaname = 'public'
  AND tablename IN ('users', 'products')
ORDER BY tablename, policyname;
