import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../../core/theme/app_colors.dart';
import '../../cubit/service_cubit.dart';
import '../../data/models/service_model.dart';
import '../../../../core/widgets/empty_state_widget.dart';

class ServiceManagementScreen extends StatefulWidget {
  final int laundryId;

  const ServiceManagementScreen({super.key, required this.laundryId});

  @override
  State<ServiceManagementScreen> createState() => _ServiceManagementScreenState();
}

class _ServiceManagementScreenState extends State<ServiceManagementScreen> {
  bool _showInactive = false;

  @override
  void initState() {
    super.initState();
    _loadServices();
  }

  void _loadServices() {
    if (_showInactive) {
      context.read<ServiceCubit>().fetchAllServices(widget.laundryId);
    } else {
      context.read<ServiceCubit>().fetchServices(widget.laundryId);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Kelola Layanan'),
        elevation: 0,
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
      ),
      body: BlocBuilder<ServiceCubit, ServiceState>(
        builder: (context, state) {
          if (state is ServiceLoading || state is ServiceInitial) {
            return const Center(child: CircularProgressIndicator());
          }

          if (state is ServiceError) {
            return EmptyStateWidget(
              icon: Icons.error_outline,
              title: 'Error',
              subtitle: state.message,
              actionLabel: 'Coba Lagi',
              onAction: _loadServices,
            );
          }

          if (state is ServiceLoaded) {
            final services = _showInactive
                ? state.services
                : state.services.where((s) => s.isActive).toList();

            if (services.isEmpty) {
              return EmptyStateWidget(
                icon: Icons.category_outlined,
                title: 'Belum Ada Layanan',
                subtitle: 'Tambahkan layanan untuk memulai',
                actionLabel: 'Tambah Layanan',
                onAction: () => _showServiceFormDialog(),
              );
            }

            return Column(
              children: [
                Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'Total: ${services.length} layanan',
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                          color: AppColors.textSecondary,
                        ),
                      ),
                      Row(
                        children: [
                          const Text(
                            'Tampilkan Non-Aktif',
                            style: TextStyle(
                              fontSize: 14,
                              color: AppColors.textSecondary,
                            ),
                          ),
                          const SizedBox(width: 8),
                          Switch(
                            value: _showInactive,
                            onChanged: (value) {
                              setState(() => _showInactive = value);
                              _loadServices();
                            },
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                Expanded(
                  child: ListView.separated(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    itemCount: services.length,
                    separatorBuilder: (_, __) => const SizedBox(height: 12),
                    itemBuilder: (context, index) {
                      final service = services[index];
                      return _buildServiceCard(service);
                    },
                  ),
                ),
              ],
            );
          }

          return const SizedBox.shrink();
        },
      ),
    );
  }

