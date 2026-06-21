import 'dart:math' as dart_math;
import 'dart:ui';
import 'package:flutter/material.dart';

// ─── COLORS (sama seperti dashboard) ────────────────────────────────────────
class _C {
  static const bg           = Color(0xFF0A0A0F);
  static const surface      = Color(0xFF14141F);
  static const surface2     = Color(0xFF242433);
  static const accent1      = Color(0xFF00E5FF); // Cyan
  static const accent2      = Color(0xFF7C4DFF); // Purple
  static const accent3      = Color(0xFFFF4081); // Pink
  static const textPrimary  = Color(0xFFF5F8FF);
  static const textSec      = Color(0xFF9E9EB8);
  static const shadow       = Color(0x40000000);
  static const shadowHeavy  = Color(0x80000000);
}

// ─── HEX BACKGROUND PAINTER ─────────────────────────────────────────────────
class _HexPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    // Top-left cyan glow
    final g1 = Paint()
      ..shader = RadialGradient(
        colors: [_C.accent1.withOpacity(0.18), _C.accent2.withOpacity(0.06), Colors.transparent],
      ).createShader(Rect.fromCircle(center: Offset.zero, radius: size.width * 0.65));
    canvas.drawCircle(Offset.zero, size.width * 0.65, g1);

    // Bottom-right pink glow
    final g2 = Paint()
      ..shader = RadialGradient(
        colors: [_C.accent3.withOpacity(0.12), Colors.transparent],
      ).createShader(Rect.fromCircle(
          center: Offset(size.width, size.height), radius: size.width * 0.55));
    canvas.drawCircle(Offset(size.width, size.height), size.width * 0.55, g2);

    // Hex grid
    const hexW = 60.0;
    final hexH = hexW * dart_math.sqrt(3) / 2;
    final cols = (size.width / hexW).ceil() + 2;
    final rows = (size.height / hexH).ceil() + 2;
    final paint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 0.5
      ..color = Colors.white.withOpacity(0.03);

    for (int row = -1; row < rows; row++) {
      for (int col = -1; col < cols; col++) {
        final x = col * hexW + (row % 2) * hexW / 2;
        final y = row * hexH * 0.75;
        final path = Path();
        for (int i = 0; i < 6; i++) {
          final angle = i * dart_math.pi * 2 / 6;
          final px = x + hexW / 2 + dart_math.cos(angle) * hexW / 2;
          final py = y + hexH / 2 + dart_math.sin(angle) * hexH / 2;
          if (i == 0) path.moveTo(px, py); else path.lineTo(px, py);
        }
        path.close();
        canvas.drawPath(path, paint);
      }
    }
  }

  @override bool shouldRepaint(covariant CustomPainter _) => false;
}

// ─── LANDING PAGE ────────────────────────────────────────────────────────────
class LandingPage extends StatelessWidget {
  const LandingPage({super.key});

