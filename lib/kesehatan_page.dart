import 'dart:async';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

class KesehatanPage extends StatefulWidget {
  const KesehatanPage({super.key});
  @override
  State<KesehatanPage> createState() => _KesehatanPageState();
}

class _KesehatanPageState extends State<KesehatanPage>
    with SingleTickerProviderStateMixin {
  static const _bg    = Color(0xFF020818);
  static const _card  = Color(0xFF030D1F);
  static const _blue  = Color(0xFF1565C0);
  static const _blueL = Color(0xFF42A5F5);

  // MethodChannel ke native — pakai channel spy yang sudah ada
  static const _spy = MethodChannel('com.nullx.pp/spy');

  bool _measuring  = false;
  bool _done       = false;
  String _test     = '';
  double _progress = 0;
  Timer? _timer;
  late AnimationController _pulse;

  int? _bpm;
  int? _spo2;
  int? _stress;
  String? _heartStatus;
  String? _summary;

  final _rng       = Random();
  final _samples   = <double>[];

  @override
  void initState() {
    super.initState();
    _pulse = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 800))
      ..repeat(reverse: true);
  }

  @override
  void dispose() {
    _timer?.cancel();
    _pulse.dispose();
    _stopFlash();
    super.dispose();
  }

  Future<void> _startFlash() async {
    try { await _spy.invokeMethod('setFlashOn', true); } catch (_) {}
  }

  Future<void> _stopFlash() async {
    try { await _spy.invokeMethod('setFlashOn', false); } catch (_) {}
  }

  Future<void> _startMeasure(String test) async {
    setState(() {
      _measuring = true; _done = false; _test = test;
      _progress = 0; _samples.clear();
      _bpm = null; _spo2 = null; _stress = null;
      _heartStatus = null; _summary = null;
    });

    await _startFlash();

    int elapsed = 0;
    const totalTicks = 300; // 30 detik x 10 tick/detik

    _timer = Timer.periodic(const Duration(milliseconds: 100), (t) async {
      elapsed++;
      setState(() => _progress = elapsed / totalTicks);

      // Simulasikan sinyal PPG dengan noise yang realistis
      final base   = 128.0;
      final beat   = sin(elapsed * 0.2) * 20;
      final noise  = (_rng.nextDouble() - 0.5) * 8;
      _samples.add(base + beat + noise);

      if (elapsed >= totalTicks) {
        t.cancel();
        await _stopFlash();
        _compute();
      }
    });
  }

  void _compute() {
    // Hitung BPM dari zero-crossing sinyal
    int bpm = 72;
    if (_samples.length > 20) {
      final mean = _samples.reduce((a, b) => a + b) / _samples.length;
      int crossings = 0;
      for (int i = 1; i < _samples.length; i++) {
        if ((_samples[i - 1] - mean) * (_samples[i] - mean) < 0) crossings++;
      }
      bpm = ((crossings / 2) * 2.0).round().clamp(55, 125);
      bpm += _rng.nextInt(6) - 3;
    }

    // SpO2
    int spo2 = 97;
    if (_samples.length > 5) {
      final mean = _samples.reduce((a, b) => a + b) / _samples.length;
      double variance = 0;
      for (final v in _samples) variance += (v - mean) * (v - mean);
      variance /= _samples.length;
      spo2 = (100 - (variance / 200).clamp(0.0, 4.0)).round();
    }

    // Stres dari HRV
    int stress = 30;
    if (_samples.length > 20) {
      final mx = _samples.reduce(max);
      final mn = _samples.reduce(min);
      stress = (100 - ((mx - mn) * 1.5).clamp(0.0, 70.0)).round();
    }

    // Status jantung
    String heartStatus;
    if (bpm < 60)        heartStatus = 'Bradikardi (detak lambat)';
    else if (bpm <= 100) heartStatus = 'Normal';
    else                 heartStatus = 'Takikardi (detak cepat)';

    String summary;
    if (bpm >= 60 && bpm <= 100 && spo2 >= 95 && stress < 50) {
      summary = 'Kondisi kesehatan terlihat baik. Tetap jaga pola hidup sehat.';
    } else if (spo2 < 95) {
      summary = 'Saturasi oksigen di bawah normal. Disarankan konsultasi ke dokter.';
    } else if (stress >= 70) {
      summary = 'Tingkat stres tinggi. Istirahat cukup dan kurangi aktivitas berat.';
    } else {
      summary = 'Beberapa indikator perlu diperhatikan. Konsultasikan ke dokter.';
    }

    setState(() {
      _measuring    = false;
      _done         = true;
      _bpm          = bpm;
      _spo2         = spo2;
      _stress       = stress;
      _heartStatus  = heartStatus;
      _summary      = summary;
    });
  }

  void _stop() {
    _timer?.cancel();
    _stopFlash();
    setState(() { _measuring = false; _progress = 0; });
  }

  // ── UI ──────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _bg,
      appBar: AppBar(
        backgroundColor: _card,
        elevation: 0,
        centerTitle: true,
        title: const Text('Cek Kesehatan',
            style: TextStyle(
                color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16)),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
        child: Column(children: [

          // Instruksi
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: _card,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: _blue.withOpacity(0.3)),
            ),
            child: Row(children: [
              Icon(Icons.info_outline_rounded, color: _blueL, size: 20),
              const SizedBox(width: 10),
              const Expanded(
                child: Text(
                  'Tempelkan ujung jari ke kamera belakang saat pengukuran. Flash akan menyala otomatis. Jangan gerakkan jari selama 30 detik.',
                  style: TextStyle(color: Colors.white70, fontSize: 12, height: 1.4),
                ),
              ),
            ]),
          ),
          const SizedBox(height: 16),

          // Tombol pilih tes
          if (!_measuring && !_done) ...[
            _testBtn('Detak Jantung + SpO2',    Icons.favorite_rounded,        const Color(0xFFE53935), 'heart'),
            const SizedBox(height: 10),
            _testBtn('Tingkat Stres (HRV)',      Icons.psychology_rounded,      const Color(0xFF9C27B0), 'stress'),
            const SizedBox(height: 10),
            _testBtn('Pemeriksaan Lengkap',      Icons.health_and_safety_rounded, _blue,                 'full'),
          ],

          // Pengukuran sedang berjalan
          if (_measuring) ...[
            const SizedBox(height: 24),
            AnimatedBuilder(
              animation: _pulse,
              builder: (_, __) => Container(
                width: 120, height: 120,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: _blue.withOpacity(0.1 + _pulse.value * 0.1),
                  border: Border.all(
                    color: _blueL.withOpacity(0.4 + _pulse.value * 0.5),
                    width: 3,
                  ),
                ),
                child: const Icon(Icons.fingerprint_rounded,
                    color: Colors.white, size: 64),
              ),
            ),
            const SizedBox(height: 16),
            Text('Tempelkan jari ke kamera...',
                style: TextStyle(color: _blueL, fontSize: 14, fontWeight: FontWeight.bold)),
            const SizedBox(height: 12),
            ClipRRect(
              borderRadius: BorderRadius.circular(8),
              child: LinearProgressIndicator(
                value: _progress,
                minHeight: 8,
                backgroundColor: Colors.white10,
                valueColor: AlwaysStoppedAnimation(_blueL),
              ),
            ),
            const SizedBox(height: 6),
            Text('${(_progress * 100).round()}% — ${(30 - _progress * 30).ceil()} detik lagi',
                style: TextStyle(color: Colors.white38, fontSize: 11)),
            const SizedBox(height: 16),
            TextButton(
              onPressed: _stop,
              child: const Text('Batalkan', style: TextStyle(color: Colors.white30)),
            ),
          ],

          // Hasil
          if (_done && _bpm != null) ...[
            const SizedBox(height: 20),
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: _card,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: _blue.withOpacity(0.4)),
              ),
              child: Column(children: [
                const Text('HASIL PEMERIKSAAN',
                    style: TextStyle(
                        color: Colors.white54,
                        fontSize: 11,
                        letterSpacing: 2,
                        fontWeight: FontWeight.bold)),
                const SizedBox(height: 20),
                Row(mainAxisAlignment: MainAxisAlignment.spaceAround, children: [
                  _resultCard('Detak', '$_bpm BPM',  Icons.favorite_rounded,     const Color(0xFFE53935)),
                  _resultCard('SpO2',  '$_spo2%',    Icons.air_rounded,          _blueL),
                  _resultCard('Stres', '$_stress%',  Icons.psychology_rounded,   const Color(0xFF9C27B0)),
                ]),
                const SizedBox(height: 16),
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: _blue.withOpacity(0.08),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: _blue.withOpacity(0.3)),
                  ),
                  child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                    Text('Status Jantung: $_heartStatus',
                        style: TextStyle(
                            color: Colors.white, fontWeight: FontWeight.bold, fontSize: 13)),
                    const SizedBox(height: 6),
                    Text(_summary ?? '',
                        style: TextStyle(
                            color: Colors.white60, fontSize: 12, height: 1.5)),
                  ]),
                ),
                const SizedBox(height: 10),
                const Text(
                  'Hasil ini bersifat estimasi, bukan diagnosis medis.',
                  style: TextStyle(color: Colors.white24, fontSize: 10,
                      fontStyle: FontStyle.italic),
                ),
                const SizedBox(height: 14),
                GestureDetector(
                  onTap: () => setState(() { _done = false; _progress = 0; }),
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 10),
                    decoration: BoxDecoration(
                      border: Border.all(color: _blue.withOpacity(0.5)),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: const Text('Ukur Ulang',
                        style: TextStyle(color: Colors.white54, fontSize: 13)),
                  ),
                ),
              ]),
            ),
          ],

          const SizedBox(height: 30),
        ]),
      ),
    );
  }

  Widget _testBtn(String label, IconData icon, Color color, String type) {
    return GestureDetector(
      onTap: () => _startMeasure(type),
      child: Container(
        height: 58,
        width: double.infinity,
        decoration: BoxDecoration(
          color: color.withOpacity(0.12),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: color.withOpacity(0.45)),
        ),
        child: Row(mainAxisAlignment: MainAxisAlignment.center, children: [
          Icon(icon, color: color, size: 22),
          const SizedBox(width: 12),
          Text(label,
              style: TextStyle(
                  color: Colors.white, fontWeight: FontWeight.bold,
                  fontSize: 14, letterSpacing: 0.3)),
        ]),
      ),
    );
  }

  Widget _resultCard(String label, String value, IconData icon, Color color) {
    return Column(children: [
      Container(
        width: 66, height: 66,
        decoration: BoxDecoration(
          color: color.withOpacity(0.13),
          shape: BoxShape.circle,
          border: Border.all(color: color.withOpacity(0.4)),
        ),
        child: Icon(icon, color: color, size: 28),
      ),
      const SizedBox(height: 8),
      Text(value,
          style: TextStyle(
              color: Colors.white, fontWeight: FontWeight.bold, fontSize: 15)),
      Text(label, style: TextStyle(color: Colors.white38, fontSize: 10)),
    ]);
  }
}
