/*
  # Fix RLS policies for grading entries

  1. Changes
    - Simplify and fix RLS policies for grading entries
    - Ensure admin users can perform all operations
    - Fix policy naming and consistency

  2. Security
    - Maintain proper access control
    - Ensure admin privileges work correctly
    - Keep user data isolation
*/

-- First, drop existing policies to avoid conflicts
DROP POLICY IF EXISTS "admin_insert_entries" ON grading_entries;
DROP POLICY IF EXISTS "admin_update_entries" ON grading_entries;
DROP POLICY IF EXISTS "view_entries" ON grading_entries;
DROP POLICY IF EXISTS "Enable insert for admins" ON grading_entries;
DROP POLICY IF EXISTS "Enable update for admins" ON grading_entries;
DROP POLICY IF EXISTS "Users can view own entries" ON grading_entries;

-- Create a more reliable admin check function
CREATE OR REPLACE FUNCTION is_admin()
RETURNS boolean AS $$
BEGIN
  RETURN EXISTS (
    SELECT 1
    FROM public.users
    WHERE id = auth.uid()
    AND role = 'admin'
  );
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- Enable RLS on the table
ALTER TABLE grading_entries ENABLE ROW LEVEL SECURITY;

-- Create new, simplified policies
-- Insert policy for admins
CREATE POLICY "admin_insert_grading_entries" ON grading_entries
  FOR INSERT
  TO authenticated
  WITH CHECK (
    is_admin()
  );

-- Update policy for admins
CREATE POLICY "admin_update_grading_entries" ON grading_entries
  FOR UPDATE
  TO authenticated
  USING (is_admin())
  WITH CHECK (is_admin());

-- Select policy for both users and admins
CREATE POLICY "view_grading_entries" ON grading_entries
  FOR SELECT
  TO authenticated
  USING (
    consumer_id = auth.uid() OR
    is_admin()
  );