/*
  # Fix user management and RLS policies

  1. Security Changes
    - Update RLS policies to use both JWT claims and database roles
    - Ensure proper admin access to user management
    - Fix user visibility issues

  2. Changes
    - Drop existing policies
    - Create new comprehensive policies
    - Update admin check function
    - Add trigger to sync JWT claims with user role
*/

-- Drop existing policies
DROP POLICY IF EXISTS "users_select_policy" ON users;
DROP POLICY IF EXISTS "admin_insert_policy" ON users;
DROP POLICY IF EXISTS "admin_update_policy" ON users;

-- Enable RLS
ALTER TABLE users ENABLE ROW LEVEL SECURITY;

-- Create function to check admin status using both JWT and database role
CREATE OR REPLACE FUNCTION is_admin()
RETURNS boolean AS $$
BEGIN
  RETURN (
    -- Check JWT claim
    (auth.jwt() ->> 'role')::text = 'admin'
    OR
    -- Fallback to database check
    EXISTS (
      SELECT 1
      FROM auth.users
      WHERE id = auth.uid()
      AND raw_user_meta_data->>'role' = 'admin'
    )
  );
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- Create function to sync user role with JWT claims
CREATE OR REPLACE FUNCTION sync_user_role()
RETURNS trigger AS $$
BEGIN
  -- Update auth.users metadata when role changes
  UPDATE auth.users
  SET raw_user_meta_data = 
    CASE 
      WHEN raw_user_meta_data IS NULL THEN 
        jsonb_build_object('role', NEW.role)
      ELSE 
        raw_user_meta_data || jsonb_build_object('role', NEW.role)
    END
  WHERE id = NEW.id;
  
  RETURN NEW;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- Create trigger for role synchronization
DROP TRIGGER IF EXISTS sync_user_role_trigger ON users;
CREATE TRIGGER sync_user_role_trigger
  AFTER INSERT OR UPDATE OF role ON users
  FOR EACH ROW
  EXECUTE FUNCTION sync_user_role();

-- Create policies
CREATE POLICY "users_select_policy" ON users
  FOR SELECT
  TO authenticated
  USING (
    is_admin() OR id = auth.uid()
  );

CREATE POLICY "admin_insert_policy" ON users
  FOR INSERT
  TO authenticated
  WITH CHECK (
    is_admin()
  );

CREATE POLICY "admin_update_policy" ON users
  FOR UPDATE
  TO authenticated
  USING (
    is_admin()
  )
  WITH CHECK (
    is_admin()
  );