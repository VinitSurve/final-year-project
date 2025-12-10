-- ============================================
-- FIX: User Registration RLS Policy
-- ============================================

-- OPTION 1: Allow authenticated users to insert (Recommended)
-- This works after the user signs in immediately after signup

DROP POLICY IF EXISTS "users_insert" ON users;
DROP POLICY IF EXISTS "users_insert_own_profile" ON users;

CREATE POLICY "users_insert_authenticated"
ON users
FOR INSERT
TO authenticated
WITH CHECK (true);

-- Keep restrictive SELECT and UPDATE policies
-- (These should already be in place)

-- OPTION 2: Disable email confirmation in Supabase Dashboard
-- Go to: Authentication → Providers → Email
-- Uncheck: "Enable email confirmations"
-- This allows signUp() to automatically authenticate the user

-- OPTION 3: Temporary fix for testing (NOT for production)
-- ALTER TABLE users DISABLE ROW LEVEL SECURITY;

-- Verify policies
SELECT 
  tablename, 
  policyname, 
  cmd,
  roles,
  with_check
FROM pg_policies 
WHERE tablename = 'users'
ORDER BY cmd;

-- Expected output for users table:
-- INSERT | users_insert_authenticated | {authenticated} | true
-- SELECT | users_select | {authenticated} | (auth.uid() = id)
-- UPDATE | users_update | {authenticated} | (auth.uid() = id)
