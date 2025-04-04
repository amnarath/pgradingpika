/*
  # Fix admin access and RLS policies

  1. Changes
    - Update admin check function to use raw_user_meta_data
    - Fix RLS policies for proper admin access
    - Ensure proper role checking

  2. Security
    - Maintain security while fixing access issues
    - Keep existing policy structure
*/

-- Update admin check function without dropping it
CREATE OR REPLACE FUNCTION is_admin()
RETURNS boolean
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
BEGIN
  RETURN (
    SELECT EXISTS (
      SELECT 1
      FROM auth.users
      WHERE id = auth.uid()
      AND (raw_user_meta_data->>'role')::text = 'admin'
      AND NOT EXISTS (
        SELECT 1
        FROM users
        WHERE id = auth.uid()
        AND blocked = true
      )
    )
  );
END;
$$;

-- Update RLS policies for users table
DROP POLICY IF EXISTS "users_select_policy" ON users;
DROP POLICY IF EXISTS "admin_insert_policy" ON users;
DROP POLICY IF EXISTS "admin_update_policy" ON users;

CREATE POLICY "users_select_policy" ON users
  FOR SELECT
  TO authenticated
  USING (
    id = auth.uid() OR
    (
      SELECT EXISTS (
        SELECT 1
        FROM auth.users
        WHERE id = auth.uid()
        AND (raw_user_meta_data->>'role')::text = 'admin'
      )
    )
  );

CREATE POLICY "admin_insert_policy" ON users
  FOR INSERT
  TO authenticated
  WITH CHECK (
    (
      SELECT EXISTS (
        SELECT 1
        FROM auth.users
        WHERE id = auth.uid()
        AND (raw_user_meta_data->>'role')::text = 'admin'
      )
    )
  );

CREATE POLICY "admin_update_policy" ON users
  FOR UPDATE
  TO authenticated
  USING (
    (
      SELECT EXISTS (
        SELECT 1
        FROM auth.users
        WHERE id = auth.uid()
        AND (raw_user_meta_data->>'role')::text = 'admin'
      )
    )
  )
  WITH CHECK (
    (
      SELECT EXISTS (
        SELECT 1
        FROM auth.users
        WHERE id = auth.uid()
        AND (raw_user_meta_data->>'role')::text = 'admin'
      )
    )
  );

-- Update RLS policies for grading_entries
DROP POLICY IF EXISTS "entries_read" ON grading_entries;
DROP POLICY IF EXISTS "admin_insert_entries" ON grading_entries;
DROP POLICY IF EXISTS "admin_update_entries" ON grading_entries;

CREATE POLICY "entries_read" ON grading_entries
  FOR SELECT
  TO authenticated
  USING (
    consumer_id = auth.uid() OR
    (
      SELECT EXISTS (
        SELECT 1
        FROM auth.users
        WHERE id = auth.uid()
        AND (raw_user_meta_data->>'role')::text = 'admin'
      )
    )
  );

CREATE POLICY "admin_insert_entries" ON grading_entries
  FOR INSERT
  TO authenticated
  WITH CHECK (
    (
      SELECT EXISTS (
        SELECT 1
        FROM auth.users
        WHERE id = auth.uid()
        AND (raw_user_meta_data->>'role')::text = 'admin'
      )
    )
  );

CREATE POLICY "admin_update_entries" ON grading_entries
  FOR UPDATE
  TO authenticated
  USING (
    (
      SELECT EXISTS (
        SELECT 1
        FROM auth.users
        WHERE id = auth.uid()
        AND (raw_user_meta_data->>'role')::text = 'admin'
      )
    )
  )
  WITH CHECK (
    (
      SELECT EXISTS (
        SELECT 1
        FROM auth.users
        WHERE id = auth.uid()
        AND (raw_user_meta_data->>'role')::text = 'admin'
      )
    )
  );