// lib/features/b3/warga/b3_konfirmasi_screen.dart
//
// W5 · Konfirmasi Pendaftaran B3 (warga) — TAMPILAN SAJA.
// Tombol "Kirim Pendaftaran" belum memanggil backend.
// Alur: W4 Form -> [W5 Konfirmasi] -> W6 Terkirim

import 'package:flutter/material.dart';

import 'b3_form_screen.dart' show B3FormData;
import 'b3_konfirmasi_screen.dart';

class B3KonfirmasiScreen extends StatelessWidget {
  /// Kalau tidak diisi, dipakai data contoh (bisa dibuka sendiri tanpa W4).
  final B3FormData data;

  const B3KonfirmasiScreen({super.key, this.data = const B3FormData()});

  static const _green = Color(0xFF2E7D32);
  static const _greenDark = Color(0xFF1B5E20);
  static const _cream = Color(0xFFFAF4DC);
  static const _card = Color(0xFFFFFDF5);
  static const _iconTile = Color(0xFFE3EFD9);
  static const _warnBg = Color(0xFFF6EBC4);
  static const _warnFg = Color(0xFF7A5B00);

  void _kirim(BuildContext context) {
    // TODO: panggil backend di sini nanti, lalu pindah ke W6 kalau sukses.
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(builder: (_) => B3KonfirmasiScreen(data: data)),
    );
  }

  @override
  Widget build(BuildContext context) {
    final rows = <_Row>[
      _Row(Icons.event_note_rounded, 'Periode', data.periodeLabel),
      _Row(Icons.recycling_rounded, 'Jenis B3', data.jenisText),
      _Row(Icons.scale_outlined, 'Estimasi berat', data.beratText),
      _Row(
        Icons.place_outlined,
        'Alamat jemput',
        '${data.alamat}, ${data.desa}',
      ),
      _Row(Icons.local_shipping_outlined, 'Tanggal jemput', data.tanggalJemput),
      if (data.keterangan.isNotEmpty)
        _Row(Icons.notes_rounded, 'Keterangan', data.keterangan),
    ];

    return Scaffold(
      backgroundColor: _cream,
      appBar: AppBar(
        backgroundColor: _green,
        foregroundColor: Colors.white,
        elevation: 0,
        title: const Text(
          'Konfirmasi Pendaftaran',
          style: TextStyle(fontWeight: FontWeight.w700, fontSize: 18),
        ),
      ),
      body: SafeArea(
        child: Column(
          children: [
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(16),
                child: Column(
                  children: [
                    _summaryCard(rows),
                    const SizedBox(height: 14),
                    _warningBox(),
                  ],
                ),
              ),
            ),
            _actionBar(context),
          ],
        ),
      ),
    );
  }

  Widget _summaryCard(List<_Row> rows) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
      decoration: BoxDecoration(
        color: _card,
        borderRadius: BorderRadius.circular(14),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 10,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Column(
        children: [
          for (var i = 0; i < rows.length; i++) ...[
            _rowTile(rows[i]),
            if (i != rows.length - 1)
              Divider(height: 1, color: _greenDark.withValues(alpha: 0.08)),
          ],
        ],
      ),
    );
  }

  Widget _rowTile(_Row r) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 34,
            height: 34,
            decoration: BoxDecoration(
              color: _iconTile,
              borderRadius: BorderRadius.circular(9),
            ),
            child: Icon(r.icon, size: 18, color: _green),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  r.label,
                  style: TextStyle(
                    fontSize: 11,
                    color: _greenDark.withValues(alpha: 0.55),
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  r.value,
                  style: const TextStyle(
                    fontSize: 13.5,
                    fontWeight: FontWeight.w700,
                    color: _greenDark,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _warningBox() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: _warnBg,
        borderRadius: BorderRadius.circular(12),
      ),
      child: const Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(Icons.warning_amber_rounded, size: 20, color: _warnFg),
          SizedBox(width: 10),
          Expanded(
            child: Text(
              'Kemas B3 terpisah dari sampah lain, jangan dicampur, dan '
              'siapkan di depan rumah pada hari penjemputan. '
              'Barang akan ditimbang petugas.',
              style: TextStyle(fontSize: 12, height: 1.45, color: _warnFg),
            ),
          ),
        ],
      ),
    );
  }

  Widget _actionBar(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 14),
      color: _cream,
      child: Row(
        children: [
          Expanded(
            flex: 2,
            child: SizedBox(
              height: 52,
              child: OutlinedButton(
                onPressed: () => Navigator.pop(context),
                style: OutlinedButton.styleFrom(
                  foregroundColor: _greenDark,
                  backgroundColor: _card,
                  side: BorderSide(color: _green.withValues(alpha: 0.4)),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(26),
                  ),
                ),
                child: const Text(
                  'Ubah',
                  style: TextStyle(fontWeight: FontWeight.w700),
                ),
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            flex: 3,
            child: SizedBox(
              height: 52,
              child: ElevatedButton(
                onPressed: () => _kirim(context),
                style: ElevatedButton.styleFrom(
                  backgroundColor: _green,
                  foregroundColor: Colors.white,
                  elevation: 0,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(26),
                  ),
                ),
                child: const Text(
                  'Kirim Pendaftaran',
                  style: TextStyle(fontSize: 14, fontWeight: FontWeight.w700),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _Row {
  final IconData icon;
  final String label;
  final String value;
  const _Row(this.icon, this.label, this.value);
}