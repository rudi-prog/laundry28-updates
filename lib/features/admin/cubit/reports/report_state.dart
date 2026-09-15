part of 'report_cubit.dart';

abstract class ReportState {
  const ReportState();
}

class ReportInitial extends ReportState {}

class ReportLoading extends ReportState {}

class ReportFinancialLoaded extends ReportState {
  final String period;
  final DateTime startDate;
  final DateTime endDate;
  final Map<String, dynamic> report;

  const ReportFinancialLoaded({
    required this.period,
    required this.startDate,
    required this.endDate,
    required this.report,
  });
}

class ReportDailyLoaded extends ReportState {
  final String period;
  final DateTime startDate;
  final DateTime endDate;
  final Map<String, dynamic> report;

  const ReportDailyLoaded({
    required this.period,
    required this.startDate,
    required this.endDate,
    required this.report,
  });
}

class ReportError extends ReportState {
  final String message;

  const ReportError(this.message);
}
