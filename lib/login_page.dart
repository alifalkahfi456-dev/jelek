import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:url_launcher/url_launcher.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:device_info_plus/device_info_plus.dart';
import 'package:video_player/video_player.dart';
import 'dart:ui';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'dart:math';

const String baseUrl = "http://server.sanzyoffc.panelantirusuh.biz.id:10604";

class LoginPage extends StatefulWidget {
  const LoginPage({super.key});

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> with TickerProviderStateMixin {
  final TextEditingController _userController = TextEditingController();
  final TextEditingController _passController = TextEditingController();
  
  bool _isLoading = false;
  bool _isObscure = true;
  String? _androidId;
  String? _generatedQris;
  int _randomNominal = 0;
  bool _isGeneratingQris = false;

  late VideoPlayerController _videoController;
  late AnimationController _fadeController;
  late AnimationController _slideController;
  late AnimationController _glowController;
  late AnimationController _pulseController;
  late AnimationController _rotateController;
  late AnimationController _breathingController;
  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation;
  late Animation<double> _glowAnimation;
  late Animation<double> _pulseAnimation;
  late Animation<double> _rotateAnimation;
  late Animation<double> _breathingAnimation;

  final Color _primaryColor   = const Color(0xFFB8B8CC);
  final Color _secondaryColor = const Color(0xFF787888);
  final Color _accentColor    = const Color(0xFFD8D8EC);
  final Color _successColor   = const Color(0xFF8899AA);
  final Color _warningColor   = const Color(0xFFC8B890);
  final Color _darkBg         = const Color(0xFF0D0D12);
  final Color _darkerBg       = const Color(0xFF07070A);
  final Color _surfaceColor   = const Color(0xFF161620);
  final Color _cardColor      = const Color(0xFF111118);
  final Color _glowColor1     = const Color(0xFFE0E0F8);
  final Color _glowColor2     = const Color(0xFF9090B4);
  final Color _glowColor3     = const Color(0xFFBBBBD0);
  final Color _roseColor      = const Color(0xFFBB8899);
  final Color _goldColor      = const Color(0xFFCCBB88);

  final String _qrisApiKey = 'cki_ScQlLqI6YIrYMr5o1cmPQhyp1uXscwT6J63VeiMqsqX5WaSK'; // jangan diganti karena untuk biaya tambahan update 

  @override
  void initState() {
    super.initState();
    _initAnimations();
    _initVideo();
    _initAndroidId();
    _loadSavedData();
    _generateRandomQris();
  }

  void _initAnimations() {
    _fadeController = AnimationController(
      duration: const Duration(milliseconds: 1400),
      vsync: this,
    );
    _slideController = AnimationController(
      duration: const Duration(milliseconds: 1100),
      vsync: this,
    );
    _glowController = AnimationController(
      duration: const Duration(milliseconds: 3000),
      vsync: this,
    )..repeat(reverse: true);
    _pulseController = AnimationController(
      duration: const Duration(milliseconds: 2000),
      vsync: this,
    )..repeat(reverse: true);
    _rotateController = AnimationController(
      duration: const Duration(seconds: 20),
      vsync: this,
    )..repeat();
    _breathingController = AnimationController(
      duration: const Duration(seconds: 4),
      vsync: this,
    )..repeat(reverse: true);

    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _fadeController, curve: Curves.easeOutCubic),
    );
    _slideAnimation = Tween<Offset>(
      begin: const Offset(0, 0.4),
      end: Offset.zero,
    ).animate(
      CurvedAnimation(parent: _slideController, curve: Curves.easeOutCubic),
    );
    _glowAnimation = Tween<double>(begin: 0.3, end: 1.0).animate(
      CurvedAnimation(parent: _glowController, curve: Curves.easeInOutSine),
    );
    _pulseAnimation = Tween<double>(begin: 0.92, end: 1.08).animate(
      CurvedAnimation(parent: _pulseController, curve: Curves.easeInOutSine),
    );
    _rotateAnimation = Tween<double>(begin: 0, end: 1).animate(
      CurvedAnimation(parent: _rotateController, curve: Curves.linear),
    );
    _breathingAnimation = Tween<double>(begin: 0.7, end: 1.0).animate(
      CurvedAnimation(parent: _breathingController, curve: Curves.easeInOutSine),
    );

