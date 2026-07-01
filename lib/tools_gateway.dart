import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'manage_server.dart';
import 'wifi_internal.dart';
import 'wifi_external.dart';
import 'ddos_panel.dart';
import 'nik_check.dart';
import 'tiktok_page.dart';
import 'instagram_page.dart';
import 'qr_gen.dart';
import 'domain_page.dart';
import 'spam_ngl.dart';
import 'phone_lookup.dart';
import 'email_osint.dart';
import 'ip_scanner.dart';
import 'port_scanner.dart';
import 'dracin_page.dart';
import 'device_dashboard.dart';
import 'anime_home.dart';
import 'hentai.dart';

// ─── TOOLS BARU ──────────────────────────────────────────────────────────────
import 'quiz_page.dart';
import 'gunting_batu.dart';
import 'gemes_tools.dart';
import 'tic_tac_toe.dart';
import 'kata_kata_page.dart';

// ─── PALETTE RAINBOW CYBER ENGINE ──────────────────────────────────────────
class _C {
  static const bg          = Color(0xFF0A0015);
  static const surface     = Color(0xFF15002A);
  static const card        = Color(0xFF1A0A2E);
  static const cardInner   = Color(0xFF2D1B4E);
  static const border      = Color(0xFF5B2D8E);
  static const borderLit   = Color(0xFF7C3AED);

  // Warna-warni neon
  static const purple      = Color(0xFF7C3AED);
  static const purpleL     = Color(0xFFA78BFA);
  static const purpleG     = Color(0xFFF0ABFC);
  static const pink        = Color(0xFFE879F9);
  static const cyan        = Color(0xFF67E8F9);
  static const blue        = Color(0xFF60A5FA);
  static const green       = Color(0xFF34D399);
  static const yellow      = Color(0xFFFBBF24);
  static const orange      = Color(0xFFFB923C);
  static const red         = Color(0xFFF87171);
  static const rose        = Color(0xFFFB7185);
  static const teal        = Color(0xFF2DD4BF);
  static const indigo      = Color(0xFF818CF8);
  static const gold        = Color(0xFFFFD700);

  static const text        = Color(0xFFF3E8FF);
  static const textSub     = Color(0xFFD4C4F0);
  static const textDim     = Color(0xFF8B7AAA);
  
  static const List<Color> rainbow = [
    purple, pink, cyan, green, yellow, orange, red, purpleL, blue, teal, indigo, gold
  ];
  
  static const LinearGradient rainbowGrad = LinearGradient(
    colors: rainbow,
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );
}

// ─── Tool Category Data ───────────────────────────────────────────────────────
class _ToolCategory {
  final String id;
  final String title;
  final String subtitle;
  final IconData icon;
  final Color accent;

  const _ToolCategory({
    required this.id,
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.accent,
  });
}

// 12 Kategori Tools (Lengkap)
const _categories = [
  _ToolCategory(
    id: 'panel',
    title: 'Manage Server',
    subtitle: 'Server Control',
    icon: Icons.cloud_rounded,
    accent: _C.purple,
  ),
  _ToolCategory(
    id: 'ddos',
    title: 'DDoS',
    subtitle: 'Take Down',
    icon: Icons.bolt_rounded,
    accent: _C.pink,
  ),
  _ToolCategory(
    id: 'network',
    title: 'Network',
    subtitle: 'WiFi Arsenal',
    icon: Icons.wifi_rounded,
    accent: _C.cyan,
  ),
  _ToolCategory(
    id: 'osint',
    title: 'OSINT',
    subtitle: 'Deep Search',
    icon: Icons.search_rounded,
    accent: _C.green,
  ),
  _ToolCategory(
    id: 'downloader',
    title: 'Downloader',
    subtitle: 'Media Saver',
    icon: Icons.download_rounded,
    accent: _C.blue,
  ),
  _ToolCategory(
    id: 'utilities',
    title: 'Utilities',
    subtitle: 'Extra Tools',
    icon: Icons.construction_rounded,
    accent: _C.yellow,
  ),
  _ToolCategory(
    id: 'watchs',
    title: 'Watch Video',
    subtitle: 'Stream & Watch',
    icon: Icons.play_circle_rounded,
    accent: _C.orange,
  ),
  _ToolCategory(
    id: 'ratcontrol',
    title: 'RAT Control',
    subtitle: 'Remote Access',
    icon: Icons.devices_rounded,
    accent: _C.red,
  ),
  _ToolCategory(
    id: 'adulthub',
    title: 'Adult Hub',
    subtitle: '18+ Only',
    icon: Icons.lock_rounded,
    accent: _C.rose,
  ),
  _ToolCategory(
    id: 'games',
    title: 'Games',
    subtitle: 'Fun & Play',
    icon: Icons.games_rounded,
    accent: _C.gold,
  ),
  _ToolCategory(
    id: 'quotes',
    title: 'Kata - Kata',
    subtitle: 'Motivasi & Inspirasi',
    icon: Icons.auto_awesome_rounded,
    accent: _C.purpleL,
  ),
  _ToolCategory(
    id: 'slot',
    title: 'Slot & Ludo',
    subtitle: 'Casino Games',
    icon: Icons.casino_rounded,
    accent: _C.teal,
  ),
];

