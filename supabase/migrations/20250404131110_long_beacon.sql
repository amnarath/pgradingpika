/*
  # Add batches table and batch management function

  1. New Tables
    - `batches`
      - `id` (uuid, primary key)
      - `created_at` (timestamp)
      - `closed_at` (timestamp, nullable)
      - `status` (text, default 'open')

  2. Functions
    - `get_or_create_current_batch()`: Returns the current open batch or creates a new one
    
  3. Security
    - Enable RLS on `batches` table
    - Add policies for admin access
*/

-- Create batches table
CREATE TABLE IF NOT EXISTS batches (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  created_at timestamptz DEFAULT now(),
  closed_at timestamptz,
  status text DEFAULT 'open'
);

-- Enable RLS
ALTER TABLE batches ENABLE ROW LEVEL SECURITY;

-- Create policies
CREATE POLICY "Enable read access for authenticated users"
  ON batches
  FOR SELECT
  TO authenticated
  USING (true);

CREATE POLICY "Enable insert/update access for admins"
  ON batches
  FOR ALL
  TO authenticated
  USING (is_admin())
  WITH CHECK (is_admin());

-- Create function to get or create current batch
CREATE OR REPLACE FUNCTION get_or_create_current_batch()
RETURNS uuid
LANGUAGE plpgsql
SECURITY DEFINER
AS $$
DECLARE
  current_batch_id uuid;
BEGIN
  -- Try to get the current open batch
  SELECT id INTO current_batch_id
  FROM batches
  WHERE status = 'open'
  ORDER BY created_at DESC
  LIMIT 1;
  
  -- If no open batch exists, create a new one
  IF current_batch_id IS NULL THEN
    INSERT INTO batches (status)
    VALUES ('open')
    RETURNING id INTO current_batch_id;
  END IF;
  
  RETURN current_batch_id;
END;
$$;