/*
  # Add cards column to grading entries

  1. Changes
    - Add cards column to store card details
    - Column type is JSONB to store flexible card data structure
    - Add validation for card data structure
*/

-- Add cards column to grading_entries
ALTER TABLE grading_entries
ADD COLUMN IF NOT EXISTS cards jsonb;

-- Create a check constraint to ensure cards is an array
ALTER TABLE grading_entries
ADD CONSTRAINT cards_is_array CHECK (jsonb_typeof(cards) = 'array');

-- Create an index on the cards column for better query performance
CREATE INDEX IF NOT EXISTS idx_grading_entries_cards ON grading_entries USING gin (cards);

-- Update validate_entry_update function to handle cards
CREATE OR REPLACE FUNCTION validate_entry_update()
RETURNS trigger AS $$
BEGIN
  -- Only allow updates by admin
  IF NOT is_admin() THEN
    RAISE EXCEPTION 'Only administrators can update entries';
  END IF;

  -- Validate status changes
  IF OLD.status IS DISTINCT FROM NEW.status AND NOT is_admin() THEN
    RAISE EXCEPTION 'Only administrators can change entry status';
  END IF;

  -- Validate payment status changes
  IF OLD.payment_status IS DISTINCT FROM NEW.payment_status AND NOT is_admin() THEN
    RAISE EXCEPTION 'Only administrators can change payment status';
  END IF;

  -- Validate price changes
  IF OLD.price IS DISTINCT FROM NEW.price AND NOT is_admin() THEN
    RAISE EXCEPTION 'Only administrators can change entry price';
  END IF;

  -- Validate cards changes
  IF OLD.cards IS DISTINCT FROM NEW.cards AND NOT is_admin() THEN
    RAISE EXCEPTION 'Only administrators can modify card details';
  END IF;

  -- Validate submission date changes
  IF OLD.created_at IS DISTINCT FROM NEW.created_at AND NOT is_admin() THEN
    RAISE EXCEPTION 'Only administrators can change submission date';
  END IF;

  RETURN NEW;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;