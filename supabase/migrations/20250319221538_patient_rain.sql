/*
  # Update Grading Status Options and Remove Notes

  1. Changes
    - Create new grading_status enum with updated status options
    - Update existing entries to use new status values
    - Remove notes column from grading_entries table
    - Set default status for new entries

  Note: Using a safer approach that preserves data and avoids type casting issues
*/

-- First, remove the default value constraint
ALTER TABLE grading_entries 
ALTER COLUMN status DROP DEFAULT;

-- Create new enum type with a different name
CREATE TYPE grading_status_new AS ENUM (
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

-- Change column to text temporarily to allow easier updating
ALTER TABLE grading_entries
ALTER COLUMN status TYPE text;

-- Update existing entries with new status values
UPDATE grading_entries SET status = 'Arrived at Pikamon' WHERE status = 'pending';
UPDATE grading_entries SET status = 'Grading' WHERE status = 'in_progress';
UPDATE grading_entries SET status = 'On the Way Back to you' WHERE status = 'completed';
UPDATE grading_entries SET status = 'Arrived at Pikamon' WHERE status = 'rejected';

-- Change column to use new type
ALTER TABLE grading_entries
ALTER COLUMN status TYPE grading_status_new USING status::grading_status_new;

-- Drop old enum type
DROP TYPE grading_status;

-- Rename new enum type to the original name
ALTER TYPE grading_status_new RENAME TO grading_status;

-- Set the default value for new entries
ALTER TABLE grading_entries
ALTER COLUMN status SET DEFAULT 'Arrived at Pikamon'::grading_status;

-- Remove notes column
ALTER TABLE grading_entries DROP COLUMN IF EXISTS notes;