  Widget _buildServiceCard(ServiceModel service) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: service.isActive ? AppColors.border : AppColors.error.withValues(alpha: 0.3),
        ),
      ),
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: service.isActive
                  ? AppColors.primary.withValues(alpha: 0.05)
                  : AppColors.error.withValues(alpha: 0.05),
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(16),
                topRight: Radius.circular(16),
              ),
            ),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: service.isActive ? AppColors.primary : AppColors.error,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Icon(
                    service.isActive ? Icons.check_circle : Icons.cancel,
                    color: Colors.white,
                    size: 20,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        service.name,
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w700,
                          color: AppColors.textPrimary,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        'Est. ${service.durationHours} jam',
                        style: TextStyle(
                          fontSize: 13,
                          color: AppColors.textSecondary,
                        ),
                      ),
                    ],
                  ),
                ),
                Text(
                  'Rp ${_formatPrice(service.price)}',
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w700,
                    color: AppColors.primary,
                  ),
                ),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            decoration: BoxDecoration(
              color: AppColors.surface,
              borderRadius: const BorderRadius.only(
                bottomLeft: Radius.circular(16),
                bottomRight: Radius.circular(16),
              ),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                IconButton(
                  onPressed: () => _showServiceFormDialog(service: service),
                  icon: const Icon(Icons.edit_outlined, size: 20),
                  color: AppColors.primary,
                  tooltip: 'Edit',
                ),
                IconButton(
                  onPressed: () => _toggleActive(service),
                  icon: Icon(
                    service.isActive ? Icons.visibility_off : Icons.visibility,
                    size: 20,
                    color: service.isActive ? AppColors.warning : AppColors.success,
                  ),
                  tooltip: service.isActive ? 'Nonaktifkan' : 'Aktifkan',
                ),
                IconButton(
                  onPressed: () => _deleteService(service),
                  icon: const Icon(Icons.delete_outline, size: 20),
                  color: AppColors.error,
                  tooltip: 'Hapus',
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  void _showServiceFormDialog({ServiceModel? service}) {
    final isEditing = service != null;
    final nameController = TextEditingController(text: service?.name ?? '');
    final priceController = TextEditingController(
      text: service != null ? service.price.toStringAsFixed(0) : '',
    );
    final durationController = TextEditingController(
      text: service?.durationHours.toString() ?? '1',
    );
    final formKey = GlobalKey<FormState>();

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(isEditing ? 'Edit Layanan' : 'Tambah Layanan'),
        content: SingleChildScrollView(
          child: Form(
            key: formKey,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextFormField(
                  controller: nameController,
                  decoration: const InputDecoration(
                    labelText: 'Nama Layanan',
                    hintText: 'Contoh: Cuci Komplit',
                    prefixIcon: Icon(Icons.category_outlined),
                    border: OutlineInputBorder(),
                  ),
                  validator: (v) =>
                      (v == null || v.isEmpty) ? 'Nama layanan tidak boleh kosong' : null,
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: priceController,
                  decoration: const InputDecoration(
                    labelText: 'Harga (Rp)',
                    hintText: 'Contoh: 7000',
                    prefixIcon: Icon(Icons.attach_money),
                    border: OutlineInputBorder(),
                  ),
                  keyboardType: TextInputType.number,
                  validator: (v) {
                    if (v == null || v.isEmpty) {
                      return 'Harga harus diisi';
                    }
                    if (double.tryParse(v) == null) {
                      return 'Harga harus berupa angka';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: durationController,
                  decoration: const InputDecoration(
                    labelText: 'Estimasi (jam)',
                    hintText: 'Contoh: 1',
                    prefixIcon: Icon(Icons.access_time),
                    border: OutlineInputBorder(),
                  ),
                  keyboardType: TextInputType.number,
                  validator: (v) {
                    if (v == null || v.isEmpty) {
                      return 'Durasi harus diisi';
                    }
                    if (int.tryParse(v) == null) {
                      return 'Durasi harus berupa angka';
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
          ElevatedButton.icon(
            onPressed: () async {
              if (!formKey.currentState!.validate()) return;
              final name = nameController.text.trim();
              final price = double.tryParse(priceController.text);
              final duration = int.tryParse(durationController.text) ?? 1;
              if (isEditing) {
                final success = await context.read<ServiceCubit>().updateService(
                      id: service!.id,
                      laundryId: widget.laundryId,
                      name: name,
                      price: price,
                      durationHours: duration,
                    );
                if (success && mounted) Navigator.pop(context);
              } else {
                final success = await context.read<ServiceCubit>().createService(
                      laundryId: widget.laundryId,
                      name: name,
                      price: price!,
                      durationHours: duration,
                    );
                if (success && mounted) Navigator.pop(context);
              }
            },
            icon: Icon(isEditing ? Icons.save : Icons.add),
            label: Text(isEditing ? 'Simpan' : 'Tambah'),
          ),
        ],
      ),
    );
  }

  Future<void> _toggleActive(ServiceModel service) async {
    final success = await context.read<ServiceCubit>().toggleService(
          service.id,
          widget.laundryId,
        );
    if (success && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            service.isActive ? 'Layanan dinonaktifkan' : 'Layanan diaktifkan',
          ),
          duration: const Duration(seconds: 2),
        ),
      );
    }
  }

  Future<void> _deleteService(ServiceModel service) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Hapus Layanan'),
        content: Text(
          'Apakah Anda yakin ingin menghapus layanan "${service.name}"?\nTindakan ini tidak dapat dibatalkan.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Batal'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.error,
              foregroundColor: Colors.white,
            ),
            child: const Text('Hapus'),
          ),
        ],
      ),
    );
    if (confirmed == true && mounted) {
      final success = await context.read<ServiceCubit>().deleteService(
            service.id,
            widget.laundryId,
          );
      if (success && mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Layanan berhasil dihapus'),
            duration: Duration(seconds: 2),
          ),
        );
      }
    }
  }

  String _formatPrice(double price) {
    return price.toStringAsFixed(0).replaceAllMapped(
          RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'),
          (Match m) => '${m[1]}.',
        );
  }
}
