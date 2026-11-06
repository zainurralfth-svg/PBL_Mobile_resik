import 'package:flutter/material.dart';

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

  final List> _wargaList = [
    {
      'nama': 'Zaelani Abdul',
      'alamat': 'Jl. Wilangan Kulon No. 12',
      'kategori': 'Baterai, Lampu',
      'status': 'Dijadwalkan',
      'status_key': 'belum',
      'estimasi': '4 kg',
    },
    {
      'nama': 'Farida Novalia',
      'alamat': 'Jl. Kenanga No. 3',
      'kategori': 'Elektronik',
      'status': 'Dijadwalkan',
      'status_key': 'belum',
      'estimasi': '8 kg',
    },
    {
      'nama': 'Sitka Lucky',
      'alamat': 'Jl. Melati No. 7',
      'kategori': 'Obat Kadaluwarsa',
      'status': 'Menunggu verifikasi',
      'status_key': 'dijemput',
      'estimasi': '3 kg',
    },
    {
      'nama': 'Hendra Wijaya',
      'alamat': 'Jl. Anggrek No. 21',
      'kategori': 'Aerosol / Cat',
      'status': 'Tidak ada di tempat',
      'status_key': 'tidak_ada',
      'estimasi': '9 kg',
    },
  ];

  @override
  Widget build(BuildContext context) {
    final filteredList = _selectedFilter == 'Semua'
        ? _wargaList
        : _wargaList.where((item) {
            if (_selectedFilter == 'Belum') return item['status_key'] == 'belum';
            if (_selectedFilter == 'Dijemput') return item['status_key'] == 'dijemput';
            if (_selectedFilter == 'Tidak ada') return item['status_key'] == 'tidak_ada';
            return true;
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
                  const SizedBox(width: 8),
                  _buildFilterChip('Tidak ada'),
                ],
              ),
            ),
          ),
          Expanded(
            child: ListView.separated(
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
      onTap: () {
        setState(() {
          _selectedFilter = label;
        });
      },
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
    Color statusBgColor;
    Color statusTextColor;

    switch (item['status']) {
      case 'Dijadwalkan':
        statusBgColor = const Color(0xFFD3E3FD);
        statusTextColor = const Color(0xFF045DBF);
        break;
      case 'Menunggu verifikasi':
        statusBgColor = const Color(0xFFFFE082);
        statusTextColor = const Color(0xFF7F6000);
        break;
      case 'Tidak ada di tempat':
        statusBgColor = const Color(0xFFFFCDD2);
        statusTextColor = const Color(0xFFC62828);
        break;
      default:
        statusBgColor = const Color(0xFFE8F5E9);
        statusTextColor = const Color(0xFF2E7D32);
    }

    return Container(
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
                      item['nama'],
                      style: const TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF1B5E20),
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      item['alamat'],
                      style: const TextStyle(
                        fontSize: 11,
                        color: Colors.grey,
                      ),
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
                  item['status'],
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
                  item['kategori'],
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
                    'Est. ${item['estimasi']}',
                    style: const TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF1B5E20),
                    ),
                  ),
                  const SizedBox(width: 4),
                  const Icon(
                    Icons.chevron_right,
                    size: 16,
                    color: Colors.grey,
                  ),
                ],
              ),
            ],
          ),
        ],
      ),
    );
  }
}