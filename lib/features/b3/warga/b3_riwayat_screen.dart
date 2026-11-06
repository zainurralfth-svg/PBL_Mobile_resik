// lib/features/b3/warga/b3_riwayat_screen.dart
import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

import '../../../config/api_config.dart';
import '../../home/home_user_screen.dart';
import '../../home/info_tps_screen.dart';
import '../../home/laporan_screen.dart';
import '../../home/riwayat_penarikan_screen.dart';
import '../../home/riwayat_setor_screen.dart';
import 'b3_detail_screen.dart';

/// Ubah ke false setelah endpoint API B3 siap.
const bool kB3UseDummyData = true;

// ==================== PALET WARNA ====================
class _C {
  static const green = Color(0xFF2D6A1E);
  static const greenDark = Color(0xFF1F4F14);
  static const cream = Color(0xFFFFF8E1);
  static const card = Color(0xFFFFFCF0);
  static const chipIdle = Color(0xFFEDE5B8);
  static const text = Color(0xFF2B2B2B);
  static const muted = Color(0xFF6B6B6B);
}

// ==================== MODEL ====================
enum B3Status { dijadwalkan, diverifikasi, tidakSesuai }

class B3RiwayatItem {
  final int id;
  final DateTime tanggal;
  final String periode;
  final String jenis;
  final double estimasiBerat;
  final double? beratTerverifikasi;
  final B3Status status;
  final String? alasan;

  const B3RiwayatItem({
    required this.id,
    required this.tanggal,
    required this.periode,
    required this.jenis,
    required this.estimasiBerat,
    required this.status,
    this.beratTerverifikasi,
    this.alasan,
  });

  static double? _toDouble(dynamic v) {
    if (v == null) return null;
    if (v is num) return v.toDouble();
    return double.tryParse(v.toString());
  }

  static B3Status _toStatus(String? s) {
    switch ((s ?? '').toLowerCase()) {
      case 'diverifikasi':
        return B3Status.diverifikasi;
      case 'tidak_sesuai':
      case 'tidak sesuai':
      case 'ditolak':
        return B3Status.tidakSesuai;
      default:
        return B3Status.dijadwalkan; // dijadwalkan / diproses / menunggu
    }
  }

  factory B3RiwayatItem.fromJson(Map<String, dynamic> j) {
    final jenisRaw = j['jenis'];
    return B3RiwayatItem(
      id: int.tryParse('${j['id'] ?? j['id_b3'] ?? 0}') ?? 0,
      tanggal:
          DateTime.tryParse('${j['tanggal'] ?? j['created_at']}') ??
          DateTime.now(),
      periode: '${j['periode'] ?? '-'}',
      jenis: jenisRaw is List ? jenisRaw.join(', ') : '${jenisRaw ?? '-'}',
      estimasiBerat: _toDouble(j['estimasi_berat']) ?? 0,
      beratTerverifikasi: _toDouble(j['berat_terverifikasi']),
      status: _toStatus(j['status']?.toString()),
      alasan: j['alasan']?.toString(),
    );
  }
}

// ==================== SCREEN ====================
class B3RiwayatScreen extends StatefulWidget {
  const B3RiwayatScreen({super.key});

  @override
  State<B3RiwayatScreen> createState() => _B3RiwayatScreenState();
}

class _B3RiwayatScreenState extends State<B3RiwayatScreen> {
  List<B3RiwayatItem> _items = [];
  bool _loading = true;
  String? _error;
  bool _onlyProcessing = false; // false = Semua Riwayat, true = Diproses

  static const _hari = [
    'Senin',
    'Selasa',
    'Rabu',
    'Kamis',
    'Jumat',
    'Sabtu',
    'Minggu',
  ];
  static const _bulan = [
    'Januari',
    'Februari',
    'Maret',
    'April',
    'Mei',
    'Juni',
    'Juli',
    'Agustus',
    'September',
    'Oktober',
    'November',
    'Desember',
  ];

  @override
  void initState() {
    super.initState();
    _load();
  }

