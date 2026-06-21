import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:video_player/video_player.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';

class LandingPage extends StatefulWidget {
  const LandingPage({super.key});

  @override
  State<LandingPage> createState() => _LandingPageState();
}

class _LandingPageState extends State<LandingPage> {
  late VideoPlayerController _controller;
  bool _isVideoInitialized = false;

  // --- PALET WARNA (Deep Violet Theme) ---
  final Color deepViolet = const Color(0xFF311B92);   // Ungu Sangat Gelap (Background/Shadow)
  final Color mainViolet = const Color(0xFF7B1FA2);    // Ungu Utama (Border/Gradient)
  final Color accentViolet = const Color(0xFFEA80FC);  // Ungu Neon/Terang (Glow/Highlight)
  final Color bgBlack = const Color(0xFF000000);

  @override
  void initState() {
    super.initState();
    // Video Background: assets/videos/login.mp4
    _controller = VideoPlayerController.asset("assets/videos/login.mp4")
      ..initialize().then((_) {
        setState(() {
          _isVideoInitialized = true;
        });
        _controller.setLooping(true);
        _controller.setVolume(0);
        _controller.play();
      });
  }

  @override
  void dispose() {
    _controller.dispose();
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
    return Scaffold(
      backgroundColor: bgBlack,
      body: Stack(
        children: [
          // 1. VIDEO BACKGROUND
          if (_isVideoInitialized)
            SizedBox.expand(
              child: FittedBox(
                fit: BoxFit.cover,
                child: SizedBox(
                  width: _controller.value.size.width,
                  height: _controller.value.size.height,
                  child: VideoPlayer(_controller),
                ),
              ),
            )
          else
            Container(color: bgBlack),

          // 2. BLUR & OVERLAY GELAP
          BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 5, sigmaY: 5), // Blur sedikit
            child: Container(
              color: Colors.black.withOpacity(0.6), // Overlay gelap
            ),
          ),

          // 3. KONTEN UTAMA
          SafeArea(
            child: Center(
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(horizontal: 30),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    // FOTO TRANSPARAN (Posisi turun sedikit agar pas di atas tulisan)
                    Transform.translate(
                      offset: const Offset(0, 10), // DITURUNKAN (Dari -20 jadi 10)
                      child: Image.asset(
                        'assets/images/wel.png',
                        height: 160, 
                        fit: BoxFit.contain,
                      ),
                    ),

                    const SizedBox(height: 30),

                    // TEKS JUDUL (HOXTEN CLOUD) - Diatur agar pas di tengah dan glow
                    FittedBox( 
                      child: Text(
                        "HOXTEN CLOUD",
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontSize: 34,
                          fontWeight: FontWeight.w900,
                          color: Colors.white,
                          letterSpacing: 3, 
                          fontFamily: 'Orbitron',
                          height: 1.2,
                          shadows: [
                            Shadow(
                              color: accentViolet.withOpacity(0.9), // Glow Ungu Neon
                              blurRadius: 25,
                              offset: const Offset(0, 0),
                            ),
                            Shadow(
                              color: deepViolet, // Shadow dalam
                              blurRadius: 10,
                              offset: const Offset(0, 0),
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 12),
                    // TEKS KECIL (Subjudul)
                    Text(
                      "The Ultimate Digital Tools & Security",
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 14,
                        color: Colors.grey.shade300, 
                        letterSpacing: 1.2,
                        fontWeight: FontWeight.w500,
                      ),
                    ),

                    const SizedBox(height: 50),

                    // TOMBOL 1: LOGIN (Gradient Deep Violet)
                    Container(
                      width: double.infinity,
                      height: 55,
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: [deepViolet, mainViolet], // Gradasi Ungu Gelap ke Medium
                          begin: Alignment.centerLeft,
                          end: Alignment.centerRight,
                        ),
                        borderRadius: BorderRadius.circular(15),
                        boxShadow: [
                          BoxShadow(
                            color: mainViolet.withOpacity(0.5), // Glow Ungu
                            blurRadius: 20,
                            offset: const Offset(0, 5),
                          ),
                        ],
                      ),
                      child: ElevatedButton(
                        onPressed: () {
                          Navigator.pushNamed(context, "/login");
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.transparent,
                          shadowColor: Colors.transparent,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(15),
                          ),
                        ),
                        child: const Text(
                          "Login Account",
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                            letterSpacing: 1,
                          ),
                        ),
                      ),
                    ),

                    const SizedBox(height: 15),

                    // TOMBOL 2: BUY ACCOUNT (Outline Ungu Neon)
                    SizedBox(
                      width: double.infinity,
                      height: 55,
                      child: OutlinedButton(
                        onPressed: () => _openUrl("https://t.me/hafz_reals"),
                        style: OutlinedButton.styleFrom(
                          side: BorderSide(color: accentViolet, width: 2), // Border Neon
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(15),
                          ),
                          backgroundColor: Colors.black.withOpacity(0.3),
                        ),
                        child: Text(
                          "Buy Account",
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: accentViolet, // Teks Neon
                            letterSpacing: 1,
                          ),
                        ),
                      ),
                    ),

                    const SizedBox(height: 60),

                    // AREA TELEGRAM (Footer)
                    GestureDetector(
                      onTap: () => _openUrl("https://t.me/HoxtenCloud1"),
                      child: Column(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: mainViolet.withOpacity(0.15), // Tint background ungu
                              shape: BoxShape.circle,
                              border: Border.all(
                                color: mainViolet.withOpacity(0.8),
                              ),
                            ),
                            child: Icon(
                              FontAwesomeIcons.telegram,
                              color: accentViolet, // Icon Ungu Neon
                              size: 24,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            "Join Our Community",
                            style: TextStyle(
                              color: Colors.grey.shade500,
                              fontSize: 12,
                            ),
                          ),
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
    );
  }
}