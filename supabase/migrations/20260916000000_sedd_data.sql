-- ============================================================
-- LAUNDRY28 - DEFAULT SERVICES + AUTO SEED
-- ============================================================
-- Tujuan:
-- 1. Setiap laundry baru otomatis mendapat 8 layanan bawaan.
-- 2. Aman terhadap RLS.
-- 3. Tidak membuat duplicate service.
-- 4. Bisa dijalankan ulang.
-- ============================================================


-- ============================================================
-- 1. PASTIKAN UNIQUE CONSTRAINT ADA
-- ============================================================

ALTER TABLE public.laundry_services
DROP CONSTRAINT IF EXISTS laundry_services_laundry_id_name_key;

ALTER TABLE public.laundry_services
ADD CONSTRAINT laundry_services_laundry_id_name_key
UNIQUE (laundry_id, name);


-- ============================================================
-- 2. FUNCTION SEED DEFAULT SERVICES
-- ============================================================

CREATE OR REPLACE FUNCTION public.seed_default_services_on_laundry()
RETURNS TRIGGER
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
DECLARE
    v_now TIMESTAMPTZ := NOW();
BEGIN

    -- Cuci Komplit
    INSERT INTO public.laundry_services
        (laundry_id, name, price, duration_hours, sort_order, is_active, created_at)
    VALUES
        (NEW.id, 'Cuci Komplit', 7000, 2, 1, true, v_now)
    ON CONFLICT (laundry_id, name) DO NOTHING;


    -- Cuci Kering
    INSERT INTO public.laundry_services
        (laundry_id, name, price, duration_hours, sort_order, is_active, created_at)
    VALUES
        (NEW.id, 'Cuci Kering', 5000, 3, 2, true, v_now)
    ON CONFLICT (laundry_id, name) DO NOTHING;


    -- Setrika Saja
    INSERT INTO public.laundry_services
        (laundry_id, name, price, duration_hours, sort_order, is_active, created_at)
    VALUES
        (NEW.id, 'Setrika Saja', 4000, 1, 3, true, v_now)
    ON CONFLICT (laundry_id, name) DO NOTHING;


    -- Cuci Bed Cover
    INSERT INTO public.laundry_services
        (laundry_id, name, price, duration_hours, sort_order, is_active, created_at)
    VALUES
        (NEW.id, 'Cuci Bed Cover', 15000, 3, 4, true, v_now)
    ON CONFLICT (laundry_id, name) DO NOTHING;


    -- Cuci Karpet
    INSERT INTO public.laundry_services
        (laundry_id, name, price, duration_hours, sort_order, is_active, created_at)
    VALUES
        (NEW.id, 'Cuci Karpet', 8000, 3, 5, true, v_now)
    ON CONFLICT (laundry_id, name) DO NOTHING;


    -- Cuci Sepatu
    INSERT INTO public.laundry_services
        (laundry_id, name, price, duration_hours, sort_order, is_active, created_at)
    VALUES
        (NEW.id, 'Cuci Sepatu', 25000, 3, 6, true, v_now)
    ON CONFLICT (laundry_id, name) DO NOTHING;


    -- Cuci Jas
    INSERT INTO public.laundry_services
        (laundry_id, name, price, duration_hours, sort_order, is_active, created_at)
    VALUES
        (NEW.id, 'Cuci Jas', 35000, 2, 7, true, v_now)
    ON CONFLICT (laundry_id, name) DO NOTHING;


    -- Cuci Selimut
    INSERT INTO public.laundry_services
        (laundry_id, name, price, duration_hours, sort_order, is_active, created_at)
    VALUES
        (NEW.id, 'Cuci Selimut', 20000, 3, 8, true, v_now)
    ON CONFLICT (laundry_id, name) DO NOTHING;


    RETURN NEW;

END;
$$;


-- ============================================================
-- 3. TRIGGER
-- ============================================================

DROP TRIGGER IF EXISTS trigger_seed_default_services
ON public.laundries;

CREATE TRIGGER trigger_seed_default_services
AFTER INSERT ON public.laundries
FOR EACH ROW
EXECUTE FUNCTION public.seed_default_services_on_laundry();


-- ============================================================
-- 4. SEED LAUNDRY LAMA
-- ============================================================
-- Bagian ini mengisi layanan default untuk laundry yang
-- sudah ada sebelum trigger dibuat.
--
-- Laundry baru TIDAK membutuhkan bagian ini karena trigger
-- di atas akan otomatis menjalankannya.
-- ============================================================

INSERT INTO public.laundry_services
    (laundry_id, name, price, duration_hours, sort_order, is_active, created_at)
SELECT
    l.id,
    s.name,
    s.price,
    s.duration_hours,
    s.sort_order,
    true,
    NOW()
FROM public.laundries l
CROSS JOIN (
    VALUES
        ('Cuci Komplit', 7000::NUMERIC, 2, 1),
        ('Cuci Kering', 5000::NUMERIC, 3, 2),
        ('Setrika Saja', 4000::NUMERIC, 1, 3),
        ('Cuci Bed Cover', 15000::NUMERIC, 3, 4),
        ('Cuci Karpet', 8000::NUMERIC, 3, 5),
        ('Cuci Sepatu', 25000::NUMERIC, 3, 6),
        ('Cuci Jas', 35000::NUMERIC, 2, 7),
        ('Cuci Selimut', 20000::NUMERIC, 3, 8)
) AS s(name, price, duration_hours, sort_order)
ON CONFLICT (laundry_id, name) DO NOTHING;


-- ============================================================
-- 5. VERIFIKASI
-- ============================================================

SELECT
    l.id AS laundry_id,
    l.name AS laundry_name,
    COUNT(ls.id) AS jumlah_layanan
FROM public.laundries l
LEFT JOIN public.laundry_services ls
    ON ls.laundry_id = l.id
GROUP BY l.id, l.name
ORDER BY l.id;