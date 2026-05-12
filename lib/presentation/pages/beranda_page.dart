import 'package:flutter/material.dart';
import '../../data/local/database_helper.dart';
import 'tambah_tugas_penting_page.dart';
import 'tambah_tugas_biasa_page.dart';
import 'daftar_tugas_page.dart';
import 'pengaturan_page.dart';

class BerandaPage extends StatefulWidget {
  const BerandaPage({super.key});

  @override
  State<BerandaPage> createState() => _BerandaPageState();
}

class _BerandaPageState extends State<BerandaPage> {
  int _tugasSelesai = 0;
  int _tugasBelumSelesai = 0;
  List<Map<String, dynamic>> _grafikData = [];
  String _username = 'User';
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  // --- LOAD DATA DARI SQLITE ---
  Future<void> _loadData() async {
    setState(() => _isLoading = true);
    try {
      final db = DatabaseHelper.instance;
      final results = await Future.wait([
        db.getTugasSelesaiCount(),
        db.getTugasBelumSelesaiCount(),
        db.getGrafikMingguan(),
        db.getSetting('username'),
      ]);
      if (!mounted) return;
      setState(() {
        _tugasSelesai       = results[0] as int;
        _tugasBelumSelesai  = results[1] as int;
        _grafikData         = results[2] as List<Map<String, dynamic>>;
        _username           = (results[3] as String?) ?? 'User';
        _isLoading          = false;
      });
    } catch (_) {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  // Menghasilkan string tanggal format Indonesia
  String _getTanggalHariIni() {
    final now = DateTime.now();
    const hari  = ['Senin','Selasa','Rabu','Kamis','Jumat','Sabtu','Minggu'];
    const bulan = ['','Januari','Februari','Maret','April','Mei','Juni',
                   'Juli','Agustus','September','Oktober','November','Desember'];
    return '${hari[now.weekday - 1]}, ${now.day} ${bulan[now.month]} ${now.year}';
  }

  // Navigasi ke halaman lain lalu refresh data saat kembali
  void _navigateAndRefresh(Widget page) {
    Navigator.push(context, MaterialPageRoute(builder: (_) => page))
        .then((_) => _loadData());
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final size        = MediaQuery.of(context).size;

    return Scaffold(
      backgroundColor: const Color(0xFFF5F6FA),
      appBar: AppBar(
        title: const Text('Beranda',
            style: TextStyle(fontWeight: FontWeight.bold, color: Colors.white)),
        backgroundColor: colorScheme.primary,
        automaticallyImplyLeading: false,
        elevation: 0,
        actions: [
          IconButton(
            onPressed: _loadData,
            icon: const Icon(Icons.refresh_rounded, color: Colors.white),
            tooltip: 'Refresh',
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : RefreshIndicator(
              onRefresh: _loadData,
              child: SingleChildScrollView(
                physics: const AlwaysScrollableScrollPhysics(),
                padding: EdgeInsets.all(size.width * 0.045),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildGreeting(colorScheme),
                    const SizedBox(height: 16),
                    _buildStatistikCards(colorScheme),
                    const SizedBox(height: 16),
                    _buildGrafik(colorScheme),
                    const SizedBox(height: 16),
                    _buildNavigasiGrid(colorScheme),
                    const SizedBox(height: 16),
                  ],
                ),
              ),
            ),
    );
  }

  // --- BAGIAN 1: Greeting Card ---
  Widget _buildGreeting(ColorScheme colorScheme) {
    final total  = _tugasSelesai + _tugasBelumSelesai;
    final persen = total == 0 ? 0.0 : _tugasSelesai / total;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 18),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [colorScheme.primary, colorScheme.primary.withOpacity(0.78)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(18),
        boxShadow: [
          BoxShadow(
              color: colorScheme.primary.withOpacity(0.28),
              blurRadius: 14,
              offset: const Offset(0, 5))
        ],
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(children: [
                  Text('Halo, $_username!',
                      style: const TextStyle(
                          color: Colors.white,
                          fontSize: 20,
                          fontWeight: FontWeight.bold)),
                  const SizedBox(width: 6),
                  const Text('👋', style: TextStyle(fontSize: 18)),
                ]),
                const SizedBox(height: 4),
                Text(_getTanggalHariIni(),
                    style: TextStyle(
                        color: Colors.white.withOpacity(0.85), fontSize: 13)),
                const SizedBox(height: 12),
                // Mini progress bar
                ClipRRect(
                  borderRadius: BorderRadius.circular(4),
                  child: LinearProgressIndicator(
                    value: persen,
                    minHeight: 6,
                    backgroundColor: Colors.white.withOpacity(0.3),
                    valueColor: const AlwaysStoppedAnimation(Colors.white),
                  ),
                ),
                const SizedBox(height: 5),
                Text(
                  '${(persen * 100).toStringAsFixed(0)}% tugas selesai',
                  style: TextStyle(
                      color: Colors.white.withOpacity(0.85), fontSize: 12),
                ),
              ],
            ),
          ),
          const SizedBox(width: 16),
          // Ring progress persentase
          SizedBox(
            width: 60,
            height: 60,
            child: Stack(fit: StackFit.expand, children: [
              CircularProgressIndicator(
                value: persen,
                strokeWidth: 6,
                backgroundColor: Colors.white.withOpacity(0.3),
                valueColor: const AlwaysStoppedAnimation(Colors.white),
              ),
              Center(
                child: Text(
                  '${(persen * 100).toInt()}%',
                  style: const TextStyle(
                      color: Colors.white,
                      fontSize: 12,
                      fontWeight: FontWeight.bold),
                ),
              ),
            ]),
          ),
        ],
      ),
    );
  }

  // --- BAGIAN 2: Kartu Statistik ---
  Widget _buildStatistikCards(ColorScheme colorScheme) {
    return Row(children: [
      Expanded(
        child: _StatCard(
          label: 'TUGAS SELESAI',
          value: _tugasSelesai,
          valueColor: const Color(0xFF2E7D32),
          icon: Icons.check_circle_rounded,
          bgColor: const Color(0xFFE8F5E9),
        ),
      ),
      const SizedBox(width: 12),
      Expanded(
        child: _StatCard(
          label: 'BELUM SELESAI',
          value: _tugasBelumSelesai,
          valueColor: const Color(0xFFC62828),
          icon: Icons.pending_actions_rounded,
          bgColor: const Color(0xFFFFEBEE),
        ),
      ),
    ]);
  }

  // --- BAGIAN 3: Grafik Bar Mingguan ---
  Widget _buildGrafik(ColorScheme colorScheme) {
    final maxVal = _grafikData.isEmpty
        ? 1
        : (_grafikData.map((e) => e['jumlah'] as int).reduce((a, b) => a > b ? a : b))
            .clamp(1, 9999);

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
              color: Colors.black.withOpacity(0.06),
              blurRadius: 10,
              offset: const Offset(0, 3))
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header grafik
          Row(children: [
            Icon(Icons.bar_chart_rounded, color: colorScheme.primary, size: 20),
            const SizedBox(width: 8),
            const Text('TUGAS SELESAI / HARI',
                style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 0.4,
                    color: Color(0xFF424242))),
            const SizedBox(width: 6),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
              decoration: BoxDecoration(
                  color: colorScheme.primaryContainer,
                  borderRadius: BorderRadius.circular(20)),
              child: Text('BONUS',
                  style: TextStyle(
                      fontSize: 9,
                      fontWeight: FontWeight.bold,
                      color: colorScheme.onPrimaryContainer)),
            ),
          ]),
          const SizedBox(height: 16),

          // Bar chart manual
          // SizedBox height 150 memberi ruang cukup untuk:
          // angka (14px) + SizedBox(3) + bar (maks 70px) + SizedBox(6) + label (16px) = ~109px
          SizedBox(
            height: 150,
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: _grafikData.map((data) {
                final jumlah    = data['jumlah'] as int;
                final isHariIni = data['isHariIni'] as bool? ?? false;
                // Tinggi bar max 70px agar tidak meluber keluar SizedBox
                final tinggi    = (jumlah / maxVal) * 70;

                return Expanded(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 3),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [
                        if (jumlah > 0)
                          Text('$jumlah',
                              style: TextStyle(
                                  fontSize: 10,
                                  fontWeight: FontWeight.bold,
                                  color: isHariIni
                                      ? colorScheme.primary
                                      : const Color(0xFF9E9E9E))),
                        const SizedBox(height: 3),
                        AnimatedContainer(
                          duration: const Duration(milliseconds: 600),
                          curve: Curves.easeOutCubic,
                          height: jumlah == 0 ? 4 : tinggi,
                          decoration: BoxDecoration(
                            color: isHariIni
                                ? colorScheme.primary
                                : colorScheme.primary.withOpacity(0.4),
                            borderRadius: BorderRadius.circular(6),
                          ),
                        ),
                        const SizedBox(height: 6),
                        Text(data['hari'] as String,
                            style: TextStyle(
                                fontSize: 11,
                                fontWeight: isHariIni
                                    ? FontWeight.bold
                                    : FontWeight.normal,
                                color: isHariIni
                                    ? colorScheme.primary
                                    : const Color(0xFF9E9E9E))),
                      ],
                    ),
                  ),
                );
              }).toList(),
            ),
          ),
        ],
      ),
    );
  }

  // --- BAGIAN 4: Grid 4 Tombol Navigasi ---
  Widget _buildNavigasiGrid(ColorScheme colorScheme) {
    final menuItems = [
      _MenuItem(
        label: 'Tambah Tugas\nPenting',
        icon: Icons.priority_high_rounded,
        color: const Color(0xFFE53935),
        onTap: () => _navigateAndRefresh(const TambahTugasPentingPage()),
      ),
      _MenuItem(
        label: 'Tambah Tugas\nBiasa',
        icon: Icons.add_task_rounded,
        color: const Color(0xFF2E7D32),
        onTap: () => _navigateAndRefresh(const TambahTugasBiasaPage()),
      ),
      _MenuItem(
        label: 'Daftar\nTugas',
        icon: Icons.format_list_bulleted_rounded,
        color: const Color(0xFF1565C0),
        onTap: () => _navigateAndRefresh(const DaftarTugasPage()),
      ),
      _MenuItem(
        label: 'Pengaturan',
        icon: Icons.settings_rounded,
        color: const Color(0xFF6A1B9A),
        onTap: () => _navigateAndRefresh(const PengaturanPage()),
      ),
    ];

    return GridView.count(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      crossAxisCount: 2,
      crossAxisSpacing: 12,
      mainAxisSpacing: 12,
      childAspectRatio: 1.1,
      children: menuItems.map((item) => _NavButton(item: item)).toList(),
    );
  }
}

