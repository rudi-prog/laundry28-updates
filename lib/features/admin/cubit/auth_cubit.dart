import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:supabase_flutter/supabase_flutter.dart' as supabase;
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../../core/supabase/supabase_client.dart';
import '../data/models/staff_model.dart';
import '../data/repositories/auth_repository.dart';

part 'auth_state.dart';

class AuthCubit extends Cubit<AuthState> {
  AuthCubit() : super(AuthInitial()) {
    // Item #12: Listen to auth state changes from Supabase
    // This is the CRITICAL blocker for OAuth to work end-to-end
    _authSubscription = SupabaseService.client.auth.onAuthStateChange.listen((data) async {
      final event = data.event;
      final session = data.session;

      if (event == AuthChangeEvent.signedIn && session != null) {
        final user = session.user;
        if (kDebugMode) {
          print('🔵 [AUTH_CUBIT] Auth state change: SIGNED IN');
          print('🔵 [AUTH_CUBIT] User ID: ${user.id}');
        }

        try {
          if (kDebugMode) {
            print('🔍 [AUTH_CUBIT] Fetching staff by email: ${user.email}');
          }
          // Try to find staff record by email
          final staff = await AuthRepository().fetchStaffByEmail(user.email ?? '');

          if (staff != null) {
            // User exists in staff table
            if (kDebugMode) {
              print('✅ [AUTH_CUBIT] Staff found: ${staff.fullName} (role: ${staff.role}, laundry_id: ${staff.laundryId})');
            }

            // FIX: Staff bisa saja sudah punya baris di tabel `staff` (mis. dari
            // register()) tapi BELUM menyelesaikan onboarding laundry
            // (laundry_id masih null). Sebelumnya langsung emit Authenticated
            // di sini, sehingga owner baru bisa "lolos" masuk ke halaman utama
            // tanpa laundry_id valid — memicu error di layar yang butuh
            // laundryId (fetchStaffList, createStaff, dll).
            if (staff.laundryId == null) {
              if (kDebugMode) {
                print('🟡 [AUTH_CUBIT] Staff found but laundry_id is null — onboarding required');
              }
              emit(AuthOnboardingRequired(email: user.email));
            } else {
              emit(Authenticated(staff));
            }
          } else {
            // New user — needs onboarding
            if (kDebugMode) {
              print('🆕 [AUTH_CUBIT] No staff record for ${user.email} — onboarding required');
            }
            emit(AuthOnboardingRequired(email: user.email));
          }
        } catch (e, stackTrace) {
          if (kDebugMode) {
            print('🔴 [AUTH_CUBIT] Error fetching staff: $e');
            print('📍 $stackTrace');
          }
          // If we can't fetch staff, try to create a temporary record for email-based login
          emit(Authenticated(StaffModel(
            email: user.email ?? '',
            fullName: user.email?.split('@').first ?? 'User',
            role: 'owner',
            authUserId: user.id,
            createdAt: DateTime.now(),
          )));
        }
      } else if (event == AuthChangeEvent.signedOut ||
          event == AuthChangeEvent.tokenRefreshed) {
        if (kDebugMode) {
          print('🔵 [AUTH_CUBIT] Auth state change: ${event.name}');
        }
        if (event == AuthChangeEvent.signedOut) {
          emit(AuthUnauthenticated());
        }
        // On token refresh, try to re-fetch staff
        if (event == AuthChangeEvent.tokenRefreshed) {
          final currentUser = SupabaseService.client.auth.currentUser;
          if (currentUser != null) {
            try {
              final staff = await AuthRepository().fetchStaffByEmail(currentUser.email ?? '');
              if (staff != null && staff.laundryId != null) {
                emit(Authenticated(staff));
              }
              // Kalau laundryId masih null, biarkan state apa adanya (jangan
              // paksa Authenticated) — token refresh tidak boleh "mendorong"
              // user yang belum onboarding ke halaman utama.
            } catch (_) {
              // Ignore — state will be updated on next auth event
            }
          }
        }
      }
    });
  }

  late final StreamSubscription<supabase.AuthState> _authSubscription;

  final AuthRepository _authRepository = AuthRepository();

