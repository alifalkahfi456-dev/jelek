import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:video_player/video_player.dart';
import 'dashboard_page.dart';

class SplashScreen extends StatefulWidget {
  final String username;
  final String password;
  final String role;
  final String expiredDate;
  final String sessionKey;
  final List<Map<String, dynamic>> listBug;
  final List<Map<String, dynamic>> listDoos;
  final List<dynamic> news;

  const SplashScreen({
    super.key,
    required this.username,
    required this.password,
    required this.role,
    required this.expiredDate,
    required this.sessionKey,
    required this.listBug,
    required this.listDoos,
    required this.news,
  });

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen>
    with SingleTickerProviderStateMixin {
  late VideoPlayerController _videoController;
  late AnimationController _fadeController;
  bool _fadeOutStarted = false;
  bool _videoReady = false;
  bool _skipped = false;

  static const c1 = Color(0xFF020818);
  static const c2 = Color(0xFF1565C0);
  static const c3 = Color(0xFF020818);

  @override
  void initState() {
    super.initState();
    _fadeController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    );
    _videoController = VideoPlayerController.asset("assets/videos/load.mp4")
      ..initialize().then((_) {
        if (!mounted) return;
        setState(() => _videoReady = true);
        _videoController.setLooping(false);
        _videoController.play();

        _videoController.addListener(() {
          if (!mounted || _skipped) return;
          final position = _videoController.value.position;
          final duration = _videoController.value.duration;

          if (duration.inMilliseconds > 0 &&
              position >= duration - const Duration(seconds: 1) &&
              !_fadeOutStarted) {
            _fadeOutStarted = true;
            _fadeController.forward();
          }

          if (duration.inMilliseconds > 0 && position >= duration) {
            _navigateToDashboard();
          }
        });
      }).catchError((_) {
        // fallback jika video gagal load
        Future.delayed(const Duration(seconds: 2), _navigateToDashboard);
      });
  }

  void _skip() {
    if (_skipped) return;
    _skipped = true;
    _videoController.pause();
    _navigateToDashboard();
  }

  void _navigateToDashboard() {
    if (!mounted) return;
    Navigator.of(context).pushReplacement(
      MaterialPageRoute(
        builder: (_) => DashboardPage(
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
    _videoController.dispose();
    _fadeController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: c3,
      body: Stack(
        alignment: Alignment.center,
        children: [
          // === 1. VIDEO ===
          if (_videoReady && _videoController.value.isInitialized)
            SizedBox.expand(
              child: FittedBox(
                fit: BoxFit.cover,
                child: SizedBox(
                  width: _videoController.value.size.width,
                  height: _videoController.value.size.height,
                  child: VideoPlayer(_videoController),
                ),
              ),
            )
          else
            Container(
              color: c3,
              child: Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    SizedBox(
                      width: 40,
                      height: 40,
                      child: CircularProgressIndicator(
                        color: c2,
                        strokeWidth: 2,
                      ),
                    ),
                    const SizedBox(height: 16),
                    Text(
                      "Loading...",
                      style: TextStyle(
                        color: Colors.white.withOpacity(0.5),
                        fontSize: 12,
                        letterSpacing: 2,
                      ),
                    ),
                  ],
                ),
              ),
            ),

          // === 2. GRADIENT OVERLAY ===
          Positioned.fill(
            child: Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    Colors.transparent,
                    c3.withOpacity(0.85),
                  ],
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  stops: const [0.5, 1.0],
                ),
              ),
            ),
          ),

          // === 3. LOGO ===
          Positioned(
            bottom: 90,
            child: Column(
              children: [
                ShaderMask(
                  shaderCallback: (bounds) => LinearGradient(
                    colors: [Color(0xFF42A5F5), Color(0xFF1565C0)],
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                  ).createShader(bounds),
                  child: const Text(
                    "AX RRG",
                    style: TextStyle(
                      fontSize: 35,
                      fontWeight: FontWeight.w900,
                      color: Colors.white,
                      letterSpacing: 4,
                      fontFamily: 'Orbitron',
                      shadows: [
                        Shadow(
                          color: Color(0xFF1565C0),
                          blurRadius: 24,
                          offset: Offset(0, 4),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 10),
                Text(
                  "System Initializing...",
                  style: TextStyle(
                    color: Colors.white.withOpacity(0.6),
                    fontSize: 12,
                    letterSpacing: 2,
                  ),
                ),
              ],
            ),
          ),

          // === 4. SKIP BUTTON ===
          Positioned(
            top: 48,
            right: 20,
            child: GestureDetector(
              onTap: _skip,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                decoration: BoxDecoration(
                  color: Colors.black.withOpacity(0.4),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: Colors.white24),
                ),
                child: Row(
                  children: [
                    const Text(
                      "Skip",
                      style: TextStyle(
                        color: Colors.white70,
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(width: 4),
                    const Icon(
                      Icons.skip_next_rounded,
                      color: Colors.white54,
                      size: 16,
                    ),
                  ],
                ),
              ),
            ),
          ),

          // === 5. FADE OUT ===
          if (_fadeOutStarted)
            FadeTransition(
              opacity: _fadeController.drive(
                Tween(begin: 0.0, end: 1.0),
              ),
              child: Container(color: c3),
            ),
        ],
      ),
    );
  }
}
