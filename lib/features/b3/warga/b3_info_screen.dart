import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../../models/b3_model.dart';
import '../../../services/b3_service.dart';
import '../../home/home_user_screen.dart';
import '../../home/info_tps_screen.dart';
import '../../home/laporan_screen.dart';
import '../../home/riwayat_penarikan_screen.dart';
import '../../home/riwayat_setor_screen.dart';
import 'b3_form_screen.dart';

// Warna mengikuti desain Sampah B3 (W2 / W3)
const Color _hijauTua = Color(0xFF2E7D32);
const Color _krem = Color(0xFFFAF4DC);
const Color _hijauChip = Color(0xFFEAE4BE);
const Color _hijauBadge = Color(0xFFCDE8C0);

/// Layar "Sampah B3" untuk warga.
/// W2: ada periode dibuka. W3: belum ada periode.
class B3InfoScreen extends StatefulWidget {
  const B3InfoScreen({super.key});

  @override
  State<B3InfoScreen> createState() => _B3InfoScreenState();
}

class _B3InfoScreenState extends State<B3InfoScreen> {
  bool _loading = true;
  String? _error;
  B3Periode? _periode;
  List<B3Pendaftaran> _pendaftaran = [];

  @override
  void initState() {
    super.initState();
    _muat();
  }

  Future<void> _muat() async {
    setState(() {
      _loading = true;
      _error = null;
    });

    try {
      final prefs = await SharedPreferences.getInstance();
      final user = jsonDecode(prefs.getString('user_data') ?? '{}')
          as Map<String, dynamic>;

      final idDesa = user['id_desa']?.toString();
      final userId = (user['id_masyarakat'] ?? user['id_pns'] ?? '').toString();
      final tipe = (user['tipe'] ?? '').toString();

      final hasil = await Future.wait([
        B3Service.getPeriodeAktif(idDesa: idDesa),
        B3Service.getPendaftaranSaya(userId: userId, tipe: tipe),
      ]);

      if (!mounted) return;
      setState(() {
        _periode = hasil[0] as B3Periode?;
        _pendaftaran = hasil[1] as List<B3Pendaftaran>;
        _loading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _error = e.toString().replaceFirst('Exception: ', '');
        _loading = false;
      });
    }
  }

