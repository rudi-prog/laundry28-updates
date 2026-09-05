import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart';
import '../../../../shared/models/order_model.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../features/admin/cubit/dashboard_cubit.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../../../core/config/web_tracking_config.dart';
import 'package:flutter/services.dart';

class OrderCard extends StatelessWidget {
  final OrderModel order;

  const OrderCard({super.key, required this.order});

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: () => _showUpdateStatusDialog(context),
      borderRadius: BorderRadius.circular(16),
      child: Container(
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.06),
              blurRadius: 10,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header: Tracking Code + Status
              Row(
                children: [
                  Container(
                    width: 36,
                    height: 36,
                    decoration: BoxDecoration(
                      color: _getStatusColor(order.status).withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Icon(
                      _getStatusIcon(order.status),
                      color: _getStatusColor(order.status),
                      size: 18,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          order.trackingCode,
                          style: const TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.bold,
                            color: AppColors.textPrimary,
                          ),
                          overflow: TextOverflow.ellipsis,
                          maxLines: 1,
                        ),
                        const SizedBox(height: 2),
                        Text(
                          DateFormat('dd MMM yyyy, HH:mm', 'id_ID').format(order.createdAt),
                          style: TextStyle(
                            fontSize: 11,
                            color: AppColors.textTertiary,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Flexible(
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: _getStatusColor(order.status),
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: Text(
                        _getStatusLabel(order.status),
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 10,
                          fontWeight: FontWeight.w600,
                        ),
                        overflow: TextOverflow.ellipsis,
                        maxLines: 1,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 14),
              // Customer Info
              Row(
                children: [
                  Icon(Icons.person_outline, size: 16, color: AppColors.textTertiary),
                  const SizedBox(width: 6),
                  Flexible(
                    child: Text(
                      order.customerName,
                      style: TextStyle(fontSize: 13, color: AppColors.textSecondary),
                      overflow: TextOverflow.ellipsis,
                      maxLines: 1,
                    ),
                  ),
                  const SizedBox(width: 16),
                  Icon(Icons.phone_outlined, size: 16, color: AppColors.textTertiary),
                  const SizedBox(width: 6),
                  Expanded(
                    child: Text(
                      order.customerPhone,
                      style: TextStyle(fontSize: 13, color: AppColors.textSecondary),
                      overflow: TextOverflow.ellipsis,
                      maxLines: 1,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 10),
              // Service Type + Weight + Price
              Row(
                children: [
                  Expanded(
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                      decoration: BoxDecoration(
                        color: AppColors.primary.withValues(alpha: 0.08),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Layanan',
                            style: TextStyle(fontSize: 10, color: AppColors.textTertiary),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            order.serviceType,
                            style: const TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                              color: AppColors.primary,
                            ),
                            overflow: TextOverflow.ellipsis,
                            maxLines: 1,
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  if (order.weight != null)
                    Expanded(
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                        decoration: BoxDecoration(
                          color: AppColors.accent.withValues(alpha: 0.08),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Berat',
                              style: TextStyle(fontSize: 10, color: AppColors.textTertiary),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              '${order.weight!.toStringAsFixed(1)} kg',
                              style: const TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.w600,
                                color: AppColors.accent,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  if (order.totalPrice != null)
                    Expanded(
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                        decoration: BoxDecoration(
                          color: AppColors.success.withValues(alpha: 0.08),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Total',
                              style: TextStyle(fontSize: 10, color: AppColors.textTertiary),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              'Rp ${NumberFormat('#,###').format(order.totalPrice!)}',
                              style: const TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.w600,
                                color: AppColors.success,
                              ),
                              overflow: TextOverflow.ellipsis,
                              maxLines: 1,
                            ),
                          ],
                        ),
                      ),
                    ),
                ],
              ),
              const SizedBox(height: 12),
              const SizedBox(height: 12),
              // WhatsApp Tracking Button
              _buildWhatsAppButton(context),
              const SizedBox(height: 8),
              // Progress Bar
              _buildProgressBar(order.status),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildWhatsAppButton(BuildContext ctx) {
    final phone = order.customerPhone;
    if (phone.isEmpty) return const SizedBox.shrink();

    // Format phone for WhatsApp: remove leading 0, add Indonesia country code
    String waPhone = phone.trim();
    if (waPhone.startsWith('0')) {
      waPhone = '62' + waPhone.substring(1);
    } else if (!waPhone.startsWith('+') && !waPhone.startsWith('62')) {
      waPhone = '62' + waPhone;
    }

    final trackingUrl = WebTrackingConfig.getTrackingUrl(order.trackingCode);
    final message =
        "Halo, saya ingin cek status pesanan Laundry28 saya:\n\n"
        "Kode Tracking: *${order.trackingCode}*\n"
        "Layanan: ${order.serviceType}\n"
        "Tanggal: ${DateFormat('dd MMM yyyy', 'id_ID').format(order.createdAt)}\n\n"
        "Cek status pesanan Anda di sini:\n$trackingUrl\n\n"
        "Terima kasih! \u{1F64F}";

    final uri = Uri.parse("https://wa.me/$waPhone?text=${Uri.encodeComponent(message)}");

    return InkWell(
      onTap: () async {
        if (await canLaunchUrl(uri)) {
          await launchUrl(uri, mode: LaunchMode.externalApplication);
        } else {
          // Fallback: copy to clipboard
          await Clipboard.setData(ClipboardData(text: uri.toString()));
          ScaffoldMessenger.of(ctx)
              .showSnackBar(
                const SnackBar(
                  content: Text('Link tracking disalin ke clipboard'),
                  backgroundColor: AppColors.success,
                  behavior: SnackBarBehavior.floating,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.all(Radius.circular(10))),
                ),
              );
        }
      },
      borderRadius: BorderRadius.circular(12),
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
        decoration: BoxDecoration(
          color: const Color(0xFF25D366).withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: const Color(0xFF25D366).withValues(alpha: 0.3)),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.chat_outlined, color: const Color(0xFF25D366), size: 20),
            const SizedBox(width: 8),
            Text(
              'Kirim Link Tracking via WhatsApp',
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: const Color(0xFF25D366),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildProgressBar(String currentStatus) {
    final steps = ['Diterima', 'Dicuci', 'Dikeringkan', 'Disetrika', 'Siap Diambil', 'Selesai'];
    final currentIndex = steps.indexOf(currentStatus);

    return Column(
      children: [
        Row(
          children: steps.asMap().entries.map((entry) {
            final index = entry.key;
            final step = entry.value;
            final isActive = index <= currentIndex;
            final isCurrent = index == currentIndex;

            return Expanded(
              child: Column(
                children: [
                  Container(
                    width: 20,
                    height: 20,
                    decoration: BoxDecoration(
                      color: isActive ? _getStatusColor(currentStatus) : AppColors.border,
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: isCurrent ? _getStatusColor(currentStatus) : AppColors.border,
                        width: 2,
                      ),
                    ),
                    child: isActive
                        ? Center(
                            child: Text(
                              '${index + 1}',
                              style: TextStyle(
                                fontSize: 9,
                                fontWeight: FontWeight.bold,
                                color: isCurrent ? Colors.white : AppColors.textTertiary,
                              ),
                            ),
                          )
                        : null,
                  ),
                  const SizedBox(height: 4),
                  Text(
                    _getShortLabel(step),
                    style: TextStyle(
                      fontSize: 8,
                      color: isCurrent ? _getStatusColor(currentStatus) : AppColors.textTertiary,
                      fontWeight: isCurrent ? FontWeight.bold : FontWeight.normal,
                    ),
                    textAlign: TextAlign.center,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            );
          }).toList(),
        ),
        Padding(
          padding: const EdgeInsets.only(top: 2),
          child: Stack(
            children: [
              Container(
                height: 2,
                color: AppColors.border,
              ),
              FractionallySizedBox(
                widthFactor: currentIndex >= 0 ? (currentIndex + 1) / steps.length : 0,
                child: Container(
                  height: 2,
                  color: _getStatusColor(currentStatus),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  void _showUpdateStatusDialog(BuildContext context) {
    final statuses = ['Diterima', 'Dicuci', 'Dikeringkan', 'Disetrika', 'Siap Diambil', 'Selesai'];
    showDialog(
      context: context,
      builder: (dialogContext) => _UpdateStatusDialog(order: order, statuses: statuses),
    );
  }

  Color _getStatusColor(String status) {
    switch (status) {
      case 'Diterima': return AppColors.info;
      case 'Dicuci': return const Color(0xFF0EA5E9);
      case 'Dikeringkan': return AppColors.warning;
      case 'Disetrika': return AppColors.accent;
      case 'Siap Diambil': return AppColors.success;
      case 'Selesai': return AppColors.textSecondary;
      default: return AppColors.textTertiary;
    }
  }

  IconData _getStatusIcon(String status) {
    switch (status) {
      case 'Diterima': return Icons.inbox;
      case 'Dicuci': return Icons.water_drop;
      case 'Dikeringkan': return Icons.local_fire_department;
      case 'Disetrika': return Icons.hvac;
      case 'Siap Diambil': return Icons.check_circle;
      case 'Selesai': return Icons.done_all;
      default: return Icons.help;
    }
  }

  String _getStatusLabel(String status) {
    switch (status) {
      case 'Diterima': return 'Diterima';
      case 'Dicuci': return 'Dicuci';
      case 'Dikeringkan': return 'Kering';
      case 'Disetrika': return 'Setrika';
      case 'Siap Diambil': return 'Siap';
      case 'Selesai': return 'Selesai';
      default: return status;
    }
  }

  String _getShortLabel(String status) {
    switch (status) {
      case 'Diterima': return 'Terima';
      case 'Dicuci': return 'Cuci';
      case 'Dikeringkan': return 'Kering';
      case 'Disetrika': return 'Setrika';
      case 'Siap Diambil': return 'Siap';
      case 'Selesai': return 'Selesai';
      default: return status;
    }
  }
}

class _UpdateStatusDialog extends StatefulWidget {
  final OrderModel order;
  final List<String> statuses;
  const _UpdateStatusDialog({required this.order, required this.statuses});

  @override
  State<_UpdateStatusDialog> createState() => _UpdateStatusDialogState();
}

class _UpdateStatusDialogState extends State<_UpdateStatusDialog> {
  String? _selectedStatus;
  bool _isUpdating = false;

  @override
  void initState() {
    super.initState();
    _selectedStatus = widget.order.status;
  }

  Future<void> _handleSave() async {
    if (_selectedStatus == null || _selectedStatus == widget.order.status) {
      Navigator.pop(context);
      return;
    }
    setState(() => _isUpdating = true);
    try {
      await context.read<DashboardCubit>().updateOrderStatus(widget.order.id!, _selectedStatus!);
      if (mounted) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Status berhasil diupdate ke $_selectedStatus'),
            backgroundColor: AppColors.success,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text('Gagal update status'),
            backgroundColor: AppColors.error,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isUpdating = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      title: Row(
        children: [
          Icon(Icons.update, color: AppColors.primary),
          const SizedBox(width: 12),
          Expanded(child: const Text('Update Status', style: TextStyle(fontWeight: FontWeight.bold))),
        ],
      ),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            widget.order.trackingCode,
            style: TextStyle(color: AppColors.textSecondary),
            overflow: TextOverflow.ellipsis,
            maxLines: 1,
          ),
          const SizedBox(height: 16),
          DropdownButtonFormField<String>(
            initialValue: _selectedStatus,
            decoration: InputDecoration(
              labelText: 'Pilih Status',
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
              filled: true,
              fillColor: AppColors.surface,
            ),
            items: widget.statuses.map((status) => DropdownMenuItem(value: status, child: Text(status))).toList(),
            onChanged: (value) => setState(() => _selectedStatus = value),
          ),
        ],
      ),
      actions: [
        TextButton(onPressed: _isUpdating ? null : () => Navigator.pop(context), child: const Text('Batal')),
        ElevatedButton(
          onPressed: (_selectedStatus != null && _selectedStatus != widget.order.status && !_isUpdating)
              ? _handleSave
              : null,
          style: ElevatedButton.styleFrom(
            backgroundColor: AppColors.primary,
            foregroundColor: Colors.white,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
          ),
          child: _isUpdating
              ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
              : const Text('Simpan'),
        ),
      ],
    );
  }
}
