/*
  # Add function to get users with verification status

  1. Changes
    - Add PostgreSQL function to get users with email verification status
    - Function returns user data including email_confirmed_at
    - Ensure proper security and access control
*/

-- Create function to get users with verification status
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
  -- Check if the current user is an admin
  IF NOT EXISTS (
    SELECT 1 FROM public.users
    WHERE id = auth.uid()
    AND role = 'admin'
  ) THEN
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