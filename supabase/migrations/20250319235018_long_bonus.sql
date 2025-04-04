/*
  # Update admin check and user verification functions

  1. Changes
    - Update is_admin() function to use raw_user_meta_data
    - Add user verification function
    - Maintain existing policy dependencies
*/

-- Drop the get_users_with_verification function if it exists
DROP FUNCTION IF EXISTS get_users_with_verification();

-- Update the is_admin function without dropping it
CREATE OR REPLACE FUNCTION is_admin()
RETURNS boolean AS $$
BEGIN
  RETURN EXISTS (
    SELECT 1 FROM auth.users
    WHERE id = auth.uid()
    AND (raw_user_meta_data->>'role')::text = 'admin'
  );
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- Create users verification function with proper security context
CREATE OR REPLACE FUNCTION get_users_with_verification()
RETURNS TABLE (
  id uuid,
  email text,
  email_confirmed_at timestamptz
) 
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
BEGIN
  -- Check if the current user is an admin
  IF NOT is_admin() THEN
    RAISE EXCEPTION 'Access denied';
  END IF;

  RETURN QUERY
  SELECT 
    au.id,
    au.email,
    au.email_confirmed_at
  FROM auth.users au
  ORDER BY au.created_at DESC;
END;
$$;