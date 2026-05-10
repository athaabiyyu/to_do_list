// tambah_tugas_penting_page.dart — Placeholder, akan dikembangkan pada step berikutnya.
import "package:flutter/material.dart";
class TambahTugasPentingPage extends StatelessWidget {
  const TambahTugasPentingPage({super.key});
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Tambah Tugas Penting"),
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