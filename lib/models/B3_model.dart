// Model data B3 untuk sisi mobile.
// Bentuk JSON-nya adalah KONTRAK dengan backend (B3WargaController):
//
// GET /api/b3/periode-aktif?id_desa=..
//   { "success": true, "data": null }                      -> belum ada periode
//   { "success": true, "data": {
//       "id_periode": 1, "kecamatan": "Bagor",
//       "desa": ["Bagor", "Balongrejo"],
//       "tgl_buka": "2026-10-12", "tgl_tutup": "2026-10-25",
//       "tgl_jemput": "2026-10-29",
//       "berat_min": 2, "berat_max": 20, "status": "Dibuka" } }
//
// GET /api/b3/riwayat?user_id=..&tipe=..
//   { "success": true, "data": [
//       { "id_pendaftaran": 1, "jenis_teks": "Baterai, Lampu",
//         "status": "Dijadwalkan", "estimasi_kg": 4,
//         "berat_verifikasi_kg": null,
//         "tgl_jemput": "2026-10-29", "tgl_verifikasi": null } ] }

const List<String> _namaBulan = [
  'Jan', 'Feb', 'Mar', 'Apr', 'Mei', 'Jun',
  'Jul', 'Agu', 'Sep', 'Okt', 'Nov', 'Des',
];

const List<String> _namaBulanPanjang = [
  'Januari', 'Februari', 'Maret', 'April', 'Mei', 'Juni',
  'Juli', 'Agustus', 'September', 'Oktober', 'November', 'Desember',
];

const List<String> _namaHari = [
  'Senin', 'Selasa', 'Rabu', 'Kamis', 'Jumat', 'Sabtu', 'Minggu',
];

DateTime? _parseTanggal(dynamic v) {
  if (v == null) return null;
  return DateTime.tryParse(v.toString());
}

double? _parseDouble(dynamic v) {
  if (v == null) return null;
  if (v is num) return v.toDouble();
  return double.tryParse(v.toString());
}

/// Contoh: 3.5 -> "3,5", 4.0 -> "4"
String formatKg(double v) {
  if (v == v.roundToDouble()) return v.toInt().toString();
  return v.toString().replaceAll('.', ',');
}

/// Contoh: 2026-10-29 -> "29 Okt 2026"
String formatTanggal(DateTime d) => '${d.day} ${_namaBulan[d.month - 1]} ${d.year}';

/// Contoh: 2026-10-29 -> "Kamis, 29 Okt 2026"
String formatTanggalHari(DateTime d) =>
    '${_namaHari[d.weekday - 1]}, ${formatTanggal(d)}';

/// Contoh: "12 – 25 Okt 2026" atau "28 Okt – 5 Nov 2026"
String formatRentang(DateTime a, DateTime b) {
  if (a.month == b.month && a.year == b.year) {
    return '${a.day} – ${b.day} ${_namaBulan[b.month - 1]} ${b.year}';
  }
  return '${a.day} ${_namaBulan[a.month - 1]} – ${b.day} ${_namaBulan[b.month - 1]} ${b.year}';
}

class B3Periode {
  final int id;
  final String kecamatan;
  final List<String> desa;
  final DateTime tglBuka;
  final DateTime tglTutup;
  final DateTime tglJemput;
  final double beratMin;
  final double beratMax;
  final String status; // Dijadwalkan | Dibuka | Ditutup | Selesai

  const B3Periode({
    required this.id,
    required this.kecamatan,
    required this.desa,
    required this.tglBuka,
    required this.tglTutup,
    required this.tglJemput,
    required this.beratMin,
    required this.beratMax,
    required this.status,
  });

  /// Contoh: "Periode Oktober 2026" (diambil dari bulan tanggal jemput)
  String get judul =>
      'Periode ${_namaBulanPanjang[tglJemput.month - 1]} ${tglJemput.year}';

  bool get pendaftaranDibuka => status == 'Dibuka';

  factory B3Periode.fromJson(Map<String, dynamic> json) {
    return B3Periode(
      id: int.tryParse(json['id_periode'].toString()) ?? 0,
      kecamatan: (json['kecamatan'] ?? '').toString(),
      desa: (json['desa'] as List? ?? const [])
          .map((e) => e.toString())
          .toList(),
      tglBuka: _parseTanggal(json['tgl_buka']) ?? DateTime.now(),
      tglTutup: _parseTanggal(json['tgl_tutup']) ?? DateTime.now(),
      tglJemput: _parseTanggal(json['tgl_jemput']) ?? DateTime.now(),
      beratMin: _parseDouble(json['berat_min']) ?? 0,
      beratMax: _parseDouble(json['berat_max']) ?? 0,
      status: (json['status'] ?? '').toString(),
    );
  }
}

/// Ringkasan satu pendaftaran B3 milik warga (untuk daftar "Pendaftaran Saya").
class B3Pendaftaran {
  final int id;
  final String jenisTeks; // "Baterai, Lampu"
  final String status; // Terdaftar | Dijadwalkan | Diverifikasi | ...
  final double? estimasiKg;
  final double? beratVerifikasiKg;
  final DateTime? tglJemput;
  final DateTime? tglVerifikasi;

  const B3Pendaftaran({
    required this.id,
    required this.jenisTeks,
    required this.status,
    this.estimasiKg,
    this.beratVerifikasiKg,
    this.tglJemput,
    this.tglVerifikasi,
  });

  /// Baris kedua pada kartu daftar.
  String get keterangan {
    if (status == 'Diverifikasi' && beratVerifikasiKg != null) {
      final tgl = tglVerifikasi != null ? ' · ${formatTanggal(tglVerifikasi!)}' : '';
      return 'Berat terverifikasi ${formatKg(beratVerifikasiKg!)} kg$tgl';
    }
    final est = estimasiKg != null ? 'Est. ${formatKg(estimasiKg!)} kg' : 'Est. -';
    final jemput = tglJemput != null ? ' · Jemput ${formatTanggal(tglJemput!)}' : '';
    return '$est$jemput';
  }

  factory B3Pendaftaran.fromJson(Map<String, dynamic> json) {
    return B3Pendaftaran(
      id: int.tryParse(json['id_pendaftaran'].toString()) ?? 0,
      jenisTeks: (json['jenis_teks'] ?? '').toString(),
      status: (json['status'] ?? '').toString(),
      estimasiKg: _parseDouble(json['estimasi_kg']),
      beratVerifikasiKg: _parseDouble(json['berat_verifikasi_kg']),
      tglJemput: _parseTanggal(json['tgl_jemput']),
      tglVerifikasi: _parseTanggal(json['tgl_verifikasi']),
    );
  }
}