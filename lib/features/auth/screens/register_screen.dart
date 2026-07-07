import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../../core/constants/colors.dart';
import '../widgets/custom_text_field.dart';

class RegisterScreen extends StatefulWidget {
  const RegisterScreen({super.key});

  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _businessNameController = TextEditingController();
  final _ownerNameController = TextEditingController();
  bool _isLoading = false;
  bool _obscureText = true;

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    _businessNameController.dispose();
    _ownerNameController.dispose();
    super.dispose();
  }

  Future<void> _register() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);
    try {
      await Supabase.instance.client.auth.signUp(
        email: _emailController.text.trim(),
        password: _passwordController.text.trim(),
        data: {
          'business_name': _businessNameController.text.trim(),
          'owner_name': _ownerNameController.text.trim(),
        },
      );
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Registrasi Berhasil! Silakan periksa email verifikasi Anda.'), backgroundColor: AppColors.primary),
        );
        Navigator.pop(context);
      }
    } on AuthException catch (error) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(error.message), backgroundColor: Colors.redAccent),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(backgroundColor: Colors.transparent, elevation: 0, iconTheme: const IconThemeData(color: AppColors.secondary)),
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24.0),
            child: Form(
              key: _formKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  const Text(
                    'Mulai Usahamu 🚀',
                    style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold, color: AppColors.secondary),
                  ),
                  const SizedBox(height: 8),
                  const Text('Daftarkan UMKM Anda dan nikmati pencatatan keuangan yang rapi.', style: TextStyle(color: Colors.grey)),
                  const SizedBox(height: 32),
                  
                  CustomTextField(
                    controller: _ownerNameController,
                    label: 'Nama Pemilik',
                    icon: Icons.person_outline,
                    validator: (v) => v == null || v.isEmpty ? 'Nama pemilik wajib diisi' : null,
                  ),
                  CustomTextField(
                    controller: _businessNameController,
                    label: 'Nama Toko / Bisnis',
                    icon: Icons.storefront_outlined,
                    validator: (v) => v == null || v.isEmpty ? 'Nama usaha wajib diisi' : null,
                  ),
                  CustomTextField(
                    controller: _emailController,
                    label: 'Email Bisnis',
                    icon: Icons.email_outlined,
                    validator: (v) => v == null || !v.contains('@') ? 'Email tidak valid' : null,
                  ),
                  CustomTextField(
                    controller: _passwordController,
                    label: 'Password (Min 6 Karakter)',
                    icon: Icons.lock_outline,
                    obscureText: _obscureText,
                    suffixIcon: IconButton(
                      icon: Icon(_obscureText ? Icons.visibility_off : Icons.visibility),
                      onPressed: () => setState(() => _obscureText = !_obscureText),
                    ),
                    validator: (v) => v == null || v.length < 6 ? 'Password terlalu pendek' : null,
                  ),
                  
                  const SizedBox(height: 20),
                  
                  ElevatedButton(
                    onPressed: _isLoading ? null : _register,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primary,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                      elevation: 2,
                    ),
                    child: _isLoading 
                      ? const SizedBox(height: 20, width: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                      : const Text('Buat Akun Bisnis', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}