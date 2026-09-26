import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import 'package:laundry28/core/theme/app_colors.dart';
import 'package:laundry28/features/owner1/cubit/staff_cubit.dart';
import 'package:laundry28/features/owner1/cubit/staff_state.dart';
import 'package:laundry28/features/super_admin/cubit/laundry_cubit.dart';
import 'package:laundry28/features/super_admin/data/models/laundry_model.dart';

import 'package:laundry28/features/owner1/data/models/staff_model.dart';

import 'staff_add_dialog.dart';
import 'staff_delete_dialog.dart';
import 'staff_edit_dialog.dart';

class StaffScreen extends StatefulWidget {
  const StaffScreen({super.key});

  @override
  State<StaffScreen> createState() => _StaffScreenState();
}

class _StaffScreenState extends State<StaffScreen> {
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';
  StreamSubscription<LaundryState>? _laundrySubscription;

  @override
  void initState() {
    super.initState();
    _laundrySubscription = context.read<LaundryCubit>().stream.listen((state) {
      if (state is LaundryLoaded && mounted) {
        _loadStaff();
      }
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    _laundrySubscription?.cancel();
    super.dispose();
  }

  void _loadStaff() {
    final laundryCubit = context.read<LaundryCubit>();
    final laundryState = laundryCubit.state;
    if (laundryState is LaundryLoaded) {
      final laundryId = laundryState.laundry.id;
      context.read<StaffCubit>().fetchAllStaff(laundryId);
    }
  }

  List<StaffModel> _filterStaff(List<StaffModel> staff) {
    if (_searchQuery.isEmpty) return staff;
    return staff
        .where(
          (s) =>
              s.fullName.toLowerCase().contains(_searchQuery.toLowerCase()) ||
              (s.username ?? '').toLowerCase().contains(_searchQuery.toLowerCase()) ||
              s.email.toLowerCase().contains(_searchQuery.toLowerCase()),
        )
        .toList();
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
                                    Icons.people_rounded,
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
                                      'Staff',
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
                        onRefresh: () async => _loadStaff(),
                        child: CustomScrollView(
                          slivers: [
                            SliverToBoxAdapter(
                              child: Padding(
                                padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
                                child: TextField(
                                  controller: _searchController,
                                  onChanged: (v) => setState(() => _searchQuery = v),
                                  decoration: InputDecoration(
                                    hintText: 'Cari staff berdasarkan nama, username, atau email',
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
                            ),
                            BlocListener<StaffCubit, StaffState>(
                              listener: (context, state) {
                                if (state is StaffActionSuccess) {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    SnackBar(
                                      content: Text(
                                        state.action == 'created'
                                            ? 'Staff member added successfully'
                                            : state.action == 'updated'
                                                ? 'Staff member updated successfully'
                                                : 'Staff member deleted successfully',
                                      ),
                                      backgroundColor: AppColors.success,
                                      behavior: SnackBarBehavior.floating,
                                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                                    ),
                                  );
                                }
                              },
                              child: BlocBuilder<StaffCubit, StaffState>(
                                builder: (context, state) {
                                  if (state is StaffLoading) {
                                    return const SliverFillRemaining(
                                      hasScrollBody: false,
                                      child: Center(child: CircularProgressIndicator()),
                                    );
                                  }
                                  if (state is StaffError) {
                                    return SliverFillRemaining(
                                      hasScrollBody: false,
                                      child: Center(
                                        child: Column(
                                          mainAxisAlignment: MainAxisAlignment.center,
                                          children: [
                                            Icon(Icons.error_outline, size: 64, color: AppColors.error),
                                            const SizedBox(height: 12),
                                            Text('Gagal memuat staff', style: TextStyle(fontSize: 15, fontWeight: FontWeight.w500, color: AppColors.textSecondary)),
                                            const SizedBox(height: 4),
                                            Text(state.message, style: TextStyle(fontSize: 13, color: AppColors.textTertiary)),
                                            const SizedBox(height: 16),
                                            ElevatedButton(
                                              onPressed: _loadStaff,
                                              child: const Text('Coba Lagi'),
                                            ),
                                          ],
                                        ),
                                      ),
                                    );
                                  }
                                  final staff = state is StaffLoaded ? state.staffList : <StaffModel>[];
                                  final filtered = _filterStaff(staff);

                                  return SliverPadding(
                                    padding: const EdgeInsets.symmetric(horizontal: 16),
                                    sliver: SliverList(
                                      delegate: SliverChildBuilderDelegate(
                                        (context, index) {
                                          if (filtered.isEmpty) {
                                            return Container(
                                              padding: const EdgeInsets.symmetric(vertical: 48),
                                              child: Center(
                                                child: Column(
                                                  mainAxisAlignment: MainAxisAlignment.center,
                                                  children: [
                                                    Icon(Icons.person_off_rounded, size: 64, color: AppColors.textTertiary),
                                                    const SizedBox(height: 12),
                                                    Text('Belum ada staff', style: TextStyle(fontSize: 15, fontWeight: FontWeight.w500, color: AppColors.textSecondary)),
                                                    const SizedBox(height: 4),
                                                    Text('Tekan tombol + untuk menambah staff', style: TextStyle(fontSize: 13, color: AppColors.textTertiary)),
                                                  ],
                                                ),
                                              ),
                                            );
                                          }
                                          final s = filtered[index];
                                          return Padding(
                                            padding: const EdgeInsets.only(bottom: 8),
                                            child: Card(
                                              elevation: 0,
                                              color: Colors.white,
                                              shape: RoundedRectangleBorder(
                                                borderRadius: BorderRadius.circular(12),
                                                side: BorderSide(color: const Color(0xFFE2E8F0)),
                                              ),
                                              child: ListTile(
                                                contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                                                leading: CircleAvatar(
                                                  radius: 22,
                                                  backgroundColor: s.isOwner
                                                      ? AppColors.primary.withValues(alpha: 0.1)
                                                      : AppColors.infoLight,
                                                  child: Icon(
                                                    Icons.person_rounded,
                                                    color: s.isOwner ? AppColors.primary : AppColors.info,
                                                    size: 20,
                                                  ),
                                                ),
                                                title: Text(
                                                  s.fullName,
                                                  style: const TextStyle(
                                                    fontSize: 14,
                                                    fontWeight: FontWeight.w600,
                                                    color: AppColors.textPrimary,
                                                  ),
                                                  maxLines: 1,
                                                  overflow: TextOverflow.ellipsis,
                                                ),
                                                subtitle: Column(
                                                  crossAxisAlignment: CrossAxisAlignment.start,
                                                  children: [
                                                    const SizedBox(height: 4),
                                                    Text(
                                                      s.email,
                                                      style: TextStyle(
                                                        fontSize: 12,
                                                        color: AppColors.textSecondary,
                                                      ),
                                                      maxLines: 1,
                                                      overflow: TextOverflow.ellipsis,
                                                    ),
                                                    const SizedBox(height: 4),
                                                    Wrap(
                                                      spacing: 6,
                                                      runSpacing: 4,
                                                      children: [
                                                        Container(
                                                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                                                          decoration: BoxDecoration(
                                                            color: s.isOwner
                                                                ? AppColors.primary.withValues(alpha: 0.1)
                                                                : AppColors.infoLight,
                                                            borderRadius: BorderRadius.circular(8),
                                                          ),
                                                          child: Text(
                                                            s.isOwner ? 'Owner' : 'Employee',
                                                            style: TextStyle(
                                                              fontSize: 11,
                                                              color: s.isOwner ? AppColors.primary : AppColors.info,
                                                              fontWeight: FontWeight.w500,
                                                            ),
                                                          ),
                                                        ),
                                                        if (s.username != null) ...[
                                                          Container(
                                                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                                                            decoration: BoxDecoration(
                                                              color: AppColors.successLight,
                                                              borderRadius: BorderRadius.circular(8),
                                                            ),
                                                            child: Text(
                                                              '@${s.username}',
                                                              style: const TextStyle(
                                                                fontSize: 11,
                                                                color: AppColors.success,
                                                                fontWeight: FontWeight.w500,
                                                              ),
                                                            ),
                                                          ),
                                                        ],
                                                      ],
                                                    ),
                                                  ],
                                                ),
                                                trailing: s.isOwner
                                                    ? null
                                                    : Row(
                                                        mainAxisSize: MainAxisSize.min,
                                                        children: [
                                                          IconButton(
                                                            icon: Icon(
                                                              Icons.edit_outlined,
                                                              color: AppColors.primary,
                                                              size: 20,
                                                            ),
                                                            onPressed: () => showEditStaffDialog(context, s),
                                                          ),
                                                          IconButton(
                                                            icon: Icon(
                                                              Icons.delete_outline,
                                                              color: AppColors.error,
                                                              size: 20,
                                                            ),
                                                            onPressed: () => showConfirmDeleteStaff(context, s),
                                                          ),
                                                        ],
                                                      ),
                                              ),
                                            ),
                                          );
                                        },
                                        childCount: filtered.isEmpty ? 1 : filtered.length,
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
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () async {
          await showAddStaffDialog(context);
          _loadStaff();
        },
        backgroundColor: AppColors.primary,
        foregroundColor: AppColors.textOnPrimary,
        icon: const Icon(Icons.person_add),
        label: const Text('Add Staff'),
      ),
    );
  }
}
