import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:app_links/app_links.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'core/supabase/supabase_client.dart';
import 'core/theme/app_theme.dart';
import 'core/constants/app_routes.dart';
import 'features/admin/cubit/auth_cubit.dart';
import 'features/admin/cubit/dashboard_cubit.dart';
import 'features/admin/cubit/laundry_cubit.dart';
import 'features/admin/cubit/new_order_cubit.dart';
import 'features/tracking/cubit/tracking_cubit.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Initialize Supabase
  await SupabaseService.init();

  // Initialize locale data for Indonesian date formatting
  await initializeDateFormatting('id_ID', null);

  // Handle deep links for OAuth callback on mobile
  final appLinks = AppLinks();

  // Handle deep link if app is opened from cold start (not running)
  try {
    final initialLink = await appLinks.getInitialLink();
    if (initialLink != null) {
      AppRoutes.deeplinkUri = initialLink;
      if (kDebugMode) {
        print('🔗 [DEEP_LINK] Initial link: $initialLink');
      }
      if (initialLink.path == '/oauth/callback') {
        // Navigate to OAuth callback screen via GoRouter
        AppRoutes.router.push(AppRoutes.oauthCallback);
      }
    }
  } catch (e) {
    if (kDebugMode) {
      print('⚠️ [DEEP_LINK] Failed to get initial link: $e');
    }
  }

  // Listen for deep links when app is in warm start (running in background)
  appLinks.uriLinkStream.listen((Uri? uri) {
    if (uri != null) {
      AppRoutes.deeplinkUri = uri;
      if (kDebugMode) {
        print('🔗 [DEEP_LINK] Incoming link: $uri');
      }
      if (uri.path == '/oauth/callback') {
        // Navigate to OAuth callback screen via GoRouter
        AppRoutes.router.push(AppRoutes.oauthCallback);
      }
    }
  }).onError((error) {
    if (kDebugMode) {
      print('⚠️ [DEEP_LINK] Stream error: $error');
    }
  });

  runApp(
    MultiBlocProvider(
      providers: [
        BlocProvider(create: (_) => AuthCubit()),
        BlocProvider(create: (_) => LaundryCubit()),
        BlocProvider(create: (_) => DashboardCubit()), // Orders fetched lazily on dashboard screen load (after auth)
        BlocProvider(create: (_) => NewOrderCubit()),
        BlocProvider(create: (_) => TrackingCubit()),
      ],
      child: BlocListener<AuthCubit, AuthState>(
        listener: (context, state) {
          if (state is Authenticated) {
            AuthRoleProvider.setCurrentUserRole(state.staff.role);
            if (kDebugMode) {
              print('🔄 [ROUTE] User role updated: ${state.staff.role} (${state.staff.fullName})');
            }
            // Fetch laundry data for this owner
            final userId = SupabaseService.client.auth.currentUser?.id;
            if (userId != null) {
              context.read<LaundryCubit>().fetchActiveLaundry(userId);
              if (kDebugMode) {
                print('📦 [LAUNDRY] Fetch initiated for owner: $userId');
              }
            }
          } else if (state is AuthUnauthenticated || state is AuthInitial) {
            AuthRoleProvider.setCurrentUserRole(null);
            if (kDebugMode) {
              print('🔄 [ROUTE] User role cleared');
            }
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
