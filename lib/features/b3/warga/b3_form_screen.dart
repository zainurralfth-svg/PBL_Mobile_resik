// lib/features/b3/warga/b3_form_screen.dart
//
// W4 · Form Daftar Sampah B3 (warga) — TAMPILAN SAJA.
// Belum ada backend / GPS / data desa asli. Semua data masih contoh.
// Alur: W2 Info -> [W4 Form] -> W5 Konfirmasi -> W6 Terkirim

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'b3_konfirmasi_screen.dart';

/// Data isian form. Dioper ke W5 supaya ringkasannya sama dengan isian.
class B3FormData {
  final String periodeLabel;
  final String tanggalJemput;
  final List<String> jenis;
  final double beratKg;
  final String desa;
  final String alamat;
  final String keterangan;

  const B3FormData({
    this.periodeLabel = 'Oktober 2026 · Rute Kec. Bogor',
    this.tanggalJemput = 'Kamis, 29 Okt 2026',
    this.jenis = const ['Baterai', 'Lampu'],
    this.beratKg = 4,
    this.desa = 'Desa Bogor',
    this.alamat = 'Jl. Wilangan Kulon No. 12',
    this.keterangan = '',
  });

  String get jenisText => jenis.join(', ');
  String get beratText => '${beratKg % 1 == 0 ? beratKg.toInt() : beratKg} kg';
}

class B3FormScreen extends StatefulWidget {
  final String periodeLabel;
  final String tanggalJemput;

  /// Desa yang dilayani periode ini (dari W2: `p.desa`).
  /// Kalau null -> mode contoh (form terisi data contoh seperti Figma).
  final List<String>? desaOptions;

  /// Batas berat per pendaftaran (dari W2: `p.beratMin` / `p.beratMax`).
  final double beratMin;
  final double beratMax;

  const B3FormScreen({
    super.key,
    this.periodeLabel = 'Periode Oktober 2026 · Rute Kec. Bogor',
    this.tanggalJemput = 'Kamis, 29 Okt 2026',
    this.desaOptions,
    this.beratMin = 2,
    this.beratMax = 20,
  });

  @override
  State<B3FormScreen> createState() => _B3FormScreenState();
}

class _B3FormScreenState extends State<B3FormScreen> {
  static const _green = Color(0xFF2E7D32);
  static const _greenDark = Color(0xFF1B5E20);
  static const _cream = Color(0xFFFAF4DC);
  static const _field = Color(0xFFFFFDF5);
  static const _chipIdle = Color(0xFFEAE4BE);
  static const _banner = Color(0xFFE9E3B8);

  double get _minBerat => widget.beratMin;
  double get _maxBerat => widget.beratMax;

  /// Form terisi contoh (seperti Figma) hanya saat dibuka sendiri tanpa data
  /// periode. Kalau dibuka dari W2 (desaOptions diisi), form kosong.
  bool get _isiContoh => widget.desaOptions == null;

  static const _jenisOptions = <_JenisB3>[
    _JenisB3('Baterai', Icons.battery_charging_full_rounded),
    _JenisB3('Lampu', Icons.lightbulb_outline_rounded),
    _JenisB3('Elektronik', Icons.memory_rounded),
    _JenisB3('Obat Kedaluwarsa', Icons.medication_outlined),
    _JenisB3('Aerosol / Cat', Icons.format_paint_outlined),
  ];

  // Contoh daftar desa, dipakai kalau W2 belum mengoper desaOptions.
  static const _desaContoh = <String>[
    'Desa Bogor',
    'Desa Wilangan',
    'Desa Sukomoro',
    'Desa Kertosono',
  ];

  List<String> get _desaOptions => widget.desaOptions ?? _desaContoh;

  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _beratCtrl;
  late final TextEditingController _alamatCtrl;
  final _keteranganCtrl = TextEditingController();

  late final Set<String> _selectedJenis;
  bool _jenisError = false;
  String? _desa;

  @override
  void initState() {
    super.initState();
    _beratCtrl = TextEditingController(text: _isiContoh ? '4' : '');
    _alamatCtrl = TextEditingController(
      text: _isiContoh ? 'Jl. Wilangan Kulon No. 12' : '',
    );
    _selectedJenis = _isiContoh ? {'Baterai', 'Lampu'} : {};
    _desa = (_isiContoh && _desaOptions.contains('Desa Bogor'))
        ? 'Desa Bogor'
        : null;
  }

  @override
  void dispose() {
    _beratCtrl.dispose();
    _alamatCtrl.dispose();
    _keteranganCtrl.dispose();
    super.dispose();
  }

