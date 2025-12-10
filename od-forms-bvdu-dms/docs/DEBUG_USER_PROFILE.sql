-- Debug and fix user profile issues

-- Step 1: Check if auth users and users table are in sync
SELECT 
  au.id as auth_id,
  au.email as auth_email,
  u.id as users_table_id,
  u.email as users_table_email,
  u.role
FROM auth.users au
LEFT JOIN public.users u ON au.id = u.id
WHERE au.email = 'hod@bvdu.edu.in';

-- Step 2: Check if there's a mismatch (user exists in users table with different ID)
SELECT 
  id,
  email,
  role,
  full_name,
  created_at
FROM public.users
WHERE email = 'hod@bvdu.edu.in';

-- Step 3: Check auth.users table
SELECT 
  id,
  email,
  created_at,
  last_sign_in_at
FROM auth.users
WHERE email = 'hod@bvdu.edu.in';

-- Step 4: If there's an ID mismatch, update the users table to match auth.users
-- UNCOMMENT AND RUN THIS ONLY IF YOU FIND A MISMATCH:
-- UPDATE public.users 
-- SET id = (SELECT id FROM auth.users WHERE email = 'hod@bvdu.edu.in')
-- WHERE email = 'hod@bvdu.edu.in';

-- Step 5: Verify all RLS policies are in place
SELECT tablename, policyname, permissive, roles, cmd, qual 
FROM pg_policies 
WHERE tablename = 'users'
ORDER BY policyname;

-- Step 6: Test if current user can read from users table
-- Run this while logged in as HOD
-- SELECT * FROM users WHERE email = 'hod@bvdu.edu.in';
