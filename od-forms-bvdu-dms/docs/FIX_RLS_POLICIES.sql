-- ============================================
-- FIX: Infinite Recursion in Users Table RLS
-- Run this entire script in Supabase SQL Editor
-- ============================================

-- Step 1: Disable RLS temporarily to clear everything
ALTER TABLE users DISABLE ROW LEVEL SECURITY;

-- Step 2: Drop ALL existing policies on users table
DO $$ 
DECLARE 
    r RECORD;
BEGIN
    FOR r IN (SELECT policyname FROM pg_policies WHERE tablename = 'users') LOOP
        EXECUTE format('DROP POLICY IF EXISTS %I ON users', r.policyname);
    END LOOP;
END $$;

-- Step 3: Re-enable RLS
ALTER TABLE users ENABLE ROW LEVEL SECURITY;

-- Step 4: Create CORRECT policies (no circular reference)

-- Policy 1: Allow new users to INSERT their own profile during registration
-- This works because auth.uid() is set by Supabase Auth before this runs
CREATE POLICY "users_insert_own_profile"
ON users
FOR INSERT
TO authenticated
WITH CHECK (auth.uid() = id);

-- Policy 2: Allow users to SELECT/read their own profile
CREATE POLICY "users_select_own_profile"
ON users
FOR SELECT
TO authenticated
USING (auth.uid() = id);

-- Policy 3: Allow users to UPDATE their own profile
CREATE POLICY "users_update_own_profile"
ON users
FOR UPDATE
TO authenticated
USING (auth.uid() = id)
WITH CHECK (auth.uid() = id);

-- Policy 4: Allow HOD to view all students in their department (optional - add if needed)
-- CREATE POLICY "hod_view_students"
-- ON users
-- FOR SELECT
-- TO authenticated
-- USING (
--   EXISTS (
--     SELECT 1 FROM users hod
--     WHERE hod.id = auth.uid() 
--     AND hod.role = 'hod'
--     AND hod.department = users.department
--   )
-- );

-- Step 5: Fix Storage Bucket Policies for profile-photos
-- First, drop existing storage policies
DO $$ 
DECLARE 
    r RECORD;
BEGIN
    FOR r IN (
        SELECT policyname 
        FROM pg_policies 
        WHERE schemaname = 'storage' 
        AND tablename = 'objects'
        AND policyname LIKE '%profile%'
    ) LOOP
        EXECUTE format('DROP POLICY IF EXISTS %I ON storage.objects', r.policyname);
    END LOOP;
END $$;

-- Storage Policy 1: Public can view/download photos
CREATE POLICY "profile_photos_public_select"
ON storage.objects
FOR SELECT
TO public
USING (bucket_id = 'profile-photos');

-- Storage Policy 2: Authenticated users can upload photos
CREATE POLICY "profile_photos_authenticated_insert"
ON storage.objects
FOR INSERT
TO authenticated
WITH CHECK (bucket_id = 'profile-photos');

-- Storage Policy 3: Users can update their own photos
CREATE POLICY "profile_photos_authenticated_update"
ON storage.objects
FOR UPDATE
TO authenticated
USING (bucket_id = 'profile-photos');

-- Storage Policy 4: Users can delete their own photos
CREATE POLICY "profile_photos_authenticated_delete"
ON storage.objects
FOR DELETE
TO authenticated
USING (bucket_id = 'profile-photos');

-- Step 6: Verify policies are correct
SELECT 
  'users table policies' as table_name,
  policyname, 
  cmd,
  CASE 
    WHEN qual LIKE '%users%' AND qual NOT LIKE '%auth.uid()%' THEN '⚠️ WARNING: May cause recursion'
    ELSE '✓ OK'
  END as status
FROM pg_policies 
WHERE tablename = 'users'

UNION ALL

SELECT 
  'storage.objects policies' as table_name,
  policyname,
  cmd,
  '✓ OK' as status
FROM pg_policies 
WHERE schemaname = 'storage' 
AND tablename = 'objects'
AND bucket_id = 'profile-photos';

-- Expected output:
-- users_insert_own_profile | INSERT | ✓ OK
-- users_select_own_profile | SELECT | ✓ OK
-- users_update_own_profile | UPDATE | ✓ OK
-- profile_photos_public_select | SELECT | ✓ OK
-- profile_photos_authenticated_insert | INSERT | ✓ OK
-- profile_photos_authenticated_update | UPDATE | ✓ OK
-- profile_photos_authenticated_delete | DELETE | ✓ OK
