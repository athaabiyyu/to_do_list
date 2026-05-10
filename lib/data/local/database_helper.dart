// database_helper.dart
// File ini bertanggung jawab untuk:
// 1. Membuka / membuat file database SQLite di storage ponsel
// 2. Membuat tabel-tabel yang dibutuhkan aplikasi
// 3. Menyediakan satu titik akses database (pola Singleton)

import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';
import '../../core/constants/app_constants.dart';

class DatabaseHelper {
  // --- SINGLETON PATTERN ---
  // Pola Singleton memastikan hanya ada SATU instance DatabaseHelper
  // di seluruh aplikasi. Ini penting agar koneksi database tidak dobel
  // dan tidak terjadi konflik saat baca/tulis data.

  // Instance tunggal yang tersimpan secara statis
  static final DatabaseHelper instance = DatabaseHelper._internal();

  // Konstruktor privat — hanya bisa dipanggil dari dalam class ini
  DatabaseHelper._internal();

  // Objek database yang akan diisi saat pertama kali diakses
  static Database? _database;

  // Getter 'database': setiap kali kode lain butuh akses DB,
  // mereka memanggil ini. Jika DB sudah ada, langsung return.
  // Jika belum, baru dibuat lewat _initDB().
  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDB();
    return _database!;
  }

  // --- INISIALISASI DATABASE ---
  Future<Database> _initDB() async {
    // getDatabasesPath() → mendapatkan folder default penyimpanan DB di ponsel
    // join() → menggabungkan path folder + nama file database
    final dbPath = await getDatabasesPath();
    final path = join(dbPath, 'digistore.db');

    return await openDatabase(
      path,
      version: 1,
      // onCreate dipanggil HANYA saat database pertama kali dibuat
      onCreate: _onCreate,
      // onUpgrade dipanggil jika versi database dinaikkan (untuk migrasi)
      onUpgrade: _onUpgrade,
    );
  }

  // --- PEMBUATAN TABEL ---
  Future<void> _onCreate(Database db, int version) async {
    // Tabel 'settings' digunakan untuk menyimpan konfigurasi aplikasi,
    // termasuk username dan password yang bisa diganti di halaman Pengaturan.
    await db.execute('''
      CREATE TABLE settings (
        key   TEXT PRIMARY KEY,
        value TEXT NOT NULL
      )
    ''');

    // Memasukkan data default username dan password ke tabel settings
    // menggunakan nilai dari AppConstants agar konsisten.
    await db.insert('settings', {
      'key': AppConstants.keyUsername,
      'value': AppConstants.defaultUsername,
    });
    await db.insert('settings', {
      'key': AppConstants.keyPassword,
      'value': AppConstants.defaultPassword,
    });
  }

  // --- MIGRASI DATABASE ---
  // Dipanggil otomatis jika versi DB dinaikkan (misal dari 1 ke 2).
  // Gunakan ini saat menambah kolom atau tabel baru di versi berikutnya.
  Future<void> _onUpgrade(Database db, int oldVersion, int newVersion) async {
    // Contoh migrasi versi 1 → 2 (untuk referensi ke depan):
    // if (oldVersion < 2) {
    //   await db.execute('ALTER TABLE settings ADD COLUMN updated_at TEXT');
    // }
  }

  // --- HELPER: Ambil satu nilai dari tabel settings berdasarkan key ---
  Future<String?> getSetting(String key) async {
    final db = await database;
    final result = await db.query(
      'settings',
      where: 'key = ?',
      whereArgs: [key],
      limit: 1,
    );
    if (result.isEmpty) return null;
    return result.first['value'] as String?;
  }

  // --- HELPER: Simpan / update nilai di tabel settings ---
  Future<void> setSetting(String key, String value) async {
    final db = await database;
    // ConflictAlgorithm.replace → jika key sudah ada, timpa nilainya
    await db.insert(
      'settings',
      {'key': key, 'value': value},
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }
}