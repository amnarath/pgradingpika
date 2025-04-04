/*
  # Insert Sample Grading Entries

  1. Changes
    - Insert 10 realistic grading entries for michael@wearecold.com
    - Entries have varied statuses and realistic timestamps
    - Include meaningful batch numbers and notes
*/

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
    -- Insert sample entries
    INSERT INTO grading_entries (batch_number, consumer_id, status, notes, created_at)
    VALUES
      ('BATCH-2025-001', user_id, 'completed', 'Standard grading request for Q1 assessment', '2025-03-15 09:30:00+00'),
      ('BATCH-2025-002', user_id, 'completed', 'Urgent grading needed for certification exam', '2025-03-16 11:45:00+00'),
      ('BATCH-2025-003', user_id, 'completed', 'Monthly evaluation batch - March', '2025-03-17 14:20:00+00'),
      ('BATCH-2025-004', user_id, 'in_progress', 'Special consideration requested for international submissions', '2025-03-18 10:15:00+00'),
      ('BATCH-2025-005', user_id, 'in_progress', 'Technical assessment grading batch', '2025-03-19 16:30:00+00'),
      ('BATCH-2025-006', user_id, 'pending', 'End of quarter evaluation set', '2025-03-20 09:00:00+00'),
      ('BATCH-2025-007', user_id, 'rejected', 'Incomplete submission - missing required components', '2025-03-20 13:45:00+00'),
      ('BATCH-2025-008', user_id, 'pending', 'Rush order - needs attention within 48 hours', '2025-03-20 15:20:00+00'),
      ('BATCH-2025-009', user_id, 'pending', 'Standard processing time requested', '2025-03-20 16:10:00+00'),
      ('BATCH-2025-010', user_id, 'pending', 'Final assessment batch for March', '2025-03-20 17:00:00+00');
  END IF;
END $$;