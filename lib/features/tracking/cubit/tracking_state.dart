part of 'tracking_cubit.dart';

abstract class TrackingState {}

class TrackingInitial extends TrackingState {}

class TrackingLoading extends TrackingState {}

class TrackingLoaded extends TrackingState {
  final OrderModel order;
  TrackingLoaded(this.order);
}

class TrackingError extends TrackingState {
  final String message;
  TrackingError(this.message);
}
