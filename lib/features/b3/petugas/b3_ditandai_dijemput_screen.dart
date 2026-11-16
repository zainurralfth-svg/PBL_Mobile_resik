import 'dart:convert';
import 'dart:typed_data';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:image_picker/image_picker.dart';
import '../../../config/api_config.dart';
import 'petugas_session.dart';

class _C {
  static const green = Color(0xFF2D6A1E);
  static const cream = Color(0xFFFFF8E1);
  static const card = Color(0xFFFFFCF0);
  static const border = Color(0xFFE9E3C8);
  static const muted = Color(0xFF6B6B6B);
}

class B3DitandaiDijemputScreen extends StatefulWidget {
  final dynamic idTask;
  final String nama;
  final double estimasiKg;

  /// Jenis barang terdaftar milik warga: [{id, jenis_b3, jumlah, jumlah_petugas}]
  final List<Map<String, dynamic>> items;

  const B3DitandaiDijemputScreen({
    super.key,
    required this.idTask,
    this.nama = 'Warga',
    this.estimasiKg = 4,
    this.items = const [],
  });

  @override
  State<B3DitandaiDijemputScreen> createState() => _B3DitandaiDijemputScreenState();
}

class _B3DitandaiDijemputScreenState extends State<B3DitandaiDijemputScreen> {
  /// Foto bukti wajib di aplikasi (di API tetap opsional supaya versi app lama tidak putus).
  static const bool _fotoWajib = true;

