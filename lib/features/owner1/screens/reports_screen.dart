import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart';

import 'package:laundry28/core/theme/app_colors.dart';
import 'package:laundry28/features/shared/widgets/order_card.dart';
import 'package:laundry28/features/shared/cubit/dashboard_cubit.dart';
import 'package:laundry28/features/super_admin/cubit/laundry_cubit.dart';
import 'package:laundry28/features/super_admin/data/models/laundry_model.dart';
import 'package:laundry28/features/shared/models/order_model.dart';

class ReportsScreen extends StatefulWidget {
  const ReportsScreen({super.key});

  @override
  State<ReportsScreen> createState() => _ReportsScreenState();
}

class _ReportsScreenState extends State<ReportsScreen> {
  final TextEditingController _searchController = TextEditingController();
  String _selectedFilter = 'Semua';
  String _selectedPeriod = 'Semua Waktu';
  final List<String> _filters = ['Semua', 'Pending', 'Dikerjakan', 'Selesai'];
  final List<String> _periods = ['Hari Ini', 'Minggu Ini', 'Bulan Ini', 'Semua Waktu'];

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) _loadOrders();
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _loadOrders() {
    final laundryCubit = context.read<LaundryCubit>();
    final dashboardCubit = context.read<DashboardCubit>();
    final laundryState = laundryCubit.state;
    if (laundryState is LaundryLoaded) {
      dashboardCubit.fetchOrders(laundryId: laundryState.laundry.id);
    }
  }

  List<OrderModel> _filterOrders(List<OrderModel> orders) {
    var filtered = orders;
    final now = DateTime.now();
    final startOfDay = DateTime(now.year, now.month, now.day);
    final startOfWeek = startOfDay.subtract(Duration(days: now.weekday - 1));
    final startOfMonth = DateTime(now.year, now.month, 1);

    switch (_selectedPeriod) {
      case 'Hari Ini':
        filtered = filtered.where((o) => o.createdAt.isAtSameMomentAs(startOfDay) || o.createdAt.isAfter(startOfDay)).toList();
        break;
      case 'Minggu Ini':
        filtered = filtered.where((o) => o.createdAt.isAtSameMomentAs(startOfWeek) || o.createdAt.isAfter(startOfWeek)).toList();
        break;
      case 'Bulan Ini':
        filtered = filtered.where((o) => o.createdAt.isAtSameMomentAs(startOfMonth) || o.createdAt.isAfter(startOfMonth)).toList();
        break;
    }

    if (_searchController.text.isNotEmpty) {
      final query = _searchController.text.toLowerCase();
      filtered = filtered.where((o) {
        final name = o.customerName;
        final phone = o.customerPhone;
        return o.trackingCode.toLowerCase().contains(query) ||
            name.toLowerCase().contains(query) ||
            phone.toLowerCase().contains(query);
      }).toList();
    }

    if (_selectedFilter != 'Semua') {
      filtered = filtered.where((o) => o.status == _selectedFilter).toList();
    }

    return filtered;
  }

  Map<String, dynamic> _calculatePeriodSummary(List<OrderModel> orders) {
    final totalRevenue = orders.fold(0.0, (sum, o) => sum + (o.totalPrice ?? 0));
    final statusBreakdown = <String, int>{};
    for (var order in orders) {
      statusBreakdown[order.status] = (statusBreakdown[order.status] ?? 0) + 1;
    }
    final avgOrderValue = orders.isNotEmpty ? totalRevenue / orders.length : 0;
    return {
      'totalRevenue': totalRevenue,
      'totalOrders': orders.length,
      'avgOrderValue': avgOrderValue,
      'statusBreakdown': statusBreakdown,
    };
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color.fromARGB(255, 89, 92, 95),
      body: Stack(
        children: [
          // AppBar (bottom layer)
          Positioned(
            top: 0,
            left: 0,
            right: 0,
            child: Container(
              decoration: BoxDecoration(
                boxShadow: [
                  BoxShadow(
                    color: Colors.blue.shade900.withValues(alpha: 0.06),
                    blurRadius: 15,
                    offset: const Offset(0, -4),
                    spreadRadius: -5,
                  ),
                  BoxShadow(
                    color: Colors.blue.shade900.withValues(alpha: 0.12),
                    blurRadius: 12,
                    offset: const Offset(0, 3),
                    spreadRadius: 0,
                  ),
                ],
              ),
              child: ClipRRect(
                borderRadius: const BorderRadius.vertical(top: Radius.circular(25)),
                child: SizedBox(
                  height: 200,
                  child: Container(
                    color: const Color(0xFFFFFFFF),
                    child: BlocBuilder<LaundryCubit, LaundryState>(
                      builder: (context, laundryState) {
                        LaundryModel? laundry;
                        if (laundryState is LaundryLoaded) {
                          laundry = laundryState.laundry;
                        }
                        return Padding(
                          padding: const EdgeInsets.fromLTRB(16, 35, 16, 12),
                          child: Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Container(
                                width: 50,
                                height: 50,
                                decoration: BoxDecoration(
                                  shape: BoxShape.circle,
                                  gradient: const LinearGradient(
                                    begin: Alignment.topLeft,
                                    end: Alignment.bottomRight,
                                    colors: [
                                      Color(0xFF000A7A),
                                      Color(0xFF1E3A8A),
                                    ],
                                  ),
                                  boxShadow: [
                                    BoxShadow(
                                      color: Color(0xFF000A7A).withValues(alpha: 0.25),
                                      blurRadius: 8,
                                      offset: const Offset(0, 2),
                                    ),
                                  ],
                                ),
                                child: const Center(
                                  child: Icon(
                                    Icons.bar_chart_rounded,
                                    size: 28,
                                    color: Colors.white,
                                  ),
                                ),
                              ),
                              const SizedBox(width: 16),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  mainAxisAlignment: MainAxisAlignment.start,
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Text(
                                      'Laporan',
                                      style: const TextStyle(
                                        fontSize: 15,
                                        color: Color(0xFF000A7A),
                                        fontWeight: FontWeight.bold,
                                        height: 0.95,
                                      ),
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                    Text(
                                      laundry?.name ?? 'Laundry Anda',
                                      style: const TextStyle(
                                        fontSize: 15,
                                        color: Color(0xFF000A7A),
                                        fontWeight: FontWeight.bold,
                                        height: 0.95,
                                      ),
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                    if (laundry?.address != null && laundry!.address!.isNotEmpty)
                                      Padding(
                                        padding: const EdgeInsets.only(top: 4),
                                        child: Text(
                                          laundry.address!,
                                          style: TextStyle(
                                            fontSize: 12,
                                            color: Colors.grey.shade600,
                                            fontWeight: FontWeight.w400,
                                            height: 0.95,
                                          ),
                                          maxLines: 1,
                                          overflow: TextOverflow.ellipsis,
                                        ),
                                      ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        );
                      },
                    ),
                  ),
                ),
              ),
            ),
          ),
          // Floating sheet with rounded top corners overlapping the AppBar (top layer)
          Positioned(
            top: 100,
            left: 0,
            right: 0,
            bottom: 0,
            child: ClipRRect(
              borderRadius: const BorderRadius.vertical(top: Radius.circular(25)),
              child: Container(
                decoration: BoxDecoration(
                  color: AppColors.surface,
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.08),
                      blurRadius: 20,
                      offset: const Offset(0, 4),
                      spreadRadius: 0,
                    ),
                  ],
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.max,
                  children: [
                    Expanded(
                      child: RefreshIndicator(
                        onRefresh: () async => _loadOrders(),
                        child: CustomScrollView(
                          slivers: [
                            SliverToBoxAdapter(
                              child: Column(
                                children: [
                                  // Search bar
                                  Padding(
                                    padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
                                    child: TextField(
                                      controller: _searchController,
                                      onChanged: (value) => setState(() {}),
                                      decoration: InputDecoration(
                                        hintText: 'Cari berdasarkan nama, no. HP, atau kode tracking',
                                        prefixIcon: const Icon(Icons.search_rounded),
                                        suffixIcon: _searchController.text.isNotEmpty
                                            ? IconButton(
                                                icon: const Icon(Icons.clear_rounded),
                                                onPressed: () {
                                                  _searchController.clear();
                                                  setState(() {});
                                                },
                                              )
                                            : null,
                                        filled: true,
                                        fillColor: AppColors.background,
                                        border: OutlineInputBorder(
                                          borderRadius: BorderRadius.circular(12),
                                          borderSide: BorderSide.none,
                                        ),
                                        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                                      ),
                                    ),
                                  ),
                                  const SizedBox(height: 8),
                                  // Status filter chips
                                  Padding(
                                    padding: const EdgeInsets.symmetric(horizontal: 16),
                                    child: SizedBox(
                                      height: 40,
                                      child: ListView.builder(
                                        scrollDirection: Axis.horizontal,
                                        itemCount: _filters.length,
                                        itemBuilder: (context, index) {
                                          final filter = _filters[index];
                                          return Padding(
                                            padding: EdgeInsets.only(
                                              right: index == _filters.length - 1 ? 16 : 8,
                                            ),
                                            child: _buildFilterChip(filter, _selectedFilter == filter),
                                          );
                                        },
                                      ),
                                    ),
                                  ),
                                  const SizedBox(height: 8),
                                  // Period filter chips
                                  Padding(
                                    padding: const EdgeInsets.symmetric(horizontal: 16),
                                    child: SizedBox(
                                      height: 36,
                                      child: ListView.builder(
                                        scrollDirection: Axis.horizontal,
                                        itemCount: _periods.length,
                                        itemBuilder: (context, index) {
                                          final period = _periods[index];
                                          return Padding(
                                            padding: EdgeInsets.only(
                                              right: index == _periods.length - 1 ? 16 : 8,
                                            ),
                                            child: _buildPeriodChip(period, _selectedPeriod == period),
                                          );
                                        },
                                      ),
                                    ),
                                  ),
                                  const SizedBox(height: 8),
                                ],
                              ),
                            ),
                            SliverPadding(
                              padding: const EdgeInsets.symmetric(horizontal: 16),
                              sliver: BlocBuilder<DashboardCubit, DashboardState>(
                                builder: (context, state) {
                                  if (state is DashboardLoading) {
                                    return SliverFillRemaining(
                                      hasScrollBody: false,
                                      child: const Center(child: CircularProgressIndicator()),
                                    );
                                  }
                                  if (state is DashboardError) {
                                    return SliverFillRemaining(
                                      hasScrollBody: false,
                                      child: Center(
                                        child: Column(
                                          mainAxisAlignment: MainAxisAlignment.center,
                                          children: [
                                            Icon(Icons.error_outline, size: 64, color: AppColors.error),
                                            const SizedBox(height: 12),
                                            Text('Gagal memuat data', style: TextStyle(fontSize: 15, fontWeight: FontWeight.w500, color: AppColors.textSecondary)),
                                            const SizedBox(height: 4),
                                            Text(state.message, style: TextStyle(fontSize: 13, color: AppColors.textTertiary)),
                                            const SizedBox(height: 16),
                                            ElevatedButton(
                                              onPressed: _loadOrders,
                                              child: const Text('Coba Lagi'),
                                            ),
                                          ],
                                        ),
                                      ),
                                    );
                                  }
                                  final orders = _getOrdersFromState(state);
                                  final filtered = _filterOrders(orders);
                                  final summary = _calculatePeriodSummary(filtered);
                                  final fmt = NumberFormat.currency(locale: 'id_ID', symbol: 'Rp', decimalDigits: 0);

                                  return SliverList(
                                    delegate: SliverChildListDelegate([
                                      // Summary cards
                                      Padding(
                                        padding: const EdgeInsets.only(bottom: 4),
                                        child: Row(
                                          children: [
                                            Expanded(
                                              child: _buildSummaryCard(
                                                value: summary['totalOrders'].toString(),
                                                label: 'Total Cucian',
                                                icon: Icons.shopping_bag_rounded,
                                                color: AppColors.primary,
                                              ),
                                            ),
                                            const SizedBox(width: 8),
                                            Expanded(
                                              child: _buildSummaryCard(
                                                value: fmt.format(summary['totalRevenue']),
                                                label: 'Total Pendapatan',
                                                icon: Icons.payments_rounded,
                                                color: AppColors.success,
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                      Padding(
                                        padding: const EdgeInsets.only(bottom: 8),
                                        child: Row(
                                          children: [
                                            Expanded(
                                              child: _buildSummaryCard(
                                                value: summary['avgOrderValue'].toStringAsFixed(0),
                                                label: 'Rata-Rata Pesanan',
                                                icon: Icons.trending_up_rounded,
                                                color: AppColors.warning,
                                              ),
                                            ),
                                            const SizedBox(width: 8),
                                            Expanded(
                                              child: _buildSummaryCard(
                                                value: summary['statusBreakdown']['Siap Diambil']?.toString() ?? '0',
                                                label: 'Siap Diambil',
                                                icon: Icons.check_circle_rounded,
                                                color: AppColors.success,
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                      // Orders
                                      if (filtered.isEmpty)
                                        Container(
                                          padding: const EdgeInsets.symmetric(vertical: 48),
                                          child: Center(
                                            child: Column(
                                              mainAxisAlignment: MainAxisAlignment.center,
                                              children: [
                                                Icon(Icons.inbox_rounded, size: 64, color: AppColors.textTertiary),
                                                const SizedBox(height: 12),
                                                Text('Belum ada cucian', style: TextStyle(fontSize: 15, fontWeight: FontWeight.w500, color: AppColors.textSecondary)),
                                                const SizedBox(height: 4),
                                                Text('Coba ubah filter atau periode', style: TextStyle(fontSize: 13, color: AppColors.textTertiary)),
                                              ],
                                            ),
                                          ),
                                        ),
                                      ...filtered.map((order) => Padding(
                                        padding: const EdgeInsets.only(bottom: 8),
                                        child: OrderCard(order: order),
                                      )),
                                      if (filtered.isNotEmpty)
                                        Padding(
                                          padding: const EdgeInsets.only(top: 8, bottom: 16),
                                          child: Text(
                                            '${filtered.length} cucian ditemukan',
                                            style: TextStyle(fontSize: 12, fontWeight: FontWeight.w500, color: AppColors.textSecondary),
                                          ),
                                        ),
                                    ]),
                                  );
                                },
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFilterChip(String label, bool isSelected) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
      decoration: BoxDecoration(
        color: isSelected ? AppColors.primary : Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: isSelected ? AppColors.primary : const Color(0xFFE2E8F0)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 4,
            offset: const Offset(0, 1),
          ),
        ],
      ),
      child: Text(
        label,
        style: TextStyle(
          fontSize: 12,
          fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
          color: isSelected ? Colors.white : AppColors.textPrimary,
        ),
      ),
    );
  }

  Widget _buildPeriodChip(String label, bool isSelected) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: isSelected ? AppColors.primary : Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: isSelected ? AppColors.primary : const Color(0xFFE2E8F0)),
      ),
      child: Text(
        label,
        style: TextStyle(fontSize: 11, fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500, color: isSelected ? Colors.white : AppColors.textPrimary),
      ),
    );
  }

  Widget _buildSummaryCard({
    required String value,
    required String label,
    required IconData icon,
    required Color color,
  }) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.06),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withValues(alpha: 0.1)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(6),
                decoration: BoxDecoration(color: color.withValues(alpha: 0.12), borderRadius: BorderRadius.circular(8)),
                child: Icon(icon, size: 16, color: color),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  value,
                  style: TextStyle(fontSize: 14, fontWeight: FontWeight.w700, color: AppColors.textPrimary),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          Text(label, style: TextStyle(fontSize: 10, color: AppColors.textSecondary)),
        ],
      ),
    );
  }

  List<OrderModel> _getOrdersFromState(dynamic state) {
    if (state is DashboardState) return state.orders ?? [];
    return [];
  }
}
