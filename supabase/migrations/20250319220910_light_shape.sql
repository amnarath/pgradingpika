/*
  # Add Admin Check Function

  1. Changes
    - Add a PostgreSQL function to check if the current user has admin role
    - Function returns boolean indicating if user has admin privileges
*/

-- Create function to check if current user is admin
CREATE OR REPLACE FUNCTION check_if_admin()
RETURNS boolean
LANGUAGE plpgsql
SECURITY DEFINER
AS $$
BEGIN
  RETURN EXISTS (
    SELECT 1
    FROM auth.users
    WHERE id = auth.uid()
    AND raw_user_meta_data->>'role' = 'admin'
  );
END;
$$;