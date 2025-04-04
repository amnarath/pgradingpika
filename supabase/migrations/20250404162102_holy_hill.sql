/*
  # Add surcharge amount to grading entries

  1. Changes
    - Add surcharge_amount column to grading_entries
    - Update validation function to handle surcharge amount
    - Ensure proper access control for surcharge updates

  2. Security
    - Only admins can modify surcharge amount
    - Maintain existing RLS policies
*/

-- Add surcharge_amount column
ALTER TABLE grading_entries
ADD COLUMN surcharge_amount decimal(10,2) DEFAULT 0.00;

-- Update validate_entry_update function to handle surcharge amount
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

  -- Validate surcharge amount changes
  IF OLD.surcharge_amount IS DISTINCT FROM NEW.surcharge_amount AND NOT is_admin() THEN
    RAISE EXCEPTION 'Only administrators can change surcharge amount';
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

-- Update payment status validation to handle surcharges
CREATE OR REPLACE FUNCTION validate_payment_status()
RETURNS trigger AS $$
BEGIN
  -- Handle Unpaid status - only allowed for 'Pending' or 'Arrived at Pikamon'
  IF NEW.payment_status = 'Unpaid' AND 
     NEW.status != 'Pending' AND 
     NEW.status != 'Arrived at Pikamon' THEN
    NEW.payment_status := 'Paid'::payment_status;
  END IF;

  -- Handle Surcharge statuses
  IF NEW.surcharge_amount > 0 AND NEW.payment_status = 'Paid' THEN
    NEW.payment_status := 'Surcharge Pending'::payment_status;
  END IF;

  -- If surcharge is paid, ensure it stays paid
  IF OLD.payment_status = 'Surcharge Paid' AND NEW.surcharge_amount = OLD.surcharge_amount THEN
    NEW.payment_status := 'Surcharge Paid'::payment_status;
  END IF;

  RETURN NEW;
END;
$$ LANGUAGE plpgsql;