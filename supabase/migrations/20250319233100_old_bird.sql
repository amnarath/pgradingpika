/*
  # Fix users visibility in user management

  1. Security Changes
    - Modify users table policies to allow proper admin access
    - Add explicit SELECT policy for admins
    - Ensure proper role-based visibility

  2. Changes
    - Drop existing user policies
    - Create new, more permissive admin policies
    - Maintain security while fixing visibility
*/

-- Drop existing policies for users table
DROP POLICY IF EXISTS "users_read_own" ON users;
DROP POLICY IF EXISTS "admin_insert_users" ON users;
DROP POLICY IF EXISTS "admin_update_users" ON users;

-- Enable RLS on users table (in case it's not enabled)
ALTER TABLE users ENABLE ROW LEVEL SECURITY;

-- Create new policies for users table
CREATE POLICY "users_select_policy" ON users
  FOR SELECT
  TO authenticated
  USING (
    CASE 
      WHEN EXISTS (
        SELECT 1 
        FROM users 
        WHERE id = auth.uid() 
        AND role = 'admin'
      ) THEN true  -- Admins can see all users
      ELSE id = auth.uid()  -- Regular users can only see themselves
    END
  );

CREATE POLICY "admin_insert_policy" ON users
  FOR INSERT
  TO authenticated
  WITH CHECK (
    EXISTS (
      SELECT 1 
      FROM users 
      WHERE id = auth.uid() 
      AND role = 'admin'
    )
  );

CREATE POLICY "admin_update_policy" ON users
  FOR UPDATE
  TO authenticated
  USING (
    EXISTS (
      SELECT 1 
      FROM users 
      WHERE id = auth.uid() 
      AND role = 'admin'
    )
  )
  WITH CHECK (
    EXISTS (
      SELECT 1 
      FROM users 
      WHERE id = auth.uid() 
      AND role = 'admin'
    )
  );