  late final TextEditingController _berat;
  final _catatan = TextEditingController();
  final _picker = ImagePicker();
  late final List<TextEditingController> _jumlah;
  Uint8List? _foto;
  String? _errorBerat;
  String? _errorJumlah;
  String? _errorFoto;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _berat = TextEditingController(text: widget.estimasiKg.toString());
    _jumlah = widget.items.map((i) {
      final awal = i['jumlah_petugas'] ?? i['jumlah'] ?? 0;
      return TextEditingController(text: awal.toString());
    }).toList();
  }

  @override
  void dispose() {
    _berat.dispose();
    _catatan.dispose();
    for (final c in _jumlah) {
      c.dispose();
    }
    super.dispose();
  }

  void _snack(String pesan) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(pesan)));
  }

  Future<void> _ambilFoto(ImageSource sumber) async {
    try {
      final f = await _picker.pickImage(source: sumber, imageQuality: 70, maxWidth: 1280);
      if (f == null) return;
      final bytes = await f.readAsBytes();
      if (!mounted) return;
      setState(() {
        _foto = bytes;
        _errorFoto = null;
      });
    } catch (e) {
      debugPrint('Gagal mengambil foto: $e');
      _snack('Kamera/galeri tidak bisa dibuka di perangkat ini.');
    }
  }

  void _pilihFoto() {
    // Web/desktop umumnya tidak punya kamera: langsung galeri.
    if (kIsWeb) {
      _ambilFoto(ImageSource.gallery);
      return;
    }
    showModalBottomSheet(
      context: context,
      backgroundColor: _C.card,
      builder: (_) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.photo_camera_outlined, color: _C.green),
              title: const Text('Ambil dengan kamera'),
              onTap: () {
                Navigator.pop(context);
                _ambilFoto(ImageSource.camera);
              },
            ),
            ListTile(
              leading: const Icon(Icons.photo_library_outlined, color: _C.green),
              title: const Text('Pilih dari galeri'),
              onTap: () {
                Navigator.pop(context);
                _ambilFoto(ImageSource.gallery);
              },
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _simpanKeDatabase() async {
    final nilai = double.tryParse(_berat.text.trim().replaceAll(',', '.'));
    final beratSalah = nilai == null || nilai <= 0;

    // Jumlah per jenis: bilangan bulat >= 0
    final daftarItem = <Map<String, dynamic>>[];
    var jumlahSalah = false;
    for (var i = 0; i < widget.items.length; i++) {
      final n = int.tryParse(_jumlah[i].text.trim());
      if (n == null || n < 0) {
        jumlahSalah = true;
        break;
      }
      daftarItem.add({'id': widget.items[i]['id'], 'jumlah': n});
    }
    final fotoKurang = _fotoWajib && _foto == null;

    setState(() {
      _errorBerat = beratSalah ? 'Isi berat aktual dengan angka lebih dari 0.' : null;
      _errorJumlah = jumlahSalah ? 'Jumlah tiap jenis harus bilangan bulat 0 atau lebih.' : null;
      _errorFoto = fotoKurang ? 'Foto bukti penjemputan wajib diisi.' : null;
    });
    if (beratSalah || jumlahSalah || fotoKurang) return;

    final idPetugas = await PetugasSession.getId();
    if (idPetugas == null) {
      _snack('Sesi petugas tidak ditemukan. Silakan login ulang.');
      return;
    }

    setState(() => _isLoading = true);

    try {
      final req = http.MultipartRequest('POST', Uri.parse(ApiConfig.petugasB3TaskStatus(widget.idTask)))
        ..headers['Accept'] = 'application/json'
        ..fields['id_petugas'] = idPetugas.toString()
        ..fields['status'] = 'selesai'
        ..fields['berat_dijemput'] = nilai.toString()
        ..fields['catatan_verifikasi'] = _catatan.text
        ..fields['items'] = jsonEncode(daftarItem);

      if (_foto != null) {
        req.files.add(http.MultipartFile.fromBytes('foto', _foto!, filename: 'bukti.jpg'));
      }

      final streamed = await req.send().timeout(const Duration(seconds: 60));
      final response = await http.Response.fromStream(streamed);

      if (response.statusCode == 200) {
        if (!mounted) return;
        _snack('Penjemputan berhasil disimpan.');
        Navigator.pop(context, nilai);
        return;
      }

      var msg = 'Gagal menyimpan (${response.statusCode})';
      try {
        msg = (json.decode(response.body)['message'] ?? msg).toString();
      } catch (_) {}
      if (!mounted) return;
      setState(() => _isLoading = false);
      _snack(msg);
    } catch (e) {
      debugPrint('Error updating: $e');
      if (!mounted) return;
      setState(() => _isLoading = false);
      _snack('Tidak dapat terhubung ke server.');
    }
  }

  InputDecoration _dekor({String? hint, String? error}) => InputDecoration(
        hintText: hint,
        errorText: error,
        filled: true,
        fillColor: _C.card,
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
      );

  Widget _label(String t) => Text(t, style: const TextStyle(fontWeight: FontWeight.bold, color: _C.green));

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _C.cream,
      appBar: AppBar(
        backgroundColor: _C.green,
        foregroundColor: Colors.white,
        elevation: 0,
        title: const Text('Tandai Dijemput', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
      ),
      body: SafeArea(
        child: Column(
          children: [
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Warga: ${widget.nama}', style: const TextStyle(fontWeight: FontWeight.bold, color: _C.green)),
                    const SizedBox(height: 18),
                    _label('Berat Aktual (kg)'),
                    const SizedBox(height: 8),
                    TextField(
                      controller: _berat,
                      keyboardType: const TextInputType.numberWithOptions(decimal: true),
                      decoration: _dekor(error: _errorBerat),
                    ),
                    if (widget.items.isNotEmpty) ...[
                      const SizedBox(height: 18),
                      _label('Jumlah per Jenis (aktual)'),
                      const SizedBox(height: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                        decoration: BoxDecoration(
                          color: _C.card,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: _C.border),
                        ),
                        child: Column(
                          children: [
                            for (var i = 0; i < widget.items.length; i++)
                              Padding(
                                padding: const EdgeInsets.symmetric(vertical: 8),
                                child: Row(
                                  children: [
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          Text('${widget.items[i]['jenis_b3']}',
                                              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: _C.green)),
                                          Text('Didaftarkan warga: ${widget.items[i]['jumlah']}',
                                              style: const TextStyle(fontSize: 11, color: _C.muted)),
                                        ],
                                      ),
                                    ),
                                    SizedBox(
                                      width: 80,
                                      child: TextField(
                                        controller: _jumlah[i],
                                        keyboardType: TextInputType.number,
                                        textAlign: TextAlign.center,
                                        decoration: InputDecoration(
                                          isDense: true,
                                          filled: true,
                                          fillColor: Colors.white,
                                          border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                          ],
                        ),
                      ),
                      if (_errorJumlah != null)
                        Padding(
                          padding: const EdgeInsets.only(top: 6, left: 4),
                          child: Text(_errorJumlah!, style: const TextStyle(color: Colors.red, fontSize: 12)),
                        ),
                    ],
                    const SizedBox(height: 18),
                    _label(_fotoWajib ? 'Foto Bukti' : 'Foto Bukti (Opsional)'),
                    const SizedBox(height: 8),
                    GestureDetector(
                      onTap: _isLoading ? null : _pilihFoto,
                      child: Container(
                        height: 170,
                        width: double.infinity,
                        decoration: BoxDecoration(
                          color: _C.card,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: _errorFoto != null ? Colors.red : _C.border),
                        ),
                        child: _foto == null
                            ? const Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Icon(Icons.add_a_photo_outlined, color: _C.green, size: 32),
                                  SizedBox(height: 6),
                                  Text('Ketuk untuk menambah foto', style: TextStyle(fontSize: 12, color: _C.muted)),
                                ],
                              )
                            : ClipRRect(
                                borderRadius: BorderRadius.circular(12),
                                child: Image.memory(_foto!, fit: BoxFit.cover, width: double.infinity),
                              ),
                      ),
                    ),
                    if (_errorFoto != null)
                      Padding(
                        padding: const EdgeInsets.only(top: 6, left: 4),
                        child: Text(_errorFoto!, style: const TextStyle(color: Colors.red, fontSize: 12)),
                      ),
                    if (_foto != null)
                      TextButton.icon(
                        onPressed: _isLoading ? null : _pilihFoto,
                        icon: const Icon(Icons.refresh, size: 16),
                        label: const Text('Ganti foto'),
                      ),
                    const SizedBox(height: 18),
                    _label('Catatan (Opsional)'),
                    const SizedBox(height: 8),
                    TextField(
                      controller: _catatan,
                      maxLines: 3,
                      decoration: _dekor(hint: 'Kondisi kemasan, dll'),
                    ),
                  ],
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(16),
              child: SizedBox(
                width: double.infinity,
                height: 50,
                child: ElevatedButton(
                  onPressed: _isLoading ? null : _simpanKeDatabase,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: _C.green,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(25)),
                  ),
                  child: _isLoading
                      ? const SizedBox(
                          width: 22,
                          height: 22,
                          child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2.5),
                        )
                      : const Text('Simpan Penjemputan', style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold)),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}