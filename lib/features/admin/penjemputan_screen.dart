import 'dart:io';
import 'package:flutter/material.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:resik/features/b3/petugas/daftar_warga_desa_screen.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:image_picker/image_picker.dart';
import 'package:geolocator/geolocator.dart';
import 'package:geocoding/geocoding.dart';
import 'package:intl/intl.dart';
import '../../config/api_config.dart';
import 'home_admin_screen.dart';

class PenjemputanScreen extends StatefulWidget {
  final String? initialTab;
  const PenjemputanScreen({super.key, this.initialTab});

  @override
  State<PenjemputanScreen> createState() => _PenjemputanScreenState();
}

class _PenjemputanScreenState extends State<PenjemputanScreen> {
  String _activeBubble = 'rute_b3';

  // State Form Reguler
  final _formKey = GlobalKey<FormState>();
  final _waktuCtrl = TextEditingController();
  final _lokasiCtrl = TextEditingController();
  final _beratCtrl = TextEditingController();
  final _keteranganCtrl = TextEditingController();
  File? _imageFile;
  final _picker = ImagePicker();
  bool _isFormLoading = false;
  Map<String, dynamic>? _adminData;

  @override
  void initState() {
    super.initState();
    _activeBubble = widget.initialTab ?? 'rute_b3';
    _loadAdminData();
  }

  @override
  void dispose() {
    _waktuCtrl.dispose();
    _lokasiCtrl.dispose();
    _beratCtrl.dispose();
    _keteranganCtrl.dispose();
    super.dispose();
  }

  Future<void> _loadAdminData() async {
    final prefs = await SharedPreferences.getInstance();
    final userDataStr = prefs.getString('user_data');
    if (userDataStr != null && mounted) {
      final userData = jsonDecode(userDataStr);
      setState(() {
        _adminData = userData;
        _waktuCtrl.text = DateFormat('dd/MM/yyyy HH:mm').format(DateTime.now());
      });
    }
  }

  void _onBubbleTap(String bubble) {
    setState(() {
      _activeBubble = bubble;
    });
  }

  // --- LOGIKA FORM REGULER ---
  Future<void> _pickImage(ImageSource source) async {
    final picked = await _picker.pickImage(
      source: source,
      maxWidth: 1800,
      maxHeight: 1800,
      imageQuality: 85,
    );
    if (picked != null) {
      setState(() => _imageFile = File(picked.path));
    }
  }

