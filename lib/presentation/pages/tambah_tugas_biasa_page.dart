// tambah_tugas_biasa_page.dart
// Halaman untuk menambahkan tugas berkategori "biasa" ke database SQLite.
// Strukturnya identik dengan TambahTugasPentingPage, perbedaannya:
//   1. Warna aksen → hijau (bukan merah)
//   2. prioritas yang disimpan → 'biasa' (bukan 'penting')

import 'package:flutter/material.dart';
import '../../data/local/database_helper.dart';
import '../widgets/custom_text_field.dart';

class TambahTugasBiasaPage extends StatefulWidget {
  const TambahTugasBiasaPage({super.key});

  @override
  State<TambahTugasBiasaPage> createState() => _TambahTugasBiasaPageState();
}

class _TambahTugasBiasaPageState extends State<TambahTugasBiasaPage> {
  final _formKey             = GlobalKey<FormState>();
  final _judulController     = TextEditingController();
  final _deskripsiController = TextEditingController();
  bool _isLoading            = false;

  DateTime? _selectedDate;
  static const _accentColor = Color(0xFF2E7D32);

  // Membuka dialog kalender untuk memilih tanggal jatuh tempo
  Future<void> _pickDate() async {
    final now    = DateTime.now();
    final picked = await showDatePicker(
      context     : context,
      initialDate : _selectedDate ?? now,
      firstDate   : now,
      lastDate    : DateTime(now.year + 5),
      helpText    : 'Pilih Tanggal Jatuh Tempo',
      confirmText : 'Pilih',
      cancelText  : 'Batal',
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: Theme.of(context).colorScheme.copyWith(
              primary: _accentColor,
            ),
          ),
          child: child!,
        );
      },
    );
    if (picked != null) setState(() => _selectedDate = picked);
  }

  // Mengubah DateTime
  String _formatTanggal(DateTime date) {
    const hariList  = ['Senin','Selasa','Rabu','Kamis','Jumat','Sabtu','Minggu'];
    const bulanList = ['','Januari','Februari','Maret','April','Mei','Juni',
                       'Juli','Agustus','September','Oktober','November','Desember'];
    return '${hariList[date.weekday - 1]}, ${date.day} ${bulanList[date.month]} ${date.year}';
  }

  @override
  void dispose() {
    _judulController.dispose();
    _deskripsiController.dispose();
    super.dispose();
  }

  // --- SIMPAN TUGAS ---
  Future<void> _simpan() async {
    if (!_formKey.currentState!.validate()) return;

    // Validasi tanggal jatuh tempo wajib diisi
    if (_selectedDate == null) {
      _showSnackBar('Pilih tanggal jatuh tempo terlebih dahulu.', isError: true);
      return;
    }

    setState(() => _isLoading = true);
    try {
      await DatabaseHelper.instance.insertTugas(
        judul     : _judulController.text.trim(),
        deskripsi : _deskripsiController.text.trim(),
        prioritas : 'biasa',
        jatuhTempo: _selectedDate, // kirim tanggal yang dipilih
      );

      if (!mounted) return;
      _showSnackBar('Tugas berhasil disimpan!', isError: false);
      await Future.delayed(const Duration(milliseconds: 800));
      if (mounted) Navigator.pop(context);
    } catch (e) {
      if (mounted) _showSnackBar('Gagal menyimpan tugas. Coba lagi.', isError: true);
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  void _showSnackBar(String message, {required bool isError}) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: isError ? Colors.red[700] : _accentColor,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Scaffold(
      backgroundColor: const Color(0xFFF5F6FA),
      appBar: AppBar(
        title: const Text('Tambah Tugas Biasa',
            style: TextStyle(fontWeight: FontWeight.bold, color: Colors.white)),
        backgroundColor: _accentColor,
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
              _buildHeaderCard(),
              const SizedBox(height: 20),
              _buildFormCard(colorScheme),
              const SizedBox(height: 24),
              _buildTombolSimpan(),
              const SizedBox(height: 12),
              _buildTombolKembali(),
            ],
          ),
        ),
      ),
    );
  }

  // --- HEADER CARD ---
  Widget _buildHeaderCard() {
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
            child: const Icon(Icons.add_task_rounded,
                color: Colors.white, size: 28),
          ),
          const SizedBox(width: 14),
          const Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Tugas Biasa',
                    style: TextStyle(
                        color: Colors.white,
                        fontSize: 18,
                        fontWeight: FontWeight.bold)),
                SizedBox(height: 3),
                Text('Tugas harian tanpa prioritas khusus.',
                    style: TextStyle(color: Colors.white70, fontSize: 12)),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // --- FORM CARD ---
  Widget _buildFormCard(ColorScheme colorScheme) {
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
          const Text('Detail Tugas',
              style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF424242))),
          const SizedBox(height: 16),

          // Field Judul 
          CustomTextField(
            controller: _judulController,
            label: 'Judul Tugas',
            hint: 'Contoh: Beli kebutuhan rumah',
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

          TextFormField(
            controller: _deskripsiController,
            maxLines: 3,
            maxLength: 200,
            decoration: InputDecoration(
              labelText: 'Deskripsi',
              hintText: 'Tambahkan keterangan tambahan (opsional)',
              prefixIcon: const Padding(
                padding: EdgeInsets.only(bottom: 48),
                child: Icon(Icons.notes_rounded),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide:
                    BorderSide(color: colorScheme.outline.withOpacity(0.5)),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide:
                    const BorderSide(color: _accentColor, width: 2),
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
              fillColor:
                  colorScheme.surfaceContainerHighest.withOpacity(0.3),
            ),
          ),

          // Field Date Picker Jatuh Tempo 
          const SizedBox(height: 16),
          _buildDatePickerField(),
        ],
      ),
    );
  }

  // Date Picker field — identik dengan di halaman Tugas Penting,
  Widget _buildDatePickerField() {
    final isSelected = _selectedDate != null;
    return GestureDetector(
      onTap: _pickDate,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 16),
        decoration: BoxDecoration(
          border: Border.all(
            color: isSelected ? _accentColor : Colors.grey.withOpacity(0.5),
            width: isSelected ? 2 : 1,
          ),
          borderRadius: BorderRadius.circular(12),
          color: isSelected
              ? _accentColor.withOpacity(0.05)
              : Colors.grey.withOpacity(0.05),
        ),
        child: Row(
          children: [
            Icon(Icons.calendar_today_rounded,
                color: isSelected ? _accentColor : Colors.grey, size: 20),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Tanggal Jatuh Tempo',
                      style: TextStyle(
                          fontSize: 12,
                          color: isSelected ? _accentColor : Colors.grey[600])),
                  const SizedBox(height: 2),
                  Text(
                    isSelected
                        ? _formatTanggal(_selectedDate!)
                        : 'Ketuk untuk memilih tanggal',
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight:
                          isSelected ? FontWeight.w600 : FontWeight.normal,
                      color: isSelected ? const Color(0xFF212121) : Colors.grey,
                    ),
                  ),
                ],
              ),
            ),
            Icon(Icons.chevron_right_rounded,
                color: isSelected ? _accentColor : Colors.grey),
          ],
        ),
      ),
    );
  }

  // --- TOMBOL SIMPAN ---
  Widget _buildTombolSimpan() {
    return SizedBox(
      height: 52,
      child: ElevatedButton.icon(
        onPressed: _isLoading ? null : _simpan,
        icon: _isLoading
            ? const SizedBox(
                width: 18,
                height: 18,
                child: CircularProgressIndicator(
                    strokeWidth: 2.5, color: Colors.white))
            : const Icon(Icons.save_rounded),
        label: Text(_isLoading ? 'Menyimpan...' : 'Simpan Tugas',
            style: const TextStyle(
                fontSize: 15, fontWeight: FontWeight.w600)),
        style: ElevatedButton.styleFrom(
          backgroundColor: _accentColor,
          foregroundColor: Colors.white,
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          elevation: 2,
        ),
      ),
    );
  }

  // --- TOMBOL KEMBALI ---
  Widget _buildTombolKembali() {
    return SizedBox(
      height: 52,
      child: OutlinedButton.icon(
        onPressed: () => Navigator.pop(context),
        icon: const Icon(Icons.arrow_back_rounded),
        label: const Text('<< Kembali',
            style: TextStyle(
                fontSize: 15, fontWeight: FontWeight.w600)),
        style: OutlinedButton.styleFrom(
          foregroundColor: _accentColor,
          side: const BorderSide(color: _accentColor, width: 1.5),
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        ),
      ),
    );
  }
}