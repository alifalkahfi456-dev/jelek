import 'dart:convert';
import 'dart:math' as math;
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:device_info_plus/device_info_plus.dart';
import 'package:web_socket_channel/web_socket_channel.dart';
import 'package:web_socket_channel/status.dart' as status;
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:video_player/video_player.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:http/http.dart' as http;

import 'change_password.dart';
import 'bug_sender.dart';
import 'admin_page.dart';
import 'home_page.dart';
import 'seller_page.dart';
import 'tools_gateway.dart';
import 'login_page.dart';
import 'chat_ai_page.dart';
import 'jadwal_sholat_page.dart';
import 'global_chat_page.dart';
import 'home_anime_page.dart';
import 'al_quran_page.dart';
import 'musik_home_page.dart';
import 'cdrama_page.dart';

const Color _dpBgPage      = Color(0xFF0b1120);
const Color _dpCardBg      = Color(0xFF111827);
const Color _dpCardBg2     = Color(0xFF0d1b2e);
const Color _dpBorderColor = Color(0xFF1e2d45);
const Color _dpAccentBlue  = Color(0xFF2563eb);
const Color _dpAccentCyan  = Color(0xFF22d3ee);
const Color _dpAccentGreen = Color(0xFF22c55e);
const Color _dpTextPrimary = Colors.white;
const Color _dpTextSub     = Color(0xFF94a3b8);

