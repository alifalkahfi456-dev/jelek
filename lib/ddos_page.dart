import 'dart:ui';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:video_player/video_player.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'chat_ai_page.dart';
import 'nik_check_page.dart';
import 'phone_lookup.dart';
import 'subdomain_finder_page.dart';
import 'anime.dart';
import 'cdrama_page.dart';
import 'hentai.dart';
import 'test_funct.dart';
import 'tiktok_page.dart';
import 'gemini_ai_page.dart';
import 'cpanel_page.dart';
import 'obf_page.dart';
import 'report_scam_page.dart';

class ToolsPage extends StatefulWidget {
  final String sessionKey;
  final String userRole;

  const ToolsPage({
    super.key,
    required this.sessionKey,
    required this.userRole,
  });

  @override
  State<ToolsPage> createState() => _ToolsPageState();
}

class _ToolsPageState extends State<ToolsPage> with TickerProviderStateMixin {
  late AnimationController _headerController;
  late AnimationController _listController;
  late AnimationController _glowController;
  late AnimationController _rotateController;
  late AnimationController _carouselController;
  late Animation<double> _headerAnimation;
  late Animation<double> _glowAnimation;
  late Animation<double> _rotateAnimation;
  late List<Animation<double>> _itemAnimations;
  late PageController _carouselPageController;
  int _currentCarouselIndex = 0;
  String _searchQuery = "";

  late VideoPlayerController _videoController;
  bool _videoInitialized = false;

  final Color _primaryColor = const Color(0xFFB8B8CC);
  final Color _secondaryColor = const Color(0xFF787890);
  final Color _accentColor = const Color(0xFFD8D8EC);
  final Color _successColor = const Color(0xFF8899AA);
  final Color _warningColor = const Color(0xFFC8B890);
  final Color _darkBg = const Color(0xFF0C0C10);
  final Color _darkerBg = const Color(0xFF070709);
  final Color _surfaceColor = const Color(0xFF161620);
  final Color _cardColor = const Color(0xFF111118);
  final Color _glowColor1 = const Color(0xFFE0E0F8);
  final Color _glowColor2 = const Color(0xFF9090B4);
  final Color _glowColor3 = const Color(0xFFBBBBD0);
  final Color _goldColor = const Color(0xFFCCBB88);
  final Color _roseColor = const Color(0xFFBB8899);

  final List<Map<String, dynamic>> _payloads = [
    {
      'id': 'payload_001',
      'name': 'CRASH UI',
      'description': 'WhatsApp UI Crash - Send payload to crash target WhatsApp interface',
      'icon': FontAwesomeIcons.explosion,
      'category': 'CRASH',
      'risk': 'HIGH',
      'gradient': [const Color(0xFFE53935), const Color(0xFFFF6B6B)],
    },
    {
      'id': 'payload_002',
      'name': 'FREEZE SYSTEM',
      'description': 'WhatsApp Freeze - Freeze target WhatsApp application completely',
      'icon': FontAwesomeIcons.snowflake,
      'category': 'FREEZE',
      'risk': 'HIGH',
      'gradient': [const Color(0xFF1E88E5), const Color(0xFF64B5F6)],
    },
    {
      'id': 'payload_003',
      'name': 'LOOP MESSAGE',
      'description': 'Message Loop - Send repeated messages until app crashes',
      'icon': FontAwesomeIcons.rotateRight,
      'category': 'LOOP',
      'risk': 'MEDIUM',
      'gradient': [const Color(0xFF43A047), const Color(0xFF81C784)],
    },
    {
      'id': 'payload_004',
      'name': 'MEMORY LEAK',
      'description': 'Memory Exhaustion - Drain WhatsApp memory until crash',
      'icon': FontAwesomeIcons.memory,
      'category': 'LEAK',
      'risk': 'HIGH',
      'gradient': [const Color(0xFFFB8C00), const Color(0xFFFFB74D)],
    },
    {
      'id': 'payload_005',
      'name': 'STICKER BOMB',
      'description': 'Sticker Overload - Send massive amount of stickers',
      'icon': FontAwesomeIcons.stickerMule,
      'category': 'BOMB',
      'risk': 'MEDIUM',
      'gradient': [const Color(0xFF8E24AA), const Color(0xFFCE93D8)],
    },
    {
      'id': 'payload_006',
      'name': 'MEDIA SPAM',
      'description': 'Media Flood - Massively send images and videos',
      'icon': FontAwesomeIcons.images,
      'category': 'SPAM',
      'risk': 'MEDIUM',
      'gradient': [const Color(0xFFD81B60), const Color(0xFFF06292)],
    },
    {
      'id': 'payload_007',
      'name': 'CONTACT BOMB',
      'description': 'Contact Flood - Massively send contact cards',
      'icon': FontAwesomeIcons.addressCard,
      'category': 'BOMB',
      'risk': 'LOW',
      'gradient': [const Color(0xFF00897B), const Color(0xFF4DB6AC)],
    },
    {
      'id': 'payload_008',
      'name': 'LOCATION SPAM',
      'description': 'Location Flood - Repeatedly send location data',
      'icon': FontAwesomeIcons.locationDot,
      'category': 'SPAM',
      'risk': 'LOW',
      'gradient': [const Color(0xFF3949AB), const Color(0xFF7986CB)],
    },
    {
      'id': 'payload_009',
      'name': 'VOICE NOTE BOMB',
      'description': 'Voice Note Flood - Send massive voice notes',
      'icon': FontAwesomeIcons.microphone,
      'category': 'BOMB',
      'risk': 'MEDIUM',
      'gradient': [const Color(0xFF6A1B9A), const Color(0xFFAB47BC)],
    },
    {
      'id': 'payload_010',
      'name': 'DOCUMENT SPAM',
      'description': 'Document Flood - Massively send PDF and documents',
      'icon': FontAwesomeIcons.filePdf,
      'category': 'SPAM',
      'risk': 'LOW',
      'gradient': [const Color(0xFFE64A19), const Color(0xFFFF7043)],
    },
    {
      'id': 'payload_011',
      'name': 'FUNCTION TEST',
      'description': 'Test Function - Execute custom code payload',
      'icon': FontAwesomeIcons.code,
      'category': 'TEST',
      'risk': 'LOW',
      'gradient': [const Color(0xFF607D8B), const Color(0xFF90A4AE)],
    },
  ];

