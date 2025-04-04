/*
  # Add service level column to grading entries

  1. Changes
    - Add service_level column to store grading service level
    - Create enum type for valid service levels
    - Add validation for service level values
*/

-- Create enum for service levels
CREATE TYPE service_level AS ENUM (
  'economy',
  'regular',
  'express',
  'superExpress',
  'walkThrough'
);

-- Add service_level column to grading_entries
ALTER TABLE grading_entries
ADD COLUMN IF NOT EXISTS service_level service_level;

-- Update validate_entry_update function to handle service_level
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

  -- Validate submission date changes
  IF OLD.created_at IS DISTINCT FROM NEW.created_at AND NOT is_admin() THEN
    RAISE EXCEPTION 'Only administrators can change submission date';
  END IF;

  RETURN NEW;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;