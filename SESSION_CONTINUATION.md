# Laundry28 - Session Continuation Document

> **Generated:** 9 September 2026
> **Session Focus:** Feature #3 (Skeleton Loaders, Empty States, Pull-to-Refresh) + Preparation for Feature #4 (Loading Overlay Pattern)
> **Status:** Feature #3 COMPLETE | Feature #4 PARTIALLY COMPLETE

---

## Executive Summary

This document captures the complete state of the Laundry28 Flutter application after implementing UX enhancements (Feature #3: skeleton loaders, empty states, pull-to-refresh) and beginning work on loading overlay patterns (Feature #4). All changes follow Clean Architecture + Cubit state management with Supabase realtime sync.

---

## 1. Completed Changes (Session Summary)

### 1.1 New Files Created

| File | Purpose |
|------|---------|
| lib/core/widgets/empty_state_widget.dart | Reusable empty state widget for all screens |
| lib/features/admin/cubit/dashboard_state.dart | Dashboard Cubit states with pagination support |
| lib/features/admin/presentation/widgets/order_card_skeleton.dart | Skeleton loader for OrderCard component |
| lib/features/tracking/presentation/widgets/status_stepper_skeleton.dart | Skeleton loader for StatusStepper component |

### 1.2 Modified Files

| File | Changes Made |
|------|-------------|
| pubspec.yaml | Added shimmer: ^3.0.0 dependency |
| lib/features/admin/presentation/screens/dashboard_screen.dart | Integrated skeleton loaders, empty states, pull-to-refresh; refactored to use new DashboardState with pagination |
| lib/features/admin/cubit/dashboard_cubit.dart | Updated to extend BaseCubit; added pagination support (page, hasMore); changed state from DashboardInitial to DashboardLoading for initial load |
| lib/features/tracking/presentation/screens/tracking_screen.dart | Added pull-to-refresh via RefreshIndicator; skeleton loader already present |
| lib/features/admin/presentation/screens/new_order_screen.dart | Added loading overlay with CircularProgressIndicator during order creation |

---

## 2. Architecture State

### 2.1 Clean Architecture Layers

```
laundry28/
├── lib/
│   ├── core/                          # Core infrastructure
│   │   ├── constants/                 # AppRoutes, theme colors
│   │   ├── storage/                   # JSON storage service
│   │   └── widgets/                   # EmptyStateWidget (NEW)
│   │
│   ├── features/
│   │   ├── admin/                     # Admin module
│   │   │   ├── data/
│   │   │   │   ├── models/            # OrderModel, CustomerModel
│   │   │   │   └── repositories/      # AuthRepository (JSON-based)
│   │   │   ├── presentation/
│   │   │   │   ├── screens/           # Dashboard, Login, NewOrder
│   │   │   │   └── widgets/           # OrderCard, OrderCardSkeleton (NEW)
│   │   │   └── cubit/                 # AuthCubit, DashboardCubit, NewOrderCubit
│   │   │       ├── dashboard_state.dart  (NEW - replaces inline state)
│   │   │       └── dashboard_cubit.dart    (Updated: pagination support)
│   │   │
│   │   └── tracking/                  # Tracking module
│   │       ├── cubit/                 # TrackingCubit
│   │       └── presentation/
│   │           ├── screens/           # TrackingScreen
│   │           └── widgets/           # StatusStepper, StatusStepperSkeleton (NEW)
│   │
│   └── shared/                        # Shared across features
│       ├── models/                    # OrderModel (shared definition)
│       ├── widgets/                   # CustomButton, CustomTextField
│       └── services/                  # Supabase service
```

### 2.2 State Management Pattern

All screens use `flutter_bloc` with the following state lifecycle:

```
Initial -> Loading -> Loaded / Error -> (Pagination) -> MoreLoaded / MoreError
```

**Key Cubits:**
- **AuthCubit**: AuthInitial -> AuthLoading -> AuthAuthenticated -> AuthUnauthenticated -> AuthError
- **DashboardCubit**: DashboardLoading -> DashboardLoaded(pagination) -> DashboardError
- **NewOrderCubit**: NewOrderInitial -> NewOrderLoading -> NewOrderSuccess -> NewOrderError
- **TrackingCubit**: TrackingInitial -> TrackingLoading -> TrackingLoaded -> TrackingError

### 2.3 Supabase Integration

- Realtime subscriptions enabled on orders table via `SupabaseService`
- Orders sync automatically across admin devices
- Customer data stored in local JSON (no Supabase customer table yet)

---

## 3. Dependency Inventory

### 3.1 Production Dependencies

| Package | Version | Purpose |
|---------|---------|---------|
| supabase_flutter | ^2.3.0 | Backend & realtime sync |
| flutter_bloc | ^8.1.3 | State management |
| go_router | ^14.0.0 | Navigation |
| intl | ^0.19.0 | Date/time formatting (Indonesian locale) |
| url_launcher | ^6.2.1 | WhatsApp integration |
| qr_flutter | ^4.1.0 | QR code generation for orders |
| uuid | ^4.3.3 | Unique ID generation |
| **shimmer** | **^3.0.0** | **Skeleton loading animations (NEW)** |

### 3.2 Dev Dependencies

| Package | Version | Purpose |
|---------|---------|---------|
| flutter_lints | ^6.0.0 | Code quality linting |

---

## 4. Feature #3 Implementation Details

### 4.1 Skeleton Loaders

**Pattern Used:** Shimmer effect with base/highlight colors matching app theme.

```dart
Shimmer.fromColors(
  baseColor: Colors.grey.shade300,
  highlightColor: Colors.grey.shade100,
  child: Container(
    width: double.infinity,
    height: 60,
    decoration: BoxDecoration(
      color: Colors.white,
      borderRadius: BorderRadius.circular(12),
    ),
  ),
)
```

**Locations:**
- `OrderCardSkeleton` -> Dashboard screen order list (replaces OrderCard during loading)
- `StatusStepperSkeleton` -> Tracking screen status progress (replaces StatusStepper during loading)
- Inline shimmer in dashboard stats grid (4 stat cards as skeleton rectangles)
- Inline shimmer in tracking screen detail rows

### 4.2 Empty States

**Pattern Used:** Centered icon + title + description, reusable via `EmptyStateWidget`.

```dart
EmptyStateWidget(
  icon: Icons.receipt_long_outlined,
  title: 'Belum Ada Pesanan',
  description: 'Pesanan laundry akan muncul di sini',
)
```

**Locations:**
- Dashboard screen: When no orders exist (after filtering or initially)
- Tracking screen: When tracking code is empty/invalid

### 4.3 Pull-to-Refresh

**Pattern Used:** Flutter's built-in `RefreshIndicator` widget.

```dart
RefreshIndicator(
  onRefresh: () async {
    context.read<DashboardCubit>().fetchOrders();
    await Future.delayed(const Duration(milliseconds: 600));
  },
  color: AppColors.primary,
  child: CustomScrollView(...),
)
```

**Locations:**
- Dashboard screen: Wraps the entire order list view (already present before this session)
- Tracking screen: Wraps the tracking details view (added in this session)

---

## 5. Feature #4 - Loading Overlay Pattern (In Progress)

### 5.1 Completed Work

**NewOrderScreen:** Added loading overlay during order creation.

```dart
// In new_order_screen.dart build method
return BlocListener<NewOrderCubit, NewOrderState>(
  listener: (context, state) {
    if (state is NewOrderLoading) {
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (ctx) => const Center(
          child: CircularProgressIndicator(color: AppColors.primary),
        ),
      );
    } else if (state is NewOrderSuccess || state is NewOrderError) {
      Navigator.of(ctx).pop(); // Close dialog
    }
  },
  child: BlocBuilder<NewOrderCubit, NewOrderState>(...),
);
```

### 5.2 Remaining Work for Feature #4

The following screens still need loading overlay patterns:

| Screen | Current State | Action Needed |
|--------|--------------|---------------|
| DashboardScreen | Uses shimmer skeletons during loading | Consider adding a full-screen loading overlay for initial load (when orders.isEmpty AND isLoading) |
| TrackingScreen | Uses skeleton loader during loading | Already has good UX with skeleton; no change needed unless full-overlay is preferred |
| LoginScreen | Uses _showLoadingDialog() | Already implemented ✅ |

### 5.3 Recommended Loading Overlay Pattern

For consistency across the app, create a reusable `LoadingOverlay` widget:

```dart
// lib/core/widgets/loading_overlay.dart (NEW - to be created)
class LoadingOverlay extends StatelessWidget {
  const LoadingOverlay({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      color: Colors.black.withValues(alpha: 0.3),
      child: const Center(
        child: CircularProgressIndicator(),
      ),
    );
  }
}
```

Usage in any screen:
```dart
BlocListener<SomeCubit, SomeState>(
  listener: (context, state) {
    if (state is SomeLoading) {
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (_) => const LoadingOverlay(),
      );
    } else if (state is SomeLoaded || state is SomeError) {
      Navigator.of(context).pop();
    }
  },
  child: BlocBuilder<...>(...),
)
```

---

## 6. Known Issues & Technical Debt

### 6.1 Lint Warnings (40 info-level, no errors)

| Category | Count | Files Affected |
|----------|-------|----------------|
| avoid_print | ~25 | auth_cubit.dart, auth_repository.dart |
| unnecessary_brace_in_string_interps | 2 | auth_cubit.dart |
| curly_braces_in_flow_control_structures | 4 | auth_cubit.dart |
| overridden_fields / annotate_overrides | 2 | dashboard_state.dart |
| prefer_interpolation_to_compose_strings | 2 | order_card.dart |
| use_build_context_synchronously | 1 | order_card.dart |
| deprecated_member_use | 1 | order_card.dart (value -> initialValue) |

### 6.2 Architectural Notes

1. **DashboardState moved to separate file** (`dashboard_state.dart`) - This was done to support pagination fields (`page`, `hasMore`). The previous inline state class in the cubit had a redundant `orders` field that shadowed the inherited one.

2. **Initial load state changed**: DashboardCubit now uses `DashboardLoading` (not `DashboardInitial`) for initial fetch, so skeleton loaders display immediately instead of an empty screen.

3. **No pull_to_refresh package needed**: Flutter built-in RefreshIndicator is sufficient and avoids adding a third-party dependency.

4. **Customer data not in Supabase**: Customer information (name, phone) is stored locally via JSON storage service. A customer table in Supabase should be created for multi-device sync.

---

## 7. Next Steps for Tomorrow's Session

### Priority 1: Complete Feature #4 (Loading Overlay Pattern)

**Step-by-step instructions:**

1. Create `lib/core/widgets/loading_overlay.dart`:
   ```dart
   import 'package:flutter/material.dart';
   
   class LoadingOverlay extends StatelessWidget {
     const LoadingOverlay({super.key});
     @override
     Widget build(BuildContext context) => Container(
       color: Colors.black.withValues(alpha: 0.3),
       child: const Center(child: CircularProgressIndicator()),
     );
   }
   ```

2. Update `DashboardScreen` to show full-screen loading overlay when initial load is in progress:
   - In the build method, wrap with BlocListener<DashboardCubit>
   - Check for DashboardLoading state -> show LoadingOverlay dialog
   - On DashboardLoaded/DashboardError -> close dialog

3. Verify TrackingScreen skeleton UX is acceptable (likely no changes needed)

### Priority 2: Fix Lint Warnings

**Quick fixes (low effort, high impact):**

1. Replace all `print()` calls with proper logging or remove them:
   ```bash
   # In auth_cubit.dart and auth_repository.dart
   sed -i 's/print(/\/\//g' lib/features/admin/cubit/auth_cubit.dart
   sed -i 's/print(/\/\//g' lib/features/admin/data/repositories/auth_repository.dart
   ```

2. Fix deprecated `value` -> `initialValue` in order_card.dart:
   ```dart
   // Find: value: customerName,
   // Replace with: initialValue: customerName,
   ```

3. Fix curly braces in flow control (auth_cubit.dart):
   ```dart
   // Add braces to if/else blocks without them
   ```

### Priority 3: Supabase Customer Table

**To enable multi-device customer sync:**

1. Create `customers` table in Supabase:
   - id (uuid, primary key)
   - name (text)
   - phone (text, unique)
   - created_at (timestamptz)
   - updated_at (timestamptz)

2. Update CustomerModel to include Supabase fields

3. Replace JSON storage with Supabase queries in customer-related code

### Priority 4: Additional UX Polish

- Add error retry buttons on error states
- Implement pull-to-refresh on all list screens consistently
- Add toast/snackbar for user feedback (order created, status updated)
- Implement dark mode support

---

## 8. Quick Reference for Next Session

### Commands to Run

```bash
# Get dependencies after any pubspec changes
cd /home/star28tech/projects/laundry28
flutter pub get

# Check lint warnings
flutter analyze

# Run the app on connected device/emulator
flutter run
```

### Key File Locations

| What | Path |
|------|------|
| Dashboard Cubit | lib/features/admin/cubit/dashboard_cubit.dart |
| Dashboard State | lib/features/admin/cubit/dashboard_state.dart |
| Dashboard Screen | lib/features/admin/presentation/screens/dashboard_screen.dart |
| Order Card Widget | lib/features/admin/presentation/widgets/order_card.dart |
| Order Card Skeleton | lib/features/admin/presentation/widgets/order_card_skeleton.dart |
| Tracking Screen | lib/features/tracking/presentation/screens/tracking_screen.dart |
| Status Stepper | lib/features/tracking/presentation/widgets/status_stepper.dart |
| Status Stepper Skeleton | lib/features/tracking/presentation/widgets/status_stepper_skeleton.dart |
| Empty State Widget | lib/core/widgets/empty_state_widget.dart |
| App Theme | lib/core/constants/app_theme.dart |
| App Colors | lib/core/constants/app_colors.dart |
| Supabase Service | lib/shared/services/supabase_service.dart |

### Key Imports for New Code

```dart
// Shimmer skeleton loaders
import 'package:shimmer/shimmer.dart';

// State management
import 'package:flutter_bloc/flutter_bloc.dart';

// Navigation
import 'package:go_router/go_router.dart';

// App constants (use these, not hardcoded values)
import '../../../../../../core/constants/app_colors.dart';
```

### Naming Conventions

- **Cubits**: `*Cubit` suffix (e.g., DashboardCubit)
- **States**: `*State` suffix with descriptive variants (e.g., DashboardLoading, DashboardLoaded)
- **Screens**: `*_screen.dart` lowercase with underscores
- **Widgets**: `*Widget` or descriptive name in `*_widget.dart`
- **Skeletons**: `*_skeleton.dart` matching the widget they replace
- **Models**: `*Model` suffix (e.g., OrderModel)

---

## 9. Session Metadata

| Field | Value |
|-------|-------|
| Session Date | September 4, 2026 |
| Platform | Linux |
| IDE | VS Code |
| Flutter Version | (check with `flutter --version`) |
| Working Directory | /home/star28tech/projects/laundry28 |
| Git Status | Changes not yet committed |

---

*Document generated for autonomous session handoff. All code changes described above have been applied to the working tree.*
