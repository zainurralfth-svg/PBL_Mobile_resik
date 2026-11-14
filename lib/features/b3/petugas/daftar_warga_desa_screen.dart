import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'b3_detail_jemput_screen.dart';

class DaftarWargaDesaScreen extends StatefulWidget {
  final String namaDesa;
  const DaftarWargaDesaScreen({
    super.key,
    this.namaDesa = 'Desa Bagor',
  });

  @override
  State<DaftarWargaDesaScreen> createState() => _DaftarWargaDesaScreenState();
}

class _DaftarWargaDesaScreenState extends State<DaftarWargaDesaScreen> {
  String _selectedFilter = 'Semua';
  List<dynamic> _wargaList = [];
  bool _isLoading = true;

  final String baseUrl = "http://10.0.2.2:8000/api";

  @override
  void initState() {
    super.initState();
    _fetchWargaFromDatabase();
  }

  Future<void> _fetchWargaFromDatabase() async {
    try {
      final response = await http.get(Uri.parse('$baseUrl/petugas/b3-tasks'));
      if (response.statusCode == 200) {
        final decoded = json.decode(response.body);
        setState(() {
          _wargaList = decoded['data'];
          _isLoading = false;
        });
      } else {
        setState(() => _isLoading = false);
      }
    } catch (e) {
      setState(() => _isLoading = false);
      print("Error fetching data: $e");
    }
  }

  @override
  Widget build(BuildContext context) {
    final filteredList = _selectedFilter == 'Semua'
        ? _wargaList
        : _wargaList.where((item) {
            String status = item['status'] ?? '';
            if (_selectedFilter == 'Belum' && status == 'pending') return true;
            if (_selectedFilter == 'Dijemput' && status == 'selesai') return true;
            return false;
          }).toList();

    return Scaffold(
      backgroundColor: const Color(0xFFFAF7EE),
      appBar: AppBar(
        backgroundColor: const Color(0xFF1B5E20),
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          widget.namaDesa,
          style: const TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.bold,
            fontSize: 18,
          ),
        ),
      ),
      body: Column(
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: [
                  _buildFilterChip('Semua'),
                  const SizedBox(width: 8),
                  _buildFilterChip('Belum'),
                  const SizedBox(width: 8),
                  _buildFilterChip('Dijemput'),
                ],
              ),
            ),
          ),
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator(color: Color(0xFF1B5E20)))
                : _wargaList.isEmpty
                    ? const Center(
                        child: Text(
                          'Belum ada data penjemputan di database.',
                          style: TextStyle(color: Colors.grey),
                        ),
                      )
                    : ListView.separated(
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                        itemCount: filteredList.length,
                        separatorBuilder: (context, index) => const SizedBox(height: 12),
                        itemBuilder: (context, index) {
                          return _buildWargaCard(filteredList[index]);
                        },
                      ),
          ),
        ],
      ),
    );
  }

  Widget _buildFilterChip(String label) {
    final isSelected = _selectedFilter == label;
    return GestureDetector(
      onTap: () => setState(() => _selectedFilter = label),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          color: isSelected ? const Color(0xFF1B5E20) : const Color(0xFFE8E5CE),
          borderRadius: BorderRadius.circular(20),
        ),
        child: Text(
          label,
          style: TextStyle(
            color: isSelected ? Colors.white : const Color(0xFF333333),
            fontSize: 12,
            fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
          ),
        ),
      ),
    );
  }

  Widget _buildWargaCard(Map<String, dynamic> item) {
    String statusDb = item['status'] ?? 'pending';
    String statusText = statusDb == 'selesai' ? 'Selesai Dijemput' : 'Dijadwalkan';
    Color statusBgColor = statusDb == 'selesai' ? const Color(0xFFE8F5E9) : const Color(0xFFD3E3FD);
    Color statusTextColor = statusDb == 'selesai' ? const Color(0xFF2E7D32) : const Color(0xFF045DBF);

    String jenisB3 = 'Limbah B3';
    if (item['items'] != null && (item['items'] as List).isNotEmpty) {
      jenisB3 = item['items'].map((i) => i['jenis_b3']).join(', ');
    }

    return GestureDetector(
      onTap: () async {
        final result = await Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => B3DetailJemputScreen(dataWarga: item),
          ),
        );

        if (result != null && mounted) {
          _fetchWargaFromDatabase();
        }
      },
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
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
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        item['masyarakat']?['name'] ?? 'Warga RESIK',
                        style: const TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF1B5E20),
                        ),
                      ),
                      const SizedBox(height: 2),
                      const Text(
                        'Alamat terdaftar di sistem',
                        style: TextStyle(fontSize: 11, color: Colors.grey),
                      ),
                    ],
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: statusBgColor,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    statusText,
                    style: TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.bold,
                      color: statusTextColor,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: const Color(0xFFE8E5CE),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    jenisB3,
                    style: const TextStyle(
                      fontSize: 11,
                      color: Color(0xFF333333),
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
                Row(
                  children: [
                    Text(
                      'Est. ${item['est_berat'] ?? 0} kg',
                      style: const TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF1B5E20),
                      ),
                    ),
                    const SizedBox(width: 4),
                    const Icon(Icons.chevron_right, size: 16, color: Colors.grey),
                  ],
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}