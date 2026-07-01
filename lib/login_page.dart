import 'dart:ui';
import 'dart:convert';
import 'dart:async';
import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:url_launcher/url_launcher.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:device_info_plus/device_info_plus.dart';
import 'api_config.dart';
import 'splash.dart';

// ─── Palette Purple Cyber ─────────────────────────────────────────────────
class _C {
  static const bg         = Color(0xFF0A0015);
  static const surface    = Color(0xFF15002A);
  static const card       = Color(0xFF1A0A2E);
  static const border     = Color(0xFF5B2D8E);
  static const borderLit  = Color(0xFF7C3AED);

  static const purple     = Color(0xFF7C3AED);
  static const purpleDark = Color(0xFF4C1D95);
  static const purpleLight= Color(0xFFA78BFA);
  static const purpleGlow = Color(0xFFF0ABFC);
  static const pink       = Color(0xFFE879F9);

  static const green      = Color(0xFFA78BFA);
  static const amber      = Color(0xFFE879F9);
  static const red        = Color(0xFFD946EF);

  static const text       = Color(0xFFF3E8FF);
  static const textSub    = Color(0xFFD4C4F0);
  static const textDim    = Color(0xFF8B7AAA);

  static const LinearGradient purpleGrad = LinearGradient(
    colors: [Color(0xFF7C3AED), Color(0xFF4C1D95), Color(0xFF2D1B4E)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );
  
  static const LinearGradient accentGrad = LinearGradient(
    colors: [Color(0xFF7C3AED), Color(0xFFF0ABFC), Color(0xFF7C3AED)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );
}

class LoginPage extends StatefulWidget {
  const LoginPage({super.key});

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage>
    with TickerProviderStateMixin {
  final userCtrl    = TextEditingController();
  final passCtrl    = TextEditingController();
  final _formKey    = GlobalKey<FormState>();

  bool _isLoading       = false;
  bool _obscurePass     = true;
  String? _androidId;

  // ─── DIGITAL CLOCK ──────────────────────────────────────────────────────
  Timer? _clockTimer;
  String _timeWIB = '--:--:--';
  String _timeWITA = '--:--:--';
  String _timeWIT = '--:--:--';
  bool _showColon = true;

  // ─── TYPING ANIMATION ──────────────────────────────────────────────────
  Timer? _typingTimer;
  String _typingText = '';
  int _typingIndex = 0;
  final String _fullText = 'Login Gece Njeng mau masuk apk kan kontol';

  // Animations
  late AnimationController _bgCtrl;
  late AnimationController _entranceCtrl;
  late AnimationController _logoCtrl;
  late AnimationController _btnCtrl;
  late AnimationController _shakeCtrl;
  late AnimationController _lineCtrl;
  late AnimationController _pulseGlowCtrl;

  late Animation<double> _fade;
  late Animation<Offset>  _slide;
  late Animation<double>  _logoGlow;
  late Animation<double>  _btnPulse;
  late Animation<double>  _shake;
  late Animation<double>  _lineHeight;
  late Animation<double>  _pulseGlow;

  @override
  void initState() {
    super.initState();

    _bgCtrl = AnimationController(
        vsync: this, duration: const Duration(seconds: 18))
      ..repeat();

    _entranceCtrl = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 1000));
    _fade  = CurvedAnimation(parent: _entranceCtrl, curve: Curves.easeOut);
    _slide = Tween<Offset>(begin: const Offset(0, 0.06), end: Offset.zero)
        .animate(CurvedAnimation(
            parent: _entranceCtrl, curve: Curves.easeOutCubic));

    _logoCtrl = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 2200))
      ..repeat(reverse: true);
    _logoGlow = Tween<double>(begin: 0.4, end: 1.0)
        .animate(CurvedAnimation(parent: _logoCtrl, curve: Curves.easeInOut));

