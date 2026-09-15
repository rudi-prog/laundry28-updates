import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import '../../cubit/auth_cubit.dart';
import '../../../../core/constants/app_routes.dart';

/// Halaman onboarding untuk owner baru
/// Memaksa owner untuk mengisi data laundry sebelum bisa mengakses dashboard
class OnboardingLaundryScreen extends StatefulWidget {
  const OnboardingLaundryScreen({super.key});

  @override
  State<OnboardingLaundryScreen> createState() => _OnboardingLaundryScreenState();
}

class _OnboardingLaundryScreenState extends State<OnboardingLaundryScreen> {
  final _formKey = GlobalKey<FormState>();
  final _laundryNameController = TextEditingController();
  final _addressController = TextEditingController();
  final _phoneController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _phoneController.text = '+62';
  }

  @override
  void dispose() {
    _laundryNameController.dispose();
    _addressController.dispose();
    _phoneController.dispose();
    super.dispose();
  }

  bool _isValidPhone(String phone) {
    final cleaned = phone.replaceAll('+62', '').trim();
    final regex = RegExp(r'^8\d{8,12}$');
    return regex.hasMatch(cleaned);
  }

  Future<void> _submitOnboarding() async {
    if (!_formKey.currentState!.validate()) return;
    await context.read<AuthCubit>().completeOnboarding(
          laundryName: _laundryNameController.text.trim(),
          address: _addressController.text.trim(),
          phone: _phoneController.text.trim(),
        );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F5F5),
      appBar: AppBar(
        title: const Text('Setup Laundry'),
        backgroundColor: const Color(0xFF6C5CE7),
        foregroundColor: Colors.white,
        elevation: 0,
      ),
      body: BlocConsumer<AuthCubit, AuthState>(
        listener: (context, state) {
          if (state is AuthOnboardingComplete) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text('Laundry "${state.laundryName}" berhasil dibuat!'),
                backgroundColor: Colors.green,
                behavior: SnackBarBehavior.floating,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
            );
            Future.microtask(() {
              if (context.mounted) {
                context.go(AppRoutes.ownerDashboard);
              }
            });
          }
          if (state is AuthOnboardingError) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(state.message),
                backgroundColor: Colors.red,
                behavior: SnackBarBehavior.floating,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
                duration: const Duration(seconds: 4),
              ),
            );
          }
        },
        builder: (context, state) {
          final isLoading = state is AuthOnboardingLoading;
          if (state is AuthOnboardingComplete) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.check_circle_outline, size: 100, color: Colors.green),
                  const SizedBox(height: 24),
                  Text(
                    'Laundry "${state.laundryName}" berhasil dibuat!',
                    style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'Mengalihkan ke dashboard...',
                    style: TextStyle(fontSize: 14, color: Colors.grey[600]),
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            );
          }
          return SingleChildScrollView(
            padding: const EdgeInsets.all(24.0),
            child: Form(
              key: _formKey,
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Container(
                    padding: const EdgeInsets.all(24),
                    decoration: BoxDecoration(
                      color: const Color(0xFF6C5CE7),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(Icons.storefront_rounded, size: 60, color: Colors.white),
                  ),
                  const SizedBox(height: 24),
                  const Text(
                    'Selamat Datang!',
                    textAlign: TextAlign.center,
                    style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold, color: Color(0xFF333333)),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Silakan setup laundry Anda terlebih dahulu',
                    textAlign: TextAlign.center,
                    style: TextStyle(fontSize: 14, color: Colors.grey[600]),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Langkah ini hanya perlu dilakukan sekali',
                    textAlign: TextAlign.center,
                    style: TextStyle(fontSize: 13, color: Colors.grey[500]),
                  ),
                  const SizedBox(height: 40),
                  TextFormField(
                    controller: _laundryNameController,
                    decoration: const InputDecoration(
                      labelText: 'Nama Laundry *',
                      hintText: 'Contoh: Laundry Bersih 28',
                      prefixIcon: Icon(Icons.storefront),
                      border: OutlineInputBorder(),
                      filled: true,
                      fillColor: Colors.white,
                    ),
                    textInputAction: TextInputAction.next,
                    validator: (value) {
                      if (value == null || value.trim().isEmpty) return 'Nama laundry harus diisi';
                      if (value.trim().length < 3) return 'Nama laundry minimal 3 karakter';
                      return null;
                    },
                  ),
                  const SizedBox(height: 16),
                  TextFormField(
                    controller: _addressController,
                    decoration: const InputDecoration(
                      labelText: 'Alamat Lengkap',
                      hintText: 'Jl. Contoh No. 123, Kelurahan, Kecamatan',
                      prefixIcon: Icon(Icons.location_on),
                      border: OutlineInputBorder(),
                      filled: true,
                      fillColor: Colors.white,
                    ),
                    maxLines: 2,
                    textInputAction: TextInputAction.next,
                    validator: (value) {
                      if (value == null || value.trim().isEmpty) return 'Alamat harus diisi';
                      return null;
                    },
                  ),
                  const SizedBox(height: 16),
                  TextFormField(
                    controller: _phoneController,
                    decoration: const InputDecoration(
                      labelText: 'Nomor Telepon *',
                      hintText: '8xxxxxxxxxx',
                      prefixIcon: Icon(Icons.phone),
                      border: OutlineInputBorder(),
                      filled: true,
                      fillColor: Colors.white,
                    ),
                    keyboardType: TextInputType.phone,
                    textInputAction: TextInputAction.done,
                    validator: (value) {
                      if (value == null || value.trim().isEmpty) return 'Nomor telepon harus diisi';
                      if (!_isValidPhone(value)) return 'Format nomor telepon tidak valid\nContoh: 81234567890';
                      return null;
                    },
                  ),
                  const SizedBox(height: 8),
                  Text(
                    '* Gunakan format: 8xxxxxxxxxx (tanpa kode negara)',
                    style: TextStyle(fontSize: 12, color: Colors.grey[500]),
                  ),
                  const SizedBox(height: 32),
                  ElevatedButton(
                    onPressed: isLoading ? null : _submitOnboarding,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF6C5CE7),
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      elevation: 2,
                    ),
                    child: isLoading
                        ? const SizedBox(
                            height: 20, width: 20,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                            ),
                          )
                        : const Text('Setup Laundry Sekarang', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                  ),
                  const SizedBox(height: 16),
                  TextButton(
                    onPressed: isLoading
                        ? null
                        : () async {
                            await context.read<AuthCubit>().logout();
                            if (context.mounted) {
                              context.go(AppRoutes.login);
                            }
                          },
                    child: const Text('Kembali ke halaman login', style: TextStyle(color: Color(0xFF6C5CE7), fontSize: 14)),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}
