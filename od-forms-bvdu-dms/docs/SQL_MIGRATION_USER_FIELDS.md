# SQL Migration - Enhanced User Fields for Registration

## 📋 Overview
This migration adds additional fields to the `users` table to support the new registration form with detailed student information.

---

## 🔧 SQL Queries to Execute

### 1. Add New Columns to Users Table

```sql
-- Add name breakdown fields
ALTER TABLE users 
ADD COLUMN first_name TEXT,
ADD COLUMN middle_name TEXT,
ADD COLUMN surname TEXT;

-- Add PRN field (Permanent Registration Number)
ALTER TABLE users 
ADD COLUMN prn TEXT UNIQUE;

-- Add course field (BCA, BBA, BAF, MBA)
ALTER TABLE users 
ADD COLUMN course TEXT CHECK (course IN ('BCA', 'BBA', 'BAF', 'MBA'));

-- Add profile photo URL
ALTER TABLE users 
ADD COLUMN profile_photo_url TEXT;

-- Update year column to support roman numerals
-- Note: The year column already exists, but we need to ensure it can store text for Roman numerals
ALTER TABLE users 
ALTER COLUMN year TYPE TEXT;

-- Add constraint for year values
ALTER TABLE users 
ADD CONSTRAINT check_year_values 
CHECK (year IN ('I', 'II', 'III') OR year IS NULL);
```

### 2. Create Index for PRN Lookups

```sql
-- Index for fast PRN lookups
CREATE INDEX idx_users_prn ON users(prn) WHERE prn IS NOT NULL;

-- Index for course filtering
CREATE INDEX idx_users_course ON users(course) WHERE course IS NOT NULL;
```

### 3. Update Existing Constraint (if needed)

```sql
-- Drop old constraint if it exists
ALTER TABLE users 
DROP CONSTRAINT IF EXISTS check_student_fields;

-- Add updated constraint for student fields
ALTER TABLE users 
ADD CONSTRAINT check_student_fields 
CHECK (
  (role = 'student' AND 
   roll_number IS NOT NULL AND 
   course IS NOT NULL AND 
   year IS NOT NULL AND 
   division IS NOT NULL AND
   prn IS NOT NULL) 
  OR role != 'student'
);
```

### 4. Update full_name Generation (Optional Trigger)

```sql
-- Create or replace function to auto-generate full_name from name parts
CREATE OR REPLACE FUNCTION generate_full_name()
RETURNS TRIGGER AS $$
BEGIN
  IF NEW.first_name IS NOT NULL AND NEW.middle_name IS NOT NULL AND NEW.surname IS NOT NULL THEN
    NEW.full_name := NEW.first_name || ' ' || NEW.middle_name || ' ' || NEW.surname;
  END IF;
  RETURN NEW;
END;
$$ LANGUAGE plpgsql;

-- Create trigger to auto-generate full_name
DROP TRIGGER IF EXISTS trigger_generate_full_name ON users;
CREATE TRIGGER trigger_generate_full_name
  BEFORE INSERT OR UPDATE OF first_name, middle_name, surname
  ON users
  FOR EACH ROW
  EXECUTE FUNCTION generate_full_name();
```

---

## 🗂️ Create Profile Photos Storage Bucket

### Execute in Supabase Dashboard → Storage

```sql
-- This is done via Supabase Dashboard UI, but here's the configuration:

-- Bucket Name: profile-photos
-- Public: Yes (so photos are accessible)
-- File size limit: 5MB
-- Allowed MIME types: image/jpeg, image/png, image/webp, image/gif
```

### Storage Policy for Profile Photos

```sql
-- Policy 1: Allow authenticated users to upload their own profile photo
CREATE POLICY "Users can upload their own profile photo"
ON storage.objects
FOR INSERT
TO authenticated
WITH CHECK (
  bucket_id = 'profile-photos' AND
  (storage.foldername(name))[1] = auth.uid()::text
);

-- Policy 2: Allow public read access to all profile photos
CREATE POLICY "Public can view profile photos"
ON storage.objects
FOR SELECT
TO public
USING (bucket_id = 'profile-photos');

-- Policy 3: Allow users to update their own profile photo
CREATE POLICY "Users can update their own profile photo"
ON storage.objects
FOR UPDATE
TO authenticated
USING (
  bucket_id = 'profile-photos' AND
  (storage.foldername(name))[1] = auth.uid()::text
);

-- Policy 4: Allow users to delete their own profile photo
CREATE POLICY "Users can delete their own profile photo"
ON storage.objects
FOR DELETE
TO authenticated
USING (
  bucket_id = 'profile-photos' AND
  (storage.foldername(name))[1] = auth.uid()::text
);
```

---

## 📊 Updated Users Table Schema

After migration, the `users` table will have:

