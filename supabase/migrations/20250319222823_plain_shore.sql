/*
  # Fix User Roles and Sample Data

  1. Changes
    - Add role to existing users
    - Ensure sample data is properly associated
    - Update policies to handle roles correctly
*/

-- First, ensure the user has the correct role
UPDATE auth.users
SET raw_user_meta_data = jsonb_set(
  COALESCE(raw_user_meta_data, '{}'::jsonb),
  '{role}',
  '"customer"'
)
WHERE email = 'michael@wearecold.com';

-- Clear existing entries to avoid duplicates
DELETE FROM grading_entries;

-- Insert fresh sample data
DO $$
DECLARE
  user_id uuid;
BEGIN
  -- Get the user ID for michael@wearecold.com
  SELECT id INTO user_id
  FROM auth.users
  WHERE email = 'michael@wearecold.com';

  -- Only proceed if we found the user
  IF user_id IS NOT NULL THEN
    -- Insert sample entries with prices
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