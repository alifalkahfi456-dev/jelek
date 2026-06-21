import 'dart:math';
import 'package:flutter/material.dart';
import 'package:audioplayers/audioplayers.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

class _C {
  static const bg      = Color(0xFF120000);
  static const s1      = Color(0xFF2A0000);
  static const s2      = Color(0xFF3D0000);
  static const border  = Color(0xFF5C0000);
  static const accent  = Color(0xFFE53935);
  static const accentL = Color(0xFFFF5252);
  static const green   = Color(0xFF4CAF50);
  static const red     = Color(0xFFFF1744);
  static const textP   = Color(0xFFFFF0F5);
  static const textS   = Color(0xFFFFCDD2);
  static const textM   = Color(0xFF8B0000);
  static const white   = Color(0xFFFFFFFF);
}

// Smoty Play - pencarian lagu via iTunes Search API (gratis, no key)
class MusikPage extends StatefulWidget {
  final AudioPlayer? sharedPlayer;
  final int? initialTrack;
  const MusikPage({super.key, this.sharedPlayer, this.initialTrack});
  @override State<MusikPage> createState() => _MusikPageState();
}

class _MusikPageState extends State<MusikPage> with SingleTickerProviderStateMixin {
  late AudioPlayer _player;
  late TabController _tab;
  final _searchCtrl = TextEditingController();

  bool _playing    = false;
  bool _shuffle    = false;
  bool _repeat     = false;
  Duration _pos    = Duration.zero;
  Duration _dur    = Duration.zero;

  // Search results
  List<Map<String, dynamic>> _results = [];
  bool _searching  = false;
  String _errMsg   = '';

  // Now playing
  Map<String, dynamic>? _nowPlaying;
  String _q        = '';

  @override
  void initState() {
    super.initState();
    _tab    = TabController(length: 2, vsync: this);
    _player = widget.sharedPlayer ?? AudioPlayer();
    _player.onPlayerStateChanged.listen((s) { if (mounted) setState(() => _playing = s == PlayerState.playing); });
    _player.onPositionChanged.listen((d)    { if (mounted) setState(() => _pos = d); });
    _player.onDurationChanged.listen((d)    { if (mounted) setState(() => _dur = d); });
    _player.onPlayerComplete.listen((_)     => _nextTrack());
    // Load chart default
    _search('top hits 2024');
  }

  @override
  void dispose() {
    _searchCtrl.dispose();
    _tab.dispose();
    if (widget.sharedPlayer == null) _player.dispose();
    super.dispose();
  }

  // iTunes Search API - cari lagu bebas
  Future<void> _search(String query) async {
    if (query.trim().isEmpty) return;
    setState(() { _searching = true; _errMsg = ''; });
    try {
      final url = Uri.parse(
        'https://itunes.apple.com/search?term=${Uri.encodeComponent(query)}&media=music&limit=25&entity=song'
      );
      final res = await http.get(url).timeout(const Duration(seconds: 10));
      final data = jsonDecode(res.body);
      final list = (data['results'] as List).map((t) => {
        'title':   t['trackName'] ?? '',
        'artist':  t['artistName'] ?? '',
        'album':   t['collectionName'] ?? '',
        'img':     t['artworkUrl100'] ?? '',
        'preview': t['previewUrl'] ?? '',
        'itunesUrl': t['trackViewUrl'] ?? '',
      }).where((t) => (t['preview'] as String).isNotEmpty).toList();
      setState(() { _results = list; _searching = false; });
    } catch (e) {
      setState(() { _errMsg = 'Gagal cari: $e'; _searching = false; });
    }
  }

  Future<void> _play(Map<String, dynamic> track) async {
    final url = track['preview'] as String;
    if (url.isEmpty) { _snack('Preview tidak tersedia'); return; }
    setState(() { _nowPlaying = track; _pos = Duration.zero; });
    await _player.stop();
    await _player.play(UrlSource(url));
  }

  void _togglePlay() {
    if (_playing) _player.pause();
    else if (_nowPlaying != null) _player.resume();
  }

  void _nextTrack() {
    if (_results.isEmpty || _nowPlaying == null) return;
    final idx = _results.indexWhere((t) => t['title'] == _nowPlaying!['title']);
    if (idx < 0) return;
    int next;
    if (_shuffle) {
      do { next = Random().nextInt(_results.length); } while (next == idx && _results.length > 1);
    } else if (_repeat) {
      next = idx;
    } else {
      next = (idx + 1) % _results.length;
    }
    _play(_results[next]);
  }

