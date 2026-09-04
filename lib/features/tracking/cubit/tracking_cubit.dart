import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter/foundation.dart';
import '../../admin/data/repositories/order_repository.dart';
import '../../../../shared/models/order_model.dart';

part 'tracking_state.dart';

class TrackingCubit extends Cubit<TrackingState> {
  TrackingCubit() : super(TrackingInitial());

  final OrderRepository _orderRepository = OrderRepository();

  Future<void> fetchOrder(String trackingCode) async {
    if (trackingCode.isEmpty) {
      emit(TrackingError('Kode tracking tidak boleh kosong'));
      return;
    }
    
    debugPrint('[TRACKING] Fetching order: $trackingCode');
    emit(TrackingLoading());
    try {
      final order = await _orderRepository.fetchOrderByTrackingCode(trackingCode);
      debugPrint('[TRACKING] Order result: ${order != null ? "Found" : "Not found"}');
      if (order != null) {
        emit(TrackingLoaded(order));
      } else {
        emit(TrackingError('Pesanan dengan kode tersebut tidak ditemukan'));
      }
    } catch (e, stackTrace) {
      debugPrint('[TRACKING] Error: $e');
      debugPrint('[TRACKING] Stack: $stackTrace');
      emit(TrackingError('Terjadi kesalahan saat mengambil data'));
    }
  }
}
