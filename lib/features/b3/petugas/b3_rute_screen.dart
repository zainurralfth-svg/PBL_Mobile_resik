import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'daftar_warga_desa_screen.dart';

class B3RuteScreen extends StatefulWidget {
  const B3RuteScreen({super.key});

  @override
  State<B3RuteScreen> createState() => _B3RuteScreenState();
}

class _B3RuteScreenState extends State<B3RuteScreen> {
  bool _isLoading = true;
  int _totalWarga = 0;
  double _totalBerat = 0;
  int _dijemput = 0;
  List<dynamic> _listDesa = [];

  final String baseUrl = "http://10.0.2.2:8000/api";

  @override
  void initState() {
    super.initState();
    _fetchRuteData();
  }

  Future<void> _fetchRuteData() async {
    try {
      final response = await http.get(Uri.parse('$baseUrl/petugas/b3-rute'));
      if (response.statusCode == 200) {
        final decoded = json.decode(response.body);
        final data = decoded['data'];
        setState(() {
          _totalWarga = data['total_warga'] ?? 0;
          _totalBerat = double.tryParse(data['total_berat'].toString()) ?? 0.0;
          _dijemput = data['dijemput'] ?? 0;
          _listDesa = data['list_desa'] ?? [];
          _isLoading = false;
        });
      } else {
        setState(() => _isLoading = false);
      }
    } catch (e) {
      setState(() => _isLoading = false);
      print("Error fetching rute: $e");
    }
  }

  @override
  Widget build(BuildContext context) {
    double progress = _totalWarga > 0 ? (_dijemput / _totalWarga) : 0.0;

    return Scaffold(
      backgroundColor: const Color(0xFFFAF7EE),
      appBar: AppBar(
        backgroundColor: const Color(0xFF1B5E20),
        title: const Text('Rute Penjemputan B3', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator(color: Color(0xFF1B5E20)))
          : SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // --- KARTU HEADER UTAMA ---
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: const Color(0xFFE9E3C8)),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text('Rute Kec. Bagor', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: Color(0xFF1B5E20))),
                        const SizedBox(height: 4),
                        const Text('Periode Berjalan • Status Aktif', style: TextStyle(fontSize: 11, color: Colors.grey)),
                        const SizedBox(height: 14),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            const Text('Progres rute', style: TextStyle(fontSize: 12, color: Colors.grey)),
                            Text('$_dijemput / $_totalWarga warga', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12, color: Color(0xFF1B5E20))),
                          ],
                        ),
                        const SizedBox(height: 8),
                        ClipRRect(
                          borderRadius: BorderRadius.circular(8),
                          child: LinearProgressIndicator(
                            value: progress,
                            backgroundColor: const Color(0xFFE8E5CE),
                            valueColor: const AlwaysStoppedAnimation<Color>(Color(0xFF1B5E20)),
                            minHeight: 6,
                          ),
                        ),
                        const SizedBox(height: 16),
                        Row(
                          children: [
                            Expanded(child: _buildStatBox('$_totalWarga', 'Warga', const Color(0xFFE8E2B5))),
                            const SizedBox(width: 8),
                            Expanded(child: _buildStatBox('${_totalBerat.toStringAsFixed(1)} kg', 'Est. kg', const Color(0xFFDCE8F5))),
                            const SizedBox(width: 8),
                            Expanded(child: _buildStatBox('$_dijemput', 'Dijemput', const Color(0xFFFFE082))),
                          ],
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 20),
                  const Text('Desa dalam Rute', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: Color(0xFF1B5E20))),
                  const SizedBox(height: 10),

                  // --- LIST DESA DINAMIS DARI DB ---
                  ListView.separated(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    itemCount: _listDesa.length,
                    separatorBuilder: (_, __) => const SizedBox(height: 12),
                    itemBuilder: (context, index) {
                      final desa = _listDesa[index];
                      return GestureDetector(
                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => DaftarWargaDesaScreen(namaDesa: desa['nama_desa']),
                            ),
                          );
                        },
                        child: Container(
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(14),
                            boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.03), blurRadius: 6, offset: const Offset(0, 2))],
                          ),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(desa['nama_desa'] ?? 'Desa', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: Color(0xFF1B5E20))),
                                  const SizedBox(height: 4),
                                  Text('${desa['dijemput_desa']} / ${desa['total_warga_desa']} warga dijemput • est. ${desa['est_berat_desa']} kg', style: const TextStyle(fontSize: 11, color: Colors.grey)),
                                ],
                              ),
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                                decoration: BoxDecoration(
                                  color: const Color(0xFFE8F5E9),
                                  borderRadius: BorderRadius.circular(20),
                                ),
                                child: Text(
                                  desa['status_rute'] ?? 'Dijadwalkan',
                                  style: const TextStyle(color: Color(0xFF2E7D32), fontSize: 11, fontWeight: FontWeight.bold),
                                ),
                              ),
                            ],
                          ),
                        ),
                      );
                    },
                  ),
                ],
              ),
            ),
    );
  }

  Widget _buildStatBox(String nilai, String label, Color warna) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 12),
      decoration: BoxDecoration(color: warna, borderRadius: BorderRadius.circular(12)),
      child: Column(
        children: [
          Text(nilai, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Color(0xFF1B5E20))),
          const SizedBox(height: 2),
          Text(label, style: const TextStyle(fontSize: 10.5, color: Colors.black54)),
        ],
      ),
    );
  }
}