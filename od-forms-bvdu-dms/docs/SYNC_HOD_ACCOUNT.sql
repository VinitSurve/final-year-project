-- Sync auth.users with public.users table for HOD account

-- Step 1: Check what exists
SELECT 'Auth Users' as source, id, email, created_at 
FROM auth.users 
WHERE email = 'hod@bvdu.edu.in'
UNION ALL
SELECT 'Public Users' as source, id, email, created_at 
FROM public.users 
WHERE email = 'hod@bvdu.edu.in';

-- Step 2: If HOD exists in auth but not in public.users, insert it
-- Replace these values with the actual HOD details
INSERT INTO public.users (
  id, 
  email, 
  full_name, 
  role, 
  phone, 
  is_active, 
  created_at
)
SELECT 
  au.id,
  au.email,
  'Dr. Mona Sinha', -- Replace with actual name
  'hod',
  '+91-9876543210', -- Replace with actual phone
  true,
  au.created_at
FROM auth.users au
WHERE au.email = 'hod@bvdu.edu.in'
  AND NOT EXISTS (
    SELECT 1 FROM public.users 
    WHERE email = 'hod@bvdu.edu.in'
  );

-- Step 3: If HOD exists in both but IDs don't match, update the public.users ID
UPDATE public.users 
SET id = (SELECT id FROM auth.users WHERE email = 'hod@bvdu.edu.in')
WHERE email = 'hod@bvdu.edu.in'
  AND id != (SELECT id FROM auth.users WHERE email = 'hod@bvdu.edu.in');

-- Step 4: Verify it's synced
SELECT 
  au.id as auth_id,
  u.id as users_id,
  au.email,
  u.full_name,
  u.role,
  CASE WHEN au.id = u.id THEN '✓ SYNCED' ELSE '✗ MISMATCH' END as status
FROM auth.users au
LEFT JOIN public.users u ON au.email = u.email
WHERE au.email = 'hod@bvdu.edu.in';
