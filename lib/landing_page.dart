import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:video_player/video_player.dart';
import 'dart:math';
import 'dart:async';

import 'login_page.dart';

class LandingPage extends StatefulWidget {
  const LandingPage({super.key});

  @override
  State<LandingPage> createState() => _LandingPageState();
}

class _LandingPageState extends State<LandingPage>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> fadeAnimation;
  late Animation<Offset> slideAnimation;
  late Animation<double> scaleAnimation;
  late Animation<double> glowAnimation;
  late Animation<double> pulseAnimation;
  late Animation<double> rotateAnimation;
  late VideoPlayerController _videoController;

  late Timer _glowTimer;
  double _glowIntensity = 0.0;
  int _currentGlowIndex = 0;
  bool _showWelcomeDialogFlag = true;

  final Color _primaryColor = const Color(0xFFB0B0C8);
  final Color _secondaryColor = const Color(0xFF888899);
  final Color _accentColor = const Color(0xFFD0D0E8);
  final Color _successColor = const Color(0xFF9AAAB8);
  final Color _warningColor = const Color(0xFFC8C0A0);
  final Color _darkBg = const Color(0xFF0C0C10);
  final Color _darkerBg = const Color(0xFF070709);
  final Color _surfaceColor = const Color(0xFF14141C);
  final Color _cardColor = const Color(0xFF111118);
  final Color _glowColor1 = const Color(0xFFD8D8F0);
  final Color _glowColor2 = const Color(0xFF9090B0);
  final Color _glowColor3 = const Color(0xFFBBBBD0);
  final Color _roseColor = const Color(0xFFBB8899);

  final Color glassColor = const Color(0xFF181820);
  final Color glassBorder = const Color(0xFF2A2A38);

  @override
  void initState() {
    super.initState();

    _controller = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 1400));
    fadeAnimation = Tween<double>(begin: 0, end: 1).animate(
        CurvedAnimation(parent: _controller, curve: Curves.easeOut));
    slideAnimation = Tween<Offset>(begin: const Offset(0, 0.5), end: Offset.zero)
        .animate(CurvedAnimation(parent: _controller, curve: Curves.easeOutCubic));
    scaleAnimation = Tween<double>(begin: 0.9, end: 1.0).animate(
        CurvedAnimation(parent: _controller, curve: Curves.elasticOut));
    glowAnimation = Tween<double>(begin: 0, end: 1).animate(
        CurvedAnimation(parent: _controller, curve: Curves.easeInOut));
    pulseAnimation = Tween<double>(begin: 0.85, end: 1.15).animate(
        CurvedAnimation(parent: _controller, curve: Curves.easeInOutSine));
    rotateAnimation = Tween<double>(begin: 0, end: 1).animate(
        CurvedAnimation(parent: _controller, curve: Curves.linear));
    _controller.forward();

    _videoController = VideoPlayerController.asset('assets/videos/animek.mp4')
      ..initialize().then((_) {
        _videoController.setLooping(true);
        _videoController.setVolume(0.0);
        _videoController.setPlaybackSpeed(0.8);
        _videoController.play();
        if (mounted) setState(() {});
      }).catchError((error) {
        debugPrint("Video initialization error: $error");
      });

    _glowTimer = Timer.periodic(const Duration(milliseconds: 2000), (timer) {
      setState(() {
        _glowIntensity = 0.5 + (sin(DateTime.now().millisecondsSinceEpoch / 1000) * 0.5);
      });
    });
    
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _showWelcomeDialog();
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    _videoController.dispose();
    _glowTimer.cancel();
    super.dispose();
  }

  Future<void> _openUrl(String url) async {
    final Uri uri = Uri.parse(url);
    if (!await launchUrl(uri, mode: LaunchMode.externalApplication)) {
      debugPrint("Error launching $uri");
    }
  }

  void _showWelcomeDialog() {
    if (!_showWelcomeDialogFlag) return;
    
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return Dialog(
          backgroundColor: Colors.transparent,
          insetPadding: const EdgeInsets.all(20),
          child: TweenAnimationBuilder(
            tween: Tween<double>(begin: 0, end: 1),
            duration: const Duration(milliseconds: 500),
            curve: Curves.elasticOut,
            builder: (context, value, child) {
              return Transform.scale(
                scale: value,
                child: Opacity(
                  opacity: value,
                  child: Container(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [
                          glassColor.withOpacity(0.95),
                          glassColor.withOpacity(0.85),
                        ],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                      borderRadius: BorderRadius.circular(32),
                      border: Border.all(color: _glowColor1.withOpacity(0.3), width: 1.5),
                      boxShadow: [
                        BoxShadow(
                          color: _glowColor1.withOpacity(0.2),
                          blurRadius: 40,
                          spreadRadius: 5,
                        ),
                      ],
                    ),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(32),
                      child: BackdropFilter(
                        filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20),
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Container(
                              height: 180,
                              decoration: BoxDecoration(
                                borderRadius: const BorderRadius.vertical(top: Radius.circular(32)),
                                image: DecorationImage(
                                  image: AssetImage('assets/images/alicia.jpg'),
                                  fit: BoxFit.cover,
                                ),
                              ),
                              child: Container(
                                decoration: BoxDecoration(
                                  borderRadius: const BorderRadius.vertical(top: Radius.circular(32)),
                                  gradient: LinearGradient(
                                    begin: Alignment.topCenter,
                                    end: Alignment.bottomCenter,
                                    colors: [
                                      Colors.transparent,
                                      _darkerBg.withOpacity(0.9),
                                    ],
                                  ),
                                ),
                              ),
                            ),
                            Padding(
                              padding: const EdgeInsets.all(28),
                              child: Column(
                                children: [
                                  Row(
                                    children: [
                                      Container(
                                        padding: const EdgeInsets.all(8),
                                        decoration: BoxDecoration(
                                          color: _glowColor1.withOpacity(0.1),
                                          borderRadius: BorderRadius.circular(12),
                                          border: Border.all(color: _glowColor1.withOpacity(0.2), width: 1),
                                        ),
                                        child: Icon(FontAwesomeIcons.handPeace, color: _glowColor1, size: 24),
                                      ),
                                      const SizedBox(width: 16),
                                      Expanded(
                                        child: Text(
                                          'WELCOME BACK',
                                          style: TextStyle(
                                            fontFamily: 'CinzelDecorative',
                                            fontSize: 18,
                                            fontWeight: FontWeight.w900,
                                            color: _glowColor1,
                                            letterSpacing: 3,
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 20),
                                  Text(
                                    'Mantapp!!, akses udaaa bener nihhh',
                                    style: TextStyle(
                                      fontFamily: 'CinzelDecorative',
                                      fontSize: 16,
                                      fontWeight: FontWeight.w700,
                                      color: _successColor,
                                      letterSpacing: 1,
                                    ),
                                    textAlign: TextAlign.center,
                                  ),
                                  const SizedBox(height: 12),
                                  Text(
                                    'Nau langsung lanjut?',
                                    style: TextStyle(
                                      fontFamily: 'CinzelDecorative',
                                      fontSize: 14,
                                      fontWeight: FontWeight.w600,
                                      color: Colors.white.withOpacity(0.7),
                                      letterSpacing: 1,
                                    ),
                                    textAlign: TextAlign.center,
                                  ),
                                  const SizedBox(height: 28),
                                  Row(
                                    children: [
                                      Expanded(
                                        child: GestureDetector(
                                          onTap: () {
                                            setState(() {
                                              _showWelcomeDialogFlag = false;
                                            });
                                            Navigator.pop(context);
                                          },
                                          child: Container(
                                            padding: const EdgeInsets.symmetric(vertical: 14),
                                            decoration: BoxDecoration(
                                              color: _roseColor.withOpacity(0.1),
                                              borderRadius: BorderRadius.circular(16),
                                              border: Border.all(color: _roseColor.withOpacity(0.3), width: 1),
                                            ),
                                            child: Row(
                                              mainAxisAlignment: MainAxisAlignment.center,
                                              children: [
                                                Icon(FontAwesomeIcons.times, color: _roseColor.withOpacity(0.8), size: 16),
                                                const SizedBox(width: 10),
                                                Text(
                                                  'BATAL',
                                                  style: TextStyle(
                                                    fontFamily: 'CinzelDecorative',
                                                    fontSize: 13,
                                                    fontWeight: FontWeight.w800,
                                                    color: _roseColor.withOpacity(0.8),
                                                    letterSpacing: 2,
                                                  ),
                                                ),
                                              ],
                                            ),
                                          ),
                                        ),
                                      ),
                                      const SizedBox(width: 16),
                                      Expanded(
                                        child: GestureDetector(
                                          onTap: () {
                                            setState(() {
                                              _showWelcomeDialogFlag = false;
                                            });
                                            Navigator.pop(context);
                                          },
                                          child: Container(
                                            padding: const EdgeInsets.symmetric(vertical: 14),
                                            decoration: BoxDecoration(
                                              gradient: LinearGradient(
                                                colors: [_glowColor1, _glowColor2],
                                              ),
                                              borderRadius: BorderRadius.circular(16),
                                              boxShadow: [
                                                BoxShadow(
                                                  color: _glowColor1.withOpacity(0.3),
                                                  blurRadius: 20,
                                                  offset: const Offset(0, 6),
                                                ),
                                              ],
                                            ),
                                            child: Row(
                                              mainAxisAlignment: MainAxisAlignment.center,
                                              children: [
                                                Text(
                                                  'LANJUTKAN',
                                                  style: TextStyle(
                                                    fontFamily: 'CinzelDecorative',
                                                    fontSize: 13,
                                                    fontWeight: FontWeight.w900,
                                                    color: _darkerBg,
                                                    letterSpacing: 2,
                                                  ),
                                                ),
                                                const SizedBox(width: 10),
                                                Icon(FontAwesomeIcons.arrowRight, color: _darkerBg, size: 16),
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
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
              );
            },
          ),
        );
      },
    );
  }

  Widget _buildGlassContainer({
    required Widget child,
    double borderRadius = 28,
    EdgeInsetsGeometry? padding,
    bool withBorder = true,
    List<Color>? gradient,
    bool withShadow = true,
  }) {
    return Container(
      padding: padding,
      decoration: BoxDecoration(
        gradient: gradient != null
            ? LinearGradient(colors: gradient, begin: Alignment.topLeft, end: Alignment.bottomRight)
            : LinearGradient(
                colors: [glassColor.withOpacity(0.9), glassColor.withOpacity(0.6)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
        borderRadius: BorderRadius.circular(borderRadius),
        border: withBorder ? Border.all(color: glassBorder.withOpacity(0.7), width: 1.0) : null,
        boxShadow: withShadow
            ? [
                BoxShadow(color: Colors.black.withOpacity(0.6), blurRadius: 50, spreadRadius: -10, offset: const Offset(0, 20)),
                BoxShadow(color: _glowColor1.withOpacity(0.06), blurRadius: 40, spreadRadius: -5),
              ]
            : null,
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(borderRadius),
        child: BackdropFilter(filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20), child: child),
      ),
    );
  }

  Widget _buildAnimatedBackground() {
    return AnimatedBuilder(
      animation: rotateAnimation,
      builder: (context, child) {
        return Container(
          decoration: BoxDecoration(
            gradient: RadialGradient(
              center: const Alignment(-0.3, -0.5),
              radius: 2.0,
              colors: [
                _glowColor1.withOpacity(0.05),
                _secondaryColor.withOpacity(0.03),
                _darkBg,
                _darkerBg,
              ],
            ),
          ),
          child: Stack(
            children: [
              Positioned(
                top: -60,
                right: -80,
                child: Transform.rotate(
                  angle: rotateAnimation.value * pi * 2,
                  child: Container(
                    width: 340,
                    height: 340,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      gradient: RadialGradient(colors: [
                        _glowColor1.withOpacity(0.08),
                        _glowColor2.withOpacity(0.03),
                        Colors.transparent,
                      ]),
                    ),
                  ),
                ),
              ),
              Positioned(
                bottom: 100,
                left: -100,
                child: Transform.rotate(
                  angle: -rotateAnimation.value * pi,
                  child: Container(
                    width: 260,
                    height: 260,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      gradient: RadialGradient(colors: [
                        _secondaryColor.withOpacity(0.1),
                        _secondaryColor.withOpacity(0.02),
                        Colors.transparent,
                      ]),
                    ),
                  ),
                ),
              ),
              Positioned(
                top: MediaQuery.of(context).size.height * 0.35,
                right: -60,
                child: Container(
                  width: 180,
                  height: 180,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: RadialGradient(colors: [
                      _accentColor.withOpacity(0.07),
                      Colors.transparent,
                    ]),
                  ),
                ),
              ),
              if (_videoController.value.isInitialized)
                Positioned.fill(
                  child: Opacity(
                    opacity: 0.07,
                    child: FittedBox(
                      fit: BoxFit.cover,
                      child: SizedBox(
                        width: _videoController.value.size.width,
                        height: _videoController.value.size.height,
                        child: VideoPlayer(_videoController),
                      ),
                    ),
                  ),
                ),
              Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [
                      Colors.transparent,
                      Colors.black.withOpacity(0.2),
                      Colors.black.withOpacity(0.85),
                    ],
                  ),
                ),
              ),
              Container(
                color: Colors.white.withOpacity(0.01),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildHeroSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
              decoration: BoxDecoration(
                color: _glowColor1.withOpacity(0.06),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: _glowColor1.withOpacity(0.18), width: 1),
              ),
              child: Text(
                "v4.0",
                style: _cinzel(10, FontWeight.w700, 0.7),
              ),
            ),
            Row(
              children: [
                Container(
                  width: 7,
                  height: 7,
                  decoration: BoxDecoration(
                    color: _successColor,
                    shape: BoxShape.circle,
                    boxShadow: [BoxShadow(color: _successColor.withOpacity(0.9), blurRadius: 10)],
                  ),
                ),
                const SizedBox(width: 8),
                Text(
                  "ONLINE",
                  style: _cinzel(9, FontWeight.w700, 0.85),
                ),
              ],
            ),
          ],
        ),
        const SizedBox(height: 48),
        Stack(
          clipBehavior: Clip.none,
          children: [
            Positioned(
              left: -8,
              top: -18,
              child: Text(
                "SUN",
                style: TextStyle(
                  fontSize: 130,
                  fontWeight: FontWeight.w900,
                  fontFamily: 'CinzelDecorative',
                  foreground: Paint()
                    ..color = _glowColor1.withOpacity(0.04),
                  letterSpacing: -6,
                ),
              ),
            ),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                ShaderMask(
                  shaderCallback: (bounds) => LinearGradient(
                    colors: [_glowColor1, _accentColor, _glowColor2],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ).createShader(bounds),
                  child: Text(
                    "DEATHXRAT",
                    style: _cinzel(72, FontWeight.w900, 1.0).copyWith(
                      shadows: [
                        Shadow(color: _glowColor1.withOpacity(0.5), blurRadius: 30),
                        Shadow(color: _glowColor1.withOpacity(0.2), blurRadius: 60),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 4),
                Row(
                  children: [
                    Container(width: 32, height: 1.5, color: _glowColor2.withOpacity(0.5)),
                    const SizedBox(width: 10),
                    Text(
                      "PREMIUM SECURITY PLATFORM",
                      style: _cinzel(10, FontWeight.w600, 0.7),
                    ),
                  ],
                ),
              ],
            ),
          ],
        ),
        const SizedBox(height: 36),
        Row(
          children: [
            AnimatedBuilder(
              animation: pulseAnimation,
              builder: (context, child) {
                return Transform.scale(
                  scale: 0.92 + ((pulseAnimation.value - 0.85) / 0.3 * 0.08),
                  child: Container(
                    width: 80,
                    height: 80,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: _surfaceColor,
                      border: Border.all(color: _glowColor1.withOpacity(0.25), width: 1.5),
                      boxShadow: [
                        BoxShadow(
                          color: _glowColor1.withOpacity(0.3),
                          blurRadius: 40,
                          spreadRadius: 2,
                        ),
                        BoxShadow(
                          color: _glowColor1.withOpacity(0.1),
                          blurRadius: 80,
                          spreadRadius: 5,
                        ),
                      ],
                    ),
                    child: Center(
                      child: FaIcon(
                        FontAwesomeIcons.shieldHalved,
                        color: _glowColor1.withOpacity(0.9),
                        size: 34,
                      ),
                    ),
                  ),
                );
              },
            ),
            const SizedBox(width: 20),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    "ADVANCED",
                    style: _cinzel(18, FontWeight.w800, 0.85),
                  ),
                  Text(
                    "PROTECTION SUITE",
                    style: _cinzel(12, FontWeight.w600, 0.55),
                  ),
                  const SizedBox(height: 10),
                  Stack(
                    children: [
                      Container(
                        height: 3,
                        width: double.infinity,
                        decoration: BoxDecoration(
                          color: _glowColor1.withOpacity(0.07),
                          borderRadius: BorderRadius.circular(4),
                        ),
                      ),
                      Container(
                        height: 3,
                        width: 120,
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            colors: [_glowColor1.withOpacity(0.8), _glowColor2.withOpacity(0.2)],
                          ),
                          borderRadius: BorderRadius.circular(4),
                          boxShadow: [
                            BoxShadow(color: _glowColor1.withOpacity(0.5), blurRadius: 8),
                          ],
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildStatsRow() {
    final stats = [
      {"value": "99.99%", "label": "UPTIME", "color": _glowColor1, "icon": Icons.bar_chart},
      {"value": "24/7", "label": "SUPPORT", "color": _glowColor2, "icon": Icons.headset_mic},
      {"value": "150+", "label": "USERS", "color": _accentColor, "icon": Icons.group},
    ];

    return Row(
      children: stats.asMap().entries.map((entry) {
        int index = entry.key;
        var stat = entry.value;
        return Expanded(
          child: TweenAnimationBuilder(
            tween: Tween<double>(begin: 0, end: 1),
            duration: Duration(milliseconds: 500 + (index * 120)),
            curve: Curves.easeOutCubic,
            builder: (context, value, child) {
              return Opacity(
                opacity: value,
                child: Transform.translate(
                  offset: Offset(0, 20 * (1 - value)),
                  child: child,
                ),
              );
            },
            child: Container(
              margin: EdgeInsets.only(right: index < 2 ? 10 : 0),
              padding: const EdgeInsets.symmetric(vertical: 18, horizontal: 10),
              decoration: BoxDecoration(
                color: _surfaceColor.withOpacity(0.7),
                borderRadius: BorderRadius.circular(18),
                border: Border.all(
                  color: (stat["color"] as Color).withOpacity(0.18),
                  width: 1,
                ),
                boxShadow: [
                  BoxShadow(
                    color: (stat["color"] as Color).withOpacity(0.08),
                    blurRadius: 20,
                    spreadRadius: -2,
                  ),
                ],
              ),
              child: Column(
                children: [
                  Icon(stat["icon"] as IconData, color: (stat["color"] as Color).withOpacity(0.6), size: 16),
                  const SizedBox(height: 10),
                  Text(
                    stat["value"] as String,
                    style: _cinzel(24, FontWeight.w800, 1.0).copyWith(
                      color: stat["color"] as Color,
                      shadows: [
                        Shadow(color: (stat["color"] as Color).withOpacity(0.6), blurRadius: 16),
                      ],
                    ),
                  ),
                  const SizedBox(height: 5),
                  Text(
                    stat["label"] as String,
                    style: _cinzel(9, FontWeight.w700, 0.35),
                  ),
                ],
              ),
            ),
          ),
        );
      }).toList(),
    );
  }

  Widget _buildFeatureGrid() {
    final features = [
      {"icon": FontAwesomeIcons.shield, "title": "SECURITY", "color": _glowColor1, "desc": "Account Protection"},
      {"icon": FontAwesomeIcons.robot, "title": "CRASH WA", "color": _glowColor2, "desc": "Real Time Bugs"},
      {"icon": FontAwesomeIcons.clock, "title": "24/7 ACTIVE", "color": _accentColor, "desc": "Always Online"},
      {"icon": FontAwesomeIcons.lock, "title": "SPYWARE", "color": _glowColor3, "desc": "Device Monitoring"},
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Container(width: 4, height: 20, color: _glowColor1.withOpacity(0.7),
              decoration: BoxDecoration(
                color: _glowColor1,
                borderRadius: BorderRadius.circular(2),
                boxShadow: [BoxShadow(color: _glowColor1.withOpacity(0.8), blurRadius: 8)],
              ),
            ),
            const SizedBox(width: 12),
            Text(
              "CORE FEATURES",
              style: _cinzel(13, FontWeight.w800, 0.85),
            ),
          ],
        ),
        const SizedBox(height: 18),
        GridView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 2,
            childAspectRatio: 1.4,
            crossAxisSpacing: 12,
            mainAxisSpacing: 12,
          ),
          itemCount: features.length,
          itemBuilder: (context, index) {
            final feature = features[index];
            return TweenAnimationBuilder(
              tween: Tween<double>(begin: 0, end: 1),
              duration: Duration(milliseconds: 450 + (index * 90)),
              curve: Curves.easeOutCubic,
              builder: (context, value, child) {
                return Opacity(
                  opacity: value,
                  child: Transform.translate(
                    offset: Offset(0, 15 * (1 - value)),
                    child: child,
                  ),
                );
              },
              child: Container(
                decoration: BoxDecoration(
                  color: _cardColor,
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(
                    color: (feature["color"] as Color).withOpacity(0.2),
                    width: 1,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: (feature["color"] as Color).withOpacity(0.05),
                      blurRadius: 20,
                    ),
                  ],
                ),
                child: Stack(
                  children: [
                    Positioned(
                      top: -10,
                      right: -10,
                      child: Container(
                        width: 60,
                        height: 60,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          gradient: RadialGradient(colors: [
                            (feature["color"] as Color).withOpacity(0.12),
                            Colors.transparent,
                          ]),
                        ),
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.all(18),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          FaIcon(
                            feature["icon"] as IconData,
                            color: (feature["color"] as Color).withOpacity(0.85),
                            size: 26,
                          ),
                          const SizedBox(height: 14),
                          Text(
                            feature["title"] as String,
                            style: _cinzel(12, FontWeight.w800, 0.9),
                          ),
                          const SizedBox(height: 3),
                          Text(
                            feature["desc"] as String,
                            style: _cinzel(9, FontWeight.w500, 0.35),
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
      ],
    );
  }

  Widget _buildTestimonialCard() {
    return TweenAnimationBuilder(
      tween: Tween<double>(begin: 0, end: 1),
      duration: const Duration(milliseconds: 800),
      curve: Curves.easeOutCubic,
      builder: (context, value, child) {
        return Opacity(opacity: value, child: Transform.translate(offset: Offset(0, 20 * (1 - value)), child: child));
      },
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
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: List.generate(5, (i) =>
                    Icon(Icons.star, color: _warningColor.withOpacity(0.7), size: 14),
                  ),
                ),
                Icon(Icons.format_quote, color: _glowColor1.withOpacity(0.25), size: 28),
              ],
            ),
            const SizedBox(height: 16),
            Text(
              "Best security platform I've ever used. The protection is top-notch and the interface is incredibly smooth.",
              style: _cinzel(13, FontWeight.w500, 0.75),
            ),
            const SizedBox(height: 20),
            Row(
              children: [
                Container(
                  width: 42,
                  height: 42,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: _surfaceColor,
                    border: Border.all(color: _glowColor1.withOpacity(0.2), width: 1.2),
                    boxShadow: [
                      BoxShadow(color: _glowColor1.withOpacity(0.15), blurRadius: 12),
                    ],
                  ),
                  child: Center(
                    child: Icon(Icons.person, color: _glowColor1.withOpacity(0.7), size: 20),
                  ),
                ),
                const SizedBox(width: 14),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      "t.me/tzynotdev",
                      style: _cinzel(13, FontWeight.w700, 0.85),
                    ),
                    Text(
                      "Lead Developer",
                      style: _cinzel(10, FontWeight.w500, 0.35),
                    ),
                  ],
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPrimaryButton() {
    return TweenAnimationBuilder(
      tween: Tween<double>(begin: 0, end: 1),
      duration: const Duration(milliseconds: 800),
      curve: Curves.easeOutCubic,
      builder: (context, value, child) {
        return Opacity(opacity: value, child: Transform.translate(offset: Offset(0, 20 * (1 - value)), child: child));
      },
      child: GestureDetector(
        onTap: () => Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => const LoginPage(),
            settings: const RouteSettings(name: '/login'),
          ),
        ),
        child: Container(
          width: double.infinity,
          height: 62,
          decoration: BoxDecoration(
            color: _glowColor1.withOpacity(0.95),
            borderRadius: BorderRadius.circular(16),
            boxShadow: [
              BoxShadow(
                color: _glowColor1.withOpacity(0.35),
                blurRadius: 40,
                spreadRadius: 0,
                offset: const Offset(0, 10),
              ),
              BoxShadow(
                color: _glowColor1.withOpacity(0.15),
                blurRadius: 60,
                spreadRadius: 5,
              ),
            ],
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                "GET STARTED",
                style: _cinzel(14, FontWeight.w800, 1.0).copyWith(color: _darkerBg),
              ),
              const SizedBox(width: 14),
              Container(
                width: 30,
                height: 30,
                decoration: BoxDecoration(
                  color: _darkerBg.withOpacity(0.15),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(Icons.arrow_forward_rounded, color: _darkerBg, size: 16),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSecondaryButton() {
    return TweenAnimationBuilder(
      tween: Tween<double>(begin: 0, end: 1),
      duration: const Duration(milliseconds: 950),
      curve: Curves.easeOutCubic,
      builder: (context, value, child) {
        return Opacity(opacity: value, child: Transform.translate(offset: Offset(0, 20 * (1 - value)), child: child));
      },
      child: GestureDetector(
        onTap: () => _openUrl("https://t.me/abizar_mdArea"),
        child: Container(
          width: double.infinity,
          height: 62,
          decoration: BoxDecoration(
            color: Colors.transparent,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: _glowColor1.withOpacity(0.25), width: 1.2),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                padding: const EdgeInsets.all(7),
                decoration: BoxDecoration(
                  color: _glowColor1.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: FaIcon(FontAwesomeIcons.telegram, color: _glowColor1.withOpacity(0.9), size: 14),
              ),
              const SizedBox(width: 14),
              Text(
                "JOIN COMMUNITY",
                style: _cinzel(13, FontWeight.w700, 0.85),
              ),
            ],
          ),
        ),
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
              colors: [
                Colors.transparent,
                _glowColor1.withOpacity(0.15),
                Colors.transparent,
              ],
            ),
          ),
        ),
        const SizedBox(height: 24),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            _buildStatusDot(_successColor, "SECURE"),
            const SizedBox(width: 20),
            Container(width: 1, height: 14, color: Colors.white.withOpacity(0.08)),
            const SizedBox(width: 20),
            _buildStatusDot(_accentColor, "ENCRYPTED"),
            const SizedBox(width: 20),
            Container(width: 1, height: 14, color: Colors.white.withOpacity(0.08)),
            const SizedBox(width: 20),
            _buildStatusDot(_glowColor1, "AUDITED"),
          ],
        ),
        const SizedBox(height: 20),
        Text(
          "DEATHXRAT v4.0  •  ADVANCED SECURITY",
          style: _cinzel(9, FontWeight.w600, 0.12),
        ),
        const SizedBox(height: 6),
        Text(
          "© 2025 DEATHXRAT Security. All rights reserved.",
          style: _cinzel(8, FontWeight.w600, 0.07),
        ),
      ],
    );
  }

  Widget _buildStatusDot(Color color, String label) {
    return Row(
      children: [
        Container(
          width: 6,
          height: 6,
          decoration: BoxDecoration(
            color: color,
            shape: BoxShape.circle,
            boxShadow: [BoxShadow(color: color, blurRadius: 7, spreadRadius: 1)],
          ),
        ),
        const SizedBox(width: 7),
        Text(
          label,
          style: _cinzel(9, FontWeight.w700, 0.3),
        ),
      ],
    );
  }

  TextStyle _cinzel(double size, FontWeight weight, double opacity) {
    return TextStyle(
      fontFamily: 'CinzelDecorative',
      fontSize: size,
      fontWeight: weight,
      color: Colors.white.withOpacity(opacity),
      letterSpacing: 1.2,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _darkerBg,
      body: Stack(
        children: [
          _buildAnimatedBackground(),
          SafeArea(
            child: FadeTransition(
              opacity: fadeAnimation,
              child: SlideTransition(
                position: slideAnimation,
                child: SingleChildScrollView(
                  physics: const BouncingScrollPhysics(
                    parent: AlwaysScrollableScrollPhysics(),
                  ),
                  padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _buildHeroSection(),
                      const SizedBox(height: 36),
                      _buildStatsRow(),
                      const SizedBox(height: 36),
                      _buildFeatureGrid(),
                      const SizedBox(height: 28),
                      _buildTestimonialCard(),
                      const SizedBox(height: 36),
                      _buildPrimaryButton(),
                      const SizedBox(height: 14),
                      _buildSecondaryButton(),
                      const SizedBox(height: 40),
                      _buildFooter(),
                      const SizedBox(height: 20),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}