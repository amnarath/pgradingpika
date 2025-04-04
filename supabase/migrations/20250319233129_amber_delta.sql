/*
  # Fix users table policies to prevent recursion

  1. Security Changes
    - Remove recursive policy checks that caused infinite loops
    - Implement direct role checks using auth.jwt()
    - Maintain security while fixing performance issues

  2. Changes
    - Drop existing policies
    - Create new non-recursive policies
    - Use JWT claims for role checks instead of table queries
*/

-- Drop existing policies
DROP POLICY IF EXISTS "users_select_policy" ON users;
DROP POLICY IF EXISTS "admin_insert_policy" ON users;
DROP POLICY IF EXISTS "admin_update_policy" ON users;

-- Enable RLS on users table
ALTER TABLE users ENABLE ROW LEVEL SECURITY;

-- Create new non-recursive policies
CREATE POLICY "users_select_policy" ON users
  FOR SELECT
  TO authenticated
  USING (
    (auth.jwt() ->> 'role')::text = 'admin' OR  -- Admin can see all
    id = auth.uid()                             -- Users can see themselves
  );

CREATE POLICY "admin_insert_policy" ON users
  FOR INSERT
  TO authenticated
  WITH CHECK (
    (auth.jwt() ->> 'role')::text = 'admin'
  );

CREATE POLICY "admin_update_policy" ON users
  FOR UPDATE
  TO authenticated
  USING (
    (auth.jwt() ->> 'role')::text = 'admin'
  )
  WITH CHECK (
    (auth.jwt() ->> 'role')::text = 'admin'
  );

-- Create or replace the is_admin function to use JWT claims
CREATE OR REPLACE FUNCTION is_admin()
RETURNS boolean AS $$
BEGIN
  RETURN (auth.jwt() ->> 'role')::text = 'admin';
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;