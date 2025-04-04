/*
  # Update Payment Status Validation Rules

  1. Changes
    - Modify validate_payment_status function to ensure:
      - 'Unpaid' status only allowed for 'Arrived at Pikamon' stage
      - Other payment statuses automatically set based on grading status
    - Update existing entries to comply with new rules
*/

-- Drop existing validate_payment_status function and trigger
DROP TRIGGER IF EXISTS validate_payment_status ON grading_entries;
DROP FUNCTION IF EXISTS validate_payment_status();

-- Create updated validate_payment_status function
CREATE OR REPLACE FUNCTION validate_payment_status()
RETURNS trigger AS $$
BEGIN
  -- Handle Unpaid status - only allowed for 'Arrived at Pikamon'
  IF NEW.payment_status = 'Unpaid' AND NEW.status != 'Arrived at Pikamon' THEN
    NEW.payment_status := 'Paid'::payment_status;
  END IF;

  -- Handle Surcharge statuses - only allowed after Assembly
  IF NEW.payment_status IN ('Surcharge Pending', 'Surcharge Paid') THEN
    WITH status_order AS (
      SELECT status, row_number() OVER () as ord
      FROM unnest(enum_range(NULL::grading_status)) status
    ),
    assembly_position AS (
      SELECT ord FROM status_order WHERE status = 'Assembly'
    ),
    new_status_position AS (
      SELECT ord FROM status_order WHERE status = NEW.status
    )
    SELECT INTO NEW.payment_status
      CASE 
        WHEN (SELECT ord FROM new_status_position) <= (SELECT ord FROM assembly_position)
        THEN 'Paid'::payment_status
        ELSE NEW.payment_status
      END;
  END IF;

  -- If status changes from 'Arrived at Pikamon' to something else,
  -- and payment_status is still 'Unpaid', change it to 'Paid'
  IF NEW.status != 'Arrived at Pikamon' AND NEW.payment_status = 'Unpaid' THEN
    NEW.payment_status := 'Paid'::payment_status;
  END IF;
  
  RETURN NEW;
END;
$$ LANGUAGE plpgsql;

-- Recreate the trigger
CREATE TRIGGER validate_payment_status
  BEFORE INSERT OR UPDATE ON grading_entries
  FOR EACH ROW
  EXECUTE FUNCTION validate_payment_status();

-- Update existing entries to comply with new rules
UPDATE grading_entries
SET payment_status = 
  CASE 
    WHEN status = 'Arrived at Pikamon' THEN 'Unpaid'::payment_status
    WHEN status > 'Assembly' AND payment_status IN ('Surcharge Pending', 'Surcharge Paid') 
    THEN payment_status
    ELSE 'Paid'::payment_status
  END;