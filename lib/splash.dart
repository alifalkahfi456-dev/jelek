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
    with TickerProviderStateMixin {
  late VideoPlayerController _videoController;
  late AnimationController _fadeController;
  late AnimationController _shimmerController;
  bool _fadeOutStarted = false;
  double _progress = 0.0;

  @override
  void initState() {
    super.initState();

    _fadeController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 1),
    );

    _shimmerController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
    )..repeat();

    _videoController = VideoPlayerController.asset("assets/videos/splash.mp4")
      ..initialize().then((_) {
        setState(() {});
        _videoController
          ..setLooping(false)
          ..play();

        _videoController.addListener(_videoListener);
      });
  }

  void _videoListener() {
    final position = _videoController.value.position;
    final duration = _videoController.value.duration;

    if (duration != null && duration.inMilliseconds > 0) {
      setState(() {
        _progress = position.inMilliseconds / duration.inMilliseconds;
        _progress = _progress.clamp(0.0, 1.0);
      });

      if (position >= duration - const Duration(seconds: 1) && !_fadeOutStarted) {
        _fadeOutStarted = true;
        _fadeController.forward();
      }

      if (position >= duration) {
        _navigateToDashboard();
      }
    }
  }

  void _navigateToDashboard() {
    _videoController.removeListener(_videoListener);

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
    _shimmerController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: Stack(
        alignment: Alignment.center,
        children: [
          // Video Player
          if (_videoController.value.isInitialized)
            Center(
              child: ClipRRect(
                borderRadius: BorderRadius.circular(30),
                child: BackdropFilter(
                  filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20),
                  child: Container(
                    width: MediaQuery.of(context).size.width * 0.8,
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(30),
                      border: Border.all(
                        color: Colors.white.withOpacity(0.2),
                        width: 1.5,
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.5),
                          blurRadius: 20,
                          spreadRadius: 5,
                        ),
                      ],
                    ),
                    child: AspectRatio(
                      aspectRatio: _videoController.value.aspectRatio,
                      child: VideoPlayer(_videoController),
                    ),
                  ),
                ),
              ),
            )
          else
            const Center(child: CircularProgressIndicator(color: Colors.purple)),

          // Title and Progress Bar
          Positioned(
            bottom: 80,
            left: 40,
            right: 40,
            child: Column(
              children: [
                // Title Text
                Text(
                  "NOXTRAZ",
                  style: TextStyle(
                    fontSize: 42,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                    letterSpacing: 3,
                    shadows: [
                      Shadow(
                        color: Colors.purpleAccent.withOpacity(0.9),
                        blurRadius: 10,
                        offset: const Offset(2, 2),
                      ),
                      Shadow(
                        color: Colors.black.withOpacity(0.8),
                        blurRadius: 15,
                        offset: const Offset(-2, -2),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 32),
                
                // Enhanced Progress Bar
                Container(
                  height: 4,
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(10),
                    child: Stack(
                      children: [
                        // Base background
                        Container(
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              colors: [
                                Colors.grey.shade900.withOpacity(0.3),
                                Colors.grey.shade800.withOpacity(0.2),
                              ],
                            ),
                          ),
                        ),
                        
                        // Animated progress bar
                        FractionallySizedBox(
                          widthFactor: _progress,
                          child: AnimatedBuilder(
                            animation: _shimmerController,
                            builder: (context, child) {
                              return Container(
                                decoration: BoxDecoration(
                                  gradient: LinearGradient(
                                    begin: Alignment.centerLeft,
                                    end: Alignment.centerRight,
                                    colors: [
                                      const Color(0xFF8B5CF6),
                                      const Color(0xFFA855F7),
                                      const Color(0xFFC084FC),
                                      const Color(0xFFA855F7),
                                      const Color(0xFF8B5CF6),
                                    ],
                                    stops: [
                                      0.0,
                                      (_shimmerController.value - 0.3).clamp(0.0, 1.0),
                                      _shimmerController.value,
                                      (_shimmerController.value + 0.3).clamp(0.0, 1.0),
                                      1.0,
                                    ],
                                  ),
                                  boxShadow: [
                                    BoxShadow(
                                      color: const Color(0xFFA855F7).withOpacity(0.5),
                                      blurRadius: 8,
                                      spreadRadius: 1,
                                    ),
                                  ],
                                ),
                              );
                            },
                          ),
                        ),
                        
                        // Subtle moving dots indicator
                        if (_progress > 0 && _progress < 1)
                          Positioned(
                            left: MediaQuery.of(context).size.width * 0.8 * _progress - 40,
                            child: AnimatedBuilder(
                              animation: _shimmerController,
                              builder: (context, child) {
                                return Opacity(
                                  opacity: (0.5 + (0.5 * _shimmerController.value)).clamp(0.3, 1.0),
                                  child: Container(
                                    width: 8,
                                    height: 4,
                                    decoration: BoxDecoration(
                                      color: Colors.white,
                                      borderRadius: BorderRadius.circular(2),
                                      boxShadow: [
                                        BoxShadow(
                                          color: Colors.white.withOpacity(0.8),
                                          blurRadius: 6,
                                          spreadRadius: 2,
                                        ),
                                      ],
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
                const SizedBox(height: 20),
                
                // Loading text with subtle animation
                AnimatedBuilder(
                  animation: _shimmerController,
                  builder: (context, child) {
                    return Opacity(
                      opacity: (0.4 + (0.3 * _shimmerController.value)).clamp(0.4, 0.7),
                      child: Text(
                        "Loading...",
                        style: TextStyle(
                          color: Colors.white.withOpacity(0.6),
                          fontSize: 12,
                          fontWeight: FontWeight.w500,
                          letterSpacing: 2,
                        ),
                      ),
                    );
                  },
                ),
              ],
            ),
          ),

          // Fade Out Overlay
          if (_fadeOutStarted)
            FadeTransition(
              opacity: _fadeController,
              child: Container(color: Colors.black),
            ),
        ],
      ),
    );
  }
}