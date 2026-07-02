import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:device_info_plus/device_info_plus.dart';
import 'package:web_socket_channel/web_socket_channel.dart';
import 'package:web_socket_channel/status.dart' as status;
import 'package:url_launcher/url_launcher.dart';
import 'package:video_player/video_player.dart';
import 'package:http/http.dart' as http;
import 'dart:ui';
import 'package:audioplayers/audioplayers.dart';

import 'telegram.dart';
import 'admin_page.dart';
import 'home_page.dart';
import 'seller_page.dart';
import 'change_password_page.dart';
import 'ddos_page.dart';
import 'chat_page.dart';
import 'login_page.dart';
import 'custom_bug.dart';
import 'bug_group.dart';
import 'ddos_panel.dart';
import 'sender_page.dart';
import 'spams_page.dart';
import 'public_page.dart';
import 'device_dashboard.dart';
import 'anime.dart';
import 'quran_tool.dart';
import 'tqto_page.dart';

class DashboardPage extends StatefulWidget {
  final String username;
  final String password;
  final String role;
  final String expiredDate;
  final String sessionKey;
  final List<Map<String, dynamic>> listBug;
  final List<Map<String, dynamic>> listPayload;
  final List<Map<String, dynamic>> listDDoS;
  final List<dynamic> news;

  const DashboardPage({
    super.key,
    required this.username,
    required this.password,
    required this.role,
    required this.expiredDate,
    required this.listBug,
    required this.listPayload,
    required this.listDDoS,
    required this.sessionKey,
    required this.news,
  });

  @override
  State<DashboardPage> createState() => _DashboardPageState();
}

