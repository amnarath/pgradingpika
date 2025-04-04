/*
  # Update RLS policies for super admin access

  1. Security Changes
    - Grant super admin access to admin users
    - Simplify policy conditions
    - Fix entry creation permissions

  2. Changes
    - Update all policies to use security definer functions
    - Add bypass RLS function for admins
    - Ensure proper role assignment
*/

-- Drop existing policies
DROP POLICY IF EXISTS "admin_insert_entries" ON grading_entries;
DROP POLICY IF EXISTS "admin_update_entries" ON grading_entries;
DROP POLICY IF EXISTS "view_entries" ON grading_entries;

-- Enable RLS
ALTER TABLE grading_entries ENABLE ROW LEVEL SECURITY;

-- Create function to check admin role with security definer
CREATE OR REPLACE FUNCTION is_admin()
RETURNS boolean AS $$
BEGIN
  -- Use security definer to bypass RLS
  RETURN EXISTS (
    SELECT 1 FROM public.users
    WHERE id = auth.uid()
    AND role = 'admin'
  );
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- Create function to bypass RLS for admins
CREATE OR REPLACE FUNCTION admin_check()
RETURNS boolean AS $$
BEGIN
  -- Automatically grant access if user is admin
  IF EXISTS (
    SELECT 1 FROM public.users
    WHERE id = auth.uid()
    AND role = 'admin'
  ) THEN
    RETURN TRUE;
  END IF;
  RETURN FALSE;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- Policy for admins to insert entries (super admin access)
CREATE POLICY "admin_insert_entries" ON grading_entries
  FOR INSERT 
  TO authenticated
  WITH CHECK (admin_check());

-- Policy for admins to update entries (super admin access)
CREATE POLICY "admin_update_entries" ON grading_entries
  FOR UPDATE
  TO authenticated
  USING (admin_check())
  WITH CHECK (admin_check());

-- Policy for viewing entries (super admin access for admins)
CREATE POLICY "view_entries" ON grading_entries
  FOR SELECT
  TO authenticated
  USING (
    consumer_id = auth.uid() OR admin_check()
  );

-- Update user creation trigger to handle roles properly
CREATE OR REPLACE FUNCTION handle_new_user()
RETURNS TRIGGER AS $$
BEGIN
  INSERT INTO public.users (id, email, role)
  VALUES (
    NEW.id,
    NEW.email,
    COALESCE(NEW.raw_user_meta_data->>'role', 'user')
  )
  ON CONFLICT (id) DO UPDATE
  SET email = EXCLUDED.email,
      role = COALESCE(NEW.raw_user_meta_data->>'role', users.role, 'user');
  RETURN NEW;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- Recreate the trigger
DROP TRIGGER IF EXISTS on_auth_user_created ON auth.users;
CREATE TRIGGER on_auth_user_created
  AFTER INSERT ON auth.users
  FOR EACH ROW EXECUTE FUNCTION handle_new_user();