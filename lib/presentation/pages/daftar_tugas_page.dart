// daftar_tugas_page.dart — Placeholder, akan dikembangkan pada step berikutnya.
import "package:flutter/material.dart";
class DaftarTugasPage extends StatelessWidget {
  const DaftarTugasPage({super.key});
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Daftar Tugas"),
        backgroundColor: Theme.of(context).colorScheme.primary,
        foregroundColor: Colors.white,
      ),
      body: const Center(
        child: Text("Halaman ini akan dikembangkan.",
            style: TextStyle(fontSize: 16)),
      ),
    );
  }
}