# Database Migrations

## Quick Start - Buat Tabel `laundries` (WAJIB!)

### Langkah 1: Buka Supabase SQL Editor
1. Login ke [Supabase Dashboard](https://supabase.com/dashboard)
2. Pilih project: `iqdmlsslzhlchbuiklwf`
3. Klik **SQL Editor** di sidebar kiri
4. Klik **New Query**

### Langkah 2: Copy & Paste SQL Berikut, Lalu Klik **Run**

```sql
-- ============================================
-- Migration: Create laundries table
-- Date: 6 September 2026
-- Description:
--   - Membuat tabel `laundries` untuk multi-tenant support
--   - Menambahkan kolom `laundry_id` ke tabel `staff` dan `orders`
--   - Membuat index untuk performa
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
CREATE INDEX IF NOT EXISTS idx_laundries_owner_id ON laundries(owner_id);

-- 5. Buat default laundry untuk owner yang sudah ada
DO $$
DECLARE
    v_owner_id INTEGER;
BEGIN
    -- Cari owner pertama yang belum punya laundry
    SELECT id INTO v_owner_id FROM staff WHERE role = 'owner' LIMIT 1;
    
    IF v_owner_id IS NOT NULL THEN
        -- Cek apakah sudah ada laundry untuk owner ini
        IF NOT EXISTS (SELECT 1 FROM laundries WHERE owner_id = v_owner_id) THEN
            -- Buat laundry default
            INSERT INTO laundries (name, address, phone, owner_id)
            VALUES ('Laundry28', NULL, NULL, v_owner_id);
        END IF;
    END IF;
END $$;

-- 6. Verifikasi
SELECT 'laundries table created' AS status;
SELECT id, name, address, phone, owner_id FROM laundries;
SELECT id, email, role, laundry_id FROM staff WHERE role = 'owner';
```

### Langkah 3: Setelah Run, Refresh Browser
- Login ulang sebagai `rudi@gmail.com`
- Dashboard akan langsung muncul dengan data orders

---

## Migration Files

| File | Description |
|------|-------------|
| `create_laundries_table.sql` | Create laundries table (multi-tenant) |
| `add_username_role_to_staff.sql` | Add username & role columns to staff |
| `add_pin_to_staff.sql` | Add PIN column to staff for employee login |
| `insert_owner_pandi.sql` | Insert owner account for pandi@gmail.com |
