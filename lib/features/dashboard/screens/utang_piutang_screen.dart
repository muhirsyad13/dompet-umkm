import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'add_utang_piutang_screen.dart';

/// 1. CLASS CLIPPER UNTUK LENGKUNGAN HEADER (Desain Modern)
class CustomHeaderClipper extends CustomClipper<Path> {
  @override
  Path getClip(Size size) {
    Path path = Path();
    path.lineTo(0, size.height); // Garis ke kiri bawah
    
    // Ini adalah logika lengkungan cekung (seperti dashboard)
    var firstControlPoint = Offset(size.width / 2, size.height - 35);
    var firstEndPoint = Offset(size.width, size.height);
    
    path.quadraticBezierTo(
      firstControlPoint.dx, 
      firstControlPoint.dy, 
      firstEndPoint.dx, 
      firstEndPoint.dy,
    );
    
    path.lineTo(size.width, 0); // Naik ke kanan atas
    path.close();
    return path;
  }

  @override
  bool shouldReclip(CustomClipper<Path> oldClipper) => false;
}

class UtangPiutangScreen extends StatefulWidget {
  const UtangPiutangScreen({Key? key}) : super(key: key);

  @override
  State<UtangPiutangScreen> createState() => _UtangPiutangScreenState();
}

class _UtangPiutangScreenState extends State<UtangPiutangScreen>
with SingleTickerProviderStateMixin {
Future<void> addPayment({
  required int debtCreditId,
  required num amountPaid,
  required String notes,
}) async {
  final supabase = Supabase.instance.client;
  final userId = supabase.auth.currentUser?.id;

  if (userId == null) return;

  try {
    // 1. Insert ke tabel debt_payments
    await supabase.from('debt_payments').insert({
      'user_id': userId,
      'debt_credit_id': debtCreditId,
      'amount': amountPaid,
      'payment_date': DateTime.now().toIso8601String(),
      'notes': notes,
    });

    // 2. Update sisa jumlah di debts_credits
    final currentData = await supabase
        .from('debts_credits')
        .select('amount')
        .eq('id', debtCreditId)
        .single();

    num currentAmount = currentData['amount'];
    num newAmount = currentAmount - amountPaid;

    await supabase.from('debts_credits').update({
      'amount': newAmount,
      'is_paid': newAmount <= 0,
    }).eq('id', debtCreditId);

    // 3. Refresh data hanya jika proses sukses
    if (mounted) {
      _initializeData();
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Pembayaran berhasil dicatat!")),
      );
    }
  } catch (e) {
    debugPrint("Error saat memproses pembayaran: $e");
    // Pesan error hanya muncul di blok catch
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Gagal memproses pembayaran: $e")),
      );
    }
  }
}
void _showPaymentDialog(Map<String, dynamic> debtItem) {
    final TextEditingController amountController = TextEditingController();
    final TextEditingController notesController = TextEditingController();

    showDialog(
      context: context,
      builder: (ctx) => Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Header Icon
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: primaryGreen.withOpacity(0.1),
                  shape: BoxShape.circle,
                ),
                child: Icon(Icons.payments_rounded, color: primaryGreen, size: 32),
              ),
              const SizedBox(height: 16),
              Text(
                "Bayar Utang",
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.grey.shade800),
              ),
              Text(
                "Kepada: ${debtItem['person_name']}",
                style: const TextStyle(color: Colors.grey, fontSize: 14),
              ),
              const SizedBox(height: 24),
              // Input Nominal
              TextField(
                controller: amountController,
                keyboardType: TextInputType.number,
                decoration: InputDecoration(
                  labelText: "Nominal Bayar",
                  prefixText: "Rp ",
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(15)),
                  focusedBorder: OutlineInputBorder(borderSide: BorderSide(color: primaryGreen, width: 2), borderRadius: BorderRadius.circular(15)),
                ),
              ),
              const SizedBox(height: 16),
              // Input Catatan
              TextField(
                controller: notesController,
                decoration: InputDecoration(
                  labelText: "Catatan (Opsional)",
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(15)),
                ),
              ),
              const SizedBox(height: 24),
              // Tombol Aksi
              Row(
                children: [
                  Expanded(
                    child: TextButton(
                      onPressed: () => Navigator.pop(ctx),
                      child: const Text("Batal", style: TextStyle(color: Colors.grey)),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: primaryGreen,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
                        padding: const EdgeInsets.symmetric(vertical: 16),
                      ),
                      onPressed: () {
                        final amount = num.tryParse(amountController.text) ?? 0;
                        if (amount > 0) {
                          addPayment(
                            debtCreditId: debtItem['id'],
                            amountPaid: amount,
                            notes: notesController.text,
                          );
                          Navigator.pop(ctx);
                        }
                      },
                      child: const Text("Konfirmasi", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
  final _supabase = Supabase.instance.client;
  late TabController _tabController;

  // --- STATE VARIABLE ---
  bool _isLoading = false;
  num _totalUtang = 0;
  num _totalPiutang = 0;
  List<Map<String, dynamic>> _listUtang = [];
  List<Map<String, dynamic>> _listPiutang = [];

  // --- THEME DATA ---
  final Color primaryGreen = const Color(0xFF00796B);
  final List<Color> gradientColors = const [Color(0xFF00B493), Color(0xFF00796B)];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _initializeData();
  }

  // --- LOGIKA DATA (TIDAK BERUBAH) ---
  Future<void> _initializeData() async {
    setState(() => _isLoading = true);
    try {
      final userId = _supabase.auth.currentUser?.id;
      if (userId == null) return;

      final response = await _supabase
          .from('debts_credits')
          .select()
          .eq('user_id', userId)
          .eq('is_paid', false)
          .order('created_at', ascending: false);

      final List<dynamic> data = response as List<dynamic>;

      num u = 0, p = 0;
      List<Map<String, dynamic>> lu = [], lp = [];
      for (var item in data) {
        if (item['type'] == 'debt') {
          u += (item['amount'] ?? 0);
          lu.add(item);
        } else {
          p += (item['amount'] ?? 0);
          lp.add(item);
        }
      }
      if (mounted) {
        setState(() {
          _totalUtang = u;
          _totalPiutang = p;
          _listUtang = lu;
          _listPiutang = lp;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  // --- FORMATTER RAPI ---
  String _formatCurrency(num n) {
    return 'Rp ${n.toInt().toString().replaceAllMapped(RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'), (m) => '${m[1]}.')}';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF6F8FB),
      floatingActionButton: FloatingActionButton(
        backgroundColor: primaryGreen,
        onPressed: () async {
          if (await Navigator.push(context, MaterialPageRoute(builder: (_) => const AddUtangPiutangScreen())) == true) {
            _initializeData();
          }
        },
        child: const Icon(Icons.add, color: Colors.white),
      ),
      body: _isLoading
          ? Center(child: CircularProgressIndicator(color: primaryGreen))
          : SingleChildScrollView(
              child: Column(
                children: [
                  _buildHeader(),
                  _buildSummaryCard(),
                  const SizedBox(height: 20),
                  _buildTabBar(),
                  _buildTabContent(),
                ],
              ),
            ),
    );
  }

  // --- KOMPONEN: HEADER MELENGKUNG ---
  Widget _buildHeader() {
  return ClipPath(
    clipper: CustomHeaderClipper(), // Clipper yang sudah disamakan
    child: Container(
      height: 180, // Ditinggikan sedikit agar logo tidak terlalu mepet
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: gradientColors,
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
      ),
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // Logo Dompet
            const Icon(
              Icons.account_balance_wallet_rounded, // Atau gunakan Icons.wallet
              size: 40,
              color: Colors.white,
            ),
            const SizedBox(height: 8), // Jarak antara ikon dan teks
            // Tulisan Buku Keuangan
            const Text(
              "Buku Keuangan",
              style: TextStyle(
                color: Colors.white, 
                fontSize: 20, 
                fontWeight: FontWeight.bold,
                letterSpacing: 0.5,
              ),
            ),
          ],
        ),
      ),
    ),
  );
}

  // --- KOMPONEN: CARD SALDO (Sesuai image_770ad8.png) ---
 Widget _buildSummaryCard() {
  return Padding(
    // Tambahkan top margin di sini (misal 10 atau 20) 
    // agar card turun dari header
    padding: const EdgeInsets.fromLTRB(16, 20, 16, 0), 
    child: Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: primaryGreen,
        borderRadius: BorderRadius.circular(28),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.1), 
            blurRadius: 15, 
            offset: const Offset(0, 8)
          )
        ],
      ),
        child: Column(
          children: [
            const Text("Selisih Saldo Bersih", style: TextStyle(color: Colors.white70, fontSize: 13)),
            const SizedBox(height: 10),
            FittedBox(
              child: Text(_formatCurrency(_totalPiutang - _totalUtang),
                  style: const TextStyle(color: Colors.white, fontSize: 32, fontWeight: FontWeight.w800)),
            ),
            const Divider(color: Colors.white24, height: 30),
            Row(
              children: [
                _buildSummaryIconText("Utang", _totalUtang, Icons.arrow_downward, Colors.red.shade200),
                const SizedBox(width: 20),
                _buildSummaryIconText("Piutang", _totalPiutang, Icons.arrow_upward, Colors.green.shade200),
              ],
            )
          ],
        ),
      ),
    );
  }

  Widget _buildSummaryIconText(String title, num val, IconData icon, Color color) {
    return Expanded(
      child: Row(
        children: [
          CircleAvatar(backgroundColor: Colors.white24, radius: 16, child: Icon(icon, size: 14, color: color)),
          const SizedBox(width: 8),
          Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(title, style: const TextStyle(color: Colors.white70, fontSize: 10)),
            Text(_formatCurrency(val), style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold))
          ])
        ],
      ),
    );
  }

  // --- KOMPONEN: TAB BAR ---
