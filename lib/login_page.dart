import 'dart:math' as dart_math;
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:url_launcher/url_launcher.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'splash.dart';
import 'package:device_info_plus/device_info_plus.dart';
import 'dashboard_page.dart';

const String baseUrl = "http://panel.lynzzofficial.com:2031";

// ─── COLORS (same as dashboard) ─────────────────────────────────────────────
class _C {
  static const bg          = Color(0xFF0A0A0F);
  static const surface     = Color(0xFF14141F);
  static const surface2    = Color(0xFF1C1C2A);
  static const accent1     = Color(0xFF00E5FF); // Cyan
  static const accent2     = Color(0xFF7C4DFF); // Purple
  static const accent3     = Color(0xFFFF4081); // Pink
  static const error       = Color(0xFFFF5252);
  static const warning     = Color(0xFFFFAB40);
  static const textPrimary = Color(0xFFF5F8FF);
  static const textSec     = Color(0xFF9E9EB8);
  static const textMuted   = Color(0xFF6B6B8A);
  static const shadow      = Color(0x40000000);
  static const shadowHeavy = Color(0x80000000);
}

// ─── HEX BACKGROUND PAINTER ─────────────────────────────────────────────────
class _HexPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final g1 = Paint()
      ..shader = RadialGradient(
        colors: [_C.accent1.withOpacity(0.15), _C.accent2.withOpacity(0.06), Colors.transparent],
      ).createShader(Rect.fromCircle(center: Offset.zero, radius: size.width * 0.65));
    canvas.drawCircle(Offset.zero, size.width * 0.65, g1);

    final g2 = Paint()
      ..shader = RadialGradient(
        colors: [_C.accent3.withOpacity(0.10), Colors.transparent],
      ).createShader(Rect.fromCircle(center: Offset(size.width, size.height), radius: size.width * 0.55));
    canvas.drawCircle(Offset(size.width, size.height), size.width * 0.55, g2);

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

// ─── LOGIN PAGE ──────────────────────────────────────────────────────────────
class LoginPage extends StatefulWidget {
  const LoginPage({super.key});
  @override State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> with SingleTickerProviderStateMixin {
  final userController = TextEditingController();
  final passController = TextEditingController();
  final _formKey = GlobalKey<FormState>();

  bool isLoading = false;
  bool _obscurePassword = true;
  String? androidId;

  late AnimationController _controller;
  late Animation<double> _fadeAnim;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(vsync: this, duration: const Duration(milliseconds: 800))..forward();
    _fadeAnim = CurvedAnimation(parent: _controller, curve: Curves.easeOutCubic);
    initLogin();
  }

  @override
  void dispose() {
    _controller.dispose();
    userController.dispose();
    passController.dispose();
    super.dispose();
  }

  Future<void> initLogin() async {
    androidId = await _getAndroidId();
    final prefs = await SharedPreferences.getInstance();
    final savedUser = prefs.getString("username");
    final savedPass = prefs.getString("password");
    final savedKey  = prefs.getString("key");

    if (savedUser != null && savedPass != null && savedKey != null) {
      final uri = Uri.parse("$baseUrl/myInfo?username=$savedUser&password=$savedPass&androidId=$androidId&key=$savedKey");
      try {
        final res  = await http.get(uri);
        final data = jsonDecode(res.body);
        if (data['valid'] == true) {
          Navigator.pushReplacement(context, _fadeRoute(SplashScreen(
            username: savedUser, password: savedPass,
            role: (data['role'] ?? '').toString(),
            sessionKey: data['key'], expiredDate: data['expiredDate'],
            listBug:  (data['listBug']   as List? ?? []).map((e) => Map<String, dynamic>.from(e as Map)).toList(),
            listDoos: (data['listDDoS']  as List? ?? []).map((e) => Map<String, dynamic>.from(e as Map)).toList(),
            news:     (data['news']      as List? ?? []).map((e) => Map<String, dynamic>.from(e as Map)).toList(),
          )));
        }
      } catch (_) {}
    }
  }

