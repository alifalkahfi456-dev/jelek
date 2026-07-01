import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:video_player/video_player.dart';

import 'dashboard_page.dart';

class SplashScreen extends StatefulWidget {
  final String username;
  final String password;
  final String role;
  final String sessionKey;
  final String expiredDate;
  final List<Map<String, dynamic>> listBug;
  final List<Map<String, dynamic>> listDoos;
  final List<Map<String, dynamic>> news;

  const SplashScreen({
    super.key,
    required this.username,
    required this.password,
    required this.role,
    required this.sessionKey,
    required this.expiredDate,
    required this.listBug,
    required this.listDoos,
    required this.news,
  });

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  late VideoPlayerController _controller;
  bool _isInitialized = false;
  bool _isNavigating = false;

  @override
  void initState() {
    super.initState();
    _initializeVideo();
  }

  void _initializeVideo() {
    _controller = VideoPlayerController.asset('assets/videos/load.mp4')
      ..initialize().then((_) {
        SystemChrome.setEnabledSystemUIMode(SystemUiMode.immersive);
        setState(() {
          _isInitialized = true;
        });
        _controller.play();
        _controller.setVolume(1.0);
      });

    _controller.addListener(() {
      if (_controller.value.isInitialized &&
          _controller.value.position >= _controller.value.duration) {
        _navigateToDashboard();
      }
    });
  }

  void _navigateToDashboard() {
    if (_isNavigating) return;
    _isNavigating = true;

    _controller.pause();
    SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);

