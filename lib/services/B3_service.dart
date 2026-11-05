import 'dart:async';
import 'dart:convert';
import 'package:http/http.dart' as http;
import '../config/api_config.dart';
import '../models/B3_model.dart';


/// Semua panggilan API B3 untuk warga.
///
/// Selama backend B3 belum jadi, [useDummyData] = true memakai data contoh
/// supaya tampilan bisa dikerjakan dan dicek dulu.
/// Kalau backend sudah siap, ubah [useDummyData] menjadi false.
class B3Service {
  /// true = data contoh (tanpa server). false = panggil API asli.
  static const bool useDummyData = true;

  /// Hanya berlaku saat [useDummyData] = true:
  /// true  -> contoh "periode dibuka" (desain W2)
  /// false -> contoh "belum ada periode" (desain W3)
  static const bool dummyAdaPeriode = true;

  /// Periode B3 yang sedang berlaku untuk desa warga. null = belum ada periode.
  static Future<B3Periode?> getPeriodeAktif({String? idDesa}) async {
    if (useDummyData) {
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

    final uri = Uri.parse('${ApiConfig.baseUrl}/b3/periode-aktif')
        .replace(queryParameters: {'id_desa': idDesa ?? ''});
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
    if (useDummyData) {
      await Future.delayed(const Duration(milliseconds: 500));
      if (dummyAdaPeriode) {
        return [
          B3Pendaftaran(
            id: 1,
            jenisTeks: 'Baterai, Lampu',
            status: 'Dijadwalkan',
            estimasiKg: 4,
            tglJemput: DateTime(2026, 10, 29),
          ),
        ];
      }
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

    final uri = Uri.parse('${ApiConfig.baseUrl}/b3/riwayat')
        .replace(queryParameters: {'user_id': userId, 'tipe': tipe});
    final body = await _get(uri);
    final list = (body['data'] as List? ?? const []);
    return list
        .map((e) => B3Pendaftaran.fromJson(Map<String, dynamic>.from(e as Map)))
        .toList();
  }

  // ---------- helper ----------

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