// lib/features/b3/warga/b3_detail_screen.dart
import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;

import '../../../config/api_config.dart';

/// Ubah ke false setelah endpoint detail B3 siap.
const bool kB3DetailUseDummy = false;

class _C {
  static const green = Color(0xFF2D6A1E);
  static const cream = Color(0xFFFFF8E1);
  static const card = Color(0xFFFFFCF0);
  static const iconBg = Color(0xFFE3EDCF);
  static const muted = Color(0xFF6B6B6B);
  static const pending = Color(0xFFE2DDB9);
  static const pendingText = Color(0xFF9A9777);
  static const divider = Color(0xFFE9E3C8);
  static const red = Color(0xFFB3261E);
}

enum B3DetailStatus {
  terdaftar,
  dijadwalkan,
  menungguVerifikasi,
  diverifikasi,
  tidakSesuai,
}

class B3Detail {
  final String noPendaftaran;
  final String jenis;
  final String estimasiBerat;
  final String alamat;
  final String jadwalJemput;
  final String petugas;
  final String tanggalDaftar;
  final String tanggalDijadwalkan;
  final String? beratDijemput;
  final String? tanggalDijemput;
  final String? tanggalDiperiksa;
  final B3DetailStatus status;
  final String? alasan;

  const B3Detail({
    required this.noPendaftaran,
    required this.jenis,
    required this.estimasiBerat,
    required this.alamat,
    required this.jadwalJemput,
    required this.petugas,
    required this.tanggalDaftar,
    required this.tanggalDijadwalkan,
    required this.status,
    this.beratDijemput,
    this.tanggalDijemput,
    this.tanggalDiperiksa,
    this.alasan,
  });

  factory B3Detail.fromJson(Map<String, dynamic> j) {
    final jenis = j['jenis'];
    B3DetailStatus st;
    switch ('${j['status']}'.toLowerCase().trim().replaceAll(' ', '_')) {
      case 'diverifikasi':
        st = B3DetailStatus.diverifikasi;
        break;
      case 'tidak_sesuai':
      case 'ditolak':
        st = B3DetailStatus.tidakSesuai;
        break;
      case 'terdaftar':
        st = B3DetailStatus.terdaftar;
        break;
      case 'menunggu_verifikasi':
        st = B3DetailStatus.menungguVerifikasi;
        break;
      default:
        st = B3DetailStatus.dijadwalkan;
    }
    return B3Detail(
      noPendaftaran: '${j['no_pendaftaran'] ?? '-'}',
      jenis: jenis is List ? jenis.join(', ') : '${jenis ?? '-'}',
      estimasiBerat: '${j['estimasi_berat'] ?? '-'} kg',
      alamat: '${j['alamat'] ?? '-'}',
      jadwalJemput: '${j['jadwal_jemput'] ?? '-'}',
      petugas: '${j['petugas'] ?? '-'}',
      tanggalDaftar: '${j['tanggal_daftar'] ?? '-'}',
      tanggalDijadwalkan: '${j['tanggal_dijadwalkan'] ?? '-'}',
      status: st,
      beratDijemput: j['berat_dijemput'] == null
          ? null
          : '${j['berat_dijemput']} kg',
      tanggalDijemput: j['tanggal_dijemput']?.toString(),
      tanggalDiperiksa: j['tanggal_diperiksa']?.toString(),
      alasan: j['alasan']?.toString(),
    );
  }
}

class B3DetailScreen extends StatefulWidget {
  /// ID pendaftaran B3 (dipakai saat mengambil data dari API).
  final int idB3;

  const B3DetailScreen({super.key, required this.idB3});

  @override
  State<B3DetailScreen> createState() => _B3DetailScreenState();
}

