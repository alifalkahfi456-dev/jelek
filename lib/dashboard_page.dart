// dashboard_page.dart — FULL CODE LENGKAP (CYBER RAINBOW DIGITAL THEME)
import 'dart:convert';
import 'dart:async';
import 'dart:io';
import 'dart:math' as math;
import 'package:http/http.dart' as http;
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:device_info_plus/device_info_plus.dart';
import 'package:web_socket_channel/web_socket_channel.dart';
import 'package:web_socket_channel/status.dart' as status;
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:video_player/video_player.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:geolocator/geolocator.dart';
import 'package:geocoding/geocoding.dart';

import 'api_config.dart';
import 'nik_check.dart';
import 'admin_page.dart';
import 'owner_page.dart';
import 'home_page.dart';
import 'seller_page.dart';
import 'change_password_page.dart';
import 'tools_gateway.dart';
import 'login_page.dart';
import 'bug_sender.dart';
import 'global_chat.dart';
import 'contact_page.dart';
import 'profile_page.dart';
import 'riwayat_page.dart';
import 'info_page.dart';
import 'al_quran.dart';
import 'anime_home.dart';
import 'musik_page.dart';

// ─── PALETTE RAINBOW CYBER DIGITAL ──────────────────────────────────────────
const Color kBg      = Color(0xFF0A0015);
const Color kCard    = Color(0xFF1A0A2E);
const Color kCardAlt = Color(0xFF24103D);
const Color kBorder  = Color(0x407C3AED);
const Color kPurple  = Color(0xFF7C3AED);
const Color kPurpleL = Color(0xFFA78BFA);
const Color kPurpleG = Color(0xFFF0ABFC);
const Color kPink    = Color(0xFFE879F9);
const Color kCyan    = Color(0xFF67E8F9);
const Color kBlue    = Color(0xFF60A5FA);
const Color kGreen   = Color(0xFF34D399);
const Color kYellow  = Color(0xFFFBBF24);
const Color kOrange  = Color(0xFFFB923C);
const Color kRed     = Color(0xFFF87171);
const Color kRose    = Color(0xFFFB7185);
const Color kTeal    = Color(0xFF2DD4BF);
const Color kGold    = Color(0xFFFFD700);
const Color kWhite   = Color(0xFFF3E8FF);
const Color kWhite54 = Color(0x8AF3E8FF);
const Color kWhite24 = Color(0x3DF3E8FF);

const List<Color> _rainbowColors = [
  kPurple, kPink, kCyan, kGreen, kYellow, kOrange, kRed, kPurpleL, kBlue, kTeal, kGold
];

// ─── PRAYER TIME SERVICE ───────────────────────────────────────────────────
class PrayerTimeService {
  static Future<Map<String, dynamic>> fetchPrayerTimes(String city) async {
    final now = DateTime.now();
    final uri = Uri.https('api.aladhan.com', '/v1/timingsByCity', {
      'city': city, 'country': 'ID', 'method': '11',
      'day': '${now.day}', 'month': '${now.month}', 'year': '${now.year}',
    });
    try {
      final res = await http.get(uri).timeout(const Duration(seconds: 10));
      if (res.statusCode == 200) return jsonDecode(res.body);
    } catch (_) {}
    return {};
  }
}

// ─── ROLE HELPERS ─────────────────────────────────────────────────────────
Color _roleColor(String role) {
  switch (role.toLowerCase()) {
    case 'owner':    return kGold;
    case 'admin':    return kRed;
    case 'reseller': return kGreen;
    case 'vip':      return kPurple;
    default:         return kCyan;
  }
}

IconData _roleIcon(String role) {
  switch (role.toLowerCase()) {
    case 'owner':    return Icons.workspace_premium_rounded;
    case 'admin':    return Icons.admin_panel_settings_rounded;
    case 'reseller': return Icons.storefront_rounded;
    case 'vip':      return Icons.star_rounded;
    default:         return Icons.person_rounded;
  }
}

// ─── ANIMATED DOT ──────────────────────────────────────────────────────────
class _AnimatedDot extends StatefulWidget {
  final Color color;
  final double size;
  const _AnimatedDot({required this.color, this.size = 6});
  @override
  State<_AnimatedDot> createState() => _AnimatedDotState();
}

class _AnimatedDotState extends State<_AnimatedDot>
    with SingleTickerProviderStateMixin {
  late AnimationController _c;
  late Animation<double> _a;
  @override
  void initState() {
    super.initState();
    _c = AnimationController(vsync: this, duration: const Duration(milliseconds: 900))
      ..repeat(reverse: true);
    _a = Tween<double>(begin: 0.3, end: 1.0)
        .animate(CurvedAnimation(parent: _c, curve: Curves.easeInOut));
  }
  @override
  void dispose() { _c.dispose(); super.dispose(); }
  @override
  Widget build(BuildContext context) => FadeTransition(
    opacity: _a,
    child: Container(
      width: widget.size, height: widget.size,
      decoration: BoxDecoration(
        shape: BoxShape.circle, color: widget.color,
        boxShadow: [BoxShadow(color: widget.color.withOpacity(0.8), blurRadius: 8, spreadRadius: 2)],
      ),
    ),
  );
}

// ─── TYPING TEXT WIDGET ────────────────────────────────────────────────────
class _TypingText extends StatefulWidget {
  final String text;
  final TextStyle? style;
  final Duration speed;
  const _TypingText({required this.text, this.style, this.speed = const Duration(milliseconds: 60)});

  @override
  State<_TypingText> createState() => _TypingTextState();
}

class _TypingTextState extends State<_TypingText> with SingleTickerProviderStateMixin {
  String _displayText = '';
  int _index = 0;
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    _startTyping();
  }

  void _startTyping() {
    _timer = Timer.periodic(widget.speed, (timer) {
      if (_index < widget.text.length) {
        setState(() {
          _displayText += widget.text[_index];
          _index++;
        });
      } else {
        timer.cancel();
      }
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Text(
      _displayText,
      style: widget.style,
    );
  }
}

// ─── HEXAGON PATTERN PAINTER ──────────────────────────────────────────────
class _HexagonPatternPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = kPurple.withOpacity(0.08)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 0.8;

    const double w = 72.0;
    const double h = 52.0;

    for (double row = -1; row * h < size.height + h * 2; row++) {
      for (double col = -1; col * w < size.width + w * 2; col++) {
        final double offsetX = (row.toInt() % 2 == 0) ? 0 : w * 0.5;
        final cx = col * w + offsetX;
        final cy = row * h;
        _drawDiamond(canvas, paint, Offset(cx, cy), w * 0.5, h * 0.5);
      }
    }
  }

  void _drawDiamond(Canvas canvas, Paint paint, Offset center, double hw, double hh) {
    final path = Path()
      ..moveTo(center.dx, center.dy - hh)
      ..lineTo(center.dx + hw, center.dy)
      ..lineTo(center.dx, center.dy + hh)
      ..lineTo(center.dx - hw, center.dy)
      ..close();
    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter _) => false;
}

// ─── GRID PATTERN PAINTER ──────────────────────────────────────────────────
class _GridPatternPainter extends CustomPainter {
  final Color gridColor;
  final Color lineColor;
  final double spacing;
  const _GridPatternPainter({required this.gridColor, required this.lineColor, required this.spacing});
  @override
  void paint(Canvas canvas, Size size) {
    final paintGrid = Paint()..color = gridColor..strokeWidth = 0.8..style = PaintingStyle.stroke;
    final paintLines = Paint()..color = lineColor..strokeWidth = 0.4..style = PaintingStyle.stroke;
    for (double x = 0; x < size.width; x += spacing) {
      canvas.drawLine(Offset(x, 0), Offset(x, size.height), paintGrid);
    }
    for (double y = 0; y < size.height; y += spacing) {
      canvas.drawLine(Offset(0, y), Offset(size.width, y), paintGrid);
    }
    for (double x = -size.height; x < size.width + size.height; x += spacing * 2) {
      canvas.drawLine(Offset(x, 0), Offset(x + size.height, size.height), paintLines);
    }
    for (double x = -size.height; x < size.width + size.height; x += spacing * 2) {
      canvas.drawLine(Offset(x, size.height), Offset(x + size.height, 0), paintLines);
    }
  }
  @override
  bool shouldRepaint(covariant CustomPainter _) => false;
}

