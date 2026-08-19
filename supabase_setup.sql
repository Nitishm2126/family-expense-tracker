-- =================================================================
-- FAMILY EXPENSE TRACKER — Supabase Setup SQL
-- Run this ENTIRE script in the Supabase SQL Editor.
-- Dashboard → SQL Editor → New Query → paste → Run
-- =================================================================

-- -----------------------------------------------------------------
-- SECTION 1: RLS POLICIES (the proper fix)
-- These let the anon role SELECT/INSERT/UPDATE/DELETE data.
-- -----------------------------------------------------------------

-- families
DROP POLICY IF EXISTS "Allow anon to read families" ON public.families;
CREATE POLICY "Allow anon to read families"
  ON public.families FOR SELECT TO anon USING (true);

-- members
DROP POLICY IF EXISTS "Allow anon to read members" ON public.members;
CREATE POLICY "Allow anon to read members"
  ON public.members FOR SELECT TO anon USING (true);

-- categories
DROP POLICY IF EXISTS "Allow anon to read categories" ON public.categories;
CREATE POLICY "Allow anon to read categories"
  ON public.categories FOR SELECT TO anon USING (true);

-- expenses
DROP POLICY IF EXISTS "Allow anon select expenses" ON public.expenses;
CREATE POLICY "Allow anon select expenses"
  ON public.expenses FOR SELECT TO anon USING (true);

DROP POLICY IF EXISTS "Allow anon insert expenses" ON public.expenses;
CREATE POLICY "Allow anon insert expenses"
  ON public.expenses FOR INSERT TO anon WITH CHECK (true);

DROP POLICY IF EXISTS "Allow anon update expenses" ON public.expenses;
CREATE POLICY "Allow anon update expenses"
  ON public.expenses FOR UPDATE TO anon USING (true) WITH CHECK (true);

DROP POLICY IF EXISTS "Allow anon delete expenses" ON public.expenses;
CREATE POLICY "Allow anon delete expenses"
  ON public.expenses FOR DELETE TO anon USING (true);

-- incomes
DROP POLICY IF EXISTS "Allow anon select incomes" ON public.incomes;
CREATE POLICY "Allow anon select incomes"
  ON public.incomes FOR SELECT TO anon USING (true);

DROP POLICY IF EXISTS "Allow anon insert incomes" ON public.incomes;
CREATE POLICY "Allow anon insert incomes"
  ON public.incomes FOR INSERT TO anon WITH CHECK (true);

DROP POLICY IF EXISTS "Allow anon update incomes" ON public.incomes;
CREATE POLICY "Allow anon update incomes"
  ON public.incomes FOR UPDATE TO anon USING (true) WITH CHECK (true);

DROP POLICY IF EXISTS "Allow anon delete incomes" ON public.incomes;
CREATE POLICY "Allow anon delete incomes"
  ON public.incomes FOR DELETE TO anon USING (true);

-- budgets
DROP POLICY IF EXISTS "Allow anon select budgets" ON public.budgets;
CREATE POLICY "Allow anon select budgets"
  ON public.budgets FOR SELECT TO anon USING (true);

DROP POLICY IF EXISTS "Allow anon insert budgets" ON public.budgets;
CREATE POLICY "Allow anon insert budgets"
  ON public.budgets FOR INSERT TO anon WITH CHECK (true);

DROP POLICY IF EXISTS "Allow anon update budgets" ON public.budgets;
CREATE POLICY "Allow anon update budgets"
  ON public.budgets FOR UPDATE TO anon USING (true) WITH CHECK (true);

-- -----------------------------------------------------------------
-- SECTION 2: SECURITY DEFINER functions (backup approach)
-- These let Flutter call RPC functions that bypass RLS,
-- even if the policies above aren't applied yet.
-- -----------------------------------------------------------------

-- Function: get all members for the family
CREATE OR REPLACE FUNCTION public.get_family_members()
RETURNS TABLE (id uuid, family_id uuid, name text)
LANGUAGE sql
SECURITY DEFINER
SET search_path = public
AS $$
  SELECT id, family_id, name
  FROM public.members
  ORDER BY name;
$$;

GRANT EXECUTE ON FUNCTION public.get_family_members() TO anon;

-- Function: get families
CREATE OR REPLACE FUNCTION public.get_families()
RETURNS TABLE (family_id uuid, name text)
LANGUAGE sql
SECURITY DEFINER
SET search_path = public
AS $$
  SELECT family_id, name
  FROM public.families
  LIMIT 1;
$$;

GRANT EXECUTE ON FUNCTION public.get_families() TO anon;

-- -----------------------------------------------------------------
-- SECTION 3: VERIFY (run this after the above to confirm)
-- -----------------------------------------------------------------

-- Check RLS policies
SELECT
    tablename,
    policyname,
    cmd,
    roles::text
FROM pg_policies
WHERE schemaname = 'public'
AND tablename IN ('families', 'members', 'categories', 'expenses', 'incomes', 'budgets')
ORDER BY tablename, policyname;
