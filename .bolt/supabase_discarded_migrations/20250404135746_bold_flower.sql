/*
  # Fix batch number generation and add constraints

  1. Changes
    - Update get_or_create_current_batch function to use proper sequence
    - Add constraints to ensure valid batch numbers
    - Fix batch number format to YYYY-MM-XXX
*/

-- Drop existing function
DROP FUNCTION IF EXISTS get_or_create_current_batch();

-- Create sequence for batch numbers
CREATE SEQUENCE IF NOT EXISTS batch_number_seq;

-- Create function to generate batch numbers
CREATE OR REPLACE FUNCTION get_or_create_current_batch()
RETURNS text
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
DECLARE
  batch_number text;
  current_year_month text;
  sequence_number int;
BEGIN
  -- Get current year and month
  current_year_month := to_char(CURRENT_DATE, 'YYYY-MM');
  
  -- Get next sequence number
  SELECT nextval('batch_number_seq') INTO sequence_number;
  
  -- Format batch number as YYYY-MM-XXX
  batch_number := current_year_month || '-' || LPAD(sequence_number::text, 3, '0');
  
  RETURN batch_number;
END;
$$;

-- Add constraint to ensure batch numbers follow the correct format
ALTER TABLE grading_entries
ADD CONSTRAINT valid_batch_number_format 
CHECK (batch_number ~ '^\d{4}-\d{2}-\d{3}$');