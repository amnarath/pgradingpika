/*
  # Add admin check function

  1. New Functions
    - `check_if_admin`: RPC function to check if the current user is an admin
    
  2. Security
    - Function is accessible to authenticated users only
*/

CREATE OR REPLACE FUNCTION check_if_admin()
RETURNS boolean
LANGUAGE plpgsql
SECURITY DEFINER
AS $$
BEGIN
  RETURN (
    SELECT COALESCE(
      (raw_user_meta_data->>'role') = 'admin',
      false
    )
    FROM auth.users
    WHERE id = auth.uid()
  );
END;
$$;