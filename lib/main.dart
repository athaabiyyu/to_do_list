import 'package:flutter/material.dart';
import 'data/local/database_helper.dart';
import 'presentation/pages/login_page.dart';

Future<void> main() async {

  // Inisialisasi binding antara flutter engine dan framework.
  WidgetsFlutterBinding.ensureInitialized();

  // Inisialisasi database memanggil getter 'database'
  await DatabaseHelper.instance.database;

  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Taso',

      debugShowCheckedModeBanner: false,

      // Tema Aplikasi
      theme: ThemeData(
        colorSchemeSeed: const Color(0xFF2E7D32),
        brightness: Brightness.light,
        useMaterial3: true,

        appBarTheme: const AppBarTheme(
          centerTitle: true,
          elevation: 0,
        ),
      ),

      // Halaman pertama 
      home: const LoginPage(),
    );
  }
}