// main.dart
// Entry point aplikasi Flutter — file pertama yang dijalankan.
// Bertanggung jawab untuk:
// 1. Inisialisasi Flutter engine
// 2. Menyiapkan database sebelum UI ditampilkan
// 3. Mendefinisikan tema aplikasi secara global
// 4. Menentukan halaman pertama yang dibuka (LoginPage)

import 'package:flutter/material.dart';
import 'data/local/database_helper.dart';
import 'presentation/pages/login_page.dart';

Future<void> main() async {
  // WidgetsFlutterBinding.ensureInitialized() wajib dipanggil
  // sebelum menggunakan fitur async di main(), misalnya akses database.
  // Ini menginisialisasi binding antara Flutter engine dan framework.
  WidgetsFlutterBinding.ensureInitialized();

  // Inisialisasi database SQLite sebelum aplikasi berjalan.
  // Dengan memanggil getter 'database', tabel dan data default
  // akan otomatis dibuat jika belum ada.
  await DatabaseHelper.instance.database;

  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'DigiStore',

      // Menyembunyikan banner "DEBUG" di pojok kanan atas
      debugShowCheckedModeBanner: false,

      // --- TEMA APLIKASI ---
      // Tema didefinisikan di satu tempat agar konsisten di seluruh halaman.
      // colorSchemeSeed menentukan warna utama (primary) dan
      // Flutter akan otomatis generate warna-warna turunannya.
      theme: ThemeData(
        colorSchemeSeed: const Color(0xFF1565C0), // Biru profesional
        brightness: Brightness.light,
        useMaterial3: true, // Gunakan Material Design 3 (terbaru)

        // Tema untuk AppBar
        appBarTheme: const AppBarTheme(
          centerTitle: true,
          elevation: 0,
        ),
      ),

      // Halaman pertama yang ditampilkan saat aplikasi dibuka
      home: const LoginPage(),
    );
  }
}