// ─── DASHBOARD PAGE ────────────────────────────────────────────────────────
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
  // ── STATE ────────────────────────────────────────────────────────────────
  late String sessionKey, username, password, role, expiredDate;
  late List<Map<String, dynamic>> listBug, listDoos;
  late List<dynamic> newsList;

  late WebSocketChannel channel;
  String androidId = 'unknown';
  File? _profileImage;
  VideoPlayerController? _menuVideoCtrl;

  int _navIndex   = 0;
  int onlineUsers = 0;
  int activeConns = 0;

  // ── ANIMATION CONTROLLERS ──────────────────────────────────────────────
  late AnimationController _fadeCtrl;
  late Animation<double> _fadeAnim;
  late AnimationController _pulseCtrl;
  late Animation<double> _pulseAnim;
  late AnimationController _rotateCtrl;
  late Animation<double> _rotateAnim;
  late AnimationController _glowCtrl;
  late Animation<double> _glowAnim;
  late AnimationController _bounceCtrl;
  late Animation<double> _bounceAnim;

  // ── DIGITAL CLOCK ────────────────────────────────────────────────────────
  Timer? _clockTimer;
  String _timeWIB = '--:--:--';
  String _timeWITA = '--:--:--';
  String _timeWIT = '--:--:--';
  bool _showColon = true;

  Timer? _statsTimer;

  // News carousel
  late PageController _newsPageCtrl;
  int _newsPageViewKey = 0;
  double _currentNewsPage = 0.0;

  // Quick Actions carousel
  late PageController _qaPageCtrl;
  double _currentQaPage = 0.0;

  // ── LOCATION ──
  bool _locationLoading = false;
  bool _locationGranted = false;

  // ── PRAYER TIMES ──
  String _prayerCity = 'Surabaya';
  Map<String, String> _prayerTimes = {};
  String _nextPrayerLabel = '';
  String _nextPrayerTime  = '';
  bool _prayerLoading = true;

  // ── HADITH ──
  Map<String, dynamic>? _hadith;
  bool _hadithLoading = true;
  int _lastHadithNumber = 0;

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

    _fadeCtrl = AnimationController(vsync: this, duration: const Duration(milliseconds: 800))..forward();
    _fadeAnim = CurvedAnimation(parent: _fadeCtrl, curve: Curves.easeOut);

    _pulseCtrl = AnimationController(vsync: this, duration: const Duration(seconds: 2))
      ..repeat(reverse: true);
    _pulseAnim = CurvedAnimation(parent: _pulseCtrl, curve: Curves.easeInOut);

    _rotateCtrl = AnimationController(vsync: this, duration: const Duration(seconds: 20))..repeat();
    _rotateAnim = Tween<double>(begin: 0.0, end: 2 * math.pi)
        .animate(CurvedAnimation(parent: _rotateCtrl, curve: Curves.linear));

    _glowCtrl = AnimationController(vsync: this, duration: const Duration(milliseconds: 2000))
      ..repeat(reverse: true);
    _glowAnim = CurvedAnimation(parent: _glowCtrl, curve: Curves.easeInOut);

    _bounceCtrl = AnimationController(vsync: this, duration: const Duration(milliseconds: 800))
      ..repeat(reverse: true);
    _bounceAnim = Tween<double>(begin: 0.96, end: 1.0)
        .animate(CurvedAnimation(parent: _bounceCtrl, curve: Curves.easeInOut));

    _newsPageCtrl = PageController(viewportFraction: 0.88, initialPage: 0);
    _newsPageCtrl.addListener(() {
      if (mounted) setState(() => _currentNewsPage = _newsPageCtrl.page ?? 0.0);
    });

    _qaPageCtrl = PageController(viewportFraction: 0.88, initialPage: 0);
    _qaPageCtrl.addListener(() {
      if (mounted) setState(() => _currentQaPage = _qaPageCtrl.page ?? 0.0);
    });

    // ─── CLOCK ──────────────────────────────────────────────────────────────
    _updateClock();
    _clockTimer = Timer.periodic(const Duration(seconds: 1), (_) {
      _updateClock();
      setState(() => _showColon = !_showColon);
    });

    _initAndroidId();
    _loadProfileImage();
    _initMenuVideo();
    _detectLocationAndFetchPrayer();
    _fetchRandomHadith();
  }

  @override
  void dispose() {
    _clockTimer?.cancel();
    _statsTimer?.cancel();
    channel.sink.close(status.goingAway);
    _fadeCtrl.dispose();
    _pulseCtrl.dispose();
    _rotateCtrl.dispose();
    _glowCtrl.dispose();
    _bounceCtrl.dispose();
    _menuVideoCtrl?.dispose();
    _newsPageCtrl.dispose();
    _qaPageCtrl.dispose();
    super.dispose();
  }

  void _updateClock() {
    final now = DateTime.now().toUtc();
    final wib = now.add(const Duration(hours: 7));
    final wita = now.add(const Duration(hours: 8));
    final wit = now.add(const Duration(hours: 9));
    setState(() {
      _timeWIB = _formatTime(wib);
      _timeWITA = _formatTime(wita);
      _timeWIT = _formatTime(wit);
    });
  }

  String _formatTime(DateTime time) {
    return '${time.hour.toString().padLeft(2, '0')}:${time.minute.toString().padLeft(2, '0')}:${time.second.toString().padLeft(2, '0')}';
  }

  // ─── INIT HELPERS ────────────────────────────────────────────────────────
  Future<void> _loadProfileImage() async {
    final prefs = await SharedPreferences.getInstance();
    final path  = prefs.getString('profile_image_$username');
    if (path != null && path.isNotEmpty && mounted) {
      setState(() => _profileImage = File(path));
    }
  }

  void _initMenuVideo() {
    _menuVideoCtrl = VideoPlayerController.asset('assets/videos/banner.mp4')
      ..initialize().then((_) {
        if (mounted) setState(() {});
        _menuVideoCtrl?.setLooping(true);
        _menuVideoCtrl?.setVolume(0);
        _menuVideoCtrl?.play();
      });
  }

  Future<void> _initAndroidId() async {
    final info = await DeviceInfoPlugin().androidInfo;
    androidId = info.id;
    _connectWS();
  }

  void _connectWS() {
    channel = WebSocketChannel.connect(Uri.parse('http://tirzzadminbaik.pteroqdactyl.my.id:11560'));

    channel.sink.add(jsonEncode({
      'type': 'validate',
      'key': sessionKey,
      'androidId': androidId,
    }));

    channel.stream.listen((event) {
      final data = jsonDecode(event);

      if (data['type'] == 'myInfo' && data['valid'] == true && mounted) {
        channel.sink.add(jsonEncode({'type': 'stats'}));
      }

      if (data['type'] == 'stats' && mounted) {
        setState(() {
          onlineUsers = data['onlineUsers'] ?? 0;
          activeConns = data['activeConnections'] ?? 0;
        });
      }

      if (data['type'] == 'myInfo' && data['valid'] == false && mounted) {
        _handleInvalidSession(data['reason'] ?? 'Session invalid');
      }

      if (data['type'] == 'forceLogout' && mounted) {
        _handleInvalidSession(data['reason'] ?? 'Logged out');
      }
    }, onError: (_) {
      Future.delayed(const Duration(seconds: 3), () {
        if (mounted) _connectWS();
      });
    });

    _statsTimer = Timer.periodic(const Duration(seconds: 5), (_) {
      try {
        channel.sink.add(jsonEncode({'type': 'stats'}));
      } catch (_) {}
    });
  }

  Future<void> _openUrl(String url) async {
    await launchUrl(Uri.parse(url), mode: LaunchMode.externalApplication);
  }

  // ── FETCH PRAYER TIMES ────────────────────────────────────────────────────
  Future<void> _fetchPrayerTimes() async {
    if (!mounted) return;
    setState(() => _prayerLoading = true);
    final data = await PrayerTimeService.fetchPrayerTimes(_prayerCity);
    if (!mounted) return;
    if (data.isNotEmpty) {
      final timings = data['data']?['timings'] ?? {};
      final Map<String, String> times = {
        'Subuh'  : timings['Fajr']    ?? '--:--',
        'Dzuhur' : timings['Dhuhr']   ?? '--:--',
        'Ashar'  : timings['Asr']     ?? '--:--',
        'Maghrib': timings['Maghrib'] ?? '--:--',
        'Isya'   : timings['Isha']    ?? '--:--',
      };
      final now = TimeOfDay.now();
      String nextLabel = 'Isya';
      String nextTime  = times['Isya'] ?? '--:--';
      for (final entry in times.entries) {
        final parts = entry.value.split(':');
        if (parts.length >= 2) {
          final h = int.tryParse(parts[0]) ?? 0;
          final m = int.tryParse(parts[1]) ?? 0;
          if (h > now.hour || (h == now.hour && m > now.minute)) {
            nextLabel = entry.key;
            nextTime  = entry.value;
            break;
          }
        }
      }
      setState(() {
        _prayerTimes     = times;
        _nextPrayerLabel = nextLabel;
        _nextPrayerTime  = nextTime;
        _prayerLoading   = false;
      });
    } else {
      setState(() => _prayerLoading = false);
    }
  }

  // ── DETECT LOCATION ───────────────────────────────────────────────────────
  Future<void> _detectLocationAndFetchPrayer() async {
    if (!mounted) return;
    setState(() => _locationLoading = true);

    try {
      final serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        if (mounted) {
          setState(() {
            _locationLoading = false;
            _prayerCity = 'Surabaya';
          });
          await _fetchPrayerTimes();
        }
        return;
      }

      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
        if (permission == LocationPermission.denied) {
          if (mounted) {
            setState(() {
              _locationLoading = false;
              _prayerCity = 'Surabaya';
            });
            await _fetchPrayerTimes();
          }
          return;
        }
      }

      if (permission == LocationPermission.deniedForever) {
        if (mounted) {
          setState(() {
            _locationLoading = false;
            _prayerCity = 'Surabaya';
          });
          await _fetchPrayerTimes();
        }
        return;
      }

      final position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.medium,
      );

      final placemarks = await placemarkFromCoordinates(
        position.latitude,
        position.longitude,
      );

      if (placemarks.isNotEmpty && mounted) {
        final place = placemarks.first;
        final city = place.subAdministrativeArea?.isNotEmpty == true
            ? place.subAdministrativeArea!
            : place.locality?.isNotEmpty == true
                ? place.locality!
                : place.administrativeArea ?? 'Surabaya';

        setState(() {
          _prayerCity     = city;
          _locationGranted = true;
          _locationLoading = false;
        });

        await _fetchPrayerTimes();

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Row(children: [
                const Icon(Icons.location_on_rounded, color: Colors.white, size: 16),
                const SizedBox(width: 8),
                Text('Lokasi terdeteksi: $city'),
              ]),
              backgroundColor: kGreen,
              behavior: SnackBarBehavior.floating,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              duration: const Duration(seconds: 3),
            ),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _locationLoading = false;
          _prayerCity = 'Surabaya';
        });
        await _fetchPrayerTimes();
      }
    }
  }

  // ── FETCH HADITH ──────────────────────────────────────────────────────────
  Future<void> _fetchRandomHadith() async {
    if (!mounted) return;
    setState(() => _hadithLoading = true);
    try {
      int randomNumber;
      do {
        randomNumber = math.Random().nextInt(100) + 1;
      } while (randomNumber == _lastHadithNumber);
      _lastHadithNumber = randomNumber;
      final response = await http
          .get(Uri.parse('https://api.hadith.gading.dev/books/muslim/$randomNumber'))
          .timeout(const Duration(seconds: 8));
      if (response.statusCode == 200 && mounted) {
        setState(() { _hadith = json.decode(response.body); _hadithLoading = false; });
      } else {
        if (mounted) setState(() => _hadithLoading = false);
      }
    } catch (_) {
      if (mounted) setState(() => _hadithLoading = false);
    }
  }

  // ── CHANGE CITY DIALOG ────────────────────────────────────────────────────
  void _showChangeCityDialog() {
    final ctrl = TextEditingController(text: _prayerCity);
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        backgroundColor: kCard,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
        title: const Text('Ganti Lokasi',
            style: TextStyle(color: kWhite, fontFamily: 'Orbitron', fontSize: 14)),
        content: TextField(
          controller: ctrl,
          style: const TextStyle(color: kWhite),
          decoration: InputDecoration(
            hintText: 'Nama kota (misal: Jakarta)',
            hintStyle: const TextStyle(color: kWhite54),
            filled: true, fillColor: kBg,
            border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
            prefixIcon: const Icon(Icons.location_city_rounded, color: kPurple),
          ),
        ),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Batal', style: TextStyle(color: kWhite54))),
          ElevatedButton(
            onPressed: () {
              if (ctrl.text.trim().isNotEmpty) {
                setState(() {
                  _prayerCity = ctrl.text.trim();
                  _locationGranted = false;
                });
                _fetchPrayerTimes();
                Navigator.pop(context);
              }
            },
            style: ElevatedButton.styleFrom(
                backgroundColor: kPurple,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10))),
            child: const Text('Simpan',
                style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }

  // ── HADITH FULL DIALOG ────────────────────────────────────────────────────
  void _showHadithFullDialog(String arabic, String indo, String source, String number, String grade) {
    showDialog(
      context: context,
      barrierDismissible: true,
      builder: (_) => Dialog(
        backgroundColor: Colors.transparent,
        insetPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 24),
        child: Container(
          decoration: BoxDecoration(
            color: kCard, borderRadius: BorderRadius.circular(24),
            border: Border.all(color: kPurple.withOpacity(0.5)),
            boxShadow: [
              BoxShadow(color: kPurple.withOpacity(0.2), blurRadius: 40, spreadRadius: 4),
              BoxShadow(color: Colors.black.withOpacity(0.8), blurRadius: 30, offset: const Offset(0, 10)),
            ],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                padding: const EdgeInsets.all(18),
                decoration: BoxDecoration(
                  borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
                  color: kPurple.withOpacity(0.15),
                  border: Border(bottom: BorderSide(color: kBorder.withOpacity(0.8))),
                ),
                child: Row(
                  children: [
                    Container(
                      width: 42, height: 42,
                      decoration: BoxDecoration(shape: BoxShape.circle, color: kPurple.withOpacity(0.3)),
                      child: const Icon(Icons.menu_book_rounded, color: kPurple, size: 22),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                        const Text('HADITH LENGKAP',
                            style: TextStyle(color: kWhite, fontWeight: FontWeight.bold, fontSize: 14, fontFamily: 'Orbitron')),
                        Text(grade, style: const TextStyle(color: kPurple, fontSize: 11)),
                      ]),
                    ),
                    GestureDetector(
                      onTap: () => Navigator.pop(context),
                      child: Container(
                        width: 34, height: 34,
                        decoration: BoxDecoration(shape: BoxShape.circle, color: kWhite.withOpacity(0.08)),
                        child: const Icon(Icons.close_rounded, color: kWhite54, size: 18),
                      ),
                    ),
                  ],
                ),
              ),
              ConstrainedBox(
                constraints: BoxConstraints(maxHeight: MediaQuery.of(context).size.height * 0.62),
                child: SingleChildScrollView(
                  physics: const BouncingScrollPhysics(),
                  padding: const EdgeInsets.all(18),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Container(
                        width: double.infinity, padding: const EdgeInsets.all(18),
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(16),
                          color: const Color(0xFF1C0000),
                          border: Border.all(color: kBorder.withOpacity(0.5)),
                        ),
                        child: Text(arabic,
                            textAlign: TextAlign.right, textDirection: TextDirection.rtl,
                            style: const TextStyle(color: kWhite, fontSize: 19, height: 2.2)),
                      ),
                      const SizedBox(height: 14),
                      Row(children: [
                        Container(width: 3, height: 18,
                            decoration: BoxDecoration(borderRadius: BorderRadius.circular(2), color: kPurple)),
                        const SizedBox(width: 8),
                        const Text('ARTINYA:', style: TextStyle(color: kPurple, fontSize: 11, fontWeight: FontWeight.bold, letterSpacing: 1.2)),
                      ]),
                      const SizedBox(height: 10),
                      Container(
                        width: double.infinity, padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(14),
                          color: const Color(0xFF150000),
                          border: Border.all(color: kBorder.withOpacity(0.4)),
                        ),
                        child: Text(indo,
                            style: const TextStyle(color: kWhite, fontSize: 14, fontStyle: FontStyle.italic, height: 1.8)),
                      ),
                      const SizedBox(height: 16),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(color: kPurple.withOpacity(0.6)),
                          color: kPurple.withOpacity(0.12),
                        ),
                        child: Row(mainAxisSize: MainAxisSize.min, children: [
                          const Icon(Icons.receipt_long_rounded, color: kPurple, size: 14),
                          const SizedBox(width: 6),
                          Text('${source.isNotEmpty ? source : "Muslim"} #$number',
                              style: const TextStyle(color: kPurple, fontSize: 12, fontWeight: FontWeight.bold)),
                        ]),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _handleInvalidSession(String message) async {
    await Future.delayed(const Duration(milliseconds: 300));
    final prefs = await SharedPreferences.getInstance();
    await prefs.clear();
    if (!mounted) return;
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => AlertDialog(
        backgroundColor: kCard,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
        title: const Text('⚠️ Session Expired', style: TextStyle(color: kWhite)),
        content: Text(message, style: const TextStyle(color: kWhite54)),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pushAndRemoveUntil(
                MaterialPageRoute(builder: (_) => const LoginPage()), (_) => false),
            child: const Text('OK', style: TextStyle(color: kPurple)),
          ),
        ],
      ),
    );
  }

  // ─── NAVIGATION ────────────────────────────────────────────────────────────
  void _onNavTap(int index) {
    setState(() => _navIndex = index);
    if (index == 0) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (_newsPageCtrl.hasClients) {
          setState(() { _currentNewsPage = 0.0; _newsPageViewKey++; });
          _newsPageCtrl.jumpToPage(0);
        }
      });
    }
  }

  void _onDrawerNav(int index) {
    Widget page;
    switch (index) {
      case 1: page = SellerPage(keyToken: sessionKey); break;
      case 2: page = AdminPage(sessionKey: sessionKey); break;
      case 3: page = OwnerPage(sessionKey: sessionKey, username: username); break;
      default: return;
    }
    Navigator.pop(context);
    Navigator.push(context, MaterialPageRoute(builder: (_) => page)).then((_) {
      if (mounted) {
        setState(() => _navIndex = 0);
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (_newsPageCtrl.hasClients) {
            setState(() { _currentNewsPage = 0.0; _newsPageViewKey++; });
            _newsPageCtrl.jumpToPage(0);
          }
        });
      }
    });
  }

  // ── CURRENT PAGE ──────────────────────────────────────────────────────────
  Widget _buildCurrentPage() {
    switch (_navIndex) {
      case 1:
        return HomePage(
          username: username, password: password,
          listBug: listBug, role: role,
          expiredDate: expiredDate, sessionKey: sessionKey,
        );
      case 2:
        return InfoPage(sessionKey: sessionKey);
      case 3:
        return ToolsPage(sessionKey: sessionKey, userRole: role, listDoos: listDoos);
      case 0:
      default:
        return _buildHomePage();
    }
  }

  // ─── HOME PAGE ─────────────────────────────────────────────────────────────
  Widget _buildHomePage() {
    return FadeTransition(
      opacity: _fadeAnim,
      child: SingleChildScrollView(
        physics: const BouncingScrollPhysics(),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildBannerVideo(),
            const SizedBox(height: 14),
            _buildDigitalClock(),
            const SizedBox(height: 14),
            _buildWelcomeCard(),
            const SizedBox(height: 14),
            _buildQuickActionsSection(),
            const SizedBox(height: 14),
            _buildLatestUpdates(),
            const SizedBox(height: 14),
            _buildPrayerSection(),
            const SizedBox(height: 14),
            _buildHadithSection(),
            const SizedBox(height: 24),
            Center(
              child: ShaderMask(
                shaderCallback: (bounds) => LinearGradient(
                  colors: _rainbowColors,
                ).createShader(bounds),
                child: const Text(
                  '⚡ CYBER - RAINBOW ⚡',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 13,
                    letterSpacing: 4,
                    fontFamily: 'Orbitron',
                  ),
                ),
              ),
            ),
            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }

  // ─── RAINBOW BACKGROUND ──────────────────────────────────────────────────
  Widget _buildRainbowBackground() {
    return AnimatedBuilder(
      animation: _rotateCtrl,
      builder: (_, __) {
        return Container(
          decoration: BoxDecoration(
            gradient: RadialGradient(
              center: Alignment(
                math.sin(_rotateCtrl.value * 0.5) * 0.3,
                math.cos(_rotateCtrl.value * 0.7) * 0.3,
              ),
              radius: 1.5,
              colors: [
                _rainbowColors[_rotateCtrl.value.toInt() % _rainbowColors.length]
                    .withOpacity(0.06),
                _rainbowColors[(_rotateCtrl.value.toInt() + 3) % _rainbowColors.length]
                    .withOpacity(0.04),
                kBg,
              ],
              stops: const [0.0, 0.5, 1.0],
            ),
          ),
        );
      },
    );
  }

  // ─── GLOW ORBS ────────────────────────────────────────────────────────────
  Widget _buildGlowOrbs() {
    return Stack(
      children: List.generate(6, (i) {
        final angle = (i / 6) * 2 * math.pi;
        return AnimatedBuilder(
          animation: _rotateCtrl,
          builder: (_, __) {
            final x = math.cos(_rotateCtrl.value * 0.4 + angle) * 160;
            final y = math.sin(_rotateCtrl.value * 0.6 + angle) * 100;
            final color = _rainbowColors[(i * 2) % _rainbowColors.length];
            final size = 60 + 20 * math.sin(_rotateCtrl.value + i).abs();
            return Positioned(
              left: MediaQuery.of(context).size.width / 2 + x - size / 2,
              top: MediaQuery.of(context).size.height / 2 + y - size / 2,
              child: Container(
                width: size,
                height: size,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: RadialGradient(
                    colors: [color.withOpacity(0.05), Colors.transparent],
                    radius: 0.7,
                  ),
                ),
              ),
            );
          },
        );
      }),
    );
  }

  // ─── DIGITAL CLOCK ──────────────────────────────────────────────────────────
  Widget _buildDigitalClock() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 14),
      padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
      decoration: BoxDecoration(
        color: kCard.withOpacity(0.6),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: _rainbowColors[DateTime.now().second % _rainbowColors.length]
              .withOpacity(0.3),
          width: 1,
        ),
        boxShadow: [
          BoxShadow(
            color: kPurple.withOpacity(0.1),
            blurRadius: 30,
          ),
        ],
      ),
      child: Column(
        children: [
          // ─── GARIS LURUS GLOW RAINBOW ──────────────────────────────────
          AnimatedBuilder(
            animation: _glowCtrl,
            builder: (_, __) {
              return Container(
                height: 2,
                width: double.infinity,
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      Colors.transparent,
                      ..._rainbowColors,
                      Colors.transparent,
                    ],
                    stops: const [0.0, 0.05, 0.15, 0.25, 0.35, 0.45, 0.55, 0.65, 0.75, 0.85, 0.95, 1.0],
                  ),
                  borderRadius: BorderRadius.circular(2),
                  boxShadow: [
                    BoxShadow(
                      color: kPurple.withOpacity(0.5 * _glowCtrl.value),
                      blurRadius: 14 + 10 * _glowCtrl.value,
                      spreadRadius: 2,
                    ),
                  ],
                ),
              );
            },
          ),
          const SizedBox(height: 10),
          // ─── JAM ──────────────────────────────────────────────────────────
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              _clockItem('WIB', _timeWIB, kPurpleL),
              _clockItem('WITA', _timeWITA, kPink),
              _clockItem('WIT', _timeWIT, kCyan),
            ],
          ),
          const SizedBox(height: 6),
          // ─── LIVE INDICATOR ──────────────────────────────────────────────
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              AnimatedContainer(
                duration: const Duration(milliseconds: 500),
                width: 6,
                height: 6,
                decoration: BoxDecoration(
                  color: _showColon ? kGreen : kGreen.withOpacity(0.15),
                  shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(
                      color: kGreen.withOpacity(_showColon ? 0.8 : 0.05),
                      blurRadius: 12,
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 6),
              Text(
                'LIVE',
                style: TextStyle(
                  color: kGreen.withOpacity(_showColon ? 0.9 : 0.2),
                  fontSize: 9,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 1.8,
                  fontFamily: 'Orbitron',
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _clockItem(String label, String time, Color color) {
    return Column(
      children: [
        Text(
          label,
          style: TextStyle(
            color: kWhite54.withOpacity(0.5),
            fontSize: 9,
            fontWeight: FontWeight.w600,
            letterSpacing: 1.5,
            fontFamily: 'Orbitron',
          ),
        ),
        const SizedBox(height: 2),
        Stack(
          children: [
            Text(
              time,
              style: TextStyle(
                color: color.withOpacity(0.08),
                fontSize: 18,
                fontWeight: FontWeight.w700,
                fontFamily: 'Orbitron',
                letterSpacing: 1.5,
                shadows: [
                  Shadow(color: color.withOpacity(0.3), blurRadius: 30),
                ],
              ),
            ),
            Text(
              time,
              style: TextStyle(
                color: color.withOpacity(0.2),
                fontSize: 18,
                fontWeight: FontWeight.w700,
                fontFamily: 'Orbitron',
                letterSpacing: 1.5,
                shadows: [
                  Shadow(color: color.withOpacity(0.6), blurRadius: 50),
                ],
              ),
            ),
            Text(
              time,
              style: const TextStyle(
                color: Color(0xFFF3E8FF),
                fontSize: 18,
                fontWeight: FontWeight.w700,
                fontFamily: 'Orbitron',
                letterSpacing: 1.5,
                shadows: [
                  Shadow(color: Color(0xFFA78BFA), blurRadius: 15),
                ],
              ),
            ),
          ],
        ),
      ],
    );
  }

  // ─── BANNER VIDEO ──────────────────────────────────────────────────────────
  Widget _buildBannerVideo() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 14),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(20),
        child: Container(
          height: 190, width: double.infinity,
          color: const Color(0xFF080C12),
          child: Stack(
            fit: StackFit.expand,
            children: [
              if (_menuVideoCtrl != null && _menuVideoCtrl!.value.isInitialized)
                FittedBox(
                  fit: BoxFit.cover,
                  child: SizedBox(
                    width: _menuVideoCtrl!.value.size.width,
                    height: _menuVideoCtrl!.value.size.height,
                    child: VideoPlayer(_menuVideoCtrl!),
                  ),
                )
              else
                Container(
                  decoration: const BoxDecoration(
                    gradient: LinearGradient(
                      colors: [Color(0xFF0A0F1E), Color(0xFF1A1A2E)],
                      begin: Alignment.topLeft, end: Alignment.bottomRight,
                    ),
                  ),
                ),
              Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      Colors.black.withOpacity(0.7),
                      Colors.transparent,
                      Colors.black.withOpacity(0.4),
                    ],
                    begin: Alignment.centerLeft, end: Alignment.centerRight,
                  ),
                ),
              ),
              const Positioned(
                left: 16, bottom: 14,
                child: Text('⚡ CYBER - RAINBOW ⚡',
                  style: TextStyle(
                    color: Colors.white, fontSize: 22, fontWeight: FontWeight.bold,
                    fontFamily: 'Orbitron', letterSpacing: 2,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ─── WELCOME CARD ──────────────────────────────────────────────────────────
  Widget _buildWelcomeCard() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 14),
      child: AnimatedBuilder(
        animation: _bounceAnim,
        builder: (_, __) => Transform.scale(
          scale: _bounceAnim.value,
          child: Container(
            padding: const EdgeInsets.all(18),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [kCard, kCardAlt],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(
                color: _rainbowColors[DateTime.now().second % _rainbowColors.length]
                    .withOpacity(0.4),
                width: 1.5,
              ),
              boxShadow: [
                BoxShadow(
                  color: kPurple.withOpacity(0.15),
                  blurRadius: 30,
                  offset: const Offset(0, 10),
                ),
              ],
            ),
            child: Stack(
              children: [
                Positioned.fill(
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(18),
                    child: CustomPaint(painter: _HexagonPatternPainter()),
                  ),
                ),
                Column(
                  children: [
                    Row(
                      children: [
                        ScaleTransition(
                          scale: _pulseAnim,
                          child: Container(
                            width: 58, height: 58,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              gradient: LinearGradient(
                                colors: [kPurple, kPink],
                                begin: Alignment.topLeft,
                                end: Alignment.bottomRight,
                              ),
                              boxShadow: [
                                BoxShadow(
                                  color: kPurple.withOpacity(0.5),
                                  blurRadius: 20,
                                  spreadRadius: 4,
                                ),
                              ],
                            ),
                            child: const Center(
                              child: Icon(Icons.security_rounded, color: kWhite, size: 28),
                            ),
                          ),
                        ),
                        const SizedBox(width: 14),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text(
                                'Welcome',
                                style: TextStyle(
                                  color: kWhite54,
                                  fontSize: 12,
                                  fontFamily: 'Orbitron',
                                ),
                              ),
                              // ─── TYPING TEXT EFFECT ────────────────────
                              _TypingText(
                                text: username,
                                style: const TextStyle(
                                  color: kWhite,
                                  fontSize: 20,
                                  fontWeight: FontWeight.bold,
                                  fontFamily: 'Orbitron',
                                ),
                              ),
                              const SizedBox(height: 4),
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
                                decoration: BoxDecoration(
                                  borderRadius: BorderRadius.circular(20),
                                  border: Border.all(color: kPurple.withOpacity(0.6)),
                                  color: kPurple.withOpacity(0.12),
                                ),
                                child: Text(
                                  role.toUpperCase(),
                                  style: const TextStyle(
                                    color: kPurpleL,
                                    fontSize: 10,
                                    fontWeight: FontWeight.bold,
                                    letterSpacing: 1.5,
                                    fontFamily: 'Orbitron',
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                        Container(
                          width: 40, height: 40,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: kPurple.withOpacity(0.12),
                            border: Border.all(color: kPurple.withOpacity(0.4)),
                          ),
                          child: const Icon(Icons.timer_outlined, color: kPurple, size: 20),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.symmetric(vertical: 10),
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(30),
                        border: Border.all(
                          color: _rainbowColors[DateTime.now().second % _rainbowColors.length]
                              .withOpacity(0.3),
                        ),
                        color: kPurple.withOpacity(0.04),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          _AnimatedDot(color: kPurple),
                          const SizedBox(width: 10),
                          ShaderMask(
                            shaderCallback: (bounds) => LinearGradient(
                              colors: _rainbowColors,
                            ).createShader(bounds),
                            child: const Text(
                              '⚡ CYBER - RAINBOW DASHBOARD ⚡',
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 11,
                                fontWeight: FontWeight.bold,
                                fontFamily: 'Orbitron',
                                letterSpacing: 1.5,
                              ),
                            ),
                          ),
                          const SizedBox(width: 10),
                          _AnimatedDot(color: kPurple),
                        ],
                      ),
                    ),
                    const SizedBox(height: 16),
                    Row(
                      children: [
                        _buildCircleStatItem(
                            icon: Icons.people_alt_rounded,
                            value: '$onlineUsers',
                            label: 'Online Users',
                            color: kCyan),
                        _buildStatDivider(),
                        _buildCircleStatItem(
                            icon: Icons.link_rounded,
                            value: '$activeConns',
                            label: 'Active Connections',
                            color: kBlue),
                        _buildStatDivider(),
                        _buildCircleStatItem(
                            icon: Icons.calendar_month_rounded,
                            value: expiredDate.length > 10 ? expiredDate.substring(0, 10) : expiredDate,
                            label: 'Expiration',
                            color: kOrange),
                      ],
                    ),
                    const SizedBox(height: 12),
                    Align(
                      alignment: Alignment.centerLeft,
                      child: ScaleTransition(
                        scale: _pulseAnim,
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(20),
                            border: Border.all(color: kPurple.withOpacity(0.6)),
                            color: kPurple.withOpacity(0.08),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              _AnimatedDot(color: kPurple),
                              const SizedBox(width: 6),
                              const Text(
                                'LIVE',
                                style: TextStyle(
                                  color: kPurple,
                                  fontSize: 10,
                                  fontWeight: FontWeight.bold,
                                  letterSpacing: 1,
                                  fontFamily: 'Orbitron',
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildCircleStatItem({
    required IconData icon,
    required String value,
    required String label,
    required Color color,
  }) {
    return Expanded(
      child: Column(
        children: [
          Container(
            width: 62, height: 62,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: color.withOpacity(0.18),
              border: Border.all(color: color.withOpacity(0.6), width: 2),
              boxShadow: [BoxShadow(color: color.withOpacity(0.4), blurRadius: 18, spreadRadius: 3)],
            ),
            child: Center(child: Icon(icon, color: color, size: 28)),
          ),
          const SizedBox(height: 8),
          Text(value,
              style: const TextStyle(
                  color: kWhite, fontWeight: FontWeight.bold, fontSize: 13, fontFamily: 'Orbitron')),
          const SizedBox(height: 2),
          Text(label, style: const TextStyle(color: kWhite54, fontSize: 9), textAlign: TextAlign.center),
        ],
      ),
    );
  }

  Widget _buildStatDivider() =>
      Container(width: 1, height: 60, color: kBorder.withOpacity(0.6));

  // ─── QUICK ACTIONS ─────────────────────────────────────────────────────────
  Widget _buildQuickActionsSection() {
    final actions = [
      _QuickActionData(
        icon: FontAwesomeIcons.whatsapp,
        bgIcon: FontAwesomeIcons.whatsapp,
        title: 'Manage Sender',
        subtitle: 'Manage your active sender',
        gradient: [kPurple, kPurpleL],
        onTap: () => Navigator.push(
          context,
          _slideRoute(BugSenderPage(sessionKey: sessionKey, username: username, role: role)),
        ).then((_) {
          if (mounted && _newsPageCtrl.hasClients) {
            setState(() { _currentNewsPage = 0.0; _newsPageViewKey++; });
            _newsPageCtrl.jumpToPage(0);
          }
        }),
      ),
      _QuickActionData(
        icon: FontAwesomeIcons.telegram,
        bgIcon: FontAwesomeIcons.telegram,
        title: 'Join Channel',
        subtitle: 'wahyu Info Channel',
        gradient: [kPurpleL, kPurple],
        onTap: () => _openUrl('https://t.me/wahyustoru'),
      ),
      _QuickActionData(
        icon: FontAwesomeIcons.music,
        bgIcon: FontAwesomeIcons.music,
        title: 'Music Player',
        subtitle: 'Search & Play Music',
        gradient: [kPink, kPurple],
        onTap: () => Navigator.push(
          context,
          _slideRoute(MusikPage(username: username)),
        ),
      ),
      _QuickActionData(
        icon: FontAwesomeIcons.bookQuran,
        bgIcon: FontAwesomeIcons.bookQuran,
        title: 'Al Quran',
        subtitle: 'Baca Al-Quran',
        gradient: [kGreen, kTeal],
        onTap: () => Navigator.push(context, _slideRoute(AlQuranPage())),
      ),
      _QuickActionData(
        icon: FontAwesomeIcons.tv,
        bgIcon: FontAwesomeIcons.tv,
        title: 'Anime',
        subtitle: 'Discover & Watch Anime',
        gradient: [kCyan, kBlue],
        onTap: () => Navigator.push(context, _slideRoute(HomeAnimePage())),
      ),
      _QuickActionData(
        icon: FontAwesomeIcons.comments,
        bgIcon: FontAwesomeIcons.comments,
        title: 'Global Chat',
        subtitle: 'Chat dengan semua user',
        gradient: [kPurple, kPink],
        onTap: () => Navigator.push(
          context,
          _slideRoute(GlobalChatPage(
            sessionKey: sessionKey,
            username: username,
            role: role,
          )),
        ),
      ),
    ];

    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 14),
          child: Row(
            children: [
              Container(
                width: 44, height: 44,
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(12),
                  color: kYellow.withOpacity(0.18),
                  border: Border.all(color: kYellow.withOpacity(0.4)),
                ),
                child: const Icon(Icons.bolt_rounded, color: kYellow, size: 22),
              ),
              const SizedBox(width: 12),
              const Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('QUICK ACTIONS',
                      style: TextStyle(
                        color: kWhite, fontWeight: FontWeight.bold, fontSize: 15,
                        fontFamily: 'Orbitron', letterSpacing: 1)),
                  Text('Beberapa Menu Tambahan',
                      style: TextStyle(color: kWhite54, fontSize: 12)),
                ],
              ),
              const Spacer(),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(20),
                  color: kYellow.withOpacity(0.15),
                  border: Border.all(color: kYellow.withOpacity(0.5)),
                ),
                child: Row(children: [
                  Container(
                      width: 7, height: 7,
                      decoration: const BoxDecoration(shape: BoxShape.circle, color: kYellow)),
                  const SizedBox(width: 5),
                  const Text('RAINBOW',
                      style: TextStyle(color: kYellow, fontSize: 11, fontWeight: FontWeight.bold)),
                ]),
              ),
            ],
          ),
        ),
        const SizedBox(height: 14),
        SizedBox(
          height: 180,
          child: PageView.builder(
            controller: _qaPageCtrl,
            itemCount: actions.length,
            onPageChanged: (index) {
              if (mounted) setState(() => _currentQaPage = index.toDouble());
            },
            itemBuilder: (context, index) {
              return Padding(
                padding: const EdgeInsets.symmetric(horizontal: 8),
                child: _buildQuickActionCard(actions[index]),
              );
            },
          ),
        ),
        const SizedBox(height: 12),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: List.generate(actions.length, (index) {
            final bool isActive = _currentQaPage.round() == index;
            return AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              margin: const EdgeInsets.symmetric(horizontal: 4),
              width: isActive ? 24 : 8,
              height: 8,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(4),
                color: isActive ? kYellow : Colors.white24,
              ),
            );
          }),
        ),
      ],
    );
  }

  Widget _buildQuickActionCard(_QuickActionData action) {
    return GestureDetector(
      onTap: action.onTap,
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(22),
          gradient: LinearGradient(
              colors: action.gradient,
              begin: Alignment.topLeft,
              end: Alignment.bottomRight),
          boxShadow: [
            BoxShadow(
                color: action.gradient.first.withOpacity(0.4),
                blurRadius: 25, offset: const Offset(0, 10))
          ],
        ),
        child: Stack(
          children: [
            Positioned(
              right: -12, bottom: -12,
              child: Icon(action.bgIcon, color: Colors.white.withOpacity(0.08), size: 110),
            ),
            Padding(
              padding: const EdgeInsets.all(22),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    width: 50, height: 50,
                    decoration: BoxDecoration(
                        shape: BoxShape.circle, color: Colors.white.withOpacity(0.22)),
                    child: Icon(action.icon, color: kWhite, size: 24),
                  ),
                  const Spacer(),
                  Align(
                    alignment: Alignment.topRight,
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                      decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(20),
                          color: Colors.white.withOpacity(0.22)),
                      child: const Text('Tap →',
                          style: TextStyle(color: kWhite, fontSize: 11, fontWeight: FontWeight.bold)),
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(action.title,
                      style: const TextStyle(
                        color: kWhite, fontWeight: FontWeight.bold, fontSize: 17, fontFamily: 'Orbitron')),
                  const SizedBox(height: 4),
                  Text(action.subtitle,
                      style: TextStyle(color: kWhite.withOpacity(0.8), fontSize: 12)),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ─── LATEST UPDATES ────────────────────────────────────────────────────────
  Widget _buildLatestUpdates() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 14),
          child: Row(
            children: [
              const Icon(Icons.dashboard_customize_rounded, color: kOrange, size: 22),
              const SizedBox(width: 8),
              const Text('LATEST UPDATES',
                  style: TextStyle(
                    color: kWhite, fontWeight: FontWeight.bold, fontSize: 15,
                    fontFamily: 'Orbitron', letterSpacing: 1)),
              const Spacer(),
              if (newsList.isNotEmpty)
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(20),
                    color: kOrange.withOpacity(0.15),
                    border: Border.all(color: kOrange.withOpacity(0.5)),
                  ),
                  child: Text('${newsList.length} Updates',
                      style: const TextStyle(
                          color: kOrange, fontSize: 11, fontWeight: FontWeight.bold)),
                ),
            ],
          ),
        ),
        const SizedBox(height: 12),
        if (newsList.isNotEmpty)
          SizedBox(
            height: 200,
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              physics: const BouncingScrollPhysics(),
              padding: const EdgeInsets.symmetric(horizontal: 14),
              itemCount: newsList.length,
              itemBuilder: (ctx, i) => _buildNewsCardHorizontal(newsList[i]),
            ),
          ),
        if (newsList.isEmpty)
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 14),
            child: Container(
              height: 120,
              decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(16),
                  color: kCard,
                  border: Border.all(color: kBorder.withOpacity(0.6))),
              child: const Center(
                  child: Text('No updates available', style: TextStyle(color: kWhite54))),
            ),
          ),
      ],
    );
  }

  Widget _buildNewsCardHorizontal(dynamic item) {
    final imgUrl   = item['image']?.toString() ?? '';
    final title    = item['title']?.toString() ?? 'No Title';
    final date     = item['date']?.toString() ?? item['created_at']?.toString() ?? '';
    final cardWidth = (MediaQuery.of(context).size.width / 2) - 22;

    return Container(
      width: cardWidth,
      margin: const EdgeInsets.only(right: 12),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(18),
        color: kCard,
        border: Border.all(color: kBorder.withOpacity(0.6)),
        boxShadow: [
          BoxShadow(color: kPurple.withOpacity(0.08), blurRadius: 20, offset: const Offset(0, 8))
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          ClipRRect(
            borderRadius: const BorderRadius.vertical(top: Radius.circular(18)),
            child: Stack(
              children: [
                Container(
                  height: 110, width: double.infinity, color: kCardAlt,
                  child: imgUrl.isNotEmpty
                      ? Image.network(imgUrl, fit: BoxFit.cover,
                          errorBuilder: (_, __, ___) => const Center(
                              child: Icon(Icons.image_not_supported, color: kWhite54, size: 30)))
                      : const Center(
                          child: Icon(Icons.article_rounded, color: kWhite54, size: 30)),
                ),
                Positioned(
                  top: 8, right: 8,
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(10),
                      color: Colors.black.withOpacity(0.65),
                      border: Border.all(color: kOrange.withOpacity(0.8)),
                    ),
                    child: const Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.circle_notifications_rounded, color: kOrange, size: 10),
                        SizedBox(width: 3),
                        Text('NEW',
                            style: TextStyle(
                                color: kOrange, fontSize: 9, fontWeight: FontWeight.bold)),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(10, 10, 10, 6),
            child: Text(title,
                style: const TextStyle(
                  color: kWhite, fontSize: 16, fontWeight: FontWeight.bold,
                  fontFamily: 'Orbitron', height: 1.3),
                maxLines: 2, overflow: TextOverflow.ellipsis),
          ),
          const Spacer(),
          Padding(
            padding: const EdgeInsets.fromLTRB(10, 0, 10, 10),
            child: Row(
              children: [
                const Icon(Icons.access_time_rounded, color: kWhite54, size: 11),
                const SizedBox(width: 4),
                if (date.isNotEmpty)
                  Expanded(
                    child: Text(
                        date.length > 10 ? date.substring(0, 10) : date,
                        style: const TextStyle(color: kWhite54, fontSize: 10)),
                  ),
                Container(
                  padding: const EdgeInsets.all(4),
                  decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(8),
                      color: kOrange.withOpacity(0.2)),
                  child: const Icon(Icons.arrow_forward_ios_rounded, color: kOrange, size: 9),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ─── PRAYER SECTION ────────────────────────────────────────────────────────
  Widget _buildPrayerSection() {
    final prayerColors = [
      kPurple, kOrange, kRed, kGreen, kBlue,
    ];
    final prayerIcons = [
      Icons.nights_stay_rounded,
      Icons.wb_sunny_rounded,
      Icons.cloud_rounded,
      Icons.wb_twilight_rounded,
      Icons.nightlight_round,
    ];
    final prayerKeys = ['Subuh', 'Dzuhur', 'Ashar', 'Maghrib', 'Isya'];

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 14),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: kCard,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: kBorder.withOpacity(0.6)),
          boxShadow: [
            BoxShadow(color: kPurple.withOpacity(0.08), blurRadius: 30, offset: const Offset(0, 10))
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  width: 48, height: 48,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(12),
                    color: kPurple.withOpacity(0.2),
                    border: Border.all(color: kPurple.withOpacity(0.5)),
                  ),
                  child: const Center(child: Icon(Icons.mosque, color: kPurple, size: 26)),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text('JADWAL SHOLAT',
                          style: TextStyle(
                            color: kWhite, fontWeight: FontWeight.bold, fontSize: 15,
                            fontFamily: 'Orbitron', letterSpacing: 1)),
                      Text(_prayerCity,
                          style: const TextStyle(color: kWhite54, fontSize: 12)),
                    ],
                  ),
                ),
                GestureDetector(
                  onTap: _locationLoading ? null : _detectLocationAndFetchPrayer,
                  child: Container(
                    width: 38, height: 38,
                    margin: const EdgeInsets.only(right: 8),
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: _locationGranted
                          ? kPurple.withOpacity(0.2)
                          : kWhite24.withOpacity(0.1),
                      border: Border.all(
                        color: _locationGranted
                            ? kPurple.withOpacity(0.6)
                            : kWhite54.withOpacity(0.3),
                      ),
                    ),
                    child: _locationLoading
                        ? const Padding(
                            padding: EdgeInsets.all(10),
                            child: CircularProgressIndicator(color: kPurple, strokeWidth: 2),
                          )
                        : Icon(
                            _locationGranted
                                ? Icons.my_location_rounded
                                : Icons.location_searching_rounded,
                            color: _locationGranted ? kPurple : kWhite54,
                            size: 18,
                          ),
                  ),
                ),
                GestureDetector(
                  onTap: _showChangeCityDialog,
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(20),
                      color: kPurple,
                    ),
                    child: const Row(children: [
                      Icon(Icons.edit_location_alt_rounded, color: Colors.white, size: 14),
                      SizedBox(width: 5),
                      Text('GANTI',
                          style: TextStyle(
                              color: Colors.white, fontSize: 12, fontWeight: FontWeight.bold)),
                    ]),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 14),

            if (_nextPrayerLabel.isNotEmpty)
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(30),
                  border: Border.all(color: kPurple.withOpacity(0.6)),
                ),
                child: Row(
                  children: [
                    ScaleTransition(
                      scale: _pulseAnim,
                      child: _AnimatedDot(color: kOrange, size: 10),
                    ),
                    const SizedBox(width: 10),
                    Text('Menuju $_nextPrayerLabel : $_nextPrayerTime',
                        style: const TextStyle(
                          color: kWhite, fontSize: 13, fontWeight: FontWeight.w600,
                          fontFamily: 'Orbitron')),
                    const Spacer(),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(color: kPurple.withOpacity(0.6)),
                      ),
                      child: const Text('RAINBOW',
                          style: TextStyle(color: kPurple, fontSize: 10, fontWeight: FontWeight.bold)),
                    ),
                  ],
                ),
              ),
            const SizedBox(height: 14),

            if (_prayerLoading)
              const Center(child: CircularProgressIndicator(color: kPurple, strokeWidth: 2))
            else
              SizedBox(
                height: 118,
                child: ListView.builder(
                  scrollDirection: Axis.horizontal,
                  physics: const BouncingScrollPhysics(),
                  itemCount: prayerKeys.length,
                  itemBuilder: (ctx, i) {
                    final key   = prayerKeys[i];
                    final time  = _prayerTimes[key] ?? '--:--';
                    final color = prayerColors[i];
                    final icon  = prayerIcons[i];
                    final isNext = key == _nextPrayerLabel;
                    return AnimatedContainer(
                      duration: const Duration(milliseconds: 400),
                      curve: Curves.easeOut,
                      margin: EdgeInsets.only(right: 10, bottom: isNext ? 0 : 6, top: isNext ? 0 : 6),
                      width: 105,
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(18),
                        color: color,
                        boxShadow: [
                          BoxShadow(
                              color: color.withOpacity(isNext ? 0.8 : 0.3),
                              blurRadius: isNext ? 25 : 8, offset: const Offset(0, 6))
                        ],
                        border: isNext
                            ? Border.all(color: kPurple, width: 2.5)
                            : null,
                      ),
                      child: Padding(
                        padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 8),
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(icon, color: Colors.white, size: 24),
                            const SizedBox(height: 5),
                            Text(key.toUpperCase(),
                                style: const TextStyle(
                                    color: Colors.white, fontSize: 9,
                                    fontWeight: FontWeight.bold, letterSpacing: 0.8)),
                            const SizedBox(height: 5),
                            Text(time,
                                style: const TextStyle(
                                    color: Colors.white, fontSize: 19,
                                    fontWeight: FontWeight.bold, fontFamily: 'Orbitron')),
                          ],
                        ),
                      ),
                    );
                  },
                ),
              ),
          ],
        ),
      ),
    );
  }

  // ─── HADITH SECTION ────────────────────────────────────────────────────────
  Widget _buildHadithSection() {
    if (_hadithLoading) {
      return Padding(
        padding: const EdgeInsets.symmetric(horizontal: 14),
        child: Container(
          height: 200,
          decoration: BoxDecoration(
            color: kCard, borderRadius: BorderRadius.circular(20),
            border: Border.all(color: kBorder.withOpacity(0.6)),
          ),
          child: const Center(child: CircularProgressIndicator(color: kPurple, strokeWidth: 2)),
        ),
      );
    }

    final arabic = _hadith?['data']?['text']?['ar'] ??
        'إِنَّمَا الأَعْمَالُ بِالنِّيَّاتِ، وَإِنَّمَا لِكُلِّ امْرِئٍ مَا نَوَى';
    final indo   = _hadith?['data']?['text']?['id'] ??
        'Sesungguhnya setiap amalan tergantung pada niatnya.';
    final number = _hadith?['data']?['id']?.toString() ?? '1';
    final source = _hadith?['data']?['source']?.toString() ?? 'Muslim';
    final grade  = _hadith?['data']?['grade']?.toString() ?? 'Sahih Muslim';

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 14),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: kCard, borderRadius: BorderRadius.circular(20),
          border: Border.all(color: kBorder.withOpacity(0.6)),
          boxShadow: [
            BoxShadow(color: kPurple.withOpacity(0.08), blurRadius: 30, offset: const Offset(0, 10))
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  width: 50, height: 50,
                  decoration: BoxDecoration(
                      shape: BoxShape.circle, color: kPurple.withOpacity(0.2)),
                  child: const Center(child: Icon(Icons.menu_book_rounded, color: kPurple, size: 26)),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                    const Text('HADITH OF THE DAY',
                        style: TextStyle(
                          color: kWhite, fontWeight: FontWeight.bold, fontSize: 15,
                          fontFamily: 'Orbitron', letterSpacing: 0.5)),
                    const SizedBox(height: 2),
                    Text('$grade · Tap card to read full',
                        style: const TextStyle(color: kWhite54, fontSize: 11)),
                  ]),
                ),
              ],
            ),
            const SizedBox(height: 14),
            GestureDetector(
              onTap: () => _showHadithFullDialog(arabic, indo, source, number, grade),
              child: Column(
                children: [
                  Container(
                    width: double.infinity, padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(14),
                      color: const Color(0xFF1C0000),
                      border: Border.all(color: kBorder.withOpacity(0.5)),
                    ),
                    child: Text(arabic,
                        textAlign: TextAlign.right, textDirection: TextDirection.rtl,
                        style: const TextStyle(color: kWhite, fontSize: 17, height: 2.0)),
                  ),
                  const SizedBox(height: 10),
                  Container(
                    width: double.infinity, padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(14), color: const Color(0xFF150000)),
                    child: Text(indo,
                        style: const TextStyle(
                          color: kWhite54, fontSize: 12, fontStyle: FontStyle.italic, height: 1.7),
                        maxLines: 3, overflow: TextOverflow.ellipsis),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 14),
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: kPurple.withOpacity(0.6)),
                    color: kPurple.withOpacity(0.1),
                  ),
                  child: Row(mainAxisSize: MainAxisSize.min, children: [
                    const Icon(Icons.receipt_long_rounded, color: kPurple, size: 13),
                    const SizedBox(width: 5),
                    Text('${source.isNotEmpty ? source : "Muslim"} #$number',
                        style: const TextStyle(
                            color: kPurple, fontSize: 11, fontWeight: FontWeight.bold)),
                  ]),
                ),
                const Spacer(),
                GestureDetector(
                  onTap: _fetchRandomHadith,
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: kWhite54.withOpacity(0.3)),
                    ),
                    child: const Row(mainAxisSize: MainAxisSize.min, children: [
                      Icon(Icons.touch_app_rounded, color: kWhite54, size: 14),
                      SizedBox(width: 4),
                      Text('Tap card', style: TextStyle(color: kWhite54, fontSize: 11)),
                    ]),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  // ─── BUILD ─────────────────────────────────────────────────────────────────
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: kBg,
      extendBodyBehindAppBar: false,
      appBar: _buildAppBar(),
      drawer: _buildDrawer(),
      body: Stack(
        children: [
          _buildRainbowBackground(),
          _buildGlowOrbs(),
          _buildBackgroundGrid(),
          Container(
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                colors: [Color(0xFF0A0015), Color(0xFF0A0D14)],
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
              ),
            ),
          ),
          AnimatedSwitcher(
            duration: const Duration(milliseconds: 350),
            transitionBuilder: (child, anim) =>
                FadeTransition(opacity: anim, child: child),
            child: KeyedSubtree(
              key: ValueKey(_navIndex),
              child: _buildCurrentPage(),
            ),
          ),
        ],
      ),
      bottomNavigationBar: _buildBottomNav(),
    );
  }

  Widget _buildBackgroundGrid() {
    return CustomPaint(
      size: Size.infinite,
      painter: _GridPatternPainter(
        gridColor: kPurple.withOpacity(0.04),
        lineColor: kPink.withOpacity(0.02),
        spacing: 35,
      ),
    );
  }

  // ─── APPBAR ────────────────────────────────────────────────────────────────
  PreferredSizeWidget _buildAppBar() {
    return AppBar(
      backgroundColor: kBg.withOpacity(0.95),
      elevation: 0,
      iconTheme: const IconThemeData(color: kWhite),
      titleSpacing: 0,
      flexibleSpace: Container(
        decoration: BoxDecoration(
          border: Border(
            bottom: BorderSide(
              color: _rainbowColors[DateTime.now().second % _rainbowColors.length]
                  .withOpacity(0.3),
              width: 1,
            ),
          ),
        ),
      ),
      title: Row(
        children: [
          const SizedBox(width: 8),
          Container(
            width: 36, height: 36,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              border: Border.all(
                color: _rainbowColors[DateTime.now().second % _rainbowColors.length]
                    .withOpacity(0.5),
                width: 2,
              ),
              color: kPurple.withOpacity(0.1),
            ),
            child: ClipOval(
              child: Image.asset(
                'assets/images/logo.png',
                width: 36,
                height: 36,
                fit: BoxFit.cover,
              ),
            ),
          ),
        ],
      ),
      actions: [
        GestureDetector(
          onTap: () => Navigator.push(
            context,
            _slideRoute(MusikPage(username: username)),
          ),
          child: Container(
            margin: const EdgeInsets.only(right: 4),
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [kPurple, kPink],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(10),
              boxShadow: [
                BoxShadow(
                  color: kPurple.withOpacity(0.5),
                  blurRadius: 15,
                ),
              ],
            ),
            child: const Icon(Icons.music_note_rounded, color: Colors.white, size: 20),
          ),
        ),
        const SizedBox(width: 4),
        GestureDetector(
          onTap: () => Navigator.push(
            context,
            _slideRoute(ProfilePage(
              username: username, password: password,
              role: role, expiredDate: expiredDate, sessionKey: sessionKey,
            )),
          ).then((_) {
            if (mounted && _newsPageCtrl.hasClients) {
              setState(() { _currentNewsPage = 0.0; _newsPageViewKey++; });
              _newsPageCtrl.jumpToPage(0);
            }
          }),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(username,
                  style: const TextStyle(
                      color: kWhite, fontSize: 13, fontWeight: FontWeight.bold)),
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(role.toUpperCase(),
                      style: const TextStyle(
                          color: kWhite54, fontSize: 10, fontFamily: 'Orbitron')),
                  const SizedBox(width: 4),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1),
                    decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(6),
                        color: kRed.withOpacity(0.2),
                        border: Border.all(color: kRed.withOpacity(0.5))),
                    child: Text('Exp: $expiredDate',
                        style: const TextStyle(
                            color: kRed, fontSize: 9, fontWeight: FontWeight.bold)),
                  ),
                ],
              ),
            ],
          ),
        ),
        const SizedBox(width: 10),
        GestureDetector(
          onTap: () => Navigator.push(
            context,
            _slideRoute(ProfilePage(
              username: username, password: password,
              role: role, expiredDate: expiredDate, sessionKey: sessionKey,
            )),
          ),
          child: Container(
            width: 38, height: 38,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              border: Border.all(
                color: _rainbowColors[DateTime.now().second % _rainbowColors.length]
                    .withOpacity(0.5),
                width: 2,
              ),
              color: kPurple.withOpacity(0.15),
            ),
            child: ClipOval(
              child: _profileImage != null
                  ? Image.file(_profileImage!, fit: BoxFit.cover)
                  : const Icon(FontAwesomeIcons.userAstronaut, color: kPurple, size: 20),
            ),
          ),
        ),
        const SizedBox(width: 4),
        GestureDetector(
          onTap: () => Navigator.push(context, _slideRoute(const ContactPage())),
          child: const Padding(
            padding: EdgeInsets.symmetric(horizontal: 8),
            child: Icon(Icons.headset_mic_outlined, color: kWhite, size: 24),
          ),
        ),
        const SizedBox(width: 4),
      ],
    );
  }

  // ─── BOTTOM NAV (PREMIUM ANIMASI) ──────────────────────────────────────────
  Widget _buildBottomNav() {
    final items = [
      _NavItem(icon: Icons.home_rounded, label: 'Home'),
      _NavItem(icon: FontAwesomeIcons.whatsapp, label: 'Bug'),
      _NavItem(icon: Icons.info_outline_rounded, label: 'Info'),
      _NavItem(icon: Icons.build_circle_outlined, label: 'Tools'),
    ];

    return Container(
      margin: const EdgeInsets.fromLTRB(12, 0, 12, 12),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            const Color(0xFF1A0A2E).withOpacity(0.95),
            const Color(0xFF2D1B4E).withOpacity(0.9),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(40),
        border: Border.all(
          color: _rainbowColors[DateTime.now().second % _rainbowColors.length]
              .withOpacity(0.2),
          width: 1,
        ),
        boxShadow: [
          BoxShadow(
            color: kPurple.withOpacity(0.25),
            blurRadius: 30,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: SizedBox(
        height: 72,
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceAround,
          children: List.generate(items.length, (i) {
            final isActive = _navIndex == i;
            final color = _rainbowColors[(i * 2) % _rainbowColors.length];
            
            return GestureDetector(
              onTap: () => _onNavTap(i),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 400),
                curve: Curves.elasticOut,
                padding: EdgeInsets.symmetric(
                  horizontal: isActive ? 22 : 12,
                  vertical: 6,
                ),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(30),
                  gradient: isActive
                      ? LinearGradient(
                          colors: [
                            color.withOpacity(0.25),
                            color.withOpacity(0.08),
                          ],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        )
                      : null,
                  color: isActive ? null : Colors.transparent,
                  border: Border.all(
                    color: isActive ? color.withOpacity(0.6) : Colors.transparent,
                    width: 1.5,
                  ),
                  boxShadow: isActive
                      ? [
                          BoxShadow(
                            color: color.withOpacity(0.3),
                            blurRadius: 20,
                            spreadRadius: 2,
                          )
                        ]
                      : null,
                ),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    if (isActive)
                      ScaleTransition(
                        scale: _pulseAnim,
                        child: Container(
                          width: 8,
                          height: 8,
                          margin: const EdgeInsets.only(bottom: 2),
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: color,
                            boxShadow: [
                              BoxShadow(
                                color: color.withOpacity(0.8),
                                blurRadius: 15,
                              ),
                            ],
                          ),
                        ),
                      ),
                    Icon(
                      items[i].icon,
                      color: isActive ? color : kWhite54,
                      size: isActive ? 26 : 20,
                    ),
                    const SizedBox(height: 2),
                    Text(
                      items[i].label,
                      style: TextStyle(
                        color: isActive ? color : kWhite54,
                        fontSize: isActive ? 10 : 8,
                        fontWeight: isActive ? FontWeight.bold : FontWeight.normal,
                        fontFamily: 'Orbitron',
                      ),
                    ),
                  ],
                ),
              ),
            );
          }),
        ),
      ),
    );
  }

  // ─── DRAWER ────────────────────────────────────────────────────────────────
  Widget _buildDrawer() {
    return Drawer(
      backgroundColor: kBg,
      width: MediaQuery.of(context).size.width * 0.8,
      child: Column(
        children: [
          Container(
            height: 240,
            color: Colors.black,
            child: Stack(
              children: [
                if (_menuVideoCtrl != null && _menuVideoCtrl!.value.isInitialized)
                  SizedBox.expand(
                    child: FittedBox(
                      fit: BoxFit.cover,
                      child: SizedBox(
                        width: _menuVideoCtrl!.value.size.width,
                        height: _menuVideoCtrl!.value.size.height,
                        child: VideoPlayer(_menuVideoCtrl!),
                      ),
                    ),
                  ),
                Container(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topCenter, end: Alignment.bottomCenter,
                      colors: [Colors.black.withOpacity(0.3), Colors.black.withOpacity(0.85)],
                    ),
                  ),
                ),
                SafeArea(
                  child: Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Container(
                          width: 80, height: 80,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            border: Border.all(
                              color: _rainbowColors[DateTime.now().second % _rainbowColors.length]
                                  .withOpacity(0.6),
                              width: 2.5,
                            ),
                            boxShadow: [
                              BoxShadow(
                                color: kPurple.withOpacity(0.3),
                                blurRadius: 20,
                                spreadRadius: 4,
                              ),
                            ],
                          ),
                          child: ClipOval(
                            child: _profileImage != null
                                ? Image.file(_profileImage!, fit: BoxFit.cover)
                                : const Icon(FontAwesomeIcons.userAstronaut, size: 38, color: kWhite),
                          ),
                        ),
                        const SizedBox(height: 12),
                        Text(username,
                            style: const TextStyle(
                                color: kWhite, fontSize: 18, fontWeight: FontWeight.bold, fontFamily: 'Orbitron')),
                        Text(role.toUpperCase(),
                            style: const TextStyle(color: kPurple, fontSize: 12, letterSpacing: 2)),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
          Expanded(
            child: Container(
              color: kBg,
              child: ListView(
                padding: const EdgeInsets.symmetric(vertical: 16),
                children: [
                  if (['reseller','vip','owner','high_owner','founder','developer'].contains(role))
                    _buildDrawerItem(
                        icon: Icons.storefront_rounded,
                        label: 'Seller Page',
                        color: kGreen,
                        onTap: () => _onDrawerNav(1)),
                  if (['owner','high_owner','founder','developer'].contains(role))
                    _buildDrawerItem(
                        icon: Icons.workspace_premium_rounded,
                        label: 'Owner Page',
                        color: kGold,
                        onTap: () => _onDrawerNav(3)),
                  _buildDrawerItem(
                    icon: Icons.history_rounded,
                    label: 'Riwayat Aktivitas',
                    color: kCyan,
                    onTap: () {
                      Navigator.pop(context);
                      Navigator.push(
                          context,
                          _slideRoute(RiwayatPage(sessionKey: sessionKey, role: role))).then((_) {
                        if (mounted && _newsPageCtrl.hasClients) {
                          setState(() { _currentNewsPage = 0.0; _newsPageViewKey++; });
                          _newsPageCtrl.jumpToPage(0);
                        }
                      });
                    },
                  ),
                  _buildDrawerItem(
                    icon: Icons.lock_outline_rounded,
                    label: 'Ganti Password',
                    color: kYellow,
                    onTap: () {
                      Navigator.pop(context);
                      Navigator.push(
                        context,
                        _slideRoute(ChangePasswordPage(username: username, sessionKey: sessionKey)),
                      );
                    },
                  ),
                  const SizedBox(height: 16),
                  _buildDrawerItem(
                    icon: Icons.logout_rounded,
                    label: 'Keluar',
                    color: kRed,
                    isLogout: true,
                    onTap: () async {
                      Navigator.pop(context);
                      final prefs = await SharedPreferences.getInstance();
                      await prefs.clear();
                      if (!mounted) return;
                      Navigator.of(context).pushAndRemoveUntil(
                          MaterialPageRoute(builder: (_) => const LoginPage()), (_) => false);
                    },
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDrawerItem({
    required IconData icon,
    required String label,
    required Color color,
    required VoidCallback onTap,
    bool isLogout = false,
  }) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 14, vertical: 5),
      decoration: BoxDecoration(
        color: isLogout ? kRed.withOpacity(0.08) : kCard,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
            color: isLogout ? kRed.withOpacity(0.4) : kBorder.withOpacity(0.6)),
      ),
      child: ListTile(
        leading: Icon(icon, color: isLogout ? kRed : color, size: 20),
        title: Text(label,
            style: TextStyle(
                color: isLogout ? kRed : kWhite,
                fontWeight: FontWeight.w600, fontSize: 14)),
        trailing: const Icon(Icons.arrow_forward_ios_rounded, color: kWhite24, size: 13),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
        onTap: onTap,
      ),
    );
  }
}

// ─── QUICK ACTION DATA ─────────────────────────────────────────────────────────
class _QuickActionData {
  final IconData icon;
  final IconData bgIcon;
  final String title;
  final String subtitle;
  final List<Color> gradient;
  final VoidCallback onTap;
  const _QuickActionData({
    required this.icon,
    required this.bgIcon,
    required this.title,
    required this.subtitle,
    required this.gradient,
    required this.onTap,
  });
}

// ─── NAV ITEM ─────────────────────────────────────────────────────────────────
class _NavItem {
  final IconData icon;
  final String label;
  const _NavItem({required this.icon, required this.label});
}

// ─── SLIDE ROUTE ──────────────────────────────────────────────────────────────
PageRoute _slideRoute(Widget page) => PageRouteBuilder(
  pageBuilder: (_, __, ___) => page,
  transitionDuration: const Duration(milliseconds: 350),
  transitionsBuilder: (_, anim, __, child) => SlideTransition(
    position: Tween<Offset>(begin: const Offset(1, 0), end: Offset.zero)
        .animate(CurvedAnimation(parent: anim, curve: Curves.easeOutCubic)),
    child: FadeTransition(opacity: anim, child: child),
  ),
);

// ─── NEWSMEDIA ────────────────────────────────────────────────────────────────
class NewsMedia extends StatefulWidget {
  final String url;
  const NewsMedia({super.key, required this.url});
  @override
  State<NewsMedia> createState() => _NewsMediaState();
}

class _NewsMediaState extends State<NewsMedia> {
  VideoPlayerController? _ctrl;
  bool _isVideo(String url) =>
      url.endsWith('.mp4') || url.endsWith('.webm') ||
      url.endsWith('.mov') || url.endsWith('.mkv');
  @override
  void initState() {
    super.initState();
    if (_isVideo(widget.url)) {
      _ctrl = VideoPlayerController.networkUrl(Uri.parse(widget.url))
        ..initialize().then((_) {
          if (mounted) setState(() {});
          _ctrl?.setLooping(true);
          _ctrl?.setVolume(0.0);
          _ctrl?.play();
        });
    }
  }
  @override
  void dispose() { _ctrl?.dispose(); super.dispose(); }
  @override
  Widget build(BuildContext context) {
    if (_isVideo(widget.url)) {
      if (_ctrl != null && _ctrl!.value.isInitialized) {
        return AspectRatio(aspectRatio: _ctrl!.value.aspectRatio, child: VideoPlayer(_ctrl!));
      }
      return const Center(child: CircularProgressIndicator(color: kPurple, strokeWidth: 2));
    }
    return Image.network(
      widget.url, fit: BoxFit.cover,
      errorBuilder: (_, __, ___) =>
          Container(color: kCard, child: const Icon(Icons.error_rounded, color: kWhite24)),
    );
  }
}