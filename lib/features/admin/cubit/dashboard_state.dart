part of 'dashboard_cubit.dart';

abstract class DashboardState {
  final List<OrderModel>? orders;
  const DashboardState({this.orders});
}

class DashboardInitial extends DashboardState {}

class DashboardLoading extends DashboardState {
  final List<OrderModel> previousOrders;
  DashboardLoading(this.previousOrders) : super(orders: previousOrders);
}

class DashboardLoaded extends DashboardState {
  final List<OrderModel> orders;
  DashboardLoaded(this.orders, List<OrderModel> _) : super(orders: orders);
}

class DashboardError extends DashboardState {
  final String message;
  DashboardError(this.message, List<OrderModel> previousOrders) : super(orders: previousOrders);
}
