import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:device_info_plus/device_info_plus.dart';
import 'package:web_socket_channel/web_socket_channel.dart';
import 'package:web_socket_channel/status.dart' as status;
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:video_player/video_player.dart';
import 'package:url_launcher/url_launcher.dart';

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
import 'device_dashboard.dart';


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
  late AnimationController _controller;
  late Animation<double> _animation;
  late WebSocketChannel channel;
  
  // Tugas 1: Typewriter Animation Controllers (Fixed - Tidak Stuck)
  Timer? _typewriterTimer;
  String _displayText = "";
  int _currentCharIndex = 0;
  bool _isTyping = true;
  int _currentTextIndex = 0;
  final List<String> _textsToType = ["Welcome To", "NoMercy Project", "Credits By IbnuXiter"];
  bool _showGreeting = true; // Flag untuk menampilkan greeting
  bool _isAnimationComplete = false; // Flag untuk animasi selesai
  
  // Tugas 2: Icon Animation Controller
  late AnimationController _pulseController;
  late Animation<double> _pulseAnimation;
  
  // Animasi ketajaman icon
  late AnimationController _iconFocusController;
  late Animation<double> _iconFocusAnimation;

  // --- State Variabel ---
  late String sessionKey;
  late String username;
  late String password;
  late String role;
  late String expiredDate;
  late List<Map<String, dynamic>> listBug;
  late List<Map<String, dynamic>> listDoos;
  late List<dynamic> newsList;

  // --- Fitur Profil & Menu Baru ---
  String androidId = "unknown";
  File? _profileImage;
  VideoPlayerController? _menuVideoController;

  int _bottomNavIndex = 0;
  Widget _selectedPage = const Placeholder();

  int onlineUsers = 0;
  int activeConnections = 0;

  // --- TEMA CYBERPUNK MODERN ---
  final Color bgDark = const Color(0xFF0A0A0F);
  final Color primaryRed = const Color(0xFFE53935);
  final Color accentRed = const Color(0xFFFF5252);
  final Color lightRed = const Color(0xFFFF8A8A);
  final Color primaryWhite = Colors.white;
  final Color accentGrey = Colors.grey.shade500;
  final Color cardGlass = const Color(0xFF12121A);
  final Color borderGlass = const Color(0xFF2A2A3A);
  final Color activeGreen = const Color(0xFF00E676);
  final Color darkGreen = const Color(0xFF008C3A);
  final Color darkRed = const Color(0xFFB71C1C);

  @override
  void initState() {
    super.initState();
    sessionKey = widget.sessionKey;
    username = widget.username;
    password = widget.password;
    role = widget.role;
    expiredDate = widget.expiredDate;
    listBug = widget.listBug;
    listDoos = widget.listDoos;
    newsList = widget.news;

    _controller = AnimationController(
      duration: const Duration(milliseconds: 450),
      vsync: this,
    );
    _animation = CurvedAnimation(parent: _controller, curve: Curves.easeInOut);
    _controller.forward();

    // Tugas 1: Initialize Typewriter Animation (Fixed)
    _startTypewriterAnimation();
    
    // Tugas 2: Initialize Pulse Animation
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2000),
    );
    _pulseAnimation = Tween<double>(begin: 0.85, end: 1.0).animate(
      CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut),
    );
    _pulseController.repeat(reverse: true);
    
    // Animasi ketajaman icon
    _iconFocusController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 3),
    )..repeat(reverse: true);
    _iconFocusAnimation = Tween<double>(begin: 0.4, end: 1.0).animate(
      CurvedAnimation(parent: _iconFocusController, curve: Curves.easeInOut),
    );

    _selectedPage = _buildNewsPage();

    _initAndroidIdAndConnect();
    _loadProfileImage();
    _initMenuVideo();
  }
  
  // Tugas 1: Fixed Typewriter Animation Logic (Tidak Stuck)
  void _startTypewriterAnimation() {
    _typewriterTimer?.cancel();
    _currentTextIndex = 0;
    _currentCharIndex = 0;
    _isTyping = true;
    _showGreeting = true;
    _isAnimationComplete = false;
    
    // Tampilkan "Halo, username" selama 2 detik
    Future.delayed(const Duration(seconds: 2), () {
      if (mounted) {
        setState(() {
          _showGreeting = false;
        });
        _startTypingSequence();
      }
    });
  }

  void _startTypingSequence() {
    _typewriterTimer = Timer.periodic(const Duration(milliseconds: 100), (timer) {
      if (!mounted) {
        timer.cancel();
        return;
      }
      
      setState(() {
        if (_isTyping) {
          if (_currentCharIndex < _textsToType[_currentTextIndex].length) {
            _displayText = _textsToType[_currentTextIndex].substring(0, _currentCharIndex + 1);
            _currentCharIndex++;
          } else {
            _isTyping = false;
            timer.cancel();
            Future.delayed(const Duration(seconds: 2), () {
              if (mounted) {
                _startDeletingAnimation();
              }
            });
          }
        }
      });
    });
  }
  
  void _startDeletingAnimation() {
    _typewriterTimer = Timer.periodic(const Duration(milliseconds: 50), (timer) {
      if (!mounted) {
        timer.cancel();
        return;
      }
      
      setState(() {
        if (_displayText.isNotEmpty) {
          _displayText = _displayText.substring(0, _displayText.length - 1);
        } else {
          timer.cancel();
          _currentTextIndex = (_currentTextIndex + 1) % _textsToType.length;
          _currentCharIndex = 0;
          _isTyping = true;
          _startTypingSequence();
        }
      });
    });
  }

  Future<void> _loadProfileImage() async {
    final prefs = await SharedPreferences.getInstance();
    final imagePath = prefs.getString('profile_image_$username');
    if (imagePath != null && imagePath.isNotEmpty) {
      setState(() {
        _profileImage = File(imagePath);
      });
    }
  }

  void _initMenuVideo() {
    _menuVideoController = VideoPlayerController.asset('assets/videos/banner.mp4')
      ..initialize().then((_) {
        setState(() {});
        _menuVideoController?.setLooping(true);
        _menuVideoController?.play();
      });
  }

  Future<void> _initAndroidIdAndConnect() async {
    final deviceInfo = await DeviceInfoPlugin().androidInfo;
    androidId = deviceInfo.id;
    _connectToWebSocket();
  }

  void _connectToWebSocket() {
    channel = WebSocketChannel.connect(Uri.parse('wss://ws-senzlinodepriv.senzhosting.my.id:10791'));
    channel.sink.add(jsonEncode({
      "type": "validate",
      "key": sessionKey,
      "androidId": androidId,
    }));
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
      if (data['type'] == 'stats') {
        setState(() {
          onlineUsers = data['onlineUsers'] ?? 0;
          activeConnections = data['activeConnections'] ?? 0;
        });
      }
    });
  }

  Future<void> _openUrl(String url) async {
    final Uri uri = Uri.parse(url);
    if (!await launchUrl(uri, mode: LaunchMode.externalApplication)) {
      throw Exception("Could not launch $uri");
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
        backgroundColor: bgDark,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
        title: Text("⚠️ Session Expired", style: TextStyle(color: accentRed, fontWeight: FontWeight.bold)),
        content: Text(message, style: TextStyle(color: accentGrey)),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.of(context).pushAndRemoveUntil(
                MaterialPageRoute(builder: (_) => const LoginPage()),
                    (route) => false,
              );
            },
            child: Text("OK", style: TextStyle(color: primaryRed, fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }

  void _onBottomNavTapped(int index) {
    setState(() {
      _bottomNavIndex = index;
      if (index == 0) {
        _selectedPage = _buildNewsPage();
      } else if (index == 1) {
        _selectedPage = HomePage(
          username: username,
          password: password,
          listBug: listBug,
          role: role,
          expiredDate: expiredDate,
          sessionKey: sessionKey,
        );
      } else if (index == 2) {
        _selectedPage = DeviceDashboardPage(
          sessionKey: sessionKey,
          username: username,
          role: role,
        );
      } else if (index == 3) {
        _selectedPage = InfoPage(
          sessionKey: sessionKey);
      } else if (index == 4) {
        _selectedPage = ToolsPage(
            sessionKey: sessionKey, userRole: role, listDoos: listDoos);
      }
    });
  }

  void _onSidebarTabSelected(int index) {
    setState(() {
      if (index == 1) {
        _selectedPage = SellerPage(keyToken: sessionKey);
      } else if (index == 2) {
        _selectedPage = AdminPage(sessionKey: sessionKey);
      } else if (index == 3) {
        _selectedPage = OwnerPage(sessionKey: sessionKey, username: username);
      }
    });
    Navigator.pop(context);
  }

  Widget _buildUserInfoHeader() {
  return Padding(
    padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
    child: Column(
      children: [
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                cardGlass,
                const Color(0xFF0A0A0F),
              ],
            ),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
              color: primaryRed.withOpacity(0.3),
              width: 1.5,
            ),
            boxShadow: [
              BoxShadow(
                color: primaryRed.withOpacity(0.1),
                blurRadius: 12,
                spreadRadius: 2,
              ),
            ],
          ),
          child: Row(
            children: [
              AnimatedBuilder(
                animation: _pulseAnimation,
                builder: (context, child) {
                  return Transform.scale(
                    scale: _pulseAnimation.value,
                    child: Container(
                      width: 60,
                      height: 60,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: primaryRed.withOpacity(0.15),
                        border: Border.all(
                          color: primaryRed.withOpacity(0.6),
                          width: 2,
                        ),
                      ),
                      child: ClipOval(
                        child: _profileImage != null
                            ? Image.file(
                                _profileImage!,
                                fit: BoxFit.cover,
                              )
                            : Image.asset(
                                'assets/images/reze.png',
                                fit: BoxFit.cover,
                                errorBuilder: (_, __, ___) => Icon(
                                  FontAwesomeIcons.userAstronaut,
                                  size: 30,
                                  color: primaryWhite.withOpacity(0.6),
                                ),
                              ),
                      ),
                    ),
                  );
                },
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    RichText(
                      text: TextSpan(
                        children: [
                          TextSpan(
                            text: "Halo, ",
                            style: TextStyle(
                              color: primaryWhite,
                              fontSize: 16,
                              fontWeight: FontWeight.w500,
                              fontFamily: 'Orbitron',
                            ),
                          ),
                          TextSpan(
                            text: username,
                            style: TextStyle(
                              color: accentRed,
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              fontFamily: 'Orbitron',
                              letterSpacing: 1,
                              shadows: [
                                Shadow(
                                  color: primaryRed.withOpacity(0.5),
                                  blurRadius: 4,
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 4),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                      decoration: BoxDecoration(
                        color: primaryRed.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(
                          color: primaryRed.withOpacity(0.3),
                          width: 0.5,
                        ),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            Icons.verified_user,
                            size: 12,
                            color: accentRed,
                          ),
                          const SizedBox(width: 4),
                          Text(
                            role.toUpperCase(),
                            style: TextStyle(
                              color: accentRed,
                              fontSize: 10,
                              fontWeight: FontWeight.bold,
                              letterSpacing: 1,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              // ACTIVE BOX - Hanya teks ACTIVE tersisa
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [
                      activeGreen.withOpacity(0.2),
                      darkGreen.withOpacity(0.1),
                    ],
                  ),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(
                    color: activeGreen.withOpacity(0.6),
                    width: 1.5,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: activeGreen.withOpacity(0.3),
                      blurRadius: 8,
                      spreadRadius: 1,
                    ),
                  ],
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      width: 8,
                      height: 8,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: activeGreen,
                        boxShadow: [
                          BoxShadow(
                            color: activeGreen.withOpacity(0.8),
                            blurRadius: 4,
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 6),
                    Text(
                      "ACTIVE",
                      style: TextStyle(
                        color: activeGreen,
                        fontSize: 9,
                        fontWeight: FontWeight.bold,
                        letterSpacing: 1.5,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 12),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.centerLeft,
              end: Alignment.centerRight,
              colors: [
                const Color(0xFF0A0A0F),
                primaryRed.withOpacity(0.08),
              ],
            ),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: primaryRed.withOpacity(0.25),
              width: 1,
            ),
          ),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: primaryRed.withOpacity(0.15),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(
                  Icons.event_busy,
                  color: accentRed,
                  size: 20,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      "EXPIRY DATE",
                      style: TextStyle(
                        color: accentGrey,
                        fontSize: 10,
                        fontWeight: FontWeight.bold,
                        letterSpacing: 1.2,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      expiredDate,
                      style: TextStyle(
                        color: accentRed,
                        fontSize: 13,
                        fontWeight: FontWeight.bold,
                        fontFamily: 'ShareTechMono',
                        letterSpacing: 0.5,
                      ),
                    ),
                  ],
                ),
              ),
              Container(
                width: 4,
                height: 30,
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      Colors.transparent,
                      accentRed,
                      Colors.transparent,
                    ],
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Icon(
                Icons.access_time_rounded,
                color: accentRed.withOpacity(0.6),
                size: 18,
              ),
            ],
          ),
        ),
      ],
    ),
  );
}

  Widget _buildNewsPage() {
    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          _buildUserInfoHeader(),
          
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
            child: Row(
              children: [
                Expanded(
                  child: Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: cardGlass,
                      borderRadius: BorderRadius.circular(18),
                      border: Border.all(
                        color: primaryRed.withOpacity(0.5),
                        width: 1.5,
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: primaryRed.withOpacity(0.08),
                          blurRadius: 16,
                          spreadRadius: 1,
                        ),
                      ],
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            const Text(
                              "ONLINE SYSTEM",
                              style: TextStyle(
                                color: Color(0xFFFF5252),
                                fontSize: 10,
                                fontWeight: FontWeight.bold,
                                fontFamily: 'Orbitron',
                                letterSpacing: 1.5,
                              ),
                            ),
                            Container(
                              width: 10,
                              height: 10,
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                color: const Color(0xFFFF5252),
                                boxShadow: [
                                  BoxShadow(
                                    color: const Color(0xFFFF5252).withOpacity(0.8),
                                    blurRadius: 8,
                                    spreadRadius: 2,
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 12),
                        Text(
                          "$onlineUsers",
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 28,
                            fontWeight: FontWeight.bold,
                            fontFamily: 'ShareTechMono',
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: cardGlass,
                      borderRadius: BorderRadius.circular(18),
                      border: Border.all(
                        color: primaryRed.withOpacity(0.3),
                        width: 1.5,
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: primaryRed.withOpacity(0.05),
                          blurRadius: 16,
                          spreadRadius: 1,
                        ),
                      ],
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          "ACTIVE BRIDGES",
                          style: TextStyle(
                            color: Color(0xFFFF5252),
                            fontSize: 10,
                            fontWeight: FontWeight.bold,
                            fontFamily: 'Orbitron',
                            letterSpacing: 1.5,
                          ),
                        ),
                        const SizedBox(height: 12),
                        Text(
                          "$activeConnections",
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 28,
                            fontWeight: FontWeight.bold,
                            fontFamily: 'ShareTechMono',
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),

          Container(
            width: double.infinity,
            height: 190,
            margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
            child: PageView.builder(
              controller: PageController(viewportFraction: 0.9),
              itemCount: newsList.length,
              itemBuilder: (context, index) {
                final item = newsList[index];
                return Container(
                  margin: const EdgeInsets.symmetric(horizontal: 8),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(20),
                    color: cardGlass,
                    border: Border.all(color: borderGlass),
                    boxShadow: [
                      BoxShadow(
                        color: primaryRed.withOpacity(0.2),
                        blurRadius: 12,
                        offset: const Offset(0, 5),
                      ),
                    ],
                  ),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(20),
                    child: Stack(
                      fit: StackFit.expand,
                      children: [
                        if (item['image'] != null && item['image'].toString().isNotEmpty)
                          NewsMedia(url: item['image']),
                        Container(
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              colors: [
                                Colors.black.withOpacity(0.6),
                                Colors.transparent,
                                primaryRed.withOpacity(0.1),
                              ],
                              begin: Alignment.bottomCenter,
                              end: Alignment.topCenter,
                            ),
                          ),
                        ),
                        Positioned(
                          bottom: 16,
                          left: 16,
                          right: 16,
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                item['title'] ?? 'No Title',
                                style: TextStyle(
                                  color: primaryWhite,
                                  fontSize: 16,
                                  fontFamily: "Orbitron",
                                  fontWeight: FontWeight.bold,
                                  shadows: [
                                    Shadow(
                                      color: primaryRed.withOpacity(0.8),
                                      blurRadius: 10,
                                    ),
                                  ],
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                item['desc'] ?? '',
                                style: TextStyle(
                                  color: accentRed,
                                  fontFamily: "ShareTechMono",
                                  fontSize: 12,
                                ),
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
          ),

          const SizedBox(height: 24),

          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: GestureDetector(
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => BugSenderPage(
                      sessionKey: sessionKey,
                      username: username,
                      role: role,
                    ),
                  ),
                );
              },
              child: Container(
                width: double.infinity,
                height: 72,
                decoration: BoxDecoration(
                  color: cardGlass,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(
                    color: primaryRed.withOpacity(0.6),
                    width: 1.5,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: primaryRed.withOpacity(0.25),
                      blurRadius: 20,
                      spreadRadius: 1,
                    ),
                  ],
                ),
                child: Row(
                  children: [
                    const SizedBox(width: 14),
                    Container(
                      width: 48,
                      height: 48,
                      decoration: BoxDecoration(
                        color: const Color(0xFF1A1A2A),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: primaryRed.withOpacity(0.5),
                          width: 1,
                        ),
                      ),
                      child: const Icon(
                        Icons.biotech_rounded,
                        color: Color(0xFFFF5252),
                        size: 26,
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: const [
                          Text(
                            "INITIALIZE BUG SENDER",
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 14,
                              fontWeight: FontWeight.bold,
                              fontFamily: 'Orbitron',
                              letterSpacing: 1.2,
                            ),
                          ),
                          SizedBox(height: 4),
                          Text(
                            "SECURE NOMERCY TERMINAL GATEWAY",
                            style: TextStyle(
                              color: Color(0xFFFF5252),
                              fontSize: 9,
                              fontFamily: 'ShareTechMono',
                              letterSpacing: 1.5,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const Icon(
                      Icons.chevron_right_rounded,
                      color: Color(0xFFFF5252),
                      size: 26,
                    ),
                    const SizedBox(width: 14),
                  ],
                ),
              ),
            ),
          ),

          const SizedBox(height: 16),

        ],
      ),
    );
  }

  Widget _buildAccessButton({
    required String label,
    required IconData icon,
    required VoidCallback onTap,
  }) {
    return Container(
      height: 50,
      decoration: BoxDecoration(
        color: cardGlass,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: accentRed.withOpacity(0.4)),
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(12),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon, color: accentRed, size: 20),
              const SizedBox(width: 8),
              Text(
                label,
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                  fontSize: 13,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Color _getRoleColor(String role) {
    switch (role.toLowerCase()) {
      case "owner":
        return accentRed;
      case "vip":
        return primaryRed;
      case "reseller":
        return Colors.lightGreenAccent;
      case "premium":
        return Colors.orangeAccent;
      default:
        return lightRed;
    }
  }

  Widget _buildCompactInfoItem({
    required IconData icon,
    required String label,
    required String value,
    Color valueColor = Colors.white,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
      decoration: BoxDecoration(
        color: Colors.black.withOpacity(0.2),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: borderGlass),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: primaryRed.withOpacity(0.2),
              shape: BoxShape.circle,
            ),
            child: Icon(icon, color: accentRed, size: 18),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: TextStyle(
                    color: accentGrey,
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  value,
                  style: TextStyle(
                    color: valueColor,
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                    fontFamily: 'ShareTechMono',
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCustomDrawer() {
    return Drawer(
      backgroundColor: bgDark,
      width: MediaQuery.of(context).size.width * 0.8,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Container(
            height: 250,
            color: Colors.black,
            child: Stack(
              children: [
                if (_menuVideoController != null && _menuVideoController!.value.isInitialized)
                  SizedBox.expand(
                    child: FittedBox(
                      fit: BoxFit.cover,
                      child: SizedBox(
                        width: _menuVideoController!.value.size.width,
                        height: _menuVideoController!.value.size.height,
                        child: VideoPlayer(_menuVideoController!),
                      ),
                    ),
                  ),
                Container(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: [
                        Colors.black.withOpacity(0.2),
                        Colors.black.withOpacity(0.8),
                      ],
                    ),
                  ),
                ),
                SafeArea(
                  child: Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Container(
                          width: 100,
                          height: 100,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            border: Border.all(color: accentRed, width: 3),
                            boxShadow: [
                              BoxShadow(
                                color: primaryRed.withOpacity(0.6),
                                blurRadius: 15,
                                spreadRadius: 2,
                              )
                            ],
                          ),
                          child: ClipOval(
                            child: _profileImage != null
                                ? Image.file(
                              _profileImage!,
                              fit: BoxFit.cover,
                            )
                                : Icon(
                              FontAwesomeIcons.userAstronaut,
                              size: 50,
                              color: Colors.white.withOpacity(0.8),
                            ),
                          ),
                        ),
                        const SizedBox(height: 16),
                        Text(
                          username,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 22,
                            fontWeight: FontWeight.bold,
                            fontFamily: 'Orbitron',
                          ),
                        ),
                        Text(
                          role.toUpperCase(),
                          style: TextStyle(
                            color: accentRed,
                            fontSize: 14,
                            letterSpacing: 2,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),

          Expanded(
            child: Container(
              color: bgDark,
              child: ListView(
                padding: const EdgeInsets.symmetric(vertical: 20),
                children: [
                  if (role == "reseller")
                    _buildDrawerMenuItem(
                      icon: Icons.storefront,
                      label: "Seller Page",
                      onTap: () => _onSidebarTabSelected(1),
                    ),
                  if (role == "admin")
                    _buildDrawerMenuItem(
                      icon: Icons.admin_panel_settings,
                      label: "Admin Page",
                      onTap: () => _onSidebarTabSelected(2),
                    ),
                  if (role == "owner")
                    _buildDrawerMenuItem(
                      icon: Icons.workspace_premium,
                      label: "Owner Page",
                      onTap: () => _onSidebarTabSelected(3),
                    ),
                  _buildDrawerMenuItem(
                    icon: Icons.history_rounded,
                    label: "Riwayat Aktivitas",
                    onTap: () {
                      Navigator.pop(context);
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => RiwayatPage(
                            sessionKey: sessionKey,
                            role: role,
                          ),
                        ),
                      );
                    },
                  ),
                  const SizedBox(height: 20),
                  _buildDrawerMenuItem(
                    icon: Icons.logout,
                    label: "Log Out",
                    isLogout: true,
                    onTap: () async {
                      Navigator.pop(context);
                      final prefs = await SharedPreferences.getInstance();
                      await prefs.clear();
                      if (!mounted) return;
                      Navigator.of(context).pushAndRemoveUntil(
                        MaterialPageRoute(builder: (_) => const LoginPage()),
                            (route) => false,
                      );
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

  Widget _buildDrawerMenuItem({
    required IconData icon,
    required String label,
    required VoidCallback onTap,
    bool isLogout = false,
  }) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        color: isLogout
            ? Colors.red.withOpacity(0.2)
            : cardGlass,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isLogout ? Colors.red.withOpacity(0.5) : borderGlass,
        ),
      ),
      child: ListTile(
        leading: Icon(
          icon,
          color: isLogout ? Colors.redAccent : accentRed,
          size: 22,
        ),
        title: Text(
          label,
          style: TextStyle(
            color: isLogout ? Colors.redAccent : primaryWhite,
            fontWeight: FontWeight.w600,
            fontSize: 16,
          ),
        ),
        trailing: const Icon(
          Icons.arrow_forward_ios,
          color: Colors.white38,
          size: 14,
        ),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        onTap: onTap,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: bgDark,
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        centerTitle: true,
        title: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            ShaderMask(
              shaderCallback: (bounds) => const LinearGradient(
                colors: [Color(0xFFFF5252), Color(0xFFFF8A8A), Color(0xFFFF5252)],
              ).createShader(bounds),
              child: Text(
                _showGreeting ? "Halo, $username" : _displayText,
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                  fontSize: 20,
                  fontFamily: 'Orbitron',
                  letterSpacing: 2,
                  shadows: [
                    Shadow(color: Color(0xFFFF5252), blurRadius: 12),
                    Shadow(color: Color(0xFFC62828), blurRadius: 24),
                  ],
                ),
              ),
            ),
            Container(
              width: 2,
              height: 24,
              margin: const EdgeInsets.only(left: 2),
              color: accentRed,
            ),
          ],
        ),
        backgroundColor: const Color(0xFF12121A),
        elevation: 0,
        iconTheme: const IconThemeData(color: Color(0xFFFF5252)),
        leading: Builder(
          builder: (context) => Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              AnimatedBuilder(
                animation: _iconFocusAnimation,
                builder: (context, child) {
                  return Opacity(
                    opacity: _iconFocusAnimation.value,
                    child: Transform.scale(
                      scale: 0.85 + (_iconFocusAnimation.value * 0.15),
                      child: IconButton(
                        icon: const Icon(Icons.tune_outlined, color: Color(0xFFFF5252), size: 26),
                        onPressed: () => Scaffold.of(context).openDrawer(),
                      ),
                    ),
                  );
                },
              ),
              const SizedBox(width: 4),
              Stack(
                children: [
                  Container(
                    width: 38,
                    height: 38,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      border: Border.all(color: primaryRed.withOpacity(0.5), width: 1.5),
                    ),
                    child: ClipOval(
                      child: _profileImage != null
                          ? Image.file(_profileImage!, fit: BoxFit.cover)
                          : Icon(FontAwesomeIcons.userAstronaut, size: 18, color: primaryWhite.withOpacity(0.6)),
                    ),
                  ),
                  Positioned(
                    bottom: 0,
                    right: 0,
                    child: Container(
                      width: 10,
                      height: 10,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: activeGreen,
                        border: Border.all(color: bgDark, width: 1.5),
                        boxShadow: [
                          BoxShadow(
                            color: activeGreen.withOpacity(0.6),
                            blurRadius: 4,
                            spreadRadius: 1,
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
        actions: [
          const SizedBox(width: 8),
          Container(
            margin: const EdgeInsets.symmetric(vertical: 8),
            width: 38,
            height: 38,
            decoration: BoxDecoration(
              color: primaryRed.withOpacity(0.15),
              borderRadius: BorderRadius.circular(25),
              border: Border.all(
                color: darkRed,
                width: 1.2,
              ),
            ),
            child: IconButton(
              padding: EdgeInsets.zero,
              icon: const Icon(Icons.headset_mic_outlined, color: Color(0xFFFF5252), size: 20),
              tooltip: 'Customer Service',
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => ContactPage()),
                );
              },
            ),
          ),
          const SizedBox(width: 6),
          Container(
            margin: const EdgeInsets.symmetric(vertical: 8),
            width: 38,
            height: 38,
            decoration: BoxDecoration(
              color: primaryRed.withOpacity(0.15),
              borderRadius: BorderRadius.circular(25),
              border: Border.all(
                color: darkRed,
                width: 1.2,
              ),
            ),
            child: IconButton(
              padding: EdgeInsets.zero,
              icon: const Icon(Icons.account_circle_outlined, color: Color(0xFFFF5252), size: 20),
              tooltip: 'My Profile',
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => ProfilePage(
                      username: username,
                      password: password,
                      role: role,
                      expiredDate: expiredDate,
                      sessionKey: sessionKey,
                    ),
                  ),
                );
              },
            ),
          ),
          const SizedBox(width: 12),
        ],
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(1),
          child: Container(
            height: 1,
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                colors: [Colors.transparent, Color(0xFFFF5252), Colors.transparent],
              ),
            ),
          ),
        ),
      ),
      drawer: _buildCustomDrawer(),
      body: Container(
        decoration: const BoxDecoration(
          color: Color(0xFF0A0A0F),
        ),
        child: SafeArea(
          child: FadeTransition(opacity: _animation, child: _selectedPage),
        ),
      ),
      bottomNavigationBar: Container(
        color: const Color(0xFF0A0A0F),
        padding: const EdgeInsets.fromLTRB(16, 10, 16, 28),
        child: Container(
          height: 76,
          decoration: BoxDecoration(
            color: cardGlass,
            borderRadius: BorderRadius.circular(22),
            border: Border.all(
              color: primaryRed.withOpacity(0.35),
              width: 0.8,
            ),
            boxShadow: [
              BoxShadow(
                color: primaryRed.withOpacity(0.1),
                blurRadius: 24,
                spreadRadius: 1,
              ),
            ],
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: List.generate(5, (index) {
              final icons = [
                Icons.dashboard_rounded,
                FontAwesomeIcons.whatsapp,
                Icons.devices_rounded,
                Icons.notifications_none_rounded,
                Icons.build_circle_outlined,
              ];
              final labels = ["Dashboard", "WhatsApp", "Control", "Info", "Tools"];
              final isActive = _bottomNavIndex == index;
              return GestureDetector(
                onTap: () => _onBottomNavTapped(index),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 250),
                  curve: Curves.easeInOut,
                  padding: EdgeInsets.symmetric(
                    horizontal: isActive ? 18 : 16,
                    vertical: 12,
                  ),
                  decoration: BoxDecoration(
                    color: isActive
                        ? const Color(0xFF1A1A2A)
                        : Colors.transparent,
                    borderRadius: BorderRadius.circular(16),
                    border: isActive
                        ? Border.all(
                            color: accentRed.withOpacity(0.6),
                            width: 0.8,
                          )
                        : null,
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        icons[index],
                        color: isActive
                            ? accentRed
                            : Colors.grey.shade600,
                        size: 26,
                      ),
                      if (isActive) ...[
                        const SizedBox(width: 9),
                        Text(
                          labels[index],
                          style: const TextStyle(
                            color: Color(0xFFFF5252),
                            fontSize: 14,
                            fontWeight: FontWeight.bold,
                            fontFamily: 'Orbitron',
                            letterSpacing: 0.5,
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
              );
            }),
          ),
        ),
      ),
    );
  }

  @override
  void dispose() {
    _typewriterTimer?.cancel();
    channel.sink.close(status.goingAway);
    _controller.dispose();
    _pulseController.dispose();
    _iconFocusController.dispose();
    _menuVideoController?.dispose();
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
          setState(() {});
          _controller?.setLooping(true);
          _controller?.setVolume(0.0);
          _controller?.play();
        });
    }
  }

  bool _isVideo(String url) {
    return url.endsWith(".mp4") ||
        url.endsWith(".webm") ||
        url.endsWith(".mov") ||
        url.endsWith(".mkv");
  }

  @override
  void dispose() {
    _controller?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (_isVideo(widget.url)) {
      if (_controller != null && _controller!.value.isInitialized) {
        return AspectRatio(
          aspectRatio: _controller!.value.aspectRatio,
          child: VideoPlayer(_controller!),
        );
      } else {
        return const Center(
          child: CircularProgressIndicator(
            color: Color(0xFFFF5252),
          ),
        );
      }
    } else {
      return Image.network(
        widget.url,
        fit: BoxFit.cover,
        errorBuilder: (_, __, ___) => Container(
          color: Colors.grey.shade800,
          child: const Icon(Icons.error, color: Color(0xFFFF5252)),
        ),
      );
    }
  }
}