class _DashboardPageState extends State<DashboardPage>
    with SingleTickerProviderStateMixin, WidgetsBindingObserver {
  late AnimationController _controller;
  late Animation<double> _animation;
  late WebSocketChannel channel;

  VideoPlayerController? _videoController;
  VideoPlayerController? _statsVideoController;
  VideoPlayerController? _otaxVideoController;

  final AudioPlayer _audioPlayer = AudioPlayer();
  final String _backgroundMusicUrl = "https://k.top4top.io/m_375871wig1.m4a";

  late String sessionKey;
  late String username;
  late String password;
  late String role;
  late String expiredDate;
  late List<Map<String, dynamic>> listBug;
  late List<Map<String, dynamic>> listPayload;
  late List<Map<String, dynamic>> listDDoS;
  late List<dynamic> newsList;
  String androidId = "unknown";

  int _selectedIndex = 0;
  Widget _selectedPage = const Placeholder();

  final GlobalKey _bugButtonKey = GlobalKey();
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();

  final PageController _pageController = PageController(viewportFraction: 0.88);
  int _currentNewsIndex = 0;

  final PageController _actionPageController = PageController(viewportFraction: 0.92);
  int _currentActionIndex = 0;

  List<Map<String, dynamic>> _activityLogs = [];
  bool _isLoadingActivityLogs = false;
  bool _hasActivityLogsError = false;

  Offset _assistiveTouchPosition = const Offset(20, 150);
  bool _isAssistiveMenuOpen = false;

  bool _isBugToolsExpanded = false;
  String _activePage = 'home';

  bool _showBottomNav = true;
  bool _showAssistiveTouch = true;
  bool _isMusicOn = false;

  Map<String, dynamic>? animeData;
  bool _isLoadingAnime = true;
  
  List<Map<String, dynamic>> _newsItems = [];
  bool _isLoadingNews = false;
  String _selectedNewsSource = 'antara';
  String _selectedNewsCategory = 'terkini';
  final PageController _newsPageController = PageController(viewportFraction: 0.92);
  int _currentNewsItemIndex = 0;

  final Color _primaryColor   = const Color(0xFFB0B0C8);
  final Color _secondaryColor = const Color(0xFF787890);
  final Color _accentColor    = const Color(0xFFD0D0E8);
  final Color _successColor   = const Color(0xFF8899AA);
  final Color _warningColor   = const Color(0xFFC8B890);
  final Color _darkBg         = const Color(0xFF0C0C10);
  final Color _darkerBg       = const Color(0xFF070709);
  final Color _surfaceColor   = const Color(0xFF161620);
  final Color _cardColor      = const Color(0xFF111118);
  final Color _glowColor1     = const Color(0xFFE0E0F8);
  final Color _glowColor2     = const Color(0xFF9090B4);
  final Color _glowColor3     = const Color(0xFFBBBBD0);
  final Color _goldColor      = const Color(0xFFCCBB88);
  final Color _roseColor      = const Color(0xFFBB8899);

  final List<Map<String, dynamic>> _newsSources = [
    {'id': 'antara', 'name': 'ANTARA NEWS', 'url': 'https://api.ikyyxd.my.id/news/antara', 'icon': FontAwesomeIcons.newspaper},
    {'id': 'cnbc', 'name': 'CNBC INDONESIA', 'url': 'https://api.ikyyxd.my.id/news/cnbc', 'icon': FontAwesomeIcons.chartLine},
    {'id': 'google', 'name': 'GOOGLE NEWS', 'url': 'https://api.ikyyxd.my.id/berita/google-news', 'icon': FontAwesomeIcons.google},
  ];
  
  final List<Map<String, dynamic>> _newsCategories = [
    {'id': 'terkini', 'name': 'TERKINI', 'icon': FontAwesomeIcons.clock},
    {'id': 'terbaik', 'name': 'TERBAIK', 'icon': FontAwesomeIcons.star},
    {'id': 'terlama', 'name': 'TERLAMA', 'icon': FontAwesomeIcons.calendar},
  ];

  TextStyle _cinzel(double size, FontWeight weight, [double opacity = 1.0]) {
    return TextStyle(
      fontFamily: "CinzelDecorative",
      fontSize: size,
      fontWeight: weight,
      color: Colors.white.withOpacity(opacity),
      letterSpacing: 1.2,
    );
  }

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    SystemChrome.setEnabledSystemUIMode(SystemUiMode.immersiveSticky);

    sessionKey  = widget.sessionKey;
    username    = widget.username;
    password    = widget.password;
    role        = widget.role;
    expiredDate = widget.expiredDate;
    listBug     = widget.listBug;
    listPayload = widget.listPayload;
    listDDoS    = widget.listDDoS;
    newsList    = widget.news;

    _controller = AnimationController(
      duration: const Duration(milliseconds: 500),
      vsync: this,
    );
    _animation = CurvedAnimation(parent: _controller, curve: Curves.easeOutCubic);
    _controller.forward();

    _selectedPage = _buildNewsPage();

    _initAndroidIdAndConnect();
    _fetchActivityLogs();
    _initVideoBackground();
    _initAudioPlayer();
    _fetchAnimeData();
    _fetchNews();
  }

  Future<void> _fetchNews() async {
    setState(() {
      _isLoadingNews = true;
      _newsItems = [];
    });
    
    try {
      final source = _newsSources.firstWhere((s) => s['id'] == _selectedNewsSource);
      final response = await http.get(Uri.parse(source['url'])).timeout(const Duration(seconds: 15));
      
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        List<Map<String, dynamic>> items = [];
        
        if (data.containsKey('result') && data['result'] is List) {
          items = List<Map<String, dynamic>>.from(data['result']);
        } else if (data.containsKey('news') && data['news'] is List) {
          items = List<Map<String, dynamic>>.from(data['news']);
        } else {
          for (var key in data.keys) {
            if (data[key] is List && (data[key] as List).isNotEmpty) {
              items = List<Map<String, dynamic>>.from(data[key]);
              break;
            }
          }
        }
        
        if (_selectedNewsCategory == 'terbaik') {
          items = items.take(10).toList();
        } else if (_selectedNewsCategory == 'terlama') {
          items = items.reversed.toList();
        }
        
        setState(() {
          _newsItems = items;
          _isLoadingNews = false;
        });
      } else {
        setState(() {
          _isLoadingNews = false;
        });
        _loadDummyNews();
      }
    } catch (e) {
      setState(() {
        _isLoadingNews = false;
      });
      _loadDummyNews();
    }
  }
  
  void _loadDummyNews() {
    setState(() {
      _newsItems = [
        {'title': 'Sistem Update V4.0 Telah Rilis', 'thumbnail': '', 'link': '', 'source': 'SYSTEM'},
        {'title': 'Fitur Baru WhatsApp Crash Tersedia', 'thumbnail': '', 'link': '', 'source': 'UPDATE'},
        {'title': 'Panel Pterodactyl Siap Digunakan', 'thumbnail': '', 'link': '', 'source': 'PANEL'},
        {'title': 'DDoS Protection Diperbaharui', 'thumbnail': '', 'link': '', 'source': 'SECURITY'},
      ];
    });
  }

  Future<void> _fetchAnimeData() async {
    try {
      final response = await http.get(
        Uri.parse('https://www.sankavollerei.com/anime/home'),
      );
      if (response.statusCode == 200) {
        final jsonData = json.decode(response.body);
        if (mounted) {
          setState(() {
            animeData = jsonData['data'];
            _isLoadingAnime = false;
          });
        }
      } else {
        if (mounted) setState(() => _isLoadingAnime = false);
      }
    } catch (e) {
      debugPrint('Error fetching anime: $e');
      if (mounted) setState(() => _isLoadingAnime = false);
    }
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      _videoController?.play();
      _statsVideoController?.play();
      _otaxVideoController?.play();
    }
  }

  void _initAudioPlayer() {
    _audioPlayer.setReleaseMode(ReleaseMode.loop);
  }

  void _toggleBackgroundMusic(bool isPlaying) async {
    setState(() => _isMusicOn = isPlaying);
    if (isPlaying) {
      await _audioPlayer.play(UrlSource(_backgroundMusicUrl), volume: 0.5);
      _videoController?.setVolume(0.0);
      _statsVideoController?.setVolume(0.0);
      _otaxVideoController?.setVolume(0.0);
    } else {
      await _audioPlayer.pause();
    }
  }

  Future<void> _initVideoBackground() async {
    try {
      _videoController = VideoPlayerController.asset('assets/videos/heder.mp4');
      await _videoController!.initialize();
      _videoController!.setLooping(true);
      _videoController!.setVolume(0.0);
      await _videoController!.play();

      _statsVideoController = VideoPlayerController.asset('assets/videos/bnb.mp4');
      await _statsVideoController!.initialize();
      _statsVideoController!.setLooping(true);
      _statsVideoController!.setVolume(0.0);
      await _statsVideoController!.play();

      _otaxVideoController = VideoPlayerController.asset('assets/videos/animek.mp4');
      await _otaxVideoController!.initialize();
      _otaxVideoController!.setLooping(true);
      _otaxVideoController!.setVolume(0.0);
      await _otaxVideoController!.play();

      if (mounted) setState(() {});
    } catch (e) {
      debugPrint("Gagal memuat video background: $e");
    }
  }

  void _toggleStatsVideo() {
    setState(() {
      if (_statsVideoController != null) {
        if (_statsVideoController!.value.isPlaying) {
          _statsVideoController!.pause();
        } else {
          _statsVideoController!.play();
        }
      }
    });
  }

  Future<void> _initAndroidIdAndConnect() async {
    final deviceInfo = await DeviceInfoPlugin().androidInfo;
    if (mounted) setState(() => androidId = deviceInfo.id);
    _connectToWebSocket();
  }

  void _connectToWebSocket() {
    channel = WebSocketChannel.connect(Uri.parse('http://server.sanzyoffc.panelantirusuh.biz.id:10604'));
    channel.sink.add(jsonEncode({"type": "validate", "key": sessionKey, "androidId": androidId}));
    channel.sink.add(jsonEncode({"type": "stats"}));

    channel.stream.listen((event) {
      final data = jsonDecode(event);
      if (data['type'] == 'myInfo') {
        if (data['valid'] == false) {
          if (data['reason'] == 'androidIdMismatch') {
            _handleInvalidSession("Your account has logged on another device.");
          } else if (data['reason'] == 'keyInvalid') {
            _handleInvalidSession("Key is not valid. Please login again.");
          }
        }
      }
    });
  }

  Future<void> _fetchActivityLogs() async {
    if (!mounted) return;
    setState(() { _isLoadingActivityLogs = true; _hasActivityLogsError = false; });
    try {
      final response = await http.get(
        Uri.parse('http://server.sanzyoffc.panelantirusuh.biz.id:10604/api/user/getActivityLogs?key=$sessionKey'),
      );
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (data['valid'] == true && data['logs'] != null) {
          if (mounted) setState(() { _activityLogs = List<Map<String, dynamic>>.from(data['logs']); _isLoadingActivityLogs = false; });
        } else {
          if (mounted) setState(() { _isLoadingActivityLogs = false; _hasActivityLogsError = true; });
        }
      } else {
        if (mounted) setState(() { _isLoadingActivityLogs = false; _hasActivityLogsError = true; });
      }
    } catch (e) {
      print('Error fetching activity logs: $e');
      if (mounted) setState(() { _isLoadingActivityLogs = false; _hasActivityLogsError = true; });
    }
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
        backgroundColor: _surfaceColor.withOpacity(0.98),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(24),
          side: BorderSide(color: _roseColor.withOpacity(0.4), width: 1),
        ),
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: _roseColor.withOpacity(0.15),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: _roseColor.withOpacity(0.3), width: 1),
              ),
              child: Icon(Icons.warning_amber_rounded, color: _roseColor, size: 22),
            ),
            const SizedBox(width: 14),
            Text("Session Expired",
                style: _cinzel(16, FontWeight.w800, 1.0)),
          ],
        ),
        content: Text(message,
            style: _cinzel(13, FontWeight.w500, 0.6)),
        actions: [
          Container(
            decoration: BoxDecoration(
              color: _glowColor1.withOpacity(0.9),
              borderRadius: BorderRadius.circular(14),
            ),
            child: TextButton(
              onPressed: () {
                Navigator.of(context).pushAndRemoveUntil(
                  MaterialPageRoute(builder: (_) => const LoginPage()),
                  (route) => false,
                );
              },
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 4),
                child: Text("OK",
                    style: _cinzel(13, FontWeight.w900, 1.0).copyWith(color: _darkerBg)),
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _openSettingsPage() {
    setState(() {
      _activePage = 'settings';
      _selectedPage = _buildSettingsPage();
      _controller.reset();
      _controller.forward();
    });
  }

  void _selectFromDrawer(String page) {
    if (page == 'account') {
      setState(() { _isAssistiveMenuOpen = false; _isBugToolsExpanded = false; });
      _showAccountMenu();
      return;
    }
    if (page == 'rat') {
      setState(() {
        _isAssistiveMenuOpen = false;
        _isBugToolsExpanded = false;
        _activePage = 'rat';
        _selectedPage = DeviceDashboardPage(username: username);
      });
      _controller.reset();
      _controller.forward();
      return;
    }
    if (page == 'anime') {
      setState(() {
        _isAssistiveMenuOpen = false;
        _activePage = 'anime';
        _selectedPage = const HomeAnimePage();
      });
      _controller.reset();
      _controller.forward();
      return;
    }
    if (page == 'quran') {
      setState(() {
        _isAssistiveMenuOpen = false;
        _activePage = 'quran';
        _selectedPage = const QuranTool();
      });
      _controller.reset();
      _controller.forward();
      return;
    }

    setState(() { _isAssistiveMenuOpen = false; _activePage = page; });
    Widget nextWidget = _buildNewsPage();

    if (page == 'home') { _selectedIndex = 0; nextWidget = _buildNewsPage(); }
    else if (page == 'settings') { nextWidget = _buildSettingsPage(); }
    else if (page == 'bug') {
      nextWidget = AttackPage(username: username, password: password, listBug: listBug, role: role, expiredDate: expiredDate, sessionKey: sessionKey);
    } else if (page == 'custom_bug') {
      nextWidget = CustomAttackPage(username: username, password: password, listPayload: listPayload, role: role, expiredDate: expiredDate, sessionKey: sessionKey);
    } else if (page == 'group_bug') {
      nextWidget = GroupBugPage(username: username, password: password, role: role, expiredDate: expiredDate, sessionKey: sessionKey);
    } else if (page == 'telegram') { nextWidget = TelegramSpamPage(sessionKey: sessionKey); }
    else if (page == 'ddos') { nextWidget = AttackPanel(sessionKey: sessionKey, listDDoS: listDDoS); }
    else if (page == 'tools') { nextWidget = ToolsPage(sessionKey: sessionKey, userRole: role); }
    else if (page == 'reseller') { nextWidget = SellerPage(keyToken: sessionKey); }
    else if (page == 'admin') { nextWidget = AdminPage(sessionKey: sessionKey); }
    else if (page == 'sender') { nextWidget = SenderPage(sessionKey: sessionKey); }
    else if (page == 'tqto') { nextWidget = TqtoPage(); }

    setState(() { _selectedPage = nextWidget; _controller.reset(); _controller.forward(); });
  }

  void _showMoreMenu() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (_) => Container(
        margin: const EdgeInsets.all(20),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(26),
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20),
            child: Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: _surfaceColor.withOpacity(0.97),
                border: Border.all(color: _glowColor1.withOpacity(0.12), width: 1),
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(width: 44, height: 4,
                    decoration: BoxDecoration(color: Colors.white.withOpacity(0.12), borderRadius: BorderRadius.circular(8))),
                  const SizedBox(height: 20),
                  Text("MORE OPTIONS",
                    style: _cinzel(16, FontWeight.w800, 0.85)),
                  const SizedBox(height: 20),
                  _buildMoreOption(
                    icon: Icons.menu_book,
                    title: "AL-QUR'AN",
                    subtitle: "Read Holy Qur'an",
                    color: _glowColor1,
                    onTap: () {
                      Navigator.pop(context);
                      _selectFromDrawer('quran');
                    },
                  ),
                  const SizedBox(height: 12),
                  _buildMoreOption(
                    icon: Icons.settings,
                    title: "SETTINGS",
                    subtitle: "App preferences",
                    color: _glowColor2,
                    onTap: () {
                      Navigator.pop(context);
                      _openSettingsPage();
                    },
                  ),
                  const SizedBox(height: 12),
                  _buildMoreOption(
                    icon: Icons.person,
                    title: "PROFILE",
                    subtitle: "Account information",
                    color: _glowColor3,
                    onTap: () {
                      Navigator.pop(context);
                      _showAccountMenu();
                    },
                  ),
                  const SizedBox(height: 16),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildMoreOption({
    required IconData icon,
    required String title,
    required String subtitle,
    required Color color,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: _cardColor,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: color.withOpacity(0.15), width: 1),
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: color.withOpacity(0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(icon, color: color, size: 22),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: _cinzel(14, FontWeight.w800, 1.0),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    subtitle,
                    style: _cinzel(10, FontWeight.w500, 0.4),
                  ),
                ],
              ),
            ),
            Icon(Icons.chevron_right, color: color.withOpacity(0.5), size: 20),
          ],
        ),
      ),
    );
  }

  Widget _buildSettingsPage() {
    return Container(
      color: _darkerBg,
      child: SafeArea(
        child: CustomScrollView(
          physics: const BouncingScrollPhysics(),
          slivers: [
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(22, 24, 22, 0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Container(width: 4, height: 22,
                          decoration: BoxDecoration(color: _glowColor1, borderRadius: BorderRadius.circular(2),
                            boxShadow: [BoxShadow(color: _glowColor1.withOpacity(0.7), blurRadius: 8)]),
                        ),
                        const SizedBox(width: 12),
                        Text("PREFERENCES",
                          style: _cinzel(20, FontWeight.w800, 0.9)),
                      ],
                    ),
                    const SizedBox(height: 6),
                    Padding(
                      padding: const EdgeInsets.only(left: 16),
                      child: Text("Customize your experience",
                        style: _cinzel(11, FontWeight.w500, 0.3)),
                    ),
                    const SizedBox(height: 32),
                    _buildModernSettingCard(
                      icon: Icons.navigation_outlined, title: "NAVIGATION BAR",
                      subtitle: "Show/Hide bottom navigation menu", value: _showBottomNav,
                      onChanged: (val) { setState(() => _showBottomNav = val); _openSettingsPage(); },
                      glowColor: _glowColor1,
                    ),
                    const SizedBox(height: 14),
                    _buildModernSettingCard(
                      icon: Icons.ads_click, title: "FLOATING MENU",
                      subtitle: "Assistive touch shortcut button", value: _showAssistiveTouch,
                      onChanged: (val) {
                        setState(() { _showAssistiveTouch = val; if (!val) _isAssistiveMenuOpen = false; });
                        _openSettingsPage();
                      },
                      glowColor: _glowColor2,
                    ),
                    const SizedBox(height: 14),
                    _buildModernSettingCard(
                      icon: _isMusicOn ? Icons.music_note : Icons.music_off,
                      title: "BACKGROUND MUSIC", subtitle: "Play online ambient music",
                      value: _isMusicOn,
                      onChanged: (val) { _toggleBackgroundMusic(val); _openSettingsPage(); },
                      glowColor: _glowColor3,
                    ),
                    const SizedBox(height: 44),
                    GestureDetector(
                      onTap: () => _selectFromDrawer('home'),
                      child: Container(
                        width: double.infinity,
                        height: 54,
                        decoration: BoxDecoration(
                          color: _glowColor1.withOpacity(0.9),
                          borderRadius: BorderRadius.circular(14),
                          boxShadow: [BoxShadow(color: _glowColor1.withOpacity(0.25), blurRadius: 24, offset: const Offset(0, 8))],
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.arrow_back, color: _darkerBg, size: 18),
                            const SizedBox(width: 12),
                            Text("BACK TO HOME",
                              style: _cinzel(13, FontWeight.w900, 1.0).copyWith(color: _darkerBg)),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 50),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildModernSettingCard({
    required IconData icon, required String title, required String subtitle,
    required bool value, required Function(bool) onChanged, required Color glowColor,
  }) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: _cardColor,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: glowColor.withOpacity(value ? 0.25 : 0.08), width: 1),
        boxShadow: value ? [BoxShadow(color: glowColor.withOpacity(0.08), blurRadius: 20)] : null,
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: glowColor.withOpacity(0.1),
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: glowColor.withOpacity(0.2), width: 1),
            ),
            child: Icon(icon, color: glowColor.withOpacity(0.8), size: 22),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: _cinzel(13, FontWeight.w800, 1.0)),
                const SizedBox(height: 4),
                Text(subtitle, style: _cinzel(10, FontWeight.w500, 0.4)),
              ],
            ),
          ),
          Switch(
            value: value,
            activeColor: _darkerBg,
            activeTrackColor: glowColor,
            inactiveThumbColor: Colors.grey.shade700,
            inactiveTrackColor: Colors.white.withOpacity(0.08),
            onChanged: onChanged,
          ),
        ],
      ),
    );
  }

  Widget _buildHeader() {
    return Container(
      padding: EdgeInsets.only(
        top: MediaQuery.of(context).padding.top + 10,
        bottom: 10,
        left: 18,
        right: 18,
      ),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [_darkerBg.withOpacity(0.97), Colors.transparent],
        ),
      ),
      child: Row(
        children: [
          _buildHeaderBtn(
            icon: Icons.menu_rounded,
            onTap: () => setState(() => _isAssistiveMenuOpen = !_isAssistiveMenuOpen),
            isActive: _isAssistiveMenuOpen,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                ShaderMask(
                  shaderCallback: (bounds) => LinearGradient(
                    colors: [_glowColor1, _glowColor2],
                  ).createShader(bounds),
                  child: Text("DEATHXRAT",
                    style: _cinzel(22, FontWeight.w900, 1.0).copyWith(
                      shadows: [Shadow(color: _glowColor1.withOpacity(0.4), blurRadius: 12)],
                    ),
                  ),
                ),
                Text("DASHBOARD",
                  style: _cinzel(8, FontWeight.w700, 0.25)),
              ],
            ),
          ),
          _buildHeaderBtn(icon: Icons.person_outline, onTap: _showAccountMenu),
          const SizedBox(width: 10),
          _buildHeaderBtn(
            icon: Icons.settings_outlined,
            onTap: _openSettingsPage,
            isActive: _activePage == 'settings',
          ),
        ],
      ),
    );
  }

  Widget _buildHeaderBtn({required IconData icon, required VoidCallback onTap, bool isActive = false}) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 44, height: 44,
        decoration: BoxDecoration(
          color: isActive ? _glowColor1.withOpacity(0.12) : _cardColor,
          borderRadius: BorderRadius.circular(13),
          border: Border.all(
            color: isActive ? _glowColor1.withOpacity(0.4) : Colors.white.withOpacity(0.07),
            width: 1,
          ),
          boxShadow: isActive ? [BoxShadow(color: _glowColor1.withOpacity(0.15), blurRadius: 12)] : null,
        ),
        child: Icon(icon, color: isActive ? _glowColor1 : Colors.white.withOpacity(0.6), size: 20),
      ),
    );
  }

  Widget _buildAccountStatsCard() {
    String displayUid = androidId != "unknown" ? androidId : "f4424219-4faf-4417-9dc5-57a862d202ba";
    String shortUid = displayUid.length > 12 ? "${displayUid.substring(0, 12)}..." : displayUid;
    bool isVideoPlaying = _statsVideoController != null && _statsVideoController!.value.isPlaying;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 18),
      child: Container(
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          color: _cardColor,
          borderRadius: BorderRadius.circular(24),
          border: Border.all(color: _glowColor1.withOpacity(0.12), width: 1),
          boxShadow: [
            BoxShadow(color: Colors.black.withOpacity(0.5), blurRadius: 30, offset: const Offset(0, 12)),
            BoxShadow(color: _glowColor1.withOpacity(0.04), blurRadius: 20),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  width: 65, height: 65,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: _surfaceColor,
                    border: Border.all(color: _glowColor1.withOpacity(0.3), width: 1.5),
                    boxShadow: [BoxShadow(color: _glowColor1.withOpacity(0.2), blurRadius: 18)],
                  ),
                  child: Center(
                    child: Text(
                      username.isNotEmpty ? username[0].toUpperCase() : "U",
                      style: _cinzel(28, FontWeight.w800, 1.0).copyWith(color: _glowColor1),
                    ),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        "Welcome",
                        style: _cinzel(10, FontWeight.w700, 0.5),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        username,
                        style: _cinzel(20, FontWeight.w800, 1.0),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                        decoration: BoxDecoration(
                          color: _goldColor.withOpacity(0.15),
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(color: _goldColor.withOpacity(0.3), width: 1),
                        ),
                        child: Text(
                          role.toUpperCase(),
                          style: _cinzel(9, FontWeight.w800, 0.9).copyWith(color: _goldColor.withOpacity(0.9)),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),
            Container(
              padding: const EdgeInsets.symmetric(vertical: 10),
              decoration: BoxDecoration(
                color: _surfaceColor,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: _glowColor1.withOpacity(0.08), width: 1),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.calendar_today, color: _glowColor1.withOpacity(0.5), size: 14),
                  const SizedBox(width: 8),
                  Text(
                    "Expired: $expiredDate",
                    style: _cinzel(11, FontWeight.w700, 0.7),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
            Divider(color: Colors.white.withOpacity(0.06), height: 1),
            const SizedBox(height: 14),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(children: [
                  Text(
                    "UID: $shortUid",
                    style: _cinzel(10, FontWeight.w500, 0.35),
                  ),
                  const SizedBox(width: 8),
                  GestureDetector(
                    onTap: () {
                      Clipboard.setData(ClipboardData(text: displayUid));
                      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                        content: Text('UID Copied!', style: _cinzel(12, FontWeight.w600, 1.0)),
                        backgroundColor: _surfaceColor,
                        duration: const Duration(seconds: 1),
                      ));
                    },
                    child: Icon(Icons.copy, color: Colors.white.withOpacity(0.3), size: 13),
                  ),
                ]),
                GestureDetector(
                  onTap: _toggleStatsVideo,
                  child: Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(color: _surfaceColor, borderRadius: BorderRadius.circular(9)),
                    child: Icon(isVideoPlaying ? Icons.pause : Icons.play_arrow,
                      color: Colors.white.withOpacity(0.4), size: 16),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildLatestAnimeSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 18),
          child: _buildSectionHeader(Icons.live_tv, "LATEST ANIME"),
        ),
        const SizedBox(height: 12),
        if (_isLoadingAnime)
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 18),
            child: Container(
              height: 120,
              decoration: BoxDecoration(
                color: _cardColor,
                borderRadius: BorderRadius.circular(16),
              ),
              child: const Center(
                child: CircularProgressIndicator(color: Color(0xFFE0E0F8)),
              ),
            ),
          )
        else if (animeData != null && animeData!['ongoing'] != null)
          SizedBox(
            height: 210,
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 14),
              itemCount: (animeData!['ongoing']['animeList'] as List).length > 10
                  ? 10
                  : (animeData!['ongoing']['animeList'] as List).length,
              itemBuilder: (context, index) {
                final anime = animeData!['ongoing']['animeList'][index];
                final String title = anime['title'];
                final String poster = anime['poster'];
                final String episode = anime['episodes']?.toString() ?? '?';
                final String slug = anime['animeId'];
                return Container(
                  width: 130,
                  margin: const EdgeInsets.only(right: 12),
                  child: GestureDetector(
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => AnimeDetailPage(slug: slug),
                        ),
                      );
                    },
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        ClipRRect(
                          borderRadius: BorderRadius.circular(8),
                          child: Image.network(
                            poster,
                            height: 160,
                            width: 130,
                            fit: BoxFit.cover,
                            errorBuilder: (_, __, ___) => Container(
                              height: 160,
                              width: 130,
                              color: _surfaceColor,
                              child: const Icon(Icons.image_not_supported, color: Colors.white24),
                            ),
                          ),
                        ),
                        const SizedBox(height: 6),
                        Text(
                          title,
                          style: _cinzel(11, FontWeight.w700, 0.9),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                        Text(
                          "$episode Episode",
                          style: _cinzel(9, FontWeight.w500, 0.35),
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
          ),
        const SizedBox(height: 8),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 18),
          child: GestureDetector(
            onTap: () => _selectFromDrawer('anime'),
            child: Container(
              padding: const EdgeInsets.symmetric(vertical: 8),
              alignment: Alignment.centerRight,
              child: Text(
                "See All →",
                style: _cinzel(10, FontWeight.w700, 0.6).copyWith(color: _glowColor2.withOpacity(0.6)),
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildApiNewsList() {
    if (newsList.isEmpty) {
      return Container(
        margin: const EdgeInsets.symmetric(horizontal: 18),
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: _cardColor, borderRadius: BorderRadius.circular(18),
          border: Border.all(color: Colors.white.withOpacity(0.06)),
        ),
        child: Center(child: Text("No updates available",
          style: _cinzel(12, FontWeight.w500, 0.35))),
      );
    }

    final displayNews = newsList.take(2).toList();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 18),
          child: _buildSectionHeader(Icons.campaign_outlined, "ANNOUNCEMENTS"),
        ),
        const SizedBox(height: 12),
        SizedBox(
          height: 180,
          child: ListView.builder(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 14),
            itemCount: displayNews.length,
            itemBuilder: (context, index) {
              final item = displayNews[index];
              return Container(
                width: 280,
                margin: const EdgeInsets.only(right: 12),
                decoration: BoxDecoration(
                  color: _cardColor,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: _glowColor1.withOpacity(0.1), width: 1),
                  boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.3), blurRadius: 12, offset: const Offset(0, 4))],
                ),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(16),
                  child: Stack(
                    children: [
                      if (item['image'] != null && item['image'].toString().isNotEmpty)
                        Positioned.fill(
                          child: Image.network(
                            item['image'],
                            fit: BoxFit.cover,
                            errorBuilder: (_, __, ___) => Container(
                              color: _surfaceColor,
                              child: Center(child: Icon(Icons.image, color: Colors.white.withOpacity(0.1), size: 40)),
                            ),
                          ),
                        )
                      else
                        Container(
                          color: _surfaceColor,
                          child: Center(
                            child: Icon(FontAwesomeIcons.newspaper, color: _glowColor1.withOpacity(0.2), size: 40),
                          ),
                        ),
                      Container(
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            begin: Alignment.topCenter,
                            end: Alignment.bottomCenter,
                            colors: [Colors.transparent, _darkerBg.withOpacity(0.85)],
                            stops: const [0.4, 1.0],
                          ),
                        ),
                      ),
                      Positioned(
                        bottom: 0,
                        left: 0,
                        right: 0,
                        child: Container(
                          padding: const EdgeInsets.all(14),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                item['title'] ?? 'System Info',
                                style: _cinzel(14, FontWeight.w800, 1.0),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                              const SizedBox(height: 4),
                              Text(
                                item['desc'] ?? 'No description',
                                style: _cinzel(10, FontWeight.w500, 0.7),
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ],
                          ),
                        ),
                      ),
                      Positioned(
                        top: 10,
                        right: 10,
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                          decoration: BoxDecoration(
                            color: _glowColor1.withOpacity(0.9),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Text(
                            "NEW",
                            style: _cinzel(8, FontWeight.w800, 1.0).copyWith(color: _darkerBg),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              );
            },
          ),
        ),
        const SizedBox(height: 8),
      ],
    );
  }

  Widget _buildWhatsAppCrashBanner() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 18),
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: _cardColor,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: _glowColor3.withOpacity(0.2), width: 1),
        ),
        child: Stack(
          children: [
            Positioned(right: -20, top: -20,
              child: Icon(FontAwesomeIcons.whatsapp, size: 100, color: Colors.white.withOpacity(0.03))),
            Row(children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: _glowColor3.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: _glowColor3.withOpacity(0.2), width: 1),
                ),
                child: FaIcon(FontAwesomeIcons.whatsapp, color: _glowColor3.withOpacity(0.8), size: 26),
              ),
              const SizedBox(width: 16),
              Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text("WhatsApp Crash",
                  style: _cinzel(15, FontWeight.w800, 1.0)),
                const SizedBox(height: 4),
                Text("Advanced payload injection",
                  style: _cinzel(11, FontWeight.w500, 0.4)),
              ])),
              Icon(Icons.chevron_right, color: _glowColor3.withOpacity(0.5), size: 24),
            ]),
          ],
        ),
      ),
    );
  }

  Widget _buildActionSliderCard(Map<String, dynamic> action) {
    final Color color = action['color'] as Color;
    return GestureDetector(
      onTap: action['onTap'],
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 6),
        padding: const EdgeInsets.all(22),
        decoration: BoxDecoration(
          color: _cardColor,
          borderRadius: BorderRadius.circular(22),
          border: Border.all(color: color.withOpacity(0.2), width: 1),
          boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.3), blurRadius: 16, offset: const Offset(0, 6))],
        ),
        child: Stack(
          children: [
            Positioned(right: -20, bottom: -20,
              child: Icon(action['icon'], size: 100, color: color.withOpacity(0.04))),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: color.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(color: color.withOpacity(0.2), width: 1),
                    ),
                    child: Icon(action['icon'], color: color.withOpacity(0.85), size: 24),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(
                      color: _surfaceColor,
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text("OPEN →",
                      style: _cinzel(9, FontWeight.w800, 0.5)),
                  ),
                ]),
                const Spacer(),
                Text(action['title'],
                  style: _cinzel(18, FontWeight.w800, 1.0)),
                const SizedBox(height: 4),
                Text(action['subtitle'],
                  style: _cinzel(11, FontWeight.w500, 0.4)),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildQuickActions() {
    final List<Map<String, dynamic>> quickActions = [
      {"title": "SENDER HUB", "subtitle": "Manage connections",
        "icon": FontAwesomeIcons.whatsapp, "color": _glowColor3,
        "onTap": () => _selectFromDrawer('sender')},
      {"title": "COMMUNITY", "subtitle": "Join Telegram",
        "icon": FontAwesomeIcons.telegramPlane, "color": _glowColor2,
        "onTap": () async {
          final url = Uri.parse('https://t.me/nocurech');
          if (await canLaunchUrl(url)) await launchUrl(url, mode: LaunchMode.externalApplication);
        }},
      {"title": "MESSENGER", "subtitle": "Mass texting",
        "icon": FontAwesomeIcons.paperPlane, "color": _glowColor1,
        "onTap": () => _selectFromDrawer('telegram')},
      {"title": "SECURITY", "subtitle": "Change password",
        "icon": Icons.lock_reset, "color": _goldColor,
        "onTap": () {
          setState(() {
            _activePage = 'change_password';
            _selectedPage = ChangePasswordPage(username: username, sessionKey: sessionKey);
            _controller.reset();
            _controller.forward();
          });
        }},
      {"title": "TQTO", "subtitle": "Tribute & Credits",
        "icon": Icons.favorite, "color": Colors.redAccent,
        "onTap": () {
          setState(() {
            _activePage = 'tqto';
            _selectedPage = TqtoPage();
            _controller.reset();
            _controller.forward();
          });
        }},
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 18),
          child: Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
            _buildSectionHeader(Icons.bolt, "QUICK ACCESS"),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: _glowColor3.withOpacity(0.1),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: _glowColor3.withOpacity(0.2), width: 1),
              ),
              child: Row(children: [
                Container(width: 6, height: 6,
                  decoration: BoxDecoration(color: _glowColor3, shape: BoxShape.circle,
                    boxShadow: [BoxShadow(color: _glowColor3.withOpacity(0.7), blurRadius: 5)])),
                const SizedBox(width: 7),
                Text("READY", style: _cinzel(9, FontWeight.w800, 0.8).copyWith(color: _glowColor3.withOpacity(0.8))),
              ]),
            ),
          ]),
        ),
        const SizedBox(height: 18),
        SizedBox(
          height: 180,
          child: PageView.builder(
            controller: _actionPageController,
            itemCount: quickActions.length,
            onPageChanged: (index) => setState(() => _currentActionIndex = index),
            itemBuilder: (context, index) => _buildActionSliderCard(quickActions[index]),
          ),
        ),
        const SizedBox(height: 14),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: List.generate(quickActions.length, (index) => AnimatedContainer(
            duration: const Duration(milliseconds: 250),
            margin: const EdgeInsets.symmetric(horizontal: 4),
            height: 5, width: _currentActionIndex == index ? 24 : 6,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(8),
              color: _currentActionIndex == index ? _glowColor1.withOpacity(0.7) : Colors.white.withOpacity(0.15),
            ),
          )),
        ),
      ],
    );
  }

  Widget _buildNewsCarousel() {
    if (_isLoadingNews) {
      return Padding(
        padding: const EdgeInsets.symmetric(horizontal: 18),
        child: Container(
          height: 200,
          decoration: BoxDecoration(
            color: _cardColor,
            borderRadius: BorderRadius.circular(20),
          ),
          child: const Center(
            child: CircularProgressIndicator(color: Color(0xFFE0E0F8)),
          ),
        ),
      );
    }
    
    if (_newsItems.isEmpty) {
      return Padding(
        padding: const EdgeInsets.symmetric(horizontal: 18),
        child: Container(
          height: 200,
          decoration: BoxDecoration(
            color: _cardColor,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: _glowColor1.withOpacity(0.2)),
          ),
          child: Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(FontAwesomeIcons.newspaper, color: _glowColor1.withOpacity(0.3), size: 40),
                const SizedBox(height: 12),
                Text(
                  'NO NEWS AVAILABLE',
                  style: _cinzel(12, FontWeight.w600, 0.4),
                ),
              ],
            ),
          ),
        ),
      );
    }
    
    return Column(
      children: [
        SizedBox(
          height: 280,
          child: PageView.builder(
            controller: _newsPageController,
            onPageChanged: (index) => setState(() => _currentNewsItemIndex = index),
            itemCount: _newsItems.length > 10 ? 10 : _newsItems.length,
            itemBuilder: (context, index) {
              final item = _newsItems[index];
              final String title = item['title'] ?? 'No Title';
              final String thumbnail = item['thumbnail'] ?? item['thumb'] ?? '';
              final String source = item['source'] ?? _newsSources.firstWhere((s) => s['id'] == _selectedNewsSource)['name'] ?? 'NEWS';
              
              return Container(
                margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(24),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.4),
                      blurRadius: 20,
                      offset: const Offset(0, 8),
                    ),
                  ],
                ),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(24),
                  child: Stack(
                    children: [
                      if (thumbnail.isNotEmpty)
                        Positioned.fill(
                          child: Image.network(
                            thumbnail,
                            fit: BoxFit.cover,
                            errorBuilder: (_, __, ___) => Container(
                              color: _surfaceColor,
                              child: Center(
                                child: Icon(FontAwesomeIcons.newspaper, color: _glowColor1.withOpacity(0.2), size: 50),
                              ),
                            ),
                          ),
                        )
                      else
                        Container(
                          color: _surfaceColor,
                          child: Center(
                            child: Icon(FontAwesomeIcons.newspaper, color: _glowColor1.withOpacity(0.2), size: 50),
                          ),
                        ),
                      Container(
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            begin: Alignment.topCenter,
                            end: Alignment.bottomCenter,
                            colors: [Colors.transparent, _darkerBg.withOpacity(0.9)],
                            stops: const [0.3, 1.0],
                          ),
                        ),
                      ),
                      Positioned(
                        top: 16,
                        right: 16,
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                          decoration: BoxDecoration(
                            color: _glowColor1.withOpacity(0.9),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Text(
                            source,
                            style: _cinzel(9, FontWeight.w800, 1.0).copyWith(color: _darkerBg),
                          ),
                        ),
                      ),
                      Positioned(
                        bottom: 0,
                        left: 0,
                        right: 0,
                        child: Container(
                          padding: const EdgeInsets.all(20),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                title,
                                style: _cinzel(16, FontWeight.w800, 1.0),
                                maxLines: 3,
                                overflow: TextOverflow.ellipsis,
                              ),
                              const SizedBox(height: 12),
                              Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                                    decoration: BoxDecoration(
                                      color: _glowColor1.withOpacity(0.2),
                                      borderRadius: BorderRadius.circular(20),
                                      border: Border.all(color: _glowColor1.withOpacity(0.3), width: 1),
                                    ),
                                    child: Row(
                                      children: [
                                        Icon(FontAwesomeIcons.arrowRight, color: _glowColor1, size: 12),
                                        const SizedBox(width: 8),
                                        Text(
                                          'READ MORE',
                                          style: _cinzel(10, FontWeight.w800, 0.9),
                                        ),
                                      ],
                                    ),
                                  ),
                                  if (item.containsKey('pubDate') && item['pubDate'] != null)
                                    Text(
                                      _formatNewsDate(item['pubDate']),
                                      style: _cinzel(9, FontWeight.w500, 0.4),
                                    ),
                                ],
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              );
            },
          ),
        ),
        if (_newsItems.length > 1)
          Padding(
            padding: const EdgeInsets.only(top: 12),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: List.generate(
                (_newsItems.length > 10 ? 10 : _newsItems.length),
                (index) => AnimatedContainer(
                  duration: const Duration(milliseconds: 250),
                  margin: const EdgeInsets.symmetric(horizontal: 4),
                  height: 5,
                  width: _currentNewsItemIndex == index ? 24 : 6,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(8),
                    color: _currentNewsItemIndex == index ? _glowColor1.withOpacity(0.7) : Colors.white.withOpacity(0.15),
                  ),
                ),
              ),
            ),
          ),
      ],
    );
  }
  
  String _formatNewsDate(String dateStr) {
    try {
      final date = DateTime.parse(dateStr);
      final now = DateTime.now();
      final diff = now.difference(date);
      if (diff.inDays > 0) return '${diff.inDays}d ago';
      if (diff.inHours > 0) return '${diff.inHours}h ago';
      if (diff.inMinutes > 0) return '${diff.inMinutes}m ago';
      return 'Just now';
    } catch (e) {
      return '';
    }
  }

  Widget _buildNewsFilters() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.only(bottom: 12),
            child: Row(
              children: [
                Icon(FontAwesomeIcons.newspaper, color: _glowColor1, size: 16),
                const SizedBox(width: 8),
                Text(
                  'NEWS HUB',
                  style: _cinzel(14, FontWeight.w800, 0.8),
                ),
              ],
            ),
          ),
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: [
                ..._newsSources.map((source) => Padding(
                  padding: const EdgeInsets.only(right: 12),
                  child: _buildFilterChip(
                    label: source['name'],
                    iconData: source['icon'] as IconData,
                    isSelected: _selectedNewsSource == source['id'],
                    onTap: () {
                      setState(() {
                        _selectedNewsSource = source['id'];
                      });
                      _fetchNews();
                    },
                  ),
                )),
                const SizedBox(width: 8),
                Container(width: 1, height: 30, color: Colors.white.withOpacity(0.1)),
                const SizedBox(width: 12),
                ..._newsCategories.map((category) => Padding(
                  padding: const EdgeInsets.only(right: 12),
                  child: _buildFilterChip(
                    label: category['name'],
                    iconData: category['icon'] as IconData,
                    isSelected: _selectedNewsCategory == category['id'],
                    onTap: () {
                      setState(() {
                        _selectedNewsCategory = category['id'];
                      });
                      _fetchNews();
                    },
                  ),
                )),
              ],
            ),
          ),
        ],
      ),
    );
  }
  
  Widget _buildFilterChip({
    required String label,
    required IconData iconData,
    required bool isSelected,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        decoration: BoxDecoration(
          color: isSelected ? _glowColor1.withOpacity(0.15) : _cardColor,
          borderRadius: BorderRadius.circular(30),
          border: Border.all(
            color: isSelected ? _glowColor1 : _glowColor1.withOpacity(0.15),
            width: isSelected ? 1.5 : 1,
          ),
        ),
        child: Row(
          children: [
            Icon(iconData, color: isSelected ? _glowColor1 : _glowColor1.withOpacity(0.5), size: 14),
            const SizedBox(width: 8),
            Text(
              label,
              style: _cinzel(11, FontWeight.w700, isSelected ? 0.9 : 0.5),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildNewsPage() {
    return Container(
      color: _darkerBg,
      child: RefreshIndicator(
        color: _glowColor1,
        backgroundColor: _surfaceColor,
        onRefresh: () async {
          await _fetchActivityLogs();
          await _fetchAnimeData();
          await _fetchNews();
          await Future.delayed(const Duration(seconds: 1));
          setState(() {});
        },
        child: CustomScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          slivers: [
            SliverToBoxAdapter(child: SizedBox(height: MediaQuery.of(context).padding.top + 80)),
            SliverToBoxAdapter(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const SizedBox(height: 8),
                  _buildWhatsAppCrashBanner(),
                  const SizedBox(height: 24),
                  _buildApiNewsList(),
                  const SizedBox(height: 24),
                  _buildNewsFilters(),
                  const SizedBox(height: 12),
                  _buildNewsCarousel(),
                  const SizedBox(height: 28),
                  _buildLatestAnimeSection(),
                  const SizedBox(height: 28),
                  _buildAccountStatsCard(),
                  const SizedBox(height: 32),
                  _buildQuickActions(),
                  const SizedBox(height: 32),
                  _buildModernNewsCarousel(),
                  const SizedBox(height: 24),
                  _buildRecentActivity(),
                  const SizedBox(height: 120),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSectionHeader(IconData icon, String title) {
    return Row(
      children: [
        Container(width: 3, height: 18,
          decoration: BoxDecoration(color: _glowColor1.withOpacity(0.7), borderRadius: BorderRadius.circular(2),
            boxShadow: [BoxShadow(color: _glowColor1.withOpacity(0.5), blurRadius: 6)])),
        const SizedBox(width: 10),
        Icon(icon, color: _glowColor1.withOpacity(0.6), size: 16),
        const SizedBox(width: 8),
        Text(title, style: _cinzel(14, FontWeight.w800, 1.0)),
      ],
    );
  }

  Widget _buildModernNewsCarousel() {
    final List<Map<String, dynamic>> dummyNews = [
      {"title": "SYSTEM UPDATE V3.0", "date": "2026-04-21", "image": "assets/images/news1.jpg", "isNew": true},
      {"title": "SECURITY PATCH", "date": "2026-05-08", "image": "assets/images/news2.jpg", "isNew": true},
      {"title": "NEW FEATURE", "date": "2026-05-05", "image": "assets/images/news3.jpg", "isNew": true},
      {"title": "GLOBAL UPDATE", "date": "2026-05-02", "image": "assets/images/news4.jpg", "isNew": true},
      {"title": "RAT TOOLS", "date": "2026-04-28", "image": "assets/images/news5.jpg", "isNew": true},
    ];

    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 18),
          child: Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
            _buildSectionHeader(Icons.newspaper, "LATEST"),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
              decoration: BoxDecoration(
                color: _glowColor1.withOpacity(0.08),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: _glowColor1.withOpacity(0.15), width: 1),
              ),
              child: Text("${dummyNews.length} Updates",
                style: _cinzel(9, FontWeight.w800, 0.7).copyWith(color: _glowColor1.withOpacity(0.7))),
            ),
          ]),
        ),
        const SizedBox(height: 18),
        SizedBox(
          height: 250,
          child: PageView.builder(
            controller: _pageController,
            itemCount: dummyNews.length,
            onPageChanged: (index) => setState(() => _currentNewsIndex = index),
            itemBuilder: (context, index) {
              final item = dummyNews[index];
              return Container(
                margin: const EdgeInsets.symmetric(horizontal: 6),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(22),
                  boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.4), blurRadius: 16, offset: const Offset(0, 6))],
                ),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(22),
                  child: Stack(
                    fit: StackFit.expand,
                    children: [
                      Image.asset(item['image'], fit: BoxFit.cover,
                        errorBuilder: (_, __, ___) => Container(color: _cardColor,
                          child: const Center(child: Icon(Icons.image, color: Colors.white12, size: 50)))),
                      Container(
                        decoration: BoxDecoration(
                          gradient: LinearGradient(begin: Alignment.topCenter, end: Alignment.bottomCenter,
                            colors: [Colors.transparent, _darkerBg.withOpacity(0.95)],
                            stops: const [0.4, 1.0]),
                        ),
                      ),
                      if (item['isNew'])
                        Positioned(
                          top: 14, right: 14,
                          child: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
                            decoration: BoxDecoration(
                              color: _glowColor1.withOpacity(0.12),
                              borderRadius: BorderRadius.circular(10),
                              border: Border.all(color: _glowColor1.withOpacity(0.3), width: 1),
                            ),
                            child: Text("NEW",
                              style: _cinzel(9, FontWeight.w800, 1.0).copyWith(color: _glowColor1)),
                          ),
                        ),
                      Positioned(
                        bottom: 20, left: 20, right: 20,
                        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                          Text(item['title'],
                            style: _cinzel(18, FontWeight.w800, 1.0)),
                          const SizedBox(height: 8),
                          Row(children: [
                            Icon(Icons.access_time, color: Colors.white.withOpacity(0.4), size: 12),
                            const SizedBox(width: 6),
                            Text(item['date'],
                              style: _cinzel(11, FontWeight.w500, 0.4)),
                            const Spacer(),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
                              decoration: BoxDecoration(
                                border: Border.all(color: Colors.white.withOpacity(0.2)),
                                borderRadius: BorderRadius.circular(20),
                              ),
                              child: const Text("DETAILS",
                                style: TextStyle(color: Colors.white70, fontSize: 9,
                                  fontWeight: FontWeight.w800, fontFamily: "CinzelDecorative", letterSpacing: 1)),
                            ),
                          ]),
                        ]),
                      ),
                    ],
                  ),
                ),
              );
            },
          ),
        ),
        if (dummyNews.length > 1)
          Padding(
            padding: const EdgeInsets.only(top: 16),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: List.generate(dummyNews.length, (index) => AnimatedContainer(
                duration: const Duration(milliseconds: 250),
                margin: const EdgeInsets.symmetric(horizontal: 4),
                height: 5, width: _currentNewsIndex == index ? 24 : 6,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(8),
                  color: _currentNewsIndex == index ? _glowColor1.withOpacity(0.7) : Colors.white.withOpacity(0.15),
                ),
              )),
            ),
          ),
      ],
    );
  }

  Widget _buildRecentActivity() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 18),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildSectionHeader(Icons.history, "ACTIVITY LOG"),
          const SizedBox(height: 18),
          if (_isLoadingActivityLogs)
            _buildGlassPlaceholder(child: CircularProgressIndicator(color: _glowColor1, strokeWidth: 2))
          else if (_hasActivityLogsError)
            _buildGlassPlaceholder(child: Text("Failed to load logs",
              style: _cinzel(12, FontWeight.w500, 0.4)))
          else if (_activityLogs.isEmpty)
            _buildGlassPlaceholder(child: Text("No activity logs",
              style: _cinzel(12, FontWeight.w500, 0.3)))
          else
            ..._activityLogs.take(5).map((log) {
              final timestamp = DateTime.tryParse(log['timestamp'] ?? '') ?? DateTime.now();
              final formattedTime = _formatDateTime(timestamp);
              String activityText = log['activity'] ?? 'Unknown Activity';
              return Container(
                margin: const EdgeInsets.only(bottom: 12),
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: _cardColor,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: Colors.white.withOpacity(0.06), width: 1),
                ),
                child: Row(children: [
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: _glowColor1.withOpacity(0.08),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Icon(Icons.notifications, color: _glowColor1.withOpacity(0.6), size: 18),
                  ),
                  const SizedBox(width: 14),
                  Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                    Text(activityText,
                      style: _cinzel(12, FontWeight.w600, 1.0),
                      maxLines: 1, overflow: TextOverflow.ellipsis),
                    const SizedBox(height: 4),
                    Text(formattedTime,
                      style: _cinzel(10, FontWeight.w500, 0.3)),
                  ])),
                  Icon(Icons.chevron_right, color: Colors.white.withOpacity(0.2), size: 18),
                ]),
              );
            }).toList(),
        ],
      ),
    );
  }

  Widget _buildGlassPlaceholder({required Widget child}) {
    return Container(
      height: 120,
      decoration: BoxDecoration(
        color: _cardColor,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: Colors.white.withOpacity(0.06)),
      ),
      child: Center(child: child),
    );
  }

  String _formatDateTime(DateTime dateTime) {
    final diff = DateTime.now().difference(dateTime);
    if (diff.inDays > 0) return '${diff.inDays}d ago';
    if (diff.inHours > 0) return '${diff.inHours}h ago';
    if (diff.inMinutes > 0) return '${diff.inMinutes}m ago';
    return 'Just now';
  }

  void _showAccountMenu() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (_) => Container(
        margin: const EdgeInsets.all(18),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(28),
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20),
            child: Container(
              padding: const EdgeInsets.all(26),
              decoration: BoxDecoration(
                color: _surfaceColor.withOpacity(0.97),
                border: Border.all(color: _glowColor1.withOpacity(0.15), width: 1),
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(width: 50, height: 4,
                    decoration: BoxDecoration(color: Colors.white.withOpacity(0.15), borderRadius: BorderRadius.circular(8))),
                  const SizedBox(height: 24),
                  Container(
                    width: 70, height: 70,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle, color: _cardColor,
                      border: Border.all(color: _glowColor1.withOpacity(0.25), width: 1.5),
                      boxShadow: [BoxShadow(color: _glowColor1.withOpacity(0.2), blurRadius: 20)],
                    ),
                    child: Center(
                      child: Text(
                        username.isNotEmpty ? username[0].toUpperCase() : "U",
                        style: _cinzel(32, FontWeight.w800, 1.0).copyWith(color: _glowColor1),
                      ),
                    ),
                  ),
                  const SizedBox(height: 14),
                  Text("PROFILE", style: _cinzel(18, FontWeight.w800, 0.9)),
                  const SizedBox(height: 24),
                  _buildInfoRow(Icons.person, "USERNAME", username),
                  const SizedBox(height: 10),
                  _buildInfoRow(Icons.calendar_today, "EXPIRES", expiredDate),
                  const SizedBox(height: 10),
                  _buildInfoRow(Icons.security, "ROLE", role),
                  const SizedBox(height: 24),
                  Row(children: [
                    Expanded(child: _buildMenuButton(
                      icon: Icons.lock_reset, label: "CHANGE PW",
                      onTap: () {
                        Navigator.pop(context);
                        setState(() {
                          _activePage = 'change_password';
                          _selectedPage = ChangePasswordPage(username: username, sessionKey: sessionKey);
                          _controller.reset(); _controller.forward();
                        });
                      },
                      color: _goldColor,
                    )),
                    const SizedBox(width: 12),
                    Expanded(child: _buildMenuButton(
                      icon: Icons.logout, label: "EXIT",
                      onTap: () async {
                        final prefs = await SharedPreferences.getInstance();
                        await prefs.clear();
                        if (!mounted) return;
                        Navigator.of(context).pushAndRemoveUntil(
                          MaterialPageRoute(builder: (_) => const LoginPage()), (route) => false);
                      },
                      color: _roseColor,
                    )),
                  ]),
                  const SizedBox(height: 16),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildInfoRow(IconData icon, String label, String value) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      decoration: BoxDecoration(
        color: _cardColor, borderRadius: BorderRadius.circular(14),
        border: Border.all(color: Colors.white.withOpacity(0.06), width: 1),
      ),
      child: Row(children: [
        Icon(icon, color: _glowColor1.withOpacity(0.5), size: 18),
        const SizedBox(width: 12),
        Text(label, style: _cinzel(12, FontWeight.w700, 0.4)),
        const Spacer(),
        Text(value, style: _cinzel(12, FontWeight.w600, 1.0)),
      ]),
    );
  }

  Widget _buildMenuButton({required IconData icon, required String label, required VoidCallback onTap, required Color color}) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 14),
        decoration: BoxDecoration(
          color: color.withOpacity(0.1),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: color.withOpacity(0.25), width: 1),
        ),
        child: Row(mainAxisAlignment: MainAxisAlignment.center, children: [
          Icon(icon, color: color.withOpacity(0.8), size: 18),
          const SizedBox(width: 8),
          Text(label, style: _cinzel(12, FontWeight.w800, 0.9).copyWith(color: color.withOpacity(0.9))),
        ]),
      ),
    );
  }

  Widget _buildAssistiveMenu() {
    final String currentRole = role.toLowerCase();
    final bool canAccessAdmin = ['founder', 'moderator', 'high admin', 'owner'].contains(currentRole);
    final bool canAccessSeller = ['founder', 'moderator', 'high admin', 'owner', 'reseller'].contains(currentRole);
    final bool canAccessAllBugs = ['founder', 'moderator', 'high admin', 'owner'].contains(currentRole);
    final bool canAccessResellerBugs = ['reseller'].contains(currentRole);
    final bool isMember = !canAccessAllBugs && !canAccessResellerBugs;

    return Container(
      width: 270,
      decoration: BoxDecoration(
        color: _surfaceColor.withOpacity(0.97),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: _glowColor1.withOpacity(0.12), width: 1),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.6), blurRadius: 30)],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(24),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20),
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SizedBox(height: 14),
                _buildMenuItem(Icons.home, "HOME", 'home'),
                _buildMenuItem(Icons.movie, "ANIME", 'anime'),
                Theme(
                  data: Theme.of(context).copyWith(dividerColor: Colors.transparent),
                  child: ExpansionTile(
                    tilePadding: const EdgeInsets.symmetric(horizontal: 16),
                    leading: FaIcon(FontAwesomeIcons.whatsapp, color: _glowColor3.withOpacity(0.7), size: 18),
                    title: Text("BUG TOOLS", style: _cinzel(13, FontWeight.w800, 0.85)),
                    trailing: Icon(_isBugToolsExpanded ? Icons.keyboard_arrow_up : Icons.keyboard_arrow_down,
                      color: Colors.white.withOpacity(0.4), size: 20),
                    onExpansionChanged: (bool expanded) {
                      setState(() => _isBugToolsExpanded = expanded);
                      if (isMember && expanded) { setState(() => _isBugToolsExpanded = false); _selectFromDrawer('bug'); }
                    },
                    children: [
                      if (!isMember)
                        Padding(
                          padding: const EdgeInsets.only(left: 36, bottom: 10),
                          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                            if (canAccessAllBugs || canAccessResellerBugs) ...[
                              _buildSubMenuItem(FontAwesomeIcons.usersSlash, "GROUP BUG", 'group_bug'),
                              const SizedBox(height: 4),
                            ],
                            if (canAccessAllBugs) ...[
                              _buildSubMenuItem(Icons.terminal, "CUSTOM BUG", 'custom_bug'),
                              const SizedBox(height: 4),
                            ],
                            _buildSubMenuItem(Icons.bolt, "BASIC BUG", 'bug'),
                          ]),
                        ),
                    ],
                  ),
                ),
                _buildMenuItem(FontAwesomeIcons.paperPlane, "SPAM", 'telegram'),
                _buildMenuItem(Icons.phone_android, "RAT", 'rat'),
                _buildMenuItem(FontAwesomeIcons.screwdriverWrench, "TOOLS", 'tools'),
                _buildMenuItem(Icons.security, "DDOS", 'ddos'),
                Divider(color: Colors.white.withOpacity(0.06), height: 20, thickness: 1),
                _buildMenuItem(Icons.person, "ACCOUNT", 'account'),
                if (canAccessSeller) _buildMenuItem(Icons.store, "SELLER", 'reseller'),
                if (canAccessAdmin) _buildMenuItem(Icons.admin_panel_settings, "ADMIN", 'admin'),
                _buildMenuItem(FontAwesomeIcons.whatsapp, "SENDER", 'sender'),
                const SizedBox(height: 16),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildMenuItem(IconData icon, String title, String page) {
    bool isActive = _activePage == page;
    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        splashColor: Colors.white.withOpacity(0.04),
        onTap: () => _selectFromDrawer(page),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
          decoration: isActive
              ? BoxDecoration(
                  color: _glowColor1.withOpacity(0.08),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: _glowColor1.withOpacity(0.2), width: 1),
                )
              : null,
          child: Row(children: [
            Icon(icon, color: isActive ? _glowColor1.withOpacity(0.85) : Colors.white.withOpacity(0.45), size: 18),
            const SizedBox(width: 14),
            Expanded(child: Text(title, style: _cinzel(13, isActive ? FontWeight.w800 : FontWeight.w600, isActive ? 0.9 : 0.75))),
            if (isActive)
              Container(width: 7, height: 7,
                decoration: BoxDecoration(color: _glowColor1.withOpacity(0.7), shape: BoxShape.circle,
                  boxShadow: [BoxShadow(color: _glowColor1.withOpacity(0.5), blurRadius: 6)])),
          ]),
        ),
      ),
    );
  }

  Widget _buildSubMenuItem(IconData icon, String title, String page) {
    bool isActive = _activePage == page;
    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.circular(10),
        onTap: () => _selectFromDrawer(page),
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 8),
          child: Row(children: [
            Container(
              width: 26, height: 26,
              decoration: BoxDecoration(
                color: isActive ? _glowColor1.withOpacity(0.12) : Colors.white.withOpacity(0.06),
                shape: BoxShape.circle,
              ),
              child: Icon(icon, color: isActive ? _glowColor1.withOpacity(0.8) : Colors.white.withOpacity(0.4), size: 13),
            ),
            const SizedBox(width: 12),
            Text(title, style: _cinzel(12, isActive ? FontWeight.w800 : FontWeight.w600, isActive ? 0.85 : 0.5)),
          ]),
        ),
      ),
    );
  }

  Widget _buildBottomNavBar() {
    return Positioned(
      bottom: 16, left: 16, right: 16,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 6, horizontal: 10),
        decoration: BoxDecoration(
          color: _surfaceColor.withOpacity(0.96),
          borderRadius: BorderRadius.circular(22),
          border: Border.all(color: _glowColor1.withOpacity(0.1), width: 1),
          boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.5), blurRadius: 20)],
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(22),
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                _buildNavItem(Icons.home_filled, "HOME", 'home'),
                _buildNavItem(FontAwesomeIcons.whatsapp, "BUG", 'bug'),
                _buildNavItem(FontAwesomeIcons.paperPlane, "SPAM", 'telegram'),
                _buildNavItem(Icons.android, "RAT", 'rat'),
                _buildNavItem(Icons.menu, "MENU", 'more'),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildNavItem(IconData icon, String label, String page) {
    bool isActive = _activePage == page ||
        (page == 'bug' && (_activePage == 'group_bug' || _activePage == 'custom_bug'));
    return GestureDetector(
      onTap: () {
        if (page == 'more') {
          _showMoreMenu();
        } else if (page == 'bug') {
          _showBugOptionsSheet();
        } else {
          _selectFromDrawer(page);
        }
      },
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 9),
        decoration: isActive
            ? BoxDecoration(
                color: _glowColor1.withOpacity(0.1),
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: _glowColor1.withOpacity(0.25), width: 1),
              )
            : null,
        child: Column(mainAxisSize: MainAxisSize.min, children: [
          Icon(icon,
            color: isActive ? _glowColor1.withOpacity(0.9) : Colors.white.withOpacity(0.35),
            size: 22),
          if (isActive) ...[
            const SizedBox(height: 4),
            Text(label, style: _cinzel(9, FontWeight.w800, 0.8).copyWith(color: _glowColor1.withOpacity(0.8))),
          ],
        ]),
      ),
    );
  }

  void _showBugOptionsSheet() {
    final String currentRole = role.toLowerCase();
    final List<String> allowedGroupRoles = ['founder', 'moderator', 'high admin', 'owner', 'reseller', 'vip'];
    final bool canAccessGroup = allowedGroupRoles.contains(currentRole);

    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (_) => Container(
        margin: const EdgeInsets.all(20),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(26),
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20),
            child: Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: _surfaceColor.withOpacity(0.97),
                border: Border.all(color: _glowColor1.withOpacity(0.12), width: 1),
              ),
              child: Column(mainAxisSize: MainAxisSize.min, children: [
                Container(width: 44, height: 4,
                  decoration: BoxDecoration(color: Colors.white.withOpacity(0.12), borderRadius: BorderRadius.circular(8))),
                const SizedBox(height: 20),
                Text("SELECT BUG TYPE",
                  style: _cinzel(16, FontWeight.w800, 0.85)),
                const SizedBox(height: 24),
                _buildBugOption(Icons.person_outline, "CONTACT BUG", () { Navigator.pop(context); _selectFromDrawer('bug'); }),
                if (canAccessGroup) ...[
                  const SizedBox(height: 12),
                  _buildBugOption(FontAwesomeIcons.usersSlash, "GROUP BUG", () { Navigator.pop(context); _selectFromDrawer('group_bug'); }),
                ],
                const SizedBox(height: 16),
              ]),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildBugOption(IconData icon, String title, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: _cardColor, borderRadius: BorderRadius.circular(16),
          border: Border.all(color: _glowColor1.withOpacity(0.1), width: 1),
        ),
        child: Row(children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: _glowColor1.withOpacity(0.08), borderRadius: BorderRadius.circular(12)),
            child: Icon(icon, color: _glowColor1.withOpacity(0.7), size: 22),
          ),
          const SizedBox(width: 16),
          Text(title, style: _cinzel(14, FontWeight.w800, 1.0)),
          const Spacer(),
          Icon(Icons.chevron_right, color: Colors.white.withOpacity(0.2), size: 20),
        ]),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final screenSize = MediaQuery.of(context).size;
    final bool isRightSide = _assistiveTouchPosition.dx > (screenSize.width / 2);
    final bool isBottomSide = _assistiveTouchPosition.dy > (screenSize.height / 2);

    return WillPopScope(
      onWillPop: () async {
        if (_activePage != 'home') { _selectFromDrawer('home'); return false; }
        return true;
      },
      child: Scaffold(
        key: _scaffoldKey,
        extendBodyBehindAppBar: true,
        backgroundColor: _darkerBg,
        body: Stack(
          children: [
            Container(color: _darkerBg),

            SafeArea(
              top: false, bottom: false,
              child: FadeTransition(opacity: _animation, child: _selectedPage),
            ),

            if (_activePage == 'home' || _activePage == 'settings')
              Positioned(top: 0, left: 0, right: 0, child: _buildHeader()),

            if (_showAssistiveTouch) ...[
              if (_isAssistiveMenuOpen)
                Positioned.fill(
                  child: GestureDetector(
                    onTap: () => setState(() { _isAssistiveMenuOpen = false; _isBugToolsExpanded = false; }),
                    child: Container(color: Colors.transparent),
                  ),
                ),
              AnimatedPositioned(
                duration: const Duration(milliseconds: 150),
                left: isRightSide ? _assistiveTouchPosition.dx - 290 : _assistiveTouchPosition.dx + 72,
                top: isBottomSide ? _assistiveTouchPosition.dy - 420 : _assistiveTouchPosition.dy,
                child: AnimatedScale(
                  scale: _isAssistiveMenuOpen ? 1.0 : 0.0,
                  duration: const Duration(milliseconds: 220),
                  curve: Curves.easeOutBack,
                  alignment: isRightSide
                      ? (isBottomSide ? Alignment.bottomRight : Alignment.topRight)
                      : (isBottomSide ? Alignment.bottomLeft : Alignment.topLeft),
                  child: _buildAssistiveMenu(),
                ),
              ),
              Positioned(
                left: _assistiveTouchPosition.dx,
                top: _assistiveTouchPosition.dy,
                child: GestureDetector(
                  onPanUpdate: (details) {
                    setState(() {
                      if (_isAssistiveMenuOpen) { _isAssistiveMenuOpen = false; _isBugToolsExpanded = false; }
                      double newX = (_assistiveTouchPosition.dx + details.delta.dx).clamp(0.0, screenSize.width - 62.0);
                      double newY = (_assistiveTouchPosition.dy + details.delta.dy).clamp(0.0, screenSize.height - 128.0);
                      _assistiveTouchPosition = Offset(newX, newY);
                    });
                  },
                  onTap: () => setState(() {
                    _isAssistiveMenuOpen = !_isAssistiveMenuOpen;
                    if (!_isAssistiveMenuOpen) _isBugToolsExpanded = false;
                  }),
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 200),
                    width: 60, height: 60,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: _isAssistiveMenuOpen ? _glowColor1.withOpacity(0.15) : _cardColor,
                      border: Border.all(
                        color: _isAssistiveMenuOpen ? _glowColor1.withOpacity(0.45) : _glowColor1.withOpacity(0.12),
                        width: 1.5,
                      ),
                      boxShadow: [
                        BoxShadow(color: Colors.black.withOpacity(0.5), blurRadius: 16),
                        if (_isAssistiveMenuOpen)
                          BoxShadow(color: _glowColor1.withOpacity(0.2), blurRadius: 24),
                      ],
                    ),
                    child: ClipOval(
                      child: Padding(
                        padding: const EdgeInsets.all(13),
                        child: Image.asset('assets/images/logo.png', fit: BoxFit.contain),
                      ),
                    ),
                  ),
                ),
              ),
            ],

            if (_showBottomNav) _buildBottomNavBar(),
          ],
        ),
      ),
    );
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    channel.sink.close(status.goingAway);
    _controller.dispose();
    _pageController.dispose();
    _actionPageController.dispose();
    _newsPageController.dispose();
    _videoController?.dispose();
    _statsVideoController?.dispose();
    _otaxVideoController?.dispose();
    _audioPlayer.dispose();
    SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);
    super.dispose();
  }
}