  List<Map<String, dynamic>> get _filteredPayloads {
    if (_searchQuery.isEmpty) return _payloads;
    return _payloads.where((payload) {
      return payload['name'].toLowerCase().contains(_searchQuery.toLowerCase()) ||
          payload['description'].toLowerCase().contains(_searchQuery.toLowerCase()) ||
          payload['category'].toLowerCase().contains(_searchQuery.toLowerCase());
    }).toList();
  }

  @override
  void initState() {
    super.initState();
    
    _videoController = VideoPlayerController.asset('assets/videos/banner.mp4')
      ..initialize().then((_) {
        _videoController.setLooping(true);
        _videoController.setVolume(0.0);
        _videoController.play();
        if (mounted) {
          setState(() {
            _videoInitialized = true;
          });
        }
      }).catchError((error) {
        debugPrint("Video initialization error: $error");
        if (mounted) {
          setState(() {
            _videoInitialized = false;
          });
        }
      });

    _headerController = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );
    _listController = AnimationController(
      duration: const Duration(milliseconds: 1000),
      vsync: this,
    );
    _glowController = AnimationController(
      duration: const Duration(milliseconds: 2500),
      vsync: this,
    );
    _glowController.repeat(reverse: true);
    
    _rotateController = AnimationController(
      duration: const Duration(seconds: 20),
      vsync: this,
    );
    _rotateController.repeat();

    _carouselController = AnimationController(
      duration: const Duration(seconds: 30),
      vsync: this,
    )..repeat();

    _carouselPageController = PageController(viewportFraction: 0.85);

    _headerAnimation = Tween<double>(begin: 0, end: 1).animate(
      CurvedAnimation(parent: _headerController, curve: Curves.easeOutCubic),
    );

    _glowAnimation = Tween<double>(begin: 0.3, end: 1.0).animate(
      CurvedAnimation(parent: _glowController, curve: Curves.easeInOutSine),
    );
    
    _rotateAnimation = Tween<double>(begin: 0, end: 1).animate(
      CurvedAnimation(parent: _rotateController, curve: Curves.linear),
    );

    _itemAnimations = List.generate(
      16,
      (index) => Tween<double>(begin: 0, end: 1).animate(
        CurvedAnimation(
          parent: _listController,
          curve: Interval(
            index * 0.07,
            0.6 + (index * 0.07),
            curve: Curves.easeOutCubic,
          ),
        ),
      ),
    );

