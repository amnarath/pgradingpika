/*
  # Fix email verification function return type

  1. Changes
    - Update get_users_with_verification function to use text type for email
    - Ensure consistent return types with auth.users table
*/

-- Drop existing function
DROP FUNCTION IF EXISTS get_users_with_verification();

-- Recreate function with correct return type
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
    au.email::text,  -- Explicitly cast to text
    au.email_confirmed_at
  FROM auth.users au
  ORDER BY au.created_at DESC;
END;
$$;