    Navigator.of(context).pushReplacement(
      MaterialPageRoute(
        builder: (context) => DashboardPage(
          username: widget.username,
          password: widget.password,
          role: widget.role,
          expiredDate: widget.expiredDate,
          sessionKey: widget.sessionKey,
          listBug: widget.listBug,
          listDoos: widget.listDoos,
          news: widget.news,
        ),
      ),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: Stack(
        fit: StackFit.expand,
        children: [
          // Video Background
          if (_isInitialized)
            SizedBox.expand(
              child: VideoPlayer(_controller),
            )
          else
            const Center(
              child: SizedBox(
                width: 30,
                height: 30,
                child: CircularProgressIndicator(
                  color: Color(0xFF00AAFF),
                  strokeWidth: 2,
                ),
              ),
            ),

          // Gradient overlay biru tua di pinggir
          Positioned(
            bottom: 0,
            left: 0,
            right: 0,
            child: Container(
              height: 280,
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    Colors.transparent,
                    const Color(0xFF001133).withOpacity(0.7),
                    const Color(0xFF000822).withOpacity(0.95),
                  ],
                ),
              ),
            ),
          ),
          Positioned(
            top: 0,
            left: 0,
            right: 0,
            child: Container(
              height: 150,
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.bottomCenter,
                  end: Alignment.topCenter,
                  colors: [
                    Colors.transparent,
                    const Color(0xFF001133).withOpacity(0.6),
                  ],
                ),
              ),
            ),
          ),

          // Efek grid neon (garis-garis futuristik)
          ..._buildNeonGrid(),

          // Konten utama
          Positioned(
            bottom: 80,
            left: 0,
            right: 0,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Logo / Teks utama Hello
                Stack(
                  alignment: Alignment.center,
                  children: [
                    // Glow luar
                    Text(
                      "Hello",
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontFamily: 'Rajdhani',
                        fontSize: 38,
                        fontWeight: FontWeight.bold,
                        letterSpacing: 5.0,
                        color: Colors.transparent,
                        shadows: [
                          Shadow(
                            blurRadius: 30,
                            color: const Color(0xFF00AAFF),
                            offset: Offset(0, 0),
                          ),
                        ],
                      ),
                    ),
                    // Stroke outline
                    Text(
                      "Hello",
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontFamily: 'Rajdhani',
                        fontSize: 38,
                        fontWeight: FontWeight.bold,
                        letterSpacing: 5.0,
                        foreground: Paint()
                          ..style = PaintingStyle.stroke
                          ..strokeWidth = 2.5
                          ..color = const Color(0xFF88CCFF),
                      ),
                    ),
                    // Gradient fill
                    ShaderMask(
                      shaderCallback: (bounds) => const LinearGradient(
                        colors: [
                          Color(0xFF42A5F5),
                          Color(0xFF00AAFF),
                          Color(0xFF0D47A1),
                        ],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ).createShader(bounds),
                      blendMode: BlendMode.srcIn,
                      child: const Text(
                        "Hello",
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontFamily: 'Rajdhani',
                          fontSize: 38,
                          fontWeight: FontWeight.bold,
                          letterSpacing: 5.0,
                          color: Colors.white,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                // Garis neon
                Container(
                  width: 150,
                  height: 2,
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      colors: [Color(0xFF00AAFF), Color(0xFF88CCFF)],
                    ),
                    borderRadius: BorderRadius.circular(10),
                    boxShadow: [
                      BoxShadow(
                        color: const Color(0xFF00AAFF).withOpacity(0.8),
                        blurRadius: 8,
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),
                // Subtitle
                const Text(
                  "CHAN XITER",
                  style: TextStyle(
                    fontFamily: 'Rajdhani',
                    fontSize: 14,
                    color: Color(0xFF88CCFF),
                    letterSpacing: 4.0,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 6),
                const Text(
                  "MULTIPLE PAYLOAD ATTACK SYSTEM",
                  style: TextStyle(
                    fontFamily: 'Rajdhani',
                    fontSize: 10,
                    color: Color(0xFF4488AA),
                    letterSpacing: 2.0,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: 20),
                // Efek loading dot biru
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    _buildDot(0),
                    const SizedBox(width: 8),
                    _buildDot(1),
                    const SizedBox(width: 8),
                    _buildDot(2),
                  ],
                ),
              ],
            ),
          ),

          // Skip button dengan gaya biru glassmorphism
          Positioned(
            top: 50,
            right: 25,
            child: IgnorePointer(
              ignoring: _isNavigating,
              child: GestureDetector(
                onTap: _navigateToDashboard,
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(30),
                  child: BackdropFilter(
                    filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 10),
                      decoration: BoxDecoration(
                        color: const Color(0xFF00AAFF).withOpacity(0.15),
                        borderRadius: BorderRadius.circular(30),
                        border: Border.all(
                          color: const Color(0xFF00AAFF).withOpacity(0.5),
                          width: 1,
                        ),
                      ),
                      child: const Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            "SKIP",
                            style: TextStyle(
                              color: Color(0xFF88CCFF),
                              fontWeight: FontWeight.bold,
                              fontSize: 12,
                              letterSpacing: 2.0,
                              fontFamily: 'Rajdhani',
                            ),
                          ),
                          SizedBox(width: 6),
                          Icon(Icons.arrow_forward_ios_rounded, color: Color(0xFF88CCFF), size: 11),
                        ],
                      ),
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

  // Animasi titik loading biru
  Widget _buildDot(int index) {
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) {
        // Simulasi animasi sederhana dengan timer (tanpa controller tambahan)
        return Container(
          width: 8,
          height: 8,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: const Color(0xFF00AAFF).withOpacity(0.6 + (index * 0.2)),
            boxShadow: [
              BoxShadow(
                color: const Color(0xFF00AAFF).withOpacity(0.8),
                blurRadius: 4,
              ),
            ],
          ),
        );
      },
    );
  }

  List<Widget> _buildNeonGrid() {
    // Garis dekoratif horizontal dan vertikal tipis untuk efek cyber
    return [
      Positioned(
        left: 20,
        top: 100,
        child: Container(
          width: 1,
          height: 60,
          color: const Color(0xFF00AAFF).withOpacity(0.3),
        ),
      ),
      Positioned(
        right: 20,
        top: 100,
        child: Container(
          width: 1,
          height: 60,
          color: const Color(0xFF00AAFF).withOpacity(0.3),
        ),
      ),
      Positioned(
        left: 20,
        bottom: 100,
        child: Container(
          width: 60,
          height: 1,
          color: const Color(0xFF00AAFF).withOpacity(0.3),
        ),
      ),
      Positioned(
        right: 20,
        bottom: 100,
        child: Container(
          width: 60,
          height: 1,
          color: const Color(0xFF00AAFF).withOpacity(0.3),
        ),
      ),
    ];
  }
}