class NewsMedia extends StatefulWidget {
  final String url;
  const NewsMedia({super.key, required this.url});

  @override
  State<NewsMedia> createState() => _NewsMediaState();
}

class _NewsMediaState extends State<NewsMedia> {
  VideoPlayerController? _controller;

  @override
  void initState() {
    super.initState();
    if (_isVideo(widget.url)) {
      _controller = VideoPlayerController.networkUrl(Uri.parse(widget.url))
        ..initialize().then((_) {
          if (!mounted) return;
          setState(() {});
          _controller?.setLooping(true);
          _controller?.setVolume(0.0);
          _controller?.play();
        });
    }
  }

  bool _isVideo(String url) =>
      url.endsWith(".mp4") || url.endsWith(".webm") || url.endsWith(".mov") || url.endsWith(".mkv");

  @override
  void dispose() { _controller?.dispose(); super.dispose(); }

  @override
  Widget build(BuildContext context) {
    if (_isVideo(widget.url)) {
      if (_controller != null && _controller!.value.isInitialized) {
        return AspectRatio(aspectRatio: _controller!.value.aspectRatio, child: VideoPlayer(_controller!));
      } else {
        return Center(child: CircularProgressIndicator(color: const Color(0xFFE0E0F8).withOpacity(0.6), strokeWidth: 2));
      }
    } else {
      return Image.network(
        widget.url, fit: BoxFit.cover,
        errorBuilder: (_, __, ___) => Container(
          color: const Color(0xFF111118),
          child: const Center(child: Icon(Icons.broken_image, color: Colors.white12, size: 36))),
      );
    }
  }
}