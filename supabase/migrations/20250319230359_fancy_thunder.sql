/*
  # Set admin user

  1. Changes
    - Set user michael@wearecold.com as admin by updating their role in auth.users metadata
*/

DO $$
BEGIN
  UPDATE auth.users
  SET raw_user_meta_data = jsonb_set(
    COALESCE(raw_user_meta_data, '{}'::jsonb),
    '{role}',
    '"admin"'
  )
  WHERE email = 'michael@wearecold.com';
END $$;