  String _fmt(double v) => v % 1 == 0 ? v.toInt().toString() : v.toString();

  void _onLanjut() {
    FocusScope.of(context).unfocus();
    setState(() => _jenisError = _selectedJenis.isEmpty);
    if (_selectedJenis.isEmpty || !_formKey.currentState!.validate()) return;

    final data = B3FormData(
      periodeLabel: widget.periodeLabel.replaceFirst(
        RegExp(r'^Periode\s+'),
        '',
      ),
      tanggalJemput: widget.tanggalJemput,
      jenis: _jenisOptions
          .map((o) => o.label)
          .where(_selectedJenis.contains)
          .toList(),
      beratKg: double.parse(_beratCtrl.text.replaceAll(',', '.').trim()),
      desa: _desa ?? '-',
      alamat: _alamatCtrl.text.trim(),
      keterangan: _keteranganCtrl.text.trim(),
    );

    // Sementara langsung push ke W5 supaya bisa dicek alurnya.
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => B3KonfirmasiScreen(data: data)),
    );
  }

  // ------------------------------------------------------------------
  // UI
  // ------------------------------------------------------------------

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _cream,
      appBar: AppBar(
        backgroundColor: _green,
        foregroundColor: Colors.white,
        elevation: 0,
        title: const Text(
          'Daftar Sampah B3',
          style: TextStyle(fontWeight: FontWeight.w700, fontSize: 18),
        ),
      ),
      body: SafeArea(
        child: Column(
          children: [
            Expanded(
              child: GestureDetector(
                behavior: HitTestBehavior.translucent,
                onTap: () => FocusScope.of(context).unfocus(),
                child: SingleChildScrollView(
                  padding: const EdgeInsets.all(16),
                  child: Form(
                    key: _formKey,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _periodeBanner(),
                        const SizedBox(height: 18),
                        _label('Jenis B3 *'),
                        _jenisChips(),
                        const SizedBox(height: 18),
                        _label('Estimasi Berat Sampah'),
                        _beratField(),
                        const SizedBox(height: 18),
                        _label('Desa'),
                        _desaDropdown(),
                        const SizedBox(height: 18),
                        _label('Alamat Penjemputan'),
                        _alamatField(),
                        const SizedBox(height: 18),
                        _label('Keterangan (Opsional)'),
                        _keteranganField(),
                      ],
                    ),
                  ),
                ),
              ),
            ),
            _lanjutButton(),
          ],
        ),
      ),
    );
  }

  Widget _periodeBanner() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: _banner,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          const Icon(Icons.event_note_rounded, size: 18, color: _greenDark),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              widget.periodeLabel,
              style: const TextStyle(
                color: _greenDark,
                fontSize: 12.5,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _label(String text) => Padding(
    padding: const EdgeInsets.only(bottom: 8),
    child: Text(
      text,
      style: const TextStyle(
        color: _greenDark,
        fontSize: 13,
        fontWeight: FontWeight.w700,
      ),
    ),
  );

  Widget _jenisChips() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: _jenisOptions.map((o) {
            final selected = _selectedJenis.contains(o.label);
            return GestureDetector(
              onTap: () => setState(() {
                selected
                    ? _selectedJenis.remove(o.label)
                    : _selectedJenis.add(o.label);
                _jenisError = false;
              }),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 150),
                padding: const EdgeInsets.symmetric(
                  horizontal: 14,
                  vertical: 10,
                ),
                decoration: BoxDecoration(
                  color: selected ? _green : _chipIdle,
                  borderRadius: BorderRadius.circular(22),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      o.icon,
                      size: 16,
                      color: selected ? Colors.white : _greenDark,
                    ),
                    const SizedBox(width: 6),
                    Text(
                      o.label,
                      style: TextStyle(
                        fontSize: 12.5,
                        fontWeight: FontWeight.w600,
                        color: selected ? Colors.white : _greenDark,
                      ),
                    ),
                  ],
                ),
              ),
            );
          }).toList(),
        ),
        if (_jenisError)
          const Padding(
            padding: EdgeInsets.only(top: 6, left: 4),
            child: Text(
              'Pilih minimal satu jenis B3',
              style: TextStyle(color: Color(0xFFD32F2F), fontSize: 11.5),
            ),
          ),
      ],
    );
  }

  Widget _beratField() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        TextFormField(
          controller: _beratCtrl,
          keyboardType: const TextInputType.numberWithOptions(decimal: true),
          inputFormatters: [
            FilteringTextInputFormatter.allow(RegExp(r'[0-9.,]')),
          ],
          decoration: _decoration(
            icon: Icons.scale_outlined,
            hint: 'Contoh: 4',
            suffix: const Padding(
              padding: EdgeInsets.only(right: 14),
              child: Text(
                'kg',
                style: TextStyle(
                  color: _greenDark,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ),
          validator: (v) {
            final n = double.tryParse((v ?? '').replaceAll(',', '.').trim());
            if (n == null) return 'Isi estimasi berat';
            if (n < _minBerat || n > _maxBerat) {
              return 'Berat harus antara ${_fmt(_minBerat)}–${_fmt(_maxBerat)} kg';
            }
            return null;
          },
        ),
        Padding(
          padding: const EdgeInsets.only(top: 6, left: 4),
          child: Text(
            'Minimal ${_fmt(_minBerat)} kg, maksimal ${_fmt(_maxBerat)} kg per pendaftaran',
            style: const TextStyle(color: Color(0xFF6B7A5E), fontSize: 11),
          ),
        ),
      ],
    );
  }

  Widget _desaDropdown() {
    return DropdownButtonFormField<String>(
      initialValue: _desa,
      isExpanded: true,
      icon: const Icon(Icons.keyboard_arrow_down_rounded, color: _greenDark),
      decoration: _decoration(
        icon: Icons.location_city_outlined,
        hint: 'Pilih desa',
      ),
      style: const TextStyle(
        color: _greenDark,
        fontSize: 13.5,
        fontFamily: 'Montserrat',
      ),
      items: _desaOptions
          .map((d) => DropdownMenuItem(value: d, child: Text(d)))
          .toList(),
      onChanged: (v) => setState(() => _desa = v),
      validator: (v) => v == null ? 'Pilih desa' : null,
    );
  }

  Widget _alamatField() {
    return TextFormField(
      controller: _alamatCtrl,
      textInputAction: TextInputAction.next,
      decoration: _decoration(
        icon: Icons.near_me_outlined,
        hint: 'Jl. Wilangan Kulon No. 12',
        // Tombol lokasi: sementara hanya tampilan.
        suffix: IconButton(
          tooltip: 'Gunakan lokasi saat ini',
          icon: const Icon(
            Icons.my_location_rounded,
            color: _greenDark,
            size: 20,
          ),
          onPressed: () {
            // TODO: sambungkan ke GPS (geolocator) nanti.
          },
        ),
      ),
      validator: (v) {
        if ((v ?? '').trim().isEmpty) return 'Isi alamat penjemputan';
        if (v!.trim().length < 8) return 'Alamat terlalu singkat';
        return null;
      },
    );
  }

  Widget _keteranganField() {
    return TextFormField(
      controller: _keteranganCtrl,
      minLines: 3,
      maxLines: 5,
      maxLength: 200,
      textCapitalization: TextCapitalization.sentences,
      decoration: _decoration(
        hint: 'Jumlah, kondisi kemasan, patokan lokasi',
      ).copyWith(counterStyle: const TextStyle(fontSize: 11)),
    );
  }

  Widget _lanjutButton() {
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 14),
      color: _cream,
      child: SizedBox(
        width: double.infinity,
        height: 52,
        child: ElevatedButton(
          onPressed: _onLanjut,
          style: ElevatedButton.styleFrom(
            backgroundColor: _green,
            foregroundColor: Colors.white,
            elevation: 0,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(26),
            ),
          ),
          child: const Text(
            'Lanjut',
            style: TextStyle(fontSize: 15, fontWeight: FontWeight.w700),
          ),
        ),
      ),
    );
  }

  InputDecoration _decoration({
    IconData? icon,
    required String hint,
    Widget? suffix,
  }) {
    OutlineInputBorder border(Color c, [double w = 1]) => OutlineInputBorder(
      borderRadius: BorderRadius.circular(12),
      borderSide: BorderSide(color: c, width: w),
    );

    return InputDecoration(
      filled: true,
      fillColor: _field,
      hintText: hint,
      hintStyle: TextStyle(
        color: _greenDark.withValues(alpha: 0.4),
        fontSize: 13,
      ),
      prefixIcon: icon == null
          ? null
          : Padding(
              padding: const EdgeInsets.all(10),
              child: Container(
                decoration: BoxDecoration(
                  color: const Color(0xFFE3EFD9),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(icon, size: 18, color: _green),
              ),
            ),
      suffixIcon: suffix,
      contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
      enabledBorder: border(Colors.transparent),
      focusedBorder: border(_green, 1.5),
      errorBorder: border(const Color(0xFFD32F2F)),
      focusedErrorBorder: border(const Color(0xFFD32F2F), 1.5),
    );
  }
}

class _JenisB3 {
  final String label;
  final IconData icon;
  const _JenisB3(this.label, this.icon);
}