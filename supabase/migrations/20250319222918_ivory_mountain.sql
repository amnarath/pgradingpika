/*
  # Fix RLS Policies and User Roles

  1. Changes
    - Simplify RLS policies
    - Fix user role handling
    - Ensure proper data access
*/

-- Drop existing policies
DROP POLICY IF EXISTS "Customers can read own entries" ON grading_entries;
DROP POLICY IF EXISTS "Admins can read all entries" ON grading_entries;
DROP POLICY IF EXISTS "Admins can update all entries" ON grading_entries;
DROP POLICY IF EXISTS "Admins can insert entries" ON grading_entries;

-- Create simplified policies
CREATE POLICY "Enable read access for users"
  ON grading_entries
  FOR SELECT
  TO authenticated
  USING (
    auth.uid() = consumer_id OR
    (SELECT COALESCE((auth.jwt() ->> 'role'::text) = 'admin'::text, false))
  );

CREATE POLICY "Enable insert access for admins"
  ON grading_entries
  FOR INSERT
  TO authenticated
  WITH CHECK ((SELECT COALESCE((auth.jwt() ->> 'role'::text) = 'admin'::text, false)));

CREATE POLICY "Enable update access for admins"
  ON grading_entries
  FOR UPDATE
  TO authenticated
  USING ((SELECT COALESCE((auth.jwt() ->> 'role'::text) = 'admin'::text, false)))
  WITH CHECK ((SELECT COALESCE((auth.jwt() ->> 'role'::text) = 'admin'::text, false)));

-- Update user role
UPDATE auth.users
SET raw_user_meta_data = jsonb_set(
  COALESCE(raw_user_meta_data, '{}'::jsonb),
  '{role}',
  '"customer"'
);

-- Clear and reinsert sample data
DELETE FROM grading_entries;

DO $$
DECLARE
  user_id uuid;
BEGIN
  SELECT id INTO user_id FROM auth.users LIMIT 1;
  
  IF user_id IS NOT NULL THEN
    INSERT INTO grading_entries (batch_number, consumer_id, status, price, created_at)
    VALUES
      ('PKM-2025-001', user_id, 'Arrived at Pikamon', 149.99, NOW() - INTERVAL '14 days'),
      ('PKM-2025-002', user_id, 'Arrived at USA Warehouse', 299.99, NOW() - INTERVAL '12 days'),
      ('PKM-2025-003', user_id, 'Arrived at PSA', 199.99, NOW() - INTERVAL '10 days'),
      ('PKM-2025-004', user_id, 'Order Prep', 249.99, NOW() - INTERVAL '8 days'),
      ('PKM-2025-005', user_id, 'Research & ID', 179.99, NOW() - INTERVAL '6 days'),
      ('PKM-2025-006', user_id, 'Grading', 399.99, NOW() - INTERVAL '4 days'),
      ('PKM-2025-007', user_id, 'Assembly', 299.99, NOW() - INTERVAL '3 days'),
      ('PKM-2025-008', user_id, 'On the way Back', 249.99, NOW() - INTERVAL '2 days'),
      ('PKM-2025-009', user_id, 'Arrived back at Pikamon from Grading', 199.99, NOW() - INTERVAL '1 day'),
      ('PKM-2025-010', user_id, 'On the Way Back to you', 349.99, NOW());
  END IF;
END $$;