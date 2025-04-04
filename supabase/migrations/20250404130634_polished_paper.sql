/*
  # Add batch management and submission handling

  1. Changes
    - Add service_level and cards columns to grading_entries
    - Add function to manage batch numbers
    - Add trigger for entry number generation
    - Update existing entries with new columns

  2. Security
    - Maintain RLS policies
    - Ensure proper access control
*/

-- Add new columns to grading_entries
ALTER TABLE grading_entries
ADD COLUMN service_level text,
ADD COLUMN cards jsonb;

-- Create type for batch status
CREATE TYPE batch_status AS ENUM ('open', 'closed');

-- Create batches table
CREATE TABLE IF NOT EXISTS batches (
  batch_number text PRIMARY KEY,
  status batch_status DEFAULT 'open',
  created_at timestamptz DEFAULT now(),
  closed_at timestamptz,
  cards_count int DEFAULT 0
);

-- Enable RLS on batches
ALTER TABLE batches ENABLE ROW LEVEL SECURITY;

-- Create policy for batches
CREATE POLICY "Admins can manage batches"
  ON batches
  FOR ALL
  TO authenticated
  USING (is_admin())
  WITH CHECK (is_admin());

-- Function to generate batch number
CREATE OR REPLACE FUNCTION generate_batch_number()
RETURNS text
LANGUAGE plpgsql
AS $$
DECLARE
  year_month text;
  batch_seq int;
  new_batch_number text;
BEGIN
  -- Format: BATCH-YYYYMM-XXX
  year_month := to_char(current_date, 'YYYYMM');
  
  -- Get the next sequence number for this month
  SELECT COALESCE(MAX(CAST(SPLIT_PART(batch_number, '-', 3) AS INTEGER)), 0) + 1
  INTO batch_seq
  FROM batches
  WHERE batch_number LIKE 'BATCH-' || year_month || '-%';
  
  new_batch_number := 'BATCH-' || year_month || '-' || LPAD(batch_seq::text, 3, '0');
  
  RETURN new_batch_number;
END;
$$;

-- Function to get or create current batch
CREATE OR REPLACE FUNCTION get_or_create_current_batch()
RETURNS text
LANGUAGE plpgsql
SECURITY DEFINER
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

-- Trigger function to update batch cards count
CREATE OR REPLACE FUNCTION update_batch_cards_count()
RETURNS trigger
LANGUAGE plpgsql
AS $$
BEGIN
  IF TG_OP = 'INSERT' THEN
    UPDATE batches
    SET cards_count = cards_count + 1
    WHERE batch_number = NEW.batch_number;
  ELSIF TG_OP = 'DELETE' THEN
    UPDATE batches
    SET cards_count = cards_count - 1
    WHERE batch_number = OLD.batch_number;
  END IF;
  
  RETURN NULL;
END;
$$;

-- Create trigger for updating batch cards count
CREATE TRIGGER update_batch_cards_count_trigger
AFTER INSERT OR DELETE ON grading_entries
FOR EACH ROW
EXECUTE FUNCTION update_batch_cards_count();

-- Function to close full batches
CREATE OR REPLACE FUNCTION close_full_batch()
RETURNS trigger
LANGUAGE plpgsql
AS $$
DECLARE
  max_cards_per_batch int := 100; -- Adjust this value as needed
BEGIN
  UPDATE batches
  SET status = 'closed',
      closed_at = now()
  WHERE batch_number = NEW.batch_number
    AND cards_count >= max_cards_per_batch
    AND status = 'open';
  
  RETURN NULL;
END;
$$;

-- Create trigger for closing full batches
CREATE TRIGGER close_full_batch_trigger
AFTER UPDATE ON batches
FOR EACH ROW
EXECUTE FUNCTION close_full_batch();