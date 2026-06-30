// dashboard_page.dart - LENGKAP DENGAN 5 TOMBOL (Home, Bug, Chat, Info, Tools)

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
import 'contact_page.dart';
import 'profile_page.dart';
import 'riwayat_page.dart';
import 'info_page.dart';
import 'al_quran.dart';
import 'anime_home.dart';
import 'chat_public.dart';

// MAINTENANCE SERVICE
class MaintenanceService {
  static const String baseUrl = 'http://kurumi.xylotrechuz.my.id:2117';
  
  static Future<Map<String, dynamic>> getStatus() async {
    try {
      final response = await http.get(
        Uri.parse('$baseUrl/api/maintenance/status'),
      ).timeout(const Duration(seconds: 5));
      
      if (response.statusCode == 200) {
        return jsonDecode(response.body);
      }
    } catch (_) {}
    
    return {
      'maintenance': false,
      'message': '',
      'update_available': false,
      'update_version': '',
      'download_url': ''
    };
  }
  
  static Future<void> showMaintenanceDialog(BuildContext context) async {
    final status = await getStatus();
    await showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => WillPopScope(
        onWillPop: () async => false,
        child: MaintenanceDialog(message: status['message'] ?? 'Sistem sedang dalam perawatan'),
      ),
    );
  }
  
  static Future<bool> checkUpdate(BuildContext context) async {
    final status = await getStatus();
    if (status['update_available'] == true && status['download_url'].isNotEmpty) {
      final shouldUpdate = await showDialog<bool>(
        context: context,
        builder: (_) => Dialog(
          backgroundColor: Colors.transparent,
          child: Container(
            decoration: BoxDecoration(
              gradient: const LinearGradient(colors: [Color(0xFF131A26), Color(0xFF0A0E17)]),
              borderRadius: BorderRadius.circular(24),
              border: Border.all(color: const Color(0xFF00E5FF).withOpacity(0.5)),
            ),
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.system_update_rounded, color: Color(0xFF00E5FF), size: 60),
                const SizedBox(height: 20),
                const Text(
                  'UPDATE AVAILABLE',
                  style: TextStyle(color: Color(0xFF00E5FF), fontSize: 18, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 8),
                Text(
                  'Version ${status['update_version']}',
                  style: const TextStyle(color: Color(0xFF00FF88), fontSize: 14),
                ),
                const SizedBox(height: 24),
                Row(
                  children: [
                    Expanded(
                      child: GestureDetector(
                        onTap: () => Navigator.pop(context, false),
                        child: Container(
                          padding: const EdgeInsets.symmetric(vertical: 12),
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(30),
                            border: Border.all(color: Colors.white.withOpacity(0.3)),
                          ),
                          child: const Text('LATER', textAlign: TextAlign.center, style: TextStyle(color: Colors.white70)),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: GestureDetector(
                        onTap: () => Navigator.pop(context, true),
                        child: Container(
                          padding: const EdgeInsets.symmetric(vertical: 12),
                          decoration: const BoxDecoration(
                            gradient: LinearGradient(colors: [Color(0xFF00E5FF), Color(0xFF00FF88)]),
                            borderRadius: BorderRadius.all(Radius.circular(30)),
                          ),
                          child: const Text('UPDATE NOW', textAlign: TextAlign.center, style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold)),
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ) ?? false;
      
      if (shouldUpdate) {
        final url = Uri.parse(status['download_url']);
        await launchUrl(url, mode: LaunchMode.externalApplication);
        return true;
      }
    }
    return false;
  }
}

// MAINTENANCE DIALOG WITH ANIMATION & BUTTONS
class MaintenanceDialog extends StatefulWidget {
  final String message;
  const MaintenanceDialog({super.key, required this.message});

  @override
  State<MaintenanceDialog> createState() => _MaintenanceDialogState();
}

class _MaintenanceDialogState extends State<MaintenanceDialog> with SingleTickerProviderStateMixin {
  late AnimationController _pulseCtrl;
  late Animation<double> _pulseAnim;
  late AnimationController _rotateCtrl;

  @override
  void initState() {
    super.initState();
    _pulseCtrl = AnimationController(vsync: this, duration: const Duration(seconds: 1))
      ..repeat(reverse: true);
    _pulseAnim = Tween<double>(begin: 0.8, end: 1.2).animate(
      CurvedAnimation(parent: _pulseCtrl, curve: Curves.easeInOut)
    );
    _rotateCtrl = AnimationController(vsync: this, duration: const Duration(seconds: 3))
      ..repeat();
  }

  @override
  void dispose() {
    _pulseCtrl.dispose();
    _rotateCtrl.dispose();
    super.dispose();
  }

  void _openUrl(String url) async {
    await launchUrl(Uri.parse(url), mode: LaunchMode.externalApplication);
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: Colors.transparent,
      child: Container(
        decoration: BoxDecoration(
          gradient: const LinearGradient(colors: [Color(0xFF131A26), Color(0xFF0A0E17)]),
          borderRadius: BorderRadius.circular(32),
          border: Border.all(color: const Color(0xFFFF3B30).withOpacity(0.5)),
          boxShadow: [
            BoxShadow(color: const Color(0xFFFF3B30).withOpacity(0.3), blurRadius: 30, spreadRadius: 5),
          ],
        ),
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            AnimatedBuilder(
              animation: _rotateCtrl,
              builder: (_, __) => Transform.rotate(
                angle: _rotateCtrl.value * 2 * math.pi,
                child: ScaleTransition(
                  scale: _pulseAnim,
                  child: Container(
                    width: 80, height: 80,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      gradient: LinearGradient(colors: [const Color(0xFFFF3B30), const Color(0xFFFF6B6B)]),
                      boxShadow: [
                        BoxShadow(color: const Color(0xFFFF3B30).withOpacity(0.5), blurRadius: 20, spreadRadius: 5),
                      ],
                    ),
                    child: const Icon(Icons.build_circle_rounded, color: Colors.white, size: 45),
                  ),
                ),
              ),
            ),
            const SizedBox(height: 20),
            ShaderMask(
              shaderCallback: (bounds) => const LinearGradient(
                colors: [Color(0xFFFF3B30), Color(0xFFFF6B6B), Color(0xFFFF3B30)],
                stops: [0, 0.5, 1],
              ).createShader(bounds),
              child: const Text(
                'MAINTENANCE MODE',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  fontFamily: 'Orbitron',
                  letterSpacing: 2,
                ),
              ),
            ),
            const SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                _buildAnimatedDot(0),
                const SizedBox(width: 8),
                _buildAnimatedDot(1),
                const SizedBox(width: 8),
                _buildAnimatedDot(2),
              ],
            ),
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(16),
                color: const Color(0xFFFF3B30).withOpacity(0.1),
                border: Border.all(color: const Color(0xFFFF3B30).withOpacity(0.3)),
              ),
              child: Text(
                widget.message,
                textAlign: TextAlign.center,
                style: const TextStyle(color: Colors.white70, fontSize: 14, height: 1.5),
              ),
            ),
            const SizedBox(height: 24),
            Container(
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(16),
                color: const Color(0xFF1A2333),
                border: Border.all(color: const Color(0xFF00E5FF).withOpacity(0.3)),
              ),
              child: Column(
                children: [
                  GestureDetector(
                    onTap: () => _openUrl('https://t.me/MarvelNovaX'),
                    child: Container(
                      padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 16),
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(16),
                        color: const Color(0xFF00E5FF).withOpacity(0.1),
                      ),
                      child: Row(
                        children: [
                          Container(
                            width: 40, height: 40,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              gradient: const LinearGradient(colors: [Color(0xFF00E5FF), Color(0xFF00FF88)]),
                            ),
                            child: const Icon(Icons.telegram, color: Colors.black, size: 22),
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: const [
                                Text(
                                  'JOIN CHANNEL FOR UPDATE',
                                  style: TextStyle(color: Color(0xFF00E5FF), fontSize: 12, fontWeight: FontWeight.bold, letterSpacing: 1),
                                ),
                                Text(
                                  '@MarvelNovaX',
                                  style: TextStyle(color: Colors.white70, fontSize: 11),
                                ),
                              ],
                            ),
                          ),
                          const Icon(Icons.arrow_forward_ios_rounded, color: Color(0xFF00E5FF), size: 14),
                        ],
                      ),
                    ),
                  ),
                  Container(height: 1, color: const Color(0xFF00E5FF).withOpacity(0.2)),
                  GestureDetector(
                    onTap: () => _openUrl('https://t.me/MarvelNovaX'),
                    child: Container(
                      padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 16),
                      child: Row(
                        children: [
                          Container(
                            width: 40, height: 40,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              gradient: const LinearGradient(colors: [Color(0xFFB026FF), Color(0xFFFF2D75)]),
                            ),
                            child: const Icon(Icons.code_rounded, color: Colors.white, size: 22),
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: const [
                                Text(
                                  'DEVELOPER',
                                  style: TextStyle(color: Color(0xFFB026FF), fontSize: 12, fontWeight: FontWeight.bold, letterSpacing: 1),
                                ),
                                Text(
                                  '@MarvelNovaX',
                                  style: TextStyle(color: Colors.white70, fontSize: 11),
                                ),
                              ],
                            ),
                          ),
                          const Icon(Icons.arrow_forward_ios_rounded, color: Color(0xFFB026FF), size: 14),
                        ],
                      ),
                    ),
                  ),
                  Container(height: 1, color: const Color(0xFFB026FF).withOpacity(0.2)),
                  GestureDetector(
                    onTap: () => _openUrl('https://t.me/MarvelNovaX'),
                    child: Container(
                      padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 16),
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: Row(
                        children: [
                          Container(
                            width: 40, height: 40,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              gradient: const LinearGradient(colors: [Color(0xFFFF6D00), Color(0xFFFFD600)]),
                            ),
                            child: const Icon(Icons.favorite_rounded, color: Colors.white, size: 22),
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: const [
                                Text(
                                  'LOVERS',
                                  style: TextStyle(color: Color(0xFFFF6D00), fontSize: 12, fontWeight: FontWeight.bold, letterSpacing: 1),
                                ),
                                Text(
                                  '@Mavvlena',
                                  style: TextStyle(color: Colors.white70, fontSize: 11),
                                ),
                              ],
                            ),
                          ),
                          const Icon(Icons.arrow_forward_ios_rounded, color: Color(0xFFFF6D00), size: 14),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),
            GestureDetector(
              onTap: () => exit(0),
              child: Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(vertical: 12),
                decoration: BoxDecoration(
                  gradient: const LinearGradient(colors: [Color(0xFFFF3B30), Color(0xFFD32F2F)]),
                  borderRadius: BorderRadius.circular(30),
                ),
                child: const Text(
                  'CLOSE APPLICATION',
                  textAlign: TextAlign.center,
                  style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, letterSpacing: 2),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAnimatedDot(int index) {
    return TweenAnimationBuilder(
      tween: Tween<double>(begin: 0, end: 1),
      duration: Duration(milliseconds: 600 + (index * 200)),
      curve: Curves.easeInOut,
      builder: (_, double value, __) {
        return Opacity(
          opacity: 0.3 + (value * 0.7),
          child: Container(
            width: 10, height: 10,
            decoration: const BoxDecoration(
              shape: BoxShape.circle,
              color: Color(0xFFFF3B30),
            ),
          ),
        );
      },
    );
  }
}

