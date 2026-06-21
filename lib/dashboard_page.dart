// dashboard_page.dart
// Full convert dari dashboard.html (GENIUS) ke Flutter — full animation.
// Terhubung ke backend Node.js asli (lihat login_page.dart / splash.dart).

import 'dart:async';
import 'dart:convert';
import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';
import 'package:flutter/services.dart';
import 'package:http/http.dart' as http;
import 'package:intl/intl.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:device_info_plus/device_info_plus.dart';
import 'package:url_launcher/url_launcher.dart';

import 'login_page.dart' show baseUrl;
import 'seller_page.dart';
import 'device_dashboard.dart';
import 'chat.dart';

// ════════════════ HELPER: format tanggal & sisa hari dari data backend ════════════════
DateTime _parseExpired(String raw) {
  try {
    return DateTime.parse(raw);
  } catch (_) {
    return DateTime.now();
  }
}

String _formatExpired(String raw) => DateFormat('dd-MM-yyyy').format(_parseExpired(raw));
int _daysLeftOf(String raw) => _parseExpired(raw).difference(DateTime.now()).inDays;
bool _isActiveOf(String raw) => _daysLeftOf(raw) > 0;

/// Normalisasi item news dari backend.
/// Backend bisa kirim key `desc` atau `description` — ditangani fleksibel di sini.
String _newsDesc(Map<String, dynamic> n) =>
    (n['desc'] ?? n['description'] ?? n['content'] ?? '').toString();
String _newsTitle(Map<String, dynamic> n) => (n['title'] ?? n['judul'] ?? '').toString();

// ─────────────────────────── THEME / COLORS ───────────────────────────
class AppColors {
  static const bg = Color(0xFFF4F7FB);
  static const bgDeep = Color(0xFFE8EFFA);
  static const surface = Color(0xFFFFFFFF);
  static const cardGlass = Color(0xCCFFFFFF);

  static const blue = Color(0xFF2F80FF);
  static const blueDeep = Color(0xFF1A5FE0);
  static const blueSoft = Color(0xFF7FB1FF);
  static const blueFaint = Color(0xFFE5EEFF);

  static const textPrimary = Color(0xFF161D2E);
  static const textSec = Color(0xFF656E85);
  static const textMuted = Color(0xFFA0A7BD);

  static const shadow = Color(0x142A4B8E);
  static const shadowSoft = Color(0x0A2A4B8E);
}

class ShadowUtils {
  static List<BoxShadow> get card => const [
        BoxShadow(color: AppColors.shadow, blurRadius: 24, offset: Offset(0, 8)),
        BoxShadow(color: AppColors.shadowSoft, blurRadius: 4, offset: Offset(0, 1)),
      ];
  static List<BoxShadow> get soft => const [
        BoxShadow(color: AppColors.shadowSoft, blurRadius: 10, offset: Offset(0, 3)),
      ];
  static List<BoxShadow> get heavy => const [
        BoxShadow(color: AppColors.shadow, blurRadius: 30, offset: Offset(0, 12)),
      ];
}

// ─────────────────────────── GLASS CARD ───────────────────────────
class GlassCard extends StatefulWidget {
  final Widget child;
  final EdgeInsetsGeometry padding;
  final double radius;
  final VoidCallback? onTap;
  final Gradient? gradient;

  const GlassCard({
    super.key,
    required this.child,
    this.padding = const EdgeInsets.all(16),
    this.radius = 22,
    this.onTap,
    this.gradient,
  });

  @override
  State<GlassCard> createState() => _GlassCardState();
}

class _GlassCardState extends State<GlassCard> {
  bool _pressed = false;

  @override
  Widget build(BuildContext context) {
    final container = Container(
      padding: widget.padding,
      decoration: BoxDecoration(
        color: widget.gradient == null ? AppColors.cardGlass : null,
        gradient: widget.gradient,
        borderRadius: BorderRadius.circular(widget.radius),
        border: Border.all(color: AppColors.blue.withOpacity(0.10)),
        boxShadow: ShadowUtils.card,
      ),
      child: widget.child,
    );

    if (widget.onTap == null) return container;

    return GestureDetector(
      onTapDown: (_) => setState(() => _pressed = true),
      onTapUp: (_) => setState(() => _pressed = false),
      onTapCancel: () => setState(() => _pressed = false),
      onTap: () {
        HapticFeedback.lightImpact();
        widget.onTap!();
      },
      child: AnimatedScale(
        duration: const Duration(milliseconds: 140),
        scale: _pressed ? 0.97 : 1.0,
        child: AnimatedOpacity(
          duration: const Duration(milliseconds: 140),
          opacity: _pressed ? 0.88 : 1.0,
          child: container,
        ),
      ),
    );
  }
}

// ─────────────────────────── FADE IN UP ───────────────────────────
class FadeInUp extends StatefulWidget {
  final Widget child;
  final Duration delay;
  const FadeInUp({super.key, required this.child, this.delay = Duration.zero});

  @override
  State<FadeInUp> createState() => _FadeInUpState();
}

class _FadeInUpState extends State<FadeInUp> with SingleTickerProviderStateMixin {
  late AnimationController _c;
  late Animation<double> _opacity;
  late Animation<Offset> _offset;

  @override
  void initState() {
    super.initState();
    _c = AnimationController(vsync: this, duration: const Duration(milliseconds: 520));
    final curved = CurvedAnimation(parent: _c, curve: Curves.easeOutCubic);
    _opacity = Tween<double>(begin: 0, end: 1).animate(curved);
    _offset = Tween<Offset>(begin: const Offset(0, 0.06), end: Offset.zero).animate(curved);
    Future.delayed(widget.delay, () {
      if (mounted) _c.forward();
    });
  }

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return FadeTransition(
      opacity: _opacity,
      child: SlideTransition(position: _offset, child: widget.child),
    );
  }
}

