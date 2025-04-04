/*
  # Fix admin role check and RLS policies

  1. Security Changes
    - Improve admin role checking function
    - Add proper error handling
    - Fix user role assignment

  2. Changes
    - Update admin check function to be more robust
    - Ensure proper role assignment during user creation
    - Fix RLS policies for grading entries
*/

-- Drop existing policies and functions
DROP POLICY IF EXISTS "admin_insert_entries" ON grading_entries;
DROP POLICY IF EXISTS "admin_update_entries" ON grading_entries;
DROP POLICY IF EXISTS "view_entries" ON grading_entries;

-- Create improved admin check function
CREATE OR REPLACE FUNCTION is_admin()
RETURNS boolean AS $$
DECLARE
  _user_id uuid;
  _role text;
BEGIN
  -- Get the current user ID
  _user_id := auth.uid();
  
  -- If no user is authenticated, return false
  IF _user_id IS NULL THEN
    RETURN false;
  END IF;

  -- Get the user's role
  SELECT role INTO _role
  FROM public.users
  WHERE id = _user_id;

  -- Return true if the user is an admin
  RETURN _role = 'admin';
EXCEPTION
  WHEN OTHERS THEN
    RETURN false;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- Create function to handle user creation with proper role
CREATE OR REPLACE FUNCTION handle_new_user()
RETURNS TRIGGER AS $$
BEGIN
  -- Insert new user with role, handling conflicts
  INSERT INTO public.users (id, email, role)
  VALUES (
    NEW.id,
    NEW.email,
    COALESCE(NEW.raw_user_meta_data->>'role', 'user')
  )
  ON CONFLICT (id) DO UPDATE
  SET 
    email = EXCLUDED.email,
    role = COALESCE(NEW.raw_user_meta_data->>'role', users.role, 'user'),
    updated_at = now();
  
  RETURN NEW;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- Recreate the trigger
DROP TRIGGER IF EXISTS on_auth_user_created ON auth.users;
CREATE TRIGGER on_auth_user_created
  AFTER INSERT ON auth.users
  FOR EACH ROW
  EXECUTE FUNCTION handle_new_user();

-- Enable RLS
ALTER TABLE grading_entries ENABLE ROW LEVEL SECURITY;

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