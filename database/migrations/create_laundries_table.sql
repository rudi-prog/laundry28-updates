-- ============================================
-- Multi-tenant: Create laundries table
-- ============================================

-- 1. Buat tabel laundries
CREATE TABLE IF NOT EXISTS laundries (
    id SERIAL PRIMARY KEY,
    name TEXT NOT NULL,
    address TEXT,
    phone TEXT,
    logo_url TEXT,
    owner_id INTEGER REFERENCES staff(id) ON DELETE SET NULL,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- 2. Tambah kolom laundry_id ke tabel staff
ALTER TABLE staff ADD COLUMN IF NOT EXISTS laundry_id INTEGER REFERENCES laundries(id) ON DELETE SET NULL;

-- 3. Tambah kolom laundry_id ke tabel orders
ALTER TABLE orders ADD COLUMN IF NOT EXISTS laundry_id INTEGER REFERENCES laundries(id) ON DELETE SET NULL;

-- 4. Buat index untuk performa query
CREATE INDEX IF NOT EXISTS idx_staff_laundry_id ON staff(laundry_id);
CREATE INDEX IF NOT EXISTS idx_orders_laundry_id ON orders(laundry_id);

-- 5. Migrasi owner yang sudah ada (Pandi) ke laundry baru
--    (hanya jika belum punya laundry_id)
DO $$
DECLARE
    v_owner_id INTEGER;
    v_laundry_id INTEGER;
BEGIN
    -- Cari owner yang belum punya laundry_id
    SELECT id INTO v_owner_id FROM staff WHERE role = 'owner' AND laundry_id IS NULL LIMIT 1;

    IF v_owner_id IS NOT NULL THEN
        -- Buat laundry default bernama 'Laundry28'
        INSERT INTO laundries (name, owner_id)
        VALUES ('Laundry28', v_owner_id)
        RETURNING id INTO v_laundry_id;

        -- Update owner ke laundry baru
        UPDATE staff SET laundry_id = v_laundry_id WHERE id = v_owner_id;

        -- Update semua order lama milik owner tersebut
        UPDATE orders SET laundry_id = v_laundry_id
        WHERE laundry_id IS NULL;
    END IF;
END $$;
