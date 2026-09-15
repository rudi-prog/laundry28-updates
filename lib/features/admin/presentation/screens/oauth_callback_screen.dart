import 'dart:async';

import 'package:app_links/app_links.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../../../../../core/supabase/supabase_client.dart';
import '../../../../../core/utils/web_utils.dart';
import '../../../../../core/constants/app_routes.dart';
import '../../cubit/auth_cubit.dart';

/// Simple OAuth callback screen.
///
/// Mobile: Setelah deep link dibuka (laundry28://oauth/callback?code=xxx),
/// supabase_flutter secara otomatis mendeteksi URL dan membuat session.
/// onAuthStateChange listener di AuthCubit akan mendeteksi session baru
/// dan emit Authenticated state → BlocListener di main.dart → GoRouter redirect ke dashboard.
///
/// Web: Setelah Google auth, Supabase redirect ke /callback?code=xxx.
/// Kita perlu mengekstrak code dari URL dan menukarnya jadi session.
///
/// Screen ini hanya menunjukkan loading sementara proses selesai.
class OAuthCallbackScreen extends StatefulWidget {
  const OAuthCallbackScreen({super.key});

  @override
  State<OAuthCallbackScreen> createState() => _OAuthCallbackScreenState();
}

class _OAuthCallbackScreenState extends State<OAuthCallbackScreen> {
  Timer? _timeoutTimer;
  bool _hasProcessed = false;
  bool _isNavigating = false;

  @override
  void initState() {
    super.initState();
    _startTimeout();
    _handleCallback();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    // Second attempt: check if deep link was stored by main.dart after dependencies loaded
    if (!_hasProcessed && AppRoutes.deeplinkUri != null) {
      if (kDebugMode) {
        print('🔄 [OAUTH_CALLBACK] didChangeDependencies - retrying with stored deep link');
      }
      _handleCallback();
    }
  }

  @override
  void dispose() {
    _timeoutTimer?.cancel();
    super.dispose();
  }

  /// Cancel timeout timer jika sudah berhasil login
  void _cancelTimeout() {
    _timeoutTimer?.cancel();
    _timeoutTimer = null;
    if (kDebugMode) {
      print('✅ [OAUTH_CALLBACK] Timeout cancelled — session ready');
    }
  }

  /// Cancel timeout dan redirect ke dashboard
  void _cancelTimeoutAndNavigate(String route) {
    _cancelTimeout();
    if (mounted && !_isNavigating) {
      _isNavigating = true;
      Future.microtask(() {
        if (mounted) {
          context.go(route);
        }
      });
    }
  }

  /// Start a timeout to prevent the loading screen from hanging indefinitely.
  /// If OAuth takes longer than 15 seconds, show a cancel dialog.
  void _startTimeout() {
    _timeoutTimer = Timer(const Duration(seconds: 15), () {
      if (mounted) {
        showDialog(
          context: context,
          barrierDismissible: false,
          builder: (ctx) => AlertDialog(
            title: const Text('⏱️ Timeout'),
            content: const Text(
              'Login memakan waktu terlalu lama. '
              'Apakah Anda membatalkan login atau koneksi tidak stabil?\n\n'
              'Kembali ke halaman login?',
            ),
            actions: [
              TextButton(
                onPressed: () {
                  if (context.mounted) {
                    context.go(AppRoutes.login);
                  }
                },
                child: const Text('Kembali ke Login'),
              ),
              TextButton(
                onPressed: () {
                  if (context.mounted) Navigator.of(context).pop();
                },
                child: const Text('Tetap Tunggu'),
              ),
            ],
          ),
        );
      }
    });
  }

