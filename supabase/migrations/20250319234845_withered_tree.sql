/*
  # Fix ambiguous column reference in users verification function

  1. Changes
    - Fix ambiguous id column reference by using table alias
    - Maintain proper security checks
    - Keep existing functionality
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
    SELECT 1 FROM public.users pu
    WHERE pu.id = auth.uid()
    AND pu.role = 'admin'
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