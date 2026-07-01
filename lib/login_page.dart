import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:url_launcher/url_launcher.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:device_info_plus/device_info_plus.dart';
import 'splash.dart';

const String baseUrl = "http://saitama.omdhancivok.my.id:2001";

class LoginPage extends StatefulWidget {
  const LoginPage({super.key});

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage>
    with SingleTickerProviderStateMixin {
  final userController = TextEditingController();
  final passController = TextEditingController();
  final _formKey = GlobalKey<FormState>();

  bool isLoading = false;
  bool _obscurePassword = true;
  String? androidId;

  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation;

  // Warna tema biru (sesuai landing)
  static const Color _primaryBlue = Color(0xFF0A66C2);
  static const Color _deepBlue = Color(0xFF003366);
  static const Color _lightBlue = Color(0xFF4B9FFF);
  static const Color _glowBlue = Color(0xFF1E88E5);
  static const Color _cardBg = Color(0xFF0F172A);
  static const Color _textLight = Color(0xFFF1F5F9);
  static const Color _textDim = Color(0xFF94A3B8);

  @override
  void initState() {
    super.initState();
    _initAnimations();
    _initLogin();
  }

  void _initAnimations() {
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 900),
    )..forward();

    _fadeAnimation = Tween<double>(begin: 0, end: 1).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeOut),
    );
    _slideAnimation = Tween<Offset>(begin: const Offset(0, 0.15), end: Offset.zero)
        .animate(CurvedAnimation(parent: _animationController, curve: Curves.easeOutCubic));
  }

  Future<void> _initLogin() async {
    androidId = await _getAndroidId();

    final prefs = await SharedPreferences.getInstance();
    final savedUser = prefs.getString("username");
    final savedPass = prefs.getString("password");
    final savedKey = prefs.getString("key");

    if (savedUser != null && savedPass != null && savedKey != null) {
      final uri = Uri.parse(
          "$baseUrl/myInfo?username=$savedUser&password=$savedPass&androidId=$androidId&key=$savedKey");

      try {
        final res = await http.get(uri);
        final data = jsonDecode(res.body);

        if (data['valid'] == true) {
          if (!mounted) return;
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(
              builder: (_) => SplashScreen(
                username: savedUser,
                password: savedPass,
                role: data['role'],
                sessionKey: data['key'],
                expiredDate: data['expiredDate'],
                listBug: (data['listBug'] as List? ?? [])
                    .map((e) => Map<String, dynamic>.from(e as Map))
                    .toList(),
                listDoos: (data['listDDoS'] as List? ?? [])
                    .map((e) => Map<String, dynamic>.from(e as Map))
                    .toList(),
                news: (data['news'] as List? ?? [])
                    .map((e) => Map<String, dynamic>.from(e as Map))
                    .toList(),
              ),
            ),
          );
        }
      } catch (_) {}
    }
  }

  Future<String> _getAndroidId() async {
    final deviceInfo = DeviceInfoPlugin();
    final android = await deviceInfo.androidInfo;
    return android.id ?? "unknown_device";
  }

  Future<void> _login() async {
    if (!_formKey.currentState!.validate()) return;

    final username = userController.text.trim();
    final password = passController.text.trim();

    setState(() => isLoading = true);

    try {
      final validate = await http.post(
        Uri.parse("$baseUrl/validate"),
        body: {
          "username": username,
          "password": password,
          "androidId": androidId ?? "unknown_device",
        },
      );

      final validData = jsonDecode(validate.body);
      debugPrint("VALIDATE RESPONSE => $validData");

      if (validData['expired'] == true) {
        _showPopup(
          title: "⏳ Access Expired",
          message: "Your access has expired.\nPlease renew it.",
          color: Colors.orange,
          showContact: true,
        );
      } else if (validData['valid'] != true) {
        _showPopup(
          title: "❌ Login Failed",
          message: "Invalid username or password.",
          color: Colors.red,
        );
      } else {
        final prefs = await SharedPreferences.getInstance();
        prefs.setString("username", username);
        prefs.setString("password", password);
        prefs.setString("key", validData['key']);

        if (!mounted) return;
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
            builder: (_) => SplashScreen(
              username: username,
              password: password,
              role: validData['role'],
              sessionKey: validData['key'],
              expiredDate: validData['expiredDate'],
              listBug: (validData['listBug'] as List? ?? [])
                  .map((e) => Map<String, dynamic>.from(e as Map))
                  .toList(),
              listDoos: (validData['listDDoS'] as List? ?? [])
                  .map((e) => Map<String, dynamic>.from(e as Map))
                  .toList(),
              news: (validData['news'] as List? ?? [])
                  .map((e) => Map<String, dynamic>.from(e as Map))
                  .toList(),
            ),
          ),
        );
      }
    } catch (e) {
      _showPopup(
        title: "⚠️ Connection Error",
        message: "Failed to connect to the server.\nPlease check your internet connection.",
        color: _primaryBlue,
      );
    }

    if (mounted) setState(() => isLoading = false);
  }

  void _showPopup({
    required String title,
    required String message,
    Color color = Colors.red,
    bool showContact = false,
  }) {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        backgroundColor: Colors.black.withOpacity(0.85),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        title: Text(
          title,
          style: TextStyle(color: color, fontWeight: FontWeight.bold, fontSize: 18),
        ),
        content: Text(
          message,
          style: const TextStyle(color: Colors.white70, fontSize: 14),
        ),
        actions: [
          if (showContact)
            TextButton(
              onPressed: () async {
                final uri = Uri.parse("https://t.me/vanesha31");
                await launchUrl(uri, mode: LaunchMode.externalApplication);
              },
              child: Text("Contact Admin", style: TextStyle(color: _lightBlue)),
            ),
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text("Close", style: TextStyle(color: Colors.white54)),
          ),
        ],
      ),
    );
  }

  @override
  void dispose() {
    _animationController.dispose();
    userController.dispose();
    passController.dispose();
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
        extendBodyBehindAppBar: true,
        appBar: AppBar(
          backgroundColor: Colors.transparent,
          elevation: 0,
          systemOverlayStyle: const SystemUiOverlayStyle(
            statusBarColor: Colors.transparent,
            statusBarIconBrightness: Brightness.light,
          ),
          leading: IconButton(
            icon: const Icon(Icons.arrow_back_ios, color: Colors.white),
            onPressed: () => Navigator.pop(context),
          ),
        ),
        body: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [
                _deepBlue,
                _primaryBlue,
                const Color(0xFF0A2540),
              ],
              stops: const [0.0, 0.5, 1.0],
            ),
          ),
          child: SafeArea(
            child: FadeTransition(
              opacity: _fadeAnimation,
              child: SlideTransition(
                position: _slideAnimation,
                child: Center(
                  child: SingleChildScrollView(
                    physics: const BouncingScrollPhysics(),
                    padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 32),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        // Logo glassmorphism
                        Container(
                          width: 100,
                          height: 100,
                          decoration: BoxDecoration(
                            gradient: const LinearGradient(
                              colors: [_primaryBlue, _lightBlue],
                              begin: Alignment.topLeft,
                              end: Alignment.bottomRight,
                            ),
                            borderRadius: BorderRadius.circular(30),
                            boxShadow: [
                              BoxShadow(
                                color: _glowBlue.withOpacity(0.5),
                                blurRadius: 25,
                                spreadRadius: 2,
                                offset: const Offset(0, 8),
                              ),
                            ],
                          ),
                          child: ClipRRect(
                            borderRadius: BorderRadius.circular(30),
                            child: Image.asset(
                              'assets/images/logo.jpg',
                              fit: BoxFit.cover,
                              errorBuilder: (context, error, stackTrace) {
                                return const Icon(
                                  Icons.security,
                                  color: Colors.white,
                                  size: 50,
                                );
                              },
                            ),
                          ),
                        ),
                        const SizedBox(height: 28),
                        // Title dengan efek gradien teks
                        ShaderMask(
                          shaderCallback: (Rect bounds) {
                            return const LinearGradient(
                              colors: [Color(0xFF4B9FFF), Color(0xFF0A66C2)],
                              begin: Alignment.topLeft,
                              end: Alignment.bottomRight,
                            ).createShader(bounds);
                          },
                          child: const Text(
                            'WELCOME BACK',
                            style: TextStyle(
                              fontSize: 28,
                              fontWeight: FontWeight.w800,
                              letterSpacing: 2,
                              color: Colors.white,
                            ),
                          ),
                        ),
                        const SizedBox(height: 8),
                        const Text(
                          'Sign in to continue',
                          style: TextStyle(color: _textDim, fontSize: 14, letterSpacing: 0.5),
                        ),
                        const SizedBox(height: 48),
                        // Form Card
                        Container(
                          padding: const EdgeInsets.all(24),
                          decoration: BoxDecoration(
                            color: _cardBg.withOpacity(0.6),
                            borderRadius: BorderRadius.circular(32),
                            border: Border.all(color: Colors.white.withOpacity(0.08), width: 1),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withOpacity(0.3),
                                blurRadius: 20,
                                offset: const Offset(0, 8),
                              ),
                            ],
                          ),
                          child: Form(
                            key: _formKey,
                            child: Column(
                              children: [
                                _buildTextField(
                                  controller: userController,
                                  label: 'Username',
                                  icon: Icons.person_outline,
                                ),
                                const SizedBox(height: 20),
                                _buildTextField(
                                  controller: passController,
                                  label: 'Password',
                                  icon: Icons.lock_outline,
                                  isPassword: true,
                                ),
                                const SizedBox(height: 32),
                                _buildLoginButton(),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    required IconData icon,
    bool isPassword = false,
  }) {
    return TextFormField(
      controller: controller,
      obscureText: isPassword ? _obscurePassword : false,
      style: const TextStyle(color: _textLight, fontSize: 16),
      decoration: InputDecoration(
        labelText: label,
        labelStyle: const TextStyle(color: _textDim),
        prefixIcon: Icon(icon, color: _lightBlue, size: 22),
        suffixIcon: isPassword
            ? IconButton(
                icon: Icon(
                  _obscurePassword ? Icons.visibility_off : Icons.visibility,
                  color: _textDim,
                ),
                onPressed: () => setState(() => _obscurePassword = !_obscurePassword),
              )
            : null,
        filled: true,
        fillColor: Colors.white.withOpacity(0.05),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: BorderSide(color: Colors.white.withOpacity(0.15), width: 1),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: BorderSide(color: _lightBlue, width: 1.5),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: const BorderSide(color: Colors.redAccent, width: 1),
        ),
        focusedErrorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: const BorderSide(color: Colors.redAccent, width: 1.5),
        ),
      ),
      validator: (value) => (value == null || value.isEmpty) ? 'Please enter $label' : null,
    );
  }

  Widget _buildLoginButton() {
    return SizedBox(
      width: double.infinity,
      height: 56,
      child: ElevatedButton(
        onPressed: isLoading ? null : _login,
        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.transparent,
          shadowColor: Colors.transparent,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(40)),
          padding: EdgeInsets.zero,
        ),
        child: Ink(
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              colors: [_primaryBlue, _lightBlue],
              begin: Alignment.centerLeft,
              end: Alignment.centerRight,
            ),
            borderRadius: BorderRadius.circular(40),
            boxShadow: [
              BoxShadow(
                color: _glowBlue.withOpacity(0.5),
                blurRadius: 15,
                offset: const Offset(0, 6),
              ),
            ],
          ),
          child: Container(
            alignment: Alignment.center,
            child: isLoading
                ? const SizedBox(
                    height: 24,
                    width: 24,
                    child: CircularProgressIndicator(
                      strokeWidth: 2.5,
                      color: Colors.white,
                    ),
                  )
                : const Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.login, color: Colors.white, size: 22),
                      SizedBox(width: 12),
                      Text(
                        'Sign In',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                          letterSpacing: 0.8,
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