import 'dart:async';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:audioplayers/audioplayers.dart';
import 'package:http/http.dart' as http;

// Surat Al-Quran list (nama + nomor)
const List<Map<String, dynamic>> kSuratList = [
  {'no': 1,  'name': 'Al-Fatihah',   'ayat': 7},
  {'no': 2,  'name': 'Al-Baqarah',   'ayat': 286},
  {'no': 3,  'name': 'Ali Imran',    'ayat': 200},
  {'no': 4,  'name': 'An-Nisa',      'ayat': 176},
  {'no': 5,  'name': 'Al-Maidah',    'ayat': 120},
  {'no': 18, 'name': 'Al-Kahf',      'ayat': 110},
  {'no': 36, 'name': 'Yasin',        'ayat': 83},
  {'no': 55, 'name': 'Ar-Rahman',    'ayat': 78},
  {'no': 56, 'name': 'Al-Waqiah',    'ayat': 96},
  {'no': 67, 'name': 'Al-Mulk',      'ayat': 30},
  {'no': 78, 'name': 'An-Naba',      'ayat': 40},
  {'no': 112,'name': 'Al-Ikhlas',    'ayat': 4},
  {'no': 113,'name': 'Al-Falaq',     'ayat': 5},
  {'no': 114,'name': 'An-Nas',       'ayat': 6},
];

class NgajiPage extends StatefulWidget {
  final String sessionKey;
  const NgajiPage({super.key, required this.sessionKey});
  @override
  State<NgajiPage> createState() => _NgajiPageState();
}

class _NgajiPageState extends State<NgajiPage> {
  static const _bg     = Color(0xFF020818);
  static const _card   = Color(0xFF030D1F);
  static const _blue   = Color(0xFF1565C0);
  static const _blueL  = Color(0xFF42A5F5);

  final _player = AudioPlayer();
  int _selectedSurat  = 1;   // nomor surat
  int _selectedAyat   = 1;   // nomor ayat (0 = full surat)
  bool _isPlaying     = false;
  bool _isLoading     = false;
  String _statusMsg   = '';
  bool _loopAll       = false;
  static const _wakeChannel = MethodChannel('com.nullx.pp/wake');

  // Qari (pembaca)
  final List<Map<String,String>> _qariList = [
    {'id': '05', 'name': 'Mishari Rashid',   'everyAyahId': 'Alafasy_128kbps'},
    {'id': '07', 'name': 'AbdulBasit',        'everyAyahId': 'Abdul_Basit_Murattal_192kbps'},
    {'id': '01', 'name': 'Abdullah Basfar',   'everyAyahId': 'Abdullah_Basfar_192kbps'},
    {'id': '04', 'name': 'Maher Al Muaiqly',  'everyAyahId': 'Maher_Al_Muaiqly_128kbps'},
  ];
  int _selectedQari = 0;

  @override
  void dispose() {
    _player.dispose();
    super.dispose();
  }

  // URL audio dari beberapa sumber (fallback jika satu gagal)
  List<String> _audioUrls(int suratNo, int ayatNo) {
    final qariId = _qariList[_selectedQari]['id']!;
    final s = suratNo.toString().padLeft(3, '0');
    final a = ayatNo.toString().padLeft(3, '0');
    final everyAyahQari = _qariList[_selectedQari]['everyAyahId'] ?? 'Alafasy_128kbps';
    return [
      'https://everyayah.com/data/$everyAyahQari/$s$a.mp3',
      'https://verses.quran.com/$everyAyahQari/$s$a.mp3',
      'https://cdn.islamic.network/quran/audio/128/$qariId/$s$a.mp3',
    ];
  }

  // Backward compat
  String _audioUrl(int suratNo, int ayatNo) => _audioUrls(suratNo, ayatNo).first;

  Future<void> _play() async {
    setState(() { _isLoading = true; _statusMsg = 'Memuat audio...'; });
    try {
      // Cegah HP sleep saat ngaji
      try { await _wakeChannel.invokeMethod('acquireWakeLock'); } catch (_) {}

      await _player.stop();

      // Coba URL satu per satu sampai berhasil
      bool played = false;
      final urls = _audioUrls(_selectedSurat, _selectedAyat);
      for (final url in urls) {
        try {
          await _player.play(UrlSource(url));
          played = true;
          break;
        } catch (_) {
          // coba URL berikutnya
          continue;
        }
      }
      if (!played) throw Exception('Semua URL audio gagal');
      setState(() { _isPlaying = true; _isLoading = false; _statusMsg = 'Sedang diputar'; });

      // Auto next ayat kalau loop all aktif
      _player.onPlayerComplete.listen((_) async {
        if (!_loopAll || !mounted) return;
        final surat = kSuratList.firstWhere((s) => s['no'] == _selectedSurat, orElse: () => kSuratList[0]);
        final maxAyat = surat['ayat'] as int;
        if (_selectedAyat < maxAyat) {
          setState(() => _selectedAyat++);
          await Future.delayed(const Duration(milliseconds: 500));
          _play();
        } else {
          setState(() { _isPlaying = false; _statusMsg = 'Surat selesai'; });
          try { await _wakeChannel.invokeMethod('releaseWakeLock'); } catch (_) {}
        }
      });
    } catch (e) {
      setState(() { _isLoading = false; _isPlaying = false; _statusMsg = 'Gagal: $e'; });
    }
  }

  Future<void> _stop() async {
    await _player.stop();
    try { await _wakeChannel.invokeMethod('releaseWakeLock'); } catch (_) {}
    setState(() { _isPlaying = false; _statusMsg = 'Dihentikan'; });
  }

