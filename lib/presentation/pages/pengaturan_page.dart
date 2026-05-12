// pengaturan_page.dart

import 'package:flutter/material.dart';
import '../../core/constants/app_constants.dart';
import '../../data/local/database_helper.dart';
import '../widgets/custom_text_field.dart';

class PengaturanPage extends StatefulWidget {
  const PengaturanPage({super.key});

  @override
  State<PengaturanPage> createState() => _PengaturanPageState();
}

class _PengaturanPageState extends State<PengaturanPage> {
  final _formKey               = GlobalKey<FormState>();
  final _passwordLamaController = TextEditingController();
  final _passwordBaruController = TextEditingController();
  final _konfirmasiController   = TextEditingController();

  // State untuk show/hide password masing-masing field
  bool _showPasswordLama      = false;
  bool _showPasswordBaru      = false;
  bool _showKonfirmasi        = false;
  bool _isLoading             = false;

  // Username yang sedang aktif (ditampilkan di halaman)
  String _username = '';

  static const _accentColor = Color(0xFF6A1B9A); // ungu — identitas halaman

  @override
  void initState() {
    super.initState();
    _loadUsername();
  }

  @override
  void dispose() {
    _passwordLamaController.dispose();
    _passwordBaruController.dispose();
    _konfirmasiController.dispose();
    super.dispose();
  }

  Future<void> _loadUsername() async {
    final username = await DatabaseHelper.instance.getSetting(AppConstants.keyUsername);
    if (mounted) setState(() => _username = username ?? 'User');
  }

