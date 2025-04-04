/*
  # Update RLS policies for grading entries

  1. Security Changes
    - Modify policies to properly handle admin role
    - Simplify policy conditions
    - Ensure proper access control for admins and users

  2. Changes
    - Update INSERT policy for admins
    - Update UPDATE policy for admins
    - Update SELECT policy for users and admins
*/

-- Enable RLS on grading_entries if not already enabled
ALTER TABLE grading_entries ENABLE ROW LEVEL SECURITY;

-- Drop existing policies if they exist
DROP POLICY IF EXISTS "Enable insert for admins" ON grading_entries;
DROP POLICY IF EXISTS "Enable update for admins" ON grading_entries;
DROP POLICY IF EXISTS "Users can view own entries" ON grading_entries;

-- Policy for admins to insert entries
CREATE POLICY "Enable insert for admins" ON grading_entries
  FOR INSERT 
  TO authenticated
  WITH CHECK (
    EXISTS (
      SELECT 1 FROM users
      WHERE users.id = auth.uid()
      AND users.role = 'admin'
    )
  );

-- Policy for admins to update entries
CREATE POLICY "Enable update for admins" ON grading_entries
  FOR UPDATE
  TO authenticated
  USING (
    EXISTS (
      SELECT 1 FROM users
      WHERE users.id = auth.uid()
      AND users.role = 'admin'
    )
  )
  WITH CHECK (
    EXISTS (
      SELECT 1 FROM users
      WHERE users.id = auth.uid()
      AND users.role = 'admin'
    )
  );

-- Policy for users to view their own entries and admins to view all
CREATE POLICY "Users can view own entries" ON grading_entries
  FOR SELECT
  TO authenticated
  USING (
    consumer_id = auth.uid() OR
    EXISTS (
      SELECT 1 FROM users
      WHERE users.id = auth.uid()
      AND users.role = 'admin'
    )
  );