  Future<String> _getAndroidId() async {
    final deviceInfo = DeviceInfoPlugin();
    final android = await deviceInfo.androidInfo;
    return android.id ?? "unknown_device";
  }

  PageRouteBuilder _fadeRoute(Widget page) => PageRouteBuilder(
    transitionDuration: const Duration(milliseconds: 500),
    pageBuilder: (_, __, ___) => page,
    transitionsBuilder: (_, anim, __, child) =>
        FadeTransition(opacity: anim.drive(Tween(begin: 0.0, end: 1.0).chain(CurveTween(curve: Curves.easeOutCubic))), child: child),
  );

  Future<void> login() async {
    if (!_formKey.currentState!.validate()) return;
    final username = userController.text.trim();
    final password = passController.text.trim();
    setState(() => isLoading = true);

    try {
      final validate = await http.post(
        Uri.parse("$baseUrl/validate"),
        body: {"username": username, "password": password, "androidId": androidId ?? "unknown_device"},
      );
      final validData = jsonDecode(validate.body);

      if (validData['expired'] == true) {
        _showPopup(title: "⏳ Access Expired", message: "Your access has expired.\nPlease renew it.", color: _C.warning, showContact: true);
      } else if (validData['valid'] != true) {
        _showPopup(title: "Login Failed", message: "Invalid username or password.", color: _C.accent3);
      } else {
        final prefs = await SharedPreferences.getInstance();
        prefs.setString("username", username);
        prefs.setString("password", password);
        prefs.setString("key", validData['key']);
        Navigator.pushReplacement(context, _fadeRoute(SplashScreen(
          username: username, password: password,
          role: (validData['role'] ?? '').toString(),
          sessionKey: validData['key'], expiredDate: validData['expiredDate'],
          listBug:  (validData['listBug']   as List? ?? []).map((e) => Map<String, dynamic>.from(e as Map)).toList(),
          listDoos: (validData['listDDoS']  as List? ?? []).map((e) => Map<String, dynamic>.from(e as Map)).toList(),
          news:     (validData['news']      as List? ?? []).map((e) => Map<String, dynamic>.from(e as Map)).toList(),
        )));
      }
    } catch (_) {
      _showPopup(title: "Connection Error", message: "Failed to connect to the server.\nPlease check your internet connection.", color: _C.error);
    }

    setState(() => isLoading = false);
  }

