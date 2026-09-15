import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../../core/supabase/supabase_client.dart';
import '../../../../core/utils/pin_hasher.dart';
import '../models/staff_model.dart';

class StaffRepository {
  final SupabaseClient _client = SupabaseService.client;

  Future<List<StaffModel>> fetchAllStaff() async {
    try {
      if (kDebugMode) {
        print('STAFF: Fetching all staff...');
      }
      final response = await _client
          .from('staff')
          .select('*')
          .order('created_at', ascending: false);
      return (response as List).map((json) => StaffModel.fromJson(json)).toList();
    } on PostgrestException catch (e) {
      if (kDebugMode) {
        print('STAFF Fetch error: ${e.message}');
      }
      rethrow;
    }
  }

  Future<StaffModel?> findByUsername(String username) async {
    try {
      final response = await _client
          .from('staff')
          .select('*')
          .eq('username', username.trim().toLowerCase())
          .limit(1);
      if (response.isNotEmpty) return StaffModel.fromJson(response.first);
      return null;
    } on PostgrestException catch (e) {
      if (kDebugMode) {
        print('STAFF Find by username error: ${e.message}');
      }
      rethrow;
    }
  }

  Future<StaffModel?> findByEmail(String email) async {
    try {
      final response = await _client
          .from('staff')
          .select('*')
          .eq('email', email.trim().toLowerCase())
          .limit(1);
      if (response.isNotEmpty) return StaffModel.fromJson(response.first);
      return null;
    } on PostgrestException catch (e) {
      if (kDebugMode) {
        print('STAFF Find by email error: ${e.message}');
      }
      rethrow;
    }
  }

  Future<StaffModel> createStaff({
    required String fullName,
    required String username,
    required String password,
    String email = '',
    required String pin,
    String? authUserId,
    required int laundryId,
  }) async {
    try {
      if (kDebugMode) {
        print('STAFF: Creating new staff: $username');
      }

      // Defensive: laundryId must never be null
      if (laundryId <= 0) {
        throw Exception('laundry_id tidak valid. Pastikan laundry sudah dikonfigurasi sebelum menambahkan karyawan.');
      }

      // Retry mechanism for username collision
      final baseUsername = username.trim().toLowerCase();
      String finalUsername = baseUsername;
      int suffix = 1;
      while ((await findByUsername(finalUsername)) != null) {
        finalUsername = '$baseUsername$suffix';
        suffix++;
        if (kDebugMode) {
          print('⚠️ [STAFF] Username "$finalUsername" sudah digunakan, mencoba alternatif...');
        }
      }

      final authResponse = await _client.auth.signUp(
        email: email.isNotEmpty ? email : '$finalUsername@laundry28.com',
        password: password,
      );
      if (authResponse.user == null) throw Exception('Gagal membuat akun karyawan');

      // Hash PIN (bcrypt auto-generate salt, tidak perlu pin_salt terpisah)
      final pinHash = PinHasher.hash(pin);
      if (kDebugMode) {
        print('STAFF: PIN hashed with bcrypt for: $finalUsername');
      }

      // FIX #7: Use authUserId from signup response for RLS policy compliance
      final actualAuthUserId = authUserId ?? authResponse.user?.id;

      final insertData = <String, dynamic>{
        'email': email.isNotEmpty ? email : '$finalUsername@laundry28.com',
        'username': finalUsername,
        'full_name': fullName.trim(),
        'pin_hash': pinHash,
        'role': 'employee',
        'auth_user_id': actualAuthUserId,
        'failed_pin_attempts': 0,
        'laundry_id': laundryId,
      };

      final newStaff = await _client.from('staff').insert(insertData).select().single();

      if (kDebugMode) {
        print('STAFF: Created: $fullName ($username)');
      }
      return StaffModel.fromJson(newStaff);
    } on PostgrestException catch (e) {
      if (kDebugMode) {
        print('STAFF Create error: ${e.message}');
      }
      rethrow;
    }
  }

