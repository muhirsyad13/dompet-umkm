import 'package:flutter/material.dart';
import 'dashboard_screen.dart';
import 'utang_piutang_screen.dart'; 
import 'package:dompet_umkm/features/profile/screens/profile_screen.dart';


class MainLayout extends StatefulWidget {
  const MainLayout({super.key});

  @override
  State<MainLayout> createState() => _MainLayoutState();
}

class _MainLayoutState extends State<MainLayout> {
  int _selectedIndex = 0;

  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });
  }

  @override
  Widget build(BuildContext context) {
    // Di sini kita panggil DashboardScreen kamu yang utuh tanpa perlu dipotong-potong
    final List<Widget> screens = [
      const DashboardScreen(), // Halaman Index 0 (Dashboard bawaan kamu)
      const UtangPiutangScreen(),
      const ProfileScreen(),// Index 1// Index 2
    ];

    return Scaffold(
      body: IndexedStack(
        index: _selectedIndex,
        children: screens,
      ),
      bottomNavigationBar: Container(
  margin: const EdgeInsets.fromLTRB(20, 0, 20, 20), // Memberi efek melayang
  decoration: BoxDecoration(
    color: Colors.white,
    borderRadius: BorderRadius.circular(30), // Sudut membulat
    boxShadow: [
      BoxShadow(
        color: Colors.black.withValues(alpha: 0.1),
        blurRadius: 20,
        offset: const Offset(0, 10),
      ),
    ],
  ),
  child: ClipRRect(
    borderRadius: BorderRadius.circular(30),
    child: BottomNavigationBar(
      currentIndex: _selectedIndex,
      onTap: _onItemTapped,
      type: BottomNavigationBarType.fixed,
      selectedItemColor: const Color(0xFF00796b), // Hijau teal Anda
      unselectedItemColor: Colors.grey,
      backgroundColor: Colors.white,
      elevation: 0, // Dibuat 0 karena bayangan sudah ada di container
      showSelectedLabels: true,
      showUnselectedLabels: true,
      items: const [
        BottomNavigationBarItem(
          icon: Icon(Icons.dashboard_outlined),
          activeIcon: Icon(Icons.dashboard),
          label: 'Dashboard',
        ),
        BottomNavigationBarItem(
          icon: Icon(Icons.receipt_long_outlined),
          activeIcon: Icon(Icons.receipt_long),
          label: 'Utang',
        ),
        BottomNavigationBarItem(
          icon: Icon(Icons.person_outline),
          activeIcon: Icon(Icons.person),
          label: 'Profil',
        ),
      ],
    ),
  ),
),
    );
  }
}