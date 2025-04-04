/*
  # Add Pending status to grading workflow

  1. Changes
    - Add 'Pending' status to grading_status enum
    - Update existing entries to use new status
    - Update default value for new entries
    - Handle payment status validation properly

  2. Security
    - Maintain data integrity during migration
    - Handle payment status validation correctly
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

-- Re-enable the triggers
ALTER TABLE grading_entries ENABLE TRIGGER validate_entry_updates;
ALTER TABLE grading_entries ENABLE TRIGGER validate_payment_status;
ALTER TABLE grading_entries ENABLE TRIGGER ensure_payment_status_auth;