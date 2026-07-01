import 'dart:math' as math;
import 'dart:async';
import 'package:flutter/material.dart';
import 'package:audioplayers/audioplayers.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

// ─── PALETTE PURPLE CYBER ──────────────────────────────────────────────────
class _C {
  static const bg          = Color(0xFF0A0015);
  static const surface     = Color(0xFF15002A);
  static const s1          = Color(0xFF1A0A2E);
  static const s2          = Color(0xFF2D1B4E);
  static const border      = Color(0xFF5B2D8E);
  static const borderGlow  = Color(0xFF7C3AED);
  static const purple      = Color(0xFF7C3AED);
  static const purpleL     = Color(0xFFA78BFA);
  static const purpleG     = Color(0xFFF0ABFC);
  static const pink        = Color(0xFFE879F9);
  static const green       = Color(0xFFA78BFA);
  static const red         = Color(0xFFD946EF);
  static const textP       = Color(0xFFF3E8FF);
  static const textS       = Color(0xFFD4C4F0);
  static const textM       = Color(0xFF8B7AAA);
  static const white       = Color(0xFFFFFFFF);
  static const gold        = Color(0xFFE879F9);
}

class MusikPage extends StatefulWidget {
  final AudioPlayer? sharedPlayer;
  final int? initialTrack;
  final String username;
  
  const MusikPage({
    super.key, 
    this.sharedPlayer, 
    this.initialTrack,
    required this.username,
  });
  
  @override State<MusikPage> createState() => _MusikPageState();
}

class _MusikPageState extends State<MusikPage> with SingleTickerProviderStateMixin {
  late AudioPlayer _player;
  late TabController _tab;
  final _searchCtrl = TextEditingController();
  late ScrollController _scrollController;

  bool _playing    = false;
  bool _shuffle    = false;
  bool _repeat     = false;
  bool _isSearching = false;
  Duration _pos    = Duration.zero;
  Duration _dur    = Duration.zero;
  double _scrollOffset = 0.0;

  List<Map<String, dynamic>> _results = [];
  Map<String, dynamic>? _nowPlaying;
  String _q        = '';
  String _errMsg   = '';
  
  // Digital Clock
  String _wib = '';
  String _wita = '';
  String _wit = '';

  Timer? _clockTimer;
  
  // Animations
  late AnimationController _gradientCtrl;
  late AnimationController _pulseCtrl;
  late AnimationController _scanCtrl;

