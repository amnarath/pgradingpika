/*
  # Fix RLS policies and user creation

  1. Security Changes
    - Add proper RLS policies for grading entries
    - Add trigger for user role management
    - Fix user creation flow

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

-- Policy for admins to insert entries
CREATE POLICY "admin_insert_entries" ON grading_entries
  FOR INSERT 
  TO authenticated
  WITH CHECK (is_admin());

-- Policy for admins to update entries
CREATE POLICY "admin_update_entries" ON grading_entries
  FOR UPDATE
  TO authenticated
  USING (is_admin())
  WITH CHECK (is_admin());

-- Policy for viewing entries
CREATE POLICY "view_entries" ON grading_entries
  FOR SELECT
  TO authenticated
  USING (
    consumer_id = auth.uid() OR is_admin()
  );

-- Create trigger to ensure user record exists
CREATE OR REPLACE FUNCTION handle_new_user()
RETURNS TRIGGER AS $$
BEGIN
  INSERT INTO public.users (id, email, role)
  VALUES (new.id, new.email, COALESCE(new.raw_user_meta_data->>'role', 'user'));
  RETURN new;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- Create the trigger
DROP TRIGGER IF EXISTS on_auth_user_created ON auth.users;
CREATE TRIGGER on_auth_user_created
  AFTER INSERT ON auth.users
  FOR EACH ROW EXECUTE FUNCTION handle_new_user();