// ─────────────────────────── PULSE DOT ───────────────────────────
class PulseDot extends StatefulWidget {
  final Color color;
  const PulseDot({super.key, this.color = AppColors.blue});
  @override
  State<PulseDot> createState() => _PulseDotState();
}

class _PulseDotState extends State<PulseDot> with SingleTickerProviderStateMixin {
  late AnimationController _c;
  late Animation<double> _a;

  @override
  void initState() {
    super.initState();
    _c = AnimationController(vsync: this, duration: const Duration(milliseconds: 900))..repeat(reverse: true);
    _a = Tween<double>(begin: 0.35, end: 1.0).animate(CurvedAnimation(parent: _c, curve: Curves.easeInOut));
  }

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return FadeTransition(
      opacity: _a,
      child: Container(
        width: 7,
        height: 7,
        decoration: BoxDecoration(
          color: widget.color,
          shape: BoxShape.circle,
          boxShadow: [BoxShadow(color: widget.color.withOpacity(0.5), blurRadius: 6)],
        ),
      ),
    );
  }
}

// ─────────────────────────── TYPEWRITER TITLE ───────────────────────────
class TypewriterText extends StatefulWidget {
  final String text;
  final TextStyle style;
  const TypewriterText({super.key, required this.text, required this.style});

  @override
  State<TypewriterText> createState() => _TypewriterTextState();
}

class _TypewriterTextState extends State<TypewriterText> {
  String _shown = '';
  Timer? _timer;
  Timer? _loop;
  bool _cursorOn = true;
  Timer? _blinkTimer;

  @override
  void initState() {
    super.initState();
    _run();
    _loop = Timer.periodic(const Duration(milliseconds: 9000), (_) => _run());
    _blinkTimer = Timer.periodic(const Duration(milliseconds: 400), (_) {
      if (mounted) setState(() => _cursorOn = !_cursorOn);
    });
  }

  void _run() {
    _timer?.cancel();
    int i = 0;
    setState(() => _shown = '');
    _timer = Timer.periodic(const Duration(milliseconds: 80), (t) {
      if (i >= widget.text.length) {
        t.cancel();
        return;
      }
      setState(() => _shown += widget.text[i]);
      i++;
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    _loop?.cancel();
    _blinkTimer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return RichText(
      text: TextSpan(style: widget.style, children: [
        TextSpan(text: _shown),
        TextSpan(
          text: '|',
          style: widget.style.copyWith(color: _cursorOn ? AppColors.blue : Colors.transparent),
        ),
      ]),
    );
  }
}

// ─────────────────────────── COUNT UP NUMBER ───────────────────────────
class CountUpNumber extends StatefulWidget {
  final int target;
  final TextStyle style;
  const CountUpNumber({super.key, required this.target, required this.style});

  @override
  State<CountUpNumber> createState() => _CountUpNumberState();
}

class _CountUpNumberState extends State<CountUpNumber> with SingleTickerProviderStateMixin {
  late AnimationController _c;
  late Animation<double> _a;

  @override
  void initState() {
    super.initState();
    _c = AnimationController(vsync: this, duration: const Duration(milliseconds: 800));
    _a = Tween<double>(begin: 0, end: widget.target.toDouble())
        .animate(CurvedAnimation(parent: _c, curve: Curves.easeOutCubic));
    _c.forward();
  }

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _a,
      builder: (_, __) => Text(_a.value.round().toString(), style: widget.style),
    );
  }
}

// ─────────────────────────── DASHBOARD PAGE ───────────────────────────
class DashboardPage extends StatefulWidget {
  final String username, password, role, expiredDate, sessionKey;
  final List<Map<String, dynamic>> listBug, listDoos;
  final List<dynamic> news;

  const DashboardPage({
    super.key,
    required this.username,
    required this.password,
    required this.role,
    required this.expiredDate,
    required this.listBug,
    required this.listDoos,
    required this.sessionKey,
    required this.news,
  });

  @override
  State<DashboardPage> createState() => _DashboardPageState();
}

class _DashboardPageState extends State<DashboardPage> with SingleTickerProviderStateMixin {
  int _navIndex = 0;
  final PageController _newsController = PageController(viewportFraction: 0.92);
  int _newsCurrent = 0;
  Timer? _newsAutoTimer;

  late AnimationController _blobController;

  @override
  void initState() {
    super.initState();
    _blobController = AnimationController(vsync: this, duration: const Duration(seconds: 16))..repeat();
    _newsAutoTimer = Timer.periodic(const Duration(seconds: 5), (_) {
      if (!_newsController.hasClients) return;
      _newsCurrent = (_newsCurrent + 1) % math.max(widget.news.length, 1);
      _newsController.animateToPage(_newsCurrent,
          duration: const Duration(milliseconds: 380), curve: Curves.easeOutCubic);
    });
  }

  @override
  void dispose() {
    _newsAutoTimer?.cancel();
    _newsController.dispose();
    _blobController.dispose();
    super.dispose();
  }

  void _openDrawerMenu() => _scaffoldKey.currentState?.openDrawer();