  Future<void> _handleCallback() async {
    final uri = Uri.parse(await _getTopLevelUrl() ?? '');
    final code = uri.queryParameters['code'];
    final error = uri.queryParameters['error'];
    final errorDescription = uri.queryParameters['error_description'];

    // 🔴 CRITICAL CHECK: Jika URL localhost di mobile = ERROR KONFIGURASI
    if (!kIsWeb && uri.host.contains('localhost')) {
      if (kDebugMode) {
        print('🔴 [OAUTH] CRITICAL: localhost detected on mobile!');
        print('🔴 [OAUTH] This means Supabase Dashboard Site URL is misconfigured.');
        print('🔴 [OAUTH] Please update: Supabase Dashboard > Authentication > Settings > Site URL');
        print('🔴 [OAUTH] Change from "http://localhost:3000" to your production domain');
      }
      if (mounted) {
        showDialog(
          context: context,
          barrierDismissible: false,
          builder: (ctx) => AlertDialog(
            title: const Text('⚠️ Konfigurasi Salah'),
            content: Text(
              'Error: Redirect URL salah ke localhost.\n\n'
              'Ini masalah konfigurasi, bukan masalah HP kamu.\n\n'
              'Solusi:\n'
              '1. Buka https://supabase.com/dashboard\n'
              '2. Pilih project kamu\n'
              '3. Pergi ke Authentication > Settings\n'
              '4. Ubah "Site URL" dari "http://localhost:3000" ke domain production\n'
              '5. Ubah "Redirect URLs" dari "http://localhost:3000/callback" ke "laundry28://oauth/callback"\n'
              '6. Save → Coba login lagi',
            ),
            actions: [
              TextButton(
                onPressed: () {
                  if (context.mounted) {
                    context.go(AppRoutes.login);
                  }
                },
                child: const Text('Kembali ke Login'),
              ),
            ],
          ),
        );
      }
      return;
    }

    if (error != null) {
      if (kDebugMode) {
        print('❌ [OAUTH] OAuth error: $error - $errorDescription');
      }
      if (mounted) {
        showDialog(
          context: context,
          barrierDismissible: false,
          builder: (ctx) => AlertDialog(
            title: const Text('❌ Login Gagal'),
            content: Text(
              errorDescription != null && errorDescription.isNotEmpty
                  ? 'Login gagal: $errorDescription'
                  : 'Login dibatalkan atau gagal. Silakan coba lagi.',
            ),
            actions: [
              TextButton(
                onPressed: () {
                  if (context.mounted) {
                    Navigator.of(context).pop();
                    context.go(AppRoutes.login);
                  }
                },
                child: const Text('Kembali ke Login'),
              ),
            ],
          ),
        );
      }
      return;
    }

    if (code != null) {
      if (kDebugMode) {
        print('✅ [OAUTH] OAuth code detected, processing...');
      }
      try {
        if (kIsWeb) {
          // Web: Exchange code for session using getSessionFromUrl
          // getSessionFromUrl is void in supabase_flutter 2.17.2 - it processes the URL internally
          await SupabaseService.client.auth.getSessionFromUrl(uri);
          // Check if session was created after processing
          final currentSession = SupabaseService.client.auth.currentSession;
          if (currentSession != null) {
            if (kDebugMode) { print('✅ [OAUTH] Web: Session obtained successfully'); }
          } else {
            if (kDebugMode) { print('⚠️ [OAUTH] Web: No session in URL'); }
          }
        } else {
          // Mobile: Supabase SDK already handles the deep link automatically
          // via _handleDeeplink in supabase_flutter. We just need to wait
          // for onAuthStateChange to detect the new session.
          //
          // IMPORTANT: Do NOT call getSessionFromUrl manually here —
          // the code has already been exchanged by the SDK, or will be
          // exchanged shortly by the uriLinkStream listener.
          if (kDebugMode) { print('✅ [OAUTH] Mobile: Deep link received, waiting for Supabase SDK to process...'); }

          // Wait a moment for the SDK to finish processing the deep link
          await Future.delayed(const Duration(milliseconds: 1000));

          // Verify session was created
          final currentSession = SupabaseService.client.auth.currentSession;
          if (currentSession != null) {
            if (kDebugMode) { print('✅ [OAUTH] Mobile: Session detected after SDK processing'); }
            if (kDebugMode) { print('✅ [OAUTH] Mobile: User ID = ${currentSession.user.id}'); }
            // Session sudah ada — AuthCubit.onAuthStateChange akan emit Authenticated
            // dan BlocConsumer listener akan redirect ke dashboard
          } else {
            if (kDebugMode) { print('⚠️ [OAUTH] Mobile: Session not yet available, will be handled by onAuthStateChange...'); }
          }
        }
      } catch (e) {
        if (kDebugMode) { print('❌ [OAUTH] Error processing OAuth callback: $e'); }
      }
    } else {
      // No code in URL — cek apakah session sudah ada
      // Ini bisa terjadi jika:
      // 1. User logout → login lagi → SDK sudah process session sebelumnya
      // 2. Deep link tidak membawa code (error scenario)
      if (kDebugMode) { print('⚠️ [OAUTH] No code in URL, checking existing session...'); }
      final currentSession = SupabaseService.client.auth.currentSession;
      if (currentSession != null) {
        if (kDebugMode) { print('✅ [OAUTH] Session already exists — AuthCubit should emit Authenticated'); }
        // Session sudah ada — AuthCubit.onAuthStateChange akan emit Authenticated
        // dan BlocConsumer listener akan redirect ke dashboard
        // Jika sudah ada session tapi AuthCubit tidak emit, ini berarti
        // user sudah pernah login sebelumnya dan session masih valid
      } else {
        if (kDebugMode) { print('❌ [OAUTH] No session found — login gagal atau tidak ada code'); }
        // Tidak ada session dan tidak ada code — login gagal
        if (mounted) {
          _cancelTimeout();
          showDialog(
            context: context,
            barrierDismissible: false,
            builder: (ctx) => AlertDialog(
              title: const Text('❌ Login Gagal'),
              content: const Text(
                'Tidak dapat memproses login. Silakan coba lagi.',
              ),
              actions: [
                TextButton(
                  onPressed: () {
                    if (context.mounted) {
                      Navigator.of(context).pop();
                      context.go(AppRoutes.login);
                    }
                  },
                  child: const Text('Kembali ke Login'),
                ),
              ],
            ),
          );
        }
      }
    }

    // Tidak perlu delay atau fetch role manual.
    // AuthCubit.onAuthStateChange listener akan otomatis:
    // 1. Mendeteksi session baru
    // 2. Fetch staff data via _fetchStaffData()
    // 3. Emit Authenticated state
    // 4. BlocListener di main.dart → GoRouter redirect ke dashboard
    // 5. GoRouter redirect ke dashboard
    if (kDebugMode) { print('✅ [OAUTH] Waiting for AuthCubit to handle state transition...'); }
  }