  Future<StaffModel> updateStaff({
    required int id,
    String? fullName,
    String? username,
    String? password,
    String? pin,
  }) async {
    try {
      if (kDebugMode) {
        print('STAFF: Updating staff ID: $id');
      }
      final updateData = <String, dynamic>{};
      if (fullName != null) updateData['full_name'] = fullName.trim();
      if (username != null) updateData['username'] = username.trim().toLowerCase();
      // Hash PIN baru jika ada (bcrypt auto-generate salt)
      if (pin != null && pin.isNotEmpty) {
        final pinHash = PinHasher.hash(pin);
        updateData['pin_hash'] = pinHash;
        updateData['failed_pin_attempts'] = 0;
        if (kDebugMode) {
          print('STAFF: PIN hashed with bcrypt and updated for staff ID: $id');
        }
      }

      if (password != null && password.isNotEmpty) {
        try {
          await _client.auth.admin.updateUserById(
            id.toString(),
            attributes: AdminUserAttributes(password: password),
          );
        } catch (e) {
          if (kDebugMode) {
            print('⚠️ Could not update auth password: $e');
          }
        }
      }

      final response = await _client.from('staff').update(updateData).eq('id', id).select().single();
      if (kDebugMode) {
        print('STAFF: Updated');
      }
      return StaffModel.fromJson(response);
    } on PostgrestException catch (e) {
      if (kDebugMode) {
        print('STAFF Update error: ${e.message}');
      }
      rethrow;
    }
  }

  Future<void> deleteStaff(int id) async {
    try {
      if (kDebugMode) {
        print('STAFF: Deleting staff ID: $id via edge function');
      }

      // FIX: Use Edge Function 'delete-staff' instead of direct DELETE.
      // RLS blocks direct DELETE from client — no policy allows it.
      // Edge Function runs with service_role, bypassing RLS and
      // deleting both the staff row AND the auth user cleanly.
      final response = await _client.functions.invoke(
        'delete-staff',
        body: {'staff_id': id},
      );

      final data = response.data;
      if (kDebugMode) {
        print('STAFF: delete-staff response status=${response.status}, data=$data');
      }

      if (response.status != 200 || data == null || data['success'] != true) {
        final errorMsg = (data is Map && data['error'] != null)
            ? data['error'].toString()
            : 'Gagal menghapus karyawan';
        final details = (data is Map && data['details'] != null)
            ? ' (${data['details']})'
            : '';
        throw Exception('$errorMsg$details');
      }

      if (kDebugMode) {
        print('STAFF: Deleted ID: $id (auth + staff row)');
      }
    } on PostgrestException catch (e) {
      if (kDebugMode) {
        print('STAFF Delete error: ${e.message}');
      }
      rethrow;
    } catch (e) {
      if (kDebugMode) {
        print('STAFF Delete error: $e');
      }
      rethrow;
    }
  }

  /// Reset failed PIN attempts setelah berhasil login
  Future<void> resetFailedAttempts(int staffId) async {
    try {
      await _client.from('staff').update({
        'failed_pin_attempts': 0,
        'locked_until': null,
      }).eq('id', staffId);
      if (kDebugMode) {
        print('STAFF: Reset failed attempts for ID: $staffId');
      }
    } on PostgrestException catch (e) {
      if (kDebugMode) {
        print('STAFF Reset failed attempts error: ${e.message}');
      }
    }
  }

  /// Catat percobaan PIN gagal dan lock jika melebihi batas
  Future<bool> recordFailedPinAttempt(int staffId) async {
    try {
      // Get current staff data
      final staffResponse = await _client
          .from('staff')
          .select('failed_pin_attempts, locked_until')
          .eq('id', staffId)
          .single();

      final currentAttempts = (staffResponse as Map<String, dynamic>)['failed_pin_attempts'] as int? ?? 0;
      final lockedUntil = staffResponse['locked_until'] != null
          ? DateTime.parse(staffResponse['locked_until'] as String)
          : null;

      // If already locked, don't increment
      if (lockedUntil != null && DateTime.now().isBefore(lockedUntil)) {
        return true; // Still locked
      }

      final newAttempts = currentAttempts + 1;
      final maxAttempts = 5;
      final lockDuration = Duration(minutes: 5);
      DateTime? newLockedUntil;

      if (newAttempts >= maxAttempts) {
        newLockedUntil = DateTime.now().add(lockDuration);
        if (kDebugMode) {
          print('STAFF: Account locked for $lockDuration after $newAttempts failed attempts');
        }
      }

      await _client.from('staff').update({
        'failed_pin_attempts': newAttempts,
        'locked_until': newLockedUntil?.toIso8601String(),
      }).eq('id', staffId);

      return newLockedUntil != null;
    } on PostgrestException catch (e) {
      if (kDebugMode) {
        print('STAFF Record failed attempt error: ${e.message}');
      }
      return false;
    }
  }

  static String generateUsername(String fullName) {
    final base = fullName.toLowerCase().replaceAll(RegExp(r'[^a-z0-9]'), '').replaceAll(' ', '');
    final random = DateTime.now().millisecondsSinceEpoch % 1000;
    return '${base}${random}';
  }
}
