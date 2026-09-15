import 'package:flutter/foundation.dart';
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

  // Palette
  static const Color _primary = Color(0xFF6C5CE7);
  static const Color _primaryDark = Color(0xFF3B2FBF);
  static const Color _accent = Color(0xFFFFC168);
  static const Color _textDark = Color(0xFF1A1A2E);
  static const Color _textMuted = Color(0xFF9291A5);

  static const double _heroHeight = 236;
  static const double _sheetOverlap = 46;

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
    final bool isSuccess = message.toLowerCase().contains('berhasil');
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        child: Padding(
          padding: const EdgeInsets.fromLTRB(24, 28, 24, 20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 56,
                height: 56,
                decoration: BoxDecoration(
                  color: (isSuccess ? Colors.green : Colors.redAccent)
                      .withOpacity(0.12),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  isSuccess ? Icons.check_rounded : Icons.close_rounded,
                  color: isSuccess ? Colors.green : Colors.redAccent,
                  size: 30,
                ),
              ),
              const SizedBox(height: 16),
              Text(
                isSuccess ? 'Berhasil' : 'Login Gagal',
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w700,
                  color: _textDark,
                ),
              ),
              const SizedBox(height: 8),
              SelectableText(
                message,
                textAlign: TextAlign.center,
                style: const TextStyle(fontSize: 14, color: _textMuted),
              ),
              const SizedBox(height: 20),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () => Navigator.of(ctx).pop(),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: _primary,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape:
                        RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                    elevation: 0,
                  ),
                  child: const Text('TUTUP',
                      style: TextStyle(fontWeight: FontWeight.w600)),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showLoadingDialog() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => Center(
        child: Container(
          padding: const EdgeInsets.all(28),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(20),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.08),
                blurRadius: 24,
                offset: const Offset(0, 8),
              ),
            ],
          ),
          child: const Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              SizedBox(
                width: 32,
                height: 32,
                child: CircularProgressIndicator(
                  strokeWidth: 3,
                  valueColor: AlwaysStoppedAnimation<Color>(_primary),
                ),
              ),
              SizedBox(height: 16),
              Text('Memproses...', style: TextStyle(fontSize: 14, color: _textMuted)),
            ],
          ),
        ),
      ),
    );
  }

  void _handleGoogleSignIn() async {
    if (kIsWeb) {
      _showLoadingDialog();
    }
    try {
      await context.read<AuthCubit>().signInWithGoogle();
    } catch (e) {
      if (Navigator.of(context).canPop()) {
        Navigator.of(context).pop();
      }
      _showMessageDialog('Gagal login dengan Google. Coba lagi.');
    }
  }

  @override
  Widget build(BuildContext context) {
    return BlocListener<AuthCubit, AuthState>(
      listener: (context, state) {
        if (state is AuthGoogleLoading) {
          if (kIsWeb) {
            _showLoadingDialog();
          }
        }
        if (state is Authenticated) {
          while (Navigator.of(context).canPop()) {
            Navigator.of(context).pop();
          }
          final role = state.staff.role;
          print('🚀 [NAV] Redirecting to: /dashboard (role: $role)');
          context.go('/dashboard');
        } else if (state is AuthUnauthenticated) {
          if (Navigator.of(context).canPop()) {
            Navigator.of(context).pop();
          }
          if (state.message != null && state.message!.isNotEmpty) {
            _showMessageDialog(state.message!);
          }
        }
      },
      child: Scaffold(
        backgroundColor: Colors.white,
        body: SizedBox(
          height: double.infinity,
          child: Stack(
            children: [
              // ---------- HERO ----------
              SizedBox(
                height: _heroHeight,
                width: double.infinity,
                child: Stack(
                  clipBehavior: Clip.none,
                  children: [
                    Container(
                      decoration: const BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                          colors: [_primaryDark, _primary],
                        ),
                      ),
                    ),
                    // decorative shapes
                    Positioned(
                      top: -50,
                      right: -40,
                      child: _blob(160, Colors.white.withOpacity(0.06)),
                    ),
                    Positioned(
                      top: 30,
                      right: 70,
                      child: _blob(26, _accent.withOpacity(0.5)),
                    ),
                    Positioned(
                      top: 90,
                      left: -30,
                      child: _blob(90, Colors.white.withOpacity(0.05)),
                    ),
                    SafeArea(
                      bottom: false,
                      child: Padding(
                        padding: const EdgeInsets.fromLTRB(28, 12, 28, 0),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Container(
                                  width: 44,
                                  height: 44,
                                  decoration: BoxDecoration(
                                    color: Colors.white.withOpacity(0.15),
                                    borderRadius: BorderRadius.circular(14),
                                  ),
                                  child: const Icon(
                                    Icons.local_laundry_service_rounded,
                                    color: Colors.white,
                                    size: 24,
                                  ),
                                ),
                                const SizedBox(width: 12),
                                const Text(
                                  'Laundry28',
                                  style: TextStyle(
                                    color: Colors.white,
                                    fontSize: 18,
                                    fontWeight: FontWeight.w700,
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 22),
                            const Text(
                              'Selamat datang\nkembali 👋',
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 26,
                                height: 1.25,
                                fontWeight: FontWeight.w800,
                                letterSpacing: -0.5,
                              ),
                            ),
                            const SizedBox(height: 6),
                            Text(
                              'Masuk untuk kelola operasional laundry kamu',
                              style: TextStyle(
                                color: Colors.white.withOpacity(0.8),
                                fontSize: 13,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),

              // ---------- BOTTOM SHEET ----------
              Positioned(
                top: _heroHeight - _sheetOverlap,
                left: 0,
                right: 0,
                bottom: 0,
                child: Container(
                  decoration: const BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.only(
                      topLeft: Radius.circular(32),
                      topRight: Radius.circular(32),
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: Color(0x1F000000),
                        blurRadius: 30,
                        offset: Offset(0, -8),
                      ),
                    ],
                  ),
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.fromLTRB(28, 20, 28, 28),
                    child: Form(
                      key: _formKey,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          // drag handle
                          Center(
                            child: Container(
                              width: 40,
                              height: 4,
                              margin: const EdgeInsets.only(bottom: 22),
                              decoration: BoxDecoration(
                                color: Colors.grey.shade200,
                                borderRadius: BorderRadius.circular(4),
                              ),
                            ),
                          ),
                          // underline-tab role switch
                          Row(
                            children: [
                              Expanded(
                                child: _tabItem(
                                  label: 'Owner',
                                  selected: _loginMode == LoginMode.owner,
                                  onTap: () => _switchLoginMode(LoginMode.owner),
                                ),
                              ),
                              Expanded(
                                child: _tabItem(
                                  label: 'Karyawan',
                                  selected: _loginMode == LoginMode.employee,
                                  onTap: () =>
                                      _switchLoginMode(LoginMode.employee),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 28),

                          if (_loginMode == LoginMode.owner) ...[
                            CustomTextField(
                              labelText: 'Email',
                              controller: _emailController,
                              prefixIcon:
                                  const Icon(Icons.email_outlined, color: _textMuted),
                              keyboardType: TextInputType.emailAddress,
                              validator: (v) {
                                if (v == null || v.isEmpty) return 'Email wajib diisi';
                                if (!v.contains('@')) return 'Email tidak valid';
                                return null;
                              },
                            ),
                            const SizedBox(height: 14),
                            CustomTextField(
                              labelText: 'Password',
                              controller: _passwordController,
                              obscureText: _obscurePassword,
                              prefixIcon:
                                  const Icon(Icons.lock_outline, color: _textMuted),
                              suffixIcon: IconButton(
                                icon: Icon(
                                  _obscurePassword
                                      ? Icons.visibility_off_outlined
                                      : Icons.visibility_outlined,
                                  color: _textMuted,
                                ),
                                onPressed: () => setState(
                                    () => _obscurePassword = !_obscurePassword),
                              ),
                              validator: (v) {
                                if (v == null || v.isEmpty) return 'Password wajib diisi';
                                return null;
                              },
                            ),
                            if (!_isRegisterMode) ...[
                              const SizedBox(height: 10),
                              Align(
                                alignment: Alignment.centerRight,
                                child: Text(
                                  'Lupa password?',
                                  style: TextStyle(
                                    fontSize: 12.5,
                                    color: _primary,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ),
                            ],
                          ],

                          if (_loginMode == LoginMode.employee) ...[
                            CustomTextField(
                              labelText: 'Username',
                              controller: _usernameController,
                              prefixIcon:
                                  const Icon(Icons.badge_outlined, color: _textMuted),
                              validator: (v) {
                                if (v == null || v.isEmpty) return 'Username wajib diisi';
                                return null;
                              },
                            ),
                            const SizedBox(height: 14),
                            CustomTextField(
                              labelText: 'PIN (4-6 digit)',
                              controller: _pinController,
                              obscureText: _obscurePin,
                              prefixIcon:
                                  const Icon(Icons.pin_outlined, color: _textMuted),
                              suffixIcon: IconButton(
                                icon: Icon(
                                  _obscurePin
                                      ? Icons.visibility_off_outlined
                                      : Icons.visibility_outlined,
                                  color: _textMuted,
                                ),
                                onPressed: () =>
                                    setState(() => _obscurePin = !_obscurePin),
                              ),
                              keyboardType: TextInputType.number,
                              maxLength: 6,
                              hintText: 'Masukkan PIN 4-6 digit',
                              validator: (v) {
                                if (_loginMode == LoginMode.employee) {
                                  if (v == null || v.isEmpty) return 'PIN wajib diisi';
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
                            const SizedBox(height: 6),
                            _hintRow('Gunakan PIN yang diatur oleh owner'),
                          ],

                          if (_loginMode == LoginMode.owner && _isRegisterMode) ...[
                            const SizedBox(height: 14),
                            CustomTextField(
                              labelText: 'NAMA LENGKAP',
                              controller: _fullNameController,
                              hintText: 'Masukkan nama lengkap',
                              prefixIcon:
                                  const Icon(Icons.person_outline, color: _textMuted),
                              validator: (v) {
                                if (_isRegisterMode) {
                                  if (v == null || v.isEmpty) {
                                    return 'Nama lengkap wajib diisi';
                                  }
                                }
                                return null;
                              },
                            ),
                          ],

                          const SizedBox(height: 24),
                          BlocBuilder<AuthCubit, AuthState>(
                            builder: (context, state) {
                              String buttonLabel = 'LOGIN';
                              if (_loginMode == LoginMode.owner && _isRegisterMode) {
                                buttonLabel = 'DAFTAR';
                              }
                              return Container(
                                decoration: BoxDecoration(
                                  borderRadius: BorderRadius.circular(16),
                                  gradient: const LinearGradient(
                                    colors: [_primary, _primaryDark],
                                  ),
                                  boxShadow: [
                                    BoxShadow(
                                      color: _primary.withOpacity(0.35),
                                      blurRadius: 18,
                                      offset: const Offset(0, 10),
                                    ),
                                  ],
                                ),
                                child: CustomButton(
                                  label: buttonLabel,
                                  onPressed:
                                      state is AuthLoading ? null : _handleLogin,
                                  isLoading: state is AuthLoading,
                                ),
                              );
                            },
                          ),

                          if (_loginMode == LoginMode.owner) ...[
                            const SizedBox(height: 20),
                            Row(
                              children: [
                                Expanded(
                                    child:
                                        Divider(color: Colors.grey.shade200)),
                                const Padding(
                                  padding: EdgeInsets.symmetric(horizontal: 12),
                                  child: Text('atau',
                                      style: TextStyle(
                                          fontSize: 12, color: _textMuted)),
                                ),
                                Expanded(
                                    child:
                                        Divider(color: Colors.grey.shade200)),
                              ],
                            ),
                            const SizedBox(height: 20),
                            BlocBuilder<AuthCubit, AuthState>(
                              builder: (context, authState) {
                                final disabled = authState is AuthLoading ||
                                    authState is AuthGoogleLoading;
                                return SizedBox(
                                  width: double.infinity,
                                  child: OutlinedButton.icon(
                                    onPressed:
                                        disabled ? null : _handleGoogleSignIn,
                                    icon: const Text(
                                      'G',
                                      style: TextStyle(
                                        fontSize: 16,
                                        fontWeight: FontWeight.bold,
                                        color: Color(0xFF4285F4),
                                      ),
                                    ),
                                    label: const Text(
                                      'Sign in with Google',
                                      style: TextStyle(
                                        fontSize: 14,
                                        fontWeight: FontWeight.w600,
                                        color: _textDark,
                                      ),
                                    ),
                                    style: OutlinedButton.styleFrom(
                                      side: BorderSide(
                                          color: Colors.grey.shade300, width: 1.4),
                                      padding:
                                          const EdgeInsets.symmetric(vertical: 14),
                                      shape: RoundedRectangleBorder(
                                          borderRadius: BorderRadius.circular(14)),
                                    ),
                                  ),
                                );
                              },
                            ),
                            const SizedBox(height: 22),
                            Center(
                              child: GestureDetector(
                                onTap: _toggleRegisterMode,
                                child: Text.rich(
                                  TextSpan(
                                    text: _isRegisterMode
                                        ? 'Sudah punya akun? '
                                        : 'Belum punya akun? ',
                                    style: const TextStyle(
                                        fontSize: 13.5, color: _textMuted),
                                    children: [
                                      TextSpan(
                                        text: _isRegisterMode
                                            ? 'Login di sini'
                                            : 'Buat Akun Owner',
                                        style: const TextStyle(
                                          fontSize: 13.5,
                                          color: _primary,
                                          fontWeight: FontWeight.w700,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            ),
                          ],
                          const SizedBox(height: 8),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _tabItem({
    required String label,
    required bool selected,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 220),
        padding: const EdgeInsets.only(bottom: 12),
        decoration: BoxDecoration(
          border: Border(
            bottom: BorderSide(
              color: selected ? _primary : Colors.grey.shade200,
              width: 2.5,
            ),
          ),
        ),
        child: Text(
          label,
          textAlign: TextAlign.center,
          style: TextStyle(
            fontSize: 14.5,
            fontWeight: FontWeight.w700,
            color: selected ? _textDark : _textMuted,
          ),
        ),
      ),
    );
  }

  Widget _hintRow(String text) {
    return Row(
      children: [
        const Icon(Icons.info_outline_rounded, size: 14, color: _textMuted),
        const SizedBox(width: 6),
        Expanded(
          child: Text(
            text,
            style: const TextStyle(fontSize: 12, color: _textMuted),
          ),
        ),
      ],
    );
  }

  Widget _blob(double size, Color color) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(shape: BoxShape.circle, color: color),
    );
  }
}