  // ---------- DATA ----------
  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
    });

    try {
      if (kB3UseDummyData) {
        await Future.delayed(const Duration(milliseconds: 400));
        _items = _dummy();
      } else {
        final prefs = await SharedPreferences.getInstance();
        final userDataStr = prefs.getString('user_data');
        if (userDataStr == null) {
          throw 'Silakan login ulang';
        }
        final user = jsonDecode(userDataStr);
        final idMasyarakat = user['id_masyarakat'];

        final uri = Uri.parse(
          '${ApiConfig.baseUrl}/b3/riwayat',
        ).replace(queryParameters: {'id_masyarakat': '$idMasyarakat'});

        final res = await http
            .get(uri, headers: ApiConfig.headers)
            .timeout(const Duration(seconds: 10));
        final body = jsonDecode(res.body);

        if (res.statusCode == 200 && body['status'] == 'success') {
          _items = (body['data'] as List? ?? [])
              .map((e) => B3RiwayatItem.fromJson(e as Map<String, dynamic>))
              .toList();
        } else {
          throw body['message'] ?? 'Gagal memuat data';
        }
      }
      _items.sort((a, b) => b.tanggal.compareTo(a.tanggal));
    } catch (e) {
      _error = '$e';
    }

    if (mounted) setState(() => _loading = false);
  }

  List<B3RiwayatItem> _dummy() => [
    B3RiwayatItem(
      id: 1,
      tanggal: DateTime(2026, 10, 29),
      periode: 'Oktober',
      jenis: 'Baterai, Lampu',
      estimasiBerat: 4,
      status: B3Status.dijadwalkan,
    ),
    B3RiwayatItem(
      id: 2,
      tanggal: DateTime(2026, 9, 28),
      periode: 'September',
      jenis: 'Baterai',
      estimasiBerat: 3,
      beratTerverifikasi: 3.5,
      status: B3Status.diverifikasi,
    ),
    B3RiwayatItem(
      id: 3,
      tanggal: DateTime(2026, 8, 31),
      periode: 'Agustus',
      jenis: 'Obat Kedaluwarsa',
      estimasiBerat: 2,
      status: B3Status.tidakSesuai,
      alasan: 'Berisi sampah non-B3.',
    ),
  ];

  List<B3RiwayatItem> get _filtered => _onlyProcessing
      ? _items.where((e) => e.status == B3Status.dijadwalkan).toList()
      : _items;

  // Kelompokkan per tanggal (urutan sudah desc)
  Map<DateTime, List<B3RiwayatItem>> _grouped(List<B3RiwayatItem> list) {
    final map = <DateTime, List<B3RiwayatItem>>{};
    for (final e in list) {
      final key = DateTime(e.tanggal.year, e.tanggal.month, e.tanggal.day);
      map.putIfAbsent(key, () => []).add(e);
    }
    return map;
  }

  String _formatTanggal(DateTime d) =>
      '${_hari[d.weekday - 1]}, ${d.day} ${_bulan[d.month - 1]} ${d.year}';

  String _formatBerat(double? v) {
    if (v == null) return '-';
    final s = v == v.roundToDouble() ? v.toInt().toString() : v.toString();
    return '$s kg';
  }

  // ---------- BUILD ----------
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _C.cream,
      body: Column(
        children: [
          _buildHeader(context),
          Expanded(child: _buildBody()),
        ],
      ),
      bottomNavigationBar: SafeArea(
        top: false,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [_buildSubTabs(context), _buildBottomNav(context)],
        ),
      ),
    );
  }

  Widget _buildHeader(BuildContext context) {
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
            'Riwayat B3',
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

  Widget _buildBody() {
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 14, 16, 6),
          child: Row(
            children: [
              Expanded(
                child: _filterChip(
                  'Semua Riwayat',
                  !_onlyProcessing,
                  () => setState(() => _onlyProcessing = false),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: _filterChip(
                  'Diproses',
                  _onlyProcessing,
                  () => setState(() => _onlyProcessing = true),
                ),
              ),
            ],
          ),
        ),
        Expanded(child: _buildList()),
      ],
    );
  }

  Widget _filterChip(String label, bool selected, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        height: 38,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: selected ? _C.green : _C.chipIdle,
          borderRadius: BorderRadius.circular(20),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w600,
            color: selected ? Colors.white : _C.text,
          ),
        ),
      ),
    );
  }

  Widget _buildList() {
    if (_loading) {
      return const Center(child: CircularProgressIndicator(color: _C.green));
    }

    if (_error != null) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.error_outline, size: 48, color: _C.muted),
              const SizedBox(height: 10),
              Text(
                _error!,
                textAlign: TextAlign.center,
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
        ),
      );
    }

    final groups = _grouped(_filtered);

    return RefreshIndicator(
      color: _C.green,
      onRefresh: _load,
      child: groups.isEmpty
          ? ListView(
              children: const [
                SizedBox(height: 120),
                Icon(Icons.eco_outlined, size: 56, color: _C.muted),
                SizedBox(height: 10),
                Center(
                  child: Text(
                    'Belum ada riwayat B3',
                    style: TextStyle(color: _C.muted),
                  ),
                ),
              ],
            )
          : ListView(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 20),
              children: [
                for (final entry in groups.entries) ...[
                  Padding(
                    padding: const EdgeInsets.only(top: 8, bottom: 8),
                    child: Text(
                      _formatTanggal(entry.key),
                      style: const TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                        color: _C.text,
                      ),
                    ),
                  ),
                  for (final item in entry.value) _buildCard(item),
                ],
              ],
            ),
    );
  }

  Widget _buildCard(B3RiwayatItem item) {
    return GestureDetector(
      onTap: () => Navigator.push(
        context,
        MaterialPageRoute(builder: (_) => B3DetailScreen(idB3: item.id)),
      ),
      child: _buildCardContent(item),
    );
  }

  // ---------- CARD ----------
  Widget _buildCardContent(B3RiwayatItem item) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: _C.card,
        borderRadius: BorderRadius.circular(14),
        boxShadow: const [
          BoxShadow(
            color: Color(0x1A000000),
            blurRadius: 8,
            offset: Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Text(
                  'B3 · Periode ${item.periode}',
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w800,
                    color: _C.green,
                  ),
                ),
              ),
              _statusBadge(item.status),
            ],
          ),
          const SizedBox(height: 6),
          _infoLine('Jenis', item.jenis),
          _infoLine('Est. berat', _formatBerat(item.estimasiBerat)),
          _infoLine(
            'Berat terverifikasi',
            _formatBerat(item.beratTerverifikasi),
          ),
          if (item.status == B3Status.tidakSesuai &&
              (item.alasan ?? '').isNotEmpty) ...[
            const SizedBox(height: 10),
            _alasanBox(item.alasan!),
          ],
        ],
      ),
    );
  }

  Widget _infoLine(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(top: 2),
      child: Text(
        '$label: $value',
        style: const TextStyle(fontSize: 11, color: _C.muted),
      ),
    );
  }

  Widget _statusBadge(B3Status s) {
    late final String label;
    late final Color bg;
    late final Color fg;

    switch (s) {
      case B3Status.dijadwalkan:
        label = 'Dijadwalkan';
        bg = const Color(0xFFDCE9F8);
        fg = const Color(0xFF1E5AA8);
        break;
      case B3Status.diverifikasi:
        label = 'Diverifikasi';
        bg = const Color(0xFFD7EDCF);
        fg = const Color(0xFF2D6A1E);
        break;
      case B3Status.tidakSesuai:
        label = 'Tidak sesuai';
        bg = const Color(0xFFF6C9C4);
        fg = const Color(0xFFB3261E);
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

  Widget _alasanBox(String alasan) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: const Color(0xFFF6C9C4),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: const Color(0xFFE57373)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: const [
              Icon(
                Icons.warning_amber_rounded,
                size: 14,
                color: Color(0xFFB3261E),
              ),
              SizedBox(width: 4),
              Text(
                'Alasan',
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w800,
                  color: Color(0xFFB3261E),
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Text(alasan, style: const TextStyle(fontSize: 11, color: _C.text)),
        ],
      ),
    );
  }

  // ---------- SUB TAB (Riwayat Setor / Penarikan / Riwayat B3) ----------
  Widget _buildSubTabs(BuildContext context) {
    return Container(
      color: _C.green,
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
      child: Row(
        children: [
          _subTab(
            icon: Icons.inventory_2_outlined,
            label: 'Riwayat Setor',
            active: false,
            onTap: () => Navigator.pushReplacement(
              context,
              MaterialPageRoute(builder: (_) => const RiwayatSetorScreen()),
            ),
          ),
          _subTab(
            icon: Icons.account_balance_wallet_outlined,
            label: 'Penarikan',
            active: false,
            onTap: () => Navigator.pushReplacement(
              context,
              MaterialPageRoute(builder: (_) => const RiwayatPenarikanScreen()),
            ),
          ),
          _subTab(
            icon: Icons.eco_outlined,
            label: 'Riwayat B3',
            active: true,
            onTap: () {},
          ),
        ],
      ),
    );
  }

  Widget _subTab({
    required IconData icon,
    required String label,
    required bool active,
    required VoidCallback onTap,
  }) {
    return Expanded(
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: onTap,
        child: Container(
          height: 34,
          margin: const EdgeInsets.symmetric(horizontal: 3),
          decoration: BoxDecoration(
            color: active ? _C.chipIdle : Colors.transparent,
            borderRadius: BorderRadius.circular(20),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon, size: 14, color: active ? _C.greenDark : Colors.white),
              const SizedBox(width: 5),
              Flexible(
                child: Text(
                  label,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                    color: active ? _C.greenDark : Colors.white,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ---------- BOTTOM NAV ----------
  Widget _buildBottomNav(BuildContext context) {
    void goTo(Widget page) => Navigator.pushAndRemoveUntil(
      context,
      MaterialPageRoute(builder: (_) => page),
      (route) => false,
    );

    return Container(
      height: 68,
      color: _C.cream,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          IconButton(
            icon: const Icon(Icons.home_outlined, color: _C.green),
            onPressed: () => goTo(const HomeUserScreen()),
          ),
          IconButton(
            icon: const Icon(Icons.description_outlined, color: _C.green),
            onPressed: () => goTo(const LaporanScreen()),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 12),
            decoration: BoxDecoration(
              color: _C.green,
              borderRadius: BorderRadius.circular(26),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: const [
                Icon(Icons.store_outlined, color: Colors.white, size: 18),
                SizedBox(width: 8),
                Text(
                  'Bank Sampah',
                  style: TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w700,
                    fontSize: 13,
                  ),
                ),
              ],
            ),
          ),
          IconButton(
            icon: const Icon(Icons.location_on_outlined, color: _C.green),
            onPressed: () => goTo(const InfoTpsScreen()),
          ),
        ],
      ),
    );
  }
}
