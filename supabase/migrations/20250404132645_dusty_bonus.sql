-- Drop existing function if it exists
DROP FUNCTION IF EXISTS get_or_create_current_batch();

-- Create new function with updated logic and better batch number format
CREATE OR REPLACE FUNCTION get_or_create_current_batch()
RETURNS text
LANGUAGE plpgsql
SECURITY DEFINER
AS $$
DECLARE
  current_batch_id uuid;
  batch_number text;
  initial_cutoff_date timestamp with time zone := '2025-05-01 23:59:59+00'::timestamptz;
  new_batch_window interval := interval '60 days';
  batch_sequence int;
BEGIN
  -- First try to get the current open batch
  SELECT id INTO current_batch_id
  FROM batches
  WHERE status = 'open'
  ORDER BY created_at DESC
  LIMIT 1;

  -- Get the next sequence number for today
  SELECT COALESCE(MAX(SUBSTRING(batch_number FROM '\d+$')::integer), 0) + 1
  INTO batch_sequence
  FROM grading_entries
  WHERE batch_number LIKE to_char(CURRENT_DATE, 'YYYYMM') || '-%';

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

  -- Generate user-friendly batch number (format: YYYYMM-XXX)
  batch_number := to_char(CURRENT_DATE, 'YYYYMM') || '-' || 
                  LPAD(batch_sequence::text, 3, '0');

  RETURN batch_number;
END;
$$;