/*
  # Fix Email Verification and User Management

  1. Changes
    - Add email verification handling
    - Add trigger for email verification
    - Add function to validate role changes
    - Add function to handle email confirmation

  2. Security
    - Maintain proper access control
    - Ensure secure role management
*/

-- Function to handle email verification
CREATE OR REPLACE FUNCTION handle_email_verification()
RETURNS trigger AS $$
BEGIN
  -- Update user metadata when email is verified
  IF NEW.email_confirmed_at IS NOT NULL AND OLD.email_confirmed_at IS NULL THEN
    UPDATE auth.users
    SET raw_user_meta_data = 
      CASE 
        WHEN raw_user_meta_data IS NULL THEN 
          jsonb_build_object('email_verified', true)
        ELSE 
          raw_user_meta_data || jsonb_build_object('email_verified', true)
      END
    WHERE id = NEW.id;
  END IF;
  
  RETURN NEW;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- Create trigger for email verification
DROP TRIGGER IF EXISTS on_email_verified ON auth.users;
CREATE TRIGGER on_email_verified
  AFTER UPDATE OF email_confirmed_at ON auth.users
  FOR EACH ROW
  EXECUTE FUNCTION handle_email_verification();

-- Function to validate role changes
CREATE OR REPLACE FUNCTION validate_role_change()
RETURNS trigger AS $$
BEGIN
  -- Only allow role changes by admin
  IF OLD.role IS DISTINCT FROM NEW.role AND NOT is_admin() THEN
    RAISE EXCEPTION 'Only administrators can change user roles';
  END IF;
  RETURN NEW;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- Create trigger for role changes
DROP TRIGGER IF EXISTS ensure_role_change_auth ON users;
CREATE TRIGGER ensure_role_change_auth
  BEFORE UPDATE ON users
  FOR EACH ROW
  EXECUTE FUNCTION validate_role_change();

-- Function to handle email confirmation
CREATE OR REPLACE FUNCTION handle_email_confirmation()
RETURNS trigger AS $$
BEGIN
  -- When email is confirmed, update user metadata
  IF NEW.email_confirmed_at IS NOT NULL AND OLD.email_confirmed_at IS NULL THEN
    -- Update the user's metadata
    UPDATE auth.users
    SET raw_user_meta_data = jsonb_set(
      COALESCE(raw_user_meta_data, '{}'::jsonb),
      '{email_confirmed}',
      'true'::jsonb
    )
    WHERE id = NEW.id;
  END IF;
  RETURN NEW;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- Create trigger for email confirmation
DROP TRIGGER IF EXISTS on_email_confirmed ON auth.users;
CREATE TRIGGER on_email_confirmed
  AFTER UPDATE OF email_confirmed_at ON auth.users
  FOR EACH ROW
  EXECUTE FUNCTION handle_email_confirmation();