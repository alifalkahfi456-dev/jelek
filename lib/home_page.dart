import 'dart:async';
import 'dart:convert';
import 'dart:math' as math;
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:video_player/video_player.dart';
import 'api_config.dart';

// ─── PALETTE CYBER RAINBOW HACKER ──────────────────────────────────────────
class _C {
  static const bg          = Color(0xFF0A0015);
  static const surface     = Color(0xFF15002A);
  static const card        = Color(0xFF1A0A2E);
  static const cardAlt     = Color(0xFF2D1B4E);
  static const border      = Color(0xFF5B2D8E);
  
  // Rainbow colors
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
  static const white       = Color(0xFFFFFFFF);

  static const List<Color> rainbow = [
    purple, pink, cyan, green, yellow, orange, red, purpleL, blue, teal, gold
  ];
  
  static const LinearGradient rainbowGrad = LinearGradient(
    colors: rainbow,
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );
  
  static const LinearGradient hackerGrad = LinearGradient(
    colors: [Color(0xFF7C3AED), Color(0xFFF0ABFC), Color(0xFF7C3AED)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );
}

class HomePage extends StatefulWidget {
  final String username;
  final String password;
  final String sessionKey;
  final List<Map<String, dynamic>> listBug;
  final String role;
  final String expiredDate;

  const HomePage({
    super.key,
    required this.username,
    required this.password,
    required this.sessionKey,
    required this.listBug,
    required this.role,
    required this.expiredDate,
  });

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> with TickerProviderStateMixin {
  late VideoPlayerController _videoController;
  late AnimationController _pulseController;
  late AnimationController _glowController;
  late AnimationController _resultCtrl;
  late AnimationController _rotateCtrl;
  late Animation<double> _resultFade;
  late Animation<Offset> _resultSlide;

  final targetController = TextEditingController();
  final PageController _bugPageController = PageController(viewportFraction: 0.85);

  String? _selectedBugId;
  bool _isSending = false;
  String? _responseMessage;
  int _currentBugPage = 0;

  // Sender
  List<String> _globalSenders = [];
  bool _isLoadingSenders = false;
  int _privateSenderCount = 0;
  int _globalSenderCount = 0;
  bool _loadingSender = false;
  Timer? _senderTimer;

  String _selectedSender = 'private';

  // ─── COLORS ──────────────────────────────────────────────────────────────
  final Color _purpleAccent = _C.purple;
  final Color _purpleLight = _C.purpleL;
  final Color _purpleGlow = _C.purpleG;
  final Color _textWhite = _C.white;
  final Color _textGrey = _C.textSub;

  bool get canAccessGlobalSender {
    final r = widget.role.toLowerCase();
    return ['owner', 'high_owner', 'founder', 'developer'].contains(r);
  }

  @override
  void initState() {
    super.initState();

    _videoController = VideoPlayerController.asset('assets/videos/background.mp4')
      ..initialize().then((_) {
        if (!mounted) return;
        setState(() {});
        _videoController.setLooping(true);
        _videoController.setVolume(0.0);
        _videoController.play();
      });

    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
    )..repeat(reverse: true);

    _glowController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
    )..repeat(reverse: true);

