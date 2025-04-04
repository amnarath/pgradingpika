/*
  # Complete RLS rebuild for proper permission management

  1. Security Changes
    - Implement comprehensive RLS policies for users and grading_entries tables
    - Define clear role-based access control
    - Ensure proper data isolation between users
    - Implement secure admin privileges

  2. Changes
    - Drop existing policies for clean slate
    - Create enhanced admin check function
    - Set up policies for users table
    - Set up policies for grading_entries table
    - Implement proper security checks
*/

-- Drop all existing policies
DROP POLICY IF EXISTS "admin_insert_grading_entries" ON grading_entries;
DROP POLICY IF EXISTS "admin_update_grading_entries" ON grading_entries;
DROP POLICY IF EXISTS "view_grading_entries" ON grading_entries;
DROP POLICY IF EXISTS "Users can read own data" ON users;
DROP POLICY IF EXISTS "Admins can read all users" ON users;
DROP POLICY IF EXISTS "Only admins can insert users" ON users;
DROP POLICY IF EXISTS "Only admins can update users" ON users;

-- Enhanced admin check function
CREATE OR REPLACE FUNCTION is_admin()
RETURNS boolean AS $$
BEGIN
  -- Check if the user exists and has admin role
  RETURN EXISTS (
    SELECT 1
    FROM public.users
    WHERE id = auth.uid()
    AND role = 'admin'
  );
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- Enable RLS on both tables
ALTER TABLE users ENABLE ROW LEVEL SECURITY;
ALTER TABLE grading_entries ENABLE ROW LEVEL SECURITY;

-- Users table policies
CREATE POLICY "users_read_own" ON users
  FOR SELECT
  TO authenticated
  USING (
    id = auth.uid() OR
    is_admin()
  );

CREATE POLICY "admin_insert_users" ON users
  FOR INSERT
  TO authenticated
  WITH CHECK (
    is_admin()
  );

CREATE POLICY "admin_update_users" ON users
  FOR UPDATE
  TO authenticated
  USING (is_admin())
  WITH CHECK (is_admin());

-- Grading entries policies
CREATE POLICY "entries_read" ON grading_entries
  FOR SELECT
  TO authenticated
  USING (
    consumer_id = auth.uid() OR
    is_admin()
  );

CREATE POLICY "admin_insert_entries" ON grading_entries
  FOR INSERT
  TO authenticated
  WITH CHECK (
    is_admin()
  );

CREATE POLICY "admin_update_entries" ON grading_entries
  FOR UPDATE
  TO authenticated
  USING (is_admin())
  WITH CHECK (is_admin());

-- Create function to validate user role changes
CREATE OR REPLACE FUNCTION validate_role_change()
RETURNS trigger AS $$
BEGIN
  -- Only allow role changes by admin
  IF OLD.role IS DISTINCT FROM NEW.role AND NOT is_admin() THEN
    RAISE EXCEPTION 'Only administrators can change user roles';
  END IF;
  RETURN NEW;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- Create trigger for role changes
DROP TRIGGER IF EXISTS ensure_role_change_auth ON users;
CREATE TRIGGER ensure_role_change_auth
  BEFORE UPDATE ON users
  FOR EACH ROW
  EXECUTE FUNCTION validate_role_change();

-- Create function to validate payment status changes
CREATE OR REPLACE FUNCTION validate_payment_status_change()
RETURNS trigger AS $$
BEGIN
  -- Only allow payment status changes by admin
  IF OLD.payment_status IS DISTINCT FROM NEW.payment_status AND NOT is_admin() THEN
    RAISE EXCEPTION 'Only administrators can change payment status';
  END IF;
  RETURN NEW;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- Create trigger for payment status changes
DROP TRIGGER IF EXISTS ensure_payment_status_auth ON grading_entries;
CREATE TRIGGER ensure_payment_status_auth
  BEFORE UPDATE ON grading_entries
  FOR EACH ROW
  EXECUTE FUNCTION validate_payment_status_change();