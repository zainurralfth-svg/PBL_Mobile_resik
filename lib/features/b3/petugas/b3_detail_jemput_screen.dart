import 'package:flutter/material.dart';
import 'b3_ditandai_dijemput_screen.dart';

class B3DetailJemputScreen extends StatelessWidget {
  // Data opsional jika nanti ingin dinamis passing data dari halaman sebelumnya
  final Map<String, dynamic>? dataWarga;

  const B3DetailJemputScreen({
    super.key,
    this.dataWarga,
  });

  @override
  Widget build(BuildContext context) {
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
          style: TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.bold,
            fontSize: 18,
          ),
        ),
      ),
      body: Column(
        children: [
          // BAGIAN CARD DETAIL
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(16.0),
              child: Container(
                padding: const EdgeInsets.all(20.0),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.05),
                      blurRadius: 10,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // --- HEADER PROFIL ---
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(12),
                          decoration: const BoxDecoration(
                            color: Color(0xFFE8E5CE),
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(
                            Icons.person_outline_rounded,
                            color: Color(0xFF1B5E20),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                dataWarga?['nama'] ?? 'Zaelani Abdul',
                                style: const TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 16,
                                  color: Color(0xFF1B5E20),
                                ),
                              ),
                              const SizedBox(height: 2),
                              const Text(
                                '081234567890',
                                style: TextStyle(
                                  color: Colors.grey,
                                  fontSize: 12,
                                ),
                              ),
                            ],
                          ),
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 10, vertical: 6),
                          decoration: BoxDecoration(
                            color: const Color(0xFFD3E3FD),
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: const Text(
                            'Dijadwalkan',
                            style: TextStyle(
                              color: Color(0xFF045DBF),
                              fontSize: 10,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    const Divider(color: Color(0xFFEEEEEE), thickness: 1),
                    const SizedBox(height: 12),

                    // --- DETAIL INFO ---
                    _buildDetailRow(
                      icon: Icons.location_on_outlined,
                      title: 'Alamat',
                      value: dataWarga?['alamat'] ??
                          'Jl. Wilangan Kulon No. 12, Desa Bagor',
                    ),
                    _buildDetailRow(
                      icon: Icons.battery_charging_full_rounded,
                      title: 'Jenis B3',
                      value: dataWarga?['kategori'] ?? 'Baterai, Lampu',
                    ),
                    _buildDetailRow(
                      icon: Icons.scale_outlined,
                      title: 'Estimasi berat',
                      value: dataWarga?['estimasi'] ?? '4 kg',
                    ),
                    _buildDetailRow(
                      icon: Icons.note_alt_outlined,
                      title: 'Keterangan warga',
                      value: 'Di depan rumah, dekat pagar hijau',
                      isLast: true,
                    ),

                    const SizedBox(height: 12),

                    // --- TOMBOL BUKA PETA ---
                    SizedBox(
                      width: double.infinity,
                      child: OutlinedButton.icon(
                        onPressed: () {
                          // Aksi buka peta
                        },
                        icon: const Icon(
                          Icons.near_me_outlined,
                          size: 18,
                        ),
                        label: const Text(
                          'Buka Peta',
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 14,
                          ),
                        ),
                        style: OutlinedButton.styleFrom(
                          foregroundColor: const Color(0xFF1B5E20),
                          side: const BorderSide(color: Color(0xFF1B5E20)),
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
          
          // BAGIAN ACTION BUTTON (BAWAH)
          Container(
            padding: const EdgeInsets.all(16),
            decoration: const BoxDecoration(
              color: Color(0xFFFAF7EE),
            ),
            child: SafeArea(
              child: Row(
                children: [
                  Expanded(
                    child: ElevatedButton(
                      onPressed: () {
                        // Aksi Tidak Ada Di Tempat
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFFD32F2F), // Merah
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        elevation: 0,
                      ),
                      child: const Text(
                        'Tidak Ada di Tempat',
                        style: TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                          fontSize: 13,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: ElevatedButton(
                      onPressed: () async {
                        // Ambil angka dari teks estimasi, mis. '4 kg' -> 4.0
                        final estimasi = double.tryParse(
                              RegExp(r'[0-9]+([.,][0-9]+)?')
                                      .firstMatch('${dataWarga?['estimasi'] ?? '4'}')
                                      ?.group(0)
                                      ?.replaceAll(',', '.') ??
                                  '',
                            ) ??
                            4;

                        final hasil = await Navigator.push<double>(
                          context,
                          MaterialPageRoute(
                            builder: (_) => B3DitandaiDijemputScreen(
                              nama: dataWarga?['nama'] ?? 'Zaelani Abdul',
                              alamat: dataWarga?['alamat'] ?? 'Jl. Wilangan Kulon No. 12, Desa Bagor',
                              jenis: dataWarga?['kategori'] ?? 'Baterai, Lampu',
                              estimasiKg: estimasi,
                            ),
                          ),
                        );

                        // Sudah disimpan -> kembali ke daftar warga.
                        if (hasil != null && context.mounted) {
                          Navigator.pop(context, hasil);
                        }
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF1B5E20), // Hijau Gelap
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        elevation: 0,
                      ),
                      child: const Text(
                        'Tandai Dijemput',
                        style: TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                          fontSize: 13,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  // Widget bantuan untuk membuat baris detail berulang
  Widget _buildDetailRow({
    required IconData icon,
    required String title,
    required String value,
    bool isLast = false,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: const Color(0xFFE8E5CE),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(icon, size: 16, color: const Color(0xFF1B5E20)),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 11,
                    color: Colors.grey,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  value,
                  style: const TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF1B5E20),
                  ),
                ),
                const SizedBox(height: 8),
                if (!isLast)
                  const Divider(
                    color: Color(0xFFEEEEEE),
                    thickness: 1,
                    height: 1,
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}