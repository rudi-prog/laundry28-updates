import 'package:flutter_bloc/flutter_bloc.dart';

import '../../data/repositories/staff_repository.dart';
import 'staff_state.dart';

/// Cubit untuk manajemen karyawan (CRUD operations)
class StaffCubit extends Cubit<StaffState> {
  final StaffRepository _repository;

  StaffCubit({required StaffRepository repository})
      : _repository = repository,
        super(StaffState.initial());

  /// Fetch semua daftar karyawan
  Future<void> fetchAllStaff() async {
    emit(const StaffLoading());
    try {
      final staffList = await _repository.fetchAllStaff();
      emit(StaffLoaded(staffList));
    } catch (e) {
      emit(StaffError(e.toString()));
    }
  }

  /// Tambah karyawan baru
  Future<void> addStaff({
    required String fullName,
    required String username,
    required String password,
    String email = '',
    String? pin,
  }) async {
    emit(const StaffLoading());
    try {
      await _repository.createStaff(
        fullName: fullName,
        username: username,
        password: password,
        email: email,
        pin: pin,
      );
      // Refresh list setelah create
      await fetchAllStaff();
      emit(const StaffActionSuccess('created'));
    } catch (e) {
      emit(StaffError(e.toString()));
    }
  }

  /// Update data karyawan
  Future<void> updateStaff({
    required int id,
    String? fullName,
    String? username,
    String? password,
    String? pin,
  }) async {
    emit(const StaffLoading());
    try {
      await _repository.updateStaff(
        id: id,
        fullName: fullName,
        username: username,
        password: password,
        pin: pin,
      );
      await fetchAllStaff();
      emit(const StaffActionSuccess('updated'));
    } catch (e) {
      emit(StaffError(e.toString()));
    }
  }

  /// Hapus karyawan
  Future<void> removeStaff(int id) async {
    emit(const StaffLoading());
    try {
      await _repository.deleteStaff(id);
      await fetchAllStaff();
      emit(const StaffActionSuccess('deleted'));
    } catch (e) {
      emit(StaffError(e.toString()));
    }
  }

  /// Generate username otomatis dari nama lengkap
  String generateUsername(String fullName) {
    return StaffRepository.generateUsername(fullName);
  }
}
