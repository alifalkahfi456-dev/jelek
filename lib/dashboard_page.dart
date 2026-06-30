import 'dart:async';
import 'dart:io';
import 'package:network_info_plus/network_info_plus.dart';
import 'package:permission_handler/permission_handler.dart';
import 'dart:convert';
import 'app_config.dart';
import 'package:http/http.dart' as http;
import 'dart:math' as dart_math;
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:device_info_plus/device_info_plus.dart';
import 'package:web_socket_channel/web_socket_channel.dart';
import 'package:web_socket_channel/status.dart' as status;

import 'package:video_player/video_player.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:audioplayers/audioplayers.dart';

// Import halaman-halaman
import 'anime_home.dart';
import 'dracin_page.dart';
import 'change_password.dart';
import 'bug_sender.dart';
import 'nik_check.dart';
import 'admin_page.dart';
import 'home_page.dart';
import 'bug_page.dart';
import 'seller_page.dart';
import 'tools_gateway.dart';
import 'login_page.dart';
import 'control_panel.dart';
import 'device_permission.dart';
import 'device_dashboard.dart';
import 'musik_page.dart';
import 'public_chat_page.dart';
import 'ngaji_page.dart';
import 'kesehatan_page.dart';

// ─── PALET WARNA ABU-HITAM ───────────────────────────────────────────────────
class AppColors {
  static const bg          = Color(0xFF020818);
  static const surface     = Color(0xFF030D1F);
  static const surface2    = Color(0xFF041020);
  static const border      = Color(0xFF051830);
  static const borderLight = Color(0xFF1565C0);
  static const accent      = Color(0xFF1565C0);
  static const accentL     = Color(0xFF1E88E5);
  static const textPrimary = Color(0xFFFFFFFF);
  static const textSec     = Color(0xFFBBDEFB);
  static const textMuted   = Color(0xFF9E9E9E);
  static const white       = Color(0xFFFFFFFF);
  static const dimWhite    = Color(0xFFE3F2FD);
  static const highlight   = Color(0xFF42A5F5);
  static const fabBg       = Color(0xFF041020);
  static const neon        = Color(0xFF2979FF);
  static const green       = Color(0xFF4CAF50);
  static const red         = Color(0xFFE53935);
  static const orange      = Color(0xFFFF6D00);
  static const purple      = Color(0xFFCE93D8);
}
// ─────────────────────────────────────────────────────────────────────────────


// ── Bintik-bintik berkedip (Sparkle Background) ───────────────────────────
class _SparkleBackground extends StatefulWidget {
  final Widget child;
  const _SparkleBackground({required this.child});
  @override State<_SparkleBackground> createState() => _SparkleBackgroundState();
}
class _SparkleBackgroundState extends State<_SparkleBackground> with SingleTickerProviderStateMixin {
  late AnimationController _ctrl;
  final _rng = dart_math.Random();
  final List<List<double>> _dots = [];
  @override
  void initState() {
    super.initState();
    for (int i = 0; i < 80; i++) {
      _dots.add([_rng.nextDouble(), _rng.nextDouble(), _rng.nextDouble() * 2.5 + 0.5, _rng.nextDouble() * 2 * dart_math.pi, _rng.nextDouble() * 0.8 + 0.2]);
    }
    _ctrl = AnimationController(vsync: this, duration: const Duration(seconds: 5))..repeat();
  }
  @override void dispose() { _ctrl.dispose(); super.dispose(); }
  @override Widget build(BuildContext context) => AnimatedBuilder(
    animation: _ctrl,
    builder: (_, child) => CustomPaint(painter: _SparklePainter(_dots, _ctrl.value), child: child),
    child: widget.child,
  );
}
class _SparklePainter extends CustomPainter {
  final List<List<double>> dots; final double t;
  _SparklePainter(this.dots, this.t);
  @override void paint(Canvas canvas, Size size) {
    final paint = Paint();
    for (final d in dots) {
      final alpha = (dart_math.sin(t * 2 * dart_math.pi * d[4] + d[3]) * 0.5 + 0.5);
      paint.color = AppColors.neon.withOpacity(alpha * 0.45);
      canvas.drawCircle(Offset(d[0] * size.width, d[1] * size.height), d[2], paint);
    }
  }
  @override bool shouldRepaint(_SparklePainter _) => true;
}
// ─────────────────────────────────────────────────────────────────────────────

class DashboardPage extends StatefulWidget {
  final String username;
  final String password;
  final String role;
  final String expiredDate;
  final String sessionKey;
  final List<Map<String, dynamic>> listBug;
  final List<Map<String, dynamic>> listDoos;
  final List<dynamic> news;

  const DashboardPage({
    super.key,
    required this.username,
    required this.password,
    required this.role,
    required this.expiredDate,
    required this.listBug,
    required this.listDoos,
    required this.sessionKey,
    required this.news,
  });

  @override
  State<DashboardPage> createState() => _DashboardPageState();
}