  void _showPopup({required String title, required String message, Color color = _C.accent3, bool showContact = false}) {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        backgroundColor: _C.surface,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
          side: BorderSide(color: color.withOpacity(0.4), width: 1),
        ),
        title: Text(title, style: TextStyle(color: color, fontWeight: FontWeight.bold, fontSize: 18, fontFamily: 'Orbitron')),
        content: Text(message, style: const TextStyle(color: _C.textSec, fontSize: 14)),
        actions: [
          if (showContact)
            TextButton(
              onPressed: () async => await launchUrl(Uri.parse("https://t.me/pemxx08"), mode: LaunchMode.externalApplication),
              child: Text("Contact Admin", style: TextStyle(color: _C.accent1)),
            ),
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text("Close", style: TextStyle(color: _C.textMuted)),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _C.bg,
      body: Stack(
        children: [
          // Hex background
          CustomPaint(
            size: Size.infinite,
            painter: _HexPainter(),
            child: const SizedBox.expand(),
          ),

          // Konten utama
          SafeArea(
            child: FadeTransition(
              opacity: _fadeAnim,
              child: Center(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 24),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      // ── Logo ──
                      TweenAnimationBuilder<double>(
                        duration: const Duration(milliseconds: 600),
                        tween: Tween(begin: 0.5, end: 1.0),
                        curve: Curves.easeOutBack,
                        builder: (_, v, child) => Transform.scale(scale: v, child: child),
                        child: Container(
                          width: 100, height: 100,
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(28),
                            gradient: const LinearGradient(
                              colors: [_C.accent1, _C.accent2],
                              begin: Alignment.topLeft,
                              end: Alignment.bottomRight,
                            ),
                            boxShadow: [
                              BoxShadow(color: _C.accent1.withOpacity(0.3), blurRadius: 24, spreadRadius: 2),
                              BoxShadow(color: _C.accent2.withOpacity(0.2), blurRadius: 12),
                            ],
                          ),
                          child: ClipRRect(
                            borderRadius: BorderRadius.circular(28),
                            child: Image.asset('assets/images/logo.jpg', fit: BoxFit.cover),
                          ),
                        ),
                      ),

                      const SizedBox(height: 28),

                      // ── Title ──
                      TweenAnimationBuilder<double>(
                        duration: const Duration(milliseconds: 600),
                        tween: Tween(begin: 0.0, end: 1.0),
                        curve: Curves.easeOutCubic,
                        builder: (_, v, child) => Opacity(
                          opacity: v,
                          child: Transform.translate(offset: Offset(0, 20 * (1 - v)), child: child),
                        ),
                        child: Column(
                          children: [
                            ShaderMask(
                              shaderCallback: (bounds) => const LinearGradient(
                                colors: [_C.accent1, _C.accent2],
                              ).createShader(bounds),
                              child: const Text(
                                "WELCOME BACK",
                                style: TextStyle(
                                  fontSize: 24, fontWeight: FontWeight.w800,
                                  color: Colors.white, fontFamily: 'Orbitron', letterSpacing: 2,
                                ),
                              ),
                            ),
                            const SizedBox(height: 6),
                            const Text(
                              "Sign in to continue",
                              style: TextStyle(color: _C.textSec, fontSize: 13, letterSpacing: 0.5),
                            ),
                          ],
                        ),
                      ),

                      const SizedBox(height: 36),

                      // ── Form card ──
                      TweenAnimationBuilder<double>(
                        duration: const Duration(milliseconds: 700),
                        tween: Tween(begin: 0.9, end: 1.0),
                        curve: Curves.easeOutCubic,
                        builder: (_, v, child) => Transform.scale(scale: v, child: child),
                        child: Container(
                          padding: const EdgeInsets.all(20),
                          decoration: BoxDecoration(
                            color: _C.surface,
                            borderRadius: BorderRadius.circular(24),
                            border: Border.all(color: Colors.white.withOpacity(0.08), width: 0.5),
                            boxShadow: [
                              BoxShadow(color: _C.accent2.withOpacity(0.12), blurRadius: 20, offset: const Offset(0, 8)),
                              const BoxShadow(color: _C.shadowHeavy, blurRadius: 10, offset: Offset(0, 4)),
                            ],
                          ),
                          child: Form(
                            key: _formKey,
                            child: Column(
                              children: [
                                _buildTextField(
                                  controller: userController,
                                  label: "Username",
                                  icon: Icons.person_outline_rounded,
                                ),
                                const SizedBox(height: 16),
                                _buildTextField(
                                  controller: passController,
                                  label: "Password",
                                  icon: Icons.lock_outline_rounded,
                                  obscureText: _obscurePassword,
                                  isPassword: true,
                                ),
                                const SizedBox(height: 24),

                                // ── Login Button ──
                                SizedBox(
                                  width: double.infinity,
                                  height: 52,
                                  child: _AnimatedLoginButton(
                                    isLoading: isLoading,
                                    onPressed: login,
                                    gradient: const LinearGradient(
                                      colors: [_C.accent1, _C.accent2],
                                      begin: Alignment.centerLeft,
                                      end: Alignment.centerRight,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),

                      const SizedBox(height: 28),

                      // ── Footer label ──
                      const Text(
                        "CATACLYSM",
                        style: TextStyle(
                          color: _C.textMuted, fontSize: 9,
                          letterSpacing: 3, fontFamily: 'Orbitron',
                        ),
                      ),
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

  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    required IconData icon,
    bool obscureText = false,
    bool isPassword = false,
  }) {
    return TweenAnimationBuilder<double>(
      duration: const Duration(milliseconds: 400),
      tween: Tween(begin: 0.85, end: 1.0),
      curve: Curves.easeOutCubic,
      builder: (_, v, child) => Transform.scale(scale: v, child: child),
      child: TextFormField(
        controller: controller,
        obscureText: obscureText,
        style: const TextStyle(color: _C.textPrimary, fontFamily: 'Orbitron', fontSize: 13),
        decoration: InputDecoration(
          labelText: label,
          labelStyle: const TextStyle(color: _C.textSec, fontFamily: 'Orbitron', fontSize: 12),
          prefixIcon: Icon(icon, color: _C.accent1, size: 20),
          suffixIcon: isPassword
              ? IconButton(
                  icon: AnimatedSwitcher(
                    duration: const Duration(milliseconds: 200),
                    child: Icon(
                      _obscurePassword ? Icons.visibility_outlined : Icons.visibility_off_outlined,
                      key: ValueKey(_obscurePassword),
                      color: _C.textMuted,
                      size: 20,
                    ),
                  ),
                  onPressed: () {
                    HapticFeedback.lightImpact();
                    setState(() => _obscurePassword = !_obscurePassword);
                  },
                )
              : null,
          filled: true,
          fillColor: _C.surface2.withOpacity(0.8),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(14),
            borderSide: BorderSide(color: Colors.white.withOpacity(0.08), width: 1),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(14),
            borderSide: const BorderSide(color: _C.accent1, width: 1.5),
          ),
          errorBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(14),
            borderSide: const BorderSide(color: _C.error, width: 1),
          ),
          focusedErrorBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(14),
            borderSide: const BorderSide(color: _C.error, width: 1.5),
          ),
          errorStyle: const TextStyle(color: _C.error, fontSize: 11),
        ),
        validator: (v) => (v == null || v.isEmpty) ? "Please enter $label" : null,
      ),
    );
  }
}

// ─── ANIMATED LOGIN BUTTON ───────────────────────────────────────────────────
class _AnimatedLoginButton extends StatefulWidget {
  final bool isLoading;
  final VoidCallback onPressed;
  final Gradient gradient;

  const _AnimatedLoginButton({
    required this.isLoading,
    required this.onPressed,
    required this.gradient,
  });

  @override State<_AnimatedLoginButton> createState() => _AnimatedLoginButtonState();
}

class _AnimatedLoginButtonState extends State<_AnimatedLoginButton>
    with SingleTickerProviderStateMixin {
  bool _isPressed = false;
  late AnimationController _glowCtrl;
  late Animation<double> _glow;

  @override void initState() {
    super.initState();
    _glowCtrl = AnimationController(vsync: this, duration: const Duration(milliseconds: 1400))..repeat(reverse: true);
    _glow = Tween<double>(begin: 0.4, end: 1.0).animate(CurvedAnimation(parent: _glowCtrl, curve: Curves.easeInOut));
  }

  @override void dispose() { _glowCtrl.dispose(); super.dispose(); }

  void _handleTap() {
    if (widget.isLoading) return;
    HapticFeedback.lightImpact();
    setState(() => _isPressed = true);
    Future.delayed(const Duration(milliseconds: 150), () {
      if (mounted) setState(() => _isPressed = false);
      widget.onPressed();
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
          child: Container(
            decoration: BoxDecoration(
              gradient: widget.gradient,
              borderRadius: BorderRadius.circular(14),
              boxShadow: [
                BoxShadow(color: _C.accent1.withOpacity(0.30 * _glow.value), blurRadius: 20, offset: const Offset(0, 6)),
                BoxShadow(color: _C.accent2.withOpacity(0.20 * _glow.value), blurRadius: 12, offset: const Offset(0, 4)),
              ],
            ),
            child: Center(
              child: widget.isLoading
                  ? const SizedBox(
                      width: 22, height: 22,
                      child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                    )
                  : const Text(
                      "SIGN IN",
                      style: TextStyle(
                        fontSize: 14, fontWeight: FontWeight.w800,
                        color: Colors.white, fontFamily: 'Orbitron', letterSpacing: 2.5,
                      ),
                    ),
            ),
          ),
        ),
      ),
    );
  }
}
