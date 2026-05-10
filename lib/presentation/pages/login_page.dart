// login_page.dart
// Halaman Login — halaman pertama yang muncul saat aplikasi dibuka.
// Bertanggung jawab untuk:
// 1. Menampilkan logo, nama, dan tagline aplikasi
// 2. Menerima input username dan password
// 3. Memvalidasi input dengan data yang tersimpan di SQLite
// 4. Mengarahkan ke halaman Beranda jika login berhasil

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

// State dipisah dari widget karena halaman ini memiliki data yang berubah
// (loading state, nilai controller, dll) — inilah kegunaan StatefulWidget.
class _LoginPageState extends State<LoginPage> {

  // --- CONTROLLER ---
  // TextEditingController digunakan untuk membaca nilai yang diketik user
  // di dalam TextField. Wajib di-dispose saat widget dihancurkan.
  final _usernameController = TextEditingController();
  final _passwordController = TextEditingController();

  // GlobalKey untuk Form — digunakan untuk memvalidasi semua field sekaligus
  final _formKey = GlobalKey<FormState>();

  // State untuk menampilkan loading indicator saat proses login berlangsung
  bool _isLoading = false;

  // --- DISPOSE ---
  // Wajib! Melepaskan resource controller dari memori saat halaman ditutup.
  // Jika tidak di-dispose, bisa menyebabkan memory leak.
  @override
  void dispose() {
    _usernameController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  // --- FUNGSI LOGIN ---
  // Fungsi ini dipanggil saat tombol "Login" ditekan.
  Future<void> _handleLogin() async {
    // Jalankan validasi form terlebih dahulu.
    // Jika ada field yang tidak valid, proses dihentikan.
    if (!_formKey.currentState!.validate()) return;

    // Tampilkan loading indicator dan matikan interaksi
    setState(() => _isLoading = true);

    try {
      // Ambil username dan password yang tersimpan di database SQLite
      final db = DatabaseHelper.instance;
      final savedUsername = await db.getSetting(AppConstants.keyUsername);
      final savedPassword = await db.getSetting(AppConstants.keyPassword);

      // Bandingkan input user dengan data di database
      final inputUsername = _usernameController.text.trim();
      final inputPassword = _passwordController.text;

      final isValid =
          inputUsername == savedUsername && inputPassword == savedPassword;

      if (!mounted) return; // Pastikan widget masih ada sebelum update UI

      if (isValid) {
        // Login berhasil → navigasi ke Beranda
        // pushReplacement mengganti halaman ini dengan Beranda,
        // sehingga user tidak bisa kembali ke Login dengan tombol back.
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (_) => const BerandaPage()),
        );
      } else {
        // Login gagal → tampilkan pesan error via SnackBar
        _showErrorSnackBar('Username atau password salah.');
      }
    } catch (e) {
      // Tangani error tak terduga (misal DB error)
      if (mounted) _showErrorSnackBar('Terjadi kesalahan. Coba lagi.');
    } finally {
      // Sembunyikan loading indicator, apapun hasilnya
      if (mounted) setState(() => _isLoading = false);
    }
  }

  // --- HELPER: Tampilkan pesan error ---
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

  // --- BUILD UI ---
  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Scaffold(
      // Agar konten tidak tertimpa keyboard saat field ditekan
      resizeToAvoidBottomInset: true,
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            // Padding responsif: menggunakan persentase lebar layar
            // agar tampilan proporsional di berbagai ukuran ponsel
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
                  // --- BAGIAN LOGO & IDENTITAS APLIKASI ---
                  _buildAppIdentity(colorScheme),

                  const SizedBox(height: 48),

                  // --- BAGIAN FORM INPUT ---
                  _buildForm(),

                  const SizedBox(height: 24),

                  // --- TOMBOL LOGIN ---
                  _buildLoginButton(colorScheme),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  // --- WIDGET: Logo, Nama, dan Tagline Aplikasi ---
  // Dipisah menjadi method tersendiri agar build() tetap ringkas dan mudah dibaca.
  Widget _buildAppIdentity(ColorScheme colorScheme) {
    return Column(
      children: [
        // Logo aplikasi menggunakan Container berbentuk lingkaran
        // dengan icon di dalamnya — mudah diganti dengan gambar aset.
        Container(
          // Ukuran responsif berdasarkan lebar layar
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
            Icons.store_rounded, // icon toko — bisa diganti sesuai tema app
            size: MediaQuery.of(context).size.width * 0.13,
            color: colorScheme.onPrimaryContainer,
          ),
        ),

        const SizedBox(height: 20),

        // Nama Aplikasi
        Text(
          AppConstants.appName,
          style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                fontWeight: FontWeight.bold,
                color: colorScheme.onSurface,
                letterSpacing: 0.5,
              ),
        ),

        const SizedBox(height: 6),

        // Tagline / Deskripsi singkat
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

  // --- WIDGET: Form Input Username & Password ---
  Widget _buildForm() {
    return Column(
      children: [
        // Field Username menggunakan CustomTextField yang sudah dibuat
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
          isPassword: true, // aktifkan mode obscure text
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

  // --- WIDGET: Tombol Login ---
  Widget _buildLoginButton(ColorScheme colorScheme) {
    return SizedBox(
      height: 52, // tinggi tombol yang nyaman untuk disentuh
      child: ElevatedButton(
        onPressed: _isLoading ? null : _handleLogin,
        // Jika sedang loading, tombol dinonaktifkan (null = disabled)
        style: ElevatedButton.styleFrom(
          backgroundColor: colorScheme.primary,
          foregroundColor: colorScheme.onPrimary,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          elevation: 2,
        ),
        child: _isLoading
            // Tampilkan loading spinner saat proses login berlangsung
            ? SizedBox(
                width: 22,
                height: 22,
                child: CircularProgressIndicator(
                  strokeWidth: 2.5,
                  color: colorScheme.onPrimary,
                ),
              )
            // Tampilkan teks "Login" saat tidak loading
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