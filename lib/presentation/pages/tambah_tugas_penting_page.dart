// tambah_tugas_penting_page.dart
// Halaman untuk menambahkan tugas berkategori "penting" ke database SQLite.
// Bertanggung jawab untuk:
// 1. Menampilkan form: judul, deskripsi, dan tanggal jatuh tempo
// 2. Validasi input sebelum disimpan
// 3. Menyimpan data ke SQLite via DatabaseHelper
// 4. Kembali ke Beranda setelah simpan (agar Beranda bisa refresh data)

import 'package:flutter/material.dart';
import '../../data/local/database_helper.dart';
import '../widgets/custom_text_field.dart';

class TambahTugasPentingPage extends StatefulWidget {
  const TambahTugasPentingPage({super.key});

  @override
  State<TambahTugasPentingPage> createState() => _TambahTugasPentingPageState();
}

class _TambahTugasPentingPageState extends State<TambahTugasPentingPage> {
  // --- CONTROLLER & KEY ---
  final _formKey        = GlobalKey<FormState>();
  final _judulController      = TextEditingController();
  final _deskripsiController  = TextEditingController();

  // Menyimpan tanggal yang dipilih dari DatePicker.
  // Nullable karena awalnya belum dipilih.
  DateTime? _selectedDate;

  bool _isLoading = false;

  @override
  void dispose() {
    // Wajib dispose controller untuk mencegah memory leak
    _judulController.dispose();
    _deskripsiController.dispose();
    super.dispose();
  }

