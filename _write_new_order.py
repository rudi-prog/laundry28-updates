import os

content = r'''import 'package:flutter/material.dart';
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
'''

path = '/home/star28tech/projects/laundry28/lib/features/admin/presentation/screens/new_order_screen.dart'
with open(path, 'w') as f:
    f.write(content)
print(f'Part 1 written: {len(content)} chars')