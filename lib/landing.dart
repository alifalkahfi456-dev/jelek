import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:url_launcher/url_launcher.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:device_info_plus/device_info_plus.dart';
import 'api_config.dart';
import 'login_page.dart';

// ─── Palette: Dark Cyan/Teal ────────────────────────────────
class _C {
  // Background tones - dark navy/slate
  static const bg         = Color(0xFF0E1117);
  static const surface    = Color(0xFF161B22);
  static const card       = Color(0xFF1A1F2B);
  static const logoBg     = Color(0xFF1C2130);
  static const border     = Color(0xFF2A3040);
  
  static const cyan       = Color(0xFF1DE9B6);
  static const cyanDark   = Color(0xFF00C9A0);
  static const cyanDim    = Color(0xFF0D8A72);
  static const cyanBorder = Color(0xFF1DE9B6);
  
  static const text       = Color(0xFFECEFF4);
  static const textSub    = Color(0xFFADB5BD);
  static const textDim    = Color(0xFF6B7280);

  static const socialCyan = Color(0xFF1DE9B6);
  static const socialGrey = Color(0xFF2A3040);
  static const socialPurple = Color(0xFF7C3AED);
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
    
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _fadeCtrl.forward();
    });
  }

  @override
  void dispose() {
    _fadeCtrl.dispose();
    _floatCtrl.dispose();
    super.dispose();
  }

  Future<void> _openUrl(String url) async {
    final uri = Uri.parse(url);
    if (!await launchUrl(uri, mode: LaunchMode.externalApplication)) {
      throw Exception('Could not launch $uri');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _C.bg,
      body: Container(
        decoration: BoxDecoration(
          gradient: RadialGradient(
            center: Alignment.topCenter,
            radius: 1.2,
            colors: [
              _C.surface,
              _C.bg,
              Color(0xFF0A0C10),
            ],
            stops: [0, 0.5, 1],
          ),
        ),
        child: SafeArea(
          child: FadeTransition(
            opacity: _fadeAnim,
            child: SingleChildScrollView(
              physics: const BouncingScrollPhysics(),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  const SizedBox(height: 24),
                  _buildLogoBox(),
                  const SizedBox(height: 32),
                  _buildBigTitle(),
                  const SizedBox(height: 28),
                  _buildDescCard(),
                  const SizedBox(height: 20),
                  _buildLoginButton(),
                  const SizedBox(height: 14),
                  _buildContactSupportButton(),
                  const SizedBox(height: 28),
                  _buildSocialSection(),
                  const SizedBox(height: 30),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildLogoBox() {
  return Padding(
    padding: const EdgeInsets.symmetric(horizontal: 24),
    child: AnimatedBuilder(
      animation: _floatCtrl,
      builder: (context, child) {
        return Transform.translate(
          offset: Offset(0, 5 * _floatCtrl.value),
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
                color: _C.cyan.withOpacity(0.2),
                width: 1,
              ),
              boxShadow: [
                BoxShadow(
                  color: _C.cyan.withOpacity(0.1),
                  blurRadius: 20,
                  spreadRadius: 2,
                  offset: const Offset(0, 10),
                ),
              ],
            ),
            child: Stack(
              fit: StackFit.expand,
              children: [
                // Gambar full bingkai
                ClipRRect(
                  borderRadius: BorderRadius.circular(28),
                  child: Image.asset(
                    'assets/images/login.png',
                    width: double.infinity,
                    height: double.infinity,
                    fit: BoxFit.cover,
                  ),
                ),
                // Overlay gelap agar teks lebih terbaca
                Container(
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(28),
                    gradient: LinearGradient(
                      begin: Alignment.bottomCenter,
                      end: Alignment.topCenter,
                      colors: [
                        Colors.black.withOpacity(0.7),
                        Colors.transparent,
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
  );
}

  Widget _buildBigTitle() {
    return Column(
      children: [
        ShaderMask(
          shaderCallback: (bounds) => const LinearGradient(
            colors: [
              Color(0xFFFFFFFF), // putih di kiri
              Color(0xFF1DE9B6), // cyan di tengah-kanan
              Color(0xFFFFFFFF), // putih hint di ujung
            ],
            stops: [0.0, 0.6, 1.0],
            begin: Alignment.centerLeft,
            end: Alignment.centerRight,
          ).createShader(bounds),
          child: const Text(
            'THE-END X-ONE',
            textAlign: TextAlign.center,
            style: TextStyle(
              color: Colors.white,
              fontSize: 44,
              fontWeight: FontWeight.w900,
              fontFamily: 'Orbitron',
              letterSpacing: 4,
              height: 1.0,
            ),
          ),
        ),
        const SizedBox(height: 12),
        Container(
          width: 140,
          height: 2,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(10),
            gradient: const LinearGradient(
              colors: [Colors.transparent, _C.cyan, _C.cyanDark, Colors.transparent],
            ),
          ),
        ),
        const SizedBox(height: 14),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [_C.cyan.withOpacity(0.1), _C.cyanDark.withOpacity(0.05)],
            ),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: _C.cyan.withOpacity(0.2)),
          ),
          child: const Text(
            'G A C O R   •   T E R U P D A T E   •   S T A B I L',
            textAlign: TextAlign.center,
            style: TextStyle(
              color: _C.cyan,
              fontSize: 11,
              letterSpacing: 2,
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
            color: _C.cyan.withOpacity(0.2),
            width: 1.5,
          ),
          boxShadow: [
            BoxShadow(
              color: _C.cyan.withOpacity(0.08),
              blurRadius: 15,
              spreadRadius: 1,
              offset: const Offset(0, 8),
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
                  colors: [_C.cyanDim.withOpacity(0.6), _C.cyan.withOpacity(0.3)],
                ),
                borderRadius: BorderRadius.circular(18),
                border: Border.all(color: _C.cyan.withOpacity(0.5), width: 1.5),
                boxShadow: [
                  BoxShadow(
                    color: _C.cyan.withOpacity(0.3),
                    blurRadius: 10,
                    spreadRadius: 1,
                  ),
                ],
              ),
              child: const Center(
                child: Icon(
                  Icons.shield_outlined,
                  color: _C.cyan,
                  size: 30,
                ),
              ),
            ),
            const SizedBox(height: 20),
            ShaderMask(
              shaderCallback: (bounds) => const LinearGradient(
                colors: [Color(0xFF1DE9B6), Color(0xFF00C9A0)],
              ).createShader(bounds),
              child: const Text(
                'THE-END BUG',
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
            Text(
              'Aplikasi dengan design elegant dan fitur terbaru.\nPengembangan langsung oleh TEAM THE-END.',
              textAlign: TextAlign.center,
              style: TextStyle(
                color: _C.textSub,
                fontSize: 13,
                height: 1.6,
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
              _C.cyan.withOpacity(0.15),
              _C.cyanDark.withOpacity(0.1),
            ],
          ),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: _C.cyan, width: 1.5),
          boxShadow: [
            BoxShadow(
              color: _C.cyan.withOpacity(0.2),
              blurRadius: 10,
              spreadRadius: 1,
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
                  Icon(Icons.rocket_launch_rounded, color: _C.cyan, size: 20),
                  SizedBox(width: 12),
                  Text(
                    'LOGIN TO THE-END',
                    style: TextStyle(
                      color: _C.cyan,
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
            onTap: () => _openUrl('https://t.me/yanxz_emptiness'),
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
              blurRadius: 12,
              spreadRadius: 2,
              offset: const Offset(0, 5),
            ),
          ],
        ),
        child: Column(
          children: [
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
              decoration: BoxDecoration(
                color: _C.cyan.withOpacity(0.1),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: _C.cyan.withOpacity(0.2)),
              ),
              child: Text(
                'HUBUNGI KAMI',
                style: TextStyle(
                  color: _C.cyan,
                  fontSize: 11,
                  letterSpacing: 2,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
            const SizedBox(height: 24),
            Row(
  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
  children: [
    _buildSocialItem(
      icon: FontAwesomeIcons.telegram,
      bgColor: Color(0xFF29B6F6),
      label: 'Telegram',
      onTap: () => _openUrl('https://t.me/yanxz_emptiness'),
    ),
    _buildSocialItem(
      icon: FontAwesomeIcons.tiktok,
      bgColor: Color(0xFF6B7280),
      label: 'TikTok',
      onTap: () => _openUrl('https://tiktok.com/@yanxz_emptiness'),
    ),
    _buildSocialItem(
      icon: FontAwesomeIcons.instagram,
      bgColor: Color(0xFFE1306C),
      label: 'Instagram',
      onTap: () => _openUrl('https://instagram.com/'),
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
                blurRadius: 14,
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
          ),
        ),
      ],
    ),
  );
 }
}