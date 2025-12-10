# Fix: Infinite Recursion in Users Table Policy

## Error
```
infinite recursion detected in policy for relation "users"
```

## Cause
Your RLS (Row Level Security) policy on the `users` table is referencing the `users` table itself, creating a circular dependency.

## Solution

### Step 1: Check Current Policies
Go to Supabase Dashboard → SQL Editor and run:

```sql
-- View all policies on users table
SELECT 
  schemaname, 
  tablename, 
  policyname, 
  permissive, 
  roles, 
  cmd, 
  qual, 
  with_check
FROM pg_policies 
WHERE tablename = 'users';
```

### Step 2: Drop Problematic Policies
```sql
-- Drop all existing policies on users table
DROP POLICY IF EXISTS "Users can view own data" ON users;
DROP POLICY IF EXISTS "Users can update own data" ON users;
DROP POLICY IF EXISTS "Users can insert own data" ON users;
DROP POLICY IF EXISTS "Enable insert for authenticated users" ON users;
DROP POLICY IF EXISTS "Enable read access for authenticated users" ON users;
DROP POLICY IF EXISTS "Enable update for users based on id" ON users;
DROP POLICY IF EXISTS "Allow users to read own profile" ON users;
DROP POLICY IF EXISTS "Allow users to update own profile" ON users;
```

### Step 3: Create Correct Policies

**Important:** Use `auth.uid()` instead of querying the users table.

```sql
-- Enable RLS
ALTER TABLE users ENABLE ROW LEVEL SECURITY;

-- Policy 1: Allow authenticated users to INSERT their own profile
-- This runs during registration (auth.uid() is already set by Supabase Auth)
CREATE POLICY "Allow authenticated insert"
ON users
FOR INSERT
TO authenticated
WITH CHECK (auth.uid() = id);

-- Policy 2: Allow users to READ their own data
CREATE POLICY "Allow users read own data"
ON users
FOR SELECT
TO authenticated
USING (auth.uid() = id);

-- Policy 3: Allow users to UPDATE their own data
CREATE POLICY "Allow users update own data"
ON users
FOR UPDATE
TO authenticated
USING (auth.uid() = id)
WITH CHECK (auth.uid() = id);

-- Policy 4: Allow service role to do anything (for admin operations)
CREATE POLICY "Service role has full access"
ON users
FOR ALL
TO service_role
USING (true)
WITH CHECK (true);
```

### Step 4: Fix Storage Policies

Your profile photos storage also has an error. Update the storage bucket policies:

```sql
-- For profile-photos bucket
-- Go to: Storage → profile-photos → Policies

-- Policy 1: Anyone can view photos (SELECT)
CREATE POLICY "Public Access"
ON storage.objects FOR SELECT
TO public
USING (bucket_id = 'profile-photos');

-- Policy 2: Authenticated users can upload photos (INSERT)
CREATE POLICY "Authenticated users can upload"
ON storage.objects FOR INSERT
TO authenticated
WITH CHECK (
  bucket_id = 'profile-photos' 
  AND (storage.foldername(name))[1] = 'profile-photos'
);

-- Policy 3: Users can update their own photos (UPDATE)
CREATE POLICY "Users can update own photos"
ON storage.objects FOR UPDATE
TO authenticated
USING (bucket_id = 'profile-photos' AND auth.uid()::text = owner)
WITH CHECK (bucket_id = 'profile-photos' AND auth.uid()::text = owner);

-- Policy 4: Users can delete their own photos (DELETE)
CREATE POLICY "Users can delete own photos"
ON storage.objects FOR DELETE
TO authenticated
USING (bucket_id = 'profile-photos' AND auth.uid()::text = owner);
```

### Step 5: Verify Policies

```sql
-- Check users table policies
SELECT policyname, cmd 
FROM pg_policies 
WHERE tablename = 'users';

-- Should show:
-- - Allow authenticated insert (INSERT)
-- - Allow users read own data (SELECT)
-- - Allow users update own data (UPDATE)
-- - Service role has full access (ALL)
```

## Alternative: Disable RLS Temporarily (For Testing Only)

**WARNING: Only use this for testing! Re-enable for production.**

```sql
ALTER TABLE users DISABLE ROW LEVEL SECURITY;
```

Then re-enable with correct policies before going live.

## Rate Limiting Issue

You're seeing:
```
For security purposes, you can only request this after 47 seconds.
```

**Solution:**
1. Wait 60 seconds before trying again
2. Clear browser cache and cookies for localhost
3. If testing repeatedly, consider using different emails
4. In production, Supabase allows configuring rate limits in: Authentication → Rate Limits

## Test Registration Flow

After fixing policies:
1. Wait 60 seconds for rate limit to reset
2. Use a NEW email address
3. Try registration again
4. Check Supabase Dashboard → Authentication → Users to verify account creation
5. Check Table Editor → users to verify profile data insertion

## Common Pitfalls to Avoid

❌ **Don't do this:**
```sql
-- This causes infinite recursion!
CREATE POLICY "bad_policy"
ON users FOR SELECT
USING (
  -- Querying users table from within users table policy!
  EXISTS (SELECT 1 FROM users WHERE id = auth.uid() AND role = 'student')
);
```

✅ **Do this instead:**
```sql
CREATE POLICY "good_policy"
ON users FOR SELECT
USING (
  -- Use auth.uid() and column values directly
  auth.uid() = id AND role = 'student'
);
```

## Debugging Tips

If you still get errors:
1. Check logs: Supabase Dashboard → Logs → Postgres Logs
2. Test policy: Use "Test policy" button in Table Editor
3. Verify auth.uid() is set: Run in SQL Editor:
```sql
SELECT auth.uid();
-- Should return your user UUID when logged in
```
