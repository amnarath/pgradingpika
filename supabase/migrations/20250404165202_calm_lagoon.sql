/*
  # Fix RLS Policies and Remove User Blocking

  1. Changes
    - Drop all existing policies first
    - Remove user blocking functionality
    - Create new simplified policies
    - Fix policy naming conflicts

  2. Security
    - Maintain proper access control
    - Prevent policy conflicts
    - Keep role-based security
*/

-- Drop ALL existing policies first to avoid conflicts
DROP POLICY IF EXISTS "users_select_policy" ON users;
DROP POLICY IF EXISTS "users_insert_policy" ON users;
DROP POLICY IF EXISTS "users_update_policy" ON users;
DROP POLICY IF EXISTS "Enable insert for admins" ON grading_entries;
DROP POLICY IF EXISTS "Enable update for admins" ON grading_entries;
DROP POLICY IF EXISTS "Users can view own entries" ON grading_entries;
DROP POLICY IF EXISTS "grading_entries_select_policy" ON grading_entries;
DROP POLICY IF EXISTS "grading_entries_insert_policy" ON grading_entries;
DROP POLICY IF EXISTS "grading_entries_update_policy" ON grading_entries;

-- Remove blocked column from users table
ALTER TABLE users DROP COLUMN IF EXISTS blocked;

-- Drop functions related to user blocking
DROP FUNCTION IF EXISTS is_user_blocked();
DROP FUNCTION IF EXISTS toggle_user_blocked(uuid, boolean);

-- Update is_admin function to use simpler role check
CREATE OR REPLACE FUNCTION is_admin()
RETURNS boolean AS $$
BEGIN
  RETURN EXISTS (
    SELECT 1
    FROM users
    WHERE id = auth.uid()
    AND role = 'admin'
  );
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- Create new policies for users table with unique names
CREATE POLICY "users_view_own_and_admin_all" ON users
  FOR SELECT
  TO authenticated
  USING (
    id = auth.uid() OR is_admin()
  );

CREATE POLICY "users_insert_admin_only" ON users
  FOR INSERT
  TO authenticated
  WITH CHECK (
    is_admin()
  );

CREATE POLICY "users_update_admin_only" ON users
  FOR UPDATE
  TO authenticated
  USING (is_admin())
  WITH CHECK (is_admin());

-- Create new policies for grading_entries with unique names
CREATE POLICY "entries_view_own_and_admin_all" ON grading_entries
  FOR SELECT
  TO authenticated
  USING (
    consumer_id = auth.uid() OR is_admin()
  );

CREATE POLICY "entries_insert_own_and_admin_all" ON grading_entries
  FOR INSERT
  TO authenticated
  WITH CHECK (
    consumer_id = auth.uid() OR is_admin()
  );

CREATE POLICY "entries_update_admin_only" ON grading_entries
  FOR UPDATE
  TO authenticated
  USING (is_admin())
  WITH CHECK (is_admin());