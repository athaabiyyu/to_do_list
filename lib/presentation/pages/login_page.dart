import 'package:flutter/material.dart';
import '../../core/constants/app_constants.dart';
import '../../data/local/database_helper.dart';
import '../widgets/custom_text_field.dart';
import 'beranda_page.dart';

class LoginPage extends StatefulWidget {
  const LoginPage({super.key});

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {

  // controller
  final _usernameController = TextEditingController();
  final _passwordController = TextEditingController();

  // GlobalKey untuk Form
  final _formKey = GlobalKey<FormState>();

  // loading indicator
  bool _isLoading = false;

  // melepaskan resource controller dari memori saat halaman ditutup.
  @override
  void dispose() {
    _usernameController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  // Login function
  Future<void> _handleLogin() async {

    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    try {
      final db = DatabaseHelper.instance;

      // Ambil kredensial yang tersimpan di database
      final savedUsername = await db.getSetting(AppConstants.keyUsername);
      final savedPassword = await db.getSetting(AppConstants.keyPassword);

      // Bandingkan dengan input pengguna
      final inputUsername = _usernameController.text.trim();
      final inputPassword = _passwordController.text;

      final isValid =
          inputUsername == savedUsername && inputPassword == savedPassword;

      if (!mounted) return;

      if (isValid) {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (_) => const BerandaPage()),
        );
      } else {
        _showErrorSnackBar('Username atau password salah.');
      }
    } catch (e) {
      if (mounted) _showErrorSnackBar('Terjadi kesalahan. Coba lagi.');
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  // helper untuk menampilkan pesan error 
  void _showErrorSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Theme.of(context).colorScheme.error,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      ),
    );
  }

  // UI
  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Scaffold(
      resizeToAvoidBottomInset: true,
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: EdgeInsets.symmetric(
              horizontal: MediaQuery.of(context).size.width * 0.08,
              vertical: 32,
            ),
            child: Form(
              key: _formKey,
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  _buildAppIdentity(colorScheme),

                  const SizedBox(height: 48),

                  _buildForm(),

                  const SizedBox(height: 24),

                  _buildLoginButton(colorScheme),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  // Widget : logo, nama, dan tagline aplikasi 
  Widget _buildAppIdentity(ColorScheme colorScheme) {
    return Column(
      children: [
        Container(
          width: MediaQuery.of(context).size.width * 0.28,
          height: MediaQuery.of(context).size.width * 0.28,
          decoration: BoxDecoration(
            color: colorScheme.primaryContainer,
            shape: BoxShape.circle,
            boxShadow: [
              BoxShadow(
                color: colorScheme.primary.withOpacity(0.2),
                blurRadius: 20,
                offset: const Offset(0, 8),
              ),
            ],
          ),
          child: Icon(
            Icons.check_circle_outline_rounded,
            size: MediaQuery.of(context).size.width * 0.13,
            color: colorScheme.onPrimaryContainer,
          ),
        ),

        const SizedBox(height: 20),

        Text(
          AppConstants.appName,
          style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                fontWeight: FontWeight.bold,
                color: colorScheme.onSurface,
                letterSpacing: 0.5,
              ),
        ),

        const SizedBox(height: 6),

        Text(
          AppConstants.appTagline,
          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: colorScheme.onSurfaceVariant,
              ),
          textAlign: TextAlign.center,
        ),
      ],
    );
  }

  // Widget : form input username & password 
  Widget _buildForm() {
    return Column(
      children: [
        CustomTextField(
          controller: _usernameController,
          label: 'Username',
          hint: 'Masukkan username Anda',
          prefixIcon: Icons.person_outline_rounded,
          validator: (value) {
            // Validasi: field tidak boleh kosong
            if (value == null || value.trim().isEmpty) {
              return 'Username tidak boleh kosong';
            }
            return null; // null = valid
          },
        ),

        const SizedBox(height: 16),

        // Field Password
        CustomTextField(
          controller: _passwordController,
          label: 'Password',
          hint: 'Masukkan password Anda',
          prefixIcon: Icons.lock_outline_rounded,
          isPassword: true, 
          validator: (value) {
            if (value == null || value.isEmpty) {
              return 'Password tidak boleh kosong';
            }
            return null;
          },
        ),
      ],
    );
  }

  // Widget : Tombol Login 
  Widget _buildLoginButton(ColorScheme colorScheme) {
    return SizedBox(
      height: 52,
      child: ElevatedButton(
        onPressed: _isLoading ? null : _handleLogin,
        style: ElevatedButton.styleFrom(
          backgroundColor: colorScheme.primary,
          foregroundColor: colorScheme.onPrimary,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          elevation: 2,
        ),
        child: _isLoading
            ? SizedBox(
                width: 22,
                height: 22,
                child: CircularProgressIndicator(
                  strokeWidth: 2.5,
                  color: colorScheme.onPrimary,
                ),
              )
            : const Text(
                'Login',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  letterSpacing: 0.5,
                ),
              ),
      ),
    );
  }
}