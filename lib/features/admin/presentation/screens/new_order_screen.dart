import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/constants/app_routes.dart';
import '../../../../shared/widgets/custom_button.dart';
import '../../../../shared/widgets/custom_text_field.dart';
import '../../cubit/new_order_cubit.dart';
import '../../cubit/dashboard_cubit.dart';

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
        appBar: AppBar(title: const Text('Pesanan Baru')),
        body: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text('INFO PELANGGAN', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: Color(0xFF757575))),
                        const SizedBox(height: 16),
                        CustomTextField(
                          labelText: 'Nama Pelanggan',
                          controller: _customerNameController,
                          prefixIcon: const Icon(Icons.person_outline),
                          validator: (v) => (v == null || v.isEmpty) ? 'Nama wajib diisi' : null,
                        ),
                        const SizedBox(height: 16),
                        CustomTextField(
                          labelText: 'No. WhatsApp',
                          controller: _customerPhoneController,
                          prefixIcon: const Icon(Icons.phone_outlined),
                          hintText: '08xxxxxxxxxx',
                          keyboardType: TextInputType.phone,
                          validator: (v) {
                            if (v == null || v.isEmpty) return 'No. WA wajib diisi';
                            if (v.length < 10) return 'Nomor tidak valid';
                            return null;
                          },
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text('JENIS LAYANAN', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: Color(0xFF757575))),
                        const SizedBox(height: 16),
                        DropdownButtonFormField<String>(
                          initialValue: _selectedService,
                          decoration: const InputDecoration(labelText: 'Pilih Layanan'),
                          items: _services.map((s) => DropdownMenuItem(value: s, child: Text(s))).toList(),
                          onChanged: (v) => setState(() => _selectedService = v!),
                          validator: (v) => (v == null) ? 'Pilih layanan' : null,
                        ),
                        const SizedBox(height: 16),
                        CustomTextField(
                          labelText: 'Berat (kg)',
                          controller: _weightController,
                          keyboardType: const TextInputType.numberWithOptions(decimal: true),
                          prefixIcon: const Icon(Icons.scale),
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
                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text('ESTIMASI SELESAI', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: Color(0xFF757575))),
                        const SizedBox(height: 16),
                        InkWell(
                          onTap: _selectDate,
                          child: InputDecorator(
                            decoration: const InputDecoration(labelText: 'Tanggal', prefixIcon: Icon(Icons.calendar_today)),
                            child: Text(_estimatedDate == null ? 'Pilih tanggal' : '${_estimatedDate!.day}/${_estimatedDate!.month}/${_estimatedDate!.year}'),
                          ),
                        ),
                        const SizedBox(height: 16),
                        InkWell(
                          onTap: _selectTime,
                          child: InputDecorator(
                            decoration: const InputDecoration(labelText: 'Waktu', prefixIcon: Icon(Icons.access_time)),
                            child: Text(_estimatedTime == null ? 'Pilih waktu' : _estimatedTime!.format(context)),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                BlocBuilder<NewOrderCubit, NewOrderState>(
                  builder: (context, state) {
                    return CustomButton(
                      label: 'SIMPAN PESANAN',
                      onPressed: state is! NewOrderLoading ? _handleSave : null,
                      isLoading: state is NewOrderLoading,
                    );
                  },
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
