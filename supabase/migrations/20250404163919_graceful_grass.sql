/*
  # Fix RLS policies for users and grading entries

  1. Security Changes
    - Add proper RLS policies for users table
    - Update grading entries policies to ensure proper access
    - Ensure users can access their own data
    - Maintain admin access to all data

  2. Changes
    - Enable RLS on users table
    - Add SELECT policy for users table
    - Update grading entries policies
*/

-- Enable RLS on users table if not already enabled
ALTER TABLE users ENABLE ROW LEVEL SECURITY;

-- Drop existing policies if they exist
DROP POLICY IF EXISTS "Users can read own data" ON users;
DROP POLICY IF EXISTS "Enable insert for users and admins" ON grading_entries;
DROP POLICY IF EXISTS "Enable insert for admins" ON grading_entries;
DROP POLICY IF EXISTS "Enable update for admins" ON grading_entries;
DROP POLICY IF EXISTS "Users can view own entries" ON grading_entries;

-- Create policy for users to read their own data
CREATE POLICY "Users can read own data" ON users
  FOR SELECT
  TO authenticated
  USING (
    id = auth.uid() OR
    EXISTS (
      SELECT 1
      FROM users u
      WHERE u.id = auth.uid()
      AND u.role = 'admin'
    )
  );

-- Policy for users to insert their own entries and admins to insert any entries
CREATE POLICY "Enable insert for users and admins" ON grading_entries
  FOR INSERT 
  TO authenticated
  WITH CHECK (
    consumer_id = auth.uid() OR
    EXISTS (
      SELECT 1
      FROM users
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
      SELECT 1
      FROM users
      WHERE users.id = auth.uid()
      AND users.role = 'admin'
    )
  )
  WITH CHECK (
    EXISTS (
      SELECT 1
      FROM users
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
      SELECT 1
      FROM users
      WHERE users.id = auth.uid()
      AND users.role = 'admin'
    )
  );