import 'package:go_router/go_router.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../features/admin/presentation/screens/login_screen.dart';
import '../../features/admin/presentation/screens/dashboard_screen.dart';
import '../../features/admin/presentation/screens/new_order_screen.dart';
import '../../features/tracking/presentation/screens/tracking_screen.dart';

/// Route guard: cek apakah user sudah login via Supabase session
bool _isAuthenticated() {
  try {
    final session = Supabase.instance.client.auth.currentSession;
    return session != null;
  } catch (_) {
    return false;
  }
}

class AppRoutes {
  static const String login = '/login';
  static const String dashboard = '/dashboard';
  static const String tracking = '/tracking';
  static const String newOrder = '/new-order';

  static final GoRouter router = GoRouter(
    initialLocation: login,
    redirect: (context, state) {
      final isAuthenticated = _isAuthenticated();
      final isLoginRoute = state.matchedLocation == login;
      final isTrackingRoute = state.matchedLocation.startsWith(tracking);

      // Tracking page bisa diakses tanpa login (public route)
      if (isTrackingRoute) return null;

      // Jika belum login dan bukan di halaman login → redirect ke login
      if (!isAuthenticated && !isLoginRoute) {
        return login;
      }

      // Jika sudah login dan masih di halaman login → redirect ke dashboard
      if (isAuthenticated && isLoginRoute) {
        return dashboard;
      }

      return null;
    },
    routes: [
      GoRoute(
        name: 'login',
        path: login,
        builder: (context, state) => const LoginScreen(),
      ),
      GoRoute(
        name: 'dashboard',
        path: dashboard,
        builder: (context, state) => const DashboardScreen(),
      ),
      GoRoute(
        name: 'new-order',
        path: newOrder,
        builder: (context, state) => const NewOrderScreen(),
      ),
      GoRoute(
        name: 'tracking',
        path: tracking,
        builder: (context, state) {
          final trackingCode = state.uri.queryParameters['code'] ?? '';
          return TrackingScreen(trackingCode: trackingCode);
        },
      ),
    ],
  );
}