  void _openAccountSheet() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (_) => AccountSheet(
        username: widget.username,
        role: widget.role,
        expiredDate: widget.expiredDate,
        onLogout: () {
          Navigator.pop(context);
          _openLogoutDialog();
        },
      ),
    );
  }

  void _openLogoutDialog() {
    showDialog(
      context: context,
      builder: (_) => LogoutDialog(
        onConfirm: () async {
          Navigator.pop(context);
          final prefs = await SharedPreferences.getInstance();
          await prefs.remove('username');
          await prefs.remove('password');
          await prefs.remove('key');
          if (!mounted) return;
          Navigator.pushAndRemoveUntil(
            context,
            MaterialPageRoute(builder: (_) => const LoginPage()),
            (route) => false,
          );
        },
      ),
    );
  }

  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();

  @override
  Widget build(BuildContext context) {
    final daysLeft = math.max(_daysLeftOf(widget.expiredDate), 0);
    final progressPct = (math.min(1, math.max(0, _daysLeftOf(widget.expiredDate) / 30))).toDouble();

    return Scaffold(
      key: _scaffoldKey,
      backgroundColor: AppColors.bg,
      drawer: AppDrawer(
        username: widget.username,
        role: widget.role,
        onSeller: () {
          Navigator.pop(context);
          ScaffoldMessenger.of(context)
              .showSnackBar(const SnackBar(content: Text('Seller Page (contoh navigasi)')));
          // Navigator.push(context, MaterialPageRoute(builder: (_) => const SellerPage()));
        },
        onLogout: () {
          Navigator.pop(context);
          _openLogoutDialog();
        },
      ),
      body: SafeArea(
        bottom: false,
        child: Column(
          children: [
            _AppBarRow(onMenuTap: _openDrawerMenu, onAvatarTap: _openAccountSheet),
            Expanded(
              child: Stack(
                children: [
                  AnimatedBuilder(
                    animation: _blobController,
                    builder: (context, _) => CustomPaint(
                      painter: _BlobPainter(t: _blobController.value),
                      size: Size.infinite,
                    ),
                  ),
                  ListView(
                    padding: const EdgeInsets.fromLTRB(16, 16, 16, 120),
                    children: [
                      FadeInUp(
                        delay: Duration.zero,
                        child: _ProfileHero(
          username: widget.username,
          role: widget.role,
          expiredDate: widget.expiredDate,
          daysLeft: daysLeft,
        ),
                      ),
                      const SizedBox(height: 16),
                      FadeInUp(
                        delay: const Duration(milliseconds: 80),
                        child: _StatusGrid(
          expiredDate: widget.expiredDate,
          daysLeft: daysLeft,
          progressPct: progressPct,
        ),
                      ),
                      const SizedBox(height: 20),
                      FadeInUp(
                        delay: const Duration(milliseconds: 140),
                        child: const _SectionLabel(icon: Icons.article_outlined, label: 'NEWS & UPDATE'),
                      ),
                      FadeInUp(
                        delay: const Duration(milliseconds: 160),
                        child: _NewsCarousel(
                          news: widget.news,
                          controller: _newsController,
                          current: _newsCurrent,
                          onDot: (i) {
                            _newsCurrent = i;
                            _newsController.animateToPage(i,
                                duration: const Duration(milliseconds: 380), curve: Curves.easeOutCubic);
                          },
                          onPageChanged: (i) => setState(() => _newsCurrent = i),
                        ),
                      ),
                      const SizedBox(height: 20),
                      FadeInUp(
                        delay: const Duration(milliseconds: 180),
                        child: const _SectionLabel(icon: Icons.sports_esports_outlined, label: 'RETRO ARCADE'),
                      ),
                      FadeInUp(
                        delay: const Duration(milliseconds: 190),
                        child: const DinoRunGame(),
                      ),
                      const SizedBox(height: 20),
                      FadeInUp(
                        delay: const Duration(milliseconds: 200),
                        child: const _SectionLabel(icon: Icons.bar_chart_rounded, label: 'STATISTIK PENGGUNA'),
                      ),
                      FadeInUp(
                        delay: const Duration(milliseconds: 210),
                        child: const UserGraphCard(),
                      ),
                      const SizedBox(height: 20),
                      FadeInUp(
                        delay: const Duration(milliseconds: 220),
                        child: GlassCard(
                          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                          radius: 18,
                          onTap: () {
                            // launchUrl(Uri.parse('https://example.com/thanks_to.html'));
                          },
                          child: Row(
                            children: [
                              _miniIconBox(Icons.favorite_rounded),
                              const SizedBox(width: 12),
                              const Expanded(
                                child: Text('Thanks To — orang yang berkontribusi',
                                    style: TextStyle(fontWeight: FontWeight.w600, fontSize: 12.5)),
                              ),
                              const Icon(Icons.chevron_right, color: AppColors.blue, size: 18),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
      bottomNavigationBar: BottomNavBar(
        index: _navIndex,
        onChanged: (i) {
          HapticFeedback.selectionClick();
          setState(() => _navIndex = i);
        },
      ),
    );
  }

  static Widget _miniIconBox(IconData icon) => Container(
        width: 32,
        height: 32,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(12),
          gradient: const LinearGradient(colors: [AppColors.blueSoft, AppColors.blue]),
        ),
        child: Icon(icon, color: Colors.white, size: 15),
      );
}

// ─────────────────────────── APP BAR ───────────────────────────
class _AppBarRow extends StatelessWidget {
  final VoidCallback onMenuTap;
  final VoidCallback onAvatarTap;
  const _AppBarRow({required this.onMenuTap, required this.onAvatarTap});

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 64,
      padding: const EdgeInsets.symmetric(horizontal: 16),
      decoration: const BoxDecoration(
        color: AppColors.surface,
        border: Border(bottom: BorderSide(color: AppColors.blueFaint)),
      ),
      child: Row(
        children: [
          _IconBtn(icon: Icons.menu, onTap: onMenuTap),
          const SizedBox(width: 14),
          Expanded(
            child: TypewriterText(
              text: 'GENIUS',
              style: const TextStyle(
                  fontWeight: FontWeight.w800, fontSize: 17, letterSpacing: 1.5, color: AppColors.textPrimary),
            ),
          ),
          GestureDetector(
            onTap: onAvatarTap,
            child: Container(
              width: 34,
              height: 34,
              padding: const EdgeInsets.all(2),
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: const LinearGradient(colors: [AppColors.blueSoft, AppColors.blue]),
                boxShadow: ShadowUtils.soft,
              ),
              child: const CircleAvatar(
                backgroundColor: Colors.white,
                child: Icon(Icons.person, color: AppColors.blue, size: 16),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _IconBtn extends StatelessWidget {
  final IconData icon;
  final VoidCallback onTap;
  const _IconBtn({required this.icon, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 34,
        height: 34,
        decoration: BoxDecoration(color: AppColors.blueFaint, borderRadius: BorderRadius.circular(12)),
        child: Icon(icon, size: 18, color: AppColors.blueDeep),
      ),
    );
  }
}

// ─────────────────────────── BACKGROUND BLOBS ───────────────────────────
class _BlobPainter extends CustomPainter {
  final double t;
  const _BlobPainter({required this.t});

  @override
  void paint(Canvas canvas, Size size) {
    final a1 = math.sin(t * 2 * math.pi) * 16;
    final p1 = Paint()
      ..shader = RadialGradient(colors: [
        AppColors.blueSoft.withOpacity(0.28),
        Colors.transparent,
      ]).createShader(Rect.fromCircle(center: Offset(-20 + a1, -40 + a1), radius: 160));
    canvas.drawCircle(Offset(-20 + a1, -40 + a1), 160, p1);

    final a2 = math.sin(t * 2 * math.pi + 2) * 14;
    final p2 = Paint()
      ..shader = RadialGradient(colors: [
        AppColors.blue.withOpacity(0.16),
        Colors.transparent,
      ]).createShader(Rect.fromCircle(center: Offset(size.width + 20 + a2, size.height * 0.4 + a2), radius: 150));
    canvas.drawCircle(Offset(size.width + 20 + a2, size.height * 0.4 + a2), 150, p2);
  }

  @override
  bool shouldRepaint(covariant _BlobPainter oldDelegate) => oldDelegate.t != t;
}

// ─────────────────────────── SECTION LABEL ───────────────────────────
class _SectionLabel extends StatelessWidget {
  final IconData icon;
  final String label;
  const _SectionLabel({required this.icon, required this.label});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10, top: 4),
      child: Row(
        children: [
          Container(
            width: 26,
            height: 26,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(10),
              gradient: const LinearGradient(colors: [AppColors.blueSoft, AppColors.blue]),
              boxShadow: ShadowUtils.soft,
            ),
            child: Icon(icon, size: 13, color: Colors.white),
          ),
          const SizedBox(width: 8),
          Text(label,
              style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w800, letterSpacing: 1.2)),
        ],
      ),
    );
  }
}

// ─────────────────────────── PROFILE HERO ───────────────────────────
class _ProfileHero extends StatelessWidget {
  final String username, role, expiredDate;
  final int daysLeft;
  const _ProfileHero({
    required this.username,
    required this.role,
    required this.expiredDate,
    required this.daysLeft,
  });

  @override
  Widget build(BuildContext context) {
    return GlassCard(
      padding: const EdgeInsets.all(20),
      gradient: LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: [Colors.white.withOpacity(0.9), AppColors.blueFaint.withOpacity(0.7)],
      ),
      child: Row(
        children: [
          Container(
            width: 64,
            height: 64,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: const LinearGradient(colors: [AppColors.blue, AppColors.blueDeep]),
              boxShadow: ShadowUtils.card,
            ),
            child: const Icon(Icons.person, color: Colors.white, size: 30),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Flexible(
                      child: Text(
                        username,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w800),
                      ),
                    ),
                    const SizedBox(width: 8),
                    const PulseDot(),
                  ],
                ),
                const SizedBox(height: 6),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: AppColors.blue.withOpacity(0.10),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Text(role.toUpperCase(),
                      style: const TextStyle(
                          color: AppColors.blueDeep, fontSize: 10, fontWeight: FontWeight.w800, letterSpacing: 0.6)),
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    const Icon(Icons.event, size: 11, color: AppColors.textMuted),
                    const SizedBox(width: 4),
                    Text('Berlaku hingga ${user.expiredDisplay}',
                        style: const TextStyle(color: AppColors.textMuted, fontSize: 11)),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────── STATUS GRID ───────────────────────────
class _StatusGrid extends StatelessWidget {
  final String expiredDate;
  final int daysLeft;
  final double progressPct;
  const _StatusGrid({required this.expiredDate, required this.daysLeft, required this.progressPct});

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Expanded(
          flex: 3,
          child: GlassCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      width: 30,
                      height: 30,
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(12),
                        gradient: const LinearGradient(colors: [AppColors.blue, AppColors.blueDeep]),
                        boxShadow: ShadowUtils.soft,
                      ),
                      child: const Icon(Icons.shield_outlined, size: 15, color: Colors.white),
                    ),
                    const SizedBox(width: 10),
                    const Text('MASA AKTIF',
                        style: TextStyle(
                            color: AppColors.textMuted, fontSize: 9.5, fontWeight: FontWeight.w800, letterSpacing: 1.2)),
                  ],
                ),
                const SizedBox(height: 14),
                Row(
                  crossAxisAlignment: CrossAxisAlignment.baseline,
                  textBaseline: TextBaseline.alphabetic,
                  children: [
                    CountUpNumber(
                      target: daysLeft,
                      style: const TextStyle(color: AppColors.blueDeep, fontSize: 30, fontWeight: FontWeight.w800, height: 1),
                    ),
                    const SizedBox(width: 6),
                    const Text('hari', style: TextStyle(color: AppColors.textMuted, fontSize: 12, fontWeight: FontWeight.w600)),
                  ],
                ),
                const SizedBox(height: 10),
                ClipRRect(
                  borderRadius: BorderRadius.circular(6),
                  child: Container(
                    height: 6,
                    color: AppColors.blueFaint,
                    alignment: Alignment.centerLeft,
                    child: TweenAnimationBuilder<double>(
                      duration: const Duration(milliseconds: 800),
                      curve: Curves.easeOutCubic,
                      tween: Tween(begin: 0, end: progressPct),
                      builder: (context, value, _) => FractionallySizedBox(
                        widthFactor: value,
                        child: Container(color: AppColors.blue),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          flex: 2,
          child: GlassCard(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Container(
                  width: 42,
                  height: 42,
                  decoration: BoxDecoration(color: AppColors.blue.withOpacity(0.10), shape: BoxShape.circle),
                  child: Icon(
                    _isActiveOf(expiredDate) ? Icons.verified_rounded : Icons.error_outline_rounded,
                    color: AppColors.blue,
                    size: 22,
                  ),
                ),
                const SizedBox(height: 8),
                Text(_isActiveOf(expiredDate) ? 'AKTIF' : 'EXPIRED',
                    style: const TextStyle(
                        color: AppColors.blueDeep, fontSize: 11, fontWeight: FontWeight.w800, letterSpacing: 0.6)),
                const SizedBox(height: 2),
                Text(_formatExpired(expiredDate), style: const TextStyle(color: AppColors.textMuted, fontSize: 9.5)),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

// ─────────────────────────── NEWS CAROUSEL ───────────────────────────
class _NewsCarousel extends StatelessWidget {
  final List<dynamic> news;
  final PageController controller;
  final int current;
  final ValueChanged<int> onDot;
  final ValueChanged<int> onPageChanged;

  const _NewsCarousel({
    required this.news,
    required this.controller,
    required this.current,
    required this.onDot,
    required this.onPageChanged,
  });

  @override
  Widget build(BuildContext context) {
    if (news.isEmpty) {
      return Container(
        height: 190,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: AppColors.blueFaint.withOpacity(0.5),
          borderRadius: BorderRadius.circular(22),
        ),
        child: const Text('Belum ada update', style: TextStyle(color: AppColors.textMuted, fontSize: 12)),
      );
    }
    return Column(
      children: [
        SizedBox(
          height: 190,
          child: PageView.builder(
            controller: controller,
            itemCount: news.length,
            onPageChanged: onPageChanged,
            itemBuilder: (context, i) {
              final n = Map<String, dynamic>.from(news[i] as Map);
              return Padding(
                padding: const EdgeInsets.symmetric(horizontal: 5),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(22),
                  child: Stack(
                    fit: StackFit.expand,
                    children: [
                      Container(
                        decoration: const BoxDecoration(
                          gradient: LinearGradient(colors: [AppColors.blueSoft, AppColors.blue]),
                        ),
                        child: const Center(
                          child: Icon(Icons.article_outlined, size: 38, color: Colors.white70),
                        ),
                      ),
                      Container(
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            begin: Alignment.topCenter,
                            end: Alignment.bottomCenter,
                            colors: [Colors.transparent, AppColors.blueDeep.withOpacity(0.75)],
                            stops: const [0.4, 1],
                          ),
                        ),
                      ),
                      Positioned(
                        left: 14,
                        right: 14,
                        bottom: 14,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(_newsTitle(n),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 14)),
                            const SizedBox(height: 4),
                            Text(_newsDesc(n),
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                                style: TextStyle(color: Colors.white.withOpacity(0.75), fontSize: 11)),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              );
            },
          ),
        ),
        const SizedBox(height: 12),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: List.generate(news.length, (i) {
            final active = i == current;
            return GestureDetector(
              onTap: () => onDot(i),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 250),
                curve: Curves.easeOutCubic,
                margin: const EdgeInsets.symmetric(horizontal: 3),
                width: active ? 22 : 6,
                height: 5,
                decoration: BoxDecoration(
                  color: active ? AppColors.blue : AppColors.blueFaint,
                  borderRadius: BorderRadius.circular(3),
                ),
              ),
            );
          }),
        ),
      ],
    );
  }
}

// ─────────────────────────── DINO RUN GAME ───────────────────────────
class DinoRunGame extends StatefulWidget {
  const DinoRunGame({super.key});

  @override
  State<DinoRunGame> createState() => _DinoRunGameState();
}

enum _GameState { idle, running, over }

class _Obstacle {
  double x;
  final double w;
  final double h;
  final int variant;
  _Obstacle({required this.x, required this.w, required this.h, required this.variant});
}

class _DinoRunGameState extends State<DinoRunGame> with SingleTickerProviderStateMixin {
  static const double groundY = 26;
  static const double playerW = 30, playerH = 34;
  static const double hitInset = 4;
  static const double gravity = 2300;
  static const double jumpVelocity = 480;
  static const double baseSpeed = 230;

  _GameState _state = _GameState.idle;
  double _velocityY = 0;
  double _playerBottom = groundY;
  double _speed = baseSpeed;
  double _score = 0;
  int _best = 0;
  final List<_Obstacle> _obstacles = [];
  double _spawnTimer = 0;
  double _nextSpawnAt = 900;
  Duration _lastTick = Duration.zero;
  Ticker? _ticker;
  final math.Random _rng = math.Random();
  double _boxWidth = 300;

  @override
  void dispose() {
    _ticker?.dispose();
    super.dispose();
  }

  void _resetGame() {
    _obstacles.clear();
    _velocityY = 0;
    _playerBottom = groundY;
    _speed = baseSpeed;
    _score = 0;
    _spawnTimer = 0;
    _nextSpawnAt = 900;
  }

  void _startGame() {
    _resetGame();
    _state = _GameState.running;
    _lastTick = Duration.zero;
    _ticker ??= createTicker(_onTick);
    _ticker!.start();
    setState(() {});
  }

  void _gameOver() {
    _state = _GameState.over;
    _best = math.max(_best, _score.floor());
    _ticker?.stop();
    setState(() {});
  }

  void _spawnObstacle() {
    final variant = _rng.nextInt(3);
    const sizes = [
      [16.0, 30.0],
      [12.0, 22.0],
      [22.0, 26.0],
    ];
    final s = sizes[variant];
    _obstacles.add(_Obstacle(x: _boxWidth + 10, w: s[0], h: s[1], variant: variant));
  }

  void _onTick(Duration elapsed) {
    if (_state != _GameState.running) return;
    if (_lastTick == Duration.zero) _lastTick = elapsed;
    final dt = math.min(0.032, (elapsed - _lastTick).inMicroseconds / 1e6);
    _lastTick = elapsed;

    _speed = baseSpeed + math.min(220, _score * 2.2);

    _velocityY -= gravity * dt;
    _playerBottom += _velocityY * dt;
    if (_playerBottom <= groundY) {
      _playerBottom = groundY;
      _velocityY = 0;
    }

    _spawnTimer += dt * 1000;
    if (_spawnTimer >= _nextSpawnAt) {
      _spawnTimer = 0;
      _nextSpawnAt = (750 + _rng.nextDouble() * 750 - math.min(300, _score * 3)).clamp(420, double.infinity);
      _spawnObstacle();
    }

    final pLeft = 30 + hitInset, pRight = 30 + playerW - hitInset;
    final pBottom = _playerBottom, pTop = _playerBottom + playerH;

    for (int i = _obstacles.length - 1; i >= 0; i--) {
      final o = _obstacles[i];
      o.x -= _speed * dt;
      if (o.x < -30) {
        _obstacles.removeAt(i);
        continue;
      }
      final obLeft = o.x + hitInset, obRight = o.x + o.w - hitInset;
      const obBottom = groundY;
      final obTop = groundY + o.h;
      final xOverlap = obRight > pLeft && obLeft < pRight;
      final yOverlap = pBottom < obTop && pTop > obBottom;
      if (xOverlap && yOverlap) {
        _gameOver();
        return;
      }
    }

    _score += dt * 12;
    setState(() {});
  }

  void _jumpOrStart() {
    if (_state == _GameState.idle || _state == _GameState.over) {
      _startGame();
      return;
    }
    if (_state == _GameState.running && _playerBottom == groundY) {
      _velocityY = jumpVelocity;
      HapticFeedback.lightImpact();
    }
  }

  Color _cactusColor(int variant) {
    switch (variant) {
      case 0:
        return const Color(0xFF3DBB6B);
      case 1:
        return const Color(0xFF2E9B57);
      default:
        return const Color(0xFF56CE82);
    }
  }

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(builder: (context, constraints) {
      _boxWidth = constraints.maxWidth;
      return GestureDetector(
        onTap: _jumpOrStart,
        child: Container(
          height: 190,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(22),
            border: Border.all(color: AppColors.blue.withOpacity(0.25), width: 1.5),
            boxShadow: ShadowUtils.card,
            gradient: const LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [Color(0xFFBFE6FF), Color(0xFFE8F6FF), Color(0xFFFFF3D6)],
              stops: [0, 0.55, 1],
            ),
          ),
          clipBehavior: Clip.hardEdge,
          child: Stack(
            children: [
              // sun
              Positioned(
                top: 14,
                right: 20,
                child: Container(
                  width: 30,
                  height: 30,
                  decoration: const BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: RadialGradient(colors: [Color(0xFFFFE45C), Color(0xFFFFC93C)]),
                    boxShadow: [BoxShadow(color: Color(0xB3FFC93C), blurRadius: 18)],
                  ),
                ),
              ),
              // ground dashed line
              Positioned(
                left: 0,
                right: 0,
                bottom: groundY,
                child: CustomPaint(painter: _DashedLinePainter(), size: const Size(double.infinity, 3)),
              ),
              // floor
              const Positioned(
                left: 0,
                right: 0,
                bottom: 0,
                height: groundY,
                child: DecoratedBox(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: [Color(0xFFD9C29A), Color(0xFFC7AC7B)],
                    ),
                  ),
                ),
              ),
              // obstacles
              for (final o in _obstacles)
                Positioned(
                  left: o.x,
                  bottom: groundY,
                  width: o.w,
                  height: o.h,
                  child: Container(
                    decoration: BoxDecoration(
                      color: _cactusColor(o.variant),
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                ),
              // player
              Positioned(
                left: 30,
                bottom: _playerBottom,
                width: playerW,
                height: playerH,
                child: const Icon(Icons.pets, color: Color(0xFF3DBB6B), size: 28),
              ),
              // badges
              Positioned(
                top: 12,
                left: 12,
                child: _gameBadge('DINO RUN', AppColors.blueDeep),
              ),
              Positioned(
                top: 12,
                right: 12,
                child: _gameBadge('SCORE ${_score.floor().toString().padLeft(4, '0')}', const Color(0xFFE0822A)),
              ),
              if (_state == _GameState.idle)
                const Positioned(
                  bottom: 32,
                  left: 0,
                  right: 0,
                  child: Text(
                    'TAP TO START',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                        color: AppColors.blueDeep,
                        fontFamily: 'monospace',
                        fontWeight: FontWeight.bold,
                        fontSize: 10,
                        letterSpacing: 3),
                  ),
                ),
              if (_state == _GameState.over)
                Positioned.fill(
                  child: Container(
                    color: AppColors.bg.withOpacity(0.55),
                    alignment: Alignment.center,
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Text('GAME OVER',
                            style: TextStyle(
                                fontWeight: FontWeight.w900,
                                fontSize: 16,
                                color: Color(0xFFE0473D),
                                letterSpacing: 1.5,
                                fontFamily: 'monospace')),
                        const SizedBox(height: 6),
                        Text('Tap untuk main lagi · Best $_best',
                            style: const TextStyle(fontSize: 11, color: AppColors.textSec, fontFamily: 'monospace')),
                      ],
                    ),
                  ),
                ),
            ],
          ),
        ),
      );
    });
  }

  Widget _gameBadge(String text, Color color) => Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
        decoration: BoxDecoration(
          color: Colors.white.withOpacity(0.55),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: AppColors.blue.withOpacity(0.2)),
        ),
        child: Text(text,
            style: TextStyle(
                color: color, fontWeight: FontWeight.w900, fontSize: 11, fontFamily: 'monospace', letterSpacing: 1)),
      );
}