    _fadeController.forward();
    _slideController.forward();
  }

  void _initVideo() {
    _videoController = VideoPlayerController.asset('assets/videos/login.mp4')
      ..initialize().then((_) {
        setState(() {});
        _videoController.setLooping(true);
        _videoController.play();
        _videoController.setVolume(0);
        _videoController.setPlaybackSpeed(0.8);
      }).catchError((error) {
        debugPrint("Video initialization error: $error");
      });
  }

  Future<void> _initAndroidId() async {
    final deviceInfo = DeviceInfoPlugin();
    final android = await deviceInfo.androidInfo;
    _androidId = android.id ?? "unknown_device";
  }

  Future<void> _loadSavedData() async {
    final prefs = await SharedPreferences.getInstance();
    final savedUser = prefs.getString("username");
    final savedPass = prefs.getString("password");
    final savedKey = prefs.getString("key");

    if (savedUser != null && savedPass != null && savedKey != null && _androidId != null) {
      try {
        final uri = Uri.parse(
          "$baseUrl/api/auth/myInfo?username=$savedUser&password=$savedPass&androidId=$_androidId&key=$savedKey",
        );
        final res = await http.get(uri);
        final data = jsonDecode(res.body);

        if (data['valid'] == true) {
          if (!mounted) return;
          Navigator.pushReplacementNamed(
            context,
            '/splash',
            arguments: {
              'username': savedUser,
              'password': savedPass,
              'role': data['role'],
              'key': data['key'],
              'expiredDate': data['expiredDate'],
              'listBug': data['listBug'] ?? [],
              'listPayload': data['listPayload'] ?? [],
              'listDDoS': data['listDDoS'] ?? [],
              'news': data['news'] ?? [],
            },
          );
        }
      } catch (_) {}
    }
  }

  Future<void> _generateRandomQris() async {
    setState(() {
      _isGeneratingQris = true;
    });

    final random = Random();
    _randomNominal = 10000 + random.nextInt(990000); // 10k - 1jt
    
    try {
      final response = await http.post(
        Uri.parse('https://api.qrispy.id/v1/qris/generate'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $_qrisApiKey',
          'X-API-Key': _qrisApiKey,
        },
        body: json.encode({
          'amount': _randomNominal,
          'expiry': 3600,
          'notes': 'Payment for DEATHXRAT Access',
        }),
      ).timeout(const Duration(seconds: 15));

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        setState(() {
          _generatedQris = data['qris_image'] ?? data['qr_code'] ?? data['image'];
          _isGeneratingQris = false;
        });
      } else {
        setState(() {
          _generatedQris = null;
          _isGeneratingQris = false;
        });
      }
    } catch (e) {
      setState(() {
        _generatedQris = null;
        _isGeneratingQris = false;
      });
    }
  }

  Future<void> _login() async {
    final username = _userController.text.trim();
    final password = _passController.text.trim();

    if (username.isEmpty || password.isEmpty) {
      _showAlert("ERROR", "Username and password are required.", isError: true);
      return;
    }

    setState(() => _isLoading = true);

    try {
      final validate = await http.post(
        Uri.parse("$baseUrl/api/auth/validate"),
        body: {
          "username": username,
          "password": password,
          "androidId": _androidId ?? "unknown_device",
        },
      ).timeout(const Duration(seconds: 15));

      final validData = jsonDecode(validate.body);

      if (validData['expired'] == true) {
        _showAlert("ACCESS EXPIRED", "Your access has expired. Please renew it.", isError: true);
      } else if (validData['valid'] != true) {
        _showAlert("LOGIN FAILED", "Invalid username or password.", isError: true);
      } else {
        final prefs = await SharedPreferences.getInstance();
        prefs.setString("username", username);
        prefs.setString("password", password);
        prefs.setString("key", validData['key']);

        if (!mounted) return;
        Navigator.pushReplacementNamed(
          context,
          '/splash',
          arguments: {
            'username': username,
            'password': password,
            'role': validData['role'],
            'key': validData['key'],
            'expiredDate': validData['expiredDate'],
            'listBug': validData['listBug'] ?? [],
            'listPayload': validData['listPayload'] ?? [],
            'listDDoS': validData['listDDoS'] ?? [],
            'news': validData['news'] ?? [],
          },
        );
      }
    } catch (_) {
      _showAlert("CONNECTION ERROR", "Failed to connect to the server.", isError: true);
    }

    setState(() => _isLoading = false);
  }

  void _showAlert(String title, String msg, {bool isError = false}) {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        backgroundColor: _surfaceColor.withOpacity(0.98),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(24),
          side: BorderSide(color: isError ? _roseColor.withOpacity(0.4) : _successColor.withOpacity(0.4), width: 1),
        ),
        title: Row(
          children: [
            Icon(isError ? Icons.error_outline_rounded : Icons.check_circle_outline, color: isError ? _roseColor : _successColor, size: 22),
            const SizedBox(width: 12),
            Text(title, style: _cinzel(16, FontWeight.w800, 1.0)),
          ],
        ),
        content: Text(msg, style: _cinzel(13, FontWeight.w500, 0.7)),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text("CLOSE", style: _cinzel(12, FontWeight.w700, 0.8)),
          ),
        ],
      ),
    );
  }

  void _showQrisDialog() {
    showDialog(
      context: context,
      builder: (context) => Dialog(
        backgroundColor: Colors.transparent,
        insetPadding: const EdgeInsets.all(20),
        child: Container(
          decoration: BoxDecoration(
            color: _cardColor,
            borderRadius: BorderRadius.circular(28),
            border: Border.all(color: _glowColor1.withOpacity(0.3), width: 1),
          ),
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: _goldColor.withOpacity(0.15),
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: _goldColor.withOpacity(0.3), width: 1),
                      ),
                      child: Icon(FontAwesomeIcons.qrcode, color: _goldColor, size: 24),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text("QRIS PAYMENT", style: _cinzel(18, FontWeight.w900, 0.9)),
                          const SizedBox(height: 4),
                          Text("Scan to complete payment", style: _cinzel(10, FontWeight.w500, 0.4)),
                        ],
                      ),
                    ),
                    GestureDetector(
                      onTap: () => Navigator.pop(context),
                      child: Icon(Icons.close, color: Colors.white.withOpacity(0.4), size: 24),
                    ),
                  ],
                ),
                const SizedBox(height: 24),
                Container(
                  height: 1,
                  decoration: BoxDecoration(
                    gradient: LinearGradient(colors: [Colors.transparent, _glowColor1.withOpacity(0.12), Colors.transparent]),
                  ),
                ),
                const SizedBox(height: 24),
                Center(
                  child: Text(
                    "NOMINAL: Rp ${_randomNominal.toString().replaceAllMapped(RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'), (Match m) => '${m[1]},')}",
                    style: _cinzel(20, FontWeight.w900, 1.0).copyWith(color: _goldColor),
                  ),
                ),
                const SizedBox(height: 20),
                if (_isGeneratingQris)
                  const Padding(
                    padding: EdgeInsets.all(40),
                    child: CircularProgressIndicator(color: Color(0xFFE0E0F8)),
                  )
                else if (_generatedQris != null)
                  Container(
                    width: 250,
                    height: 250,
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(color: _glowColor1.withOpacity(0.2), width: 1),
                    ),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(20),
                      child: Image.network(
                        _generatedQris!,
                        fit: BoxFit.contain,
                        errorBuilder: (_, __, ___) => Center(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(FontAwesomeIcons.qrcode, color: _goldColor.withOpacity(0.5), size: 64),
                              const SizedBox(height: 12),
                              Text("QRIS GENERATED", style: _cinzel(12, FontWeight.w700, 0.5)),
                            ],
                          ),
                        ),
                      ),
                    ),
                  )
                else
                  Container(
                    width: 250,
                    height: 250,
                    decoration: BoxDecoration(
                      color: _surfaceColor,
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(color: _glowColor1.withOpacity(0.2), width: 1),
                    ),
                    child: Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(FontAwesomeIcons.qrcode, color: _glowColor1.withOpacity(0.3), size: 64),
                          const SizedBox(height: 12),
                          Text("QRIS DEMO MODE", style: _cinzel(12, FontWeight.w700, 0.4)),
                          const SizedBox(height: 8),
                          Text("Rp $_randomNominal", style: _cinzel(14, FontWeight.w800, 0.6)),
                        ],
                      ),
                    ),
                  ),
                const SizedBox(height: 24),
                Row(
                  children: [
                    Expanded(
                      child: GestureDetector(
                        onTap: () {
                          Navigator.pop(context);
                          _generateRandomQris();
                        },
                        child: Container(
                          padding: const EdgeInsets.symmetric(vertical: 12),
                          decoration: BoxDecoration(
                            color: _cardColor,
                            borderRadius: BorderRadius.circular(14),
                            border: Border.all(color: _glowColor1.withOpacity(0.2), width: 1),
                          ),
                          child: Center(
                            child: Text("REFRESH", style: _cinzel(12, FontWeight.w700, 0.7)),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: GestureDetector(
                        onTap: () => Navigator.pop(context),
                        child: Container(
                          padding: const EdgeInsets.symmetric(vertical: 12),
                          decoration: BoxDecoration(
                            gradient: LinearGradient(colors: [_glowColor1, _glowColor2]),
                            borderRadius: BorderRadius.circular(14),
                          ),
                          child: Center(
                            child: Text("CLOSE", style: _cinzel(12, FontWeight.w900, 1.0).copyWith(color: _darkerBg)),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                Text("Scan QRIS to continue", style: _cinzel(9, FontWeight.w500, 0.3)),
              ],
            ),
          ),
        ),
      ),
    );
  }

  void _openTelegramBot() async {
    final url = Uri.parse("https://t.me/tzynotdev_private_id");
    if (await canLaunchUrl(url)) {
      await launchUrl(url, mode: LaunchMode.externalApplication);
    }
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
  void dispose() {
    _videoController.dispose();
    _fadeController.dispose();
    _slideController.dispose();
    _glowController.dispose();
    _pulseController.dispose();
    _rotateController.dispose();
    _breathingController.dispose();
    _userController.dispose();
    _passController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;
    final isWide = size.width > 600;

    return Scaffold(
      backgroundColor: _darkerBg,
      body: Stack(
        children: [
          _buildAnimatedBackground(),
          SafeArea(
            child: FadeTransition(
              opacity: _fadeAnimation,
              child: isWide ? _buildWideLayout() : _buildNarrowLayout(),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAnimatedBackground() {
    return Stack(
      children: [
        Container(color: _darkerBg),
        if (_videoController.value.isInitialized)
          Positioned.fill(
            child: FittedBox(
              fit: BoxFit.cover,
              child: SizedBox(
                width: _videoController.value.size.width,
                height: _videoController.value.size.height,
                child: Opacity(opacity: 0.06, child: VideoPlayer(_videoController)),
              ),
            ),
          ),
        AnimatedBuilder(
          animation: _rotateAnimation,
          builder: (context, child) {
            return Positioned.fill(
              child: CustomPaint(
                painter: GradientOrbsPainter(
                  animation: _rotateAnimation.value,
                  primaryColor: _primaryColor,
                  secondaryColor: _secondaryColor,
                  accentColor: _accentColor,
                ),
              ),
            );
          },
        ),
        Positioned.fill(
          child: Opacity(
            opacity: 0.03,
            child: CustomPaint(painter: HexagonPainter()),
          ),
        ),
        ...List.generate(30, (index) {
          final xPos = (index * 97) % (MediaQuery.of(context).size.width);
          final yPos = (index * 53) % (MediaQuery.of(context).size.height);
          return Positioned(
            left: xPos,
            top: yPos,
            child: AnimatedBuilder(
              animation: _glowAnimation,
              builder: (context, child) {
                return Container(
                  width: 1 + (index % 3),
                  height: 1 + (index % 3),
                  decoration: BoxDecoration(
                    color: _glowColor1.withOpacity(0.07 * _glowAnimation.value),
                    shape: BoxShape.circle,
                  ),
                );
              },
            ),
          );
        }),
        Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [
                Colors.transparent,
                Colors.black.withOpacity(0.5),
                Colors.black.withOpacity(0.9),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildGlassCard({required Widget child}) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(28),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20),
        child: Container(
          decoration: BoxDecoration(
            color: _surfaceColor.withOpacity(0.55),
            borderRadius: BorderRadius.circular(28),
            border: Border.all(color: _glowColor1.withOpacity(0.1), width: 1),
            boxShadow: [
              BoxShadow(color: Colors.black.withOpacity(0.5), blurRadius: 50, spreadRadius: -10, offset: const Offset(0, 24)),
              BoxShadow(color: _glowColor1.withOpacity(0.04), blurRadius: 30),
            ],
          ),
          child: child,
        ),
      ),
    );
  }

  Widget _buildInputField(String hint, TextEditingController controller, IconData icon, {bool isPassword = false}) {
    return Container(
      decoration: BoxDecoration(
        color: _cardColor,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: _glowColor1.withOpacity(0.1), width: 1),
      ),
      child: TextField(
        controller: controller,
        obscureText: isPassword ? _isObscure : false,
        style: _cinzel(13, FontWeight.w600, 0.9),
        cursorColor: _glowColor1,
        decoration: InputDecoration(
          prefixIcon: Icon(icon, color: _glowColor1.withOpacity(0.4), size: 18),
          suffixIcon: isPassword
              ? IconButton(
                  icon: Icon(_isObscure ? Icons.visibility_off_rounded : Icons.visibility_rounded, color: Colors.white.withOpacity(0.2), size: 18),
                  onPressed: () => setState(() => _isObscure = !_isObscure),
                )
              : null,
          hintText: hint,
          hintStyle: _cinzel(12, FontWeight.w500, 0.25),
          filled: true,
          fillColor: Colors.transparent,
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: BorderSide.none),
          enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: BorderSide.none),
          focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: BorderSide(color: _glowColor1.withOpacity(0.3), width: 1)),
          contentPadding: const EdgeInsets.symmetric(vertical: 16, horizontal: 16),
        ),
      ),
    );
  }

  Widget _buildWideLayout() {
    return Row(
      children: [
        Expanded(
          flex: 5,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 40, vertical: 32),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text("WELCOME BACK", style: _cinzel(11, FontWeight.w700, 0.7)),
                const SizedBox(height: 14),
                ShaderMask(
                  shaderCallback: (bounds) => LinearGradient(
                    colors: [_glowColor1, _accentColor, _glowColor2],
                  ).createShader(bounds),
                  child: Text("DEATHXRAT", style: _cinzel(72, FontWeight.w900, 1.0).copyWith(shadows: [Shadow(color: _glowColor1.withOpacity(0.4), blurRadius: 30)])),
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    Container(width: 36, height: 1.5, color: _glowColor2.withOpacity(0.4)),
                    const SizedBox(width: 12),
                    Text("SECURITY PLATFORM", style: _cinzel(11, FontWeight.w600, 0.6)),
                  ],
                ),
                const SizedBox(height: 32),
                Text("Enterprise-grade protection for your digital assets.", style: _cinzel(12, FontWeight.w500, 0.35)),
                const SizedBox(height: 36),
                Row(
                  children: [
                    _buildStatusDot(_successColor, "SECURE"),
                    const SizedBox(width: 18),
                    _buildStatusDot(_accentColor, "ENCRYPTED"),
                    const SizedBox(width: 18),
                    _buildStatusDot(_primaryColor, "AUDITED"),
                  ],
                ),
              ],
            ),
          ),
        ),
        Expanded(
          flex: 4,
          child: Center(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(24),
              child: SlideTransition(
                position: _slideAnimation,
                child: _buildLoginForm(),
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildNarrowLayout() {
    return SingleChildScrollView(
      physics: const BouncingScrollPhysics(),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: _glowColor1.withOpacity(0.06),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: _glowColor1.withOpacity(0.15), width: 1),
                  ),
                  child: Text("v1.0", style: _cinzel(10, FontWeight.w700, 0.7)),
                ),
                _buildStatusDot(_successColor, "ONLINE"),
              ],
            ),
            const SizedBox(height: 44),
            ShaderMask(
              shaderCallback: (bounds) => LinearGradient(
                colors: [_glowColor1, _accentColor, _glowColor2],
              ).createShader(bounds),
              child: Text("DEATHXRAT", style: _cinzel(68, FontWeight.w900, 1.0).copyWith(shadows: [Shadow(color: _glowColor1.withOpacity(0.4), blurRadius: 28)])),
            ),
            const SizedBox(height: 8),
            Text("ACCESS PORTAL", style: _cinzel(9, FontWeight.w700, 0.6)),
            const SizedBox(height: 32),
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: [
                  _buildChip(FontAwesomeIcons.shieldHalved, "SECURE"),
                  const SizedBox(width: 10),
                  _buildChip(FontAwesomeIcons.lock, "ENCRYPTED"),
                  const SizedBox(width: 10),
                  _buildChip(FontAwesomeIcons.clockRotateLeft, "24/7"),
                  const SizedBox(width: 10),
                  GestureDetector(
                    onTap: _showQrisDialog,
                    child: _buildChip(FontAwesomeIcons.qrcode, "QRIS"),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 32),
            SlideTransition(position: _slideAnimation, child: _buildLoginForm()),
            const SizedBox(height: 32),
            Center(
              child: Column(
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      _buildStatusDot(_successColor, "SECURE"),
                      const SizedBox(width: 16),
                      Container(width: 1, height: 12, color: Colors.white.withOpacity(0.07)),
                      const SizedBox(width: 16),
                      _buildStatusDot(_accentColor, "ENCRYPTED"),
                      const SizedBox(width: 16),
                      Container(width: 1, height: 12, color: Colors.white.withOpacity(0.07)),
                      const SizedBox(width: 16),
                      _buildStatusDot(_glowColor1, "AUDITED"),
                    ],
                  ),
                  const SizedBox(height: 14),
                  Text("COSMIC v1.0  •  ADVANCED SECURITY", style: _cinzel(8, FontWeight.w600, 0.1)),
                ],
              ),
            ),
            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }

  Widget _buildChip(IconData icon, String label) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 9),
      decoration: BoxDecoration(
        color: _cardColor,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: _glowColor1.withOpacity(0.12), width: 1),
      ),
      child: Row(
        children: [
          FaIcon(icon, size: 11, color: _glowColor1.withOpacity(0.6)),
          const SizedBox(width: 8),
          Text(label, style: _cinzel(9, FontWeight.w700, 0.7)),
        ],
      ),
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
        const SizedBox(width: 6),
        Text(label, style: _cinzel(9, FontWeight.w700, 0.3)),
      ],
    );
  }

  Widget _buildLoginForm() {
    return _buildGlassCard(
      child: Padding(
        padding: const EdgeInsets.all(28),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                AnimatedBuilder(
                  animation: _pulseAnimation,
                  builder: (context, child) {
                    return Transform.scale(
                      scale: 0.92 + (_pulseAnimation.value - 0.92) * 0.5,
                      child: Container(
                        width: 52,
                        height: 52,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: _cardColor,
                          border: Border.all(color: _glowColor1.withOpacity(0.22), width: 1.5),
                          boxShadow: [BoxShadow(color: _glowColor1.withOpacity(0.25), blurRadius: 24, spreadRadius: 1)],
                        ),
                        child: Center(child: Text("N", style: _cinzel(26, FontWeight.w900, 1.0))),
                      ),
                    );
                  },
                ),
                const SizedBox(width: 16),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text("SIGN IN", style: _cinzel(18, FontWeight.w800, 0.9)),
                    Text("Enter your credentials", style: _cinzel(10, FontWeight.w500, 0.3)),
                  ],
                ),
              ],
            ),
            const SizedBox(height: 24),
            Container(height: 1, decoration: BoxDecoration(gradient: LinearGradient(colors: [Colors.transparent, _glowColor1.withOpacity(0.12), Colors.transparent]))),
            const SizedBox(height: 24),
            Text("USERNAME", style: _cinzel(9, FontWeight.w700, 0.6)),
            const SizedBox(height: 8),
            _buildInputField("Enter username", _userController, Icons.person_outline_rounded),
            const SizedBox(height: 18),
            Text("PASSWORD", style: _cinzel(9, FontWeight.w700, 0.6)),
            const SizedBox(height: 8),
            _buildInputField("Enter password", _passController, Icons.lock_outline_rounded, isPassword: true),
            const SizedBox(height: 28),
            AnimatedBuilder(
              animation: _breathingAnimation,
              builder: (context, child) {
                return Container(
                  width: double.infinity,
                  height: 54,
                  decoration: BoxDecoration(
                    color: _isLoading ? _surfaceColor : _glowColor1.withOpacity(0.92),
                    borderRadius: BorderRadius.circular(14),
                    boxShadow: _isLoading ? [] : [BoxShadow(color: _glowColor1.withOpacity(0.3 * _breathingAnimation.value), blurRadius: 30, offset: const Offset(0, 8))],
                  ),
                  child: Material(
                    color: Colors.transparent,
                    borderRadius: BorderRadius.circular(14),
                    child: InkWell(
                      borderRadius: BorderRadius.circular(14),
                      onTap: _isLoading ? null : _login,
                      child: Center(
                        child: _isLoading
                            ? SizedBox(width: 22, height: 22, child: CircularProgressIndicator(color: _glowColor1, strokeWidth: 2))
                            : Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Text("AUTHENTICATE", style: _cinzel(13, FontWeight.w900, 1.0).copyWith(color: _darkerBg)),
                                  const SizedBox(width: 12),
                                  Container(width: 26, height: 26, decoration: BoxDecoration(color: _darkerBg.withOpacity(0.15), borderRadius: BorderRadius.circular(7)), child: Icon(Icons.arrow_forward_rounded, color: _darkerBg, size: 14)),
                                ],
                              ),
                      ),
                    ),
                  ),
                );
              },
            ),
            const SizedBox(height: 20),
            Center(
              child: GestureDetector(
                onTap: _openTelegramBot,
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      padding: const EdgeInsets.all(7),
                      decoration: BoxDecoration(
                        color: _glowColor1.withOpacity(0.07),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: FaIcon(FontAwesomeIcons.telegramPlane, color: _glowColor1.withOpacity(0.6), size: 12),
                    ),
                    const SizedBox(width: 10),
                    Text("Need assistance?", style: _cinzel(11, FontWeight.w500, 0.45)),
                    Icon(Icons.chevron_right_rounded, color: _glowColor1.withOpacity(0.3), size: 14),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 20),
            Container(height: 1, decoration: BoxDecoration(gradient: LinearGradient(colors: [Colors.transparent, Colors.white.withOpacity(0.05), Colors.transparent]))),
            const SizedBox(height: 14),
            Center(child: Text("COSMIC v1.0  •  ENCRYPTED", style: _cinzel(8, FontWeight.w600, 0.12))),
          ],
        ),
      ),
    );
  }
}

class HexagonPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.white.withOpacity(0.04)
      ..strokeWidth = 0.5
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
      if (i == 0) path.moveTo(x, y);
      else path.lineTo(x, y);
    }
    path.close();
    canvas.drawPath(path, paint);
  }
  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

class GradientOrbsPainter extends CustomPainter {
  final double animation;
  final Color primaryColor;
  final Color secondaryColor;
  final Color accentColor;
  GradientOrbsPainter({required this.animation, required this.primaryColor, required this.secondaryColor, required this.accentColor});
  @override
  void paint(Canvas canvas, Size size) {
    final orb1Paint = Paint()..shader = RadialGradient(colors: [primaryColor.withOpacity(0.07), Colors.transparent]).createShader(Rect.fromCircle(center: Offset(size.width * 0.15, size.height * 0.2), radius: 160));
    canvas.drawCircle(Offset(size.width * 0.15, size.height * 0.2), 160, orb1Paint);
    final orb2Paint = Paint()..shader = RadialGradient(colors: [secondaryColor.withOpacity(0.05), Colors.transparent]).createShader(Rect.fromCircle(center: Offset(size.width * 0.88, size.height * 0.3), radius: 140));
    canvas.drawCircle(Offset(size.width * 0.88, size.height * 0.3), 140, orb2Paint);
    final orb3Paint = Paint()..shader = RadialGradient(colors: [accentColor.withOpacity(0.04 + animation * 0.03), Colors.transparent]).createShader(Rect.fromCircle(center: Offset(size.width * 0.5, size.height * 0.88), radius: 180));
    canvas.drawCircle(Offset(size.width * 0.5, size.height * 0.88), 180, orb3Paint);
  }
  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}