  /// Login dengan email & password menggunakan Supabase Auth
  Future<void> login(String email, String password) async {
    if (kDebugMode) {
      print('🔵 [LOGIN] Attempting: $email');
    }
    emit(AuthLoading());
    try {
      final staff = await _authRepository.login(email, password);
      if (staff != null) {
        if (kDebugMode) {
          print('✅ [LOGIN] Auth successful for: ${staff.email} (laundry_id: ${staff.laundryId})');
        }

        // FIX: sama seperti di onAuthStateChange — kalau staff belum punya
        // laundry_id (mis. baru register() tapi belum completeOnboarding()),
        // arahkan ke onboarding, jangan langsung Authenticated.
        if (staff.laundryId == null) {
          if (kDebugMode) {
            print('🟡 [LOGIN] Staff found but laundry_id is null — onboarding required');
          }
          emit(AuthOnboardingRequired(email: staff.email));
        } else {
          emit(Authenticated(staff));
        }
      } else {
        if (kDebugMode) {
          print('❌ [LOGIN] Invalid credentials for: $email');
        }
        emit(AuthUnauthenticated(
            message: 'Email atau password salah'));
      }
    } catch (e) {
      if (kDebugMode) {
        print('🔴 [LOGIN] ERROR: ${_formatError(e)}');
      }
      emit(AuthUnauthenticated(
          message: 'Login gagal! Periksa koneksi internet atau coba lagi.'));
    }
  }

  /// Login Employee dengan username & password
  Future<void> loginByUsername(String username, String password) async {
    if (kDebugMode) {
      print('🔵 [LOGIN_BY_USERNAME] Attempting: $username');
    }
    emit(AuthLoading());
    try {
      final staff = await _authRepository.loginByUsername(username, password);
      if (staff != null) {
        if (kDebugMode) {
          print('✅ [LOGIN_BY_USERNAME] Auth successful for: ${staff.fullName} (role: ${staff.role})');
        }
        // Catatan: employee selalu dibuat lewat createStaff() (edge function)
        // yang mewajibkan laundryId valid sejak awal, jadi employee tidak
        // mungkin punya laundryId null. Tidak perlu pengecekan tambahan.
        emit(Authenticated(staff));
      } else {
        if (kDebugMode) {
          print('❌ [LOGIN_BY_USERNAME] Invalid credentials for: $username');
        }
        emit(AuthUnauthenticated(
            message: 'Username atau password salah'));
      }
    } catch (e) {
      if (kDebugMode) {
        print('🔴 [LOGIN_BY_USERNAME] ERROR: ${_formatError(e)}');
      }
      emit(AuthUnauthenticated(
          message: 'Login gagal! Periksa koneksi internet atau coba lagi.'));
    }
  }

  /// Login Employee dengan username & PIN
  Future<void> loginByPin(String username, String pin) async {
    if (kDebugMode) {
      print('🔵 [LOGIN_BY_PIN] Attempting: $username');
    }
    emit(AuthLoading());
    try {
      final staff = await _authRepository.loginByPin(username, pin);
      if (staff != null) {
        if (kDebugMode) {
          print('✅ [LOGIN_BY_PIN] Auth successful for: ${staff.fullName} (role: ${staff.role})');
        }
        // Sama seperti loginByUsername — employee selalu punya laundryId valid.
        emit(Authenticated(staff));
      } else {
        if (kDebugMode) {
          print('❌ [LOGIN_BY_PIN] Invalid credentials for: $username');
        }
        emit(AuthUnauthenticated(
            message: 'Username atau PIN salah'));
      }
    } catch (e) {
      if (kDebugMode) {
        print('🔴 [LOGIN_BY_PIN] ERROR: ${_formatError(e)}');
      }
      // Pass specific error message from repository (e.g., "Akun terkunci")
      final errorMessage = e.toString().replaceAll('Exception: ', '');
      emit(AuthUnauthenticated(message: errorMessage));
    }
  }

  /// Item #11: Login dengan Google OAuth
  Future<void> signInWithGoogle() async {
    if (kDebugMode) {
      print('🔵 [GOOGLE_OAUTH] Starting Google Sign-In...');
    }
    emit(AuthGoogleLoading());
    try {
      await _authRepository.signInWithGoogle(
        redirectTo: kIsWeb ? null : 'laundry28://oauth/callback',
      );
      if (kDebugMode) {
        print('🔵 [GOOGLE_OAUTH] OAuth flow initiated — waiting for redirect...');
      }
      // Catatan: hasil OAuth ditangani lewat onAuthStateChange listener di atas
      // (yang sudah memeriksa laundryId juga), jadi tidak perlu emit di sini.
    } catch (e) {
      if (kDebugMode) {
        print('🔴 [GOOGLE_OAUTH] Error: ${_formatError(e)}');
      }
      if (e.toString().contains('cancelled') || e.toString().contains('Cancelled')) {
        emit(AuthUnauthenticated(message: 'Login Google dibatalkan'));
      } else {
        emit(AuthUnauthenticated(message: 'Login Google gagal: ${_formatError(e)}'));
      }
    }
  }

