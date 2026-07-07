import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'edit_profile_screen.dart';
import '../../auth/widgets/header_clipper.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});
  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  final _supabase = Supabase.instance.client;

  String _getGreeting() {
    var hour = DateTime.now().hour;
    if (hour < 12) return 'Selamat Pagi ☀️';
    if (hour < 15) return 'Selamat Siang 🌤️';
    if (hour < 18) return 'Selamat Sore 🌅';
    return 'Selamat Malam 🌙';
  }

  Future<Map<String, dynamic>> _fetchProfileData() async {
    final user = _supabase.auth.currentUser;
    return await _supabase.from('profiles').select().eq('id', user!.id).single();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: FutureBuilder<Map<String, dynamic>>(
        future: _fetchProfileData(),
        builder: (context, snapshot) {
          if (!snapshot.hasData) return const Center(child: CircularProgressIndicator());
          final data = snapshot.data!;
          return SingleChildScrollView(
            child: Column(
              children: [
                ClipPath(
                  clipper: HeaderClipper(),
                  child: Container(
                    height: 200,
                    width: double.infinity,
                    decoration: const BoxDecoration(
                      gradient: LinearGradient(colors: [Color(0xFF00b493), Color(0xFF00796b)]),
                    ),
                    padding: const EdgeInsets.fromLTRB(25, 40, 25, 20),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Text(_getGreeting(), style: const TextStyle(color: Colors.white70)),
                              Text(data['owner_name'] ?? "-", style: const TextStyle(color: Colors.white, fontSize: 24, fontWeight: FontWeight.bold)),
                            ],
                          ),
                        ),
                        const Icon(Icons.account_balance_wallet, size: 30, color: Colors.white),
                      ],
                    ),
                  ),
                ),
                Transform.translate(
  offset: const Offset(0, 0), 
  child: Padding(
    padding: const EdgeInsets.symmetric(horizontal: 20),
    child: Column(
      children: [
        _buildDetailCard(Icons.email, "Email", _supabase.auth.currentUser?.email ?? "-"),
        _buildDetailCard(Icons.phone, "Telepon", data['phone'] ?? "Belum diisi"),
        _buildDetailCard(Icons.location_on, "Alamat", data['address'] ?? "Belum diisi"),
        const SizedBox(height: 20),
                       // Ganti bagian tombol Edit Profil di profile_screen.dart menjadi seperti ini:
SizedBox(
  width: double.infinity,
  height: 50, // Tambahkan tinggi agar tombol lebih nyaman ditekan
  child: ElevatedButton(
    onPressed: () async {
      final result = await Navigator.push(context, MaterialPageRoute(builder: (context) => EditProfileScreen(userData: data)));
      if (result == true) setState(() {});
    },
    style: ElevatedButton.styleFrom(
      backgroundColor: const Color(0xFF00796b), // Hijau khas aplikasi Anda
      foregroundColor: Colors.white, // Teks putih
      elevation: 0, // Datar agar senada dengan desain
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
    ),
    child: const Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Icon(Icons.edit, size: 20),
        SizedBox(width: 8),
        Text("Edit Profil", style: TextStyle(fontWeight: FontWeight.bold)),
      ],
    ),
  ),
),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildDetailCard(IconData icon, String title, String sub) => Container(
    margin: const EdgeInsets.only(bottom: 12),
    padding: const EdgeInsets.all(16),
    decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(16), boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 10, offset: const Offset(0, 4))]),
    child: ListTile(leading: Icon(icon, color: const Color(0xFF00796b)), title: Text(title, style: const TextStyle(color: Colors.grey, fontSize: 12)), subtitle: Text(sub, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16))),
  );
}