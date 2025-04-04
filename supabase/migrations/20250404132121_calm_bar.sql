/*
  # Update batch management logic
  
  1. Changes
    - Add function to manage batch creation and closure dates
    - Update get_or_create_current_batch function with new timing logic
    - First batch closes May 1st 2025
    - Subsequent batches have 60-day windows
  
  2. Security
    - Functions are security definer to ensure proper access control
*/

-- Drop existing function if it exists
DROP FUNCTION IF EXISTS get_or_create_current_batch();

-- Create new function with updated logic
CREATE OR REPLACE FUNCTION get_or_create_current_batch()
RETURNS uuid
LANGUAGE plpgsql
SECURITY DEFINER
AS $$
DECLARE
  current_batch_id uuid;
  initial_cutoff_date timestamp with time zone := '2025-05-01 23:59:59+00'::timestamptz;
  new_batch_window interval := interval '60 days';
BEGIN
  -- First try to get the current open batch
  SELECT id INTO current_batch_id
  FROM batches
  WHERE status = 'open'
  ORDER BY created_at DESC
  LIMIT 1;

  -- If no open batch exists, create a new one
  IF current_batch_id IS NULL THEN
    -- Check if we're before the initial cutoff date
    IF NOW() < initial_cutoff_date THEN
      -- Create initial batch that closes May 1st 2025
      INSERT INTO batches (status, closed_at)
      VALUES ('open', initial_cutoff_date)
      RETURNING id INTO current_batch_id;
    ELSE
      -- Create a new batch with 60-day window
      INSERT INTO batches (status, closed_at)
      VALUES ('open', NOW() + new_batch_window)
      RETURNING id INTO current_batch_id;
    END IF;
  ELSE
    -- Check if current batch should be closed
    DECLARE
      batch_close_date timestamp with time zone;
    BEGIN
      SELECT closed_at INTO batch_close_date
      FROM batches
      WHERE id = current_batch_id;

      IF NOW() > batch_close_date THEN
        -- Close current batch
        UPDATE batches
        SET status = 'closed'
        WHERE id = current_batch_id;

        -- Create new batch with 60-day window
        INSERT INTO batches (status, closed_at)
        VALUES ('open', NOW() + new_batch_window)
        RETURNING id INTO current_batch_id;
      END IF;
    END;
  END IF;

  RETURN current_batch_id;
END;
$$;