-- ============================================
-- Manual Fix: Checkout + Payment Schema Compatibility
-- ============================================
-- Run this in Supabase SQL Editor (or via scripts/apply_checkout_payment_schema_fix.js)
-- Project: ugrraxmjvbujpdzfsvzt
-- ============================================

BEGIN;

-- 1) ORDERS: add fields used by backend/mobile checkout flow
ALTER TABLE public.orders
  ADD COLUMN IF NOT EXISTS payment_method VARCHAR(50),
  ADD COLUMN IF NOT EXISTS shipping_address JSONB,
  ADD COLUMN IF NOT EXISTS notes TEXT,
  ADD COLUMN IF NOT EXISTS total DECIMAL(12, 2);

-- Backfill total from legacy total_amount when available
UPDATE public.orders
SET total = COALESCE(total, total_amount)
WHERE total IS NULL;

-- 2) ORDER_ITEMS: add fields used by order controller inserts
ALTER TABLE public.order_items
  ADD COLUMN IF NOT EXISTS price DECIMAL(12, 2),
  ADD COLUMN IF NOT EXISTS total DECIMAL(12, 2),
  ADD COLUMN IF NOT EXISTS buyer_id UUID REFERENCES public.users(id);

-- Backfill from legacy fields
UPDATE public.order_items
SET
  price = COALESCE(price, unit_price),
  total = COALESCE(total, subtotal)
WHERE price IS NULL OR total IS NULL;

-- 3) PAYMENTS: add aliases used by payment controller inserts
ALTER TABLE public.payments
  ADD COLUMN IF NOT EXISTS method VARCHAR(50),
  ADD COLUMN IF NOT EXISTS transaction_ref VARCHAR(255),
  ADD COLUMN IF NOT EXISTS phone VARCHAR(20);

-- Backfill aliases from existing columns
UPDATE public.payments
SET
  method = COALESCE(method, payment_method),
  phone = COALESCE(phone, phone_number)
WHERE method IS NULL OR phone IS NULL;

-- 4) Ensure existing not-null payment_method is populated
UPDATE public.payments
SET payment_method = COALESCE(payment_method, method, 'marzpay')
WHERE payment_method IS NULL;

-- 5) Expand orders.payment_status check constraint to include runtime values
DO $$
DECLARE constraint_name TEXT;
BEGIN
  SELECT c.conname
  INTO constraint_name
  FROM pg_constraint c
  JOIN pg_class t ON c.conrelid = t.oid
  JOIN pg_namespace n ON n.oid = t.relnamespace
  WHERE n.nspname = 'public'
    AND t.relname = 'orders'
    AND c.contype = 'c'
    AND pg_get_constraintdef(c.oid) ILIKE '%payment_status%';

  IF constraint_name IS NOT NULL THEN
    EXECUTE format('ALTER TABLE public.orders DROP CONSTRAINT %I', constraint_name);
  END IF;

  ALTER TABLE public.orders
    ADD CONSTRAINT orders_payment_status_check
    CHECK (payment_status IN ('pending', 'processing', 'completed', 'paid', 'failed', 'refunded', 'cancelled'));
END $$;

-- 6) Expand payments.status check constraint to include completed
DO $$
DECLARE constraint_name TEXT;
BEGIN
  SELECT c.conname
  INTO constraint_name
  FROM pg_constraint c
  JOIN pg_class t ON c.conrelid = t.oid
  JOIN pg_namespace n ON n.oid = t.relnamespace
  WHERE n.nspname = 'public'
    AND t.relname = 'payments'
    AND c.contype = 'c'
    AND pg_get_constraintdef(c.oid) ILIKE '%status%';

  IF constraint_name IS NOT NULL THEN
    EXECUTE format('ALTER TABLE public.payments DROP CONSTRAINT %I', constraint_name);
  END IF;

  ALTER TABLE public.payments
    ADD CONSTRAINT payments_status_check
    CHECK (status IN ('pending', 'processing', 'completed', 'successful', 'failed', 'cancelled', 'refunded'));
END $$;

COMMIT;

-- Verification quick checks
SELECT column_name
FROM information_schema.columns
WHERE table_schema = 'public'
  AND table_name = 'orders'
  AND column_name IN ('payment_method', 'shipping_address', 'notes', 'total');

SELECT column_name
FROM information_schema.columns
WHERE table_schema = 'public'
  AND table_name = 'order_items'
  AND column_name IN ('price', 'total', 'buyer_id');

SELECT column_name
FROM information_schema.columns
WHERE table_schema = 'public'
  AND table_name = 'payments'
  AND column_name IN ('method', 'transaction_ref', 'phone', 'payment_method');
