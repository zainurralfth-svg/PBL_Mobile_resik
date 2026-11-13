import 'dart:async';
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import '../config/api_config.dart';
import '../models/b3_model.dart';

/// Semua panggilan API B3 untuk warga.
///
/// Dua bagian punya saklar sendiri supaya bisa dipakai bertahap:
/// - [useDummyPeriode]     : periode dari web (sudah ada API-nya)
/// - [useDummyPendaftaran] : pendaftaran/riwayat warga (API-nya belum dibuat)
class B3Service {
  /// false = ambil periode asli yang dibuat admin di web.
  /// true  = data contoh (tanpa server).
  static const bool useDummyPeriode = false;

  /// true = data contoh sampai API pendaftaran B3 selesai.
  static const bool useDummyPendaftaran = false;

  /// Hanya berlaku saat [useDummyPeriode] = true:
  /// true -> contoh "periode dibuka" (W2), false -> "belum ada periode" (W3).
  static const bool dummyAdaPeriode = true;

  /// Periode B3 untuk desa warga. null = belum ada periode.
  static Future<B3Periode?> getPeriodeAktif({String? idDesa}) async {
    if (useDummyPeriode) {
      await Future.delayed(const Duration(milliseconds: 500));
      if (!dummyAdaPeriode) return null;
      return B3Periode(
        id: 1,
        kecamatan: 'Bagor',
        desa: const ['Bagor', 'Balongrejo', 'Kedungsumber', 'Banaran'],
        tglBuka: DateTime(2026, 10, 12),
        tglTutup: DateTime(2026, 10, 25),
        tglJemput: DateTime(2026, 10, 29),
        beratMin: 2,
        beratMax: 20,
        status: 'Dibuka',
      );
    }

    final uri = Uri.parse(
      '${ApiConfig.baseUrl}/b3/periode-aktif',
    ).replace(queryParameters: {'id_desa': idDesa ?? ''});
    final body = await _get(uri);
    final data = body['data'];
    if (data == null) return null;
    return B3Periode.fromJson(Map<String, dynamic>.from(data as Map));
  }

  /// Ringkasan pendaftaran B3 milik warga.
  static Future<List<B3Pendaftaran>> getPendaftaranSaya({
    required String userId,
    required String tipe,
  }) async {
    if (useDummyPendaftaran) {
      await Future.delayed(const Duration(milliseconds: 500));
      // Riwayat contoh, tidak bergantung pada ada/tidaknya periode.
      return [
        B3Pendaftaran(
          id: 2,
          jenisTeks: 'Baterai',
          status: 'Diverifikasi',
          beratVerifikasiKg: 3.5,
          tglVerifikasi: DateTime(2026, 9, 28),
        ),
      ];
    }

    final uri = Uri.parse(
      '${ApiConfig.baseUrl}/b3/riwayat',
    ).replace(queryParameters: {'user_id': userId, 'tipe': tipe});
    final body = await _get(uri);
    final list = (body['data'] as List? ?? const []);
    return list
        .map((e) => B3Pendaftaran.fromJson(Map<String, dynamic>.from(e as Map)))
        .toList();
  }

  /// Kirim pendaftaran B3 baru ke backend. Mengembalikan isi `data` dari respons
  /// (biasanya berisi id pendaftaran / nomor pendaftaran).
  ///
  /// TODO: samakan nama field di bawah dengan B3WargaController@store / Postman yang
  /// sudah berhasil menyimpan ke database.
  static Future<Map<String, dynamic>> daftar({
    required int idPeriode,
    required List<String> jenis,
    required double beratKg,
    required String desa,
    required String alamat,
    String keterangan = '',
  }) async {
    final prefs = await SharedPreferences.getInstance();
    final user =
        jsonDecode(prefs.getString('user_data') ?? '{}')
            as Map<String, dynamic>;
    final tipe = (user['tipe'] ?? '').toString();
    final isPns =
        tipe == 'pns' ||
        (user['id_masyarakat'] == null && user['id_pns'] != null);
    final rawId = isPns ? user['id_pns'] : user['id_masyarakat'];
    final userId = int.tryParse((rawId ?? '').toString());
    if (userId == null) {
      throw Exception('Data akun tidak lengkap. Silakan login ulang.');
    }

    // Nama field harus sama dengan validasi B3WargaController@store.
    // id_desa tidak dikirim: server mengambilnya dari data pengguna.
    // alamat/keterangan belum punya kolom di server, jadi tidak dikirim.
    final body = await _post(Uri.parse('${ApiConfig.baseUrl}/b3'), {
      'id_periode': idPeriode,
      if (isPns) 'id_pns': userId else 'id_masyarakat': userId,
      'est_berat': beratKg,
      'items': jenis.map((j) => {'jenis_b3': j, 'jumlah': 1}).toList(),
    });
    final data = body['data'];
    return data is Map ? Map<String, dynamic>.from(data) : <String, dynamic>{};
  }

  // ---------- helper ----------

  static Future<Map<String, dynamic>> _post(
    Uri uri,
    Map<String, dynamic> payload,
  ) async {
    final response = await http
        .post(
          uri,
          headers: {
            ...ApiConfig.headers,
            'Content-Type': 'application/json',
            'Accept': 'application/json',
          },
          body: jsonEncode(payload),
        )
        .timeout(const Duration(seconds: 15));

    Map<String, dynamic> body;
    try {
      body = jsonDecode(response.body) as Map<String, dynamic>;
    } on FormatException {
      throw Exception(
        'Server mengirim respons tak terduga (kode ${response.statusCode}).',
      );
    }

    final ok = response.statusCode == 200 || response.statusCode == 201;
    if (!ok || body['success'] == false) {
      var pesan =
          (body['message'] ?? 'Gagal mendaftar (kode ${response.statusCode}).')
              .toString();
      // Detail validasi Laravel: {"errors": {"field": ["pesan", ...]}}
      final errors = body['errors'];
      if (errors is Map && errors.isNotEmpty) {
        final detail = errors.entries
            .map((e) {
              final v = e.value;
              return v is List ? '${e.key}: ${v.join(', ')}' : '${e.key}: $v';
            })
            .join('\n');
        pesan = '$pesan\n$detail';
      }
      throw Exception(pesan);
    }
    return body;
  }

  static Future<Map<String, dynamic>> _get(Uri uri) async {
    final response = await http
        .get(uri, headers: ApiConfig.headers)
        .timeout(const Duration(seconds: 10));

    Map<String, dynamic> body;
    try {
      body = jsonDecode(response.body) as Map<String, dynamic>;
    } on FormatException {
      // Server membalas HTML (misalnya error 500), bukan JSON.
      throw Exception(
        'Server mengirim respons tak terduga (kode ${response.statusCode}).',
      );
    }

    if (response.statusCode != 200 || body['success'] == false) {
      throw Exception(
        (body['message'] ?? 'Terjadi kesalahan (kode ${response.statusCode}).')
            .toString(),
      );
    }
    return body;
  }
}
