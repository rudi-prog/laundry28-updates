import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../../core/supabase/supabase_client.dart';
import '../models/staff_model.dart';

/// Repository untuk autentikasi - terintegrasi dengan Supabase Auth
class AuthRepository {
  final SupabaseClient _client = SupabaseService.client;

  /// Login dengan email & password menggunakan Supabase Auth
  Future<StaffModel?> login(String email, String password) async {
    try {
      // Login menggunakan Supabase Auth (email/password)
      print('🔵 Attempting login for: $email');
      final response = await _client.auth.signInWithPassword(
        email: email,
        password: password,
      );

      // Jika login berhasil, ambil data staff dari tabel staff
      if (response.user != null) {
        try {
          print('✅ Auth successful, fetching staff data...');
          final staffResponse = await _client
              .from('staff')
              .select()
              .eq('email', email.trim().toLowerCase())
              .maybeSingle();

          if (staffResponse != null) {
            print('📋 Staff found: ${staffResponse['full_name']}');
            return StaffModel.fromJson(staffResponse);
          }
        } on PostgrestException catch (e) {
          // Tabel staff tidak ditemukan atau query gagal — tapi auth berhasil
          print('⚠️ Staff table lookup error: ${e.message}, but auth succeeded');
        }

        // Auth berhasil tapi tidak ada di tabel staff / query gagal — buat record sementara
        final user = response.user;
        print('🆕 Creating temporary staff for: ${user?.email}');
        return StaffModel(
          email: user!.email ?? '',
          fullName: user.email?.split('@').first ?? 'User',
          createdAt: DateTime.now(),
        );
      }

      print('❌ Auth failed - no user returned');
      return null;
    } catch (e, stackTrace) {
      print('🔴 [REPO] Login error: $e');
      print('📍 [REPO] Stack trace:\n$stackTrace');
      
      // Deteksi tipe error spesifik untuk debugging mobile
      final errStr = e.toString();
      if (errStr.contains('timeout') || errStr.contains('Timeout')) {
        print('⏰ [TIMEOUT DETECTED] - Server tidak merespons dalam waktu yang ditentukan');
      } else if (errStr.contains('connection') || errStr.contains('Connection')) {
        print('🌐 [CONNECTION ERROR] - Tidak dapat terhubung ke server');
      } else if (errStr.contains('certificate') || errStr.contains('SSL') || errStr.contains('TLS')) {
        print('🔒 [SSL/CERT ERROR] - Masalah sertifikat keamanan');
      } else if (errStr.contains('format') || errStr.contains('Format')) {
        print('📝 [FORMAT ERROR] - Format data tidak valid');
      }
      
      rethrow;
    }
  }

  /// Register user baru
  Future<bool> register(String email, String password, String fullName) async {
    try {
      final response = await _client.auth.signUp(
        email: email,
        password: password,
      );

      if (response.user != null) {
        // Insert ke tabel staff
        await _client.from('staff').insert({
          'email': email,
          'full_name': fullName,
          'created_at': DateTime.now().toIso8601String(),
        });
        return true;
      }
      return false;
    } catch (e, stackTrace) {
      print('🔴 [REPO] Register error: $e');
      print('📍 [REPO] Stack trace:\n$stackTrace');
      
      final errStr = e.toString();
      if (errStr.contains('duplicate') || errStr.contains('unique')) {
        print('🔄 [DUPLICATE] - Email sudah terdaftar');
      } else if (errStr.contains('password') || errStr.contains('weak')) {
        print('🔑 [PASSWORD ERROR] - Password tidak memenuhi syarat');
      }
      
      return false;
    }
  }

  /// Check if user is logged in
  bool isAuthenticated() {
    return _client.auth.currentUser != null;
  }

  /// Get current user
  User? getCurrentUser() {
    return _client.auth.currentUser;
  }

  /// Logout
  Future<void> logout() async {
    await _client.auth.signOut();
  }

  /// Refresh session if expired
  Future<void> refreshSession() async {
    try {
      final session = _client.auth.currentSession;
      if (session != null) {
        await _client.auth.refreshSession();
      }
    } catch (e) {
      print('Session refresh error: $e');
    }
  }
}