```sql
CREATE TABLE users (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  email TEXT UNIQUE NOT NULL,
  role TEXT NOT NULL CHECK (role IN ('student', 'event-leader', 'faculty', 'hod')),
  
  -- Common fields
  full_name TEXT NOT NULL,
  first_name TEXT,
  middle_name TEXT,
  surname TEXT,
  phone TEXT,
  profile_photo_url TEXT,
  created_at TIMESTAMPTZ DEFAULT NOW(),
  last_login TIMESTAMPTZ,
  is_active BOOLEAN DEFAULT TRUE,
  created_by UUID REFERENCES users(id),
  
  -- Student specific
  prn TEXT UNIQUE,                          -- NEW: Permanent Registration Number
  course TEXT CHECK (course IN ('BCA', 'BBA', 'BAF', 'MBA')),  -- NEW
  roll_number TEXT UNIQUE,
  department TEXT,                          -- Can be deprecated (use course instead)
  year TEXT CHECK (year IN ('I', 'II', 'III')),  -- UPDATED: Changed from INTEGER to TEXT
  division TEXT CHECK (division IN ('A', 'B', 'C')),
  
  -- Faculty/HOD specific
  employee_id TEXT UNIQUE,
  designation TEXT,
  
  -- Event Leader specific
  club_name TEXT,
  position TEXT,
  
  CONSTRAINT check_student_fields CHECK (
    (role = 'student' AND 
     roll_number IS NOT NULL AND 
     course IS NOT NULL AND 
     year IS NOT NULL AND 
     division IS NOT NULL AND
     prn IS NOT NULL) 
    OR role != 'student'
  ),
  CONSTRAINT check_faculty_fields CHECK (
    (role IN ('faculty', 'hod') AND employee_id IS NOT NULL) 
    OR role NOT IN ('faculty', 'hod')
  )
);
```

---

## 🔄 Migration Steps

### Step-by-Step Execution Order:

1. **Backup existing data** (if any):
   ```sql
   -- Create backup table
   CREATE TABLE users_backup AS SELECT * FROM users;
   ```

2. **Add new columns** (from Section 1 above)

3. **Create indexes** (from Section 2 above)

4. **Update constraints** (from Section 3 above)

5. **Create trigger for full_name** (from Section 4 above - optional)

6. **Create storage bucket** via Supabase Dashboard:
   - Go to Storage
   - Click "New Bucket"
   - Name: `profile-photos`
   - Check "Public bucket"
   - Click "Create"

7. **Add storage policies** (from Storage Policy section above)

8. **Test registration** with new fields

---

## ✅ Verification Queries

After migration, verify the changes:

```sql
-- Check table structure
SELECT column_name, data_type, is_nullable, column_default
FROM information_schema.columns
WHERE table_name = 'users'
ORDER BY ordinal_position;

-- Check constraints
SELECT constraint_name, constraint_type
FROM information_schema.table_constraints
WHERE table_name = 'users';

-- Check indexes
SELECT indexname, indexdef
FROM pg_indexes
WHERE tablename = 'users';

-- Test insert with new fields
INSERT INTO users (
  id, email, role, 
  first_name, middle_name, surname, full_name,
  phone, prn, course, year, division, roll_number
) VALUES (
  uuid_generate_v4(),
  'test.student@bvdu.edu.in',
  'student',
  'Test', 'Kumar', 'Sharma', 'Test Kumar Sharma',
  '9876543210',
  '2021BCA001',
  'BCA',
  'I',
  'A',
  '001'
);

-- Verify insert
SELECT * FROM users WHERE email = 'test.student@bvdu.edu.in';
```

---

## 🎯 Key Changes Summary

| Field | Type | Purpose | Required For |
|-------|------|---------|--------------|
| `first_name` | TEXT | Student's first name | Students |
| `middle_name` | TEXT | Student's middle name | Students |
| `surname` | TEXT | Student's surname | Students |
| `prn` | TEXT (UNIQUE) | Permanent Registration Number | Students |
| `course` | TEXT (ENUM) | Academic course (BCA/BBA/BAF/MBA) | Students |
| `year` | TEXT (ENUM) | Academic year (I/II/III) | Students |
| `profile_photo_url` | TEXT | URL to profile photo in storage | All users |

---

## 🚨 Important Notes

1. **Department vs Course**: The `department` field can be considered deprecated. Use `course` instead for better clarity.

2. **Year Format**: Changed from INTEGER to TEXT to support Roman numerals (I, II, III).

3. **PRN Format**: Expected format is `YYYYCCCNNN` (Year + Course Code + Number)
   - Example: `2021BCA001`, `2022BBA025`, `2023BAF010`

4. **Roll Number**: This is the division-specific roll number (001, 002, etc.)

5. **Profile Photos**: 
   - Stored in `profile-photos` bucket
   - File naming: `{user_id}.{extension}`
   - Max size: 5MB
   - Public access for display

6. **Full Name Auto-Generation**: The trigger will automatically create `full_name` from the three name components.

---

## 🔗 Related Files

- Registration Form: `register.html`
- Login Form: `login.html`
- Configuration: `js/config.js`
- Main Integration Guide: `SUPABASE_INTEGRATION.md`

---

## 📝 Rollback (If Needed)

```sql
-- Remove new columns
ALTER TABLE users 
DROP COLUMN IF EXISTS first_name,
DROP COLUMN IF EXISTS middle_name,
DROP COLUMN IF EXISTS surname,
DROP COLUMN IF EXISTS prn,
DROP COLUMN IF EXISTS course,
DROP COLUMN IF EXISTS profile_photo_url;

-- Revert year column type
ALTER TABLE users 
ALTER COLUMN year TYPE INTEGER USING year::INTEGER;

-- Remove indexes
DROP INDEX IF EXISTS idx_users_prn;
DROP INDEX IF EXISTS idx_users_course;

-- Remove trigger and function
DROP TRIGGER IF EXISTS trigger_generate_full_name ON users;
DROP FUNCTION IF EXISTS generate_full_name();

-- Restore from backup if needed
-- DROP TABLE users;
-- ALTER TABLE users_backup RENAME TO users;
```