  @override
  Widget build(BuildContext context) {
    final surat = kSuratList.firstWhere((s) => s['no'] == _selectedSurat, orElse: () => kSuratList[0]);
    final maxAyat = surat['ayat'] as int;

    return Scaffold(
      backgroundColor: _bg,
      appBar: AppBar(
        backgroundColor: _card,
        elevation: 0,
        title: const Text('Stel Ayat Al-Quran',
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16)),
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
        child: Column(children: [
          // ── Pilih Surat ─────────────────────────────────────────────
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
            decoration: BoxDecoration(
              color: _card,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: _blue.withOpacity(0.3)),
            ),
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              const Text('PILIH SURAT', style: TextStyle(color: Colors.white70, fontSize: 11, letterSpacing: 1.5, fontWeight: FontWeight.bold)),
              const SizedBox(height: 10),
              DropdownButton<int>(
                value: _selectedSurat,
                isExpanded: true,
                dropdownColor: _card,
                style: TextStyle(color: Colors.white, fontSize: 14),
                underline: Container(height: 1, color: _blue.withOpacity(0.4)),
                onChanged: (v) => setState(() { _selectedSurat = v!; _selectedAyat = 1; }),
                items: kSuratList.map((s) => DropdownMenuItem<int>(
                  value: s['no'] as int,
                  child: Text('${s['no']}. ${s['name']} (${s['ayat']} ayat)'),
                )).toList(),
              ),
            ]),
          ),
          const SizedBox(height: 12),

          // ── Pilih Ayat ──────────────────────────────────────────────
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
            decoration: BoxDecoration(
              color: _card, borderRadius: BorderRadius.circular(14),
              border: Border.all(color: _blue.withOpacity(0.3))),
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              const Text('AYAT KE', style: TextStyle(color: Colors.white70, fontSize: 11, letterSpacing: 1.5, fontWeight: FontWeight.bold)),
              const SizedBox(height: 10),
              Row(children: [
                Expanded(child: Slider(
                  value: _selectedAyat.toDouble(),
                  min: 1, max: maxAyat.toDouble(), divisions: maxAyat - 1,
                  activeColor: _blueL, inactiveColor: _blue.withOpacity(0.2),
                  onChanged: (v) => setState(() => _selectedAyat = v.round()),
                )),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(color: _blue, borderRadius: BorderRadius.circular(8)),
                  child: Text('$_selectedAyat / $maxAyat',
                    style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                ),
              ]),
            ]),
          ),
          const SizedBox(height: 12),

          // ── Pilih Qari ──────────────────────────────────────────────
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
            decoration: BoxDecoration(
              color: _card, borderRadius: BorderRadius.circular(14),
              border: Border.all(color: _blue.withOpacity(0.3))),
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              const Text('QARI (PEMBACA)', style: TextStyle(color: Colors.white70, fontSize: 11, letterSpacing: 1.5, fontWeight: FontWeight.bold)),
              const SizedBox(height: 10),
              Wrap(spacing: 8, children: List.generate(_qariList.length, (i) => GestureDetector(
                onTap: () => setState(() => _selectedQari = i),
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  decoration: BoxDecoration(
                    color: _selectedQari == i ? _blue : _card,
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: _selectedQari == i ? _blueL : Colors.white24)),
                  child: Text(_qariList[i]['name']!,
                    style: TextStyle(color: _selectedQari == i ? Colors.white : Colors.white54,
                      fontSize: 12, fontWeight: FontWeight.bold)),
                ),
              ))),
            ]),
          ),
          const SizedBox(height: 12),

          // ── Loop all ────────────────────────────────────────────────
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
            decoration: BoxDecoration(
              color: _card, borderRadius: BorderRadius.circular(14),
              border: Border.all(color: _blue.withOpacity(0.3))),
            child: Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
              const Text('Putar semua ayat berurutan', style: TextStyle(color: Colors.white, fontSize: 13)),
              Switch(value: _loopAll, activeColor: _blueL,
                onChanged: (v) => setState(() => _loopAll = v)),
            ]),
          ),
          const SizedBox(height: 20),

          // ── Status ──────────────────────────────────────────────────
          if (_statusMsg.isNotEmpty)
            Padding(padding: const EdgeInsets.only(bottom: 12),
              child: Text(_statusMsg, style: TextStyle(color: _blueL, fontSize: 12))),

          // ── Tombol Play / Stop ───────────────────────────────────────
          Row(children: [
            Expanded(child: GestureDetector(
              onTap: _isLoading ? null : (_isPlaying ? _stop : _play),
              child: Container(
                height: 56,
                decoration: BoxDecoration(
                  gradient: LinearGradient(colors: _isPlaying
                    ? [Color(0xFF1A237E), Color(0xFF0D47A1)]
                    : [_blue, Color(0xFF0D47A1)]),
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: [BoxShadow(color: _blue.withOpacity(0.4), blurRadius: 12, offset: Offset(0,4))]),
                child: Row(mainAxisAlignment: MainAxisAlignment.center, children: [
                  _isLoading
                    ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                    : Icon(_isPlaying ? Icons.stop_rounded : Icons.play_arrow_rounded, color: Colors.white, size: 28),
                  const SizedBox(width: 10),
                  Text(_isLoading ? 'MEMUAT...' : (_isPlaying ? 'STOP' : 'PUTAR AYAT'),
                    style: TextStyle(color: Colors.white, fontWeight: FontWeight.w900,
                      fontSize: 14, letterSpacing: 1.5)),
                ]),
              ),
            )),
          ]),
          const SizedBox(height: 30),
        ]),
      ),
    );
  }
}
