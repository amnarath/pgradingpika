/*
  # Add Entry Number and Surcharge Logic

  1. Changes
    - Add entry_number column (unique identifier for each entry)
    - Add trigger to auto-generate entry numbers
    - Add constraint for surcharge statuses
    - Update existing entries with entry numbers
*/

-- Add entry_number column
ALTER TABLE grading_entries
ADD COLUMN entry_number text UNIQUE;

-- Create sequence for entry numbers
CREATE SEQUENCE IF NOT EXISTS grading_entry_seq;

-- Function to generate entry number
CREATE OR REPLACE FUNCTION generate_entry_number()
RETURNS trigger AS $$
BEGIN
  NEW.entry_number := 'ENTRY-' || TO_CHAR(NOW(), 'YYYY') || '-' || 
                     LPAD(nextval('grading_entry_seq')::text, 6, '0');
  RETURN NEW;
END;
$$ LANGUAGE plpgsql;

-- Trigger to auto-generate entry numbers
CREATE TRIGGER set_entry_number
  BEFORE INSERT ON grading_entries
  FOR EACH ROW
  EXECUTE FUNCTION generate_entry_number();

-- Function to validate payment status based on grading status
CREATE OR REPLACE FUNCTION validate_payment_status()
RETURNS trigger AS $$
BEGIN
  -- Only allow Surcharge statuses after Assembly
  IF NEW.payment_status IN ('Surcharge Pending', 'Surcharge Paid') THEN
    -- Get the order of statuses
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
    -- Check if new status comes after Assembly
    SELECT INTO NEW.payment_status
      CASE 
        WHEN (SELECT ord FROM new_status_position) <= (SELECT ord FROM assembly_position)
        THEN 'Unpaid'::payment_status
        ELSE NEW.payment_status
      END;
  END IF;
  
  RETURN NEW;
END;
$$ LANGUAGE plpgsql;

-- Trigger to validate payment status
CREATE TRIGGER validate_payment_status
  BEFORE INSERT OR UPDATE ON grading_entries
  FOR EACH ROW
  EXECUTE FUNCTION validate_payment_status();

-- Generate entry numbers for existing entries
DO $$
DECLARE
  entry RECORD;
BEGIN
  FOR entry IN SELECT id FROM grading_entries ORDER BY created_at
  LOOP
    UPDATE grading_entries
    SET entry_number = 'ENTRY-' || TO_CHAR(created_at, 'YYYY') || '-' || 
                      LPAD(nextval('grading_entry_seq')::text, 6, '0')
    WHERE id = entry.id;
  END LOOP;
END $$;