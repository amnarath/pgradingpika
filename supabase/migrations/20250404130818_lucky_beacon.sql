/*
  # Fix get_or_create_current_batch function

  1. Changes
    - Update function to accept a JSON parameter for compatibility with Supabase Edge Functions
    - Maintain existing functionality
    - Fix parameter handling
*/

-- Drop and recreate the function with proper parameter handling
CREATE OR REPLACE FUNCTION get_or_create_current_batch(payload json DEFAULT '{}'::json)
RETURNS text
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
DECLARE
  current_batch text;
  max_cards_per_batch int := 100; -- Adjust this value as needed
BEGIN
  -- Get the latest open batch that isn't full
  SELECT batch_number
  INTO current_batch
  FROM batches
  WHERE status = 'open'
    AND cards_count < max_cards_per_batch
  ORDER BY created_at DESC
  LIMIT 1;
  
  -- If no suitable batch exists, create a new one
  IF current_batch IS NULL THEN
    current_batch := generate_batch_number();
    
    INSERT INTO batches (batch_number)
    VALUES (current_batch);
  END IF;
  
  RETURN current_batch;
END;
$$;