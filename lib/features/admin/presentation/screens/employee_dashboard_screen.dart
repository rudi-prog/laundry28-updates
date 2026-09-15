import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import 'package:shimmer/shimmer.dart';
import '../../../../core/constants/app_routes.dart';
import '../../../../core/widgets/empty_state_widget.dart';
import '../../cubit/dashboard_cubit.dart';
import '../../cubit/auth_cubit.dart';
import '../../cubit/laundry_cubit.dart';
import '../widgets/order_card.dart';
import '../widgets/order_card_skeleton.dart';
import '../../../../shared/models/order_model.dart';
import '../../../../core/theme/app_colors.dart';

class EmployeeDashboardScreen extends StatefulWidget {
  const EmployeeDashboardScreen({super.key});

  @override
  State<EmployeeDashboardScreen> createState() => _EmployeeDashboardScreenState();
}

class _EmployeeDashboardScreenState extends State<EmployeeDashboardScreen> {
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
  void initState() {
    super.initState();
    // Fetch orders on initial load
    _loadOrders();
  }

  void _loadOrders() {
    final laundryCubit = context.read<LaundryCubit>();
    final state = laundryCubit.state;
    if (state is LaundryLoaded) {
      context.read<DashboardCubit>().fetchOrders(laundryId: state.laundry.id);
    } else {
      context.read<DashboardCubit>().fetchOrders();
    }
  }

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

  Future<void> _onRefresh() async {
    _loadOrders();
    // Small delay to show the refresh animation
    await Future.delayed(const Duration(milliseconds: 600));
  }

  @override
  Widget build(BuildContext context) {
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
              title: BlocBuilder<LaundryCubit, LaundryState>(
                builder: (context, laundryState) {
                  String title = 'Dashboard Karyawan';
                  if (laundryState is LaundryLoaded) {
                    title = 'Dashboard Karyawan - ${laundryState.laundry.name}';
                  } else if (laundryState is LaundryLoading) {
                    title = 'Dashboard Karyawan';
                  } else if (laundryState is LaundryUnconfigured) {
                    title = 'Dashboard Karyawan (Laundry Belum Disetup)';
                  }
                  return Text(
                    title,
                    style: const TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 0.5,
                    ),
                  );
                },
              ),
              elevation: 0,
              actions: [
                IconButton(
                  icon: const Icon(Icons.refresh),
                  onPressed: () {
                    _loadOrders();
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
        body: BlocBuilder<DashboardCubit, DashboardState>(
          builder: (context, state) {
            // Determine orders list from current state
            final List<OrderModel> orders;
            final bool isLoading = state is DashboardLoading || state is DashboardInitial;
            final bool isError = state is DashboardError;

            if (state is DashboardLoaded) {
              orders = state.orders;
            } else if (state is DashboardLoading) {
              orders = state.previousOrders;
            } else if (state is DashboardError) {
              orders = []; // Show empty/error state, keep previous in state.message
            } else {
              orders = [];
            }

            return RefreshIndicator(
              onRefresh: _onRefresh,
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
                          BlocBuilder<LaundryCubit, LaundryState>(
                            builder: (context, laundryState) {
                              if (laundryState is LaundryLoaded) {
                                return Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                                  decoration: BoxDecoration(
                                    color: AppColors.primary.withValues(alpha: 0.1),
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  child: Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      Icon(
                                        Icons.storefront_outlined,
                                        size: 14,
                                        color: AppColors.primary,
                                      ),
                                      const SizedBox(width: 6),
                                      Text(
                                        laundryState.laundry.name,
                                        style: TextStyle(
                                          fontSize: 13,
                                          fontWeight: FontWeight.w600,
                                          color: AppColors.primary,
                                        ),
                                      ),
                                    ],
                                  ),
                                );
                              }
                              return const SizedBox.shrink();
                            },
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

                          // Stats grid - show shimmer during loading
                          if (isLoading && orders.isEmpty) ..._buildStatsSkeleton(context),
                          if (!isLoading || orders.isNotEmpty) _buildStatsGrid(orders),

                          const SizedBox(height: 20),

                          // Search Field
                          TextField(
                            controller: _searchController,
                            textInputAction: TextInputAction.search,
                            onChanged: (value) {},
                            onSubmitted: (_) {},
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
                                            FocusScope.of(context).unfocus();
                                            WidgetsBinding.instance.addPostFrameCallback((_) {
                                              if (mounted) setState(() {});
                                            });
                                          },
                                        ),
                                        const SizedBox(width: 4),
                                        IconButton(
                                          icon: const Icon(Icons.clear, size: 18),
                                          onPressed: () {
                                            _searchController.clear();
                                            FocusScope.of(context).unfocus();
                                            WidgetsBinding.instance.addPostFrameCallback((_) {
                                              if (mounted) setState(() {});
                                            });
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

                  // Filtered order list - show skeletons while loading, or actual cards when loaded
                  if (isLoading) ...[
                    SliverToBoxAdapter(
                      child: Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 20),
                        child: OrderCardSkeleton(count: 5),
                      ),
                    ),
                  ] else if (_getFilteredOrders(orders).isEmpty && orders.isNotEmpty)
                    SliverToBoxAdapter(
                      child: EmptyStateWidget(
                        icon: Icons.filter_list_off_outlined,
                        title: 'Tidak ada pesanan yang cocok',
                        subtitle: 'Coba ubah filter atau kata kunci pencarian',
                      ),
                    )
                  else if (orders.isEmpty && !isError)
                    SliverToBoxAdapter(
                      child: EmptyStateWidget(
                        icon: Icons.inbox_outlined,
                        title: 'Belum ada pesanan',
                        subtitle: 'Pesanan baru akan muncul di sini',
                      ),
                    )
                  else if (orders.isEmpty && isError)
                    SliverToBoxAdapter(
                      child: EmptyStateWidget(
                        icon: Icons.error_outline,
                        title: 'Gagal memuat data',
                        subtitle: 'Periksa koneksi internet Anda dan coba lagi',
                        actionLabel: 'Coba Lagi',
                        onAction: () => context.read<DashboardCubit>().fetchOrders(),
                      ),
                    )
                  else
                    SliverList(
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

                  const SliverToBoxAdapter(child: SizedBox(height: 20)),
                ],
              ),
            );
          }),
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
        // FIX: Clamp cardWidth to prevent negative values on small screens
        final safeAvailableWidth = availableWidth.clamp(0.0, double.infinity);
        final cardWidth = (safeAvailableWidth - cardSpacing) / 2;

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

