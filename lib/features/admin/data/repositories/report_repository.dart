import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:flutter/foundation.dart';

import '../../../../core/supabase/supabase_client.dart';

/// Repository untuk data laporan
class ReportRepository {
  final SupabaseClient _client = SupabaseService.client;

  /// Fetch orders yang sudah selesai dalam periode tertentu
  /// FIX #6: Move laundry_id filtering to server-side query
  Future<List<Map<String, dynamic>>> fetchCompletedOrders({
    required DateTime startDate,
    required DateTime endDate,
    int? laundryId,
  }) async {
    try {
      var query = _client
          .from('orders')
          .select()
          .eq('status', 'Selesai')
          .gte('created_at', startDate.toIso8601String())
          .lte('created_at', endDate.toIso8601String());

      if (laundryId != null) {
        query = query.eq('laundry_id', laundryId);
      }

      final response = await query.order('created_at', ascending: false);

      if (laundryId != null) {
        return (response as List)
            .where((item) => item['laundry_id'] == laundryId)
            .cast<Map<String, dynamic>>()
            .toList();
      }

      return response.cast<Map<String, dynamic>>();
    } catch (e) {
      debugPrint('[REPORT] fetchCompletedOrders error: $e');
      return [];
    }
  }

  /// Fetch semua orders dalam periode tertentu
  /// FIX #6: Move laundry_id filtering to server-side query
  Future<List<Map<String, dynamic>>> fetchAllOrdersInPeriod({
    required DateTime startDate,
    required DateTime endDate,
    int? laundryId,
  }) async {
    try {
      var query = _client
          .from('orders')
          .select()
          .gte('created_at', startDate.toIso8601String())
          .lte('created_at', endDate.toIso8601String());

      if (laundryId != null) {
        query = query.eq('laundry_id', laundryId);
      }

      final response = await query.order('created_at', ascending: false);

      if (laundryId != null) {
        return (response as List)
            .where((item) => item['laundry_id'] == laundryId)
            .cast<Map<String, dynamic>>()
            .toList();
      }

      return response.cast<Map<String, dynamic>>();
    } catch (e) {
      debugPrint('[REPORT] fetchAllOrdersInPeriod error: $e');
      return [];
    }
  }

  /// Fetch orders berdasarkan status dalam periode tertentu
  /// FIX #6: Move laundry_id filtering to server-side query
  Future<List<Map<String, dynamic>>> fetchOrdersByStatus({
    required DateTime startDate,
    required DateTime endDate,
    required String status,
    int? laundryId,
  }) async {
    try {
      var query = _client
          .from('orders')
          .select()
          .eq('status', status)
          .gte('created_at', startDate.toIso8601String())
          .lte('created_at', endDate.toIso8601String());

      if (laundryId != null) {
        query = query.eq('laundry_id', laundryId);
      }

      final response = await query.order('created_at', ascending: false);

      if (laundryId != null) {
        return (response as List)
            .where((item) => item['laundry_id'] == laundryId)
            .cast<Map<String, dynamic>>()
            .toList();
      }

      return response.cast<Map<String, dynamic>>();
    } catch (e) {
      debugPrint('[REPORT] fetchOrdersByStatus error: $e');
      return [];
    }
  }

  /// Fetch orders hari ini
  Future<List<Map<String, dynamic>>> fetchTodayOrders({int? laundryId}) async {
    final now = DateTime.now();
    final startOfDay = DateTime(now.year, now.month, now.day);
    final endOfDay = startOfDay.add(const Duration(days: 1));
    return fetchAllOrdersInPeriod(
      startDate: startOfDay,
      endDate: endOfDay,
      laundryId: laundryId,
    );
  }

  /// Fetch orders yang sudah selesai hari ini
  Future<List<Map<String, dynamic>>> fetchTodayCompletedOrders({int? laundryId}) async {
    final now = DateTime.now();
    final startOfDay = DateTime(now.year, now.month, now.day);
    final endOfDay = startOfDay.add(const Duration(days: 1));
    return fetchCompletedOrders(
      startDate: startOfDay,
      endDate: endOfDay,
      laundryId: laundryId,
    );
  }
}