  void _prevTrack() {
    if (_results.isEmpty || _nowPlaying == null) return;
    final idx = _results.indexWhere((t) => t['title'] == _nowPlaying!['title']);
    if (idx < 0) return;
    _play(_results[(idx - 1 + _results.length) % _results.length]);
  }

  String _fmt(Duration d) {
    final m = d.inMinutes.remainder(60).toString().padLeft(2, '0');
    final s = d.inSeconds.remainder(60).toString().padLeft(2, '0');
    return '$m:$s';
  }

  void _snack(String msg) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Text(msg, style: const TextStyle(color: _C.white)),
      backgroundColor: _C.accent, behavior: SnackBarBehavior.floating,
    ));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _C.bg,
      body: SafeArea(child: Column(children: [

        // Header
        Container(
          color: _C.s1,
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          child: Row(children: [
            const Icon(Icons.music_note_rounded, color: _C.accentL, size: 20),
            const SizedBox(width: 10),
            const Text('Smoty Play', style: TextStyle(color: _C.textP, fontWeight: FontWeight.bold, fontSize: 16, letterSpacing: 1)),
            const Spacer(),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
              decoration: BoxDecoration(color: _C.accent.withOpacity(0.15), borderRadius: BorderRadius.circular(8), border: Border.all(color: _C.accentL.withOpacity(0.3))),
              child: const Text('30s Preview', style: TextStyle(color: _C.accentL, fontSize: 10)),
            ),
          ]),
        ),

        // Search bar
        Padding(
          padding: const EdgeInsets.fromLTRB(14, 12, 14, 0),
          child: Row(children: [
            Expanded(child: Container(
              decoration: BoxDecoration(color: _C.s1, borderRadius: BorderRadius.circular(12), border: Border.all(color: _C.border)),
              child: TextField(
                controller: _searchCtrl,
                onChanged: (v) => setState(() => _q = v),
                onSubmitted: (v) => _search(v),
                style: const TextStyle(color: _C.textP, fontSize: 13),
                decoration: const InputDecoration(
                  hintText: 'Cari lagu, artis, album...',
                  hintStyle: TextStyle(color: _C.textM),
                  prefixIcon: Icon(Icons.search_rounded, color: _C.textS, size: 18),
                  border: InputBorder.none,
                  contentPadding: EdgeInsets.symmetric(vertical: 12),
                ),
              ),
            )),
            const SizedBox(width: 8),
            GestureDetector(
              onTap: () => _search(_searchCtrl.text),
              child: Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(color: _C.accent, borderRadius: BorderRadius.circular(12)),
                child: const Icon(Icons.search_rounded, color: _C.white, size: 18),
              ),
            ),
          ]),
        ),

        // Quick genre chips
        Padding(
          padding: const EdgeInsets.fromLTRB(14, 10, 14, 4),
          child: SizedBox(height: 28, child: ListView(
            scrollDirection: Axis.horizontal,
            children: [
              'Top Hits', 'Lo-Fi', 'Pop', 'Hip-Hop', 'R&B', 'Electronic', 'Acoustic', 'K-Pop', 'Indonesia',
            ].map((g) => GestureDetector(
              onTap: () { _searchCtrl.text = g; _search(g); },
              child: Container(
                margin: const EdgeInsets.only(right: 6),
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                decoration: BoxDecoration(
                  color: _C.s1, borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: _C.border),
                ),
                child: Text(g, style: const TextStyle(color: _C.textS, fontSize: 11)),
              ),
            )).toList(),
          )),
        ),

        // Now Playing bar
        if (_nowPlaying != null) _buildNowPlaying(),

        // Results
        Expanded(child: _searching
          ? const Center(child: CircularProgressIndicator(color: _C.accentL))
          : _errMsg.isNotEmpty
            ? Center(child: Text(_errMsg, style: const TextStyle(color: _C.textS)))
            : _results.isEmpty
              ? const Center(child: Text('Cari lagu favoritmu', style: TextStyle(color: _C.textS)))
              : ListView.builder(
                  padding: const EdgeInsets.fromLTRB(14, 8, 14, 100),
                  itemCount: _results.length,
                  itemBuilder: (_, i) {
                    final t = _results[i];
                    final isPlaying = _nowPlaying != null && _nowPlaying!['title'] == t['title'] && _playing;
                    return GestureDetector(
                      onTap: () => _play(t),
                      child: Container(
                        margin: const EdgeInsets.only(bottom: 8),
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                        decoration: BoxDecoration(
                          color: isPlaying ? _C.accent.withOpacity(0.15) : _C.s1,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: isPlaying ? _C.accentL.withOpacity(0.4) : _C.border),
                        ),
                        child: Row(children: [
                          ClipRRect(
                            borderRadius: BorderRadius.circular(8),
                            child: t['img'] != ''
                              ? Image.network(t['img'] as String, width: 46, height: 46, fit: BoxFit.cover,
                                  errorBuilder: (_, __, ___) => Container(width: 46, height: 46, color: _C.s2, child: const Icon(Icons.music_note_rounded, color: _C.textM, size: 20)))
                              : Container(width: 46, height: 46, color: _C.s2, child: const Icon(Icons.music_note_rounded, color: _C.textM, size: 20)),
                          ),
                          const SizedBox(width: 12),
                          Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                            Text(t['title'] as String, style: TextStyle(color: isPlaying ? _C.textP : _C.textS, fontSize: 13, fontWeight: isPlaying ? FontWeight.bold : FontWeight.normal), maxLines: 1, overflow: TextOverflow.ellipsis),
                            const SizedBox(height: 2),
                            Text(t['artist'] as String, style: const TextStyle(color: _C.textM, fontSize: 11), maxLines: 1, overflow: TextOverflow.ellipsis),
                          ])),
                          if (isPlaying)
                            const Icon(Icons.graphic_eq_rounded, color: _C.accentL, size: 20)
                          else
                            const Icon(Icons.play_circle_outline_rounded, color: _C.textM, size: 20),
                        ]),
                      ),
                    );
                  },
                ),
        ),
      ])),
    );
  }

  Widget _buildNowPlaying() {
    final t = _nowPlaying!;
    return Container(
      margin: const EdgeInsets.fromLTRB(14, 8, 14, 0),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: _C.s1,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: _C.accentL.withOpacity(0.3)),
      ),
      child: Column(children: [
        Row(children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(10),
            child: t['img'] != ''
              ? Image.network(t['img'] as String, width: 52, height: 52, fit: BoxFit.cover,
                  errorBuilder: (_, __, ___) => Container(width: 52, height: 52, color: _C.s2, child: const Icon(Icons.music_note_rounded, color: _C.textM)))
              : Container(width: 52, height: 52, color: _C.s2, child: const Icon(Icons.music_note_rounded, color: _C.textM)),
          ),
          const SizedBox(width: 12),
          Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(t['title'] as String, style: const TextStyle(color: _C.textP, fontWeight: FontWeight.bold, fontSize: 13), maxLines: 1, overflow: TextOverflow.ellipsis),
            Text(t['artist'] as String, style: const TextStyle(color: _C.textS, fontSize: 11), maxLines: 1, overflow: TextOverflow.ellipsis),
          ])),
          // Controls
          Row(children: [
            GestureDetector(onTap: () => setState(() => _shuffle = !_shuffle),
              child: Icon(Icons.shuffle_rounded, color: _shuffle ? _C.green : _C.textM, size: 18)),
            const SizedBox(width: 8),
            GestureDetector(onTap: _prevTrack, child: const Icon(Icons.skip_previous_rounded, color: _C.textP, size: 22)),
            const SizedBox(width: 6),
            GestureDetector(onTap: _togglePlay,
              child: Container(width: 36, height: 36,
                decoration: const BoxDecoration(color: _C.green, shape: BoxShape.circle),
                child: Icon(_playing ? Icons.pause_rounded : Icons.play_arrow_rounded, color: _C.white, size: 20))),
            const SizedBox(width: 6),
            GestureDetector(onTap: _nextTrack, child: const Icon(Icons.skip_next_rounded, color: _C.textP, size: 22)),
            const SizedBox(width: 8),
            GestureDetector(onTap: () => setState(() => _repeat = !_repeat),
              child: Icon(Icons.repeat_rounded, color: _repeat ? _C.green : _C.textM, size: 18)),
          ]),
        ]),
        const SizedBox(height: 8),
        SliderTheme(
          data: SliderTheme.of(context).copyWith(
            activeTrackColor: _C.green, inactiveTrackColor: _C.border,
            thumbColor: _C.white, thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 5),
            overlayShape: SliderComponentShape.noThumb, trackHeight: 2,
          ),
          child: Slider(
            value: _dur.inSeconds > 0 ? (_pos.inSeconds / _dur.inSeconds).clamp(0.0, 1.0) : 0.0,
            onChanged: (v) { if (_dur.inSeconds > 0) _player.seek(Duration(seconds: (v * _dur.inSeconds).toInt())); },
          ),
        ),
        Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
          Text(_fmt(_pos), style: const TextStyle(color: _C.textM, fontSize: 10)),
          Text(_fmt(_dur), style: const TextStyle(color: _C.textM, fontSize: 10)),
        ]),
      ]),
    );
  }
}
