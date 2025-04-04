/*
  # Fix ambiguous id reference in get_users_with_verification function

  1. Changes
    - Create a new function that explicitly references table columns to avoid ambiguity
    - Drop the old function if it exists
    - Add proper table references for id columns

  2. Security
    - Function remains accessible only to authenticated users
    - Maintains existing security context
*/

-- Drop the existing function if it exists
DROP FUNCTION IF EXISTS get_users_with_verification;

-- Create the new function with explicit column references
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
  RETURN QUERY
  SELECT 
    users.id,
    users.email,
    au.email_confirmed_at
  FROM public.users
  LEFT JOIN auth.users au ON au.id = users.id
  ORDER BY users.created_at DESC;
END;
$$;

-- Grant execute permission to authenticated users
GRANT EXECUTE ON FUNCTION get_users_with_verification() TO authenticated;