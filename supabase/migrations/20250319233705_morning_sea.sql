/*
  # Update admin permissions for entry management

  1. Changes
    - Allow admins to update all entry fields
    - Add validation for payment status changes
    - Add validation for entry status changes
    - Ensure proper admin role checks

  2. Security
    - Maintain RLS for all operations
    - Add specific validation triggers
    - Update admin check function
*/

-- Drop existing policies
DROP POLICY IF EXISTS "entries_read" ON grading_entries;
DROP POLICY IF EXISTS "admin_insert_entries" ON grading_entries;
DROP POLICY IF EXISTS "admin_update_entries" ON grading_entries;

-- Enable RLS
ALTER TABLE grading_entries ENABLE ROW LEVEL SECURITY;

-- Create policies for grading entries
CREATE POLICY "entries_read" ON grading_entries
  FOR SELECT
  TO authenticated
  USING (
    consumer_id = auth.uid() OR
    is_admin()
  );

CREATE POLICY "admin_insert_entries" ON grading_entries
  FOR INSERT
  TO authenticated
  WITH CHECK (
    is_admin()
  );

CREATE POLICY "admin_update_entries" ON grading_entries
  FOR UPDATE
  TO authenticated
  USING (
    is_admin()
  )
  WITH CHECK (
    is_admin()
  );

-- Create function to validate entry updates
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

  -- Validate submission date changes
  IF OLD.created_at IS DISTINCT FROM NEW.created_at AND NOT is_admin() THEN
    RAISE EXCEPTION 'Only administrators can change submission date';
  END IF;

  RETURN NEW;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- Create trigger for entry updates
DROP TRIGGER IF EXISTS validate_entry_updates ON grading_entries;
CREATE TRIGGER validate_entry_updates
  BEFORE UPDATE ON grading_entries
  FOR EACH ROW
  EXECUTE FUNCTION validate_entry_update();