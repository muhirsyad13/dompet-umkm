import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

// Baris login_screen dihapus karena sudah diwakili di dalam welcome_screen
import 'features/auth/screens/welcome_screen.dart';
void main() async {
  // Memastikan framework Flutter siap sebelum menjalankan inisialisasi async
  WidgetsFlutterBinding.ensureInitialized();

  // Inisialisasi koneksi Supabase Dompet UMKM
  await Supabase.initialize(
    url: 'https://ugwiofasrevdejvndgfa.supabase.co',
    // OPTIMASI: Mengganti anonKey menjadi publishableKey sesuai versi terbaru
    publishableKey: 'sb_publishable_1Ds0XlqDE8iWTl2q9ztQsQ_dzn5sTw_', 
  );

  runApp(const MyApp());
}

// Shortcut global untuk memanggil client Supabase di halaman mana saja
final supabase = Supabase.instance.client;

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Dompet UMKM',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        useMaterial3: true,
        // PERBAIKAN: Mengganti Colors.emerald menjadi Colors.teal yang didukung resmi oleh Flutter
        colorSchemeSeed: Colors.teal, 
      ),
      home: const WelcomeScreen(),
    );
  }
}

class MainCheckScreen extends StatelessWidget {
  const MainCheckScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return const Scaffold(
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // PERBAIKAN: Menggunakan Colors.teal agar valid menjadi bagian dari komponen konstan
            Icon(Icons.check_circle, color: Colors.teal, size: 80),
            SizedBox(height: 16),
            Text(
              'Koneksi Supabase Siap! 🚀',
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
            SizedBox(height: 8),
            Text(
              'Database Dompet UMKM v1.2 Berhasil Terhubung.',
              style: TextStyle(color: Colors.grey),
            ),
          ],
        ),
      ),
    );
  }
}