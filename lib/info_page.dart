import 'dart:async';
import 'dart:convert';
import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'api_config.dart';

// ─── PALETTE RAINBOW CYBER ──────────────────────────────────────────────────
class _C {
  static const bg          = Color(0xFF0A0015);
  static const surface     = Color(0xFF15002A);
  static const card        = Color(0xFF1A0A2E);
  static const cardAlt     = Color(0xFF2D1B4E);
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
  static const gold        = Color(0xFFFFD700);
  
  static const text        = Color(0xFFF3E8FF);
  static const textSub     = Color(0xFFD4C4F0);
  static const textDim     = Color(0xFF8B7AAA);

  static const List<Color> rainbow = [
    purple, pink, cyan, green, yellow, orange, red, purpleL, blue, teal, gold
  ];
  
  static const LinearGradient rainbowGrad = LinearGradient(
    colors: rainbow,
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );
}

// ─── RULES DATA ───────────────────────────────────────────────────────────────
const _rules = [
  _Rule(
    title: 'Larangan Barter Akun',
    desc:  'Akun tidak boleh ditukar dengan barang, jasa, atau akun lain dalam bentuk apa pun.',
    icon:  Icons.swap_horiz_rounded,
    color: _C.yellow,
  ),
  _Rule(
    title: 'Larangan Membagikan Akun',
    desc:  'Setiap akun bersifat pribadi dan hanya boleh digunakan oleh pemilik akun yang terdaftar.',
    icon:  Icons.share_rounded,
    color: _C.blue,
  ),
  _Rule(
    title: 'Larangan Menjual Akun',
    desc:  'Member TIDAK diperbolehkan menjual akun. Penjualan hanya boleh dilakukan oleh role yang diizinkan secara resmi.',
    icon:  Icons.sell_rounded,
    color: _C.red,
  ),
  _Rule(
    title: 'Larangan Jual Durasi Ilegal',
    desc:  'Dilarang menjual akses harian, mingguan, trial, atau sejenisnya di luar ketentuan yang telah ditetapkan.',
    icon:  Icons.timer_off_rounded,
    color: _C.orange,
  ),
  _Rule(
    title: 'Larangan Banting Harga',
    desc:  'Dilarang merusak atau menurunkan harga yang telah ditentukan di bawah ketentuan X - NULL V3.',
    icon:  Icons.trending_down_rounded,
    color: _C.green,
  ),
];

class _Rule {
  final String title;
  final String desc;
  final IconData icon;
  final Color color;
  const _Rule({required this.title, required this.desc,
      required this.icon, required this.color});
}

// ─── FALLBACK DATA ────────────────────────────────────────────────────────────
const _fallbackServerInfo = {
  'name': 'X - NULL Server',
  'version': '3.0',
  'status': 'online',
};

// ─── PAGE ─────────────────────────────────────────────────────────────────────
class InfoPage extends StatefulWidget {
  final String sessionKey;
  const InfoPage({super.key, required this.sessionKey});

  @override
  State<InfoPage> createState() => _InfoPageState();
}

class _InfoPageState extends State<InfoPage> with TickerProviderStateMixin {
  Map<String, dynamic> serverInfo = _fallbackServerInfo;
  bool isLoading = false;

  bool   _apiOnline   = false;
  int    _pingMs      = 0;
  String _pingStatus  = 'Checking...';
  Timer? _pingTimer;

  // ─── ANIMATIONS ──────────────────────────────────────────────────────────
  late AnimationController _bgCtrl;
  late AnimationController _entranceCtrl;
  late AnimationController _pingDotCtrl;
  late AnimationController _sanctionCtrl;
  late AnimationController _pulseCtrl;
  late AnimationController _rotateCtrl;
  late AnimationController _glowCtrl;

  late Animation<double> _entrance;
  late Animation<double> _pingDot;
  late Animation<double> _sanctionGlow;
  late Animation<double> _pulseAnim;
  late Animation<double> _glowAnim;

  // ─── DIGITAL CLOCK ──────────────────────────────────────────────────────
  Timer? _clockTimer;
  String _timeWIB = '--:--:--';
  String _timeWITA = '--:--:--';
  String _timeWIT = '--:--:--';
  bool _showColon = true;

  int? _expandedRule;

