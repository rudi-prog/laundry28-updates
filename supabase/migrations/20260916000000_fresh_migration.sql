-- ============================================================
-- LAUNDRY28 - ROW LEVEL SECURITY (RLS) + SERVICE_ROLE GRANTS
-- ============================================================
-- Cakupan: staff, laundries, orders, laundry_services
--
-- Model akses:
--   - Setiap staff (owner/employee) terikat ke satu laundry_id.
--   - Owner  : akses penuh ke SEMUA data dalam laundry-nya sendiri
--              (termasuk update data staff lain di laundry yang sama).
--   - Employee: hanya boleh baca data laundry-nya, dan hanya boleh
--              update baris dirinya sendiri (mis. failed_pin_attempts).
--   - CREATE dan DELETE staff HARUS lewat Edge Function
--     (create-staff / delete-staff) yang pakai service_role key —
--     service_role BYPASS RLS sepenuhnya, jadi sengaja TIDAK dibuat
--     policy INSERT untuk staff lain / DELETE staff sama sekali
--     di sini. Satu-satunya INSERT yang diizinkan dari client adalah
--     insert baris milik diri sendiri saat onboarding awal
--     (lihat AuthRepository.completeOnboarding()).
--
-- CATATAN PENTING (ditambahkan setelah insiden "permission denied
-- for table staff" di edge function create-staff):
--   RLS (ENABLE ROW LEVEL SECURITY) TIDAK sama dengan GRANT.
--   Kalau tabel dibuat/di-restore di luar jalur migrasi standar
--   Supabase, role `service_role` bisa saja TIDAK otomatis dapat
--   privilege ke tabel tsb, meskipun secara desain service_role
--   seharusnya bypass RLS sepenuhnya — RLS baru berlaku SETELAH
--   privilege dasar (SELECT/INSERT/UPDATE/DELETE) itu ada. Makanya
--   bagian GRANT di bawah WAJIB ada supaya edge function yang pakai
--   service_role key (create-staff, delete-staff, dst) bisa jalan.
--
-- Aman dijalankan ulang (semua pakai DROP IF EXISTS / CREATE OR REPLACE
-- / GRANT yang idempotent).
-- ============================================================


-- ------------------------------------------------------------
-- 0. HELPER FUNCTIONS
-- ------------------------------------------------------------
-- SECURITY DEFINER dipakai supaya function ini boleh baca tabel
-- `staff` TANPA melalui RLS staff itu sendiri — kalau tidak,
-- policy staff yang memanggil function ini akan infinite recursion
-- (policy staff butuh baca staff, yang butuh cek policy staff, dst).

CREATE OR REPLACE FUNCTION public.current_staff_id()
RETURNS bigint
LANGUAGE sql
SECURITY DEFINER
STABLE
SET search_path = public
AS $$
  SELECT id FROM public.staff WHERE auth_user_id = auth.uid() LIMIT 1;
$$;

CREATE OR REPLACE FUNCTION public.current_laundry_id()
RETURNS bigint
LANGUAGE sql
SECURITY DEFINER
STABLE
SET search_path = public
AS $$
  SELECT laundry_id FROM public.staff WHERE auth_user_id = auth.uid() LIMIT 1;
$$;

CREATE OR REPLACE FUNCTION public.current_role()
RETURNS text
LANGUAGE sql
SECURITY DEFINER
STABLE
SET search_path = public
AS $$
  SELECT role FROM public.staff WHERE auth_user_id = auth.uid() LIMIT 1;
$$;

CREATE OR REPLACE FUNCTION public.is_owner()
RETURNS boolean
LANGUAGE sql
SECURITY DEFINER
STABLE
SET search_path = public
AS $$
  SELECT public.current_role() = 'owner';
$$;


-- ============================================================
-- 1. TABLE: staff
-- ============================================================

ALTER TABLE public.staff ENABLE ROW LEVEL SECURITY;

-- SELECT: boleh lihat baris diri sendiri, atau semua staff di laundry yang sama
DROP POLICY IF EXISTS staff_select ON public.staff;
CREATE POLICY staff_select ON public.staff
  FOR SELECT
  TO authenticated
  USING (
    auth_user_id = auth.uid()
    OR laundry_id = public.current_laundry_id()
  );

-- INSERT: HANYA boleh insert baris untuk diri sendiri (onboarding awal).
-- Membuat staff LAIN (karyawan) wajib lewat edge function create-staff
-- (service_role) — sengaja tidak ada policy untuk itu di sini.
DROP POLICY IF EXISTS staff_insert_self ON public.staff;
CREATE POLICY staff_insert_self ON public.staff
  FOR INSERT
  TO authenticated
  WITH CHECK (
    auth_user_id = auth.uid()
  );

-- UPDATE: diri sendiri boleh update baris sendiri (mis. reset failed_pin_attempts
-- saat login, atau melengkapi laundry_id saat onboarding). Owner boleh update
-- baris staff LAIN asal masih dalam laundry yang sama.
DROP POLICY IF EXISTS staff_update ON public.staff;
CREATE POLICY staff_update ON public.staff
  FOR UPDATE
  TO authenticated
  USING (
    auth_user_id = auth.uid()
    OR (public.is_owner() AND laundry_id = public.current_laundry_id())
  )
  WITH CHECK (
    auth_user_id = auth.uid()
    OR (public.is_owner() AND laundry_id = public.current_laundry_id())
  );

-- DELETE: TIDAK ADA policy sama sekali — delete staff wajib lewat
-- edge function delete-staff (service_role). Client (authenticated/anon)
-- tidak bisa DELETE baris staff dalam kondisi apa pun.


-- ============================================================
-- 2. TABLE: laundries
-- ============================================================

ALTER TABLE public.laundries ENABLE ROW LEVEL SECURITY;

-- SELECT: staff boleh lihat laundry tempat dia terdaftar
DROP POLICY IF EXISTS laundries_select ON public.laundries;
CREATE POLICY laundries_select ON public.laundries
  FOR SELECT
  TO authenticated
  USING (
    id = public.current_laundry_id()
    OR owner_id = public.current_staff_id()
  );

-- INSERT: dipakai saat onboarding (owner bikin laundry pertamanya).
-- Dibatasi: owner_id yang di-insert harus = staff id milik user yang login.
DROP POLICY IF EXISTS laundries_insert ON public.laundries;
CREATE POLICY laundries_insert ON public.laundries
  FOR INSERT
  TO authenticated
  WITH CHECK (
    owner_id = public.current_staff_id()
  );

-- UPDATE: hanya owner dari laundry tsb yang boleh update (misal ganti nama/alamat)
DROP POLICY IF EXISTS laundries_update ON public.laundries;
CREATE POLICY laundries_update ON public.laundries
  FOR UPDATE
  TO authenticated
  USING (
    owner_id = public.current_staff_id()
    AND public.is_owner()
  )
  WITH CHECK (
    owner_id = public.current_staff_id()
    AND public.is_owner()
  );

-- DELETE: tidak ada policy — hapus laundry sebaiknya proses khusus/manual,
-- bukan operasi rutin dari app.


-- ============================================================
-- 3. TABLE: orders
-- ============================================================

ALTER TABLE public.orders ENABLE ROW LEVEL SECURITY;

-- SELECT: staff (owner & employee) boleh lihat semua order di laundry-nya
DROP POLICY IF EXISTS orders_select ON public.orders;
CREATE POLICY orders_select ON public.orders
  FOR SELECT
  TO authenticated
  USING (
    laundry_id = public.current_laundry_id()
  );

-- INSERT: staff boleh bikin order baru untuk laundry-nya sendiri
DROP POLICY IF EXISTS orders_insert ON public.orders;
CREATE POLICY orders_insert ON public.orders
  FOR INSERT
  TO authenticated
  WITH CHECK (
    laundry_id = public.current_laundry_id()
  );

-- UPDATE: staff boleh update order (ubah status, dsb) di laundry-nya sendiri
DROP POLICY IF EXISTS orders_update ON public.orders;
CREATE POLICY orders_update ON public.orders
  FOR UPDATE
  TO authenticated
  USING (
    laundry_id = public.current_laundry_id()
  )
  WITH CHECK (
    laundry_id = public.current_laundry_id()
  );

-- DELETE: hanya owner yang boleh hapus order (employee tidak boleh hapus)
DROP POLICY IF EXISTS orders_delete ON public.orders;
CREATE POLICY orders_delete ON public.orders
  FOR DELETE
  TO authenticated
  USING (
    laundry_id = public.current_laundry_id()
    AND public.is_owner()
  );


-- ============================================================
-- 4. TABLE: laundry_services
-- ============================================================

ALTER TABLE public.laundry_services ENABLE ROW LEVEL SECURITY;

-- SELECT: staff boleh lihat daftar layanan laundry-nya
DROP POLICY IF EXISTS laundry_services_select ON public.laundry_services;
CREATE POLICY laundry_services_select ON public.laundry_services
  FOR SELECT
  TO authenticated
  USING (
    laundry_id = public.current_laundry_id()
  );

-- INSERT/UPDATE/DELETE: hanya owner yang boleh kelola daftar layanan
-- (Catatan: trigger auto-seed jalan via SECURITY DEFINER function,
-- jadi tetap berfungsi normal terlepas dari policy ini.)
DROP POLICY IF EXISTS laundry_services_insert ON public.laundry_services;
CREATE POLICY laundry_services_insert ON public.laundry_services
  FOR INSERT
  TO authenticated
  WITH CHECK (
    laundry_id = public.current_laundry_id()
    AND public.is_owner()
  );

DROP POLICY IF EXISTS laundry_services_update ON public.laundry_services;
CREATE POLICY laundry_services_update ON public.laundry_services
  FOR UPDATE
  TO authenticated
  USING (
    laundry_id = public.current_laundry_id()
    AND public.is_owner()
  )
  WITH CHECK (
    laundry_id = public.current_laundry_id()
    AND public.is_owner()
  );

DROP POLICY IF EXISTS laundry_services_delete ON public.laundry_services;
CREATE POLICY laundry_services_delete ON public.laundry_services
  FOR DELETE
  TO authenticated
  USING (
    laundry_id = public.current_laundry_id()
    AND public.is_owner()
  );


-- ============================================================
-- 5. TRACKING PUBLIK (anon, tanpa login)
-- ============================================================
-- Halaman tracking.html dipakai PELANGGAN yang TIDAK login (role
-- Supabase = anon, bukan authenticated). Semua policy RLS di atas
-- ("TO authenticated") tidak berlaku untuk mereka, jadi tanpa ini
-- query order dari halaman tracking akan SELALU kosong.
--
-- SENGAJA tidak dibuat sebagai policy "SELECT ... TO anon USING (true)"
-- di tabel orders/laundries, karena anon key itu PUBLIK (ada di kode
-- HTML, siapa saja bisa lihat). Kalau policy anon dibuka lebar begitu,
-- siapa pun yang punya anon key bisa query SEMUA order langsung lewat
-- REST API (bukan cuma lewat tracking_code spesifik di halaman ini) —
-- berisiko bocor data pelanggan (nama, no. telepon) secara massal.
--
-- Sebagai gantinya: function SECURITY DEFINER yang HANYA menerima
-- satu tracking_code spesifik dan return data order yang cocok. Tidak
-- ada cara untuk "list semua order" lewat function ini — pemanggil
-- HARUS tahu tracking_code yang valid lebih dulu.

CREATE OR REPLACE FUNCTION public.get_order_by_tracking_code(p_tracking_code text)
RETURNS TABLE (
  tracking_code text,
  customer_name text,
  customer_phone text,
  service_type text,
  estimated_time timestamptz,
  weight numeric,
  total_price numeric,
  status text,
  created_at timestamptz,
  updated_at timestamptz,
  laundry_name text
)
LANGUAGE sql
SECURITY DEFINER
STABLE
SET search_path = public
AS $$
  SELECT
    o.tracking_code,
    o.customer_name,
    o.customer_phone,
    o.service_type,
    o.estimated_time,
    o.weight,
    o.total_price,
    o.status,
    o.created_at,
    o.updated_at,
    l.name AS laundry_name
  FROM public.orders o
  JOIN public.laundries l ON l.id = o.laundry_id
  WHERE o.tracking_code = p_tracking_code
  LIMIT 1;
$$;

-- Izinkan role anon (pengunjung tanpa login) MEMANGGIL function ini
-- saja — bukan akses langsung ke tabel. Ini yang bikin aman: anon
-- tidak pernah dapat GRANT SELECT ke tabel orders/laundries itu sendiri.
GRANT EXECUTE ON FUNCTION public.get_order_by_tracking_code(text) TO anon;


-- ============================================================
-- 6. GRANTS UNTUK service_role
-- ============================================================
-- WAJIB ADA: edge functions (create-staff, delete-staff, dan edge
-- function lain yang pakai SUPABASE_SERVICE_ROLE_KEY) query lewat
-- REST API (PostgREST) dengan role `service_role`. Tanpa GRANT ini,
-- PostgREST akan balas 403 "permission denied for table ..." (kode
-- Postgres 42501) meskipun RLS sudah benar, karena privilege dasar
-- ke tabel belum tentu ter-apply otomatis (terutama kalau tabel
-- sempat dibuat/di-restore di luar jalur migrasi Supabase standar).
--
-- Baris ALTER DEFAULT PRIVILEGES di bagian akhir memastikan tabel
-- BARU yang dibuat nanti otomatis dapat grant ini juga, tanpa perlu
-- diulang manual setiap kali bikin tabel baru.

GRANT ALL ON TABLE public.staff TO service_role;
GRANT ALL ON TABLE public.laundries TO service_role;
GRANT ALL ON TABLE public.orders TO service_role;
GRANT ALL ON TABLE public.laundry_services TO service_role;

GRANT USAGE, SELECT ON ALL SEQUENCES IN SCHEMA public TO service_role;

ALTER DEFAULT PRIVILEGES IN SCHEMA public
  GRANT ALL ON TABLES TO service_role;

ALTER DEFAULT PRIVILEGES IN SCHEMA public
  GRANT USAGE, SELECT ON SEQUENCES TO service_role;


-- ============================================================
-- 7. VERIFIKASI
-- ============================================================
-- Jalankan setelah migrasi untuk memastikan semua policy terpasang:

SELECT tablename, policyname, cmd
FROM pg_policies
WHERE schemaname = 'public'
  AND tablename IN ('staff', 'laundries', 'orders', 'laundry_services')
ORDER BY tablename, cmd;

-- Jalankan untuk memastikan service_role sudah dapat privilege ke semua tabel:

SELECT table_name, grantee, privilege_type
FROM information_schema.role_table_grants
WHERE table_schema = 'public'
  AND grantee = 'service_role'
  AND table_name IN ('staff', 'laundries', 'orders', 'laundry_services')
ORDER BY table_name, privilege_type;

-- Jalankan untuk memastikan anon bisa memanggil function tracking publik
-- (harus muncul 1 baris dengan privilege_type = EXECUTE):

SELECT routine_name, grantee, privilege_type
FROM information_schema.routine_privileges
WHERE routine_schema = 'public'
  AND routine_name = 'get_order_by_tracking_code'
  AND grantee = 'anon';

-- Tes langsung function-nya dengan tracking_code yang valid (ganti
-- 'KODE-DISINI' dengan kode tracking pesanan yang sungguhan ada):

-- SELECT * FROM public.get_order_by_tracking_code('KODE-DISINI');