// ignore: unused_import
import 'package:pdf/pdf.dart';
// ignore: unused_import
import 'package:pdf/widgets.dart' as pw;
// ignore: unused_import
import 'package:printing/printing.dart';
import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../auth/screens/login_screen.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:dompet_umkm/features/dashboard/screens/report_screen.dart';

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  final _supabase = Supabase.instance.client;
  bool _isLoading = false;
  String _businessName = "Toko Bisnis";
  String _ownerName = "Pemilik";

  // Variabel penampung data kas
  int _totalBalance = 0;
  int _totalIncome = 0;
  int _totalExpense = 0;
  int _selectedYear = DateTime.now().year;
  num _totalUtang = 0;
num _totalPiutang = 0; // Untuk status loading  // Default ke tahun sekarang (2026)
  List<dynamic> _transactionsList = [];

  // Controller untuk formulir input transaksi baru
  final _titleController = TextEditingController();
  final _amountController = TextEditingController();
  String _selectedType = 'income';

  @override
  void initState() {
    super.initState();
    _loadDashboardData();
  }

  @override
  void dispose() {
    _titleController.dispose();
    _amountController.dispose();
    super.dispose();
  }
Future<void> _loadDashboardData() async {
    setState(() => _isLoading = true);
    try {
      final user = _supabase.auth.currentUser;
      if (user == null) return;

      // --- 1. Ambil Data Profil ---
      setState(() {
        _businessName = user.userMetadata?['business_name'] ?? "Toko Berkah";
        _ownerName = user.userMetadata?['owner_name'] ?? "Pemilik";
      });

      // --- 2. Ambil Data Transaksi ---
      final responseTx = await _supabase.from('transactions').select().eq('user_id', user.id);
      final dataTx = responseTx as List<dynamic>;

      // --- 3. Ambil Data Utang Piutang (TANPA FILTER) ---
      // Kita hapus dulu .eq('is_paid', false) untuk memastikan data masuk
      // Ganti bagian responseDebt menjadi ini:
final responseDebt = await _supabase
    .from('debts_credits')
    .select()
    .eq('user_id', user.id)
    .eq('is_paid', false); // Hanya ambil yang belum lunas
      final dataDebt = responseDebt as List<dynamic>;

      print("DEBUG: Jumlah data debt/credit: ${dataDebt.length}");
      print("DEBUG: Isi data debt/credit: $dataDebt");

      // --- 4. Kalkulasi Kas ---
      int incomeCalculated = 0;
      int expenseCalculated = 0;
      for (var item in dataTx) {
        final amount = (item['amount'] is num) ? (item['amount'] as num).toInt() : 0;
        if (item['type'] == 'income') incomeCalculated += amount;
        else if (item['type'] == 'expense') expenseCalculated += amount;
      }

      // --- 5. Kalkulasi Utang Piutang ---
     // --- 5. Kalkulasi Utang Piutang ---
      num utang = 0;
      num piutang = 0;
      for (var item in dataDebt) {
        final amount = (item['amount'] is num) ? (item['amount'] as num) : 0;
        final type = item['type']?.toString().toLowerCase(); 
        
        // Cek 'debt' untuk utang, dan 'receivable' untuk piutang
        if (type == 'debt') {
          utang += amount;
        } else if (type == 'receivable') { // <--- UBAH DI SINI
          piutang += amount;
        }
      }

      setState(() {
        _transactionsList = dataTx;
        _totalIncome = incomeCalculated;
        _totalExpense = expenseCalculated;
        _totalBalance = incomeCalculated - expenseCalculated;
        _totalUtang = utang;
        _totalPiutang = piutang;
      });

    } catch (e) {
      debugPrint("Gagal memuat: $e");
    } finally {
      setState(() => _isLoading = false);
    }
  }

  // Fungsi untuk menghapus transaksi dari Supabase
  Future<void> _deleteTransaction(int id) async {
    try {
      setState(() {
        _isLoading = true;
      });

      // Menghapus data di Supabase berdasarkan ID transaksi
      await _supabase.from('transactions').delete().eq('id', id);

      // Tampilkan pesan sukses kecil di bawah layar
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Transaksi berhasil dihapus'),
            backgroundColor: Colors.green,
          ),
        );
      }

      

      // Muat ulang data dashboard agar kalkulasi saldo kembali sinkron
      await _loadDashboardData();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Gagal menghapus: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }

  }
  
  
  // Menyimpan transaksi baru ke database Supabase
  Future<void> _saveTransaction() async {
    if (_titleController.text.trim().isEmpty || _amountController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Semua kolom wajib diisi!'), backgroundColor: Colors.orange),
      );
      return;
    }

    final user = _supabase.auth.currentUser;
    if (user == null) return;

    try {
     await _supabase.from('transactions').insert({
        'user_id': user.id,
        'title': _titleController.text.trim(),
        'amount': int.parse(_amountController.text.trim()), // Memastikan dikirim berupa angka
        'type': _selectedType,
      });

      if (mounted) {
        Navigator.pop(context); // Tutup bottom sheet
        _titleController.clear();
        _amountController.clear();
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Transaksi berhasil dicatat!'), backgroundColor: Colors.green),
        );
        
        // PERBAIKAN: Setelah simpan sukses, langsung tarik ulang data kas agar UI berubah otomatis
        _loadDashboardData();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Gagal menyimpan: $e'), backgroundColor: Colors.redAccent),
        );
      }
    }
  }

  void _showFormBottomSheet() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setModalState) {
            return Padding(
              padding: EdgeInsets.only(
                bottom: MediaQuery.of(context).viewInsets.bottom + 24,
                top: 24, left: 24, right: 24,
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  const Text('Catat Transaksi Baru', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.teal), textAlign: TextAlign.center),
                  const SizedBox(height: 20),
                  TextField(
                    controller: _titleController,
                    decoration: InputDecoration(labelText: 'Nama Transaksi / Keterangan', prefixIcon: const Icon(Icons.edit_note), border: OutlineInputBorder(borderRadius: BorderRadius.circular(12))),
                  ),
                  const SizedBox(height: 16),
                  TextField(
                    controller: _amountController,
                    keyboardType: TextInputType.number,
                    decoration: InputDecoration(labelText: 'Nominal Uang (Rp)', prefixIcon: const Icon(Icons.attach_money), border: OutlineInputBorder(borderRadius: BorderRadius.circular(12))),
                  ),
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      Expanded(
                        child: RadioListTile<String>(
                          title: const Text('Pemasukan', style: TextStyle(fontSize: 14)),
                          value: 'income', groupValue: _selectedType, activeColor: Colors.teal,
                          onChanged: (val) => setModalState(() => _selectedType = val!),
                        ),
                      ),
                      Expanded(
                        child: RadioListTile<String>(
                          title: const Text('Pengeluaran', style: TextStyle(fontSize: 14)),
                          value: 'expense', groupValue: _selectedType, activeColor: Colors.red,
                          onChanged: (val) => setModalState(() => _selectedType = val!),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 20),
                  ElevatedButton(
                    onPressed: () async {
                      await _saveTransaction();
                    },
                    style: ElevatedButton.styleFrom(backgroundColor: Colors.teal, foregroundColor: Colors.white, padding: const EdgeInsets.symmetric(vertical: 16), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))),
                    child: const Text('Simpan Transaksi', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  Future<void> _logout() async {
    await _supabase.auth.signOut();
    if (mounted) {
      Navigator.pushReplacement(context, MaterialPageRoute(builder: (context) => const LoginScreen()));
    }
  }

  // FITUR EKSPOR LAPORAN PDF (Sudah Bersih dari Typo)
Future<void> _exportToPDF() async {
    // 1. Kita ambil data terfilter berdasarkan tahun saat ini
    final totals = _calculateYearlyTotals();
    
    final filteredTransactions = _transactionsList.where((tx) {
      if (tx['created_at'] == null) return false;
      try {
        DateTime date = DateTime.parse(tx['created_at'].toString());
        return date.year == _selectedYear;
      } catch (e) {
        return false;
      }
    }).toList();

    // 2. Oper data terfilter ke halaman ReportScreen baru
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => ReportScreen(
          businessName: _businessName,
          ownerName: _ownerName,
          selectedYear: _selectedYear,
          transactions: filteredTransactions.cast<Map<String, dynamic>>(), // Mengirim data yang lolos filter saja
          totalIncome: (totals['totalIncome'] ?? 0.0).toDouble(),
          totalExpense: (totals['totalExpense'] ?? 0.0).toDouble(),
          totalBalance: (totals['balance'] ?? 0.0).toDouble(),
        ),
      ),
    );
  }
@override
  Widget build(BuildContext context) {
    // Fungsi internal memformat angka menjadi Rupiah (Titik ribuan)
    String formatRupiah(double amount) {
      return 'Rp ${amount.toInt().toString().replaceAllMapped(RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'), (Match m) => '${m[1]}.')}';
    }

    return Scaffold(
      backgroundColor: const Color(0xfff6f8fb),
      // appBar LAMA SUDAH DIHAPUS TOTAL DI SINI
      body: _isLoading
          ? const Center(child: CircularProgressIndicator(color: Colors.teal))
          : RefreshIndicator(
              onRefresh: _loadDashboardData,
              child: SingleChildScrollView(
                physics: const AlwaysScrollableScrollPhysics(),
                padding: EdgeInsets.zero, // Membuat header baru bisa mentok ke atas layar
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // 1. HEADER MODERN CUSTOM (Menggantikan AppBar lama)
                    _buildModernHeader(),
                    
                    // 2. KONTEN UTAMA DASHBOARD (Diberi padding agar rapi tidak mentok pinggir)
                    Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // CARD HIJAU UTAMA PREMIUM
                          Card(
                            elevation: 6,
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
                            shadowColor: Colors.teal.withOpacity(0.3),
                            child: Container(
                              decoration: BoxDecoration(
                                gradient: const LinearGradient(
                                  colors: [Color(0xFF00b493), Color(0xFF00796b)], 
                                  begin: Alignment.topLeft, 
                                  end: Alignment.bottomRight
                                ),
                                borderRadius: BorderRadius.circular(24),
                              ),
                              padding: const EdgeInsets.all(24.0),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                    children: [
                                      const Text(
                                        'Total Saldo Kas Usaha', 
                                        style: TextStyle(color: Colors.white70, fontSize: 14, fontWeight: FontWeight.w500),
                                      ),
                                      Container(
                                        padding: const EdgeInsets.all(6),
                                        decoration: BoxDecoration(color: Colors.white24, borderRadius: BorderRadius.circular(10)),
                                        child: const Icon(Icons.account_balance_wallet_rounded, color: Colors.white, size: 20),
                                      )
                                    ],
                                  ),
                                  const SizedBox(height: 8),
                                  Text(
                                    formatRupiah(_totalBalance.toDouble()), 
                                    style: const TextStyle(color: Colors.white, fontSize: 30, fontWeight: FontWeight.bold, letterSpacing: 0.5),
                                  ),
                                  const SizedBox(height: 20),
                                  Container(height: 1, color: Colors.white12), 
                                  const SizedBox(height: 16),
                                  Row(
                                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                    children: [
                                      // Sisi Pemasukan
                                      Expanded(
                                        child: Row(
                                          children: [
                                            Container(
                                              padding: const EdgeInsets.all(8),
                                              decoration: BoxDecoration(color: Colors.white.withOpacity(0.15), shape: BoxShape.circle),
                                              child: const Icon(Icons.arrow_downward_rounded, color: Color(0xFF4ADE80), size: 18),
                                            ),
                                            const SizedBox(width: 10),
                                            Expanded(
                                              child: Column(
                                                crossAxisAlignment: CrossAxisAlignment.start,
                                                children: [
                                                  const Text('Pemasukan', style: TextStyle(color: Colors.white70, fontSize: 11, fontWeight: FontWeight.w400)),
                                                  Text(formatRupiah(_totalIncome.toDouble()), style: const TextStyle(color: Colors.white, fontSize: 13, fontWeight: FontWeight.bold), overflow: TextOverflow.ellipsis),
                                                ],
                                              ),
                                            )
                                          ],
                                        ),
                                      ),
                                      Container(width: 1, height: 30, color: Colors.white12),
                                      const SizedBox(width: 16),
                                      // Sisi Pengeluaran
                                      Expanded(
                                        child: Row(
                                          children: [
                                            Container(
                                              padding: const EdgeInsets.all(8),
                                              decoration: BoxDecoration(color: Colors.white.withOpacity(0.15), shape: BoxShape.circle),
                                              child: const Icon(Icons.arrow_upward_rounded, color: Color(0xFFFCA5A5), size: 18),
                                            ),
                                            const SizedBox(width: 10),
                                            Expanded(
                                              child: Column(
                                                crossAxisAlignment: CrossAxisAlignment.start,
                                                children: [
                                                  const Text('Pengeluaran', style: TextStyle(color: Colors.white70, fontSize: 11, fontWeight: FontWeight.w400)),
                                                  Text(formatRupiah(_totalExpense.toDouble()), style: const TextStyle(color: Colors.white, fontSize: 13, fontWeight: FontWeight.bold), overflow: TextOverflow.ellipsis),
                                                ],
                                              ),
                                            )
                                          ],
                                        ),
                                      ),
                                    ],
                                  )
                                ],
                              ),
                            ),
                          ),

                          const SizedBox(height: 16), // Jarak antara Card Saldo dan Ringkasan

