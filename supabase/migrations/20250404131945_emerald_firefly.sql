/*
  # Fix get_or_create_current_batch function

  1. Changes
    - Drop all existing versions of the function
    - Create a single version with consistent return type
    - Add batch closing date constraint
    - Ensure proper error handling

  2. Security
    - Maintain RLS policies
    - Keep security definer setting
    - Set proper search path
*/

-- Drop existing function versions
DROP FUNCTION IF EXISTS get_or_create_current_batch();
DROP FUNCTION IF EXISTS get_or_create_current_batch(json);

-- Create single version of the function
CREATE OR REPLACE FUNCTION get_or_create_current_batch()
RETURNS text
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
DECLARE
  current_batch_id uuid;
  batch_number text;
  closing_date date := '2024-05-01'::date;
BEGIN
  -- Check if we've passed the closing date
  IF current_date >= closing_date THEN
    RAISE EXCEPTION 'Batch submissions are closed as of May 1st, 2024';
  END IF;

  -- Try to get an open batch from today
  SELECT id INTO current_batch_id
  FROM batches
  WHERE 
    status = 'open' 
    AND date_trunc('day', created_at) = date_trunc('day', now())
    AND closed_at IS NULL
  LIMIT 1;

  -- If no open batch exists for today, create one
  IF current_batch_id IS NULL THEN
    INSERT INTO batches (created_at, status)
    VALUES (now(), 'open')
    RETURNING id INTO current_batch_id;
  END IF;

  -- Generate batch number in format YYYYMMDD-UUID
  batch_number := to_char(now(), 'YYYYMMDD') || '-' || current_batch_id::text;
  
  RETURN batch_number;
EXCEPTION
  WHEN OTHERS THEN
    -- Re-raise the error with a more user-friendly message
    RAISE EXCEPTION 'Failed to create or retrieve batch: %', SQLERRM;
END;
$$;