  @override
  void initState() {
    super.initState();
    _tab    = TabController(length: 2, vsync: this);
    _scrollController = ScrollController()..addListener(() {
      setState(() {
        _scrollOffset = _scrollController.offset;
      });
    });
    
    _gradientCtrl = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 8),
    )..repeat();
    
    _pulseCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    )..repeat(reverse: true);
    
    _scanCtrl = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 3),
    )..repeat();
    
    _player = widget.sharedPlayer ?? AudioPlayer();
    _player.onPlayerStateChanged.listen((s) { 
      if (mounted) setState(() => _playing = s == PlayerState.playing); 
    });
    _player.onPositionChanged.listen((d) { 
      if (mounted) setState(() => _pos = d); 
    });
    _player.onDurationChanged.listen((d) { 
      if (mounted) setState(() => _dur = d); 
    });
    _player.onPlayerComplete.listen((_) => _nextTrack());
    
    _updateClock();
    _clockTimer = Timer.periodic(const Duration(seconds: 1), (_) => _updateClock());
    
    _search('top hits 2024');
  }

  @override
  void dispose() {
    _searchCtrl.dispose();
    _tab.dispose();
    _scrollController.dispose();
    _clockTimer?.cancel();
    _gradientCtrl.dispose();
    _pulseCtrl.dispose();
    _scanCtrl.dispose();
    if (widget.sharedPlayer == null) _player.dispose();
    super.dispose();
  }

  void _updateClock() {
    final now = DateTime.now();
    final wib = now.toLocal();
    final wita = wib.add(const Duration(hours: 1));
    final wit = wib.add(const Duration(hours: 2));
    setState(() {
      _wib = _formatTime(wib);
      _wita = _formatTime(wita);
      _wit = _formatTime(wit);
    });
  }

  String _formatTime(DateTime t) {
    return '${t.hour.toString().padLeft(2, '0')}:${t.minute.toString().padLeft(2, '0')}:${t.second.toString().padLeft(2, '0')}';
  }

  Future<void> _search(String query) async {
    if (query.trim().isEmpty) return;
    setState(() { _isSearching = true; _errMsg = ''; });
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
      setState(() { _results = list; _isSearching = false; });
    } catch (e) {
      setState(() { _errMsg = 'Gagal cari: $e'; _isSearching = false; });
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
      do { next = math.Random().nextInt(_results.length); } while (next == idx && _results.length > 1);
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
      backgroundColor: _C.purple,
      behavior: SnackBarBehavior.floating,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
    ));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _C.bg,
      body: Stack(
        children: [
          // Animated gradient background
          AnimatedBuilder(
            animation: _gradientCtrl,
            builder: (_, __) {
              return Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment(
                      math.sin(_gradientCtrl.value * 2 * math.pi),
                      math.cos(_gradientCtrl.value * 2 * math.pi),
                    ),
                    end: Alignment(
                      math.cos(_gradientCtrl.value * 2 * math.pi),
                      math.sin(_gradientCtrl.value * 2 * math.pi),
                    ),
                    colors: [
                      _C.bg,
                      _C.surface,
                      _C.s1,
                    ],
                  ),
                ),
              );
            },
          ),
          
          // Glow effects
          Positioned(
            top: -100,
            right: -50,
            child: Container(
              width: 400,
              height: 400,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: RadialGradient(
                  colors: [_C.purple.withOpacity(0.06), Colors.transparent],
                  radius: 0.8,
                ),
              ),
            ),
          ),
          Positioned(
            bottom: -100,
            left: -50,
            child: Container(
              width: 400,
              height: 400,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: RadialGradient(
                  colors: [_C.purpleG.withOpacity(0.04), Colors.transparent],
                  radius: 0.8,
                ),
              ),
            ),
          ),
          
          // ─── GARIS BAWAH MENGIKUTI SCROLL ─────────────────────────────
          Positioned(
            top: 0,
            left: 0,
            right: 0,
            child: Container(
              height: 2,
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    Colors.transparent,
                    _C.purple.withOpacity(0.6),
                    _C.purpleG,
                    _C.purpleL,
                    _C.purple.withOpacity(0.6),
                    Colors.transparent,
                  ],
                  stops: const [0.0, 0.15, 0.4, 0.6, 0.85, 1.0],
                ),
                boxShadow: [
                  BoxShadow(
                    color: _C.purple.withOpacity(0.5),
                    blurRadius: 20,
                    spreadRadius: 3,
                  ),
                ],
              ),
            ),
          ),
          
          SafeArea(
            child: Column(
              children: [
                _buildCyberHeader(),
                _buildDigitalClock(),
                _buildSearchBar(),
                _buildGenreChips(),
                if (_nowPlaying != null) _buildNowPlaying(),
                Expanded(
                  child: _isSearching
                    ? _buildLoading()
                    : _errMsg.isNotEmpty
                      ? _buildError()
                      : _results.isEmpty
                        ? _buildEmpty()
                        : _buildResultList(),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ─── CYBER HEADER ─────────────────────────────────────────────────────────
  Widget _buildCyberHeader() {
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [_C.s1.withOpacity(0.6), _C.bg],
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
        ),
        border: Border(
          bottom: BorderSide(
            color: _C.purple.withOpacity(0.15),
            width: 0.5,
          ),
        ),
      ),
      child: Row(
        children: [
          AnimatedBuilder(
            animation: _pulseCtrl,
            builder: (_, __) {
              return Transform.rotate(
                angle: _pulseCtrl.value * 0.2,
                child: Container(
                  padding: const EdgeInsets.all(6),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [_C.purple, _C.purpleG],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    borderRadius: BorderRadius.circular(10),
                    boxShadow: [
                      BoxShadow(
                        color: _C.purple.withOpacity(0.3 + _pulseCtrl.value * 0.3),
                        blurRadius: 16 + _pulseCtrl.value * 8,
                        spreadRadius: 2,
                      ),
                    ],
                  ),
                  child: const Icon(
                    Icons.music_note_rounded,
                    color: _C.white,
                    size: 18,
                  ),
                ),
              );
            },
          ),
          const SizedBox(width: 12),
          const Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'NEON MUSIC',
                style: TextStyle(
                  color: _C.white,
                  fontWeight: FontWeight.w900,
                  fontSize: 16,
                  letterSpacing: 2,
                ),
              ),
              Text(
                '30s Preview • Purple Cyber',
                style: TextStyle(
                  color: _C.textM,
                  fontSize: 9,
                  letterSpacing: 1,
                ),
              ),
            ],
          ),
          const Spacer(),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
            decoration: BoxDecoration(
              color: _C.purple.withOpacity(0.1),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(
                color: _C.purpleL.withOpacity(0.3),
                width: 0.5,
              ),
            ),
            child: Row(
              children: [
                AnimatedContainer(
                  duration: const Duration(milliseconds: 500),
                  width: 6,
                  height: 6,
                  decoration: BoxDecoration(
                    color: _C.green,
                    shape: BoxShape.circle,
                    boxShadow: [
                      BoxShadow(
                        color: _C.green.withOpacity(0.5),
                        blurRadius: 8,
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 6),
                const Text(
                  'LIVE',
                  style: TextStyle(
                    color: _C.textS,
                    fontSize: 9,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 1,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ─── DIGITAL CLOCK ──────────────────────────────────────────────────────
  Widget _buildDigitalClock() {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [_C.s1.withOpacity(0.4), _C.bg],
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
        ),
        border: Border(
          bottom: BorderSide(
            color: _C.purple.withOpacity(0.1),
            width: 0.5,
          ),
        ),
      ),
      child: Column(
        children: [
          // ─── GARIS ATAS GLOW ─────────────────────────────────────────
          Container(
            height: 2,
            margin: const EdgeInsets.only(bottom: 10),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  Colors.transparent,
                  _C.purple.withOpacity(0.6),
                  _C.purpleG,
                  _C.purpleL,
                  _C.purple.withOpacity(0.6),
                  Colors.transparent,
                ],
                stops: const [0.0, 0.15, 0.4, 0.6, 0.85, 1.0],
              ),
              boxShadow: [
                BoxShadow(
                  color: _C.purple.withOpacity(0.4),
                  blurRadius: 16,
                  spreadRadius: 2,
                ),
              ],
            ),
          ),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              _buildClockItem('WIB', _wib, _C.purpleL),
              _buildClockItem('WITA', _wita, _C.purpleG),
              _buildClockItem('WIT', _wit, _C.pink),
            ],
          ),
          // ─── GARIS BAWAH SCAN ────────────────────────────────────────
          Container(
            height: 1,
            margin: const EdgeInsets.only(top: 10),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  Colors.transparent,
                  _C.purple.withOpacity(0.3),
                  Colors.transparent,
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildClockItem(String label, String time, Color color) {
    return AnimatedBuilder(
      animation: _pulseCtrl,
      builder: (_, __) {
        return Column(
          children: [
            Text(
              label,
              style: TextStyle(
                color: color.withOpacity(0.5 + _pulseCtrl.value * 0.3),
                fontSize: 9,
                fontWeight: FontWeight.w600,
                letterSpacing: 2,
              ),
            ),
            const SizedBox(height: 4),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              decoration: BoxDecoration(
                color: Colors.black.withOpacity(0.3),
                borderRadius: BorderRadius.circular(6),
                border: Border.all(
                  color: color.withOpacity(0.2 + _pulseCtrl.value * 0.2),
                  width: 0.5,
                ),
                boxShadow: [
                  BoxShadow(
                    color: color.withOpacity(0.1 * _pulseCtrl.value),
                    blurRadius: 10,
                  ),
                ],
              ),
              child: Text(
                time,
                style: TextStyle(
                  color: color,
                  fontSize: 14,
                  fontWeight: FontWeight.w700,
                  fontFamily: 'monospace',
                  letterSpacing: 2,
                  shadows: [
                    Shadow(
                      color: color.withOpacity(0.3 * _pulseCtrl.value),
                      blurRadius: 12,
                    ),
                  ],
                ),
              ),
            ),
          ],
        );
      },
    );
  }

  // ─── SEARCH BAR ──────────────────────────────────────────────────────────
  Widget _buildSearchBar() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(14, 10, 14, 6),
      child: Row(
        children: [
          Expanded(
            child: Container(
              decoration: BoxDecoration(
                color: _C.s1,
                borderRadius: BorderRadius.circular(14),
                border: Border.all(
                  color: _C.purple.withOpacity(0.2),
                  width: 0.5,
                ),
                boxShadow: [
                  BoxShadow(
                    color: _C.purple.withOpacity(0.05),
                    blurRadius: 8,
                  ),
                ],
              ),
              child: TextField(
                controller: _searchCtrl,
                onChanged: (v) => setState(() => _q = v),
                onSubmitted: (v) => _search(v),
                style: const TextStyle(
                  color: _C.textP,
                  fontSize: 13,
                  fontWeight: FontWeight.w400,
                ),
                decoration: InputDecoration(
                  hintText: 'Cari lagu, artis, album...',
                  hintStyle: TextStyle(
                    color: _C.textM.withOpacity(0.6),
                    fontSize: 12,
                  ),
                  prefixIcon: Icon(
                    Icons.search_rounded,
                    color: _C.textM.withOpacity(0.6),
                    size: 18,
                  ),
                  border: InputBorder.none,
                  contentPadding: const EdgeInsets.symmetric(vertical: 12),
                ),
              ),
            ),
          ),
          const SizedBox(width: 8),
          GestureDetector(
            onTap: () => _search(_searchCtrl.text),
            child: Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [_C.purple, _C.purpleG],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(14),
                boxShadow: [
                  BoxShadow(
                    color: _C.purple.withOpacity(0.3),
                    blurRadius: 12,
                    spreadRadius: 1,
                  ),
                ],
              ),
              child: const Icon(
                Icons.search_rounded,
                color: _C.white,
                size: 18,
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ─── GENRE CHIPS ─────────────────────────────────────────────────────────
  Widget _buildGenreChips() {
    final genres = ['Top Hits', 'Lo-Fi', 'Pop', 'Hip-Hop', 'R&B', 'Electronic', 'Acoustic', 'K-Pop', 'Indonesia'];
    return Padding(
      padding: const EdgeInsets.fromLTRB(14, 6, 14, 6),
      child: SizedBox(
        height: 30,
        child: ListView(
          scrollDirection: Axis.horizontal,
          children: genres.map((g) {
            final isActive = _q.toLowerCase() == g.toLowerCase();
            return GestureDetector(
              onTap: () {
                _searchCtrl.text = g;
                _search(g);
              },
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                margin: const EdgeInsets.only(right: 6),
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 5),
                decoration: BoxDecoration(
                  gradient: isActive
                    ? LinearGradient(
                        colors: [_C.purple, _C.purpleG],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      )
                    : LinearGradient(
                        colors: [_C.s1, _C.s2],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(
                    color: isActive ? _C.purpleL : _C.border,
                    width: isActive ? 1.5 : 0.5,
                  ),
                  boxShadow: isActive
                    ? [
                        BoxShadow(
                          color: _C.purple.withOpacity(0.3),
                          blurRadius: 10,
                        ),
                      ]
                    : [],
                ),
                child: Text(
                  g,
                  style: TextStyle(
                    color: isActive ? _C.white : _C.textS,
                    fontSize: 10,
                    fontWeight: isActive ? FontWeight.w700 : FontWeight.w400,
                    letterSpacing: 0.5,
                  ),
                ),
              ),
            );
          }).toList(),
        ),
      ),
    );
  }

  // ─── NOW PLAYING ──────────────────────────────────────────────────────────
  Widget _buildNowPlaying() {
    final t = _nowPlaying!;
    return AnimatedContainer(
      duration: const Duration(milliseconds: 300),
      margin: const EdgeInsets.fromLTRB(14, 6, 14, 6),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [_C.s1, _C.s2],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(
          color: _C.purpleL.withOpacity(0.3),
          width: 0.5,
        ),
        boxShadow: [
          BoxShadow(
            color: _C.purple.withOpacity(0.1),
            blurRadius: 20,
            spreadRadius: 2,
          ),
        ],
      ),
      child: Column(
        children: [
          Row(
            children: [
              // Album art with glow
              Container(
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(12),
                  boxShadow: [
                    BoxShadow(
                      color: _C.purple.withOpacity(0.2),
                      blurRadius: 16,
                    ),
                  ],
                ),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(12),
                  child: t['img'] != ''
                    ? Image.network(
                        t['img'] as String,
                        width: 52,
                        height: 52,
                        fit: BoxFit.cover,
                        errorBuilder: (_, __, ___) => Container(
                          width: 52,
                          height: 52,
                          color: _C.s2,
                          child: const Icon(
                            Icons.music_note_rounded,
                            color: _C.textM,
                            size: 24,
                          ),
                        ),
                      )
                    : Container(
                        width: 52,
                        height: 52,
                        color: _C.s2,
                        child: const Icon(
                          Icons.music_note_rounded,
                          color: _C.textM,
                          size: 24,
                        ),
                      ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      t['title'] as String,
                      style: const TextStyle(
                        color: _C.textP,
                        fontWeight: FontWeight.bold,
                        fontSize: 13,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 2),
                    Text(
                      t['artist'] as String,
                      style: const TextStyle(
                        color: _C.textS,
                        fontSize: 11,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
              // Controls
              Row(
                children: [
                  GestureDetector(
                    onTap: () => setState(() => _shuffle = !_shuffle),
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 200),
                      padding: const EdgeInsets.all(4),
                      decoration: BoxDecoration(
                        color: _shuffle ? _C.purple.withOpacity(0.15) : Colors.transparent,
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(
                          color: _shuffle ? _C.purpleL : Colors.transparent,
                          width: 0.5,
                        ),
                      ),
                      child: Icon(
                        Icons.shuffle_rounded,
                        color: _shuffle ? _C.green : _C.textM,
                        size: 16,
                      ),
                    ),
                  ),
                  const SizedBox(width: 4),
                  GestureDetector(
                    onTap: _prevTrack,
                    child: const Icon(
                      Icons.skip_previous_rounded,
                      color: _C.textP,
                      size: 22,
                    ),
                  ),
                  const SizedBox(width: 4),
                  GestureDetector(
                    onTap: _togglePlay,
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 200),
                      width: 36,
                      height: 36,
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: [_C.purple, _C.purpleG],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        ),
                        shape: BoxShape.circle,
                        boxShadow: [
                          BoxShadow(
                            color: _C.purple.withOpacity(0.3),
                            blurRadius: 12,
                            spreadRadius: 2,
                          ),
                        ],
                      ),
                      child: Icon(
                        _playing ? Icons.pause_rounded : Icons.play_arrow_rounded,
                        color: _C.white,
                        size: 20,
                      ),
                    ),
                  ),
                  const SizedBox(width: 4),
                  GestureDetector(
                    onTap: _nextTrack,
                    child: const Icon(
                      Icons.skip_next_rounded,
                      color: _C.textP,
                      size: 22,
                    ),
                  ),
                  const SizedBox(width: 4),
                  GestureDetector(
                    onTap: () => setState(() => _repeat = !_repeat),
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 200),
                      padding: const EdgeInsets.all(4),
                      decoration: BoxDecoration(
                        color: _repeat ? _C.purple.withOpacity(0.15) : Colors.transparent,
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(
                          color: _repeat ? _C.purpleL : Colors.transparent,
                          width: 0.5,
                        ),
                      ),
                      child: Icon(
                        Icons.repeat_rounded,
                        color: _repeat ? _C.green : _C.textM,
                        size: 16,
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 8),
          // Progress bar with glow
          SliderTheme(
            data: SliderTheme.of(context).copyWith(
              activeTrackColor: _C.purpleL,
              inactiveTrackColor: _C.border,
              thumbColor: _C.white,
              thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 5),
              overlayShape: SliderComponentShape.noThumb,
              trackHeight: 2,
              activeTickMarkColor: Colors.transparent,
              inactiveTickMarkColor: Colors.transparent,
            ),
            child: Slider(
              value: _dur.inSeconds > 0 ? (_pos.inSeconds / _dur.inSeconds).clamp(0.0, 1.0) : 0.0,
              onChanged: (v) {
                if (_dur.inSeconds > 0) {
                  _player.seek(Duration(seconds: (v * _dur.inSeconds).toInt()));
                }
              },
            ),
          ),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                _fmt(_pos),
                style: const TextStyle(
                  color: _C.textM,
                  fontSize: 10,
                  fontFamily: 'monospace',
                ),
              ),
              Text(
                _fmt(_dur),
                style: const TextStyle(
                  color: _C.textM,
                  fontSize: 10,
                  fontFamily: 'monospace',
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  // ─── RESULT LIST ──────────────────────────────────────────────────────────
  Widget _buildResultList() {
    return ListView.builder(
      controller: _scrollController,
      padding: const EdgeInsets.fromLTRB(14, 4, 14, 100),
      itemCount: _results.length,
      itemBuilder: (_, i) {
        final t = _results[i];
        final isPlaying = _nowPlaying != null && 
          _nowPlaying!['title'] == t['title'] && 
          _playing;
        
        return TweenAnimationBuilder<double>(
          duration: const Duration(milliseconds: 400),
          curve: Curves.easeOut,
          tween: Tween(begin: 0.0, end: 1.0),
          builder: (_, val, __) {
            final transform = Matrix4.identity()
              ..setEntry(3, 2, 0.001)
              ..rotateX((1 - val) * 0.02);
            return Transform(
              transform: transform,
              child: GestureDetector(
                onTap: () => _play(t),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  margin: const EdgeInsets.only(bottom: 8),
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                  decoration: BoxDecoration(
                    gradient: isPlaying
                      ? LinearGradient(
                          colors: [_C.purple.withOpacity(0.15), _C.s1],
                          begin: Alignment.centerLeft,
                          end: Alignment.centerRight,
                        )
                      : const LinearGradient(
                          colors: [_C.s1, _C.s1],
                          begin: Alignment.centerLeft,
                          end: Alignment.centerRight,
                        ),
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(
                      color: isPlaying ? _C.purpleL.withOpacity(0.4) : _C.border.withOpacity(0.5),
                      width: isPlaying ? 1 : 0.5,
                    ),
                    boxShadow: isPlaying
                      ? [
                          BoxShadow(
                            color: _C.purple.withOpacity(0.15),
                            blurRadius: 16,
                          ),
                        ]
                      : [],
                  ),
                  child: Row(
                    children: [
                      ClipRRect(
                        borderRadius: BorderRadius.circular(10),
                        child: t['img'] != ''
                          ? Image.network(
                              t['img'] as String,
                              width: 44,
                              height: 44,
                              fit: BoxFit.cover,
                              errorBuilder: (_, __, ___) => Container(
                                width: 44,
                                height: 44,
                                color: _C.s2,
                                child: const Icon(
                                  Icons.music_note_rounded,
                                  color: _C.textM,
                                  size: 20,
                                ),
                              ),
                            )
                          : Container(
                              width: 44,
                              height: 44,
                              color: _C.s2,
                              child: const Icon(
                                Icons.music_note_rounded,
                                color: _C.textM,
                                size: 20,
                              ),
                            ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              t['title'] as String,
                              style: TextStyle(
                                color: isPlaying ? _C.purpleL : _C.textP,
                                fontSize: 13,
                                fontWeight: isPlaying ? FontWeight.bold : FontWeight.w500,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                            const SizedBox(height: 2),
                            Text(
                              t['artist'] as String,
                              style: const TextStyle(
                                color: _C.textM,
                                fontSize: 11,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ],
                        ),
                      ),
                      if (isPlaying)
                        AnimatedBuilder(
                          animation: _pulseCtrl,
                          builder: (_, __) => Icon(
                            Icons.equalizer_rounded,
                            color: _C.purpleL.withOpacity(0.5 + _pulseCtrl.value * 0.5),
                            size: 20,
                          ),
                        )
                      else
                        Icon(
                          Icons.play_circle_outline_rounded,
                          color: _C.textM.withOpacity(0.5),
                          size: 20,
                        ),
                    ],
                  ),
                ),
              ),
            );
          },
        );
      },
    );
  }

  // ─── LOADING / EMPTY / ERROR ─────────────────────────────────────────────
  Widget _buildLoading() {
    return const Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          SizedBox(
            width: 40,
            height: 40,
            child: CircularProgressIndicator(
              color: _C.purpleL,
              strokeWidth: 2,
            ),
          ),
          SizedBox(height: 16),
          Text(
            'Memuat lagu...',
            style: TextStyle(
              color: _C.textM,
              fontSize: 12,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildError() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.error_outline_rounded,
            color: _C.purpleL.withOpacity(0.5),
            size: 48,
          ),
          const SizedBox(height: 12),
          Text(
            _errMsg,
            style: const TextStyle(
              color: _C.textM,
              fontSize: 13,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildEmpty() {
    return const Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.music_off_rounded,
            color: _C.textM,
            size: 48,
          ),
          SizedBox(height: 12),
          Text(
            'Cari lagu favoritmu',
            style: TextStyle(
              color: _C.textS,
              fontSize: 14,
            ),
          ),
          SizedBox(height: 4),
          Text(
            'Ketuk ikon search untuk mulai',
            style: TextStyle(
              color: _C.textM,
              fontSize: 11,
            ),
          ),
        ],
      ),
    );
  }
}