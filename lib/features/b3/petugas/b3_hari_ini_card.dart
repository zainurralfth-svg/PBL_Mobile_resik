import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;

class B3HariIniCard extends StatefulWidget {
  const B3HariIniCard({super.key});

  @override
  State<B3HariIniCard> createState() => _B3HariIniCardState();
}

class _B3HariIniCardState extends State<B3HariIniCard> {
  int dijemput = 0;
  int totalWarga = 0;
  String wilayah = 'Kec. Bagor';
  bool isLoading = true;

  final String baseUrl = "http://10.0.2.2:8000/api";

  @override
  void initState() {
    super.initState();
    fetchRingkasan();
  }

  Future<void> fetchRingkasan() async {
    try {
      final response = await http.get(Uri.parse('$baseUrl/petugas/b3-ringkasan'));
      if (response.statusCode == 200) {
        final decoded = json.decode(response.body);
        final data = decoded['data'];
        setState(() {
          dijemput = data['dijemput'] ?? 0;
          totalWarga = data['total_warga'] ?? 0;
          wilayah = data['wilayah'] ?? 'Kec. Bagor';
          isLoading = false;
        });
      }
    } catch (e) {
      setState(() => isLoading = false);
      print("Error fetching ringkasan: $e");
    }
  }

  @override
  Widget build(BuildContext context) {
    double progress = totalWarga > 0 ? (dijemput / totalWarga) : 0.0;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFE9E3C8)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.03),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: const Color(0xFF1B5E20),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Icon(Icons.eco, color: Colors.white, size: 20),
              ),
              const SizedBox(width: 12),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Penjemputan B3 Hari Ini',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 15,
                      color: Color(0xFF1B5E20),
                    ),
                  ),
                  Text(
                    'Rute $wilayah',
                    style: const TextStyle(fontSize: 11, color: Colors.grey),
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Sudah dijemput',
                style: TextStyle(fontSize: 12, color: Colors.grey),
              ),
              isLoading
                  ? const SizedBox(
                      width: 12,
                      height: 12,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : Text(
                      '$dijemput / $totalWarga warga',
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 12,
                        color: Color(0xFF1B5E20),
                      ),
                    ),
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
        ],
      ),
    );
  }
}