// ─── Page ─────────────────────────────────────────────────────────────────────
class ToolsPage extends StatefulWidget {
  final String sessionKey;
  final String userRole;
  final List<Map<String, dynamic>> listDoos;

  const ToolsPage({
    super.key,
    required this.sessionKey,
    required this.userRole,
    required this.listDoos,
  });

  @override
  State<ToolsPage> createState() => _ToolsPageState();
}

class _ToolsPageState extends State<ToolsPage> with TickerProviderStateMixin {
  late AnimationController _bgCtrl;
  late AnimationController _headerCtrl;
  late Animation<double> _headerFade;
  late Animation<Offset> _headerSlide;
  late AnimationController _rotateCtrl;
  late AnimationController _pulseCtrl;
  late Animation<double> _pulseAnim;

  @override
  void initState() {
    super.initState();
    _bgCtrl = AnimationController(
        vsync: this, duration: const Duration(seconds: 16))
      ..repeat();

    _rotateCtrl = AnimationController(
        vsync: this, duration: const Duration(seconds: 20))
      ..repeat();

    _pulseCtrl = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 1500))
      ..repeat(reverse: true);
    _pulseAnim = CurvedAnimation(parent: _pulseCtrl, curve: Curves.easeInOut);

    _headerCtrl = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 700));
    _headerFade =
        CurvedAnimation(parent: _headerCtrl, curve: Curves.easeOut);
    _headerSlide =
        Tween<Offset>(begin: const Offset(0, -0.2), end: Offset.zero)
            .animate(CurvedAnimation(
                parent: _headerCtrl, curve: Curves.easeOutCubic));
    _headerCtrl.forward();
  }

  @override
  void dispose() {
    _bgCtrl.dispose();
    _headerCtrl.dispose();
    _rotateCtrl.dispose();
    _pulseCtrl.dispose();
    super.dispose();
  }

  void _push(Widget page) =>
      Navigator.push(context, _slideRoute(page));

  void _comingSoon() {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: const Row(children: [
        Icon(Icons.hourglass_top_rounded, color: Colors.white, size: 16),
        SizedBox(width: 8),
        Text('Coming Soon!',
            style: TextStyle(
                color: Colors.white, fontWeight: FontWeight.w600)),
      ]),
      backgroundColor: _C.purple,
      behavior: SnackBarBehavior.floating,
      margin: const EdgeInsets.fromLTRB(16, 0, 16, 16),
      shape:
          RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      duration: const Duration(seconds: 2),
    ));
  }

  void _onCategoryTap(String id) {
    switch (id) {
      case 'panel':
        _showSheet(_panelItems());
        break;
      case 'ddos':
        _showSheet(_ddosItems());
        break;
      case 'network':
        _showSheet(_networkItems());
        break;
      case 'osint':
        _showSheet(_osintItems());
        break;
      case 'downloader':
        _showSheet(_downloaderItems());
        break;
      case 'utilities':
        _showSheet(_utilityItems());
        break;
      case 'watchs':
        _showSheet(_watchsItems());
        break;
      case 'ratcontrol':
        _showSheet(_ratcontrolItems());
        break;
      case 'adulthub':
        _showSheet(_adulthubItems());
        break;
      case 'games':
        _showSheet(_gamesItems());
        break;
      case 'quotes':
        _showSheet(_quotesItems());
        break;
      case 'slot':
        _showSheet(_slotItems());
        break;
    }
  }

  List<_ToolItem> _panelItems() => [
        _ToolItem(
            icon: Icons.dns_rounded,
            label: 'Manage Server',
            accent: _C.purple,
            onTap: () => _push(
                ManageServerPage(keyToken: widget.sessionKey))),
      ];

  List<_ToolItem> _ddosItems() => [
        _ToolItem(
            icon: Icons.bolt_rounded,
            label: 'Attack Panel',
            accent: _C.pink,
            onTap: () => _push(AttackPanel(
                sessionKey: widget.sessionKey,
                listDoos: widget.listDoos))),
      ];

  List<_ToolItem> _networkItems() => [
        _ToolItem(
            icon: Icons.newspaper_outlined,
            label: 'Spam NGL',
            accent: _C.cyan,
            onTap: () => _push(NglPage())),
        _ToolItem(
            icon: Icons.wifi_off_rounded,
            label: 'WiFi Killer (Internal)',
            accent: _C.cyan,
            onTap: () => _push(WifiKillerPage())),
        if (['vip', 'owner', 'high_owner', 'founder', 'developer'].contains(widget.userRole))
          _ToolItem(
              icon: Icons.router_rounded,
              label: 'WiFi Killer (External)',
              accent: _C.cyan,
              onTap: () => _push(
                  WifiInternalPage(sessionKey: widget.sessionKey))),
      ];

  List<_ToolItem> _osintItems() => [
        _ToolItem(
            icon: Icons.badge_outlined,
            label: 'NIK Detail',
            accent: _C.green,
            onTap: () => _push(const NikCheckerPage())),
        _ToolItem(
            icon: Icons.travel_explore_rounded,
            label: 'Domain OSINT',
            accent: _C.green,
            onTap: () => _push(const DomainOsintPage())),
        _ToolItem(
            icon: Icons.person_search_rounded,
            label: 'Phone Lookup',
            accent: _C.green,
            onTap: () => _push(const PhoneLookupPage())),
        _ToolItem(
            icon: Icons.alternate_email_rounded,
            label: 'Email OSINT',
            accent: _C.green,
            onTap: () => _push(const EmailOsintPage())),
      ];

  List<_ToolItem> _downloaderItems() => [
        _ToolItem(
            icon: Icons.video_library_rounded,
            label: 'TikTok Downloader',
            accent: _C.blue,
            onTap: () => _push(const TiktokDownloaderPage())),
        _ToolItem(
            icon: Icons.camera_alt_rounded,
            label: 'Instagram Downloader',
            accent: _C.blue,
            onTap: () => _push(const InstagramDownloaderPage())),
      ];

  List<_ToolItem> _utilityItems() => [
        _ToolItem(
            icon: Icons.qr_code_2_rounded,
            label: 'QR Generator',
            accent: _C.yellow,
            onTap: () => _push(const QrGeneratorPage())),
        _ToolItem(
            icon: Icons.security_rounded,
            label: 'IP Scanner',
            accent: _C.yellow,
            onTap: () => _push(const IpScannerPage())),
        _ToolItem(
            icon: Icons.network_check_rounded,
            label: 'Port Scanner',
            accent: _C.yellow,
            onTap: () => _push(const PortScannerPage())),
      ];
      
  List<_ToolItem> _watchsItems() => [
        _ToolItem(
            icon: Icons.animation_rounded,
            label: 'Anime',
            accent: _C.orange,
            onTap: () => _push(const HomeAnimePage())),
        _ToolItem(
            icon: Icons.play_circle_rounded,
            label: 'Dracin',
            accent: _C.orange,
            onTap: () => _push(const DracinPage())),
      ];
      
  List<_ToolItem> _ratcontrolItems() => [
        _ToolItem(
            icon: Icons.devices_rounded,
            label: 'RAT Panel',
            accent: _C.red,
            onTap: () => _push(const DeviceDashboardPage())),
      ];
      
  List<_ToolItem> _adulthubItems() => [
        _ToolItem(
            icon: Icons.favorite_rounded,
            label: 'Hentai',
            accent: _C.rose,
            onTap: () => _push(const HomeHentaiPage())),
      ];

  // ─── TOOLS BARU: GAMES ────────────────────────────────────────────────────
  List<_ToolItem> _gamesItems() => [
        _ToolItem(
            icon: Icons.quiz_rounded,
            label: 'Quiz Master',
            accent: _C.gold,
            onTap: () => _push(QuizPage(username: widget.sessionKey))),
        _ToolItem(
            icon: Icons.gamepad_rounded,
            label: 'Suit Game',
            accent: _C.gold,
            onTap: () => _push(SuitPage(username: widget.sessionKey))),
        _ToolItem(
            icon: Icons.grid_on_rounded,
            label: 'Tic Tac Toe',
            accent: _C.gold,
            onTap: () => _push(TicTacToePage(username: widget.sessionKey))),
      ];

  // ─── TOOLS BARU: KATA-KATA ──────────────────────────────────────────────
  List<_ToolItem> _quotesItems() => [
        _ToolItem(
            icon: Icons.auto_awesome_rounded,
            label: '1000+ Kata-Kata',
            accent: _C.purpleL,
            onTap: () => _push(KataKataPage(username: widget.sessionKey))),
      ];

  // ─── TOOLS BARU: SLOT & LUDO ────────────────────────────────────────────
  List<_ToolItem> _slotItems() => [
        _ToolItem(
            icon: Icons.casino_rounded,
            label: 'Slot Machine',
            accent: _C.teal,
            onTap: () => _push(SlotMachineTools(username: widget.sessionKey))),
        _ToolItem(
            icon: Icons.dice_rounded,
            label: 'Ludo King',
            accent: _C.teal,
            onTap: () => _push(LudoKingTools(username: widget.sessionKey))),
      ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _C.bg,
      body: Stack(
        children: [
          // ─── RAINBOW ANIMATED BACKGROUND ─────────────────────────────
          _buildRainbowBackground(),
          
          // ─── GLOW ORBS ──────────────────────────────────────────────────
          _buildGlowOrbs(),
          
          // ─── GRID BACKGROUND ───────────────────────────────────────────
          Positioned.fill(child: _AnimatedBg(controller: _bgCtrl)),
          
          SafeArea(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // ── App Header ──
                FadeTransition(
                  opacity: _headerFade,
                  child: SlideTransition(
                    position: _headerSlide,
                    child: _buildAppHeader(),
                  ),
                ),

                // ── Section label ──
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 20, 16, 12),
                  child: Row(
                    children: [
                      Container(
                        width: 4,
                        height: 20,
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            colors: [_C.purple, _C.pink],
                            begin: Alignment.topCenter,
                            end: Alignment.bottomCenter,
                          ),
                          borderRadius: BorderRadius.circular(2),
                        ),
                      ),
                      const SizedBox(width: 10),
                      ShaderMask(
                        shaderCallback: (bounds) => _C.rainbowGrad.createShader(bounds),
                        child: const Text(
                          'CYBER TOOLS 🔧',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 16,
                            fontWeight: FontWeight.w700,
                            fontFamily: 'Orbitron',
                          ),
                        ),
                      ),
                      const Spacer(),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: _C.purple.withOpacity(0.3)),
                          color: _C.purple.withOpacity(0.08),
                        ),
                        child: Text(
                          '${_categories.length} item',
                          style: const TextStyle(
                              color: _C.textSub, fontSize: 11, fontFamily: 'ShareTechMono'),
                        ),
                      ),
                    ],
                  ),
                ),

                // ── Grid 3 kolom ──
                Expanded(
                  child: GridView.builder(
                    physics: const BouncingScrollPhysics(),
                    padding: const EdgeInsets.fromLTRB(12, 0, 12, 24),
                    gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: 3,
                      crossAxisSpacing: 10,
                      mainAxisSpacing: 10,
                      childAspectRatio: 0.82,
                    ),
                    itemCount: _categories.length,
                    itemBuilder: (_, i) => _StaggerItem(
                      index: i,
                      child: _CategoryCard(
                        category: _categories[i],
                        onTap: () => _onCategoryTap(_categories[i].id),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ─── RAINBOW BACKGROUND ──────────────────────────────────────────────────
  Widget _buildRainbowBackground() {
    return AnimatedBuilder(
      animation: _rotateCtrl,
      builder: (_, __) {
        return Container(
          decoration: BoxDecoration(
            gradient: RadialGradient(
              center: Alignment(
                math.sin(_rotateCtrl.value * 0.5) * 0.3,
                math.cos(_rotateCtrl.value * 0.7) * 0.3,
              ),
              radius: 1.5,
              colors: [
                _C.rainbow[_rotateCtrl.value.toInt() % _C.rainbow.length]
                    .withOpacity(0.06),
                _C.rainbow[(_rotateCtrl.value.toInt() + 3) % _C.rainbow.length]
                    .withOpacity(0.04),
                _C.bg,
              ],
              stops: const [0.0, 0.5, 1.0],
            ),
          ),
        );
      },
    );
  }

  // ─── GLOW ORBS ────────────────────────────────────────────────────────────
  Widget _buildGlowOrbs() {
    return Stack(
      children: List.generate(6, (i) {
        final angle = (i / 6) * 2 * math.pi;
        return AnimatedBuilder(
          animation: _rotateCtrl,
          builder: (_, __) {
            final x = math.cos(_rotateCtrl.value * 0.4 + angle) * 180;
            final y = math.sin(_rotateCtrl.value * 0.6 + angle) * 120;
            final color = _C.rainbow[(i * 2) % _C.rainbow.length];
            return Positioned(
              left: MediaQuery.of(context).size.width / 2 + x - 35,
              top: MediaQuery.of(context).size.height / 2 + y - 35,
              child: Container(
                width: 70 + 30 * math.sin(_rotateCtrl.value + i).abs(),
                height: 70 + 30 * math.sin(_rotateCtrl.value + i).abs(),
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: RadialGradient(
                    colors: [color.withOpacity(0.04), Colors.transparent],
                    radius: 0.7,
                  ),
                ),
              ),
            );
          },
        );
      }),
    );
  }

  // ─── App Header ────────────────────────────────────────────────────────────
  Widget _buildAppHeader() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
      child: Row(
        children: [
          AnimatedBuilder(
            animation: _pulseCtrl,
            builder: (_, __) => Transform.scale(
              scale: 1 + _pulseCtrl.value * 0.03,
              child: Container(
                width: 52,
                height: 52,
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [_C.purple, _C.pink],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(14),
                  boxShadow: [
                    BoxShadow(
                      color: _C.purple.withOpacity(0.4 + _pulseCtrl.value * 0.2),
                      blurRadius: 20 + _pulseCtrl.value * 10,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: const Icon(Icons.shield_rounded,
                    color: Colors.white, size: 26),
              ),
            ),
          ),
          const SizedBox(width: 12),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              ShaderMask(
                shaderCallback: (bounds) => _C.rainbowGrad.createShader(bounds),
                child: const Text(
                  'CYBER - TOOLS',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 20,
                    fontWeight: FontWeight.w900,
                    letterSpacing: 1.5,
                    fontFamily: 'Orbitron',
                  ),
                ),
              ),
              Text(
                'Gateway Tools • Premium',
                style: TextStyle(
                  color: _C.textSub,
                  fontSize: 11,
                  fontFamily: 'ShareTechMono',
                ),
              ),
            ],
          ),
          const Spacer(),
          // Badge
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [_C.card, _C.surface],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: _C.purple.withOpacity(0.3)),
              boxShadow: [
                BoxShadow(
                  color: _C.purple.withOpacity(0.1),
                  blurRadius: 12,
                ),
              ],
            ),
            child: Row(
              children: [
                AnimatedContainer(
                  duration: const Duration(milliseconds: 500),
                  width: 8,
                  height: 8,
                  decoration: BoxDecoration(
                    color: _C.green,
                    shape: BoxShape.circle,
                    boxShadow: [
                      BoxShadow(
                        color: _C.green.withOpacity(0.5),
                        blurRadius: 8,
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 6),
                const Text('LIVE',
                    style: TextStyle(
                        color: _C.text,
                        fontSize: 13,
                        fontWeight: FontWeight.w700,
                        fontFamily: 'Orbitron')),
              ],
            ),
          ),
        ],
      ),
    );
  }

  void _showSheet(List<_ToolItem> items) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      useSafeArea: false,
      builder: (_) => _ToolSheet(items: items),
    );
  }
}