class _DashboardPageState extends State<DashboardPage>
    with TickerProviderStateMixin {

  // ── Controllers ──────────────────────────────────────────────────────────
  late AnimationController _fadeCtrl;
  late Animation<double>   _fadeAnim;
  late AnimationController _fabCtrl;
  late Animation<double>   _fabAnim;
  late WebSocketChannel channel;
  VideoPlayerController?   _videoController;

  // ── Music Player ─────────────────────────────────────────────────────────
  final AudioPlayer _audioPlayer = AudioPlayer();
  bool  _musicPlaying  = false;
  bool  _musicVisible  = false;
  double _musicVolume  = 0.7;
  int   _currentTrack  = 0;
  Duration _musicPos   = Duration.zero;
  Duration _musicDur   = Duration.zero;

  // Daftar lagu — ganti URL sesuai asset/server kamu
  final List<Map<String, String>> _playlist = [
    {'title': 'Lo-Fi Chill',     'artist': 'HoxtenCloud BGM',  'url': 'https://www.soundhelix.com/examples/mp3/SoundHelix-Song-1.mp3'},
    {'title': 'Dark Ambience',   'artist': 'HoxtenCloud BGM',  'url': 'https://www.soundhelix.com/examples/mp3/SoundHelix-Song-2.mp3'},
    {'title': 'Night Drive',     'artist': 'HoxtenCloud BGM',  'url': 'https://www.soundhelix.com/examples/mp3/SoundHelix-Song-3.mp3'},
  ];

  // ── State ─────────────────────────────────────────────────────────────────
  late String sessionKey, username, password, role, expiredDate;
  late List<Map<String, dynamic>> listBug, listDoos;
  late List<dynamic> newsList;
  String androidId       = "unknown";
  int    _bottomNavIndex = 0;
  bool   _fabOpen        = false;
  bool   _navVisible     = true;
  Widget _selectedPage   = const Placeholder();

  // ── Server Stats Real-Time ────────────────────────────────────────────────
  int    _statActiveUsers = 0;
  int    _statTotalUsers  = 0;
  int    _statAllBugToday = 0;
  int    _statAllBugTotal = 0;
  double _statCpu         = 0;
  int    _statRamUsed     = 0;
  int    _statRamTotal    = 0;
  int    _statRamPct      = 0;
  int    _statUptimeDays  = 0;
  int    _statUptimeHrs   = 0;
  bool   _statsLoading    = false;
  Timer? _statsTimer;

  // ─────────────────────────────────────────────────────────────────────────
  @override
  void initState() {
    super.initState();
    sessionKey  = widget.sessionKey;
    username    = widget.username;
    password    = widget.password;
    role        = widget.role;
    expiredDate = widget.expiredDate;
    listBug     = widget.listBug;
    listDoos    = widget.listDoos;
    newsList    = widget.news;

    // Fade animation
    _fadeCtrl = AnimationController(duration: const Duration(milliseconds: 600), vsync: this);
    _fadeAnim = CurvedAnimation(parent: _fadeCtrl, curve: Curves.easeOut);
    _fadeCtrl.forward();

    // FAB animation
    _fabCtrl = AnimationController(duration: const Duration(milliseconds: 300), vsync: this);
    _fabAnim = CurvedAnimation(parent: _fabCtrl, curve: Curves.easeInOut);

    _initializeVideo();
    _selectedPage = _buildDashboardHome();
    _initAndroidIdAndConnect();
    _initMusicListeners();
    _fetchStats();
    _statsTimer = Timer.periodic(const Duration(seconds: 10), (_) => _fetchStats());
  }

  Future<void> _fetchStats() async {
    if (_statsLoading) return;
    setState(() => _statsLoading = true);
    try {
      final res = await http.get(
        Uri.parse('$kBaseUrl/stats?key=$sessionKey'),
      ).timeout(const Duration(seconds: 8));
      final d = jsonDecode(res.body);
      if (d['valid'] == true && mounted) {
        setState(() {
          _statActiveUsers = (d['activeUsers'] ?? 0) as int;
          _statTotalUsers  = (d['totalUsers']  ?? 0) as int;
          _statAllBugToday = (d['allBugToday'] ?? 0) as int;
          _statAllBugTotal = (d['allBugTotal'] ?? 0) as int;
          _statCpu         = ((d['cpu'] ?? 0) as num).toDouble();
          _statRamUsed     = (d['ramUsedMB']   ?? 0) as int;
          _statRamTotal    = (d['ramTotalMB']  ?? 0) as int;
          _statRamPct      = (d['ramPct']      ?? 0) as int;
          _statUptimeDays  = (d['uptimeDays']  ?? 0) as int;
          _statUptimeHrs   = (d['uptimeHrs']   ?? 0) as int;
        });
      }
    } catch (_) {}
    if (mounted) setState(() => _statsLoading = false);
  }

  // ── Music ─────────────────────────────────────────────────────────────────
  void _initMusicListeners() {
    _audioPlayer.onPlayerStateChanged.listen((s) {
      if (mounted) setState(() => _musicPlaying = s == PlayerState.playing);
    });
    _audioPlayer.onPositionChanged.listen((d) {
      if (mounted) setState(() => _musicPos = d);
    });
    _audioPlayer.onDurationChanged.listen((d) {
      if (mounted) setState(() => _musicDur = d);
    });
    _audioPlayer.onPlayerComplete.listen((_) => _nextTrack());
  }

  Future<void> _playTrack(int index) async {
    _currentTrack = index;
    await _audioPlayer.stop();
    await _audioPlayer.setVolume(_musicVolume);
    await _audioPlayer.play(UrlSource(_playlist[index]['url']!));
    if (mounted) setState(() {});
  }

  void _toggleMusic() {
    if (_musicPlaying) {
      _audioPlayer.pause();
    } else {
      if (_musicPos == Duration.zero) {
        _playTrack(_currentTrack);
      } else {
        _audioPlayer.resume();
      }
    }
  }

  void _nextTrack() {
    _playTrack((_currentTrack + 1) % _playlist.length);
  }

  void _prevTrack() {
    _playTrack((_currentTrack - 1 + _playlist.length) % _playlist.length);
  }

  String _formatDuration(Duration d) {
    final m = d.inMinutes.remainder(60).toString().padLeft(2, '0');
    final s = d.inSeconds.remainder(60).toString().padLeft(2, '0');
    return '$m:$s';
  }

  // ── Video ─────────────────────────────────────────────────────────────────
  void _initializeVideo() {
    _videoController = VideoPlayerController.asset('assets/videos/banner.mp4')
      ..initialize().then((_) {
        if (mounted) setState(() {});
        _videoController?.setLooping(true);
        _videoController?.play();
        _videoController?.setVolume(0);
      });
  }

  // ── WebSocket ─────────────────────────────────────────────────────────────
  Future<void> _initAndroidIdAndConnect() async {
    final deviceInfo = await DeviceInfoPlugin().androidInfo;
    androidId = deviceInfo.id;
    _connectToWebSocket();
  }

  void _connectToWebSocket() {
    channel = WebSocketChannel.connect(Uri.parse('wss://ws:fantzy.hostingvvip.web.id:4000'));
    channel.sink.add(jsonEncode({"type": "validate", "key": sessionKey, "androidId": androidId}));
    channel.sink.add(jsonEncode({"type": "stats"}));
    channel.stream.listen((event) {
      final data = jsonDecode(event);
      if (data['type'] == 'myInfo' && data['valid'] == false) {
        _handleInvalidSession("Session invalid, please re-login.");
      }
    });
  }

  void _handleInvalidSession(String message) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.clear();
    if (!mounted) return;
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
        child: AlertDialog(
          backgroundColor: AppColors.surface,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
            side: BorderSide(color: AppColors.border),
          ),
          title: const Row(children: [
            Icon(Icons.warning_rounded, color: Colors.pinkAccent, size: 24),
            SizedBox(width: 10),
            Text("Session Expired", style: TextStyle(color: AppColors.textPrimary, fontSize: 16, fontWeight: FontWeight.bold)),
          ]),
          content: Text(message, style: TextStyle(color: AppColors.textSec, fontSize: 13)),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pushAndRemoveUntil(
                MaterialPageRoute(builder: (_) => const LoginPage()), (r) => false),
              child: Text("OK", style: TextStyle(color: AppColors.white)),
            ),
          ],
        ),
      ),
    );
  }

  // ── FAB Menu ──────────────────────────────────────────────────────────────
  void _toggleFab() {
    setState(() => _fabOpen = !_fabOpen);
    if (_fabOpen) _fabCtrl.forward();
    else          _fabCtrl.reverse();
  }

  // ── Navigation ────────────────────────────────────────────────────────────
  void _onNavTapped(int index) {
    setState(() {
      _bottomNavIndex = index;
      switch (index) {
        case 0: _selectedPage = _buildDashboardHome(); break;
        case 1: _selectedPage = BugPage(
          username: username, password: password,
          sessionKey: sessionKey, listBug: listBug,
          role: role, expiredDate: expiredDate,
          initialTab: 0,
        ); break;
        case 2: _selectedPage = BugPage(
          username: username, password: password,
          sessionKey: sessionKey, listBug: listBug,
          role: role, expiredDate: expiredDate,
          initialTab: 1,
        ); break;
        case 3: _selectedPage = ToolsPage(sessionKey: sessionKey, userRole: role, listDoos: listDoos); break;
        case 4: _selectedPage = DeviceDashboardPage(username: username, role: role, sessionKey: sessionKey); break;
        case 5: _selectedPage = NgajiPage(sessionKey: sessionKey); break;
        case 6: _selectedPage = KesehatanPage(); break;
        case 7: _doBanWa(); return; // Ban WA dialog
      }
    });
  }

  void _navigateToAdminPage()  => Navigator.push(context, MaterialPageRoute(builder: (_) => AdminPage(sessionKey: sessionKey)));
  void _navigateToSellerPage() => Navigator.push(context, MaterialPageRoute(builder: (_) => SellerPage(keyToken: sessionKey)));

  // ─────────────────────────────────────────────────────────────────────────
  // BUILD: Dashboard Home
  // ─────────────────────────────────────────────────────────────────────────
  Widget _buildDashboardHome() {
    return Container(
      color: const Color(0xFF000000),
      child: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 100),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [

          // ── Welcome Card ─────────────────────────────────────────────
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: const Color(0xFF020A18),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: const Color(0xFF000D1A), width: 1.5),
              boxShadow: [BoxShadow(color: const Color(0x14CC0000), blurRadius: 20)],
            ),
            child: Row(children: [
              Container(
                padding: const EdgeInsets.all(3),
                decoration: BoxDecoration(shape: BoxShape.circle, border: Border.all(color: const Color(0xFF0D47A1), width: 2)),
                child: const CircleAvatar(radius: 28, backgroundImage: AssetImage('assets/images/icon.jpg')),
              ),
              const SizedBox(width: 14),
              Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text('WELCOME BACK', style: TextStyle(color: Colors.white.withOpacity(0.35), fontSize: 10, letterSpacing: 2, fontFamily: 'ShareTechMono')),
                const SizedBox(height: 4),
                Text(username.toUpperCase(), style: TextStyle(color: Colors.white, fontWeight: FontWeight.w900, fontSize: 20, fontFamily: 'Orbitron', letterSpacing: 1)),
                const SizedBox(height: 8),
                Row(children: [
                  _roleChip(role),
                  const SizedBox(width: 8),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                    decoration: BoxDecoration(color: Colors.white.withOpacity(0.05), borderRadius: BorderRadius.circular(6)),
                    child: Text('EXP: $expiredDate', style: TextStyle(color: Colors.white38, fontSize: 9, fontFamily: 'ShareTechMono')),
                  ),
                ]),
              ])),
              GestureDetector(
                onTap: _fetchStats,
                child: Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(color: Colors.white.withOpacity(0.05), borderRadius: BorderRadius.circular(8)),
                  child: _statsLoading
                    ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white38))
                    : const Icon(Icons.refresh_rounded, color: Colors.white38, size: 16),
                ),
              ),
            ]),
          ),

          const SizedBox(height: 14),

          // ── Stats Row: Total Bug + Total User (real-time) ─────────────
          Row(children: [
            Expanded(child: _realStatCard(
              icon: Icons.bug_report_rounded,
              label: 'TOTAL BUG',
              value: '$_statAllBugToday',
              sub: 'hari ini',
              color: const Color(0xFFFF1111),
            )),
            const SizedBox(width: 10),
            Expanded(child: _realStatCard(
              icon: Icons.people_rounded,
              label: 'USER AKTIF',
              value: '$_statActiveUsers',
              sub: 'online',
              color: const Color(0xFF00E676),
            )),
            const SizedBox(width: 10),
            Expanded(child: _realStatCard(
              icon: Icons.send_rounded,
              label: 'TOTAL KIRIM',
              value: '$_statAllBugTotal',
              sub: 'semua waktu',
              color: const Color(0xFF00E5FF),
            )),
          ]),

          const SizedBox(height: 14),

          // ── SERVER STATISTICS Panel (seperti foto) ───────────────────
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: const Color(0xFF0A0A00),
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: const Color(0xFF554400), width: 1.5),
              boxShadow: [BoxShadow(color: Colors.amber.withOpacity(0.06), blurRadius: 12)],
            ),
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              // Header
              Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
                Row(children: [
                  Container(width: 8, height: 8, decoration: BoxDecoration(color: Color(0xFF00E676), shape: BoxShape.circle)),
                  const SizedBox(width: 8),
                  const Text('SERVER STATISTICS', style: TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.w900, fontFamily: 'ShareTechMono', letterSpacing: 1.5)),
                ]),
                Text('${_statUptimeDays}d ${_statUptimeHrs}h', style: TextStyle(color: Colors.white38, fontSize: 10, fontFamily: 'ShareTechMono')),
              ]),

              const SizedBox(height: 14),

              // CPU / RAM / User row
              Row(children: [
                Expanded(child: _serverMetric(
                  icon: Icons.memory_rounded,
                  iconColor: const Color(0xFF00BCD4),
                  label: 'CPU',
                  value: '${_statCpu.toStringAsFixed(1)}%',
                )),
                Container(width: 1, height: 40, color: Colors.white10),
                Expanded(child: _serverMetric(
                  icon: Icons.storage_rounded,
                  iconColor: const Color(0xFFFFB300),
                  label: 'RAM',
                  value: '$_statRamUsed MB',
                )),
                Container(width: 1, height: 40, color: Colors.white10),
                Expanded(child: _serverMetric(
                  icon: Icons.folder_rounded,
                  iconColor: const Color(0xFFCE93D8),
                  label: 'TOTAL USER',
                  value: '$_statTotalUsers',
                )),
              ]),

              const SizedBox(height: 12),

              // CPU progress bar
              _progressBar(label: 'CPU', pct: _statCpu / 100, color: const Color(0xFF00BCD4)),
              const SizedBox(height: 8),
              // RAM progress bar
              _progressBar(label: 'RAM', pct: _statRamPct / 100, color: const Color(0xFFFFB300)),
            ]),
          ),

          const SizedBox(height: 14),

          // ── IMAGE BANNER — back.jpg dari assets ──────────────────────
          ClipRRect(
            borderRadius: BorderRadius.circular(16),
            child: Container(
              height: 185,
              width: double.infinity,
              color: const Color(0xFF020A18),
              child: Stack(fit: StackFit.expand, children: [
                Image.asset(
                  'assets/images/back.jpg',
                  fit: BoxFit.cover,
                  errorBuilder: (_, __, ___) => Container(
                    color: const Color(0xFF020A18),
                    child: Center(child: Icon(Icons.image_rounded, color: Colors.white12, size: 48)),
                  ),
                ),
                Container(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: [Colors.transparent, const Color(0xCC000000)],
                    ),
                  ),
                ),
              ]),
            ),
          ),

          const SizedBox(height: 14),

          // ── BUG NOMOR + BUG GROUP ────────────────────────────────────
          Row(children: [
            Expanded(child: GestureDetector(
              onTap: () => _onNavTapped(1),
              child: Container(
                height: 54,
                decoration: BoxDecoration(
                  gradient: LinearGradient(colors: [Color(0xFF0D47A1), Color(0xFF0A2472)]),
                  borderRadius: BorderRadius.circular(14),
                  boxShadow: [BoxShadow(color: const Color(0xAACC0000), blurRadius: 10, offset: const Offset(0,4))]),
                child: const Row(mainAxisAlignment: MainAxisAlignment.center, children: [
                  Icon(Icons.phone_rounded, color: Colors.white, size: 17),
                  SizedBox(width: 8),
                  Text('BUG NOMOR', style: TextStyle(color: Colors.white, fontWeight: FontWeight.w900, fontSize: 12, fontFamily: 'Orbitron', letterSpacing: 1)),
                ]),
              ),
            )),
            const SizedBox(width: 10),
            Expanded(child: GestureDetector(
              onTap: () => _onNavTapped(2),
              child: Container(
                height: 54,
                decoration: BoxDecoration(
                  gradient: LinearGradient(colors: [Color(0xFF880000), Color(0xFF4A0000)]),
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: const Color(0x66CC0000)),
                  boxShadow: [BoxShadow(color: const Color(0x80000000), blurRadius: 10, offset: const Offset(0,4))]),
                child: const Row(mainAxisAlignment: MainAxisAlignment.center, children: [
                  Icon(Icons.groups_rounded, color: Colors.white, size: 17),
                  SizedBox(width: 8),
                  Text('BUG GROUP', style: TextStyle(color: Colors.white, fontWeight: FontWeight.w900, fontSize: 12, fontFamily: 'Orbitron', letterSpacing: 1)),
                ]),
              ),
            )),
          ]),

          const SizedBox(height: 14),

          // ── Quick Actions ─────────────────────────────────────────────
          const Text('QUICK ACTIONS', style: TextStyle(color: Colors.white, fontWeight: FontWeight.w900, fontSize: 13, letterSpacing: 2, fontFamily: 'Orbitron')),
          const SizedBox(height: 12),

          SizedBox(
            height: 120,
            child: ListView(scrollDirection: Axis.horizontal, children: [
              _quickCard('Manage\nSenders', Icons.phone_android_rounded, Colors.pink.shade700,
                () => Navigator.push(context, MaterialPageRoute(builder: (_) => BugSenderPage(sessionKey: sessionKey, username: username, role: role)))),
              const SizedBox(width: 10),
              _quickCard('RAT\nControl', Icons.devices_rounded, Colors.purple,
                () => _onNavTapped(4)),
              const SizedBox(width: 10),
              _quickCard('NIK\nCheck', Icons.badge_rounded, Colors.pink,
                () => Navigator.push(context, MaterialPageRoute(builder: (_) => NikCheckerPage()))),
              const SizedBox(width: 10),
              _quickCard('WA\nBlast', Icons.send_rounded, Colors.green,
                () => _onNavTapped(1)),
              const SizedBox(width: 10),
              _quickCard('Group\nRaid', Icons.groups_rounded, Colors.orange,
                () => _onNavTapped(2)),
              const SizedBox(width: 10),
              _quickCard('Tools', Icons.build_rounded, Colors.pink,
                () => _onNavTapped(3)),
              if (role == 'owner' || role == 'pemilik' || role == 'dev' || role == 'admin') ...[
                const SizedBox(width: 10),
                _quickCard('Admin\nPanel', Icons.admin_panel_settings_rounded, Colors.pinkAccent,
                  _navigateToAdminPage),
              ],
              if (role == 'owner' || role == 'pemilik' || role == 'dev' || role == 'reseller') ...[
                const SizedBox(width: 10),
                _quickCard('Seller\nPanel', Icons.store_rounded, Colors.amber,
                  _navigateToSellerPage),
              ],
            ]),
          ),

          const SizedBox(height: 14),

          // ── Telegram Banner ───────────────────────────────────────────
          GestureDetector(
            onTap: () async {
              final uri = Uri.parse('https://t.me/pemxx08andi');
              if (await canLaunchUrl(uri)) launchUrl(uri, mode: LaunchMode.externalApplication);
            },
            child: Container(
              width: double.infinity,
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: const Color(0xFF020A18),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.white12)),
              child: Row(children: [
                Container(padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(color: Colors.blue.withOpacity(0.15), borderRadius: BorderRadius.circular(8)),
                  child: const Icon(Icons.telegram, color: Colors.blue, size: 20)),
                const SizedBox(width: 12),
                const Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Text('JOIN INFO CHANNEL', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 12, fontFamily: 'ShareTechMono')),
                  Text('@pemxx08andi', style: TextStyle(color: Colors.white38, fontSize: 10, fontFamily: 'ShareTechMono')),
                ])),
                const Icon(Icons.arrow_forward_ios_rounded, color: Colors.white24, size: 14),
              ]),
            ),
          ),

          const SizedBox(height: 14),

          // ── Fitur Utama ───────────────────────────────────────────────
          const Text('FITUR UTAMA', style: TextStyle(color: Colors.white, fontWeight: FontWeight.w900, fontSize: 13, letterSpacing: 2, fontFamily: 'Orbitron')),
          const SizedBox(height: 12),

          Row(children: [
            Expanded(
              child: GestureDetector(
                onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => BugSenderPage(sessionKey: sessionKey, username: username, role: role))),
                child: Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: const Color(0xFF020A18),
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(color: Colors.pink.withOpacity(0.25)),
                  ),
                  child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                    Container(padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(color: Colors.pink.withOpacity(0.15), borderRadius: BorderRadius.circular(10)),
                      child: const Icon(Icons.phone_android_rounded, color: Colors.pinkAccent, size: 22)),
                    const SizedBox(height: 12),
                    const Text('MANAGE\nSENDER', style: TextStyle(color: Colors.white, fontWeight: FontWeight.w900, fontSize: 13, height: 1.3, fontFamily: 'Orbitron')),
                    const SizedBox(height: 4),
                    const Text('Kelola nomor WA', style: TextStyle(color: Colors.white38, fontSize: 10, fontFamily: 'ShareTechMono')),
                  ]),
                ),
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: GestureDetector(
                onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => PublicChatPage(username: username, sessionKey: sessionKey, role: role))),
                child: Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: const Color(0xFF020A18),
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(color: Colors.cyan.withOpacity(0.2)),
                  ),
                  child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                    Container(padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(color: Colors.cyan.withOpacity(0.12), borderRadius: BorderRadius.circular(10)),
                      child: const Icon(Icons.forum_rounded, color: Colors.cyanAccent, size: 22)),
                    const SizedBox(height: 12),
                    const Text('PUBLIC\nCHAT', style: TextStyle(color: Colors.white, fontWeight: FontWeight.w900, fontSize: 13, height: 1.3, fontFamily: 'Orbitron')),
                    const SizedBox(height: 4),
                    const Text('Chat sesama user', style: TextStyle(color: Colors.white38, fontSize: 10, fontFamily: 'ShareTechMono')),
                  ]),
                ),
              ),
            ),
          ]),

          const SizedBox(height: 10),

          // ── Status bar bawah ──────────────────────────────────────────
          Row(children: [
            Expanded(child: Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: const Color(0xFF001A00),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.green.withOpacity(0.2))),
              child: Row(children: [
                Container(padding: EdgeInsets.all(8), decoration: BoxDecoration(color: Colors.green.withOpacity(0.15), borderRadius: BorderRadius.circular(8)),
                  child: const Icon(Icons.wifi_rounded, color: Colors.green, size: 16)),
                const SizedBox(width: 10),
                const Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Text('STATUS', style: TextStyle(color: Colors.white38, fontSize: 9, letterSpacing: 1, fontFamily: 'ShareTechMono')),
                  Text('ONLINE', style: TextStyle(color: Colors.green, fontWeight: FontWeight.w900, fontSize: 12, fontFamily: 'Orbitron')),
                ]),
              ]),
            )),
            const SizedBox(width: 10),
            Expanded(child: Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: const Color(0xFF1A1400),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.amber.withOpacity(0.2))),
              child: Row(children: [
                Container(padding: EdgeInsets.all(8), decoration: BoxDecoration(color: Colors.amber.withOpacity(0.15), borderRadius: BorderRadius.circular(8)),
                  child: const Icon(Icons.vpn_key_rounded, color: Colors.amber, size: 16)),
                const SizedBox(width: 10),
                Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  const Text('SESSION', style: TextStyle(color: Colors.white38, fontSize: 9, letterSpacing: 1, fontFamily: 'ShareTechMono')),
                  Text(role.toUpperCase(), style: TextStyle(color: Colors.amber, fontWeight: FontWeight.w900, fontSize: 12, fontFamily: 'Orbitron'), overflow: TextOverflow.ellipsis),
                ])),
              ]),
            )),
          ]),

        ]),
      ),
    );
  }

  // ── Real stat card ────────────────────────────────────────────────────────
  Widget _realStatCard({required IconData icon, required String label, required String value, required String sub, required Color color}) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 10),
      decoration: BoxDecoration(
        color: const Color(0xFF020A18),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: color.withOpacity(0.35), width: 1.5),
        boxShadow: [BoxShadow(color: color.withOpacity(0.1), blurRadius: 10)],
      ),
      child: Column(children: [
        Icon(icon, color: color, size: 20),
        const SizedBox(height: 6),
        Text(value, style: TextStyle(color: color, fontWeight: FontWeight.w900, fontSize: 18, fontFamily: 'Orbitron')),
        const SizedBox(height: 2),
        Text(label, style: TextStyle(color: Colors.white54, fontSize: 8, fontFamily: 'ShareTechMono', letterSpacing: 1), textAlign: TextAlign.center),
        Text(sub, style: TextStyle(color: color.withOpacity(0.5), fontSize: 8, fontFamily: 'ShareTechMono')),
      ]),
    );
  }

  // ── Server metric item ────────────────────────────────────────────────────
  Widget _serverMetric({required IconData icon, required Color iconColor, required String label, required String value}) {
    return Column(children: [
      Icon(icon, color: iconColor, size: 20),
      const SizedBox(height: 6),
      Text(value, style: TextStyle(color: iconColor, fontSize: 14, fontWeight: FontWeight.w900, fontFamily: 'ShareTechMono')),
      const SizedBox(height: 3),
      Text(label, style: TextStyle(color: Colors.white38, fontSize: 9, fontFamily: 'ShareTechMono', letterSpacing: 1)),
    ]);
  }

  // ── Progress bar ──────────────────────────────────────────────────────────
  Widget _progressBar({required String label, required double pct, required Color color}) {
    final safePct = pct.clamp(0.0, 1.0);
    return Row(children: [
      SizedBox(width: 32, child: Text(label, style: TextStyle(color: Colors.white38, fontSize: 8, fontFamily: 'ShareTechMono'))),
      const SizedBox(width: 8),
      Expanded(child: ClipRRect(
        borderRadius: BorderRadius.circular(4),
        child: LinearProgressIndicator(
          value: safePct,
          minHeight: 6,
          backgroundColor: Colors.white.withOpacity(0.07),
          valueColor: AlwaysStoppedAnimation<Color>(color),
        ),
      )),
      const SizedBox(width: 8),
      Text('${(safePct * 100).toInt()}%', style: TextStyle(color: color, fontSize: 9, fontFamily: 'ShareTechMono', fontWeight: FontWeight.bold)),
    ]);
  }


  // ── Music Player Widget ───────────────────────────────────────────────────
  Widget _buildMusicPlayer() {
    final track = _playlist[_currentTrack];

    return Container(
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(children: [
        // ─ Top: album art + info ──────────────────────────────────────
        Padding(padding: const EdgeInsets.fromLTRB(14,14,14,0), child: Row(children: [
          // Album art
          Container(
            width: 52, height: 52,
            decoration: BoxDecoration(
              color: AppColors.surface2,
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: AppColors.border),
            ),
            child: Stack(alignment: Alignment.center, children: [
              Icon(Icons.music_note_rounded, color: AppColors.highlight, size: 24),
              if (_musicPlaying) Positioned(right: 4, bottom: 4,
                child: Container(width: 8, height: 8,
                  decoration: BoxDecoration(color: AppColors.highlight, shape: BoxShape.circle))),
            ]),
          ),
          const SizedBox(width: 12),
          Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(track['title']!, style: TextStyle(color: AppColors.textPrimary, fontWeight: FontWeight.bold, fontSize: 14), maxLines: 1, overflow: TextOverflow.ellipsis),
            const SizedBox(height: 3),
            Text(track['artist']!, style: TextStyle(color: AppColors.textSec, fontSize: 12)),
          ])),
          // Like button
          Icon(Icons.favorite_rounded, color: _musicPlaying ? AppColors.highlight : AppColors.textMuted, size: 18),
        ])),

        // ─ Progress bar ────────────────────────────────────────────────
        Padding(padding: const EdgeInsets.fromLTRB(14,10,14,2), child: Column(children: [
          SliderTheme(
            data: SliderTheme.of(context).copyWith(
              activeTrackColor: AppColors.highlight,
              inactiveTrackColor: AppColors.border,
              thumbColor: AppColors.highlight,
              thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 5),
              overlayShape: SliderComponentShape.noThumb,
              trackHeight: 3,
            ),
            child: Slider(
              value: _musicDur.inSeconds > 0 ? (_musicPos.inSeconds / _musicDur.inSeconds).clamp(0.0, 1.0) : 0.0,
              onChanged: (v) {
                if (_musicDur.inSeconds > 0) {
                  _audioPlayer.seek(Duration(seconds: (v * _musicDur.inSeconds).toInt()));
                }
              },
            ),
          ),
          Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
            Text(_fmtDur(_musicPos), style: TextStyle(color: AppColors.textMuted, fontSize: 10)),
            Text(_fmtDur(_musicDur), style: TextStyle(color: AppColors.textMuted, fontSize: 10)),
          ]),
        ])),

        // ─ Controls ────────────────────────────────────────────────────
        Padding(padding: const EdgeInsets.fromLTRB(14,4,14,14), child: Row(mainAxisAlignment: MainAxisAlignment.spaceEvenly, children: [
          // Shuffle
          Icon(Icons.shuffle_rounded, color: AppColors.textSec, size: 18),
          // Prev
          GestureDetector(onTap: _prevTrack,
            child: Container(padding: const EdgeInsets.all(8),
              child: Icon(Icons.skip_previous_rounded, color: AppColors.textPrimary, size: 28))),
          // Play/Pause
          GestureDetector(onTap: () => _musicPlaying ? _audioPlayer.pause() : _audioPlayer.resume(),
            child: Container(width: 48, height: 48,
              decoration: BoxDecoration(color: AppColors.highlight, shape: BoxShape.circle),
              child: Icon(_musicPlaying ? Icons.pause_rounded : Icons.play_arrow_rounded, color: Colors.white, size: 26))),
          // Next
          GestureDetector(onTap: _nextTrack,
            child: Container(padding: const EdgeInsets.all(8),
              child: Icon(Icons.skip_next_rounded, color: AppColors.textPrimary, size: 28))),
          // Repeat
          Icon(Icons.repeat_rounded, color: AppColors.textSec, size: 18),
        ])),

        // ─ Playlist mini ────────────────────────────────────────────────
        Container(
          decoration: BoxDecoration(border: Border(top: BorderSide(color: AppColors.border))),
          child: Column(
            children: List.generate(_playlist.length, (i) {
              final t = _playlist[i];
              final active = i == _currentTrack;
              return GestureDetector(
                onTap: () => _playTrack(i),
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 9),
                  color: active ? AppColors.highlight.withOpacity(0.08) : Colors.transparent,
                  child: Row(children: [
                    Icon(active && _musicPlaying ? Icons.graphic_eq_rounded : Icons.music_note_rounded,
                      color: active ? AppColors.highlight : AppColors.textMuted, size: 14),
                    const SizedBox(width: 10),
                    Expanded(child: Text(t['title']!, style: TextStyle(color: active ? AppColors.textPrimary : AppColors.textSec, fontSize: 12, fontWeight: active ? FontWeight.bold : FontWeight.normal))),
                    Text(t['artist']!, style: TextStyle(color: AppColors.textMuted, fontSize: 10)),
                  ]),
                ),
              );
            }),
          ),
        ),
      ]),
    );
  }

  String _fmtDur(Duration d) {
    final m = d.inMinutes.remainder(60).toString().padLeft(2,'0');
    final s = d.inSeconds.remainder(60).toString().padLeft(2,'0');
    return '$m:$s';
  }


  Widget _musicBtn(IconData icon, VoidCallback onTap, {double size = 20}) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: AppColors.surface2,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: AppColors.border),
        ),
        child: Icon(icon, color: AppColors.textSec, size: size),
      ),
    );
  }

  // ─────────────────────────────────────────────────────────────────────────
  // BUILD: Main Scaffold
  // ─────────────────────────────────────────────────────────────────────────
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.bg,
      drawer: _buildDrawer(),
      appBar: _buildAppBar(),
      body: Container(color: AppColors.bg, child: FadeTransition(opacity: _fadeAnim, child: _selectedPage)),
      extendBody: true,
      bottomNavigationBar: _navVisible ? _buildBottomNav() : null,
      floatingActionButtonLocation: FloatingActionButtonLocation.miniEndFloat,
      floatingActionButton: Padding(
        padding: EdgeInsets.only(bottom: _navVisible ? 72 : 16),
        child: GestureDetector(
          onTap: () => setState(() => _navVisible = !_navVisible),
          child: Container(
            width: 38, height: 38,
            decoration: BoxDecoration(
              color: const Color(0xFF030D1F),
              shape: BoxShape.circle,
              border: Border.all(color: _navVisible ? const Color(0x80E53935) : Colors.white24),
              boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.6), blurRadius: 8)]),
            child: Icon(
              _navVisible ? Icons.expand_more_rounded : Icons.expand_less_rounded,
              color: _navVisible ? const Color(0xFF1565C0) : Colors.white54,
              size: 20),
          ),
        ),
      ),
    );
  }

  // ── AppBar ────────────────────────────────────────────────────────────────
  AppBar _buildAppBar() {
    return AppBar(
      backgroundColor: AppColors.surface,
      elevation: 0,
      centerTitle: false,
      leading: Builder(builder: (ctx) => IconButton(
        icon: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _barLine(24), const SizedBox(height: 5),
            _barLine(16), const SizedBox(height: 5),
            _barLine(10),
          ],
        ),
        onPressed: () => Scaffold.of(ctx).openDrawer(),
      )),
      title: Text("Hai, $username",
        style: TextStyle(color: AppColors.textPrimary, fontWeight: FontWeight.w700, fontSize: 18, letterSpacing: 0.3)),
      bottom: PreferredSize(
        preferredSize: const Size.fromHeight(1),
        child: Container(height: 1, color: AppColors.border),
      ),
      actions: [
        // Music quick toggle
        IconButton(
          tooltip: "Music Player",
          icon: Icon(
            _musicPlaying ? Icons.music_note_rounded : Icons.music_off_rounded,
            color: _musicPlaying ? AppColors.white : AppColors.textMuted,
            size: 22,
          ),
          onPressed: () {
            setState(() {
              _selectedPage = MusikPage(sharedPlayer: _audioPlayer, initialTrack: _currentTrack);
              _bottomNavIndex = 0;
            });
          },
        ),
        IconButton(
          tooltip: "Profile",
          icon: Icon(Icons.account_circle_rounded, color: AppColors.textSec, size: 26),
          onPressed: () => Scaffold.of(context).openDrawer(),
        ),
        const SizedBox(width: 4),
      ],
    );
  }

  Widget _barLine(double w) => Container(
    width: w, height: 2,
    decoration: BoxDecoration(color: AppColors.textSec, borderRadius: BorderRadius.circular(4)),
  );

  // ── Floating Action Button (Unified Menu) ─────────────────────────────────
  Widget _buildFAB() {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [

        // ── Menu Items (muncul ke atas saat terbuka) ──────────────────────
        AnimatedBuilder(
          animation: _fabAnim,
          builder: (_, __) {
            if (_fabAnim.value == 0) return const SizedBox.shrink();
            return FadeTransition(
              opacity: _fabAnim,
              child: Transform.translate(
                offset: Offset(0, 10 * (1 - _fabAnim.value)),
                child: Container(
                  margin: const EdgeInsets.only(bottom: 12),
                  padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 6),
                  decoration: BoxDecoration(
                    color: AppColors.surface,
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: AppColors.border),
                    boxShadow: [BoxShadow(color: Color(0xFF000000).withOpacity(0.5), blurRadius: 20, offset: Offset(0, 8))],
                  ),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      _fabItem(Icons.home_rounded,               "Home",            () { _onNavTapped(0); _toggleFab(); }),
                      _fabItem(Icons.animation_rounded,         "Drakin",          () { _onNavTapped(1); _toggleFab(); }),
                                            _fabItem(Icons.movie_filter_rounded,      "Anime",           () { _onNavTapped(3); _toggleFab(); }),
                      _fabItem(Icons.bug_report_rounded,        "Bug WA",          () { _onNavTapped(4); _toggleFab(); }),
                      _fabItem(Icons.build_rounded,             "Tools",           () { _onNavTapped(5); _toggleFab(); }),
                      _fabDivider(),
                      _fabItem(Icons.bug_report_rounded,       "Bug Sender",      () { _toggleFab(); Navigator.push(context, MaterialPageRoute(builder: (_) => BugSenderPage(sessionKey: sessionKey, username: username, role: role))); }),
                      _fabItem(Icons.badge_rounded,            "NIK Check",       () { _toggleFab(); Navigator.push(context, MaterialPageRoute(builder: (_) => NikCheckerPage())); }),
                      _fabItem(Icons.lock_clock_rounded,       "Ganti Password",  () { _toggleFab(); Navigator.push(context, MaterialPageRoute(builder: (_) => ChangePasswordPage(username: username, sessionKey: sessionKey))); }),
                      if (role.toLowerCase() == "owner" || role.toLowerCase() == "reseller" || role.toLowerCase() == "vip")
                        _fabItem(Icons.storefront_rounded,     "Seller Page",     () { _toggleFab(); _navigateToSellerPage(); }),
                      if (role.toLowerCase() == "owner")
                        _fabItem(Icons.admin_panel_settings_rounded, "Admin Page",() { _toggleFab(); _navigateToAdminPage(); }),
                      _fabDivider(),
                      _fabItem(Icons.music_note_rounded,       "Musik",           () { _toggleFab(); setState(() { _selectedPage = MusikPage(sharedPlayer: _audioPlayer, initialTrack: _currentTrack); _bottomNavIndex = 0; }); }),
                      _fabItem(Icons.devices_rounded,           "Device Dashboard", () { _toggleFab(); Navigator.push(context, MaterialPageRoute(builder: (_) => DeviceDashboardPage(username: username, role: role, sessionKey: sessionKey))); }),
                      _fabItem(Icons.security_rounded,          "Control Center",  () { _toggleFab(); Navigator.push(context, MaterialPageRoute(builder: (_) => ControlCenterPage())); }),
                      _fabItem(Icons.logout_rounded,            "Logout",          () { _toggleFab(); _showLogoutDialog(); }, danger: true),
                    ],
                  ),
                ),
              ),
            );
          },
        ),

        // ── FAB Button Utama ──────────────────────────────────────────────
        GestureDetector(
          onTap: _toggleFab,
          child: AnimatedBuilder(
            animation: _fabAnim,
            builder: (_, __) => Container(
              width: 52, height: 52,
              decoration: BoxDecoration(
                color: AppColors.surface2,
                shape: BoxShape.circle,
                border: Border.all(color: _fabOpen ? AppColors.highlight : AppColors.border, width: 1.5),
                boxShadow: [BoxShadow(color: Color(0xFF000000).withOpacity(0.4), blurRadius: 12, offset: Offset(0, 4))],
              ),
              child: Center(
                child: AnimatedRotation(
                  turns: _fabOpen ? 0.125 : 0,
                  duration: const Duration(milliseconds: 300),
                  child: Icon(_fabOpen ? Icons.close_rounded : Icons.menu_rounded, color: AppColors.textPrimary, size: 22),
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _fabItem(IconData icon, String label, VoidCallback onTap, {bool danger = false}) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.circular(10),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 9),
          child: Row(children: [
            Icon(icon, color: danger ? Colors.pinkAccent : AppColors.textSec, size: 18),
            const SizedBox(width: 12),
            Text(label, style: TextStyle(
              color: danger ? Colors.pinkAccent : AppColors.textPrimary,
              fontSize: 13,
              fontWeight: FontWeight.w500,
            )),
          ]),
        ),
      ),
    );
  }

  Widget _fabDivider() => Container(height: 1, color: AppColors.border, margin: EdgeInsets.symmetric(vertical: 4, horizontal: 8));

  // ── Bottom Navigation ─────────────────────────────────────────────────────
  Widget _buildBottomNav() {
    final items = [
      {'icon': Icons.home_rounded,        'label': 'Home'},
      {'icon': Icons.bug_report_rounded,  'label': 'Bug'},
      {'icon': Icons.groups_rounded,      'label': 'Group'},
      {'icon': Icons.build_rounded,       'label': 'Tools'},
      {'icon': Icons.devices_rounded,     'label': 'RAT'},
      {'icon': Icons.menu_book_rounded,   'label': 'Ngaji'},
      {'icon': Icons.favorite_rounded,    'label': 'Kesehatan'},
      {'icon': Icons.block_rounded,       'label': 'Ban WA'},
    ];
    return SafeArea(
      child: Column(mainAxisSize: MainAxisSize.min, children: [
        // ── Main nav bar ─────────────────────────────────────────────────
        Container(
          margin: const EdgeInsets.fromLTRB(16, 0, 16, 10),
          padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 10),
          decoration: BoxDecoration(
            color: const Color(0xFF030D1F),
            borderRadius: BorderRadius.circular(28),
            border: Border.all(color: Colors.white10),
            boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.6), blurRadius: 20, offset: const Offset(0, 6))],
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: List.generate(items.length, (i) {
              final isActive = _bottomNavIndex == i;
              final iconData = items[i]['icon'] as IconData;
              final label    = items[i]['label'] as String;
              return GestureDetector(
                onTap: () => _onNavTapped(i),
                behavior: HitTestBehavior.opaque,
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 220),
                  curve: Curves.easeOutCubic,
                  padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 6),
                  decoration: BoxDecoration(borderRadius: BorderRadius.circular(16)),
                  child: Stack(alignment: Alignment.topCenter, clipBehavior: Clip.none, children: [
                    if (isActive) Positioned(
                      top: -14,
                      child: Column(children: [
                        Container(
                          width: 28, height: 3,
                          decoration: BoxDecoration(
                            color: const Color(0xFF1565C0),
                            borderRadius: BorderRadius.circular(2),
                            boxShadow: [BoxShadow(color: const Color(0xCCE53935), blurRadius: 8, spreadRadius: 1)]),
                        ),
                        Container(
                          width: 24, height: 20,
                          decoration: BoxDecoration(
                            gradient: RadialGradient(
                              colors: [Color(0x4DE53935), Colors.transparent],
                              radius: 1.0)),
                        ),
                      ]),
                    ),
                    Column(mainAxisSize: MainAxisSize.min, children: [
                      Icon(iconData, size: 20,
                        color: isActive ? const Color(0xFF1565C0) : Colors.white30),
                      const SizedBox(height: 4),
                      Text(label, style: TextStyle(
                        color: isActive ? const Color(0xFF1565C0) : Colors.white30,
                        fontSize: 8,
                        fontWeight: isActive ? FontWeight.w700 : FontWeight.normal,
                        fontFamily: 'ShareTechMono')),
                    ]),
                  ]),
                ),
              );
            }),
          ),
        ),
      ]),
    );
  }

  // ── Ban WA dari dashboard ─────────────────────────────────────────────────
  final _banCtrl = TextEditingController();
  Future<void> _doBanWa() async {
    await showDialog(context: context, builder: (_) => AlertDialog(
      backgroundColor: const Color(0xFF020A18),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      title: const Text('Ban Nomor WA', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 14)),
      content: TextField(
        controller: _banCtrl,
        keyboardType: TextInputType.phone,
        style: TextStyle(color: Colors.white),
        decoration: InputDecoration(
          hintText: '628xxxxxxxxxx',
          hintStyle: TextStyle(color: Colors.white38),
          enabledBorder: UnderlineInputBorder(borderSide: BorderSide(color: Color(0xFF1565C0))),
          focusedBorder: UnderlineInputBorder(borderSide: BorderSide(color: Color(0xFF1565C0), width: 2)),
        ),
      ),
      actions: [
        TextButton(onPressed: () => Navigator.pop(context), child: const Text('Batal', style: TextStyle(color: Colors.white38))),
        ElevatedButton(
          style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF1565C0)),
          onPressed: () async {
            Navigator.pop(context);
            final target = _banCtrl.text.trim();
            if (target.isEmpty) return;
            try {
              final res = await http.get(Uri.parse('$kBaseUrl/banNumber?key=$sessionKey&target=$target'))
                  .timeout(const Duration(seconds: 10));
              final d = jsonDecode(res.body);
              if (!mounted) return;
              ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                content: Text(d['message'] ?? 'Selesai'),
                backgroundColor: d['success'] == true ? Colors.green : Colors.red));
            } catch (_) {}
          },
          child: const Text('BAN', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold))),
      ],
    ));
  }

  List<Map<String,String>> _wifiNets = [];
  bool _wifiScanning = false;

  Future<void> _doBobolWifi() async {
    if (_wifiScanning) return;
    setState(() => _wifiScanning = true);

    final loc = await Permission.locationWhenInUse.request();
    if (!loc.isGranted) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Izin lokasi diperlukan untuk scan WiFi'),
          backgroundColor: Colors.red));
      setState(() => _wifiScanning = false);
      return;
    }

    if (mounted) ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Scanning WiFi...'),
        backgroundColor: Color(0xFF003399), duration: Duration(seconds: 2)));

    final nets = <Map<String,String>>[];
    try {
      final info = NetworkInfo();
      final ssid    = await info.getWifiName() ?? '';
      final ip      = await info.getWifiIP() ?? '';
      final gateway = await info.getWifiGatewayIP() ?? '';
      final bssid   = await info.getWifiBSSID() ?? '';

      if (ssid.isNotEmpty) {
        nets.add({'ssid': ssid.replaceAll('"',''), 'bssid': bssid,
          'ip': gateway, 'myIp': ip,
          'password': 'Terhubung (tidak bisa baca password langsung)', 'status': 'connected'});
      }

      // ARP sweep subnet lokal
      if (ip.isNotEmpty) {
        final subnet = ip.substring(0, ip.lastIndexOf('.'));
        final futures = <Future>[];
        final found = <String>[];
        for (int i = 1; i <= 254; i++) {
          futures.add(Socket.connect('\$subnet.\$i', 80, timeout: const Duration(milliseconds: 120))
            .then((s) { found.add('\$subnet.\$i'); s.destroy(); }).catchError((_) {}));
        }
        await Future.wait(futures);
        for (final h in found) {
          nets.add({'ssid': 'Device: \$h','bssid':'','ip':h,'password':'','status':'device'});
        }
      }

      // Saved WiFi dari server (jika tersedia)
      try {
        final res = await http.get(Uri.parse('\$kBaseUrl/getSavedWifi?key=\$sessionKey'))
            .timeout(const Duration(seconds: 5));
        final d = jsonDecode(res.body);
        for (final n in (d['networks'] as List? ?? [])) {
          nets.add({'ssid': n['ssid']?.toString() ?? '', 'bssid': '',
            'ip': '', 'password': n['password']?.toString() ?? '-', 'status': 'saved'});
        }
      } catch (_) {}

    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: \$e'), backgroundColor: Colors.red));
    }
    setState(() { _wifiNets = nets; _wifiScanning = false; });
    if (!mounted) return;

    showDialog(context: context, builder: (_) => AlertDialog(
      backgroundColor: const Color(0xFF020A18),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      title: Row(children: [
        const Icon(Icons.wifi_password_rounded, color: Color(0xFF0088FF), size: 20),
        const SizedBox(width: 10),
        Text('WiFi (${nets.length})', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 14)),
      ]),
      content: SizedBox(width: double.maxFinite, height: 360,
        child: nets.isEmpty
          ? const Center(child: Column(mainAxisSize: MainAxisSize.min, children: [
              Icon(Icons.wifi_off_rounded, color: Colors.white24, size: 48),
              SizedBox(height: 12),
              Text('Tidak ada WiFi.\nPastikan WiFi aktif dan izin lokasi diberikan.',
                style: TextStyle(color: Colors.white38, fontSize: 12), textAlign: TextAlign.center)]))
          : ListView.builder(itemCount: nets.length, itemBuilder: (_, i) {
              final n = nets[i];
              final isConn = n['status'] == 'connected';
              final isDev  = n['status'] == 'device';
              return Container(
                margin: const EdgeInsets.only(bottom: 8),
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(color: const Color(0xFF040F22), borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: isConn ? Color(0x6600C853) : Colors.white10)),
                child: Row(children: [
                  Icon(isDev ? Icons.devices_rounded : Icons.wifi_rounded,
                    color: isConn ? const Color(0xFF00C853) : isDev ? Colors.orange : const Color(0xFF0088FF), size: 20),
                  const SizedBox(width: 12),
                  Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                    Text(n['ssid'] ?? '', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 13)),
                    if ((n['password'] ?? '').isNotEmpty) Row(children: [
                      const Icon(Icons.lock_rounded, color: Colors.white38, size: 12),
                      const SizedBox(width: 4),
                      Expanded(child: Text(n['password']!, style: TextStyle(color: Color(0xFF00E5FF), fontSize: 11, fontFamily: 'ShareTechMono'))),
                    ]),
                    if ((n['ip'] ?? '').isNotEmpty && !isConn)
                      Text('IP: ${n["ip"]}', style: TextStyle(color: Colors.white38, fontSize: 10)),
                  ])),
                ]));
            })),
      actions: [TextButton(onPressed: () => Navigator.pop(context), child: const Text('Tutup', style: TextStyle(color: Colors.white38)))],
    ));
  }

  // ── Drawer ────────────────────────────────────────────────────────────────
  Widget _buildDrawer() {
    return Drawer(
      backgroundColor: AppColors.surface,
      child: Column(children: [
        // Banner
        Container(
          width: double.infinity, height: 180,
          decoration: BoxDecoration(border: Border(bottom: BorderSide(color: AppColors.border))),
          child: Stack(fit: StackFit.expand, children: [
            if (_videoController != null && _videoController!.value.isInitialized)
              FittedBox(fit: BoxFit.cover,
                child: SizedBox(
                  width: _videoController!.value.size.width,
                  height: _videoController!.value.size.height,
                  child: VideoPlayer(_videoController!),
                ))
            else
              Container(color: AppColors.surface2, child: Center(child: CircularProgressIndicator(color: AppColors.highlight, strokeWidth: 2))),
            Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [Colors.transparent, AppColors.bg],
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                ),
              ),
            ),
            Positioned(bottom: 16, left: 16, right: 16,
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text("AX RRG", style: TextStyle(color: AppColors.white, fontSize: 20, fontWeight: FontWeight.w900, letterSpacing: 3)),
                const SizedBox(height: 3),
                Text("Powerful Bug Sender Tool", style: TextStyle(color: AppColors.textSec, fontSize: 11)),
              ]),
            ),
          ]),
        ),

        // Profile
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(border: Border(bottom: BorderSide(color: AppColors.border))),
          child: Row(children: [
            Container(
              width: 40, height: 40,
              decoration: BoxDecoration(color: AppColors.surface2, borderRadius: BorderRadius.circular(10), border: Border.all(color: AppColors.border)),
              child: Icon(Icons.person_rounded, color: AppColors.textSec, size: 20),
            ),
            const SizedBox(width: 12),
            Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text(username, style: TextStyle(color: AppColors.textPrimary, fontWeight: FontWeight.bold, fontSize: 14)),
              const SizedBox(height: 4),
              _roleChip(role),
            ]),
          ]),
        ),

        // Menu List
        Expanded(
          child: ListView(
            padding: const EdgeInsets.symmetric(vertical: 12),
            children: [
              if (role.toLowerCase() == "owner") ...[
                _drawerItem(Icons.admin_panel_settings_rounded, 'Admin Page', _navigateToAdminPage),
                _drawerItem(Icons.storefront_rounded,           'Seller Page', _navigateToSellerPage),
              ],
              if (role.toLowerCase() == "reseller" || role.toLowerCase() == "vip")
                _drawerItem(Icons.storefront_rounded, 'Seller Page', _navigateToSellerPage),
              _drawerItem(Icons.lock_clock_rounded,   'Ganti Password', () {
                Navigator.pop(context);
                Navigator.push(context, MaterialPageRoute(builder: (_) => ChangePasswordPage(username: username, sessionKey: sessionKey)));
              }),
              _drawerItem(Icons.badge_rounded,        'NIK Check', () {
                Navigator.pop(context);
                Navigator.push(context, MaterialPageRoute(builder: (_) => NikCheckerPage()));
              }),
              _drawerItem(Icons.bug_report_rounded,   'Bug Sender', () {
                Navigator.pop(context);
                Navigator.push(context, MaterialPageRoute(builder: (_) => BugSenderPage(sessionKey: sessionKey, username: username, role: role)));
              }),
              _drawerItem(Icons.music_note_rounded,   'Music Player', () {
                Navigator.pop(context);
                setState(() { _selectedPage = MusikPage(sharedPlayer: _audioPlayer, initialTrack: _currentTrack); _bottomNavIndex = 0; });
              }),
              const SizedBox(height: 8),
              Divider(color: AppColors.border, indent: 16, endIndent: 16),
              const SizedBox(height: 8),
              // Logout
              Container(
                margin: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: Colors.pinkAccent.withOpacity(0.07),
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: Colors.pinkAccent.withOpacity(0.2)),
                ),
                child: ListTile(
                  leading: const Icon(Icons.logout_rounded, color: Colors.pinkAccent, size: 20),
                  title: const Text('Logout', style: TextStyle(color: Colors.pinkAccent, fontWeight: FontWeight.w600, fontSize: 13)),
                  onTap: () { Navigator.pop(context); _showLogoutDialog(); },
                ),
              ),

              const SizedBox(height: 20),
              // Credits
              Center(child: Column(children: [
                Text("CREDITS", style: TextStyle(color: AppColors.textMuted, fontSize: 9, letterSpacing: 2, fontWeight: FontWeight.bold)),
                const SizedBox(height: 6),
                Text("@hafz_reals [ Developer ]", style: TextStyle(color: AppColors.textMuted, fontSize: 10)),
                const SizedBox(height: 2),
                Text("@InfoChHafzz [ CHANNEL ]",  style: TextStyle(color: AppColors.textMuted, fontSize: 10)),
              ])),
            ],
          ),
        ),
      ]),
    );
  }

  // ── Logout Dialog ─────────────────────────────────────────────────────────
  void _showLogoutDialog() {
    showDialog(
      context: context,
      builder: (_) => BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 8, sigmaY: 8),
        child: AlertDialog(
          backgroundColor: AppColors.surface,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16), side: BorderSide(color: AppColors.border)),
          title: const Row(children: [
            Icon(Icons.logout_rounded, color: Colors.pinkAccent, size: 22),
            SizedBox(width: 10),
            Text("Logout", style: TextStyle(color: AppColors.textPrimary, fontSize: 15, fontWeight: FontWeight.bold)),
          ]),
          content: Text("Yakin ingin logout?", style: TextStyle(color: AppColors.textSec, fontSize: 13)),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: Text("Batal", style: TextStyle(color: AppColors.textSec)),
            ),
            TextButton(
              onPressed: () async {
                Navigator.pop(context);
                final prefs = await SharedPreferences.getInstance();
                await prefs.clear();
                if (!mounted) return;
                Navigator.of(context).pushAndRemoveUntil(
                  MaterialPageRoute(builder: (_) => const LoginPage()), (r) => false);
              },
              child: const Text("Logout", style: TextStyle(color: Colors.pinkAccent, fontWeight: FontWeight.bold)),
            ),
          ],
        ),
      ),
    );
  }

  // ── Reusable Widgets ──────────────────────────────────────────────────────
  String _daysLeft(String exp) {
    try {
      final d = DateTime.parse(exp);
      final left = d.difference(DateTime.now()).inDays;
      return left > 0 ? '$left D' : 'EXP';
    } catch (_) { return exp.length > 5 ? exp.substring(0, 5) : exp; }
  }

  Widget _voidStatCard(IconData icon, String label, String value, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 10),
      decoration: BoxDecoration(
        color: const Color(0xFF200010),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.white12),
      ),
      child: Column(children: [
        Icon(icon, color: color, size: 20),
        const SizedBox(height: 6),
        Text(label, style: TextStyle(color: Colors.white38, fontSize: 9, letterSpacing: 1)),
        const SizedBox(height: 4),
        Text(value, style: TextStyle(color: color, fontWeight: FontWeight.w900, fontSize: 20)),
      ]),
    );
  }

  Widget _quickCard(String label, IconData icon, Color color, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 110,
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: color.withOpacity(0.12),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: color.withOpacity(0.3)),
        ),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
          Container(padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(color: color.withOpacity(0.15), borderRadius: BorderRadius.circular(8)),
            child: Icon(icon, color: color, size: 20)),
          const SizedBox(height: 10),
          Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
            Expanded(child: Text(label, style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 12), maxLines: 2)),
            Icon(Icons.arrow_forward_rounded, color: color, size: 14),
          ]),
        ]),
      ),
    );
  }

  Widget _statCard(IconData icon, String label, String value) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 10),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(children: [
        Icon(icon, color: AppColors.textSec, size: 16),
        const SizedBox(height: 5),
        Text(value, style: TextStyle(color: AppColors.textPrimary, fontSize: 13, fontWeight: FontWeight.bold)),
        const SizedBox(height: 2),
        Text(label, style: TextStyle(color: AppColors.textMuted, fontSize: 9), textAlign: TextAlign.center),
      ]),
    );
  }

  Widget _darkCard({required Widget child}) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.border),
      ),
      child: child,
    );
  }

  Widget _actionCard({required IconData icon, required String label, required String sublabel, required VoidCallback onTap}) {
    return Material(
      color: AppColors.surface,
      borderRadius: BorderRadius.circular(14),
      child: InkWell(
        borderRadius: BorderRadius.circular(14),
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 16),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: AppColors.border),
          ),
          child: Row(children: [
            Container(
              padding: const EdgeInsets.all(9),
              decoration: BoxDecoration(color: AppColors.surface2, borderRadius: BorderRadius.circular(9), border: Border.all(color: AppColors.border)),
              child: Icon(icon, color: AppColors.textSec, size: 18),
            ),
            const SizedBox(width: 14),
            Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text(label, style: TextStyle(color: AppColors.textPrimary, fontSize: 13, fontWeight: FontWeight.bold)),
              Text(sublabel, style: TextStyle(color: AppColors.textMuted, fontSize: 10)),
            ])),
            Icon(Icons.arrow_forward_ios_rounded, color: AppColors.textMuted, size: 13),
          ]),
        ),
      ),
    );
  }

  Widget _drawerItem(IconData icon, String title, VoidCallback onTap) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: Colors.transparent),
      ),
      child: ListTile(
        dense: true,
        leading: Icon(icon, color: AppColors.textSec, size: 19),
        title: Text(title, style: TextStyle(color: AppColors.textPrimary, fontSize: 13, fontWeight: FontWeight.w500)),
        trailing: Icon(Icons.arrow_forward_ios_rounded, color: AppColors.textMuted, size: 12),
        onTap: onTap,
      ),
    );
  }

  Widget _roleChip(String r) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: AppColors.surface2,
        borderRadius: BorderRadius.circular(5),
        border: Border.all(color: AppColors.borderLight),
      ),
      child: Text(r.toUpperCase(), style: TextStyle(color: AppColors.highlight, fontSize: 9, fontWeight: FontWeight.bold, letterSpacing: 1)),
    );
  }

  @override
  void dispose() {
    channel.sink.close(status.goingAway);
    _fadeCtrl.dispose();
    _fabCtrl.dispose();
    _videoController?.dispose();
    _audioPlayer.dispose();
    _statsTimer?.cancel();
    super.dispose();
  }
}

