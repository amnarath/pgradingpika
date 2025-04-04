/*
  # Fix batch table and function migration

  1. Changes
    - Drop existing table and related objects
    - Recreate batches table with proper structure
    - Add RLS policies with unique names
    - Create get_or_create_current_batch function

  2. Security
    - Enable RLS on batches table
    - Add proper policies for authenticated users and admins
*/

-- Drop existing objects if they exist
DROP FUNCTION IF EXISTS get_or_create_current_batch();
DROP TABLE IF EXISTS batches CASCADE;

-- Create batches table
CREATE TABLE IF NOT EXISTS batches (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  created_at timestamptz DEFAULT now(),
  closed_at timestamptz DEFAULT null,
  status text DEFAULT 'open'
);

-- Enable RLS
ALTER TABLE batches ENABLE ROW LEVEL SECURITY;

-- Create policies with unique names
CREATE POLICY "batches_read_policy"
  ON batches
  FOR SELECT
  TO authenticated
  USING (true);

CREATE POLICY "batches_admin_policy"
  ON batches
  FOR ALL
  TO authenticated
  USING (is_admin())
  WITH CHECK (is_admin());

-- Create function to get or create current batch
CREATE OR REPLACE FUNCTION get_or_create_current_batch()
RETURNS text
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
DECLARE
  current_batch_id uuid;
  batch_number text;
BEGIN
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
END;
$$;