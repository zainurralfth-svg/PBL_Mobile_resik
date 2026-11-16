// lib/features/b3/petugas/b3_ringkasan_screen.dart
// P6 · Ringkasan Muatan (petugas) — tersambung ke API:
//   GET  /api/petugas/b3-muatan?id_petugas=..      (ringkasan & muatan per jenis)
//   POST /api/petugas/b3-rute/selesai              (tombol "Selesaikan Rute")
// Muatan per jenis dihitung dalam jumlah item (pcs): berat tersimpan per warga, bukan per jenis.
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import '../../../config/api_config.dart';
import 'petugas_session.dart';

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
  final String jenis;
  final int warga;
  final int jumlah;
  const _Muatan(this.jenis, this.warga, this.jumlah);

  IconData get ikon {
    final j = jenis.toLowerCase();
    if (j.contains('baterai') || j.contains('aki')) return Icons.battery_full;
    if (j.contains('lampu')) return Icons.lightbulb_outline;
    if (j.contains('elektronik')) return Icons.memory;
    if (j.contains('obat')) return Icons.medication_outlined;
    if (j.contains('cat')) return Icons.format_paint_outlined;
    return Icons.inventory_2_outlined;
  }
}

class B3RingkasanScreen extends StatefulWidget {
  /// Nilai awal sebelum data dari server tiba (opsional).
  final int dijemput;
  final int totalWarga;

  const B3RingkasanScreen({
    super.key,
    this.dijemput = 0,
    this.totalWarga = 0,
  });

  @override
  State<B3RingkasanScreen> createState() => _B3RingkasanScreenState();
}

class _B3RingkasanScreenState extends State<B3RingkasanScreen> {
  bool _loading = true;
  bool _menyelesaikan = false;
  String? _error;
  late int _dijemput = widget.dijemput;
  late int _totalWarga = widget.totalWarga;
  double _beratAktual = 0;
  List<_Muatan> _muatan = [];

  int get _totalItem => _muatan.fold(0, (a, m) => a + m.jumlah);

  @override
  void initState() {
    super.initState();
    _muat();
  }