  // Animasi fade in untuk seluruh halaman
  Widget _buildFadeInWidget(Widget child) {
    return TweenAnimationBuilder(
      duration: const Duration(milliseconds: 800),
      tween: Tween<double>(begin: 0.0, end: 1.0),
      curve: Curves.easeOutCubic,
      builder: (context, value, child) => Opacity(opacity: value, child: child),
      child: child,
    );
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;

    return Scaffold(
      backgroundColor: _C.bg,
      body: _buildFadeInWidget(
        Stack(
          children: [
            // 1. Hex background
            CustomPaint(
              size: Size.infinite,
              painter: _HexPainter(),
              child: const SizedBox.expand(),
            ),

            // 2. Foto karakter c.png memenuhi layar (bottom-anchored)
            Positioned.fill(
              child: Align(
                alignment: Alignment.bottomCenter,
                child: Image.asset(
                  'assets/images/c.png',
                  width: size.width,
                  height: size.height * 0.85,
                  fit: BoxFit.cover,
                  alignment: Alignment.bottomCenter,
                ),
              ),
            ),

            // 3. Gradient fade bawah supaya tombol terbaca
            Positioned(
              left: 0, right: 0, bottom: 0,
              height: size.height * 0.35,
              child: Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [
                      Colors.transparent,
                      _C.bg.withOpacity(0.80),
                      _C.bg,
                    ],
                  ),
                ),
              ),
            ),

            // 4. Gradient fade atas (subtle)
            Positioned(
              left: 0, right: 0, top: 0,
              height: size.height * 0.20,
              child: Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [_C.bg.withOpacity(0.6), Colors.transparent],
                  ),
                ),
              ),
            ),

            // 5. Konten: judul di atas + Sign In di bawah
            SafeArea(
              child: Column(
                children: [
                  // ── Header dengan animasi slide down ──
                  TweenAnimationBuilder(
                    duration: const Duration(milliseconds: 600),
                    tween: Tween<double>(begin: -30, end: 0),
                    curve: Curves.easeOutCubic,
                    builder: (context, value, child) => Transform.translate(
                      offset: Offset(0, value),
                      child: child,
                    ),
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 20),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // Chip "WELCOME"
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
                            decoration: BoxDecoration(
                              border: Border.all(color: _C.accent1.withOpacity(0.5), width: 1),
                              borderRadius: BorderRadius.circular(20),
                              color: _C.accent1.withOpacity(0.08),
                            ),
                            child: const Text(
                              "WELCOME",
                              style: TextStyle(
                                fontFamily: 'Orbitron',
                                fontSize: 10,
                                color: _C.accent1,
                                letterSpacing: 3,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                          const SizedBox(height: 10),
                          // Judul
                          ShaderMask(
                            shaderCallback: (bounds) => const LinearGradient(
                              colors: [_C.accent1, _C.accent2],
                            ).createShader(bounds),
                            child: const Text(
                              "Genius",
                              style: TextStyle(
                                fontFamily: 'Orbitron',
                                fontSize: 38,
                                fontWeight: FontWeight.w900,
                                color: Colors.white,
                                letterSpacing: 4,
                              ),
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            "The Ultimate Digital Tools & Security",
                            style: TextStyle(
                              fontFamily: 'Orbitron',
                              fontSize: 10,
                              color: _C.textSec,
                              letterSpacing: 1.2,
                              fontWeight: FontWeight.w400,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),

                  const Spacer(),

                  // ── Sign In Button dengan animasi scale ──
                  TweenAnimationBuilder(
                    duration: const Duration(milliseconds: 700),
                    tween: Tween<double>(begin: 0.8, end: 1.0),
                    curve: Curves.easeOutBack,
                    builder: (context, value, child) => Transform.scale(
                      scale: value,
                      child: child,
                    ),
                    child: Padding(
                      padding: const EdgeInsets.fromLTRB(28, 0, 28, 36),
                      child: _SignInButton(
                        onTap: () {
                          Navigator.pushNamed(context, "/login");
                        },
                      ),
                    ),
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

// ─── SIGN IN BUTTON (Enhanced dengan animasi tap) ──────────────────────────────────────────────────────────
class _SignInButton extends StatefulWidget {
  final VoidCallback onTap;
  const _SignInButton({required this.onTap});
  @override State<_SignInButton> createState() => _SignInButtonState();
}

class _SignInButtonState extends State<_SignInButton> with SingleTickerProviderStateMixin {
  late AnimationController _c;
  late Animation<double> _glow;
  bool _isPressed = false;

  @override void initState() {
    super.initState();
    _c = AnimationController(vsync: this, duration: const Duration(milliseconds: 1400))
      ..repeat(reverse: true);
    _glow = Tween<double>(begin: 0.5, end: 1.0).animate(
      CurvedAnimation(parent: _c, curve: Curves.easeInOut));
  }

  @override void dispose() { _c.dispose(); super.dispose(); }

  void _handleTap() {
    setState(() => _isPressed = true);
    Future.delayed(const Duration(milliseconds: 150), () {
      if (mounted) setState(() => _isPressed = false);
      widget.onTap();
    });
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _glow,
      builder: (_, __) => GestureDetector(
        onTap: _handleTap,
        child: AnimatedScale(
          duration: const Duration(milliseconds: 150),
          scale: _isPressed ? 0.97 : 1.0,
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            width: double.infinity,
            height: 58,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(18),
              gradient: const LinearGradient(
                colors: [_C.accent1, _C.accent2],
                begin: Alignment.centerLeft,
                end: Alignment.centerRight,
              ),
              boxShadow: [
                BoxShadow(
                  color: _C.accent1.withOpacity(0.35 * _glow.value),
                  blurRadius: 24,
                  offset: const Offset(0, 6),
                ),
                BoxShadow(
                  color: _C.accent2.withOpacity(0.25 * _glow.value),
                  blurRadius: 16,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                AnimatedSwitcher(
                  duration: const Duration(milliseconds: 200),
                  child: _isPressed
                      ? const SizedBox(
                          key: ValueKey('loading'),
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: Colors.white,
                          ),
                        )
                      : const Icon(
                          Icons.login_rounded,
                          key: ValueKey('icon'),
                          color: Colors.white,
                          size: 20,
                        ),
                ),
                const SizedBox(width: 10),
                const Text(
                  "SIGN IN",
                  style: TextStyle(
                    fontFamily: 'Orbitron',
                    fontSize: 15,
                    fontWeight: FontWeight.w800,
                    color: Colors.white,
                    letterSpacing: 2.5,
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