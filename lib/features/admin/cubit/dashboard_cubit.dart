import 'package:flutter_bloc/flutter_bloc.dart';
import '../data/repositories/order_repository.dart';
import '../../../../shared/models/order_model.dart';

part 'dashboard_state.dart';

class DashboardCubit extends Cubit<DashboardState> {
  DashboardCubit() : super(DashboardInitial());

  final OrderRepository _orderRepository = OrderRepository();

  Future<void> fetchOrders({int? laundryId}) async {
    try {
      emit(DashboardLoading(state.orders ?? []));
      final orders = await _orderRepository.fetchOrders(laundryId: laundryId);
      if (orders.isEmpty) {
        emit(DashboardEmpty(state.orders ?? []));
      } else {
        emit(DashboardLoaded(orders, state.orders ?? []));
      }
    } catch (e) {
      print('❌ [DASHBOARD] Error fetching orders: $e');
      emit(DashboardError('Gagal memuat pesanan', state.orders ?? []));
    }
  }

  Future<void> updateOrderStatus(int orderId, String newStatus, {int? laundryId}) async {
    try {
      await _orderRepository.updateOrderStatus(orderId, newStatus, laundryId: laundryId);
      await fetchOrders(laundryId: laundryId);
    } catch (e) {
      rethrow;
    }
  }
}