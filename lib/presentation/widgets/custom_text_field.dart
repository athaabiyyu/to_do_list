// custom_text_field.dart
// Widget TextField yang bisa dipakai ulang (reusable) di seluruh aplikasi.
// Keuntungan membuat widget sendiri:
// - Tampilan konsisten di semua halaman
// - Jika ingin ubah gaya, cukup ubah di satu file ini
// - Kode di halaman-halaman lain jadi lebih ringkas dan bersih

import 'package:flutter/material.dart';

class CustomTextField extends StatelessWidget {
  // --- PROPERTI ---
  // Semua konfigurasi diterima dari luar (parent widget),
  // sehingga widget ini fleksibel dan bisa dipakai untuk berbagai field.

  final TextEditingController controller;
  final String label;
  final String hint;
  final IconData prefixIcon;
  final bool isPassword;   // jika true, teks akan disembunyikan (••••)
  final String? Function(String?)? validator; // fungsi validasi opsional

  const CustomTextField({
    super.key,
    required this.controller,
    required this.label,
    required this.hint,
    required this.prefixIcon,
    this.isPassword = false,
    this.validator,
  });

  @override
  Widget build(BuildContext context) {
    // Mengambil warna dari tema aktif aplikasi
    final colorScheme = Theme.of(context).colorScheme;

    return TextFormField(
      controller: controller,
      obscureText: isPassword, // sembunyikan teks jika ini field password
      validator: validator,
      decoration: InputDecoration(
        labelText: label,
        hintText: hint,

        // Ikon di sisi kiri field
        prefixIcon: Icon(prefixIcon, color: colorScheme.primary),

        // Border saat field tidak difokus
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(
            color: colorScheme.outline.withOpacity(0.5),
          ),
        ),

        // Border saat field sedang difokus (warna primary)
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(
            color: colorScheme.primary,
            width: 2,
          ),
        ),

        // Border saat validasi gagal (warna error)
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: colorScheme.error),
        ),
        focusedErrorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: colorScheme.error, width: 2),
        ),

        // Warna latar belakang field
        filled: true,
        fillColor: colorScheme.surfaceContainerHighest.withOpacity(0.3),
      ),
    );
  }
}