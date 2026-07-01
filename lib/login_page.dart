import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:url_launcher/url_launcher.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:device_info_plus/device_info_plus.dart';
import 'splash.dart';

const String baseUrl = "https://panel-private-yanz.fansjkt48.web.id:10918";

class LoginPage extends StatefulWidget {
  const LoginPage({super.key});

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage>
    with TickerProviderStateMixin {
  final userController = TextEditingController();
  final passController = TextEditingController();
  final _formKey = GlobalKey<FormState>();

  bool isLoading = false;
  bool _obscurePassword = true;
  bool _navigated = false;
  String? androidId;

  late AnimationController _slideController;
  late AnimationController _rotateController;
  late Animation<Offset> _slideAnim;
  late Animation<double> _rotateAnim;

  @override
  void initState() {
    super.initState();
    _initAnim();
    _initLogin();
  }

  void _initAnim() {
    _slideController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1000),
    )..forward();

    _rotateController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 20),
    )..repeat();

    _slideAnim = Tween<Offset>(
      begin: const Offset(0, 1),
      end: Offset.zero,
    ).animate(
      CurvedAnimation(
        parent: _slideController,
        curve: Curves.easeOutCubic,
      ),
    );

    _rotateAnim =
        Tween<double>(begin: 0, end: 1).animate(_rotateController);
  }

  Future<void> _initLogin() async {
    androidId = await _getAndroidId();

    final prefs = await SharedPreferences.getInstance();
    final savedUser = prefs.getString("username");
    final savedPass = prefs.getString("password");
    final savedKey = prefs.getString("key");

    if (savedUser == null || savedPass == null || savedKey == null) return;

    try {
      final res = await http.get(Uri.parse(
        "$baseUrl/myInfo"
        "?username=$savedUser"
        "&password=$savedPass"
        "&androidId=$androidId"
        "&key=$savedKey",
      ));

      final data = jsonDecode(res.body);
      if (data['valid'] == true && mounted && !_navigated) {
        _goToSplash(savedUser, savedPass, data);
      }
    } catch (_) {}
  }

  Future<String> _getAndroidId() async {
    final deviceInfo = DeviceInfoPlugin();
    final android = await deviceInfo.androidInfo;
    return android.id ?? "unknown_device";
  }

  Future<void> login() async {
    if (!_formKey.currentState!.validate()) return;

    final username = userController.text.trim();
    final password = passController.text.trim();

    setState(() => isLoading = true);

    try {
      final res = await http.post(
        Uri.parse("$baseUrl/validate"),
        body: {
          "username": username,
          "password": password,
          "androidId": androidId ?? "unknown_device",
        },
      );

      final data = jsonDecode(res.body);
      if (!mounted) return;

      if (data['expired'] == true) {
        _showPopup(
          title: "⏳ Access Expired",
          message: "Your access has expired.\nPlease renew it.",
          color: Colors.amber,
          showContact: true,
        );
      } else if (data['valid'] != true) {
        _showPopup(
          title: "❌ Login Failed",
          message: "Invalid username or password.",
          color: Colors.redAccent,
        );
      } else if (!_navigated) {
        final prefs = await SharedPreferences.getInstance();
        prefs.setString("username", username);
        prefs.setString("password", password);
        prefs.setString("key", data['key']);

        _goToSplash(username, password, data);
      }
    } catch (_) {
      if (!mounted) return;
      _showPopup(
        title: "⚠️ Connection Error",
        message:
            "Failed to connect to the server.\nPlease check your connection.",
        color: Colors.teal,
      );
    } finally {
      if (mounted) setState(() => isLoading = false);
    }
  }

  void _goToSplash(String user, String pass, Map<String, dynamic> data) {
    _navigated = true;
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(
        builder: (_) => SplashScreen(
          username: user,
          password: pass,
          role: data['role'],
          sessionKey: data['key'],
          expiredDate: data['expiredDate'],
          listBug: (data['listBug'] as List? ?? [])
              .map((e) => Map<String, dynamic>.from(e))
              .toList(),
          listDoos: (data['listDoos'] as List? ?? [])
              .map((e) => Map<String, dynamic>.from(e))
              .toList(),
        ),
      ),
    );
  }

  void _showPopup({
    required String title,
    required String message,
    Color color = Colors.redAccent,
    bool showContact = false,
  }) {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        backgroundColor: const Color(0xFF1A1A2E),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(24),
        ),
        title: Text(
          title,
          style: TextStyle(color: color, fontWeight: FontWeight.bold),
        ),
        content: Text(
          message,
          style: const TextStyle(color: Colors.white70),
        ),
        actions: [
          if (showContact)
            TextButton(
              onPressed: () async {
                await launchUrl(
                  Uri.parse("https://t.me/KaiiOfficial"),
                  mode: LaunchMode.externalApplication,
                );
              },
              child: const Text("Contact Admin"),
            ),
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text("Close"),
          ),
        ],
      ),
    );
  }

  @override
  void dispose() {
    _slideController.dispose();
    _rotateController.dispose();
    userController.dispose();
    passController.dispose();
    super.dispose();
  }

  // ======================= UI BUILD METHOD (ASLI LU) =======================
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [
              Color(0xFF0F3460),
              Color(0xFF16213E),
              Color(0xFF0F3460)
            ],
            begin: Alignment.centerLeft,
            end: Alignment.centerRight,
          ),
        ),
        child: Stack(
          children: [
            Positioned(
              top: -100,
              left: -100,
              child: AnimatedBuilder(
                animation: _rotateAnim,
                builder: (context, child) {
                  return Transform.rotate(
                    angle: _rotateAnim.value * 2 * 3.14159,
                    child: Container(
                      width: 300,
                      height: 300,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        border: Border.all(
                          color: Colors.teal.withOpacity(0.1),
                          width: 2,
                        ),
                      ),
                    ),
                  );
                },
              ),
            ),
            Positioned(
              bottom: -150,
              right: -150,
              child: AnimatedBuilder(
                animation: _rotateAnim,
                builder: (context, child) {
                  return Transform.rotate(
                    angle: -_rotateAnim.value * 2 * 3.14159,
                    child: Container(
                      width: 400,
                      height: 400,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        border: Border.all(
                          color: Colors.blue.withOpacity(0.1),
                          width: 2,
                        ),
                      ),
                    ),
                  );
                },
              ),
            ),
            Center(
              child: SlideTransition(
                position: _slideAnim,
                child: Container(
                  margin: const EdgeInsets.all(24),
                  padding: const EdgeInsets.all(32),
                  decoration: BoxDecoration(
                    color: Colors.black.withOpacity(0.4),
                    borderRadius: BorderRadius.circular(24),
                    border: Border.all(
                      color: Colors.teal.withOpacity(0.3),
                      width: 1,
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.5),
                        blurRadius: 20,
                        spreadRadius: 5,
                      ),
                    ],
                  ),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Container(
                        width: 80,
                        height: 80,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          gradient: LinearGradient(
                            colors: [Colors.teal, Colors.blue],
                          ),
                        ),
                        child: ClipOval(
                          child: Image.asset(
                            'assets/images/logo.jpg',
                            fit: BoxFit.cover,
                          ),
                        ),
                      ),
                      const SizedBox(height: 24),
                      const Text(
                        "RavenGetSuzo",
                        style: TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                      const SizedBox(height: 8),
                      const Text(
                        "Please Log-in",
                        style: TextStyle(
                          color: Colors.white54,
                          fontSize: 14,
                        ),
                      ),
                      const SizedBox(height: 32),
                      Form(
                        key: _formKey,
                        child: Column(
                          children: [
                            _buildMinimalInput(
                                userController, "Username", Icons.person),
                            const SizedBox(height: 16),
                            _buildMinimalInput(
                              passController,
                              "Password",
                              Icons.lock,
                              isPassword: true,
                            ),
                            const SizedBox(height: 32),
                            _buildMinimalButton(),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMinimalInput(
    TextEditingController controller,
    String label,
    IconData icon, {
    bool isPassword = false,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.05),
        borderRadius: BorderRadius.circular(12),
      ),
      child: TextFormField(
        controller: controller,
        obscureText: isPassword ? _obscurePassword : false,
        style: const TextStyle(color: Colors.white),
        decoration: InputDecoration(
          hintText: label,
          hintStyle: const TextStyle(color: Colors.white38),
          prefixIcon: Icon(icon, color: Colors.teal.withOpacity(0.7)),
          suffixIcon: isPassword
              ? IconButton(
                  icon: Icon(
                    _obscurePassword
                        ? Icons.visibility_off
                        : Icons.visibility,
                    color: Colors.white38,
                  ),
                  onPressed: () {
                    setState(() {
                      _obscurePassword = !_obscurePassword;
                    });
                  },
                )
              : null,
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide.none,
          ),
        ),
      ),
    );
  }

  Widget _buildMinimalButton() {
    return Container(
      width: double.infinity,
      height: 50,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(12),
        gradient: const LinearGradient(
          colors: [Colors.teal, Colors.blue],
        ),
      ),
      child: ElevatedButton(
        onPressed: isLoading ? null : login,
        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.transparent,
          elevation: 0,
        ),
        child: isLoading
            ? const CircularProgressIndicator(
                strokeWidth: 2,
                valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
              )
            : const Text(
                "LOGIN",
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  letterSpacing: 1.2,
                ),
              ),
      ),
    );
  }
}