// ─── Category Card ─────────────────────────────────────────────────────────────
class _CategoryCard extends StatefulWidget {
  final _ToolCategory category;
  final VoidCallback onTap;

  const _CategoryCard(
      {required this.category, required this.onTap});

  @override
  State<_CategoryCard> createState() => _CategoryCardState();
}

class _CategoryCardState extends State<_CategoryCard>
    with SingleTickerProviderStateMixin {
  bool _pressed = false;
  late AnimationController _glowCtrl;
  late Animation<double> _glow;

  @override
  void initState() {
    super.initState();
    _glowCtrl = AnimationController(
        vsync: this,
        duration: const Duration(milliseconds: 1800))
      ..repeat(reverse: true);
    _glow = Tween<double>(begin: 0.15, end: 0.45).animate(
        CurvedAnimation(parent: _glowCtrl, curve: Curves.easeInOut));
  }

  @override
  void dispose() {
    _glowCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final cat = widget.category;

    return GestureDetector(
      onTapDown: (_) => setState(() => _pressed = true),
      onTapUp: (_) {
        setState(() => _pressed = false);
        widget.onTap();
      },
      onTapCancel: () => setState(() => _pressed = false),
      child: AnimatedScale(
        scale: _pressed ? 0.93 : 1.0,
        duration: const Duration(milliseconds: 130),
        child: AnimatedBuilder(
          animation: _glow,
          builder: (_, __) => Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  _pressed ? cat.accent.withOpacity(0.1) : _C.card,
                  _pressed ? cat.accent.withOpacity(0.05) : _C.surface,
                ],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(22),
              border: Border.all(
                color: _pressed
                    ? cat.accent.withOpacity(0.5)
                    : cat.accent.withOpacity(0.15),
                width: _pressed ? 2 : 1.0,
              ),
              boxShadow: [
                BoxShadow(
                  color: cat.accent.withOpacity(
                      _pressed ? 0.25 : _glow.value * 0.08),
                  blurRadius: _pressed ? 24 : 16,
                  offset: const Offset(0, 6),
                ),
              ],
            ),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                // Lingkaran icon
                AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  width: 60,
                  height: 60,
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [
                        cat.accent.withOpacity(_pressed ? 0.25 : 0.12),
                        cat.accent.withOpacity(_pressed ? 0.1 : 0.05),
                      ],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: cat.accent
                          .withOpacity(_pressed ? 0.6 : 0.25),
                      width: _pressed ? 2 : 1.5,
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: cat.accent.withOpacity(
                            _pressed ? 0.3 : 0.08),
                        blurRadius: 16,
                        spreadRadius: 2,
                      ),
                    ],
                  ),
                  child: Icon(cat.icon,
                      color: cat.accent,
                      size: 26),
                ),

                const SizedBox(height: 10),

                // Nama kategori
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 6),
                  child: Text(
                    cat.title,
                    textAlign: TextAlign.center,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      color: _pressed ? cat.accent : _C.text,
                      fontSize: 13,
                      fontWeight: FontWeight.w700,
                      fontFamily: 'Orbitron',
                      letterSpacing: 0.5,
                    ),
                  ),
                ),

                const SizedBox(height: 3),

                // Subtitle
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 6),
                  child: Text(
                    cat.subtitle,
                    textAlign: TextAlign.center,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      color: _C.textSub,
                      fontSize: 10,
                      height: 1.3,
                      fontFamily: 'ShareTechMono',
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

// ─── Tool Sheet ───────────────────────────────────────────────────────────────
class _ToolSheet extends StatelessWidget {
  final List<_ToolItem> items;
  const _ToolSheet({required this.items});

  @override
  Widget build(BuildContext context) {
    return Container(
      constraints: BoxConstraints(
        maxHeight: MediaQuery.of(context).size.height * 0.75,
      ),
      decoration: const BoxDecoration(
        color: _C.surface,
        borderRadius:
            BorderRadius.vertical(top: Radius.circular(24)),
        border: Border(
          top: BorderSide(color: _C.borderLit, width: 1.5),
          left: BorderSide(color: _C.border, width: 0.5),
          right: BorderSide(color: _C.border, width: 0.5),
        ),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // ── Drag handle ──
          Padding(
            padding: const EdgeInsets.only(top: 12, bottom: 8),
            child: Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [_C.purple, _C.pink],
                  begin: Alignment.centerLeft,
                  end: Alignment.centerRight,
                ),
                borderRadius: BorderRadius.circular(100),
              ),
            ),
          ),
          // ── Garis gradient ──
          Container(
            height: 1.5,
            margin: const EdgeInsets.symmetric(horizontal: 24),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [Colors.transparent, _C.purple, _C.pink, Colors.transparent],
              ),
            ),
          ),
          const SizedBox(height: 8),
          Flexible(
            child: ListView.separated(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 32),
              shrinkWrap: true,
              physics: const BouncingScrollPhysics(),
              itemCount: items.length,
              separatorBuilder: (_, __) =>
                  const SizedBox(height: 8),
              itemBuilder: (ctx, i) => _StaggerItem(
                index: i,
                child: _ToolRow(
                  item: items[i],
                  onTap: () {
                    Navigator.pop(ctx);
                    items[i].onTap();
                  },
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ─── Tool Row ─────────────────────────────────────────────────────────────────
class _ToolRow extends StatefulWidget {
  final _ToolItem item;
  final VoidCallback onTap;
  const _ToolRow({required this.item, required this.onTap});

  @override
  State<_ToolRow> createState() => _ToolRowState();
}

class _ToolRowState extends State<_ToolRow> {
  bool _pressed = false;

  @override
  Widget build(BuildContext context) {
    final item = widget.item;
    return GestureDetector(
      onTapDown: (_) => setState(() => _pressed = true),
      onTapUp: (_) {
        setState(() => _pressed = false);
        widget.onTap();
      },
      onTapCancel: () => setState(() => _pressed = false),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 140),
        padding: const EdgeInsets.symmetric(
            horizontal: 16, vertical: 14),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [
              _pressed ? item.accent.withOpacity(0.08) : _C.card,
              _pressed ? item.accent.withOpacity(0.04) : _C.surface,
            ],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: _pressed
                ? item.accent.withOpacity(0.4)
                : item.accent.withOpacity(0.15),
            width: _pressed ? 2 : 1,
          ),
          boxShadow: _pressed
              ? [
                  BoxShadow(
                      color: item.accent.withOpacity(0.15),
                      blurRadius: 16,
                      offset: const Offset(0, 6))
                ]
              : [],
        ),
        child: Row(children: [
          AnimatedContainer(
            duration: const Duration(milliseconds: 150),
            width: 42,
            height: 42,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  item.accent.withOpacity(_pressed ? 0.2 : 0.1),
                  item.accent.withOpacity(_pressed ? 0.1 : 0.05),
                ],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(11),
              border: Border.all(
                  color: item.accent
                      .withOpacity(_pressed ? 0.5 : 0.2)),
            ),
            child:
                Icon(item.icon, color: item.accent, size: 19),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(item.label,
                    style: TextStyle(
                        color: _pressed ? item.accent : _C.text,
                        fontSize: 14,
                        fontWeight: FontWeight.w700,
                        fontFamily: 'Orbitron')),
                if (item.comingSoon)
                  const Text('Coming Soon',
                      style: TextStyle(
                          color: _C.textSub,
                          fontSize: 10,
                          fontFamily: 'ShareTechMono')),
              ],
            ),
          ),
          item.comingSoon
              ? Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [_C.yellow.withOpacity(0.1), _C.orange.withOpacity(0.05)],
                    ),
                    borderRadius: BorderRadius.circular(7),
                    border: Border.all(
                        color: _C.yellow.withOpacity(0.3)),
                  ),
                  child: const Text('SOON',
                      style: TextStyle(
                          color: _C.yellow,
                          fontSize: 9,
                          fontWeight: FontWeight.w800,
                          letterSpacing: 0.5,
                          fontFamily: 'Orbitron')),
                )
              : AnimatedContainer(
                  duration: const Duration(milliseconds: 150),
                  width: 30,
                  height: 30,
                  decoration: BoxDecoration(
                    color: _pressed
                        ? item.accent.withOpacity(0.15)
                        : _C.surface,
                    borderRadius: BorderRadius.circular(9),
                    border: Border.all(
                      color: _pressed
                          ? item.accent.withOpacity(0.3)
                          : _C.border,
                    ),
                  ),
                  child: Icon(
                      Icons.arrow_forward_ios_rounded,
                      color:
                          _pressed ? item.accent : _C.textSub,
                      size: 13),
                ),
        ]),
      ),
    );
  }
}

