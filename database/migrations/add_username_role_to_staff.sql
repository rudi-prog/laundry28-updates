-- ============================================
-- Migration: Add username & role to staff table
-- Date: 5 September 2026
-- Description: 
--   - Tambah kolom 'username' untuk login karyawan
--   - Tambah kolom 'role' untuk membedakan owner vs employee
-- ============================================

-- Tambah kolom username (unik, nullable untuk data lama)
ALTER TABLE staff ADD COLUMN IF NOT EXISTS username TEXT UNIQUE;

-- Tambah kolom role dengan default 'employee'
ALTER TABLE staff ADD COLUMN IF NOT EXISTS role TEXT DEFAULT 'employee';

-- Update record yang sudah ada jadi owner (jika email = rudi@gmail.com)
UPDATE staff SET role = 'owner', username = 'rudi_admin' 
WHERE email = 'rudi@gmail.com' AND role IS NULL;

-- Buat index untuk performa loginByUsername
CREATE INDEX IF NOT EXISTS idx_staff_username ON staff(username);

-- ============================================
-- Cara run migration:
-- 1. Buka Supabase Dashboard → SQL Editor
-- 2. Copy paste script ini
-- 3. Klik Run
-- ============================================
