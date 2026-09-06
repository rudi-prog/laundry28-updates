/// Abstract base class untuk Staff Cubit states
import '../../data/models/staff_model.dart';

class StaffState {
  final bool isLoading;
  final List<StaffModel>? staffList;
  final String? errorMessage;

  const StaffState({
    this.isLoading = false,
    this.staffList,
    this.errorMessage,
  });

  factory StaffState.initial() => const StaffState();

  StaffState copyWith({
    bool? isLoading,
    List<StaffModel>? staffList,
    String? errorMessage,
  }) {
    return StaffState(
      isLoading: isLoading ?? this.isLoading,
      staffList: staffList ?? this.staffList,
      errorMessage: errorMessage ?? this.errorMessage,
    );
  }
}

/// Loading state saat fetch data
class StaffLoading extends StaffState {
  const StaffLoading() : super(isLoading: true);
}

/// Success state - data berhasil dimuat
class StaffLoaded extends StaffState {
  final List<StaffModel> staffList;
  const StaffLoaded(this.staffList) : super(staffList: staffList, isLoading: false);
}

/// Error state - ada kesalahan
class StaffError extends StaffState {
  final String message;
  const StaffError(this.message) : super(errorMessage: message, isLoading: false);
}

/// Success saat create/update/delete
class StaffActionSuccess extends StaffState {
  final String action; // "created", "updated", "deleted"
  const StaffActionSuccess(this.action)
      : super(isLoading: false, errorMessage: null);
}