    _btnCtrl = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 1600))
      ..repeat(reverse: true);
    _btnPulse = Tween<double>(begin: 1.0, end: 1.05)
        .animate(CurvedAnimation(parent: _btnCtrl, curve: Curves.easeInOut));

    _shakeCtrl = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 500));
    _shake = TweenSequence<double>([
      TweenSequenceItem(tween: Tween(begin: 0.0, end: -8.0), weight: 1),
      TweenSequenceItem(tween: Tween(begin: -8.0, end: 8.0), weight: 2),
      TweenSequenceItem(tween: Tween(begin: 8.0, end: -5.0),  weight: 2),
      TweenSequenceItem(tween: Tween(begin: -5.0, end: 5.0),   weight: 2),
      TweenSequenceItem(tween: Tween(begin: 5.0, end: 0.0),    weight: 1),
    ]).animate(CurvedAnimation(parent: _shakeCtrl, curve: Curves.easeInOut));

    _lineCtrl = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 1500))
      ..repeat(reverse: true);
    _lineHeight = Tween<double>(begin: 0.3, end: 0.9)
        .animate(CurvedAnimation(parent: _lineCtrl, curve: Curves.easeInOut));

    _pulseGlowCtrl = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 1200))
      ..repeat(reverse: true);
    _pulseGlow = Tween<double>(begin: 0.3, end: 1.0)
        .animate(CurvedAnimation(parent: _pulseGlowCtrl, curve: Curves.easeInOut));

    _entranceCtrl.forward();
    
    _updateClock();
    _clockTimer = Timer.periodic(const Duration(seconds: 1), (_) {
      _updateClock();
      setState(() => _showColon = !_showColon);
    });

    // ─── START TYPING ANIMATION ──────────────────────────────────────────
    _startTyping();

    _initLogin();
  }

  void _startTyping() {
    _typingTimer = Timer.periodic(const Duration(milliseconds: 80), (timer) {
      if (_typingIndex < _fullText.length) {
        setState(() {
          _typingText += _fullText[_typingIndex];
          _typingIndex++;
        });
      } else {
        timer.cancel();
      }
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
    _typingTimer?.cancel();
    _bgCtrl.dispose();
    _entranceCtrl.dispose();
    _logoCtrl.dispose();
    _btnCtrl.dispose();
    _shakeCtrl.dispose();
    _lineCtrl.dispose();
    _pulseGlowCtrl.dispose();
    userCtrl.dispose();
    passCtrl.dispose();
    super.dispose();
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

  void _showMyBabuFullScreen() {
    Navigator.push(
      context,
      PageRouteBuilder(
        pageBuilder: (_, __, ___) => const _MyBabuFullScreen(),
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

  Future<void> _initLogin() async {
    try {
      final info = await DeviceInfoPlugin().androidInfo
          .timeout(const Duration(seconds: 5));
      _androidId = info.id;
    } catch (_) {
      _androidId = 'unknown';
    }

    final prefs    = await SharedPreferences.getInstance();
    final savedUser = prefs.getString('username');
    final savedPass = prefs.getString('password');
    final savedKey  = prefs.getString('key');

    if (savedUser != null && savedPass != null && savedKey != null) {
      try {
        final res  = await http.get(Uri.parse(
            'http://tirzzadminbaik.pteroqdactyl.my.id:11560/myInfo?username=$savedUser&password=$savedPass&androidId=$_androidId&key=$savedKey'));
        final data = jsonDecode(res.body);

        if (data['valid'] == true && mounted) {
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(builder: (_) => SplashScreen(
              username: savedUser, password: savedPass,
              role: data['role'], sessionKey: data['key'],
              expiredDate: data['expiredDate'],
              listBug:  _parseList(data['listBug']),
              listDoos: _parseList(data['listDDoS']),
              news:     _parseList(data['news']),
            )),
          );
        }
      } catch (_) {}
    }
  }

  List<Map<String, dynamic>> _parseList(dynamic raw) =>
      (raw as List? ?? []).map((e) => Map<String, dynamic>.from(e as Map)).toList();

  Future<void> _login() async {
    if (!_formKey.currentState!.validate()) return;

    final username = userCtrl.text.trim();
    final password = passCtrl.text.trim();

    setState(() => _isLoading = true);

    try {
      final res  = await http.post(Uri.parse('http://tirzzadminbaik.pteroqdactyl.my.id:11560/validate'), body: {
        'username': username,
        'password': password,
        'androidId': _androidId ?? 'unknown',
      });
      final data = jsonDecode(res.body);

      if (data['expired'] == true) {
        _shakeCtrl.forward(from: 0);
        _showAlert(
          title:   'Akses Habis',
          message: 'Masa akses Anda telah berakhir. Silakan perpanjang.',
          type:    _AlertType.warning,
          showContact: true,
        );
      } else if (data['valid'] != true) {
        _shakeCtrl.forward(from: 0);
        final msg = (data['message'] ?? '').toString().toLowerCase();
        if (msg.contains('perangkat') || msg.contains('device') ||
            msg.contains('another')) {
          _showAlert(
            title:   'Sesi Aktif',
            message: 'Akun ini sedang login di perangkat lain.',
            type:    _AlertType.warning,
          );
        } else {
          _showAlert(
            title:   'Login Gagal',
            message: 'Username atau password salah.',
            type:    _AlertType.error,
          );
        }
      } else {
        final prefs = await SharedPreferences.getInstance();
        prefs.setString('username', username);
        prefs.setString('password', password);
        prefs.setString('key', data['key']);

        if (mounted) {
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(builder: (_) => SplashScreen(
              username: username, password: password,
              role: data['role'], sessionKey: data['key'],
              expiredDate: data['expiredDate'],
              listBug:  _parseList(data['listBug']),
              listDoos: _parseList(data['listDDoS']),
              news:     _parseList(data['news']),
            )),
          );
        }
      }
    } catch (_) {
      _shakeCtrl.forward(from: 0);
      _showAlert(
        title:   'Koneksi Error',
        message: 'Gagal terhubung ke server. Periksa jaringan Anda.',
        type:    _AlertType.error,
      );
    }

    if (mounted) setState(() => _isLoading = false);
  }

  void _showAlert({
    required String title,
    required String message,
    required _AlertType type,
    bool showContact = false,
  }) {
    final color = switch (type) {
      _AlertType.error   => _C.red,
      _AlertType.warning => _C.amber,
      _AlertType.success => _C.green,
    };
    final icon = switch (type) {
      _AlertType.error   => Icons.error_rounded,
      _AlertType.warning => Icons.warning_amber_rounded,
      _AlertType.success => Icons.check_circle_rounded,
    };

    showGeneralDialog(
      context: context,
      barrierDismissible: true,
      barrierLabel: '',
      barrierColor: Colors.black87,
      transitionDuration: const Duration(milliseconds: 320),
      transitionBuilder: (_, anim, __, child) => ScaleTransition(
        scale: CurvedAnimation(parent: anim, curve: Curves.easeOutBack),
        child: FadeTransition(opacity: anim, child: child),
      ),
      pageBuilder: (ctx, _, __) => Dialog(
        backgroundColor: Colors.transparent,
        insetPadding: const EdgeInsets.symmetric(horizontal: 28),
        child: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [_C.card, _C.surface],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(28),
            border: Border.all(color: color.withOpacity(0.3), width: 1.5),
            boxShadow: [
              BoxShadow(color: color.withOpacity(0.15), blurRadius: 50),
            ],
          ),
          padding: const EdgeInsets.all(28),
          child: Column(mainAxisSize: MainAxisSize.min, children: [
            Container(
              width: 60, height: 60,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: color.withOpacity(0.1),
                border: Border.all(color: color.withOpacity(0.3)),
              ),
              child: Icon(icon, color: color, size: 30),
            ),
            const SizedBox(height: 18),
            Text(title, style: const TextStyle(color: _C.text,
                fontSize: 20, fontWeight: FontWeight.w800)),
            const SizedBox(height: 10),
            Text(message, textAlign: TextAlign.center,
                style: const TextStyle(color: _C.textSub,
                    fontSize: 13, height: 1.5)),
            const SizedBox(height: 24),
            if (showContact) ...[
              _GradBtn(
                label: 'HUBUNGI ADMIN',
                fullWidth: true,
                onTap: () async {
                  Navigator.pop(ctx);
                  await launchUrl(Uri.parse('https://t.me/valentpaket'),
                      mode: LaunchMode.externalApplication);
                },
              ),
              const SizedBox(height: 12),
            ],
            _OutlineBtn(
              label: showContact ? 'TUTUP' : 'OK',
              fullWidth: true,
              onTap: () => Navigator.pop(ctx),
            ),
          ]),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _C.bg,
      body: Stack(
        children: [
          Positioned.fill(child: _AnimatedBg(controller: _bgCtrl)),
          SafeArea(
            child: FadeTransition(
              opacity: _fade,
              child: SlideTransition(
                position: _slide,
                child: Center(
                  child: SingleChildScrollView(
                    physics: const BouncingScrollPhysics(),
                    padding: const EdgeInsets.symmetric(
                        horizontal: 20, vertical: 24),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        _buildVerticalLine(),
                        const SizedBox(height: 12),
                        _buildDigitalClock(),
                        const SizedBox(height: 24),
                        _buildLogo(),
                        const SizedBox(height: 20),
                        _buildTypingText(),
                        const SizedBox(height: 20),
                        _buildHeading(),
                        const SizedBox(height: 32),
                        AnimatedBuilder(
                          animation: _shake,
                          builder: (_, child) => Transform.translate(
                            offset: Offset(_shake.value, 0),
                            child: child,
                          ),
                          child: _buildForm(),
                        ),
                        const SizedBox(height: 16),
                        _buildBottomButtons(),
                        const SizedBox(height: 24),
                        _buildFooter(),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildVerticalLine() {
    return AnimatedBuilder(
      animation: _lineHeight,
      builder: (_, __) => Row(
        children: [
          Container(
            width: 3,
            height: 30 + (_lineHeight.value * 40),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  _C.purple.withOpacity(0.1),
                  _C.purple.withOpacity(0.8 + (_lineHeight.value * 0.2)),
                  _C.purpleLight.withOpacity(0.9 + (_lineHeight.value * 0.1)),
                  _C.purple.withOpacity(0.8 + (_lineHeight.value * 0.2)),
                  _C.purple.withOpacity(0.1),
                ],
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
              ),
              borderRadius: BorderRadius.circular(2),
              boxShadow: [
                BoxShadow(
                  color: _C.purple.withOpacity(0.4 + (_lineHeight.value * 0.3)),
                  blurRadius: 12,
                  spreadRadius: 2,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDigitalClock() {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 16),
      decoration: BoxDecoration(
        color: _C.card.withOpacity(0.6),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: _C.purple.withOpacity(0.25)),
        boxShadow: [
          BoxShadow(
            color: _C.purple.withOpacity(0.08),
            blurRadius: 20,
          ),
        ],
      ),
      child: Column(
        children: [
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
                  color: _C.purple.withOpacity(0.6),
                  blurRadius: 16,
                  spreadRadius: 3,
                ),
              ],
            ),
          ),
          const SizedBox(height: 8),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              _clockItem('WIB', _timeWIB),
              _clockItem('WITA', _timeWITA),
              _clockItem('WIT', _timeWIT),
            ],
          ),
          const SizedBox(height: 4),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              AnimatedContainer(
                duration: const Duration(milliseconds: 500),
                width: 5,
                height: 5,
                decoration: BoxDecoration(
                  color: _showColon ? _C.purpleLight : _C.purpleLight.withOpacity(0.15),
                  shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(
                      color: _C.purpleLight.withOpacity(_showColon ? 0.9 : 0.05),
                      blurRadius: 10,
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 6),
              Text(
                'LIVE',
                style: TextStyle(
                  color: _C.purpleLight.withOpacity(_showColon ? 0.9 : 0.2),
                  fontSize: 8,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 1.5,
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
            fontSize: 8,
            fontWeight: FontWeight.w600,
            letterSpacing: 1.2,
            fontFamily: 'Orbitron',
          ),
        ),
        const SizedBox(height: 2),
        Stack(
          children: [
            Text(
              time,
              style: TextStyle(
                color: _C.purple.withOpacity(0.06),
                fontSize: 15,
                fontWeight: FontWeight.w700,
                fontFamily: 'Orbitron',
                letterSpacing: 1.5,
                shadows: [
                  Shadow(color: _C.purple.withOpacity(0.3), blurRadius: 25),
                ],
              ),
            ),
            Text(
              time,
              style: TextStyle(
                color: _C.purple.withOpacity(0.15),
                fontSize: 15,
                fontWeight: FontWeight.w700,
                fontFamily: 'Orbitron',
                letterSpacing: 1.5,
                shadows: [
                  Shadow(color: _C.purple.withOpacity(0.6), blurRadius: 40),
                ],
              ),
            ),
            Text(
              time,
              style: const TextStyle(
                color: Color(0xFFF3E8FF),
                fontSize: 15,
                fontWeight: FontWeight.w700,
                fontFamily: 'Orbitron',
                letterSpacing: 1.5,
                shadows: [
                  Shadow(color: Color(0xFFA78BFA), blurRadius: 12),
                ],
              ),
            ),
          ],
        ),
      ],
    );
  }

  // ─── TYPING TEXT ──────────────────────────────────────────────────────────
  Widget _buildTypingText() {
    return AnimatedBuilder(
      animation: _pulseGlow,
      builder: (_, __) => Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [
              _C.purple.withOpacity(0.08 * _pulseGlow.value),
              _C.purpleLight.withOpacity(0.04 * _pulseGlow.value),
            ],
          ),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: _C.purple.withOpacity(0.2 * _pulseGlow.value),
            width: 1.2,
          ),
          boxShadow: [
            BoxShadow(
              color: _C.purple.withOpacity(0.15 * _pulseGlow.value),
              blurRadius: 20,
              spreadRadius: 2,
            ),
          ],
        ),
        child: Row(
          children: [
            ShaderMask(
              shaderCallback: (bounds) => LinearGradient(
                colors: [
                  _C.purple,
                  _C.purpleLight,
                  _C.purpleGlow,
                  _C.purpleLight,
                  _C.purple,
                ],
                stops: const [0.0, 0.25, 0.5, 0.75, 1.0],
              ).createShader(bounds),
              child: Text(
                _typingText,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 14,
                  fontWeight: FontWeight.w700,
                  fontFamily: 'Orbitron',
                  letterSpacing: 0.5,
                ),
              ),
            ),
            const SizedBox(width: 4),
            AnimatedContainer(
              duration: const Duration(milliseconds: 300),
              width: 3,
              height: 18,
              decoration: BoxDecoration(
                color: _C.purpleLight.withOpacity(_typingIndex < _fullText.length ? 1.0 : 0.0),
                borderRadius: BorderRadius.circular(2),
                boxShadow: [
                  BoxShadow(
                    color: _C.purpleLight.withOpacity(_typingIndex < _fullText.length ? 0.6 : 0.0),
                    blurRadius: 8,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildLogo() {
    return AnimatedBuilder(
      animation: _logoGlow,
      builder: (_, __) => Stack(
        alignment: Alignment.center,
        children: [
          Container(
            width: 130, height: 130,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: RadialGradient(
                colors: [
                  _C.purple.withOpacity(_logoGlow.value * 0.15),
                  Colors.transparent,
                ],
                radius: 0.8,
              ),
            ),
          ),
          Container(
            width: 110, height: 110,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              border: Border.all(
                color: _C.purple.withOpacity(_logoGlow.value * 0.3),
                width: 1.5,
              ),
            ),
          ),
          Container(
            width: 92, height: 92,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              border: Border.all(
                color: _C.purpleLight.withOpacity(_logoGlow.value * 0.5),
                width: 2,
              ),
            ),
          ),
          Hero(
            tag: 'logo',
            child: Container(
              width: 76, height: 76,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(24),
                gradient: const LinearGradient(
                  colors: [Color(0xFF1A0A2E), Color(0xFF0A0015)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                border: Border.all(
                  color: _C.purpleLight.withOpacity(_logoGlow.value * 0.8),
                  width: 2,
                ),
                boxShadow: [
                  BoxShadow(
                    color: _C.purple.withOpacity(_logoGlow.value * 0.6),
                    blurRadius: 30,
                    spreadRadius: 2,
                  ),
                ],
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(22),
                child: Image.asset('assets/images/logo.png',
                    fit: BoxFit.cover,
                    errorBuilder: (_, __, ___) => Icon(
                      Icons.rocket_rounded, color: _C.purpleLight, size: 40)),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHeading() {
    return Column(children: [
      ShaderMask(
        shaderCallback: (b) => const LinearGradient(
          colors: [Color(0xFF7C3AED), Color(0xFFF0ABFC), Color(0xFF7C3AED)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ).createShader(b),
        child: const Text(
          'PURPLE - CORE',
          style: TextStyle(
            fontSize: 28,
            fontWeight: FontWeight.w900,
            color: Colors.white,
            letterSpacing: 2,
            fontFamily: 'Orbitron',
          ),
        ),
      ),
      const SizedBox(height: 8),
      Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
        decoration: BoxDecoration(
          color: _C.surface,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: _C.border, width: 1),
        ),
        child: const Text('Masuk untuk melanjutkan',
            style: TextStyle(color: _C.textSub, fontSize: 13,
                fontWeight: FontWeight.w500, fontFamily: 'ShareTechMono')),
      ),
    ]);
  }

  Widget _buildForm() {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [_C.card, _C.surface],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(28),
        border: Border.all(color: _C.border, width: 1),
        boxShadow: [
          BoxShadow(color: _C.purple.withOpacity(0.1),
              blurRadius: 40, offset: const Offset(0, 15)),
        ],
      ),
      child: Form(
        key: _formKey,
        child: Column(children: [
          Row(children: [
            Container(
              width: 5, height: 20,
              decoration: BoxDecoration(
                gradient: _C.accentGrad,
                borderRadius: BorderRadius.circular(3),
              ),
            ),
            const SizedBox(width: 12),
            Icon(Icons.account_circle_rounded,
                color: _C.purpleLight, size: 18),
            const SizedBox(width: 8),
            const Text('KREDENSIAL AKUN',
                style: TextStyle(color: _C.text, fontSize: 13,
                    fontWeight: FontWeight.w700, letterSpacing: 0.5,
                    fontFamily: 'Orbitron')),
          ]),
          const SizedBox(height: 22),

          _LoginField(
            controller: userCtrl,
            label: 'Username',
            icon: Icons.person_outline_rounded,
            validator: (v) => (v == null || v.isEmpty)
                ? 'Username tidak boleh kosong' : null,
          ),
          const SizedBox(height: 16),

          _LoginField(
            controller: passCtrl,
            label: 'Password',
            icon: Icons.lock_outline_rounded,
            obscure: _obscurePass,
            onToggleObscure: () =>
                setState(() => _obscurePass = !_obscurePass),
            validator: (v) => (v == null || v.isEmpty)
                ? 'Password tidak boleh kosong' : null,
          ),
          const SizedBox(height: 28),

          _LoginButton(
            isLoading: _isLoading,
            pulseAnim: _btnPulse,
            onTap: _login,
          ),
        ]),
      ),
    );
  }

  Widget _buildBottomButtons() {
    return Column(
      children: [
        Row(
          children: [
            Expanded(
              child: _GradBtn(
                label: 'THANKS TO ❤️',
                onTap: _showThanksToFullScreen,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _PurpleBtn(
                label: 'MY BABU GWEH 😈',
                onTap: _showMyBabuFullScreen,
              ),
            ),
          ],
        ),
        const SizedBox(height: 10),
        GestureDetector(
          onTap: () => launchUrl(
              Uri.parse('https://t.me/valentpaket'),
              mode: LaunchMode.externalApplication),
          child: Container(
            padding: const EdgeInsets.symmetric(vertical: 10),
            decoration: BoxDecoration(
              gradient: _C.purpleGrad,
              borderRadius: BorderRadius.circular(14),
              boxShadow: [
                BoxShadow(
                  color: _C.purple.withOpacity(0.3),
                  blurRadius: 16,
                  spreadRadius: 1,
                ),
              ],
            ),
            child: const Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.shopping_cart_rounded, color: Colors.white, size: 18),
                SizedBox(width: 8),
                Text(
                  'BELI AKSES SEKARANG',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 13,
                    fontWeight: FontWeight.bold,
                    fontFamily: 'Orbitron',
                    letterSpacing: 1,
                  ),
                ),
                SizedBox(width: 8),
                Icon(Icons.arrow_forward_ios_rounded, color: Colors.white, size: 14),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildFooter() {
    return Column(children: [
      Row(mainAxisAlignment: MainAxisAlignment.center, children: [
        Icon(Icons.circle, color: _C.purple, size: 5),
        const SizedBox(width: 8),
        const Text('© 2026 PURPLE - CORE',
            style: TextStyle(color: _C.textDim, fontSize: 11,
                fontWeight: FontWeight.w500, letterSpacing: 0.5,
                fontFamily: 'Orbitron')),
        const SizedBox(width: 8),
        Icon(Icons.circle, color: _C.purple, size: 5),
      ]),
    ]);
  }
}

// ─── MY BABU FULL SCREEN ────────────────────────────────────────────────────
class _MyBabuFullScreen extends StatefulWidget {
  const _MyBabuFullScreen();

  @override
  State<_MyBabuFullScreen> createState() => _MyBabuFullScreenState();
}

class _MyBabuFullScreenState extends State<_MyBabuFullScreen>
    with TickerProviderStateMixin {
  late AnimationController _fadeCtrl;
  late Animation<double> _fadeAnim;
  late AnimationController _floatCtrl;
  late AnimationController _rotateCtrl;

  final List<Map<String, dynamic>> _babuList = [
    {'name': 'Wahyu', 'title': 'My Babu 😈', 'color': Color(0xFFFF6B6B), 'emoji': '👑'},
    {'name': 'Afif', 'title': 'My Budak 🤨', 'color': Color(0xFF4ECDC4), 'emoji': '🔗'},
    {'name': 'Arul', 'title': 'Pemain Bokep 🤨', 'color': Color(0xFFFFD93D), 'emoji': '🎬'},
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
                      const Color(0xFF1A0A2E).withOpacity(0.92),
                      const Color(0xFF0A0015).withOpacity(0.97),
                    ],
                  ),
                ),
              ),
            ),
          ),
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
                  stops: const [0.0, 0.15, 0.5, 0.85, 1.0],
                ),
                boxShadow: [
                  BoxShadow(
                    color: const Color(0xFF7C3AED).withOpacity(0.6),
                    blurRadius: 24,
                    spreadRadius: 4,
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
                              'MY BABU GWEH',
                              style: TextStyle(
                                color: Color(0xFFF3E8FF),
                                fontSize: 20,
                                fontWeight: FontWeight.bold,
                                fontFamily: 'Orbitron',
                                letterSpacing: 2,
                              ),
                            ),
                            Text(
                              '🔥 GANAS SEMUA 🔥',
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
                      itemCount: _babuList.length,
                      itemBuilder: (context, index) {
                        final item = _babuList[index];
                        final color = item['color'] as Color;
                        return AnimatedBuilder(
                          animation: _floatCtrl,
                          builder: (context, child) {
                            final delay = index * 0.15;
                            final offset = (1 + delay) * 5 * _floatCtrl.value;
                            return Transform.translate(
                              offset: Offset(0, offset),
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
                                      margin: const EdgeInsets.only(bottom: 16),
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
                                            width: 60, height: 60,
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
                                                item['emoji'],
                                                style: const TextStyle(
                                                  fontSize: 28,
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
                                            child: Icon(
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

// ─── Login Field ──────────────────────────────────────────────────────────────
class _LoginField extends StatefulWidget {
  final TextEditingController controller;
  final String label;
  final IconData icon;
  final bool obscure;
  final VoidCallback? onToggleObscure;
  final String? Function(String?)? validator;

  const _LoginField({
    required this.controller,
    required this.label,
    required this.icon,
    this.obscure = false,
    this.onToggleObscure,
    this.validator,
  });

  @override
  State<_LoginField> createState() => _LoginFieldState();
}

class _LoginFieldState extends State<_LoginField> {
  bool _focused = false;
  final _focus = FocusNode();

  @override
  void initState() {
    super.initState();
    _focus.addListener(() => setState(() => _focused = _focus.hasFocus));
  }

  @override
  void dispose() { _focus.dispose(); super.dispose(); }

  @override
  Widget build(BuildContext context) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 200),
      decoration: BoxDecoration(
        color: _C.bg,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: _focused ? _C.purple : _C.border,
          width: _focused ? 1.5 : 1.0,
        ),
        boxShadow: _focused
            ? [BoxShadow(color: _C.purple.withOpacity(0.2),
                blurRadius: 20, offset: const Offset(0, 4))]
            : [],
      ),
      child: TextFormField(
        controller: widget.controller,
        focusNode: _focus,
        obscureText: widget.obscure,
        validator: widget.validator,
        style: const TextStyle(color: _C.text, fontSize: 15,
            fontWeight: FontWeight.w500),
        cursorColor: _C.purple,
        decoration: InputDecoration(
          labelText: widget.label,
          labelStyle: TextStyle(color: _focused ? _C.purpleLight : _C.textSub, 
              fontSize: 13, fontWeight: FontWeight.w500),
          floatingLabelStyle:
              const TextStyle(color: _C.purpleLight, fontSize: 11),
          prefixIcon: Icon(widget.icon,
              color: _focused ? _C.purpleLight : _C.textSub, size: 20),
          suffixIcon: widget.onToggleObscure != null
              ? IconButton(
                  icon: Icon(
                    widget.obscure
                        ? Icons.visibility_off_outlined
                        : Icons.visibility_outlined,
                    color: _focused ? _C.purpleLight : _C.textSub, size: 20,
                  ),
                  onPressed: widget.onToggleObscure,
                )
              : null,
          errorStyle: const TextStyle(color: _C.red, fontSize: 11),
          border: InputBorder.none,
          contentPadding:
              const EdgeInsets.symmetric(horizontal: 18, vertical: 16),
        ),
      ),
    );
  }
}

// ─── Login Button ─────────────────────────────────────────────────────────────
class _LoginButton extends StatefulWidget {
  final bool isLoading;
  final Animation<double> pulseAnim;
  final VoidCallback onTap;

  const _LoginButton({
    required this.isLoading,
    required this.pulseAnim,
    required this.onTap,
  });

  @override
  State<_LoginButton> createState() => _LoginButtonState();
}

class _LoginButtonState extends State<_LoginButton> {
  bool _down = false;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTapDown: (_) => setState(() => _down = true),
      onTapUp: (_) {
        setState(() => _down = false);
        if (!widget.isLoading) widget.onTap();
      },
      onTapCancel: () => setState(() => _down = false),
      child: AnimatedBuilder(
        animation: widget.pulseAnim,
        builder: (_, __) => Transform.scale(
          scale: widget.isLoading || _down ? 1.0 : widget.pulseAnim.value,
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 150),
            height: 56,
            width: double.infinity,
            decoration: BoxDecoration(
              gradient: widget.isLoading ? _C.purpleGrad : _C.accentGrad,
              borderRadius: BorderRadius.circular(18),
              boxShadow: _down || widget.isLoading
                  ? []
                  : [
                      BoxShadow(
                        color: _C.purple.withOpacity(
                            widget.pulseAnim.value * 0.5),
                        blurRadius: 28,
                        offset: const Offset(0, 8),
                      ),
                    ],
            ),
            child: Center(
              child: AnimatedSwitcher(
                duration: const Duration(milliseconds: 220),
                child: widget.isLoading
                    ? const SizedBox(
                        key: ValueKey('loading'),
                        width: 22, height: 22,
                        child: CircularProgressIndicator(
                            strokeWidth: 2.5, color: Colors.white),
                      )
                    : const Row(
                        key: ValueKey('idle'),
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.login_rounded,
                              color: Colors.white, size: 20),
                          SizedBox(width: 12),
                          Text('MASUK',
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 16,
                                fontWeight: FontWeight.w800,
                                letterSpacing: 1,
                                fontFamily: 'Orbitron',
                              )),
                        ],
                      ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

// ─── Gradient Button ──────────────────────────────────────────────────────────
class _GradBtn extends StatefulWidget {
  final String label;
  final VoidCallback onTap;
  final bool fullWidth;

  const _GradBtn({required this.label, required this.onTap,
      this.fullWidth = false});

  @override
  State<_GradBtn> createState() => _GradBtnState();
}

class _GradBtnState extends State<_GradBtn> {
  bool _down = false;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTapDown: (_) => setState(() => _down = true),
      onTapUp: (_) { setState(() => _down = false); widget.onTap(); },
      onTapCancel: () => setState(() => _down = false),
      child: AnimatedScale(
        scale: _down ? 0.96 : 1.0,
        duration: const Duration(milliseconds: 120),
        child: Container(
          height: 44,
          width: widget.fullWidth ? double.infinity : null,
          padding: const EdgeInsets.symmetric(horizontal: 12),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [const Color(0xFFFFD700), const Color(0xFFFFA500)],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(14),
            boxShadow: _down ? [] : [
              BoxShadow(
                color: const Color(0xFFFFD700).withOpacity(0.4),
                blurRadius: 16,
                offset: const Offset(0, 6),
              ),
            ],
          ),
          child: Center(
            child: Text(widget.label,
                style: const TextStyle(color: Colors.black,
                    fontWeight: FontWeight.w800, fontSize: 12,
                    letterSpacing: 0.5, fontFamily: 'Orbitron')),
          ),
        ),
      ),
    );
  }
}

// ─── Purple Button ────────────────────────────────────────────────────────────
class _PurpleBtn extends StatefulWidget {
  final String label;
  final VoidCallback onTap;
  final bool fullWidth;

  const _PurpleBtn({required this.label, required this.onTap,
      this.fullWidth = false});

  @override
  State<_PurpleBtn> createState() => _PurpleBtnState();
}

class _PurpleBtnState extends State<_PurpleBtn> {
  bool _down = false;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTapDown: (_) => setState(() => _down = true),
      onTapUp: (_) { setState(() => _down = false); widget.onTap(); },
      onTapCancel: () => setState(() => _down = false),
      child: AnimatedScale(
        scale: _down ? 0.96 : 1.0,
        duration: const Duration(milliseconds: 120),
        child: Container(
          height: 44,
          width: widget.fullWidth ? double.infinity : null,
          padding: const EdgeInsets.symmetric(horizontal: 12),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [const Color(0xFF7C3AED), const Color(0xFFF0ABFC)],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(14),
            boxShadow: _down ? [] : [
              BoxShadow(
                color: const Color(0xFF7C3AED).withOpacity(0.4),
                blurRadius: 20,
                offset: const Offset(0, 8),
              ),
            ],
          ),
          child: Center(
            child: Text(widget.label,
                style: const TextStyle(color: Colors.white,
                    fontWeight: FontWeight.w800, fontSize: 12,
                    letterSpacing: 0.5, fontFamily: 'Orbitron')),
          ),
        ),
      ),
    );
  }
}

// ─── Outline Button ───────────────────────────────────────────────────────────
class _OutlineBtn extends StatefulWidget {
  final String label;
  final VoidCallback onTap;
  final bool fullWidth;

  const _OutlineBtn({required this.label, required this.onTap,
      this.fullWidth = false});

  @override
  State<_OutlineBtn> createState() => _OutlineBtnState();
}

class _OutlineBtnState extends State<_OutlineBtn> {
  bool _down = false;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTapDown: (_) => setState(() => _down = true),
      onTapUp: (_) { setState(() => _down = false); widget.onTap(); },
      onTapCancel: () => setState(() => _down = false),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 120),
        height: 48,
        width: widget.fullWidth ? double.infinity : null,
        decoration: BoxDecoration(
          color: _down ? _C.border.withOpacity(0.3) : Colors.transparent,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: _C.border, width: 1.5),
        ),
        child: Center(
          child: Text(widget.label,
              style: const TextStyle(color: _C.textSub,
                  fontWeight: FontWeight.w700, fontSize: 14,
                  letterSpacing: 0.5, fontFamily: 'Orbitron')),
        ),
      ),
    );
  }
}

// ─── Animated Background ──────────────────────────────────────────────────────
class _AnimatedBg extends StatelessWidget {
  final AnimationController controller;
  const _AnimatedBg({required this.controller});

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: controller,
      builder: (_, __) =>
          CustomPaint(painter: _BgPainter(controller.value)),
    );
  }
}

class _BgPainter extends CustomPainter {
  final double t;
  _BgPainter(this.t);

  @override
  void paint(Canvas canvas, Size size) {
    final grid = Paint()
      ..color = _C.border.withOpacity(0.2)
      ..strokeWidth = 0.8;
    const step = 40.0;
    for (double x = 0; x < size.width; x += step) {
      canvas.drawLine(Offset(x, 0), Offset(x, size.height), grid);
    }
    for (double y = 0; y < size.height; y += step) {
      canvas.drawLine(Offset(0, y), Offset(size.width, y), grid);
    }
    
    final glow = Paint()
      ..shader = RadialGradient(colors: [
        _C.purple.withOpacity(0.12 + math.sin(t * math.pi * 2) * 0.04),
        Colors.transparent,
      ], radius: 0.75).createShader(Rect.fromCircle(
          center: Offset(size.width / 2, size.height * 0.35),
          radius: size.width * 0.7));
    canvas.drawCircle(
        Offset(size.width / 2, size.height * 0.35), size.width * 0.7, glow);

    final glow2 = Paint()
      ..shader = RadialGradient(colors: [
        _C.purpleLight.withOpacity(0.08 + math.cos(t * math.pi * 2) * 0.03),
        Colors.transparent,
      ], radius: 0.5).createShader(Rect.fromCircle(
          center: Offset(size.width * 0.15, size.height * 0.75),
          radius: size.width * 0.4));
    canvas.drawCircle(
        Offset(size.width * 0.15, size.height * 0.75), size.width * 0.4, glow2);
  }

  @override
  bool shouldRepaint(_BgPainter old) => old.t != t;
}

enum _AlertType { error, warning, success }