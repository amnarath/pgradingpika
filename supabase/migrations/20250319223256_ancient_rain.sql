/*
  # Add Payment Status to Grading Entries

  1. Changes
    - Add payment_status enum type
    - Add payment_status column to grading_entries table
    - Update existing entries with payment statuses
    - Add function to calculate amount due

  2. Security
    - Maintain existing RLS policies
*/

-- Create payment status enum
CREATE TYPE payment_status AS ENUM (
  'Unpaid',
  'Paid',
  'Surcharge Pending',
  'Surcharge Paid'
);

-- Add payment_status column
ALTER TABLE grading_entries
ADD COLUMN payment_status payment_status DEFAULT 'Unpaid'::payment_status;

-- Update existing entries to have some variety in payment status
DO $$
BEGIN
  -- Set some entries to Paid
  UPDATE grading_entries
  SET payment_status = 'Paid'::payment_status
  WHERE ctid IN (
    SELECT ctid
    FROM grading_entries
    ORDER BY RANDOM()
    LIMIT (SELECT COUNT(*) / 4 FROM grading_entries)
  );

  -- Set some entries to Surcharge Pending
  UPDATE grading_entries
  SET payment_status = 'Surcharge Pending'::payment_status
  WHERE payment_status = 'Unpaid'::payment_status
  AND ctid IN (
    SELECT ctid
    FROM grading_entries
    WHERE payment_status = 'Unpaid'::payment_status
    ORDER BY RANDOM()
    LIMIT (SELECT COUNT(*) / 3 FROM grading_entries WHERE payment_status = 'Unpaid'::payment_status)
  );

  -- Set some entries to Surcharge Paid
  UPDATE grading_entries
  SET payment_status = 'Surcharge Paid'::payment_status
  WHERE payment_status = 'Unpaid'::payment_status
  AND ctid IN (
    SELECT ctid
    FROM grading_entries
    WHERE payment_status = 'Unpaid'::payment_status
    ORDER BY RANDOM()
    LIMIT (SELECT COUNT(*) / 2 FROM grading_entries WHERE payment_status = 'Unpaid'::payment_status)
  );
END $$;

-- Create a function to calculate the amount due
CREATE OR REPLACE FUNCTION calculate_amount_due(entry_price decimal, entry_payment_status payment_status)
RETURNS decimal AS $$
BEGIN
  RETURN CASE
    WHEN entry_payment_status IN ('Paid'::payment_status, 'Surcharge Paid'::payment_status) THEN 0
    ELSE entry_price
  END;
END;
$$ LANGUAGE plpgsql;