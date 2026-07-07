import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class AddUtangPiutangScreen extends StatefulWidget {
  const AddUtangPiutangScreen({Key? key}) : super(key: key);

  @override
  State<AddUtangPiutangScreen> createState() => _AddUtangPiutangScreenState();
}

class _AddUtangPiutangScreenState extends State<AddUtangPiutangScreen> {
  final _formKey = GlobalKey<FormState>();
  final _supabase = Supabase.instance.client;

  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _amountController = TextEditingController();
  final TextEditingController _notesController = TextEditingController();

  String _transactionType = 'debt'; // Otomatis diset aman dari null
  DateTime? _selectedDate;
  bool _isLoading = false;

  @override
  void dispose() {
    _nameController.dispose();
    _amountController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  Future<void> _selectDueDate(BuildContext context) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: DateTime.now().add(const Duration(days: 7)),
      firstDate: DateTime.now().subtract(const Duration(days: 30)),
      lastDate: DateTime.now().add(const Duration(days: 365 * 5)),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: const ColorScheme.light(primary: Color(0xFF0A5C41)),
          ),
          child: child!,
        );
      },
    );
    if (picked != null && picked != _selectedDate) {
      setState(() => _selectedDate = picked);
    }
  }

  Future<void> _saveTransaction() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _isLoading = true);

    try {
      final userId = _supabase.auth.currentUser?.id;
      if (userId == null) throw Exception('Pengguna tidak terautentikasi.');

      final String? dueDateString = _selectedDate != null 
          ? "${_selectedDate!.year}-${_selectedDate!.month.toString().padLeft(2, '0')}-${_selectedDate!.day.toString().padLeft(2, '0')}"
          : null;

      final cleanAmountText = _amountController.text.trim().replaceAll('.', '');
      final num parsedAmount = num.parse(cleanAmountText);

      await _supabase.from('debts_credits').insert({
        'user_id': userId,
        'title': _nameController.text.trim(),
        'person_name': _nameController.text.trim(),
        'amount': parsedAmount,
        'type': _transactionType, 
        'due_date': dueDateString,
        'notes': _notesController.text.trim().isEmpty ? null : _notesController.text.trim(),
        'is_paid': false,
        'created_at': DateTime.now().toIso8601String(),
      });

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Catatan berhasil disimpan!'), backgroundColor: Color(0xFF10B981)),
      );
      Navigator.pop(context, true);
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Gagal menyimpan: $e'), backgroundColor: Colors.redAccent),
      );
    } finally {
      if (!mounted) return;
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF4F7F6),
      appBar: AppBar(
        title: const Text(
          'Tambah Catatan Baru',
          style: TextStyle(fontWeight: FontWeight.w800, fontSize: 18, color: Color(0xFF0F2922)),
        ),
        backgroundColor: Colors.white,
        foregroundColor: const Color(0xFF0F2922),
        elevation: 0,
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator(color: Color(0xFF0A5C41)))
          : SingleChildScrollView(
              padding: const EdgeInsets.all(20),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // --- MODERNISED TOGGLE SELECTOR ---
                    Container(
                      padding: const EdgeInsets.all(6),
                      decoration: BoxDecoration(color: const Color(0xFFE4ECE9), borderRadius: BorderRadius.circular(16)),
                      child: Row(
                        children: [
                          Expanded(
                            child: InkWell(
                              onTap: () => setState(() => _transactionType = 'debt'),
                              borderRadius: BorderRadius.circular(12),
                              child: Container(
                                padding: const EdgeInsets.symmetric(vertical: 14),
                                decoration: BoxDecoration(
                                  color: _transactionType == 'debt' ? const Color(0xFF0A5C41) : Colors.transparent,
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: Center(
                                  child: Text(
                                    'Utang Saya',
                                    style: TextStyle(
                                      fontWeight: FontWeight.bold,
                                      color: _transactionType == 'debt' ? Colors.white : const Color(0xFF6B877E),
                                    ),
                                  ),
                                ),
                              ),
                            ),
                          ),
                          Expanded(
                            child: InkWell(
                              onTap: () => setState(() => _transactionType = 'receivable'), // Sesuaikan 'credit' jika memakai opsi A di atas
                              borderRadius: BorderRadius.circular(12),
                              child: Container(
                                padding: const EdgeInsets.symmetric(vertical: 14),
                                decoration: BoxDecoration(
                                  color: _transactionType == 'receivable' ? const Color(0xFF0A5C41) : Colors.transparent,
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: Center(
                                  child: Text(
                                    'Piutang Saya',
                                    style: TextStyle(
                                      fontWeight: FontWeight.bold,
                                      color: _transactionType == 'receivable' ? Colors.white : const Color(0xFF6B877E),
                                    ),
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 24),

                    // --- CARD FORM CONTAINER ---
                    Container(
                      padding: const EdgeInsets.all(20),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(24),
                        boxShadow: [
                          BoxShadow(color: const Color(0xFF0A5C41).withOpacity(0.03), blurRadius: 20, offset: const Offset(0, 8))
                        ],
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          _buildLabel('Nama Kontak / Pelanggan'),
                          TextFormField(
                            controller: _nameController,
                            decoration: _buildDecoration('Masukkan nama lengkap', Icons.person_rounded),
                            validator: (value) => value == null || value.trim().isEmpty ? 'Nama tidak boleh kosong' : null,
                          ),
                          const SizedBox(height: 20),

                          _buildLabel('Nominal Transaksi (Rp)'),
                          TextFormField(
                            controller: _amountController,
                            keyboardType: TextInputType.number,
                            decoration: _buildDecoration('Contoh: 500000', Icons.payments_rounded),
                            style: const TextStyle(fontWeight: FontWeight.bold, color: Color(0xFF0A5C41)),
                            validator: (value) {
                              if (value == null || value.trim().isEmpty) return 'Nominal tidak boleh kosong';
                              if (num.tryParse(value.trim().replaceAll('.', '')) == null) return 'Masukkan angka saja';
                              return null;
                            },
                          ),
                          const SizedBox(height: 20),

                          _buildLabel('Tanggal Jatuh Tempo (Opsional)'),
                          InkWell(
                            onTap: () => _selectDueDate(context),
                            borderRadius: BorderRadius.circular(14),
                            child: Container(
                              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 15),
                              decoration: BoxDecoration(
                                color: const Color(0xFFF4F7F6),
                                borderRadius: BorderRadius.circular(14),
                                border: Border.all(color: const Color(0xFFE2E8F0)),
                              ),
                              child: Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  Row(
                                    children: [
                                      const Icon(Icons.calendar_month_rounded, color: Color(0xFF6B877E), size: 18),
                                      const SizedBox(width: 12),
                                      Text(
                                        _selectedDate == null 
                                            ? 'Pilih batas tanggal lunas' 
                                            : "${_selectedDate!.day}/${_selectedDate!.month}/${_selectedDate!.year}",
                                        style: TextStyle(
                                          color: _selectedDate == null ? const Color(0xFF94A3B8) : const Color(0xFF0F2922),
                                          fontWeight: _selectedDate == null ? FontWeight.normal : FontWeight.bold,
                                        ),
                                      ),
                                    ],
                                  ),
                                  const Icon(Icons.arrow_forward_ios_rounded, size: 14, color: Color(0xFF0A5C41)),
                                ],
                              ),
                            ),
                          ),
                          const SizedBox(height: 20),

                          _buildLabel('Keterangan Tambahan (Opsional)'),
                          TextFormField(
                            controller: _notesController,
                            maxLines: 3,
                            decoration: _buildDecoration('Catatan detail belanja / barang...', Icons.description_rounded),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 30),

                    // --- TOMBOL SIMPAN ELEGAN ---
                    SizedBox(
                      width: double.infinity,
                      height: 56,
                      child: ElevatedButton(
                        onPressed: _saveTransaction,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF0A5C41),
                          elevation: 0,
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                        ),
                        child: const Text(
                          'Simpan Catatan',
                          style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16),
                        ),
                      ),
                    )
                  ],
                ),
              ),
            ),
    );
  }

  Widget _buildLabel(String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8.0, left: 2),
      child: Text(text, style: const TextStyle(fontWeight: FontWeight.w700, color: Color(0xFF475569), fontSize: 13)),
    );
  }

  InputDecoration _buildDecoration(String hint, IconData icon) {
    return InputDecoration(
      hintText: hint,
      hintStyle: const TextStyle(color: Color(0xFF94A3B8), fontSize: 14),
      fillColor: const Color(0xFFF4F7F6),
      filled: true,
      prefixIcon: Icon(icon, color: const Color(0xFF6B877E), size: 18),
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: const BorderSide(color: Color(0xFFE2E8F0))),
      focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: const BorderSide(color: Color(0xFF0A5C41), width: 1.5)),
      errorBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: const BorderSide(color: Colors.redAccent)),
      focusedErrorBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: const BorderSide(color: Colors.redAccent, width: 1.5)),
    );
  }
}