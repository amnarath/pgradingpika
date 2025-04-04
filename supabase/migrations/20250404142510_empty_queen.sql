/*
  # Fix batch number ambiguity

  1. Changes
    - Update get_or_create_current_batch function to fix ambiguous column reference
    - Improve batch number generation logic
    - Add proper table aliases to avoid ambiguity

  2. Security
    - Maintain existing security context
    - Keep all security definer settings
*/

-- Drop existing function
DROP FUNCTION IF EXISTS get_or_create_current_batch();

-- Create updated function with fixed batch number handling
CREATE OR REPLACE FUNCTION get_or_create_current_batch()
RETURNS text
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
DECLARE
  current_batch_id uuid;
  batch_number text;
  batch_sequence int;
BEGIN
  -- Get the next sequence number for today using explicit table reference
  SELECT COALESCE(MAX(SUBSTRING(ge.batch_number FROM '\d+$')::integer), 0) + 1
  INTO batch_sequence
  FROM grading_entries ge
  WHERE ge.batch_number LIKE to_char(CURRENT_DATE, 'YYYY-MM') || '-%';

  -- Get or create batch record
  SELECT b.id INTO current_batch_id
  FROM batches b
  WHERE b.status = 'open'
  ORDER BY b.created_at DESC
  LIMIT 1;

  -- If no open batch exists, create a new one
  IF current_batch_id IS NULL THEN
    INSERT INTO batches (status)
    VALUES ('open')
    RETURNING id INTO current_batch_id;
  END IF;

  -- Generate user-friendly batch number (format: YYYY-MM-XXX)
  batch_number := to_char(CURRENT_DATE, 'YYYY-MM') || '-' || 
                  LPAD(batch_sequence::text, 3, '0');

  RETURN batch_number;
EXCEPTION
  WHEN OTHERS THEN
    -- Re-raise the error with a more user-friendly message
    RAISE EXCEPTION 'Failed to create or retrieve batch: %', SQLERRM;
END;
$$;