  Future<String?> _getTopLevelUrl() async {
    if (kIsWeb) {
      // On web, get the current browser URL which contains the OAuth code
      final url = getCurrentUrl();
      if (kDebugMode) { print('🌐 [OAUTH] Current browser URL: $url'); }
      return url;
    }

    // On mobile, use the stored deep link URI first (from uriLinkStream or getInitialLink)
    if (AppRoutes.deeplinkUri != null) {
      if (kDebugMode) { print('📱 [OAUTH] Using stored deep link URI: ${AppRoutes.deeplinkUri}'); }
      return AppRoutes.deeplinkUri.toString();
    }

    // Fallback to app_links.getInitialLink()
    try {
      final appLinks = AppLinks();
      final uri = await appLinks.getInitialLink();
      if (uri != null) {
        if (kDebugMode) { print('📱 [OAUTH] Mobile deep link URI (app_links): $uri'); }
        return uri.toString();
      }
    } catch (e) {
      if (kDebugMode) { print('⚠️ [OAUTH] Failed to get deep link via app_links: $e'); }
    }

    // Fallback to Uri.base (may be unreliable on some devices)
    final fallbackUri = Uri.base;
    if (kDebugMode) { print('📱 [OAUTH] Mobile deep link URI (fallback Uri.base): $fallbackUri'); }
    return fallbackUri.toString();
  }

  @override
  Widget build(BuildContext context) {
    return BlocConsumer<AuthCubit, AuthState>(
      listener: (context, state) {
        if (state is AuthOnboardingRequired) {
          if (kDebugMode) { print('🔀 [OAUTH_CALLBACK] AuthOnboardingRequired received — navigating to /onboarding'); }
          _cancelTimeoutAndNavigate(AppRoutes.onboarding);
        } else if (state is Authenticated) {
          if (kDebugMode) { print('✅ [OAUTH_CALLBACK] Authenticated received — navigating to dashboard'); }
          _cancelTimeoutAndNavigate(AppRoutes.dashboard);
        }
      },
      builder: (context, state) {
        return Scaffold(
          body: Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const CircularProgressIndicator(color: Color(0xFF1976D2)),
                const SizedBox(height: 16),
                Text(
                  'Memproses login...',
                  style: TextStyle(color: Colors.grey),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}