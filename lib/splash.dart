import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
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
    with TickerProviderStateMixin {
  // ── Video Player ─────────────────────────────────────────────────────────
  late VideoPlayerController _videoController;
  late AnimationController _fadeInController;
  late AnimationController _pulseController;
  late AnimationController _tapHintController;

  late Animation<double> _fadeInAnim;
  late Animation<double> _pulseAnim;
  late Animation<double> _tapHintAnim;

  bool _canSkip = false;

  @override
  void initState() {
    super.initState();

    SystemChrome.setEnabledSystemUIMode(SystemUiMode.immersiveSticky);

    _videoController = VideoPlayerController.asset("assets/videos/splash.mp4")
      ..initialize().then((_) {
        setState(() {});
        _videoController.setLooping(true);
        _videoController.setVolume(0.5);
        _videoController.play();
      });

    _fadeInController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    );
    _fadeInAnim = CurvedAnimation(
      parent: _fadeInController,
      curve: Curves.easeIn,
    );
    _fadeInController.forward();

    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1800),
    )..repeat(reverse: true);
    _pulseAnim = Tween<double>(begin: 0.95, end: 1.05).animate(
      CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut),
    );

    _tapHintController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 900),
    )..repeat(reverse: true);
    _tapHintAnim = Tween<double>(begin: 0.3, end: 1.0).animate(
      CurvedAnimation(parent: _tapHintController, curve: Curves.easeInOut),
    );

    Future.delayed(const Duration(milliseconds: 1000), () {
      if (mounted) setState(() => _canSkip = true);
    });
  }

  void _navigateToDashboard() {
    if (!mounted) return;
    SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);
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
    _fadeInController.dispose();
    _pulseController.dispose();
    _tapHintController.dispose();
    SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;

    return Scaffold(
      backgroundColor: const Color(0xFF1A0A0A),
      body: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: _canSkip ? _navigateToDashboard : null,
        child: Stack(
          children: [
            // ── 1. Background Video: splash.mp4 ────────────────────────────
            Positioned.fill(
              child: _videoController.value.isInitialized
                  ? VideoPlayer(_videoController)
                  : Container(
                      color: const Color(0xFF1A0A0A),
                      child: const Center(
                        child: CircularProgressIndicator(
                          color: Color(0xFFFF5252),
                        ),
                      ),
                    ),
            ),

            // ── 2. Overlay hitam tipis di seluruh layar ────────────────────
            Positioned.fill(
              child: Container(
                color: const Color(0xFF1A0A0A).withOpacity(0.55),
              ),
            ),

            // ── 3. Konten utama (logo + teks) ──────────────────────────────
            FadeTransition(
              opacity: _fadeInAnim,
              child: Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // Logo pulse
                    ScaleTransition(
                      scale: _pulseAnim,
                      child: Container(
                        width: 130,
                        height: 130,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          boxShadow: [
                            BoxShadow(
                              color: const Color(0xFFFF5252).withOpacity(0.5),
                              blurRadius: 40,
                              spreadRadius: 6,
                            ),
                            BoxShadow(
                              color: const Color(0xFFC62828).withOpacity(0.3),
                              blurRadius: 20,
                              spreadRadius: 2,
                            ),
                          ],
                        ),
                        child: ClipOval(
                          child: Image.asset(
                            "assets/images/logo.png",
                            fit: BoxFit.cover,
                          ),
                        ),
                      ),
                    ),

                    const SizedBox(height: 28),

                    // Judul "NoMercy Project"
                    ShaderMask(
                      shaderCallback: (bounds) => const LinearGradient(
                        colors: [Color(0xFFFF5252), Color(0xFFFF8A8A), Color(0xFFFF5252)],
                      ).createShader(bounds),
                      child: Text(
                        "NoMercy Project",
                        style: TextStyle(
                          fontSize: 38,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                          letterSpacing: 3,
                          fontFamily: 'Orbitron',
                          shadows: [
                            Shadow(
                              color: const Color(0xFFFF5252).withOpacity(0.9),
                              blurRadius: 18,
                              offset: const Offset(2, 2),
                            ),
                            Shadow(
                              color: const Color(0xFFC62828).withOpacity(0.6),
                              blurRadius: 24,
                              offset: const Offset(-2, -2),
                            ),
                          ],
                        ),
                      ),
                    ),

                    const SizedBox(height: 20),

                    // ── Overlay hitam + teks deskripsi ─────────────────────
                    Container(
                      margin: const EdgeInsets.symmetric(horizontal: 36),
                      padding: const EdgeInsets.symmetric(
                          horizontal: 22, vertical: 16),
                      decoration: BoxDecoration(
                        color: const Color(0xFF1A0A0A).withOpacity(0.85),
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(
                          color: const Color(0xFFC62828).withOpacity(0.35),
                          width: 1.2,
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: const Color(0xFFC62828).withOpacity(0.08),
                            blurRadius: 20,
                            spreadRadius: 1,
                          ),
                        ],
                      ),
                      child: Text(
                        "NoMercy Projectへようこそ。\n最新のエレガントで高級感のあるデザインをお楽しみください。\n最大限にご活用ください。",
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          color: const Color(0xFFFF8A8A).withOpacity(0.9),
                          fontSize: 13.5,
                          height: 1.7,
                          letterSpacing: 0.6,
                          fontWeight: FontWeight.w400,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),

            // ── 4. "tap to continue" — pojok bawah tengah ──────────────────
            Positioned(
              bottom: 48,
              left: 0,
              right: 0,
              child: FadeTransition(
                opacity: _fadeInAnim,
                child: AnimatedBuilder(
                  animation: _tapHintAnim,
                  builder: (context, _) {
                    return Opacity(
                      opacity: _canSkip ? _tapHintAnim.value : 0.0,
                      child: const Text(
                        "tap to continue",
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          color: Color(0xFFFF5252),
                          fontSize: 12,
                          letterSpacing: 2.5,
                          fontWeight: FontWeight.w300,
                        ),
                      ),
                    );
                  },
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}