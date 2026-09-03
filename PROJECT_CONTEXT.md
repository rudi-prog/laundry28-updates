# 🧺 Laundry28 - Project Context

## 📝 Deskripsi Proyek
Aplikasi tracking laundry berbasis **Flutter Web** + **Supabase**. 
Konsumen melacak status pesanan via link WhatsApp tanpa perlu install aplikasi. Karyawan mengelola pesanan melalui panel admin yang simpel.

---

## 🏗️ Arsitektur & Teknologi
- **Framework:** Flutter (Web Target)
- **Backend/Database:** Supabase (PostgreSQL + Realtime + Auth)
- **State Management:** `flutter_bloc`
- **Navigation:** `go_router` (mendukung deep link dari WhatsApp)
- **Hosting:** Vercel / Netlify (Gratis)

---

## 📂 Struktur Folder
```
lib/
├── main.dart                  # Entry point aplikasi
├── core/                      # Konfigurasi global
│   ├── constants/             # Routes, Colors, Strings
│   ├── supabase/              # Setup & koneksi Supabase
│   ├── theme/                 # App Theme & Typography
│   └── utils/                 # Helpers (format currency, date, dll)
├── features/                  # Fitur utama (dipisah per domain)
│   ├── tracking/              # 👤 Sisi Customer (Tanpa Login)
│   │   ├── cubit/             # Logic state tracking
│   │   ├── data/
│   │   │   ├── models/        # OrderModel
│   │   │   └── repositories/  # OrderRepository
│   │   └── presentation/
│   │       ├── screens/       # TrackingScreen
│   │       └── widgets/       # StatusStepper, OrderSummary
│   └── admin/                 # 👨‍💻 Sisi Karyawan (Login)
│       ├── cubit/             # Logic state admin & auth
│       ├── data/
│       │   ├── models/        # StaffModel
│       │   └── repositories/  # AuthRepository, OrderRepo
│       └── presentation/
│           ├── screens/       # LoginScreen, DashboardScreen
│           └── widgets/       # OrderCard, StaffForm
└── shared/                    # Komponen UI reusable
    └── widgets/               # CustomButton, CustomTextField, dll
```

---

## 🗄️ Database Schema (Supabase)

### 1. `staff` (Login Karyawan)
| Kolom | Tipe | Keterangan |
|-------|------|------------|
| `id` | BIGINT | Primary Key (Auto Increment) |
| `username` | TEXT | Unik, untuk login |
| `password` | TEXT | Hash password |
| `full_name` | TEXT | Nama lengkap karyawan |
| `created_at` | TIMESTAMPTZ | Waktu pembuatan akun |

### 2. `orders` (Data Pesanan)
| Kolom | Tipe | Keterangan |
|-------|------|------------|
| `id` | BIGINT | Primary Key |
| `tracking_code` | TEXT | Kode unik (contoh: LTY-001) |
| `customer_name` | TEXT | Nama pelanggan |
| `customer_phone` | TEXT | No WhatsApp pelanggan |
| `service_type` | TEXT | Jenis layanan (Cuci Komplit, Setrika, dll) |
| `status` | TEXT | Default: 'Diterima' |
| `estimated_time` | TIMESTAMPTZ | Estimasi selesai |
| `created_at` | TIMESTAMPTZ | Waktu pesanan dibuat |
| `updated_at` | TIMESTAMPTZ | Update otomatis via Trigger |

### 3. `services` (Opsional: Master Layanan)
| Kolom | Tipe | Keterangan |
|-------|------|------------|
| `id` | BIGINT | Primary Key |
| `name` | TEXT | Nama layanan |
| `price_per_kg` | INT | Harga per kg (opsional) |
| `duration_hours` | INT | Estimasi jam selesai |

---

## 🔄 Alur Sistem
1. **Karyawan** input pesanan → Sistem generate `tracking_code` unik.
2. **Karyawan** klik "Kirim ke WA" → Link tracking terkirim ke customer.
3. **Konsumen** buka link → Langsung lihat status real-time (tanpa login).
4. **Karyawan** update status → Perubahan langsung muncul di HP konsumen (Supabase Realtime).

### Status Flow:
`Diterima` → `Dicuci` → `Dikeringkan` → `Disetrika` → `Siap Diambil` → `Selesai`

---

## 📦 Library Utama (`pubspec.yaml`)
```yaml
dependencies:
  flutter:
    sdk: flutter
  supabase_flutter: ^2.3.0
  flutter_bloc: ^8.1.3
  go_router: ^14.0.0
  intl: ^0.19.0
  url_launcher: ^6.2.1
  qr_flutter: ^4.1.0
```

---

## ✅ Progress Checklist

### Sudah Selesai ✅
- [x] Diskusi konsep & alur sistem
- [x] Setup folder proyek & struktur Clean Architecture
- [x] Buat `PROJECT_CONTEXT.md`
- [x] Buat script SQL setup lengkap (`supabase_final_setup.sql`)
- [x] Coding halaman Login Admin (email/password → Supabase Auth)
- [x] Coding halaman Dashboard Admin (input pesanan, kelola staff)
- [x] Coding halaman Tracking Customer (tanpa login, via link WA)
- [x] **Fix: Missing INTERNET permission di AndroidManifest.xml** ← ROOT CAUSE LOGIN MOBILE GAGAL
- [x] **Fix: False positive SSL error di `_formatError()` auth_cubit.dart**
- [x] Login berhasil di vivo 1807 (release mode) — akun `rudi@gmail.com`
- [x] Git initialized & semua file committed

### Belum Selesai / Next Steps 🔜
- [ ] Testing login admin lain (`admin@laundry28.com`)
- [ ] Testing register flow di mobile
- [ ] Testing error handling (putus internet, timeout, password salah)
- [ ] Deploy Flutter Web ke Vercel/Netlify
- [ ] Optimasi performa & UI polish

---

## 🔧 Latest Changes (9 September 2026)

### Bug Fix: Mobile Admin Login Gagal
**Root Cause:**
1. `INTERNET` permission hilang di `AndroidManifest.xml` → DNS resolution gagal (`errno = 7`)
2. False positive SSL error karena project ID Supabase `iqdmlsslzhlchbuiklwf` mengandung substring `'ssl'`

**Perbaikan:**
- Tambah `<uses-permission android:name="android.permission.INTERNET" />` di manifest
- Perbaiki `_formatError()` di `auth_cubit.dart`: prioritas cek `SocketException`, SSL check lebih spesifik (hindari match project ID)
- Login berhasil di vivo 1807 release mode

**File yang diubah:**
- `android/app/src/main/AndroidManifest.xml`
- `lib/features/admin/cubit/auth_cubit.dart`

---

## 💡 Catatan Penting
- Konsumen **TIDAK** perlu install aplikasi (akses via browser/Flutter Web).
- Konsumen **TIDAK** perlu login/coba ingat kode. Cukup buka link dari WA.
- Karyawan butuh login sederhana (username + password).
- Update status bersifat **real-time** menggunakan fitur `Supabase Realtime`.
- Hosting gratis menggunakan **Vercel** atau **Netlify** untuk Flutter Web.
