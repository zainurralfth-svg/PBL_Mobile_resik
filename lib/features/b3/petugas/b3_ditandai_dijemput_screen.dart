import 'dart:convert';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
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
  final dynamic idTask;
  final String nama;
  final double estimasiKg;

  const B3DitandaiDijemputScreen({
    super.key,
    required this.idTask,
    this.nama = 'Warga',
    this.estimasiKg = 4,
  });

  @override
  State<B3DitandaiDijemputScreen> createState() => _B3DitandaiDijemputScreenState();
}

class _B3DitandaiDijemputScreenState extends State<B3DitandaiDijemputScreen> {
  late final TextEditingController _berat;
  final _catatan = TextEditingController();
  final _picker = ImagePicker();
  Uint8List? _foto;
  String? _errorBerat;
  bool _isLoading = false;

  final String baseUrl = "http://10.0.2.2:8000/api";

  @override
  void initState() {
    super.initState();
    _berat = TextEditingController(text: widget.estimasiKg.toString());
  }

  @override
  void dispose() {
    _berat.dispose();
    _catatan.dispose();
    super.dispose();
  }

  Future<void> _simpanKeDatabase() async {
    final nilai = double.tryParse(_berat.text.trim().replaceAll(',', '.'));
    if (nilai == null || nilai <= 0) {
      setState(() => _errorBerat = 'Isi berat aktual dengan angka lebih dari 0.');
      return;
    }
    setState(() {
      _errorBerat = null;
      _isLoading = true;
    });

    try {
      final response = await http.put(
        Uri.parse('$baseUrl/petugas/b3-tasks/${widget.idTask}/status'),
        headers: {"Content-Type": "application/json"},
        body: json.encode({
          "status": "selesai",
          "est_berat": nilai,
          "catatan_verifikasi": _catatan.text,
        }),
      );

      if (response.statusCode == 200) {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Berhasil disimpan ke Database!')),
        );
        Navigator.pop(context, nilai);
      } else {
        setState(() => _isLoading = false);
      }
    } catch (e) {
      setState(() => _isLoading = false);
      print("Error updating: $e");
    }
  }

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
                    const Text('Berat Aktual (kg)', style: TextStyle(fontWeight: FontWeight.bold, color: _C.green)),
                    const SizedBox(height: 8),
                    TextField(
                      controller: _berat,
                      keyboardType: const TextInputType.numberWithOptions(decimal: true),
                      decoration: InputDecoration(
                        errorText: _errorBerat,
                        filled: true,
                        fillColor: _C.card,
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                    ),
                    const SizedBox(height: 18),
                    const Text('Catatan (Opsional)', style: TextStyle(fontWeight: FontWeight.bold, color: _C.green)),
                    const SizedBox(height: 8),
                    TextField(
                      controller: _catatan,
                      maxLines: 3,
                      decoration: InputDecoration(
                        hintText: 'Kondisi kemasan, dll',
                        filled: true,
                        fillColor: _C.card,
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                      ),
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
                      ? const CircularProgressIndicator(color: Colors.white)
                      : const Text('Simpan ke Database', style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold)),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}