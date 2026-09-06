import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../../core/supabase/supabase_client.dart';
import '../models/staff_model.dart';

class StaffRepository {
  final SupabaseClient _client = SupabaseService.client;

  Future<List<StaffModel>> fetchAllStaff() async {
    try {
      print('STAFF: Fetching all staff...');
      final response = await _client
          .from('staff')
          .select('*')
          .order('created_at', ascending: false);
      return (response as List).map((json) => StaffModel.fromJson(json)).toList();
    } on PostgrestException catch (e) {
      print('STAFF Fetch error: ${e.message}');
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
      print('STAFF Find by username error: ${e.message}');
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
      print('STAFF Find by email error: ${e.message}');
      rethrow;
    }
  }

  Future<StaffModel> createStaff({
    required String fullName,
    required String username,
    required String password,
    String email = '',
    String? pin,
  }) async {
    try {
      print('STAFF: Creating new staff: $username');
      final existing = await findByUsername(username);
      if (existing != null) throw Exception('Username sudah digunakan');

      final authResponse = await _client.auth.signUp(
        email: email.isNotEmpty ? email : '$username@laundry28.local',
        password: password,
      );
      if (authResponse.user == null) throw Exception('Gagal membuat akun karyawan');

      final newStaff = await _client.from('staff').insert({
        'email': email.isNotEmpty ? email : '$username@laundry28.local',
        'username': username.trim().toLowerCase(),
        'full_name': fullName.trim(),
        'pin': pin,
        'role': 'employee',
      }).select().single();

      print('STAFF: Created: $fullName ($username)');
      return StaffModel.fromJson(newStaff);
    } on PostgrestException catch (e) {
      print('STAFF Create error: ${e.message}');
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
      print('STAFF: Updating staff ID: $id');
      final updateData = <String, dynamic>{};
      if (fullName != null) updateData['full_name'] = fullName.trim();
      if (username != null) updateData['username'] = username.trim().toLowerCase();
      if (pin != null) updateData['pin'] = pin;

      if (password != null && password.isNotEmpty) {
        try {
          await _client.auth.admin.updateUserById(
            id.toString(),
            attributes: AdminUserAttributes(password: password),
          );
        } catch (e) {
          print('⚠️ Could not update auth password: $e');
        }
      }

      final response = await _client.from('staff').update(updateData).eq('id', id).select().single();
      print('STAFF: Updated');
      return StaffModel.fromJson(response);
    } on PostgrestException catch (e) {
      print('STAFF Update error: ${e.message}');
      rethrow;
    }
  }

  Future<void> deleteStaff(int id) async {
    try {
      print('STAFF: Deleting staff ID: $id');
      await _client.from('staff').delete().eq('id', id);
      print('STAFF: Deleted ID: $id');
    } on PostgrestException catch (e) {
      print('STAFF Delete error: ${e.message}');
      rethrow;
    }
  }

  static String generateUsername(String fullName) {
    final base = fullName.toLowerCase().replaceAll(RegExp(r'[^a-z0-9]'), '').replaceAll(' ', '');
    final random = DateTime.now().millisecondsSinceEpoch % 1000;
    return '${base}${random}';
  }
}
