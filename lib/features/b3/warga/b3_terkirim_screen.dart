// lib/features/b3/warga/b3_terkirim_screen.dart
//
// W6 · Pendaftaran Terkirim (warga) — TAMPILAN SAJA.
// Nomor pendaftaran & status masih contoh (belum dari backend).
// Alur: W5 Konfirmasi -> [W6 Terkirim] -> Riwayat B3 / Beranda

import 'package:flutter/material.dart';

import 'b3_form_screen.dart' show B3FormData;

class B3TerkirimScreen extends StatelessWidget {
  /// Kalau tidak diisi, dipakai data contoh (bisa dibuka sendiri).
  final B3FormData data;

  /// Contoh. Nanti diisi dari response backend.
  final String noPendaftaran;
  final String status;

  const B3TerkirimScreen({
    super.key,
    this.data = const B3FormData(),
    this.noPendaftaran = '#B3-00021',
    this.status = 'Terdaftar',
  });

  static const _green = Color(0xFF2E7D32);
  static const _greenDark = Color(0xFF1B5E20);
  static const _cream = Color(0xFFFAF4DC);
  static const _card = Color(0xFFFFFDF5);
  static const _badgeBg = Color(0xFFEAE4BE);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _cream,
      body: SafeArea(
        child: Column(
          children: [
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(16, 56, 16, 16),
                child: Column(
                  children: [
                    _checkIcon(),
                    const SizedBox(height: 22),
                    const Text(
                      'Pendaftaran Terkirim',
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.w800,
                        color: _greenDark,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Petugas DLH akan menjemput pada',
                      style: TextStyle(
                        fontSize: 12.5,
                        color: _greenDark.withValues(alpha: 0.65),
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      data.tanggalJemput,
                      style: const TextStyle(
                        fontSize: 13.5,
                        fontWeight: FontWeight.w800,
                        color: _greenDark,
                      ),
                    ),
                    const SizedBox(height: 28),
                    _summaryCard(),
                  ],
                ),
              ),
            ),
            _actions(context),
          ],
        ),
      ),
    );
  }

  Widget _checkIcon() {
    return Container(
      width: 124,
      height: 124,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: _green.withValues(alpha: 0.12),
      ),
      child: Container(
        width: 92,
        height: 92,
        decoration: const BoxDecoration(shape: BoxShape.circle, color: _green),
        child: const Icon(Icons.check_rounded, size: 52, color: Colors.white),
      ),
    );
  }

  Widget _summaryCard() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
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
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'No. Pendaftaran',
                      style: TextStyle(
                        fontSize: 11,
                        color: _greenDark.withValues(alpha: 0.55),
                      ),
                    ),
                    const SizedBox(height: 3),
                    Text(
                      noPendaftaran,
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w800,
                        color: _greenDark,
                      ),
                    ),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
                decoration: BoxDecoration(
                  color: _badgeBg,
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Text(
                  status,
                  style: const TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                    color: _greenDark,
                  ),
                ),
              ),
            ],
          ),
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 12),
            child: Divider(height: 1, color: _greenDark.withValues(alpha: 0.1)),
          ),
          Row(
            children: [
              const Icon(Icons.recycling_rounded, size: 18, color: _green),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  '${data.jenisText} · Est. ${data.beratText}',
                  style: const TextStyle(fontSize: 12.5, color: _greenDark),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _actions(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 14),
      color: _cream,
      child: Column(
        children: [
          SizedBox(
            width: double.infinity,
            height: 52,
            child: ElevatedButton(
              onPressed: () {
                // TODO: arahkan ke Riwayat B3 (W7) nanti.
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: _green,
                foregroundColor: Colors.white,
                elevation: 0,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(26),
                ),
              ),
              child: const Text(
                'Lihat Status',
                style: TextStyle(fontSize: 14.5, fontWeight: FontWeight.w700),
              ),
            ),
          ),
          const SizedBox(height: 10),
          SizedBox(
            width: double.infinity,
            height: 52,
            child: OutlinedButton(
              // Sementara: tutup semua halaman B3, balik ke halaman pertama.
              onPressed: () => Navigator.popUntil(context, (r) => r.isFirst),
              style: OutlinedButton.styleFrom(
                foregroundColor: _greenDark,
                backgroundColor: _card,
                side: BorderSide(color: _green.withValues(alpha: 0.4)),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(26),
                ),
              ),
              child: const Text(
                'Kembali ke Beranda',
                style: TextStyle(fontSize: 14.5, fontWeight: FontWeight.w700),
              ),
            ),
          ),
        ],
      ),
    );
  }
}