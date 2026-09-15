import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart';
import 'package:shimmer/shimmer.dart';

import '../../../../../core/theme/app_colors.dart';
import '../../../../../core/widgets/share_text_widget.dart';
import '../../../cubit/reports/report_cubit.dart';
import '../../../cubit/laundry_cubit.dart';

class FinancialReportScreen extends StatefulWidget {
  const FinancialReportScreen({super.key});

  @override
  State<FinancialReportScreen> createState() => _FinancialReportScreenState();
}

class _FinancialReportScreenState extends State<FinancialReportScreen> {
  String _selectedPeriod = 'Hari Ini';
  int? _laundryId;
  final List<String> _periods = ['Hari Ini', 'Minggu Ini', 'Bulan Ini', 'Custom'];

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
      case 'Hari Ini': cubit.fetchTodayFinancialReport(laundryId: _laundryId); break;
      case 'Minggu Ini': cubit.fetchWeekFinancialReport(laundryId: _laundryId); break;
      case 'Bulan Ini': cubit.fetchMonthFinancialReport(laundryId: _laundryId); break;
      case 'Custom':
        cubit.fetchCustomFinancialReport(startDate: DateTime.now().subtract(const Duration(days: 30)), endDate: DateTime.now(), laundryId: _laundryId);
        break;
    }
  }

  void _onPeriodChanged(String? value) {
    if (value != null) { setState(() => _selectedPeriod = value); _fetchReport(); }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Laporan Keuangan'), actions: [
        BlocBuilder<ReportCubit, ReportState>(builder: (ctx, state) {
          if (state is ReportFinancialLoaded) return IconButton(icon: const Icon(Icons.share), onPressed: () {
            final text = ctx.read<ReportCubit>().generateFinancialReportText(state);
            showDialog(context: ctx, builder: (_) => ShareTextWidget(text: text, title: 'Laporan Keuangan'));
          });
          return const SizedBox.shrink();
        }),
      ]),
      body: Column(children: [
        Container(color: Colors.white, padding: const EdgeInsets.all(16), child: DropdownButtonFormField<String>(
          value: _selectedPeriod, decoration: const InputDecoration(labelText: 'Periode', prefixIcon: Icon(Icons.calendar_today), border: OutlineInputBorder()),
          items: _periods.map((p) => DropdownMenuItem(value: p, child: Text(p))).toList(), onChanged: _onPeriodChanged,
        )),
        const Divider(height: 1),
        Expanded(child: BlocBuilder<ReportCubit, ReportState>(builder: (ctx, state) {
          if (state is ReportLoading) return _buildLoading();
          if (state is ReportError) return _buildError(state.message);
          if (state is ReportFinancialLoaded) return _buildContent(state);
          return _buildEmpty();
        })),
      ]),
    );
  }

  Widget _buildLoading() {
    return ListView(padding: const EdgeInsets.all(16), children: [
      _shimmerCard('Total Pendapatan', AppColors.primary), const SizedBox(height: 12),
      _shimmerCard('Total Cucian', AppColors.success), const SizedBox(height: 12),
      _shimmerCard('Rata-rata/Cucian', AppColors.warning), const SizedBox(height: 24),
      const Text('Breakdown per Layanan', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)), const SizedBox(height: 12),
      ...List.generate(3, (_) => _shimmerService()),
    ]);
  }

  Widget _shimmerCard(String label, Color color) {
    return Container(padding: const EdgeInsets.all(20), decoration: BoxDecoration(color: color.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(12), border: Border.all(color: color.withValues(alpha: 0.3))),
      child: Shimmer.fromColors(baseColor: Colors.grey.shade300, highlightColor: Colors.white, child: Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
        Text(label, style: TextStyle(color: Colors.grey.shade400, fontSize: 14)), Container(width: 100, height: 24, color: Colors.grey.shade300),
      ])),
    );
  }

  Widget _shimmerService() {
    return Container(margin: const EdgeInsets.only(bottom: 8), padding: const EdgeInsets.all(16), decoration: BoxDecoration(color: Colors.grey.shade100, borderRadius: BorderRadius.circular(8)),
      child: Shimmer.fromColors(baseColor: Colors.grey.shade300, highlightColor: Colors.white, child: Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
        Container(width: 120, height: 16, color: Colors.grey.shade300), Container(width: 80, height: 16, color: Colors.grey.shade300),
      ])),
    );
  }

  Widget _buildError(String message) {
    return Center(child: Padding(padding: const EdgeInsets.all(24), child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
      const Icon(Icons.error_outline, size: 64, color: AppColors.error), const SizedBox(height: 16),
      const Text('Gagal memuat laporan', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)), const SizedBox(height: 8),
      Text(message, style: const TextStyle(color: AppColors.textSecondary), textAlign: TextAlign.center), const SizedBox(height: 24),
      ElevatedButton.icon(onPressed: _fetchReport, icon: const Icon(Icons.refresh), label: const Text('Coba Lagi'), style: ElevatedButton.styleFrom(backgroundColor: AppColors.primary, foregroundColor: Colors.white)),
    ])));
  }

  Widget _buildEmpty() {
    return const Center(child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
      Icon(Icons.pie_chart_outline, size: 64, color: AppColors.textTertiary), SizedBox(height: 16),
      Text('Belum ada data', style: TextStyle(fontSize: 16, color: AppColors.textTertiary)),
    ]));
  }

  Widget _buildContent(ReportFinancialLoaded state) {
    final report = state.report;
    final currencyFormat = NumberFormat.currency(locale: 'id_ID', symbol: 'Rp ', decimalDigits: 0);
    return SingleChildScrollView(padding: const EdgeInsets.all(16), child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      _statCard('Total Pendapatan', currencyFormat.format(report['totalRevenue']), Icons.account_balance_wallet, AppColors.primary), const SizedBox(height: 12),
      Row(children: [
        Expanded(child: _statCard('Total Cucian', '${report['totalOrders']}', Icons.shopping_bag, AppColors.success)),
        const SizedBox(width: 12),
        Expanded(child: _statCard('Rata-rata/Cucian', currencyFormat.format(report['averageOrderValue']), Icons.trending_up, AppColors.warning)),
      ]), const SizedBox(height: 24),
      Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
        const Text('Breakdown per Layanan', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
        Text('${report['revenueByService'].length} layanan', style: const TextStyle(fontSize: 14, color: AppColors.textSecondary)),
      ]), const SizedBox(height: 12),
      ...List.generate(report['revenueByService'].length, (i) {
        final service = report['revenueByService'][i];
        final ordersCount = report['ordersByService'][service['name']];
        final percentage = report['totalRevenue'] > 0 ? service['revenue'] / report['totalRevenue'] * 100 : 0;
        return Container(margin: const EdgeInsets.only(bottom: 12), padding: const EdgeInsets.all(16), decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(12), border: Border.all(color: AppColors.border), boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.05), blurRadius: 4, offset: const Offset(0, 2))]),
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
              Expanded(child: Text(service['name'], style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold))),
              Text(currencyFormat.format(service['revenue']), style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: AppColors.primary)),
            ]), const SizedBox(height: 8),
            Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
              Text('$ordersCount cucian', style: const TextStyle(fontSize: 13, color: AppColors.textSecondary)),
              Text('${percentage.toStringAsFixed(1)}%', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: percentage > 50 ? AppColors.success : AppColors.textSecondary)),
            ]), const SizedBox(height: 8),
            LinearProgressIndicator(value: percentage / 100, minHeight: 6, backgroundColor: AppColors.surfaceVariant, valueColor: AlwaysStoppedAnimation<Color>(percentage > 50 ? AppColors.success : AppColors.primary)),
          ]),
        );
      }),
      Container(width: double.infinity, padding: const EdgeInsets.all(16), margin: const EdgeInsets.only(top: 8), decoration: BoxDecoration(color: AppColors.surfaceVariant, borderRadius: BorderRadius.circular(8)),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text('Periode: ${state.period}', style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w500)), const SizedBox(height: 4),
          Text('${DateFormat('dd MMM yyyy', 'id_ID').format(state.startDate)} - ${DateFormat('dd MMM yyyy', 'id_ID').format(state.endDate)}', style: const TextStyle(fontSize: 12, color: AppColors.textSecondary)),
        ]),
      ),
    ]));
  }

  Widget _statCard(String title, String value, IconData icon, Color color) {
    return Container(decoration: BoxDecoration(gradient: LinearGradient(colors: [color, color.withValues(alpha: 0.7)]), borderRadius: BorderRadius.circular(16), boxShadow: [BoxShadow(color: color.withValues(alpha: 0.3), blurRadius: 8, offset: const Offset(0, 4))]),
      child: Padding(padding: const EdgeInsets.all(16), child: Column(mainAxisAlignment: MainAxisAlignment.center, crossAxisAlignment: CrossAxisAlignment.start, children: [
        Icon(icon, color: Colors.white, size: 28), const SizedBox(height: 12),
        Text(value, style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: Colors.white)), const SizedBox(height: 4),
        Text(title, style: const TextStyle(fontSize: 12, color: Colors.white70)),
      ])),
    );
  }
}