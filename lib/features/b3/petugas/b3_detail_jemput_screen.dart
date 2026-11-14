import 'package:flutter/material.dart';
import 'b3_ditandai_dijemput_screen.dart';

class B3DetailJemputScreen extends StatelessWidget {
  final Map<String, dynamic>? dataWarga;
  const B3DetailJemputScreen({super.key, this.dataWarga});

  @override
  Widget build(BuildContext context) {
    String jenisB3 = 'Limbah B3';
    if (dataWarga?['items'] != null && (dataWarga?['items'] as List).isNotEmpty) {
      jenisB3 = dataWarga?['items'].map((i) => i['jenis_b3']).join(', ');
    }

    return Scaffold(
      backgroundColor: const Color(0xFFFAF7EE),
      appBar: AppBar(
        backgroundColor: const Color(0xFF1B5E20),
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text(
          'Detail Penjemputan',
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 18),
        ),
      ),
      body: Column(
        children: [
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(16.0),
              child: Container(
                padding: const EdgeInsets.all(20.0),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: [
                    BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 10, offset: const Offset(0, 4)),
                  ],
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(12),
                          decoration: const BoxDecoration(color: Color(0xFFE8E5CE), shape: BoxShape.circle),
                          child: const Icon(Icons.person_outline_rounded, color: Color(0xFF1B5E20)),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                dataWarga?['masyarakat']?['name'] ?? 'Warga RESIK',
                                style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: Color(0xFF1B5E20)),
                              ),
                              const SizedBox(height: 2),
                              const Text('081234567890', style: TextStyle(color: Colors.grey, fontSize: 12)),
                            ],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    const Divider(color: Color(0xFFEEEEEE), thickness: 1),
                    const SizedBox(height: 12),
                    _buildDetailRow(icon: Icons.location_on_outlined, title: 'Alamat', value: 'Jl. Wilangan Kulon No. 12, Bagor'),
                    _buildDetailRow(icon: Icons.battery_charging_full_rounded, title: 'Jenis B3', value: jenisB3),
                    _buildDetailRow(icon: Icons.scale_outlined, title: 'Estimasi berat', value: '${dataWarga?['est_berat'] ?? 0} kg'),
                    _buildDetailRow(icon: Icons.note_alt_outlined, title: 'Keterangan', value: dataWarga?['catatan_verifikasi'] ?? 'Tidak ada catatan', isLast: true),
                  ],
                ),
              ),
            ),
          ),
          Container(
            padding: const EdgeInsets.all(16),
            decoration: const BoxDecoration(color: Color(0xFFFAF7EE)),
            child: SafeArea(
              child: SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () async {
                    final hasil = await Navigator.push<double>(
                      context,
                      MaterialPageRoute(
                        builder: (_) => B3DitandaiDijemputScreen(
                          idTask: dataWarga?['id'],
                          nama: dataWarga?['masyarakat']?['name'] ?? 'Warga',
                          estimasiKg: double.tryParse(dataWarga?['est_berat'].toString() ?? '0') ?? 0.0,
                        ),
                      ),
                    );

                    if (hasil != null && context.mounted) {
                      Navigator.pop(context, hasil);
                    }
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF1B5E20),
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                  child: const Text('Tandai Dijemput', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 14)),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDetailRow({required IconData icon, required String title, required String value, bool isLast = false}) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(color: const Color(0xFFE8E5CE), borderRadius: BorderRadius.circular(8)),
            child: Icon(icon, size: 16, color: const Color(0xFF1B5E20)),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: const TextStyle(fontSize: 11, color: Colors.grey, fontWeight: FontWeight.w500)),
                const SizedBox(height: 4),
                Text(value, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: Color(0xFF1B5E20))),
                const SizedBox(height: 8),
                if (!isLast) const Divider(color: Color(0xFFEEEEEE), thickness: 1, height: 1),
              ],
            ),
          ),
        ],
      ),
    );
  }
}