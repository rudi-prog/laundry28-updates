# 🧺 Laundry28

A modern laundry management system built with **Flutter Web** and **Supabase**. 
It allows staff to manage orders via an admin dashboard, while customers can track their order status in real-time using a simple WhatsApp link—no app installation required.

## ✨ Key Features
- 👨‍💻 **Admin Dashboard:** Manage orders, update statuses (Washing → Ironing → Ready), and handle customer data.
- 📱 **Customer Tracking:** Real-time status updates via web links sent through WhatsApp.
- 🔐 **Secure Auth:** Staff login powered by Supabase Authentication.
- ⚡ **Real-time Sync:** Instant updates using Supabase Realtime subscriptions.

## 🛠️ Tech Stack
- **Frontend:** Flutter (Web & Mobile)
- **Backend/Database:** Supabase (PostgreSQL, Auth, Realtime)
- **State Management:** BLoC / Cubit
- **Routing:** go_router

## 🚀 Getting Started
1. Clone the repository: `git clone https://github.com/[your-username]/laundry28.git`
2. Install dependencies: `flutter pub get`
3. Configure Supabase credentials in `lib/core/supabase/`.
4. Run the app: `flutter run -d chrome` (for web) or connect your mobile device.

## 📖 Documentation
For detailed technical documentation, database schema, and project history, please refer to **[PROJECT_CONTEXT.md](./PROJECT_CONTEXT.md)**.
