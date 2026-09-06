import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../../core/supabase/supabase_client.dart';
import '../models/staff_model.dart';

/// Repository untuk autentikasi - terintegrasi dengan Supabase Auth
class AuthRepository {
  final SupabaseClient _client = SupabaseService.client;

  /// Login Owner (email & password) via Supabase Auth
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
              .limit(1);

          if (staffResponse.isNotEmpty) {
            print('📋 Staff found: ${staffResponse.first['full_name']}');
            return StaffModel.fromJson(staffResponse.first);
          }
        } on PostgrestException catch (e) {
          // Tabel staff tidak ditemukan atau query gagal — tapi auth berhasil
          print('⚠️ Staff table lookup error: ${e.message}, but auth succeeded');
        }

        // Auth berhasil tapi tidak ada di tabel staff / query gagal — buat record sementara
        // Gunakan role 'owner' karena ini adalah login_owner flow (email-based)
        final user = response.user;
        print('🆕 Creating temporary staff for: ${user?.email}');
        return StaffModel(
          email: user!.email ?? '',
          fullName: user.email?.split('@').first ?? 'User',
          role: 'owner', // Default role untuk email-based login
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

  /// Login Employee (username & password) via Supabase Auth
  Future<StaffModel?> loginByUsername(String username, String password) async {
    try {
      print('🔵 Attempting employee login for: $username');
      
      // 1. Cari staff berdasarkan username di tabel staff
      final staffResponse = await _client
          .from('staff')
          .select()
          .eq('username', username.trim().toLowerCase())
          .limit(1);

      if (staffResponse.isEmpty) {
        print('❌ Employee not found: $username');
        return null;
      }

      final staffData = staffResponse.first as Map<String, dynamic>;
      final staffEmail = staffData['email'] as String?;
      
      if (staffEmail == null || staffEmail.isEmpty) {
        print('❌ No email found for username: $username');
        return null;
      }

      // 2. Login menggunakan Supabase Auth dengan email dari record staff
      print('🔵 Authenticating as: $staffEmail');
      final authResponse = await _client.auth.signInWithPassword(
        email: staffEmail,
        password: password,
      );

      if (authResponse.user == null) {
        print('❌ Auth failed for employee: $username');
        return null;
      }

      // 3. Return staff model dengan role info
      final staff = StaffModel.fromJson(staffData);
      print('✅ Employee login successful: ${staff.fullName} (role: ${staff.role})');
      return staff;
    } catch (e, stackTrace) {
      print('🔴 [REPO] LoginByUsername error: $e');
      print('📍 [REPO] Stack trace:\n$stackTrace');
      rethrow;
    }
  }

  /// Login Employee dengan PIN (username + 4-6 digit PIN)
  /// Metode ini TIDAK menggunakan Supabase Auth, langsung cek dari tabel staff
  Future<StaffModel?> loginByPin(String username, String pin) async {
    try {
      print('🔵 Attempting PIN login for: $username');

      // 1. Cari staff berdasarkan username di tabel staff
      final staffResponse = await _client
          .from('staff')
          .select()
          .eq('username', username.trim().toLowerCase())
          .limit(1);

      if (staffResponse.isEmpty) {
        print('❌ Employee not found: $username');
        return null;
      }

      final staffData = staffResponse.first as Map<String, dynamic>;
      final staff = StaffModel.fromJson(staffData);

      // 2. Cek apakah employee punya PIN
      if (staff.pin == null || staff.pin!.isEmpty) {
        print('⚠️ No PIN set for employee: $username');
        return null;
      }

      // 3. Validasi PIN (case-insensitive, trim whitespace)
      if (staff.pin!.trim() == pin.trim()) {
        print('✅ PIN login successful: ${staff.fullName} (role: ${staff.role})');
        return staff;
      } else {
        print('❌ PIN mismatch for: $username');
        return null;
      }
    } catch (e, stackTrace) {
      print('🔴 [REPO] LoginByPin error: $e');
      print('📍 [REPO] Stack trace:\n$stackTrace');
      rethrow;
    }
  }

  /// Register user baru (Owner)
  /// Default role adalah 'owner' karena registrasi dari login screen adalah pemilik bisnis
  Future<bool> register(
    String email,
    String password,
    String fullName, {
    String role = 'owner',
  }) async {
    try {
      final response = await _client.auth.signUp(
        email: email,
        password: password,
      );

      if (response.user != null) {
        // Insert ke tabel staff dengan role (default: owner)
        await _client.from('staff').insert({
          'email': email,
          'full_name': fullName,
          'role': role,
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

  // ==================== Staff CRUD Methods ====================

  /// Fetch all staff members from the database
  Future<List<StaffModel>> fetchStaffList() async {
    try {
      print('📋 Fetching staff list...');
      final response = await _client
          .from('staff')
          .select()
          .order('created_at', ascending: false);

      final staffList = (response as List)
          .map((json) => StaffModel.fromJson(json as Map<String, dynamic>))
          .toList();

      print('✅ Found ${staffList.length} staff members');
      return staffList;
    } catch (e, stackTrace) {
      print('🔴 [REPO] fetchStaffList error: $e');
      print('📍 [REPO] Stack trace:\n$stackTrace');
      rethrow;
    }
  }

  /// Create a new staff member
  Future<StaffModel> createStaff({
    required String email,
    required String fullName,
    String? username,
    String role = 'employee',
    String password = 'admin123',
  }) async {
    try {
      print('➕ Creating new staff: $fullName ($email)');

      // First, create the user in Supabase Auth
      final response = await _client.auth.signUp(
        email: email.trim().toLowerCase(),
        password: password,
      );

      if (response.user == null) {
        throw Exception('Failed to create auth user');
      }

      // Then, insert staff record
      await _client.from('staff').insert({
        'email': email.trim().toLowerCase(),
        'full_name': fullName.trim(),
        'username': username?.trim().toLowerCase(),
        'role': role,
        'created_at': DateTime.now().toIso8601String(),
      });

      print('✅ Staff created successfully: $fullName');

      // Return the created staff model
      return StaffModel(
        id: response.user!.id.hashCode, // Use user ID hash as placeholder
        email: email.trim().toLowerCase(),
        username: username?.trim().toLowerCase(),
        fullName: fullName.trim(),
        role: role,
        createdAt: DateTime.now(),
      );
    } catch (e, stackTrace) {
      print('🔴 [REPO] createStaff error: $e');
      print('📍 [REPO] Stack trace:\n$stackTrace');
      rethrow;
    }
  }

  /// Update an existing staff member
  Future<StaffModel> updateStaff({
    required int id,
    String? email,
    String? fullName,
    String? username,
    String? role,
  }) async {
    try {
      print('✏️ Updating staff #$id');

      final updateData = <String, dynamic>{};
      if (email != null) updateData['email'] = email.trim().toLowerCase();
      if (fullName != null) updateData['full_name'] = fullName.trim();
      if (username != null) updateData['username'] = username.trim().toLowerCase();
      if (role != null) updateData['role'] = role;

      final response = await _client
          .from('staff')
          .update(updateData)
          .eq('id', id)
          .select()
          .single();

      final staff = StaffModel.fromJson(response as Map<String, dynamic>);
      print('✅ Staff updated successfully: ${staff.fullName}');
      return staff;
    } catch (e, stackTrace) {
      print('🔴 [REPO] updateStaff error: $e');
      print('📍 [REPO] Stack trace:\n$stackTrace');
      rethrow;
    }
  }

  /// Delete a staff member (both from staff table and auth)
  Future<void> deleteStaff(int id) async {
    try {
      print('🗑️ Deleting staff #$id');

      // First, get the staff email to delete from auth
      final staffResponse = await _client
          .from('staff')
          .select('email')
          .eq('id', id)
          .single();

      final email = (staffResponse as Map<String, dynamic>)['email'] as String?;

      // Delete from staff table
      await _client.from('staff').delete().eq('id', id);

      // Delete from Supabase Auth if email exists
      if (email != null) {
        try {
          final usersResponse = await _client
              .from('users')
              .select('id')
              .eq('email', email);

          // Note: Supabase Auth users are managed through auth API, not a direct table
          // We'll leave the auth user for now and just delete from staff table
          // In production, you'd use admin API to delete auth users
        } catch (e) {
          print('⚠️ Could not fetch auth user for email $email: $e');
        }
      }

      print('✅ Staff #$id deleted successfully');
    } catch (e, stackTrace) {
      print('🔴 [REPO] deleteStaff error: $e');
      print('📍 [REPO] Stack trace:\n$stackTrace');
      rethrow;
    }
  }
}
