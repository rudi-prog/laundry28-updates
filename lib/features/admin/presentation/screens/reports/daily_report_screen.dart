import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart';
import 'package:shimmer/shimmer.dart';

import '../../../../../core/theme/app_colors.dart';
import '../../../../../core/widgets/share_text_widget.dart';
import '../../../cubit/reports/report_cubit.dart';
import '../../../cubit/laundry_cubit.dart';

class DailyReportScreen extends StatefulWidget {
  const DailyReportScreen({super.key});

  @override
  State<DailyReportScreen> createState() => _DailyReportScreenState();
}

class _DailyReportScreenState extends State<DailyReportScreen> {
  String _selectedPeriod = 'Hari Ini';
  int? _laundryId;
  final List<String> _periods = ['Hari Ini', 'Kemarin', 'Custom'];

  @override
  void initState() {
    super.initState();
    _loadLaundryId();
    _fetchReport();
  }

  void _loadLaundryId() {
    final state = context.read<LaundryCubit>().state;
    if (state is LaundryLoaded) _laundryId = state.laundry.id;
  }

  void _fetchReport() {
    final cubit = context.read<ReportCubit>();
    if (_laundryId == null) return;
    switch (_selectedPeriod) {
      case 'Hari Ini': cubit.fetchTodayDailyReport(laundryId: _laundryId); break;
      case 'Kemarin': cubit.fetchYesterdayDailyReport(laundryId: _laundryId); break;
      case 'Custom':
        cubit.fetchCustomDailyReport(
          startDate: DateTime.now().subtract(const Duration(days: 30)),
          endDate: DateTime.now(),
          laundryId: _laundryId,
        );
        break;
    }
  }