  void _segera(String nama) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('$nama segera tersedia.')),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _krem,
      appBar: AppBar(
        backgroundColor: _hijauTua,
        foregroundColor: Colors.white,
        elevation: 0,
        centerTitle: false,
        title: const Text(
          'Sampah B3',
          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 20),
        ),
      ),
      body: RefreshIndicator(
        color: _hijauTua,
        onRefresh: _muat,
        child: _buildBody(),
      ),
      bottomNavigationBar: _bottomBar(),
    );
  }

  Widget _buildBody() {
    if (_loading) {
      return ListView(
        children: const [
          SizedBox(height: 200),
          Center(child: CircularProgressIndicator(color: _hijauTua)),
        ],
      );
    }

    if (_error != null) {
      return ListView(
        padding: const EdgeInsets.all(24),
        children: [
          const SizedBox(height: 120),
          const Icon(Icons.cloud_off_outlined, size: 48, color: _hijauTua),
          const SizedBox(height: 12),
          Text(
            _error!,
            textAlign: TextAlign.center,
            style: const TextStyle(color: Colors.black54),
          ),
          const SizedBox(height: 16),
          Center(
            child: OutlinedButton(
              onPressed: _muat,
              child: const Text('Coba lagi'),
            ),
          ),
        ],
      );
    }

    final periode = _periode;
    return ListView(
      physics: const AlwaysScrollableScrollPhysics(),
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
      children: [
        if (periode != null) _kartuPeriode(periode) else _kartuKosong(),
        const SizedBox(height: 20),
        _judulSeksi('Pendaftaran Saya', 'Lihat Semua', () => _segera('Riwayat B3')),
        const SizedBox(height: 8),
        if (_pendaftaran.isEmpty)
          _kartuPutih(
            child: const Text(
              'Anda belum pernah mendaftar B3.',
              style: TextStyle(color: Colors.black54),
            ),
          )
        else
          ..._pendaftaran.map(_itemPendaftaran),
        const SizedBox(height: 20),
        const Text(
          'Jenis B3 yang Diterima',
          style: TextStyle(
            color: _hijauTua,
            fontWeight: FontWeight.bold,
            fontSize: 16,
          ),
        ),
        const SizedBox(height: 12),
        _jenisB3(),
        if (periode != null) ...[
          const SizedBox(height: 20),
          _kartuPanduan(),
        ],
      ],
    );
  }

  // ---------- Kartu periode (W2) ----------

  Widget _kartuPeriode(B3Periode p) {
    return _kartuPutih(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color: _hijauChip,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(Icons.eco_outlined, color: _hijauTua),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      p.judul,
                      style: const TextStyle(
                        color: _hijauTua,
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                      ),
                    ),
                    Text(
                      'Rute Kec. ${p.kecamatan}',
                      style: const TextStyle(color: Colors.black54, fontSize: 13),
                    ),
                  ],
                ),
              ),
              _badge(p.status),
            ],
          ),
          const SizedBox(height: 12),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: p.desa
                .map(
                  (d) => Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                    decoration: BoxDecoration(
                      color: _hijauChip,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      d,
                      style: const TextStyle(
                        color: _hijauTua,
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                )
                .toList(),
          ),
          const Divider(height: 24),
          _baris(
            Icons.calendar_today_outlined,
            'Pendaftaran',
            formatRentang(p.tglBuka, p.tglTutup),
          ),
          const SizedBox(height: 12),
          _baris(
            Icons.local_shipping_outlined,
            'Tanggal jemput',
            formatTanggalHari(p.tglJemput),
          ),
          const SizedBox(height: 12),
          _baris(
            Icons.shopping_bag_outlined,
            'Batas berat per pendaftaran',
            '${formatKg(p.beratMin)} – ${formatKg(p.beratMax)} kg',
          ),
          const SizedBox(height: 16),
          SizedBox(
            width: double.infinity,
            height: 48,
            child: ElevatedButton(
              onPressed: p.pendaftaranDibuka
                  ? () => Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => B3FormScreen(
                            periodeLabel: '${p.judul} · Rute Kec. ${p.kecamatan}',
                            tanggalJemput: formatTanggalHari(p.tglJemput),
                            desaOptions: p.desa,
                            beratMin: p.beratMin.toDouble(),
                            beratMax: p.beratMax.toDouble(),
                          ),
                        ),
                      )
                  : null,
              style: ElevatedButton.styleFrom(
                backgroundColor: _hijauTua,
                foregroundColor: Colors.white,
                disabledBackgroundColor: Colors.grey.shade300,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              child: Text(
                p.pendaftaranDibuka ? 'Daftar Sekarang' : 'Pendaftaran belum dibuka',
                style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _baris(IconData icon, String label, String nilai) {
    return Row(
      children: [
        Container(
          width: 36,
          height: 36,
          decoration: BoxDecoration(
            color: _hijauChip,
            borderRadius: BorderRadius.circular(10),
          ),
          child: Icon(icon, size: 18, color: _hijauTua),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: const TextStyle(color: Colors.black54, fontSize: 12),
              ),
              Text(
                nilai,
                style: const TextStyle(
                  color: _hijauTua,
                  fontWeight: FontWeight.bold,
                  fontSize: 15,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  // ---------- Kartu kosong (W3) ----------

  Widget _kartuKosong() {
    return _kartuPutih(
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 12),
        child: Column(
          children: [
            Container(
              width: 72,
              height: 72,
              decoration: const BoxDecoration(
                color: Color(0xFFE9E3B5),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.calendar_today_outlined,
                size: 30,
                color: _hijauTua,
              ),
            ),
            const SizedBox(height: 14),
            const Text(
              'Belum ada periode B3',
              style: TextStyle(
                color: _hijauTua,
                fontWeight: FontWeight.bold,
                fontSize: 16,
              ),
            ),
            const SizedBox(height: 6),
            const Text(
              'Pendaftaran dibuka oleh DLH per periode.\n'
              'Cek lagi nanti atau lihat riwayat Anda.',
              textAlign: TextAlign.center,
              style: TextStyle(color: Colors.black54, fontSize: 13),
            ),
          ],
        ),
      ),
    );
  }

  // ---------- Pendaftaran saya ----------

  Widget _judulSeksi(String judul, String aksi, VoidCallback onAksi) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          judul,
          style: const TextStyle(
            color: _hijauTua,
            fontWeight: FontWeight.bold,
            fontSize: 16,
          ),
        ),
        GestureDetector(
          onTap: onAksi,
          child: Text(
            aksi,
            style: const TextStyle(color: Colors.black54, fontSize: 13),
          ),
        ),
      ],
    );
  }

  Widget _itemPendaftaran(B3Pendaftaran p) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: InkWell(
        borderRadius: BorderRadius.circular(14),
        onTap: () => _segera('Detail pendaftaran B3'),
        child: _kartuPutih(
          child: Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'B3 · ${p.jenisTeks}',
                      style: const TextStyle(
                        color: _hijauTua,
                        fontWeight: FontWeight.bold,
                        fontSize: 15,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      p.keterangan,
                      style: const TextStyle(color: Colors.black54, fontSize: 12),
                    ),
                  ],
                ),
              ),
              _badge(p.status),
              const SizedBox(width: 4),
              const Icon(Icons.chevron_right, color: _hijauTua),
            ],
          ),
        ),
      ),
    );
  }

  // ---------- Jenis B3 ----------

  Widget _jenisB3() {
    const jenis = [
      (Icons.battery_full_rounded, 'Baterai'),
      (Icons.lightbulb_outline_rounded, 'Lampu'),
      (Icons.memory_rounded, 'Elektronik'),
      (Icons.medication_outlined, 'Obat'),
      (Icons.sanitizer_outlined, 'Aerosol'),
    ];

    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: jenis
          .map(
            (j) => Column(
              children: [
                Container(
                  width: 52,
                  height: 52,
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(14),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.06),
                        blurRadius: 6,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: Icon(j.$1, color: _hijauTua),
                ),
                const SizedBox(height: 6),
                Text(
                  j.$2,
                  style: const TextStyle(color: _hijauTua, fontSize: 11),
                ),
              ],
            ),
          )
          .toList(),
    );
  }

  Widget _kartuPanduan() {
    return InkWell(
      borderRadius: BorderRadius.circular(14),
      onTap: () => _segera('Panduan mengemas B3'),
      child: _kartuPutih(
        child: Row(
          children: const [
            Icon(Icons.info_outline, color: _hijauTua),
            SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Cara mengemas B3 dengan aman',
                    style: TextStyle(
                      color: _hijauTua,
                      fontWeight: FontWeight.bold,
                      fontSize: 14,
                    ),
                  ),
                  Text(
                    'Baca sebelum petugas datang',
                    style: TextStyle(color: Colors.black54, fontSize: 12),
                  ),
                ],
              ),
            ),
            Icon(Icons.chevron_right, color: _hijauTua),
          ],
        ),
      ),
    );
  }

  // ---------- Bar bawah: bubble B3 / Setor / Penarikan + navigasi ----------
  // Sama dengan bar bawah di layar Riwayat Setor dan Riwayat Penarikan,
  // supaya ketiga layar Bank Sampah terasa satu kelompok.

  Widget _bottomBar() {
    return Container(
      color: Colors.white,
      child: SafeArea(
        top: false,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
              child: Row(
                children: [
                  Expanded(
                    child: _bubble('B3', Icons.warning_amber_rounded, true, () {}),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: _bubble(
                      'Setor',
                      Icons.upload_rounded,
                      false,
                      () => Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => const RiwayatSetorScreen(),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: _bubble(
                      'Penarikan',
                      Icons.download_rounded,
                      false,
                      () => Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => const RiwayatPenarikanScreen(),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            _nav(),
          ],
        ),
      ),
    );
  }

  Widget _bubble(
    String label,
    IconData icon,
    bool isActive,
    VoidCallback onTap,
  ) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 12),
        decoration: BoxDecoration(
          gradient: isActive
              ? const LinearGradient(
                  colors: [Color(0xFF2E7D32), Color(0xFF4CAF50)],
                )
              : null,
          color: isActive ? null : const Color(0xFFE8F5E9),
          borderRadius: BorderRadius.circular(20),
          boxShadow: isActive
              ? [
                  BoxShadow(
                    color: const Color(0xFF4CAF50).withOpacity(0.3),
                    blurRadius: 6,
                    offset: const Offset(0, 3),
                  ),
                ]
              : null,
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              icon,
              size: 18,
              color: isActive ? Colors.white : const Color(0xFF2E7D32),
            ),
            const SizedBox(width: 6),
            Flexible(
              child: Text(
                label,
                style: TextStyle(
                  color: isActive ? Colors.white : const Color(0xFF2E7D32),
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                ),
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _nav() {
    const items = [
      (Icons.home_outlined, Icons.home, 'Home'),
      (Icons.assignment_outlined, Icons.assignment, 'Laporan'),
      (Icons.store_outlined, Icons.store, 'Bank Sampah'),
      (Icons.location_on_outlined, Icons.location_on, 'Info TPS'),
    ];

    void pindah(Widget layar) {
      Navigator.pushAndRemoveUntil(
        context,
        MaterialPageRoute(builder: (_) => layar),
        (route) => false,
      );
    }

    return Container(
      height: 65,
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, -5),
          ),
        ],
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: List.generate(items.length, (index) {
          final aktif = index == 2; // Bank Sampah
          final item = items[index];

          return GestureDetector(
            onTap: () {
              if (index == 0) {
                pindah(const HomeUserScreen());
              } else if (index == 1) {
                pindah(const LaporanScreen());
              } else if (index == 3) {
                pindah(const InfoTpsScreen());
              }
            },
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              decoration: aktif
                  ? const BoxDecoration(
                      color: Color(0xFF4CAF50),
                      borderRadius: BorderRadius.all(Radius.circular(20)),
                    )
                  : null,
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    aktif ? item.$2 : item.$1,
                    color: aktif ? Colors.white : Colors.grey,
                    size: 22,
                  ),
                  if (aktif) const SizedBox(width: 6),
                  if (aktif)
                    Text(
                      item.$3,
                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                        fontSize: 12,
                      ),
                    ),
                ],
              ),
            ),
          );
        }),
      ),
    );
  }

  // ---------- Komponen umum ----------

  Widget _kartuPutih({required Widget child}) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.06),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: child,
    );
  }

  Widget _badge(String status) {
    Color bg;
    Color fg;
    switch (status) {
      case 'Dibuka':
      case 'Diverifikasi':
        bg = _hijauBadge;
        fg = _hijauTua;
        break;
      case 'Dijadwalkan':
        bg = const Color(0xFFD6E4F7);
        fg = const Color(0xFF2D5BA3);
        break;
      case 'Menunggu verifikasi':
        bg = const Color(0xFFFFF3CD);
        fg = const Color(0xFF7A5B00);
        break;
      case 'Tidak sesuai':
      case 'Tidak ada di tempat':
        bg = const Color(0xFFFDECEA);
        fg = const Color(0xFFB71C1C);
        break;
      default:
        bg = const Color(0xFFEEEEEE);
        fg = Colors.black54;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(10),
      ),
      child: Text(
        status,
        style: TextStyle(color: fg, fontSize: 11, fontWeight: FontWeight.w600),
      ),
    );
  }
}