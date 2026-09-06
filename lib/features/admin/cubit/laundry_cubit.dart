import 'package:flutter_bloc/flutter_bloc.dart';
import '../data/repositories/laundry_repository.dart';
import '../data/models/laundry_model.dart';
import '../../../../core/supabase/supabase_client.dart';

part 'laundry_state.dart';

class LaundryCubit extends Cubit<LaundryState> {
  LaundryCubit() : super(LaundryInitial());

  final LaundryRepository _repository = LaundryRepository();

  /// Fetch laundry aktif berdasarkan auth user's staff ID
  Future<void> fetchActiveLaundry(String userId) async {
    emit(LaundryLoading());
    try {
      // Get auth user's email first
      final user = SupabaseService.client.auth.currentUser;
      if (user == null || user.email == null) {
        print('❌ [LAUNDRY] No authenticated user');
        emit(LaundryUnconfigured());
        return;
      }

      // Look up staff_id from email
      final staffId = await _repository.getStaffIdByEmail(user.email!);
      if (staffId == null) {
        print('⚠️ [LAUNDRY] No staff record found for email: ${user.email}');
        emit(LaundryUnconfigured());
        return;
      }

      print('✅ [LAUNDRY] Found staff_id: $staffId for email: ${user.email}');

      // Fetch laundry by staff_id (integer)
      final laundry = await _repository.fetchByStaffId(staffId);
      if (laundry != null) {
        print('✅ [LAUNDRY] Active laundry found: ${laundry.name}');
        emit(LaundryLoaded(laundry));
      } else {
        print('⚠️ [LAUNDRY] No laundry found for staff: $staffId');
        emit(LaundryUnconfigured());
      }
    } catch (e) {
      print('❌ [LAUNDRY] Error fetching: $e');
      emit(LaundryUnconfigured());
    }
  }

  /// Setup laundry baru untuk owner
  Future<void> setupLaundry({
    required String name,
    String? address,
    String? phone,
  }) async {
    emit(LaundryLoading());
    try {
      // Get current user's email and look up staff_id
      final user = SupabaseService.client.auth.currentUser;
      if (user == null || user.email == null) {
        emit(LaundryError('User tidak ditemukan'));
        return;
      }

      final staffId = await _repository.getStaffIdByEmail(user.email!);
      if (staffId == null) {
        emit(LaundryError('Staff record tidak ditemukan untuk email ini'));
        return;
      }

      final laundry = await _repository.createLaundry(
        name: name,
        address: address,
        phone: phone,
        ownerId: staffId,
      );

      // Update staff record dengan laundry_id
      await _repository.assignLaundryToOwner(staffId, laundry.id);

      print('✅ [LAUNDRY] Setup complete: ${laundry.name} (staff_id: $staffId)');
      emit(LaundryLoaded(laundry));
    } catch (e) {
      print('❌ [LAUNDRY] Setup error: $e');
      emit(LaundryError('Gagal setup laundry: $e'));
    }
  }

  /// Refresh laundry saat ini
  Future<void> refresh() async {
    final userId = SupabaseService.client.auth.currentUser?.id;
    if (userId != null) {
      await fetchActiveLaundry(userId);
    }
  }
}