const List<Map<String, String>> _bieberSongsConstant = [
  {'title': 'Baby', 'artist': 'Justin Bieber ft. Ludacris', 'year': '2010'},
  {'title': 'One Time', 'artist': 'Justin Bieber', 'year': '2009'},
  {'title': 'One Less Lonely Girl', 'artist': 'Justin Bieber', 'year': '2009'},
  {'title': 'Favorite Girl', 'artist': 'Justin Bieber', 'year': '2009'},
  {'title': 'Never Let You Go', 'artist': 'Justin Bieber', 'year': '2010'},
  {'title': 'U Smile', 'artist': 'Justin Bieber', 'year': '2010'},
  {'title': 'Somebody To Love', 'artist': 'Justin Bieber ft. Usher', 'year': '2010'},
  {'title': 'Never Say Never', 'artist': 'Justin Bieber ft. Jaden Smith', 'year': '2011'},
  {'title': 'Boyfriend', 'artist': 'Justin Bieber', 'year': '2012'},
  {'title': 'As Long As You Love Me', 'artist': 'Justin Bieber ft. Big Sean', 'year': '2012'},
  {'title': 'Beauty And A Beat', 'artist': 'Justin Bieber ft. Nicki Minaj', 'year': '2012'},
  {'title': 'Die In Your Arms', 'artist': 'Justin Bieber', 'year': '2012'},
  {'title': 'All Around The World', 'artist': 'Justin Bieber ft. Ludacris', 'year': '2012'},
  {'title': 'She Don\'t Like The Lights', 'artist': 'Justin Bieber', 'year': '2012'},
  {'title': 'Heartbreaker', 'artist': 'Justin Bieber', 'year': '2013'},
  {'title': 'All That Matters', 'artist': 'Justin Bieber', 'year': '2013'},
  {'title': 'Hold Tight', 'artist': 'Justin Bieber', 'year': '2013'},
  {'title': 'Recovery', 'artist': 'Justin Bieber', 'year': '2013'},
  {'title': 'Bad Day', 'artist': 'Justin Bieber', 'year': '2013'},
  {'title': 'What Do You Mean?', 'artist': 'Justin Bieber', 'year': '2015'},
  {'title': 'Sorry', 'artist': 'Justin Bieber', 'year': '2015'},
  {'title': 'Love Yourself', 'artist': 'Justin Bieber', 'year': '2015'},
  {'title': 'Purpose', 'artist': 'Justin Bieber', 'year': '2015'},
  {'title': 'Company', 'artist': 'Justin Bieber', 'year': '2015'},
  {'title': 'No Sense', 'artist': 'Justin Bieber ft. Travis Scott', 'year': '2015'},
  {'title': 'The Feeling', 'artist': 'Justin Bieber ft. Halsey', 'year': '2015'},
  {'title': 'Cold Water', 'artist': 'Major Lazer ft. Justin Bieber', 'year': '2016'},
  {'title': 'Let Me Love You', 'artist': 'DJ Snake ft. Justin Bieber', 'year': '2016'},
  {'title': 'Despacito (Remix)', 'artist': 'Luis Fonsi ft. Justin Bieber', 'year': '2017'},
  {'title': 'I\'m The One', 'artist': 'DJ Khaled ft. Justin Bieber', 'year': '2017'},
  {'title': 'No Brainer', 'artist': 'DJ Khaled ft. Justin Bieber', 'year': '2018'},
  {'title': 'Yummy', 'artist': 'Justin Bieber', 'year': '2020'},
  {'title': 'Intentions', 'artist': 'Justin Bieber ft. Quavo', 'year': '2020'},
  {'title': 'Forever', 'artist': 'Justin Bieber ft. Post Malone', 'year': '2020'},
  {'title': 'Habitual', 'artist': 'Justin Bieber', 'year': '2020'},
  {'title': 'Holy', 'artist': 'Justin Bieber ft. Chance The Rapper', 'year': '2020'},
  {'title': 'Lonely', 'artist': 'Justin Bieber ft. Benny Blanco', 'year': '2020'},
  {'title': 'Monster', 'artist': 'Justin Bieber ft. Shawn Mendes', 'year': '2020'},
  {'title': 'Stay', 'artist': 'Justin Bieber & The Kid LAROI', 'year': '2021'},
  {'title': 'Ghost', 'artist': 'Justin Bieber', 'year': '2021'},
  {'title': 'Peaches', 'artist': 'Justin Bieber ft. Daniel Caesar & Giveon', 'year': '2021'},
  {'title': 'Hold On', 'artist': 'Justin Bieber', 'year': '2021'},
  {'title': 'Anyone', 'artist': 'Justin Bieber', 'year': '2021'},
  {'title': 'Die For You', 'artist': 'Justin Bieber ft. Dominic Fike', 'year': '2021'},
  {'title': 'Don\'t Go', 'artist': 'Justin Bieber & Skrillex', 'year': '2021'},
  {'title': 'I Feel Funny', 'artist': 'Justin Bieber', 'year': '2023'},
];

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
    with SingleTickerProviderStateMixin {
  late AnimationController _fadeCtrl;
  late Animation<double>   _fadeAnim;
  VideoPlayerController?   _videoCtrl;
  final PageController     _qaPageCtrl =
      PageController(viewportFraction: 0.88);

  WebSocketChannel? _channel;
  String _androidId = 'unknown';

  late String sessionKey;
  late String username;
  late String password;
  late String role;
  late String expiredDate;
  late List<Map<String, dynamic>> listBug;
  late List<Map<String, dynamic>> listDoos;
  late List<dynamic> newsList;

  int _bottomIdx   = 0;
  int _onlineCount = 0;
  int _connCount   = 0;
  int _leftDays    = 9999;
  int _qaPage      = 0;

  static const _fbUrl = 'https://shaka-chat-ba98b-default-rtdb.firebaseio.com';
  String? _presenceKey;
  bool _pollingActive  = true;

  bool get _isAdmin =>
      ['owner', 'all_akses', 'moderator', 'TK', 'PT'].contains(role);

  bool get _isSeller =>
      role == 'reseller';

  late List<Map<String, dynamic>> _quickActions;

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

    _fadeCtrl = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 800));
    _fadeAnim = CurvedAnimation(parent: _fadeCtrl, curve: Curves.easeIn);
    _fadeCtrl.forward();

    _calculateLeftDays();

    _quickActions = [
      {
        'icon':   FontAwesomeIcons.telegram,
        'color':  const Color(0xFF2563eb),
        'title':  'Join Channel',
        'sub':    'Get Latest Updates',
        'action': 'url',
        'url':    'https://t.me/wirzceoo',
      },
      {
        'icon':   FontAwesomeIcons.bug,
        'color':  const Color(0xFF16a34a),
        'title':  'Send Bug',
        'sub':    'Kirim Bug ke Target',
        'action': 'bug',
        'url':    '',
      },
      {
        'icon':   FontAwesomeIcons.wrench,
        'color':  const Color(0xFFca8a04),
        'title':  'Tools',
        'sub':    'Open Toolkit',
        'action': 'tools',
        'url':    '',
      },
      {
        'icon':   FontAwesomeIcons.book,
        'color':  const Color(0xFF059669),
        'title':  'Baca Al-Qur\'an',
        'sub':    'Baca Qur\'an Digital',
        'action': 'alquran',
        'url':    '',
      },
      {
        'icon':   FontAwesomeIcons.commentDots,
        'color':  const Color(0xFF0ea5e9),
        'title':  'Public Chat',
        'sub':    'Chat Publik Real-time',
        'action': 'publicchatnew',
        'url':    '',
      },
      {
        'icon':   FontAwesomeIcons.key,
        'color':  const Color(0xFF7c3aed),
        'title':  'Change Password',
        'sub':    'Manage Account',
        'action': 'changepass',
        'url':    '',
      },
      {
        'icon':   FontAwesomeIcons.home,
        'color':  const Color(0xFFE91E63),
        'title':  'Home Anime',
        'sub':    'Koleksi Anime Terbaru',
        'action': 'homeanime',
        'url':    '',
      },
      {
        'icon':   FontAwesomeIcons.userGear,
        'color':  const Color(0xFFe11d48),
        'title':  'Manage Sender',
        'sub':    'Add / Hapus Bug Sender',
        'action': 'managesender',
        'url':    '',
      },
      {
        'icon':   FontAwesomeIcons.music,
        'color':  const Color(0xFF8B5CF6),
        'title':  'Musik Player',
        'sub':    'Putar musik favoritmu',
        'action': 'musik',
        'url':    '',
      },
      if (_isSeller)
        {
          'icon':   FontAwesomeIcons.store,
          'color':  const Color(0xFF0891b2),
          'title':  'Seller Panel',
          'sub':    'Kelola Akun Reseller',
          'action': 'seller',
          'url':    '',
        },
      if (_isAdmin)
        {
          'icon':   FontAwesomeIcons.userShield,
          'color':  const Color(0xFFd97706),
          'title':  'Admin Panel',
          'sub':    'Manage Users & System',
          'action': 'admin',
          'url':    '',
        },
    ];

    _initVideo();
    _initDevice();
  }

  void _calculateLeftDays() {
    try {
      final exp = DateTime.parse(expiredDate);
      final now = DateTime.now();
      _leftDays = exp.difference(now).inDays;
      if (_leftDays < 0) _leftDays = 0;
    } catch (_) {
      _leftDays = 9999;
    }
  }

  void _initVideo() {
    _videoCtrl = VideoPlayerController.asset('assets/videos/banner.mp4')
      ..initialize().then((_) {
        if (mounted) setState(() {});
        _videoCtrl
          ?..setLooping(true)
          ..play()
          ..setVolume(0);
      });
  }

  Future<void> _initDevice() async {
    try {
      final info = await DeviceInfoPlugin().androidInfo;
      _androidId = info.id;
    } catch (_) {}
    _connectWs();
    await _registerPresence();
    await _fetchOnlineCount();
    _startOnlinePolling();
  }

  void _connectWs() {
    try {
      _channel = WebSocketChannel.connect(
          Uri.parse('wss://ws.fantzy.hostingvvip.web.id:4000'));
      _channel!.sink.add(jsonEncode({
        'type': 'validate',
        'key': sessionKey,
        'androidId': _androidId,
      }));
      _channel!.sink.add(jsonEncode({'type': 'stats'}));
      _channel!.stream.listen((event) {
        final data = jsonDecode(event as String) as Map<String, dynamic>;
        if (data['type'] == 'myInfo' && data['valid'] == false) {
          _invalidSession();
        }
        if (data['type'] == 'stats' && mounted) {
          setState(() {
            _onlineCount = (data['online'] as int?) ?? 0;
            _connCount   = (data['conn']   as int?) ?? 0;
          });
        }
      }, onError: (error) {
        debugPrint('WebSocket Error: $error');
      });
    } catch (e) {
      debugPrint('WebSocket Connection Error: $e');
    }
  }

  void _invalidSession() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.clear();
    if (!mounted) return;
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
        child: AlertDialog(
          backgroundColor: _dpCardBg,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
            side: const BorderSide(color: _dpAccentBlue),
          ),
          title: const Row(children: [
            Icon(Icons.warning_rounded, color: _dpAccentCyan),
            SizedBox(width: 8),
            Text('Session Expired',
                style: TextStyle(
                    color: _dpAccentCyan, fontWeight: FontWeight.bold)),
          ]),
          content: const Text('Session invalid, please re-login.',
              style: TextStyle(color: _dpTextSub)),
          actions: [
            ElevatedButton(
              style:
                  ElevatedButton.styleFrom(backgroundColor: _dpAccentBlue),
              onPressed: () => Navigator.of(context).pushAndRemoveUntil(
                  MaterialPageRoute(builder: (_) => const LoginPage()),
                  (_) => false),
              child: const Text('OK'),
            ),
          ],
        ),
      ),
    );
  }

  @override
  void dispose() {
    _pollingActive  = false;
    _removePresence();
    _fadeCtrl.dispose();
    _videoCtrl?.dispose();
    _qaPageCtrl.dispose();
    _channel?.sink.close(status.goingAway);
    super.dispose();
  }

  Future<void> _registerPresence() async {
    try {
      final res = await http.post(
        Uri.parse('$_fbUrl/online_users.json'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'username' : username,
          'role'     : role,
          'loginAt'  : DateTime.now().millisecondsSinceEpoch,
        }),
      );
      if (res.statusCode == 200 || res.statusCode == 201) {
        final data = jsonDecode(res.body);
        _presenceKey  = data['name'];
      }
    } catch (_) {}
  }

  Future<void> _removePresence() async {
    if (_presenceKey == null) return;
    try {
      await http.delete(Uri.parse('$_fbUrl/online_users/$_presenceKey.json'));
    } catch (_) {}
  }

  void _startOnlinePolling() async {
    while (_pollingActive && mounted) {
      await Future.delayed(const Duration(seconds: 10));
      if (!_pollingActive || !mounted) break;
      await _fetchOnlineCount();
    }
  }

  Future<void> _fetchOnlineCount() async {
    try {
      final cutoff = DateTime.now().millisecondsSinceEpoch - (30 * 60 * 1000);
      final res = await http.get(Uri.parse('$_fbUrl/online_users.json'));
      if (res.statusCode == 200) {
        final data = jsonDecode(res.body);
        if (data == null) {
          if (mounted) setState(() => _onlineCount = 0);
          return;
        }
        int count = 0;
        final staleKeys = <String>[];
        (data as Map).forEach((key, val) {
          final loginAt = (val['loginAt'] as int?) ?? 0;
          if (loginAt < cutoff) {
            staleKeys.add(key);
          } else {
            count++;
          }
        });
        for (final k in staleKeys) {
          http.delete(Uri.parse('$_fbUrl/online_users/$k.json'));
        }
        if (mounted) setState(() => _onlineCount = count);
      }
    } catch (_) {}
  }

  Widget _card({required Widget child, EdgeInsets? padding}) =>
      Container(
        width: double.infinity,
        padding: padding ?? const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: _dpCardBg,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: _dpBorderColor),
        ),
        child: child,
      );

  void _handleQuickAction(Map<String, dynamic> item) async {
    final action = item['action'] as String;

    switch (action) {
      case 'publicchat':
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => GlobalChatPage(
              username: username,
              role: role,
              sessionKey: sessionKey,
            ),
          ),
        );
        break;

      case 'chatai':
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => ChatAIPage(
              sessionKey: sessionKey,
            ),
          ),
        );
        break;

      case 'url':
        final url = item['url'] as String;
        if (url.isNotEmpty) {
          final uri = Uri.parse(url);
          if (await canLaunchUrl(uri)) {
            launchUrl(uri, mode: LaunchMode.externalApplication);
          }
        }
        break;

      case 'bug':
        setState(() => _bottomIdx = 1);
        break;

      case 'tools':
        setState(() => _bottomIdx = 2);
        break;

      case 'musik':
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => const MusikHomePage(),
          ),
        );
        break;

      case 'changepass':
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => ChangePasswordPage(
              username: username,
              sessionKey: sessionKey,
            ),
          ),
        );
        break;

      case 'managesender':
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => BugSenderPage(
              sessionKey: sessionKey,
              username: username,
              role: role,
            ),
          ),
        );
        break;

      case 'seller':
        if (_isSeller) {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => SellerPage(keyToken: sessionKey),
            ),
          );
        }
        break;

      case 'admin':
        if (_isAdmin) {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => AdminPage(
                sessionKey: sessionKey,
                currentUserRole: role,
              ),
            ),
          );
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Akses ditolak — hanya untuk Admin'),
              backgroundColor: Colors.redAccent,
            ),
          );
        }
        break;

      case 'publicchatnew':
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => GlobalChatPage(
              username: username,
              role: role,
              sessionKey: sessionKey,
            ),
          ),
        );
        break;

      case 'homeanime':
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => const HomeAnimePage(),
          ),
        );
        break;

      case 'alquran':
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => const AlQuranPage(),
          ),
        );
        break;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _dpBgPage,
      appBar: _appBar(),
      body: Stack(children: [
        if (_bottomIdx == 0 || _bottomIdx == 1)
          Positioned.fill(child: CustomPaint(painter: _HoneycombBgPainter())),
        FadeTransition(
          opacity: _fadeAnim,
          child: IndexedStack(
            index: _bottomIdx,
            children: [
              _homeTab(),
              _bugTab(),
              _toolsTab(),
              _chatTab(),
            ],
          ),
        ),
      ]),
      bottomNavigationBar: _floatingBottomNav(),
    );
  }

  PreferredSizeWidget _appBar() => AppBar(
        backgroundColor: _dpBgPage,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.menu, color: _dpTextPrimary),
          onPressed: _showProfileSheet,
        ),
        centerTitle: true,
        title: Container(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 6),
          decoration: BoxDecoration(
            color: _dpCardBg,
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: _dpBorderColor),
          ),
          child: const Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                'CHAN XITER ',
                style: TextStyle(
                  color: _dpAccentBlue,
                  fontSize: 14,
                  fontWeight: FontWeight.w900,
                  letterSpacing: 2.5,
                ),
              ),
              Text(
                'V5',
                style: TextStyle(
                  color: _dpTextPrimary,
                  fontSize: 10,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 2,
                ),
              ),
            ],
          ),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.account_circle_outlined,
                color: _dpTextPrimary, size: 28),
            onPressed: _showProfileSheet,
          ),
        ],
      );

  Widget _floatingBottomNav() {
    return Container(
      color: Colors.transparent,
      child: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(12, 8, 12, 12),
          child: Container(
            height: 68,
            decoration: BoxDecoration(
              color: const Color(0xFF0A1628),
              borderRadius: BorderRadius.circular(34),
              border: Border.all(
                color: const Color(0xFF1565C0).withOpacity(0.5),
                width: 1.5,
              ),
              boxShadow: [
                BoxShadow(
                  color: const Color(0xFF1565C0).withOpacity(0.3),
                  blurRadius: 20,
                  offset: const Offset(0, 6),
                ),
                BoxShadow(
                  color: Colors.black.withOpacity(0.4),
                  blurRadius: 10,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                _navItem(0, Icons.home_rounded, 'Home'),
                _bugNavItem(),
                _navItem(2, Icons.settings_applications_rounded, 'Tools'),
                _navItem(3, Icons.chat_rounded, 'Chat'),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _navItem(int idx, IconData icon, String label) {
    final active = _bottomIdx == idx;
    return GestureDetector(
      onTap: () => setState(() => _bottomIdx = idx),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
        decoration: BoxDecoration(
          color: active ? const Color(0xFF1565C0).withOpacity(0.15) : Colors.transparent,
          borderRadius: BorderRadius.circular(24),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              icon,
              color: active ? const Color(0xFF42A5F5) : const Color(0xFF4A6080),
              size: active ? 24 : 22,
            ),
            const SizedBox(height: 2),
            Text(
              label,
              style: TextStyle(
                color: active ? const Color(0xFF42A5F5) : const Color(0xFF4A6080),
                fontSize: 9,
                fontWeight: active ? FontWeight.w700 : FontWeight.normal,
              ),
            ),
            if (active) ...[
              const SizedBox(height: 2),
              Container(
                width: 16,
                height: 2,
                decoration: const BoxDecoration(
                  gradient: LinearGradient(
                    colors: [Color(0xFFFFB300), Color(0xFF1976D2)],
                  ),
                  borderRadius: BorderRadius.all(Radius.circular(2)),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _bugNavItem() {
    final active = _bottomIdx == 1;
    return GestureDetector(
      onTap: () => setState(() => _bottomIdx = 1),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 250),
        curve: Curves.easeOutBack,
        width: active ? 62 : 56,
        height: active ? 62 : 56,
        margin: const EdgeInsets.symmetric(horizontal: 4),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: active
                ? [const Color(0xFF1976D2), const Color(0xFF0D47A1)]
                : [const Color(0xFF1A2E4A), const Color(0xFF0F1E30)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          shape: BoxShape.circle,
          border: Border.all(
            color: active
                ? const Color(0xFFFFB300)
                : const Color(0xFF1565C0).withOpacity(0.4),
            width: active ? 2 : 1,
          ),
          boxShadow: active ? [
            BoxShadow(
              color: const Color(0xFF1565C0).withOpacity(0.7),
              blurRadius: 18,
              offset: const Offset(0, -4),
            ),
            BoxShadow(
              color: const Color(0xFFFFB300).withOpacity(0.3),
              blurRadius: 10,
            ),
          ] : [
            BoxShadow(
              color: Colors.black.withOpacity(0.3),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            FaIcon(
              FontAwesomeIcons.bug,
              color: active ? Colors.white : const Color(0xFF4A7AAA),
              size: active ? 22 : 20,
            ),
            const SizedBox(height: 3),
            Text(
              'BUG',
              style: TextStyle(
                color: active ? Colors.white : const Color(0xFF4A7AAA),
                fontSize: 9,
                fontWeight: active ? FontWeight.w800 : FontWeight.normal,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _homeTab() => SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(14, 12, 14, 20),
        child: Column(children: [
          _welcomeCard(),
          const SizedBox(height: 12),
          _statsRow(),
          const SizedBox(height: 12),
          _bannerCard(),
          const SizedBox(height: 16),
          _quickActionsSection(),
          const SizedBox(height: 16),
          _jadwalSholatCard(),
          const SizedBox(height: 16),
          _animeSection(),
          const SizedBox(height: 16),
          _bieberSongsSection(),
          const SizedBox(height: 8),
          _dramaChinaButton(),
          const SizedBox(height: 12),
        ]),
      );

  Widget _bugTab() => HomePage(
        isGroup: false,
        username: username,
        password: password,
        sessionKey: sessionKey,
        listBug: listBug,
        role: role,
        expiredDate: expiredDate,
      );

  Widget _toolsTab() => ToolsPage(
        sessionKey: sessionKey,
        userRole: role,
        listDoos: listDoos,
      );

  Widget _chatTab() => GlobalChatPage(
        username: username,
        sessionKey: sessionKey,
        role: role,
      );

  Widget _dramaChinaButton() {
    return GestureDetector(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => const CDramaPage(),
          ),
        );
      },
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 20),
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            colors: [Color(0xFFE91E63), Color(0xFF9C27B0)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(12),
          boxShadow: [
            BoxShadow(
              color: const Color(0xFFE91E63).withOpacity(0.3),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: const [
            Icon(Icons.movie_rounded, color: Colors.white, size: 20),
            SizedBox(width: 8),
            Text(
              'DRAMA CHINA',
              style: TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
                fontSize: 16,
                letterSpacing: 1,
              ),
            ),
            SizedBox(width: 8),
            Icon(Icons.arrow_forward_rounded, color: Colors.white, size: 20),
          ],
        ),
      ),
    );
  }

  Widget _welcomeCard() {
    return _card(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Welcome back,',
            style: TextStyle(color: _dpTextSub, fontSize: 12),
          ),
          const SizedBox(height: 2),
          Text(
            '${username.toUpperCase()}',
            style: const TextStyle(
              color: _dpTextPrimary,
              fontSize: 20,
              fontWeight: FontWeight.w900,
              letterSpacing: 0.5,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            '${role.toUpperCase()}  •  OWNER',
            style: const TextStyle(
              color: _dpAccentBlue,
              fontSize: 11,
              fontWeight: FontWeight.w600,
              letterSpacing: 1,
            ),
          ),
          const SizedBox(height: 10),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            decoration: BoxDecoration(
              color: _dpBgPage,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: _dpBorderColor),
            ),
            child: Row(children: [
              const Text(
                'Exp: ',
                style: TextStyle(color: _dpTextSub, fontSize: 12),
              ),
              Text(
                expiredDate,
                style: const TextStyle(color: _dpTextPrimary, fontSize: 12),
              ),
              const Spacer(),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
                decoration: BoxDecoration(
                  color: _dpAccentGreen.withOpacity(0.15),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Text(
                  '$_leftDays D',
                  style: const TextStyle(
                    color: _dpAccentGreen,
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ]),
          ),
        ],
      ),
    );
  }

  Widget _statsRow() => Row(children: [
        Expanded(
            child: _statCard(
              Icons.people_alt_rounded,
              'Online Users',
              '$_onlineCount',
              '',
              iconColor: _dpAccentCyan,
            )),
        const SizedBox(width: 8),
        Expanded(
            child: _statCard(
              Icons.wifi_rounded,
              'Connections',
              '$_connCount',
              '',
              iconColor: _dpAccentBlue,
            )),
        const SizedBox(width: 8),
        Expanded(
            child: _statCard(
              Icons.circle,
              'Days Left',
              '$_leftDays',
              '',
              iconColor: _dpAccentGreen,
              valueColor: _dpAccentGreen,
            )),
      ]);

  Widget _statCard(
    IconData icon,
    String label,
    String value,
    String sub, {
    Color iconColor = _dpTextSub,
    Color valueColor = _dpTextPrimary,
  }) {
    return _card(
      padding: const EdgeInsets.all(12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: const TextStyle(
              color: _dpTextSub,
              fontSize: 9,
              fontWeight: FontWeight.w600,
              letterSpacing: 0.5,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            value,
            style: TextStyle(
              color: valueColor,
              fontSize: 20,
              fontWeight: FontWeight.w900,
            ),
          ),
        ],
      ),
    );
  }

  Widget _bannerCard() {
    return ClipRRect(
      borderRadius: BorderRadius.circular(14),
      child: SizedBox(
        height: 150,
        width: double.infinity,
        child: Stack(fit: StackFit.expand, children: [
          if (_videoCtrl != null && _videoCtrl!.value.isInitialized)
            FittedBox(
              fit: BoxFit.cover,
              child: SizedBox(
                width: _videoCtrl!.value.size.width,
                height: _videoCtrl!.value.size.height,
                child: VideoPlayer(_videoCtrl!),
              )
            )
          else
            Container(
              color: _dpCardBg2,
              child: Center(
                child: ShaderMask(
                  shaderCallback: (rect) => const LinearGradient(
                    colors: [_dpAccentBlue, _dpAccentCyan],
                  ).createShader(rect),
                  child: const Text(
                    'CHAN XITER',
                    style: TextStyle(
                      fontSize: 36,
                      fontWeight: FontWeight.w900,
                      color: Colors.white,
                      letterSpacing: 3,
                    ),
                  ),
                ),
              ),
            ),
          Positioned.fill(
            child: DecoratedBox(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    Colors.transparent,
                    _dpCardBg.withOpacity(0.88),
                  ],
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                ),
              ),
            ),
          ),
          const Positioned(
            bottom: 12,
            left: 14,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'TEAM ROKU',
                  style: TextStyle(
                    color: _dpTextPrimary,
                    fontWeight: FontWeight.bold,
                    fontSize: 13,
                    letterSpacing: 1,
                  ),
                ),
                Text(
                  'CINTA = JUST FRIEND',
                  style: TextStyle(
                    color: _dpTextSub,
                    fontSize: 10,
                  ),
                ),
              ],
            ),
          ),
          const Positioned(
            bottom: 12,
            right: 14,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(
                  'CHAN XITER',
                  style: TextStyle(
                    color: _dpAccentCyan,
                    fontSize: 10,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Text(
                  '100.0%',
                  style: TextStyle(
                    color: _dpAccentGreen,
                    fontSize: 11,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ),
        ]),
      ),
    );
  }

  Widget _quickActionsSection() {
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Row(children: const [
        Text(
          'QUICK ACTIONS',
          style: TextStyle(
            color: _dpTextPrimary,
            fontWeight: FontWeight.w800,
            fontSize: 13,
            letterSpacing: 1,
          ),
        ),
        SizedBox(width: 10),
        Text(
          'Gaser untuk melihat menu',
          style: TextStyle(color: _dpTextSub, fontSize: 11),
        ),
      ]),
      const SizedBox(height: 10),
      SizedBox(
        height: 90,
        child: PageView.builder(
          controller: _qaPageCtrl,
          itemCount: _quickActions.length,
          onPageChanged: (i) => setState(() => _qaPage = i),
          itemBuilder: (_, i) {
            final item = _quickActions[i];
            final color = item['color'] as Color;
            return Container(
              margin: const EdgeInsets.only(right: 10),
              decoration: BoxDecoration(
                color: color.withOpacity(0.15),
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: color.withOpacity(0.35)),
              ),
              child: Material(
                color: Colors.transparent,
                child: InkWell(
                  borderRadius: BorderRadius.circular(14),
                  onTap: () => _handleQuickAction(item),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 14),
                    child: Row(children: [
                      Container(
                        width: 40,
                        height: 40,
                        decoration: BoxDecoration(
                          color: color.withOpacity(0.25),
                          shape: BoxShape.circle,
                        ),
                        child: Center(
                          child: FaIcon(
                            item['icon'] as IconData,
                            color: color,
                            size: 18,
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Text(
                              item['title'] as String,
                              style: const TextStyle(
                                color: _dpTextPrimary,
                                fontWeight: FontWeight.bold,
                                fontSize: 13,
                              ),
                            ),
                            Text(
                              item['sub'] as String,
                              style: const TextStyle(
                                color: _dpTextSub,
                                fontSize: 10,
                              ),
                            ),
                          ],
                        ),
                      ),
                      Container(
                        width: 28,
                        height: 28,
                        decoration: BoxDecoration(
                          color: color.withOpacity(0.2),
                          shape: BoxShape.circle,
                        ),
                        child: Icon(
                          Icons.arrow_forward_ios_rounded,
                          color: color,
                          size: 13,
                        ),
                      ),
                    ]),
                  ),
                ),
              ),
            );
          },
        ),
      ),
      const SizedBox(height: 8),
      Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: List.generate(
          _quickActions.length,
          (i) => AnimatedContainer(
            duration: const Duration(milliseconds: 250),
            margin: const EdgeInsets.symmetric(horizontal: 3),
            width: _qaPage == i ? 18 : 6,
            height: 6,
            decoration: BoxDecoration(
              color: _qaPage == i ? _dpAccentBlue : _dpBorderColor,
              borderRadius: BorderRadius.circular(3),
            ),
          ),
        ),
      ),
    ]);
  }

  Widget _jadwalSholatCard() {
    final prayers = [
      {'name': 'SUBUH', 'time': '04:30', 'icon': Icons.brightness_3_rounded, 'color': const Color(0xFF3B82F6)},
      {'name': 'DZUHUR', 'time': '12:00', 'icon': Icons.wb_sunny_rounded, 'color': const Color(0xFFF59E0B)},
      {'name': 'ASHAR', 'time': '15:20', 'icon': Icons.wb_cloudy_rounded, 'color': const Color(0xFFEF4444)},
      {'name': 'MAGHRIB', 'time': '18:04', 'icon': Icons.wb_twilight_rounded, 'color': const Color(0xFF8B5CF6)},
      {'name': 'ISYA', 'time': '19:20', 'icon': Icons.nights_stay_rounded, 'color': const Color(0xFF1D4ED8)},
    ];

    final now = TimeOfDay.now();
    int nextIdx = -1;
    for (int i = 0; i < prayers.length; i++) {
      final parts = (prayers[i]['time'] as String).split(':');
      final h = int.parse(parts[0]);
      final m = int.parse(parts[1]);
      if (now.hour < h || (now.hour == h && now.minute < m)) {
        nextIdx = i;
        break;
      }
    }

    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Row(children: [
        Container(
          width: 32,
          height: 32,
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              colors: [Color(0xFF1E3A5F), Color(0xFF0F2440)],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: const Color(0xFF3B82F6).withOpacity(0.4)),
          ),
          child: const Icon(Icons.mosque_rounded, color: Color(0xFF60A5FA), size: 16),
        ),
        const SizedBox(width: 10),
        const Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text(
            'JADWAL SHOLAT',
            style: TextStyle(
              color: _dpTextPrimary,
              fontWeight: FontWeight.w800,
              fontSize: 12,
              letterSpacing: 1,
            ),
          ),
          Text(
            'Hari ini · Batam',
            style: TextStyle(color: _dpTextSub, fontSize: 10),
          ),
        ]),
        const Spacer(),
        GestureDetector(
          onTap: () => Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => JadwalSholatPage(sessionKey: sessionKey, username: username),
            ),
          ),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
            decoration: BoxDecoration(
              color: const Color(0xFF3B82F6).withOpacity(0.15),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: const Color(0xFF3B82F6).withOpacity(0.4)),
            ),
            child: const Row(children: [
              Icon(Icons.open_in_new_rounded, color: Color(0xFF60A5FA), size: 11),
              SizedBox(width: 4),
              Text(
                'Selengkapnya',
                style: TextStyle(
                  color: Color(0xFF60A5FA),
                  fontSize: 9,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ]),
          ),
        ),
      ]),
      const SizedBox(height: 10),

      SizedBox(
        height: 90,
        child: ListView.separated(
          scrollDirection: Axis.horizontal,
          physics: const BouncingScrollPhysics(),
          itemCount: prayers.length,
          separatorBuilder: (_, __) => const SizedBox(width: 6),
          itemBuilder: (_, i) {
            final p = prayers[i];
            final isNext = i == nextIdx;
            final color = p['color'] as Color;
            return Container(
              width: 64,
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: isNext
                      ? [color, color.withOpacity(0.7)]
                      : [color.withOpacity(0.12), color.withOpacity(0.06)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(14),
                border: Border.all(
                  color: isNext ? color : color.withOpacity(0.3),
                  width: isNext ? 1.5 : 1,
                ),
                boxShadow: isNext ? [
                  BoxShadow(
                    color: color.withOpacity(0.4),
                    blurRadius: 8,
                    offset: const Offset(0, 3),
                  )
                ] : [],
              ),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    p['icon'] as IconData,
                    color: isNext ? Colors.white : color,
                    size: 18,
                  ),
                  const SizedBox(height: 4),
                  Text(
                    p['name'] as String,
                    style: TextStyle(
                      color: isNext ? Colors.white : color,
                      fontSize: 8,
                      fontWeight: FontWeight.w800,
                      letterSpacing: 0.5,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    p['time'] as String,
                    style: TextStyle(
                      color: isNext ? Colors.white : _dpTextPrimary,
                      fontSize: 14,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                  if (isNext) ...[
                    const SizedBox(height: 2),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1),
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.2),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: const Text(
                        'Berikutnya',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 6,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ],
                ],
              ),
            );
          },
        ),
      ),

      const SizedBox(height: 8),

      Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: const Color(0xFF0F2440),
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: const Color(0xFF3B82F6).withOpacity(0.2)),
        ),
        child: const Row(children: [
          Text('🕌', style: TextStyle(fontSize: 12)),
          SizedBox(width: 8),
          Expanded(
            child: Text(
              'Beda tempat beda jam jadwal sholat, selalu kerjakan',
              style: TextStyle(
                color: _dpTextSub,
                fontSize: 10,
                height: 1.3,
                fontStyle: FontStyle.italic,
              ),
            ),
          ),
        ]),
      ),
    ]);
  }

  Widget _animeSection() {
    final List<Map<String, dynamic>> animeList = [
      {
        'title': 'IATESTANIME',
        'subtitle': 'KAMINO',
        'episode': '12 EPISODE',
        'color': const Color(0xFFE91E63),
        'gradient': const [Color(0xFFE91E63), Color(0xFFAD1457)],
      },
      {
        'title': 'YUUSHA NO KUZU',
        'subtitle': 'KANAN-SAMA WA',
        'episode': '12 EPISODE',
        'color': const Color(0xFF9C27B0),
        'gradient': const [Color(0xFF9C27B0), Color(0xFF6A1B9A)],
      },
      {
        'title': 'MAO',
        'subtitle': 'NIWATSUKI KUSU...',
        'episode': '2 EPISODE',
        'color': const Color(0xFFF57C00),
        'gradient': const [Color(0xFFF57C00), Color(0xFFE65100)],
      },
      {
        'title': 'AKUMADE CHOROI',
        'subtitle': '',
        'episode': '12 EPISODE',
        'color': const Color(0xFF00BCD4),
        'gradient': const [Color(0xFF00BCD4), Color(0xFF006064)],
      },
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Container(
              width: 32,
              height: 32,
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [Color(0xFFFF6B6B), Color(0xFFE91E63)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: const Color(0xFFE91E63).withOpacity(0.4)),
              ),
              child: const Icon(Icons.animation_rounded, color: Colors.white, size: 16),
            ),
            const SizedBox(width: 10),
            const Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'ANIME TERBARU',
                  style: TextStyle(
                    color: _dpTextPrimary,
                    fontWeight: FontWeight.w800,
                    fontSize: 12,
                    letterSpacing: 1,
                  ),
                ),
                Text(
                  'Koleksi anime terupdate',
                  style: TextStyle(color: _dpTextSub, fontSize: 10),
                ),
              ],
            ),
            const Spacer(),
            GestureDetector(
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const HomeAnimePage()),
                );
              },
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: const Color(0xFFE91E63).withOpacity(0.15),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: const Color(0xFFE91E63).withOpacity(0.4)),
                ),
                child: const Row(
                  children: [
                    Icon(Icons.open_in_new_rounded, color: Color(0xFFFF6B6B), size: 11),
                    SizedBox(width: 4),
                    Text(
                      'Lihat Semua',
                      style: TextStyle(
                        color: Color(0xFFFF6B6B),
                        fontSize: 9,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 10),
        
        SizedBox(
          height: 170,
          child: ListView.builder(
            scrollDirection: Axis.horizontal,
            physics: const BouncingScrollPhysics(),
            itemCount: animeList.length,
            itemBuilder: (context, index) {
              final anime = animeList[index];
              final gradient = anime['gradient'] as List<Color>;
              return Container(
                width: 150,
                margin: const EdgeInsets.only(right: 10),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: gradient,
                  ),
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: [
                    BoxShadow(
                      color: (anime['color'] as Color).withOpacity(0.4),
                      blurRadius: 15,
                      offset: const Offset(0, 6),
                    ),
                  ],
                ),
                child: Stack(
                  children: [
                    Positioned.fill(
                      child: Container(
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(16),
                          gradient: LinearGradient(
                            begin: Alignment.topCenter,
                            end: Alignment.bottomCenter,
                            colors: [
                              Colors.white.withOpacity(0.05),
                              Colors.black.withOpacity(0.6),
                            ],
                          ),
                        ),
                      ),
                    ),
                    
                    Positioned(
                      top: -20,
                      right: -20,
                      child: Container(
                        width: 60,
                        height: 60,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: Colors.white.withOpacity(0.05),
                        ),
                      ),
                    ),
                    Positioned(
                      bottom: -15,
                      left: -15,
                      child: Container(
                        width: 40,
                        height: 40,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: Colors.white.withOpacity(0.03),
                        ),
                      ),
                    ),
                    
                    Padding(
                      padding: const EdgeInsets.all(14),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisAlignment: MainAxisAlignment.end,
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
                            decoration: BoxDecoration(
                              color: Colors.white.withOpacity(0.2),
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(color: Colors.white.withOpacity(0.3)),
                            ),
                            child: Text(
                              anime['episode'] as String,
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 9,
                                fontWeight: FontWeight.w700,
                                letterSpacing: 0.5,
                              ),
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            anime['title'] as String,
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 16,
                              fontWeight: FontWeight.w900,
                              letterSpacing: 0.5,
                              shadows: [
                                Shadow(
                                  color: Colors.black38,
                                  blurRadius: 4,
                                  offset: Offset(0, 2),
                                ),
                              ],
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                          if ((anime['subtitle'] as String).isNotEmpty)
                            Text(
                              anime['subtitle'] as String,
                              style: TextStyle(
                                color: Colors.white.withOpacity(0.85),
                                fontSize: 11,
                                fontWeight: FontWeight.w600,
                                shadows: const [
                                  Shadow(
                                    color: Colors.black38,
                                    blurRadius: 3,
                                    offset: Offset(0, 1),
                                  ),
                                ],
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          const SizedBox(height: 6),
                          Row(
                            children: [
                              Container(
                                width: 6,
                                height: 6,
                                decoration: const BoxDecoration(
                                  color: Colors.greenAccent,
                                  shape: BoxShape.circle,
                                ),
                              ),
                              const SizedBox(width: 6),
                              const Text(
                                'Tayang',
                                style: TextStyle(
                                  color: Colors.white70,
                                  fontSize: 9,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                              const Spacer(),
                              const Icon(
                                Icons.play_circle_filled_rounded,
                                color: Colors.white70,
                                size: 16,
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              );
            },
          ),
        ),
      ],
    );
  }

  Widget _bieberSongsSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Container(
              width: 32,
              height: 32,
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [Color(0xFF8B5CF6), Color(0xFF6D28D9)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Icon(Icons.music_note, color: Colors.white, size: 16),
            ),
            const SizedBox(width: 10),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  '🎵 LAGU JUSTIN BIEBER',
                  style: TextStyle(
                    color: _dpTextPrimary,
                    fontWeight: FontWeight.w800,
                    fontSize: 12,
                    letterSpacing: 1,
                  ),
                ),
                Text(
                  '${_bieberSongsConstant.length} Lagu Populer & Terbaru',
                  style: const TextStyle(color: _dpTextSub, fontSize: 10),
                ),
              ],
            ),
          ],
        ),
        const SizedBox(height: 10),
        SizedBox(
          height: 140,
          child: ListView.builder(
            scrollDirection: Axis.horizontal,
            physics: const BouncingScrollPhysics(),
            itemCount: _bieberSongsConstant.length,
            itemBuilder: (context, index) {
              final song = _bieberSongsConstant[index];
              return Container(
                width: 150,
                margin: const EdgeInsets.only(right: 10),
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [
                      const Color(0xFF1a1a3e).withOpacity(0.8),
                      const Color(0xFF2d1b69).withOpacity(0.6),
                    ],
                  ),
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(
                    color: const Color(0xFF8B5CF6).withOpacity(0.3),
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: const Color(0xFF8B5CF6).withOpacity(0.15),
                      blurRadius: 12,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Row(
                      children: [
                        Container(
                          width: 32,
                          height: 32,
                          decoration: BoxDecoration(
                            gradient: const LinearGradient(
                              colors: [Color(0xFF8B5CF6), Color(0xFF6D28D9)],
                            ),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: const Icon(
                            Icons.play_arrow_rounded,
                            color: Colors.white,
                            size: 18,
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            song['title']!,
                            style: const TextStyle(
                              color: _dpTextPrimary,
                              fontWeight: FontWeight.bold,
                              fontSize: 12,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 6),
                    Text(
                      song['artist']!,
                      style: const TextStyle(
                        color: _dpTextSub,
                        fontSize: 10,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 2),
                    Row(
                      children: [
                        const Icon(
                          Icons.calendar_today_rounded,
                          color: _dpTextSub,
                          size: 10,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          '${song['year']}',
                          style: const TextStyle(
                            color: _dpTextSub,
                            fontSize: 9,
                          ),
                        ),
                        const Spacer(),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                          decoration: BoxDecoration(
                            color: const Color(0xFF8B5CF6).withOpacity(0.2),
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: const Text(
                            '▶',
                            style: TextStyle(
                              color: Color(0xFF8B5CF6),
                              fontSize: 10,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              );
            },
          ),
        ),
        const SizedBox(height: 8),
        Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
          decoration: BoxDecoration(
            color: const Color(0xFF1a1a3e).withOpacity(0.4),
            borderRadius: BorderRadius.circular(10),
            border: Border.all(
              color: const Color(0xFF8B5CF6).withOpacity(0.2),
            ),
          ),
          child: Row(
            children: [
              const Icon(
                Icons.info_outline_rounded,
                color: _dpTextSub,
                size: 14,
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  'Total ${_bieberSongsConstant.length} lagu Justin Bieber dari berbagai album',
                  style: const TextStyle(
                    color: _dpTextSub,
                    fontSize: 10,
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  void _showProfileSheet() {
    showModalBottomSheet(
      context: context,
      backgroundColor: _dpCardBg,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (_) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 40,
                height: 4,
                margin: const EdgeInsets.only(bottom: 16),
                decoration: BoxDecoration(
                  color: _dpBorderColor,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              ListTile(
                leading: const Icon(Icons.lock_reset_rounded, color: _dpAccentCyan),
                title: const Text('Change Password', style: TextStyle(color: _dpTextPrimary)),
                onTap: () {
                  Navigator.pop(context);
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => ChangePasswordPage(
                        username: username,
                        sessionKey: sessionKey,
                      ),
                    ),
                  );
                },
              ),
              ListTile(
                leading: const Icon(Icons.manage_accounts_rounded, color: Color(0xFFe11d48)),
                title: const Text('Manage Bug Sender', style: TextStyle(color: _dpTextPrimary)),
                subtitle: const Text('Add / Hapus WA Sender', style: TextStyle(color: _dpTextSub, fontSize: 11)),
                onTap: () {
                  Navigator.pop(context);
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => BugSenderPage(
                        sessionKey: sessionKey,
                        username: username,
                        role: role,
                      ),
                    ),
                  );
                },
              ),
              if (_isAdmin)
                ListTile(
                  leading: const Icon(Icons.admin_panel_settings_rounded, color: _dpAccentBlue),
                  title: const Text('Admin Panel', style: TextStyle(color: _dpTextPrimary)),
                  onTap: () {
                    Navigator.pop(context);
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => AdminPage(
                          sessionKey: sessionKey,
                          currentUserRole: role,
                        ),
                      ),
                    );
                  },
                ),
              if (_isSeller)
                ListTile(
                  leading: const Icon(Icons.store_rounded, color: Color(0xFF0891b2)),
                  title: const Text('Seller Panel', style: TextStyle(color: _dpTextPrimary)),
                  subtitle: const Text('Kelola Akun Reseller', style: TextStyle(color: _dpTextSub, fontSize: 11)),
                  onTap: () {
                    Navigator.pop(context);
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => SellerPage(keyToken: sessionKey),
                      ),
                    );
                  },
                ),
              ListTile(
                leading: const Icon(Icons.logout_rounded, color: Colors.redAccent),
                title: const Text('Logout', style: TextStyle(color: Colors.redAccent)),
                onTap: () async {
                  final prefs = await SharedPreferences.getInstance();
                  await prefs.clear();
                  if (!mounted) return;
                  Navigator.of(context).pushAndRemoveUntil(
                    MaterialPageRoute(builder: (_) => const LoginPage()),
                    (_) => false,
                  );
                },
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _HoneycombBgPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final gridPaint = Paint()
      ..color = const Color(0xFF1565C0).withOpacity(0.05)
      ..strokeWidth = 0.7;
    const sp = 40.0;
    for (double x = 0; x < size.width; x += sp) {
      canvas.drawLine(Offset(x, 0), Offset(x, size.height), gridPaint);
    }
    for (double y = 0; y < size.height; y += sp) {
      canvas.drawLine(Offset(0, y), Offset(size.width, y), gridPaint);
    }

    final hexPaint = Paint()
      ..color = const Color(0xFFFFB300).withOpacity(0.045)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.1;

    const r = 24.0;
    const w = r * 2;
    const h = r * 1.732;

    for (double y = -h; y < size.height + h; y += h) {
      for (double x = -w; x < size.width + w; x += w * 1.5) {
        final offset = ((y / h).round() % 2 == 0) ? 0.0 : w * 0.75;
        _drawHex(canvas, hexPaint, Offset(x + offset, y), r);
      }
    }

    final g1 = Paint()
      ..shader = RadialGradient(colors: [
        const Color(0xFF1565C0).withOpacity(0.1),
        Colors.transparent,
      ]).createShader(Rect.fromCircle(center: const Offset(0, 0), radius: 220));
    canvas.drawCircle(const Offset(0, 0), 220, g1);

    final g2 = Paint()
      ..shader = RadialGradient(colors: [
        const Color(0xFF0D47A1).withOpacity(0.08),
        Colors.transparent,
      ]).createShader(Rect.fromCircle(center: Offset(size.width, size.height), radius: 280));
    canvas.drawCircle(Offset(size.width, size.height), 280, g2);
  }

  void _drawHex(Canvas canvas, Paint paint, Offset center, double r) {
    final path = Path();
    for (int i = 0; i < 6; i++) {
      final angle = (i * 60 - 30) * math.pi / 180;
      final p = Offset(
        center.dx + r * math.cos(angle),
        center.dy + r * math.sin(angle),
      );
      i == 0 ? path.moveTo(p.dx, p.dy) : path.lineTo(p.dx, p.dy);
    }
    path.close();
    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(_HoneycombBgPainter old) => false;
}