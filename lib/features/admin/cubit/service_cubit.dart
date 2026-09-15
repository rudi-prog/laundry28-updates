import 'package:flutter_bloc/flutter_bloc.dart';
import '../data/repositories/service_repository.dart';
import '../data/models/service_model.dart';

part 'service_state.dart';

class ServiceCubit extends Cubit<ServiceState> {
  ServiceCubit() : super(ServiceInitial());

  final ServiceRepository _repository = ServiceRepository();

  /// Fetch semua layanan aktif untuk laundry tertentu
  Future<void> fetchServices(int laundryId) async {
    emit(ServiceLoading());
    try {
      final services = await _repository.fetchServicesByLaundryId(laundryId);
      emit(ServiceLoaded(services));
    } catch (e) {
      print('SERVICE Cubit Fetch error: $e');
      emit(ServiceError('Gagal memuat layanan: $e'));
    }
  }

  /// Fetch semua layanan (termasuk non-aktif)
  Future<void> fetchAllServices(int laundryId) async {
    emit(ServiceLoading());
    try {
      final services = await _repository.fetchAllServicesByLaundryId(laundryId);
      emit(ServiceLoaded(services));
    } catch (e) {
      print('SERVICE Cubit Fetch all error: $e');
      emit(ServiceError('Gagal memuat layanan: $e'));
    }
  }

  /// Create layanan baru
  Future<bool> createService({
    required int laundryId,
    required String name,
    required double price,
    int durationHours = 1,
  }) async {
    try {
      final maxOrder = await _repository.getMaxSortOrder(laundryId);
      final _ = await _repository.createService(
        laundryId: laundryId,
        name: name,
        price: price,
        durationHours: durationHours,
        sortOrder: maxOrder + 1,
      );
      
      // Refresh list
      final services = await _repository.fetchServicesByLaundryId(laundryId);
      emit(ServiceLoaded(services));
      return true;
    } catch (e) {
      print('SERVICE Cubit Create error: $e');
      emit(ServiceError('Gagal menambah layanan: $e'));
      return false;
    }
  }

  /// Update layanan
  Future<bool> updateService({
    required int id,
    required int laundryId,
    String? name,
    double? price,
    int? durationHours,
  }) async {
    try {
      await _repository.updateService(
        id: id,
        name: name,
        price: price,
        durationHours: durationHours,
        laundryId: laundryId,
      );
      
      // Refresh list
      final services = await _repository.fetchServicesByLaundryId(laundryId);
      emit(ServiceLoaded(services));
      return true;
    } catch (e) {
      print('SERVICE Cubit Update error: $e');
      emit(ServiceError('Gagal mengubah layanan: $e'));
      return false;
    }
  }

  /// Toggle active/inactive
  Future<bool> toggleService(int id, int laundryId) async {
    try {
      final service = await _repository.fetchAllServicesByLaundryId(laundryId);
      final current = service.firstWhere((s) => s.id == id);
      
      await _repository.updateService(
        id: id,
        isActive: !current.isActive,
        laundryId: laundryId,
      );
      
      final updated = await _repository.fetchServicesByLaundryId(laundryId);
      emit(ServiceLoaded(updated));
      return true;
    } catch (e) {
      print('SERVICE Cubit Toggle error: $e');
      emit(ServiceError('Gagal mengubah status layanan: $e'));
      return false;
    }
  }

  /// Delete layanan
  Future<bool> deleteService(int id, int laundryId) async {
    try {
      await _repository.deleteService(id, laundryId: laundryId);
      
      // Refresh list
      final services = await _repository.fetchServicesByLaundryId(laundryId);
      emit(ServiceLoaded(services));
      return true;
    } catch (e) {
      print('SERVICE Cubit Delete error: $e');
      emit(ServiceError('Gagal menghapus layanan: $e'));
      return false;
    }
  }

  /// Get service by name (untuk New Order)
  Future<ServiceModel?> getServiceByName(int laundryId, String name) async {
    try {
      return await _repository.fetchServiceByName(laundryId, name);
    } catch (e) {
      print('SERVICE Cubit Get by name error: $e');
      return null;
    }
  }
}