  /// Register user baru
  Future<void> register(String email, String password, String fullName) async {
    if (kDebugMode) {
      print('🔵 [REGISTER] Attempting: $email');
    }
    emit(AuthLoading());
    try {
      final success = await _authRepository.register(email, password, fullName);
      if (success) {
        if (kDebugMode) {
          print('✅ [REGISTER] Success for: $email');
        }
        emit(AuthUnauthenticated(
            message: 'Registrasi berhasil! Silakan login.'));
      } else {
        if (kDebugMode) {
          print('❌ [REGISTER] Failed for: $email');
        }
        emit(AuthUnauthenticated(message: 'Registrasi gagal.'));
      }
    } catch (e) {
      if (kDebugMode) {
        print('🔴 [REGISTER] ERROR: ${_formatError(e)}');
      }
      emit(AuthUnauthenticated(
          message: 'Registrasi gagal! Periksa koneksi internet atau coba lagi.'));
    }
  }

  /// Item #13: Complete onboarding — create laundry for new user
  Future<void> completeOnboarding({
    required String laundryName,
    required String address,
    required String phone,
  }) async {
    emit(AuthOnboardingLoading());
    try {
      final result = await _authRepository.completeOnboarding(
        laundryName: laundryName,
        address: address,
        phone: phone,
      );
      if (kDebugMode) {
        print('✅ [ONBOARDING] Laundry "$laundryName" created (ID: ${result['laundryId']})');
      }
      emit(AuthOnboardingComplete(
        laundryName: laundryName,
        laundryId: result['laundryId'],
      ));
    } catch (e, stackTrace) {
      if (kDebugMode) {
        print('🔴 [ONBOARDING] Error: ${_formatError(e)}');
        print('🔴 [ONBOARDING] RAW ERROR: $e');
        print('📍 [ONBOARDING] Stack trace:\n$stackTrace');
      }
      emit(AuthOnboardingError('Gagal membuat laundry. Periksa koneksi internet Anda dan coba lagi'));
    }
  }

  /// Logout
  Future<void> logout() async {
    if (kDebugMode) {
      print('🔵 [LOGOUT] Logging out...');
    }
    await _authRepository.logout();
    emit(AuthUnauthenticated());
  }

  /// Format error menjadi pesan yang mudah dibaca user (Item #18)
  /// Pesan teknis tetap hanya untuk log/debug, pesan user selalu ramah & jelas
  String _formatError(dynamic e) {
    final str = e.toString().toLowerCase();

    // Cek SocketException / DNS errors FIRST (before generic 'ssl' match)
    if (str.contains('socketexception') || str.contains('socket exception')) {
      if (str.contains('failed host lookup') ||
          str.contains('no address associated') ||
          str.contains('dns') ||
          str.contains('hostname')) {
        return 'Tidak dapat menemukan server. Periksa koneksi internet Anda';
      }
      if (str.contains('connection refused') ||
          str.contains('connection timed out') ||
          str.contains('connection reset')) {
        return 'Server tidak merespons. Periksa koneksi internet Anda';
      }
    }

    // Cek tipe error spesifik
    if (str.contains('timeout') && !str.contains('supabase')) {
      return 'Koneksi terputus. Periksa internet Anda dan coba lagi';
    }
    if (str.contains('connection') || str.contains('connectivity')) {
      return 'Periksa koneksi internet Anda';
    }

    // SSL/Certificate check — pesan user-friendly, jangan pakai istilah teknis
    if (str.contains('certificate') ||
        str.contains('x509') ||
        str.contains('pkix') ||
        str.contains('sslhandshakeexception') ||
        str.contains('tls handshake')) {
      return 'Koneksi tidak aman. Periksa pengaturan jaringan Anda';
    }

    if (str.contains('401')) {
      return 'Email atau password salah. Periksa kembali dan coba lagi';
    }
    if (str.contains('403')) {
      return 'Anda tidak memiliki akses. Hubungi administrator';
    }
    if (str.contains('429')) {
      return 'Terlalu banyak percobaan. Tunggu beberapa menit sebelum mencoba lagi';
    }
    if (str.contains('500') || str.contains('internal')) {
      return 'Masalah server. Kami sedang memperbaiki — coba lagi nanti';
    }

    // Generic friendly message (don't expose technical details to user)
    return 'Terjadi kesalahan. Periksa koneksi internet Anda dan coba lagi';
  }

  @override
  Future<void> close() {
    _authSubscription.cancel();
    return super.close();
  }
}