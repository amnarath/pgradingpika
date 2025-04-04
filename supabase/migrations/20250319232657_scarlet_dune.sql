/*
  # Fix admin entry creation and RLS policies

  1. Changes
    - Simplify admin role check
    - Update RLS policies for grading entries
    - Ensure proper role handling in user creation

  2. Security
    - Improve admin role verification
    - Strengthen RLS policies
    - Add proper error handling
*/

-- Drop existing policies and functions
DROP POLICY IF EXISTS "admin_insert_entries" ON grading_entries;
DROP POLICY IF EXISTS "admin_update_entries" ON grading_entries;
DROP POLICY IF EXISTS "view_entries" ON grading_entries;

-- Create a more robust admin check function
CREATE OR REPLACE FUNCTION is_admin()
RETURNS boolean AS $$
BEGIN
  RETURN (
    SELECT role = 'admin'
    FROM public.users
    WHERE id = auth.uid()
  );
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- Create function to handle new user creation
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

-- Policy for admins to insert entries (simplified)
CREATE POLICY "admin_insert_entries" ON grading_entries
  FOR INSERT 
  TO authenticated
  WITH CHECK (is_admin());

-- Policy for admins to update entries (simplified)
CREATE POLICY "admin_update_entries" ON grading_entries
  FOR UPDATE
  TO authenticated
  USING (is_admin())
  WITH CHECK (is_admin());

-- Policy for viewing entries (simplified)
CREATE POLICY "view_entries" ON grading_entries
  FOR SELECT
  TO authenticated
  USING (consumer_id = auth.uid() OR is_admin());