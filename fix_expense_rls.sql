-- =================================================================
-- CREATE insert_expense RPC FUNCTION
-- Same SECURITY DEFINER pattern as get_family_members()
-- which is already working in the app.
--
-- Run this in the Supabase SQL Editor:
-- https://supabase.com/dashboard/project/eowvprknwokacnmickgt/sql/new
-- =================================================================

-- This function bypasses RLS (SECURITY DEFINER), but validates
-- that the member actually belongs to the given family before inserting.
CREATE OR REPLACE FUNCTION public.insert_expense(
    p_family_id uuid,
    p_member_id uuid,
    p_category_id uuid DEFAULT NULL,
    p_description text DEFAULT '',
    p_amount numeric DEFAULT 0,
    p_payment_mode text DEFAULT 'Cash',
    p_expense_date date DEFAULT CURRENT_DATE,
    p_expense_time text DEFAULT ''
)
RETURNS json
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
DECLARE
    result json;
BEGIN
    -- Validate: member must exist and belong to the given family
    IF NOT EXISTS (
        SELECT 1 FROM public.members m
        WHERE m.id = p_member_id AND m.family_id = p_family_id
    ) THEN
        RAISE EXCEPTION 'Invalid member_id or member does not belong to the given family';
    END IF;

    -- Insert the expense
    INSERT INTO public.expenses (
        family_id,
        member_id,
        category_id,
        description,
        amount,
        payment_mode,
        expense_date,
        expense_time
    ) VALUES (
        p_family_id,
        p_member_id,
        p_category_id,
        p_description,
        p_amount,
        p_payment_mode,
        p_expense_date,
        p_expense_time
    )
    RETURNING row_to_json(expenses.*) INTO result;

    RETURN result;
END;
$$;

-- Grant the anon role permission to call this function
GRANT EXECUTE ON FUNCTION public.insert_expense(uuid, uuid, uuid, text, numeric, text, date, text) TO anon;

-- =================================================================
-- VERIFY: Test that the function exists
-- =================================================================
SELECT routine_name, routine_type
FROM information_schema.routines
WHERE routine_schema = 'public'
  AND routine_name = 'insert_expense';