// --- KOMPONEN: TAB BAR REDESIGNED (Clean & Professional) ---
Widget _buildTabBar() {
  return Container(
    margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
    height: 55,
    decoration: BoxDecoration(
      color: Colors.white,
      borderRadius: BorderRadius.circular(20),
      border: Border.all(color: Colors.grey.shade200),
    ),
    child: TabBar(
      controller: _tabController,
      // KONSEP KUNCI: indicatorSize: TabBarIndicatorSize.tab
      // Ini memaksa indikator memenuhi seluruh lebar kotak tab!
      indicatorSize: TabBarIndicatorSize.tab, 
      indicator: BoxDecoration(
        color: const Color(0xFF00796B), // Warna hijau Anda
        borderRadius: BorderRadius.circular(16),
      ),
      // Memberi sedikit ruang agar kotak hijau tidak menempel ke border putih
      indicatorPadding: const EdgeInsets.all(4), 
      
      dividerColor: Colors.transparent, // Menghilangkan garis bawah
      labelColor: Colors.white,
      unselectedLabelColor: Colors.grey.shade600,
      labelStyle: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
      tabs: const [
        Tab(text: "Utang Saya"),
        Tab(text: "Piutang Usaha"),
      ],
    ),
  );
}

  // --- KOMPONEN: DAFTAR TRANSAKSI ---
  Widget _buildTabContent() {
    return SizedBox(
      height: 400,
      child: TabBarView(
        controller: _tabController,
        children: [_buildListItems(_listUtang), _buildListItems(_listPiutang)],
      ),
    );
  }

