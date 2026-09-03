import 'package:supabase_flutter/supabase_flutter.dart';

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

  /// Fetch all orders dari Supabase
  Future<List<OrderModel>> fetchOrders() async {
    try {
      final response = await _client
          .from('orders')
          .select()
          .order('created_at', ascending: false);

      return response
          .map<OrderModel>((json) => OrderModel.fromJson(json))
          .toList();
    } catch (e) {
      print('fetchOrders error: $e');
      return [];
    }
  }

  /// Fetch order by tracking code
  Future<OrderModel?> fetchOrderByTrackingCode(String trackingCode) async {
    try {
      final response = await _client
          .from('orders')
          .select()
          .eq('tracking_code', trackingCode)
          .maybeSingle();

      if (response == null) return null;
      return OrderModel.fromJson(response);
    } catch (e) {
      print('fetchOrderByTrackingCode error: $e');
      return null;
    }
  }

  /// Create new order di Supabase
  Future<OrderModel> createOrder(OrderModel order) async {
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

      final response = await _client
          .from('orders')
          .insert({
            'tracking_code': trackingCode,
            'customer_name': order.customerName,
            'customer_phone': order.customerPhone,
            'service_type': order.serviceType,
            'status': order.status,
            'estimated_time': order.estimatedTime?.toIso8601String(),
            'weight': order.weight,
            'total_price': order.totalPrice?.toInt(),
            'created_at': DateTime.now().toIso8601String(),
          })
          .select()
          .maybeSingle();

      if (response == null) {
        throw Exception('Failed to create order');
      }

      return OrderModel.fromJson(response);
    } catch (e) {
      print('createOrder error: $e');
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
          .select()
          .maybeSingle();

      if (response == null) {
        throw Exception('Order not found');
      }

      return OrderModel.fromJson(response);
    } on PostgrestException catch (e) {
      print('PostgrestException: ${e.message} (Code: ${e.code})');
      rethrow;
    } catch (e) {
      print('updateOrderStatus error: $e');
      rethrow;
    }
  }
}
