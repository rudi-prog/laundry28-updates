import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:shimmer/shimmer.dart';

import '../../../../core/constants/app_routes.dart';
import '../../../../core/widgets/empty_state_widget.dart';
import '../../../../core/theme/app_colors.dart';
import '../../cubit/auth_cubit.dart';
import '../../cubit/dashboard_cubit.dart';
import '../../cubit/laundry_cubit.dart';
import '../../data/repositories/auth_repository.dart';
import '../../data/models/staff_model.dart';
import '../widgets/order_card.dart';
import '../widgets/order_card_skeleton.dart';
import '../../../../shared/models/order_model.dart';
import 'package:flutter/foundation.dart';

class OwnerDashboardScreen extends StatefulWidget {
  const OwnerDashboardScreen({super.key});

  @override
  State<OwnerDashboardScreen> createState() => _OwnerDashboardScreenState();
}

class _OwnerDashboardScreenState extends State<OwnerDashboardScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  String _selectedStatus = 'Semua';
  final TextEditingController _searchController = TextEditingController();
  final TextEditingController _searchStaffController = TextEditingController();

  static const List<String> _statusFilterOptions = [
    'Semua',
    'Diterima',
    'Dicuci',
    'Dikeringkan',
    'Disetrika',
    'Siap Diambil',
    'Selesai',
  ];

  bool _isStaffLoading = true;
  List<StaffModel> _staffList = [];
  StaffModel? _editingStaff;
  bool _isDeletingStaff = false;
  bool _staffPinVisible = false;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _loadOrders();
    _fetchStaffList();
  }

  void _loadOrders() {
    final laundryCubit = context.read<LaundryCubit>();
    final state = laundryCubit.state;
    if (state is LaundryUnconfigured) {
      // Redirect to setup laundry page
      if (mounted) {
        context.go(AppRoutes.setupLaundry);
      }
      return;
    }
    if (state is LaundryLoaded) {
      context.read<DashboardCubit>().fetchOrders(laundryId: state.laundry.id);
    } else {
      context.read<DashboardCubit>().fetchOrders();
    }
  }

  @override
  void dispose() {
    _tabController.dispose();
    _searchController.dispose();
    _searchStaffController.dispose();
    super.dispose();
  }

  Future<void> _fetchStaffList() async {
    // Check if widget is still mounted before starting
    if (!mounted) return;
    
    try {
      final repository = AuthRepository();
      final laundryCubit = context.read<LaundryCubit>();
      final laundryState = laundryCubit.state;
      int? laundryId;
      debugPrint('🔵 [DASHBOARD] _fetchStaffList() START');
      debugPrint('🔵 [DASHBOARD] LaundryCubit state type: ${laundryState.runtimeType}');
      if (laundryState is LaundryLoaded) {
        laundryId = laundryState.laundry.id;
        debugPrint('🔵 [DASHBOARD] laundryId extracted: $laundryId');
      } else {
        debugPrint('🟡 [DASHBOARD] LaundryCubit state is not LaundryLoaded: ${laundryState.runtimeType}');
      }
      debugPrint('🔵 [DASHBOARD] Calling repository.fetchStaffList(laundryId: $laundryId)...');
      final response = await repository.fetchStaffList(laundryId: laundryId);
      
      // Check if widget is still mounted after async operation
      if (!mounted) return;
      
      debugPrint('🟢 [DASHBOARD] fetchStaffList returned ${response.length} staff members');
      for (var i = 0; i < response.length; i++) {
        final s = response[i];
        debugPrint('🟢 [DASHBOARD]   [$i] id=${s.id}, name=${s.fullName}, laundry_id=${s.laundryId}');
      }
      if (mounted) {
        setState(() {
          _staffList = response;
          _isStaffLoading = false;
        });
        debugPrint('🟢 [DASHBOARD] setState done. _staffList.length = ${_staffList.length}');
      }
    } catch (e) {
      debugPrint('🔴 [DASHBOARD] _fetchStaffList error: $e');
      if (mounted) {
        setState(() => _isStaffLoading = false);
      }
    }
  }

  Future<void> _onRefresh() async {
    final laundryCubit = context.read<LaundryCubit>();
    final state = laundryCubit.state;
    if (state is LaundryUnconfigured) {
      if (mounted) {
        Navigator.of(context).pushNamed('/setup-laundry');
      }
      return;
    }
    if (state is LaundryLoaded) {
      await Future.wait([
        context.read<DashboardCubit>().fetchOrders(laundryId: state.laundry.id),
        _fetchStaffList(),
      ]);
    } else {
      await Future.wait([
        context.read<DashboardCubit>().fetchOrders(),
        _fetchStaffList(),
      ]);
    }
    await Future.delayed(const Duration(milliseconds: 600));
  }

  List<OrderModel> _getFilteredOrders(List<OrderModel> orders) {
    var filtered = orders;
    if (_selectedStatus != 'Semua') {
      filtered = filtered.where((o) => o.status == _selectedStatus).toList();
    }
    final query = _searchController.text.trim().toLowerCase();
    if (query.isNotEmpty) {
      filtered = filtered.where((o) {
        return o.trackingCode.toLowerCase().contains(query) ||
            o.customerName.toLowerCase().contains(query) ||
            o.customerPhone.contains(query);
      }).toList();
    }
    filtered.sort((a, b) => b.createdAt.compareTo(a.createdAt));
    return filtered;
  }

  List<StaffModel> _getFilteredStaff(List<StaffModel> staff) {
    final query = _searchStaffController.text.trim().toLowerCase();
    if (query.isEmpty) return staff;
    return staff
        .where((s) =>
            s.fullName.toLowerCase().contains(query) ||
            s.email.toLowerCase().contains(query) ||
            (s.username ?? '').toLowerCase().contains(query) ||
            s.role.toLowerCase().contains(query))
        .toList();
  }

  @override
  Widget build(BuildContext context) {
    return BlocListener<AuthCubit, AuthState>(
      listener: (context, state) {
        if (state is AuthUnauthenticated) {
          context.go('/login');
        }
      },
      child: BlocListener<LaundryCubit, LaundryState>(
        listener: (context, state) {
          if (state is LaundryUnconfigured && context.mounted) {
            print('🔀 [DASHBOARD] Laundry belum disetup, redirect ke setup');
            context.go(AppRoutes.setupLaundry);
          } else if (state is LaundryLoaded) {
            // Re-load orders AND staff when laundry becomes available (e.g. after setup)
            print('🔄 [DASHBOARD] Laundry loaded, re-fetching orders for: ${state.laundry.id}');
            context.read<DashboardCubit>().fetchOrders(laundryId: state.laundry.id);
            _fetchStaffList();
          }
        },
        child: Scaffold(
          backgroundColor: AppColors.background,
          appBar: AppBar(
          backgroundColor: AppColors.primary,
          foregroundColor: Colors.white,
          title: BlocBuilder<LaundryCubit, LaundryState>(
            builder: (context, laundryState) {
              String laundryTitle = 'Dashboard Owner';
              if (laundryState is LaundryLoaded) {
                laundryTitle = 'Dashboard Owner - ${laundryState.laundry.name}';
              } else if (laundryState is LaundryLoading) {
                laundryTitle = 'Dashboard Owner';
              } else if (laundryState is LaundryUnconfigured) {
                laundryTitle = 'Dashboard Owner (Laundry Belum Disetup)';
              }
              return Text(
                laundryTitle,
                style: const TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 0.5,
                ),
              );
            },
          ),
          elevation: 0,
          bottom: TabBar(
            controller: _tabController,
            indicatorColor: Colors.white,
            labelColor: Colors.white,
            unselectedLabelColor: Colors.white70,
            tabs: const [
              Tab(icon: Icon(Icons.bar_chart), text: 'Analytics'),
              Tab(icon: Icon(Icons.people), text: 'Staff'),
            ],
          ),
          actions: [
            IconButton(
              icon: const Icon(Icons.refresh),
              onPressed: _onRefresh,
            ),
            PopupMenuButton<MenuChoice>(
              icon: const CircleAvatar(
                radius: 14,
                backgroundColor: Colors.white24,
                child: Icon(Icons.person, size: 18),
              ),
              itemBuilder: (context) => <PopupMenuEntry<MenuChoice>>[
                const PopupMenuItem(
                  value: MenuChoice.view,
                  child: Row(
                    children: [
                      Icon(Icons.visibility, size: 20),
                      SizedBox(width: 12),
                      Text('Profile'),
                    ],
                  ),
                ),
                const PopupMenuDivider(),
                PopupMenuItem<MenuChoice>(
                  value: MenuChoice.delete,
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
                if (value == MenuChoice.delete) {
                  context.read<AuthCubit>().logout();
                }
              },
            ),
          ],
        ),
        body: TabBarView(
          controller: _tabController,
          children: [_buildAnalyticsTab(), _buildStaffTab()],
        ),
        floatingActionButton: _tabController.index == 1
            ? FloatingActionButton.extended(
                onPressed: _showAddStaffDialog,
                backgroundColor: AppColors.primary,
                foregroundColor: Colors.white,
                icon: const Icon(Icons.person_add),
                label: const Text('Tambah Staff'),
              )
            : null,
      ),
    ),
  );
  }

  // ==================== ANALYTICS TAB ====================

  Widget _buildAnalyticsTab() {
    return BlocBuilder<DashboardCubit, DashboardState>(
      builder: (context, state) {
        final List<OrderModel> orders;
        final bool isLoading =
            state is DashboardLoading || state is DashboardInitial;
        final bool isError = state is DashboardError;

        if (state is DashboardLoaded) {
          orders = state.orders;
        } else if (state is DashboardLoading) {
          orders = state.previousOrders;
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
                        'Selamat Datang \u{1f44b}',
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
                        DateFormat('EEEE, dd MMMM yyyy', 'id_ID')
                            .format(DateTime.now()),
                        style: TextStyle(
                          fontSize: 14,
                          color: AppColors.textSecondary,
                        ),
                      ),
                      const SizedBox(height: 24),
                      if (isLoading && orders.isEmpty)
                        ..._buildAnalyticsSkeleton(context),
                      if (!isLoading || orders.isNotEmpty)
                        _buildAnalyticsStats(orders),
                      const SizedBox(height: 24),
                      TextField(
                        controller: _searchController,
                        decoration: InputDecoration(
                          hintText: 'Cari pesanan...',
                          prefixIcon: const Icon(Icons.search),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          filled: true,
                          fillColor: AppColors.surface,
                        ),
                        onChanged: (_) {},
                      ),
                      const SizedBox(height: 16),
                      SizedBox(
                        height: 40,
                        child: ListView.builder(
                          scrollDirection: Axis.horizontal,
                          itemCount: _statusFilterOptions.length,
                          itemBuilder: (context, index) {
                            final status = _statusFilterOptions[index];
                            final isSelected = _selectedStatus == status;
                            return Padding(
                              padding: const EdgeInsets.only(right: 8),
                              child: FilterChip(
                                label: Text(status),
                                selected: isSelected,
                                onSelected: (_) {
                                  setState(() => _selectedStatus = status);
                                },
                                selectedColor:
                                    AppColors.primary.withValues(alpha: 0.15),
                                checkmarkColor: AppColors.primary,
                                backgroundColor: AppColors.surface,
                                side: BorderSide(
                                  color: isSelected
                                      ? AppColors.primary
                                      : AppColors.border,
                                ),
                              ),
                            );
                          },
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  child: Text(
                    'Daftar Pesanan',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: AppColors.textPrimary,
                    ),
                  ),
                ),
              ),
              const SliverToBoxAdapter(
                child: SizedBox(height: 8),
              ),
              if (isLoading)
                const SliverToBoxAdapter(
                  child: OrderCardSkeleton(count: 5),
                )
              else if (isError || orders.isEmpty)
                const SliverToBoxAdapter(
                  child: EmptyStateWidget(
                    icon: Icons.receipt_long_outlined,
                    title: 'Belum Ada Pesanan',
                    subtitle:
                        'Pesanan akan muncul di sini saat ada order baru.',
                  ),
                )
              else
                SliverList(
                  delegate: SliverChildBuilderDelegate(
                    (context, index) {
                      final filteredOrders = _getFilteredOrders(orders);
                      if (index >= filteredOrders.length) {
                        return const SizedBox.shrink();
                      }
                      final order = filteredOrders[index];
                      return Padding(
                        padding: const EdgeInsets.only(
                          left: 20,
                          right: 20,
                          bottom: 12,
                        ),
                        child: OrderCard(
                          order: order,
                        ),
                      );
                    },
                    childCount: isLoading ? 5 : orders.length,
                  ),
                ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildAnalyticsStats(List<OrderModel> orders) {
    final totalOrders = orders.length;
    final readyCount =
        orders.where((o) => o.status == 'Siap Diambil').length;
    final inProgressCount = orders
        .where((o) => !["Siap Diambil", "Selesai"].contains(o.status))
        .length;
    final completedCount =
        orders.where((o) => o.status == 'Selesai').length;

    final totalRevenue = orders
        .where((o) => o.totalPrice != null)
        .fold(0.0, (sum, o) => sum + (o.totalPrice ?? 0));

    return Column(
      children: [
        _buildRevenueCard(totalRevenue),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(
              child: _buildStatCard(
                title: "Total Pesanan",
                value: totalOrders.toString(),
                icon: Icons.shopping_bag_outlined,
                color: AppColors.primary,
                gradient: const LinearGradient(
                    colors: [AppColors.primary, AppColors.primaryLight]),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _buildStatCard(
                title: "Dalam Proses",
                value: inProgressCount.toString(),
                icon: Icons.pending_outlined,
                color: AppColors.warning,
                gradient: const LinearGradient(
                    colors: [AppColors.warning, Color(0xFFFCD34D)]),
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(
              child: _buildStatCard(
                title: "Siap Diambil",
                value: readyCount.toString(),
                icon: Icons.check_circle_outline,
                color: AppColors.success,
                gradient: const LinearGradient(
                    colors: [AppColors.success, Color(0xFF6EE7B7)]),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _buildStatCard(
                title: "Selesai",
                value: completedCount.toString(),
                icon: Icons.done_all,
                color: AppColors.textSecondary,
                gradient: const LinearGradient(
                    colors: [
                      AppColors.textSecondary,
                      AppColors.textTertiary
                    ]),
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildRevenueCard(double revenue) {
    return Container(
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF667EEA), Color(0xFF764BA2)],
        ),
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF667EEA).withValues(alpha: 0.3),
            blurRadius: 8,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.2),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Icon(
                    Icons.attach_money,
                    color: Colors.white,
                    size: 24,
                  ),
                ),
                const SizedBox(width: 12),
                const Text(
                  'Total Pendapatan',
                  style: TextStyle(
                    color: Colors.white70,
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Text(
              NumberFormat.currency(
                locale: 'id_ID',
                symbol: 'Rp ',
                decimalDigits: 0,
              ).format(revenue),
              style: const TextStyle(
                fontSize: 28,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),
          ],
        ),
      ),
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
          BoxShadow(
            color: color.withValues(alpha: 0.3),
            blurRadius: 8,
            offset: const Offset(0, 4),
          ),
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
              style: const TextStyle(
                fontSize: 28,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              title,
              style: TextStyle(
                fontSize: 12,
                color: Colors.white.withValues(alpha: 0.9),
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
    );
  }

  List<Widget> _buildAnalyticsSkeleton(BuildContext context) {
    final shimmerColor = Colors.grey[300]!;
    final highlightColor = Colors.grey[100]!;
    return [
      Shimmer.fromColors(
        baseColor: shimmerColor,
        highlightColor: highlightColor,
        child: Container(
          height: 120,
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
          ),
        ),
      ),
      const SizedBox(height: 12),
      Row(
        children: [
          Expanded(
            child: Shimmer.fromColors(
              baseColor: shimmerColor,
              highlightColor: highlightColor,
              child: Container(
                height: 100,
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16),
                ),
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Shimmer.fromColors(
              baseColor: shimmerColor,
              highlightColor: highlightColor,
              child: Container(
                height: 100,
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16),
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
            child: Shimmer.fromColors(
              baseColor: shimmerColor,
              highlightColor: highlightColor,
              child: Container(
                height: 100,
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16),
                ),
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Shimmer.fromColors(
              baseColor: shimmerColor,
              highlightColor: highlightColor,
              child: Container(
                height: 100,
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16),
                ),
              ),
            ),
          ),
        ],
      ),
    ];
  }

  Widget _buildStaffTab() {
    return BlocBuilder<DashboardCubit, DashboardState>(
      builder: (context, state) {
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
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text(
                            'Manajemen Karyawan',
                            style: TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
                              color: AppColors.textPrimary,
                            ),
                          ),
                          ElevatedButton.icon(
                            onPressed: _isStaffLoading
                                ? null
                                : () => _showStaffFormDialog(),
                            icon: const Icon(Icons.add, size: 18),
                            label: const Text('Tambah'),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: AppColors.primary,
                              foregroundColor: Colors.white,
                              padding: const EdgeInsets.symmetric(
                                horizontal: 16,
                                vertical: 10,
                              ),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(10),
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),
                      TextField(
                        controller: _searchStaffController,
                        decoration: InputDecoration(
                          hintText: 'Cari karyawan...',
                          prefixIcon: const Icon(Icons.search),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          filled: true,
                          fillColor: AppColors.surface,
                        ),
                        onChanged: (_) {},
                      ),
                    ],
                  ),
                ),
              ),
              if (_isStaffLoading)
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 20),
                    child: Column(
                      children: [
                        _buildStaffCardSkeleton(),
                        const SizedBox(height: 12),
                        _buildStaffCardSkeleton(),
                        const SizedBox(height: 12),
                        _buildStaffCardSkeleton(),
                      ],
                    ),
                  ),
                )
              else if (_staffList.isEmpty)
                const SliverToBoxAdapter(
                  child: EmptyStateWidget(
                    icon: Icons.people_outline,
                    title: 'Belum Ada Karyawan',
                    subtitle:
                        'Tambahkan karyawan untuk mengelola tim laundry Anda.',
                  ),
                )
              else
                SliverPadding(
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  sliver: SliverList(
                    delegate: SliverChildBuilderDelegate(
                      (context, index) {
                        final filteredStaff = _getFilteredStaff(_staffList);
                        if (index >= filteredStaff.length) {
                          return const SizedBox.shrink();
                        }
                        final staff = filteredStaff[index];
                        return Padding(
                          padding: const EdgeInsets.only(bottom: 12),
                          child: _buildStaffCard(staff),
                        );
                      },
                      childCount: _staffList.length,
                    ),
                  ),
                ),
            ],
          ),
        );
      },
    );
  }

  /// Build a skeleton card for staff loading state
  Widget _buildStaffCardSkeleton() {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.border.withValues(alpha: 0.5)),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [AppColors.primary, AppColors.primaryLight],
                ),
                borderRadius: BorderRadius.circular(14),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    height: 14,
                    width: 120,
                    decoration: BoxDecoration(
                      color: AppColors.textTertiary.withValues(alpha: 0.2),
                      borderRadius: BorderRadius.circular(4),
                    ),
                  ),
                  const SizedBox(height: 8),
                  Container(
                    height: 10,
                    width: 80,
                    decoration: BoxDecoration(
                      color: AppColors.textTertiary.withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(4),
                    ),
                  ),
                ],
              ),
            ),
            Container(
              width: 32,
              height: 32,
              decoration: BoxDecoration(
                color: AppColors.textTertiary.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(8),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStaffCard(StaffModel staff) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.border.withValues(alpha: 0.5)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () => _showStaffDetailDialog(staff),
          borderRadius: BorderRadius.circular(16),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                Container(
                  width: 56,
                  height: 56,
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [
                        AppColors.primary,
                        AppColors.primaryLight,
                      ],
                    ),
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: Icon(
                    Icons.person_outline,
                    color: Colors.white,
                    size: 28,
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        staff.fullName,
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                          color: AppColors.textPrimary,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 4),
                      Text(
                        staff.role,
                        style: TextStyle(
                          fontSize: 13,
                          color: AppColors.textSecondary,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Row(
                        children: [
                          Icon(
                            Icons.email_outlined,
                            size: 12,
                            color: AppColors.textTertiary,
                          ),
                          const SizedBox(width: 4),
                          Flexible(
                            child: Text(
                              staff.email,
                              style: TextStyle(
                                fontSize: 12,
                                color: AppColors.textTertiary,
                              ),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                PopupMenuButton<MenuChoice>(
                  icon: Icon(
                    Icons.more_vert,
                    color: AppColors.textSecondary,
                  ),
                  itemBuilder: (context) => [
                    const PopupMenuItem(
                      value: MenuChoice.view,
                      child: Row(
                        children: [
                          Icon(Icons.visibility, size: 18),
                          SizedBox(width: 8),
                          Text('Lihat Detail'),
                        ],
                      ),
                    ),
                    const PopupMenuItem(
                      value: MenuChoice.edit,
                      child: Row(
                        children: [
                          Icon(Icons.edit, size: 18),
                          SizedBox(width: 8),
                          Text('Edit'),
                        ],
                      ),
                    ),
                    const PopupMenuDivider(),
                    const PopupMenuItem(
                      value: MenuChoice.delete,
                      child: Row(
                        children: [
                          Icon(Icons.delete, size: 18, color: Colors.red),
                          SizedBox(width: 8),
                          Text('Hapus', style: TextStyle(color: Colors.red)),
                        ],
                      ),
                    ),
                  ],
                  onSelected: (choice) {
                    switch (choice) {
                      case MenuChoice.view:
                        _showStaffDetailDialog(staff);
                        break;
                      case MenuChoice.edit:
                        _showEditStaffDialog(staff);
                        break;
                      case MenuChoice.delete:
                        _confirmDeleteStaff(staff);
                        break;
                    }
                  },
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  void _showAddStaffDialog() {
    _editingStaff = null;
    _showStaffFormDialog();
  }

  void _showEditStaffDialog(StaffModel staff) {
    _editingStaff = staff;
    _showStaffFormDialog();
  }

  void _showStaffFormDialog() {
    final isEditing = _editingStaff != null;
    final nc = TextEditingController(text: isEditing ? _editingStaff!.fullName : '');
    final uc = TextEditingController(text: isEditing ? (_editingStaff!.username ?? '') : '');
    final pw = TextEditingController(text: isEditing ? (_editingStaff!.hasPinHash ? '••••' : '') : '');
    final _formKey = GlobalKey<FormState>();

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(isEditing ? 'Edit Karyawan' : 'Tambah Karyawan'),
        content: SingleChildScrollView(
          child: Form(
            key: _formKey,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextFormField(
                  controller: nc,
                  decoration: const InputDecoration(
                    labelText: 'Nama Lengkap',
                    prefixIcon: Icon(Icons.person_outline),
                    border: OutlineInputBorder(),
                  ),
                  validator: (v) => (v == null || v.isEmpty) ? 'Nama tidak boleh kosong' : null,
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: uc,
                  decoration: const InputDecoration(
                    labelText: 'Username',
                    prefixIcon: Icon(Icons.person_outline),
                    border: OutlineInputBorder(),
                  ),
                  textCapitalization: TextCapitalization.none,
                  validator: (v) => (v == null || v.isEmpty) ? 'Username tidak boleh kosong' : null,
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: pw,
                  decoration: InputDecoration(
                    labelText: isEditing
                        ? 'PIN (4-6 digit, kosongkan jika tidak diubah)'
                        : 'PIN (4-6 digit)',
                    prefixIcon: const Icon(Icons.pin_outlined),
                    suffixIcon: IconButton(
                      icon: Icon(
                        _staffPinVisible
                            ? Icons.visibility_outlined
                            : Icons.visibility_off_outlined,
                      ),
                      onPressed: () {
                        setState(() {
                          _staffPinVisible = !_staffPinVisible;
                        });
                      },
                    ),
                    border: const OutlineInputBorder(),
                    hintText: 'Masukkan PIN 4-6 digit',
                  ),
                  obscureText: !_staffPinVisible,
                  keyboardType: TextInputType.number,
                  maxLength: 6,
                  validator: (v) {
                    if (v == null || v.isEmpty) {
                      return 'PIN harus diisi';
                    }
                    if (v.length < 4 || v.length > 6) {
                      return 'PIN harus 4-6 digit';
                    }
                    if (!RegExp(r'^\d+$').hasMatch(v)) {
                      return 'PIN hanya boleh angka';
                    }
                    return null;
                  },
                ),
              ],
            ),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Batal'),
          ),
          ElevatedButton(
            onPressed: () async {
              if (_formKey.currentState!.validate()) {
                Navigator.pop(context);
                if (isEditing) {
                  await _updateStaff(
                    _editingStaff!.id ?? 0,
                    nc.text,
                    uc.text,
                    pw.text,
                  );
                } else {
                  await _createStaff(nc.text, uc.text, pw.text);
                }
              }
            },
            child: Text(isEditing ? 'Simpan' : 'Tambah'),
          ),
        ],
      ),
    );
  }

  Future<void> _createStaff(
    String fullName,
    String username,
    String pin,
  ) async {
    debugPrint('🔵 [DASHBOARD] _createStaff() START — fullName=$fullName, username=$username');
    setState(() => _isStaffLoading = true);
    try {
      final repository = AuthRepository();
      final laundryCubit = context.read<LaundryCubit>();

      // Check current state synchronously first to avoid hanging on await for
      // if the cubit is already in a terminal state
      int? laundryId;
      final currentState = laundryCubit.state;
      
      if (currentState is LaundryLoaded) {
        laundryId = currentState.laundry.id;
        debugPrint('🟢 [DASHBOARD] LaundryLoaded from current state — id=$laundryId');
      } else if (currentState is LaundryUnconfigured) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Laundry belum dikonfigurasi. Silakan setup laundry terlebih dahulu.'),
              duration: Duration(seconds: 4),
            ),
          );
        }
        setState(() => _isStaffLoading = false);
        return;
      } else if (currentState is LaundryError) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Gagal memuat data laundry: ${currentState.message}'),
              duration: const Duration(seconds: 4),
            ),
          );
        }
        setState(() => _isStaffLoading = false);
        return;
      } else {
        // State is LaundryLoading or LaundryInitial — wait for it to change
        debugPrint('🔵 [DASHBOARD] Waiting for LaundryCubit stream (current: ${currentState.runtimeType})...');
        await for (final state in laundryCubit.stream) {
          debugPrint('🔵 [DASHBOARD] LaundryCubit stream event: ${state.runtimeType}');
          if (state is LaundryLoaded) {
            laundryId = state.laundry.id;
            debugPrint('🟢 [DASHBOARD] LaundryLoaded captured — id=$laundryId');
            break;
          } else if (state is LaundryUnconfigured) {
            if (mounted) {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Laundry belum dikonfigurasi. Silakan setup laundry terlebih dahulu.'),
                  duration: Duration(seconds: 4),
                ),
              );
            }
            setState(() => _isStaffLoading = false);
            return;
          } else if (state is LaundryError) {
            if (mounted) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text('Gagal memuat data laundry: ${state.message}'),
                  duration: const Duration(seconds: 4),
                ),
              );
            }
            setState(() => _isStaffLoading = false);
            return;
          }
          // Continue waiting if state is LaundryLoading or LaundryInitial
        }
      }

      // Verify laundryId was captured
      if (laundryId == null) {
        debugPrint('🔴 [DASHBOARD] FATAL: laundryId is still null after state check');
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Gagal memuat data laundry'),
              duration: Duration(seconds: 4),
            ),
          );
        }
        setState(() => _isStaffLoading = false);
        return;
      }

      if (pin.isEmpty) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('PIN harus diisi untuk karyawan baru.'),
              duration: Duration(seconds: 4),
            ),
          );
        }
        setState(() => _isStaffLoading = false);
        return;
      }

      debugPrint('🔵 [DASHBOARD] Calling repository.createStaff(laundryId=$laundryId)...');
      await repository.createStaff(
        fullName: fullName,
        username: username,
        pin: pin,
        laundryId: laundryId,
      );
      debugPrint('🟢 [DASHBOARD] repository.createStaff() completed successfully');

      // Check staff list BEFORE re-fetching
      debugPrint('🔵 [DASHBOARD] Staff list BEFORE _fetchStaffList: ${_staffList.length} items');

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Karyawan berhasil ditambahkan')),
        );
      }
      debugPrint('🔵 [DASHBOARD] Calling _fetchStaffList() after create...');
      await _fetchStaffList();
      debugPrint('🟢 [DASHBOARD] _createStaff() completed. New staff list length: ${_staffList.length}');
    } catch (e) {
      debugPrint('🔴 [DASHBOARD] createStaff error: $e');
      if (kDebugMode) {
        print('🔴 [DASHBOARD] createStaff error: $e');
      }
      String errorMessage;
      if (e is Exception) {
        errorMessage = e.toString();
      } else if (e is String) {
        errorMessage = e;
      } else {
        errorMessage = 'Terjadi kesalahan yang tidak diketahui';
      }
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Gagal menambahkan karyawan: $errorMessage'),
            duration: const Duration(seconds: 4),
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isStaffLoading = false);
      }
    }
  }

  Future<void> _updateStaff(
    int id,
    String fullName,
    String username,
    String pin,
  ) async {
    setState(() => _isStaffLoading = true);
    try {
      final repository = AuthRepository();
      await repository.updateStaff(
        id: id,
        fullName: fullName,
        username: username,
        pin: pin,
      );
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Karyawan berhasil diperbarui')),
        );
      }
      await _fetchStaffList();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Gagal memperbarui karyawan: $e')),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isStaffLoading = false);
      }
    }
  }

  void _confirmDeleteStaff(StaffModel staff) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Hapus Karyawan'),
        content: Text(
          'Apakah Anda yakin ingin menghapus karyawan "${staff.fullName}"? Tindakan ini tidak dapat dibatalkan.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Batal'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              _deleteStaff(staff);
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              foregroundColor: Colors.white,
            ),
            child: const Text('Hapus'),
          ),
        ],
      ),
    );
  }

  Future<void> _deleteStaff(StaffModel staff) async {
    setState(() => _isDeletingStaff = true);
    try {
      final repository = AuthRepository();
      final staffId = staff.id;
      if (staffId == null) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('ID karyawan tidak valid')),
          );
        }
        return;
      }
      await repository.deleteStaff(staffId);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Karyawan berhasil dihapus')),
        );
      }
      await _fetchStaffList();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Gagal menghapus karyawan: $e')),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isDeletingStaff = false);
      }
    }
  }

  void _showStaffDetailDialog(StaffModel staff) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Detail Karyawan'),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    width: 64,
                    height: 64,
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [AppColors.primary, AppColors.primaryLight],
                      ),
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: const Icon(
                      Icons.person,
                      color: Colors.white,
                      size: 32,
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          staff.fullName,
                          style: const TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: AppColors.textPrimary,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 4,
                          ),
                          decoration: BoxDecoration(
                            color: AppColors.primary.withValues(alpha: 0.1),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Text(
                            staff.role,
                            style: TextStyle(
                              fontSize: 12,
                              color: AppColors.primary,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 24),
              _buildDetailRow(Icons.person_outline, 'Nama Lengkap', staff.fullName),
              const SizedBox(height: 16),
              _buildDetailRow(Icons.person_outline, 'Username', staff.username ?? '-'),
              const SizedBox(height: 16),
              _buildDetailRow(Icons.email_outlined, 'Email', staff.email),
              const SizedBox(height: 16),
              _buildDetailRow(Icons.badge_outlined, 'Role', staff.role),
              const SizedBox(height: 16),
              _buildDetailRow(
                Icons.access_time,
                'Terdaftar',
                DateFormat('dd MMM yyyy, HH:mm', 'id_ID').format(staff.createdAt),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Tutup'),
          ),
          ElevatedButton.icon(
            onPressed: () {
              Navigator.pop(context);
              _showEditStaffDialog(staff);
            },
            icon: const Icon(Icons.edit, size: 18),
            label: const Text('Edit'),
          ),
        ],
      ),
    );
  }

  Widget _buildDetailRow(IconData icon, String label, String value) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, size: 20, color: AppColors.primary),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: TextStyle(
                  fontSize: 12,
                  color: AppColors.textSecondary,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                value,
                style: const TextStyle(
                  fontSize: 14,
                  color: AppColors.textPrimary,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

enum MenuChoice { view, edit, delete }
