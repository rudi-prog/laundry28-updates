import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../shared/widgets/custom_text_field.dart';
import '../../cubit/staff/staff_cubit.dart';
import '../../cubit/staff/staff_state.dart';
import '../../data/models/staff_model.dart';

/// Screen untuk manajemen karyawan (CRUD)
class StaffManagementScreen extends StatefulWidget {
  const StaffManagementScreen({super.key});

  @override
  State<StaffManagementScreen> createState() => _StaffManagementScreenState();
}

class _StaffManagementScreenState extends State<StaffManagementScreen> {
  final _formKey = GlobalKey<FormState>();
  final _fullNameController = TextEditingController();
  final _usernameController = TextEditingController();
  final _passwordController = TextEditingController();
  final _pinController = TextEditingController();
  bool _obscurePassword = true;
  bool _obscurePin = true;
  StaffModel? _editingStaff;

  @override
  void initState() {
    super.initState();
    context.read<StaffCubit>().fetchAllStaff();
  }

  @override
  void dispose() {
    _fullNameController.dispose();
    _usernameController.dispose();
    _passwordController.dispose();
    _pinController.dispose();
    super.dispose();
  }

  /// Generate username otomatis dari nama lengkap
  void _generateUsername(String fullName) {
    final username = context.read<StaffCubit>().generateUsername(fullName);
    if (mounted) {
      setState(() => _usernameController.text = username);
    }
  }

  /// Buka dialog tambah karyawan baru
  void _showAddDialog() {
    _editingStaff = null;
    _fullNameController.clear();
    _usernameController.clear();
    _passwordController.clear();
    _pinController.clear();
    setState(() {
      _obscurePassword = true;
      _obscurePin = true;
    });
    showDialog(
      context: context,
      builder: (ctx) => _buildStaffDialog(),
    );
  }

  /// Buka dialog edit karyawan
  void _showEditDialog(StaffModel staff) {
    _editingStaff = staff;
    _fullNameController.text = staff.fullName;
    _usernameController.text = staff.username ?? '';
    _passwordController.clear();
    _pinController.text = staff.pin ?? '';
    setState(() {
      _obscurePassword = true;
      _obscurePin = true;
    });
    showDialog(
      context: context,
      builder: (ctx) => _buildStaffDialog(),
    );
  }