  // --- GANTI PASSWORD ---
  // Alur:
  // 1. Validasi form (field tidak boleh kosong, format sesuai)
  // 2. Ambil password saat ini dari SQLite
  // 3. Bandingkan dengan input password lama
  // 4. Jika cocok → simpan password baru
  // 5. Jika tidak cocok → tampilkan error
  Future<void> _gantiPassword() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);
    try {
      // Ambil password yang tersimpan di SQLite
      final passwordTersimpan = await DatabaseHelper.instance
          .getSetting(AppConstants.keyPassword);

      if (!mounted) return;

      // Verifikasi: password lama yang diinput harus cocok
      if (_passwordLamaController.text != passwordTersimpan) {
        _showSnackBar('Password saat ini salah!', isError: true);
        return;
      }

      // Simpan password baru ke SQLite
      await DatabaseHelper.instance.setSetting(
        AppConstants.keyPassword,
        _passwordBaruController.text,
      );

      if (!mounted) return;

      // Bersihkan semua field setelah berhasil
      _passwordLamaController.clear();
      _passwordBaruController.clear();
      _konfirmasiController.clear();

      _showSnackBar('Password berhasil diperbarui!', isError: false);

    } catch (e) {
      if (mounted) _showSnackBar('Terjadi kesalahan. Coba lagi.', isError: true);
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  void _showSnackBar(String message, {required bool isError}) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(children: [
          Icon(
            isError ? Icons.error_outline : Icons.check_circle_outline,
            color: Colors.white, size: 18,
          ),
          const SizedBox(width: 8),
          Expanded(child: Text(message)),
        ]),
        backgroundColor: isError ? Colors.red[700] : const Color(0xFF2E7D32),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;

    return Scaffold(
      backgroundColor: const Color(0xFFF5F6FA),
      appBar: AppBar(
        title: const Text('Pengaturan',
            style: TextStyle(fontWeight: FontWeight.bold, color: Colors.white)),
        backgroundColor: _accentColor,
        iconTheme: const IconThemeData(color: Colors.white),
        elevation: 0,
      ),
      body: SingleChildScrollView(
        padding: EdgeInsets.all(size.width * 0.05),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // 1. Kartu info akun aktif
            _buildInfoAkunCard(),
            const SizedBox(height: 16),

            // 2. Form ganti password
            _buildGantiPasswordCard(context),
            const SizedBox(height: 16),

            // 3. Kartu developer
            _buildDeveloperCard(size),
            const SizedBox(height: 16),
          ],
        ),
      ),
    );
  }

  // --- KARTU INFO AKUN ---
  Widget _buildInfoAkunCard() {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [_accentColor, _accentColor.withOpacity(0.78)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: _accentColor.withOpacity(0.3),
            blurRadius: 12, offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        children: [
          // Avatar inisial username
          Container(
            width: 52, height: 52,
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.25),
              shape: BoxShape.circle,
            ),
            child: Center(
              child: Text(
                _username.isNotEmpty
                    ? _username[0].toUpperCase()
                    : 'U',
                style: const TextStyle(
                    color: Colors.white,
                    fontSize: 22,
                    fontWeight: FontWeight.bold),
              ),
            ),
          ),
          const SizedBox(width: 14),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('Akun Aktif',
                  style: TextStyle(color: Colors.white70, fontSize: 12)),
              const SizedBox(height: 2),
              Text(_username,
                  style: const TextStyle(
                      color: Colors.white,
                      fontSize: 18,
                      fontWeight: FontWeight.bold)),
            ],
          ),
          const Spacer(),
          const Icon(Icons.verified_user_rounded,
              color: Colors.white54, size: 28),
        ],
      ),
    );
  }

  // --- FORM GANTI PASSWORD ---
  Widget _buildGantiPasswordCard(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.06),
            blurRadius: 10, offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Form(
        key: _formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header section
            Row(children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: _accentColor.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Icon(Icons.lock_reset_rounded,
                    color: _accentColor, size: 20),
              ),
              const SizedBox(width: 10),
              const Text('Ganti Password',
                  style: TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF212121))),
            ]),
            const SizedBox(height: 6),
            const Text(
              'Masukkan password saat ini untuk memverifikasi, lalu isi password baru.',
              style: TextStyle(fontSize: 12, color: Color(0xFF9E9E9E)),
            ),

            const Divider(height: 28),

            // Field Password Saat Ini
            // Menggunakan TextFormField langsung (bukan CustomTextField)
            // karena butuh toggle show/hide password yang dikelola state lokal
            _buildPasswordField(
              controller : _passwordLamaController,
              label      : 'Password Saat Ini',
              hint       : 'Masukkan password saat ini',
              isVisible  : _showPasswordLama,
              onToggle   : () => setState(() => _showPasswordLama = !_showPasswordLama),
              colorScheme: colorScheme,
              validator  : (value) {
                if (value == null || value.isEmpty) {
                  return 'Password saat ini tidak boleh kosong';
                }
                return null;
              },
            ),
            const SizedBox(height: 14),

            // Field Password Baru
            _buildPasswordField(
              controller : _passwordBaruController,
              label      : 'Password Baru',
              hint       : 'Minimal 4 karakter',
              isVisible  : _showPasswordBaru,
              onToggle   : () => setState(() => _showPasswordBaru = !_showPasswordBaru),
              colorScheme: colorScheme,
              validator  : (value) {
                if (value == null || value.isEmpty) {
                  return 'Password baru tidak boleh kosong';
                }
                if (value.length < 4) {
                  return 'Password minimal 4 karakter';
                }
                if (value == _passwordLamaController.text) {
                  return 'Password baru tidak boleh sama dengan yang lama';
                }
                return null;
              },
            ),
            const SizedBox(height: 14),

            // Field Konfirmasi Password Baru
            _buildPasswordField(
              controller : _konfirmasiController,
              label      : 'Konfirmasi Password Baru',
              hint       : 'Ulangi password baru',
              isVisible  : _showKonfirmasi,
              onToggle   : () => setState(() => _showKonfirmasi = !_showKonfirmasi),
              colorScheme: colorScheme,
              validator  : (value) {
                if (value == null || value.isEmpty) {
                  return 'Konfirmasi password tidak boleh kosong';
                }
                // Validasi: harus sama dengan password baru
                if (value != _passwordBaruController.text) {
                  return 'Password tidak cocok';
                }
                return null;
              },
            ),
            const SizedBox(height: 20),

            // Tombol Simpan Password
            SizedBox(
              width: double.infinity,
              height: 50,
              child: ElevatedButton.icon(
                onPressed: _isLoading ? null : _gantiPassword,
                icon: _isLoading
                    ? const SizedBox(
                        width: 18, height: 18,
                        child: CircularProgressIndicator(
                            strokeWidth: 2.5, color: Colors.white))
                    : const Icon(Icons.save_rounded),
                label: Text(
                  _isLoading ? 'Menyimpan...' : 'Simpan Password',
                  style: const TextStyle(
                      fontSize: 15, fontWeight: FontWeight.w600),
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: _accentColor,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12)),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // Helper widget untuk field password dengan tombol toggle show/hide.
  // Dipisah agar tidak mengulang kode yang sama 3 kali.
  Widget _buildPasswordField({
    required TextEditingController controller,
    required String label,
    required String hint,
    required bool isVisible,
    required VoidCallback onToggle,
    required ColorScheme colorScheme,
    required String? Function(String?) validator,
  }) {
    return TextFormField(
      controller  : controller,
      obscureText : !isVisible, // sembunyikan teks jika isVisible = false
      validator   : validator,
      decoration  : InputDecoration(
        labelText : label,
        hintText  : hint,
        prefixIcon: Icon(Icons.lock_outline_rounded, color: _accentColor),
        // Tombol di kanan untuk toggle tampil/sembunyikan password
        suffixIcon: IconButton(
          onPressed: onToggle,
          icon: Icon(
            isVisible ? Icons.visibility_off_rounded : Icons.visibility_rounded,
            color: Colors.grey,
            size: 20,
          ),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: colorScheme.outline.withOpacity(0.5)),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: _accentColor, width: 2),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: colorScheme.error),
        ),
        focusedErrorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: colorScheme.error, width: 2),
        ),
        filled    : true,
        fillColor : colorScheme.surfaceContainerHighest.withOpacity(0.3),
      ),
    );
  }

  // --- KARTU DEVELOPER ---
  // Menampilkan identitas pembuat aplikasi (foto, nama, NIM)
  Widget _buildDeveloperCard(Size size) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.06),
            blurRadius: 10, offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Column(
        children: [
          // Label "Developer"
          Row(children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Colors.blue.withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Icon(Icons.code_rounded,
                  color: Colors.blue, size: 20),
            ),
            const SizedBox(width: 10),
            const Text('Developer',
                style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF212121))),
          ]),

          const Divider(height: 24),

          // Foto developer
          // Saat ini menggunakan placeholder lingkaran dengan inisial.
          // Ganti dengan Image.asset('assets/foto.jpg') jika ada foto.
          Container(
            width: size.width * 0.28,
            height: size.width * 0.28,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: LinearGradient(
                colors: [
                  Colors.blue[400]!,
                  Colors.blue[800]!,
                ],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              boxShadow: [
                BoxShadow(
                  color: Colors.blue.withOpacity(0.3),
                  blurRadius: 12,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: ClipOval(child: Image.asset('assets/profile.jpg', fit: BoxFit.cover)),
          ),
          const SizedBox(height: 14),

          // Nama developer — GANTI DENGAN NAMA KAMU
          const Text(
            'Aulia Atha Abiyyu Iffat',
            style: TextStyle(
                fontSize: 17,
                fontWeight: FontWeight.bold,
                color: Color(0xFF212121)),
          ),
          const SizedBox(height: 4),

          // NIM — GANTI DENGAN NIM KAMU
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 5),
            decoration: BoxDecoration(
              color: Colors.blue.withOpacity(0.1),
              borderRadius: BorderRadius.circular(20),
            ),
            child: const Text(
              'NIM: 2241720249',
              style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: Colors.blue),
            ),
          ),
          const SizedBox(height: 8),

          // Keterangan role
          const Text(
            'Mobile App Developer',
            style: TextStyle(fontSize: 12, color: Color(0xFF9E9E9E)),
          ),
        ],
      ),
    );
  }
}