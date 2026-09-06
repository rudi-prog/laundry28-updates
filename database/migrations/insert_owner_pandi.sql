-- ============================================
-- Migration: Insert Owner Account (pandi@gmail.com)
-- Date: 6 September 2026
-- Description:
--   - Insert record untuk pandi@gmail.com ke tabel staff
--   - Set role = 'owner' agar redirect ke Owner Dashboard
--   - Owner ini dibuat via Supabase Auth register, tapi belum ada record di tabel staff
-- ============================================

-- Insert owner record jika belum ada
INSERT INTO staff (email, full_name, username, role, created_at)
VALUES (
  'pandi@gmail.com',
  'Pandi',
  'pandi_owner',
  'owner',
  NOW()
)
ON CONFLICT (email) DO NOTHING;

-- Verify the insertion
SELECT email, full_name, username, role FROM staff WHERE email = 'pandi@gmail.com';

-- ============================================
-- Cara run migration:
-- 1. Buka Supabase Dashboard → SQL Editor
-- 2. Copy paste script ini
-- 3. Klik Run
-- ============================================
