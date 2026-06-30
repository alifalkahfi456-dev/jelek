import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:http/http.dart' as http;

class LandingPage extends StatefulWidget {
  const LandingPage({super.key});

  @override
  State<LandingPage> createState() => _LandingPageState();
}

class _LandingPageState extends State<LandingPage> with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;
  late Animation<double> _scaleAnimation;
  late Animation<Offset> _slideAnimation;
  late Animation<double> _pulseAnimation;
  late AnimationController _glowController;
  late Animation<double> _rotationAnimation;
  late Animation<double> _glowPulseAnimation;
  
  // Flag untuk update
  bool _updateAvailable = false;
  bool _isLoading = true;
  String _updateMessage = "";
  String _updateVersion = "";
  String _downloadUrl = "";
  
  // Base URL API (sama dengan login_page.dart)
  final String _baseUrl = "http://senzlinodepriv.senzhosting.my.id:10791";
  final String _defaultDownloadUrl = "https://t.me/RizzXybsRols";

  // --- PREMIUM CYBERPUNK THEME - ELEGAN & MEWAH ---
  final Color primaryDark = const Color(0xFF0A0A0F);
  final Color primaryRed = const Color(0xFFE53935);
  final Color deepRed = const Color(0xFF8B0000);
  final Color accentRed = const Color(0xFFFF1744);
  final Color neonPink = const Color(0xFFFF4081);
  final Color crimsonGlow = const Color(0xFFFF0044);
  final Color darkCrimson = const Color(0xFF4A0000);
  final Color glassBorder = Colors.white.withOpacity(0.12);
  final Color cardBg = Colors.white.withOpacity(0.04);
  final Color shimmerGold = const Color(0xFFFFD700);

  @override
  void initState() {
    super.initState();
    
    _initAnimations();
    _checkForUpdatesFromServer();
  }
  
  void _initAnimations() {
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    );

    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeOut),
    );

    _scaleAnimation = Tween<double>(begin: 0.85, end: 1.0).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeOutCubic),
    );

    _slideAnimation = Tween<Offset>(begin: const Offset(0, 0.3), end: Offset.zero).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeOutCubic),
    );
    
    // Controller untuk animasi glow dan rotasi
    _glowController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 3000),
    )..repeat(reverse: true);
    
    _pulseAnimation = Tween<double>(begin: 1.0, end: 1.08).animate(
      CurvedAnimation(parent: _glowController, curve: Curves.easeInOut),
    );
    
    _glowPulseAnimation = Tween<double>(begin: 0.3, end: 0.7).animate(
      CurvedAnimation(parent: _glowController, curve: Curves.easeInOut),
    );
    
    _rotationAnimation = Tween<double>(begin: 0.0, end: 360.0).animate(
      CurvedAnimation(parent: _glowController, curve: Curves.linear),
    );

    _animationController.forward();
  }
  
  Future<void> _checkForUpdatesFromServer() async {
    setState(() => _isLoading = true);
    
    try {
      final prefs = await SharedPreferences.getInstance();
      final cachedUpdateStatus = prefs.getBool('update_required') ?? false;
      final cachedUpdateMessage = prefs.getString('update_message') ?? "";
      final cachedUpdateVersion = prefs.getString('update_version') ?? "";
      final cachedDownloadUrl = prefs.getString('download_url') ?? _defaultDownloadUrl;
      
      try {
        final response = await http.get(
          Uri.parse("$_baseUrl/checkUpdate"),
          headers: {
            'Content-Type': 'application/json',
          },
        ).timeout(const Duration(seconds: 5));
        
        if (response.statusCode == 200) {
          final Map<String, dynamic> data = json.decode(response.body);
          
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
            
            if (isValid) {
              _updateAvailable = true;
              _updateMessage = data['message'] ?? "System undergoing upgrade\nNew features & enhanced security coming soon.";
              _updateVersion = data['version'] ?? "";
              _downloadUrl = data['downloadUrl'] ?? _defaultDownloadUrl;
            } else {
              _updateAvailable = false;
            }
          } else {
            _updateAvailable = false;
          }
          
          await prefs.setBool('update_required', _updateAvailable);
          await prefs.setString('update_message', _updateMessage);
          await prefs.setString('update_version', _updateVersion);
          await prefs.setString('download_url', _downloadUrl);
        } else {
          _updateAvailable = cachedUpdateStatus;
          _updateMessage = cachedUpdateMessage;
          _updateVersion = cachedUpdateVersion;
          _downloadUrl = cachedDownloadUrl;
        }
      } catch (e) {
        print("Error fetching from server: $e");
        _updateAvailable = cachedUpdateStatus;
        _updateMessage = cachedUpdateMessage;
        _updateVersion = cachedUpdateVersion;
        _downloadUrl = cachedDownloadUrl;
      }
      
      setState(() => _isLoading = false);
      
      if (_updateAvailable && mounted) {
        _showUpdateDialog();
      }
      
    } catch (e) {
      setState(() => _isLoading = false);
      print("General error: $e");
    }
  }
  
  void _showUpdateDialog() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return WillPopScope(
          onWillPop: () async => false,
          child: Dialog(
            backgroundColor: Colors.transparent,
            insetPadding: const EdgeInsets.all(20),
            child: _buildUpdateDialog(),
          ),
        );
      },
    );
  }
  
  Widget _buildUpdateDialog() {
    return TweenAnimationBuilder(
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
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              const Color(0xFF1A0A0A),
              const Color(0xFF0A0A0F),
              const Color(0xFF1A0505),
            ],
            stops: const [0, 0.5, 1],
          ),
          borderRadius: BorderRadius.circular(32),
          border: Border.all(
            color: primaryRed.withOpacity(0.6),
            width: 2,
          ),
          boxShadow: [
            BoxShadow(
              color: primaryRed.withOpacity(0.4),
              blurRadius: 60,
              spreadRadius: 10,
            ),
            BoxShadow(
              color: deepRed.withOpacity(0.3),
              blurRadius: 80,
              spreadRadius: 20,
            ),
          ],
        ),
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Animated Icon
              AnimatedBuilder(
                animation: _rotationAnimation,
                builder: (context, child) {
                  return Transform.rotate(
                    angle: _rotationAnimation.value * 3.14159 / 180,
                    child: Container(
                      padding: const EdgeInsets.all(18),
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: [
                            deepRed.withOpacity(0.3),
                            primaryRed.withOpacity(0.3),
                            deepRed.withOpacity(0.3),
                          ],
                        ),
                        shape: BoxShape.circle,
                        boxShadow: [
                          BoxShadow(
                            color: primaryRed.withOpacity(0.6),
                            blurRadius: 40,
                            spreadRadius: 15,
                          ),
                        ],
                      ),
                      child: const Icon(
                        Icons.build_circle_outlined,
                        color: Colors.white,
                        size: 48,
                      ),
                    ),
                  );
                },
              ),
              const SizedBox(height: 24),
              
              // Glowing title
              ShaderMask(
                shaderCallback: (bounds) => LinearGradient(
                  colors: [accentRed, neonPink, accentRed],
                  stops: const [0, 0.5, 1],
                ).createShader(bounds),
                child: Text(
                  _updateVersion.isNotEmpty ? "UPDATE v$_updateVersion" : "UPDATE REQUIRED",
                  style: const TextStyle(
                    fontSize: 26,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                    letterSpacing: 4,
                  ),
                ),
              ),
              const SizedBox(height: 16),
              
              // Message container with glass effect
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [
                      deepRed.withOpacity(0.15),
                      primaryRed.withOpacity(0.05),
                    ],
                  ),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(
                    color: primaryRed.withOpacity(0.4),
                    width: 1,
                  ),
                ),
                child: Text(
                  _updateMessage.isNotEmpty 
                      ? _updateMessage
                      : "System undergoing upgrade\nNew features & enhanced security coming soon.",
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    color: Colors.white70,
                    fontSize: 14,
                    height: 1.6,
                    letterSpacing: 0.5,
                  ),
                ),
              ),
              const SizedBox(height: 24),
              
              // Version badge with premium style
              if (_updateVersion.isNotEmpty)
                Container(
                  margin: const EdgeInsets.only(bottom: 20),
                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [deepRed, primaryRed, deepRed],
                    ),
                    borderRadius: BorderRadius.circular(30),
                    boxShadow: [
                      BoxShadow(
                        color: primaryRed.withOpacity(0.6),
                        blurRadius: 20,
                        spreadRadius: 2,
                      ),
                    ],
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(Icons.star, color: Colors.white, size: 14),
                      const SizedBox(width: 8),
                      Text(
                        "Latest Version $_updateVersion",
                        style: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                          fontSize: 12,
                          letterSpacing: 2,
                        ),
                      ),
                    ],
                  ),
                ),
              
              const SizedBox(height: 8),
              
              // Animated progress bar
              Container(
                height: 4,
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.05),
                  borderRadius: BorderRadius.circular(2),
                ),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(2),
                  child: LinearProgressIndicator(
                    value: null,
                    backgroundColor: Colors.transparent,
                    valueColor: AlwaysStoppedAnimation<Color>(accentRed),
                  ),
                ),
              ),
              const SizedBox(height: 28),
              
              // Tombol Download with premium style
              Container(
                width: double.infinity,
                height: 58,
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [primaryRed, deepRed, primaryRed],
                    stops: const [0, 0.5, 1],
                  ),
                  borderRadius: BorderRadius.circular(18),
                  boxShadow: [
                    BoxShadow(
                      color: primaryRed.withOpacity(0.5),
                      blurRadius: 25,
                      spreadRadius: 5,
                    ),
                  ],
                ),
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.transparent,
                    shadowColor: Colors.transparent,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(18),
                    ),
                  ),
                  onPressed: () => _openUrl(_downloadUrl),
                  child: const Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.download_rounded, color: Colors.white),
                      SizedBox(width: 12),
                      Text(
                        "DOWNLOAD NOW",
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                          letterSpacing: 2,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              
              const SizedBox(height: 20),
              
              // Status indicator with pulse
              AnimatedBuilder(
                animation: _glowPulseAnimation,
                builder: (context, child) {
                  return Container(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    decoration: BoxDecoration(
                      color: primaryRed.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(
                        color: primaryRed.withOpacity(0.3 + _glowPulseAnimation.value * 0.3),
                        width: 1,
                      ),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Container(
                          width: 8,
                          height: 8,
                          decoration: BoxDecoration(
                            color: primaryRed,
                            shape: BoxShape.circle,
                            boxShadow: [
                              BoxShadow(
                                color: primaryRed.withOpacity(0.6 + _glowPulseAnimation.value * 0.4),
                                blurRadius: 12,
                                spreadRadius: 4,
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(width: 10),
                        Text(
                          "Access Blocked Until Update",
                          style: TextStyle(
                            color: primaryRed,
                            fontSize: 11,
                            fontWeight: FontWeight.bold,
                            letterSpacing: 1.5,
                          ),
                        ),
                      ],
                    ),
                  );
                },
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  void dispose() {
    _animationController.dispose();
    _glowController.dispose();
    super.dispose();
  }

  Future<void> _openUrl(String url) async {
    final Uri uri = Uri.parse(url);
    if (!await launchUrl(uri, mode: LaunchMode.externalApplication)) {
      throw Exception("Could not launch $uri");
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return Scaffold(
        backgroundColor: primaryDark,
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                width: 60,
                height: 60,
                child: CircularProgressIndicator(
                  color: accentRed,
                  strokeWidth: 3,
                ),
              ),
              const SizedBox(height: 24),
              Text(
                "Initializing System...",
                style: TextStyle(
                  color: Colors.white54,
                  letterSpacing: 2,
                  fontSize: 12,
                ),
              ),
            ],
          ),
        ),
      );
    }
    
    return Scaffold(
      backgroundColor: primaryDark,
      body: Stack(
        children: [
          // --- PREMIUM CYBERPUNK BACKGROUND ---
          _buildPremiumBackground(),
          
          // --- GLOW EFFECTS LAYER ---
          _buildGlowEffects(),
          
          SafeArea(
            child: FadeTransition(
              opacity: _fadeAnimation,
              child: RefreshIndicator(
                onRefresh: _checkForUpdatesFromServer,
                color: accentRed,
                backgroundColor: primaryDark,
                child: SingleChildScrollView(
                  physics: const BouncingScrollPhysics(),
                  padding: const EdgeInsets.symmetric(horizontal: 24),
                  child: Column(
                    children: [
                      const SizedBox(height: 40),
                      
                      // --- LOGO SECTION WITH ROTATING RING ---
                      ScaleTransition(
                        scale: _scaleAnimation,
                        child: _buildLogoSection(),
                      ),
                      
                      const SizedBox(height: 20),
                      
                      // --- GLOWING TEXT ---
                      _buildGlowingText(),
                      
                      const SizedBox(height: 50),
                      
                      // --- PREMIUM GLASS CARD ---
                      _buildPremiumGlassCard(
                        child: Column(
                          children: [
                            // --- TOMBOL LOGIN ---
                            _buildPremiumButton(
                              onPressed: _updateAvailable ? null : () {
                                Navigator.pushNamed(context, "/login");
                              },
                              icon: Icons.login_rounded,
                              label: "ENTER THE SYSTEM",
                              isPrimary: true,
                            ),
                            
                            const SizedBox(height: 18),
                            
                            // --- TOMBOL BUY ACCESS ---
                            _buildPremiumButton(
                              onPressed: _updateAvailable ? null : () => _openUrl("https://t.me/RizzXybsRols"),
                              icon: Icons.shopping_bag_rounded,
                              label: "GET ACCESS",
                              isPrimary: false,
                            ),
                          ],
                        ),
                      ),
                      
                      const SizedBox(height: 35),
                      
                      // --- SOCIAL LINKS ---
                      _buildSocialLinks(),
                      
                      const SizedBox(height: 35),
                      
                      // --- CYBER DIVIDER ---
                      _buildCyberDivider(),
                      
                      const SizedBox(height: 24),
                      
                      // --- FOOTER ---
                      _buildFooter(),
                      
                      const SizedBox(height: 30),
                    ],
                  ),
                ),
              ),
            ),
          ),
          
          // --- UPDATE NOTIFICATION BADGE ---
          if (_updateAvailable)
            Positioned(
              top: 16,
              right: 16,
              child: _buildUpdateBadge(),
            ),
        ],
      ),
    );
  }
  
  Widget _buildUpdateBadge() {
    return GestureDetector(
      onTap: _showUpdateDialog,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [primaryRed, deepRed],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(30),
          boxShadow: [
            BoxShadow(
              color: primaryRed.withOpacity(0.6),
              blurRadius: 20,
              spreadRadius: 3,
            ),
          ],
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(
              Icons.warning_amber_rounded,
              color: Colors.white,
              size: 16,
            ),
            const SizedBox(width: 8),
            Text(
              _updateVersion.isNotEmpty ? "UPDATE v$_updateVersion" : "UPDATE",
              style: const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
                fontSize: 12,
                letterSpacing: 1.5,
              ),
            ),
            const SizedBox(width: 8),
            Container(
              width: 6,
              height: 6,
              decoration: BoxDecoration(
                color: Colors.white,
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(
                    color: Colors.white,
                    blurRadius: 10,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  // --- PREMIUM BACKGROUND WITH PARTICLES ---
  Widget _buildPremiumBackground() {
    return Stack(
      children: [
        // Dark base
        Container(color: primaryDark),
        
        // Grid with higher opacity
        CustomPaint(
          painter: PremiumGridPainter(),
          size: Size.infinite,
        ),
        
        // Gradient overlays
        Positioned(
          top: 0,
          left: 0,
          right: 0,
          child: Container(
            height: MediaQuery.of(context).size.height * 0.4,
            decoration: BoxDecoration(
              gradient: RadialGradient(
                radius: 0.8,
                colors: [
                  primaryRed.withOpacity(0.08),
                  Colors.transparent,
                ],
              ),
            ),
          ),
        ),
        
        // Bottom glow
        Positioned(
          bottom: 0,
          left: 0,
          right: 0,
          child: Container(
            height: MediaQuery.of(context).size.height * 0.3,
            decoration: BoxDecoration(
              gradient: RadialGradient(
                radius: 0.8,
                colors: [
                  deepRed.withOpacity(0.06),
                  Colors.transparent,
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildGlowEffects() {
    return Stack(
      children: [
        // Top right glow
        Positioned(
          top: -80,
          right: -80,
          child: AnimatedBuilder(
            animation: _glowPulseAnimation,
            builder: (context, child) {
              return Container(
                width: 350,
                height: 350,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: RadialGradient(
                    colors: [
                      primaryRed.withOpacity(0.12 + _glowPulseAnimation.value * 0.08),
                      Colors.transparent,
                    ],
                    stops: const [0, 1],
                  ),
                ),
              );
            },
          ),
        ),
        
        // Bottom left glow
        Positioned(
          bottom: -50,
          left: -50,
          child: Container(
            width: 250,
            height: 250,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: RadialGradient(
                colors: [
                  neonPink.withOpacity(0.08),
                  Colors.transparent,
                ],
                stops: const [0, 1],
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildLogoSection() {
    return AnimatedBuilder(
      animation: _glowController,
      builder: (context, child) {
        return Transform.scale(
          scale: _pulseAnimation.value,
          child: Stack(
            alignment: Alignment.center,
            children: [
              // Outer rotating ring
              Transform.rotate(
                angle: _rotationAnimation.value * 3.14159 / 180,
                child: Container(
                  width: 240,
                  height: 240,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: primaryRed.withOpacity(0.3 + _glowPulseAnimation.value * 0.2),
                      width: 2,
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: primaryRed.withOpacity(0.15 + _glowPulseAnimation.value * 0.1),
                        blurRadius: 50,
                        spreadRadius: 10,
                      ),
                    ],
                  ),
                  child: Stack(
                    alignment: Alignment.center,
                    children: [
                      // Inner ring
                      Container(
                        width: 220,
                        height: 220,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          border: Border.all(
                            color: neonPink.withOpacity(0.2 + _glowPulseAnimation.value * 0.1),
                            width: 1,
                          ),
                        ),
                      ),
                      
                      // Dotted ring
                      Container(
                        width: 200,
                        height: 200,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          border: Border.all(
                            color: primaryRed.withOpacity(0.1),
                            width: 1,
                            style: BorderStyle.solid,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              
              // Main avatar with premium glow
              Container(
                width: 180,
                height: 180,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: RadialGradient(
                    colors: [
                      primaryRed.withOpacity(0.4 + _glowPulseAnimation.value * 0.2),
                      deepRed.withOpacity(0.2),
                    ],
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: primaryRed.withOpacity(0.3 + _glowPulseAnimation.value * 0.2),
                      blurRadius: 50,
                      spreadRadius: 10,
                    ),
                  ],
                ),
                child: Stack(
                  alignment: Alignment.center,
                  children: [
                    // Outer ring glow
                    Container(
                      width: 180,
                      height: 180,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        border: Border.all(
                          color: primaryRed.withOpacity(0.4 + _glowPulseAnimation.value * 0.2),
                          width: 2,
                        ),
                      ),
                    ),
                    
                    // Avatar
                    ClipOval(
                      child: Image.asset(
                        "assets/images/reze.png",
                        width: 160,
                        height: 160,
                        fit: BoxFit.cover,
                        errorBuilder: (context, error, stackTrace) {
                          return Container(
                            color: primaryRed,
                            child: const Icon(Icons.person, size: 80, color: Colors.white),
                          );
                        },
                      ),
                    ),
                    
                    // Corner accents
                    Positioned(
                      top: 8,
                      left: 8,
                      child: _buildCornerAccent(),
                    ),
                    Positioned(
                      bottom: 8,
                      right: 8,
                      child: _buildCornerAccent(),
                    ),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildCornerAccent() {
    return Container(
      width: 24,
      height: 24,
      decoration: BoxDecoration(
        border: Border(
          top: BorderSide(color: accentRed, width: 2.5),
          left: BorderSide(color: accentRed, width: 2.5),
        ),
      ),
    );
  }

  Widget _buildGlowingText() {
    return Column(
      children: [
        ShaderMask(
          shaderCallback: (bounds) => LinearGradient(
            colors: [accentRed, neonPink, primaryRed, accentRed],
            stops: const [0, 0.3, 0.7, 1],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ).createShader(bounds),
          child: const Text(
            "NOMERCY PROJECT",
            style: TextStyle(
              fontSize: 34,
              fontWeight: FontWeight.w900,
              color: Colors.white,
              letterSpacing: 6,
              shadows: [
                Shadow(
                  color: Color(0xFFFF1744),
                  blurRadius: 20,
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 14),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 10),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [primaryRed.withOpacity(0.15), deepRed.withOpacity(0.05)],
              begin: Alignment.centerLeft,
              end: Alignment.centerRight,
            ),
            borderRadius: BorderRadius.circular(30),
            border: Border.all(
              color: primaryRed.withOpacity(0.2),
              width: 1,
            ),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 6,
                height: 6,
                decoration: BoxDecoration(
                  color: accentRed,
                  shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(
                      color: accentRed,
                      blurRadius: 12,
                      spreadRadius: 2,
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 12),
              const Text(
                "AUTHORIZED ACCESS ONLY",
                style: TextStyle(
                  color: Colors.white60,
                  fontSize: 10,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 3,
                ),
              ),
              const SizedBox(width: 12),
              Container(
                width: 6,
                height: 6,
                decoration: BoxDecoration(
                  color: accentRed,
                  shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(
                      color: accentRed,
                      blurRadius: 12,
                      spreadRadius: 2,
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildPremiumGlassCard({required Widget child}) {
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Colors.white.withOpacity(0.06),
            Colors.white.withOpacity(0.02),
          ],
        ),
        borderRadius: BorderRadius.circular(28),
        border: Border.all(
          color: glassBorder,
          width: 1.5,
        ),
        boxShadow: [
          BoxShadow(
            color: primaryRed.withOpacity(0.05),
            blurRadius: 30,
            spreadRadius: 5,
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(28),
        child: child,
      ),
    );
  }

  Widget _buildPremiumButton({
    required VoidCallback? onPressed,
    required IconData icon,
    required String label,
    required bool isPrimary,
  }) {
    return Container(
      height: 62,
      decoration: BoxDecoration(
        gradient: isPrimary
            ? LinearGradient(
                colors: [primaryRed, deepRed, primaryRed],
                stops: const [0, 0.5, 1],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              )
            : LinearGradient(
                colors: [Colors.transparent, Colors.transparent],
              ),
        borderRadius: BorderRadius.circular(18),
        border: isPrimary
            ? null
            : Border.all(
                color: primaryRed.withOpacity(onPressed == null ? 0.15 : 0.5),
                width: 1.5,
              ),
        boxShadow: isPrimary && onPressed != null
            ? [
                BoxShadow(
                  color: primaryRed.withOpacity(0.5),
                  blurRadius: 25,
                  spreadRadius: 5,
                ),
              ]
            : null,
      ),
      child: ElevatedButton(
        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.transparent,
          shadowColor: Colors.transparent,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(18),
          ),
          disabledBackgroundColor: Colors.transparent,
        ),
        onPressed: onPressed,
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              icon, 
              color: onPressed == null 
                  ? Colors.white24 
                  : (isPrimary ? Colors.white : accentRed),
              size: 22,
            ),
            const SizedBox(width: 12),
            Text(
              label,
              style: TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.w700,
                color: onPressed == null 
                    ? Colors.white24 
                    : (isPrimary ? Colors.white : accentRed),
                letterSpacing: 2,
              ),
            ),
            if (isPrimary && onPressed != null)
              const SizedBox(width: 8),
            if (isPrimary && onPressed != null)
              const Icon(
                Icons.arrow_forward_rounded,
                color: Colors.white,
                size: 16,
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildSocialLinks() {
    return Row(
      children: [
        Expanded(
          child: _buildSocialButton(
            icon: FontAwesomeIcons.telegram,
            label: "Telegram",
            url: "https://t.me/RizzXybsRols",
            color: const Color(0xFF0088cc),
          ),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: _buildSocialButton(
            icon: FontAwesomeIcons.whatsapp,
            label: "WhatsApp",
            url: "https://whatsapp.com/channel/0029Vb7QegzAjPXEwh1M2n31",
            color: const Color(0xFF25D366),
          ),
        ),
      ],
    );
  }

  Widget _buildSocialButton({
    required IconData icon, 
    required String label, 
    required String url, 
    required Color color
  }) {
    return InkWell(
      onTap: _updateAvailable ? null : () => _openUrl(url),
      borderRadius: BorderRadius.circular(14),
      child: Container(
        height: 52,
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [
              cardBg,
              cardBg,
            ],
          ),
          border: Border.all(
            color: _updateAvailable ? Colors.white.withOpacity(0.03) : glassBorder,
            width: 1,
          ),
          borderRadius: BorderRadius.circular(14),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            FaIcon(
              icon, 
              color: _updateAvailable ? Colors.white24 : color, 
              size: 18,
            ),
            const SizedBox(width: 10),
            Text(
              label,
              style: TextStyle(
                color: _updateAvailable ? Colors.white24 : Colors.white70,
                fontWeight: FontWeight.w600,
                fontSize: 13,
                letterSpacing: 0.5,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCyberDivider() {
    return Row(
      children: [
        Expanded(
          child: Container(
            height: 1,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [Colors.transparent, primaryRed.withOpacity(0.4), Colors.transparent],
              ),
            ),
          ),
        ),
        const SizedBox(width: 16),
        Container(
          width: 4,
          height: 4,
          decoration: BoxDecoration(
            color: primaryRed,
            shape: BoxShape.circle,
            boxShadow: [
              BoxShadow(
                color: primaryRed,
                blurRadius: 8,
              ),
            ],
          ),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: Container(
            height: 1,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [Colors.transparent, primaryRed.withOpacity(0.4), Colors.transparent],
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildFooter() {
    return Column(
      children: [
        Text(
          "© 2025 NoMercy Project",
          style: TextStyle(
            color: Colors.white30, 
            fontSize: 11,
            letterSpacing: 2,
          ),
        ),
        const SizedBox(height: 8),
        if (_updateVersion.isNotEmpty)
          Text(
            "Latest: v$_updateVersion",
            style: TextStyle(
              color: primaryRed.withOpacity(0.4), 
              fontSize: 9,
              letterSpacing: 1,
            ),
          ),
        const SizedBox(height: 4),
        Text(
          "SECURE CONNECTION",
          style: TextStyle(
            color: Colors.white12,
            fontSize: 8,
            letterSpacing: 3,
          ),
        ),
      ],
    );
  }
}

// --- PREMIUM CYBERPUNK GRID PAINTER ---
class PremiumGridPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final gridPaint = Paint()
      ..color = const Color(0xFFFF1744).withOpacity(0.04)
      ..strokeWidth = 0.5
      ..style = PaintingStyle.stroke;
    
    const spacing = 30.0;
    
    // Garis vertikal
    for (double x = 0; x < size.width; x += spacing) {
      canvas.drawLine(Offset(x, 0), Offset(x, size.height), gridPaint);
    }
    
    // Garis horizontal
    for (double y = 0; y < size.height; y += spacing) {
      canvas.drawLine(Offset(0, y), Offset(size.width, y), gridPaint);
    }
    
    // Corner accents with glow
    final cornerPaint = Paint()
      ..color = const Color(0xFFFF1744).withOpacity(0.25)
      ..strokeWidth = 2;
      
    final cornerPaintInner = Paint()
      ..color = const Color(0xFFFF1744).withOpacity(0.1)
      ..strokeWidth = 1;
    
    // Top-left
    canvas.drawLine(const Offset(20, 0), const Offset(70, 0), cornerPaint);
    canvas.drawLine(const Offset(0, 20), const Offset(0, 70), cornerPaint);
    canvas.drawLine(const Offset(10, 0), const Offset(30, 0), cornerPaintInner);
    canvas.drawLine(const Offset(0, 10), const Offset(0, 30), cornerPaintInner);
    
    // Top-right
    canvas.drawLine(Offset(size.width - 70, 0), Offset(size.width - 20, 0), cornerPaint);
    canvas.drawLine(Offset(size.width, 20), Offset(size.width, 70), cornerPaint);
    canvas.drawLine(Offset(size.width - 30, 0), Offset(size.width - 10, 0), cornerPaintInner);
    canvas.drawLine(Offset(size.width, 10), Offset(size.width, 30), cornerPaintInner);
    
    // Bottom-left
    canvas.drawLine(Offset(20, size.height), Offset(70, size.height), cornerPaint);
    canvas.drawLine(Offset(0, size.height - 70), Offset(0, size.height - 20), cornerPaint);
    canvas.drawLine(Offset(10, size.height), Offset(30, size.height), cornerPaintInner);
    canvas.drawLine(Offset(0, size.height - 30), Offset(0, size.height - 10), cornerPaintInner);
    
    // Bottom-right
    canvas.drawLine(Offset(size.width - 70, size.height), Offset(size.width - 20, size.height), cornerPaint);
    canvas.drawLine(Offset(size.width, size.height - 70), Offset(size.width, size.height - 20), cornerPaint);
    canvas.drawLine(Offset(size.width - 30, size.height), Offset(size.width - 10, size.height), cornerPaintInner);
    canvas.drawLine(Offset(size.width, size.height - 30), Offset(size.width, size.height - 10), cornerPaintInner);
    
    // Additional decorative dots
    final dotPaint = Paint()
      ..color = const Color(0xFFFF1744).withOpacity(0.15)
      ..style = PaintingStyle.fill;
    
    // Create the dot positions dynamically instead of using a constant list
    final dotPositions = [
      const Offset(40, 40),
      const Offset(60, 40),
      const Offset(40, 60),
      Offset(size.width - 40, 40),
      Offset(size.width - 60, 40),
      Offset(size.width - 40, 60),
      Offset(40, size.height - 40),
      Offset(60, size.height - 40),
      Offset(40, size.height - 60),
      Offset(size.width - 40, size.height - 40),
      Offset(size.width - 60, size.height - 40),
      Offset(size.width - 40, size.height - 60),
    ];
    
    for (final pos in dotPositions) {
      canvas.drawCircle(pos, 2, dotPaint);
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}