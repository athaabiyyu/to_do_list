// beranda_page.dart
// Halaman Beranda — saat ini berfungsi sebagai placeholder.
// Akan dilengkapi fiturnya pada step berikutnya.
// Halaman ini dituju setelah login berhasil.

import 'package:flutter/material.dart';

class BerandaPage extends StatelessWidget {
  const BerandaPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Beranda'),
        // Menghapus tombol back agar pengguna tidak bisa kembali ke Login
        // setelah berhasil masuk
        automaticallyImplyLeading: false,
      ),
      body: const Center(
        child: Text(
          'Selamat datang di Beranda!\nHalaman ini akan dikembangkan.',
          textAlign: TextAlign.center,
          style: TextStyle(fontSize: 16),
        ),
      ),
    );
  }
}