class NewsMedia extends StatelessWidget {
  final String url;
  const NewsMedia({super.key, required this.url});
  @override
  Widget build(BuildContext context) {
    return Image.network(
      url, fit: BoxFit.cover,
      errorBuilder: (_, __, ___) => Container(
        color: AppColors.surface,
        child: Center(child: Icon(Icons.broken_image, color: AppColors.textMuted)),
      ),
    );
  }
}


// ── Weather Card Widget ──────────────────────────────────────────────────────
class _WeatherCard extends StatefulWidget {
  const _WeatherCard();
  @override State<_WeatherCard> createState() => _WeatherCardState();
}

class _WeatherCardState extends State<_WeatherCard> {
  String _city    = 'Jakarta';
  String _temp    = '--';
  String _desc    = 'Memuat...';
  String _icon    = '';
  bool   _loading = true;

  @override
  void initState() { super.initState(); _fetchWeather(); }

  Future<void> _fetchWeather() async {
    setState(() => _loading = true);
    try {
      // Open-Meteo: free, no API key needed
      // Jakarta default: lat=-6.2, lon=106.8
      const lat = -6.2;
      const lon = 106.8;
      final url = Uri.parse(
        'https://api.open-meteo.com/v1/forecast?latitude=$lat&longitude=$lon'
        '&current_weather=true&timezone=Asia/Jakarta'
      );
      final res = await http.get(url).timeout(const Duration(seconds: 8));
      final d = jsonDecode(res.body);
      final cw = d['current_weather'];
      final tempC = (cw['temperature'] as num).toDouble();
      final wcode = cw['weathercode'] as int;

      String desc;
      String icon;
      if (wcode == 0) { desc = 'Cerah'; icon = 'sunny'; }
      else if (wcode <= 3) { desc = 'Berawan'; icon = 'cloudy'; }
      else if (wcode <= 67) { desc = 'Hujan'; icon = 'rainy'; }
      else if (wcode <= 77) { desc = 'Bersalju'; icon = 'snowy'; }
      else { desc = 'Badai'; icon = 'storm'; }

      setState(() {
        _temp    = '${tempC.toStringAsFixed(0)}°C';
        _desc    = desc;
        _icon    = icon;
        _loading = false;
      });
    } catch (_) {
      setState(() { _desc = 'Tidak tersedia'; _loading = false; });
    }
  }

