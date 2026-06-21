import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';

class LandingPage extends StatefulWidget {
  const LandingPage({super.key});

  @override
  State<LandingPage> createState() => _LandingPageState();
}

class _LandingPageState extends State<LandingPage> {
  final Color solidBg      = const Color(0xFF001412);   // background hijau sangat gelap
  final Color mainTeal     = const Color(0xFF00695C);   // hijau kebiru gelap
  final Color accentTeal   = const Color(0xFF00BFA5);   // aksen teal terang
  final Color telegramBlue = const Color(0xFF2AABEE);   // biru telegram
  final Color whatsappGreen= const Color(0xFF25D366);   // hijau whatsapp

  Future<void> _openUrl(String url) async {
    final Uri uri = Uri.parse(url);
    if (!await launchUrl(uri, mode: LaunchMode.externalApplication)) {
      throw Exception("Could not launch $uri");
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: solidBg,
      body: Stack(
        children: [
          _buildBackground(),
          _buildGlassOverlay(),
          _buildMainContent(),
          _buildFloatingButtons(),
        ],
      ),
    );
  }

  Widget _buildBackground() {
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [solidBg, const Color(0xFF000D0A)],
        ),
      ),
    );
  }

  Widget _buildGlassOverlay() {
    return BackdropFilter(
      filter: ImageFilter.blur(sigmaX: 3, sigmaY: 3),
      child: Container(color: Colors.white.withOpacity(0.02)),
    );
  }

  Widget _buildMainContent() {
    return SafeArea(
      child: SingleChildScrollView(
        physics: const BouncingScrollPhysics(),
        padding: const EdgeInsets.symmetric(horizontal: 24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const SizedBox(height: 60),
            Center(
              child: Image.asset('assets/images/wel.png', height: 260, fit: BoxFit.contain),
            ),
            const SizedBox(height: 20),
            FittedBox(
              child: Text(
                "404 VOIDX V1.3",
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 36,
                  fontWeight: FontWeight.w900,
                  color: Colors.white,
                  letterSpacing: 3,
                  fontFamily: 'Orbitron',
                  shadows: [
                    Shadow(color: accentTeal.withOpacity(0.7), blurRadius: 25),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 8),
            Text(
              "The Ultimate Digital Tools & Security",
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 14,
                color: Colors.grey.shade400,
                letterSpacing: 1.2,
                fontWeight: FontWeight.w500,
              ),
            ),
            const SizedBox(height: 40),

            // BUTTON SIGN IN - gradient hijau kebiru
            _buildGradientButton(
              label: "Sign In",
              onTap: () => Navigator.pushNamed(context, "/login"),
            ),
            const SizedBox(height: 16),

            // BUTTON BUY ACCESS - outline putih, teks putih
            _buildOutlineButton(label: "Buy Access", url: "https://t.me/F4Lzzzzoffc"),

            const SizedBox(height: 100),
          ],
        ),
      ),
    );
  }

  Widget _buildFloatingButtons() {
    return Align(
      alignment: Alignment.bottomCenter,
      child: Padding(
        padding: const EdgeInsets.only(bottom: 30, left: 24, right: 24),
        child: Row(
          children: [
            Expanded(
              child: _buildLargeSocialButton(
                icon: FontAwesomeIcons.telegram,
                label: "TELEGRAM",
                color: telegramBlue,
                url: "https://t.me/F4Lzzzzoffc",
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _buildLargeSocialButton(
                icon: FontAwesomeIcons.whatsapp,
                label: "WHATSAPP",
                color: whatsappGreen,
                url: "https://wa.me/6289691563280",
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildGradientButton({required String label, required VoidCallback onTap}) {
    return SizedBox(
      width: double.infinity,
      height: 55,
      child: ElevatedButton(
        onPressed: onTap,
        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.transparent,
          shadowColor: Colors.transparent,
          padding: EdgeInsets.zero,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        ),
        child: Ink(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [accentTeal, mainTeal],
              begin: Alignment.centerLeft,
              end: Alignment.centerRight,
            ),
            borderRadius: BorderRadius.circular(16),
            boxShadow: [
              BoxShadow(color: accentTeal.withOpacity(0.4), blurRadius: 20, offset: const Offset(0, 8)),
            ],
          ),
          child: const Center(
            child: Text(
              "Sign In",
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.white, letterSpacing: 1.2),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildOutlineButton({required String label, required String url}) {
    return SizedBox(
      width: double.infinity,
      height: 55,
      child: OutlinedButton(
        onPressed: () => _openUrl(url),
        style: OutlinedButton.styleFrom(
          side: const BorderSide(color: Colors.white54, width: 1.5),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          backgroundColor: Colors.white.withOpacity(0.08),
        ),
        child: const Text(
          "Buy Access",
          style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.white, letterSpacing: 1.2),
        ),
      ),
    );
  }

  Widget _buildLargeSocialButton({
    required IconData icon,
    required String label,
    required Color color,
    required String url,
  }) {
    return SizedBox(
      height: 55,
      child: OutlinedButton.icon(
        onPressed: () => _openUrl(url),
        icon: Icon(icon, color: color, size: 20),
        label: Text(
          label,
          style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: Colors.white, letterSpacing: 1.0),
        ),
        style: OutlinedButton.styleFrom(
          side: BorderSide(color: color.withOpacity(0.8), width: 1.5),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          backgroundColor: color.withOpacity(0.15),
        ),
      ),
    );
  }
}
