import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/constants/app_routes.dart';
import '../../../../shared/widgets/custom_button.dart';
import '../../../../shared/widgets/custom_text_field.dart';
import '../../cubit/new_order_cubit.dart';
import '../../cubit/dashboard_cubit.dart';
import '../../../../core/theme/app_colors.dart';

class NewOrderScreen extends StatefulWidget {
  const NewOrderScreen({super.key});

  @override
  State<NewOrderScreen> createState() => _NewOrderScreenState();
}

class _NewOrderScreenState extends State<NewOrderScreen> {
  final _formKey = GlobalKey<FormState>();
  final _customerNameController = TextEditingController();
  final _customerPhoneController = TextEditingController();
  final _weightController = TextEditingController(text: '1.0');
  String _selectedService = 'Cuci Komplit';
  DateTime? _estimatedDate;
  TimeOfDay? _estimatedTime;

  final List<String> _months = [
    'Januari', 'Februari', 'Maret', 'April', 'Mei', 'Juni',
    'Juli', 'Agustus', 'September', 'Oktober', 'November', 'Desember',
  ];

  final List<String> _services = [
    'Cuci Komplit',
    'Cuci + Setrika',
    'Setrika Saja',
    'Cuci Saja',
    'Cuci Bedcover',
    'Cuci Sepatu',
  ];

  @override
  void dispose() {
    _customerNameController.dispose();
    _customerPhoneController.dispose();
    _weightController.dispose();
    super.dispose();
  }

  void _handleSave() async {
    if (!_formKey.currentState!.validate()) return;

    final estimatedDateTime = _estimatedDate != null && _estimatedTime != null
        ? DateTime(_estimatedDate!.year, _estimatedDate!.month, _estimatedDate!.day,
            _estimatedTime!.hour, _estimatedTime!.minute)
        : null;

    final weight = double.tryParse(_weightController.text) ?? 1.0;

    await context.read<NewOrderCubit>().saveOrder(
          customerName: _customerNameController.text,
          customerPhone: _customerPhoneController.text,
          serviceType: _selectedService,
          weight: weight,
          estimatedTime: estimatedDateTime,
        );
  }

