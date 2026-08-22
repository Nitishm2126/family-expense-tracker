-- Run this in the Supabase SQL Editor
-- This ensures the anon role has explicit SELECT permissions for the categories table

DROP POLICY IF EXISTS "Allow anon to read categories" ON public.categories;

CREATE POLICY "Allow anon to read categories"
  ON public.categories 
  FOR SELECT 
  TO anon 
  USING (true);

-- Also ensure RLS is actually enabled on the table
ALTER TABLE public.categories ENABLE ROW LEVEL SECURITY;

-- Grant usage to the anon role just in case it was revoked
GRANT USAGE ON SCHEMA public TO anon;
GRANT SELECT ON public.categories TO anon;
