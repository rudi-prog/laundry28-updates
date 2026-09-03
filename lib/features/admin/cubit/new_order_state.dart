part of 'new_order_cubit.dart';

abstract class NewOrderState {}

class NewOrderInitial extends NewOrderState {}

class NewOrderLoading extends NewOrderState {}

class NewOrderSuccess extends NewOrderState {}

class NewOrderError extends NewOrderState {
  final String message;
  NewOrderError(this.message);
}
