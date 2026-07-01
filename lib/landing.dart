import 'dart:math' as math;
import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:video_player/video_player.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'login_page.dart';

// ─────────────────────────────────────────────
//  PALETTE
// ─────────────────────────────────────────────
const Color _lpBgPage     = Color(0xFF0b1120);
const Color _lpCardBg     = Color(0xFF111827);
const Color _lpBorderCol  = Color(0xFF1e2d45);
const Color _lpAccentBlue = Color(0xFF2563eb);
const Color _lpAccentCyan = Color(0xFF22d3ee);
const Color _lpTextPrimary = Colors.white;
const Color _lpTextSub    = Color(0xFF94a3b8);

class LandingPage extends StatefulWidget {
  const LandingPage({super.key});

  @override
  State<LandingPage> createState() => _LandingPageState();
}

class _LandingPageState extends State<LandingPage>
    with TickerProviderStateMixin {
  // ── FIX: Pake nullable biar aman ──
  VideoPlayerController? _videoController;
  late AnimationController _fadeCtrl;
  late AnimationController _hexCtrl;
  late AnimationController _shimCtrl;
  late Animation<double> _fadeAnim;
  late Animation<Offset> _slideAnim;
  late Animation<double> _hexAnim;
  late Animation<double> _shimAnim;

  bool _videoReady = false;
  bool _videoError = false;

  @override
  void initState() {
    super.initState();
    _initVideo();

    // ── Animation Controllers ──
    _fadeCtrl = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 900));
    _fadeAnim = CurvedAnimation(parent: _fadeCtrl, curve: Curves.easeOut);
    _slideAnim = Tween<Offset>(
            begin: const Offset(0, 0.12), end: Offset.zero)
        .animate(CurvedAnimation(
            parent: _fadeCtrl, curve: Curves.easeOutCubic));
    _fadeCtrl.forward();

    _hexCtrl = AnimationController(
        vsync: this, duration: const Duration(seconds: 4))
      ..repeat(reverse: true);
    _hexAnim = CurvedAnimation(parent: _hexCtrl, curve: Curves.easeInOut);

    _shimCtrl = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 1800))
      ..repeat();
    _shimAnim = Tween<double>(begin: -1.5, end: 1.5).animate(
        CurvedAnimation(parent: _shimCtrl, curve: Curves.easeInOut));
  }

  // ── FIX: Video init dengan error handling lebih baik ──
  Future<void> _initVideo() async {
    try {
      // Cek dulu apakah file ada
      final controller = VideoPlayerController.asset('assets/videos/landing.mp4');
      await controller.initialize();
      
      if (mounted) {
        setState(() {
          _videoController = controller;
          _videoReady = true;
        });
        controller
          ..setLooping(true)
          ..setVolume(0)
          ..play();
      }
    } catch (e) {
      // FIX: Log error biar tau masalahnya
      debugPrint('Video init error: $e');
      if (mounted) {
        setState(() {
          _videoError = true;
        });
      }
    }
  }

  // ── FIX: Handle URL dengan lebih aman ──
  Future<void> _openUrl(String url) async {
    try {
      final uri = Uri.parse(url);
      if (await canLaunchUrl(uri)) {
        await launchUrl(uri, mode: LaunchMode.externalApplication);
      } else {
        // FIX: Kasih tau user kalo URL gak bisa dibuka
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Tidak bisa membuka: $url'),
              backgroundColor: Colors.redAccent,
              duration: const Duration(seconds: 2),
            ),
          );
        }
      }
    } catch (e) {
      debugPrint('Open URL error: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Gagal membuka link'),
            backgroundColor: Colors.redAccent,
            duration: Duration(seconds: 2),
          ),
        );
      }
    }
  }

  // ── FIX: Dispose dengan aman ──
  @override
  void dispose() {
    _videoController?.dispose(); // FIX: Pake ? biar aman kalo null
    _fadeCtrl.dispose();
    _hexCtrl.dispose();
    _shimCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: const SystemUiOverlayStyle(
        statusBarColor: Colors.transparent,
        statusBarIconBrightness: Brightness.light,
      ),
      child: Scaffold(
        backgroundColor: _lpBgPage,
        body: Stack(children: [
          // ── Honeycomb background ───────────────
          Positioned.fill(
            child: AnimatedBuilder(
              animation: _hexAnim,
              builder: (_, __) => CustomPaint(
                painter: _HoneycombPainter(pulse: _hexAnim.value),
              ),
            ),
          ),

          // ── Content ───────────────────────────
          SafeArea(
            child: FadeTransition(
              opacity: _fadeAnim,
              child: SlideTransition(
                position: _slideAnim,
                child: SingleChildScrollView(
                  physics: const BouncingScrollPhysics(),
                  padding: const EdgeInsets.symmetric(
                      horizontal: 22, vertical: 20),
                  child: Column(children: [
                    _topBadge(),
                    const SizedBox(height: 24),
                    _videoBanner(),
                    const SizedBox(height: 28),
                    _infoCard(),
                    const SizedBox(height: 32),
                    _loginButton(),
                    const SizedBox(height: 14),
                    _telegramButton(),
                    const SizedBox(height: 30),
                  ]),
                ),
              ),
            ),
          ),
        ]),
      ),
    );
  }

  // ─────────────────────────────────────────────
  //  TOP BADGE - QUANTUM PROJECT
  // ─────────────────────────────────────────────
  Widget _topBadge() {
    return Row(mainAxisAlignment: MainAxisAlignment.center, children: [
      Container(
        padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 8),
        decoration: BoxDecoration(
          color: _lpCardBg,
          borderRadius: BorderRadius.circular(30),
          border: Border.all(color: _lpBorderCol),
          boxShadow: [
            BoxShadow(
              color: _lpAccentBlue.withOpacity(0.2),
              blurRadius: 16,
              spreadRadius: 1,
            ),
          ],
        ),
        child: Row(mainAxisSize: MainAxisSize.min, children: [
          _miniHex(),
          const SizedBox(width: 10),
          ShaderMask(
            shaderCallback: (r) => const LinearGradient(
              colors: [_lpAccentBlue, _lpAccentCyan],
            ).createShader(r),
            child: const Text(
              'CHAN XITER',
              style: TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.w900,
                fontSize: 15,
                letterSpacing: 2.5,
              ),
            ),
          ),
          const SizedBox(width: 10),
          _miniHex(),
        ]),
      ),
    ]);
  }

  Widget _miniHex() => CustomPaint(
        size: const Size(18, 18),
        painter: _SingleHexPainter(
          color: _lpAccentBlue.withOpacity(0.7),
          filled: false,
        ),
      );

  // ─────────────────────────────────────────────
  //  VIDEO BANNER - FIX: Pake null check
  // ─────────────────────────────────────────────
  Widget _videoBanner() {
    return Container(
      height: 210,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: _lpAccentBlue.withOpacity(0.3), width: 1.2),
        boxShadow: [
          BoxShadow(
            color: _lpAccentBlue.withOpacity(0.25),
            blurRadius: 24,
            spreadRadius: 1,
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(22),
        child: Stack(fit: StackFit.expand, children: [
          // FIX: Pake null check di sini
          if (_videoReady && _videoController != null && _videoController!.value.isInitialized)
            FittedBox(
              fit: BoxFit.cover,
              child: SizedBox(
                width: _videoController!.value.size.width,
                height: _videoController!.value.size.height,
                child: VideoPlayer(_videoController!),
              ),
            )
          else
            Container(
              color: _lpCardBg,
              child: Center(
                child: _videoError
                    ? Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          FaIcon(FontAwesomeIcons.film,
                              color: _lpTextSub, size: 40),
                          const SizedBox(height: 10),
                          const Text('Preview unavailable',
                              style: TextStyle(
                                  color: _lpTextSub, fontSize: 13)),
                        ],
                      )
                    : const CircularProgressIndicator(
                        color: _lpAccentCyan, strokeWidth: 2),
              ),
            ),

          // Gradient overlay
          Positioned.fill(
            child: DecoratedBox(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    Colors.transparent,
                    _lpBgPage.withOpacity(0.75),
                  ],
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                ),
              ),
            ),
          ),

          // Bottom label - QUANTUM APPS
          Positioned(
            bottom: 14,
            left: 16,
            child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  ShaderMask(
                    shaderCallback: (r) => const LinearGradient(
                      colors: [_lpAccentCyan, _lpAccentBlue],
                    ).createShader(r),
                    child: const Text(
                      'CHAN XITER',
                      style: TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.w900,
                        fontSize: 14,
                        letterSpacing: 1.5,
                      ),
                    ),
                  ),
                  const Text(
                    'GACOR · TERUPDATE · STABIL',
                    style: TextStyle(color: _lpTextSub, fontSize: 11),
                  ),
                ]),
          ),

          // Volume icon
          Positioned(
            bottom: 12,
            right: 12,
            child: Container(
              padding: const EdgeInsets.all(6),
              decoration: BoxDecoration(
                color: Colors.black.withOpacity(0.5),
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Icon(Icons.volume_off_rounded,
                  color: Colors.white54, size: 14),
            ),
          ),
        ]),
      ),
    );
  }

  // ─────────────────────────────────────────────
  //  INFO CARD - QUANTUM BUG MODULE
  // ─────────────────────────────────────────────
  Widget _infoCard() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: _lpCardBg,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: _lpBorderCol),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.4),
            blurRadius: 20,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Column(children: [
        // Hex grid deco row
        Row(mainAxisAlignment: MainAxisAlignment.center, children: [
          for (int i = 0; i < 5; i++) ...[
            AnimatedBuilder(
              animation: _hexAnim,
              builder: (_, __) {
                final delay = i / 5;
                final t     = ((_hexAnim.value + delay) % 1.0);
                final op    = 0.15 + t * 0.55;
                return CustomPaint(
                  size: const Size(28, 28),
                  painter: _SingleHexPainter(
                    color: i == 2
                        ? _lpAccentCyan.withOpacity(op)
                        : _lpAccentBlue.withOpacity(op * 0.7),
                    filled: i == 2,
                  ),
                );
              },
            ),
            if (i < 4) const SizedBox(width: 6),
          ],
        ]),
        const SizedBox(height: 20),

        // Title - QUANTUM BUG MODULE
        ShaderMask(
          shaderCallback: (r) => const LinearGradient(
            colors: [Color(0xFF60a5fa), _lpAccentBlue],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ).createShader(r),
          child: const Text(
            'CHAN XITER',
            style: TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.w900,
              fontSize: 26,
              letterSpacing: 2,
            ),
          ),
        ),
        const SizedBox(height: 8),

        // Divider line dengan hex ends
        Row(children: [
          const Expanded(
              child: Divider(color: Color(0xFF1e2d45), thickness: 1)),
          const SizedBox(width: 8),
          CustomPaint(
            size: const Size(10, 10),
            painter: _SingleHexPainter(
                color: _lpAccentBlue, filled: true),
          ),
          const SizedBox(width: 8),
          const Expanded(
              child: Divider(color: Color(0xFF1e2d45), thickness: 1)),
        ]),
        const SizedBox(height: 20),

        // Description box
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: _lpBgPage,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: _lpBorderCol),
          ),
          child: const Text(
            'Confirmation of the latest official CHAN XITER update. We, as representatives of the CHAN XITER team, would like to inform you that this is an app bug. So make sure that while using this application, don\'t use it for revenge. Use it for your own needs only.',
            textAlign: TextAlign.center,
            style: TextStyle(
              color: _lpTextSub,
              fontSize: 13,
              height: 1.65,
              letterSpacing: 0.2,
            ),
          ),
        ),
        const SizedBox(height: 16),

        // Footer badge
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
          decoration: BoxDecoration(
            color: _lpAccentBlue.withOpacity(0.08),
            borderRadius: BorderRadius.circular(30),
            border: Border.all(
                color: _lpAccentBlue.withOpacity(0.25), width: 1),
          ),
          child: const Text(
            '— CHAN XITER TEAM —',
            style: TextStyle(
              color: _lpTextSub,
              fontSize: 12,
              fontWeight: FontWeight.w600,
              letterSpacing: 2,
            ),
          ),
        ),
      ]),
    );
  }

  // ─────────────────────────────────────────────
  //  LOGIN BUTTON
  // ─────────────────────────────────────────────
  Widget _loginButton() {
    return AnimatedBuilder(
      animation: _shimAnim,
      builder: (_, child) {
        return Container(
          height: 60,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            boxShadow: [
              BoxShadow(
                color: _lpAccentBlue.withOpacity(0.45),
                blurRadius: 22,
                offset: const Offset(0, 6),
              ),
            ],
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(16),
            child: Stack(children: [
              // Base gradient
              Container(
                decoration: const BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      Color(0xFF1d4ed8),
                      Color(0xFF1e40af),
                      Color(0xFF1d4ed8),
                    ],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                ),
              ),

              // Honeycomb pattern overlay
              Positioned.fill(
                child: CustomPaint(
                  painter: _ButtonHexPainter(
                      opacity: 0.12),
                ),
              ),

              // Shimmer sweep
              Positioned.fill(
                child: Transform.translate(
                  offset: Offset(
                      _shimAnim.value *
                          MediaQuery.of(context).size.width,
                      0),
                  child: Container(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [
                          Colors.transparent,
                          Colors.white.withOpacity(0.12),
                          Colors.transparent,
                        ],
                        stops: const [0.3, 0.5, 0.7],
                      ),
                    ),
                  ),
                ),
              ),

              // Content
              child!,
            ]),
          ),
        );
      },
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(16),
          onTap: () => Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => const LoginPage()),
          ),
          child: SizedBox(
            width: double.infinity,
            height: 60,
            child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Container(
                    width: 36,
                    height: 36,
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.12),
                      shape: BoxShape.circle,
                      border: Border.all(
                          color: Colors.white.withOpacity(0.2),
                          width: 1),
                    ),
                    child: const Icon(Icons.rocket_launch_rounded,
                        color: Colors.white, size: 18),
                  ),
                  const SizedBox(width: 14),
                  Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: const [
                      Text(
                        'LOGIN TO CHAN XITER',
                        style: TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.w900,
                          fontSize: 15,
                          letterSpacing: 1.5,
                        ),
                      ),
                      Text(
                        'Access your account',
                        style: TextStyle(
                          color: Colors.white60,
                          fontSize: 11,
                          letterSpacing: 0.3,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(width: 14),
                  Container(
                    width: 30,
                    height: 30,
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.1),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(Icons.arrow_forward_rounded,
                        color: Colors.white, size: 15),
                  ),
                ]),
          ),
        ),
      ),
    );
  }

  // ─────────────────────────────────────────────
  //  CONTACT SUPPORT - HUBUNGI KAMI
  // ─────────────────────────────────────────────
  Widget _telegramButton() {
    return Column(
      children: [
        // Contact Support label
        const Text(
          'CONTACT SUPPORT',
          style: TextStyle(
            color: _lpTextSub,
            fontSize: 12,
            fontWeight: FontWeight.w600,
            letterSpacing: 2,
          ),
        ),
        const SizedBox(height: 10),
        const Text(
          'HUBUNGI KAMI',
          style: TextStyle(
            color: _lpTextPrimary,
            fontSize: 14,
            fontWeight: FontWeight.w700,
            letterSpacing: 1,
          ),
        ),
        const SizedBox(height: 12),
        // Social media buttons row
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            _socialButton(
              icon: FontAwesomeIcons.telegram,
              label: 'Telegram',
              url: 'https://t.me/vanesha31',
              color: _lpAccentBlue,
            ),
            const SizedBox(width: 16),
            _socialButton(
              icon: FontAwesomeIcons.tiktok,
              label: 'TikTok',
              // FIX: Pake URL yang valid
              url: 'https://www.tiktok.com/@CHAN XITER',
              color: _lpAccentCyan,
            ),
            const SizedBox(width: 16),
            _socialButton(
              icon: FontAwesomeIcons.instagram,
              label: 'Instagram',
              // FIX: Pake URL yang valid
              url: 'https://www.instagram.com/CHAN XITER',
              color: const Color(0xFFE4405F),
            ),
          ],
        ),
      ],
    );
  }

  Widget _socialButton({
    required IconData icon,
    required String label,
    required String url,
    required Color color,
  }) {
    return GestureDetector(
      onTap: () => _openUrl(url),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        decoration: BoxDecoration(
          color: _lpCardBg,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: _lpBorderCol),
        ),
        child: Row(
          children: [
            FaIcon(icon, color: color, size: 18),
            const SizedBox(width: 8),
            Text(
              label,
              style: const TextStyle(
                color: _lpTextPrimary,
                fontSize: 12,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ═════════════════════════════════════════════════
//  HONEYCOMB BACKGROUND PAINTER
// ═════════════════════════════════════════════════
class _HoneycombPainter extends CustomPainter {
  final double pulse;
  _HoneycombPainter({required this.pulse});

  @override
  void paint(Canvas canvas, Size size) {
    final hexR  = 28.0;
    final hexW  = hexR * math.sqrt(3);
    final hexH  = hexR * 2;
    final cols  = (size.width  / hexW).ceil() + 2;
    final rows  = (size.height / (hexH * 0.75)).ceil() + 2;

    for (int row = -1; row < rows; row++) {
      for (int col = -1; col < cols; col++) {
        final dx = col * hexW + (row.isOdd ? hexW / 2 : 0);
        final dy = row * hexH * 0.75;

        final cx   = size.width  / 2;
        final cy   = size.height / 2;
        final dist = math.sqrt(
            math.pow(dx - cx, 2) + math.pow(dy - cy, 2));
        final maxD = math.sqrt(
            math.pow(size.width, 2) + math.pow(size.height, 2)) / 2;
        final norm  = (dist / maxD).clamp(0.0, 1.0);

        final wave  = math.sin((norm * math.pi * 2) - (pulse * math.pi * 2));
        final alpha = (0.025 + wave * 0.018).clamp(0.008, 0.06);

        final paint = Paint()
          ..color = const Color(0xFF2563eb).withOpacity(alpha)
          ..style = PaintingStyle.stroke
          ..strokeWidth = 0.8;

        _drawHex(canvas, Offset(dx, dy), hexR, paint);

        if ((row + col) % 7 == 0) {
          final fillPaint = Paint()
            ..color = const Color(0xFF1e3a6e)
                .withOpacity((alpha * 0.4).clamp(0, 0.03))
            ..style = PaintingStyle.fill;
          _drawHex(canvas, Offset(dx, dy), hexR, fillPaint);
        }
      }
    }
  }

  void _drawHex(Canvas canvas, Offset center, double r, Paint paint) {
    final path = Path();
    for (int i = 0; i < 6; i++) {
      final angle = (math.pi / 180) * (60 * i - 30);
      final x     = center.dx + r * math.cos(angle);
      final y     = center.dy + r * math.sin(angle);
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
  bool shouldRepaint(_HoneycombPainter old) => old.pulse != pulse;
}

// ═════════════════════════════════════════════════
//  SINGLE HEXAGON PAINTER
// ═════════════════════════════════════════════════
class _SingleHexPainter extends CustomPainter {
  final Color color;
  final bool  filled;
  _SingleHexPainter({required this.color, required this.filled});

  @override
  void paint(Canvas canvas, Size size) {
    final r     = size.width / 2;
    final paint = Paint()
      ..color     = color
      ..style     = filled ? PaintingStyle.fill : PaintingStyle.stroke
      ..strokeWidth = 1.2;
    final path = Path();
    for (int i = 0; i < 6; i++) {
      final angle = (math.pi / 180) * (60 * i - 30);
      final x     = size.width  / 2 + r * math.cos(angle);
      final y     = size.height / 2 + r * math.sin(angle);
      if (i == 0) path.moveTo(x, y);
      else         path.lineTo(x, y);
    }
    path.close();
    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(_SingleHexPainter old) =>
      old.color != color || old.filled != filled;
}

// ═════════════════════════════════════════════════
//  BUTTON HEX PATTERN PAINTER
// ═════════════════════════════════════════════════
class _ButtonHexPainter extends CustomPainter {
  final double opacity;
  _ButtonHexPainter({required this.opacity});

  @override
  void paint(Canvas canvas, Size size) {
    final r     = 14.0;
    final hexW  = r * math.sqrt(3);
    final hexH  = r * 2;
    final cols  = (size.width  / hexW).ceil() + 2;
    final rows  = (size.height / (hexH * 0.75)).ceil() + 2;

    final paint = Paint()
      ..color       = Colors.white.withOpacity(opacity)
      ..style       = PaintingStyle.stroke
      ..strokeWidth = 0.6;

    for (int row = -1; row < rows; row++) {
      for (int col = -1; col < cols; col++) {
        final dx = col * hexW + (row.isOdd ? hexW / 2 : 0);
        final dy = row * hexH * 0.75;
        final path = Path();
        for (int i = 0; i < 6; i++) {
          final angle = (math.pi / 180) * (60 * i - 30);
          final x     = dx + r * math.cos(angle);
          final y     = dy + r * math.sin(angle);
          if (i == 0) path.moveTo(x, y);
          else         path.lineTo(x, y);
        }
        path.close();
        canvas.drawPath(path, paint);
      }
    }
  }

  @override
  bool shouldRepaint(_ButtonHexPainter old) => old.opacity != opacity;
}