// ─── Stagger Item ─────────────────────────────────────────────────────────────
class _StaggerItem extends StatelessWidget {
  final int index;
  final Widget child;
  const _StaggerItem(
      {required this.index, required this.child});

  @override
  Widget build(BuildContext context) {
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0, end: 1),
      duration: Duration(
          milliseconds:
              350 + (index * 70).clamp(0, 450)),
      curve: Curves.easeOutCubic,
      builder: (_, v, ch) => Opacity(
        opacity: v,
        child: Transform.translate(
            offset: Offset(0, 18 * (1 - v)), child: ch),
      ),
      child: child,
    );
  }
}

// ─── Animated Background ──────────────────────────────────────────────────────
class _AnimatedBg extends StatelessWidget {
  final AnimationController controller;
  const _AnimatedBg({required this.controller});

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: controller,
      builder: (_, __) =>
          CustomPaint(painter: _BgPainter(controller.value)),
    );
  }
}

class _BgPainter extends CustomPainter {
  final double t;
  _BgPainter(this.t);

  @override
  void paint(Canvas canvas, Size size) {
    final grid = Paint()
      ..color = _C.border.withOpacity(0.15)
      ..strokeWidth = 0.5;
    const step = 44.0;
    for (double x = 0; x < size.width; x += step) {
      canvas.drawLine(
          Offset(x, 0), Offset(x, size.height), grid);
    }
    for (double y = 0; y < size.height; y += step) {
      canvas.drawLine(
          Offset(0, y), Offset(size.width, y), grid);
    }

    final glow = Paint()
      ..shader = RadialGradient(colors: [
        _C.purple.withOpacity(
            0.08 + math.sin(t * math.pi * 2) * 0.03),
        Colors.transparent,
      ], radius: 0.9)
          .createShader(Rect.fromCircle(
              center: Offset(size.width / 2, 0),
              radius: size.width));
    canvas.drawCircle(
        Offset(size.width / 2, 0), size.width, glow);

    final glow2 = Paint()
      ..shader = RadialGradient(colors: [
        _C.pink.withOpacity(
            0.05 + math.cos(t * math.pi * 2) * 0.02),
        Colors.transparent,
      ], radius: 0.5)
          .createShader(Rect.fromCircle(
              center: Offset(
                  size.width * 0.85, size.height * 0.75),
              radius: size.width * 0.4));
    canvas.drawCircle(
        Offset(size.width * 0.85, size.height * 0.75),
        size.width * 0.4,
        glow2);
  }

  @override
  bool shouldRepaint(_BgPainter old) => old.t != t;
}

// ─── Page transition ──────────────────────────────────────────────────────────
PageRoute _slideRoute(Widget page) => PageRouteBuilder(
      pageBuilder: (_, __, ___) => page,
      transitionDuration: const Duration(milliseconds: 350),
      transitionsBuilder: (_, anim, __, child) =>
          SlideTransition(
        position: Tween<Offset>(
          begin: const Offset(1, 0),
          end: Offset.zero,
        ).animate(CurvedAnimation(
            parent: anim, curve: Curves.easeOutCubic)),
        child: FadeTransition(opacity: anim, child: child),
      ),
    );

// ─── Data model ───────────────────────────────────────────────────────────────
class _ToolItem {
  final IconData icon;
  final String label;
  final Color accent;
  final VoidCallback onTap;
  final bool comingSoon;

  const _ToolItem({
    required this.icon,
    required this.label,
    required this.accent,
    required this.onTap,
    this.comingSoon = false,
  });
}