// Letakkan ini di bawah Card Hijau Utama Anda
Row(
  children: [
    Expanded(
      child: _buildDebtCreditCard(
        "Total Utang", 
        _totalUtang, 
        Colors.redAccent, 
        Icons.arrow_upward_rounded // Ikon untuk utang (keluar)
      ),
    ),
    const SizedBox(width: 12),
    Expanded(
      child: _buildDebtCreditCard(
        "Total Piutang", 
        _totalPiutang, 
        Colors.teal, 
        Icons.arrow_downward_rounded // Ikon untuk piutang (masuk)
      ),
    ),
  ],
),
const SizedBox(height: 20),
                          const SizedBox(height: 20),
                          
                          // GRAFIK STATISTIK KEUANGAN
                          _buildFinancialChart(),
                          const SizedBox(height: 24),
                          
                          // DAFTAR RIWAYAT TRANSAKSI TERBARU
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              const Text(
                                'Riwayat Transaksi Terbaru', 
                                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Color(0xFF1F2937))
                              ),
                              if (_transactionsList.length > 5)
                                Text(
                                  'Lihat Semua',
                                  style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: Colors.teal.shade700),
                                ),
                            ],
                          ),
                          const SizedBox(height: 12),

                          _transactionsList.isEmpty
                              ? Container(
                                  height: 160,
                                  decoration: BoxDecoration(
                                    color: Colors.white, 
                                    borderRadius: BorderRadius.circular(16),
                                    border: Border.all(color: const Color(0xFFE5E7EB)),
                                  ),
                                  child: const Center(
                                    child: Column(
                                      mainAxisAlignment: MainAxisAlignment.center,
                                      children: [
                                        Icon(Icons.receipt_long_rounded, size: 40, color: Color(0xFF9CA3AF)),
                                        SizedBox(height: 8),
                                        Text('Belum ada transaksi tercatat.', style: TextStyle(color: Color(0xFF6B7280), fontSize: 13)),
                                      ],
                                    ),
                                  ),
                                )
                                
                 :ListView.separated(
  shrinkWrap: true,
  physics: const NeverScrollableScrollPhysics(),
  // Dihapus batasan .length > 5 agar semua transaksi muncul
  itemCount: _transactionsList.length, 
  separatorBuilder: (context, index) => const SizedBox(height: 12),
  itemBuilder: (context, index) {
    final item = _transactionsList[index];
    final isIncome = item['type'] == 'income';
    final txId = item['id'];

    // Format Tanggal
    String displayDate = 'Tanpa Tanggal';
    if (item['created_at'] != null) {
      final rawDate = item['created_at'].toString();
      displayDate = rawDate.length >= 10 ? rawDate.substring(0, 10) : rawDate;
    }

    return Dismissible(
      key: Key(txId.toString()),
      direction: DismissDirection.endToStart,
      background: Container(
        decoration: BoxDecoration(color: const Color(0xFFEF4444), borderRadius: BorderRadius.circular(16)),
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.only(right: 20),
        child: const Icon(Icons.delete_outline_rounded, color: Colors.white, size: 22),
      ),
      onDismissed: (direction) => _deleteTransaction(txId),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20), // Sudut lebih membulat (modern)
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.03),
              blurRadius: 10,
              offset: const Offset(0, 4),
            )
          ],
        ),
        child: Row(
          children: [
            // Ikon dengan background soft
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: isIncome ? const Color(0xFFE6F4EA) : const Color(0xFFFCE8E6),
                borderRadius: BorderRadius.circular(15),
              ),
              child: Icon(
                isIncome ? Icons.arrow_downward_rounded : Icons.arrow_upward_rounded,
                size: 22,
                color: isIncome ? const Color(0xFF10B981) : const Color(0xFFEF4444),
              ),
            ),
            const SizedBox(width: 16),
            // Keterangan & Tanggal
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    item['title'] ?? 'Tanpa Keterangan',
                    style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15, color: Color(0xFF1F2937)),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    "${isIncome ? 'Pemasukan' : 'Pengeluaran'} • $displayDate",
                    style: TextStyle(fontSize: 12, color: Colors.grey[600], fontWeight: FontWeight.w500),
                  ),
                ],
              ),
            ),
            // Nominal
            Text(
              "${isIncome ? '+' : '-'} ${formatRupiah((item['amount'] ?? 0).toDouble())}",
              style: TextStyle(
                fontWeight: FontWeight.bold, 
                fontSize: 15, 
                color: isIncome ? const Color(0xFF10B981) : const Color(0xFFEF4444),
              ),
            ),
          ],
        ),
      ),
    );
  },
),
                        // <--- Pastikan koma ini ada jika di dalam Column/ListView
                          const SizedBox(height: 80), 
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _showFormBottomSheet,
        label: const Text('Catat Transaksi', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.white)),
        icon: const Icon(Icons.add, color: Colors.white),
        backgroundColor: Colors.teal,
        elevation: 4,
      ),
    );
  }

