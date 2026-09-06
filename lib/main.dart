import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'core/supabase/supabase_client.dart';
import 'core/theme/app_theme.dart';
import 'core/constants/app_routes.dart';
import 'features/admin/cubit/auth_cubit.dart';
import 'features/admin/cubit/dashboard_cubit.dart';
import 'features/admin/cubit/new_order_cubit.dart';
import 'features/tracking/cubit/tracking_cubit.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Initialize Supabase
  await SupabaseService.init();

  // Initialize locale data for Indonesian date formatting
  await initializeDateFormatting('id_ID', null);

  runApp(
    MultiBlocProvider(
      providers: [
        BlocProvider(create: (_) => AuthCubit()),
        BlocProvider(create: (_) => DashboardCubit()), // Orders fetched lazily on dashboard screen load (after auth)
        BlocProvider(create: (_) => NewOrderCubit()),
        BlocProvider(create: (_) => TrackingCubit()),
      ],
      child: BlocListener<AuthCubit, AuthState>(
        listener: (context, state) {
          // Update global role saat auth state berubah
          if (state is Authenticated) {
            AuthRoleProvider.setCurrentUserRole(state.staff.role);
            print('🔄 [ROUTE] User role updated: ${state.staff.role} (${state.staff.fullName})');
          } else if (state is AuthUnauthenticated || state is AuthInitial) {
            AuthRoleProvider.setCurrentUserRole(null);
            print('🔄 [ROUTE] User role cleared');
          }
        },
        child: MaterialApp.router(
          title: 'Laundry28',
          theme: AppTheme.lightTheme,
          routerConfig: AppRoutes.router,
          debugShowCheckedModeBanner: false,
        ),
      ),
    ),
  );
}
