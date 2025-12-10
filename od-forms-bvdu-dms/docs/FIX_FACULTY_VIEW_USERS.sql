-- Fix RLS policies for users table - NO RECURSION VERSION

-- First, disable RLS temporarily to fix the issue
ALTER TABLE users DISABLE ROW LEVEL SECURITY;

-- Drop ALL existing policies for users table
DROP POLICY IF EXISTS "Allow faculty to view event leaders" ON users;
DROP POLICY IF EXISTS "Faculty can view all users" ON users;
DROP POLICY IF EXISTS "Users can view event leaders" ON users;
DROP POLICY IF EXISTS "Users can view own profile" ON users;
DROP POLICY IF EXISTS "Allow users to read own profile" ON users;
DROP POLICY IF EXISTS "Users can update own profile" ON users;
DROP POLICY IF EXISTS "HOD can view all users" ON users;

-- Re-enable RLS
ALTER TABLE users ENABLE ROW LEVEL SECURITY;

-- Create a security definer function to get user role (avoids RLS recursion)
CREATE OR REPLACE FUNCTION get_user_role(user_id uuid)
RETURNS text
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
DECLARE
  user_role text;
BEGIN
  SELECT role INTO user_role FROM users WHERE id = user_id;
  RETURN user_role;
END;
$$;

-- CRITICAL: Allow users to read their own profile (needed for login)
CREATE POLICY "Users can view own profile" ON users
  FOR SELECT
  TO authenticated
  USING (auth.uid() = id);

-- Allow users to update their own profile
CREATE POLICY "Users can update own profile" ON users
  FOR UPDATE
  TO authenticated
  USING (auth.uid() = id);

-- Allow faculty to view all users
CREATE POLICY "Faculty can view all users" ON users
  FOR SELECT
  TO authenticated
  USING (get_user_role(auth.uid()) = 'faculty');

-- Allow HOD to view all users
CREATE POLICY "HOD can view all users" ON users
  FOR SELECT
  TO authenticated
  USING (get_user_role(auth.uid()) = 'hod');

-- Verify the policies were created
SELECT schemaname, tablename, policyname, permissive, roles, cmd, qual 
FROM pg_policies 
WHERE tablename = 'users'
ORDER BY policyname;
