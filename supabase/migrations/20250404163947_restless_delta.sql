/*
  # Fix RLS policies for users and grading entries

  1. Security Changes
    - Update admin check function
    - Fix policy conflicts by dropping existing policies
    - Ensure proper access control for users and admins

  2. Changes
    - Drop all existing policies before creating new ones
    - Update admin check function
    - Create new policies for both tables
*/

-- Drop ALL existing policies first to avoid conflicts
DROP POLICY IF EXISTS "Enable insert for users and admins" ON grading_entries;
DROP POLICY IF EXISTS "Enable insert for admins" ON grading_entries;
DROP POLICY IF EXISTS "Enable update for admins" ON grading_entries;
DROP POLICY IF EXISTS "Users can view own entries" ON grading_entries;
DROP POLICY IF EXISTS "admin_insert_entries" ON grading_entries;
DROP POLICY IF EXISTS "admin_update_entries" ON grading_entries;
DROP POLICY IF EXISTS "entries_read" ON grading_entries;
DROP POLICY IF EXISTS "users_select_policy" ON users;

-- Helper function to check if user is admin
CREATE OR REPLACE FUNCTION is_admin()
RETURNS boolean AS $$
BEGIN
  RETURN EXISTS (
    SELECT 1 FROM users
    WHERE id = auth.uid()
    AND role = 'admin'
  );
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- Policy for users to insert their own entries
CREATE POLICY "enable_insert_for_users_and_admins" ON grading_entries
  FOR INSERT 
  TO authenticated
  WITH CHECK (
    consumer_id = auth.uid() OR
    EXISTS (
      SELECT 1 FROM users
      WHERE users.id = auth.uid()
      AND users.role = 'admin'
    )
  );

-- Policy for admins to update entries
CREATE POLICY "enable_update_for_admins" ON grading_entries
  FOR UPDATE
  TO authenticated
  USING (
    EXISTS (
      SELECT 1 FROM users
      WHERE users.id = auth.uid()
      AND users.role = 'admin'
    )
  )
  WITH CHECK (
    EXISTS (
      SELECT 1 FROM users
      WHERE users.id = auth.uid()
      AND users.role = 'admin'
    )
  );

-- Policy for users to view their own entries and admins to view all
CREATE POLICY "enable_view_entries" ON grading_entries
  FOR SELECT
  TO authenticated
  USING (
    consumer_id = auth.uid() OR
    EXISTS (
      SELECT 1 FROM users
      WHERE users.id = auth.uid()
      AND users.role = 'admin'
    )
  );

-- Policy for users to view their own data and admins to view all users
CREATE POLICY "enable_select_users" ON users
  FOR SELECT
  TO authenticated
  USING (
    id = auth.uid() OR
    EXISTS (
      SELECT 1 FROM users
      WHERE users.id = auth.uid()
      AND users.role = 'admin'
    )
  );

-- Ensure RLS is enabled on both tables
ALTER TABLE users ENABLE ROW LEVEL SECURITY;
ALTER TABLE grading_entries ENABLE ROW LEVEL SECURITY;