-- ============================================
-- Migration: Add pin column to staff table
-- Date: 6 September 2026
-- Description: 
--   - Tambah kolom 'pin' untuk autentikasi karyawan (PIN-based login)
--   - Kolom ini menggantikan email sebagai kredensial login
-- ============================================

-- Tambah kolom pin (nullable untuk data lama, 4-6 digit)
ALTER TABLE staff ADD COLUMN IF NOT EXISTS pin TEXT;

-- Update record yang sudah ada dengan PIN default (opsional, gunakan jika perlu)
-- UPDATE staff SET pin = '1234' WHERE pin IS NULL;

-- Buat index untuk performa login via pin (jika diperlukan)
CREATE INDEX IF NOT EXISTS idx_staff_pin ON staff(pin);

-- ============================================
-- Cara run migration:
-- 1. Buka Supabase Dashboard → SQL Editor
-- 2. Copy paste script ini
-- 3. Klik Run
-- ============================================
