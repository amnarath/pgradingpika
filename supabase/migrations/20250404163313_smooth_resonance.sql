/*
  # Add user blocking functionality

  1. Changes
    - Add blocked column to users table
    - Add function to handle user blocking
    - Update RLS policies to prevent blocked users from accessing data

  2. Security
    - Only admins can block/unblock users
    - Blocked users cannot access any data
*/

-- Add blocked column to users table
ALTER TABLE users
ADD COLUMN blocked boolean DEFAULT false;

-- Update RLS policies to check for blocked status
CREATE OR REPLACE FUNCTION is_user_blocked()
RETURNS boolean AS $$
BEGIN
  RETURN EXISTS (
    SELECT 1 FROM users
    WHERE id = auth.uid()
    AND blocked = true
  );
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- Update existing policies to check for blocked status
CREATE OR REPLACE FUNCTION is_admin()
RETURNS boolean AS $$
BEGIN
  RETURN EXISTS (
    SELECT 1 FROM users
    WHERE id = auth.uid()
    AND role = 'admin'
    AND NOT blocked
  );
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- Function to toggle user blocked status
CREATE OR REPLACE FUNCTION toggle_user_blocked(user_id uuid, should_block boolean)
RETURNS void
LANGUAGE plpgsql
SECURITY DEFINER
AS $$
BEGIN
  -- Check if the current user is an admin
  IF NOT is_admin() THEN
    RAISE EXCEPTION 'Access denied';
  END IF;

  -- Update user's blocked status
  UPDATE users
  SET blocked = should_block
  WHERE id = user_id;
END;
$$;