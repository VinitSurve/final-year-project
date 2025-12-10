-- ============================================
-- FIX USER ROLE CONSTRAINTS AND ADD DESIGNATION
-- Run this in Supabase SQL Editor
-- ============================================

-- Step 1: Drop all role-related check constraints
ALTER TABLE users
DROP CONSTRAINT IF EXISTS check_faculty_fields;

ALTER TABLE users
DROP CONSTRAINT IF EXISTS users_role_check;

-- Step 2: Add designation column (for faculty and HOD)
ALTER TABLE users
ADD COLUMN IF NOT EXISTS designation TEXT;

-- Step 3: Recreate role check constraint with ALL roles
ALTER TABLE users
ADD CONSTRAINT users_role_check 
CHECK (role IN ('student', 'faculty', 'event_leader', 'hod', 'admin'));

-- Step 4: Add comment to explain column
COMMENT ON COLUMN users.designation IS 'Faculty/HOD designation - Professor, Associate Professor, Assistant Professor, Lecturer, etc.';

-- Step 5: Verify column was added
SELECT column_name, data_type, is_nullable
FROM information_schema.columns
WHERE table_name = 'users'
AND column_name = 'designation';

-- Step 6: Clean up orphaned auth user (if needed)
-- Remove the event leader auth account that failed to create profile
DELETE FROM auth.users 
WHERE email = 'survevinit5006@gmail.com';
