import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../../core/supabase/supabase_client.dart';
import '../models/laundry_model.dart';

class LaundryRepository {
  final SupabaseClient _client = SupabaseService.client;

  /// Helper: Get staff_id from auth user's email
  Future<int?> getStaffIdByEmail(String email) async {
    try {
      final response = await _client
          .from('staff')
          .select('id')
          .eq('email', email.trim().toLowerCase())
          .limit(1);

      if (response.isEmpty) return null;
      return response.first['id'] as int;
    } catch (e) {
      print('LAUNDRY getStaffIdByEmail error: $e');
      return null;
    }
  }

  /// Fetch laundry by owner's staff ID (integer)
  Future<LaundryModel?> fetchByStaffId(int staffId) async {
    try {
      final response = await _client
          .from('laundries')
          .select('*')
          .eq('owner_id', staffId)
          .limit(1);

      if (response.isEmpty) return null;
      return LaundryModel.fromJson(response.first);
    } on PostgrestException catch (e) {
      print('LAUNDRY Fetch by staffId error: ${e.message}');
      rethrow;
    }
  }

  /// Fetch laundry by laundry_id (for filtering)
  Future<LaundryModel?> fetchById(int id) async {
    try {
      final response = await _client
          .from('laundries')
          .select('*')
          .eq('id', id)
          .limit(1);

      if (response.isEmpty) return null;
      return LaundryModel.fromJson(response.first);
    } on PostgrestException catch (e) {
      print('LAUNDRY Fetch by ID error: ${e.message}');
      rethrow;
    }
  }

  /// Create new laundry
  Future<LaundryModel> createLaundry({
    required String name,
    String? address,
    String? phone,
    required int ownerId, // staff.id (INTEGER)
  }) async {
    try {
      final response = await _client.from('laundries').insert({
        'name': name,
        'address': address,
        'phone': phone,
        'owner_id': ownerId,
      }).select().single();

      return LaundryModel.fromJson(response);
    } on PostgrestException catch (e) {
      print('LAUNDRY Create error: ${e.message}');
      rethrow;
    }
  }

  /// Assign laundry to owner's staff record
  Future<void> assignLaundryToOwner(int staffId, int laundryId) async {
    try {
      await _client
          .from('staff')
          .update({'laundry_id': laundryId})
          .eq('id', staffId);
    } on PostgrestException catch (e) {
      print('LAUNDRY Assign error: ${e.message}');
      rethrow;
    }
  }

  /// Update laundry info
  Future<LaundryModel> updateLaundry({
    required int id,
    String? name,
    String? address,
    String? phone,
    String? logoUrl,
  }) async {
    try {
      final updateData = <String, dynamic>{};
      if (name != null) updateData['name'] = name;
      if (address != null) updateData['address'] = address;
      if (phone != null) updateData['phone'] = phone;
      if (logoUrl != null) updateData['logo_url'] = logoUrl;

      final response = await _client
          .from('laundries')
          .update(updateData)
          .eq('id', id)
          .select()
          .single();

      return LaundryModel.fromJson(response);
    } on PostgrestException catch (e) {
      print('LAUNDRY Update error: ${e.message}');
      rethrow;
    }
  }
}
