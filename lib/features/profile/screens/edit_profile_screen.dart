import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../auth/widgets/header_clipper.dart';

class EditProfileScreen extends StatefulWidget {
  final Map<String, dynamic> userData;
  const EditProfileScreen({super.key, required this.userData});
  @override
  State<EditProfileScreen> createState() => _EditProfileScreenState();
}

class _EditProfileScreenState extends State<EditProfileScreen> {
  final _supabase = Supabase.instance.client;
  late TextEditingController _typeController;
  late TextEditingController _phoneController;
  late TextEditingController _addressController;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _typeController = TextEditingController(text: widget.userData['business_type'] ?? '');
    _phoneController = TextEditingController(text: widget.userData['phone'] ?? '');
    _addressController = TextEditingController(text: widget.userData['address'] ?? '');
  }

  Future<void> _updateProfile() async {
    setState(() => _isLoading = true);
    try {
      await _supabase.from('profiles').update({
        'business_type': _typeController.text,
        'phone': _phoneController.text,
        'address': _addressController.text,
      }).eq('id', _supabase.auth.currentUser!.id);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Profil berhasil diperbarui!")),
        );
        Navigator.pop(context, true);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Gagal update: $e")),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SingleChildScrollView(
        padding: const EdgeInsets.only(bottom: 50),
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
                child: const Center(
                  child: Text("Edit Profil", 
                    style: TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.bold)
                  )
                ),
              ),
            ),
            Transform.translate(
              offset: const Offset(0, 25), // Card diturunkan agar lebih rapi
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 24),
                child: Column(
                  children: [
                    _buildTextField("Tipe Bisnis", _typeController, Icons.category),
                    _buildTextField("Nomor Telepon", _phoneController, Icons.phone),
                    _buildTextField("Alamat", _addressController, Icons.location_on),
                    const SizedBox(height: 30),
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        onPressed: _isLoading ? null : _updateProfile,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF00796b), 
                          padding: const EdgeInsets.symmetric(vertical: 16), 
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16))
                        ),
                        child: _isLoading 
                          ? const CircularProgressIndicator(color: Colors.white) 
                          : const Text("Simpan", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 40), 

SizedBox(
  // Mengisi sisa layar agar footer terdorong ke bawah
  height: MediaQuery.of(context).size.height * 0.25, 
  child: Column(
    mainAxisAlignment: MainAxisAlignment.end, // Paksa konten ke paling bawah
    children: [
      const Icon(Icons.account_balance_wallet, size: 30, color: Color(0xFF00796b)), // Hijau
      const SizedBox(height: 8),
      Text(
        "Dompet UMKM", 
        style: TextStyle(
          color: const Color(0xFF00796b), // Hijau
          fontSize: 14, 
          fontWeight: FontWeight.w600
        )
      ),
      const SizedBox(height: 20), // Jarak mepet ke bawah layar
    ],
  ),
),
          ],
        ),
      ),
    );
  }

  Widget _buildTextField(String label, TextEditingController ctrl, IconData icon) => Padding(
    padding: const EdgeInsets.only(bottom: 20),
    child: TextFormField(
      controller: ctrl, 
      decoration: InputDecoration(
        labelText: label, 
        floatingLabelBehavior: FloatingLabelBehavior.always,
        prefixIcon: Icon(icon, color: const Color(0xFF00796b)), 
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(16))
      )
    ),
  );
}