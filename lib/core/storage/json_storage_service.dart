import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';

class JsonStorageService {
  static const String _ordersKey = 'laundry28_orders';
  static const String _staffKey = 'laundry28_staff';
  static const String _nextOrderIdKey = 'laundry28_next_order_id';
  
  static SharedPreferences? _prefs;
  
  static Future<void> init() async {
    _prefs = await SharedPreferences.getInstance();
    _initializeDefaults();
  }
  
  static void _initializeDefaults() {
    final staffData = _prefs?.getString(_staffKey);
    if (staffData == null || staffData.isEmpty) {
      final defaultStaff = [
        {
          'id': 1,
          'username': 'admin',
          'password': 'admin123',
          'full_name': 'Administrator',
          'created_at': DateTime.now().toIso8601String(),
        }
      ];
      _prefs?.setString(_staffKey, jsonEncode(defaultStaff));
    }
    
    final ordersData = _prefs?.getString(_ordersKey);
    if (ordersData == null || ordersData.isEmpty) {
      _prefs?.setString(_ordersKey, jsonEncode([]));
    }
    
    final nextId = _prefs?.getInt(_nextOrderIdKey);
    if (nextId == null) {
      _prefs?.setInt(_nextOrderIdKey, 1);
    }
  }
  
  Future<Map<String, dynamic>?> login(String username, String password) async {
    final staffData = _prefs?.getString(_staffKey);
    if (staffData == null) return null;
    
    final List<dynamic> staffList = jsonDecode(staffData);
    for (var staff in staffList) {
      if (staff['username'] == username && staff['password'] == password) {
        return staff;
      }
    }
    return null;
  }
  
  Future<List<Map<String, dynamic>>> fetchOrders() async {
    final ordersData = _prefs?.getString(_ordersKey);
    if (ordersData == null || ordersData.isEmpty) return [];
    
    final List<dynamic> ordersList = jsonDecode(ordersData);
    ordersList.sort((a, b) {
      final dateA = DateTime.parse(a['created_at']);
      final dateB = DateTime.parse(b['created_at']);
      return dateB.compareTo(dateA);
    });
    return ordersList.cast<Map<String, dynamic>>();
  }
  
  Future<Map<String, dynamic>?> fetchOrderByTrackingCode(String trackingCode) async {
    final orders = await fetchOrders();
    for (var order in orders) {
      if (order['tracking_code'] == trackingCode) {
        return order;
      }
    }
    return null;
  }
  
  Future<Map<String, dynamic>> createOrder(Map<String, dynamic> order) async {
    final ordersData = _prefs?.getString(_ordersKey) ?? '[]';
    final List<dynamic> ordersList = jsonDecode(ordersData);
    
    int nextId = _prefs?.getInt(_nextOrderIdKey) ?? 1;
    final trackingCode = 'LTY-${nextId.toString().padLeft(3, '0')}';
    
    final newOrder = {
      'id': nextId,
      'tracking_code': trackingCode,
      'customer_name': order['customer_name'],
      'customer_phone': order['customer_phone'],
      'service_type': order['service_type'],
      'status': order['status'] ?? 'Diterima',
      'estimated_time': order['estimated_time'],
      'weight': order['weight'] ?? 1.0,
      'total_price': order['total_price'] ?? 0,
      'created_at': DateTime.now().toIso8601String(),
      'updated_at': null,
    };
    
    ordersList.add(newOrder);
    _prefs?.setString(_ordersKey, jsonEncode(ordersList));
    _prefs?.setInt(_nextOrderIdKey, nextId + 1);
    
    return newOrder;
  }
  
  Future<Map<String, dynamic>> updateOrderStatus(int orderId, String newStatus) async {
    final ordersData = _prefs?.getString(_ordersKey) ?? '[]';
    final List<dynamic> ordersList = jsonDecode(ordersData);
    
    bool found = false;
    for (int i = 0; i < ordersList.length; i++) {
      if (ordersList[i]['id'] == orderId) {
        ordersList[i]['status'] = newStatus;
        ordersList[i]['updated_at'] = DateTime.now().toIso8601String();
        found = true;
        break;
      }
    }
    
    if (!found) {
      throw Exception('Order not found with id: $orderId');
    }
    
    _prefs?.setString(_ordersKey, jsonEncode(ordersList));
    return ordersList.firstWhere((o) => o['id'] == orderId);
  }
}
