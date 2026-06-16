-- ============================================
-- Manual Fix for Profile Creation Issue
-- Run this in Supabase SQL Editor
-- ============================================
-- Go to: https://app.supabase.com/project/ugrraxmjvbujpdzfsvzt/sql/new
-- Copy and paste this entire file, then click "Run"
-- ============================================

-- Step 1: Update trigger function with proper error handling
CREATE OR REPLACE FUNCTION public.handle_new_user()
RETURNS TRIGGER
SECURITY DEFINER
SET search_path = public, auth
LANGUAGE plpgsql
AS $$
BEGIN
    RAISE LOG 'Creating user profile for user_id: %, email: %', NEW.id, NEW.email;
    
    INSERT INTO public.users (
        id,
        email,
        full_name,
        phone,
        role,
        created_at,
        updated_at
    )
    VALUES (
        NEW.id,
        NEW.email,
        COALESCE(NEW.raw_user_meta_data->>'full_name', 'User'),
        COALESCE(NEW.phone, NEW.raw_user_meta_data->>'phone'),
        COALESCE(NEW.raw_user_meta_data->>'role', 'buyer'),
        NOW(),
        NOW()
    )
    ON CONFLICT (id) DO UPDATE SET
        email = EXCLUDED.email,
        full_name = COALESCE(EXCLUDED.full_name, users.full_name),
        phone = COALESCE(EXCLUDED.phone, users.phone),
        role = COALESCE(EXCLUDED.role, users.role),
        updated_at = NOW();
    
    RAISE LOG 'User profile created successfully for user_id: %', NEW.id;
    RETURN NEW;
EXCEPTION
    WHEN OTHERS THEN
        RAISE LOG 'Error in handle_new_user for user_id %, error: %', NEW.id, SQLERRM;
        RAISE WARNING 'Failed to create user profile: %', SQLERRM;
        RETURN NEW;
END;
$$;

-- Step 2: Ensure trigger exists
DROP TRIGGER IF EXISTS on_auth_user_created ON auth.users;
CREATE TRIGGER on_auth_user_created
    AFTER INSERT ON auth.users
    FOR EACH ROW
    EXECUTE FUNCTION public.handle_new_user();

-- Step 3: Update RLS policy to allow service_role inserts
DROP POLICY IF EXISTS "Users can insert own profile during signup" ON users;
CREATE POLICY "Users can insert own profile during signup"
    ON users FOR INSERT
    WITH CHECK (
        auth.uid() = id OR
        auth.role() = 'service_role'
    );

-- Step 4: Grant necessary permissions
GRANT ALL ON TABLE public.users TO postgres, service_role;
GRANT SELECT, INSERT, UPDATE ON TABLE public.users TO authenticated;
GRANT SELECT ON TABLE public.users TO anon;

-- Step 5: Verify setup
SELECT 'Fix applied successfully!' AS status;
SELECT 'Trigger: ' || tgname || ' on ' || tgrelid::regclass AS trigger_info
FROM pg_trigger 
WHERE tgname = 'on_auth_user_created';