  void _showImageSourceDialog() {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) {
        return SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                margin: const EdgeInsets.only(top: 12),
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: Colors.grey[300],
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              const SizedBox(height: 16),
              const Text(
                'Pilih Sumber Foto',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF1A1A1A),
                ),
              ),
              const SizedBox(height: 20),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: Row(
                  children: [
                    Expanded(
                      child: _buildImageSourceButton(
                        icon: Icons.camera_alt_rounded,
                        label: 'Kamera',
                        color: const Color(0xFF2E7D32),
                        onTap: () {
                          Navigator.pop(context);
                          _pickImage(ImageSource.camera);
                        },
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: _buildImageSourceButton(
                        icon: Icons.photo_library_rounded,
                        label: 'Galeri',
                        color: const Color(0xFF1976D2),
                        onTap: () {
                          Navigator.pop(context);
                          _pickImage(ImageSource.gallery);
                        },
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 20),
            ],
          ),
        );
      },
    );
  }

  Widget _buildImageSourceButton({
    required IconData icon,
    required String label,
    required Color color,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 16),
        decoration: BoxDecoration(
          color: color.withOpacity(0.1),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: color.withOpacity(0.3)),
        ),
        child: Column(
          children: [
            Icon(icon, color: color, size: 28),
            const SizedBox(height: 8),
            Text(
              label,
              style: TextStyle(
                color: color,
                fontSize: 13,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _getCurrentLocation() async {
    setState(() => _isFormLoading = true);
    try {
      bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        _showSnackBar('Lokasi tidak aktif. Silakan aktifkan GPS.', Colors.red);
        setState(() => _isFormLoading = false);
        return;
      }
      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
        if (permission == LocationPermission.denied) {
          _showSnackBar('Izin lokasi ditolak', Colors.red);
          setState(() => _isFormLoading = false);
          return;
        }
      }
      Position position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
      );
      try {
        List<Placemark> placemarks = await placemarkFromCoordinates(
          position.latitude,
          position.longitude,
        );
        if (placemarks.isNotEmpty) {
          Placemark place = placemarks[0];
          String alamat = [
            place.street,
            place.locality,
            place.administrativeArea,
            place.postalCode,
            place.country,
          ].where((e) => e != null && e.isNotEmpty).join(', ');
          setState(
            () => _lokasiCtrl.text = alamat.isEmpty
                ? '${position.latitude}, ${position.longitude}'
                : alamat,
          );
        } else {
          setState(
            () => _lokasiCtrl.text =
                '${position.latitude}, ${position.longitude}',
          );
        }
      } catch (e) {
        setState(
          () => _lokasiCtrl.text = '${position.latitude}, ${position.longitude}',
        );
      }
    } catch (e) {
      _showSnackBar('Gagal mendapatkan lokasi: $e', Colors.red);
    } finally {
      setState(() => _isFormLoading = false);
    }
  }

  void _showSnackBar(String msg, Color color) {
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(msg),
          backgroundColor: color,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10),
          ),
        ),
      );
    }
  }

  Future<void> _submitPenjemputan() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _isFormLoading = true);
    try {
      final prefs = await SharedPreferences.getInstance();
      final adminData = jsonDecode(prefs.getString('user_data') ?? '{}');
      final adminId = adminData['id_petugas'];
      var request = http.MultipartRequest(
        'POST',
        Uri.parse('${ApiConfig.baseUrl}/penjemputan/store'),
      );
      request.headers.addAll({'Accept': 'application/json'});
      request.fields['id_petugas'] = adminId.toString();
      request.fields['nama_admin'] =
          _adminData?['nama'] ?? _adminData?['nama_lengkap'] ?? 'Admin';
      request.fields['waktu'] = DateFormat('yyyy-MM-dd HH:mm:ss').format(DateTime.now());
      request.fields['lokasi'] = _lokasiCtrl.text;
      request.fields['berat'] = _beratCtrl.text;
      request.fields['keterangan'] = _keteranganCtrl.text;
      request.fields['status'] = 'diproses';
      if (_imageFile != null) {
        request.files.add(
          await http.MultipartFile.fromPath(
            'foto',
            _imageFile!.path,
            filename: 'penjemputan_${DateTime.now().millisecondsSinceEpoch}.jpg',
          ),
        );
      }
      var streamedResponse = await request.send().timeout(const Duration(seconds: 30));
      var response = await http.Response.fromStream(streamedResponse);
      var result = jsonDecode(response.body);

      if (mounted) {
        setState(() => _isFormLoading = false);
        if (response.statusCode == 200 || response.statusCode == 201) {
          _showSnackBar('Penjemputan berhasil diajukan', const Color(0xFF2E7D32));
          _waktuCtrl.clear();
          _lokasiCtrl.clear();
          _beratCtrl.clear();
          _keteranganCtrl.clear();
          setState(() => _imageFile = null);
        } else {
          _showSnackBar(result['message'] ?? 'Gagal mengajukan penjemputan', Colors.red);
        }
      }
    } catch (e) {
      setState(() => _isFormLoading = false);
      _showSnackBar('Koneksi error: $e', Colors.red);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F7FA),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: const Color(0xFFF1F8E9),
              borderRadius: BorderRadius.circular(10),
            ),
            child: const Icon(
              Icons.arrow_back_ios_new,
              color: Color(0xFF2E7D32),
              size: 16,
            ),
          ),
          onPressed: () => Navigator.pushAndRemoveUntil(
            context,
            MaterialPageRoute(builder: (_) => const HomeAdminScreen()),
            (route) => false,
          ),
        ),
        title: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: const EdgeInsets.all(6),
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [Color(0xFF2E7D32), Color(0xFF4CAF50)],
                ),
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Icon(
                Icons.local_shipping_rounded,
                color: Colors.white,
                size: 16,
              ),
            ),
            const SizedBox(width: 10),
            const Text(
              'Penjemputan Sampah',
              style: TextStyle(
                color: Color(0xFF1A1A1A),
                fontWeight: FontWeight.w700,
                fontSize: 16,
                letterSpacing: 0.3,
              ),
            ),
          ],
        ),
        centerTitle: false,
      ),
      body: Column(
        children: [
          // BUBBLE TABS (REGULER & RUTE B3)
          Container(
            padding: const EdgeInsets.symmetric(vertical: 12),
            color: Colors.white,
            child: Center(
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  _buildBubble(
                    'Reguler',
                    Icons.add_circle_outline_rounded,
                    _activeBubble == 'form',
                    () => _onBubbleTap('form'),
                  ),
                  const SizedBox(width: 12),
                  _buildBubble(
                    'Rute B3',
                    Icons.eco,
                    _activeBubble == 'rute_b3',
                    () => _onBubbleTap('rute_b3'),
                  ),
                ],
              ),
            ),
          ),
          // KONTEN SESUAI TAB YANG DIPILIH
          Expanded(
            child: _activeBubble == 'form'
                ? _buildKontenFormReguler()
                : _buildKontenRuteB3(),
          ),
        ],
      ),
    );
  }

  // --- KONTEN FORM REGULER ---
  Widget _buildKontenFormReguler() {
    return ListView(
      physics: const AlwaysScrollableScrollPhysics(),
      padding: const EdgeInsets.all(20),
      children: [
        Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildSectionTitle('Detail Penjemputan', 'Lengkapi data penjemputan'),
              const SizedBox(height: 16),
              _buildFotoUpload(),
              const SizedBox(height: 16),
              _buildWaktuField(),
              const SizedBox(height: 16),
              _buildLokasiField(),
              const SizedBox(height: 16),
              _buildBeratField(),
              const SizedBox(height: 16),
              _buildKeteranganField(),
              const SizedBox(height: 24),
              _buildSubmitButton(),
              const SizedBox(height: 20),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildSectionTitle(String title, String subtitle) {
    return Row(
      children: [
        Container(
          width: 4,
          height: 20,
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              colors: [Color(0xFF2E7D32), Color(0xFF4CAF50)],
            ),
            borderRadius: BorderRadius.circular(2),
          ),
        ),
        const SizedBox(width: 10),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              title,
              style: const TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.w700,
                color: Color(0xFF1A1A1A),
              ),
            ),
            const SizedBox(height: 2),
            Text(
              subtitle,
              style: TextStyle(
                fontSize: 11,
                color: Colors.grey[600],
                fontWeight: FontWeight.w400,
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildFotoUpload() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Foto Lokasi (Opsional)',
          style: TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w600,
            color: Color(0xFF1B5E20),
          ),
        ),
        const SizedBox(height: 8),
        GestureDetector(
          onTap: _showImageSourceDialog,
          child: Container(
            height: 180,
            width: double.infinity,
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: _imageFile != null ? const Color(0xFF4CAF50) : Colors.grey.shade200,
              ),
            ),
            child: _imageFile != null
                ? ClipRRect(
                    borderRadius: BorderRadius.circular(11),
                    child: Image.file(_imageFile!, fit: BoxFit.cover),
                  )
                : Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: const Color(0xFFE8F5E9),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: const Icon(
                          Icons.add_a_photo_rounded,
                          size: 32,
                          color: Color(0xFF2E7D32),
                        ),
                      ),
                      const SizedBox(height: 12),
                      const Text(
                        'Upload Foto Lokasi',
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                          color: Color(0xFF1B5E20),
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Format: JPG, PNG (Maks 10MB)',
                        style: TextStyle(fontSize: 11, color: Colors.grey[600]),
                      ),
                    ],
                  ),
          ),
        ),
      ],
    );
  }

  Widget _buildWaktuField() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Waktu Pengajuan',
          style: TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w600,
            color: Color(0xFF1B5E20),
          ),
        ),
        const SizedBox(height: 8),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          decoration: BoxDecoration(
            color: Colors.grey.shade50,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: Colors.grey.shade200),
          ),
          child: Row(
            children: [
              const Icon(Icons.access_time_rounded, color: Color(0xFF2E7D32), size: 16),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  _waktuCtrl.text.isEmpty ? 'Otomatis' : _waktuCtrl.text,
                  style: TextStyle(fontSize: 13, color: Colors.grey[700]),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildLokasiField() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Lokasi Penjemputan',
          style: TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w600,
            color: Color(0xFF1B5E20),
          ),
        ),
        const SizedBox(height: 8),
        GestureDetector(
          onTap: _isFormLoading ? null : _getCurrentLocation,
          child: Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.grey.shade200),
            ),
            child: Row(
              children: [
                const Icon(Icons.location_on_rounded, color: Color(0xFF2E7D32), size: 18),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    _lokasiCtrl.text.isEmpty
                        ? 'Klik untuk mendapatkan lokasi'
                        : _lokasiCtrl.text,
                    style: const TextStyle(fontSize: 13, color: Color(0xFF1A1A1A)),
                  ),
                ),
                const Icon(Icons.my_location_rounded, color: Color(0xFF2E7D32), size: 16),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildBeratField() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Estimasi Berat Sampah',
          style: TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w600,
            color: Color(0xFF1B5E20),
          ),
        ),
        const SizedBox(height: 8),
        Container(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: Colors.grey.shade200),
          ),
          child: TextFormField(
            controller: _beratCtrl,
            keyboardType: const TextInputType.numberWithOptions(decimal: true),
            decoration: const InputDecoration(
              hintText: '0',
              prefixIcon: Icon(Icons.scale_rounded, color: Color(0xFF2E7D32)),
              suffixText: 'kg',
              border: InputBorder.none,
              contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            ),
            validator: (v) {
              if (v == null || v.isEmpty) return 'Berat wajib diisi';
              if (double.tryParse(v) == null) return 'Masukkan angka valid';
              return null;
            },
          ),
        ),
      ],
    );
  }

  Widget _buildKeteranganField() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Keterangan (Opsional)',
          style: TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w600,
            color: Color(0xFF1B5E20),
          ),
        ),
        const SizedBox(height: 8),
        Container(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: Colors.grey.shade200),
          ),
          child: TextFormField(
            controller: _keteranganCtrl,
            maxLines: 3,
            decoration: const InputDecoration(
              hintText: 'Jenis sampah, akses lokasi, dll',
              prefixIcon: Icon(Icons.notes_rounded, color: Color(0xFF2E7D32)),
              border: InputBorder.none,
              contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildSubmitButton() {
    return SizedBox(
      width: double.infinity,
      height: 56,
      child: ElevatedButton(
        onPressed: _isFormLoading ? null : _submitPenjemputan,
        style: ElevatedButton.styleFrom(
          backgroundColor: const Color(0xFF2E7D32),
          foregroundColor: Colors.white,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(14),
          ),
        ),
        child: _isFormLoading
            ? const CircularProgressIndicator(color: Colors.white)
            : const Text(
                'Kirim Pengajuan',
                style: TextStyle(fontSize: 15, fontWeight: FontWeight.w700),
              ),
      ),
    );
  }

  // --- KONTEN RUTE B3 ---
  Widget _buildKontenRuteB3() {
    return ListView(
      physics: const AlwaysScrollableScrollPhysics(),
      padding: const EdgeInsets.all(16),
      children: [
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: Colors.grey.shade200),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Rute Kec. Bagor',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF1B5E20),
                ),
              ),
              const SizedBox(height: 4),
              const Text(
                'Periode Oktober 2026 • Kamis, 29 Okt 2026',
                style: TextStyle(fontSize: 12, color: Colors.grey),
              ),
              const SizedBox(height: 16),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: const [
                  Text('Progres rute', style: TextStyle(fontSize: 12, color: Colors.grey)),
                  Text('3 / 8 warga', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Color(0xFF1B5E20))),
                ],
              ),
              const SizedBox(height: 8),
              ClipRRect(
                borderRadius: BorderRadius.circular(4),
                child: const LinearProgressIndicator(
                  value: 3 / 8,
                  backgroundColor: Color(0xFFE8F5E9),
                  valueColor: AlwaysStoppedAnimation<Color>(Color(0xFF2E7D32)),
                  minHeight: 8,
                ),
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  Expanded(child: _buildB3StatCard('8', 'Warga', const Color(0xFFF1F8E9), const Color(0xFF2E7D32))),
                  const SizedBox(width: 8),
                  Expanded(child: _buildB3StatCard('62', 'Est. kg', const Color(0xFFE3F2FD), const Color(0xFF1976D2))),
                  const SizedBox(width: 8),
                  Expanded(child: _buildB3StatCard('3', 'Dijemput', const Color(0xFFFFF3E0), const Color(0xFFF57C00))),
                ],
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: Colors.grey.shade200),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Desa dalam Rute',
                style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: Color(0xFF1B5E20)),
              ),
              const SizedBox(height: 12),
              _buildDesaB3Item('Desa Bagor', '3 / 4 warga dijemput • est. 24 kg'),
              _buildDesaB3Item('Desa Balongrejo', '0 / 2 warga dijemput • est. 18 kg'),
              _buildDesaB3Item('Desa Kedungsumber', '0 / 1 warga dijemput • est. 12 kg'),
              _buildDesaB3Item('Desa Banaran', '0 / 1 warga dijemput • est. 8 kg'),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildB3StatCard(String value, String label, Color bgColor, Color textColor) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 12),
      decoration: BoxDecoration(color: bgColor, borderRadius: BorderRadius.circular(12)),
      child: Column(
        children: [
          Text(value, style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: textColor)),
          const SizedBox(height: 4),
          Text(label, style: TextStyle(fontSize: 11, color: textColor, fontWeight: FontWeight.w500)),
        ],
      ),
    );
  }

  Widget _buildDesaB3Item(String namaDesa, String info) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        border: Border.all(color: Colors.grey.shade200),
        borderRadius: BorderRadius.circular(12),
      ),
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        title: Text(namaDesa, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
        subtitle: Text(info, style: const TextStyle(fontSize: 11, color: Colors.grey)),
        trailing: Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
          decoration: BoxDecoration(
            color: const Color(0xFFE8F5E9),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: const [
              Text('Dijadwalkan', style: TextStyle(fontSize: 10, color: Color(0xFF2E7D32), fontWeight: FontWeight.bold)),
              SizedBox(width: 4),
              Icon(Icons.chevron_right, size: 14, color: Color(0xFF2E7D32)),
            ],
          ),
        ),
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => DaftarWargaDesaScreen(namaDesa: namaDesa),
            ),
          );
        },
      ),
    );
  }

  Widget _buildBubble(String label, IconData icon, bool isActive, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 16),
        decoration: BoxDecoration(
          color: isActive ? const Color(0xFF2E7D32) : const Color(0xFFE8F5E9),
          borderRadius: BorderRadius.circular(25),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              icon,
              size: 18,
              color: isActive ? Colors.white : const Color(0xFF2E7D32),
            ),
            const SizedBox(width: 6),
            Text(
              label,
              style: TextStyle(
                color: isActive ? Colors.white : const Color(0xFF2E7D32),
                fontSize: 13,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
      ),
    );
  }
}