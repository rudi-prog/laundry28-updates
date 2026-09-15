import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../../core/supabase/supabase_client.dart';
import '../../../../core/utils/pin_hasher.dart';
import '../models/staff_model.dart';

/// Repository untuk autentikasi - terintegrasi dengan Supabase Auth
class AuthRepository {
  final SupabaseClient _client = SupabaseService.client;

  /// Login Owner (email & password) via Supabase Auth
  Future<StaffModel?> login(String email, String password) async {
    try {
      if (kDebugMode) {
        print('🔵 Attempting login for: $email');
      }
      final response = await _client.auth.signInWithPassword(
        email: email,
        password: password,
      );

      if (response.user != null) {
        try {
          if (kDebugMode) {
            print('✅ Auth successful, fetching staff data...');
          }
          final staffResponse = await _client
              .from('staff')
              .select('*')
              .eq('email', email.trim().toLowerCase())
              .limit(1);

          if (staffResponse.isNotEmpty) {
            if (kDebugMode) {
              print('📋 Staff found: ${staffResponse.first['full_name']}');
            }
            return StaffModel.fromJson(staffResponse.first);
          }
        } on PostgrestException catch (e) {
          if (kDebugMode) {
            print('⚠️ Staff table lookup error: ${e.message}, but auth succeeded');
          }
        }

        final user = response.user;
        if (kDebugMode) {
          print('🆕 Creating temporary staff for: ${user?.email}');
        }
        return StaffModel(
          email: user!.email ?? '',
          fullName: user.email?.split('@').first ?? 'User',
          role: 'owner',
          createdAt: DateTime.now(),
        );
      }

      if (kDebugMode) {
        print('❌ Auth failed - no user returned');
      }
      return null;
    } catch (e, stackTrace) {
      if (kDebugMode) {
        print('🔴 [REPO] Login error: $e');
        print('📍 [REPO] Stack trace:\n$stackTrace');
      }

      final errStr = e.toString();
      if (errStr.contains('timeout') || errStr.contains('Timeout')) {
        if (kDebugMode) {
          print('⏰ [TIMEOUT DETECTED] - Server tidak merespons dalam waktu yang ditentukan');
        }
      } else if (errStr.contains('connection') || errStr.contains('Connection')) {
        if (kDebugMode) {
          print('🌐 [CONNECTION ERROR] - Tidak dapat terhubung ke server');
        }
      } else if (errStr.contains('certificate') || errStr.contains('SSL') || errStr.contains('TLS')) {
        if (kDebugMode) {
          print('🔒 [SSL/CERT ERROR] - Masalah sertifikat keamanan');
        }
      } else if (errStr.contains('format') || errStr.contains('Format')) {
        if (kDebugMode) {
          print('📝 [FORMAT ERROR] - Format data tidak valid');
        }
      }

      rethrow;
    }
  }

  /// Login Employee (username & password) via Supabase Auth
  Future<StaffModel?> loginByUsername(String username, String password) async {
    try {
      if (kDebugMode) {
        print('🔵 Attempting employee login for: $username');
      }

      final authEmail = '${username.trim().toLowerCase()}@laundry28.com';
      if (kDebugMode) {
        print('🔵 Authenticating as: $authEmail');
      }
      final authResponse = await _client.auth.signInWithPassword(
        email: authEmail,
        password: password,
      );

      if (authResponse.user == null) {
        if (kDebugMode) {
          print('❌ Auth failed for employee: $username');
        }
        return null;
      }

      if (kDebugMode) {
        print('✅ Auth successful, fetching staff data...');
      }

      final staffResponse = await _client
          .from('staff')
          .select('*')
          .eq('username', username.trim().toLowerCase())
          .limit(1);

      if (staffResponse.isEmpty) {
        if (kDebugMode) {
          print('❌ Employee not found in staff table: $username');
        }
        return null;
      }

      final staffData = staffResponse.first;
      final staff = StaffModel.fromJson(staffData);
      if (kDebugMode) {
        print('✅ Employee login successful: ${staff.fullName} (role: ${staff.role})');
      }
      return staff;
    } catch (e, stackTrace) {
      if (kDebugMode) {
        print('🔴 [REPO] LoginByUsername error: $e');
        print('📍 [REPO] Stack trace:\n$stackTrace');
      }
      rethrow;
    }
  }

