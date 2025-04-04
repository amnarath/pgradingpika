/*
  # Add email verification control function

  1. Changes
    - Add function to toggle email verification status
    - Ensure proper admin access control
    - Maintain security context
*/

-- Create function to toggle email verification status
CREATE OR REPLACE FUNCTION toggle_email_verification(user_id uuid, is_verified boolean)
RETURNS void
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
BEGIN
  -- Check if the current user is an admin
  IF NOT is_admin() THEN
    RAISE EXCEPTION 'Access denied';
  END IF;

  -- Update email_confirmed_at in auth.users
  UPDATE auth.users
  SET email_confirmed_at = CASE 
    WHEN is_verified THEN CURRENT_TIMESTAMP
    ELSE NULL
  END
  WHERE id = user_id;
END;
$$;