  @override
  void initState() {
    super.initState();

    _bgCtrl = AnimationController(
        vsync: this, duration: const Duration(seconds: 18))..repeat();

    _rotateCtrl = AnimationController(
        vsync: this, duration: const Duration(seconds: 20))..repeat();

    _glowCtrl = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 2000))..repeat(reverse: true);
    _glowAnim = CurvedAnimation(parent: _glowCtrl, curve: Curves.easeInOut);

    _entranceCtrl = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 600));
    _entrance = CurvedAnimation(parent: _entranceCtrl, curve: Curves.easeOutCubic);

    _pingDotCtrl = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 1200))..repeat(reverse: true);
    _pingDot = Tween<double>(begin: 0.3, end: 1.0)
        .animate(CurvedAnimation(parent: _pingDotCtrl, curve: Curves.easeInOut));

    _sanctionCtrl = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 2000))..repeat(reverse: true);
    _sanctionGlow = Tween<double>(begin: 0.2, end: 0.6)
        .animate(CurvedAnimation(parent: _sanctionCtrl, curve: Curves.easeInOut));

    _pulseCtrl = AnimationController(
        vsync: this, duration: const Duration(seconds: 2))..repeat(reverse: true);
    _pulseAnim = Tween<double>(begin: 0.5, end: 1.0)
        .animate(CurvedAnimation(parent: _pulseCtrl, curve: Curves.easeInOut));

    // ─── CLOCK ────────────────────────────────────────────────────────────
    _updateClock();
    _clockTimer = Timer.periodic(const Duration(seconds: 1), (_) {
      _updateClock();
      setState(() => _showColon = !_showColon);
    });

    _fetchServerInfo();
    _startPingLoop();
    _entranceCtrl.forward();
  }

  @override
  void dispose() {
    _pingTimer?.cancel();
    _clockTimer?.cancel();
    _bgCtrl.dispose();
    _entranceCtrl.dispose();
    _pingDotCtrl.dispose();
    _sanctionCtrl.dispose();
    _pulseCtrl.dispose();
    _rotateCtrl.dispose();
    _glowCtrl.dispose();
    super.dispose();
  }

  void _updateClock() {
    final now = DateTime.now().toUtc();
    final wib = now.add(const Duration(hours: 7));
    final wita = now.add(const Duration(hours: 8));
    final wit = now.add(const Duration(hours: 9));
    setState(() {
      _timeWIB = _formatTime(wib);
      _timeWITA = _formatTime(wita);
      _timeWIT = _formatTime(wit);
    });
  }

  String _formatTime(DateTime time) {
    return '${time.hour.toString().padLeft(2, '0')}:${time.minute.toString().padLeft(2, '0')}:${time.second.toString().padLeft(2, '0')}';
  }

  // ─── API ───────────────────────────────────────────────────────────────────
  Future<void> _fetchServerInfo() async {
    try {
      final res = await http.get(Uri.parse(
          'http://tirzzadminbaik.pteroqdactyl.my.id:11560/getServerInfo?key=${widget.sessionKey}'));
      if (res.statusCode == 200 && mounted) {
        setState(() { serverInfo = jsonDecode(res.body); });
      }
    } catch (_) {}
  }

  void _startPingLoop() {
    _checkPing();
    _pingTimer = Timer.periodic(const Duration(seconds: 5), (_) => _checkPing());
  }

  Future<void> _checkPing() async {
    final start = DateTime.now();
    try {
      final res = await http.get(Uri.parse(
              'http://tirzzadminbaik.pteroqdactyl.my.id:11560/ping?key=${widget.sessionKey}'))
          .timeout(const Duration(seconds: 3));
      final ms = DateTime.now().difference(start).inMilliseconds;
      if (res.statusCode == 200 && mounted) {
        setState(() {
          _apiOnline  = true;
          _pingMs     = ms;
          _pingStatus = '${ms}ms';
        });
      } else {
        throw Exception();
      }
    } catch (_) {
      if (mounted) setState(() { 
        _apiOnline = false; 
        _pingMs = 0; 
        _pingStatus = 'Offline'; 
      });
    }
  }

  Color get _pingColor {
    if (!_apiOnline) return _C.red;
    if (_pingMs < 200) return _C.green;
    if (_pingMs < 500) return _C.yellow;
    return _C.orange;
  }

  String get _pingLabel {
    if (!_apiOnline) return 'OFFLINE';
    if (_pingMs < 200) return 'EXCELLENT';
    if (_pingMs < 500) return 'GOOD';
    return 'SLOW';
  }

  // ─── BUILD ────────────────────────────────────────────────────────────────
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _C.bg,
      extendBodyBehindAppBar: true,
      appBar: _buildAppBar(),
      body: Stack(
        children: [
          // ─── RAINBOW BACKGROUND ──────────────────────────────────────
          _buildRainbowBackground(),
          _buildGlowOrbs(),
          Positioned.fill(child: _AnimatedBg(controller: _bgCtrl)),
          
          SafeArea(
            child: FadeTransition(
              opacity: _entrance,
              child: ListView(
                physics: const BouncingScrollPhysics(),
                padding: const EdgeInsets.fromLTRB(16, 8, 16, 48),
                children: [
                  _buildHeroHeader(),
                  const SizedBox(height: 16),
                  _buildDigitalClock(),
                  const SizedBox(height: 16),
                  _buildStatusCardModern(),
                  const SizedBox(height: 24),
                  _buildModernSectionHeader(),
                  const SizedBox(height: 16),
                  ..._rules.asMap().entries.map((e) =>
                    Padding(
                      padding: const EdgeInsets.only(bottom: 12),
                      child: _ModernRuleCard(
                        rule: e.value,
                        number: e.key + 1,
                        isExpanded: _expandedRule == e.key,
                        onTap: () => setState(() {
                          _expandedRule = _expandedRule == e.key ? null : e.key;
                        }),
                      ),
                    ),
                  ),
                  const SizedBox(height: 20),
                  _buildSanctionCardModern(),
                  const SizedBox(height: 24),
                  _buildFooter(),
                ],
              ),
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
            final x = math.cos(_rotateCtrl.value * 0.4 + angle) * 160;
            final y = math.sin(_rotateCtrl.value * 0.6 + angle) * 100;
            final color = _C.rainbow[(i * 2) % _C.rainbow.length];
            final size = 60 + 20 * math.sin(_rotateCtrl.value + i).abs();
            return Positioned(
              left: MediaQuery.of(context).size.width / 2 + x - size / 2,
              top: MediaQuery.of(context).size.height / 2 + y - size / 2,
              child: Container(
                width: size,
                height: size,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: RadialGradient(
                    colors: [color.withOpacity(0.05), Colors.transparent],
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

  // ─── DIGITAL CLOCK ──────────────────────────────────────────────────────
  Widget _buildDigitalClock() {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
      decoration: BoxDecoration(
        color: _C.card.withOpacity(0.4),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: _C.rainbow[DateTime.now().second % _C.rainbow.length]
              .withOpacity(0.2),
          width: 1,
        ),
        boxShadow: [
          BoxShadow(
            color: _C.purple.withOpacity(0.05),
            blurRadius: 12,
          ),
        ],
      ),
      child: Column(
        children: [
          AnimatedBuilder(
            animation: _glowCtrl,
            builder: (_, __) {
              return Container(
                height: 2,
                width: double.infinity,
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      Colors.transparent,
                      ..._C.rainbow,
                      Colors.transparent,
                    ],
                    stops: const [0.0, 0.05, 0.15, 0.25, 0.35, 0.45, 0.55, 0.65, 0.75, 0.85, 0.95, 1.0],
                  ),
                  borderRadius: BorderRadius.circular(2),
                  boxShadow: [
                    BoxShadow(
                      color: _C.purple.withOpacity(0.5 * _glowCtrl.value),
                      blurRadius: 14 + 10 * _glowCtrl.value,
                      spreadRadius: 2,
                    ),
                  ],
                ),
              );
            },
          ),
          const SizedBox(height: 4),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              _clockItem('WIB', _timeWIB, _C.purpleL),
              _clockItem('WITA', _timeWITA, _C.pink),
              _clockItem('WIT', _timeWIT, _C.cyan),
            ],
          ),
          const SizedBox(height: 4),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              AnimatedContainer(
                duration: const Duration(milliseconds: 500),
                width: 5,
                height: 5,
                decoration: BoxDecoration(
                  color: _showColon ? _C.green : _C.green.withOpacity(0.15),
                  shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(
                      color: _C.green.withOpacity(_showColon ? 0.8 : 0.05),
                      blurRadius: 8,
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 6),
              Text(
                'LIVE',
                style: TextStyle(
                  color: _C.green.withOpacity(_showColon ? 0.9 : 0.2),
                  fontSize: 8,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 1.5,
                  fontFamily: 'Orbitron',
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _clockItem(String label, String time, Color color) {
    return Column(
      children: [
        Text(
          label,
          style: TextStyle(
            color: _C.textDim.withOpacity(0.5),
            fontSize: 8,
            fontWeight: FontWeight.w600,
            letterSpacing: 1.2,
            fontFamily: 'Orbitron',
          ),
        ),
        const SizedBox(height: 2),
        Stack(
          children: [
            Text(
              time,
              style: TextStyle(
                color: color.withOpacity(0.08),
                fontSize: 14,
                fontWeight: FontWeight.w700,
                fontFamily: 'Orbitron',
                letterSpacing: 1.5,
                shadows: [
                  Shadow(color: color.withOpacity(0.3), blurRadius: 25),
                ],
              ),
            ),
            Text(
              time,
              style: TextStyle(
                color: color.withOpacity(0.2),
                fontSize: 14,
                fontWeight: FontWeight.w700,
                fontFamily: 'Orbitron',
                letterSpacing: 1.5,
                shadows: [
                  Shadow(color: color.withOpacity(0.6), blurRadius: 40),
                ],
              ),
            ),
            Text(
              time,
              style: TextStyle(
                color: Colors.white,
                fontSize: 14,
                fontWeight: FontWeight.w700,
                fontFamily: 'Orbitron',
                letterSpacing: 1.5,
                shadows: [
                  Shadow(color: color, blurRadius: 12),
                ],
              ),
            ),
          ],
        ),
      ],
    );
  }

  // ─── HERO HEADER ──────────────────────────────────────────────────────────
  Widget _buildHeroHeader() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 12),
      child: Column(
        children: [
          ShaderMask(
            shaderCallback: (rect) => _C.rainbowGrad.createShader(rect),
            child: const Text('Peraturan &\nInformasi',
                style: TextStyle(
                  color: _C.text,
                  fontSize: 28,
                  fontWeight: FontWeight.w800,
                  height: 1.2,
                  letterSpacing: -0.5,
                  fontFamily: 'Orbitron',
                )),
          ),
          const SizedBox(height: 8),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: _C.purple.withOpacity(0.2)),
              color: _C.purple.withOpacity(0.05),
            ),
            child: const Text('Patuhi aturan untuk kenyamanan bersama',
                style: TextStyle(color: _C.textSub, fontSize: 12, fontFamily: 'ShareTechMono')),
          ),
        ],
      ),
    );
  }

  // ─── STATUS CARD MODERN ──────────────────────────────────────────────────
  Widget _buildStatusCardModern() {
    return AnimatedBuilder(
      animation: _pulseAnim,
      builder: (_, __) => Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [_C.card, _C.surface],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(24),
          border: Border.all(
            color: (_apiOnline ? _pingColor : _C.red).withOpacity(0.3 + _pulseAnim.value * 0.1),
            width: 1.5,
          ),
          boxShadow: [
            BoxShadow(
              color: (_apiOnline ? _pingColor : _C.red).withOpacity(0.1 * _pulseAnim.value),
              blurRadius: 20 + 10 * _pulseAnim.value,
              offset: const Offset(0, 8),
            ),
          ],
        ),
        child: Column(
          children: [
            Row(
              children: [
                AnimatedBuilder(
                  animation: _pingDot,
                  builder: (_, __) => Container(
                    width: 48, height: 48,
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [
                          (_apiOnline ? _pingColor : _C.red).withOpacity(0.15 * _pingDot.value),
                          (_apiOnline ? _pingColor : _C.red).withOpacity(0.05),
                        ],
                      ),
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(
                        color: (_apiOnline ? _pingColor : _C.red).withOpacity(0.3 * _pingDot.value),
                        width: 1.5,
                      ),
                    ),
                    child: Icon(
                      _apiOnline ? Icons.check_circle_rounded : Icons.error_rounded,
                      color: _apiOnline ? _pingColor : _C.red,
                      size: 24,
                    ),
                  ),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('API SERVER',
                          style: TextStyle(
                              color: _C.textDim, fontSize: 11,
                              fontWeight: FontWeight.w600, letterSpacing: 1,
                              fontFamily: 'Orbitron')),
                      const SizedBox(height: 4),
                      Text(_apiOnline ? 'Online' : 'Offline',
                          style: TextStyle(
                              color: _apiOnline ? _pingColor : _C.red,
                              fontSize: 16, fontWeight: FontWeight.bold,
                              fontFamily: 'Orbitron')),
                      Text(_pingLabel,
                          style: TextStyle(
                              color: _pingColor.withOpacity(0.7),
                              fontSize: 10, fontWeight: FontWeight.w600)),
                    ],
                  ),
                ),
                // Ping Ring
                Container(
                  width: 56, height: 56,
                  child: Stack(
                    alignment: Alignment.center,
                    children: [
                      SizedBox(
                        width: 50, height: 50,
                        child: CircularProgressIndicator(
                          value: _apiOnline ? (_pingMs / 500).clamp(0.0, 1.0) : 0,
                          strokeWidth: 3,
                          backgroundColor: _C.border,
                          color: _pingColor,
                        ),
                      ),
                      Text(_apiOnline ? '$_pingMs' : '0',
                          style: TextStyle(
                              color: _pingColor, fontSize: 14,
                              fontWeight: FontWeight.bold,
                              fontFamily: 'Orbitron')),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 14),
            if (!_apiOnline)
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: _C.red.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Row(
                  children: [
                    Icon(Icons.wifi_off_rounded, color: _C.red, size: 16),
                    const SizedBox(width: 8),
                    const Expanded(
                      child: Text('Koneksi ke server terputus',
                          style: TextStyle(color: _C.textSub, fontSize: 12)),
                    ),
                  ],
                ),
              ),
          ],
        ),
      ),
    );
  }

  // ─── MODERN SECTION HEADER ─────────────────────────────────────────────────
  Widget _buildModernSectionHeader() {
    return Row(
      children: [
        Container(
          width: 4, height: 28,
          decoration: BoxDecoration(
            gradient: _C.rainbowGrad,
            borderRadius: BorderRadius.circular(2),
          ),
        ),
        const SizedBox(width: 12),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            ShaderMask(
              shaderCallback: (rect) => _C.rainbowGrad.createShader(rect),
              child: const Text('PERATURAN',
                  style: TextStyle(color: _C.text, fontSize: 18,
                      fontWeight: FontWeight.w800, letterSpacing: -0.3,
                      fontFamily: 'Orbitron')),
            ),
            const Text('Tap untuk melihat detail',
                style: TextStyle(color: _C.textSub, fontSize: 11)),
          ],
        ),
        const Spacer(),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
          decoration: BoxDecoration(
            color: _C.purple.withOpacity(0.1),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: _C.purple.withOpacity(0.2)),
          ),
          child: Text('${_rules.length} ATURAN',
              style: const TextStyle(color: _C.purpleL, fontSize: 10,
                  fontWeight: FontWeight.w700, fontFamily: 'Orbitron')),
        ),
      ],
    );
  }

  // ─── SANCTION CARD MODERN ──────────────────────────────────────────────────
  Widget _buildSanctionCardModern() {
    return AnimatedBuilder(
      animation: _sanctionCtrl,
      builder: (_, __) => Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [_C.card.withOpacity(0.5), _C.surface],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(24),
          border: Border.all(
            color: _C.red.withOpacity(0.3 + _sanctionGlow.value * 0.3),
            width: 1.5,
          ),
          boxShadow: [
            BoxShadow(
              color: _C.red.withOpacity(0.1 * _sanctionGlow.value),
              blurRadius: 30,
              spreadRadius: 2,
            ),
          ],
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(24),
          child: Stack(
            children: [
              Positioned(
                right: -20, top: -20,
                child: Icon(Icons.gavel_rounded,
                    size: 100, color: _C.red.withOpacity(0.05)),
              ),
              Padding(
                padding: const EdgeInsets.all(20),
                child: Column(
                  children: [
                    Row(
                      children: [
                        AnimatedContainer(
                          duration: const Duration(milliseconds: 500),
                          padding: const EdgeInsets.all(10),
                          decoration: BoxDecoration(
                            color: _C.red.withOpacity(0.15 + _sanctionGlow.value * 0.1),
                            borderRadius: BorderRadius.circular(14),
                            border: Border.all(
                              color: _C.red.withOpacity(0.3 + _sanctionGlow.value * 0.2),
                              width: 1.5,
                            ),
                          ),
                          child: Icon(Icons.warning_rounded,
                              color: _C.red.withOpacity(0.8 + _sanctionGlow.value * 0.2),
                              size: 22),
                        ),
                        const SizedBox(width: 12),
                        const Expanded(
                          child: Text('SANKSI TEGAS',
                              style: TextStyle(color: _C.red, fontSize: 16,
                                  fontWeight: FontWeight.w800, letterSpacing: 1,
                                  fontFamily: 'Orbitron')),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    Container(
                      padding: const EdgeInsets.all(14),
                      decoration: BoxDecoration(
                        color: _C.red.withOpacity(0.05),
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: _C.red.withOpacity(0.15)),
                      ),
                      child: const Row(
                        children: [
                          Icon(Icons.block_rounded, color: _C.red, size: 20),
                          SizedBox(width: 12),
                          Expanded(
                            child: Text('Akun akan DIHAPUS secara permanen',
                                style: TextStyle(color: _C.text, fontSize: 13,
                                    fontWeight: FontWeight.w600,
                                    fontFamily: 'ShareTechMono')),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 12),
                    Wrap(
                      spacing: 8,
                      children: [
                        _sanctionChip(Icons.account_balance_wallet_rounded, 'Tanpa refund'),
                        _sanctionChip(Icons.sync_disabled_rounded, 'Tanpa kompensasi'),
                        _sanctionChip(Icons.person_off_rounded, 'Permanent ban'),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _sanctionChip(IconData icon, String label) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(20),
        color: _C.red.withOpacity(0.08),
        border: Border.all(color: _C.red.withOpacity(0.2)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: _C.red, size: 12),
          const SizedBox(width: 4),
          Text(label,
              style: const TextStyle(color: _C.textSub, fontSize: 10,
                  fontWeight: FontWeight.w500, fontFamily: 'ShareTechMono')),
        ],
      ),
    );
  }

  Widget _buildFooter() {
    return Column(children: [
      Container(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
        decoration: BoxDecoration(
          color: _C.surface,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: _C.border),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(Icons.shield_moon_rounded, color: _C.purpleL, size: 18),
            const SizedBox(width: 12),
            const Expanded(
              child: Text(
                'Dengan menggunakan aplikasi ini, pengguna dianggap telah '
                'menyetujui seluruh peraturan yang berlaku.',
                style: TextStyle(color: _C.textSub, fontSize: 11, height: 1.5,
                    fontFamily: 'ShareTechMono'),
              ),
            ),
          ],
        ),
      ),
      const SizedBox(height: 16),
      Row(mainAxisAlignment: MainAxisAlignment.center, children: [
        Container(
          height: 2, width: 30,
          decoration: BoxDecoration(
            gradient: _C.rainbowGrad,
            borderRadius: BorderRadius.circular(2),
          ),
        ),
        const SizedBox(width: 10),
        ShaderMask(
          shaderCallback: (rect) => _C.rainbowGrad.createShader(rect),
          child: const Text('SYNTAX PHANTOM',
              style: TextStyle(color: _C.text, fontSize: 10,
                  fontWeight: FontWeight.w600, letterSpacing: 0.5,
                  fontFamily: 'Orbitron')),
        ),
        const SizedBox(width: 10),
        Container(
          height: 2, width: 30,
          decoration: BoxDecoration(
            gradient: _C.rainbowGrad,
            borderRadius: BorderRadius.circular(2),
          ),
        ),
      ]),
    ]);
  }

  PreferredSizeWidget _buildAppBar() {
    return AppBar(
      backgroundColor: Colors.transparent,
      elevation: 0,
      automaticallyImplyLeading: false,
      centerTitle: true,
      title: const SizedBox.shrink(),
      flexibleSpace: Container(
        decoration: BoxDecoration(
          border: Border(
            bottom: BorderSide(
              color: _C.rainbow[DateTime.now().second % _C.rainbow.length]
                  .withOpacity(0.2),
              width: 0.5,
            ),
          ),
        ),
      ),
    );
  }
}

// ─── MODERN RULE CARD ─────────────────────────────────────────────────────────
class _ModernRuleCard extends StatelessWidget {
  final _Rule rule;
  final int number;
  final bool isExpanded;
  final VoidCallback onTap;

  const _ModernRuleCard({
    required this.rule,
    required this.number,
    required this.isExpanded,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final color = rule.color;

    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [
              isExpanded ? color.withOpacity(0.08) : _C.card,
              isExpanded ? color.withOpacity(0.04) : _C.surface,
            ],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: isExpanded ? color.withOpacity(0.4) : _C.border,
            width: isExpanded ? 1.5 : 1,
          ),
          boxShadow: isExpanded ? [
            BoxShadow(
              color: color.withOpacity(0.1),
              blurRadius: 20,
              spreadRadius: 2,
            ),
          ] : [],
        ),
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.all(14),
              child: Row(
                children: [
                  Container(
                    width: 34, height: 34,
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [color.withOpacity(0.2), color.withOpacity(0.05)],
                      ),
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(color: color.withOpacity(0.3)),
                    ),
                    child: Center(
                      child: Text('$number',
                          style: TextStyle(color: color, fontSize: 14,
                              fontWeight: FontWeight.bold,
                              fontFamily: 'Orbitron')),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Container(
                    width: 36, height: 36,
                    decoration: BoxDecoration(
                      color: color.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Icon(rule.icon, color: color, size: 18),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(rule.title,
                        style: TextStyle(
                          color: isExpanded ? _C.text : _C.text,
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                          fontFamily: 'Orbitron',
                        )),
                  ),
                  AnimatedRotation(
                    turns: isExpanded ? 0.5 : 0,
                    duration: const Duration(milliseconds: 300),
                    child: Icon(Icons.keyboard_arrow_down_rounded,
                        color: isExpanded ? color : _C.textDim, size: 20),
                  ),
                ],
              ),
            ),
            AnimatedCrossFade(
              firstChild: const SizedBox(width: double.infinity),
              secondChild: Padding(
                padding: const EdgeInsets.fromLTRB(14, 0, 14, 14),
                child: Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: _C.surface,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: _C.border),
                  ),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Container(
                        width: 3, height: 30,
                        decoration: BoxDecoration(
                          color: color,
                          borderRadius: BorderRadius.circular(2),
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Text(rule.desc,
                            style: const TextStyle(color: _C.textSub, fontSize: 12,
                                height: 1.5, fontFamily: 'ShareTechMono')),
                      ),
                    ],
                  ),
                ),
              ),
              crossFadeState: isExpanded
                  ? CrossFadeState.showSecond
                  : CrossFadeState.showFirst,
              duration: const Duration(milliseconds: 300),
            ),
          ],
        ),
      ),
    );
  }
}