  void _snack(String pesan) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(pesan)));
  }

  Future<void> _muat() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final idPetugas = await PetugasSession.getId();
      if (idPetugas == null) {
        throw 'Sesi petugas tidak ditemukan. Silakan login ulang.';
      }
      final res = await http
          .get(Uri.parse('${ApiConfig.petugasB3Muatan}?id_petugas=$idPetugas'), headers: ApiConfig.headers)
          .timeout(const Duration(seconds: 15));
      if (res.statusCode != 200) {
        throw 'Gagal memuat ringkasan (${res.statusCode}).';
      }
      final data = json.decode(res.body)['data'];
      final list = (data['muatan'] as List? ?? [])
          .map((m) => _Muatan(
                (m['jenis'] ?? '-').toString(),
                int.tryParse(m['warga'].toString()) ?? 0,
                int.tryParse(m['jumlah'].toString()) ?? 0,
              ))
          .toList();
      if (!mounted) return;
      setState(() {
        _dijemput = int.tryParse(data['dijemput'].toString()) ?? 0;
        _totalWarga = int.tryParse(data['total_warga'].toString()) ?? 0;
        _beratAktual = double.tryParse(data['berat_aktual'].toString()) ?? 0;
        _muatan = list;
        _loading = false;
      });
    } catch (e) {
      debugPrint('Error muat ringkasan: $e');
      if (!mounted) return;
      setState(() {
        _error = e is String ? e : 'Tidak dapat terhubung ke server.';
        _loading = false;
      });
    }
  }

  Future<void> _selesaikanRute() async {
    final idPetugas = await PetugasSession.getId();
    if (idPetugas == null) {
      _snack('Sesi petugas tidak ditemukan. Silakan login ulang.');
      return;
    }
    setState(() => _menyelesaikan = true);
    try {
      final res = await http
          .post(
            Uri.parse(ApiConfig.petugasB3RuteSelesai),
            headers: ApiConfig.headers,
            body: json.encode({'id_petugas': idPetugas}),
          )
          .timeout(const Duration(seconds: 15));
      var msg = res.statusCode == 200 ? 'Rute berhasil diselesaikan.' : 'Gagal menyelesaikan rute (${res.statusCode}).';
      try {
        msg = (json.decode(res.body)['message'] ?? msg).toString();
      } catch (_) {}
      _snack(msg);
      if (res.statusCode == 200) await _muat();
    } catch (e) {
      debugPrint('Error selesaikan rute: $e');
      _snack('Tidak dapat terhubung ke server.');
    } finally {
      if (mounted) setState(() => _menyelesaikan = false);
    }
  }

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
            child: _loading
                ? const Center(child: CircularProgressIndicator(color: _C.green))
                : _error != null
                    ? Center(
                        child: Padding(
                          padding: const EdgeInsets.all(24),
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Text(_error!, textAlign: TextAlign.center, style: const TextStyle(color: _C.muted)),
                              const SizedBox(height: 12),
                              OutlinedButton(onPressed: _muat, child: const Text('Coba lagi')),
                            ],
                          ),
                        ),
                      )
                    : RefreshIndicator(
                        color: _C.green,
                        onRefresh: _muat,
                        child: SingleChildScrollView(
                          physics: const AlwaysScrollableScrollPhysics(),
                          padding: const EdgeInsets.all(16),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  Expanded(child: _statKartu('$_dijemput / $_totalWarga', 'Warga dijemput', _C.olive)),
                                  const SizedBox(width: 12),
                                  Expanded(child: _statKartu('${_kg(_beratAktual)} kg', 'Berat aktual', _C.biru)),
                                ],
                              ),
                              const SizedBox(height: 20),
                              Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  const Text(
                                    'Muatan per Jenis',
                                    style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: _C.green),
                                  ),
                                  Text('Total $_totalItem item', style: const TextStyle(fontSize: 11, color: _C.muted)),
                                ],
                              ),
                              const SizedBox(height: 10),
                              _daftarMuatan(),
                              const SizedBox(height: 14),
                              _catatan(),
                            ],
                          ),
                        ),
                      ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
            child: SizedBox(
              width: double.infinity,
              height: 48,
              child: ElevatedButton(
                onPressed: (_loading || _menyelesaikan) ? null : _selesaikanRute,
                style: ElevatedButton.styleFrom(
                  backgroundColor: _C.green,
                  foregroundColor: Colors.white,
                  elevation: 0,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
                ),
                child: _menyelesaikan
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2.5),
                      )
                    : const Text('Selesaikan Rute', style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold)),
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
      decoration: BoxDecoration(color: warna, borderRadius: BorderRadius.circular(14)),
      child: Column(
        children: [
          Text(nilai, style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: _C.green)),
          const SizedBox(height: 2),
          Text(label, style: const TextStyle(fontSize: 11, color: _C.muted)),
        ],
      ),
    );
  }

  Widget _daftarMuatan() {
    if (_muatan.isEmpty) {
      return Container(
        width: double.infinity,
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: _C.card,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: _C.divider),
        ),
        child: const Text(
          'Belum ada barang yang dijemput.',
          textAlign: TextAlign.center,
          style: TextStyle(fontSize: 12, color: _C.muted),
        ),
      );
    }
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
            if (i < _muatan.length - 1) const Divider(height: 1, color: _C.divider),
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
            decoration: BoxDecoration(color: _C.iconBg, borderRadius: BorderRadius.circular(8)),
            child: Icon(m.ikon, size: 17, color: _C.green),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(m.jenis, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: _C.green)),
                Text('${m.warga} warga', style: const TextStyle(fontSize: 10.5, color: _C.muted)),
              ],
            ),
          ),
          Text('${m.jumlah} item', style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: _C.green)),
        ],
      ),
    );
  }

  Widget _catatan() {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(color: _C.note, borderRadius: BorderRadius.circular(12)),
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