  Future<void> _selectDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: DateTime.now().add(const Duration(days: 1)),
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 30)),
    );
    if (picked != null) setState(() => _estimatedDate = picked);
  }

  Future<void> _selectTime() async {
    final picked = await showTimePicker(context: context, initialTime: TimeOfDay.now());
    if (picked != null) setState(() => _estimatedTime = picked);
  }

  @override
  Widget build(BuildContext context) {
    return BlocListener<NewOrderCubit, NewOrderState>(
      listener: (context, state) {
        if (state is NewOrderSuccess) {
          context.read<DashboardCubit>().fetchOrders();
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('Pesanan berhasil dibuat'),
                backgroundColor: Colors.green,
              ),
            );
            context.go(AppRoutes.dashboard);
          }
        } else if (state is NewOrderError) {
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(state.message),
                backgroundColor: Colors.red,
                duration: const Duration(seconds: 4),
                action: SnackBarAction(
                  label: 'Tutup',
                  textColor: Colors.white,
                  onPressed: () {},
                ),
              ),
            );
          }
        }
      },
      child: Scaffold(
        backgroundColor: AppColors.background,
        appBar: AppBar(
          backgroundColor: AppColors.primary,
          foregroundColor: Colors.white,
          elevation: 0,
          leading: (Theme.of(context).platform == TargetPlatform.iOS ||
                  Theme.of(context).platform == TargetPlatform.android)
              ? IconButton(
                  icon: const Icon(Icons.arrow_back_ios_new, size: 20),
                  onPressed: () => context.go(AppRoutes.dashboard),
                )
              : null,
          title: const Text(
            'Pesanan Baru',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              letterSpacing: 0.5,
            ),
          ),
        ),
        body: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Section Header - Customer Info
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  decoration: BoxDecoration(
                    color: AppColors.primary,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Row(
                    children: [
                      Icon(Icons.person_outline, color: Colors.white, size: 24),
                      const SizedBox(width: 12),
                      const Text(
                        'INFORMASI PELANGGAN',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 15,
                          color: Colors.white,
                          letterSpacing: 0.8,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),
                // Customer Name & Phone Card
                Container(
                  decoration: BoxDecoration(
                    color: AppColors.surface,
                    borderRadius: BorderRadius.circular(16),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.05),
                        blurRadius: 10,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: Padding(
                    padding: const EdgeInsets.all(20),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        CustomTextField(
                          labelText: 'Nama Pelanggan',
                          controller: _customerNameController,
                          prefixIcon: Icon(Icons.person_outline, color: AppColors.primary),
                          hintText: 'Masukkan nama pelanggan',
                          validator: (v) {
                            if (v == null || v.isEmpty) return 'Nama wajib diisi';
                            if (v.length < 3) return 'Nama minimal 3 karakter';
                            return null;
                          },
                        ),
                        const SizedBox(height: 16),
                        CustomTextField(
                          labelText: 'No. Telepon',
                          controller: _customerPhoneController,
                          keyboardType: TextInputType.phone,
                          prefixIcon: Icon(Icons.phone_outlined, color: AppColors.primary),
                          hintText: '08xxxxxxxxxx',
                          validator: (v) {
                            if (v == null || v.isEmpty) return 'No. telepon wajib diisi';
                            if (v.length < 10) return 'Nomor telepon tidak valid';
                            return null;
                          },
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 16),

                // Section Header - Service Info
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  decoration: BoxDecoration(
                    color: AppColors.warning,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Row(
                    children: [
                      Icon(Icons.local_laundry_service, color: Colors.white, size: 24),
                      const SizedBox(width: 12),
                      const Text(
                        'DETAIL PESANAN',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 15,
                          color: Colors.white,
                          letterSpacing: 0.8,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),

                // Service & Weight Card
                Container(
                  decoration: BoxDecoration(
                    color: AppColors.surface,
                    borderRadius: BorderRadius.circular(16),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.05),
                        blurRadius: 10,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: Padding(
                    padding: const EdgeInsets.all(20),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'JENIS LAYANAN',
                          style: TextStyle(
                            fontWeight: FontWeight.w600,
                            fontSize: 13,
                            color: AppColors.textSecondary,
                            letterSpacing: 0.5,
                          ),
                        ),
                        const SizedBox(height: 12),
                        Container(
                          decoration: BoxDecoration(
                            border: Border.all(color: AppColors.border),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: DropdownButtonFormField<String>(
                            initialValue: _selectedService,
                            decoration: const InputDecoration(
                              contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                              border: InputBorder.none,
                            ),
                            items: _services.map((s) => DropdownMenuItem(value: s, child: Text(s))).toList(),
                            onChanged: (v) => setState(() => _selectedService = v!),
                            validator: (v) => (v == null) ? 'Pilih layanan' : null,
                          ),
                        ),
                        const SizedBox(height: 20),
                        Text(
                          'BERAT BAJA',
                          style: TextStyle(
                            fontWeight: FontWeight.w600,
                            fontSize: 13,
                            color: AppColors.textSecondary,
                            letterSpacing: 0.5,
                          ),
                        ),
                        const SizedBox(height: 12),
                        CustomTextField(
                          labelText: 'Berat (kg)',
                          controller: _weightController,
                          keyboardType: const TextInputType.numberWithOptions(decimal: true),
                          prefixIcon: Icon(Icons.scale_outlined, color: AppColors.primary),
                          hintText: 'Contoh: 1.0',
                          validator: (v) {
                            if (v == null || v.isEmpty) return 'Berat wajib diisi';
                            if (double.tryParse(v) == null || double.parse(v) <= 0) {
                              return 'Berat harus lebih dari 0';
                            }
                            return null;
                          },
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 16),

                // Section Header - Estimated Time
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  decoration: BoxDecoration(
                    color: AppColors.success,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Row(
                    children: [
                      Icon(Icons.schedule_outlined, color: Colors.white, size: 24),
                      const SizedBox(width: 12),
                      const Text(
                        'WAKTU SELESAI',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 15,
                          color: Colors.white,
                          letterSpacing: 0.8,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),

                // Estimated Time Card
                Container(
                  decoration: BoxDecoration(
                    color: AppColors.surface,
                    borderRadius: BorderRadius.circular(16),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.05),
                        blurRadius: 10,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: Padding(
                    padding: const EdgeInsets.all(20),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Date Picker
                        InkWell(
                          onTap: _selectDate,
                          borderRadius: BorderRadius.circular(12),
                          child: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                            decoration: BoxDecoration(
                              border: Border.all(color: AppColors.border),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Row(
                              children: [
                                Icon(Icons.calendar_today_outlined, color: AppColors.primary),
                                const SizedBox(width: 16),
                                Text(
                                  _estimatedDate != null
                                      ? '📅 ${_formatDate(_estimatedDate!)}'
                                      : 'Pilih tanggal selesai',
                                  style: TextStyle(
                                    fontSize: 15,
                                    color: _estimatedDate != null
                                        ? AppColors.textPrimary
                                        : AppColors.textSecondary,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                        const SizedBox(height: 16),

                        // Time Picker
                        InkWell(
                          onTap: _selectTime,
                          borderRadius: BorderRadius.circular(12),
                          child: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                            decoration: BoxDecoration(
                              border: Border.all(color: AppColors.border),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Row(
                              children: [
                                Icon(Icons.access_time_outlined, color: AppColors.primary),
                                const SizedBox(width: 16),
                                Text(
                                  _estimatedTime != null
                                      ? '🕐 ${_formatTime(_estimatedTime!)}'
                                      : 'Pilih waktu selesai',
                                  style: TextStyle(
                                    fontSize: 15,
                                    color: _estimatedTime != null
                                        ? AppColors.textPrimary
                                        : AppColors.textSecondary,
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
                const SizedBox(height: 32),

                // Save Button
                BlocBuilder<NewOrderCubit, NewOrderState>(
                  builder: (context, state) {
                    return CustomButton(
                      label: 'SIMPAN PESANAN',
                      onPressed: state is NewOrderLoading ? null : _handleSave,
                      isLoading: state is NewOrderLoading,
                      height: 56,
                    );
                  },
                ),

                const SizedBox(height: 32),
              ],
            ),
          ),
        ),
      ),
    );
  }

  String _formatDate(DateTime date) {
    return '''${date.day.toString().padLeft(2, '0')} ${_months[date.month - 1]} ${date.year}''';
  }

  String _formatTime(TimeOfDay time) {
    final hour = time.hourOfPeriod.toString().padLeft(2, '0');
    final minute = time.minute.toString().padLeft(2, '0');
    return '''$hour:$minute''';
  }
}
