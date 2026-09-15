part of 'auth_cubit.dart';

abstract class AuthState {}

class AuthInitial extends AuthState {}

class AuthLoading extends AuthState {}

class Authenticated extends AuthState {
  final StaffModel staff;
  Authenticated(this.staff);
}

class AuthUnauthenticated extends AuthState {
  final String? message;
  AuthUnauthenticated({this.message});
}

/// User login berhasil tapi belum punya laundry — perlu onboarding
class AuthOnboardingRequired extends AuthState {
  final String? email;
  AuthOnboardingRequired({this.email});
}

/// Onboarding laundry berhasil diselesaikan
class AuthOnboardingComplete extends AuthState {
  final String laundryName;
  final int laundryId;
  AuthOnboardingComplete({required this.laundryName, required this.laundryId});
}

/// Error saat onboarding
class AuthOnboardingLoading extends AuthState {}

class AuthGoogleLoading extends AuthState {}

class AuthOnboardingError extends AuthState {
  final String message;
  AuthOnboardingError(this.message);
}