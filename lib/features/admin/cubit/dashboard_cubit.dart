import 'package:flutter_bloc/flutter_bloc.dart';
import '../data/repositories/order_repository.dart';
import '../../../../shared/models/order_model.dart';

class DashboardCubit extends Cubit<List<OrderModel>> {
  DashboardCubit() : super([]);

  final OrderRepository _orderRepository = OrderRepository();

  Future<void> fetchOrders() async {
    try {
      final orders = await _orderRepository.fetchOrders();
      emit(orders);
    } catch (e) {
      emit([]);
    }
  }

  Future<void> updateOrderStatus(int orderId, String newStatus) async {
    try {
      await _orderRepository.updateOrderStatus(orderId, newStatus);
      await fetchOrders();
    } catch (e) {
      rethrow;
    }
  }
}