/*
  # Fix Pending status in grading entries

  1. Changes
    - Drop and recreate grading_status enum with Pending status
    - Update existing entries to use new status values
    - Maintain data integrity during migration
    - Fix validation functions to handle Pending status

  2. Security
    - Temporarily disable triggers during migration
    - Re-enable triggers after migration
    - Maintain RLS policies
*/

-- First, temporarily disable the triggers that might interfere
ALTER TABLE grading_entries DISABLE TRIGGER validate_entry_updates;
ALTER TABLE grading_entries DISABLE TRIGGER validate_payment_status;
ALTER TABLE grading_entries DISABLE TRIGGER ensure_payment_status_auth;

-- Create new enum type with Pending status
CREATE TYPE grading_status_new AS ENUM (
  'Pending',
  'Arrived at Pikamon',
  'Arrived at USA Warehouse',
  'Arrived at PSA',
  'Order Prep',
  'Research & ID',
  'Grading',
  'Assembly',
  'On the way Back',
  'Arrived back at Pikamon from Grading',
  'On the Way Back to you'
);

-- Add a temporary column for the new status
ALTER TABLE grading_entries
ADD COLUMN status_new grading_status_new;

-- Update the temporary column with mapped values
UPDATE grading_entries
SET status_new = CASE status::text
  WHEN 'Arrived at Pikamon' THEN 'Arrived at Pikamon'::grading_status_new
  WHEN 'Arrived at USA Warehouse' THEN 'Arrived at USA Warehouse'::grading_status_new
  WHEN 'Arrived at PSA' THEN 'Arrived at PSA'::grading_status_new
  WHEN 'Order Prep' THEN 'Order Prep'::grading_status_new
  WHEN 'Research & ID' THEN 'Research & ID'::grading_status_new
  WHEN 'Grading' THEN 'Grading'::grading_status_new
  WHEN 'Assembly' THEN 'Assembly'::grading_status_new
  WHEN 'On the way Back' THEN 'On the way Back'::grading_status_new
  WHEN 'Arrived back at Pikamon from Grading' THEN 'Arrived back at Pikamon from Grading'::grading_status_new
  WHEN 'On the Way Back to you' THEN 'On the Way Back to you'::grading_status_new
  ELSE 'Pending'::grading_status_new
END;

-- Drop the old status column and rename the new one
ALTER TABLE grading_entries DROP COLUMN status;
ALTER TABLE grading_entries RENAME COLUMN status_new TO status;

-- Drop old enum type
DROP TYPE grading_status;

-- Rename new enum type to original name
ALTER TYPE grading_status_new RENAME TO grading_status;

-- Set default value for new entries
ALTER TABLE grading_entries
ALTER COLUMN status SET DEFAULT 'Pending'::grading_status;

-- Update validate_payment_status function to handle Pending status
CREATE OR REPLACE FUNCTION validate_payment_status()
RETURNS trigger AS $$
BEGIN
  -- Handle Unpaid status - only allowed for 'Pending' or 'Arrived at Pikamon'
  IF NEW.payment_status = 'Unpaid' AND 
     NEW.status != 'Pending' AND 
     NEW.status != 'Arrived at Pikamon' THEN
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

  -- If status changes from 'Pending' or 'Arrived at Pikamon' to something else,
  -- and payment_status is still 'Unpaid', change it to 'Paid'
  IF NEW.status NOT IN ('Pending', 'Arrived at Pikamon') AND NEW.payment_status = 'Unpaid' THEN
    NEW.payment_status := 'Paid'::payment_status;
  END IF;
  
  RETURN NEW;
END;
$$ LANGUAGE plpgsql;

-- Re-enable the triggers
ALTER TABLE grading_entries ENABLE TRIGGER validate_entry_updates;
ALTER TABLE grading_entries ENABLE TRIGGER validate_payment_status;
ALTER TABLE grading_entries ENABLE TRIGGER ensure_payment_status_auth;