  /// Hapus karyawan dengan konfirmasi
  void _deleteStaff(int id, String fullName) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text('Hapus Karyawan'),
        content: Text('Yakin ingin menghapus karyawan "$fullName"?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: const Text('BATAL'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
            ),
            onPressed: () {
              Navigator.of(ctx).pop();
              context.read<StaffCubit>().removeStaff(id);
            },
            child: const Text('HAPUS'),
          ),
        ],
      ),
    );
  }

  /// Submit form (tambah atau update)
  Future<void> _submitForm() async {
    if (!_formKey.currentState!.validate()) return;

    final fullName = _fullNameController.text.trim();
    final username = _usernameController.text.trim();
    final password = _passwordController.text.trim();
    final pin = _pinController.text.trim();

    // Validasi PIN: harus 4-6 digit angka jika diisi
    if (pin.isNotEmpty && (pin.length < 4 || pin.length > 6 || !RegExp(r'^\d+$').hasMatch(pin))) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('PIN harus 4-6 digit angka'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    if (_editingStaff != null) {
      await context.read<StaffCubit>().updateStaff(
            id: _editingStaff!.id!,
            fullName: fullName,
            username: username,
            password: password.isEmpty ? null : password,
            pin: pin.isEmpty ? null : pin,
          );
    } else {
      if (password.isEmpty) return;
      await context.read<StaffCubit>().addStaff(
            fullName: fullName,
            username: username,
            password: password,
            pin: pin.isEmpty ? null : pin,
          );
    }

    if (mounted) Navigator.of(context).pop();
  }

  /// Build dialog form untuk tambah/edit karyawan
  Widget _buildStaffDialog() {
    return AlertDialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      title: Text(_editingStaff == null ? 'Tambah Karyawan' : 'Edit Karyawan'),
      content: SizedBox(
        width: 400,
        child: Form(
          key: _formKey,
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                CustomTextField(
                  labelText: 'Nama Lengkap',
                  controller: _fullNameController,
                  prefixIcon: const Icon(Icons.person_outline),
                  onChanged: (v) => _generateUsername(v),
                  validator: (v) {
                    if (v == null || v.trim().isEmpty) return 'Nama wajib diisi';
                    return null;
                  },
                ),
                const SizedBox(height: 16),
                CustomTextField(
                  labelText: 'Username',
                  controller: _usernameController,
                  prefixIcon: const Icon(Icons.badge_outlined),
                  validator: (v) {
                    if (v == null || v.trim().isEmpty) return 'Username wajib diisi';
                    if (v.length < 3) return 'Username minimal 3 karakter';
                    return null;
                  },
                ),
                const SizedBox(height: 16),
                CustomTextField(
                  labelText: _editingStaff == null ? 'Password' : 'Password (kosongkan jika tidak diubah)',
                  controller: _passwordController,
                  obscureText: _obscurePassword,
                  prefixIcon: const Icon(Icons.lock_outline),
                  suffixIcon: IconButton(
                    icon: Icon(_obscurePassword ? Icons.visibility_off : Icons.visibility),
                    onPressed: () => setState(() => _obscurePassword = !_obscurePassword),
                  ),
                  validator: (v) {
                    if (_editingStaff == null && (v == null || v.isEmpty)) return 'Password wajib diisi';
                    if (v != null && v.isNotEmpty && v.length < 6) return 'Password minimal 6 karakter';
                    return null;
                  },
                ),
                const SizedBox(height: 16),
                if (_editingStaff == null)
                  CustomTextField(
                    labelText: 'PIN Login (4-6 digit)',
                    controller: _pinController,
                    obscureText: _obscurePin,
                    prefixIcon: const Icon(Icons.pin_outlined),
                    suffixIcon: IconButton(
                      icon: Icon(_obscurePin ? Icons.visibility_off : Icons.visibility),
                      onPressed: () => setState(() => _obscurePin = !_obscurePin),
                    ),
                    keyboardType: TextInputType.number,
                    maxLength: 6,
                    validator: (v) {
                      if (v != null && v.isNotEmpty) {
                        if (v.length < 4 || v.length > 6) return 'PIN harus 4-6 digit';
                        if (!RegExp(r'^\d+$').hasMatch(v)) return 'PIN hanya boleh berisi angka';
                      }
                      return null;
                    },
                    hintText: 'Contoh: 1234',
                  ),
                if (_editingStaff != null)
                  Padding(
                    padding: const EdgeInsets.only(bottom: 8),
                    child: Row(
                      children: [
                        Icon(Icons.info_outline, size: 16, color: Colors.grey[600]),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            'PIN saat ini: ${_editingStaff!.pin ?? "belum diatur"}',
                            style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                          ),
                        ),
                      ],
                    ),
                  ),
                if (_editingStaff != null)
                  CustomTextField(
                    labelText: 'PIN Baru (kosongkan jika tidak diubah)',
                    controller: _pinController,
                    obscureText: _obscurePin,
                    prefixIcon: const Icon(Icons.pin_outlined),
                    suffixIcon: IconButton(
                      icon: Icon(_obscurePin ? Icons.visibility_off : Icons.visibility),
                      onPressed: () => setState(() => _obscurePin = !_obscurePin),
                    ),
                    keyboardType: TextInputType.number,
                    maxLength: 6,
                    hintText: 'Kosongkan jika tidak diubah',
                  ),
              ],
            ),
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('BATAL'),
        ),
        BlocBuilder<StaffCubit, StaffState>(
          builder: (context, state) {
            return ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
              ),
              onPressed: state is StaffLoading ? null : _submitForm,
              child: state is StaffLoading
                  ? const SizedBox(height: 20, width: 20, child: CircularProgressIndicator(strokeWidth: 2))
                  : Text(_editingStaff == null ? 'TAMBAH' : 'SIMPAN'),
            );
          },
        ),
      ],
    );
  }

  /// Build daftar karyawan dengan search dan list view
  Widget _buildStaffList() {
    return BlocBuilder<StaffCubit, StaffState>(
      builder: (context, state) {
        if (state is StaffLoading && state.staffList == null) {
          return const Center(child: CircularProgressIndicator());
        }

        if (state is StaffError) {
          return Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.error_outline, size: 48, color: Colors.red.shade300),
                const SizedBox(height: 16),
                Text(state.message, style: TextStyle(color: Colors.grey[600])),
                const SizedBox(height: 16),
                ElevatedButton(
                  onPressed: () => context.read<StaffCubit>().fetchAllStaff(),
                  child: const Text('COBA LAGI'),
                ),
              ],
            ),
          );
        }

        if (state is StaffLoaded && state.staffList.isEmpty) {
          return Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.people_outline, size: 64, color: Colors.grey.shade300),
                const SizedBox(height: 16),
                Text('Belum ada karyawan', style: TextStyle(fontSize: 16, color: Colors.grey[600])),
                const SizedBox(height: 8),
                TextButton(
                  onPressed: _showAddDialog,
                  child: const Text('Tambah Karyawan Pertama'),
                ),
              ],
            ),
          );
        }

        final staffList = state is StaffLoaded ? state.staffList : [];

        return Column(
          children: [
            Padding(
              padding: const EdgeInsets.only(bottom: 16),
              child: TextField(
                decoration: InputDecoration(
                  hintText: 'Cari karyawan...',
                  prefixIcon: const Icon(Icons.search),
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                  filled: true,
                  fillColor: Colors.grey.shade50,
                ),
              ),
            ),
            Expanded(
              child: ListView.separated(
                itemCount: staffList.length,
                separatorBuilder: (_, __) => const SizedBox(height: 8),
                itemBuilder: (context, index) {
                  final staff = staffList[index];
                  return _buildStaffCard(staff);
                },
              ),
            ),
          ],
        );
      },
    );
  }

  /// Build card untuk satu karyawan
  Widget _buildStaffCard(StaffModel staff) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: AppColors.primary.withOpacity(0.1),
          child: Icon(Icons.person, color: AppColors.primary),
        ),
        title: Text(staff.fullName, style: const TextStyle(fontWeight: FontWeight.w600)),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 4),
            Text('Username: ${staff.username ?? "-"}'),
            if (staff.email.isNotEmpty) Text('Email: ${staff.email}'),
            if (staff.pin != null && staff.pin!.isNotEmpty)
              Row(
                children: [
                  Icon(Icons.pin_outlined, size: 12, color: Colors.green[700]),
                  const SizedBox(width: 4),
                  Text(
                    'PIN: ${staff.pin}',
                    style: TextStyle(fontSize: 12, color: Colors.green[700]),
                  ),
                ],
              )
            else
              Text(
                'Belum diatur PIN',
                style: TextStyle(fontSize: 12, color: Colors.orange[700]),
              ),
            Text('Role: ${staff.role}', style: TextStyle(fontSize: 12, color: Colors.grey[600])),
          ],
        ),
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            IconButton(
              icon: const Icon(Icons.edit_outlined),
              onPressed: () => _showEditDialog(staff),
              tooltip: 'Edit',
            ),
            IconButton(
              icon: const Icon(Icons.delete_outline),
              onPressed: () => _deleteStaff(staff.id!, staff.fullName),
              tooltip: 'Hapus',
              color: Colors.red,
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Manajemen Karyawan'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () => context.read<StaffCubit>().fetchAllStaff(),
          ),
        ],
      ),
      body: _buildStaffList(),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _showAddDialog,
        icon: const Icon(Icons.add),
        label: const Text('Tambah Karyawan'),
        backgroundColor: AppColors.primary,
      ),
    );
  }
}