class _DashedLinePainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = AppColors.blueSoft
      ..strokeWidth = size.height;
    double x = 0;
    while (x < size.width) {
      canvas.drawLine(Offset(x, size.height / 2), Offset(x + 14, size.height / 2), paint);
      x += 22;
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

// ─────────────────────────── USER GRAPH ───────────────────────────
class UserGraphCard extends StatefulWidget {
  const UserGraphCard({super.key});

  @override
  State<UserGraphCard> createState() => _UserGraphCardState();
}

class _UserGraphCardState extends State<UserGraphCard> {
  late List<double> _values;
  late int _total;
  static const labels = ['Sen', 'Sel', 'Rab', 'Kam', 'Jum', 'Sab', 'Min'];

  @override
  void initState() {
    super.initState();
    final rng = math.Random();
    _values = List.generate(7, (_) => 40 + rng.nextDouble() * 160);
    _total = _values.fold(0.0, (a, b) => a + b).round();
  }

  @override
  Widget build(BuildContext context) {
    final maxV = _values.reduce(math.max);
    return GlassCard(
      child: SizedBox(
        height: 134,
        child: Column(
          children: [
            Row(
              children: [
                Container(
                  width: 25,
                  height: 25,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(8),
                    gradient: const LinearGradient(colors: [AppColors.blueSoft, AppColors.blue]),
                  ),
                  child: const Icon(Icons.bar_chart_rounded, size: 13, color: Colors.white),
                ),
                const SizedBox(width: 8),
                const Text('Pengguna Mingguan', style: TextStyle(fontWeight: FontWeight.w800, fontSize: 12)),
                const Spacer(),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(color: AppColors.blueFaint, borderRadius: BorderRadius.circular(10)),
                  child: Text('$_total total',
                      style: const TextStyle(color: AppColors.blueDeep, fontSize: 10, fontWeight: FontWeight.bold)),
                ),
              ],
            ),
            const SizedBox(height: 10),
            Expanded(
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: List.generate(_values.length, (i) {
                  final isLast = i == _values.length - 1;
                  final h = _values[i] / maxV;
                  return Expanded(
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 2),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        mainAxisAlignment: MainAxisAlignment.end,
                        children: [
                          Expanded(
                            child: Align(
                              alignment: Alignment.bottomCenter,
                              child: TweenAnimationBuilder<double>(
                                duration: const Duration(milliseconds: 900),
                                curve: Curves.easeOutCubic,
                                tween: Tween(begin: 0, end: h),
                                builder: (context, value, _) => FractionallySizedBox(
                                  heightFactor: value,
                                  child: Container(
                                    decoration: BoxDecoration(
                                      borderRadius: const BorderRadius.vertical(top: Radius.circular(6)),
                                      gradient: LinearGradient(
                                        begin: Alignment.bottomCenter,
                                        end: Alignment.topCenter,
                                        colors: isLast
                                            ? [AppColors.blueDeep, AppColors.blue]
                                            : [AppColors.blueSoft.withOpacity(0.7), AppColors.blue.withOpacity(0.85)],
                                      ),
                                    ),
                                  ),
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(height: 6),
                          Text(labels[i],
                              style: const TextStyle(fontSize: 9, fontWeight: FontWeight.w600, color: AppColors.textMuted)),
                        ],
                      ),
                    ),
                  );
                }),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ─────────────────────────── BOTTOM NAV ───────────────────────────
class BottomNavBar extends StatelessWidget {
  final int index;
  final ValueChanged<int> onChanged;
  const BottomNavBar({super.key, required this.index, required this.onChanged});

  static const _items = [
    (Icons.grid_view_rounded, 'Home'),
    (Icons.chat_bubble_outline_rounded, 'Chat'),
    (Icons.devices_other_rounded, 'Device'),
  ];

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(24, 0, 24, 18),
      child: Container(
        height: 66,
        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 8),
        decoration: BoxDecoration(
          color: Colors.white.withOpacity(0.75),
          borderRadius: BorderRadius.circular(24),
          border: Border.all(color: AppColors.blue.withOpacity(0.10)),
          boxShadow: ShadowUtils.heavy,
        ),
        child: Row(
          children: List.generate(_items.length, (i) {
            final active = i == index;
            final (icon, label) = _items[i];
            return Expanded(
              child: GestureDetector(
                onTap: () => onChanged(i),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 280),
                  margin: const EdgeInsets.symmetric(horizontal: 3),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(16),
                    gradient: active ? const LinearGradient(colors: [AppColors.blueSoft, AppColors.blue]) : null,
                    boxShadow: active ? [const BoxShadow(color: Color(0x4D2F80FF), blurRadius: 14, offset: Offset(0, 4))] : null,
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(icon, size: 19, color: active ? Colors.white : AppColors.textMuted),
                      if (active) ...[
                        const SizedBox(width: 7),
                        Text(label, style: const TextStyle(fontSize: 12.5, fontWeight: FontWeight.bold, color: Colors.white)),
                      ],
                    ],
                  ),
                ),
              ),
            );
          }),
        ),
      ),
    );
  }
}

