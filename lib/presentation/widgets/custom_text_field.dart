
import 'package:flutter/material.dart';

class CustomTextField extends StatelessWidget {
  // --- PROPERTI ---

  final TextEditingController controller;
  final String label;
  final String hint;
  final IconData prefixIcon;
  final bool isPassword;  
  final String? Function(String?)? validator; 

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
      obscureText: isPassword, 
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