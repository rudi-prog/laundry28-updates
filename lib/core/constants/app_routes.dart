import 'package:flutter/foundation.dart';
import 'package:go_router/go_router.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../features/admin/presentation/screens/login_screen.dart';
import '../../features/admin/presentation/screens/owner_dashboard_screen.dart';
import '../../features/admin/presentation/screens/employee_dashboard_screen.dart';
import '../../features/admin/presentation/screens/setup_laundry_screen.dart';
import '../../features/admin/presentation/screens/new_order_screen.dart';
import '../../features/tracking/presentation/screens/tracking_screen.dart';
import '../../features/admin/cubit/auth_cubit.dart';

/// ChangeNotifier yang sync ke AuthCubit untuk trigger GoRouter redirect
class AuthRoleProvider extends ChangeNotifier {
  String? _role;
  String? get role => _role;

  static void setCurrentUserRole(String? role) {
    authRoleProvider._role = role;
    authRoleProvider.notifyListeners();
  }

  void updateFromAuthCubit(AuthCubit cubit) {
    final state = cubit.state;
    if (state is Authenticated) {
      if (_role != state.staff.role) {
        _role = state.staff.role;
        notifyListeners();
      }
    } else if (state is AuthUnauthenticated || state is AuthInitial) {
      if (_role != null) {
        _role = null;
        notifyListeners();
      }
    }
  }
}

/// Global instance untuk refreshListenable
final AuthRoleProvider authRoleProvider = AuthRoleProvider();

/// Route guard: cek apakah user sudah login via Supabase session atau AuthRoleProvider
bool _isAuthenticated() {
  try {
    final session = Supabase.instance.client.auth.currentSession;
    if (session != null) return true;
  } catch (_) {}
  // Juga cek AuthRoleProvider untuk login PIN (yang tidak membuat Supabase session)
  if (authRoleProvider.role != null) return true;
  return false;
}

/// Get current user's role from staff table
Future<String?> _getUserRole() async {
  try {
    final user = Supabase.instance.client.auth.currentUser;
    if (user == null) return null;
    final response = await Supabase.instance.client
        .from('staff')
        .select('role')
        .eq('email', user.email ?? '')
        .limit(1);
    if (response.isNotEmpty) {
      final role = response.first['role'] as String?;
      print('🔍 [ROUTE] Fetched role from DB: $role for ${user.email}');
      return role;
    }
    print('⚠️ [ROUTE] No staff record for ${user.email}, defaulting to owner');
    return 'owner';
  } catch (e) {
    print('Error fetching user role: $e');
    return 'owner';
  }
}

/// Get the appropriate dashboard route based on user role
String? _getDashboardRoute() {
  // Prioritas: gunakan role dari AuthRoleProvider (sync dari AuthCubit)
  final role = authRoleProvider.role;
  
  if (role != null) {
    print('🔍 [ROUTE] Role dari AuthProvider: $role');
    if (role == 'owner') {
      return AppRoutes.ownerDashboard;
    }
    return AppRoutes.employeeDashboard;
  }
  
  // Role belum di-set → return null (no redirect), biarkan user stay di halaman saat ini
  print('⚠️ [ROUTE] Role belum di-set, tidak redirect');
  return null;
}

class AppRoutes {
  static const String login = '/login';
  static const String dashboard = '/dashboard';
  static const String ownerDashboard = '/owner/dashboard';
  static const String employeeDashboard = '/employee/dashboard';
  static const String tracking = '/tracking';
  static const String newOrder = '/new-order';
  static const String setupLaundry = '/setup-laundry';

  static final GoRouter router = GoRouter(
    initialLocation: login,
    refreshListenable: authRoleProvider,
    redirect: (context, state) async {
      final isAuthenticated = _isAuthenticated();
      final isLoginRoute = state.matchedLocation == login;
      final isTrackingRoute = state.matchedLocation.startsWith(tracking);

      // Tracking page bisa diakses tanpa login (public route)
      if (isTrackingRoute) return null;

      // Jika belum login dan bukan di halaman login → redirect ke login
      if (!isAuthenticated && !isLoginRoute) {
        return login;
      }

      // Jika sudah login dan masih di halaman login → redirect ke dashboard sesuai role
      if (isAuthenticated && isLoginRoute) {
        final route = await _getDashboardRoute();
        if (route != null) {
          print('🔀 [REDIRECT] Authenticated, redirecting to: $route');
          return route;
        }
        print('⚠️ [REDIRECT] Role belum di-set, tetap di login');
        return null;
      }

      // Jika akses ke /dashboard (general route), redirect ke role-specific dashboard
      if (isAuthenticated && state.matchedLocation == dashboard) {
        final route = await _getDashboardRoute();
        if (route != null) {
          print('🔀 [REDIRECT] General dashboard, redirecting to: $route');
          return route;
        }
        print('⚠️ [REDIRECT] Role belum di-set, tetap di dashboard umum');
        return null;
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
        name: 'owner-dashboard',
        path: ownerDashboard,
        builder: (context, state) => const OwnerDashboardScreen(),
      ),
      GoRoute(
        name: 'employee-dashboard',
        path: employeeDashboard,
        builder: (context, state) => const EmployeeDashboardScreen(),
      ),
      GoRoute(
        name: 'new-order',
        path: newOrder,
        builder: (context, state) => const NewOrderScreen(),
      ),
      GoRoute(
        name: 'setup-laundry',
        path: '/setup-laundry',
        builder: (context, state) => const SetupLaundryScreen(),
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
