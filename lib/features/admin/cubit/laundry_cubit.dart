import 'package:flutter_bloc/flutter_bloc.dart';
import '../data/repositories/laundry_repository.dart';
import '../data/models/laundry_model.dart';
import '../../../../core/supabase/supabase_client.dart';

part 'laundry_state.dart';

class LaundryCubit extends Cubit<LaundryState> {
  LaundryCubit() : super(LaundryInitial());

  final LaundryRepository _repository = LaundryRepository();

  /// Fetch laundry aktif berdasarkan auth user's staff ID
  /// Mencoba 2 pendekatan:
  /// 1. Query sebagai OWNER (laundries.owner_id = staff.id)
  /// 2. Query sebagai EMPLOYEE (staff.laundry_id → laundries.id)
  Future<void> fetchActiveLaundry(String userId) async {
    print('🔵 [LAUNDRY_CUBIT] fetchActiveLaundry called with userId: $userId');
    emit(LaundryLoading());
    try {
      // Get auth user's email first
      final user = SupabaseService.client.auth.currentUser;
      if (user == null || user.email == null) {
        print('❌ [LAUNDRY] No authenticated user');
        emit(LaundryUnconfigured());
        return;
      }
      print('📧 [LAUNDRY] Authenticated user email: ${user.email}');

      // Look up staff_id from email
      print('🔍 [LAUNDRY] Looking up staff_id by email: ${user.email}');
      final staffId = await _repository.getStaffIdByEmail(user.email!);
      if (staffId == null) {
        print('⚠️ [LAUNDRY] No staff record found for email: ${user.email}');
        emit(LaundryUnconfigured());
        return;
      }

      print('✅ [LAUNDRY] Found staff_id: $staffId for email: ${user.email}');

      // Approach 1: Try as OWNER (owner_id match)
      print('🔍 [LAUNDRY] Approach 1: Trying as OWNER (owner_id = $staffId)');
      var laundry = await _repository.fetchByStaffId(staffId);
      if (laundry != null) {
        print('✅ [LAUNDRY] Active laundry found (as OWNER): ${laundry.name}');
        emit(LaundryLoaded(laundry));
        return;
      }
      print('⚠️ [LAUNDRY] Not found as OWNER, trying Approach 2...');

      // Approach 2: Try as EMPLOYEE (staff.laundry_id match)
      print('🔍 [LAUNDRY] Approach 2: Trying as EMPLOYEE (staff_id=$staffId → laundry_id)');
      laundry = await _repository.fetchByStaffLaundryId(staffId);
      if (laundry != null) {
        print('✅ [LAUNDRY] Active laundry found (as EMPLOYEE): ${laundry.name} (staff.laundry_id=$staffId)');
        emit(LaundryLoaded(laundry));
        return;
      }

      print('❌ [LAUNDRY] No laundry found for staff: $staffId (role: employee, no laundry_id linked)');
      emit(LaundryUnconfigured());
    } catch (e, stackTrace) {
      print('❌ [LAUNDRY] Error fetching: $e');
      print('❌ [LAUNDRY] Stack trace: $stackTrace');
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