    _headerController.forward();
    _listController.forward();
  }

  @override
  void dispose() {
    _headerController.dispose();
    _listController.dispose();
    _glowController.dispose();
    _rotateController.dispose();
    _carouselController.dispose();
    _carouselPageController.dispose();
    _videoController.dispose();
    super.dispose();
  }

  Widget _buildAnimatedBackground() {
    return Stack(
      children: [
        if (_videoInitialized && _videoController.value.isInitialized)
          SizedBox.expand(
            child: FittedBox(
              fit: BoxFit.cover,
              child: SizedBox(
                width: _videoController.value.size.width,
                height: _videoController.value.size.height,
                child: Opacity(opacity: 0.06, child: VideoPlayer(_videoController)),
              ),
            ),
          )
        else
          Container(
            decoration: BoxDecoration(
              gradient: RadialGradient(
                center: const Alignment(-0.2, -0.4),
                radius: 1.6,
                colors: [_glowColor1.withOpacity(0.05), _darkerBg, _darkBg],
              ),
            ),
          ),
        
        AnimatedBuilder(
          animation: _rotateAnimation,
          builder: (context, _) {
            final size = MediaQuery.of(context).size;
            return Stack(
              children: [
                Positioned(
                  top: -size.height * 0.1,
                  right: -size.width * 0.2,
                  child: Transform.rotate(
                    angle: _rotateAnimation.value * pi * 2,
                    child: Container(
                      width: size.width * 0.65,
                      height: size.width * 0.65,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        border: Border.all(color: _glowColor1.withOpacity(0.05), width: 1),
                      ),
                    ),
                  ),
                ),
                Positioned(
                  bottom: -size.height * 0.08,
                  left: -size.width * 0.15,
                  child: Transform.rotate(
                    angle: -_rotateAnimation.value * pi,
                    child: Container(
                      width: size.width * 0.5,
                      height: size.width * 0.5,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        border: Border.all(color: _glowColor2.withOpacity(0.06), width: 0.8),
                      ),
                    ),
                  ),
                ),
              ],
            );
          },
        ),
        
        Container(
          decoration: BoxDecoration(
            gradient: RadialGradient(
              center: Alignment.center,
              radius: 1.0,
              colors: [
                Colors.transparent,
                Colors.black.withOpacity(0.55),
              ],
            ),
          ),
        ),
        
        Positioned.fill(
          child: Opacity(
            opacity: 0.03,
            child: CustomPaint(
              painter: ToolsHexagonPainter(),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildNeonHeader() {
    return Padding(
      padding: const EdgeInsets.only(left: 20, right: 20, top: 16, bottom: 8),
      child: AnimatedBuilder(
        animation: _glowAnimation,
        builder: (context, _) {
          return Container(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
            decoration: BoxDecoration(
              color: _cardColor,
              borderRadius: BorderRadius.circular(24),
              border: Border.all(color: _glowColor1.withOpacity(0.3), width: 1.5),
              boxShadow: [
                BoxShadow(
                  color: _glowColor1.withOpacity(0.12 * _glowAnimation.value),
                  blurRadius: 24,
                  spreadRadius: 2,
                ),
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(14),
                      decoration: BoxDecoration(
                        color: _glowColor1.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: _glowColor1.withOpacity(0.25), width: 1),
                      ),
                      child: Icon(Icons.build_circle, color: _glowColor1, size: 28),
                    ),
                    const SizedBox(width: 16),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        ShaderMask(
                          shaderCallback: (bounds) => LinearGradient(
                            colors: [_glowColor1, _accentColor, _glowColor2],
                          ).createShader(bounds),
                          child: const Text(
                            "PAYLOAD SYSTEM",
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 20,
                              fontWeight: FontWeight.w900,
                              fontFamily: "CinzelDecorative",
                              letterSpacing: 4,
                            ),
                          ),
                        ),
                        const SizedBox(height: 6),
                        Text(
                          "Advanced Payload Injector",
                          style: TextStyle(
                            color: _glowColor2.withOpacity(0.6),
                            fontSize: 10,
                            fontFamily: "CinzelDecorative",
                            fontWeight: FontWeight.w600,
                            letterSpacing: 1.5,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
                const SizedBox(height: 18),
                Container(
                  height: 2,
                  width: 60,
                  decoration: BoxDecoration(
                    gradient: LinearGradient(colors: [_glowColor1, _glowColor2]),
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
                const SizedBox(height: 14),
                SizedBox(
                  height: 24,
                  child: MarqueeText(
                    text: "SELECT PAYLOAD   SLIDE LEFT OR RIGHT   SEND ATTACK   MULTI SEARCH AVAILABLE   PROFESSIONAL TOOLKIT",
                    style: TextStyle(
                      color: _glowColor1.withOpacity(0.5),
                      fontSize: 10,
                      fontFamily: "CinzelDecorative",
                      fontWeight: FontWeight.w600,
                      letterSpacing: 2,
                    ),
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildSearchBar() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
      child: Container(
        decoration: BoxDecoration(
          color: _cardColor,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: _glowColor1.withOpacity(0.2)),
        ),
        child: TextField(
          onChanged: (value) {
            setState(() {
              _searchQuery = value;
              _currentCarouselIndex = 0;
              if (_filteredPayloads.isNotEmpty) {
                _carouselPageController.animateToPage(
                  0,
                  duration: const Duration(milliseconds: 300),
                  curve: Curves.easeOut,
                );
              }
            });
          },
          style: TextStyle(
            color: Colors.white,
            fontFamily: "CinzelDecorative",
            fontSize: 13,
          ),
          cursorColor: _glowColor1,
          decoration: InputDecoration(
            hintText: "SEARCH PAYLOAD...",
            hintStyle: TextStyle(
              color: Colors.white.withOpacity(0.3),
              fontSize: 11,
              fontFamily: "CinzelDecorative",
              letterSpacing: 1,
            ),
            prefixIcon: Icon(FontAwesomeIcons.magnifyingGlass, color: _glowColor1, size: 18),
            border: InputBorder.none,
            contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          ),
        ),
      ),
    );
  }

  Widget _buildPayloadCarousel() {
    if (_filteredPayloads.isEmpty) {
      return Padding(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 40),
        child: Center(
          child: Column(
            children: [
              Icon(FontAwesomeIcons.circleExclamation, color: _glowColor1.withOpacity(0.3), size: 48),
              const SizedBox(height: 12),
              Text(
                "NO PAYLOAD FOUND",
                style: TextStyle(
                  color: _glowColor1.withOpacity(0.3),
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  fontFamily: "CinzelDecorative",
                  letterSpacing: 2,
                ),
              ),
            ],
          ),
        ),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
          child: Row(
            children: [
              Icon(FontAwesomeIcons.codeBranch, color: _glowColor1, size: 14),
              const SizedBox(width: 8),
              Text(
                "PAYLOAD SELECTOR",
                style: TextStyle(
                  color: _glowColor1,
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                  fontFamily: "CinzelDecorative",
                  letterSpacing: 2,
                ),
              ),
              const Spacer(),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: _glowColor1.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  "${_currentCarouselIndex + 1}/${_filteredPayloads.length}",
                  style: TextStyle(
                    color: _glowColor1.withOpacity(0.7),
                    fontSize: 9,
                    fontFamily: "CinzelDecorative",
                  ),
                ),
              ),
            ],
          ),
        ),
        SizedBox(
          height: 220,
          child: PageView.builder(
            controller: _carouselPageController,
            onPageChanged: (index) {
              setState(() {
                _currentCarouselIndex = index;
              });
            },
            itemCount: _filteredPayloads.length,
            itemBuilder: (context, index) {
              final payload = _filteredPayloads[index];
              final isActive = _currentCarouselIndex == index;
              return AnimatedContainer(
                duration: const Duration(milliseconds: 300),
                margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: isActive ? [payload['gradient'][0].withOpacity(0.15), Colors.transparent] : [Colors.transparent, Colors.transparent],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: _PayloadCard(
                  payload: payload,
                  isActive: isActive,
                  glowAnimation: _glowAnimation,
                  onTap: () {
                    _showPayloadDetail(payload);
                  },
                ),
              );
            },
          ),
        ),
      ],
    );
  }

  void _showPayloadDetail(Map<String, dynamic> payload) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (context) => Container(
        decoration: BoxDecoration(
          color: _cardColor,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
          border: Border.all(color: _glowColor1.withOpacity(0.3), width: 1),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              margin: const EdgeInsets.only(top: 16),
              width: 50,
              height: 4,
              decoration: BoxDecoration(
                color: _glowColor1.withOpacity(0.3),
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(24),
              child: Column(
                children: [
                  Container(
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      gradient: LinearGradient(colors: payload['gradient']),
                      shape: BoxShape.circle,
                    ),
                    child: Icon(payload['icon'], color: Colors.white, size: 32),
                  ),
                  const SizedBox(height: 20),
                  Text(
                    payload['name'],
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 22,
                      fontWeight: FontWeight.w900,
                      fontFamily: "CinzelDecorative",
                      letterSpacing: 2,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                    decoration: BoxDecoration(
                      color: payload['risk'] == 'HIGH' 
                          ? const Color(0xFFE53935).withOpacity(0.15)
                          : payload['risk'] == 'MEDIUM'
                              ? const Color(0xFFFB8C00).withOpacity(0.15)
                              : const Color(0xFF43A047).withOpacity(0.15),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(
                      "RISK: ${payload['risk']}",
                      style: TextStyle(
                        color: payload['risk'] == 'HIGH' 
                            ? const Color(0xFFE53935)
                            : payload['risk'] == 'MEDIUM'
                                ? const Color(0xFFFB8C00)
                                : const Color(0xFF43A047),
                        fontSize: 10,
                        fontWeight: FontWeight.w700,
                        fontFamily: "CinzelDecorative",
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    payload['description'],
                    style: TextStyle(
                      color: Colors.white.withOpacity(0.7),
                      fontSize: 13,
                      height: 1.5,
                      fontFamily: "CinzelDecorative",
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 16),
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: _darkBg,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: _glowColor1.withOpacity(0.15)),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceAround,
                      children: [
                        _buildInfoChip(FontAwesomeIcons.tag, payload['category']),
                        _buildInfoChip(FontAwesomeIcons.exclamationTriangle, payload['risk']),
                        _buildInfoChip(FontAwesomeIcons.hashtag, payload['id']),
                      ],
                    ),
                  ),
                  const SizedBox(height: 24),
                  Row(
                    children: [
                      Expanded(
                        child: OutlinedButton(
                          onPressed: () => Navigator.pop(context),
                          style: OutlinedButton.styleFrom(
                            side: BorderSide(color: _glowColor1.withOpacity(0.3)),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                            padding: const EdgeInsets.symmetric(vertical: 14),
                          ),
                          child: Text(
                            "CANCEL",
                            style: TextStyle(
                              color: _glowColor1.withOpacity(0.6),
                              fontWeight: FontWeight.w700,
                              fontFamily: "CinzelDecorative",
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: ElevatedButton(
                          onPressed: () {
                            Navigator.pop(context);
                            _executePayload(payload);
                          },
                          style: ElevatedButton.styleFrom(
                            backgroundColor: payload['gradient'][0],
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                            padding: const EdgeInsets.symmetric(vertical: 14),
                          ),
                          child: const Text(
                            "SEND PAYLOAD",
                            style: TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.w700,
                              fontFamily: "CinzelDecorative",
                              letterSpacing: 1,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoChip(IconData icon, String label) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: _surfaceColor,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        children: [
          Icon(icon, color: _glowColor1.withOpacity(0.5), size: 12),
          const SizedBox(width: 6),
          Text(
            label,
            style: TextStyle(
              color: _glowColor1.withOpacity(0.5),
              fontSize: 10,
              fontWeight: FontWeight.w600,
              fontFamily: "CinzelDecorative",
            ),
          ),
        ],
      ),
    );
  }

  void _executePayload(Map<String, dynamic> payload) {
    if (payload['name'] == 'FUNCTION TEST') {
      Navigator.push(
        context,
        MaterialPageRoute(builder: (context) => const TestFunctionPage()),
      );
      return;
    }
    
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        backgroundColor: _cardColor,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
          side: BorderSide(color: _glowColor1.withOpacity(0.3)),
        ),
        title: Row(
          children: [
            Icon(FontAwesomeIcons.bolt, color: _glowColor1, size: 20),
            const SizedBox(width: 10),
            Text(
              "PAYLOAD EXECUTED",
              style: TextStyle(
                color: _glowColor1,
                fontSize: 14,
                fontWeight: FontWeight.w800,
                fontFamily: "CinzelDecorative",
                letterSpacing: 1,
              ),
            ),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: _darkBg,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Column(
                children: [
                  Icon(payload['icon'], color: payload['gradient'][0], size: 40),
                  const SizedBox(height: 12),
                  Text(
                    payload['name'],
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      fontFamily: "CinzelDecorative",
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    "Payload has been sent to target",
                    style: TextStyle(
                      color: Colors.white.withOpacity(0.6),
                      fontSize: 12,
                      fontFamily: "CinzelDecorative",
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(
              "CLOSE",
              style: TextStyle(
                color: _glowColor1,
                fontWeight: FontWeight.bold,
                fontFamily: "CinzelDecorative",
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAnimatedToolItem({
    required IconData icon,
    required String label,
    required String description,
    required List<Color> gradient,
    required Animation<double> animation,
    required VoidCallback onTap,
  }) {
    return AnimatedBuilder(
      animation: animation,
      builder: (context, child) {
        return Transform.translate(
          offset: Offset(0, (1 - animation.value) * 30),
          child: Opacity(
            opacity: animation.value,
            child: _PremiumToolItem(
              icon: icon,
              label: label,
              description: description,
              gradient: gradient,
              onTap: onTap,
              glowAnimation: _glowAnimation,
              cardColor: _cardColor,
            ),
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final tools = [
      {'icon': FontAwesomeIcons.robot, 'label': 'CHAT AI', 'description': 'AI ASSISTANT', 'gradient': [_glowColor1, _glowColor2]},
      {'icon': FontAwesomeIcons.google, 'label': 'GEMINI AI', 'description': 'GOOGLE AI', 'gradient': [_glowColor1, _glowColor3]},
      {'icon': FontAwesomeIcons.server, 'label': 'CPANEL', 'description': 'PANEL CREATOR', 'gradient': [_glowColor2, _glowColor1]},
      {'icon': FontAwesomeIcons.idCard, 'label': 'NIK CHECK', 'description': 'ID VALIDATOR', 'gradient': [_glowColor2, _glowColor3]},
      {'icon': FontAwesomeIcons.phoneAlt, 'label': 'PHONE LOOKUP', 'description': 'NUMBER INFO', 'gradient': [_glowColor3, _glowColor1]},
      {'icon': FontAwesomeIcons.globe, 'label': 'SUBDOMAIN', 'description': 'DOMAIN FINDER', 'gradient': [_glowColor2, _accentColor]},
      {'icon': FontAwesomeIcons.film, 'label': 'ANIME', 'description': 'STREAMING HUB', 'gradient': [_glowColor1, _glowColor3]},
      {'icon': FontAwesomeIcons.tv, 'label': 'C-DRAMA', 'description': 'CHINESE DRAMA', 'gradient': [_glowColor1, _glowColor2]},
      {'icon': FontAwesomeIcons.fire, 'label': 'X-HUB', 'description': 'ADULT CONTENT', 'gradient': [const Color(0xFFE53935), _glowColor1]},
      {'icon': FontAwesomeIcons.code, 'label': 'TEST FUNC', 'description': 'FUNCTION EXECUTOR', 'gradient': [_glowColor2, _glowColor1]},
      {'icon': FontAwesomeIcons.tiktok, 'label': 'TIKTOK', 'description': 'VIDEO FEED', 'gradient': [_glowColor1, const Color(0xFF000000)]},
      {'icon': FontAwesomeIcons.shieldHalved, 'label': 'OBFUSCATE', 'description': 'CODE PROTECTION', 'gradient': [_glowColor1, _glowColor2]},
      {'icon': FontAwesomeIcons.flag, 'label': 'SCAM REPORTER', 'description': 'REPORT SCAMMER', 'gradient': [_roseColor, _glowColor1]},
    ];

    return Scaffold(
      backgroundColor: _darkerBg,
      body: Stack(
        children: [
          _buildAnimatedBackground(),
          SafeArea(
            child: CustomScrollView(
              physics: const BouncingScrollPhysics(),
              slivers: [
                SliverToBoxAdapter(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _buildNeonHeader(),
                      const SizedBox(height: 8),
                      _buildSearchBar(),
                      const SizedBox(height: 8),
                      _buildPayloadCarousel(),
                      const SizedBox(height: 16),
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
                        child: Row(
                          children: [
                            Icon(FontAwesomeIcons.toolbox, color: _glowColor1, size: 14),
                            const SizedBox(width: 8),
                            Text(
                              "TOOLKIT",
                              style: TextStyle(
                                color: _glowColor1,
                                fontSize: 12,
                                fontWeight: FontWeight.w700,
                                fontFamily: "CinzelDecorative",
                                letterSpacing: 2,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                SliverPadding(
                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
                  sliver: SliverGrid(
                    gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: 2,
                      crossAxisSpacing: 16,
                      mainAxisSpacing: 16,
                      childAspectRatio: 0.88,
                    ),
                    delegate: SliverChildBuilderDelegate(
                      (context, index) {
                        final tool = tools[index];
                        return _buildAnimatedToolItem(
                          icon: tool['icon'] as IconData,
                          label: tool['label'] as String,
                          description: tool['description'] as String,
                          gradient: tool['gradient'] as List<Color>,
                          animation: _itemAnimations[index],
                          onTap: () => _navigateToTool(tool['label'] as String),
                        );
                      },
                      childCount: tools.length,
                    ),
                  ),
                ),
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
                    child: _buildFooter(),
                  ),
                ),
                SliverToBoxAdapter(
                  child: const SizedBox(height: 30),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
  
  Widget _buildFooter() {
    return Column(
      children: [
        Container(
          height: 1,
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [Colors.transparent, _glowColor1.withOpacity(0.1), Colors.transparent],
            ),
          ),
        ),
        const SizedBox(height: 20),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            _buildFooterDot(_successColor),
            const SizedBox(width: 10),
            _buildFooterText("PAYLOAD READY"),
            const SizedBox(width: 20),
            Container(width: 1, height: 12, color: Colors.white.withOpacity(0.06)),
            const SizedBox(width: 20),
            Icon(Icons.fingerprint, color: Colors.white.withOpacity(0.12), size: 12),
            const SizedBox(width: 20),
            _buildFooterDot(_glowColor3),
            const SizedBox(width: 10),
            _buildFooterText("ARMED"),
          ],
        ),
        const SizedBox(height: 12),
        Text(
          "PAYLOAD SYSTEM V2.0   PROFESSIONAL INJECTOR   MULTI SEARCH ACTIVE",
          style: TextStyle(
            color: Colors.white.withOpacity(0.1),
            fontSize: 8,
            letterSpacing: 3,
            fontFamily: 'CinzelDecorative',
            fontWeight: FontWeight.w600,
          ),
        ),
      ],
    );
  }

  Widget _buildFooterDot(Color color) {
    return Container(
      width: 5,
      height: 5,
      decoration: BoxDecoration(
        color: color,
        shape: BoxShape.circle,
        boxShadow: [BoxShadow(color: color, blurRadius: 5)],
      ),
    );
  }

  Widget _buildFooterText(String text) {
    return Text(
      text,
      style: TextStyle(
        color: Colors.white.withOpacity(0.25),
        fontSize: 8,
        fontWeight: FontWeight.w700,
        letterSpacing: 2.5,
        fontFamily: 'CinzelDecorative',
      ),
    );
  }

  void _navigateToTool(String toolName) {
    Widget page;
    switch (toolName) {
      case 'CHAT AI':
        page = ChatAIPage(sessionKey: widget.sessionKey);
        break;
      case 'GEMINI AI':
        page = GeminiAIPage(sessionKey: widget.sessionKey);
        break;
      case 'CPANEL':
        page = CPanelPage(sessionKey: widget.sessionKey);
        break;
      case 'NIK CHECK':
        page = NIKCheckPage(sessionKey: widget.sessionKey);
        break;
      case 'PHONE LOOKUP':
        page = PhoneLookupPage(sessionKey: widget.sessionKey);
        break;
      case 'ANIME':
        page = HomeAnimePage();
        break;
      case 'SUBDOMAIN':
        page = SubdomainFinderPage(sessionKey: widget.sessionKey);
        break;
      case 'C-DRAMA':
        page = const CDramaPage();
        break;
      case 'X-HUB':
        page = const HomeHentaiPage();
        break;
      case 'TEST FUNC':
        page = const TestFunctionPage();
        break;
      case 'TIKTOK':
        page = TikTokPage(sessionKey: widget.sessionKey);
        break;
      case 'OBFUSCATE':
        page = ObfPage(sessionKey: widget.sessionKey);
        break;
      case 'SCAM REPORTER':
        page = ReportScamPage(sessionKey: widget.sessionKey);
        break;
      default:
        return;
    }

    Navigator.of(context).push(
      PageRouteBuilder(
        pageBuilder: (context, animation, secondaryAnimation) => page,
        transitionsBuilder: (context, animation, secondaryAnimation, child) {
          const begin = Offset(1.0, 0.0);
          const end = Offset.zero;
          const curve = Curves.easeOutCubic;
          var tween = Tween(begin: begin, end: end).chain(CurveTween(curve: curve));
          return SlideTransition(position: animation.drive(tween), child: child);
        },
        transitionDuration: const Duration(milliseconds: 350),
      ),
    );
  }
}

class MarqueeText extends StatefulWidget {
  final String text;
  final TextStyle style;
  
  const MarqueeText({super.key, required this.text, required this.style});

  @override
  State<MarqueeText> createState() => _MarqueeTextState();
}

class _MarqueeTextState extends State<MarqueeText> with SingleTickerProviderStateMixin {
  late AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(vsync: this, duration: const Duration(seconds: 12))..repeat();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        return ClipRect(
          child: AnimatedBuilder(
            animation: _controller,
            builder: (context, child) {
              final width = MediaQuery.of(context).size.width;
              final dx = width - (_controller.value * (width + 500));
              return Transform.translate(
                offset: Offset(dx, 0),
                child: child,
              );
            },
            child: Text(
              widget.text,
              style: widget.style,
              maxLines: 1,
              overflow: TextOverflow.visible,
            ),
          ),
        );
      },
    );
  }
}

class _PayloadCard extends StatelessWidget {
  final Map<String, dynamic> payload;
  final bool isActive;
  final Animation<double> glowAnimation;
  final VoidCallback onTap;

  const _PayloadCard({
    required this.payload,
    required this.isActive,
    required this.glowAnimation,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        decoration: BoxDecoration(
          color: const Color(0xFF111118),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: isActive ? payload['gradient'][0].withOpacity(0.5) : Colors.white.withOpacity(0.05),
            width: isActive ? 1.5 : 1,
          ),
          boxShadow: isActive ? [
            BoxShadow(
              color: payload['gradient'][0].withOpacity(0.2),
              blurRadius: 16,
              spreadRadius: -2,
            ),
          ] : null,
        ),
        child: Stack(
          children: [
            if (isActive)
              Positioned.fill(
                child: Container(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [payload['gradient'][0].withOpacity(0.1), Colors.transparent],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    borderRadius: BorderRadius.circular(20),
                  ),
                ),
              ),
            Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  AnimatedBuilder(
                    animation: glowAnimation,
                    builder: (context, _) {
                      return Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: payload['gradient'][0].withOpacity(0.15),
                          borderRadius: BorderRadius.circular(14),
                          border: Border.all(color: payload['gradient'][0].withOpacity(0.3), width: 1),
                        ),
                        child: Icon(payload['icon'], color: payload['gradient'][0], size: 22),
                      );
                    },
                  ),
                  const Spacer(),
                  Text(
                    payload['name'],
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 14,
                      fontWeight: FontWeight.w800,
                      fontFamily: "CinzelDecorative",
                      letterSpacing: 1,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    payload['category'],
                    style: TextStyle(
                      color: Colors.white.withOpacity(0.4),
                      fontSize: 9,
                      fontFamily: "CinzelDecorative",
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Container(
                        width: 30,
                        height: 2,
                        decoration: BoxDecoration(
                          gradient: LinearGradient(colors: payload['gradient']),
                          borderRadius: BorderRadius.circular(2),
                        ),
                      ),
                      const Spacer(),
                      Icon(
                        Icons.arrow_forward_rounded,
                        color: isActive ? payload['gradient'][0] : Colors.white.withOpacity(0.25),
                        size: 16,
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _PremiumToolItem extends StatefulWidget {
  final IconData icon;
  final String label;
  final String description;
  final List<Color> gradient;
  final VoidCallback onTap;
  final Animation<double> glowAnimation;
  final Color cardColor;

  const _PremiumToolItem({
    required this.icon,
    required this.label,
    required this.description,
    required this.gradient,
    required this.onTap,
    required this.glowAnimation,
    required this.cardColor,
  });

  @override
  State<_PremiumToolItem> createState() => _PremiumToolItemState();
}

class _PremiumToolItemState extends State<_PremiumToolItem> with SingleTickerProviderStateMixin {
  late AnimationController _scaleController;
  late Animation<double> _scaleAnimation;
  bool _isPressed = false;

  @override
  void initState() {
    super.initState();
    _scaleController = AnimationController(duration: const Duration(milliseconds: 150), vsync: this);
    _scaleAnimation = Tween<double>(begin: 1.0, end: 0.96).animate(CurvedAnimation(parent: _scaleController, curve: Curves.easeInOut));
  }

  @override
  void dispose() {
    _scaleController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTapDown: (_) {
        setState(() => _isPressed = true);
        _scaleController.forward();
      },
      onTapUp: (_) {
        setState(() => _isPressed = false);
        _scaleController.reverse();
        widget.onTap();
      },
      onTapCancel: () {
        setState(() => _isPressed = false);
        _scaleController.reverse();
      },
      child: AnimatedBuilder(
        animation: _scaleController,
        builder: (context, _) {
          return Transform.scale(
            scale: _scaleAnimation.value,
            child: Container(
              decoration: BoxDecoration(
                color: _isPressed ? widget.gradient[0].withOpacity(0.08) : widget.cardColor,
                borderRadius: BorderRadius.circular(24),
                border: Border.all(
                  color: _isPressed 
                      ? widget.gradient[0].withOpacity(0.5) 
                      : widget.gradient[0].withOpacity(0.15),
                  width: 1.2,
                ),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.3),
                    blurRadius: 16,
                    offset: const Offset(0, 6),
                  ),
                  if (_isPressed)
                    BoxShadow(
                      color: widget.gradient[0].withOpacity(0.15),
                      blurRadius: 20,
                      spreadRadius: -2,
                    ),
                ],
              ),
              child: Stack(
                children: [
                  if (_isPressed)
                    Positioned.fill(
                      child: Container(
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            colors: [widget.gradient[0].withOpacity(0.1), Colors.transparent],
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                          ),
                          borderRadius: BorderRadius.circular(24),
                        ),
                      ),
                    ),
                  Padding(
                    padding: const EdgeInsets.all(18),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        AnimatedBuilder(
                          animation: widget.glowAnimation,
                          builder: (context, _) {
                            return Container(
                              padding: const EdgeInsets.all(12),
                              decoration: BoxDecoration(
                                color: widget.gradient[0].withOpacity(0.15),
                                borderRadius: BorderRadius.circular(16),
                                border: Border.all(color: widget.gradient[0].withOpacity(0.3), width: 1),
                                boxShadow: [
                                  BoxShadow(
                                    color: widget.gradient[0].withOpacity(0.2 * widget.glowAnimation.value),
                                    blurRadius: 12,
                                  ),
                                ],
                              ),
                              child: Icon(widget.icon, color: widget.gradient[0], size: 24),
                            );
                          },
                        ),
                        const Spacer(),
                        Text(
                          widget.label,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 15,
                            fontWeight: FontWeight.w800,
                            fontFamily: "CinzelDecorative",
                            letterSpacing: 1.5,
                          ),
                        ),
                        const SizedBox(height: 5),
                        Text(
                          widget.description,
                          style: TextStyle(
                            color: Colors.white.withOpacity(0.45),
                            fontSize: 10,
                            fontFamily: "CinzelDecorative",
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        const SizedBox(height: 12),
                        Row(
                          children: [
                            Container(
                              width: 30,
                              height: 2,
                              decoration: BoxDecoration(
                                gradient: LinearGradient(colors: widget.gradient),
                                borderRadius: BorderRadius.circular(2),
                              ),
                            ),
                            const Spacer(),
                            Icon(
                              Icons.arrow_forward_rounded,
                              color: _isPressed ? widget.gradient[0] : Colors.white.withOpacity(0.25),
                              size: 18,
                            ),
                          ],
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
    );
  }
}

class ToolsHexagonPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = const Color(0xFFE0E0E0).withOpacity(0.05)
      ..strokeWidth = 0.6
      ..style = PaintingStyle.stroke;

    const double side = 28;
    const double height = side * 1.732;
    const double width = side * 1.5;

    for (double y = 0; y < size.height + height; y += height) {
      for (double x = 0; x < size.width + width; x += width) {
        final offset = (y / height) % 2 == 0 ? 0.0 : width / 2;
        _drawHexagon(canvas, Offset(x + offset, y), side, paint);
      }
    }
  }

  void _drawHexagon(Canvas canvas, Offset center, double side, Paint paint) {
    final path = Path();
    for (int i = 0; i < 6; i++) {
      final angle = i * 60 * pi / 180;
      final x = center.dx + side * cos(angle);
      final y = center.dy + side * sin(angle);
      if (i == 0) {
        path.moveTo(x, y);
      } else {
        path.lineTo(x, y);
      }
    }
    path.close();
    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}