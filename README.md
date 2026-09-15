# Cuci28 - Sistem Manajemen Laundry

<div align="center">

![Flutter](https://img.shields.io/badge/Flutter-3.13+-02569B?style=for-the-badge&logo=flutter&logoColor=white)
![Dart](https://img.shields.io/badge/Dart-3.13+-0175C2?style=for-the-badge&logo=dart&logoColor=white)
![Supabase](https://img.shields.io/badge/Supabase-2.3+-3ECF8E?style=for-the-badge&logo=supabase&logoColor=white)
![License](https://img.shields.io/badge/License-MIT-green?style=for-the-badge)

**Aplikasi manajemen laundry modern dengan fitur lengkap untuk owner dan karyawan.**

[Fitur](#fitur) • [Arsitektur](#arsitektur) • [Setup](#getting-started) • [Database](#database-setup) • [Struktur Project](#struktur-project)

</div>

---

## 📋 Daftar Isi

- [Fitur Utama](#fitur-utama)
- [Arsitektur](#arsitektur)
- [Tech Stack](#tech-stack)
- [Struktur Project](#struktur-project)
- [Getting Started](#getting-started)
- [Environment Variables](#environment-variables)
- [Database Setup](#database-setup)
- [State Management](#state-management)
- [Fitur Detail](#fitur-detail)
- [Screens](#screens)
- [Data Models](#data-models)
- [Database Schema](#database-schema)
- [Entity Relationship Diagram](#entity-relationship-diagram)
- [Security](#security)
- [Testing](#testing)
- [Kontribusi](#kontribusi)
- [Lisensi](#lisensi)

---

## 🚀 Fitur Utama

### 👑 Owner (Pemilik)
| Fitur | Deskripsi |
|-------|-----------|
| **Login Email** | Autentikasi menggunakan email + password via Supabase Auth |
| **Login OAuth** | Masuk menggunakan Google OAuth |
| **Onboarding Laundry** | Setup data laundry pertama kali (nama, alamat, telepon) |
| **Dashboard** | Ringkasan pesanan, statistik, dan notifikasi real-time |
| **Manajemen Layanan** | CRUD layanan (tambah, edit, hapus, aktif/nonaktif) |
| **Manajemen Karyawan** | Tambah, edit, hapus karyawan dengan username & PIN |
| **Buat Pesanan Baru** | Input pesanan pelanggan dengan tracking code otomatis |
| **Laporan Harian** | Laporan operasional harian (total cucian, status, pendapatan) |
| **Laporan Keuangan** | Laporan pendapatan mingguan/bulanan dengan breakdown per layanan |

### 👨‍💼 Karyawan (Staff)
| Fitur | Deskripsi |
|-------|-----------|
| **Login PIN** | Autentikasi cepat menggunakan PIN 4-6 digit |
| **Dashboard Karyawan** | Daftar pesanan masuk dengan status terkini |
| **Update Status Pesanan** | Ubah status cucian (Diterima → Dicuci → Dikeringkan → Disetrika → Siap Diambil → Selesai) |

### 👤 Pelanggan
| Fitur | Deskripsi |
|-------|-----------|
| **Tracking Pesanan** | Lacak status pesanan melalui kode tracking (halaman publik) |
| **Status Real-time** | Lihat progress cucian secara visual dengan stepper |

---

## 🏗️ Arsitektur

Proyek ini menggunakan **Clean Architecture** dengan pemisahan berlapis yang jelas:

```
┌─────────────────────────────────────────────────────────┐
│                   Presentation Layer                     │
│  ┌─────────────┐  ┌──────────────┐  ┌───────────────┐  │
│  │   Screens   │  │    Widgets   │  │    Routes     │  │
│  └─────────────┘  └──────────────┘  └───────────────┘  │
├─────────────────────────────────────────────────────────┤
│                      BLoC / Cubit                       │
│  ┌─────────────┐  ┌──────────────┐  ┌───────────────┐  │
│  │  AuthCubit  │  │  Dashboard   │  │  ReportCubit  │  │
│  │  LaundryCub │  │    Cubit     │  │  ServiceCubit │  │
│  │  NewOrderCt │  │  StaffCubit  │  │ TrackingCubit │  │
│  └─────────────┘  └──────────────┘  └───────────────┘  │
├─────────────────────────────────────────────────────────┤
│                      Data Layer                         │
│  ┌─────────────┐  ┌──────────────┐  ┌───────────────┐  │
│  │   Models    │  │  Repositories│  │   Services    │  │
│  └─────────────┘  └──────────────┘  └───────────────┘  │
├─────────────────────────────────────────────────────────┤
│                    Core / Shared                        │
│  ┌─────────────┐  ┌──────────────┐  ┌───────────────┐  │
│  │   Supabase  │  │   Theme      │  │   Constants   │  │
│  │   Client    │  │   & Colors   │  │   & Routes    │  │
│  └─────────────┘  └──────────────┘  └───────────────┘  │
└─────────────────────────────────────────────────────────┘
```

### Prinsip Arsitektur
- **Separation of Concerns**: Setiap layer memiliki tanggung jawab yang terpisah
- **Dependency Rule**: Dependensi mengarah ke dalam (presentation → data → core)
- **Feature-Based**: Folder dikelompokkan berdasarkan fitur, bukan tipe file
- **State Management**: Menggunakan Cubit (BLoC pattern) untuk state yang predictable

---

## 🛠️ Tech Stack

| Kategori | Teknologi | Versi |
|----------|-----------|-------|
| **Framework** | Flutter | 3.13+ |
| **Bahasa** | Dart | 3.13+ |
| **Backend** | Supabase | 2.3+ |
| **State Management** | flutter_bloc | 8.1+ |
| **Navigation** | go_router | 14.0+ |
| **Internationalization** | intl | 0.19+ |
| **QR Code** | qr_flutter | 4.1+ |
| **Identifier** | uuid | 4.3+ |
| **UI Shimmer** | shimmer | 3.0+ |
| **Deep Links** | url_launcher | 6.2+ |
| **Icons** | cupertino_icons | 1.0+ |

### Platform yang Didukung
- ✅ Android
- ✅ iOS
- ✅ Web
- ✅ Linux
- ✅ macOS
- ✅ Windows

---

## 📁 Struktur Project

### Root Project
```
laundry28/
├── .env.local                          # Supabase credentials (jangan commit)
├── analysis_options.yaml               # Konfigurasi linting & analysis
├── pubspec.yaml                        # Dependencies & metadata project
├── prompt.md                           # Catatan development
├── README.md                           # Dokumentasi project ini
│
├── android/                            # Konfigurasi Android native
├── ios/                                # Konfigurasi iOS native
├── web/                                # Konfigurasi Web native
├── linux/                              # Konfigurasi Linux desktop
├── macos/                              # Konfigurasi macOS desktop
├── windows/                            # Konfigurasi Windows desktop
├── assets/                             # Aset statis (gambar, dll)
│
└── database/                           # Database migrations
    └── migrations/
        ├── README.md                   # Panduan migrations
        ├── add_pin_to_staff.sql        # Migrasi: tambah kolom PIN ke staff
        ├── add_username_role_to_staff.sql  # Migrasi: tambah username & role
        ├── create_laundries_table.sql  # Migrasi: buat tabel laundries
        ├── fix_laundries_permissions.sql   # Migrasi: perbaiki RLS permissions
        └── insert_owner_pandi.sql      # Data awal: owner "Pandi"
```

### Source Code (`lib/`)
```
lib/
├── main.dart                           # Entry point aplikasi
│
├── core/                               # Core utilities & configuration
│   ├── config/
│   │   └── web_tracking_config.dart    # Konfigurasi tracking untuk web
│   ├── constants/
│   │   ├── app_colors.dart             # Warna aplikasi (core level)
│   │   └── app_routes.dart             # Routing & route guards
│   ├── storage/
│   │   └── json_storage_service.dart   # Service penyimpanan JSON lokal
│   ├── supabase/
│   │   ├── supabase_client.dart        # Inisialisasi & singleton Supabase
│   │   └── supabase_constants.dart     # Konstanta Supabase
│   ├── theme/
│   │   ├── app_colors.dart             # Palet warna tema (AppColors)
│   │   └── app_theme.dart              # Tema terang (Light Theme)
│   ├── utils/
│   │   ├── app_utils.dart              # Utility functions umum
│   │   ├── web_utils.dart              # Platform stub untuk web utils
│   │   ├── web_utils_stub.dart         # Stub untuk non-web platform
│   │   └── web_utils_web.dart          # Implementasi khusus web
│   └── widgets/
│       ├── empty_state_widget.dart     # Widget state kosong (empty state)
│       └── share_text_widget.dart      # Widget share text (dialog)
│
├── features/                           # Fitur-fitur aplikasi
│   ├── admin/                          # Fitur Admin (Owner & Staff)
│   │   ├── cubit/                      # State Management
│   │   │   ├── auth_cubit.dart         # Auth: login, logout, onboarding
│   │   │   ├── auth_state.dart
│   │   │   ├── dashboard_cubit.dart    # Fetch & update pesanan
│   │   │   ├── dashboard_state.dart
│   │   │   ├── laundry_cubit.dart      # Setup & fetch data laundry
│   │   │   ├── laundry_state.dart
│   │   │   ├── new_order_cubit.dart    # Buat pesanan baru
│   │   │   ├── new_order_state.dart
│   │   │   ├── service_cubit.dart      # CRUD layanan
│   │   │   ├── service_state.dart
│   │   │   ├── staff/
│   │   │   │   ├── staff_cubit.dart    # CRUD karyawan
│   │   │   │   └── staff_state.dart
│   │   │   └── reports/
│   │   │       ├── report_cubit.dart   # Laporan harian & keuangan
│   │   │       └── report_state.dart
│   │   ├── data/
│   │   │   ├── models/
│   │   │   │   ├── laundry_model.dart  # Model data laundry
│   │   │   │   ├── service_model.dart  # Model data layanan
│   │   │   │   └── staff_model.dart    # Model data karyawan
│   │   │   └── repositories/
│   │   │       ├── auth_repository.dart
│   │   │       ├── laundry_repository.dart
│   │   │       ├── order_repository.dart
│   │   │       ├── report_repository.dart
│   │   │       ├── service_repository.dart
│   │   │       └── staff_repository.dart
│   │   └── presentation/
│   │       ├── screens/
│   │       │   ├── dashboard_screen.dart
│   │       │   ├── employee_dashboard_screen.dart
│   │       │   ├── employee_login_screen.dart
│   │       │   ├── login_mode.dart
│   │       │   ├── login_screen.dart
│   │       │   ├── new_order_screen.dart
│   │       │   ├── oauth_callback_screen.dart
│   │       │   ├── onboarding_laundry_screen.dart
│   │       │   ├── owner_dashboard_screen.dart
│   │       │   ├── service_management_screen.dart
│   │       │   ├── setup_laundry_screen.dart
│   │       │   ├── staff_management_screen.dart
│   │       │   └── reports/
│   │       │       ├── daily_report_screen.dart
│   │       │       └── financial_report_screen.dart
│   │       └── widgets/
│   │           ├── order_card.dart
│   │           └── order_card_skeleton.dart
│   │
│   └── tracking/                       # Fitur Tracking Pelanggan
│       ├── cubit/
│       │   ├── tracking_cubit.dart     # Fetch order by tracking code
│       │   └── tracking_state.dart
│       ├── data/
│       │   ├── models/
│       │   └── repositories/
│       └── presentation/
│           ├── screens/
│           │   └── tracking_screen.dart
│           └── widgets/
│               ├── status_stepper.dart
│               └── status_stepper_skeleton.dart
│
└── shared/                             # Kode shared antar fitur
    ├── models/
    │   └── order_model.dart            # Model Order (shared)
    └── widgets/
        ├── custom_button.dart          # Tombol custom reusable
        └── custom_text_field.dart      # TextField custom reusable
```

---

## 🏁 Getting Started

### Prasyarat

Pastikan Anda telah menginstall:

- **Flutter SDK** ≥ 3.13.2
- **Dart SDK** ≥ 3.13.2
- **Supabase Account** (daftar di [supabase.com](https://supabase.com))
- **IDE**: VS Code atau Android Studio
- **Git** untuk version control

### Instalasi

1. **Clone repository**
   ```bash
   git clone <repository-url>
   cd laundry28
   ```

2. **Install dependencies**
   ```bash
   flutter pub get
   ```

3. **Setup environment**
   
   Buat file `.env.local` di root project:
   ```env
   SUPABASE_URL=https://your-project.supabase.co
   SUPABASE_ANON_KEY=your-anon-key-here
   ```
   
   > ⚠️ **PENTING**: File `.env.local` sudah ada di `.gitignore`. Jangan pernah commit file ini ke repository.

4. **Jalankan aplikasi**
   ```bash
   # Android
   flutter run -d android
   
   # Web
   flutter run -d chrome
   
   # Device lain
   flutter devices
   flutter run -d <device-id>
   ```

---

## 🔧 Environment Variables

Buat file `.env.local` di root project untuk menyimpan konfigurasi backend:

```env
# Supabase Configuration (WAJIB)
SUPABASE_URL=https://your-project.supabase.co
SUPABASE_ANON_KEY=your-anon-key-here

# Google OAuth (Opsional — jika menggunakan Google Sign-In)
GOOGLE_OAUTH_CLIENT_ID=your-google-client-id.apps.googleusercontent.com
```

> **PENTING:** Jangan commit file `.env.local` ke repository. File ini sudah ditambahkan ke `.gitignore`.

---

### ⚙️ Setup Google OAuth

Untuk mengaktifkan login Google, lakukan konfigurasi di **dua sisi**:

#### 1️⃣ Google Cloud Console

1. Buka [Google Cloud Console](https://console.cloud.google.com/)
2. Pilih project Google Cloud Anda (atau buat baru)
3. Pergi ke **APIs & Services** → **Credentials**
4. Klik **Create Credentials** → **OAuth 2.0 Client ID**
5. Pilih **Web Application**
6. Tambahkan **Authorized JavaScript origins**:
   - `https://your-project.supabase.co`
   - `http://localhost:5173` (jika development lokal)
7. Tambahkan **Authorized redirect URIs**:
   - `https://your-project.supabase.co/v1/callback`
   - `http://localhost:5173/v1/callback` (jika development lokal)
8. Copy **Client ID** dan paste ke `.env.local` sebagai `GOOGLE_OAUTH_CLIENT_ID`

#### 2️⃣ Supabase Dashboard

1. Buka [Supabase Dashboard](https://supabase.com/dashboard)
2. Pilih project Anda
3. Pergi ke **Authentication** → **Providers** → **Google**
4. Aktifkan Google OAuth
5. Paste **Client ID** dan **Client Secret** dari Google Cloud Console
6. Pergi ke **URL Configuration**
7. Atur:
   - **Site URL**: `https://your-project.supabase.co`
   - **Redirect URL**: `https://your-project.supabase.co/v1/callback`
   - **Deep Links**: `laundry28://oauth/callback` (untuk mobile)

> **Catatan untuk Mobile (Android/iOS):**
> - Deep link `laundry28://oauth/callback` digunakan agar setelah login Google, user kembali ke app
> - Pastikan sudah mendaftarkan custom scheme di Android (`app-link` / `intent-filter`) dan iOS (`URL schemes`)
> - Di Google Cloud Console, tambahkan `laundry28://oauth/callback` ke Authorized redirect URIs

## 🗄️ Database Setup

### Supabase Project

1. Buat project baru di [Supabase Dashboard](https://supabase.com/dashboard)
2. Salin **Project URL** dan **anon/public key** ke file `.env.local`

### Migration Files

Semua migration SQL ada di folder `supabase/migrations/`. Jalankan secara berurutan:

| No | File | Deskripsi |
|----|------|-----------|
| 1 | `create_laundries_table.sql` | Membuat tabel `laundries` |
| 2 | `add_username_role_to_staff.sql` | Tambah kolom `username` & `role` ke tabel `staff` |
| 3 | `add_pin_to_staff.sql` | Tambah kolom `pin` untuk login karyawan |
| 4 | `insert_owner_pandi.sql` | Insert data owner awal ("Pandi") |
| 5 | `fix_laundries_permissions.sql` | Perbaiki Row Level Security (RLS) policies |
| 6 | `20260915000000_hash_pins_and_rate_limiting.sql` | Hash PIN + rate limiting + relasi Supabase Auth |
| 7 | `20260915000001_seed_default_services.sql` | Seed default services untuk laundry baru |

### Cara Menjalankan Migration

1. Buka **SQL Editor** di Supabase Dashboard
2. Copy-paste isi file migration secara berurutan
3. Atau gunakan Supabase CLI:
   ```bash
   supabase db push
   ```

### Struktur Tabel Database

**Tabel `staff`**
| Kolom | Tipe | Keterangan |
|-------|------|------------|
| `id` | BIGSERIAL | Primary key |
| `full_name` | TEXT | Nama lengkap |
| `username` | TEXT | Username unik |
| `email` | TEXT | Email (unique) |
| `password` | TEXT | Hash password (Supabase) |
| `pin` | TEXT | PIN login (karyawan) |
| `role` | TEXT | `owner` atau `employee` |
| `laundry_id` | BIGINT | Foreign key ke `laundries` |
| `created_at` | TIMESTAMPTZ | Timestamp pembuatan |

**Tabel `laundries`**
| Kolom | Tipe | Keterangan |
|-------|------|------------|
| `id` | BIGSERIAL | Primary key |
| `name` | TEXT | Nama laundry |
| `address` | TEXT | Alamat laundry |
| `phone` | TEXT | Nomor telepon |
| `owner_id` | BIGINT | Foreign key ke `staff` |
| `created_at` | TIMESTAMPTZ | Timestamp pembuatan |

**Tabel `services`**
| Kolom | Tipe | Keterangan |
|-------|------|------------|
| `id` | BIGSERIAL | Primary key |
| `laundry_id` | BIGINT | Foreign key ke `laundries` |
| `name` | TEXT | Nama layanan |
| `price` | NUMERIC | Harga per kg |
| `duration_hours` | INTEGER | Estimasi durasi (jam) |
| `is_active` | BOOLEAN | Status aktif/nonaktif |
| `sort_order` | INTEGER | Urutan tampilan |

**Tabel `orders`**
| Kolom | Tipe | Keterangan |
|-------|------|------------|
| `id` | BIGSERIAL | Primary key |
| `tracking_code` | TEXT | Kode unik tracking |
| `customer_name` | TEXT | Nama pelanggan |
| `customer_phone` | TEXT | Telepon pelanggan |
| `service_type` | TEXT | Jenis layanan |
| `status` | TEXT | Status cucian |
| `weight` | NUMERIC | Berat (kg) |
| `total_price` | NUMERIC | Total harga |
| `estimated_time` | TIMESTAMPTZ | Estimasi selesai |
| `laundry_id` | BIGINT | Foreign key ke `laundries` |
| `created_at` | TIMESTAMPTZ | Timestamp pembuatan |

> **Note:** Kolom `laundry_id` hanya muncul sekali. Sebelumnya ada duplikasi di dokumentasi yang sudah diperbaiki.

---

## 🔄 State Management

Proyek ini menggunakan **Cubit** dari package `flutter_bloc`. Setiap Cubit memiliki state yang terdefinisi dengan jelas.

### AuthCubit
Mengelola state autentikasi user.

| State | Deskripsi |
|-------|-----------|
| `AuthInitial` | State awal, belum ada aksi |
| `AuthLoading` | Proses login/onboarding |
| `Authenticated` | Login berhasil, ada user & staff |
| `AuthUnauthenticated` | User belum login / logout |
| `AuthOnboardingLoading` | Proses setup laundry |
| `AuthOnboardingComplete` | Setup laundry berhasil |
| `AuthOnboardingError` | Gagal setup laundry |

### DashboardCubit
Mengelola daftar pesanan di dashboard.

| State | Deskripsi |
|-------|-----------|
| `DashboardInitial` | State awal |
| `DashboardLoading` | Sedang memuat pesanan |
| `DashboardLoaded` | Pesanan berhasil dimuat |
| `DashboardEmpty` | Tidak ada pesanan |
| `DashboardError` | Error memuat pesanan |

### LaundryCubit
Mengelola data laundry aktif.

| State | Deskripsi |
|-------|-----------|
| `LaundryInitial` | State awal |
| `LaundryLoading` | Sedang memuat/setting laundry |
| `LaundryLoaded` | Laundry berhasil dimuat |
| `LaundryUnconfigured` | Belum ada laundry yang di-setup |
| `LaundryError` | Error memuat laundry |

### NewOrderCubit
Membuat pesanan baru dengan kalkulasi harga otomatis.

| State | Deskripsi |
|-------|-----------|
| `NewOrderInitial` | State awal |
| `NewOrderLoading` | Proses simpan pesanan |
| `NewOrderSuccess` | Pesanan berhasil dibuat |
| `NewOrderError` | Gagal membuat pesanan |

### ServiceCubit
CRUD layanan laundry.

| State | Deskripsi |
|-------|-----------|
| `ServiceInitial` | State awal |
| `ServiceLoading` | Sedang memuat layanan |
| `ServiceLoaded` | Layanan berhasil dimuat |
| `ServiceError` | Error memuat layanan |

### StaffCubit
CRUD karyawan.

| State | Deskripsi |
|-------|-----------|
| `StaffState.initial()` | State awal |
| `StaffLoading` | Sedang memuat/kelola karyawan |
| `StaffLoaded` | Karyawan berhasil dimuat |
| `StaffError` | Error |
| `StaffActionSuccess` | Aksi CRUD berhasil |

### ReportCubit
Laporan harian & keuangan.

| State | Deskripsi |
|-------|-----------|
| `ReportInitial` | State awal |
| `ReportLoading` | Sedang memuat laporan |
| `ReportDailyLoaded` | Laporan harian berhasil dimuat |
| `ReportFinancialLoaded` | Laporan keuangan berhasil dimuat |
| `ReportError` | Error memuat laporan |

### TrackingCubit
Tracking pesanan pelanggan.

| State | Deskripsi |
|-------|-----------|
| `TrackingInitial` | State awal |
| `TrackingLoading` | Sedang mencari pesanan |
| `TrackingLoaded` | Pesanan ditemukan |
| `TrackingError` | Pesanan tidak ditemukan / error |

---

## 📖 Fitur Detail

### 🔐 Autentikasi

Sistem autentikasi mendukung 3 metode:

1. **Email + Password** — Login tradisional via Supabase Auth
2. **Google OAuth** — Login cepat menggunakan akun Google
3. **PIN** — Login khusus karyawan dengan PIN 4-6 digit

**Alur Login Owner:**
```
LoginScreen → AuthCubit.loginWithEmail() → Authenticated
                                            → Redirect ke /owner/dashboard
                                            → LaundryCubit.fetchActiveLaundry()
```

**Alur Login Karyawan:**
```
LoginScreen → LoginMode.pin → AuthCubit.loginWithPin()
                                           → Authenticated (role: employee)
                                           → Redirect ke /employee/dashboard
```

### 🏪 Onboarding Laundry

Owner baru wajib mengisi data laundry sebelum mengakses dashboard:

```
Authenticated (no laundry) → OnboardingLaundryScreen
                              → Isi: Nama Laundry, Alamat, Telepon
                              → AuthCubit.completeOnboarding()
                              → LaundryCubit.setupLaundry()
                              → Redirect ke /owner/dashboard
```

### 📊 Dashboard Owner

Menu lengkap yang tersedia:
- **Dashboard** — Daftar semua pesanan dengan filter status
- **Buat Pesanan Baru** — Form input pesanan pelanggan
- **Layanan** — Kelola jenis layanan laundry
- **Karyawan** — Kelola data karyawan
- **Laporan Harian** — Statistik operasional harian
- **Laporan Keuangan** — Pendapatan & breakdown per layanan
- **Logout** — Keluar dari aplikasi

### 📋 Dashboard Karyawan

Fitur terbatas untuk karyawan:
- **Daftar Pesanan** — Melihat & mengupdate status cucian
- **Update Status** — Ubah status cucian via dropdown
- **Logout** — Keluar dari aplikasi

### 🛒 Buat Pesanan

Form pembuatan pesanan dengan fitur:
- Input nama & telepon pelanggan
- Pilih jenis layanan (dari daftar yang sudah di-setup)
- Input berat cucian (kg)
- Estimasi waktu selesai (opsional)
- **Tracking code otomatis** (UUID)
- **Kalkulasi harga otomatis** berdasarkan layanan × berat

**Default Harga Layanan:**
| Layanan | Harga/kg |
|---------|----------|
| Cuci Komplit | Rp 7.000 |
| Cuci + Setrika | Rp 6.000 |
| Setrika Saja | Rp 5.000 |
| Cuci Saja | Rp 4.000 |
| Cuci Bedcover | Rp 35.000 |
| Cuci Sepatu | Rp 50.000 |

### 📈 Laporan

**Laporan Harian (Operasional):**
- Total cucian masuk
- Cucian selesai vs masih proses
- Pendapatan hari ini
- Breakdown per status cucian
- 5 cucian terbaru
- Bisa di-share sebagai text

**Laporan Keuangan:**
- Total pendapatan periode
- Total cucian selesai
- Rata-rata pendapatan per cucian
- Breakdown pendapatan per layanan (dengan progress bar)
- Periode: Hari Ini / Minggu Ini / Bulan Ini / Custom

### 🔍 Tracking Pelanggan

Halaman publik yang bisa diakses tanpa login:
- Input kode tracking
- Tampilkan status pesanan dengan **visual stepper**
- Progress step: Diterima → Dicuci → Dikeringkan → Disetrika → Siap Diambil → Selesai
- Bisa diakses via URL: `https://app.laundry28.com/tracking?code=xxx`

---

## 📱 Screens

### Authentication Screens

| Screen | Route | Deskripsi |
|--------|-------|-----------|
| `LoginScreen` | `/login` | Halaman login utama (email/PIN/OAuth) |
| `EmployeeLoginScreen` | — | Login khusus karyawan (PIN only) |
| `OAuthCallbackScreen` | — | Handle redirect dari OAuth provider |
| `OnboardingLaundryScreen` | `/setup-laundry` | Setup laundry pertama kali untuk owner baru |

### Dashboard Screens

| Screen | Route | Deskripsi |
|--------|-------|-----------|
| `OwnerDashboardScreen` | `/owner/dashboard` | Dashboard lengkap untuk owner |
| `EmployeeDashboardScreen` | `/employee/dashboard` | Dashboard untuk karyawan |
| `DashboardScreen` | `/dashboard` | Dashboard umum (redirect ke role-specific) |

### Management Screens

| Screen | Route | Deskripsi |
|--------|-------|-----------|
| `NewOrderScreen` | `/new-order` | Form buat pesanan baru |
| `ServiceManagementScreen` | — | CRUD layanan laundry |
| `StaffManagementScreen` | — | CRUD karyawan |

### Report Screens

| Screen | Route | Deskripsi |
|--------|-------|-----------|
| `DailyReportScreen` | — | Laporan operasional harian |
| `FinancialReportScreen` | — | Laporan keuangan (pendapatan) |

### Tracking Screens

| Screen | Route | Deskripsi |
|--------|-------|-----------|
| `TrackingScreen` | `/tracking` | Halaman tracking pesanan (public) |

---

## 📦 Data Models

### OrderModel (Shared)
Digunakan oleh semua fitur (admin & tracking).

```dart
class OrderModel {
  final String id;
  final String trackingCode;
  final String customerName;
  final String customerPhone;
  final String serviceType;
  final String status;
  final double weight;
  final double totalPrice;
  final DateTime? estimatedTime;
  final int? laundryId;
  final DateTime createdAt;
}
```

### LaundryModel
Data laundry yang di-setup owner.

```dart
class LaundryModel {
  final int id;
  final String name;
  final String? address;
  final String? phone;
  final int ownerId;
  final DateTime createdAt;
}
```

### ServiceModel
Jenis layanan laundry.

```dart
class ServiceModel {
  final int id;
  final int laundryId;
  final String name;
  final double price;
  final int durationHours;
  final bool isActive;
  final int sortOrder;
}
```

### StaffModel
Data karyawan/owner.

```dart
class StaffModel {
  final int id;
  final String fullName;
  final String username;
  final String email;
  final String? pin;            // PIN plaintext (hanya untuk display, tidak disimpan di DB)
  final String? pinHash;        // Hashed PIN (SHA-256 + salt, disimpan di DB)
  final String? pinSalt;        // Salt untuk PIN hash
  final String role;            // 'owner' atau 'employee'
  final int? laundryId;
  final int? failedPinAttempts; // Counter untuk rate limiting
  final DateTime? lockedUntil;  // Waktu unlock jika terkunci
  final DateTime createdAt;
}
```

> **Keamanan PIN:** PIN tidak disimpan dalam bentuk plaintext. Setiap PIN di-hash menggunakan SHA-256 dengan salt unik. Setelah 5x percobaan gagal, akun otomatis terkunci selama 5 menit.

---

## 📊 Database Schema

Berikut adalah struktur lengkap tabel database:

```
┌──────────────┐       ┌──────────────────┐       ┌──────────────┐
│   staff      │       │     orders       │       │   services   │
├──────────────┤       ├──────────────────┤       ├──────────────┤
│ id (PK)      │       │ id (PK)          │       │ id (PK)      │
│ email        │       │ tracking_code    │       │ laundry_id(FK)│
│ username     │       │ customer_name    │       │ name         │
│ pin_hash     │       │ customer_phone   │       │ price        │
│ pin_salt     │       │ service_type     │       │ duration_hrs │
│ full_name    │       │ status           │       │ is_active    │
│ role         │       │ weight           │       │ sort_order   │
│ laundry_id(FK)│      │ total_price      │       │ laundry_id   │
│ failed_att   │       │ est_time         │       └──────────────┘
│ locked_until │       │ laundry_id(FK)   │
│ created_at   │       │ created_at       │
└──────────────┘       └──────────────────┘
```

---

## 🔗 Entity Relationship Diagram

```
┌──────────────┐     1:N     ┌──────────────┐
│   laundries  │────────────▶│    staff     │
├──────────────┤             ├──────────────┤
│ id (PK)      │             │ id (PK)      │
│ name         │             │ email        │
│ address      │             │ username     │
│ phone        │             │ pin_hash     │
│ owner_id(FK) │             │ role         │
│ created_at   │             │ laundry_id   │
└──────────────┘             └──────┬───────┘
                                    │
                                    │ 1:N
                                    ▼
                            ┌──────────────┐
                            │    orders    │
                            ├──────────────┤
                            │ id (PK)      │
                            │ tracking_code│
                            │ customer_*   │
                            │ status       │
                            │ weight       │
                            │ total_price  │
                            │ laundry_id(FK)│
                            └──────────────┘
                                    │
                                    │ N:1
                                    ▼
                            ┌──────────────┐
                            │   services   │
                            ├──────────────┤
                            │ id (PK)      │
                            │ name         │
                            │ price        │
                            │ duration_hrs │
                            └──────────────┘
```

**Relasi:**
- `laundries` → `staff`: Satu laundry memiliki banyak staff (1:N)
- `laundries` → `orders`: Satu laundry memiliki banyak orders (1:N)
- `laundries` → `services`: Satu laundry memiliki banyak services (1:N)
- `staff` → `orders`: Satu staff bisa membuat banyak orders (1:N)

---

## 🔒 Security

### Proteksi Data

| Fitur | Deskripsi |
|-------|-----------|
| **PIN Hashing** | PIN karyawan di-hash menggunakan SHA-256 + salt, tidak disimpan plaintext |
| **Rate Limiting** | Akun terkunci otomatis setelah 5x percobaan PIN gagal (durasi: 5 menit) |
| **RLS Policies** | Row Level Security di Supabase memastikan multi-tenant isolation |
| **Supabase Auth** | Password owner di-hash menggunakan bcrypt via Supabase Auth |

### RLS Policies
Semua RLS policies didokumentasikan di [`supabase/README_RLS_POLICIES.md`](supabase/README_RLS_POLICIES.md).

### Best Practices
- Selalu gunakan `.env` untuk menyimpan credential
- Jangan pernah commit file `.env` ke repository
- Review RLS policies secara berkala
- Backup database sebelum menjalankan migration

---

## 🧪 Testing

### Menjalankan Test

```bash
# Jalankan semua test
flutter test

# Jalankan test dengan coverage
flutter test --coverage

# Jalankan test spesifik
flutter test test/features/admin/cubit/auth_cubit_test.dart
```

### Struktur Test

```
test/
├── core/
│   └── utils/
│       └── pin_hasher_test.dart        # Test PIN hashing
└── features/
    └── admin/
        └── cubit/
            ├── auth_cubit_test.dart     # Test auth cubit
            └── ...
    └── tracking/
        └── cubit/
            └── tracking_cubit_test.dart # Test tracking cubit
```

### CI/CD

Project ini menggunakan GitHub Actions untuk otomatisasi testing. Setiap PR akan menjalankan:
- `flutter analyze` — Cek linting
- `flutter test` — Jalankan test suite

Lihat file [`.github/workflows/ci.yml`](.github/workflows/ci.yml) untuk detail konfigurasi.

---

## 🤝 Kontribusi

Kontribusi sangat diterima! Berikut langkah untuk berkontribusi:

1. **Fork** repository ini
2. **Create branch** untuk fitur baru: `git checkout -b feature/nama-fitur`
3. **Commit** perubahan: `git commit -m 'feat: tambah fitur baru'`
4. **Push** ke branch: `git push origin feature/nama-fitur`
5. **Buka Pull Request**

### Panduan Coding
- Ikuti **Clean Architecture** yang sudah ada
- Gunakan **Cubit** untuk state management
- Tulis **naming conventions** yang konsisten (snake_case untuk file, camelCase untuk class)
- Tambahkan **komentar** pada kode yang kompleks
- Pastikan **tidak ada error linting** sebelum commit

### Checklist Sebelum PR
- [ ] `flutter analyze` — Tidak ada error/warning
- [ ] `flutter test` — Semua test passing
- [ ] Kode mengikuti struktur folder yang ada
- [ ] Tidak ada credential/database key yang di-commit
- [ ] Dokumentasi diperbarui jika perlu

---

## 📄 Lisensi

Proyek ini dilisensikan di bawah **MIT License**.

Lihat file [LICENSE](LICENSE) untuk detail lengkap.

---

## 📞 Kontak

Untuk pertanyaan atau dukungan:
- 📧 Email: [contact@laundry28.com](mailto:contact@laundry28.com)
- 🌐 Website: [laundry28.com](https://laundry28.com)

---

<div align="center">

**Dibuat dengan ❤️ menggunakan Flutter & Supabase**

</div>