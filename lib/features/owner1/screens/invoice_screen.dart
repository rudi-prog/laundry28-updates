import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import 'package:laundry28/core/theme/app_colors.dart';
import 'package:laundry28/core/widgets/loading_indicator.dart';
import 'package:laundry28/features/super_admin/cubit/invoice_cubit.dart';
import 'package:laundry28/features/super_admin/cubit/invoice_state.dart';
import 'package:laundry28/features/super_admin/data/models/invoice_model.dart';

class InvoiceScreen extends StatefulWidget {
  final int laundryId;

  const InvoiceScreen({super.key, required this.laundryId});

  @override
  State<InvoiceScreen> createState() => _InvoiceScreenState();
}

class _InvoiceScreenState extends State<InvoiceScreen> {
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';
  String _filterStatus = 'all';

  @override
  void initState() {
    super.initState();
    context.read<InvoiceCubit>().fetchOwnerInvoices(widget.laundryId);
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _refresh() {
    _searchController.clear();
    setState(() {
      _searchQuery = '';
      _filterStatus = 'all';
    });
    context.read<InvoiceCubit>().fetchOwnerInvoices(widget.laundryId);
  }

  List<InvoiceModel> _filterInvoices(List<InvoiceModel> invoices) {
    var result = invoices;

    if (_searchQuery.isNotEmpty) {
      final query = _searchQuery.toLowerCase();
      result = result.where((i) {
        return i.invoiceCode.toLowerCase().contains(query) ||
            (i.ownerName ?? '').toLowerCase().contains(query);
      }).toList();
    }

    if (_filterStatus != 'all') {
      result = result.where((i) => i.status == _filterStatus).toList();
    }

    return result;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text(
          'Invoice',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.w700,
          ),
        ),
        centerTitle: true,
        actions: [
          IconButton(
            tooltip: 'Refresh',
            onPressed: _refresh,
            icon: const Icon(Icons.refresh_rounded),
          ),
        ],
      ),
      body: Column(
        children: [
          // Search bar
          Padding(
            padding: const EdgeInsets.all(16),
            child: TextField(
              controller: _searchController,
              onChanged: (value) {
                setState(() => _searchQuery = value);
              },
              decoration: InputDecoration(
                hintText: 'Search invoice or owner...',
                prefixIcon: const Icon(Icons.search, color: AppColors.textTertiary),
                filled: true,
                fillColor: AppColors.surface,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide.none,
                ),
              ),
            ),
          ),
          // Filter chips
          _buildFilters(),
          Expanded(child: _buildContent()),
        ],
      ),
    );
  }

  Widget _buildFilters() {
    final filters = ['all', 'pending', 'verified', 'rejected', 'expired'];
    final labels = ['Semua', 'Pending', 'Terverifikasi', 'Ditolak', 'Kadaluarsa'];
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: List.generate(filters.length, (index) {
            final isActive = _filterStatus == filters[index];
            return GestureDetector(
              onTap: () => setState(() => _filterStatus = filters[index]),
              child: Container(
                margin: EdgeInsets.only(
                  left: index == 0 ? 0 : 8,
                  right: index == filters.length - 1 ? 16 : 0,
                ),
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                decoration: BoxDecoration(
                  color: isActive ? AppColors.primary.withValues(alpha: 0.1) : Colors.transparent,
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(
                    color: isActive ? AppColors.primary : AppColors.textTertiary.withValues(alpha: 0.2),
                    width: 1,
                  ),
                ),
                child: Text(
                  labels[index],
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: isActive ? FontWeight.w600 : FontWeight.normal,
                    color: isActive ? AppColors.primary : AppColors.textSecondary,
                  ),
                ),
              ),
            );
          }),
        ),
      ),
    );
  }

  Widget _buildContent() {
    return BlocBuilder<InvoiceCubit, InvoiceState>(
      builder: (context, state) {
        if (state is InvoiceLoading && state is! InvoiceLoaded) {
          return const LoadingIndicator();
        }
        if (state is InvoiceError) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  Icons.error_outline,
                  size: 48,
                  color: AppColors.error,
                ),
                const SizedBox(height: 16),
                Text(
                  state.message,
                  style: const TextStyle(
                    fontSize: 16,
                    color: AppColors.textSecondary,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 16),
                ElevatedButton(
                  onPressed: () => _refresh(),
                  child: const Text('Retry'),
                ),
              ],
            ),
          );
        }
        if (state is InvoiceLoaded) {
          final invoices = _filterInvoices(state.invoices);
          if (invoices.isEmpty) {
            return Center(child: Text('Tidak ada invoice', style: TextStyle(color: AppColors.textSecondary)));
          }
          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: invoices.length,
            itemBuilder: (context, index) => _buildInvoiceCard(invoices[index]),
          );
        }
        return const LoadingIndicator();
      },
    );
  }

  Widget _buildInvoiceCard(InvoiceModel invoice) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: invoice.isPending
              ? AppColors.warning.withValues(alpha: 0.1)
              : AppColors.textTertiary.withValues(alpha: 0.1),
          width: 1,
        ),
      ),
      child: Row(
        children: [
          // Icon box
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: _getStatusColor(invoice.status).withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(
              _getStatusIcon(invoice.status),
              color: _getStatusColor(invoice.status),
              size: 20,
            ),
          ),
          const SizedBox(width: 12),
          // Info
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  invoice.invoiceCode,
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: AppColors.textPrimary,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  invoice.ownerName ?? '-',
                  style: const TextStyle(
                    fontSize: 12,
                    color: AppColors.textSecondary,
                  ),
                ),
                const SizedBox(height: 2),
                Row(
                  children: [
                    Text(
                      'Rp ${invoice.amount.toStringAsFixed(0)}',
                      style: const TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        color: AppColors.primary,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      '• ${invoice.planName ?? '-'}',
                      style: const TextStyle(
                        fontSize: 12,
                        color: AppColors.textSecondary,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          // Status badge
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              color: _getStatusColor(invoice.status).withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(_getStatusIcon(invoice.status), size: 14, color: _getStatusColor(invoice.status)),
                const SizedBox(width: 4),
                Text(
                  invoice.status.toUpperCase(),
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                    color: _getStatusColor(invoice.status),
                  ),
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
      case 'pending': return AppColors.warning;
      case 'verified': return AppColors.success;
      case 'rejected': return AppColors.error;
      case 'expired': return AppColors.textTertiary;
      default: return AppColors.textTertiary;
    }
  }

  IconData _getStatusIcon(String status) {
    switch (status) {
      case 'pending': return Icons.pending_outlined;
      case 'verified': return Icons.check_circle_rounded;
      case 'rejected': return Icons.cancel_outlined;
      case 'expired': return Icons.access_time_outlined;
      default: return Icons.help_outline;
    }
  }
}
