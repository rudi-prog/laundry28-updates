import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import '../../../../core/constants/app_routes.dart';
import '../../cubit/dashboard_cubit.dart';
import '../../cubit/auth_cubit.dart';
import '../widgets/order_card.dart';
import '../../../../shared/models/order_model.dart';
import '../../../../core/theme/app_colors.dart';

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  String _selectedStatus = 'Semua';
  final TextEditingController _searchController = TextEditingController();

  static const List<String> _statusFilterOptions = [
    'Semua',
    'Diterima',
    'Dicuci',
    'Dikeringkan',
    'Disetrika',
    'Siap Diambil',
    'Selesai',
  ];

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  List<OrderModel> _getFilteredOrders(List<OrderModel> orders) {
    var filtered = orders;

    // Filter by status
    if (_selectedStatus != 'Semua') {
      filtered = filtered.where((o) => o.status == _selectedStatus).toList();
    }

    // Filter by search text
    final query = _searchController.text.trim().toLowerCase();
    if (query.isNotEmpty) {
      filtered = filtered.where((o) {
        return o.trackingCode.toLowerCase().contains(query) ||
            o.customerName.toLowerCase().contains(query) ||
            o.customerPhone.contains(query);
      }).toList();
    }

    // Sort by createdAt descending (newest first)
    filtered.sort((a, b) => b.createdAt.compareTo(a.createdAt));

    return filtered;
  }

  @override
  Widget build(BuildContext context) {
    // Fetch orders lazily on first load (after auth redirect from login)
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final cubit = context.read<DashboardCubit>();
      if (cubit.state.isEmpty) {
        cubit.fetchOrders();
      }
    });

    return BlocListener<AuthCubit, AuthState>(
      listener: (context, state) {
        if (state is AuthUnauthenticated) {
          context.go('/login');
        }
      },
      child: Scaffold(
        backgroundColor: AppColors.background,
        appBar: AppBar(
          backgroundColor: AppColors.primary,
          foregroundColor: Colors.white,
          title: const Text(
            'Dashboard Admin',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              letterSpacing: 0.5,
            ),
          ),
          elevation: 0,
          actions: [
            IconButton(
              icon: const Icon(Icons.refresh),
              onPressed: () {
                context.read<DashboardCubit>().fetchOrders();
              },
            ),
            PopupMenuButton<MenuChoice>(
              icon: const CircleAvatar(
                radius: 14,
                backgroundColor: Colors.white24,
                child: Icon(Icons.person, size: 18),
              ),
              itemBuilder: (context) => <PopupMenuEntry<MenuChoice>>[
                const PopupMenuItem(
                  value: MenuChoice.profile,
                  child: Row(
                    children: [
                      Icon(Icons.person_outline, size: 20),
                      SizedBox(width: 12),
                      Text('Profile'),
                    ],
                  ),
                ),
                const PopupMenuDivider(),
                PopupMenuItem<MenuChoice>(
                  value: MenuChoice.logout,
                  child: Row(
                    children: [
                      const Icon(Icons.logout, size: 20, color: AppColors.error),
                      SizedBox(width: 12),
                      Text('Logout', style: TextStyle(color: AppColors.error)),
                    ],
                  ),
                ),
              ],
              onSelected: (value) {
                if (value == MenuChoice.logout) {
                  context.read<AuthCubit>().logout();
                }
              },
            ),
          ],
        ),
        body: BlocBuilder<DashboardCubit, List<OrderModel>>(
          builder: (context, orders) {
            return RefreshIndicator(
              onRefresh: () async {
                context.read<DashboardCubit>().fetchOrders();
                await Future.delayed(const Duration(milliseconds: 300));
              },
              color: AppColors.primary,
              child: CustomScrollView(
                slivers: [
                  SliverToBoxAdapter(
                    child: Padding(
                      padding: const EdgeInsets.all(20),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Selamat Datang 👋',
                            style: TextStyle(
                              fontSize: 24,
                              fontWeight: FontWeight.bold,
                              color: AppColors.textPrimary,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            DateFormat('EEEE, dd MMMM yyyy', 'id_ID').format(DateTime.now()),
                            style: TextStyle(
                              fontSize: 14,
                              color: AppColors.textSecondary,
                            ),
                          ),
                          const SizedBox(height: 24),
                          _buildStatsGrid(orders),
                          const SizedBox(height: 20),

                          // Search Field
                          TextField(
                            controller: _searchController,
                            textInputAction: TextInputAction.search,
                            onChanged: (value) => setState(() {}),
                            onSubmitted: (_) => setState(() {}),
                            decoration: InputDecoration(
                              hintText: 'Cari tracking code, nama, atau no. HP...',
                              prefixIcon: const Icon(Icons.search, color: AppColors.textTertiary),
                              suffixIcon: _searchController.text.isNotEmpty
                                  ? Row(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        IconButton(
                                          icon: const Icon(Icons.tune, size: 18),
                                          onPressed: () {
                                            setState(() {});
                                            FocusScope.of(context).unfocus();
                                          },
                                        ),
                                        const SizedBox(width: 4),
                                        IconButton(
                                          icon: const Icon(Icons.clear, size: 18),
                                          onPressed: () {
                                            _searchController.clear();
                                            setState(() {});
                                          },
                                        ),
                                      ],
                                    )
                                  : null,
                              filled: true,
                              fillColor: AppColors.surface,
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(12),
                                borderSide: BorderSide.none,
                              ),
                              contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                            ),
                          ),
                          const SizedBox(height: 16),

                          // Status Filter Chips
                          SingleChildScrollView(
                            scrollDirection: Axis.horizontal,
                            child: Row(
                              children: _statusFilterOptions.map((status) {
                                final isSelected = _selectedStatus == status;
                                return Padding(
                                  padding: const EdgeInsets.only(right: 8),
                                  child: FilterChip(
                                    label: Text(status),
                                    selected: isSelected,
                                    onSelected: (_) {
                                      setState(() => _selectedStatus = status);
                                    },
                                    selectedColor: AppColors.primary.withValues(alpha: 0.15),
                                    checkmarkColor: AppColors.primary,
                                    labelStyle: TextStyle(
                                      color: isSelected ? AppColors.primary : AppColors.textSecondary,
                                      fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
                                    ),
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(20),
                                      side: BorderSide(
                                        color: isSelected ? AppColors.primary : AppColors.border,
                                        width: isSelected ? 1.5 : 1,
                                      ),
                                    ),
                                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                                  ),
                                );
                              }).toList(),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  // Filtered results header + Reset button
                  SliverToBoxAdapter(
                    child: Padding(
                      padding: const EdgeInsets.fromLTRB(20, 8, 20, 4),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            'Pesanan (${_getFilteredOrders(orders).length})',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                              color: AppColors.textPrimary,
                            ),
                          ),
                          if (_selectedStatus != 'Semua' || _searchController.text.isNotEmpty)
                            TextButton.icon(
                              onPressed: () {
                                setState(() {
                                  _selectedStatus = 'Semua';
                                  _searchController.clear();
                                });
                              },
                              icon: const Icon(Icons.clear_all, size: 16),
                              label: const Text('Reset Filter'),
                              style: TextButton.styleFrom(
                                foregroundColor: AppColors.primary,
                                padding: EdgeInsets.zero,
                                minimumSize: const Size(0, 0),
                                tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                              ),
                            ),
                        ],
                      ),
                    ),
                  ),

                  // Filtered order list
                  _getFilteredOrders(orders).isEmpty && orders.isNotEmpty
                      ? SliverToBoxAdapter(
                          child: Center(
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(
                                  Icons.filter_list_off_outlined,
                                  size: 64,
                                  color: AppColors.textTertiary,
                                ),
                                const SizedBox(height: 16),
                                Text(
                                  'Tidak ada pesanan yang cocok',
                                  style: TextStyle(
                                    fontSize: 15,
                                    color: AppColors.textSecondary,
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  'Coba ubah filter atau kata kunci pencarian',
                                  style: TextStyle(
                                    fontSize: 12,
                                    color: AppColors.textTertiary,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        )
                      : SliverList(
                          delegate: SliverChildBuilderDelegate(
                            (context, index) {
                              if (index == 0) return const SizedBox(height: 8);
                              final filtered = _getFilteredOrders(orders);
                              final order = filtered[index - 1];
                              return Padding(
                                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 6),
                                child: OrderCard(order: order),
                              );
                            },
                            childCount: _getFilteredOrders(orders).isEmpty ? 0 : _getFilteredOrders(orders).length + 1,
                          ),
                        ),

                  // Empty state when no orders at all
                  if (orders.isEmpty)
                    SliverToBoxAdapter(
                      child: Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              Icons.inbox_outlined,
                              size: 80,
                              color: AppColors.textTertiary,
                            ),
                            const SizedBox(height: 16),
                            Text(
                              'Belum ada pesanan',
                              style: TextStyle(
                                fontSize: 16,
                                color: AppColors.textSecondary,
                              ),
                            ),
                            const SizedBox(height: 8),
                            Text(
                              'Pesanan baru akan muncul di sini',
                              style: TextStyle(
                                fontSize: 13,
                                color: AppColors.textTertiary,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),

                  const SliverToBoxAdapter(child: SizedBox(height: 20)),
                ],
              ),
            );
          },
        ),
        floatingActionButton: FloatingActionButton.extended(
          onPressed: () => context.go(AppRoutes.newOrder),
          backgroundColor: AppColors.primary,
          icon: const Icon(Icons.add, color: Colors.white),
          label: const Text(
            'Tambah Pesanan',
            style: TextStyle(color: Colors.white),
          ),
        ),
      ),
    );
  }

  Widget _buildStatsGrid(List<OrderModel> orders) {
    final totalOrders = orders.length;
    final readyCount = orders.where((o) => o.status == 'Siap Diambil').length;
    final inProgressCount = orders.where((o) => !["Siap Diambil", "Selesai"].contains(o.status)).length;
    final completedCount = orders.where((o) => o.status == 'Selesai').length;

    return LayoutBuilder(
      builder: (context, constraints) {
        // Calculate card width based on available space
        // Available width minus padding (20 left + 20 right), divided by 2 columns with spacing
        final availableWidth = constraints.maxWidth - 40; // subtract horizontal padding from parent
        final cardSpacing = 12.0;
        final cardWidth = (availableWidth - cardSpacing) / 2;

        return Column(
          children: [
            Row(
              children: [
                Expanded(
                  child: SizedBox(
                    width: cardWidth,
                    child: _buildStatCard(
                      title: "Total Pesanan",
                      value: totalOrders.toString(),
                      icon: Icons.shopping_bag_outlined,
                      color: AppColors.primary,
                      gradient: const LinearGradient(colors: [AppColors.primary, AppColors.primaryLight]),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: SizedBox(
                    width: cardWidth,
                    child: _buildStatCard(
                      title: "Dalam Proses",
                      value: inProgressCount.toString(),
                      icon: Icons.pending_outlined,
                      color: AppColors.warning,
                      gradient: const LinearGradient(colors: [AppColors.warning, Color(0xFFFCD34D)]),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: SizedBox(
                    width: cardWidth,
                    child: _buildStatCard(
                      title: "Siap Diambil",
                      value: readyCount.toString(),
                      icon: Icons.check_circle_outline,
                      color: AppColors.success,
                      gradient: const LinearGradient(colors: [AppColors.success, Color(0xFF6EE7B7)]),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: SizedBox(
                    width: cardWidth,
                    child: _buildStatCard(
                      title: "Selesai",
                      value: completedCount.toString(),
                      icon: Icons.done_all,
                      color: AppColors.textSecondary,
                      gradient: const LinearGradient(colors: [AppColors.textSecondary, AppColors.textTertiary]),
                    ),
                  ),
                ),
              ],
            ),
          ],
        );
      },
    );
  }

  Widget _buildStatCard({
    required String title,
    required String value,
    required IconData icon,
    required Color color,
    required LinearGradient gradient,
  }) {
    return Container(
      decoration: BoxDecoration(
        gradient: gradient,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(color: color.withValues(alpha: 0.3), blurRadius: 8, offset: const Offset(0, 4)),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(icon, color: Colors.white, size: 28),
            const SizedBox(height: 12),
            Text(
              value,
              style: const TextStyle(fontSize: 28, fontWeight: FontWeight.bold, color: Colors.white),
            ),
            const SizedBox(height: 4),
            Text(
              title,
              style: TextStyle(fontSize: 12, color: Colors.white.withValues(alpha: 0.9), fontWeight: FontWeight.w500),
            ),
          ],
        ),
      ),
    );
  }
}

enum MenuChoice { profile, logout }
