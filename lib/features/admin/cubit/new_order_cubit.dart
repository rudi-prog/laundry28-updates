import 'package:flutter_bloc/flutter_bloc.dart';
import '../data/repositories/order_repository.dart';
import '../../../../shared/models/order_model.dart';

part 'new_order_state.dart';

class NewOrderCubit extends Cubit<NewOrderState> {
  NewOrderCubit() : super(NewOrderInitial());

  final OrderRepository _orderRepository = OrderRepository();

  Future<void> saveOrder({
    required String customerName,
    required String customerPhone,
    required String serviceType,
    required double weight,
    DateTime? estimatedTime,
  }) async {
    emit(NewOrderLoading());
    try {
      final order = OrderModel(
        trackingCode: '',
        customerName: customerName,
        customerPhone: customerPhone,
        serviceType: serviceType,
        status: 'Diterima',
        createdAt: DateTime.now(),
        weight: weight,
        totalPrice: _calculatePrice(serviceType, weight),
        estimatedTime: estimatedTime,
      );
      await _orderRepository.createOrder(order);
      emit(NewOrderSuccess());
    } catch (e) {
      String errorMsg = 'Gagal membuat pesanan';
      
      // Extract meaningful error messages
      final errorStr = e.toString().toLowerCase();
      if (errorStr.contains('duplicate') || errorStr.contains('unique')) {
        errorMsg = 'Pesanan dengan data serupa sudah ada';
      } else if (errorStr.contains('session') || errorStr.contains('login')) {
        errorMsg = 'Sesi login habis. Silakan login ulang.';
      } else if (errorStr.contains('policy') || errorStr.contains('authorize')) {
        errorMsg = 'Akses ditolak. Pastikan Anda sudah login sebagai admin.';
      } else if (errorStr.contains('connect') || errorStr.contains('timeout')) {
        errorMsg = 'Gagal terhubung ke server. Periksa koneksi internet.';
      } else if (e.toString().contains('Postgrest')) {
        errorMsg = 'Error database: ${e.toString().split(':').last.trim()}';
      } else {
        errorMsg = 'Gagal membuat pesanan: $e';
      }
      
      emit(NewOrderError(errorMsg));
    }
  }

  double _calculatePrice(String serviceType, double weight) {
    final basePrice = _getBasePrice(serviceType);
    return basePrice * weight;
  }

  double _getBasePrice(String serviceType) {
    switch (serviceType) {
      case 'Cuci Komplit': return 7000;
      case 'Cuci + Setrika': return 6000;
      case 'Setrika Saja': return 5000;
      case 'Cuci Saja': return 4000;
      case 'Cuci Bedcover': return 35000;
      case 'Cuci Sepatu': return 50000;
      default: return 5000;
    }
  }
}
