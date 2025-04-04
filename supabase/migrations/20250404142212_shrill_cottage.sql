/*
  # Add grading company to entries

  1. Changes
    - Add grading_company column to grading_entries
    - Update validation function to handle grading company
    - Add check constraint for valid grading companies

  2. Security
    - Maintain existing RLS policies
    - Ensure proper validation
*/

-- Add grading_company column
ALTER TABLE grading_entries
ADD COLUMN grading_company text;

-- Add check constraint for valid grading companies
ALTER TABLE grading_entries
ADD CONSTRAINT valid_grading_company CHECK (grading_company IN ('PSA', 'TAG'));

-- Update validate_entry_update function
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

  -- Validate service level changes
  IF OLD.service_level IS DISTINCT FROM NEW.service_level AND NOT is_admin() THEN
    RAISE EXCEPTION 'Only administrators can change service level';
  END IF;

  -- Validate grading company changes
  IF OLD.grading_company IS DISTINCT FROM NEW.grading_company AND NOT is_admin() THEN
    RAISE EXCEPTION 'Only administrators can change grading company';
  
  END IF;

  -- Validate submission date changes
  IF OLD.created_at IS DISTINCT FROM NEW.created_at AND NOT is_admin() THEN
    RAISE EXCEPTION 'Only administrators can change submission date';
  END IF;

  RETURN NEW;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;