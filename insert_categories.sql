-- Run this script in the Supabase SQL Editor to populate the missing categories.
-- It associates each standard category with your active family_id.

INSERT INTO public.categories (name, family_id) VALUES
  ('Grocery', 'b4e16e52-a95f-4e6e-a6cf-dc8f85892010'),
  ('Food', 'b4e16e52-a95f-4e6e-a6cf-dc8f85892010'),
  ('Transport', 'b4e16e52-a95f-4e6e-a6cf-dc8f85892010'),
  ('Medical', 'b4e16e52-a95f-4e6e-a6cf-dc8f85892010'),
  ('Utilities', 'b4e16e52-a95f-4e6e-a6cf-dc8f85892010'),
  ('Education', 'b4e16e52-a95f-4e6e-a6cf-dc8f85892010'),
  ('Entertainment', 'b4e16e52-a95f-4e6e-a6cf-dc8f85892010'),
  ('Shopping', 'b4e16e52-a95f-4e6e-a6cf-dc8f85892010'),
  ('Rent', 'b4e16e52-a95f-4e6e-a6cf-dc8f85892010'),
  ('Others', 'b4e16e52-a95f-4e6e-a6cf-dc8f85892010');