// ─────────────────────────── DRAWER ───────────────────────────
class AppDrawer extends StatelessWidget {
  final String username, role;
  final VoidCallback onSeller;
  final VoidCallback onLogout;
  const AppDrawer({super.key, required this.username, required this.role, required this.onSeller, required this.onLogout});

  @override
  Widget build(BuildContext context) {
    return Drawer(
      backgroundColor: AppColors.surface,
      child: Column(
        children: [
          Container(
            height: 200,
            width: double.infinity,
            decoration: const BoxDecoration(
              gradient: LinearGradient(colors: [AppColors.blueSoft, AppColors.blueDeep]),
            ),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Container(
                  width: 80,
                  height: 80,
                  decoration: BoxDecoration(color: Colors.white.withOpacity(0.18), shape: BoxShape.circle),
                  child: const Icon(Icons.person, color: Colors.white, size: 38),
                ),
                const SizedBox(height: 10),
                Text(username, style: const TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold)),
                const SizedBox(height: 4),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
                  decoration: BoxDecoration(color: Colors.white.withOpacity(0.22), borderRadius: BorderRadius.circular(12)),
                  child: Text(role.toUpperCase(), style: const TextStyle(color: Colors.white, fontSize: 9, fontWeight: FontWeight.bold)),
                ),
              ],
            ),
          ),
          Expanded(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  _DrawerItem(icon: Icons.storefront_outlined, title: 'Seller Page', onTap: onSeller),
                  const Divider(height: 24, color: AppColors.blueFaint),
                  _DrawerItem(icon: Icons.logout_rounded, title: 'Logout', color: AppColors.blueDeep, onTap: onLogout),
                  const Spacer(),
                  const Center(
                    child: Text('GENIUS', style: TextStyle(color: AppColors.textMuted, fontSize: 9, letterSpacing: 2)),
                  ),
                  const SizedBox(height: 8),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _DrawerItem extends StatefulWidget {
  final IconData icon;
  final String title;
  final Color? color;
  final VoidCallback onTap;
  const _DrawerItem({required this.icon, required this.title, this.color, required this.onTap});

  @override
  State<_DrawerItem> createState() => _DrawerItemState();
}

class _DrawerItemState extends State<_DrawerItem> {
  bool _pressed = false;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTapDown: (_) => setState(() => _pressed = true),
      onTapUp: (_) => setState(() => _pressed = false),
      onTapCancel: () => setState(() => _pressed = false),
      onTap: widget.onTap,
      child: AnimatedScale(
        duration: const Duration(milliseconds: 100),
        scale: _pressed ? 0.98 : 1.0,
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 6),
          child: Row(
            children: [
              Container(
                width: 34,
                height: 34,
                decoration: BoxDecoration(color: AppColors.blueFaint, borderRadius: BorderRadius.circular(10)),
                child: Icon(widget.icon, size: 18, color: widget.color ?? AppColors.blue),
              ),
              const SizedBox(width: 14),
              Text(widget.title,
                  style: TextStyle(fontSize: 14, fontWeight: FontWeight.w500, color: widget.color ?? AppColors.textPrimary)),
            ],
          ),
        ),
      ),
    );
  }
}

