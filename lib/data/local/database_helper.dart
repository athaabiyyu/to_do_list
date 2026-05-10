// database_helper.dart
// Pusat akses database SQLite — pola Singleton.
// Semua operasi baca/tulis ke database dilakukan melalui file ini.

import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';
import '../../core/constants/app_constants.dart';

class DatabaseHelper {
  // --- SINGLETON ---
  // Hanya ada satu instance DatabaseHelper di seluruh aplikasi.
  // Ini mencegah koneksi database terbuka berkali-kali.
  static final DatabaseHelper instance = DatabaseHelper._internal();
  DatabaseHelper._internal();
  static Database? _database;

  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDB();
    return _database!;
  }

  // --- INISIALISASI ---
  Future<Database> _initDB() async {
    final path = join(await getDatabasesPath(), 'todolist.db');
    return await openDatabase(
      path,
      version: 2, // ← naikkan angka ini setiap ada perubahan struktur tabel
      onCreate: _onCreate,
      onUpgrade: _onUpgrade,
    );
  }

  Future<void> _onCreate(Database db, int version) async {
    // Tabel settings: menyimpan konfigurasi aplikasi (username, password)
    await db.execute('''
      CREATE TABLE settings (
        key   TEXT PRIMARY KEY,
        value TEXT NOT NULL
      )
    ''');

    // Tabel tugas: menyimpan semua data tugas pengguna.
    // Kolom:
    //   id              → primary key auto-increment
    //   judul           → judul/nama tugas
    //   deskripsi       → keterangan tambahan (boleh kosong)
    //   prioritas       → 'penting' atau 'biasa'
    //   jatuh_tempo     → tanggal deadline (format ISO 8601, khusus tugas penting)
    //   status          → 0 = belum selesai, 1 = selesai
    //   tanggal_selesai → tanggal saat tugas ditandai selesai (ISO 8601)
    //   created_at      → tanggal tugas dibuat
    await db.execute('''
      CREATE TABLE tugas (
        id              INTEGER PRIMARY KEY AUTOINCREMENT,
        judul           TEXT    NOT NULL,
        deskripsi       TEXT    DEFAULT '',
        prioritas       TEXT    NOT NULL DEFAULT 'biasa',
        jatuh_tempo     TEXT,
        status          INTEGER NOT NULL DEFAULT 0,
        tanggal_selesai TEXT,
        created_at      TEXT    NOT NULL
      )
    ''');

    // Data default untuk tabel settings
    await db.insert('settings', {
      'key': AppConstants.keyUsername,
      'value': AppConstants.defaultUsername,
    });
    await db.insert('settings', {
      'key': AppConstants.keyPassword,
      'value': AppConstants.defaultPassword,
    });
  }

  Future<void> _onUpgrade(Database db, int oldVersion, int newVersion) async {
    // Strategi development: drop semua tabel lama lalu buat ulang.
    // Ini cara tercepat saat masih development — tidak perlu uninstall app.
    // CATATAN: data yang sudah tersimpan akan terhapus (wajar saat dev).
    await db.execute('DROP TABLE IF EXISTS tugas');
    await db.execute('DROP TABLE IF EXISTS settings');
    await _onCreate(db, newVersion);
  }

  // ==========================================================================
  // SETTINGS
  // ==========================================================================

  Future<String?> getSetting(String key) async {
    final db = await database;
    final result = await db.query('settings',
        where: 'key = ?', whereArgs: [key], limit: 1);
    if (result.isEmpty) return null;
    return result.first['value'] as String?;
  }

  Future<void> setSetting(String key, String value) async {
    final db = await database;
    await db.insert(
      'settings',
      {'key': key, 'value': value},
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  // ==========================================================================
  // STATISTIK — digunakan oleh halaman Beranda
  // ==========================================================================

  // Menghitung jumlah tugas dengan status = 1 (selesai)
  Future<int> getTugasSelesaiCount() async {
    final db = await database;
    final result = await db
        .rawQuery('SELECT COUNT(*) as total FROM tugas WHERE status = 1');
    return (result.first['total'] as int?) ?? 0;
  }

  // Menghitung jumlah tugas dengan status = 0 (belum selesai)
  Future<int> getTugasBelumSelesaiCount() async {
    final db = await database;
    final result = await db
        .rawQuery('SELECT COUNT(*) as total FROM tugas WHERE status = 0');
    return (result.first['total'] as int?) ?? 0;
  }

  // Mengambil data grafik: jumlah tugas selesai per hari untuk 7 hari terakhir
  // Return: List of Map berisi 'hari' (label), 'jumlah', dan 'isHariIni'
  Future<List<Map<String, dynamic>>> getGrafikMingguan() async {
    final db = await database;
    final now = DateTime.now();

    // Label hari pendek dalam bahasa Indonesia
    const labelHari = ['Sen', 'Sel', 'Rab', 'Kam', 'Jum', 'Sab', 'Min'];

    final List<Map<String, dynamic>> result = [];

    // Loop 7 hari ke belakang (hari ini = i=0, 6 hari lalu = i=6)
    for (int i = 6; i >= 0; i--) {
      final hari = now.subtract(Duration(days: i));
      final tanggalStr = '${hari.year}-'
          '${hari.month.toString().padLeft(2, '0')}-'
          '${hari.day.toString().padLeft(2, '0')}';

      // Hitung tugas selesai pada tanggal ini
      // tanggal_selesai disimpan format ISO 8601: "2026-05-04T10:30:00.000"
      // LIKE 'YYYY-MM-DD%' mencocokkan semua waktu di tanggal tersebut
      final query = await db.rawQuery('''
        SELECT COUNT(*) as total FROM tugas
        WHERE status = 1
          AND tanggal_selesai LIKE '$tanggalStr%'
      ''');

      final jumlah = (query.first['total'] as int?) ?? 0;
      final labelIndex =
          hari.weekday - 1; // weekday: 1=Sen...7=Min → index 0..6

      result.add({
        'hari': labelHari[labelIndex],
        'jumlah': jumlah,
        'isHariIni': i == 0, // hari ini tampil lebih terang di grafik
      });
    }

    return result;
  }

  // ==========================================================================
  // CRUD TUGAS
  // ==========================================================================

  // Menyimpan tugas baru ke database.
  // jatuhTempo hanya diisi untuk tugas penting (null untuk tugas biasa).
  Future<int> insertTugas({
    required String judul,
    String deskripsi = '',
    required String prioritas, // 'penting' atau 'biasa'
    DateTime? jatuhTempo, // wajib untuk tugas penting, null untuk biasa
  }) async {
    final db = await database;
    return await db.insert('tugas', {
      'judul': judul,
      'deskripsi': deskripsi,
      'prioritas': prioritas,
      // Simpan dalam format ISO 8601 agar mudah diurutkan & dibandingkan
      'jatuh_tempo': jatuhTempo?.toIso8601String(),
      'status': 0,
      'created_at': DateTime.now().toIso8601String(),
    });
  }

  // Mengambil semua tugas.
  // Urutan: belum selesai dulu → penting dulu → terbaru dulu
  Future<List<Map<String, dynamic>>> getAllTugas() async {
    final db = await database;
    return await db.query(
      'tugas',
      orderBy: 'status ASC, prioritas DESC, created_at DESC',
    );
  }

  // Mengambil tugas berdasarkan prioritas saja
  Future<List<Map<String, dynamic>>> getTugasByPrioritas(
      String prioritas) async {
    final db = await database;
    return await db.query(
      'tugas',
      where: 'prioritas = ?',
      whereArgs: [prioritas],
      orderBy: 'status ASC, created_at DESC',
    );
  }

  // Mengubah status tugas: selesai (1) atau belum selesai (0).
  // tanggal_selesai diisi saat selesai, dihapus (null) saat dibatalkan.
  Future<void> updateStatusTugas(int id, bool selesai) async {
    final db = await database;
    await db.update(
      'tugas',
      {
        'status': selesai ? 1 : 0,
        'tanggal_selesai': selesai ? DateTime.now().toIso8601String() : null,
      },
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  // Menghapus tugas dari database berdasarkan id
  Future<void> deleteTugas(int id) async {
    final db = await database;
    await db.delete('tugas', where: 'id = ?', whereArgs: [id]);
  }

  // Mengubah judul, deskripsi, dan jatuh tempo tugas
  Future<void> updateTugas({
    required int id,
    required String judul,
    String deskripsi = '',
    DateTime? jatuhTempo,
  }) async {
    final db = await database;
    await db.update(
      'tugas',
      {
        'judul': judul,
        'deskripsi': deskripsi,
        'jatuh_tempo': jatuhTempo?.toIso8601String(),
      },
      where: 'id = ?',
      whereArgs: [id],
    );
  }
}