  /// Login Employee dengan PIN (username + 4-6 digit PIN)
  /// FIX: Login ke Supabase Auth DULUAN agar RLS bisa akses tabel staff
  /// FIX: Verifikasi PIN pakai bcrypt hash (bukan plaintext comparison)
  /// FIX: Rate limiting — lock akun setelah 5x gagal selama 5 menit
  Future<StaffModel?> loginByPin(String username, String pin) async {
    try {
      if (kDebugMode) {
        print('🔵 [LOGIN_BY_PIN] Attempting: $username');
      }

      final authEmail = '${username.trim().toLowerCase()}@laundry28.com';

      if (kDebugMode) {
        print('🔵 Attempting auth login for: $authEmail');
      }
      final authResponse = await _client.auth.signInWithPassword(
        email: authEmail,
        password: pin,
      );

      if (authResponse.user == null) {
        if (kDebugMode) {
          print('❌ Auth failed for: $authEmail (user mungkin belum terdaftar)');
        }
        return null;
      }

      if (kDebugMode) {
        print('✅ Auth successful, fetching staff data...');
      }

      final staffResponse = await _client
          .from('staff')
          .select('*')
          .eq('username', username.trim().toLowerCase())
          .limit(1);

      if (staffResponse.isEmpty) {
        if (kDebugMode) {
          print('⚠️ [AUTO-PROVISION] Employee not found in staff table: $username — auto-provisioning is disabled');
          print('⚠️ [AUTO-PROVISION] Please create this employee via the owner dashboard first.');
        }
        return null;
      }

      final staffData = staffResponse.first;
      final staff = StaffModel.fromJson(staffData);

      if (staff.lockedUntil != null && DateTime.now().isBefore(staff.lockedUntil!)) {
        final remaining = staff.lockedUntil!.difference(DateTime.now());
        final minutes = remaining.inMinutes;
        final seconds = remaining.inSeconds % 60;
        if (kDebugMode) {
          print('🔒 [RATE_LIMIT] Akun terkunci, sisa: ${minutes}m ${seconds}s');
        }
        throw Exception('Akun terkunci. Coba lagi dalam ${minutes}m ${seconds}s');
      }

      if (staff.pinHash == null || staff.pinHash!.isEmpty) {
        if (kDebugMode) {
          print('⚠️ No PIN hash set for employee: $username');
        }
        return null;
      }

      final isPinValid = PinHasher.verify(pin.trim(), staff.pinHash!);

      if (isPinValid) {
        if (staff.failedPinAttempts != null && staff.failedPinAttempts! > 0) {
          await _client.from('staff').update({
            'failed_pin_attempts': 0,
            'locked_until': null,
          }).eq('id', staff.id!);
          if (kDebugMode) {
            print('✅ [RATE_LIMIT] Failed attempts reset after successful login');
          }
        }
        if (kDebugMode) {
          print('✅ [LOGIN_BY_PIN] Auth successful for: ${staff.fullName} (role: ${staff.role})');
        }
        return staff;
      } else {
        final currentAttempts = staff.failedPinAttempts ?? 0;
        final newAttempts = currentAttempts + 1;

        if (kDebugMode) {
          print('❌ PIN mismatch for: $username (attempt $newAttempts/5)');
        }

        if (newAttempts >= 5) {
          final lockedUntil = DateTime.now().add(Duration(minutes: 5));
          await _client.from('staff').update({
            'failed_pin_attempts': newAttempts,
            'locked_until': lockedUntil.toIso8601String(),
          }).eq('id', staff.id!);
          if (kDebugMode) {
            print('🔒 [RATE_LIMIT] Account locked for 5 minutes');
          }
          throw Exception('Akun terkunci karena 5x gagal PIN. Coba lagi dalam 5 menit');
        }

        await _client.from('staff').update({
          'failed_pin_attempts': newAttempts,
        }).eq('id', staff.id!);

        final remainingAttempts = 5 - newAttempts;
        if (kDebugMode) {
          print('⚠️ [RATE_LIMIT] $remainingAttempts percobaan tersisa sebelum akun terkunci');
        }
        return null;
      }
    } catch (e, stackTrace) {
      if (kDebugMode) {
        print('🔴 [REPO] LoginByPin error: $e');
        print('📍 [REPO] Stack trace:\n$stackTrace');
      }
      rethrow;
    }
  }

