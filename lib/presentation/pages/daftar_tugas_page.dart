// daftar_tugas_page.dart
// Halaman Daftar Tugas — menampilkan semua tugas (penting & biasa) dari SQLite.
// Fitur:
// 1. ListView scrollable dengan semua tugas
// 2. Warna ikon panah: merah = penting, hijau = biasa
// 3. Checkbox untuk menandai tugas selesai / belum selesai
// 4. Badge prioritas dan tanggal jatuh tempo (khusus tugas penting)
// 5. Swipe to delete (bonus UX)
// 6. Filter tab: Semua / Penting / Biasa

import 'package:flutter/material.dart';
import '../../data/local/database_helper.dart';

class DaftarTugasPage extends StatefulWidget {
  const DaftarTugasPage({super.key});

  @override
  State<DaftarTugasPage> createState() => _DaftarTugasPageState();
}

class _DaftarTugasPageState extends State<DaftarTugasPage>
    with SingleTickerProviderStateMixin {

  // TabController untuk filter: Semua / Penting / Biasa
  // SingleTickerProviderStateMixin diperlukan oleh TabController
  late TabController _tabController;

  List<Map<String, dynamic>> _semuaTugas   = [];
  bool _isLoading = true;

  // Warna konstanta agar konsisten di seluruh halaman
  static const _warnaMenunggu  = Color(0xFF1565C0); // biru — header
  static const _warnaPenting   = Color(0xFFE53935); // merah
  static const _warnaBiasa     = Color(0xFF2E7D32); // hijau
  static const _warnaSelesai   = Color(0xFF9E9E9E); // abu-abu

  @override
  void initState() {
    super.initState();
    // 3 tab: Semua, Penting, Biasa
    _tabController = TabController(length: 3, vsync: this);
    _loadData();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _loadData() async {
    setState(() => _isLoading = true);
    try {
      final data = await DatabaseHelper.instance.getAllTugas();
      if (!mounted) return;
      setState(() {
        _semuaTugas = data;
        _isLoading  = false;
      });
    } catch (_) {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  // Filter list berdasarkan tab aktif
  List<Map<String, dynamic>> _getFilteredList(int tabIndex) {
    switch (tabIndex) {
      case 1: return _semuaTugas.where((t) => t['prioritas'] == 'penting').toList();
      case 2: return _semuaTugas.where((t) => t['prioritas'] == 'biasa').toList();
      default: return _semuaTugas;
    }
  }

  // Toggle status selesai/belum selesai
  Future<void> _toggleStatus(int id, bool selesaiSaatIni) async {
    await DatabaseHelper.instance.updateStatusTugas(id, !selesaiSaatIni);
    await _loadData(); // refresh list setelah update
  }

  // Hapus tugas dengan konfirmasi dialog
  Future<void> _hapusTugas(int id, String judul) async {
    final konfirmasi = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text('Hapus Tugas',
            style: TextStyle(fontWeight: FontWeight.bold)),
        content: Text('Hapus tugas "$judul"?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Batal'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('Hapus', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );

    if (konfirmasi == true) {
      await DatabaseHelper.instance.deleteTugas(id);
      await _loadData();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text('Tugas berhasil dihapus.'),
            backgroundColor: Colors.red[700],
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
          ),
        );
      }
    }
  }

  // Format tanggal dari ISO 8601 → "12 Mei 2026"
  String _formatTanggal(String? isoString) {
    if (isoString == null) return '';
    try {
      final dt = DateTime.parse(isoString);
      const bulan = ['','Jan','Feb','Mar','Apr','Mei','Jun',
                     'Jul','Agt','Sep','Okt','Nov','Des'];
      return '${dt.day} ${bulan[dt.month]} ${dt.year}';
    } catch (_) {
      return '';
    }
  }

  // Cek apakah tugas sudah melewati jatuh tempo
  bool _isOverdue(String? jatuhTempo, int status) {
    if (jatuhTempo == null || status == 1) return false;
    try {
      final deadline = DateTime.parse(jatuhTempo);
      return DateTime.now().isAfter(deadline);
    } catch (_) {
      return false;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F6FA),
      appBar: AppBar(
        title: const Text('Daftar Tugas',
            style: TextStyle(fontWeight: FontWeight.bold, color: Colors.white)),
        backgroundColor: _warnaMenunggu,
        iconTheme: const IconThemeData(color: Colors.white),
        elevation: 0,
        actions: [
          // Tombol refresh manual
          IconButton(
            onPressed: _loadData,
            icon: const Icon(Icons.refresh_rounded, color: Colors.white),
          ),
        ],
        // TabBar sebagai filter di bawah AppBar
        bottom: TabBar(
          controller: _tabController,
          indicatorColor: Colors.white,
          indicatorWeight: 3,
          labelColor: Colors.white,
          unselectedLabelColor: Colors.white60,
          labelStyle: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
          tabs: [
            Tab(text: 'Semua (${_semuaTugas.length})'),
            Tab(text: 'Penting (${_semuaTugas.where((t) => t['prioritas'] == 'penting').length})'),
            Tab(text: 'Biasa (${_semuaTugas.where((t) => t['prioritas'] == 'biasa').length})'),
          ],
        ),
      ),

      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : TabBarView(
              controller: _tabController,
              children: List.generate(3, (tabIndex) {
                final list = _getFilteredList(tabIndex);
                return _buildListView(list);
              }),
            ),
    );
  }

  // --- LISTVIEW PER TAB ---
  Widget _buildListView(List<Map<String, dynamic>> list) {
    if (list.isEmpty) {
      return _buildEmptyState();
    }

    return RefreshIndicator(
      onRefresh: _loadData,
      child: ListView.builder(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        // itemCount +1 untuk summary card di atas list
        itemCount: list.length + 1,
        itemBuilder: (context, index) {
          // Item pertama = summary card statistik
          if (index == 0) return _buildSummaryCard(list);

          final tugas     = list[index - 1];
          final id        = tugas['id'] as int;
          final judul     = tugas['judul'] as String;
          final deskripsi = tugas['deskripsi'] as String? ?? '';
          final prioritas = tugas['prioritas'] as String;
          final status    = tugas['status'] as int;
          final jatuhTempo= tugas['jatuh_tempo'] as String?;
          final isSelesai = status == 1;
          final isPenting = prioritas == 'penting';
          final isOverdue = _isOverdue(jatuhTempo, status);

          // Dismissible memungkinkan swipe ke kiri untuk hapus
          return Dismissible(
            key: Key('tugas_$id'),
            direction: DismissDirection.endToStart, // swipe dari kanan ke kiri
            confirmDismiss: (_) async {
              await _hapusTugas(id, judul);
              return false; // return false agar kita handle hapus manual
            },
            background: Container(
              margin: const EdgeInsets.only(bottom: 10),
              decoration: BoxDecoration(
                color: Colors.red[400],
                borderRadius: BorderRadius.circular(14),
              ),
              alignment: Alignment.centerRight,
              padding: const EdgeInsets.only(right: 20),
              child: const Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.delete_rounded, color: Colors.white, size: 24),
                  SizedBox(height: 4),
                  Text('Hapus', style: TextStyle(color: Colors.white, fontSize: 11)),
                ],
              ),
            ),
            child: _buildTugasCard(
              id        : id,
              judul     : judul,
              deskripsi : deskripsi,
              isPenting : isPenting,
              isSelesai : isSelesai,
              isOverdue : isOverdue,
              jatuhTempo: jatuhTempo,
            ),
          );
        },
      ),
    );
  }

  // --- SUMMARY CARD ---
  // Menampilkan ringkasan jumlah selesai vs total di atas list
  Widget _buildSummaryCard(List<Map<String, dynamic>> list) {
    final selesai = list.where((t) => t['status'] == 1).length;
    final total   = list.length;
    final persen  = total == 0 ? 0.0 : selesai / total;

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('$selesai dari $total tugas selesai',
                    style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 13,
                        color: Color(0xFF424242))),
                const SizedBox(height: 6),
                ClipRRect(
                  borderRadius: BorderRadius.circular(4),
                  child: LinearProgressIndicator(
                    value: persen,
                    minHeight: 6,
                    backgroundColor: Colors.grey[200],
                    valueColor: const AlwaysStoppedAnimation(_warnaBiasa),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 16),
          Text('${(persen * 100).toInt()}%',
              style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 18,
                  color: _warnaBiasa)),
        ],
      ),
    );
  }

  // --- KARTU ITEM TUGAS ---
  Widget _buildTugasCard({
    required int id,
    required String judul,
    required String deskripsi,
    required bool isPenting,
    required bool isSelesai,
    required bool isOverdue,
    String? jatuhTempo,
  }) {
    // Warna panah: merah untuk penting, hijau untuk biasa
    // (sesuai ketentuan soal)
    final warnaArrow = isPenting ? _warnaPenting : _warnaBiasa;

    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        // Border kiri berwarna sebagai penanda visual prioritas
        border: Border(
          left: BorderSide(
            color: isSelesai ? _warnaSelesai : warnaArrow,
            width: 4,
          ),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: InkWell(
        // Tap pada card = toggle status selesai
        // Ini memenuhi ketentuan "klik item pada list untuk tandai selesai"
        onTap: () => _toggleStatus(id, isSelesai),
        borderRadius: BorderRadius.circular(14),
        splashColor: warnaArrow.withOpacity(0.1),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
          child: Row(
            children: [
              // --- CHECKBOX ---
              // Checkbox visual untuk menandai selesai/belum
              // onChanged juga memanggil _toggleStatus agar bisa diklik
              // baik via checkbox maupun tap pada card
              SizedBox(
                width: 24,
                height: 24,
                child: Checkbox(
                  value: isSelesai,
                  onChanged: (_) => _toggleStatus(id, isSelesai),
                  activeColor: warnaArrow,
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(5)),
                  side: BorderSide(color: warnaArrow, width: 2),
                ),
              ),
              const SizedBox(width: 12),

              // --- KONTEN TEKS ---
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Judul tugas
                    Text(
                      judul,
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        // Coretan jika sudah selesai
                        decoration: isSelesai
                            ? TextDecoration.lineThrough
                            : TextDecoration.none,
                        color: isSelesai
                            ? _warnaSelesai
                            : const Color(0xFF212121),
                      ),
                    ),

                    // Deskripsi (jika ada)
                    if (deskripsi.isNotEmpty) ...[
                      const SizedBox(height: 3),
                      Text(
                        deskripsi,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.grey[500],
                          decoration: isSelesai
                              ? TextDecoration.lineThrough
                              : TextDecoration.none,
                        ),
                      ),
                    ],

                    const SizedBox(height: 6),

                    // Baris badge: prioritas + jatuh tempo
                    Row(
                      children: [
                        // Badge prioritas
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 8, vertical: 2),
                          decoration: BoxDecoration(
                            color: (isSelesai ? _warnaSelesai : warnaArrow)
                                .withOpacity(0.12),
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: Text(
                            isPenting ? '🔴 Penting' : '🟢 Biasa',
                            style: TextStyle(
                              fontSize: 10,
                              fontWeight: FontWeight.bold,
                              color: isSelesai ? _warnaSelesai : warnaArrow,
                            ),
                          ),
                        ),

                        // Badge jatuh tempo (hanya untuk tugas penting)
                        if (jatuhTempo != null) ...[
                          const SizedBox(width: 6),
                          Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 8, vertical: 2),
                            decoration: BoxDecoration(
                              color: (isOverdue
                                      ? Colors.red
                                      : Colors.orange)
                                  .withOpacity(0.12),
                              borderRadius: BorderRadius.circular(20),
                            ),
                            child: Row(
                              children: [
                                Icon(
                                  isOverdue
                                      ? Icons.warning_amber_rounded
                                      : Icons.schedule_rounded,
                                  size: 10,
                                  color: isOverdue
                                      ? Colors.red[700]
                                      : Colors.orange[700],
                                ),
                                const SizedBox(width: 3),
                                Text(
                                  isOverdue
                                      ? 'Terlambat'
                                      : _formatTanggal(jatuhTempo),
                                  style: TextStyle(
                                    fontSize: 10,
                                    fontWeight: FontWeight.bold,
                                    color: isOverdue
                                        ? Colors.red[700]
                                        : Colors.orange[700],
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ],
                    ),
                  ],
                ),
              ),

              const SizedBox(width: 8),

              // --- IKON PANAH (sesuai ketentuan soal) ---
              // Warna merah untuk penting, hijau untuk biasa
              Icon(
                isSelesai
                    ? Icons.check_circle_rounded
                    : Icons.chevron_right_rounded,
                color: isSelesai ? _warnaSelesai : warnaArrow,
                size: 26,
              ),
            ],
          ),
        ),
      ),
    );
  }

  // --- EMPTY STATE ---
  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.checklist_rounded, size: 72, color: Colors.grey[300]),
          const SizedBox(height: 16),
          Text('Belum ada tugas',
              style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: Colors.grey[400])),
          const SizedBox(height: 6),
          Text('Tambahkan tugas dari halaman Beranda.',
              style: TextStyle(fontSize: 13, color: Colors.grey[400])),
        ],
      ),
    );
  }
}