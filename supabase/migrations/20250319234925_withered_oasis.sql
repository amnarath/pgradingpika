/*
  # Fix admin access check in RPC function

  1. Changes
    - Update admin check to use both JWT and database role
    - Ensure proper access control for admin users
    - Maintain security while fixing access issues
*/

-- Create or replace the admin check function
CREATE OR REPLACE FUNCTION is_admin()
RETURNS boolean AS $$
BEGIN
  RETURN EXISTS (
    SELECT 1 FROM public.users
    WHERE id = auth.uid()
    AND role = 'admin'
  );
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- Create or replace the users verification function
CREATE OR REPLACE FUNCTION get_users_with_verification()
RETURNS TABLE (
  id uuid,
  email text,
  email_confirmed_at timestamptz
) 
LANGUAGE plpgsql
SECURITY DEFINER
AS $$
BEGIN
  -- Check if the current user is an admin using the is_admin function
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