Widget _buildListItems(List<Map<String, dynamic>> items) {
    if (items.isEmpty) {
      return Center(
        child: Text("Belum ada data", style: TextStyle(color: Colors.grey.shade500)),
      );
    }
return ListView.builder(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      itemCount: items.length,
      itemBuilder: (ctx, idx) {
        final item = items[idx];
        
        // --- MULAI PERUBAHAN ---
        return InkWell(
          onTap: () => _showPaymentDialog(item), // Memicu dialog saat diklik
          borderRadius: BorderRadius.circular(20), // Efek klik mengikuti bentuk card
          child: Container(
            margin: const EdgeInsets.only(bottom: 12),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: Colors.grey.shade100),
            ),
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Row(
                children: [
                  // Ikon Indikator
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: primaryGreen.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(15),
                    ),
                    child: Icon(Icons.receipt_long, color: primaryGreen, size: 24),
                  ),
                  const SizedBox(width: 16),
                  // Informasi Nama & Tanggal
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(item['person_name'], 
                          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                        const SizedBox(height: 4),
                        Text("Tempo: ${item['due_date']}", 
                          style: TextStyle(color: Colors.grey.shade600, fontSize: 12)),
                      ],
                    ),
                  ),
                  // Nominal Uang
                  Text(_formatCurrency(item['amount']), 
                    style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 15, color: Colors.black87)),
                ],
              ),
            ),
          ),
        );
        // --- AKHIR PERUBAHAN ---
      },
    );
  }
}