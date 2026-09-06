part of 'laundry_cubit.dart';

abstract class LaundryState {}

class LaundryInitial extends LaundryState {}

class LaundryLoading extends LaundryState {}

class LaundryLoaded extends LaundryState {
  final LaundryModel laundry;
  LaundryLoaded(this.laundry);
}

class LaundryUnconfigured extends LaundryState {}

class LaundryError extends LaundryState {
  final String message;
  LaundryError(this.message);
}
