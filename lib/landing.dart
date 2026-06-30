import 'package:flutter/material.dart';

import 'package:url_launcher/url_launcher.dart';
import 'package:video_player/video_player.dart';

// ─── Landing Page — Red theme ────────────────────────────────────────────────
class LandingPage extends StatefulWidget {
  const LandingPage({super.key});
  @override State<LandingPage> createState() => _LandingPageState();
}

class _LandingPageState extends State<LandingPage> with SingleTickerProviderStateMixin {

  // ── Warna tema merah ──────────────────────────────────────────────────────
  static const _bg      = Color(0xFF000000);
  static const _bg2     = Color(0xFF020A18);
  static const _red     = Color(0xFF0D47A1);
  static const _red2    = Color(0xFF990000);
  static const _redL    = Color(0xFF42A5F5);
  static const _pink    = Color(0xFF2979FF);
  static const _card    = Color(0xFF040F22);
  static const _cardBrd = Color(0xFF1E1E1E);
  static const _txt     = Color(0xFFFFFFFF);
  static const _txtSub  = Color(0xFFFF8A80);
  static const _tele    = Color(0xFF2AABEE);
  static const _wa      = Color(0xFF25D366);

  late VideoPlayerController _vidCtrl;
  late AnimationController _animCtrl;
  late Animation<double> _fadeAnim;
  late Animation<Offset> _slideAnim;

  @override
  void initState() {
    super.initState();
    _animCtrl = AnimationController(vsync: this, duration: const Duration(milliseconds: 900))..forward();
    _fadeAnim  = CurvedAnimation(parent: _animCtrl, curve: Curves.easeOut);
    _slideAnim = Tween<Offset>(begin: const Offset(0, 0.2), end: Offset.zero)
        .animate(CurvedAnimation(parent: _animCtrl, curve: Curves.easeOutCubic));

    _vidCtrl = VideoPlayerController.asset('assets/videos/landing.mp4')
      ..initialize().then((_) {
        setState(() {});
        _vidCtrl.setLooping(true);
        _vidCtrl.play();
        _vidCtrl.setVolume(0);
      });
  }

  @override
  void dispose() {
    _animCtrl.dispose();
    _vidCtrl.dispose();
    super.dispose();
  }

