import 'dart:ui';
import 'dart:convert';
import 'dart:async';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:url_launcher/url_launcher.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:device_info_plus/device_info_plus.dart';
import 'api_config.dart';
import 'login_page.dart';
import 'buy_akses_sheet.dart';

// ─── PALETTE PURPLE CYBER ─────────────────────────────────────────────────
class _C {
  static const bg         = Color(0xFF0A0015);
  static const surface    = Color(0xFF15002A);
  static const card       = Color(0xFF1A0A2E);
  static const logoBg     = Color(0xFF2D1B4E);
  static const border     = Color(0xFF5B2D8E);

  static const purple     = Color(0xFF7C3AED);
  static const purpleDark = Color(0xFF4C1D95);
  static const purpleLight= Color(0xFFA78BFA);
  static const purpleGlow = Color(0xFFF0ABFC);
  static const pink       = Color(0xFFE879F9);

  static const text       = Color(0xFFF3E8FF);
  static const textSub    = Color(0xFFD4C4F0);
  static const textDim    = Color(0xFF8B7AAA);

  static const socialPurple = Color(0xFF7C3AED);
  static const socialGrey   = Color(0xFF2D1B4E);
  static const socialRed    = Color(0xFF6D28D9);
}

class LandingPage extends StatefulWidget {
  const LandingPage({super.key});

  @override
  State<LandingPage> createState() => _LandingPageState();
}

