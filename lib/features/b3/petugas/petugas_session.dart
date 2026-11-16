import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';

/// Id petugas yang sedang login.
///
/// Dibaca dari SharedPreferences ('user_type' dan 'user_data'), yang sudah
/// disimpan oleh login_screen.dart saat login berhasil. Jadi tidak perlu
/// diisi manual dan tetap ada setelah aplikasi ditutup lalu dibuka lagi.
///
/// Mengembalikan null kalau belum login atau yang login bukan petugas.
class PetugasSession {
  static Future<int?> getId() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      if (prefs.getString('user_type') != 'petugas') return null;

      final raw = prefs.getString('user_data');
      if (raw == null) return null;

      final data = jsonDecode(raw);
      return int.tryParse(data['id_petugas'].toString());
    } catch (_) {
      return null;
    }
  }
}