/*
  # Update User Roles and Add Price Field

  1. Changes
    - Add price field to grading_entries
    - Update RLS policies for customer and admin roles
    - Remove old policies and create new ones
*/

-- Add price column to grading_entries
ALTER TABLE grading_entries
ADD COLUMN price decimal(10,2) DEFAULT 0.00;

-- Drop existing policies
DROP POLICY IF EXISTS "Consumers can read own entries" ON grading_entries;
DROP POLICY IF EXISTS "Consumers can create entries" ON grading_entries;
DROP POLICY IF EXISTS "Admins can read all entries" ON grading_entries;
DROP POLICY IF EXISTS "Admins can update all entries" ON grading_entries;

-- Create new policies for customers
CREATE POLICY "Customers can read own entries"
  ON grading_entries
  FOR SELECT
  TO authenticated
  USING (
    auth.uid() = consumer_id 
    AND (auth.jwt()->>'role' = 'customer' OR auth.jwt()->>'role' = 'admin')
  );

-- Create policies for admins
CREATE POLICY "Admins can read all entries"
  ON grading_entries
  FOR SELECT
  TO authenticated
  USING (auth.jwt()->>'role' = 'admin');

CREATE POLICY "Admins can update all entries"
  ON grading_entries
  FOR UPDATE
  TO authenticated
  USING (auth.jwt()->>'role' = 'admin')
  WITH CHECK (auth.jwt()->>'role' = 'admin');

CREATE POLICY "Admins can insert entries"
  ON grading_entries
  FOR INSERT
  TO authenticated
  WITH CHECK (auth.jwt()->>'role' = 'admin');

-- Update check_if_admin function
CREATE OR REPLACE FUNCTION check_if_admin()
RETURNS boolean
LANGUAGE plpgsql
SECURITY DEFINER
AS $$
BEGIN
  RETURN (SELECT COALESCE(auth.jwt()->>'role' = 'admin', false));
END;
$$;