Widget _buildDebtCreditCard(String title, num amount, Color color, IconData icon) {
  return Card(
    elevation: 3,
    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
    child: Padding(
      padding: const EdgeInsets.all(16.0),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: color.withOpacity(0.1),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(icon, color: color, size: 20),
          ),
          const SizedBox(width: 12),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(title, style: const TextStyle(fontSize: 12, color: Colors.grey)),
              const SizedBox(height: 2),
              Text(
                "Rp ${amount.toInt().toString().replaceAllMapped(RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'), (Match m) => '${m[1]}.')}",
                style: TextStyle(
                  fontSize: 14, 
                  fontWeight: FontWeight.bold, 
                  color: color
                ),
              ),
            ],
          ),
        ],
      ),
    ),
  );
}
  // PASTE KODE INI TEPAT DI BAWAH WIDGET BUILD KAMU
  Widget _buildModernHeader() {
    String initial = _businessName.isNotEmpty 
        ? _businessName.trim().split(' ').map((l) => l[0]).take(2).join().toUpperCase() 
        : "U";

    String greeting() {
      var hour = DateTime.now().hour;
      if (hour < 12) return 'Selamat Pagi ☀️';
      if (hour < 15) return 'Selamat Siang 🌤️';
      if (hour < 18) return 'Selamat Sore 🌅';
      return 'Selamat Malam 🌙';
    }

    // Menggunakan ClipPath untuk memotong background mengikuti CustomClipper di bawah
    return ClipPath(
      clipper: HeaderWaveClipper(),
      child: Container(
        width: double.infinity,
        // Ditambah sedikit bottom padding agar konten tidak terpotong lengkungan
        padding: const EdgeInsets.only(top: 60, left: 24, right: 24, bottom: 50),
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [Color(0xFF004D40), Color(0xFF00796B)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Row(
                    children: [
                      Container(
                        width: 46,
                        height: 46,
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.15),
                          shape: BoxShape.circle,
                          border: Border.all(color: Colors.white.withOpacity(0.25), width: 1.5),
                        ),
                        alignment: Alignment.center,
                        child: Text(
                          initial,
                          style: const TextStyle(color: Colors.white, fontSize: 15, fontWeight: FontWeight.bold),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              greeting(),
                              style: TextStyle(color: Colors.white.withOpacity(0.7), fontSize: 11),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              _businessName,
                              style: const TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold, overflow: TextOverflow.ellipsis),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 8),
                Material(
                  color: Colors.transparent,
                  child: InkWell(
                    onTap: _logout,
                    borderRadius: BorderRadius.circular(12),
                    child: Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: Colors.white.withOpacity(0.15)),
                      ),
                      child: const Icon(Icons.logout_rounded, color: Color(0xFFFCA5A5), size: 18),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 14),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: Colors.black.withOpacity(0.12),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.person_outline_rounded, color: Colors.teal.shade200, size: 13),
                  const SizedBox(width: 6),
                  Text(
                    "Owner: $_ownerName",
                    style: TextStyle(color: Colors.teal.shade100, fontSize: 11, fontWeight: FontWeight.w500),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
  // ================= GRAPH CODE START =================
  
  // 1. Fungsi pengolah data grafik
Map<int, Map<String, double>> _calculateMonthlyData() {
    Map<int, Map<String, double>> monthlyMap = {};
    for (int i = 1; i <= 12; i++) {
      monthlyMap[i] = {'income': 0.0, 'expense': 0.0};
    }
    for (var tx in _transactionsList) {
      if (tx['created_at'] == null) continue;
      try {
        DateTime date = DateTime.parse(tx['created_at'].toString());
        
        // FILTER: Lewati transaksi jika tahunnya tidak cocok dengan dropdown yang dipilih
        if (date.year != _selectedYear) continue;

        int month = date.month;
        double amount = 0.0;
        if (tx['amount'] is num) {
          amount = (tx['amount'] as num).toDouble();
        } else {
          amount = double.tryParse(tx['amount'].toString()) ?? 0.0;
        }
        if (tx['type'] == 'income') {
          monthlyMap[month]!['income'] = monthlyMap[month]!['income']! + amount;
        } else if (tx['type'] == 'expense') {
          monthlyMap[month]!['expense'] = monthlyMap[month]!['expense']! + amount;
        }
      } catch (e) {}
    }
    return monthlyMap;
  }

  Map<String, double> _calculateYearlyTotals() {
    final monthlyData = _calculateMonthlyData();
    double totalIncome = 0.0;
    double totalExpense = 0.0;

    monthlyData.forEach((month, values) {
      totalIncome += values['income'] ?? 0.0;
      totalExpense += values['expense'] ?? 0.0;
    });

    return {
      'totalIncome': totalIncome,
      'totalExpense': totalExpense,
      'balance': totalIncome - totalExpense,
    };
  }
  // 2. Fungsi pembantu skala grafik
  double _getMaxY(Map<int, Map<String, double>> data, List<int> months) {
    double maxVal = 100000; 
    for (int m in months) {
      if (data[m]!['income']! > maxVal) maxVal = data[m]!['income']!;
      if (data[m]!['expense']! > maxVal) maxVal = data[m]!['expense']!;
    }
    return maxVal * 1.2; 
  }

Widget _buildFinancialChart() {
  final monthlyData = _calculateMonthlyData();
  final now = DateTime.now();

  // Pastikan indeks bulan aman
  List<int> monthsToShow = [
    now.month - 2 <= 0 ? now.month + 10 : now.month - 2,
    now.month - 1 <= 0 ? now.month + 11 : now.month - 1,
    now.month,
  ];

  List<String> allMonthNames = [
    '', 'Jan', 'Feb', 'Mar', 'Apr', 'Mei', 'Juni', 'Juli', 'Agu', 'Sep', 'Okt', 'Nov', 'Des'
  ];

  return Container(
    // GRADASI HIJAU PREMIUM (Sesuai permintaan)
    decoration: BoxDecoration(
      gradient: const LinearGradient(
        colors: [Color(0xFFF0FDF4), Colors.white], // Hijau sangat soft ke putih
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
      ),
      borderRadius: BorderRadius.circular(24),
      border: Border.all(color: const Color(0xFFD1FAE5)), // Border hijau tipis
      boxShadow: [
        BoxShadow(
          color: const Color(0xFF10B981).withValues(alpha: 0.08),
          blurRadius: 20,
          offset: const Offset(0, 10),
        ),
      ],
    ),
    padding: const EdgeInsets.all(20.0),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [

        // Cari bagian ini di dalam widget _buildFinancialChart()
IconButton(
  icon: const Icon(Icons.print_outlined, size: 20, color: Color(0xFF6B7280)),
  
  // UBAH BAGIAN INI:
  onPressed: () {
    _exportToPDF(); // Memanggil fungsi agar tidak dianggap "unused"
  }, 
  
  tooltip: 'Cetak Laporan PDF',
  constraints: const BoxConstraints(),
  padding: const EdgeInsets.all(8),
  style: IconButton.styleFrom(
    backgroundColor: const Color(0xFFF3F4F6),
    shape: const CircleBorder(),
  ),
),
        // --- Header tetap sama ---
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Row(
              children: [
                const Text('Statistik Keuangan', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                const SizedBox(width: 10),
                
                // Dropdown tahun (Gunakan state management Anda)
              ],
            ),
          ],
        ),
        const SizedBox(height: 24),

        // --- BARCHART MODERN ---
        SizedBox(
          height: 180,
          child: BarChart(
            BarChartData(
              alignment: BarChartAlignment.spaceAround,
              maxY: _getMaxY(monthlyData, monthsToShow),
              barTouchData: BarTouchData(
                touchTooltipData: BarTouchTooltipData(
                  getTooltipColor: (_) => const Color(0xFF1F2937),
                  getTooltipItem: (group, groupIndex, rod, rodIndex) {
                    return BarTooltipItem(
                      '${rodIndex == 0 ? "Masuk" : "Keluar"}\n',
                      const TextStyle(color: Colors.white70, fontSize: 11),
                      children: [
                        TextSpan(
                          text: 'Rp ${rod.toY.toInt()}',
                          style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                        ),
                      ],
                    );
                  },
                ),
              ),
              barGroups: List.generate(3, (i) {
                // Ambil data bulan berdasarkan list monthsToShow
                int monthIndex = monthsToShow[i];
                double inc = (monthlyData[monthIndex]?['income'] ?? 0.0);
                double exp = (monthlyData[monthIndex]?['expense'] ?? 0.0);

                return BarChartGroupData(
                  x: i,
                  barRods: [
                    BarChartRodData(
                      toY: inc,
                      gradient: const LinearGradient(colors: [Color(0xFF10B981), Color(0xFF059669)]),
                      width: 14,
                      borderRadius: const BorderRadius.vertical(top: Radius.circular(6)),
                    ),
                    BarChartRodData(
                      toY: exp,
                      gradient: const LinearGradient(colors: [Color(0xFFEF4444), Color(0xFFB91C1C)]),
                      width: 14,
                      borderRadius: const BorderRadius.vertical(top: Radius.circular(6)),
                    ),
                  ],
                );
              }),
              titlesData: FlTitlesData(
                bottomTitles: AxisTitles(
                  sideTitles: SideTitles(
                    showTitles: true,
                    getTitlesWidget: (value, meta) => Padding(
                      padding: const EdgeInsets.only(top: 8),
                      child: Text(allMonthNames[monthsToShow[value.toInt()]], 
                        style: const TextStyle(color: Color(0xFF6B7280), fontSize: 11)),
                    ),
                  ),
                ),
                leftTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
              ),
              gridData: FlGridData(
                show: true, 
                drawVerticalLine: false,
                horizontalInterval: _getMaxY(monthlyData, monthsToShow) / 4,
                getDrawingHorizontalLine: (value) => FlLine(color: Colors.grey.withValues(alpha: 0.1), strokeWidth: 1),
              ),
              borderData: FlBorderData(show: false),
            ),
          ),
        ),
      ],
    ),
  );
}

  
  // ================= GRAPH CODE END =================
}
// Class khusus untuk memotong bentuk background melengkung ke atas (cekung)
class HeaderWaveClipper extends CustomClipper<Path> {
  @override
  Path getClip(Size size) {
    Path path = Path();
    path.lineTo(0, size.height); // Mulai dari kiri bawah
    
    // Titik awal lengkungan, titik kontrol di tengah atas, dan titik akhir di kanan bawah
    var firstControlPoint = Offset(size.width / 2, size.height - 35);
    var firstEndPoint = Offset(size.width, size.height);
    
    // Membuat garis melengkung kuadratik (Quadratic Bezier Curve)
    path.quadraticBezierTo(
      firstControlPoint.dx, 
      firstControlPoint.dy, 
      firstEndPoint.dx, 
      firstEndPoint.dy,
    );
    
    path.lineTo(size.width, 0); // Naik ke kanan atas
    path.close(); // Tutup path kembali ke titik awal (0,0)
    return path;
  }

  @override
  bool shouldReclip(CustomClipper<Path> oldClipper) => false;
}