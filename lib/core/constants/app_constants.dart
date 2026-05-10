// app_constants.dart
// File ini menyimpan semua nilai konstan yang digunakan di seluruh aplikasi.
// Dengan memusatkan nilai di sini, jika ada perubahan (misal nama app),
// kita cukup ubah di satu tempat saja — tidak perlu cari ke seluruh file.

class AppConstants {
  // Mencegah class ini di-instantiate (dibuat objeknya),
  // karena semua isinya bersifat statis (langsung pakai tanpa buat objek).
  AppConstants._();

  // Nama aplikasi yang tampil di halaman Login dan lainnya
  static const String appName = 'Taso';

  // Tagline / deskripsi singkat aplikasi
  static const String appTagline = 'Catat tugasmu, selesaikan harimu';

  // Kredensial default saat pertama kali aplikasi dipakai.
  // Nilai ini akan bisa diganti lewat halaman Pengaturan nantinya.
  static const String defaultUsername = 'user';
  static const String defaultPassword = 'user';

  // Key yang digunakan untuk menyimpan username & password ke SQLite
  // (akan dipakai nanti saat halaman Pengaturan dibuat)
  static const String keyUsername = 'username';
  static const String keyPassword = 'password';
}