class _B3DetailScreenState extends State<B3DetailScreen> {
  B3Detail? _data;
  bool _loading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      if (kB3DetailUseDummy) {
        await Future.delayed(const Duration(milliseconds: 300));
        _data = _dummyDetail(widget.idB3);
      } else {
        final res = await http
            .get(
              Uri.parse('${ApiConfig.baseUrl}/b3/${widget.idB3}'),
              headers: ApiConfig.headers,
            )
            .timeout(const Duration(seconds: 10));
        final body = jsonDecode(res.body);
        if (res.statusCode == 200 && body['status'] == 'success') {
          _data = B3Detail.fromJson(body['data'] as Map<String, dynamic>);
        } else {
          throw body['message'] ?? 'Gagal memuat data';
        }
      }
    } catch (e) {
      _error = '$e';
    }
    if (mounted) setState(() => _loading = false);
  }

  /// Data contoh. ID mengikuti data contoh di Riwayat B3:
  /// 1 = Dijadwalkan, 2 = Diverifikasi, 3 = Tidak sesuai.
  B3Detail _dummyDetail(int id) {
    switch (id) {
      case 2:
        return const B3Detail(
          noPendaftaran: '#B3-00018',
          jenis: 'Baterai',
          estimasiBerat: '3 kg',
          beratDijemput: '3.5 kg',
          alamat: 'Jl. Wilangan Kulon No. 12, Desa Bagor',
          jadwalJemput: 'Senin, 28 Sep 2026',
          petugas: 'Budi Santoso',
          tanggalDaftar: '14 Sep 2026 · 10:30',
          tanggalDijadwalkan: '22 Sep 2026',
          tanggalDijemput: '28 Sep 2026',
          tanggalDiperiksa: '29 Sep 2026',
          status: B3DetailStatus.diverifikasi,
        );
      case 3:
        return const B3Detail(
          noPendaftaran: '#B3-00014',
          jenis: 'Obat Kedaluwarsa',
          estimasiBerat: '2 kg',
          beratDijemput: '1.5 kg',
          alamat: 'Jl. Wilangan Kulon No. 12, Desa Bagor',
          jadwalJemput: 'Senin, 31 Agu 2026',
          petugas: 'Budi Santoso',
          tanggalDaftar: '25 Agu 2026 · 09:12',
          tanggalDijadwalkan: '28 Agu 2026',
          tanggalDijemput: '31 Agu 2026',
          tanggalDiperiksa: '1 Sep 2026',
          status: B3DetailStatus.tidakSesuai,
          alasan:
              'Terdapat sampah non-B3 (organik) yang tercampur dalam kemasan.',
        );
      default:
        return const B3Detail(
          noPendaftaran: '#B3-00021',
          jenis: 'Baterai, Lampu',
          estimasiBerat: '4 kg',
          alamat: 'Jl. Wilangan Kulon No. 12, Desa Bagor',
          jadwalJemput: 'Kamis, 29 Okt 2026',
          petugas: 'Budi Santoso',
          tanggalDaftar: '18 Okt 2026 · 22:05',
          tanggalDijadwalkan: '26 Okt 2026',
          status: B3DetailStatus.dijadwalkan,
        );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _C.cream,
      body: Column(
        children: [
          _header(context),
          Expanded(child: _body()),
        ],
      ),
      bottomNavigationBar: _data?.status == B3DetailStatus.tidakSesuai
          ? _packingButton()
          : null,
    );
  }

  Widget _packingButton() {
    return SafeArea(
      top: false,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
        child: SizedBox(
          width: double.infinity,
          height: 48,
          child: OutlinedButton(
            style: OutlinedButton.styleFrom(
              foregroundColor: _C.green,
              backgroundColor: _C.card,
              side: const BorderSide(color: _C.green, width: 1.2),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10),
              ),
            ),
            onPressed: () {
              // TODO: arahkan ke B3InfoScreen (cara mengemas B3) jika sudah dibuat
              // Navigator.push(context,
              //     MaterialPageRoute(builder: (_) => const B3InfoScreen()));
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Halaman panduan belum tersedia')),
              );
            },
            child: const Text(
              'Lihat Cara Mengemas B3',
              style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700),
            ),
          ),
        ),
      ),
    );
  }

  Widget _header(BuildContext context) {
    return Container(
      width: double.infinity,
      color: _C.green,
      padding: EdgeInsets.fromLTRB(
        8,
        MediaQuery.of(context).padding.top + 8,
        16,
        14,
      ),
      child: Row(
        children: [
          IconButton(
            icon: const Icon(Icons.arrow_back, color: Colors.white),
            onPressed: () => Navigator.maybePop(context),
          ),
          const SizedBox(width: 2),
          const Text(
            'Detail Pendaftaran',
            style: TextStyle(
              color: Colors.white,
              fontSize: 18,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }

  Widget _body() {
    if (_loading) {
      return const Center(child: CircularProgressIndicator(color: _C.green));
    }
    if (_error != null || _data == null) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.error_outline, size: 48, color: _C.muted),
            const SizedBox(height: 10),
            Text(
              _error ?? 'Data tidak ditemukan',
              style: const TextStyle(color: _C.muted),
            ),
            const SizedBox(height: 12),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: _C.green,
                foregroundColor: Colors.white,
              ),
              onPressed: _load,
              child: const Text('Coba lagi'),
            ),
          ],
        ),
      );
    }

    final d = _data!;
    return RefreshIndicator(
      color: _C.green,
      onRefresh: _load,
      child: ListView(
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
        children: [
          _infoCard(d),
          if (d.status == B3DetailStatus.tidakSesuai &&
              (d.alasan ?? '').isNotEmpty) ...[
            const SizedBox(height: 14),
            _alasanCard(d.alasan!),
          ],
          const SizedBox(height: 22),
          const Text(
            'Status Pendaftaran',
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w800,
              color: _C.green,
            ),
          ),
          const SizedBox(height: 10),
          _timelineCard(d),
        ],
      ),
    );
  }

  // ---------- KARTU INFO ----------
  BoxDecoration get _cardDeco => BoxDecoration(
    color: _C.card,
    borderRadius: BorderRadius.circular(14),
    boxShadow: const [
      BoxShadow(color: Color(0x1A000000), blurRadius: 8, offset: Offset(0, 2)),
    ],
  );

  Widget _infoCard(B3Detail d) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: _cardDeco,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'No. Pendaftaran',
                      style: TextStyle(fontSize: 10, color: _C.muted),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      d.noPendaftaran,
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w800,
                        color: _C.green,
                      ),
                    ),
                  ],
                ),
              ),
              _badge(d.status),
            ],
          ),
          const SizedBox(height: 6),
          if (d.status == B3DetailStatus.terdaftar ||
              d.status == B3DetailStatus.dijadwalkan) ...[
            _row(Icons.battery_charging_full_outlined, 'Jenis B3', d.jenis),
            _row(Icons.scale_outlined, 'Estimasi berat', d.estimasiBerat),
            _row(Icons.location_on_outlined, 'Alamat jemput', d.alamat),
            _row(
              Icons.local_shipping_outlined,
              'Jadwal jemput',
              d.jadwalJemput,
            ),
            _row(Icons.person_outline, 'Petugas DLH', d.petugas, last: true),
          ] else ...[
            _row(Icons.attach_file, 'Jenis B3', d.jenis),
            _row(
              Icons.scale_outlined,
              'Estimasi · berat dijemput',
              d.beratDijemput == null
                  ? d.estimasiBerat
                  : '${d.estimasiBerat} · ${d.beratDijemput}',
            ),
            _row(
              Icons.local_shipping_outlined,
              'Dijemput',
              d.jadwalJemput,
              last: true,
            ),
          ],
        ],
      ),
    );
  }

  Widget _alasanCard(String alasan) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: const Color(0xFFF6C9C4),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: const Color(0xFFE57373)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: const [
              Icon(Icons.warning_amber_rounded, size: 14, color: _C.red),
              SizedBox(width: 5),
              Text(
                'Alasan Tidak Sesuai',
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w800,
                  color: _C.red,
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          Text(alasan, style: const TextStyle(fontSize: 11, height: 1.4)),
        ],
      ),
    );
  }

  Widget _row(IconData icon, String label, String value, {bool last = false}) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 9),
      decoration: BoxDecoration(
        border: last
            ? null
            : const Border(bottom: BorderSide(color: _C.divider, width: 1)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Container(
            width: 30,
            height: 30,
            decoration: BoxDecoration(
              color: _C.iconBg,
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(icon, size: 16, color: _C.green),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: const TextStyle(fontSize: 10, color: _C.muted),
                ),
                const SizedBox(height: 1),
                Text(
                  value,
                  style: const TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w800,
                    color: _C.green,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _badge(B3DetailStatus s) {
    late final String label;
    late final Color bg;
    late final Color fg;
    switch (s) {
      case B3DetailStatus.terdaftar:
        label = 'Terdaftar';
        bg = const Color(0xFFEDE5B8);
        fg = const Color(0xFF6B5B00);
        break;
      case B3DetailStatus.dijadwalkan:
        label = 'Dijadwalkan';
        bg = const Color(0xFFDCE9F8);
        fg = const Color(0xFF1E5AA8);
        break;
      case B3DetailStatus.menungguVerifikasi:
        label = 'Menunggu verifikasi';
        bg = const Color(0xFFFFE9C7);
        fg = const Color(0xFF9A5B00);
        break;
      case B3DetailStatus.diverifikasi:
        label = 'Diverifikasi';
        bg = const Color(0xFFD7EDCF);
        fg = _C.green;
        break;
      case B3DetailStatus.tidakSesuai:
        label = 'Tidak sesuai';
        bg = const Color(0xFFF6C9C4);
        fg = _C.red;
        break;
    }
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(6),
      ),
      child: Text(
        label,
        style: TextStyle(fontSize: 9, fontWeight: FontWeight.w700, color: fg),
      ),
    );
  }

  // ---------- TIMELINE ----------
  Widget _timelineCard(B3Detail d) {
    final rejected = d.status == B3DetailStatus.tidakSesuai;
    final verified = d.status == B3DetailStatus.diverifikasi;

    // Tahap yang sudah dicapai: 1 terdaftar, 2 dijadwalkan, 3 dijemput/menunggu verifikasi, 4 selesai
    int level;
    switch (d.status) {
      case B3DetailStatus.terdaftar:
        level = 1;
        break;
      case B3DetailStatus.dijadwalkan:
        level = 2;
        break;
      case B3DetailStatus.menungguVerifikasi:
      case B3DetailStatus.tidakSesuai:
        level = 3;
        break;
      case B3DetailStatus.diverifikasi:
        level = 4;
        break;
    }

    final dijemput = d.tanggalDijemput ?? d.jadwalJemput;
    final diperiksa = d.tanggalDiperiksa == null
        ? 'Admin memeriksa berat dan jenis'
        : 'Diperiksa admin · ${d.tanggalDiperiksa}';

    final steps = <_Step>[
      _Step('Terdaftar', d.tanggalDaftar, done: true),
      _Step(
        'Dijadwalkan',
        level < 2
            ? 'Menunggu penugasan petugas'
            : d.status == B3DetailStatus.dijadwalkan
            ? 'Petugas ditugaskan · ${d.tanggalDijadwalkan}'
            : d.tanggalDijadwalkan,
        done: level >= 2,
      ),
      _Step(
        'Menunggu verifikasi',
        level >= 3 ? 'Dijemput $dijemput' : 'Setelah petugas menjemput',
        done: level >= 3,
      ),
      if (rejected)
        _Step('Tidak sesuai', diperiksa, done: true, error: true)
      else
        _Step(
          'Diverifikasi',
          verified ? diperiksa : 'Admin memeriksa berat dan jenis',
          done: verified,
        ),
    ];

    return Container(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
      decoration: _cardDeco,
      child: Column(
        children: [
          for (int i = 0; i < steps.length; i++)
            _timelineItem(
              steps[i],
              isLast: i == steps.length - 1,
              nextDone: i + 1 < steps.length && steps[i + 1].done,
            ),
        ],
      ),
    );
  }

  Widget _timelineItem(
    _Step s, {
    required bool isLast,
    required bool nextDone,
  }) {
    final Color dot = s.error ? _C.red : (s.done ? _C.green : _C.pending);
    final Color title = s.error ? _C.red : (s.done ? _C.green : _C.pendingText);
    final Color sub = s.done ? _C.muted : _C.pendingText;

    return IntrinsicHeight(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          SizedBox(
            width: 22,
            child: Column(
              children: [
                Container(
                  width: 20,
                  height: 20,
                  decoration: BoxDecoration(color: dot, shape: BoxShape.circle),
                  child: s.done
                      ? Icon(
                          s.error ? Icons.close : Icons.check,
                          size: 13,
                          color: Colors.white,
                        )
                      : null,
                ),
                if (!isLast)
                  Expanded(
                    child: Container(
                      width: 2,
                      color: nextDone ? _C.green : _C.pending,
                    ),
                  ),
              ],
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Padding(
              padding: EdgeInsets.only(bottom: isLast ? 10 : 18),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    s.title,
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w800,
                      color: title,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(s.subtitle, style: TextStyle(fontSize: 10, color: sub)),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _Step {
  final String title;
  final String subtitle;
  final bool done;
  final bool error;
  const _Step(
    this.title,
    this.subtitle, {
    this.done = false,
    this.error = false,
  });
}