    _rotateCtrl = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 20),
    )..repeat();

    _resultCtrl = AnimationController(vsync: this, duration: const Duration(milliseconds: 450));
    _resultFade = CurvedAnimation(parent: _resultCtrl, curve: Curves.easeOut);
    _resultSlide = Tween<Offset>(begin: const Offset(0, 0.12), end: Offset.zero)
        .animate(CurvedAnimation(parent: _resultCtrl, curve: Curves.easeOutCubic));

    _fetchSenderStats();
    _loadGlobalSenders();
    _senderTimer = Timer.periodic(const Duration(seconds: 30), (_) {
      _fetchSenderStats();
    });

    if (widget.listBug.isNotEmpty) {
      final firstBug = widget.listBug[0];
      _selectedBugId = firstBug['bug_id'] as String? ?? '0';
    }
  }

  @override
  void dispose() {
    _videoController.dispose();
    _pulseController.dispose();
    _glowController.dispose();
    _rotateCtrl.dispose();
    _resultCtrl.dispose();
    targetController.dispose();
    _bugPageController.dispose();
    _senderTimer?.cancel();
    super.dispose();
  }

  // ─── FETCH SENDER STATS ──────────────────────────────────────────────────
  Future<void> _fetchSenderStats() async {
    if (_loadingSender) return;
    setState(() => _loadingSender = true);
    try {
      final response = await http.get(
        Uri.parse("http://tirzzadminbaik.pteroqdactyl.my.id:11560/getSenderStats?key=${widget.sessionKey}"),
      ).timeout(const Duration(seconds: 10));
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (data['valid'] == true) {
          setState(() {
            _privateSenderCount = data['private'] ?? 0;
            _globalSenderCount = data['global'] ?? 0;
            _loadingSender = false;
          });
        } else {
          setState(() => _loadingSender = false);
        }
      } else {
        setState(() => _loadingSender = false);
      }
    } catch (_) {
      setState(() => _loadingSender = false);
    }
  }

  // ─── LOAD GLOBAL SENDERS ─────────────────────────────────────────────────
  Future<void> _loadGlobalSenders() async {
    setState(() => _isLoadingSenders = true);
    try {
      final res = await http.get(Uri.parse(
        'http://tirzzadminbaik.pteroqdactyl.my.id:11560/getActiveSenders?key=${widget.sessionKey}',
      )).timeout(const Duration(seconds: 10));
      final data = jsonDecode(res.body);
      if (data['valid'] == true && data['senders'] != null) {
        if (mounted) {
          setState(() {
            _globalSenders = List<String>.from(data['senders']);
            _globalSenderCount = _globalSenders.length;
          });
        }
      } else {
        if (mounted) setState(() => _globalSenders = []);
      }
    } catch (_) {
      if (mounted) setState(() => _globalSenders = []);
    } finally {
      if (mounted) setState(() => _isLoadingSenders = false);
    }
  }

  // ─── HELPERS ──────────────────────────────────────────────────────────────
  String? formatPhoneNumber(String input) {
    final cleaned = input.replaceAll(RegExp(r'[^\d+]'), '');
    if (!cleaned.startsWith('+') || cleaned.length < 8) return null;
    return cleaned;
  }

  void _setResponse(String type, String msg) {
    if (!mounted) return;
    setState(() => _responseMessage = '$type|$msg');
    _resultCtrl.forward(from: 0);
  }

  // ─── SEND BUG ─────────────────────────────────────────────────────────────
  Future<void> _sendBug() async {
    final rawInput = targetController.text.trim();
    final key = widget.sessionKey;

    if (formatPhoneNumber(rawInput) == null) {
      _showAlert("❌ Nomor Tidak Valid",
          "Gunakan format internasional.\nContoh: +62812xxxxxxxx");
      return;
    }

    if (_selectedSender == 'global' && !canAccessGlobalSender) {
      _showAlert("❌ Akses Ditolak",
          "Sender Global hanya untuk Owner ke atas!");
      return;
    }

    if (_selectedBugId == null || _selectedBugId!.isEmpty) {
      _showAlert("❌ No Bug Selected", "Pilih 1 bug untuk dikirim.");
      return;
    }

    if (_selectedSender == 'private' && _privateSenderCount == 0) {
      _showAlert("❌ No Private Sender", "Tidak ada private sender tersedia.");
      return;
    }
    if (_selectedSender == 'global' && _globalSenderCount == 0) {
      _showAlert("❌ No Global Sender", "Tidak ada global sender tersedia.");
      return;
    }

    setState(() {
      _isSending = true;
      _responseMessage = null;
    });
    _resultCtrl.reset();

    try {
      final encodedTarget = Uri.encodeComponent(rawInput);
      final res = await http.get(Uri.parse(
        'http://tirzzadminbaik.pteroqdactyl.my.id:11560/sendBug'
        '?key=$key'
        '&target=$encodedTarget'
        '&bug=${_selectedBugId}'
        '${_selectedSender == 'global' ? '&senderMode=global' : '&sender=private'}',
      )).timeout(const Duration(seconds: 15));
      final data = jsonDecode(res.body);

      if (data['valid'] == false) {
        _setResponse('error', 'Session key tidak valid. Silakan login ulang.');
      } else if (data['cooldown'] == true) {
        final wait = data['wait'] ?? 0;
        _setResponse('warning', 'Cooldown aktif! Tunggu $wait detik lagi.');
      } else if (data['sended'] == true) {
        final role = data['role'] ?? widget.role;
        _setResponse('success', 'Bug berhasil dikirim ke $rawInput! [$role]');
        targetController.clear();
      } else {
        _setResponse('error', 'Gagal mengirim. Server sedang maintenance.');
      }
    } on Exception catch (e) {
      if (e.toString().contains('TimeoutException')) {
        _setResponse('error', 'Request timeout. Periksa koneksi internet.');
      } else {
        _setResponse('error', 'Koneksi error. Periksa jaringan dan coba lagi.');
      }
    } finally {
      if (mounted) setState(() => _isSending = false);
    }
  }

  // ─── ALERT DIALOG ─────────────────────────────────────────────────────────
  void _showAlert(String title, String msg) {
    showDialog(
      context: context,
      builder: (_) => BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
        child: AlertDialog(
          backgroundColor: _C.card.withOpacity(0.95),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(24),
            side: BorderSide(
              color: _C.rainbow[DateTime.now().second % _C.rainbow.length]
                  .withOpacity(0.5),
              width: 1.5,
            ),
          ),
          title: ShaderMask(
            shaderCallback: (rect) => _C.rainbowGrad.createShader(rect),
            child: Text(title,
                style: TextStyle(
                  color: _C.white,
                  fontFamily: 'Orbitron',
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                )),
          ),
          content: Text(msg, style: TextStyle(color: _C.textSub, fontFamily: 'ShareTechMono')),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: ShaderMask(
                shaderCallback: (rect) => _C.rainbowGrad.createShader(rect),
                child: const Text("OK",
                    style: TextStyle(
                      color: _C.white,
                      fontWeight: FontWeight.bold,
                      fontFamily: 'Orbitron',
                    )),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ─── GLASS CARD ───────────────────────────────────────────────────────────
  Widget _glassCard({
    required Widget child,
    EdgeInsets padding = const EdgeInsets.all(16),
    BorderRadius? borderRadius,
    double blurSigma = 16,
  }) {
    return ClipRRect(
      borderRadius: borderRadius ?? BorderRadius.circular(20),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: blurSigma, sigmaY: blurSigma),
        child: Container(
          padding: padding,
          decoration: BoxDecoration(
            color: _C.card.withOpacity(0.5),
            borderRadius: borderRadius ?? BorderRadius.circular(20),
            border: Border.all(
              color: _C.rainbow[DateTime.now().second % _C.rainbow.length]
                  .withOpacity(0.15),
              width: 1,
            ),
          ),
          child: child,
        ),
      ),
    );
  }

  // ─── RAINBOW BACKGROUND EFFECT ──────────────────────────────────────────
  Widget _buildRainbowOverlay() {
    return AnimatedBuilder(
      animation: _rotateCtrl,
      builder: (_, __) {
        return Container(
          decoration: BoxDecoration(
            gradient: RadialGradient(
              center: Alignment(
                math.sin(_rotateCtrl.value * 0.5) * 0.2,
                math.cos(_rotateCtrl.value * 0.7) * 0.2,
              ),
              radius: 1.5,
              colors: [
                _C.rainbow[_rotateCtrl.value.toInt() % _C.rainbow.length]
                    .withOpacity(0.04),
                _C.rainbow[(_rotateCtrl.value.toInt() + 3) % _C.rainbow.length]
                    .withOpacity(0.02),
                Colors.transparent,
              ],
              stops: const [0.0, 0.5, 1.0],
            ),
          ),
        );
      },
    );
  }

  // ─── TOP APP BAR ──────────────────────────────────────────────────────────
  Widget _buildTopAppBar() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      child: Row(
        children: [
          AnimatedBuilder(
            animation: _pulseController,
            builder: (_, __) => Transform.scale(
              scale: 1 + _pulseController.value * 0.03,
              child: Container(
                width: 36,
                height: 36,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: LinearGradient(
                    colors: [_C.purple, _C.pink],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: _C.purple.withOpacity(0.4 + _pulseController.value * 0.2),
                      blurRadius: 16 + _pulseController.value * 8,
                    ),
                  ],
                ),
                child: const Icon(Icons.shield_rounded, color: _C.white, size: 20),
              ),
            ),
          ),
          const SizedBox(width: 10),
          ShaderMask(
            shaderCallback: (rect) => _C.rainbowGrad.createShader(rect),
            child: const Text(
              'HACKER - CORE',
              style: TextStyle(
                color: _C.white,
                fontFamily: 'Orbitron',
                fontWeight: FontWeight.w900,
                fontSize: 19,
                letterSpacing: 2,
              ),
            ),
          ),
          const Spacer(),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(20),
              border: Border.all(
                color: _C.rainbow[DateTime.now().second % _C.rainbow.length]
                    .withOpacity(0.4),
                width: 1.5,
              ),
              color: _C.card.withOpacity(0.3),
            ),
            child: Text(
              'V.3.0.0',
              style: TextStyle(
                color: _C.rainbow[DateTime.now().second % _C.rainbow.length],
                fontFamily: 'Orbitron',
                fontWeight: FontWeight.bold,
                fontSize: 13,
                letterSpacing: 1,
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ─── HEADER / USER CARD ───────────────────────────────────────────────────
  Widget _buildHeader() {
    return _glassCard(
      padding: const EdgeInsets.all(18),
      child: Column(
        children: [
          Row(
            children: [
              AnimatedBuilder(
                animation: _pulseController,
                builder: (_, __) => Container(
                  width: 58,
                  height: 58,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: _C.rainbow[DateTime.now().second % _C.rainbow.length]
                          .withOpacity(0.6),
                      width: 2.5,
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: _C.purple.withOpacity(0.4 + _pulseController.value * 0.2),
                        blurRadius: 20 + _pulseController.value * 10,
                        spreadRadius: 2,
                      ),
                    ],
                  ),
                  child: ClipOval(
                    child: Image.asset(
                      'assets/images/logo.png',
                      fit: BoxFit.cover,
                      errorBuilder: (_, __, ___) =>
                          Icon(Icons.person, color: _C.purple, size: 32),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    ShaderMask(
                      shaderCallback: (rect) => _C.rainbowGrad.createShader(rect),
                      child: Text(
                        widget.username.toUpperCase(),
                        style: const TextStyle(
                          color: _C.white,
                          fontFamily: 'Orbitron',
                          fontWeight: FontWeight.w900,
                          fontSize: 18,
                          letterSpacing: 1,
                        ),
                      ),
                    ),
                    const SizedBox(height: 4),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: _C.purple.withOpacity(0.3)),
                        color: _C.purple.withOpacity(0.08),
                      ),
                      child: Text(
                        widget.role.toUpperCase(),
                        style: TextStyle(
                          color: _C.purpleL,
                          fontFamily: 'ShareTechMono',
                          fontWeight: FontWeight.bold,
                          fontSize: 11,
                          letterSpacing: 2,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
                decoration: BoxDecoration(
                  color: _C.card.withOpacity(0.5),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: _C.purple.withOpacity(0.2)),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.access_time_rounded, color: _C.textDim, size: 13),
                    const SizedBox(width: 5),
                    Text(
                      widget.expiredDate,
                      style: TextStyle(
                        color: _C.textSub,
                        fontFamily: 'ShareTechMono',
                        fontSize: 11,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Container(
            padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 4),
            decoration: BoxDecoration(
              color: _C.surface.withOpacity(0.5),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: _C.border.withOpacity(0.2)),
            ),
            child: Row(
              children: [
                _buildStatItem(Icons.bug_report_rounded, _C.purple,
                    '${widget.listBug.length}', 'Total Bugs'),
                _buildStatDivider(),
                _buildStatItem(Icons.bolt_rounded, _C.cyan, 'GACOR', 'Success Rate'),
                _buildStatDivider(),
                _buildStatItem(Icons.check_circle_rounded, _C.green, 'ACTIVE', 'Status'),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatItem(IconData icon, Color color, String value, String label) {
    return Expanded(
      child: Column(
        children: [
          AnimatedBuilder(
            animation: _pulseController,
            builder: (_, __) => Container(
              width: 46,
              height: 46,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: color.withOpacity(0.15 + _pulseController.value * 0.05),
                border: Border.all(color: color.withOpacity(0.2), width: 1),
              ),
              child: Icon(icon, color: color, size: 24),
            ),
          ),
          const SizedBox(height: 7),
          Text(value,
              style: TextStyle(
                  color: _C.text,
                  fontWeight: FontWeight.w900,
                  fontSize: 14,
                  fontFamily: 'Orbitron')),
          const SizedBox(height: 2),
          Text(label,
              style: TextStyle(
                  color: _C.textDim, fontSize: 10, fontFamily: 'ShareTechMono')),
        ],
      ),
    );
  }

  Widget _buildStatDivider() {
    return Container(width: 1, height: 52, color: _C.border.withOpacity(0.3));
  }

  // ─── TARGET INPUT + BUG CAROUSEL ──────────────────────────────────────────
  Widget _buildNomorAndBugPanel() {
    return _glassCard(
      padding: const EdgeInsets.all(18),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.phone_android_rounded, color: _C.purple, size: 18),
              const SizedBox(width: 8),
              Text(
                'NOMOR TARGET',
                style: TextStyle(
                  color: _C.text,
                  fontFamily: 'Orbitron',
                  fontWeight: FontWeight.bold,
                  fontSize: 13,
                  letterSpacing: 2,
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          
          Container(
            decoration: BoxDecoration(
              color: _C.surface.withOpacity(0.5),
              borderRadius: BorderRadius.circular(14),
              border: Border.all(
                color: _C.rainbow[DateTime.now().second % _C.rainbow.length]
                    .withOpacity(0.2),
                width: 1,
              ),
            ),
            child: TextField(
              controller: targetController,
              style: TextStyle(color: _C.text, fontFamily: 'ShareTechMono', fontSize: 15),
              cursorColor: _C.purple,
              keyboardType: TextInputType.phone,
              decoration: InputDecoration(
                hintText: 'Contoh: +62812xxxxxxxx',
                hintStyle: TextStyle(color: _C.textDim.withOpacity(0.5), fontFamily: 'ShareTechMono'),
                prefixIcon: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 14),
                  child: Icon(Icons.language_rounded, color: _C.textDim, size: 20),
                ),
                prefixIconConstraints: const BoxConstraints(minWidth: 50, minHeight: 50),
                border: InputBorder.none,
                contentPadding: const EdgeInsets.symmetric(vertical: 16, horizontal: 16),
              ),
            ),
          ),
          const SizedBox(height: 20),

          Row(
            children: [
              Icon(Icons.bug_report, color: _C.purpleG, size: 20),
              const SizedBox(width: 8),
              Text(
                'PILIH BUG',
                style: TextStyle(
                  color: _C.text,
                  fontFamily: 'Orbitron',
                  fontWeight: FontWeight.bold,
                  fontSize: 13,
                  letterSpacing: 2,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),

          SizedBox(
            height: 170,
            child: PageView.builder(
              controller: _bugPageController,
              itemCount: widget.listBug.length,
              onPageChanged: (i) {
                setState(() {
                  _currentBugPage = i;
                  final bug = widget.listBug[i];
                  final bugId = bug['bug_id'] as String? ?? '$i';
                  _selectedBugId = bugId;
                });
              },
              itemBuilder: (context, index) {
                final bug = widget.listBug[index];
                final bugId = bug['bug_id'] as String? ?? '$index';
                final isSelected = _selectedBugId == bugId;
                final color = _C.rainbow[index % _C.rainbow.length];

                return AnimatedBuilder(
                  animation: _bugPageController,
                  builder: (context, child) {
                    double scale = 1.0;
                    if (_bugPageController.position.haveDimensions) {
                      double diff = (_bugPageController.page! - index).abs();
                      scale = (1 - diff * 0.07).clamp(0.93, 1.0);
                    }
                    return Transform.scale(scale: scale, child: child);
                  },
                  child: GestureDetector(
                    onTap: () => setState(() => _selectedBugId = bugId),
                    child: Padding(
                      padding: const EdgeInsets.only(right: 10),
                      child: Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            colors: [
                              isSelected ? color.withOpacity(0.2) : _C.surface.withOpacity(0.3),
                              isSelected ? color.withOpacity(0.05) : _C.card.withOpacity(0.2),
                            ],
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                          ),
                          borderRadius: BorderRadius.circular(18),
                          border: Border.all(
                            color: isSelected ? color : _C.border,
                            width: isSelected ? 2 : 1,
                          ),
                          boxShadow: isSelected ? [
                            BoxShadow(
                              color: color.withOpacity(0.3),
                              blurRadius: 24,
                              spreadRadius: 2,
                            )
                          ] : [],
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Icon(Icons.shield_rounded, color: isSelected ? color : _C.textDim, size: 36),
                                if (isSelected) Icon(Icons.check_circle, color: _C.green, size: 24),
                              ],
                            ),
                            const Spacer(),
                            Text(
                              (bug['bug_name'] as String? ?? 'BUG').toUpperCase(),
                              style: TextStyle(
                                color: isSelected ? color : _C.text,
                                fontFamily: 'Orbitron',
                                fontWeight: FontWeight.bold,
                                fontSize: 15,
                                letterSpacing: 1,
                              ),
                            ),
                            const SizedBox(height: 6),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                              decoration: BoxDecoration(
                                color: _C.surface.withOpacity(0.3),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Text(
                                bug['bug_id']?.toString().toLowerCase() ?? 'bug',
                                style: TextStyle(color: _C.textDim, fontFamily: 'ShareTechMono', fontSize: 11),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                );
              },
            ),
          ),

          const SizedBox(height: 10),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: List.generate(widget.listBug.length, (i) {
              final isActive = i == _currentBugPage;
              final color = _C.rainbow[i % _C.rainbow.length];
              return AnimatedContainer(
                duration: const Duration(milliseconds: 250),
                margin: const EdgeInsets.symmetric(horizontal: 3),
                width: isActive ? 24 : 8,
                height: 6,
                decoration: BoxDecoration(
                  color: isActive ? color : _C.border,
                  borderRadius: BorderRadius.circular(3),
                ),
              );
            }),
          ),
        ],
      ),
    );
  }

  // ─── SENDER PANEL ─────────────────────────────────────────────────────────
  Widget _buildSenderPanel() {
    return _glassCard(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.swap_horiz_rounded, color: _C.text, size: 20),
              const SizedBox(width: 8),
              Text(
                'PILIH SENDER',
                style: TextStyle(
                  color: _C.text,
                  fontFamily: 'Orbitron',
                  fontWeight: FontWeight.bold,
                  fontSize: 14,
                  letterSpacing: 1,
                ),
              ),
              const Spacer(),
              GestureDetector(
                onTap: () {
                  _fetchSenderStats();
                  _loadGlobalSenders();
                },
                child: Container(
                  width: 30,
                  height: 30,
                  decoration: BoxDecoration(
                    color: _C.surface.withOpacity(0.5),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: _C.purple.withOpacity(0.2)),
                  ),
                  child: (_isLoadingSenders || _loadingSender)
                      ? Padding(
                          padding: const EdgeInsets.all(7),
                          child: CircularProgressIndicator(
                              strokeWidth: 2, color: _C.purple))
                      : Icon(Icons.refresh_rounded, color: _C.textDim, size: 16),
                ),
              ),
              const SizedBox(width: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: _C.purple.withOpacity(0.3)),
                  color: _C.purple.withOpacity(0.05),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
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
                    Text(
                      _loadingSender
                          ? '-- sender online'
                          : '${_privateSenderCount + _globalSenderCount} sender online',
                      style: TextStyle(
                          color: _C.purple,
                          fontFamily: 'ShareTechMono',
                          fontSize: 11),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),

          Row(
            children: [
              // PRIVATE SENDER
              Expanded(
                child: GestureDetector(
                  onTap: () => setState(() => _selectedSender = 'private'),
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 200),
                    height: 155,
                    decoration: BoxDecoration(
                      gradient: _selectedSender == 'private'
                          ? LinearGradient(
                              colors: [_C.purple, _C.purpleDark],
                              begin: Alignment.topLeft,
                              end: Alignment.bottomRight,
                            )
                          : null,
                      color: _selectedSender == 'private'
                          ? null
                          : _C.surface.withOpacity(0.5),
                      borderRadius: BorderRadius.circular(18),
                      border: Border.all(
                        color: _selectedSender == 'private'
                            ? _C.purple
                            : _C.border,
                        width: _selectedSender == 'private' ? 2 : 1,
                      ),
                      boxShadow: _selectedSender == 'private'
                          ? [
                              BoxShadow(
                                color: _C.purple.withOpacity(0.3),
                                blurRadius: 24,
                                spreadRadius: 3,
                              )
                            ]
                          : [],
                    ),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.person_rounded,
                          color: _selectedSender == 'private'
                              ? _C.white
                              : _C.textDim,
                          size: 38,
                        ),
                        const SizedBox(height: 10),
                        Text(
                          'Pribadi',
                          style: TextStyle(
                            color: _selectedSender == 'private'
                                ? _C.white
                                : _C.textDim,
                            fontFamily: 'Orbitron',
                            fontWeight: FontWeight.bold,
                            fontSize: 15,
                          ),
                        ),
                        const SizedBox(height: 6),
                        _privateSenderCount == 0
                            ? Text(
                                '✕ Kosong',
                                style: TextStyle(
                                  color: _selectedSender == 'private'
                                      ? _C.textSub
                                      : _C.red,
                                  fontFamily: 'ShareTechMono',
                                  fontWeight: FontWeight.bold,
                                  fontSize: 12,
                                ),
                              )
                            : Text(
                                '$_privateSenderCount sender',
                                style: TextStyle(
                                  color: _selectedSender == 'private'
                                      ? _C.textSub
                                      : _C.purpleL,
                                  fontFamily: 'ShareTechMono',
                                  fontSize: 12,
                                ),
                              ),
                      ],
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 12),

              // GLOBAL SENDER
              Expanded(
                child: GestureDetector(
                  onTap: () {
                    if (!canAccessGlobalSender) {
                      _showAlert('❌ Akses Ditolak',
                          'Sender Global hanya untuk Owner ke atas!');
                      return;
                    }
                    setState(() => _selectedSender = 'global');
                    _loadGlobalSenders();
                  },
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 200),
                    height: 155,
                    decoration: BoxDecoration(
                      gradient: _selectedSender == 'global'
                          ? LinearGradient(
                              colors: [_C.purpleL, _C.purple],
                              begin: Alignment.topLeft,
                              end: Alignment.bottomRight,
                            )
                          : null,
                      color: _selectedSender == 'global'
                          ? null
                          : _C.surface.withOpacity(0.5),
                      borderRadius: BorderRadius.circular(18),
                      border: Border.all(
                        color: _selectedSender == 'global'
                            ? _C.purpleL
                            : _C.border,
                        width: _selectedSender == 'global' ? 2 : 1,
                      ),
                      boxShadow: _selectedSender == 'global'
                          ? [
                              BoxShadow(
                                color: _C.purpleL.withOpacity(0.3),
                                blurRadius: 24,
                                spreadRadius: 3,
                              )
                            ]
                          : [],
                    ),
                    child: Stack(
                      children: [
                        Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            const SizedBox(width: double.infinity),
                            Icon(
                              Icons.public_rounded,
                              color: _selectedSender == 'global'
                                  ? _C.white
                                  : _C.textDim,
                              size: 38,
                            ),
                            const SizedBox(height: 10),
                            Text(
                              'Global',
                              style: TextStyle(
                                color: _selectedSender == 'global'
                                    ? _C.white
                                    : _C.textDim,
                                fontFamily: 'Orbitron',
                                fontWeight: FontWeight.bold,
                                fontSize: 15,
                              ),
                            ),
                            const SizedBox(height: 6),
                            _globalSenderCount == 0
                                ? Text(
                                    '✕ Kosong',
                                    style: TextStyle(
                                      color: _selectedSender == 'global'
                                          ? _C.textSub
                                          : _C.red,
                                      fontFamily: 'ShareTechMono',
                                      fontWeight: FontWeight.bold,
                                      fontSize: 12,
                                    ),
                                  )
                                : Text(
                                    '$_globalSenderCount sender',
                                    style: TextStyle(
                                      color: _selectedSender == 'global'
                                          ? _C.textSub
                                          : _C.purpleL,
                                      fontFamily: 'ShareTechMono',
                                      fontSize: 12,
                                    ),
                                  ),
                          ],
                        ),
                        if (!canAccessGlobalSender)
                          Positioned(
                            top: 8,
                            right: 8,
                            child: Container(
                              width: 22,
                              height: 22,
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                color: _C.yellow,
                                border: Border.all(
                                    color: _C.border, width: 1),
                              ),
                              child: const Icon(Icons.lock_rounded,
                                  color: _C.white, size: 12),
                            ),
                          ),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),

          if (_selectedSender == 'global' && _globalSenders.isNotEmpty)
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: _C.surface.withOpacity(0.3),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: _C.purple.withOpacity(0.1)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(children: [
                    Icon(Icons.format_list_bulleted_rounded,
                        color: _C.textDim, size: 13),
                    const SizedBox(width: 6),
                    Text('${_globalSenders.length} sender aktif',
                        style: TextStyle(
                            color: _C.textDim,
                            fontSize: 11,
                            fontFamily: 'ShareTechMono',
                            fontWeight: FontWeight.w600)),
                  ]),
                  const SizedBox(height: 8),
                  ...(_globalSenders.take(3).map((s) => Padding(
                        padding: const EdgeInsets.only(bottom: 4),
                        child: Row(children: [
                          Container(
                              width: 5,
                              height: 5,
                              decoration: BoxDecoration(
                                  shape: BoxShape.circle,
                                  color: _C.purpleL)),
                          const SizedBox(width: 8),
                          Text(s,
                              style: TextStyle(
                                  color: _C.purpleL,
                                  fontSize: 11,
                                  fontFamily: 'ShareTechMono')),
                        ]),
                      ))),
                  if (_globalSenders.length > 3)
                    Text('+ ${_globalSenders.length - 3} lainnya...',
                        style: TextStyle(color: _C.textDim, fontSize: 10)),
                ],
              ),
            )
          else
            Row(
              children: [
                Icon(Icons.info_outline_rounded, color: _C.textDim, size: 13),
                const SizedBox(width: 6),
                Text(
                  'Sisa kirim global hari ini: 8 / 8',
                  style: TextStyle(
                      color: _C.textDim,
                      fontFamily: 'ShareTechMono',
                      fontSize: 11),
                ),
              ],
            ),
        ],
      ),
    );
  }

  // ─── SEND BUTTON ──────────────────────────────────────────────────────────
  Widget _buildSendButton() {
    return AnimatedBuilder(
      animation: _pulseController,
      builder: (context, child) {
        return Container(
          height: 62,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(18),
            gradient: LinearGradient(
              colors: [_C.purple, _C.pink],
              begin: Alignment.centerLeft,
              end: Alignment.centerRight,
            ),
            boxShadow: [
              BoxShadow(
                color: _C.purple
                    .withOpacity(0.3 + _pulseController.value * 0.4),
                blurRadius: 28 + _pulseController.value * 16,
                spreadRadius: 2,
              ),
            ],
          ),
          child: ElevatedButton(
            onPressed: _isSending ? null : _sendBug,
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.transparent,
              shadowColor: Colors.transparent,
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(18)),
              elevation: 0,
            ),
            child: _isSending
                ? const SizedBox(
                    width: 26,
                    height: 26,
                    child: CircularProgressIndicator(
                        color: Colors.white, strokeWidth: 3))
                : Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.rocket_launch_rounded,
                          color: Colors.white, size: 22),
                      const SizedBox(width: 10),
                      ShaderMask(
                        shaderCallback: (rect) => _C.rainbowGrad.createShader(rect),
                        child: const Text(
                          'SEND BUG',
                          style: TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.w900,
                            fontSize: 16,
                            fontFamily: 'Orbitron',
                            letterSpacing: 2,
                          ),
                        ),
                      ),
                    ],
                  ),
          ),
        );
      },
    );
  }

  // ─── RESPONSE BANNER ──────────────────────────────────────────────────────
  Widget _buildResponseMessage() {
    if (_responseMessage == null) return const SizedBox.shrink();

    final parts = _responseMessage!.split('|');
    final type = parts[0];
    final msg = parts.length > 1 ? parts[1] : '';

    Color color;
    IconData icon;
    String title;
    switch (type) {
      case 'success':
        color = _C.green;
        icon = Icons.check_circle_outline;
        title = 'Berhasil';
        break;
      case 'warning':
        color = _C.yellow;
        icon = Icons.warning_rounded;
        title = 'Peringatan';
        break;
      default:
        color = _C.red;
        icon = Icons.error_outline;
        title = 'Gagal';
    }

    return FadeTransition(
      opacity: _resultFade,
      child: SlideTransition(
        position: _resultSlide,
        child: Container(
          margin: const EdgeInsets.only(top: 12),
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          decoration: BoxDecoration(
            color: color.withOpacity(0.1),
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: color.withOpacity(0.3)),
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 32,
                height: 32,
                decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: color.withOpacity(0.12)),
                child: Icon(icon, color: color, size: 18),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(title,
                        style: TextStyle(
                            color: color,
                            fontFamily: 'Orbitron',
                            fontSize: 13,
                            fontWeight: FontWeight.bold)),
                    const SizedBox(height: 3),
                    Text(msg,
                        style: TextStyle(
                            color: _C.textSub,
                            fontFamily: 'ShareTechMono',
                            fontSize: 12,
                            height: 1.4)),
                  ],
                ),
              ),
              GestureDetector(
                onTap: () {
                  setState(() => _responseMessage = null);
                  _resultCtrl.reset();
                },
                child: Icon(Icons.close_rounded, color: _C.textDim, size: 16),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ─── BUILD ────────────────────────────────────────────────────────────────
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          // Video Background
          SizedBox(
            width: double.infinity,
            height: double.infinity,
            child: _videoController.value.isInitialized
                ? VideoPlayer(_videoController)
                : Container(color: Colors.black),
          ),

          // Rainbow overlay
          _buildRainbowOverlay(),

          // Gradient overlay
          Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  Colors.black.withOpacity(0.4),
                  _C.surface.withOpacity(0.7),
                  Colors.black.withOpacity(0.9),
                ],
              ),
            ),
          ),

          // Glow orbs
          ...List.generate(4, (i) {
            final angle = (i / 4) * 2 * math.pi;
            return AnimatedBuilder(
              animation: _rotateCtrl,
              builder: (_, __) {
                final x = math.cos(_rotateCtrl.value * 0.3 + angle) * 120;
                final y = math.sin(_rotateCtrl.value * 0.5 + angle) * 80;
                final color = _C.rainbow[(i * 2) % _C.rainbow.length];
                final size = 100 + 40 * math.sin(_rotateCtrl.value + i).abs();
                return Positioned(
                  left: MediaQuery.of(context).size.width / 2 + x - size / 2,
                  top: MediaQuery.of(context).size.height / 2 + y - size / 2,
                  child: Container(
                    width: size,
                    height: size,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      gradient: RadialGradient(
                        colors: [color.withOpacity(0.03), Colors.transparent],
                        radius: 0.7,
                      ),
                    ),
                  ),
                );
              },
            );
          }),

          // Main Content
          SafeArea(
            child: Column(
              children: [
                _buildTopAppBar(),
                Container(
                  height: 1,
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [
                        Colors.transparent,
                        _C.rainbow[DateTime.now().second % _C.rainbow.length]
                            .withOpacity(0.3),
                        Colors.transparent,
                      ],
                    ),
                  ),
                ),
                Expanded(
                  child: SingleChildScrollView(
                    physics: const BouncingScrollPhysics(),
                    padding: const EdgeInsets.symmetric(
                        horizontal: 14, vertical: 14),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        _buildHeader(),
                        const SizedBox(height: 14),
                        _buildNomorAndBugPanel(),
                        const SizedBox(height: 14),
                        _buildSenderPanel(),
                        const SizedBox(height: 20),
                        _buildSendButton(),
                        _buildResponseMessage(),
                        const SizedBox(height: 24),
                      ],
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
}