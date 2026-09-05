import 'package:flutter_bloc/flutter_bloc.dart';
import '../data/repositories/auth_repository.dart';
import '../data/models/staff_model.dart';

part 'auth_state.dart';

class AuthCubit extends Cubit<AuthState> {
  AuthCubit() : super(AuthInitial());

  final AuthRepository _authRepository = AuthRepository();

  /// Login dengan email & password menggunakan Supabase Auth
  Future<void> login(String email, String password) async {
    emit(AuthLoading());
    try {
      print('🔵 [LOGIN] Attempting: $email');
      final staff = await _authRepository.login(email, password);
      if (staff != null) {
        print('✅ [LOGIN] Auth successful for: ${staff.email}');
        emit(Authenticated(staff));
      } else {
        print('❌ [LOGIN] Invalid credentials for: $email');
        emit(AuthUnauthenticated(
            message: 'Email atau password salah'));
      }
    } catch (e, stackTrace) {
      final errorDetails = _formatError(e);
      print('🔴 [LOGIN] ERROR: ${errorDetails}');
      print('📍 STACK TRACE:\n$stackTrace');
      
      emit(AuthUnauthenticated(
          message: 'Login gagal!\n\n'
              'Tipe: ${e.runtimeType}\n'
              'Pesan: ${e.toString().replaceAll('\n', ' ').replaceAll('Exception: ', '')}'));
    }
  }

  /// Register user baru
  Future<void> register(String email, String password, String fullName) async {
    emit(AuthLoading());
    try {
      print('🔵 [REGISTER] Attempting: $email');
      final success = await _authRepository.register(email, password, fullName);
      if (success) {
        print('✅ [REGISTER] Success for: $email');
        emit(AuthUnauthenticated(
            message: 'Registrasi berhasil! Silakan login.'));
      } else {
        print('❌ [REGISTER] Failed for: $email');
        emit(AuthUnauthenticated(message: 'Registrasi gagal.'));
      }
    } catch (e, stackTrace) {
      final errorDetails = _formatError(e);
      print('🔴 [REGISTER] ERROR: ${errorDetails}');
      print('📍 STACK TRACE:\n$stackTrace');
      
      emit(AuthUnauthenticated(
          message: 'Registrasi gagal!\n\n'
              'Tipe: ${e.runtimeType}\n'
              'Pesan: ${e.toString().replaceAll('\n', ' ').replaceAll('Exception: ', '')}'));
    }
  }

  /// Logout
  Future<void> logout() async {
    await _authRepository.logout();
    emit(AuthUnauthenticated());
  }

  /// Format error menjadi string yang mudah dibaca
  String _formatError(dynamic e) {
    final str = e.toString().toLowerCase();
    
    // Cek SocketException / DNS errors FIRST (before generic 'ssl' match)
    if (str.contains('socketexception') || str.contains('socket exception')) {
      if (str.contains('failed host lookup') || 
          str.contains('no address associated') ||
          str.contains('dns') ||
          str.contains('hostname')) {
        return 'DNS ERROR - Tidak dapat menemukan server. Periksa koneksi internet';
      }
      if (str.contains('connection refused') || 
          str.contains('connection timed out') ||
          str.contains('connection reset')) {
        return 'CONNECTION FAILED - Server menolak/tidak merespons koneksi';
      }
    }
    
    // Cek tipe error spesifik
    if (str.contains('timeout') && !str.contains('supabase')) {
      return 'TIMEOUT - Koneksi terputus';
    }
    if (str.contains('connection') || str.contains('connectivity')) {
      return 'NETWORK ERROR - Periksa koneksi internet';
    }
    
    // SSL/Certificate check — be more specific to avoid false positives
    if (str.contains('certificate') || 
        str.contains('x509') || 
        str.contains('pkix') ||
        str.contains('sslhandshakeexception') ||
        str.contains('tls handshake')) {
      return 'SSL CERTIFICATE ERROR - Masalah keamanan koneksi';
    }
    
    if (str.contains('401')) {
      return 'UNAUTHORIZED - Email/password salah';
    }
    if (str.contains('403')) {
      return 'FORBIDDEN - Akses ditolak';
    }
    if (str.contains('429')) {
      return 'RATE LIMITED - Terlalu banyak percobaan';
    }
    if (str.contains('500') || str.contains('internal')) {
      return 'SERVER ERROR - Masalah dari server';
    }
    
    return str;
  }
}