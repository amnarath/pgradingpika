/*
  # Fix get_users_with_verification function and RLS policies

  1. Changes
    - Drop and recreate get_users_with_verification function
    - Update RLS policies for users table
    - Grant necessary permissions

  2. Security
    - Maintain proper access control
    - Set security definer and search path
*/

-- Drop existing function first
DROP FUNCTION IF EXISTS get_users_with_verification();

-- Create the function with new return type
CREATE OR REPLACE FUNCTION get_users_with_verification()
RETURNS TABLE (
  id uuid,
  email text,
  role text,
  created_at timestamptz,
  email_confirmed_at timestamptz
)
SECURITY DEFINER
SET search_path = public
LANGUAGE plpgsql
AS $$
BEGIN
  -- Check if the current user is an admin
  IF NOT EXISTS (
    SELECT 1 FROM users 
    WHERE id = auth.uid() 
    AND role = 'admin'
  ) THEN
    RAISE EXCEPTION 'Access denied';
  END IF;

  RETURN QUERY
  SELECT 
    u.id,
    u.email,
    u.role,
    u.created_at,
    au.email_confirmed_at
  FROM users u
  LEFT JOIN auth.users au ON au.id = u.id
  ORDER BY u.created_at DESC;
END;
$$;

-- Enable RLS on users table if not already enabled
ALTER TABLE users ENABLE ROW LEVEL SECURITY;

-- Drop existing policies
DROP POLICY IF EXISTS "users_select_policy" ON users;
DROP POLICY IF EXISTS "users_insert_policy" ON users;
DROP POLICY IF EXISTS "users_update_policy" ON users;

-- Create new policies
CREATE POLICY "users_select_policy" ON users
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

CREATE POLICY "users_insert_policy" ON users
  FOR INSERT
  TO authenticated
  WITH CHECK (
    EXISTS (
      SELECT 1 FROM users
      WHERE users.id = auth.uid()
      AND users.role = 'admin'
    )
  );

CREATE POLICY "users_update_policy" ON users
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

-- Grant necessary permissions
GRANT EXECUTE ON FUNCTION get_users_with_verification() TO authenticated;
GRANT SELECT ON auth.users TO authenticated;