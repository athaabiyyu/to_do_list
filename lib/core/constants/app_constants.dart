class AppConstants {
  // Mencegah class ini di-instantiate (dibuat objeknya),
  // karena semua isinya bersifat statis (langsung pakai tanpa buat objek).
  AppConstants._();

  static const String appName    = 'Taso';
  static const String appTagline = 'Catat tugasmu, selesaikan harimu';

  // --- KREDENSIAL DEFAULT ---
  static const String defaultUsername = 'user';
  static const String defaultPassword = 'user';

  // --- NAMA TABEL ---
  static const String tableSettings = 'settings';
  static const String tableTugas    = 'tugas';

  // --- KOLOM TABEL SETTINGS ---
  static const String colKey   = 'key';
  static const String colValue = 'value';

  // --- KEY TABEL SETTINGS ---
  static const String keyUsername = 'username';
  static const String keyPassword = 'password';

  // --- KOLOM TABEL TUGAS ---
  static const String colId             = 'id';
  static const String colJudul          = 'judul';
  static const String colDeskripsi      = 'deskripsi';
  static const String colPrioritas      = 'prioritas';
  static const String colJatuhTempo     = 'jatuh_tempo';
  static const String colStatus         = 'status';
  static const String colTanggalSelesai = 'tanggal_selesai';
  static const String colCreatedAt      = 'created_at';

  // --- NILAI KOLOM PRIORITAS ---
  static const String prioritasPenting = 'penting';
  static const String prioritasBiasa   = 'biasa';
}