  void _onPeriodChanged(String? value) {
    if (value != null) {
      setState(() => _selectedPeriod = value);
      _fetchReport();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Laporan Operasional'),
        actions: [
          BlocBuilder<ReportCubit, ReportState>(
            builder: (ctx, state) {
              if (state is ReportDailyLoaded) {
                return IconButton(
                  icon: const Icon(Icons.share),
                  onPressed: () {
                    final text = context.read<ReportCubit>().generateDailyReportText(state);
                    showDialog(
                      context: ctx,
                      builder: (_) => ShareTextWidget(text: text, title: 'Laporan Operasional'),
                    );
                  },
                );
              }
              return const SizedBox.shrink();
            },
          ),
        ],
      ),
      body: Column(
        children: [
          Container(
            color: Colors.white,
            padding: const EdgeInsets.all(16),
            child: DropdownButtonFormField<String>(
              value: _selectedPeriod,
              decoration: const InputDecoration(
                labelText: 'Periode',
                prefixIcon: Icon(Icons.calendar_today),
                border: OutlineInputBorder(),
              ),
              items: _periods.map((p) => DropdownMenuItem(value: p, child: Text(p))).toList(),
              onChanged: _onPeriodChanged,
            ),
          ),
          const Divider(height: 1),
          Expanded(
            child: BlocBuilder<ReportCubit, ReportState>(
              builder: (ctx, state) {
                if (state is ReportLoading) return _buildLoading();
                if (state is ReportError) return _buildError(state.message);
                if (state is ReportDailyLoaded) return _buildContent(state);
                return _buildEmpty();
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLoading() {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        _shimmerCard('Total Cucian', AppColors.info),
        const SizedBox(height: 12),
        _shimmerCard('Selesai', AppColors.success),
        const SizedBox(height: 12),
        _shimmerCard('Masih Proses', AppColors.warning),
        const SizedBox(height: 12),
        _shimmerCard('Pendapatan', AppColors.primary),
        const SizedBox(height: 24),
        const Text('Detail Status', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
        const SizedBox(height: 12),
        ...List.generate(4, (_) => _shimmerItem()),
      ],
    );
  }

  Widget _shimmerCard(String label, Color color) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withValues(alpha: 0.3)),
      ),
      child: Shimmer.fromColors(
        baseColor: Colors.grey.shade300,
        highlightColor: Colors.white,
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(label, style: TextStyle(color: Colors.grey.shade400, fontSize: 14)),
            Container(width: 80, height: 24, color: Colors.grey.shade300),
          ],
        ),
      ),
    );
  }

  Widget _shimmerItem() {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(color: Colors.grey.shade100, borderRadius: BorderRadius.circular(8)),
      child: Shimmer.fromColors(
        baseColor: Colors.grey.shade300,
        highlightColor: Colors.white,
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Container(width: 120, height: 16, color: Colors.grey.shade300),
            Container(width: 40, height: 16, color: Colors.grey.shade300),
          ],
        ),
      ),
    );
  }

  Widget _buildError(String message) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.error_outline, size: 64, color: AppColors.error),
            const SizedBox(height: 16),
            const Text('Gagal memuat laporan', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            Text(message, style: const TextStyle(color: AppColors.textSecondary), textAlign: TextAlign.center),
            const SizedBox(height: 24),
            ElevatedButton.icon(
              onPressed: _fetchReport,
              icon: const Icon(Icons.refresh),
              label: const Text('Coba Lagi'),
              style: ElevatedButton.styleFrom(backgroundColor: AppColors.primary, foregroundColor: Colors.white),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmpty() {
    return const Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.assignment_outlined, size: 64, color: AppColors.textTertiary),
          SizedBox(height: 16),
          Text('Belum ada data', style: TextStyle(fontSize: 16, color: AppColors.textTertiary)),
        ],
      ),
    );
  }

  Widget _buildContent(ReportDailyLoaded state) {
    final report = state.report;
    final currencyFormat = NumberFormat.currency(locale: 'id_ID', symbol: 'Rp ', decimalDigits: 0);
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: _statCard('Total Cucian', '${report['totalOrders']}', Icons.shopping_bag, AppColors.info),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _statCard('Selesai', '${report['completedOrders']}', Icons.check_circle, AppColors.success),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: _statCard('Masih Proses', '${report['pendingOrders']}', Icons.hourglass_top, AppColors.warning),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _statCard('Pendapatan', currencyFormat.format(report['totalRevenue']), Icons.account_balance_wallet, AppColors.primary),
              ),
            ],
          ),
          const SizedBox(height: 24),
          const Text('Detail Status', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
          const SizedBox(height: 12),
          ...List.generate(
            (report['ordersByStatus'] as Map<String, dynamic>).length,
            (index) {
              final entries = (report['ordersByStatus'] as Map<String, dynamic>).entries.toList();
              final entry = entries[index];
              final status = entry.key;
              final count = entry.value;
              final statusColor = _getStatusColor(status);
              return Container(
                margin: const EdgeInsets.only(bottom: 8),
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: statusColor.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: statusColor.withValues(alpha: 0.3)),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Row(
                      children: [
                        Container(
                          width: 12,
                          height: 12,
                          decoration: BoxDecoration(color: statusColor, shape: BoxShape.circle),
                        ),
                        const SizedBox(width: 12),
                        Text(status, style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w500)),
                      ],
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                      decoration: BoxDecoration(color: statusColor, borderRadius: BorderRadius.circular(12)),
                      child: Text('$count', style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                    ),
                  ],
                ),
              );
            },
          ),
          if (report['recentOrders'].isNotEmpty) ...[
            const SizedBox(height: 24),
            const Text('Cucian Terbaru', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            const SizedBox(height: 12),
            ...List.generate(
              (report['recentOrders'] as List).length.clamp(0, 5),
              (index) {
                final order = (report['recentOrders'] as List)[index];
                return Container(
                  margin: const EdgeInsets.only(bottom: 8),
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: AppColors.border),
                  ),
                  child: Row(
                    children: [
                      Container(
                        width: 40,
                        height: 40,
                        decoration: BoxDecoration(color: AppColors.primaryLight.withValues(alpha: 0.2), borderRadius: BorderRadius.circular(8)),
                        child: const Icon(Icons.receipt_long, color: AppColors.primary, size: 20),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(order['customerName'], style: const TextStyle(fontWeight: FontWeight.w600)),
                            Text(order['trackingCode'], style: TextStyle(fontSize: 12, color: AppColors.textSecondary)),
                          ],
                        ),
                      ),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          Text(currencyFormat.format(order['totalPrice']), style: const TextStyle(fontWeight: FontWeight.bold, color: AppColors.primary)),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                            decoration: BoxDecoration(color: _getStatusColor(order['status']).withValues(alpha: 0.1), borderRadius: BorderRadius.circular(4)),
                            child: Text(order['status'], style: TextStyle(fontSize: 11, color: _getStatusColor(order['status']), fontWeight: FontWeight.w500)),
                          ),
                        ],
                      ),
                    ],
                  ),
                );
              },
            ),
          ],
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(16),
            margin: const EdgeInsets.only(top: 16),
            decoration: BoxDecoration(color: AppColors.surfaceVariant, borderRadius: BorderRadius.circular(8)),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Periode: ${state.period}', style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w500)),
                const SizedBox(height: 4),
                Text(
                  '${DateFormat('dd MMM yyyy', 'id_ID').format(state.startDate)} - ${DateFormat('dd MMM yyyy', 'id_ID').format(state.endDate)}',
                  style: const TextStyle(fontSize: 12, color: AppColors.textSecondary),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Color _getStatusColor(String status) {
    switch (status) {
      case 'Diterima':
        return AppColors.info;
      case 'Dicuci':
        return AppColors.primary;
      case 'Dikeringkan':
        return AppColors.warning;
      case 'Disetrika':
        return AppColors.accent;
      case 'Siap Diambil':
        return const Color(0xFF0EA5E9);
      case 'Selesai':
        return AppColors.success;
      default:
        return AppColors.textSecondary;
    }
  }

  Widget _statCard(String title, String value, IconData icon, Color color) {
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(colors: [color, color.withValues(alpha: 0.7)]),
        borderRadius: BorderRadius.circular(16),
        boxShadow: [BoxShadow(color: color.withValues(alpha: 0.3), blurRadius: 8, offset: const Offset(0, 4))],
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(icon, color: Colors.white, size: 28),
            const SizedBox(height: 12),
            Text(value, style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: Colors.white)),
            const SizedBox(height: 4),
            Text(title, style: const TextStyle(fontSize: 12, color: Colors.white70)),
          ],
        ),
      ),
    );
  }
}
