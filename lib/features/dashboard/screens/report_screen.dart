import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';

class ReportScreen extends StatelessWidget {
  final String businessName;
  final String ownerName;
  final int selectedYear;
  final List<Map<String, dynamic>> transactions;
  final double totalIncome;
  final double totalExpense;
  final double totalBalance;

  // Memperbaiki 'key' ke format modern (super.key) agar warning hilang
  const ReportScreen({
    super.key,
    required this.businessName,
    required this.ownerName,
    required this.selectedYear,
    required this.transactions,
    required this.totalIncome,
    required this.totalExpense,
    required this.totalBalance,
  });

  String _formatPdfRupiah(double amount) {
    return 'Rp ${amount.toInt().toString().replaceAllMapped(RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'), (Match m) => '${m[1]}.')}';
  }

  Future<Uint8List> _generatePdf(PdfPageFormat format) async {
    final pdf = pw.Document(title: 'Laporan Keuangan $businessName');

    pdf.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.all(36),
        build: (pw.Context context) {
          return [
            // 1. HEADER LAPORAN FORMAL
            pw.Row(
              mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
              crossAxisAlignment: pw.CrossAxisAlignment.center,
              children: [
                pw.Column(
                  crossAxisAlignment: pw.CrossAxisAlignment.start, // Diperbaiki dari crosspw
                  children: [
                    pw.Text(
                      'LAPORAN KEUANGAN DOMPET UMKM',
                      style: pw.TextStyle(fontSize: 11, fontWeight: pw.FontWeight.bold, color: PdfColors.grey700),
                    ),
                    pw.SizedBox(height: 4),
                    pw.Text(
                      businessName.toUpperCase(),
                      style: pw.TextStyle(fontSize: 22, fontWeight: pw.FontWeight.bold, color: PdfColors.teal800),
                    ),
                    pw.Text('Pemilik: $ownerName', style: const pw.TextStyle(fontSize: 10, color: PdfColors.grey600)),
                  ],
                ),
                pw.Column(
                  crossAxisAlignment: pw.CrossAxisAlignment.end, // Diperbaiki dari crosspw
                  children: [
                    pw.Text('Periode Laporan', style: const pw.TextStyle(fontSize: 9, color: PdfColors.grey500)),
                    pw.Text('Tahun $selectedYear', style: pw.TextStyle(fontSize: 12, fontWeight: pw.FontWeight.bold, color: PdfColors.teal800)),
                    pw.SizedBox(height: 2),
                    pw.Text('Cetak: ${DateTime.now().day}/${DateTime.now().month}/${DateTime.now().year}', style: const pw.TextStyle(fontSize: 9, color: PdfColors.grey600)),
                  ],
                ),
              ],
            ),
            pw.SizedBox(height: 10),
            pw.Divider(thickness: 2, color: PdfColors.teal800),
            pw.SizedBox(height: 16),

            // 2. RINGKASAN KEUANGAN TAHUNAN
            pw.Text('Ringkasan Keuangan Tahunan', style: pw.TextStyle(fontSize: 13, fontWeight: pw.FontWeight.bold)),
            pw.SizedBox(height: 8),
            pw.Row(
              children: [
                _buildPdfSummaryCard('Total Pemasukan', _formatPdfRupiah(totalIncome), PdfColors.green50, PdfColors.green700),
                pw.SizedBox(width: 12),
                _buildPdfSummaryCard('Total Pengeluaran', _formatPdfRupiah(totalExpense), PdfColors.red50, PdfColors.red700),
                pw.SizedBox(width: 12),
                _buildPdfSummaryCard('Saldo Akhir', _formatPdfRupiah(totalBalance), PdfColors.teal50, PdfColors.teal800),
              ],
            ),
            pw.SizedBox(height: 24),

            // 3. TABEL DATA TRANSAKSI UTAMA DENGAN ZEBRA STRIPING (Mendukung Banyak Halaman)
            pw.Text('Detail Riwayat Transaksi:', style: pw.TextStyle(fontSize: 13, fontWeight: pw.FontWeight.bold)),
            pw.SizedBox(height: 8),
            pw.Table(
              border: const pw.TableBorder(
                horizontalInside: pw.BorderSide(color: PdfColors.grey200, width: 0.5),
                bottom: pw.BorderSide(color: PdfColors.grey300, width: 1),
              ),
              columnWidths: const {
                0: pw.FlexColumnWidth(2), // Tanggal
                1: pw.FlexColumnWidth(4), // Kategori / Keterangan
                2: pw.FlexColumnWidth(2), // Tipe
                3: pw.FlexColumnWidth(3), // Jumlah
              },
              children: [
                // Header Tabel
                pw.TableRow(
                  decoration: const pw.BoxDecoration(color: PdfColors.teal800),
                  children: [
                    _buildTableCell('Tanggal', isHeader: true),
                    _buildTableCell('Kategori / Keterangan', isHeader: true),
                    _buildTableCell('Tipe', isHeader: true),
                    _buildTableCell('Jumlah', isHeader: true, alignRight: true),
                  ],
                ),
                // Isi Baris Transaksi Dinamis
                if (transactions.isEmpty)
                  pw.TableRow(
                    children: [
                      _buildTableCell('-'),
                      _buildTableCell('Tidak ada data transaksi di tahun ini', textColor: PdfColors.grey500),
                      _buildTableCell('-'),
                      _buildTableCell('-', alignRight: true),
                    ],
                  )
                else
                  ...List.generate(transactions.length, (index) {
                    final tx = transactions[index];
                    final isIncome = tx['type'] == 'income';
                    final rowColor = index % 2 == 0 ? PdfColors.white : PdfColors.grey50;

                    String tgl = '-';
                    if (tx['created_at'] != null) {
                      try {
                        DateTime dt = DateTime.parse(tx['created_at'].toString());
                        tgl = '${dt.day}/${dt.month}/${dt.year}';
                      } catch (_) {}
                    }

                    double amt = 0.0;
                    if (tx['amount'] is num) {
                      amt = (tx['amount'] as num).toDouble();
                    } else {
                      amt = double.tryParse(tx['amount'].toString()) ?? 0.0;
                    }

                    return pw.TableRow(
                      decoration: pw.BoxDecoration(color: rowColor),
                      children: [
                        _buildTableCell(tgl),
                        _buildTableCell(tx['category'] ?? tx['notes'] ?? 'Tanpa Keterangan'),
                        _buildTableCell(isIncome ? 'Masuk' : 'Keluar', textColor: isIncome ? PdfColors.green700 : PdfColors.red700),
                        _buildTableCell(
                          '${isIncome ? '+' : '-'} ${_formatPdfRupiah(amt)}',
                          alignRight: true,
                          textColor: isIncome ? PdfColors.green700 : PdfColors.grey800,
                        ),
                      ],
                    );
                  }),
              ],
            ),
          ];
        },
      ),
    );

    return pdf.save();
  }

  pw.Widget _buildPdfSummaryCard(String title, String value, PdfColor bgColor, PdfColor textColor) {
    return pw.Expanded(
      child: pw.Container(
        padding: const pw.EdgeInsets.all(12),
        decoration: pw.BoxDecoration(
          color: bgColor,
          borderRadius: pw.BorderRadius.circular(6),
        ),
        child: pw.Column(
          crossAxisAlignment: pw.CrossAxisAlignment.start, // Diperbaiki dari crosspw
          children: [
            pw.Text(title, style: const pw.TextStyle(fontSize: 9, color: PdfColors.grey600)),
            pw.SizedBox(height: 4),
            pw.Text(value, style: pw.TextStyle(fontSize: 12, fontWeight: pw.FontWeight.bold, color: textColor)),
          ],
        ),
      ),
    );
  }

  pw.Widget _buildTableCell(String text, {bool isHeader = false, bool alignRight = false, PdfColor? textColor}) {
    return pw.Padding(
      padding: const pw.EdgeInsets.symmetric(horizontal: 8, vertical: 8),
      child: pw.Container(
        alignment: alignRight ? pw.Alignment.centerRight : pw.Alignment.centerLeft,
        child: pw.Text(
          text,
          style: pw.TextStyle(
            fontSize: isHeader ? 10 : 9,
            fontWeight: isHeader ? pw.FontWeight.bold : pw.FontWeight.normal,
            color: isHeader ? PdfColors.white : (textColor ?? PdfColors.grey800),
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Cetak Laporan PDF', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
        backgroundColor: Colors.white,
        foregroundColor: const Color(0xFF1F2937),
        elevation: 0.5,
      ),
      backgroundColor: const Color(0xFFF9FAFB),
      body: PdfPreview(
        maxPageWidth: 600,
        build: (format) => _generatePdf(format),
        allowSharing: true,
        allowPrinting: true,
        canChangePageFormat: false,
        loadingWidget: const Center(child: CircularProgressIndicator(color: Colors.teal)),
        pdfPreviewPageDecoration: const BoxDecoration(color: Colors.transparent),
      ),
    );
  }
}