// ─────────────────────────── ACCOUNT SHEET ───────────────────────────
class AccountSheet extends StatelessWidget {
  final String username, role, expiredDate;
  final VoidCallback onLogout;
  const AccountSheet({
    super.key,
    required this.username,
    required this.role,
    required this.expiredDate,
    required this.onLogout,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 28),
      decoration: const BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(width: 40, height: 4, decoration: BoxDecoration(color: AppColors.blueFaint, borderRadius: BorderRadius.circular(2))),
          const SizedBox(height: 18),
          TweenAnimationBuilder<double>(
            duration: const Duration(milliseconds: 400),
            curve: Curves.easeOutBack,
            tween: Tween(begin: 0.8, end: 1.0),
            builder: (context, v, child) => Transform.scale(scale: v, child: child),
            child: Container(
              width: 68,
              height: 68,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: const LinearGradient(colors: [AppColors.blueSoft, AppColors.blueDeep]),
                boxShadow: ShadowUtils.card,
              ),
              child: const Icon(Icons.person, color: Colors.white, size: 34),
            ),
          ),
          const SizedBox(height: 10),
          Text(username, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
          const SizedBox(height: 6),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
            decoration: BoxDecoration(color: AppColors.blueFaint, borderRadius: BorderRadius.circular(12)),
            child: Text(role.toUpperCase(), style: const TextStyle(color: AppColors.blueDeep, fontSize: 9, fontWeight: FontWeight.bold)),
          ),
          const SizedBox(height: 12),
          Text('Berlaku: ${user.expiredDisplay}', style: const TextStyle(color: AppColors.textSec, fontSize: 12)),
          const SizedBox(height: 20),
          Row(
            children: [
              Expanded(
                child: TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text('Tutup', style: TextStyle(color: AppColors.textMuted, fontWeight: FontWeight.w600)),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: ElevatedButton(
                  onPressed: onLogout,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.blueDeep,
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    elevation: 0,
                  ),
                  child: const Text('Logout', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────── LOGOUT DIALOG ───────────────────────────
class LogoutDialog extends StatelessWidget {
  final VoidCallback onConfirm;
  const LogoutDialog({super.key, required this.onConfirm});

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: Colors.transparent,
      child: Container(
        padding: const EdgeInsets.all(24),
        constraints: const BoxConstraints(maxWidth: 320),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [Colors.white.withOpacity(0.96), AppColors.blueFaint.withOpacity(0.8)],
          ),
          borderRadius: BorderRadius.circular(26),
          border: Border.all(color: AppColors.blue.withOpacity(0.14)),
          boxShadow: ShadowUtils.heavy,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(16),
                gradient: const LinearGradient(colors: [AppColors.blueSoft, AppColors.blueDeep]),
              ),
              child: const Icon(Icons.logout_rounded, color: Colors.white, size: 24),
            ),
            const SizedBox(height: 12),
            const Text('Konfirmasi Logout', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
            const SizedBox(height: 8),
            const Text('Yakin ingin logout?', style: TextStyle(color: AppColors.textSec, fontSize: 13), textAlign: TextAlign.center),
            const SizedBox(height: 18),
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text('Batal', style: TextStyle(color: AppColors.textMuted)),
                ),
                const SizedBox(width: 8),
                ElevatedButton(
                  onPressed: onConfirm,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.blueDeep,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    elevation: 0,
                  ),
                  child: const Text('Logout', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