// ─── ANIMATED BACKGROUND ──────────────────────────────────────────────────────
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
    const step = 40.0;
    for (double x = 0; x < size.width; x += step) {
      canvas.drawLine(Offset(x, 0), Offset(x, size.height), grid);
    }
    for (double y = 0; y < size.height; y += step) {
      canvas.drawLine(Offset(0, y), Offset(size.width, y), grid);
    }
    
    final glow = Paint()
      ..shader = RadialGradient(colors: [
        _C.purple.withOpacity(0.06 + math.sin(t * math.pi * 2) * 0.02),
        Colors.transparent,
      ], radius: 0.9).createShader(Rect.fromCircle(
          center: Offset(size.width / 2, size.height * 0.15),
          radius: size.width * 0.7));
    canvas.drawCircle(
        Offset(size.width / 2, size.height * 0.15), size.width * 0.7, glow);
        
    final glow2 = Paint()
      ..shader = RadialGradient(colors: [
        _C.pink.withOpacity(0.04 + math.cos(t * math.pi * 2) * 0.02),
        Colors.transparent,
      ], radius: 0.5).createShader(Rect.fromCircle(
          center: Offset(size.width * 0.85, size.height * 0.75),
          radius: size.width * 0.4));
    canvas.drawCircle(
        Offset(size.width * 0.85, size.height * 0.75),
        size.width * 0.4,
        glow2);
  }

  @override
  bool shouldRepaint(_BgPainter old) => old.t != t;
}