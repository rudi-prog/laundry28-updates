-- ============================================
-- Migration: Fix laundries table RLS & permissions
-- Date: 6 September 2026
-- Description:
--   - Enable RLS on laundries table
--   - Add policies for authenticated users
--   - Grant USAGE on laundries_id_seq sequence
--   - Fix 403 Forbidden error on INSERT/SELECT/UPDATE/DELETE
-- ============================================

-- 1. Enable Row Level Security on laundries table
ALTER TABLE laundries ENABLE ROW LEVEL SECURITY;

-- 2. Drop existing policies if any (idempotent)
DROP POLICY IF EXISTS "Allow authenticated users to select laundries" ON laundries;
DROP POLICY IF EXISTS "Allow authenticated users to insert laundries" ON laundries;
DROP POLICY IF EXISTS "Allow authenticated users to update their own laundries" ON laundries;
DROP POLICY IF EXISTS "Allow authenticated users to delete their own laundries" ON laundries;

-- 3. Create RLS policies for laundries table

-- SELECT: All authenticated users can read laundries
CREATE POLICY "Allow authenticated users to select laundries"
    ON laundries
    FOR SELECT
    TO authenticated
    USING (true);

-- INSERT: Authenticated users can create laundries
CREATE POLICY "Allow authenticated users to insert laundries"
    ON laundries
    FOR INSERT
    TO authenticated
    WITH CHECK (true);

-- UPDATE: Authenticated users can update laundries they own
CREATE POLICY "Allow authenticated users to update their own laundries"
    ON laundries
    FOR UPDATE
    TO authenticated
    USING (owner_id = (SELECT id FROM staff WHERE email = auth.jwt()->>'email'))
    WITH CHECK (owner_id = (SELECT id FROM staff WHERE email = auth.jwt()->>'email'));

-- DELETE: Authenticated users can delete laundries they own
CREATE POLICY "Allow authenticated users to delete their own laundries"
    ON laundries
    FOR DELETE
    TO authenticated
    USING (owner_id = (SELECT id FROM staff WHERE email = auth.jwt()->>'email'));

-- 4. Grant USAGE on the sequence so authenticated users can use auto-increment
GRANT USAGE ON SEQUENCE laundries_id_seq TO authenticated;
GRANT SELECT ON SEQUENCE laundries_id_seq TO authenticated;

-- 5. Also fix RLS & permissions for staff table
ALTER TABLE staff ENABLE ROW LEVEL SECURITY;

DROP POLICY IF EXISTS "Allow authenticated users to select staff" ON staff;
DROP POLICY IF EXISTS "Allow authenticated users to insert staff" ON staff;
DROP POLICY IF EXISTS "Allow authenticated users to update staff" ON staff;
DROP POLICY IF EXISTS "Allow authenticated users to delete staff" ON staff;

CREATE POLICY "Allow authenticated users to select staff"
    ON staff FOR SELECT TO authenticated USING (true);

CREATE POLICY "Allow authenticated users to insert staff"
    ON staff FOR INSERT TO authenticated WITH CHECK (true);

CREATE POLICY "Allow authenticated users to update staff"
    ON staff FOR UPDATE TO authenticated USING (true) WITH CHECK (true);

CREATE POLICY "Allow authenticated users to delete staff"
    ON staff FOR DELETE TO authenticated USING (true);

-- 6. Also fix RLS & permissions for orders table
ALTER TABLE orders ENABLE ROW LEVEL SECURITY;

DROP POLICY IF EXISTS "Allow authenticated users to select orders" ON orders;
DROP POLICY IF EXISTS "Allow authenticated users to insert orders" ON orders;
DROP POLICY IF EXISTS "Allow authenticated users to update orders" ON orders;
DROP POLICY IF EXISTS "Allow authenticated users to delete orders" ON orders;

CREATE POLICY "Allow authenticated users to select orders"
    ON orders FOR SELECT TO authenticated USING (true);

CREATE POLICY "Allow authenticated users to insert orders"
    ON orders FOR INSERT TO authenticated WITH CHECK (true);

CREATE POLICY "Allow authenticated users to update orders"
    ON orders FOR UPDATE TO authenticated USING (true) WITH CHECK (true);

CREATE POLICY "Allow authenticated users to delete orders"
    ON orders FOR DELETE TO authenticated USING (true);

-- 7. Grant permissions on all sequences
GRANT USAGE ON ALL SEQUENCES IN SCHEMA public TO authenticated;
GRANT SELECT ON ALL TABLES IN SCHEMA public TO authenticated;

-- 8. Verify the policies
SELECT schemaname, tablename, policyname, permissive, roles, cmd, qual, with_check
FROM pg_policies
WHERE tablename IN ('laundries', 'staff', 'orders')
ORDER BY tablename, policyname;

-- ============================================
-- Cara run migration:
-- 1. Buka Supabase Dashboard → SQL Editor
-- 2. Copy paste script ini
-- 3. Klik Run
-- ============================================
