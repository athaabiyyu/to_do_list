import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';
import '../../core/constants/app_constants.dart';

class DatabaseHelper {
  // --- SINGLETON ---
  static final DatabaseHelper instance = DatabaseHelper._internal();
  DatabaseHelper._internal();
  static Database? _database;

  // Getter database 
  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDB();
    return _database!;
  }

  // --- Inisialisasi DB ---
  Future<Database> _initDB() async {
    final path = join(await getDatabasesPath(), 'todolist.db');
    return await openDatabase(
      path,
      version: 2,
      onCreate: _onCreate,
      onUpgrade: _onUpgrade,
    );
  }

  // Membuat tabel dan data default
  Future<void> _onCreate(Database db, int version) async {
    // Tabel settings
    await db.execute('''
      CREATE TABLE ${AppConstants.tableSettings} (
        ${AppConstants.colKey}   TEXT PRIMARY KEY,
        ${AppConstants.colValue} TEXT NOT NULL
      )
    ''');

    // Tabel tugas
    await db.execute('''
      CREATE TABLE ${AppConstants.tableTugas} (
        ${AppConstants.colId}             INTEGER PRIMARY KEY AUTOINCREMENT,
        ${AppConstants.colJudul}          TEXT    NOT NULL,
        ${AppConstants.colDeskripsi}      TEXT    DEFAULT '',
        ${AppConstants.colPrioritas}      TEXT    NOT NULL DEFAULT '${AppConstants.prioritasBiasa}',
        ${AppConstants.colJatuhTempo}     TEXT,
        ${AppConstants.colStatus}         INTEGER NOT NULL DEFAULT 0,
        ${AppConstants.colTanggalSelesai} TEXT,
        ${AppConstants.colCreatedAt}      TEXT    NOT NULL
      )
    ''');

    // Data default tabel settings
    await db.insert(AppConstants.tableSettings, {
      AppConstants.colKey  : AppConstants.keyUsername,
      AppConstants.colValue: AppConstants.defaultUsername,
    });
    await db.insert(AppConstants.tableSettings, {
      AppConstants.colKey  : AppConstants.keyPassword,
      AppConstants.colValue: AppConstants.defaultPassword,
    });
  }

  // Upgrade DB: strategi development dengan drop & recreate
  Future<void> _onUpgrade(Database db, int oldVersion, int newVersion) async {
    await db.execute('DROP TABLE IF EXISTS ${AppConstants.tableTugas}');
    await db.execute('DROP TABLE IF EXISTS ${AppConstants.tableSettings}');
    await _onCreate(db, newVersion);
  }

  // ==========================================================================
  // SETTINGS
  // ==========================================================================

  Future<String?> getSetting(String key) async {
    final db     = await database;
    final result = await db.query(
      AppConstants.tableSettings,
      where    : '${AppConstants.colKey} = ?',
      whereArgs: [key],
      limit    : 1,
    );
    if (result.isEmpty) return null;
    return result.first[AppConstants.colValue] as String?;
  }

  Future<void> setSetting(String key, String value) async {
    final db = await database;
    await db.insert(
      AppConstants.tableSettings,
      {
        AppConstants.colKey  : key,
        AppConstants.colValue: value,
      },
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  // ==========================================================================
  // STATISTIK
  // ==========================================================================

  Future<int> getTugasSelesaiCount() async {
    final db     = await database;
    final result = await db.rawQuery(
      'SELECT COUNT(*) as total FROM ${AppConstants.tableTugas} '
      'WHERE ${AppConstants.colStatus} = 1',
    );
    return (result.first['total'] as int?) ?? 0;
  }

  Future<int> getTugasBelumSelesaiCount() async {
    final db     = await database;
    final result = await db.rawQuery(
      'SELECT COUNT(*) as total FROM ${AppConstants.tableTugas} '
      'WHERE ${AppConstants.colStatus} = 0',
    );
    return (result.first['total'] as int?) ?? 0;
  }

  Future<List<Map<String, dynamic>>> getGrafikMingguan() async {
    final db  = await database;
    final now = DateTime.now();
    const labelHari = ['Sen', 'Sel', 'Rab', 'Kam', 'Jum', 'Sab', 'Min'];
    final List<Map<String, dynamic>> result = [];

    for (int i = 6; i >= 0; i--) {
      final hari       = now.subtract(Duration(days: i));
      final tanggalStr = '${hari.year}-'
          '${hari.month.toString().padLeft(2, '0')}-'
          '${hari.day.toString().padLeft(2, '0')}';

      final query = await db.rawQuery('''
        SELECT COUNT(*) as total FROM ${AppConstants.tableTugas}
        WHERE ${AppConstants.colStatus} = 1
          AND ${AppConstants.colTanggalSelesai} LIKE '$tanggalStr%'
      ''');

      result.add({
        'hari'      : labelHari[hari.weekday - 1],
        'jumlah'    : (query.first['total'] as int?) ?? 0,
        'isHariIni' : i == 0,
      });
    }
    return result;
  }

  // ==========================================================================
  // CRUD TUGAS
  // ==========================================================================

  Future<int> insertTugas({
    required String judul,
    String deskripsi    = '',
    required String prioritas,
    DateTime? jatuhTempo,
  }) async {
    final db = await database;
    return await db.insert(
      AppConstants.tableTugas,
      {
        AppConstants.colJudul      : judul,
        AppConstants.colDeskripsi  : deskripsi,
        AppConstants.colPrioritas  : prioritas,
        AppConstants.colJatuhTempo : jatuhTempo?.toIso8601String(),
        AppConstants.colStatus     : 0,
        AppConstants.colCreatedAt  : DateTime.now().toIso8601String(),
      },
    );
  }

  Future<List<Map<String, dynamic>>> getAllTugas() async {
    final db = await database;
    return await db.query(
      AppConstants.tableTugas,
      orderBy:
        '${AppConstants.colStatus} ASC, '
        '${AppConstants.colPrioritas} DESC, '
        '${AppConstants.colCreatedAt} DESC',
    );
  }

  Future<List<Map<String, dynamic>>> getTugasByPrioritas(String prioritas) async {
    final db = await database;
    return await db.query(
      AppConstants.tableTugas,
      where    : '${AppConstants.colPrioritas} = ?',
      whereArgs: [prioritas],
      orderBy  :
        '${AppConstants.colStatus} ASC, '
        '${AppConstants.colCreatedAt} DESC',
    );
  }

  Future<void> updateStatusTugas(int id, bool selesai) async {
    final db = await database;
    await db.update(
      AppConstants.tableTugas,
      {
        AppConstants.colStatus         : selesai ? 1 : 0,
        AppConstants.colTanggalSelesai : selesai
            ? DateTime.now().toIso8601String()
            : null,
      },
      where    : '${AppConstants.colId} = ?',
      whereArgs: [id],
    );
  }

  Future<void> deleteTugas(int id) async {
    final db = await database;
    await db.delete(
      AppConstants.tableTugas,
      where    : '${AppConstants.colId} = ?',
      whereArgs: [id],
    );
  }

  Future<void> updateTugas({
    required int id,
    required String judul,
    String deskripsi    = '',
    DateTime? jatuhTempo,
  }) async {
    final db = await database;
    await db.update(
      AppConstants.tableTugas,
      {
        AppConstants.colJudul     : judul,
        AppConstants.colDeskripsi : deskripsi,
        AppConstants.colJatuhTempo: jatuhTempo?.toIso8601String(),
      },
      where    : '${AppConstants.colId} = ?',
      whereArgs: [id],
    );
  }
}