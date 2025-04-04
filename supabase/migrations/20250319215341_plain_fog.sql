/*
  # Grading Portal Schema Setup

  1. New Tables
    - `grading_entries`
      - `id` (uuid, primary key)
      - `batch_number` (text, unique)
      - `consumer_id` (uuid, references auth.users)
      - `status` (text)
      - `notes` (text)
      - `created_at` (timestamp)
      - `updated_at` (timestamp)
    
  2. Security
    - Enable RLS on `grading_entries` table
    - Add policies for:
      - Consumers can read their own entries
      - Consumers can create entries
      - Admins can read and update all entries
*/

-- Create enum for grading status
CREATE TYPE grading_status AS ENUM (
  'pending',
  'in_progress',
  'completed',
  'rejected'
);

-- Create grading entries table
CREATE TABLE IF NOT EXISTS grading_entries (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  batch_number text UNIQUE NOT NULL,
  consumer_id uuid REFERENCES auth.users NOT NULL,
  status grading_status DEFAULT 'pending',
  notes text,
  created_at timestamptz DEFAULT now(),
  updated_at timestamptz DEFAULT now()
);

-- Enable RLS
ALTER TABLE grading_entries ENABLE ROW LEVEL SECURITY;

-- Create admin role
CREATE ROLE admin;

-- Policies for consumers
CREATE POLICY "Consumers can read own entries"
  ON grading_entries
  FOR SELECT
  TO authenticated
  USING (auth.uid() = consumer_id);

CREATE POLICY "Consumers can create entries"
  ON grading_entries
  FOR INSERT
  TO authenticated
  WITH CHECK (auth.uid() = consumer_id);

-- Policies for admins
CREATE POLICY "Admins can read all entries"
  ON grading_entries
  FOR SELECT
  TO admin
  USING (true);

CREATE POLICY "Admins can update all entries"
  ON grading_entries
  FOR UPDATE
  TO admin
  USING (true)
  WITH CHECK (true);

-- Function to update updated_at timestamp
CREATE OR REPLACE FUNCTION update_updated_at_column()
RETURNS TRIGGER AS $$
BEGIN
  NEW.updated_at = now();
  RETURN NEW;
END;
$$ language 'plpgsql';

-- Trigger for updated_at
CREATE TRIGGER update_grading_entries_updated_at
  BEFORE UPDATE ON grading_entries
  FOR EACH ROW
  EXECUTE FUNCTION update_updated_at_column();