/*
  # Fix RLS Policies Recursion

  1. Changes
    - Remove recursive policies that cause infinite loops
    - Simplify user access control using auth.uid() directly
    - Update policies to use JWT claims for role checks
    - Add function to check admin status safely

  2. Security
    - Maintain proper access control
    - Prevent infinite recursion in policies
    - Keep role-based access control intact
*/

-- Create a function to check if the current user is an admin using JWT claims
CREATE OR REPLACE FUNCTION is_admin()
RETURNS boolean AS $$
BEGIN
  RETURN coalesce(
    current_setting('request.jwt.claims', true)::jsonb->>'role' = 'admin',
    false
  );
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- Drop existing problematic policies
DROP POLICY IF EXISTS "Users can read own data" ON users;
DROP POLICY IF EXISTS "enable_select_users" ON users;
DROP POLICY IF EXISTS "admin_insert_policy" ON users;
DROP POLICY IF EXISTS "admin_update_policy" ON users;

-- Create new, simplified policies for users table
CREATE POLICY "users_select_policy" ON users
  FOR SELECT TO authenticated
  USING (
    id = auth.uid() OR 
    is_admin()
  );

CREATE POLICY "users_insert_policy" ON users
  FOR INSERT TO authenticated
  WITH CHECK (
    is_admin()
  );

CREATE POLICY "users_update_policy" ON users
  FOR UPDATE TO authenticated
  USING (
    is_admin()
  )
  WITH CHECK (
    is_admin()
  );

-- Update grading entries policies to use the new is_admin function
DROP POLICY IF EXISTS "Enable insert for admins" ON grading_entries;
DROP POLICY IF EXISTS "Enable update for admins" ON grading_entries;
DROP POLICY IF EXISTS "Users can view own entries" ON grading_entries;

CREATE POLICY "grading_entries_insert_policy" ON grading_entries
  FOR INSERT TO authenticated
  WITH CHECK (
    consumer_id = auth.uid() OR
    is_admin()
  );

CREATE POLICY "grading_entries_update_policy" ON grading_entries
  FOR UPDATE TO authenticated
  USING (
    is_admin()
  )
  WITH CHECK (
    is_admin()
  );

CREATE POLICY "grading_entries_select_policy" ON grading_entries
  FOR SELECT TO authenticated
  USING (
    consumer_id = auth.uid() OR
    is_admin()
  );