// lib/features/b3/petugas/b3_ringkasan_screen.dart
// P6 · Ringkasan Muatan (petugas) — TAMPILAN SAJA.
// Angka di bawah masih contoh; sambungkan ke API setelah backend petugas jadi.
import 'package:flutter/material.dart';

class _C {
  static const green = Color(0xFF2D6A1E);
  static const cream = Color(0xFFFFF8E1);
  static const card = Color(0xFFFFFCF0);
  static const olive = Color(0xFFE8E2B5);
  static const biru = Color(0xFFDCE8F5);
  static const iconBg = Color(0xFFE3EDCF);
  static const divider = Color(0xFFE9E3C8);
  static const note = Color(0xFFF6E7B8);
  static const noteText = Color(0xFF7A6420);
  static const text = Color(0xFF2B2B2B);
  static const muted = Color(0xFF6B6B6B);
}

class _Muatan {
  final IconData ikon;
  final String jenis;
  final int warga;
  final double kg;
  const _Muatan(this.ikon, this.jenis, this.warga, this.kg);
}

class B3RingkasanScreen extends StatelessWidget {
  final int dijemput;
  final int totalWarga;

  const B3RingkasanScreen({
    super.key,
    this.dijemput = 3,
    this.totalWarga = 8,
  });

  // Contoh data. Nanti diganti hasil API (dikelompokkan per jenis).
  static const List<_Muatan> _muatan = [
    _Muatan(Icons.battery_full, 'Baterai', 2, 5.0),
    _Muatan(Icons.lightbulb_outline, 'Lampu', 1, 3.5),
    _Muatan(Icons.memory, 'Elektronik', 1, 2.0),
    _Muatan(Icons.medication_outlined, 'Obat Kedaluwarsa', 1, 1.0),
  ];

  double get _totalKg => _muatan.fold(0.0, (a, m) => a + m.kg);

  String _kg(double v) => v.toStringAsFixed(1);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _C.cream,
      appBar: AppBar(
        backgroundColor: _C.green,
        foregroundColor: Colors.white,
        elevation: 0,
        titleSpacing: 0,
        title: const Text(
          'Ringkasan Muatan',
          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
        ),
      ),
      body: Column(
        children: [
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: _statKartu(
                          '$dijemput / $totalWarga',
                          'Warga dijemput',
                          _C.olive,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: _statKartu(
                          '${_kg(_totalKg)} kg',
                          'Berat aktual',
                          _C.biru,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 20),
                  const Text(
                    'Muatan per Jenis',
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.bold,
                      color: _C.green,
                    ),
                  ),
                  const SizedBox(height: 10),
                  _daftarMuatan(),
                  const SizedBox(height: 14),
                  _catatan(),
                ],
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
            child: SizedBox(
              width: double.infinity,
              height: 48,
              child: ElevatedButton(
                onPressed: () {
                  // TODO: kirim "selesaikan rute" ke API petugas.
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Rute selesai (contoh).')),
                  );
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: _C.green,
                  foregroundColor: Colors.white,
                  elevation: 0,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(24),
                  ),
                ),
                child: const Text(
                  'Selesaikan Rute',
                  style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold),
                ),
              ),
            ),
          ),
          const _BarBawahPetugas(),
        ],
      ),
    );
  }

  Widget _statKartu(String nilai, String label, Color warna) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 16),
      decoration: BoxDecoration(
        color: warna,
        borderRadius: BorderRadius.circular(14),
      ),
      child: Column(
        children: [
          Text(
            nilai,
            style: const TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: _C.green,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            label,
            style: const TextStyle(fontSize: 11, color: _C.muted),
          ),
        ],
      ),
    );
  }

  Widget _daftarMuatan() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 4),
      decoration: BoxDecoration(
        color: _C.card,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: _C.divider),
      ),
      child: Column(
        children: [
          for (int i = 0; i < _muatan.length; i++) ...[
            _barisMuatan(_muatan[i]),
            if (i < _muatan.length - 1)
              const Divider(height: 1, color: _C.divider),
          ],
        ],
      ),
    );
  }

  Widget _barisMuatan(_Muatan m) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 10),
      child: Row(
        children: [
          Container(
            width: 30,
            height: 30,
            decoration: BoxDecoration(
              color: _C.iconBg,
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(m.ikon, size: 17, color: _C.green),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  m.jenis,
                  style: const TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.bold,
                    color: _C.green,
                  ),
                ),
                Text(
                  '${m.warga} warga',
                  style: const TextStyle(fontSize: 10.5, color: _C.muted),
                ),
              ],
            ),
          ),
          Text(
            '${_kg(m.kg)} kg',
            style: const TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.bold,
              color: _C.green,
            ),
          ),
        ],
      ),
    );
  }

  Widget _catatan() {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: _C.note,
        borderRadius: BorderRadius.circular(12),
      ),
      child: const Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(Icons.info_outline, size: 16, color: _C.noteText),
          SizedBox(width: 8),
          Expanded(
            child: Text(
              'Serah terima ke pengolah dicatat admin di web (tab Rekap › '
              'Catat Serah Terima). Verifikasi akhir juga dilakukan admin.',
              style: TextStyle(fontSize: 10.5, color: _C.noteText, height: 1.4),
            ),
          ),
        ],
      ),
    );
  }
}

/// Bar bawah petugas: Home · Scan · Penjemputan (aktif) · Riwayat.
/// TAMPILAN SAJA — tombol belum berpindah halaman.
class _BarBawahPetugas extends StatelessWidget {
  const _BarBawahPetugas();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
      decoration: const BoxDecoration(
        color: _C.card,
        border: Border(top: BorderSide(color: _C.divider)),
      ),
      child: SafeArea(
        top: false,
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            _ikon(Icons.home_outlined),
            _ikon(Icons.qr_code_scanner),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 10),
              decoration: BoxDecoration(
                color: _C.green,
                borderRadius: BorderRadius.circular(24),
              ),
              child: const Row(
                children: [
                  Icon(Icons.local_shipping_outlined,
                      size: 18, color: Colors.white),
                  SizedBox(width: 6),
                  Text(
                    'Penjemputan',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            ),
            _ikon(Icons.history),
          ],
        ),
      ),
    );
  }

  Widget _ikon(IconData i) => Padding(
        padding: const EdgeInsets.all(6),
        child: Icon(i, size: 22, color: _C.green),
      );
}