  List<Widget> _buildStatsSkeleton(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return [
      Row(
        children: [
          Expanded(
            child: SizedBox(
              height: 100,
              child: Shimmer.fromColors(
                baseColor: isDark ? Colors.grey.shade700 : Colors.grey.shade300,
                highlightColor: isDark ? Colors.grey.shade600 : Colors.grey.shade100,
                child: Container(
                  decoration: BoxDecoration(
                    color: Theme.of(context).colorScheme.surface,
                    borderRadius: BorderRadius.circular(16),
                  ),
                ),
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: SizedBox(
              height: 100,
              child: Shimmer.fromColors(
                baseColor: isDark ? Colors.grey.shade700 : Colors.grey.shade300,
                highlightColor: isDark ? Colors.grey.shade600 : Colors.grey.shade100,
                child: Container(
                  decoration: BoxDecoration(
                    color: Theme.of(context).colorScheme.surface,
                    borderRadius: BorderRadius.circular(16),
                  ),
                ),
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
              height: 100,
              child: Shimmer.fromColors(
                baseColor: isDark ? Colors.grey.shade700 : Colors.grey.shade300,
                highlightColor: isDark ? Colors.grey.shade600 : Colors.grey.shade100,
                child: Container(
                  decoration: BoxDecoration(
                    color: Theme.of(context).colorScheme.surface,
                    borderRadius: BorderRadius.circular(16),
                  ),
                ),
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: SizedBox(
              height: 100,
              child: Shimmer.fromColors(
                baseColor: isDark ? Colors.grey.shade700 : Colors.grey.shade300,
                highlightColor: isDark ? Colors.grey.shade600 : Colors.grey.shade100,
                child: Container(
                  decoration: BoxDecoration(
                    color: Theme.of(context).colorScheme.surface,
                    borderRadius: BorderRadius.circular(16),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    ];
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
