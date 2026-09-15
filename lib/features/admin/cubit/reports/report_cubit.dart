import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart';
import '../../data/repositories/report_repository.dart';

part 'report_state.dart';

class ReportCubit extends Cubit<ReportState> {
  ReportCubit() : super(ReportInitial());

  final ReportRepository _reportRepository = ReportRepository();

  final _currencyFormat = NumberFormat.currency(
    locale: 'id_ID',
    symbol: 'Rp ',
    decimalDigits: 0,
  );

  DateTime _startOfToday() {
    final now = DateTime.now();
    return DateTime(now.year, now.month, now.day);
  }

  DateTime _startOfWeek() {
    final now = DateTime.now();
    return now.subtract(Duration(days: now.weekday - 1)).copyWith(
      hour: 0, minute: 0, second: 0, millisecond: 0, microsecond: 0,
    );
  }

  DateTime _startOfMonth() {
    final now = DateTime.now();
    return DateTime(now.year, now.month, 1);
  }

  DateTime _endOfToday() => _startOfToday().add(const Duration(days: 1));

  DateTime _endOfWeek() {
    final now = DateTime.now();
    return now.add(Duration(days: 7 - now.weekday)).copyWith(
      hour: 23, minute: 59, second: 59,
    );
  }

  DateTime _endOfMonth() {
    final now = DateTime.now();
    return DateTime(now.year, now.month + 1, 0, 23, 59, 59);
  }