  /// Register user baru (Owner)
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
      if (kDebugMode) {
        print('🔴 [REPO] Register error: $e');
        print('📍 [REPO] Stack trace:\n$stackTrace');
      }

      final errStr = e.toString();
      if (errStr.contains('duplicate') || errStr.contains('unique')) {
        if (kDebugMode) {
          print('🔄 [DUPLICATE] - Email sudah terdaftar');
        }
      } else if (errStr.contains('password') || errStr.contains('weak')) {
        if (kDebugMode) {
          print('🔑 [PASSWORD ERROR] - Password tidak memenuhi syarat');
        }
      }

      return false;
    }
  }

  bool isAuthenticated() {
    return _client.auth.currentUser != null;
  }

  User? getCurrentUser() {
    return _client.auth.currentUser;
  }

  Future<StaffModel?> fetchStaffByEmail(String email) async {
    try {
      final response = await _client
          .from('staff')
          .select('*')
          .eq('email', email)
          .maybeSingle();

      if (response == null) {
        return null;
      }

      return StaffModel.fromJson(response);
    } catch (e) {
      if (kDebugMode) {
        print('❌ [REPO] fetchStaffByEmail error: $e');
      }
      return null;
    }
  }

  Future<void> signInWithGoogle({String? redirectTo}) async {
    try {
      if (kDebugMode) {
        print('🔵 [GOOGLE_OAUTH] Initiating Google OAuth...');
      }

      await _client.auth.signInWithOAuth(
        OAuthProvider.google,
        redirectTo: redirectTo,
      );

      if (kDebugMode) {
        print('✅ [GOOGLE_OAUTH] OAuth flow initiated successfully');
      }
    } catch (e) {
      if (kDebugMode) {
        print('🔴 [GOOGLE_OAUTH] Error: $e');
      }
      rethrow;
    }
  }

  Future<void> logout() async {
    await _client.auth.signOut();
  }

  Future<void> refreshSession() async {
    try {
      final session = _client.auth.currentSession;
      if (session != null) {
        await _client.auth.refreshSession();
      }
    } catch (e) {
      if (kDebugMode) {
        print('Session refresh error: $e');
      }
    }
  }

  // ==================== Staff CRUD Methods ====================

  /// Fetch staff members, optionally filtered by laundry
  Future<List<StaffModel>> fetchStaffList({int? laundryId}) async {
    try {
      debugPrint('📋 [REPO] fetchStaffList() called — laundryId=$laundryId');
      if (kDebugMode) {
        print('📋 Fetching staff list${laundryId != null ? ' for laundry #$laundryId' : ''}...');
      }

      dynamic response;
      if (laundryId != null) {
        debugPrint('🔵 [REPO] Query: staff WHERE laundry_id = $laundryId');
        response = await _client
            .from('staff')
            .select('*')
            .eq('laundry_id', laundryId)
            .order('created_at', ascending: false);
      } else {
        debugPrint('🟡 [REPO] Query: staff (NO laundry_id filter — fetching ALL staff)');
        response = await _client
            .from('staff')
            .select('*')
            .order('created_at', ascending: false);
      }

      final staffList = (response as List)
          .map((json) => StaffModel.fromJson(json as Map<String, dynamic>))
          .toList();

      debugPrint('🟢 [REPO] fetchStaffList returned ${staffList.length} staff');
      for (var i = 0; i < staffList.length; i++) {
        final s = staffList[i];
        debugPrint('🟢 [REPO]   [$i] id=${s.id}, name=${s.fullName}, laundry_id=${s.laundryId}');
      }
      if (kDebugMode) {
        print('✅ Found ${staffList.length} staff members');
      }
      return staffList;
    } catch (e, stackTrace) {
      if (kDebugMode) {
        print('🔴 [REPO] fetchStaffList error: $e');
        print('📍 [REPO] Stack trace:\n$stackTrace');
      }
      rethrow;
    }
  }

  /// Create a new staff member — via Edge Function (service_role bypass RLS)
  /// FIX: Tidak bisa insert langsung ke tabel `staff` karena RLS policy memblokir.
  /// Sekarang delegasikan ke edge function 'create-staff' yang menggunakan
  /// service_role key sehingga bisa bypass RLS, sekaligus membuat auth user
  /// (untuk link auth_user_id) dan hash PIN di server.
  Future<StaffModel> createStaff({
    required String fullName,
    required String username,
    required String pin,
    required int laundryId,
  }) async {
    debugPrint('➕ [REPO] createStaff() called — fullName=$fullName, username=$username, laundryId=$laundryId');
    try {
      if (laundryId <= 0) {
        debugPrint('🔴 [REPO] FATAL: laundryId is invalid ($laundryId)');
        throw Exception('laundry_id tidak valid. Pastikan laundry sudah dikonfigurasi sebelum menambahkan karyawan.');
      }

      debugPrint('🔵 [REPO] Creating staff via Edge Function...');
      final pinHash = PinHasher.hash(pin);

      final response = await _client.functions.invoke(
  'create-staff',
  body: {
    'full_name': fullName.trim(),
    'username': username.trim().toLowerCase(),
    'pin_hash': pinHash,
    'pin': pin.trim(), 
    
    
    // PIN asli — dipakai edge function sebagai
                        // password Supabase Auth. Dikirim lewat HTTPS
                        // ke edge function yang sudah terautentikasi
                        // (JWT owner), tidak disimpan sebagai plaintext
                        // di mana pun setelah ini.
  },
);

      final data = response.data;
      debugPrint('🔵 [REPO] create-staff response status=${response.status}, data=$data');

      if (response.status != 200 || data == null || data['success'] != true) {
        final errorMsg = (data is Map && data['error'] != null)
            ? data['error'].toString()
            : 'Gagal menambahkan karyawan';
        final details = (data is Map && data['details'] != null)
            ? ' (${data['details']})'
            : '';
        debugPrint('🔴 [REPO] createStaff failed: $errorMsg$details');
        throw Exception('$errorMsg$details');
      }

      final staffData = data['staff'] as Map<String, dynamic>;
      final staff = StaffModel.fromJson(staffData);

      debugPrint('🟢 [REPO] Staff created successfully — id=${staff.id}, name=${staff.fullName}, laundry_id=${staff.laundryId}');
      if (kDebugMode) {
        print('✅ Staff created successfully: ${staff.fullName} (id: ${staff.id})');
      }

      return staff;
    } on FunctionException catch (e, stackTrace) {
      debugPrint('🔴 [REPO] createStaff FunctionException: ${e.details}');
      if (kDebugMode) {
        print('📍 [REPO] Stack trace:\n$stackTrace');
      }
      throw Exception('Gagal menambahkan karyawan: ${e.details ?? e.toString()}');
    } catch (e, stackTrace) {
      debugPrint('🔴 [REPO] createStaff error: $e');
      if (kDebugMode) {
        print('🔴 [REPO] createStaff error: $e');
        print('📍 [REPO] Stack trace:\n$stackTrace');
      }
      rethrow;
    }
  }

  /// Update an existing staff member
  Future<StaffModel> updateStaff({
    required int id,
    String? fullName,
    String? username,
    String? pin,
  }) async {
    try {
      if (kDebugMode) {
        print('✏️ Updating staff #$id');
      }

      final updateData = <String, dynamic>{};
      if (fullName != null) updateData['full_name'] = fullName.trim();
      if (username != null) updateData['username'] = username.trim().toLowerCase();
      if (pin != null) updateData['pin_hash'] = PinHasher.hash(pin);

      final response = await _client
          .from('staff')
          .update(updateData)
          .eq('id', id)
          .select()
          .single();

      final staff = StaffModel.fromJson(response);
      if (kDebugMode) {
        print('✅ Staff updated successfully: ${staff.fullName}');
      }
      return staff;
    } catch (e, stackTrace) {
      if (kDebugMode) {
        print('🔴 [REPO] updateStaff error: $e');
        print('📍 [REPO] Stack trace:\n$stackTrace');
      }
      rethrow;
    }
  }

  /// Delete a staff member — via Edge Function (Admin API)
  /// FIX: Sebelumnya hanya hapus baris di tabel `staff`, auth user
  /// (username@laundry28.com) tertinggal selamanya di Supabase Auth
  /// sehingga username tidak bisa dipakai ulang. Sekarang delegasikan
  /// ke edge function 'delete-staff' yang menghapus auth user DAN baris
  /// staff sekaligus, dengan validasi bahwa caller adalah owner.
  Future<void> deleteStaff(int id) async {
    try {
      debugPrint('🗑️ [REPO] deleteStaff() called — id=$id');
      if (kDebugMode) {
        print('🗑️ Deleting staff #$id');
      }

      final response = await _client.functions.invoke(
        'delete-staff',
        body: {'staff_id': id},
      );

      final data = response.data;
      debugPrint('🔵 [REPO] delete-staff response status=${response.status}, data=$data');

      if (response.status != 200 || data == null || data['success'] != true) {
        final errorMsg = (data is Map && data['error'] != null)
            ? data['error'].toString()
            : 'Gagal menghapus karyawan';
        final details = (data is Map && data['details'] != null)
            ? ' (${data['details']})'
            : '';
        debugPrint('🔴 [REPO] deleteStaff failed: $errorMsg$details');
        throw Exception('$errorMsg$details');
      }

      debugPrint('🟢 [REPO] Staff #$id deleted successfully (auth + staff row)');
      if (kDebugMode) {
        print('✅ Staff #$id deleted successfully');
      }
    } on FunctionException catch (e, stackTrace) {
      debugPrint('🔴 [REPO] deleteStaff FunctionException: ${e.details}');
      if (kDebugMode) {
        print('📍 [REPO] Stack trace:\n$stackTrace');
      }
      throw Exception('Gagal menghapus karyawan: ${e.details ?? e.toString()}');
    } catch (e, stackTrace) {
      debugPrint('🔴 [REPO] deleteStaff error: $e');
      if (kDebugMode) {
        print('🔴 [REPO] deleteStaff error: $e');
        print('📍 [REPO] Stack trace:\n$stackTrace');
      }
      rethrow;
    }
  }

  /// Complete onboarding — create laundry and staff record for new owner
  Future<Map<String, dynamic>> completeOnboarding({
    required String laundryName,
    required String address,
    required String phone,
  }) async {
    try {
      final user = _client.auth.currentUser;
      if (user == null) {
        throw Exception('User belum login');
      }

      if (kDebugMode) {
        print('🔵 [ONBOARDING] Creating laundry for user: ${user.id}');
      }

      final existingStaff = await _client
          .from('staff')
          .select('*')
          .eq('auth_user_id', user.id)
          .maybeSingle();

      if (existingStaff != null) {
        final existingLaundryId = existingStaff['laundry_id'] as int?;
        if (existingLaundryId != null) {
          if (kDebugMode) {
            print('🔵 [ONBOARDING] User already onboarded with laundry_id=$existingLaundryId, redirecting...');
          }
          return {
            'laundryId': existingLaundryId,
            'staffId': existingStaff['id'] as int,
            'isNew': false,
          };
        }
        if (kDebugMode) {
          print('🔵 [ONBOARDING] Staff exists without laundry_id, updating existing record...');
        }
        final staffId = existingStaff['id'] as int;

        final laundryResponse = await _client.from('laundries').insert({
          'name': laundryName.trim(),
          'address': address.trim(),
          'phone': phone.trim(),
          'owner_id': staffId,
          'created_at': DateTime.now().toIso8601String(),
        }).select().single();

        final laundryId = laundryResponse['id'] as int;
        if (kDebugMode) {
          print('✅ [ONBOARDING] Laundry created: ID=$laundryId, Name=$laundryName');
        }

        await _client.from('staff').update({
          'laundry_id': laundryId,
        }).eq('id', staffId);

        if (kDebugMode) {
          print('✅ [ONBOARDING] Staff linked to laundry (updated existing record)');
        }

        return {
          'laundryId': laundryId,
          'staffId': staffId,
          'isNew': false,
        };
      }

      if (kDebugMode) {
        print('🔵 [ONBOARDING] New user — creating fresh staff record');
      }

      final userEmail = user.email?.toLowerCase() ?? '';
      final username = userEmail.split('@').first;

      try {
        final staffResponse = await _client.from('staff').insert({
          'email': userEmail,
          'username': username,
          'full_name': user.email?.split('@').first ?? 'Owner',
          'role': 'owner',
          'auth_user_id': user.id,
          'failed_pin_attempts': 0,
          'created_at': DateTime.now().toIso8601String(),
        }).select().single();

        final staffId = staffResponse['id'] as int;
        if (kDebugMode) {
          print('✅ [ONBOARDING] Staff record created for owner');
        }

        final laundryResponse = await _client.from('laundries').insert({
          'name': laundryName.trim(),
          'address': address.trim(),
          'phone': phone.trim(),
          'owner_id': staffId,
          'created_at': DateTime.now().toIso8601String(),
        }).select().single();

        final laundryId = laundryResponse['id'] as int;
        if (kDebugMode) {
          print('✅ [ONBOARDING] Laundry created: ID=$laundryId, Name=$laundryName');
        }

        await _client.from('staff').update({
          'laundry_id': laundryId,
        }).eq('id', staffId);

        if (kDebugMode) {
          print('✅ [ONBOARDING] Staff linked to laundry');
        }

        return {
          'laundryId': laundryId,
          'staffId': staffId,
          'isNew': true,
        };
      } on PostgrestException catch (e) {
        if (kDebugMode) {
          print('⚠️ [ONBOARDING] Duplicate email detected: ${e.message}');
          print('⚠️ [ONBOARDING] Error code: ${e.code}, Details: ${e.details}');
        }
        final isDuplicateEmail = (e.details?.toString().contains('staff_email_key') ?? false) ||
            (e.message.toLowerCase().contains('duplicate'));
        if (e.code == '23505' && isDuplicateEmail) {
          if (kDebugMode) {
            print('🔵 [ONBOARDING] Staff email sudah ada, cek apakah sudah punya laundry...');
          }
          final existingStaff = await _client
              .from('staff')
              .select('*')
              .eq('email', userEmail)
              .limit(1)
              .maybeSingle();

          if (existingStaff != null) {
            final existingStaffId = existingStaff['id'] as int;
            final existingLaundryId = existingStaff['laundry_id'] as int?;

            if (existingLaundryId != null) {
              if (kDebugMode) {
                print('🔵 [ONBOARDING] Staff sudah punya laundry (ID: $existingLaundryId), onboarding sudah selesai sebelumnya');
              }
              return {
                'laundryId': existingLaundryId,
                'staffId': existingStaffId,
                'isNew': false,
              };
            }

            if (kDebugMode) {
              print('🔵 [ONBOARDING] Staff ada tapi belum punya laundry, melanjutkan...');
            }

            final laundryResponse = await _client.from('laundries').insert({
              'name': laundryName.trim(),
              'address': address.trim(),
              'phone': phone.trim(),
              'owner_id': existingStaffId,
              'created_at': DateTime.now().toIso8601String(),
            }).select().single();

            final laundryId = laundryResponse['id'] as int;
            if (kDebugMode) {
              print('✅ [ONBOARDING] Laundry created: ID=$laundryId, Name=$laundryName');
            }

            await _client.from('staff').update({
              'laundry_id': laundryId,
            }).eq('id', existingStaffId);

            if (kDebugMode) {
              print('✅ [ONBOARDING] Staff linked to laundry');
            }

            return {
              'laundryId': laundryId,
              'staffId': existingStaffId,
              'isNew': false,
            };
          }
        }
        rethrow;
      }
    } catch (e, stackTrace) {
      if (kDebugMode) {
        print('🔴 [REPO] completeOnboarding error: $e');
        print('📍 [REPO] Stack trace:\n$stackTrace');
      }
      rethrow;
    }
  }
}