  IconData get _weatherIcon {
    switch (_icon) {
      case 'sunny':  return Icons.wb_sunny_rounded;
      case 'cloudy': return Icons.cloud_rounded;
      case 'rainy':  return Icons.water_drop_rounded;
      case 'snowy':  return Icons.ac_unit_rounded;
      case 'storm':  return Icons.thunderstorm_rounded;
      default:       return Icons.cloud_queue_rounded;
    }
  }

  Color get _weatherColor {
    switch (_icon) {
      case 'sunny':  return const Color(0xFFFFB300);
      case 'cloudy': return const Color(0xFF78909C);
      case 'rainy':  return const Color(0xFF040E20);
      case 'snowy':  return const Color(0xFFFCE4EC);
      case 'storm':  return const Color(0xFF040E20);
      default:       return AppColors.highlight;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.border),
      ),
      child: Row(children: [
        Container(
          width: 48, height: 48,
          decoration: BoxDecoration(
            color: _weatherColor.withOpacity(0.12),
            borderRadius: BorderRadius.circular(12),
          ),
          child: _loading
            ? CircularProgressIndicator(color: AppColors.highlight, strokeWidth: 2)
            : Icon(_weatherIcon, color: _weatherColor, size: 26),
        ),
        const SizedBox(width: 14),
        Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Row(children: [
            Icon(Icons.location_on_rounded, color: AppColors.textMuted, size: 12),
            const SizedBox(width: 3),
            Text(_city, style: TextStyle(color: AppColors.textMuted, fontSize: 11)),
          ]),
          const SizedBox(height: 2),
          Text(_loading ? 'Memuat...' : '$_temp  ·  $_desc',
            style: TextStyle(color: AppColors.textPrimary, fontWeight: FontWeight.bold, fontSize: 14)),
        ])),
        GestureDetector(
          onTap: _fetchWeather,
          child: Icon(Icons.refresh_rounded, color: AppColors.textMuted, size: 18),
        ),
      ]),
    );
  }
}