  Future<void> _openUrl(String url) async {
    final uri = Uri.parse(url);
    if (await canLaunchUrl(uri)) launchUrl(uri, mode: LaunchMode.externalApplication);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _bg,
      body: Stack(children: [
        // ── Background gradient ───────────────────────────────────────────
        Container(
          decoration: BoxDecoration(
            gradient: RadialGradient(
              center: Alignment(0, -0.4),
              radius: 1.2,
              colors: [Color(0xFF051525), _bg],
            ),
          ),
        ),

        // ── Glow lingkaran di atas ────────────────────────────────────────
        Positioned(
          top: -60, left: MediaQuery.of(context).size.width / 2 - 100,
          child: Container(
            width: 200, height: 200,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: RadialGradient(colors: [_red.withOpacity(0.35), Colors.transparent]),
            ),
          ),
        ),
        Positioned(
          top: 40, right: -40,
          child: Container(
            width: 180, height: 180,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: RadialGradient(colors: [_pink.withOpacity(0.2), Colors.transparent]),
            ),
          ),
        ),

        // ── Main content ──────────────────────────────────────────────────
        SafeArea(child: FadeTransition(opacity: _fadeAnim, child: SlideTransition(position: _slideAnim,
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 22),
            child: Column(crossAxisAlignment: CrossAxisAlignment.center, children: [
              const SizedBox(height: 50),

              // Logo / Title
              const Text('AX RRG',
                style: TextStyle(color: _txt, fontSize: 42, fontWeight: FontWeight.w900,
                  fontFamily: 'Orbitron', letterSpacing: 3,
                  shadows: [Shadow(color: _redL, blurRadius: 20)])),
              const SizedBox(height: 8),

              // Powered by badge
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
                decoration: BoxDecoration(
                  color: _card,
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: _cardBrd)),
                child: Row(mainAxisSize: MainAxisSize.min, children: [
                  Container(width: 7, height: 7, decoration: BoxDecoration(color: _red, shape: BoxShape.circle)),
                  const SizedBox(width: 8),
                  Text('Powered by @andipmx', style: TextStyle(color: _txtSub, fontSize: 12)),
                ]),
              ),
              const SizedBox(height: 32),

              // Feature cards row
              Row(children: [
                _featureCard(Icons.shield_rounded, 'Secure', _red),
                const SizedBox(width: 10),
                _featureCard(Icons.bolt_rounded, 'Fast', _pink),
                const SizedBox(width: 10),
                _featureCard(Icons.local_fire_department_rounded, 'Power', const Color(0xFFFF6D00)),
              ]),
              const SizedBox(height: 24),

              // Banner video/image card
              Container(
                height: 190,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(18),
                  border: Border.all(color: _cardBrd),
                  color: _card,
                ),
                clipBehavior: Clip.antiAlias,
                child: Stack(fit: StackFit.expand, children: [
                  if (_vidCtrl.value.isInitialized)
                    FittedBox(fit: BoxFit.cover, child: SizedBox(
                      width: _vidCtrl.value.size.width,
                      height: _vidCtrl.value.size.height,
                      child: VideoPlayer(_vidCtrl)))
                  else
                    Image.asset('assets/images/wel.png', fit: BoxFit.cover),
                  // Overlay gradient
                  Container(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topCenter, end: Alignment.bottomCenter,
                        colors: [Colors.transparent, _bg.withOpacity(0.85)]))),
                  const Positioned(bottom: 16, left: 16, child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start, children: [
                      Text('AX RRG', style: TextStyle(color: _txt, fontSize: 18, fontWeight: FontWeight.w900, fontFamily: 'Orbitron')),
                      SizedBox(height: 4),
                      Text('Log in or buy access to continue', style: TextStyle(color: _txtSub, fontSize: 12)),
                    ])),
                ]),
              ),
              const SizedBox(height: 28),

              // MASUK button
              SizedBox(width: double.infinity, height: 56,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.transparent, shadowColor: Colors.transparent, padding: EdgeInsets.zero,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16))),
                  onPressed: () => Navigator.pushNamed(context, '/login'),
                  child: Ink(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(colors: [_red, _pink], begin: Alignment.centerLeft, end: Alignment.centerRight),
                      borderRadius: BorderRadius.circular(16),
                      boxShadow: [BoxShadow(color: _red.withOpacity(0.5), blurRadius: 20, offset: Offset(0, 8))]),
                    child: const Center(child: Row(mainAxisSize: MainAxisSize.min, children: [
                      Icon(Icons.arrow_forward_rounded, color: Colors.white, size: 20),
                      SizedBox(width: 10),
                      Text('MASUK', style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.w900, letterSpacing: 2)),
                    ])),
                  ),
                )),
              const SizedBox(height: 14),

              // Beli Akses button
              SizedBox(width: double.infinity, height: 56,
                child: OutlinedButton(
                  style: OutlinedButton.styleFrom(
                    side: BorderSide(color: _cardBrd, width: 1.5),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                    backgroundColor: _card.withOpacity(0.6)),
                  onPressed: () => _openUrl('https://t.me/pemxx08'),
                  child: Row(mainAxisAlignment: MainAxisAlignment.center, children: [
                    const Icon(Icons.shopping_bag_outlined, color: _txtSub, size: 18),
                    const SizedBox(width: 10),
                    const Text('Beli Akses', style: TextStyle(color: _txt, fontSize: 15, fontWeight: FontWeight.bold)),
                    const SizedBox(width: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                      decoration: BoxDecoration(color: _red, borderRadius: BorderRadius.all(Radius.circular(10))),
                      child: const Text('CLICK HERE', style: TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.bold, letterSpacing: 1))),
                  ]),
                )),
              const SizedBox(height: 28),

              // Telegram & WhatsApp buttons
              Row(children: [
                Expanded(child: _socialBtn(Icons.telegram, 'Telegram', _tele, 'https://t.me/pemxx08')),
                const SizedBox(width: 12),
                Expanded(child: _socialBtn(Icons.chat_rounded, 'WhatsApp', _wa, 'https://wa.me/6287735450436')),
              ]),
              const SizedBox(height: 24),

              // Footer
              Text('© 2025 AX RRG  •  All rights reserved',
                style: TextStyle(color: _txtSub.withOpacity(0.5), fontSize: 11)),
              const SizedBox(height: 30),
            ]),
          ),
        ))),
      ]),
    );
  }

  Widget _featureCard(IconData icon, String label, Color color) => Expanded(
    child: Container(
      padding: const EdgeInsets.symmetric(vertical: 18),
      decoration: BoxDecoration(
        color: _card,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: _cardBrd)),
      child: Column(mainAxisSize: MainAxisSize.min, children: [
        Icon(icon, color: color, size: 28),
        const SizedBox(height: 8),
        Text(label, style: TextStyle(color: _txt, fontSize: 12, fontWeight: FontWeight.w600)),
      ]),
    ));

  Widget _socialBtn(IconData icon, String label, Color color, String url) =>
    OutlinedButton.icon(
      style: OutlinedButton.styleFrom(
        side: BorderSide(color: color.withOpacity(0.5), width: 1.5),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
        backgroundColor: color.withOpacity(0.12),
        padding: const EdgeInsets.symmetric(vertical: 14)),
      icon: Icon(icon, color: color, size: 18),
      label: Text(label, style: TextStyle(color: _txt, fontSize: 13, fontWeight: FontWeight.bold)),
      onPressed: () => _openUrl(url));
}
