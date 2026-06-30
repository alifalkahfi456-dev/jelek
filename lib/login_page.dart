import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:url_launcher/url_launcher.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:device_info_plus/device_info_plus.dart';
import 'splash.dart';

const String baseUrl = "http://senzlinodepriv.senzhosting.my.id:10791";

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
  bool _showUpdateDialog = false;
  Map<String, dynamic>? _updateInfo;
  bool _isUnderMaintenance = false;

  late AnimationController _controller;
  late Animation<double> _fadeAnim;
  late Animation<double> _scaleAnim;
  late AnimationController _glowController;

  // --- Red Cyberpunk Gaming Theme Colors ---
  final Color bgDeep = const Color(0xFF0A0505);
  final Color bgCard = const Color(0xFF1A0A0A);
  final Color neonRed = const Color(0xFFFF1744);
  final Color darkRed = const Color(0xFFC62828);
  final Color bloodRed = const Color(0xFF8B0000);
  final Color crimsonRed = const Color(0xFFDC143C);
  final Color darkBg = const Color(0xFF1A0808);
  final Color textPrimary = const Color(0xFFE0E0E0);
  final Color textSecondary = const Color(0xFFB0B0C0);

  @override
  void initState() {
    super.initState();
    _initAnim();
    initLogin();
    _checkForUpdates();
  }

  void _initAnim() {
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1000),
    )..forward();
    _glowController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
    )..repeat();
    _fadeAnim = CurvedAnimation(parent: _controller, curve: Curves.easeOut);
    _scaleAnim = CurvedAnimation(parent: _controller, curve: Curves.easeOutBack);
  }

  Future<void> _checkForUpdates() async {
    try {
      final response = await http.get(
        Uri.parse("$baseUrl/checkUpdate"),
      ).timeout(const Duration(seconds: 5));
      
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (data['show_update'] == true) {
          bool isValid = true;
          if (data['expiredDate'] != null && data['expiredDate'].toString().isNotEmpty) {
            try {
              final expired = DateTime.parse(data['expiredDate']);
              final now = DateTime.now();
              isValid = now.isBefore(expired) || now.isAtSameMomentAs(expired);
            } catch (e) {
              isValid = true;
            }
          }
          
          if (isValid && mounted) {
            setState(() {
              _showUpdateDialog = true;
              _isUnderMaintenance = true;
              _updateInfo = data;
            });
            _showUpdateDialogWidget();
          }
        }
      }
    } catch (e) {
      print('Error checking update: $e');
    }
  }

  void _showUpdateDialogWidget() {
    if (!_showUpdateDialog || _updateInfo == null) return;
    
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => WillPopScope(
        onWillPop: () async => false,
        child: _buildUpdateDialog(),
      ),
    );
  }

  Widget _buildUpdateDialog() {
    return Dialog(
      backgroundColor: Colors.transparent,
      elevation: 0,
      child: TweenAnimationBuilder(
        duration: const Duration(milliseconds: 600),
        tween: Tween<double>(begin: 0, end: 1),
        builder: (context, double value, child) {
          return Transform.scale(
            scale: value,
            child: Opacity(
              opacity: value,
              child: child,
            ),
          );
        },
        child: Container(
          margin: const EdgeInsets.all(20),
          padding: const EdgeInsets.all(28),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                bgCard,
                bgDeep,
                darkBg,
              ],
            ),
            borderRadius: BorderRadius.circular(28),
            border: Border.all(
              width: 2,
              color: neonRed,
            ),
            boxShadow: [
              BoxShadow(
                color: neonRed.withOpacity(0.3),
                blurRadius: 40,
                spreadRadius: 5,
                offset: const Offset(0, 0),
              ),
              BoxShadow(
                color: darkRed.withOpacity(0.2),
                blurRadius: 60,
                spreadRadius: 10,
                offset: const Offset(0, 0),
              ),
            ],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Animated red icon
              AnimatedBuilder(
                animation: _glowController,
                builder: (context, child) {
                  return Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [
                          darkRed.withOpacity(0.2 + _glowController.value * 0.3),
                          neonRed.withOpacity(0.2 + _glowController.value * 0.3),
                        ],
                      ),
                      shape: BoxShape.circle,
                      boxShadow: [
                        BoxShadow(
                          color: neonRed.withOpacity(0.5 + _glowController.value * 0.3),
                          blurRadius: 30,
                          spreadRadius: 10,
                        ),
                      ],
                    ),
                    child: ShaderMask(
                      shaderCallback: (bounds) => const LinearGradient(
                        colors: [Color(0xFFFF1744), Color(0xFFC62828)],
                      ).createShader(bounds),
                      child: const Icon(
                        Icons.build_circle_outlined,
                        color: Colors.white,
                        size: 52,
                      ),
                    ),
                  );
                },
              ),
              const SizedBox(height: 24),
              
              // Glowing title
              ShaderMask(
                shaderCallback: (bounds) => const LinearGradient(
                  colors: [Color(0xFFFF1744), Color(0xFFC62828), Color(0xFFFF1744)],
                  stops: [0, 0.5, 1],
                ).createShader(bounds),
                child: const Text(
                  "More Updates!",
                  style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                    letterSpacing: 3,
                    fontFamily: 'Orbitron',
                  ),
                ),
              ),
              const SizedBox(height: 12),
              
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.centerLeft,
                    end: Alignment.centerRight,
                    colors: [
                      darkRed.withOpacity(0.1),
                      neonRed.withOpacity(0.1),
                    ],
                  ),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(
                    color: neonRed,
                    width: 1,
                  ),
                ),
                child: Text(
                  _updateInfo?['message'] ?? "System undergoing upgrade\nNew features & enhanced security coming soon.",
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: textPrimary,
                    fontSize: 14,
                    height: 1.5,
                    fontFamily: 'ShareTechMono',
                  ),
                ),
              ),
              const SizedBox(height: 24),
              
              // Version badge
              if (_updateInfo?['version'] != null)
                Container(
                  margin: const EdgeInsets.only(bottom: 20),
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [darkRed, neonRed],
                    ),
                    borderRadius: BorderRadius.circular(30),
                    boxShadow: [
                      BoxShadow(
                        color: neonRed.withOpacity(0.5),
                        blurRadius: 10,
                      ),
                    ],
                  ),
                  child: Text(
                    "Latest Version ${_updateInfo!['version']}",
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                      fontSize: 11,
                      letterSpacing: 1.5,
                    ),
                  ),
                ),
              
              // Buttons
              Row(
                children: [
                  Expanded(
                    child: _buildCyberButton(
                      text: "Info",
                      icon: Icons.info_outline,
                      gradient: const LinearGradient(
                        colors: [Color(0xFF8B0000), Color(0xFFC62828)],
                      ),
                      onTap: () async {
                        final infoUrl = _updateInfo?['infoUrl'] ?? "https://t.me/RizzXybsRols;
                        await launchUrl(
                          Uri.parse(infoUrl),
                          mode: LaunchMode.externalApplication,
                        );
                      },
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: _buildCyberButton(
                      text: "Update Now",
                      icon: Icons.download_rounded,
                      gradient: const LinearGradient(
                        colors: [Color(0xFFFF1744), Color(0xFFC62828)],
                      ),
                      onTap: () async {
                        final downloadUrl = _updateInfo?['downloadUrl'] ?? "https://t.me/RizzXybsRols;
                        await launchUrl(
                          Uri.parse(downloadUrl),
                          mode: LaunchMode.externalApplication,
                        );
                      },
                    ),
                  ),
                ],
              ),
              
              const SizedBox(height: 20),
              
              // Status indicator
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: neonRed.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      width: 8,
                      height: 8,
                      decoration: BoxDecoration(
                        color: neonRed,
                        shape: BoxShape.circle,
                        boxShadow: [
                          BoxShadow(
                            color: neonRed.withOpacity(0.8),
                            blurRadius: 8,
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      "Access Blocked",
                      style: TextStyle(
                        color: neonRed,
                        fontSize: 10,
                        fontWeight: FontWeight.bold,
                        letterSpacing: 1,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildCyberButton({
    required String text,
    required IconData icon,
    required LinearGradient gradient,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        height: 48,
        decoration: BoxDecoration(
          gradient: gradient,
          borderRadius: BorderRadius.circular(12),
          boxShadow: [
            BoxShadow(
              color: neonRed.withOpacity(0.4),
              blurRadius: 15,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, color: Colors.white, size: 18),
            const SizedBox(width: 8),
            Text(
              text,
              style: const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
                fontSize: 12,
                letterSpacing: 1,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> initLogin() async {
    // Cek maintenance dulu
    if (_isUnderMaintenance) return;
    
    androidId = await getAndroidId();

    final prefs = await SharedPreferences.getInstance();
    final savedUser = prefs.getString("username");
    final savedPass = prefs.getString("password");
    final savedKey = prefs.getString("key");

    if (savedUser != null && savedPass != null && savedKey != null && !_isUnderMaintenance) {
      final uri = Uri.parse(
          "$baseUrl/myInfo?username=$savedUser&password=$savedPass&androidId=$androidId&key=$savedKey");

      try {
        final res = await http.get(uri);
        final data = jsonDecode(res.body);

        if (data['valid'] == true && mounted) {
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

  Future<String> getAndroidId() async {
    final deviceInfo = DeviceInfoPlugin();
    final android = await deviceInfo.androidInfo;
    return android.id ?? "unknown_device";
  }

  Future<void> login() async {
    if (_isUnderMaintenance) {
      _showMaintenanceBlockedDialog();
      return;
    }
    
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

      if (validData['expired'] == true) {
        _showPopup(
          title: "‼️ Access Expired",
          message: "Your access has expired.\nPlease renew your subscription.",
          color: neonRed,
          showContact: true,
        );
      } else if (validData['valid'] != true) {
        final String errorMsg = (validData['message'] ?? "").toLowerCase();

        if (errorMsg.contains("perangkat") ||
            errorMsg.contains("device") ||
            errorMsg.contains("another")) {
          _showPopup(
            title: "‼️ Active Session",
            message: "Account is logged in on another device.\nPlease logout first.",
            color: const Color(0xFF8B0000),
            showContact: false,
          );
        } else {
          _showPopup(
            title: "⚠️ Log-In Failed",
            message: "Invalid username or password.",
            color: neonRed,
            showContact: false,
          );
        }
      } else {
        final prefs = await SharedPreferences.getInstance();
        prefs.setString("username", username);
        prefs.setString("password", password);
        prefs.setString("key", validData['key']);

        if (mounted) {
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
      }
    } catch (e) {
      _showPopup(
        title: "⚠️ Connection Error",
        message: "Failed to connect to server.\nCheck your internet connection.",
        color: neonRed,
        showContact: false,
      );
    }

    setState(() => isLoading = false);
  }

  void _showMaintenanceBlockedDialog() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => AlertDialog(
        backgroundColor: bgCard,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
          side: BorderSide(color: neonRed, width: 2),
        ),
        title: Row(
          children: [
            Icon(Icons.gpp_bad, color: neonRed),
            const SizedBox(width: 10),
            Text(
              "Access Denied",
              style: TextStyle(color: neonRed, fontWeight: FontWeight.bold),
            ),
          ],
        ),
        content: Text(
          "System is under maintenance.\nPlease update the app to continue.",
          style: TextStyle(color: textPrimary),
        ),
        actions: [
          TextButton(
            onPressed: () async {
              final downloadUrl = _updateInfo?['downloadUrl'] ?? "https://t.me/RizzXybsRols;
              await launchUrl(
                Uri.parse(downloadUrl),
                mode: LaunchMode.externalApplication,
              );
            },
            child: Text(
              "Update",
              style: TextStyle(color: neonRed, fontWeight: FontWeight.bold),
            ),
          ),
        ],
      ),
    );
  }

  void _showPopup({
    required String title,
    required String message,
    Color? color,
    bool showContact = false,
  }) {
    final popupColor = color ?? neonRed;
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        backgroundColor: bgCard,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
          side: BorderSide(color: popupColor, width: 1.5),
        ),
        title: Text(
          title,
          style: TextStyle(color: popupColor, fontWeight: FontWeight.bold, fontSize: 18, letterSpacing: 1),
        ),
        content: Text(
          message,
          style: TextStyle(color: textSecondary, fontSize: 14),
        ),
        actions: [
          if (showContact)
            TextButton(
              onPressed: () async {
                await launchUrl(Uri.parse("https://t.me/RizzXybsRols"),
                    mode: LaunchMode.externalApplication);
              },
              child: Text(
                "Contact",
                style: TextStyle(color: neonRed, fontWeight: FontWeight.bold),
              ),
            ),
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(
              "Close",
              style: TextStyle(color: textSecondary),
            ),
          ),
        ],
      ),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    _glowController.dispose();
    userController.dispose();
    passController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: bgDeep,
      body: Stack(
        children: [
          // Red cyberpunk grid background
          Container(
            width: double.infinity,
            height: double.infinity,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  bgDeep,
                  const Color(0xFF0F0505),
                  bgCard,
                ],
              ),
            ),
            child: CustomPaint(
              painter: CyberpunkGridPainter(redColor: neonRed),
              size: Size.infinite,
            ),
          ),
          
          // Animated scanline effect
          AnimatedBuilder(
            animation: _glowController,
            builder: (context, child) {
              return Positioned.fill(
                child: IgnorePointer(
                  child: Container(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        colors: [
                          Colors.transparent,
                          neonRed.withOpacity(0.05 * _glowController.value),
                          Colors.transparent,
                        ],
                        stops: const [0, 0.5, 1],
                      ),
                    ),
                  ),
                ),
              );
            },
          ),
          
          SafeArea(
            child: FadeTransition(
              opacity: _fadeAnim,
              child: Column(
                children: [
                  Expanded(
                    child: Center(
                      child: SingleChildScrollView(
                        padding: const EdgeInsets.symmetric(horizontal: 28),
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            // Glowing logo container
                            AnimatedBuilder(
                              animation: _glowController,
                              builder: (context, child) {
                                return Container(
                                  width: 120,
                                  height: 120,
                                  decoration: BoxDecoration(
                                    borderRadius: BorderRadius.circular(24),
                                    boxShadow: [
                                      BoxShadow(
                                        color: neonRed.withOpacity(0.3 + _glowController.value * 0.3),
                                        blurRadius: 40,
                                        spreadRadius: 8,
                                      ),
                                      BoxShadow(
                                        color: darkRed.withOpacity(0.2 + _glowController.value * 0.2),
                                        blurRadius: 60,
                                        spreadRadius: 12,
                                      ),
                                    ],
                                  ),
                                  child: ClipRRect(
                                    borderRadius: BorderRadius.circular(24),
                                    child: Stack(
                                      children: [
                                        Image.asset(
                                          'assets/images/reze.png',
                                          fit: BoxFit.cover,
                                        ),
                                        Container(
                                          decoration: BoxDecoration(
                                            border: Border.all(
                                              width: 2,
                                              color: neonRed,
                                            ),
                                            borderRadius: BorderRadius.circular(24),
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                );
                              },
                            ),
                            const SizedBox(height: 28),

                            // Glowing title
                            ShaderMask(
                              shaderCallback: (bounds) => const LinearGradient(
                                colors: [Color(0xFFFF1744), Color(0xFFC62828)],
                              ).createShader(bounds),
                              child: const Text(
                                "NoMercy Project",
                                style: TextStyle(
                                  fontSize: 36,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.white,
                                  letterSpacing: 4,
                                  fontFamily: 'Orbitron',
                                ),
                              ),
                            ),
                            const SizedBox(height: 8),
                            
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                              decoration: BoxDecoration(
                                gradient: LinearGradient(
                                  colors: [darkRed.withOpacity(0.2), neonRed.withOpacity(0.2)],
                                ),
                                borderRadius: BorderRadius.circular(20),
                              ),
                              child: Text(
                                "Elite Access Terminal",
                                style: TextStyle(
                                  color: neonRed,
                                  fontSize: 11,
                                  letterSpacing: 2,
                                  fontWeight: FontWeight.w600,
                                  fontFamily: 'ShareTechMono',
                                ),
                              ),
                            ),
                            const SizedBox(height: 36),

                            // Login form card
                            Container(
                              padding: const EdgeInsets.all(24),
                              decoration: BoxDecoration(
                                gradient: LinearGradient(
                                  begin: Alignment.topLeft,
                                  end: Alignment.bottomRight,
                                  colors: [
                                    bgCard.withOpacity(0.8),
                                    bgDeep.withOpacity(0.9),
                                  ],
                                ),
                                borderRadius: BorderRadius.circular(24),
                                border: Border.all(
                                  color: neonRed.withOpacity(0.3),
                                  width: 1,
                                ),
                                boxShadow: [
                                  BoxShadow(
                                    color: neonRed.withOpacity(0.1),
                                    blurRadius: 30,
                                    spreadRadius: 5,
                                  ),
                                ],
                              ),
                              child: Form(
                                key: _formKey,
                                child: Column(
                                  children: [
                                    _buildInput(userController, "Username", Icons.person_outline),
                                    const SizedBox(height: 18),
                                    _buildInput(passController, "Password", Icons.lock_outline, true),
                                    const SizedBox(height: 24),

                                    // Contact link
                                    GestureDetector(
                                      onTap: () async {
                                        await launchUrl(
                                          Uri.parse("https://t.me/RizzXybsRols"),
                                          mode: LaunchMode.externalApplication,
                                        );
                                      },
                                      child: RichText(
                                        text: TextSpan(
                                          text: "No Access Yet? ",
                                          style: TextStyle(
                                            color: textSecondary,
                                            fontSize: 12,
                                            fontFamily: 'ShareTechMono',
                                          ),
                                          children: [
                                            WidgetSpan(
                                              alignment: PlaceholderAlignment.middle,
                                              child: Container(
                                                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                                                decoration: BoxDecoration(
                                                  gradient: LinearGradient(
                                                    colors: [neonRed, darkRed],
                                                  ),
                                                  borderRadius: BorderRadius.circular(12),
                                                ),
                                                child: const Text(
                                                  "Get Access",
                                                  style: TextStyle(
                                                    color: Colors.white,
                                                    fontSize: 10,
                                                    fontWeight: FontWeight.bold,
                                                    letterSpacing: 1,
                                                  ),
                                                ),
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                    ),
                                    const SizedBox(height: 28),

                                    _buildButton(),
                                  ],
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),

                  // Footer
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    decoration: BoxDecoration(
                      border: Border(
                        top: BorderSide(
                          color: neonRed.withOpacity(0.2),
                          width: 1,
                        ),
                      ),
                    ),
                    child: Text(
                      "© NoMercy Project  -  Secure Terminal",
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        color: neonRed.withOpacity(0.5),
                        fontSize: 10,
                        letterSpacing: 1.5,
                        fontFamily: 'ShareTechMono',
                      ),
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

  Widget _buildInput(
    TextEditingController controller,
    String label,
    IconData icon, [
    bool isPassword = false,
  ]) {
    return Container(
      height: 55,
      padding: const EdgeInsets.symmetric(horizontal: 16),
      decoration: BoxDecoration(
        color: bgDeep.withOpacity(0.6),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: neonRed.withOpacity(0.4), width: 1.5),
      ),
      child: TextFormField(
        controller: controller,
        obscureText: isPassword ? _obscurePassword : false,
        style: TextStyle(color: textPrimary, fontSize: 15, fontFamily: 'ShareTechMono'),
        decoration: InputDecoration(
          labelText: label,
          labelStyle: TextStyle(color: neonRed.withOpacity(0.7), fontSize: 12, letterSpacing: 1),
          prefixIcon: Icon(icon, color: neonRed, size: 20),
          suffixIcon: isPassword
              ? IconButton(
                  icon: Icon(
                    _obscurePassword ? Icons.visibility_off : Icons.visibility,
                    color: neonRed.withOpacity(0.6),
                    size: 20,
                  ),
                  onPressed: () {
                    setState(() {
                      _obscurePassword = !_obscurePassword;
                    });
                  },
                )
              : null,
          border: InputBorder.none,
          contentPadding: EdgeInsets.zero,
        ),
        validator: (value) {
          if (value == null || value.isEmpty) {
            return "$label required";
          }
          return null;
        },
      ),
    );
  }

  Widget _buildButton() {
    final double fullButtonWidth = MediaQuery.of(context).size.width - 104;

    return AnimatedContainer(
      duration: const Duration(milliseconds: 300),
      width: isLoading ? 60 : fullButtonWidth,
      height: 55,
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFFFF1744), Color(0xFFC62828)],
        ),
        borderRadius: BorderRadius.circular(14),
        boxShadow: [
          BoxShadow(
            color: neonRed.withOpacity(0.5),
            blurRadius: 20,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: isLoading ? null : login,
          borderRadius: BorderRadius.circular(14),
          child: Center(
            child: isLoading
                ? const SizedBox(
                    width: 24,
                    height: 24,
                    child: CircularProgressIndicator(
                      strokeWidth: 2.5,
                      valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                    ),
                  )
                : const Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        "Sign In",
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          letterSpacing: 2,
                          fontFamily: 'Orbitron',
                        ),
                      ),
                      SizedBox(width: 10),
                      Icon(
                        Icons.arrow_forward,
                        color: Colors.white,
                        size: 18,
                      ),
                    ],
                  ),
          ),
        ),
      ),
    );
  }
}

// Red cyberpunk grid background painter
class CyberpunkGridPainter extends CustomPainter {
  final Color redColor;
  
  CyberpunkGridPainter({required this.redColor});
  
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = redColor.withOpacity(0.08)
      ..strokeWidth = 1
      ..style = PaintingStyle.stroke;

    // Vertical lines
    for (double x = 0; x < size.width; x += 40) {
      canvas.drawLine(Offset(x, 0), Offset(x, size.height), paint);
    }

    // Horizontal lines
    for (double y = 0; y < size.height; y += 40) {
      canvas.drawLine(Offset(0, y), Offset(size.width, y), paint);
    }

    // Corner accents
    final cornerPaint = Paint()
      ..color = redColor.withOpacity(0.3)
      ..strokeWidth = 2;
      
    // Top-left corner
    canvas.drawLine(const Offset(20, 0), const Offset(60, 0), cornerPaint);
    canvas.drawLine(const Offset(0, 20), const Offset(0, 60), cornerPaint);
    
    // Top-right corner
    canvas.drawLine(Offset(size.width - 60, 0), Offset(size.width - 20, 0), cornerPaint);
    canvas.drawLine(Offset(size.width, 20), Offset(size.width, 60), cornerPaint);
    
    // Bottom-left corner
    canvas.drawLine(Offset(20, size.height), Offset(60, size.height), cornerPaint);
    canvas.drawLine(Offset(0, size.height - 60), Offset(0, size.height - 20), cornerPaint);
    
    // Bottom-right corner
    canvas.drawLine(Offset(size.width - 60, size.height), Offset(size.width - 20, size.height), cornerPaint);
    canvas.drawLine(Offset(size.width, size.height - 60), Offset(size.width, size.height - 20), cornerPaint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}