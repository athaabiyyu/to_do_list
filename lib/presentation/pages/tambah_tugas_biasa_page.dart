// tambah_tugas_biasa_page.dart — Placeholder, akan dikembangkan pada step berikutnya.
import "package:flutter/material.dart";
class TambahTugasBiasaPage extends StatelessWidget {
  const TambahTugasBiasaPage({super.key});
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Tambah Tugas Biasa"),
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