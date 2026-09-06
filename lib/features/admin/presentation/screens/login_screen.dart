import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'login_mode.dart';
import '../../../../shared/widgets/custom_button.dart';
import '../../../../shared/widgets/custom_text_field.dart';
import '../../cubit/auth_cubit.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  LoginMode _loginMode = LoginMode.owner; // owner atau employee
  bool _isRegisterMode = false; // mode registrasi untuk owner
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _fullNameController = TextEditingController();
  final _usernameController = TextEditingController();
  final _pinController = TextEditingController();
  bool _obscurePassword = true;
  bool _obscurePin = true;

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    _fullNameController.dispose();
    _usernameController.dispose();
    _pinController.dispose();
    super.dispose();
  }

  void _handleLogin() async {
    if (_formKey.currentState!.validate()) {
      if (_loginMode == LoginMode.owner) {
        if (_isRegisterMode) {
          await context.read<AuthCubit>().register(
                _emailController.text.trim(),
                _passwordController.text.trim(),
                _fullNameController.text.trim(),
              );
        } else {
          await context.read<AuthCubit>().login(
                _emailController.text.trim(),
                _passwordController.text.trim(),
              );
        }
      } else {
        await context.read<AuthCubit>().loginByPin(
              _usernameController.text.trim(),
              _pinController.text.trim(),
            );
      }
    }
  }

  void _switchLoginMode(LoginMode mode) {
    setState(() {
      _loginMode = mode;
      _isRegisterMode = false;
    });
    _emailController.clear();
    _passwordController.clear();
    _fullNameController.clear();
    _usernameController.clear();
    _pinController.clear();
  }

  void _toggleRegisterMode() {
    setState(() {
      _isRegisterMode = !_isRegisterMode;
    });
    _emailController.clear();
    _passwordController.clear();
    _fullNameController.clear();
  }

  void _showMessageDialog(String message) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
        title: Row(
          children: [
            Icon(
              message.toLowerCase().contains('berhasil')
                  ? Icons.check_circle_outline
                  : Icons.error_outline,
              color: message.toLowerCase().contains('berhasil')
                  ? Colors.green
                  : Colors.red,
              size: 28,
            ),
            const SizedBox(width: 8),
            Text(message.toLowerCase().contains('berhasil')
                ? 'Berhasil'
                : 'Login Gagal'),
          ],
        ),
        content: SelectableText(
          message,
          style: const TextStyle(fontSize: 14),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: const Text('TUTUP', style: TextStyle(color: Colors.blue)),
          ),
        ],
      ),
    );
  }

  void _showLoadingDialog() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => const Center(
        child: Card(
          child: Padding(
            padding: EdgeInsets.all(24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                CircularProgressIndicator(),
                SizedBox(height: 16),
                Text('Memproses...'),
              ],
            ),
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return BlocListener<AuthCubit, AuthState>(
      listener: (context, state) {
        if (state is Authenticated) {
          // Tutup semua dialog lalu navigasi
          while (Navigator.of(context).canPop()) {
            Navigator.of(context).pop();
          }

          // Role-based routing — semua role masuk ke dashboard (employee screen belum tersedia)
          final role = state.staff.role;
          print('🚀 [NAV] Redirecting to: /dashboard (role: $role)');
          context.go('/dashboard');
        } else if (state is AuthUnauthenticated) {
          // Tutup loading dialog jika terbuka
          if (Navigator.of(context).canPop()) {
            Navigator.of(context).pop();
          }

          // Tampilkan pesan error atau info
          if (state.message != null && state.message!.isNotEmpty) {
            _showMessageDialog(state.message!);
          }
        }
      },
      child: Scaffold(
        body: Container(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [Color(0xFF2196F3), Color(0xFF1976D2)],
            ),
          ),
          child: SafeArea(
            child: Center(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(24),
                child: Card(
                  elevation: 8,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Container(
                    constraints: const BoxConstraints(maxWidth: 400),
                    padding: const EdgeInsets.all(32),
                    child: Form(
                      key: _formKey,
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Container(
                            width: 80,
                            height: 80,
                            decoration: BoxDecoration(
                              color: const Color(0xFF2196F3),
                              shape: BoxShape.circle,
                            ),
                            child: const Icon(
                              Icons.local_laundry_service,
                              size: 40,
                              color: Colors.white,
                            ),
                          ),
                          const SizedBox(height: 24),
                          Text(
                            'Laundry28',
                            style: const TextStyle(
                              fontSize: 28,
                              fontWeight: FontWeight.bold,
                              color: Color(0xFF212121),
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            'Panel Admin Karyawan',
                            style: const TextStyle(
                              fontSize: 14,
                              color: Color(0xFF757575),
                            ),
                          ),
                          const SizedBox(height: 24),
                          // Toggle Owner / Karyawan
                          Container(
                            decoration: BoxDecoration(
                              color: Colors.grey[100],
                              borderRadius: BorderRadius.circular(12),
                            ),
                            padding: const EdgeInsets.all(4),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Expanded(
                                  child: GestureDetector(
                                    onTap: () => _switchLoginMode(LoginMode.owner),
                                    child: Container(
                                      alignment: Alignment.center,
                                      padding: const EdgeInsets.symmetric(vertical: 10),
                                      decoration: BoxDecoration(
                                        color: _loginMode == LoginMode.owner
                                            ? const Color(0xFF2196F3)
                                            : Colors.transparent,
                                        borderRadius: BorderRadius.circular(10),
                                      ),
                                      child: Text(
                                        'Owner',
                                        style: TextStyle(
                                          fontSize: 14,
                                          fontWeight: FontWeight.w600,
                                          color: _loginMode == LoginMode.owner
                                              ? Colors.white
                                              : Colors.grey[600],
                                        ),
                                      ),
                                    ),
                                  ),
                                ),
                                Expanded(
                                  child: GestureDetector(
                                    onTap: () => _switchLoginMode(LoginMode.employee),
                                    child: Container(
                                      alignment: Alignment.center,
                                      padding: const EdgeInsets.symmetric(vertical: 10),
                                      decoration: BoxDecoration(
                                        color: _loginMode == LoginMode.employee
                                            ? const Color(0xFF2196F3)
                                            : Colors.transparent,
                                        borderRadius: BorderRadius.circular(10),
                                      ),
                                      child: Text(
                                        'Karyawan',
                                        style: TextStyle(
                                          fontSize: 14,
                                          fontWeight: FontWeight.w600,
                                          color: _loginMode == LoginMode.employee
                                              ? Colors.white
                                              : Colors.grey[600],
                                        ),
                                      ),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(height: 24),
                          if (_loginMode == LoginMode.employee)
                            const Padding(
                              padding: EdgeInsets.only(bottom: 16),
                              child: Text(
                                'Login sebagai Karyawan',
                                style: TextStyle(
                                  fontSize: 12,
                                  color: Color(0xFF757575),
                                ),
                              ),
                            )
                          else
                            const Padding(
                              padding: EdgeInsets.only(bottom: 16),
                              child: Text(
                                'Login sebagai Owner',
                                style: TextStyle(
                                  fontSize: 12,
                                  color: Color(0xFF757575),
                                ),
                              ),
                            ),
                          const SizedBox(height: 16),
                          // Owner login form (email + password)
                          if (_loginMode == LoginMode.owner) ...[
                            CustomTextField(
                              labelText: 'Email',
                              controller: _emailController,
                              prefixIcon: const Icon(Icons.email_outlined),
                              keyboardType: TextInputType.emailAddress,
                              validator: (v) {
                                if (v == null || v.isEmpty) {
                                  return 'Email wajib diisi';
                                }
                                if (!v.contains('@')) {
                                  return 'Email tidak valid';
                                }
                                return null;
                              },
                            ),
                            const SizedBox(height: 16),
                            CustomTextField(
                              labelText: 'Password',
                              controller: _passwordController,
                              obscureText: _obscurePassword,
                              prefixIcon: const Icon(Icons.lock_outline),
                              suffixIcon: IconButton(
                                icon: Icon(
                                  _obscurePassword
                                      ? Icons.visibility_off
                                      : Icons.visibility,
                                ),
                                onPressed: () {
                                  setState(
                                    () => _obscurePassword = !_obscurePassword,
                                  );
                                },
                              ),
                              validator: (v) {
                                if (v == null || v.isEmpty) {
                                  return 'Password wajib diisi';
                                }
                                return null;
                              },
                            ),
                          ],
                          // Employee login form (username + PIN)
                          if (_loginMode == LoginMode.employee) ...[
                            CustomTextField(
                              labelText: 'Username',
                              controller: _usernameController,
                              prefixIcon: const Icon(Icons.badge_outlined),
                              validator: (v) {
                                if (v == null || v.isEmpty) {
                                  return 'Username wajib diisi';
                                }
                                return null;
                              },
                            ),
                            const SizedBox(height: 16),
                            CustomTextField(
                              labelText: 'PIN (4-6 digit)',
                              controller: _pinController,
                              obscureText: _obscurePin,
                              prefixIcon: const Icon(Icons.pin_outlined),
                              suffixIcon: IconButton(
                                icon: Icon(
                                  _obscurePin
                                      ? Icons.visibility_off
                                      : Icons.visibility,
                                ),
                                onPressed: () {
                                  setState(
                                    () => _obscurePin = !_obscurePin,
                                  );
                                },
                              ),
                              keyboardType: TextInputType.number,
                              maxLength: 6,
                              hintText: 'Masukkan PIN 4-6 digit',
                              validator: (v) {
                                if (_loginMode == LoginMode.employee) {
                                  if (v == null || v.isEmpty) {
                                    return 'PIN wajib diisi';
                                  }
                                  if (v.length < 4 || v.length > 6) {
                                    return 'PIN harus 4-6 digit';
                                  }
                                  if (!RegExp(r'^\d+$').hasMatch(v)) {
                                    return 'PIN hanya boleh angka';
                                  }
                                }
                                return null;
                              },
                            ),
                          ],
                          const SizedBox(height: 32),
                          // Register mode: show full name field
                          if (_loginMode == LoginMode.owner && _isRegisterMode) ...[
                            CustomTextField(
                              labelText: 'NAMA LENGKAP',
                              controller: _fullNameController,
                              hintText: 'Masukkan nama lengkap',
                              prefixIcon: const Icon(Icons.person_outline),
                              validator: (v) {
                                if (_isRegisterMode) {
                                  if (v == null || v.isEmpty) {
                                    return 'Nama lengkap wajib diisi';
                                  }
                                }
                                return null;
                              },
                            ),
                            const SizedBox(height: 16),
                          ],
                          BlocBuilder<AuthCubit, AuthState>(
                            builder: (context, state) {
                              String buttonLabel = 'LOGIN';
                              if (_loginMode == LoginMode.owner && _isRegisterMode) {
                                buttonLabel = 'DAFTAR';
                              }
                              return CustomButton(
                                label: buttonLabel,
                                onPressed: state is AuthLoading
                                    ? null
                                    : _handleLogin,
                                isLoading: state is AuthLoading,
                              );
                            },
                          ),
                          const SizedBox(height: 16),
                          // Toggle register/login link for owner
                          if (_loginMode == LoginMode.owner)
                            GestureDetector(
                              onTap: _toggleRegisterMode,
                              child: Text.rich(
                                TextSpan(
                                  text: _isRegisterMode
                                      ? 'Sudah punya akun? '
                                      : 'Belum punya akun? ',
                                  style: const TextStyle(
                                    fontSize: 14,
                                    color: Color(0xFF757575),
                                  ),
                                  children: [
                                    TextSpan(
                                      text: _isRegisterMode
                                          ? 'Login di sini'
                                          : 'Buat Akun Owner',
                                      style: const TextStyle(
                                        fontSize: 14,
                                        color: Color(0xFF1976D2),
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  ],
                                ),
                                textAlign: TextAlign.center,
                              ),
                            ),
                          const SizedBox(height: 8),
                          // Owner mode: show demo credentials
                          if (_loginMode == LoginMode.owner && !_isRegisterMode) ...[
                            const Padding(
                              padding: EdgeInsets.only(top: 8),
                              child: Text(
                                'Demo: admin@laundry28.com / admin123',
                                style: TextStyle(
                                  fontSize: 12,
                                  color: Color(0xFF757575),
                                ),
                              ),
                            ),
                          ],
                          // Employee mode: show hint
                          if (_loginMode == LoginMode.employee)
                            const Padding(
                              padding: EdgeInsets.only(top: 8),
                              child: Text(
                                'Gunakan PIN yang diatur oleh owner',
                                style: TextStyle(
                                  fontSize: 12,
                                  color: Color(0xFF757575),
                                ),
                              ),
                            ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
