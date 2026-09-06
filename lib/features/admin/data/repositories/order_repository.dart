import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:flutter/foundation.dart';

import '../../../../core/supabase/supabase_client.dart';
import '../../../../shared/models/order_model.dart';

/// Repository untuk data pesanan - terintegrasi dengan Supabase
class OrderRepository {
  final SupabaseClient _client = SupabaseService.client;

  /// Pastikan session aktif sebelum operasi database
  void _ensureSessionActive() {
    final session = _client.auth.currentSession;
    if (session == null) {
      throw Exception('User belum login. Silakan login terlebih dahulu.');
    }
    // Cek apakah session expired
    final expiresAt = session.expiresAt;
    if (expiresAt != null && DateTime.now().millisecondsSinceEpoch >= expiresAt * 1000) {
      throw Exception('Session expired. Silakan login ulang.');
    }
  }

  /// Fetch all orders dari Supabase (dengan filter laundry_id)
  Future<List<OrderModel>> fetchOrders({int? laundryId}) async {
    try {
      // Check if tables exist by querying orders directly without joins
      late List<dynamic> response;
      try {
        response = await _client
            .from('orders')
            .select('*');
      } catch (e) {
        debugPrint('[ORDER] Orders table may not exist: $e');
        return [];
      }

      // Filter by laundry_id jika ada
      if (laundryId != null) {
        response = response.where((item) => item['laundry_id'] == laundryId).toList();
      }

      // Sort by created_at descending
      response.sort((a, b) {
        final aTime = a['created_at'] as String? ?? '';
        final bTime = b['created_at'] as String? ?? '';
        return bTime.compareTo(aTime);
      });

      return response
          .map<OrderModel>((json) => OrderModel.fromJson(json))
          .toList();
    } catch (e) {
      debugPrint('fetchOrders error: $e');
      return [];
    }
  }

  /// Fetch order by tracking code
  Future<OrderModel?> fetchOrderByTrackingCode(String trackingCode) async {
    try {
      debugPrint('[REPO] Querying Supabase for tracking: $trackingCode');
      final queryFuture = _client
          .from('orders')
          .select()
          .eq('tracking_code', trackingCode)
          .limit(1);

      final response = await queryFuture.timeout(
        const Duration(seconds: 10),
        onTimeout: () {
          debugPrint('[REPO] TIMEOUT after 10s for tracking: $trackingCode');
          throw Exception('Request timeout (10 detik). Periksa koneksi internet.');
        },
      );

      debugPrint('[REPO] Response received, length: ${response.length}');
      if (response.isEmpty) {
        debugPrint('[REPO] No order found for: $trackingCode');
        return null;
      }

      final order = OrderModel.fromJson(response.first);
      debugPrint('[REPO] Order found: ${order.trackingCode} - ${order.status}');
      return order;
    } catch (e) {
      debugPrint('[REPO] fetchOrderByTrackingCode error: $e');
      rethrow;
    }
  }

  /// Create new order di Supabase
  Future<OrderModel> createOrder(OrderModel order, {int? laundryId}) async {
    try {
      // Generate tracking code: LTY-XXX format
      final countResponse = await _client
          .from('orders')
          .select('id')
          .order('id', ascending: false)
          .limit(1);

      int nextId = 1;
      if (countResponse.isNotEmpty) {
        final lastId = (countResponse[0]['id'] as num).toInt();
        nextId = lastId + 1;
      }

      final trackingCode = 'LTY-${nextId.toString().padLeft(3, '0')}';

      final insertData = <String, dynamic>{
        'tracking_code': trackingCode,
        'customer_name': order.customerName,
        'customer_phone': order.customerPhone,
        'service_type': order.serviceType,
        'status': order.status,
        'estimated_time': order.estimatedTime?.toIso8601String(),
        'weight': order.weight,
        'total_price': order.totalPrice?.toInt(),
        'created_at': DateTime.now().toIso8601String(),
        if (laundryId != null) 'laundry_id': laundryId,
      };

      final response = await _client
          .from('orders')
          .insert(insertData)
          .select();

      if (response.isEmpty) {
        throw Exception('Failed to create order');
      }

      return OrderModel.fromJson(response.first);
    } catch (e) {
      debugPrint('createOrder error: $e');
      rethrow;
    }
  }

  /// Update order status di Supabase
  Future<OrderModel> updateOrderStatus(int orderId, String newStatus) async {
    try {
      // Pastikan session aktif sebelum update
      _ensureSessionActive();

      final response = await _client
          .from('orders')
          .update({
            'status': newStatus,
            'updated_at': DateTime.now().toIso8601String(),
          })
          .eq('id', orderId)
          .select();

      if (response.isEmpty) {
        throw Exception('Order not found');
      }

      return OrderModel.fromJson(response.first);
    } on PostgrestException catch (e) {
      debugPrint('PostgrestException: ${e.message} (Code: ${e.code})');
      rethrow;
    } catch (e) {
      debugPrint('updateOrderStatus error: $e');
      rethrow;
    }
  }
}
