import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../../core/supabase/supabase_client.dart';
import '../models/service_model.dart';

class ServiceRepository {
  final SupabaseClient _client = SupabaseService.client;

  /// Fetch semua layanan aktif untuk laundry tertentu
  Future<List<ServiceModel>> fetchServicesByLaundryId(int laundryId) async {
    try {
      final response = await _client
          .from('laundry_services')
          .select('*')
          .eq('laundry_id', laundryId)
          .eq('is_active', true)
          .order('sort_order', ascending: true);

      return (response as List)
          .map((json) => ServiceModel.fromJson(json))
          .toList();
    } on PostgrestException catch (e) {
      print('SERVICE Fetch error: ${e.message}');
      rethrow;
    }
  }

  /// Fetch semua layanan (termasuk non-aktif) untuk laundry tertentu
  Future<List<ServiceModel>> fetchAllServicesByLaundryId(int laundryId) async {
    try {
      final response = await _client
          .from('laundry_services')
          .select('*')
          .eq('laundry_id', laundryId)
          .order('sort_order', ascending: true);

      return (response as List)
          .map((json) => ServiceModel.fromJson(json))
          .toList();
    } on PostgrestException catch (e) {
      print('SERVICE Fetch all error: ${e.message}');
      rethrow;
    }
  }

  /// Fetch layanan berdasarkan nama untuk laundry tertentu
  Future<ServiceModel?> fetchServiceByName(int laundryId, String name) async {
    try {
      final response = await _client
          .from('laundry_services')
          .select('*')
          .eq('laundry_id', laundryId)
          .eq('name', name)
          .limit(1);

      if (response.isEmpty) return null;
      return ServiceModel.fromJson(response.first);
    } on PostgrestException catch (e) {
      print('SERVICE Fetch by name error: ${e.message}');
      return null;
    }
  }

  /// Create layanan baru
  Future<ServiceModel> createService({
    required int laundryId,
    required String name,
    required double price,
    int durationHours = 1,
    int sortOrder = 0,
  }) async {
    try {
      final response = await _client.from('laundry_services').insert({
        'laundry_id': laundryId,
        'name': name,
        'price': price,
        'duration_hours': durationHours,
        'sort_order': sortOrder,
        'is_active': true,
      }).select().single();

      return ServiceModel.fromJson(response);
    } on PostgrestException catch (e) {
      print('SERVICE Create error: ${e.message}');
      rethrow;
    }
  }

  /// Update layanan
  /// FIX #8: Add laundry_id filter for RLS compliance
  Future<ServiceModel> updateService({
    required int id,
    String? name,
    double? price,
    int? durationHours,
    int? sortOrder,
    bool? isActive,
    int? laundryId,
  }) async {
    try {
      final updateData = <String, dynamic>{};
      if (name != null) updateData['name'] = name;
      if (price != null) updateData['price'] = price;
      if (durationHours != null) updateData['duration_hours'] = durationHours;
      if (sortOrder != null) updateData['sort_order'] = sortOrder;
      if (isActive != null) updateData['is_active'] = isActive;

      var query = _client
          .from('laundry_services')
          .update(updateData)
          .eq('id', id);

      // Server-side laundry_id filter for RLS compliance
      if (laundryId != null) {
        query = query.eq('laundry_id', laundryId);
      }

      final response = await query.select().single();

      return ServiceModel.fromJson(response);
    } on PostgrestException catch (e) {
      print('SERVICE Update error: ${e.message}');
      rethrow;
    }
  }

  /// Soft delete (set is_active = false)
  /// FIX #8: Pass laundry_id for RLS compliance
  Future<ServiceModel> deactivateService(int id, {int? laundryId}) async {
    return updateService(id: id, isActive: false, laundryId: laundryId);
  }

  /// Hard delete layanan
  /// FIX #8: Add laundry_id filter for RLS compliance
  Future<void> deleteService(int id, {int? laundryId}) async {
    try {
      var query = _client.from('laundry_services').delete().eq('id', id);

      // Server-side laundry_id filter for RLS compliance
      if (laundryId != null) {
        query = query.eq('laundry_id', laundryId);
      }

      await query;
    } on PostgrestException catch (e) {
      print('SERVICE Delete error: ${e.message}');
      rethrow;
    }
  }

  /// Get max sort_order untuk laundry tertentu
  Future<int> getMaxSortOrder(int laundryId) async {
    try {
      final response = await _client
          .from('laundry_services')
          .select('sort_order')
          .eq('laundry_id', laundryId)
          .order('sort_order', ascending: false)
          .limit(1);

      if (response.isEmpty) return 0;
      return (response.first['sort_order'] as int?) ?? 0;
    } catch (e) {
      print('SERVICE Max sort_order error: $e');
      return 0;
    }
  }
}
