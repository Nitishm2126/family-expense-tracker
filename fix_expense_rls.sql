-- =================================================================
-- FIX EXPENSES INSERT RLS POLICY
-- Run this in the Supabase SQL Editor:
-- https://supabase.com/dashboard/project/eowvprknwokacnmickgt/sql/new
-- =================================================================

-- 1. Drop any existing INSERT policies for anon on expenses
DROP POLICY IF EXISTS "Allow anon insert expenses" ON public.expenses;
DROP POLICY IF EXISTS "Enable insert for authenticated users only" ON public.expenses;
DROP POLICY IF EXISTS "Enable insert for anon" ON public.expenses;

-- 2. Create the Restrictive INSERT Policy for anon
-- This ensures that the anon role can only insert if:
--   a) The family_id matches the app's active family ID
--   b) The member_id actually belongs to that family in the members table
CREATE POLICY "Restrictive anon insert expenses" 
ON public.expenses 
FOR INSERT 
TO anon 
WITH CHECK (
  family_id = 'b4e16e52-a95f-4e6e-a6cf-dc8f85892010'::uuid
  AND EXISTS (
    SELECT 1 
    FROM public.members m 
    WHERE m.id = expenses.member_id 
    AND m.family_id = expenses.family_id
  )
);

-- Note: Ensure that category_id is either a valid UUID or NULL.