class _LandingPageState extends State<LandingPage>
    with TickerProviderStateMixin {

  late AnimationController _fadeCtrl;
  late Animation<double> _fadeAnim;
  late AnimationController _floatCtrl;
  late AnimationController _scrollLineCtrl;

  // ─── DIGITAL CLOCK ──────────────────────────────────────────────────────
  Timer? _clockTimer;
  String _timeWIB = '--:--:--';
  String _timeWITA = '--:--:--';
  String _timeWIT = '--:--:--';
  bool _showColon = true;

  // Scroll controller untuk garis bawah
  final ScrollController _scrollController = ScrollController();
  double _scrollOffset = 0.0;

  @override
  void initState() {
    super.initState();
    _fadeCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    );
    _fadeAnim = CurvedAnimation(parent: _fadeCtrl, curve: Curves.easeOutCubic);
    
    _floatCtrl = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 3),
    )..repeat(reverse: true);

    _scrollLineCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 300),
    );

    WidgetsBinding.instance.addPostFrameCallback((_) {
      _fadeCtrl.forward();
    });

    _updateClock();
    _clockTimer = Timer.periodic(const Duration(seconds: 1), (_) {
      _updateClock();
      setState(() => _showColon = !_showColon);
    });

    _scrollController.addListener(() {
      setState(() {
        _scrollOffset = _scrollController.offset;
      });
    });
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

  @override
  void dispose() {
    _clockTimer?.cancel();
    _fadeCtrl.dispose();
    _floatCtrl.dispose();
    _scrollLineCtrl.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  Future<void> _openUrl(String url) async {
    final uri = Uri.parse(url);
    if (!await launchUrl(uri, mode: LaunchMode.externalApplication)) {
      throw Exception('Could not launch $uri');
    }
  }

  // ─── LIST ANAK BUAH FULL SCREEN ──────────────────────────────────────
  void _showAnakBuahFullScreen() {
    Navigator.push(
      context,
      PageRouteBuilder(
        pageBuilder: (_, __, ___) => const _AnakBuahFullScreen(),
        transitionDuration: const Duration(milliseconds: 600),
        reverseTransitionDuration: const Duration(milliseconds: 500),
        transitionsBuilder: (_, anim, __, child) {
          final curved = CurvedAnimation(parent: anim, curve: Curves.easeOutCubic);
          return FadeTransition(
            opacity: curved,
            child: ScaleTransition(
              scale: Tween<double>(begin: 0.92, end: 1.0).animate(curved),
              child: child,
            ),
          );
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _C.bg,
      body: Stack(
        children: [
          // Background gradient
          Container(
            decoration: BoxDecoration(
              gradient: RadialGradient(
                center: Alignment.topCenter,
                radius: 1.4,
                colors: [
                  _C.surface,
                  _C.bg,
                  const Color(0xFF05000A),
                ],
                stops: const [0, 0.5, 1],
              ),
            ),
          ),
          // Garis bawah yang mengikuti scroll
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
                    _C.purple,
                    _C.purpleLight,
                    _C.purpleGlow,
                    _C.purple,
                    Colors.transparent,
                  ],
                  stops: const [0.0, 0.15, 0.4, 0.6, 0.85, 1.0],
                ),
                boxShadow: [
                  BoxShadow(
                    color: _C.purple.withOpacity(0.6),
                    blurRadius: 20,
                    spreadRadius: 3,
                  ),
                ],
              ),
            ),
          ),
          SafeArea(
            child: FadeTransition(
              opacity: _fadeAnim,
              child: SingleChildScrollView(
                controller: _scrollController,
                physics: const BouncingScrollPhysics(),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    const SizedBox(height: 16),
                    _buildDigitalClock(),
                    const SizedBox(height: 20),
                    _buildLogoBox(),
                    const SizedBox(height: 32),
                    _buildBigTitle(),
                    const SizedBox(height: 28),
                    _buildDescCard(),
                    const SizedBox(height: 20),
                    _buildLoginButton(),
                    const SizedBox(height: 14),
                    _buildBuyAksesButton(),
                    const SizedBox(height: 14),
                    _buildContactSupportButton(),
                    const SizedBox(height: 14),
                    _buildThanksToButton(),
                    const SizedBox(height: 14),
                    _buildAnakBuahButton(),
                    const SizedBox(height: 28),
                    _buildSocialSection(),
                    const SizedBox(height: 30),
                    // Garis bawah akhir
                    Container(
                      height: 2,
                      margin: const EdgeInsets.symmetric(horizontal: 40),
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
                    const SizedBox(height: 20),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ─── DIGITAL CLOCK ──────────────────────────────────────────────────────
  Widget _buildDigitalClock() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 24),
      padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 16),
      decoration: BoxDecoration(
        color: _C.card.withOpacity(0.6),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: _C.purple.withOpacity(0.25)),
        boxShadow: [
          BoxShadow(
            color: _C.purple.withOpacity(0.08),
            blurRadius: 20,
            spreadRadius: 2,
          ),
        ],
      ),
      child: Column(
        children: [
          // ─── GARIS LURUS GLOW UNGU ────────────────────────────────────
          Container(
            height: 2,
            width: double.infinity,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  Colors.transparent,
                  _C.purple,
                  _C.purpleLight,
                  _C.purpleGlow,
                  _C.purple,
                  Colors.transparent,
                ],
                stops: const [0.0, 0.15, 0.4, 0.6, 0.85, 1.0],
              ),
              borderRadius: BorderRadius.circular(2),
              boxShadow: [
                BoxShadow(
                  color: _C.purple.withOpacity(0.7),
                  blurRadius: 18,
                  spreadRadius: 3,
                ),
              ],
            ),
          ),
          const SizedBox(height: 10),
          // ─── JAM ──────────────────────────────────────────────────────────
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              _clockItem('WIB', _timeWIB),
              _clockItem('WITA', _timeWITA),
              _clockItem('WIT', _timeWIT),
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
                  color: _showColon ? _C.purpleLight : _C.purpleLight.withOpacity(0.15),
                  shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(
                      color: _C.purpleLight.withOpacity(_showColon ? 0.9 : 0.05),
                      blurRadius: 12,
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 6),
              Text(
                'LIVE',
                style: TextStyle(
                  color: _C.purpleLight.withOpacity(_showColon ? 0.9 : 0.2),
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

  Widget _clockItem(String label, String time) {
    return Column(
      children: [
        Text(
          label,
          style: TextStyle(
            color: _C.textDim.withOpacity(0.5),
            fontSize: 9,
            fontWeight: FontWeight.w600,
            letterSpacing: 1.5,
            fontFamily: 'Orbitron',
          ),
        ),
        const SizedBox(height: 2),
        Stack(
          children: [
            // Outer glow
            Text(
              time,
              style: TextStyle(
                color: _C.purple.withOpacity(0.06),
                fontSize: 18,
                fontWeight: FontWeight.w700,
                fontFamily: 'Orbitron',
                letterSpacing: 1.5,
                shadows: [
                  Shadow(color: _C.purple.withOpacity(0.3), blurRadius: 30),
                ],
              ),
            ),
            // Inner glow
            Text(
              time,
              style: TextStyle(
                color: _C.purple.withOpacity(0.15),
                fontSize: 18,
                fontWeight: FontWeight.w700,
                fontFamily: 'Orbitron',
                letterSpacing: 1.5,
                shadows: [
                  Shadow(color: _C.purple.withOpacity(0.6), blurRadius: 50),
                ],
              ),
            ),
            // Main text
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

  Widget _buildLogoBox() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: AnimatedBuilder(
        animation: _floatCtrl,
        builder: (context, child) {
          return Transform.translate(
            offset: Offset(0, 6 * _floatCtrl.value),
            child: Container(
              width: double.infinity,
              height: 210,
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [
                    _C.logoBg.withOpacity(0.9),
                    _C.card.withOpacity(0.8),
                  ],
                ),
                borderRadius: BorderRadius.circular(28),
                border: Border.all(
                  color: _C.purple.withOpacity(0.25),
                  width: 1.5,
                ),
                boxShadow: [
                  BoxShadow(
                    color: _C.purple.withOpacity(0.12),
                    blurRadius: 30,
                    spreadRadius: 3,
                    offset: const Offset(0, 12),
                  ),
                ],
              ),
              child: Stack(
                fit: StackFit.expand,
                children: [
                  ClipRRect(
                    borderRadius: BorderRadius.circular(28),
                    child: Image.asset(
                      'assets/images/login.png',
                      width: double.infinity,
                      height: double.infinity,
                      fit: BoxFit.cover,
                    ),
                  ),
                  Container(
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(28),
                      gradient: LinearGradient(
                        begin: Alignment.bottomCenter,
                        end: Alignment.topCenter,
                        colors: [
                          Colors.black.withOpacity(0.75),
                          Colors.transparent,
                          Colors.transparent,
                        ],
                      ),
                    ),
                  ),
                  Positioned(
                    bottom: 16,
                    right: 16,
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                      decoration: BoxDecoration(
                        color: _C.purple.withOpacity(0.2),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: _C.purple.withOpacity(0.4)),
                      ),
                      child: Text(
                        'FLUXOU CORE',
                        style: TextStyle(
                          color: _C.purpleLight,
                          fontSize: 10,
                          fontWeight: FontWeight.bold,
                          fontFamily: 'Orbitron',
                          letterSpacing: 1,
                        ),
                      ),
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

  Widget _buildBigTitle() {
    return Column(
      children: [
        ShaderMask(
          shaderCallback: (bounds) => const LinearGradient(
            colors: [
              Color(0xFFF3E8FF),
              Color(0xFF7C3AED),
              Color(0xFFF0ABFC),
              Color(0xFF7C3AED),
              Color(0xFFF3E8FF),
            ],
            stops: [0.0, 0.3, 0.6, 0.8, 1.0],
            begin: Alignment.centerLeft,
            end: Alignment.centerRight,
          ).createShader(bounds),
          child: const Text(
            'PURPLE - CORE',
            textAlign: TextAlign.center,
            style: TextStyle(
              color: Colors.white,
              fontSize: 42,
              fontWeight: FontWeight.w900,
              fontFamily: 'Orbitron',
              letterSpacing: 5,
              height: 1.0,
            ),
          ),
        ),
        const SizedBox(height: 12),
        Container(
          width: 160,
          height: 2,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(10),
            gradient: const LinearGradient(
              colors: [Colors.transparent, Color(0xFF7C3AED), Color(0xFFF0ABFC), Colors.transparent],
            ),
          ),
        ),
        const SizedBox(height: 14),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [_C.purple.withOpacity(0.12), _C.purpleDark.withOpacity(0.05)],
            ),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: _C.purple.withOpacity(0.25)),
          ),
          child: const Text(
            'P R E M I U M   •   T E R U P D A T E   •   C A N G G I H',
            textAlign: TextAlign.center,
            style: TextStyle(
              color: _C.purpleLight,
              fontSize: 11,
              letterSpacing: 2.5,
              fontWeight: FontWeight.w600,
              fontFamily: 'Orbitron',
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildDescCard() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 28),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              _C.card.withOpacity(0.7),
              _C.card.withOpacity(0.5),
            ],
          ),
          borderRadius: BorderRadius.circular(24),
          border: Border.all(
            color: _C.purple.withOpacity(0.2),
            width: 1.5,
          ),
          boxShadow: [
            BoxShadow(
              color: _C.purple.withOpacity(0.08),
              blurRadius: 20,
              spreadRadius: 1,
              offset: const Offset(0, 10),
            ),
          ],
        ),
        child: Column(
          children: [
            Container(
              width: 60,
              height: 60,
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [_C.purple.withOpacity(0.3), _C.purpleDark.withOpacity(0.2)],
                ),
                borderRadius: BorderRadius.circular(18),
                border: Border.all(color: _C.purple.withOpacity(0.5), width: 1.5),
                boxShadow: [
                  BoxShadow(
                    color: _C.purple.withOpacity(0.3),
                    blurRadius: 16,
                    spreadRadius: 2,
                  ),
                ],
              ),
              child: const Center(
                child: Icon(
                  Icons.shield_outlined,
                  color: _C.purpleLight,
                  size: 30,
                ),
              ),
            ),
            const SizedBox(height: 20),
            ShaderMask(
              shaderCallback: (bounds) => const LinearGradient(
                colors: [Color(0xFF7C3AED), Color(0xFFF0ABFC)],
              ).createShader(bounds),
              child: const Text(
                'CEYBER BUG',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  fontFamily: 'Orbitron',
                  letterSpacing: 3,
                ),
              ),
            ),
            const SizedBox(height: 16),
            Text(
              'Aplikasi dengan design elegant dan fitur terbaru.\nPengembangan langsung oleh TEAM FLUXOU - CORE.',
              textAlign: TextAlign.center,
              style: TextStyle(
                color: _C.textSub,
                fontSize: 13,
                height: 1.6,
                fontFamily: 'ShareTechMono',
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildLoginButton() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        width: double.infinity,
        height: 56,
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [
              _C.purple.withOpacity(0.15),
              _C.purpleDark.withOpacity(0.1),
            ],
          ),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: _C.purple, width: 1.5),
          boxShadow: [
            BoxShadow(
              color: _C.purple.withOpacity(0.25),
              blurRadius: 14,
              spreadRadius: 2,
            ),
          ],
        ),
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: () => Navigator.pushReplacement(
              context,
              MaterialPageRoute(builder: (_) => LoginPage()),
            ),
            borderRadius: BorderRadius.circular(16),
            child: Container(
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(16),
              ),
              child: const Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.rocket_launch_rounded, color: _C.purpleLight, size: 20),
                  SizedBox(width: 12),
                  Text(
                    'LOGIN TO FLUXOU CORE',
                    style: TextStyle(
                      color: _C.purpleLight,
                      fontSize: 13,
                      fontWeight: FontWeight.bold,
                      fontFamily: 'Orbitron',
                      letterSpacing: 2,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildContactSupportButton() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: Container(
        width: double.infinity,
        height: 56,
        decoration: BoxDecoration(
          color: _C.card.withOpacity(0.5),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: _C.border, width: 1.5),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.2),
              blurRadius: 8,
              spreadRadius: 0,
            ),
          ],
        ),
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: () => _openUrl('https://t.me/wahyustory'),
            borderRadius: BorderRadius.circular(16),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.headset_mic_rounded, color: _C.textSub, size: 20),
                const SizedBox(width: 12),
                Text(
                  'CONTACT SUPPORT',
                  style: TextStyle(
                    color: _C.textSub,
                    fontSize: 13,
                    fontWeight: FontWeight.bold,
                    fontFamily: 'Orbitron',
                    letterSpacing: 2,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildThanksToButton() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: Container(
        width: double.infinity,
        height: 50,
        decoration: BoxDecoration(
          color: _C.card.withOpacity(0.5),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: const Color(0xFFFFD700).withOpacity(0.4), width: 1.5),
          boxShadow: [
            BoxShadow(
              color: const Color(0xFFFFD700).withOpacity(0.1),
              blurRadius: 12,
              spreadRadius: 0,
            ),
          ],
        ),
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: _showThanksToFullScreen,
            borderRadius: BorderRadius.circular(16),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.emoji_people_rounded, color: Color(0xFFFFD700), size: 20),
                const SizedBox(width: 12),
                const Text(
                  'THANKS TO',
                  style: TextStyle(
                    color: Color(0xFFFFD700),
                    fontSize: 13,
                    fontWeight: FontWeight.bold,
                    fontFamily: 'Orbitron',
                    letterSpacing: 2,
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                  decoration: BoxDecoration(
                    color: const Color(0xFFFFD700).withOpacity(0.15),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: const Color(0xFFFFD700).withOpacity(0.3)),
                  ),
                  child: const Text(
                    '❤️',
                    style: TextStyle(
                      fontSize: 10,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // ─── LIST ANAK BUAH BUTTON ─────────────────────────────────────────────
  Widget _buildAnakBuahButton() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        width: double.infinity,
        height: 50,
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [
              _C.purple.withOpacity(0.15),
              _C.purpleDark.withOpacity(0.1),
            ],
          ),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: _C.purpleLight, width: 1.5),
          boxShadow: [
            BoxShadow(
              color: _C.purpleLight.withOpacity(0.2),
              blurRadius: 12,
              spreadRadius: 1,
            ),
          ],
        ),
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: _showAnakBuahFullScreen,
            borderRadius: BorderRadius.circular(16),
            child: const Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.people_alt_rounded, color: _C.purpleLight, size: 20),
                SizedBox(width: 12),
                Text(
                  'LIST ANAK BUAH GWEH',
                  style: TextStyle(
                    color: _C.purpleLight,
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                    fontFamily: 'Orbitron',
                    letterSpacing: 2,
                  ),
                ),
                SizedBox(width: 8),
                Icon(Icons.arrow_forward_ios_rounded, color: _C.purpleLight, size: 14),
              ],
            ),
          ),
        ),
      ),
    );
  }

  void _showThanksToFullScreen() {
    Navigator.push(
      context,
      PageRouteBuilder(
        pageBuilder: (_, __, ___) => const _ThanksToFullScreen(),
        transitionDuration: const Duration(milliseconds: 500),
        reverseTransitionDuration: const Duration(milliseconds: 400),
        transitionsBuilder: (_, anim, __, child) => FadeTransition(
          opacity: anim,
          child: child,
        ),
      ),
    );
  }

  Widget _buildSocialSection() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 24),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              _C.card.withOpacity(0.6),
              _C.card.withOpacity(0.4),
            ],
          ),
          borderRadius: BorderRadius.circular(24),
          border: Border.all(color: _C.border, width: 1),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.3),
              blurRadius: 16,
              spreadRadius: 2,
              offset: const Offset(0, 6),
            ),
          ],
        ),
        child: Column(
          children: [
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
              decoration: BoxDecoration(
                color: _C.purple.withOpacity(0.1),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: _C.purple.withOpacity(0.2)),
              ),
              child: Text(
                'HUBUNGI KAMI',
                style: TextStyle(
                  color: _C.purpleLight,
                  fontSize: 11,
                  letterSpacing: 2,
                  fontWeight: FontWeight.w600,
                  fontFamily: 'Orbitron',
                ),
              ),
            ),
            const SizedBox(height: 24),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                _buildSocialItem(
                  icon: FontAwesomeIcons.telegram,
                  bgColor: _C.purple,
                  label: 'Telegram',
                  onTap: () => _openUrl('https://t.me/wahyustory'),
                ),
                _buildSocialItem(
                  icon: FontAwesomeIcons.tiktok,
                  bgColor: _C.purpleLight,
                  label: 'TikTok',
                  onTap: () => _openUrl('https://tiktok.com/@blmada'),
                ),
                _buildSocialItem(
                  icon: FontAwesomeIcons.instagram,
                  bgColor: _C.purpleGlow,
                  label: 'Instagram',
                  onTap: () => _openUrl('https://www.instagram.com/blmada?igsh=eW1sZXhpOWZsOG1t'),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSocialItem({
    required IconData icon,
    required Color bgColor,
    required String label,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Column(
        children: [
          Container(
            width: 64,
            height: 64,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: bgColor.withOpacity(0.15),
              border: Border.all(color: bgColor.withOpacity(0.8), width: 2),
              boxShadow: [
                BoxShadow(
                  color: bgColor.withOpacity(0.35),
                  blurRadius: 18,
                  spreadRadius: 2,
                ),
              ],
            ),
            child: Center(
              child: FaIcon(icon, color: bgColor, size: 26),
            ),
          ),
          const SizedBox(height: 10),
          Text(
            label,
            style: TextStyle(
              color: _C.textSub,
              fontSize: 11,
              fontWeight: FontWeight.w500,
              letterSpacing: 1,
              fontFamily: 'ShareTechMono',
            ),
          ),
        ],
      ),
    );
  }

  void _showBuyAksesSheet() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (_) => _BuyAksesSheet(
        onBuy: (url) async {
          Navigator.pop(context);
          await launchUrl(Uri.parse(url), mode: LaunchMode.externalApplication);
        },
      ),
    );
  }

  Widget _buildBuyAksesButton() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: Container(
        width: double.infinity,
        height: 56,
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            colors: [Color(0xFF7C3AED), Color(0xFF4C1D95)],
            begin: Alignment.centerLeft,
            end: Alignment.centerRight,
          ),
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: const Color(0xFF7C3AED).withOpacity(0.4),
              blurRadius: 18,
              spreadRadius: 2,
            ),
          ],
        ),
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: _showBuyAksesSheet,
            borderRadius: BorderRadius.circular(16),
            child: const Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.shopping_cart_rounded, color: Colors.white, size: 20),
                SizedBox(width: 12),
                Text(
                  'BUY AKSES',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 13,
                    fontWeight: FontWeight.bold,
                    fontFamily: 'Orbitron',
                    letterSpacing: 2,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

// ─── LIST ANAK BUAH FULL SCREEN ────────────────────────────────────────────
class _AnakBuahFullScreen extends StatefulWidget {
  const _AnakBuahFullScreen();

  @override
  State<_AnakBuahFullScreen> createState() => _AnakBuahFullScreenState();
}

class _AnakBuahFullScreenState extends State<_AnakBuahFullScreen>
    with TickerProviderStateMixin {
  late AnimationController _fadeCtrl;
  late Animation<double> _fadeAnim;
  late AnimationController _floatCtrl;
  late AnimationController _rotateCtrl;

  final List<Map<String, dynamic>> _anakBuah = [
    {'name': 'Wahyu', 'title': 'My Babu 😈', 'color': Color(0xFFFF6B6B)},
    {'name': 'Afif', 'title': 'My Budak 🤨', 'color': Color(0xFF4ECDC4)},
    {'name': 'Arul', 'title': 'Pemain Bokep 🤨', 'color': Color(0xFFFFD93D)},
  ];

  @override
  void initState() {
    super.initState();
    _fadeCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600),
    )..forward();
    _fadeAnim = CurvedAnimation(parent: _fadeCtrl, curve: Curves.easeOut);

    _floatCtrl = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 4),
    )..repeat(reverse: true);

    _rotateCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    );
  }

  @override
  void dispose() {
    _fadeCtrl.dispose();
    _floatCtrl.dispose();
    _rotateCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.transparent,
      body: Stack(
        children: [
          Positioned.fill(
            child: BackdropFilter(
              filter: ImageFilter.blur(sigmaX: 16, sigmaY: 16),
              child: Container(
                decoration: BoxDecoration(
                  gradient: RadialGradient(
                    center: Alignment.center,
                    radius: 1.5,
                    colors: [
                      const Color(0xFF1A0A2E).withOpacity(0.9),
                      const Color(0xFF0A0015).withOpacity(0.95),
                    ],
                  ),
                ),
              ),
            ),
          ),
          // Garis glow di atas
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
                    const Color(0xFF7C3AED),
                    const Color(0xFFF0ABFC),
                    const Color(0xFF7C3AED),
                    Colors.transparent,
                  ],
                  stops: const [0.0, 0.2, 0.5, 0.8, 1.0],
                ),
                boxShadow: [
                  BoxShadow(
                    color: const Color(0xFF7C3AED).withOpacity(0.6),
                    blurRadius: 20,
                    spreadRadius: 3,
                  ),
                ],
              ),
            ),
          ),
          FadeTransition(
            opacity: _fadeAnim,
            child: SafeArea(
              child: Column(
                children: [
                  const SizedBox(height: 20),
                  // Header
                  Row(
                    children: [
                      const SizedBox(width: 20),
                      Container(
                        width: 50, height: 50,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          gradient: const LinearGradient(
                            colors: [Color(0xFF7C3AED), Color(0xFFF0ABFC)],
                          ),
                          boxShadow: [
                            BoxShadow(
                              color: const Color(0xFF7C3AED).withOpacity(0.5),
                              blurRadius: 25,
                            ),
                          ],
                        ),
                        child: const Icon(Icons.people_alt_rounded, color: Colors.white, size: 28),
                      ),
                      const SizedBox(width: 14),
                      const Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'LIST ANAK BUAH',
                              style: TextStyle(
                                color: Color(0xFFF3E8FF),
                                fontSize: 20,
                                fontWeight: FontWeight.bold,
                                fontFamily: 'Orbitron',
                                letterSpacing: 2,
                              ),
                            ),
                            Text(
                              'GWEH YANG GANAS 🔥',
                              style: TextStyle(
                                color: Color(0xFFA78BFA),
                                fontSize: 12,
                                fontFamily: 'ShareTechMono',
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 24),
                  // 3D Cards
                  Expanded(
                    child: ListView.builder(
                      physics: const BouncingScrollPhysics(),
                      padding: const EdgeInsets.symmetric(horizontal: 20),
                      itemCount: _anakBuah.length,
                      itemBuilder: (context, index) {
                        final item = _anakBuah[index];
                        final color = item['color'] as Color;
                        return AnimatedBuilder(
                          animation: _floatCtrl,
                          builder: (context, child) {
                            final delay = index * 0.15;
                            final offset = (1 + delay) * 4 * _floatCtrl.value;
                            return Transform.translate(
                              offset: Offset(0, offset),
                              child: GestureDetector(
                                onTap: () {
                                  _rotateCtrl.forward(from: 0);
                                },
                                child: TweenAnimationBuilder(
                                  duration: const Duration(milliseconds: 500),
                                  tween: Tween<double>(begin: 0, end: 1),
                                  builder: (context, value, child) {
                                    final transform = Matrix4.identity()
                                      ..setEntry(3, 2, 0.001)
                                      ..rotateX((value * 0.05) - 0.05)
                                      ..rotateY((1 - value) * 0.1);
                                    return Transform(
                                      transform: transform,
                                      child: Container(
                                        margin: const EdgeInsets.only(bottom: 14),
                                        padding: const EdgeInsets.all(20),
                                        decoration: BoxDecoration(
                                          gradient: LinearGradient(
                                            colors: [
                                              color.withOpacity(0.25),
                                              color.withOpacity(0.08),
                                            ],
                                            begin: Alignment.topLeft,
                                            end: Alignment.bottomRight,
                                          ),
                                          borderRadius: BorderRadius.circular(24),
                                          border: Border.all(
                                            color: color.withOpacity(0.5),
                                            width: 1.5,
                                          ),
                                          boxShadow: [
                                            BoxShadow(
                                              color: color.withOpacity(0.3),
                                              blurRadius: 24,
                                              spreadRadius: 2,
                                              offset: const Offset(0, 8),
                                            ),
                                          ],
                                        ),
                                        child: Row(
                                          children: [
                                            Container(
                                              width: 56, height: 56,
                                              decoration: BoxDecoration(
                                                shape: BoxShape.circle,
                                                gradient: LinearGradient(
                                                  colors: [color, color.withOpacity(0.6)],
                                                ),
                                                boxShadow: [
                                                  BoxShadow(
                                                    color: color.withOpacity(0.4),
                                                    blurRadius: 20,
                                                    spreadRadius: 2,
                                                  ),
                                                ],
                                              ),
                                              child: Center(
                                                child: Text(
                                                  item['name'][0],
                                                  style: const TextStyle(
                                                    color: Colors.white,
                                                    fontSize: 22,
                                                    fontWeight: FontWeight.bold,
                                                    fontFamily: 'Orbitron',
                                                  ),
                                                ),
                                              ),
                                            ),
                                            const SizedBox(width: 16),
                                            Expanded(
                                              child: Column(
                                                crossAxisAlignment: CrossAxisAlignment.start,
                                                children: [
                                                  Text(
                                                    item['name'],
                                                    style: TextStyle(
                                                      color: Colors.white,
                                                      fontSize: 18,
                                                      fontWeight: FontWeight.bold,
                                                      fontFamily: 'Orbitron',
                                                      letterSpacing: 1,
                                                    ),
                                                  ),
                                                  const SizedBox(height: 4),
                                                  Text(
                                                    item['title'],
                                                    style: TextStyle(
                                                      color: color,
                                                      fontSize: 13,
                                                      fontFamily: 'ShareTechMono',
                                                    ),
                                                  ),
                                                ],
                                              ),
                                            ),
                                            Container(
                                              width: 40, height: 40,
                                              decoration: BoxDecoration(
                                                shape: BoxShape.circle,
                                                color: color.withOpacity(0.15),
                                                border: Border.all(color: color.withOpacity(0.3)),
                                              ),
                                              child: const Icon(
                                                Icons.arrow_forward_ios_rounded,
                                                color: Colors.white54,
                                                size: 16,
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                    );
                                  },
                                ),
                              ),
                            );
                          },
                        );
                      },
                    ),
                  ),
                  // Tombol Menutup
                  Padding(
                    padding: EdgeInsets.fromLTRB(20, 10, 20, MediaQuery.of(context).padding.bottom + 20),
                    child: AnimatedBuilder(
                      animation: _floatCtrl,
                      builder: (context, child) {
                        return Transform.translate(
                          offset: Offset(0, 4 * _floatCtrl.value),
                          child: GestureDetector(
                            onTap: () => Navigator.pop(context),
                            child: Container(
                              width: double.infinity,
                              height: 56,
                              decoration: BoxDecoration(
                                gradient: const LinearGradient(
                                  colors: [Color(0xFF7C3AED), Color(0xFF4C1D95)],
                                  begin: Alignment.centerLeft,
                                  end: Alignment.centerRight,
                                ),
                                borderRadius: BorderRadius.circular(18),
                                boxShadow: [
                                  BoxShadow(
                                    color: const Color(0xFF7C3AED).withOpacity(0.4),
                                    blurRadius: 24,
                                    spreadRadius: 2,
                                  ),
                                ],
                              ),
                              child: const Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Icon(Icons.close_rounded, color: Colors.white, size: 22),
                                  SizedBox(width: 12),
                                  Text(
                                    'MENUTUP',
                                    style: TextStyle(
                                      color: Colors.white,
                                      fontSize: 15,
                                      fontWeight: FontWeight.bold,
                                      fontFamily: 'Orbitron',
                                      letterSpacing: 2,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        );
                      },
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ─── THANKS TO FULL SCREEN ────────────────────────────────────────────────────
class _ThanksToFullScreen extends StatefulWidget {
  const _ThanksToFullScreen();

  @override
  State<_ThanksToFullScreen> createState() => _ThanksToFullScreenState();
}

class _ThanksToFullScreenState extends State<_ThanksToFullScreen>
    with TickerProviderStateMixin {
  late AnimationController _fadeCtrl;
  late Animation<double> _fadeAnim;
  late AnimationController _floatCtrl;

  @override
  void initState() {
    super.initState();
    _fadeCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600),
    )..forward();
    _fadeAnim = CurvedAnimation(parent: _fadeCtrl, curve: Curves.easeOut);

    _floatCtrl = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 4),
    )..repeat(reverse: true);
  }

  @override
  void dispose() {
    _fadeCtrl.dispose();
    _floatCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.transparent,
      body: Stack(
        children: [
          Positioned.fill(
            child: BackdropFilter(
              filter: ImageFilter.blur(sigmaX: 12, sigmaY: 12),
              child: Container(
                color: Colors.black.withOpacity(0.7),
              ),
            ),
          ),
          FadeTransition(
            opacity: _fadeAnim,
            child: SafeArea(
              child: SingleChildScrollView(
                physics: const BouncingScrollPhysics(),
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Container(
                          width: 50, height: 50,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            gradient: LinearGradient(
                              colors: [const Color(0xFFFFD700), const Color(0xFFFFA500)],
                            ),
                            boxShadow: [
                              BoxShadow(
                                color: const Color(0xFFFFD700).withOpacity(0.4),
                                blurRadius: 20,
                              ),
                            ],
                          ),
                          child: const Icon(Icons.emoji_people_rounded, color: Colors.white, size: 28),
                        ),
                        const SizedBox(width: 14),
                        const Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'THANKS TO',
                                style: TextStyle(
                                  color: Color(0xFFFFD700),
                                  fontSize: 22,
                                  fontWeight: FontWeight.bold,
                                  fontFamily: 'Orbitron',
                                  letterSpacing: 2,
                                ),
                              ),
                              Text(
                                'Terima kasih untuk semua supportnya ❤️',
                                style: TextStyle(
                                  color: Colors.white54,
                                  fontSize: 12,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 28),
                    _buildFullSection('FLUXOU TEAM', const Color(0xFF7C3AED), [
                      'Razz', 'Wahyu', 'Afif', 'Arga', 'Tama',
                      'Arul', 'Tirzz', 'Renn', 'Asep', 'Renzz'
                    ]),
                    const SizedBox(height: 24),
                    _buildFullSection('BUYER', const Color(0xFFF59E0B), [
                      'Arga: Friend', 'Tirzz: TK', 'Arul: TK',
                      'Afif: TK', 'DAENG: OWNER', 'Sei: Owner',
                      'Tirzz: Resseler', 'Ryuk: Resseler',
                      'Banzz: Member', 'Faizan: Admin',
                      'Kenny: Member', 'Dimzz: Member',
                      'Kanzz: Resseler', 'Bani: Member',
                      'DILL: Member', 'Diki: Member',
                    ]),
                    const SizedBox(height: 24),
                    _buildFullSection('SAHABAT', const Color(0xFFFF6B9D), [
                      'RAZZ X YUU'
                    ]),
                    const SizedBox(height: 24),
                    _buildFullSection('MY FRIEND', const Color(0xFF22C55E), [
                      'Razz', 'Wahyu', 'Afif', 'Arga', 'Tama',
                      'Arul', 'Tirzz', 'Renn', 'Asep', 'Renzz', 'Yumbud'
                    ]),
                    const SizedBox(height: 40),
                    AnimatedBuilder(
                      animation: _floatCtrl,
                      builder: (_, __) => Transform.translate(
                        offset: Offset(0, 4 * _floatCtrl.value),
                        child: GestureDetector(
                          onTap: () => Navigator.pop(context),
                          child: Container(
                            width: double.infinity,
                            height: 56,
                            decoration: BoxDecoration(
                              gradient: const LinearGradient(
                                colors: [Color(0xFF7C3AED), Color(0xFF4C1D95)],
                                begin: Alignment.centerLeft,
                                end: Alignment.centerRight,
                              ),
                              borderRadius: BorderRadius.circular(18),
                              boxShadow: [
                                BoxShadow(
                                  color: const Color(0xFF7C3AED).withOpacity(0.4),
                                  blurRadius: 20,
                                  spreadRadius: 2,
                                ),
                              ],
                            ),
                            child: const Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(Icons.close_rounded, color: Colors.white, size: 22),
                                SizedBox(width: 12),
                                Text(
                                  'TUTUP',
                                  style: TextStyle(
                                    color: Colors.white,
                                    fontSize: 15,
                                    fontWeight: FontWeight.bold,
                                    fontFamily: 'Orbitron',
                                    letterSpacing: 2,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 20),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFullSection(String title, Color color, List<String> items) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Container(
              width: 4, height: 22,
              decoration: BoxDecoration(
                color: color,
                borderRadius: BorderRadius.circular(2),
                boxShadow: [
                  BoxShadow(
                    color: color.withOpacity(0.4),
                    blurRadius: 8,
                  ),
                ],
              ),
            ),
            const SizedBox(width: 12),
            Text(
              title,
              style: TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
                fontSize: 17,
                fontFamily: 'Orbitron',
                letterSpacing: 1,
              ),
            ),
            const SizedBox(width: 12),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
              decoration: BoxDecoration(
                color: color.withOpacity(0.15),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: color.withOpacity(0.3)),
              ),
              child: Text(
                '${items.length}',
                style: TextStyle(
                  color: color,
                  fontSize: 11,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        Wrap(
          spacing: 10,
          runSpacing: 10,
          children: items.map((name) {
            return Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
              decoration: BoxDecoration(
                color: color.withOpacity(0.08),
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: color.withOpacity(0.2)),
                boxShadow: [
                  BoxShadow(
                    color: color.withOpacity(0.05),
                    blurRadius: 8,
                  ),
                ],
              ),
              child: Text(
                name,
                style: TextStyle(
                  color: Colors.white70,
                  fontSize: 13,
                  fontWeight: FontWeight.w500,
                ),
              ),
            );
          }).toList(),
        ),
      ],
    );
  }
}

// ─── Buy Akses Bottom Sheet ──────────────────────────────────────────────────
class _BuyAksesSheet extends StatefulWidget {
  final Future<void> Function(String url) onBuy;
  const _BuyAksesSheet({required this.onBuy});

  @override
  State<_BuyAksesSheet> createState() => _BuyAksesSheetState();
}

class _BuyAksesSheetState extends State<_BuyAksesSheet> {
  int _selectedPackage = 0;
  String _selectedRole = 'full_up';

  final Map<String, Map<String, dynamic>> _packages = {
    'full_up': {
      'label': 'FULL UP',
      'desc': 'Paket member standar',
      'color': const Color(0xFF7C3AED),
      'plans': [
        {'name': 'Trial Sehari',  'price': 'Rp 3.000',  'icon': Icons.access_time_rounded},
        {'name': 'Trial Sebulan', 'price': 'Rp 10.000', 'icon': Icons.calendar_month_rounded},
        {'name': 'Permanen',      'price': 'Rp 20.000', 'icon': Icons.all_inclusive_rounded},
      ],
    },
    'reseller': {
      'label': 'RESELLER',
      'desc': 'Bisa create akun Full Up',
      'color': const Color(0xFF22C55E),
      'plans': [
        {'name': 'Permanen', 'price': 'Rp 35.000', 'icon': Icons.all_inclusive_rounded},
      ],
    },
    'vip': {
      'label': 'VIP',
      'desc': 'Bisa create sampai Reseller',
      'color': const Color(0xFFE50914),
      'plans': [
        {'name': 'Permanen', 'price': 'Rp 45.000', 'icon': Icons.all_inclusive_rounded},
      ],
    },
    'owner': {
      'label': 'OWNER',
      'desc': 'Bisa create sampai VIP + Sender Global',
      'color': const Color(0xFFF59E0B),
      'plans': [
        {'name': 'Permanen', 'price': 'Rp 70.000', 'icon': Icons.all_inclusive_rounded},
      ],
    },
    'high_owner': {
      'label': 'HIGH OWNER',
      'desc': 'Bisa create sampai Owner',
      'color': const Color(0xFFFF6600),
      'plans': [
        {'name': 'Permanen', 'price': 'Rp 100.000', 'icon': Icons.all_inclusive_rounded},
      ],
    },
    'founder': {
      'label': 'FOUNDER',
      'desc': 'Bisa create sampai High Owner',
      'color': const Color(0xFFFF4500),
      'plans': [
        {'name': 'Permanen', 'price': 'Rp 150.000', 'icon': Icons.all_inclusive_rounded},
      ],
    },
  };

  @override
  Widget build(BuildContext context) {
    final pkg = _packages[_selectedRole]!;
    final plans = pkg['plans'] as List;
    final color = pkg['color'] as Color;

    return Container(
      height: MediaQuery.of(context).size.height * 0.85,
      decoration: const BoxDecoration(
        color: Color(0xFF0A0015),
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
        border: Border(top: BorderSide(color: Color(0xFF2D1B4E))),
      ),
      child: Column(
        children: [
          Container(
            margin: const EdgeInsets.only(top: 12),
            width: 40, height: 4,
            decoration: BoxDecoration(
              color: const Color(0xFF2D1B4E),
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 20, 20, 0),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: const Color(0xFF7C3AED).withOpacity(0.15),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: const Color(0xFF7C3AED).withOpacity(0.4)),
                  ),
                  child: const Icon(Icons.shopping_bag_rounded, color: Color(0xFF7C3AED), size: 22),
                ),
                const SizedBox(width: 14),
                const Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('BUY AKSES',
                      style: TextStyle(
                        color: Color(0xFFF3E8FF),
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        fontFamily: 'Orbitron',
                        letterSpacing: 1,
                      ),
                    ),
                    Text('Pilih paket yang sesuai',
                      style: TextStyle(color: Color(0xFFA78BFA), fontSize: 12),
                    ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          SizedBox(
            height: 40,
            child: ListView(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 16),
              children: _packages.entries.map((e) {
                final isSelected = _selectedRole == e.key;
                final c = e.value['color'] as Color;
                return GestureDetector(
                  onTap: () => setState(() {
                    _selectedRole = e.key;
                    _selectedPackage = 0;
                  }),
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 200),
                    margin: const EdgeInsets.only(right: 8),
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                    decoration: BoxDecoration(
                      color: isSelected ? c.withOpacity(0.2) : const Color(0xFF0A0015),
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(
                        color: isSelected ? c : const Color(0xFF2D1B4E),
                        width: isSelected ? 1.5 : 1,
                      ),
                    ),
                    child: Text(
                      e.value['label'] as String,
                      style: TextStyle(
                        color: isSelected ? c : const Color(0xFF6D28D9),
                        fontSize: 11,
                        fontWeight: FontWeight.bold,
                        fontFamily: 'Orbitron',
                      ),
                    ),
                  ),
                );
              }).toList(),
            ),
          ),
          const SizedBox(height: 16),
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Column(
                children: [
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [color.withOpacity(0.15), color.withOpacity(0.05)],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(color: color.withOpacity(0.3)),
                    ),
                    child: Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(10),
                          decoration: BoxDecoration(
                            color: color.withOpacity(0.2),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Icon(Icons.workspace_premium_rounded, color: color, size: 24),
                        ),
                        const SizedBox(width: 14),
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              pkg['label'] as String,
                              style: TextStyle(
                                color: color,
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                                fontFamily: 'Orbitron',
                              ),
                            ),
                            Text(
                              pkg['desc'] as String,
                              style: const TextStyle(color: Color(0xFFA78BFA), fontSize: 12),
                            ),
                          ],
                        ),
                        if (_selectedRole == 'full_up') ...[
                          const Spacer(),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                            decoration: BoxDecoration(
                              color: const Color(0xFFF59E0B).withOpacity(0.15),
                              borderRadius: BorderRadius.circular(8),
                              border: Border.all(color: const Color(0xFFF59E0B).withOpacity(0.4)),
                            ),
                            child: const Text('RECOMMENDED',
                              style: TextStyle(
                                color: Color(0xFFF59E0B),
                                fontSize: 9,
                                fontWeight: FontWeight.bold,
                                fontFamily: 'Orbitron',
                              ),
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                  const SizedBox(height: 14),
                  ...plans.asMap().entries.map((entry) {
                    final i = entry.key;
                    final plan = entry.value as Map;
                    final isSelected = _selectedPackage == i;
                    return GestureDetector(
                      onTap: () => setState(() => _selectedPackage = i),
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 200),
                        margin: const EdgeInsets.only(bottom: 10),
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: isSelected
                              ? color.withOpacity(0.1)
                              : const Color(0xFF0A0015),
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(
                            color: isSelected ? color : const Color(0xFF2D1B4E),
                            width: isSelected ? 1.5 : 1,
                          ),
                        ),
                        child: Row(
                          children: [
                            Container(
                              width: 28, height: 28,
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                color: isSelected
                                    ? color.withOpacity(0.2)
                                    : const Color(0xFF0A0015),
                                border: Border.all(
                                  color: isSelected ? color : const Color(0xFF2D1B4E),
                                  width: 2,
                                ),
                              ),
                              child: isSelected
                                  ? Icon(Icons.check_rounded, color: color, size: 16)
                                  : null,
                            ),
                            const SizedBox(width: 14),
                            Icon(plan['icon'] as IconData, color: isSelected ? color : const Color(0xFF6D28D9), size: 20),
                            const SizedBox(width: 10),
                            Text(
                              plan['name'] as String,
                              style: TextStyle(
                                color: isSelected ? const Color(0xFFF3E8FF) : const Color(0xFFA78BFA),
                                fontSize: 14,
                                fontWeight: FontWeight.w600,
                                fontFamily: 'Orbitron',
                              ),
                            ),
                            const Spacer(),
                            Text(
                              plan['price'] as String,
                              style: TextStyle(
                                color: isSelected ? color : const Color(0xFF6D28D9),
                                fontSize: 13,
                                fontWeight: FontWeight.bold,
                                fontFamily: 'Orbitron',
                              ),
                            ),
                          ],
                        ),
                      ),
                    );
                  }),
                  const SizedBox(height: 20),
                ],
              ),
            ),
          ),
          Padding(
            padding: EdgeInsets.fromLTRB(16, 0, 16, MediaQuery.of(context).padding.bottom + 16),
            child: GestureDetector(
              onTap: () {
                final plan = plans[_selectedPackage];
                final msg = 'Halo, saya mau beli akses ${pkg['label']} - ${plan['name']} (${plan['price']})';
                final url = 'https://t.me/wahyustory?text=${Uri.encodeComponent(msg)}';
                widget.onBuy(url);
              },
              child: Container(
                width: double.infinity,
                height: 56,
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [color, color.withOpacity(0.7)],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: [
                    BoxShadow(
                      color: color.withOpacity(0.4),
                      blurRadius: 14,
                      spreadRadius: 1,
                    ),
                  ],
                ),
                child: const Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.shopping_cart_checkout_rounded, color: Colors.white, size: 20),
                    SizedBox(width: 10),
                    Text(
                      'CONTACT & BUY AKSES',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 13,
                        fontWeight: FontWeight.bold,
                        fontFamily: 'Orbitron',
                        letterSpacing: 1,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}