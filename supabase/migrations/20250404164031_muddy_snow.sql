/*
  # Update RLS policies for grading entries

  1. Security Changes
    - Modify policies to use auth.jwt() for role checks
    - Remove recursive user table queries
    - Ensure proper access control for admins and users

  2. Changes
    - Update INSERT policy for admins
    - Update UPDATE policy for admins
    - Update SELECT policy for users and admins
    - Fix infinite recursion issue
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
    (auth.jwt() ->> 'role')::text = 'admin'
  );

-- Policy for admins to update entries
CREATE POLICY "Enable update for admins" ON grading_entries
  FOR UPDATE
  TO authenticated
  USING (
    (auth.jwt() ->> 'role')::text = 'admin'
  )
  WITH CHECK (
    (auth.jwt() ->> 'role')::text = 'admin'
  );

-- Policy for users to view their own entries and admins to view all
CREATE POLICY "Users can view own entries" ON grading_entries
  FOR SELECT
  TO authenticated
  USING (
    consumer_id = auth.uid() OR
    (auth.jwt() ->> 'role')::text = 'admin'
  );