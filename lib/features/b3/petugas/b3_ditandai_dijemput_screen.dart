// lib/features/b3/petugas/b3_ditandai_dijemput_screen.dart
// P5 · Form Tandai Dijemput (petugas) — TAMPILAN SAJA.
// Data warga di bawah masih contoh; sambungkan ke API setelah backend petugas jadi.
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';

class _C {
  static const green = Color(0xFF2D6A1E);
  static const cream = Color(0xFFFFF8E1);
  static const card = Color(0xFFFFFCF0);
  static const infoCard = Color(0xFFE8E2B5);
  static const border = Color(0xFFE9E3C8);
  static const text = Color(0xFF2B2B2B);
  static const muted = Color(0xFF6B6B6B);
}

class B3DitandaiDijemputScreen extends StatefulWidget {
  final String nama;
  final String alamat;
  final String jenis;
  final double estimasiKg;
  final double beratMin;
  final double beratMax;

  const B3DitandaiDijemputScreen({
    super.key,
    this.nama = 'Zaelani Abdul',
    this.alamat = 'Jl. Wilangan Kulon No. 12',
    this.jenis = 'Baterai, Lampu',
    this.estimasiKg = 4,
    this.beratMin = 2,
    this.beratMax = 20,
  });

  @override
  State<B3DitandaiDijemputScreen> createState() =>
      _B3DitandaiDijemputScreenState();
}

class _B3DitandaiDijemputScreenState extends State<B3DitandaiDijemputScreen> {
  final _berat = TextEditingController(text: '3.8');
  final _catatan = TextEditingController();
  final _picker = ImagePicker();
  Uint8List? _foto;
  String? _errorBerat;

  @override
  void dispose() {
    _berat.dispose();
    _catatan.dispose();
    super.dispose();
  }

  String _kg(double v) =>
      v == v.roundToDouble() ? v.toInt().toString() : v.toString();

  Future<void> _pilihFoto() async {
    try {
      final file = await _picker.pickImage(
        source: ImageSource.gallery,
        imageQuality: 80,
      );
      if (file == null) return;
      final bytes = await file.readAsBytes();
      if (mounted) setState(() => _foto = bytes);
    } catch (_) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Foto tidak bisa dibuka.')),
      );
    }
  }

  void _simpan() {
    final nilai = double.tryParse(_berat.text.trim().replaceAll(',', '.'));
    if (nilai == null || nilai <= 0) {
      setState(() => _errorBerat = 'Isi berat aktual dengan angka lebih dari 0.');
      return;
    }
    setState(() => _errorBerat = null);

    // TODO: kirim ke API petugas (berat, foto, catatan). Sekarang hanya tampilan.
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Tersimpan (contoh): $nilai kg')),
    );
    Navigator.pop(context, nilai);
  }

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
          'Tandai Dijemput',
          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
        ),
      ),
      body: SafeArea(
        child: Column(
          children: [
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(16, 16, 16, 16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _kartuWarga(),
                    const SizedBox(height: 18),
                    _label('Berat Aktual (kg)'),
                    _fieldBerat(),
                    const SizedBox(height: 6),
                    Text(
                      'Estimasi warga ${_kg(widget.estimasiKg)} kg · batas periode '
                      '${_kg(widget.beratMin)} – ${_kg(widget.beratMax)} kg',
                      style: const TextStyle(fontSize: 10.5, color: _C.muted),
                    ),
                    const SizedBox(height: 18),
                    _label('Foto Bukti (Opsional)'),
                    _kotakFoto(),
                    const SizedBox(height: 18),
                    _label('Catatan (Opsional)'),
                    _fieldCatatan(),
                  ],
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
              child: SizedBox(
                width: double.infinity,
                height: 50,
                child: ElevatedButton(
                  onPressed: _simpan,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: _C.green,
                    foregroundColor: Colors.white,
                    elevation: 0,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(25),
                    ),
                  ),
                  child: const Text(
                    'Simpan',
                    style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _kartuWarga() {
    TextStyle gaya = const TextStyle(fontSize: 12, color: _C.text, height: 1.5);
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: _C.infoCard,
        borderRadius: BorderRadius.circular(14),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Data Warga',
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.bold,
              color: _C.green,
            ),
          ),
          const SizedBox(height: 4),
          Text('Nama : ${widget.nama}', style: gaya),
          Text('Alamat : ${widget.alamat}', style: gaya),
          Text('Jenis : ${widget.jenis}', style: gaya),
        ],
      ),
    );
  }

  Widget _label(String teks) => Padding(
        padding: const EdgeInsets.only(bottom: 8),
        child: Text(
          teks,
          style: const TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.bold,
            color: _C.green,
          ),
        ),
      );

  Widget _fieldBerat() {
    return TextField(
      controller: _berat,
      keyboardType: const TextInputType.numberWithOptions(decimal: true),
      style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold),
      decoration: InputDecoration(
        prefixIcon: const Icon(Icons.scale_outlined, size: 20, color: _C.green),
        errorText: _errorBerat,
        filled: true,
        fillColor: _C.card,
        contentPadding: const EdgeInsets.symmetric(vertical: 14),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: _C.border),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: _C.green, width: 1.5),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: Color(0xFFB3261E)),
        ),
        focusedErrorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: Color(0xFFB3261E), width: 1.5),
        ),
      ),
    );
  }

  Widget _kotakFoto() {
    return InkWell(
      onTap: _pilihFoto,
      borderRadius: BorderRadius.circular(14),
      child: Container(
        width: double.infinity,
        height: 120,
        clipBehavior: Clip.antiAlias,
        decoration: BoxDecoration(
          color: _C.card,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: _C.border),
        ),
        child: _foto != null
            ? Stack(
                fit: StackFit.expand,
                children: [
                  Image.memory(_foto!, fit: BoxFit.cover),
                  Positioned(
                    top: 6,
                    right: 6,
                    child: GestureDetector(
                      onTap: () => setState(() => _foto = null),
                      child: const CircleAvatar(
                        radius: 13,
                        backgroundColor: Colors.black54,
                        child: Icon(Icons.close, size: 16, color: Colors.white),
                      ),
                    ),
                  ),
                ],
              )
            : const Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.camera_alt_outlined, size: 28, color: _C.green),
                  SizedBox(height: 6),
                  Text(
                    'Upload Foto',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                      color: _C.green,
                    ),
                  ),
                  SizedBox(height: 2),
                  Text(
                    'Format: JPG, PNG',
                    style: TextStyle(fontSize: 10.5, color: _C.muted),
                  ),
                ],
              ),
      ),
    );
  }

  Widget _fieldCatatan() {
    return TextField(
      controller: _catatan,
      maxLines: 3,
      style: const TextStyle(fontSize: 12),
      decoration: InputDecoration(
        hintText: 'Kondisi kemasan, jumlah, dll',
        hintStyle: const TextStyle(fontSize: 12, color: _C.muted),
        filled: true,
        fillColor: _C.card,
        contentPadding: const EdgeInsets.all(14),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: _C.border),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: _C.green, width: 1.5),
        ),
      ),
    );
  }
}