// =============================================================================
// WIDGET: _StatCard — Kartu angka statistik tugas
// =============================================================================
class _StatCard extends StatelessWidget {
  final String label;
  final int value;
  final Color valueColor;
  final IconData icon;
  final Color bgColor;

  const _StatCard({
    required this.label,
    required this.value,
    required this.valueColor,
    required this.icon,
    required this.bgColor,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
              color: Colors.black.withOpacity(0.06),
              blurRadius: 10,
              offset: const Offset(0, 3))
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
                color: bgColor, borderRadius: BorderRadius.circular(10)),
            child: Icon(icon, color: valueColor, size: 20),
          ),
          const SizedBox(height: 10),
          Text('$value',
              style: TextStyle(
                  fontSize: 28,
                  fontWeight: FontWeight.bold,
                  color: valueColor,
                  height: 1)),
          const SizedBox(height: 4),
          Text(label,
              style: const TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                  color: Color(0xFF757575),
                  letterSpacing: 0.3)),
        ],
      ),
    );
  }
}

// =============================================================================
// MODEL: _MenuItem — konfigurasi tiap tombol navigasi
// =============================================================================
class _MenuItem {
  final String label;
  final IconData icon;
  final Color color;
  final VoidCallback onTap;
  const _MenuItem(
      {required this.label,
      required this.icon,
      required this.color,
      required this.onTap});
}

// =============================================================================
// WIDGET: _NavButton — tombol navigasi dengan efek ripple & shadow
// =============================================================================
class _NavButton extends StatelessWidget {
  final _MenuItem item;
  const _NavButton({required this.item});

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.white,
      borderRadius: BorderRadius.circular(16),
      child: InkWell(
        onTap: item.onTap,
        borderRadius: BorderRadius.circular(16),
        splashColor: item.color.withOpacity(0.15),
        highlightColor: item.color.withOpacity(0.07),
        child: Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            boxShadow: [
              BoxShadow(
                  color: Colors.black.withOpacity(0.06),
                  blurRadius: 10,
                  offset: const Offset(0, 3))
            ],
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                width: 56,
                height: 56,
                decoration: BoxDecoration(
                  color: item.color,
                  shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(
                        color: item.color.withOpacity(0.35),
                        blurRadius: 10,
                        offset: const Offset(0, 4))
                  ],
                ),
                child: Icon(item.icon, color: Colors.white, size: 26),
              ),
              const SizedBox(height: 10),
              Text(item.label,
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: Color(0xFF424242),
                      height: 1.3)),
            ],
          ),
        ),
      ),
    );
  }
}