  // --- DATE PICKER ---
  // Menampilkan dialog kalender bawaan Flutter.
  // firstDate = hari ini (tidak bisa pilih tanggal lampau)
  // lastDate  = 5 tahun ke depan
  Future<void> _pickDate() async {
    final now    = DateTime.now();
    final picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate ?? now,
      firstDate: now,
      lastDate: DateTime(now.year + 5),
      helpText: 'Pilih Tanggal Jatuh Tempo',
      confirmText: 'Pilih',
      cancelText: 'Batal',
      builder: (context, child) {
        // Membungkus DatePicker dengan Theme agar warnanya sesuai tema app
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: Theme.of(context).colorScheme.copyWith(
              primary: const Color(0xFFE53935), // merah — identik tugas penting
            ),
          ),
          child: child!,
        );
      },
    );

    // Hanya update state jika user memilih tanggal (tidak tekan Batal)
    if (picked != null) {
      setState(() => _selectedDate = picked);
    }
  }

  // --- FORMAT TANGGAL ---
  // Mengubah DateTime menjadi string yang ramah dibaca,
  // misal: "Senin, 12 Mei 2026"
  String _formatTanggal(DateTime date) {
    const hariList  = ['Senin','Selasa','Rabu','Kamis','Jumat','Sabtu','Minggu'];
    const bulanList = ['','Januari','Februari','Maret','April','Mei','Juni',
                       'Juli','Agustus','September','Oktober','November','Desember'];
    return '${hariList[date.weekday - 1]}, ${date.day} ${bulanList[date.month]} ${date.year}';
  }

  // --- SIMPAN TUGAS ---
  Future<void> _simpan() async {
    // Langkah 1: Validasi semua field di Form
    if (!_formKey.currentState!.validate()) return;

    // Langkah 2: Validasi tanggal jatuh tempo (wajib dipilih)
    if (_selectedDate == null) {
      _showSnackBar('Pilih tanggal jatuh tempo terlebih dahulu.', isError: true);
      return;
    }

    setState(() => _isLoading = true);

    try {
      // Langkah 3: Simpan ke SQLite via DatabaseHelper
      // prioritas diset 'penting' secara otomatis di halaman ini
      await DatabaseHelper.instance.insertTugas(
        judul     : _judulController.text.trim(),
        deskripsi : _deskripsiController.text.trim(),
        prioritas : 'penting',
        jatuhTempo: _selectedDate!, // sudah dipastikan tidak null di atas
      );

      if (!mounted) return;

      // Langkah 4: Tampilkan notifikasi sukses
      _showSnackBar('Tugas penting berhasil disimpan!', isError: false);

      // Langkah 5: Kembali ke halaman sebelumnya (Beranda)
      // pop() mengembalikan kontrol ke Beranda, lalu Beranda akan
      // memanggil _loadData() via .then() di _navigateAndRefresh()
      await Future.delayed(const Duration(milliseconds: 800));
      if (mounted) Navigator.pop(context);

    } catch (e) {
      if (mounted) {
        _showSnackBar('Gagal menyimpan tugas. Coba lagi.', isError: true);
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  void _showSnackBar(String message, {required bool isError}) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: isError ? const Color(0xFFE53935) : const Color(0xFF2E7D32),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    // Warna aksen halaman ini: merah — mencerminkan urgensi tugas penting
    const accentColor = Color(0xFFE53935);

    return Scaffold(
      backgroundColor: const Color(0xFFF5F6FA),
      appBar: AppBar(
        title: const Text('Tambah Tugas Penting',
            style: TextStyle(fontWeight: FontWeight.bold, color: Colors.white)),
        backgroundColor: accentColor,
        // Tombol "<< Kembali" otomatis muncul karena ada Navigator.push sebelumnya
        // Flutter akan menampilkan tombol back bawaan di sini
        iconTheme: const IconThemeData(color: Colors.white),
        elevation: 0,
      ),
      body: SingleChildScrollView(
        padding: EdgeInsets.all(MediaQuery.of(context).size.width * 0.05),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // --- HEADER CARD: Identitas kategori tugas ---
              _buildHeaderCard(accentColor),
              const SizedBox(height: 20),

              // --- FORM CARD: Field-field input ---
              _buildFormCard(colorScheme, accentColor),
              const SizedBox(height: 24),

              // --- TOMBOL SIMPAN ---
              _buildTombolSimpan(accentColor),
              const SizedBox(height: 12),

              // --- TOMBOL KEMBALI ---
              _buildTombolKembali(accentColor),
            ],
          ),
        ),
      ),
    );
  }

  // --- WIDGET: Header Card ---
  // Menampilkan identitas visual halaman ini (ikon + keterangan kategori)
  Widget _buildHeaderCard(Color accentColor) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [accentColor, accentColor.withOpacity(0.78)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: accentColor.withOpacity(0.3),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.2),
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Icon(
              Icons.priority_high_rounded,
              color: Colors.white,
              size: 28,
            ),
          ),
          const SizedBox(width: 14),
          const Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Tugas Penting',
                    style: TextStyle(
                        color: Colors.white,
                        fontSize: 18,
                        fontWeight: FontWeight.bold)),
                SizedBox(height: 3),
                Text('Tugas dengan prioritas tinggi yang perlu segera diselesaikan.',
                    style: TextStyle(color: Colors.white70, fontSize: 12)),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // --- WIDGET: Form Card ---
  // Semua field input dibungkus dalam satu card agar terlihat rapi & terkelompok
  Widget _buildFormCard(ColorScheme colorScheme, Color accentColor) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.06),
            blurRadius: 10,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Label "Detail Tugas"
          const Text('Detail Tugas',
              style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF424242))),
          const SizedBox(height: 16),

          // --- FIELD: Judul Tugas ---
          CustomTextField(
            controller: _judulController,
            label: 'Judul Tugas',
            hint: 'Contoh: Kerjakan laporan bulanan',
            prefixIcon: Icons.title_rounded,
            validator: (value) {
              if (value == null || value.trim().isEmpty) {
                return 'Judul tugas tidak boleh kosong';
              }
              if (value.trim().length < 3) {
                return 'Judul minimal 3 karakter';
              }
              return null;
            },
          ),
          const SizedBox(height: 16),

          // --- FIELD: Deskripsi Tugas ---
          // Menggunakan TextFormField langsung karena butuh maxLines > 1
          // (CustomTextField hanya untuk single-line input)
          _buildDeskripsiField(colorScheme),
          const SizedBox(height: 16),

          // --- FIELD: Tanggal Jatuh Tempo (Date Picker) ---
          _buildDatePickerField(accentColor),
        ],
      ),
    );
  }

  // Deskripsi menggunakan TextFormField dengan maxLines
  // agar pengguna bisa menulis keterangan lebih panjang
  Widget _buildDeskripsiField(ColorScheme colorScheme) {
    return TextFormField(
      controller: _deskripsiController,
      maxLines: 3,
      maxLength: 200,
      decoration: InputDecoration(
        labelText: 'Deskripsi',
        hintText: 'Tambahkan keterangan tambahan (opsional)',
        prefixIcon: const Padding(
          padding: EdgeInsets.only(bottom: 48), // sejajarkan ikon ke atas
          child: Icon(Icons.notes_rounded),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: colorScheme.outline.withOpacity(0.5)),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: Color(0xFFE53935), width: 2),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: colorScheme.error),
        ),
        focusedErrorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: colorScheme.error, width: 2),
        ),
        filled: true,
        fillColor: colorScheme.surfaceContainerHighest.withOpacity(0.3),
      ),
    );
  }

  // Date Picker ditampilkan sebagai tombol yang terlihat seperti field
  // Saat ditekan, membuka dialog kalender bawaan Flutter
  Widget _buildDatePickerField(Color accentColor) {
    final isSelected = _selectedDate != null;

    return GestureDetector(
      onTap: _pickDate,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 16),
        decoration: BoxDecoration(
          // Warna border berbeda saat sudah ada tanggal dipilih
          border: Border.all(
            color: isSelected
                ? accentColor
                : Colors.grey.withOpacity(0.5),
            width: isSelected ? 2 : 1,
          ),
          borderRadius: BorderRadius.circular(12),
          color: isSelected
              ? accentColor.withOpacity(0.05)
              : Colors.grey.withOpacity(0.05),
        ),
        child: Row(
          children: [
            Icon(
              Icons.calendar_today_rounded,
              color: isSelected ? accentColor : Colors.grey,
              size: 20,
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Tanggal Jatuh Tempo',
                    style: TextStyle(
                      fontSize: 12,
                      color: isSelected ? accentColor : Colors.grey[600],
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    isSelected
                        ? _formatTanggal(_selectedDate!)
                        : 'Ketuk untuk memilih tanggal',
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
                      color: isSelected ? const Color(0xFF212121) : Colors.grey,
                    ),
                  ),
                ],
              ),
            ),
            // Ikon panah sebagai petunjuk bahwa elemen ini interaktif
            Icon(
              Icons.chevron_right_rounded,
              color: isSelected ? accentColor : Colors.grey,
            ),
          ],
        ),
      ),
    );
  }

  // --- TOMBOL SIMPAN ---
  Widget _buildTombolSimpan(Color accentColor) {
    return SizedBox(
      height: 52,
      child: ElevatedButton.icon(
        onPressed: _isLoading ? null : _simpan,
        icon: _isLoading
            ? const SizedBox(
                width: 18, height: 18,
                child: CircularProgressIndicator(
                    strokeWidth: 2.5, color: Colors.white))
            : const Icon(Icons.save_rounded),
        label: Text(_isLoading ? 'Menyimpan...' : 'Simpan Tugas',
            style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w600)),
        style: ElevatedButton.styleFrom(
          backgroundColor: accentColor,
          foregroundColor: Colors.white,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          elevation: 2,
        ),
      ),
    );
  }

  // --- TOMBOL KEMBALI ---
  // Menggunakan OutlinedButton agar secara visual lebih ringan dari tombol Simpan
  // (hierarki visual: Simpan = primary, Kembali = secondary)
  Widget _buildTombolKembali(Color accentColor) {
    return SizedBox(
      height: 52,
      child: OutlinedButton.icon(
        onPressed: () => Navigator.pop(context),
        icon: const Icon(Icons.arrow_back_rounded),
        label: const Text('Kembali',
            style: TextStyle(fontSize: 15, fontWeight: FontWeight.w600)),
        style: OutlinedButton.styleFrom(
          foregroundColor: accentColor,
          side: BorderSide(color: accentColor, width: 1.5),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        ),
      ),
    );
  }
}