  Map<String, dynamic> _calculateFinancialReport(List<Map<String, dynamic>> orders) {
    double totalRevenue = 0;
    int totalOrders = orders.length;
    final Map<String, double> revenueByService = {};
    final Map<String, int> ordersByService = {};

    for (var order in orders) {
      final price = (order['total_price'] as num?)?.toDouble() ?? 0;
      final service = (order['service_type'] as String?) ?? 'Lainnya';
      totalRevenue += price;
      revenueByService[service] = (revenueByService[service] ?? 0) + price;
      ordersByService[service] = (ordersByService[service] ?? 0) + 1;
    }

    final double averageOrderValue = totalOrders > 0 ? totalRevenue / totalOrders : 0;
    final sortedServices = revenueByService.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));

    return {
      'totalRevenue': totalRevenue,
      'totalOrders': totalOrders,
      'averageOrderValue': averageOrderValue,
      'revenueByService': sortedServices.map((e) => {'name': e.key, 'revenue': e.value}).toList(),
      'ordersByService': ordersByService,
    };
  }

  Map<String, dynamic> _calculateDailyReport(List<Map<String, dynamic>> orders) {
    final Map<String, int> ordersByStatus = {};
    double totalRevenue = 0;
    int completedOrders = 0;
    int pendingOrders = 0;
    final List<Map<String, dynamic>> recentOrders = [];

    for (var order in orders) {
      final status = (order['status'] as String?) ?? 'Unknown';
      ordersByStatus[status] = (ordersByStatus[status] ?? 0) + 1;
      if (status == 'Selesai') {
        totalRevenue += (order['total_price'] as num?)?.toDouble() ?? 0;
        completedOrders++;
      } else {
        pendingOrders++;
      }
      if (recentOrders.length < 10) {
        recentOrders.add({
          'trackingCode': order['tracking_code'] ?? '',
          'customerName': order['customer_name'] ?? '',
          'serviceType': order['service_type'] ?? '',
          'status': status,
          'totalPrice': (order['total_price'] as num?)?.toDouble() ?? 0,
          'createdAt': order['created_at'] ?? '',
        });
      }
    }

    return {
      'totalOrders': orders.length,
      'completedOrders': completedOrders,
      'pendingOrders': pendingOrders,
      'totalRevenue': totalRevenue,
      'ordersByStatus': ordersByStatus,
      'recentOrders': recentOrders,
    };
  }

  Future<void> fetchTodayFinancialReport({int? laundryId}) async {
    emit(ReportLoading());
    try {
      final orders = await _reportRepository.fetchCompletedOrders(
        startDate: _startOfToday(), endDate: _endOfToday(), laundryId: laundryId,
      );
      emit(ReportFinancialLoaded(
        period: 'Hari Ini',
        startDate: _startOfToday(),
        endDate: _endOfToday(),
        report: _calculateFinancialReport(orders),
      ));
    } catch (e) {
      emit(ReportError('Gagal memuat laporan keuangan hari ini: $e'));
    }
  }

  Future<void> fetchWeekFinancialReport({int? laundryId}) async {
    emit(ReportLoading());
    try {
      final orders = await _reportRepository.fetchCompletedOrders(
        startDate: _startOfWeek(), endDate: _endOfWeek(), laundryId: laundryId,
      );
      emit(ReportFinancialLoaded(
        period: 'Minggu Ini',
        startDate: _startOfWeek(),
        endDate: _endOfWeek(),
        report: _calculateFinancialReport(orders),
      ));
    } catch (e) {
      emit(ReportError('Gagal memuat laporan keuangan minggu ini: $e'));
    }
  }

  Future<void> fetchMonthFinancialReport({int? laundryId}) async {
    emit(ReportLoading());
    try {
      final orders = await _reportRepository.fetchCompletedOrders(
        startDate: _startOfMonth(), endDate: _endOfMonth(), laundryId: laundryId,
      );
      emit(ReportFinancialLoaded(
        period: 'Bulan Ini',
        startDate: _startOfMonth(),
        endDate: _endOfMonth(),
        report: _calculateFinancialReport(orders),
      ));
    } catch (e) {
      emit(ReportError('Gagal memuat laporan keuangan bulan ini: $e'));
    }
  }

  Future<void> fetchCustomFinancialReport({
    required DateTime startDate,
    required DateTime endDate,
    int? laundryId,
  }) async {
    emit(ReportLoading());
    try {
      final orders = await _reportRepository.fetchCompletedOrders(
        startDate: startDate, endDate: endDate, laundryId: laundryId,
      );
      final dateFormat = DateFormat('dd MMM yyyy', 'id_ID');
      emit(ReportFinancialLoaded(
        period: 'Custom (${dateFormat.format(startDate)} - ${dateFormat.format(endDate)})',
        startDate: startDate,
        endDate: endDate,
        report: _calculateFinancialReport(orders),
      ));
    } catch (e) {
      emit(ReportError('Gagal memuat laporan keuangan: $e'));
    }
  }

  Future<void> fetchTodayDailyReport({int? laundryId}) async {
    emit(ReportLoading());
    try {
      final orders = await _reportRepository.fetchAllOrdersInPeriod(
        startDate: _startOfToday(), endDate: _endOfToday(), laundryId: laundryId,
      );
      emit(ReportDailyLoaded(
        period: 'Hari Ini',
        startDate: _startOfToday(),
        endDate: _endOfToday(),
        report: _calculateDailyReport(orders),
      ));
    } catch (e) {
      emit(ReportError('Gagal memuat laporan harian: $e'));
    }
  }

  Future<void> fetchYesterdayDailyReport({int? laundryId}) async {
    emit(ReportLoading());
    try {
      final yesterday = DateTime.now().subtract(const Duration(days: 1));
      final startDate = DateTime(yesterday.year, yesterday.month, yesterday.day);
      final endDate = startDate.add(const Duration(days: 1));
      final orders = await _reportRepository.fetchAllOrdersInPeriod(
        startDate: startDate, endDate: endDate, laundryId: laundryId,
      );
      emit(ReportDailyLoaded(
        period: 'Kemarin',
        startDate: startDate,
        endDate: endDate,
        report: _calculateDailyReport(orders),
      ));
    } catch (e) {
      emit(ReportError('Gagal memuat laporan harian: $e'));
    }
  }

  Future<void> fetchCustomDailyReport({
    required DateTime startDate,
    required DateTime endDate,
    int? laundryId,
  }) async {
    emit(ReportLoading());
    try {
      final orders = await _reportRepository.fetchAllOrdersInPeriod(
        startDate: startDate, endDate: endDate, laundryId: laundryId,
      );
      final dateFormat = DateFormat('dd MMM yyyy', 'id_ID');
      emit(ReportDailyLoaded(
        period: 'Custom (${dateFormat.format(startDate)} - ${dateFormat.format(endDate)})',
        startDate: startDate,
        endDate: endDate,
        report: _calculateDailyReport(orders),
      ));
    } catch (e) {
      emit(ReportError('Gagal memuat laporan harian: $e'));
    }
  }

  String generateFinancialReportText(ReportFinancialLoaded state) {
    final report = state.report;
    final dateFormat = DateFormat('dd MMMM yyyy', 'id_ID');
    String text = '📊 *LAPORAN KEUANGAN*\n';
    text += '📅 Periode: ${state.period}\n';
    text += '━━━━━━━━━━━━━━━━━━━━━\n\n';
    text += '💰 *Total Pendapatan:* ${_currencyFormat.format(report['totalRevenue'])}\n';
    text += '📦 *Total Cucian Selesai:* ${report['totalOrders']} cucian\n';
    text += '📈 *Rata-rata per Cucian:* ${_currencyFormat.format(report['averageOrderValue'])}\n\n';
    text += '📋 *Breakdown per Layanan:*\n';
    final revenueByService = report['revenueByService'] as List;
    for (var service in revenueByService) {
      text += '  • ${service['name']}: ${_currencyFormat.format(service['revenue'])}\n';
    }
    text += '\n━━━━━━━━━━━━━━━━━━━━━\n';
    text += '🕐 ${dateFormat.format(state.startDate)} - ${dateFormat.format(state.endDate)}';
    return text;
  }

  String generateDailyReportText(ReportDailyLoaded state) {
    final report = state.report;
    final dateFormat = DateFormat('dd MMMM yyyy', 'id_ID');
    String text = '📋 *LAPORAN HARIAN*\n';
    text += '📅 Periode: ${state.period}\n';
    text += '━━━━━━━━━━━━━━━━━━━━━\n\n';
    text += '📦 *Total Cucian:* ${report['totalOrders']} cucian\n';
    text += '✅ *Selesai:* ${report['completedOrders']} cucian\n';
    text += '🔄 *Masih Proses:* ${report['pendingOrders']} cucian\n';
    text += '💰 *Pendapatan:* ${_currencyFormat.format(report['totalRevenue'])}\n\n';
    text += '📊 *Detail Status:*\n';
    final ordersByStatus = report['ordersByStatus'] as Map<String, dynamic>;
    ordersByStatus.forEach((status, count) {
      text += '  • $status: $count cucian\n';
    });
    if (report['recentOrders'].isNotEmpty) {
      text += '\n📝 *Cucian Terbaru:*\n';
      final recentOrders = report['recentOrders'] as List;
      for (var order in recentOrders.take(5)) {
        text += '  • ${order['trackingCode']} - ${order['customerName']} (${order['status']})\n';
      }
    }
    text += '\n━━━━━━━━━━━━━━━━━━━━━\n';
    text += '🕐 ${dateFormat.format(state.startDate)} - ${dateFormat.format(state.endDate)}';
    return text;
  }
}