const Color kBgDark      = Color(0xFF0A0E17);
const Color kBgCard      = Color(0xFF131A26);
const Color kBgCardLight = Color(0xFF1A2333);
const Color kBorderColor = Color(0xFF2A3442);
const Color kNeonBlue    = Color(0xFF00E5FF);
const Color kNeonGreen   = Color(0xFF00FF88);
const Color kNeonPink    = Color(0xFFFF2D75);
const Color kNeonOrange  = Color(0xFFFF6D00);
const Color kNeonPurple  = Color(0xFFB026FF);
const Color kNeonYellow  = Color(0xFFFFD600);
const Color kRed         = Color(0xFFFF3B30);
const Color kWhite       = Colors.white;
const Color kWhite70     = Colors.white70;
const Color kWhite40     = Color(0x66FFFFFF);
const Color kWhite15     = Color(0x26FFFFFF);
const Color kWhite08     = Color(0x14FFFFFF);

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

  late AnimationController _fadeCtrl;
  late Animation<double> _fadeAnim;
  late AnimationController _pulseCtrl;
  late Animation<double> _pulseAnim;

  Timer? _statsTimer;
  late PageController _newsPageCtrl;
  int _newsPageViewKey = 0;
  double _currentNewsPage = 0.0;
  late PageController _qaPageCtrl;
  double _currentQaPage = 0.0;

  bool _locationLoading = false;
  bool _locationGranted = false;
  String _prayerCity = 'Surabaya';
  Map<String, String> _prayerTimes = {};
  String _nextPrayerLabel = '';
  String _nextPrayerTime  = '';
  bool _prayerLoading = true;

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

    _fadeCtrl = AnimationController(vsync: this, duration: const Duration(milliseconds: 600));
    _fadeAnim = CurvedAnimation(parent: _fadeCtrl, curve: Curves.easeOut);
    _fadeCtrl.forward();

    _pulseCtrl = AnimationController(vsync: this, duration: const Duration(seconds: 2))
      ..repeat(reverse: true);
    _pulseAnim = Tween<double>(begin: 0.85, end: 1.0).animate(
        CurvedAnimation(parent: _pulseCtrl, curve: Curves.easeInOut));

    _newsPageCtrl = PageController(viewportFraction: 0.88, initialPage: 0);
    _newsPageCtrl.addListener(() {
      if (mounted) setState(() => _currentNewsPage = _newsPageCtrl.page ?? 0.0);
    });

    _qaPageCtrl = PageController(viewportFraction: 0.88, initialPage: 0);
    _qaPageCtrl.addListener(() {
      if (mounted) setState(() => _currentQaPage = _qaPageCtrl.page ?? 0.0);
    });

    _initAndroidId();
    _loadProfileImage();
    _initMenuVideo();
    _detectLocationAndFetchPrayer(); 
    _fetchRandomHadith();
    
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      final needUpdate = await MaintenanceService.checkUpdate(context);
      if (needUpdate) return;
      
      final status = await MaintenanceService.getStatus();
      if (status['maintenance'] == true) {
        await MaintenanceService.showMaintenanceDialog(context);
      }
    });
  }

  @override
  void dispose() {
    _statsTimer?.cancel();
    channel.sink.close(status.goingAway);
    _fadeCtrl.dispose();
    _pulseCtrl.dispose();
    _menuVideoCtrl?.dispose();
    _newsPageCtrl.dispose();
    _qaPageCtrl.dispose();
    super.dispose();
  }

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
    channel = WebSocketChannel.connect(Uri.parse('$baseUrl'));
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

  Future<void> _fetchPrayerTimes() async {
    if (!mounted) return;
    setState(() => _prayerLoading = true);
    final now = DateTime.now();
    final uri = Uri.https('api.aladhan.com', '/v1/timingsByCity', {
      'city': _prayerCity, 'country': 'ID', 'method': '11',
      'day': '${now.day}', 'month': '${now.month}', 'year': '${now.year}',
    });
    try {
      final res = await http.get(uri).timeout(const Duration(seconds: 10));
      if (res.statusCode == 200) {
        final data = jsonDecode(res.body);
        if (data.isNotEmpty) {
          final timings = data['data']?['timings'] ?? {};
          final Map<String, String> times = {
            'Subuh'  : timings['Fajr']    ?? '--:--',
            'Dzuhur' : timings['Dhuhr']   ?? '--:--',
            'Ashar'  : timings['Asr']     ?? '--:--',
            'Maghrib': timings['Maghrib'] ?? '--:--',
            'Isya'   : timings['Isha']    ?? '--:--',
          };
          final nowTime = TimeOfDay.now();
          String nextLabel = 'Isya';
          String nextTime  = times['Isya'] ?? '--:--';
          for (final entry in times.entries) {
            final parts = entry.value.split(':');
            if (parts.length >= 2) {
              final h = int.tryParse(parts[0]) ?? 0;
              final m = int.tryParse(parts[1]) ?? 0;
              if (h > nowTime.hour || (h == nowTime.hour && m > nowTime.minute)) {
                nextLabel = entry.key;
                nextTime  = entry.value;
                break;
              }
            }
          }
          setState(() {
            _prayerTimes = times;
            _nextPrayerLabel = nextLabel;
            _nextPrayerTime = nextTime;
            _prayerLoading = false;
          });
        } else {
          setState(() => _prayerLoading = false);
        }
      } else {
        setState(() => _prayerLoading = false);
      }
    } catch (_) {
      setState(() => _prayerLoading = false);
    }
  }

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
          _prayerCity = city;
          _locationGranted = true;
          _locationLoading = false;
        });
        await _fetchPrayerTimes();
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

  void _showChangeCityDialog() {
    final ctrl = TextEditingController(text: _prayerCity);
    showDialog(
      context: context,
      builder: (_) => Dialog(
        backgroundColor: Colors.transparent,
        child: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(colors: [kBgCard, kBgCardLight]),
            borderRadius: BorderRadius.circular(24),
            border: Border.all(color: kNeonBlue.withOpacity(0.5)),
          ),
          padding: const EdgeInsets.all(20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text('Ganti Lokasi',
                  style: TextStyle(color: kNeonBlue, fontFamily: 'Orbitron', fontSize: 14)),
              const SizedBox(height: 16),
              TextField(
                controller: ctrl,
                style: const TextStyle(color: kWhite),
                decoration: InputDecoration(
                  hintText: 'Nama kota',
                  hintStyle: const TextStyle(color: kWhite70),
                  filled: true,
                  fillColor: kWhite08,
                  border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide(color: kNeonBlue.withOpacity(0.3))),
                  prefixIcon: const Icon(Icons.location_city_rounded, color: kNeonGreen),
                ),
              ),
              const SizedBox(height: 20),
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  TextButton(
                    onPressed: () => Navigator.pop(context),
                    child: const Text('Batal', style: TextStyle(color: kWhite70)),
                  ),
                  const SizedBox(width: 12),
                  GestureDetector(
                    onTap: () {
                      if (ctrl.text.trim().isNotEmpty) {
                        setState(() {
                          _prayerCity = ctrl.text.trim();
                          _locationGranted = false;
                        });
                        _fetchPrayerTimes();
                        Navigator.pop(context);
                      }
                    },
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                      decoration: BoxDecoration(
                        gradient: LinearGradient(colors: [kNeonGreen, kNeonBlue]),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: const Text('Simpan',
                          style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold)),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showHadithFullDialog(String arabic, String indo, String source, String number, String grade) {
    showDialog(
      context: context,
      barrierDismissible: true,
      builder: (_) => Dialog(
        backgroundColor: Colors.transparent,
        insetPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 24),
        child: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(colors: [kBgCard, kBgCardLight]),
            borderRadius: BorderRadius.circular(24),
            border: Border.all(color: kNeonBlue.withOpacity(0.5)),
            boxShadow: [
              BoxShadow(color: kNeonBlue.withOpacity(0.2), blurRadius: 30, spreadRadius: 2),
            ],
          ),
          padding: const EdgeInsets.all(20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Row(
                children: [
                  Container(
                    width: 42, height: 42,
                    decoration: BoxDecoration(shape: BoxShape.circle, color: kNeonBlue.withOpacity(0.2)),
                    child: const Icon(Icons.menu_book_rounded, color: kNeonBlue, size: 22),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                      const Text('HADITH LENGKAP',
                          style: TextStyle(color: kWhite, fontWeight: FontWeight.bold, fontSize: 14, fontFamily: 'Orbitron')),
                      Text(grade, style: const TextStyle(color: kNeonBlue, fontSize: 11)),
                    ]),
                  ),
                  GestureDetector(
                    onTap: () => Navigator.pop(context),
                    child: Container(
                      width: 34, height: 34,
                      decoration: BoxDecoration(shape: BoxShape.circle, color: kWhite15),
                      child: const Icon(Icons.close_rounded, color: kWhite70, size: 18),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              SingleChildScrollView(
                physics: const BouncingScrollPhysics(),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      width: double.infinity, padding: const EdgeInsets.all(18),
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(16),
                        color: kWhite08,
                        border: Border.all(color: kNeonBlue.withOpacity(0.2)),
                      ),
                      child: Text(arabic,
                          textAlign: TextAlign.right, textDirection: TextDirection.rtl,
                          style: const TextStyle(color: kWhite, fontSize: 19, height: 2.2)),
                    ),
                    const SizedBox(height: 14),
                    Row(children: [
                      Container(width: 3, height: 18,
                          decoration: BoxDecoration(borderRadius: BorderRadius.circular(2), color: kNeonBlue)),
                      const SizedBox(width: 8),
                      const Text('ARTINYA:', style: TextStyle(color: kNeonBlue, fontSize: 11, fontWeight: FontWeight.bold, letterSpacing: 1.2)),
                    ]),
                    const SizedBox(height: 10),
                    Container(
                      width: double.infinity, padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(14),
                        color: kWhite08,
                        border: Border.all(color: kNeonBlue.withOpacity(0.2)),
                      ),
                      child: Text(indo,
                          style: const TextStyle(color: kWhite70, fontSize: 14, fontStyle: FontStyle.italic, height: 1.8)),
                    ),
                    const SizedBox(height: 16),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(color: kNeonBlue.withOpacity(0.5)),
                        color: kNeonBlue.withOpacity(0.1),
                      ),
                      child: Row(mainAxisSize: MainAxisSize.min, children: [
                        const Icon(Icons.receipt_long_rounded, color: kNeonBlue, size: 14),
                        const SizedBox(width: 6),
                        Text('${source.isNotEmpty ? source : "Muslim"} #$number',
                            style: const TextStyle(color: kNeonBlue, fontSize: 12, fontWeight: FontWeight.bold)),
                      ]),
                    ),
                  ],
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
      builder: (_) => Dialog(
        backgroundColor: Colors.transparent,
        child: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(colors: [kBgCard, kBgCardLight]),
            borderRadius: BorderRadius.circular(24),
            border: Border.all(color: kNeonBlue.withOpacity(0.5)),
          ),
          padding: const EdgeInsets.all(20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text('Session Expired',
                  style: TextStyle(color: kWhite, fontFamily: 'Orbitron')),
              const SizedBox(height: 12),
              Text(message, style: const TextStyle(color: kWhite70)),
              const SizedBox(height: 20),
              GestureDetector(
                onTap: () => Navigator.of(context).pushAndRemoveUntil(
                    MaterialPageRoute(builder: (_) => const LoginPage()), (_) => false),
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 30, vertical: 10),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(colors: [kNeonBlue, kNeonGreen]),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Text('OK', style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold)),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

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
      case 4:
        return ChatPublicPage(username: username, sessionKey: sessionKey);
      case 0:
      default:
        return _buildHomePage();
    }
  }

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
              child: Text('Bellion System',
                style: TextStyle(
                  color: kWhite15,
                  fontSize: 13, letterSpacing: 4,
                  fontFamily: 'Orbitron',
                ),
              ),
            ),
            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }

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
                child: Text('Bellion-Space',
                  style: TextStyle(
                    color: kWhite, fontSize: 22, fontWeight: FontWeight.bold,
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

  Widget _buildWelcomeCard() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 14),
      child: Container(
        padding: const EdgeInsets.all(18),
        decoration: BoxDecoration(
          gradient: LinearGradient(colors: [kBgCard, kBgCardLight]),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: kNeonBlue.withOpacity(0.5)),
          boxShadow: [
            BoxShadow(color: kNeonBlue.withOpacity(0.2), blurRadius: 20, offset: const Offset(0, 8))
          ],
        ),
        child: Column(
          children: [
            Row(
              children: [
                ScaleTransition(
                  scale: _pulseAnim,
                  child: Container(
                    width: 58, height: 58,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      gradient: const LinearGradient(colors: [kRed, Color(0xFFD32F2F)]),
                      boxShadow: [BoxShadow(color: kRed.withOpacity(0.5), blurRadius: 16, spreadRadius: 2)],
                    ),
                    child: const Center(child: Icon(Icons.security_rounded, color: kWhite, size: 28)),
                  ),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text('Welcome Back,',
                          style: TextStyle(color: kWhite70, fontSize: 12, fontFamily: 'Orbitron')),
                      Text(username,
                          style: const TextStyle(
                            color: kWhite, fontSize: 18, fontWeight: FontWeight.bold, fontFamily: 'Orbitron')),
                      const SizedBox(height: 4),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(color: kNeonBlue.withOpacity(0.5)),
                          color: kNeonBlue.withOpacity(0.08),
                        ),
                        child: Text(role.toUpperCase(),
                            style: const TextStyle(
                              color: kNeonBlue, fontSize: 10, fontWeight: FontWeight.bold, letterSpacing: 1.5)),
                      ),
                    ],
                  ),
                ),
                Container(
                  width: 40, height: 40,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: kNeonGreen.withOpacity(0.12),
                    border: Border.all(color: kNeonGreen.withOpacity(0.3)),
                  ),
                  child: const Icon(Icons.timer_outlined, color: kNeonGreen, size: 20),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(vertical: 10),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(30),
                border: Border.all(color: kNeonBlue.withOpacity(0.4)),
                color: kNeonBlue.withOpacity(0.04),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Container(width: 6, height: 6, decoration: const BoxDecoration(shape: BoxShape.circle, color: kNeonBlue)),
                  const SizedBox(width: 10),
                  const Text('BELLION SPACE DASHBOARD',
                      style: TextStyle(
                        color: kNeonBlue, fontSize: 11, fontWeight: FontWeight.bold,
                        fontFamily: 'Orbitron', letterSpacing: 1.5)),
                  const SizedBox(width: 10),
                  Container(width: 6, height: 6, decoration: const BoxDecoration(shape: BoxShape.circle, color: kNeonBlue)),
                ],
              ),
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                _buildCircleStatItem(
                    icon: Icons.people_alt_rounded,
                    value: '$onlineUsers',
                    label: 'ONLINE',
                    color: kNeonGreen),
                _buildStatDivider(),
                _buildCircleStatItem(
                    icon: Icons.link_rounded,
                    value: '$activeConns',
                    label: 'SESSIONS',
                    color: kNeonBlue),
                _buildStatDivider(),
                _buildCircleStatItem(
                    icon: Icons.calendar_month_rounded,
                    value: expiredDate.length > 10 ? expiredDate.substring(0, 10) : expiredDate,
                    label: 'EXPIRED',
                    color: kNeonOrange),
              ],
            ),
          ],
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
              color: color.withOpacity(0.15),
              border: Border.all(color: color.withOpacity(0.6), width: 2),
              boxShadow: [BoxShadow(color: color.withOpacity(0.4), blurRadius: 14, spreadRadius: 2)],
            ),
            child: Center(child: Icon(icon, color: color, size: 28)),
          ),
          const SizedBox(height: 8),
          Text(value,
              style: const TextStyle(
                  color: kWhite, fontWeight: FontWeight.bold, fontSize: 13, fontFamily: 'Orbitron')),
          const SizedBox(height: 2),
          Text(label, style: const TextStyle(color: kWhite70, fontSize: 9), textAlign: TextAlign.center),
        ],
      ),
    );
  }

  Widget _buildStatDivider() =>
      Container(width: 1, height: 60, color: kWhite15);

  Widget _buildQuickActionsSection() {
    final actions = [
      {
        'icon': FontAwesomeIcons.whatsapp,
        'title': 'Manage Sender',
        'subtitle': 'Manage your active sender',
        'color': kNeonPink,
        'onTap': () => Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => BugSenderPage(sessionKey: sessionKey, username: username, role: role)),
        ),
      },
      {
        'icon': FontAwesomeIcons.telegram,
        'title': 'Join Channel',
        'subtitle': 'Get updates',
        'color': const Color(0xFF00B4D8),
        'onTap': () => _openUrl('https://t.me/MarvelNovaX'),
      },
      {
        'icon': FontAwesomeIcons.whatsapp,
        'title': 'Join WhatsApp',
        'subtitle': 'Community group',
        'color': const Color(0xFF25D366),
        'onTap': () => _openUrl('https://chat.whatsapp.com/'),
      },
      {
        'icon': FontAwesomeIcons.tv,
        'title': 'Fitur Lainnya',
        'subtitle': 'More features',
        'color': kNeonOrange,
        'onTap': () => Navigator.push(context, MaterialPageRoute(builder: (_) => HomeAnimePage())),
      },
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
                  color: kNeonYellow.withOpacity(0.15),
                  border: Border.all(color: kNeonYellow.withOpacity(0.3)),
                ),
                child: const Icon(Icons.bolt_rounded, color: kNeonYellow, size: 22),
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
                      style: TextStyle(color: kWhite70, fontSize: 12)),
                ],
              ),
            ],
          ),
        ),
        const SizedBox(height: 14),
        SizedBox(
          height: 180,
          child: ListView.builder(
            scrollDirection: Axis.horizontal,
            physics: const BouncingScrollPhysics(),
            padding: const EdgeInsets.symmetric(horizontal: 14),
            itemCount: actions.length,
            itemBuilder: (ctx, i) {
              final action = actions[i];
              return GestureDetector(
                onTap: action['onTap'] as VoidCallback,
                child: Container(
                  width: 180,
                  margin: const EdgeInsets.only(right: 12),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(22),
                    gradient: LinearGradient(
                        colors: [action['color'] as Color, (action['color'] as Color).withOpacity(0.7)],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight),
                    boxShadow: [
                      BoxShadow(
                          color: (action['color'] as Color).withOpacity(0.4),
                          blurRadius: 20, offset: const Offset(0, 8))
                    ],
                  ),
                  child: Padding(
                    padding: const EdgeInsets.all(22),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Container(
                          width: 50, height: 50,
                          decoration: BoxDecoration(
                              shape: BoxShape.circle, color: kWhite15),
                          child: Icon(action['icon'] as IconData, color: kWhite, size: 24),
                        ),
                        const Spacer(),
                        Align(
                          alignment: Alignment.topRight,
                          child: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                            decoration: BoxDecoration(
                                borderRadius: BorderRadius.circular(20),
                                color: kWhite15),
                            child: const Text('Tap',
                                style: TextStyle(color: kWhite, fontSize: 11, fontWeight: FontWeight.bold)),
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(action['title'] as String,
                            style: const TextStyle(
                              color: kWhite, fontWeight: FontWeight.bold, fontSize: 17, fontFamily: 'Orbitron')),
                        const SizedBox(height: 4),
                        Text(action['subtitle'] as String,
                            style: TextStyle(color: kWhite70, fontSize: 12)),
                      ],
                    ),
                  ),
                ),
              );
            },
          ),
        ),
      ],
    );
  }

  Widget _buildLatestUpdates() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 14),
          child: Row(
            children: [
              const Icon(Icons.dashboard_customize_rounded, color: kNeonOrange, size: 22),
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
                    color: kNeonOrange.withOpacity(0.15),
                    border: Border.all(color: kNeonOrange.withOpacity(0.4)),
                  ),
                  child: Text('${newsList.length} Updates',
                      style: const TextStyle(
                          color: kNeonOrange, fontSize: 11, fontWeight: FontWeight.bold)),
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
                  color: kBgCard,
                  border: Border.all(color: kNeonBlue.withOpacity(0.3))),
              child: const Center(
                  child: Text('No updates available', style: TextStyle(color: kWhite70))),
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
        gradient: LinearGradient(colors: [kBgCard, kBgCardLight]),
        border: Border.all(color: kNeonBlue.withOpacity(0.3)),
        boxShadow: [
          BoxShadow(color: kNeonBlue.withOpacity(0.1), blurRadius: 12, offset: const Offset(0, 6))
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
                  height: 110, width: double.infinity, color: kBgDark,
                  child: imgUrl.isNotEmpty
                      ? Image.network(imgUrl, fit: BoxFit.cover,
                          errorBuilder: (_, __, ___) => const Center(
                              child: Icon(Icons.image_not_supported, color: kWhite40, size: 30)))
                      : const Center(
                          child: Icon(Icons.article_rounded, color: kWhite40, size: 30)),
                ),
                Positioned(
                  top: 8, right: 8,
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(10),
                      color: Colors.black.withOpacity(0.65),
                      border: Border.all(color: kNeonOrange.withOpacity(0.7)),
                    ),
                    child: const Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.circle_notifications_rounded, color: kNeonOrange, size: 10),
                        SizedBox(width: 3),
                        Text('NEW',
                            style: TextStyle(
                                color: kNeonOrange, fontSize: 9, fontWeight: FontWeight.bold)),
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
                const Icon(Icons.access_time_rounded, color: kWhite40, size: 11),
                const SizedBox(width: 4),
                if (date.isNotEmpty)
                  Expanded(
                    child: Text(
                        date.length > 10 ? date.substring(0, 10) : date,
                        style: const TextStyle(color: kWhite70, fontSize: 10)),
                  ),
                Container(
                  padding: const EdgeInsets.all(4),
                  decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(8),
                      color: kNeonOrange.withOpacity(0.18)),
                  child: const Icon(Icons.arrow_forward_ios_rounded, color: kNeonOrange, size: 9),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPrayerSection() {
    final prayerColors = [
      kNeonPurple,
      const Color(0xFFFF9800),
      kNeonOrange,
      kNeonBlue,
      const Color(0xFF1565C0),
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
          gradient: LinearGradient(colors: [kBgCard, kBgCardLight]),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: kNeonBlue.withOpacity(0.4)),
          boxShadow: [
            BoxShadow(color: kNeonBlue.withOpacity(0.15), blurRadius: 18, offset: const Offset(0, 8))
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
                    color: kNeonGreen.withOpacity(0.15),
                    border: Border.all(color: kNeonGreen.withOpacity(0.4)),
                  ),
                  child: const Center(child: Icon(Icons.mosque, color: kNeonGreen, size: 26)),
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
                          style: const TextStyle(color: kWhite70, fontSize: 12)),
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
                          ? kNeonGreen.withOpacity(0.15)
                          : kWhite15,
                      border: Border.all(
                        color: _locationGranted
                            ? kNeonGreen.withOpacity(0.6)
                            : kWhite40.withOpacity(0.3),
                      ),
                    ),
                    child: _locationLoading
                        ? const Padding(
                            padding: EdgeInsets.all(10),
                            child: CircularProgressIndicator(color: kNeonGreen, strokeWidth: 2),
                          )
                        : Icon(
                            _locationGranted
                                ? Icons.my_location_rounded
                                : Icons.location_searching_rounded,
                            color: _locationGranted ? kNeonGreen : kWhite70,
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
                      gradient: LinearGradient(colors: [kNeonGreen, kNeonBlue]),
                    ),
                    child: const Row(children: [
                      Icon(Icons.edit_location_alt_rounded, color: Colors.black, size: 14),
                      SizedBox(width: 5),
                      Text('GANTI',
                          style: TextStyle(
                              color: Colors.black, fontSize: 12, fontWeight: FontWeight.bold)),
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
                  border: Border.all(color: kNeonGreen.withOpacity(0.5)),
                ),
                child: Row(
                  children: [
                    ScaleTransition(
                      scale: _pulseAnim,
                      child: Container(width: 8, height: 8, decoration: const BoxDecoration(shape: BoxShape.circle, color: kNeonOrange)),
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
                        border: Border.all(color: kNeonGreen.withOpacity(0.5)),
                      ),
                      child: const Text('Bellion-Space',
                          style: TextStyle(color: kNeonGreen, fontSize: 10, fontWeight: FontWeight.bold)),
                    ),
                  ],
                ),
              ),
            const SizedBox(height: 14),
            if (_prayerLoading)
              const Center(child: CircularProgressIndicator(color: kNeonGreen, strokeWidth: 2))
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
                              color: color.withOpacity(isNext ? 0.65 : 0.3),
                              blurRadius: isNext ? 18 : 8, offset: const Offset(0, 4))
                        ],
                        border: isNext
                            ? Border.all(color: kWhite.withOpacity(0.5), width: 1.5)
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

  Widget _buildHadithSection() {
    if (_hadithLoading) {
      return Padding(
        padding: const EdgeInsets.symmetric(horizontal: 14),
        child: Container(
          height: 200,
          decoration: BoxDecoration(
            gradient: LinearGradient(colors: [kBgCard, kBgCardLight]),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: kNeonBlue.withOpacity(0.3)),
          ),
          child: const Center(child: CircularProgressIndicator(color: kNeonBlue, strokeWidth: 2)),
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
          gradient: LinearGradient(colors: [kBgCard, kBgCardLight]),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: kNeonBlue.withOpacity(0.4)),
          boxShadow: [
            BoxShadow(color: kNeonBlue.withOpacity(0.15), blurRadius: 18, offset: const Offset(0, 8))
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
                      shape: BoxShape.circle, color: kNeonBlue.withOpacity(0.15)),
                  child: const Center(child: Icon(Icons.menu_book_rounded, color: kNeonBlue, size: 26)),
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
                        style: const TextStyle(color: kWhite70, fontSize: 11)),
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
                      color: kWhite08,
                      border: Border.all(color: kNeonBlue.withOpacity(0.2)),
                    ),
                    child: Text(arabic,
                        textAlign: TextAlign.right, textDirection: TextDirection.rtl,
                        style: const TextStyle(color: kWhite, fontSize: 17, height: 2.0)),
                  ),
                  const SizedBox(height: 10),
                  Container(
                    width: double.infinity, padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(14), color: kWhite08),
                    child: Text(indo,
                        style: const TextStyle(
                          color: kWhite70, fontSize: 12, fontStyle: FontStyle.italic, height: 1.7),
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
                    border: Border.all(color: kNeonBlue.withOpacity(0.45)),
                    color: kNeonBlue.withOpacity(0.1),
                  ),
                  child: Row(mainAxisSize: MainAxisSize.min, children: [
                    const Icon(Icons.receipt_long_rounded, color: kNeonBlue, size: 13),
                    const SizedBox(width: 5),
                    Text('${source.isNotEmpty ? source : "Muslim"} #$number',
                        style: const TextStyle(
                            color: kNeonBlue, fontSize: 11, fontWeight: FontWeight.bold)),
                  ]),
                ),
                const Spacer(),
                GestureDetector(
                  onTap: _fetchRandomHadith,
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: kWhite40.withOpacity(0.3)),
                    ),
                    child: const Row(mainAxisSize: MainAxisSize.min, children: [
                      Icon(Icons.touch_app_rounded, color: kWhite70, size: 14),
                      SizedBox(width: 4),
                      Text('Tap card', style: TextStyle(color: kWhite70, fontSize: 11)),
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: kBgDark,
      appBar: _buildGlassAppBar(),
      drawer: _buildGlassDrawer(),
      body: Stack(
        children: [
          Container(
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                colors: [Color(0xFF0A0E17), Color(0xFF060A12)],
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
      bottomNavigationBar: _buildGlassBottomNav(),
    );
  }

  PreferredSizeWidget _buildGlassAppBar() {
    return AppBar(
      backgroundColor: kBgDark.withOpacity(0.95),
      elevation: 0,
      iconTheme: const IconThemeData(color: kWhite),
      titleSpacing: 0,
      flexibleSpace: Container(
        decoration: BoxDecoration(
          border: Border(bottom: BorderSide(color: kNeonBlue.withOpacity(0.3))),
        ),
      ),
      title: Row(
        children: [
          const SizedBox(width: 8),
          Container(
            width: 36, height: 36,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              border: Border.all(color: kNeonBlue.withOpacity(0.4)),
              color: kNeonBlue.withOpacity(0.1),
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
            MaterialPageRoute(builder: (_) => ProfilePage(
              username: username, password: password,
              role: role, expiredDate: expiredDate, sessionKey: sessionKey,
            )),
          ),
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
                          color: kWhite70, fontSize: 10, fontFamily: 'Orbitron')),
                  const SizedBox(width: 4),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1),
                    decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(6),
                        color: kRed.withOpacity(0.2),
                        border: Border.all(color: kRed.withOpacity(0.4))),
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
            MaterialPageRoute(builder: (_) => ProfilePage(
              username: username, password: password,
              role: role, expiredDate: expiredDate, sessionKey: sessionKey,
            )),
          ),
          child: Container(
            width: 38, height: 38,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              border: Border.all(color: kRed.withOpacity(0.5), width: 2),
              color: kRed.withOpacity(0.15),
            ),
            child: ClipOval(
              child: _profileImage != null
                  ? Image.file(_profileImage!, fit: BoxFit.cover)
                  : const Icon(FontAwesomeIcons.userAstronaut, color: kRed, size: 20),
            ),
          ),
        ),
        const SizedBox(width: 4),
        GestureDetector(
          onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const ContactPage())),
          child: const Padding(
            padding: EdgeInsets.symmetric(horizontal: 8),
            child: Icon(Icons.headset_mic_outlined, color: kWhite, size: 24),
          ),
        ),
        const SizedBox(width: 4),
      ],
    );
  }

  Widget _buildGlassBottomNav() {
    return Container(
      margin: const EdgeInsets.fromLTRB(16, 0, 16, 12),
      decoration: BoxDecoration(
        gradient: LinearGradient(colors: [kBgCard, kBgCardLight]),
        borderRadius: BorderRadius.circular(40),
        border: Border.all(color: kNeonBlue.withOpacity(0.3)),
        boxShadow: [
          BoxShadow(color: kNeonBlue.withOpacity(0.2), blurRadius: 16, offset: const Offset(0, 4)),
        ],
      ),
      child: SizedBox(
        height: 72,
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceAround,
          children: [
            _buildNavItem(Icons.home_rounded, 'Home', 0),
            _buildNavItem(FontAwesomeIcons.whatsapp, 'Bug', 1),
            _buildChatButton(),
            _buildNavItem(Icons.info_outline_rounded, 'Info', 2),
            _buildNavItem(Icons.build_circle_outlined, 'Tools', 3),
          ],
        ),
      ),
    );
  }

  Widget _buildNavItem(IconData icon, String label, int index) {
    final isActive = _navIndex == index;
    return GestureDetector(
      onTap: () => _onNavTap(index),
      child: SizedBox(
        width: 60,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            if (isActive)
              Container(
                width: 28, height: 3,
                margin: const EdgeInsets.only(bottom: 4),
                decoration: BoxDecoration(
                  color: kNeonBlue,
                  borderRadius: BorderRadius.circular(4),
                  boxShadow: [BoxShadow(color: kNeonBlue.withOpacity(0.6), blurRadius: 4)],
                ),
              ),
            Icon(icon, color: isActive ? kNeonBlue : kWhite40, size: 24),
            const SizedBox(height: 4),
            Text(label,
                style: TextStyle(
                  color: isActive ? kNeonBlue : kWhite40,
                  fontSize: 10,
                  fontWeight: isActive ? FontWeight.bold : FontWeight.normal,
                )),
          ],
        ),
      ),
    );
  }

  Widget _buildChatButton() {
    final isActive = _navIndex == 4;
    return GestureDetector(
      onTap: () => _onNavTap(4),
      child: Container(
        width: 65,
        height: 65,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          gradient: LinearGradient(
            colors: [kNeonBlue, kNeonGreen],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          boxShadow: [
            BoxShadow(
              color: kNeonBlue.withOpacity(0.5),
              blurRadius: 16,
              spreadRadius: 2,
            ),
          ],
        ),
        child: const Center(
          child: Icon(Icons.chat_rounded, color: Colors.black, size: 32),
        ),
      ),
    );
  }

  Widget _buildGlassDrawer() {
    return Drawer(
      backgroundColor: kBgDark,
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
                            border: Border.all(color: kNeonBlue.withOpacity(0.6), width: 2.5),
                            boxShadow: [BoxShadow(color: kNeonBlue.withOpacity(0.3), blurRadius: 14, spreadRadius: 2)],
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
                            style: const TextStyle(color: kNeonBlue, fontSize: 12, letterSpacing: 2)),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
          Expanded(
            child: Container(
              color: kBgDark,
              child: ListView(
                padding: const EdgeInsets.symmetric(vertical: 16),
                children: [
                  if (role == 'reseller')
                    _buildGlassDrawerItem(
                        icon: Icons.storefront_rounded,
                        label: 'Seller Page',
                        onTap: () => _onDrawerNav(1)),
                  if (role == 'admin')
                    _buildGlassDrawerItem(
                        icon: Icons.admin_panel_settings_rounded,
                        label: 'Admin Page',
                        onTap: () => _onDrawerNav(2)),
                  if (role == 'owner')
                    _buildGlassDrawerItem(
                        icon: Icons.workspace_premium_rounded,
                        label: 'Owner Page',
                        onTap: () => _onDrawerNav(3)),
                  _buildGlassDrawerItem(
                    icon: Icons.chat_rounded,
                    label: 'Public Chat',
                    onTap: () {
                      Navigator.pop(context);
                      _onNavTap(4);
                    },
                  ),
                  _buildGlassDrawerItem(
                    icon: Icons.history_rounded,
                    label: 'Riwayat Aktivitas',
                    onTap: () {
                      Navigator.pop(context);
                      Navigator.push(
                          context,
                          MaterialPageRoute(builder: (_) => RiwayatPage(sessionKey: sessionKey, role: role)));
                    },
                  ),
                  _buildGlassDrawerItem(
                    icon: Icons.lock_outline_rounded,
                    label: 'Ganti Password',
                    onTap: () {
                      Navigator.pop(context);
                      Navigator.push(
                        context,
                        MaterialPageRoute(builder: (_) => ChangePasswordPage(username: username, sessionKey: sessionKey)),
                      );
                    },
                  ),
                  const SizedBox(height: 16),
                  _buildGlassDrawerItem(
                    icon: Icons.logout_rounded,
                    label: 'Keluar',
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

  Widget _buildGlassDrawerItem({
    required IconData icon,
    required String label,
    required VoidCallback onTap,
    bool isLogout = false,
  }) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 14, vertical: 5),
      decoration: BoxDecoration(
        gradient: LinearGradient(colors: isLogout 
            ? [kRed.withOpacity(0.15), kRed.withOpacity(0.05)]
            : [kBgCard, kBgCardLight]),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
            color: isLogout ? kRed.withOpacity(0.3) : kNeonBlue.withOpacity(0.3)),
      ),
      child: ListTile(
        leading: Icon(icon, color: isLogout ? kRed : kNeonBlue, size: 20),
        title: Text(label,
            style: TextStyle(
                color: isLogout ? kRed : kWhite,
                fontWeight: FontWeight.w600, fontSize: 14)),
        trailing: const Icon(Icons.arrow_forward_ios_rounded, color: kWhite40, size: 13),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
        onTap: onTap,
      ),
    );
  }
}