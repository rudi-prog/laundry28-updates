import 'package:flutter_bloc/flutter_bloc.dart';
import '../data/repositories/order_repository.dart';
import '../../../../shared/models/order_model.dart';

part 'dashboard_state.dart';

class DashboardCubit extends Cubit<DashboardState> {
  DashboardCubit() : super(DashboardInitial());

  final OrderRepository _orderRepository = OrderRepository();

  Future<void> fetchOrders() async {
    try {
      emit(DashboardLoading(state.orders ?? []));
      final orders = await _orderRepository.fetchOrders();
      emit(DashboardLoaded(orders, state.orders ?? []));
    } catch (e) {
      emit(DashboardError('Gagal memuat pesanan', state.orders ?? []));
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