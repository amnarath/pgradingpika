/*
  # Fix RLS policies and add user triggers

  1. Security Changes
    - Add proper RLS policies for grading entries
    - Add trigger for user role management
    - Ensure proper access control

  2. Changes
    - Update all policies to use proper role checks
    - Add trigger for maintaining user roles
    - Clean up existing policies
*/

-- Drop existing policies
DROP POLICY IF EXISTS "Enable insert for admins" ON grading_entries;
DROP POLICY IF EXISTS "Enable update for admins" ON grading_entries;
DROP POLICY IF EXISTS "Users can view own entries" ON grading_entries;

-- Enable RLS
ALTER TABLE grading_entries ENABLE ROW LEVEL SECURITY;

-- Create function to check admin role
CREATE OR REPLACE FUNCTION check_admin_role()
RETURNS boolean AS $$
BEGIN
  RETURN EXISTS (
    SELECT 1 FROM users
    WHERE users.id = auth.uid()
    AND users.role = 'admin'
  );
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- Policy for admins to insert entries
CREATE POLICY "admins_insert_entries" ON grading_entries
  FOR INSERT 
  TO authenticated
  WITH CHECK (check_admin_role());

-- Policy for admins to update entries
CREATE POLICY "admins_update_entries" ON grading_entries
  FOR UPDATE
  TO authenticated
  USING (check_admin_role())
  WITH CHECK (check_admin_role());

-- Policy for viewing entries
CREATE POLICY "view_entries" ON grading_entries
  FOR SELECT
  TO authenticated
  USING (
    consumer_id = auth.uid() OR check_admin_role()
  );

-- Trigger to ensure user role is set
CREATE OR REPLACE FUNCTION ensure_user_role()
RETURNS TRIGGER AS $$
BEGIN
  IF NEW.role IS NULL THEN
    NEW.role := 'user';
  END IF;
  RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER set_user_role
  BEFORE INSERT OR UPDATE ON users
  FOR EACH ROW
  EXECUTE FUNCTION ensure_user_role();