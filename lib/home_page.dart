import 'dart:convert';
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:http/http.dart' as http;
import 'package:video_player/video_player.dart';

class HomePage extends StatefulWidget {
  final bool isGroup;
  final String username;
  final String password;
  final String role;
  final String expiredDate;
  final String sessionKey;
  final List<Map<String, dynamic>> listBug;

  const HomePage({
    super.key,
    required this.isGroup,
    required this.username,
    required this.password,
    required this.role,
    required this.expiredDate,
    required this.sessionKey,
    required this.listBug,
  });

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> with TickerProviderStateMixin {
  late VideoPlayerController _videoController;
  final targetController = TextEditingController();

  late AnimationController _slideController;
  late AnimationController _pulseController;
  late AnimationController _progressController;

  late Animation<Offset> _slideAnimation;
  late Animation<double> _progressAnimation;

  String selectedBugId      = "";
  bool   _isSending         = false;
  bool   _isVideoInitialized = false;

  int    _currentStep = 0;
  double _progress    = 0.0;

  // ── Blue palette ────────────────────────────────────
  static const Color bgDark     = Color(0xFF03080f);
  static const Color deepBlue   = Color(0xFF060d18);
  static const Color cardBlue   = Color(0xFF091525);
  static const Color cardDark   = Color(0xFF0c1420);
  static const Color mainBlue   = Color(0xFF1565c0);
  static const Color accentCyan = Color(0xFF00b0ff);

  final List<String> _progressSteps = const [
    "Initializing...",
    "Connecting to server...",
    "Validating session...",
    "Preparing payload...",
    "Sending bug...",
    "Success!",
  ];

  @override
  void initState() {
    super.initState();

    _videoController =
        VideoPlayerController.asset("assets/videos/landing.mp4")
          ..initialize().then((_) {
            if (mounted) setState(() => _isVideoInitialized = true);
            _videoController
              ..setLooping(true)
              ..setVolume(0)
              ..play();
          });

    _slideController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 700),
    )..forward();

    _slideAnimation = Tween<Offset>(
      begin: const Offset(0, 0.25),
      end: Offset.zero,
    ).animate(CurvedAnimation(
      parent: _slideController,
      curve: Curves.easeOutCubic,
    ));

    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1400),
    )..repeat(reverse: true);

    _progressController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 700),
    );
    _progressAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _progressController, curve: Curves.easeInOut),
    );

    if (widget.listBug.isNotEmpty) {
      selectedBugId = widget.listBug[0]['bug_id'] as String;
    }
  }

  @override
  void dispose() {
    _videoController.dispose();
    _slideController.dispose();
    _pulseController.dispose();
    _progressController.dispose();
    targetController.dispose();
    super.dispose();
  }

  Future<void> _updateProgress(int step) async {
    if (!mounted) return;
    setState(() {
      _currentStep = step;
      _progress    = (step + 1) / _progressSteps.length;
    });
    _progressController
      ..reset()
      ..forward();
    await Future.delayed(const Duration(milliseconds: 550));
  }

  Future<void> _sendBugNomor() async {
    final target = targetController.text.trim();
    if (target.isEmpty) {
      _showPopup("Error", "Nomor target tidak boleh kosong!", isError: true);
      return;
    }
    setState(() { _isSending = true; _currentStep = 0; _progress = 0.0; });
    try {
      for (int i = 0; i < 4; i++) await _updateProgress(i);
      final url =
          "http://saitama.omdhancivok.my.id:2001/sendBug"
          "?key=${widget.sessionKey}&target=$target&bug=$selectedBugId";
      await _updateProgress(4);
      final res  = await http.get(Uri.parse(url));
      final data = jsonDecode(res.body) as Map<String, dynamic>;
      bool   ok  = false;
      String msg = "";
      if (data["cooldown"] == true) {
        msg = "Cooldown: Tunggu ${data['wait']} detik.";
      } else if (data["valid"] == false) {
        msg = "Sesi Invalid.";
      } else if (data["sended"] == false) {
        msg = "Gagal: Server Maintenance.";
      } else {
        ok  = true;
        msg = "Bug berhasil dikirim!";
        await _updateProgress(5);
      }
      await Future.delayed(const Duration(milliseconds: 400));
      if (ok) { _showPopup("Success", msg); targetController.clear(); }
      else    { _showPopup("Failed",  msg, isError: true); }
    } catch (_) {
      _showPopup("Connection Error", "Gagal menghubungi server.", isError: true);
    } finally {
      if (mounted) {
        setState(() { _isSending = false; _currentStep = 0; _progress = 0.0; });
      }
    }
  }

  void _showPopup(String title, String message, {bool isError = false}) {
    showDialog(
      context: context,
      builder: (_) => BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 14, sigmaY: 14),
        child: AlertDialog(
          backgroundColor: cardBlue,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
            side: BorderSide(
              color: isError ? Colors.redAccent : accentCyan,
              width: 1.5,
            ),
          ),
          title: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: (isError ? Colors.redAccent : accentCyan)
                      .withOpacity(0.15),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  isError ? Icons.error_outline : Icons.check_circle_outline,
                  color: isError ? Colors.redAccent : accentCyan,
                  size: 22,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  title,
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),
          content: Text(
            message,
            style: const TextStyle(color: Colors.white70, fontSize: 14),
          ),
          actions: [
            Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: isError
                      ? [Colors.redAccent, Colors.red]
                      : [mainBlue, accentCyan],
                ),
                borderRadius: BorderRadius.circular(10),
              ),
              child: TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text(
                  "OK",
                  style: TextStyle(
                      color: Colors.white, fontWeight: FontWeight.bold),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ════════════════════════════════════════════════════
  //  BUILD
  // ════════════════════════════════════════════════════
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: bgDark,
      body: Stack(
        children: [
          // Gradient background
          Container(
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                colors: [bgDark, deepBlue],
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
              ),
            ),
          ),

          // Dot grid overlay
          Opacity(
            opacity: 0.045,
            child: CustomPaint(
              painter: _DotGridPainter(),
              size: Size.infinite,
            ),
          ),

          SafeArea(
            child: SlideTransition(
              position: _slideAnimation,
              child: SingleChildScrollView(
                padding:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildProfileCard(),
                    const SizedBox(height: 16),

                    _buildVideoBanner(),
                    const SizedBox(height: 20),

                    _buildTargetSection(),
                    const SizedBox(height: 20),

                    _buildSectionLabel(),
                    const SizedBox(height: 12),

                    _buildBugCards(),
                    const SizedBox(height: 24),

                    if (_isSending) ...[
                      _buildProgressBar(),
                      const SizedBox(height: 20),
                    ],

                    _buildSendButton(),
                    const SizedBox(height: 30),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ════════════════════════════════════════════════════
  //  PROFILE CARD
  // ════════════════════════════════════════════════════
  Widget _buildProfileCard() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      decoration: BoxDecoration(
        color: cardDark,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: accentCyan.withOpacity(0.16), width: 1),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.4),
            blurRadius: 14,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        children: [
          // Avatar with glowing cyan ring
          Container(
            width: 64,
            height: 64,
            padding: const EdgeInsets.all(2.5),
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: const LinearGradient(
                colors: [accentCyan, mainBlue],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              boxShadow: [
                BoxShadow(
                  color: accentCyan.withOpacity(0.38),
                  blurRadius: 14,
                  spreadRadius: 1,
                ),
              ],
            ),
            child: ClipOval(
              child: Image.asset(
                'assets/images/icon.jpg',
                fit: BoxFit.cover,
                errorBuilder: (_, __, ___) => Container(
                  color: deepBlue,
                  child: const Icon(
                    Icons.person_rounded,
                    color: accentCyan,
                    size: 32,
                  ),
                ),
              ),
            ),
          ),
          const SizedBox(width: 14),

          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  widget.username,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 0.2,
                  ),
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    // Role pill — grey outline like reference
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 12, vertical: 4),
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.07),
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(
                          color: Colors.white.withOpacity(0.16),
                          width: 1,
                        ),
                      ),
                      child: Text(
                        widget.role.toUpperCase(),
                        style: const TextStyle(
                          color: Colors.white60,
                          fontSize: 10,
                          fontWeight: FontWeight.bold,
                          letterSpacing: 1.5,
                        ),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Text(
                      "Exp: ${widget.expiredDate}",
                      style: TextStyle(
                        color: Colors.grey.shade500,
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ════════════════════════════════════════════════════
  //  VIDEO BANNER
  // ════════════════════════════════════════════════════
  Widget _buildVideoBanner() {
    return ClipRRect(
      borderRadius: BorderRadius.circular(20),
      child: SizedBox(
        width: double.infinity,
        height: 210,
        child: Stack(
          fit: StackFit.expand,
          children: [
            if (_isVideoInitialized)
              FittedBox(
                fit: BoxFit.cover,
                child: SizedBox(
                  width: _videoController.value.size.width,
                  height: _videoController.value.size.height,
                  child: VideoPlayer(_videoController),
                ),
              )
            else
              Container(
                color: cardDark,
                child: const Center(
                  child: CircularProgressIndicator(
                      color: accentCyan, strokeWidth: 2),
                ),
              ),

            // Vignette
            Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    Colors.black.withOpacity(0.1),
                    Colors.transparent,
                    Colors.black.withOpacity(0.5),
                  ],
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                ),
              ),
            ),

            // Cyan border frame
            Container(
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(20),
                border: Border.all(
                  color: accentCyan.withOpacity(0.22),
                  width: 1.2,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ════════════════════════════════════════════════════
  //  TARGET NUMBER SECTION
  // ════════════════════════════════════════════════════
  Widget _buildTargetSection() {
    return Container(
      decoration: BoxDecoration(
        color: cardDark,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: Colors.white.withOpacity(0.07), width: 1),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.45),
            blurRadius: 14,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ── Header ───────────────────────────────
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 14, 16, 10),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(7),
                  decoration: BoxDecoration(
                    color: accentCyan.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(
                        color: accentCyan.withOpacity(0.3), width: 1),
                  ),
                  child: const Icon(Icons.gps_fixed_rounded,
                      color: accentCyan, size: 16),
                ),
                const SizedBox(width: 10),
                const Text(
                  'TARGET NUMBER',
                  style: TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                    fontSize: 13,
                    letterSpacing: 1.2,
                  ),
                ),
                const Spacer(),
                Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.05),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(
                        color: Colors.white.withOpacity(0.1), width: 1),
                  ),
                  child: const Text(
                    'INTERNATIONAL',
                    style: TextStyle(
                      color: Colors.white54,
                      fontSize: 9,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 1,
                    ),
                  ),
                ),
              ],
            ),
          ),

          // ── Input field ──────────────────────────
          Padding(
            padding: const EdgeInsets.fromLTRB(14, 0, 14, 6),
            child: Container(
              height: 52,
              decoration: BoxDecoration(
                color: deepBlue,
                borderRadius: BorderRadius.circular(14),
                border: Border.all(
                    color: accentCyan.withOpacity(0.18), width: 1),
              ),
              child: TextField(
                controller: targetController,
                style: const TextStyle(
                    color: Colors.white,
                    fontSize: 15,
                    fontWeight: FontWeight.w500),
                cursorColor: accentCyan,
                keyboardType: TextInputType.phone,
                decoration: InputDecoration(
                  hintText: '628123456789',
                  hintStyle: TextStyle(
                      color: Colors.grey.shade600, fontSize: 15),
                  border: InputBorder.none,
                  contentPadding: const EdgeInsets.symmetric(
                      horizontal: 16, vertical: 16),
                  prefixIcon: Padding(
                    padding: const EdgeInsets.only(left: 14, right: 10),
                    child: Icon(Icons.phone_android_rounded,
                        color: accentCyan.withOpacity(0.7), size: 20),
                  ),
                  prefixIconConstraints:
                      const BoxConstraints(minWidth: 0, minHeight: 0),
                  suffixIcon: IconButton(
                    icon: Icon(Icons.clear_rounded,
                        color: Colors.grey.shade700, size: 18),
                    onPressed: () => targetController.clear(),
                  ),
                ),
              ),
            ),
          ),

          // ── Format hint ──────────────────────────
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 2, 16, 14),
            child: Row(
              children: [
                Icon(Icons.info_outline_rounded,
                    color: Colors.grey.shade600, size: 12),
                const SizedBox(width: 5),
                Text(
                  'Format: Country code + number (without + or 0)',
                  style: TextStyle(
                      color: Colors.grey.shade600, fontSize: 11),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ════════════════════════════════════════════════════
  //  SECTION LABEL  "PILIH BUG"
  // ════════════════════════════════════════════════════
  Widget _buildSectionLabel() {
    return Row(
      children: [
        Container(
          width: 3.5,
          height: 18,
          decoration: BoxDecoration(
            color: accentCyan,
            borderRadius: BorderRadius.circular(2),
            boxShadow: [
              BoxShadow(
                color: accentCyan.withOpacity(0.55),
                blurRadius: 8,
              ),
            ],
          ),
        ),
        const SizedBox(width: 10),
        const Text(
          "PILIH BUG",
          style: TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.bold,
            fontSize: 13,
            letterSpacing: 2.5,
          ),
        ),
      ],
    );
  }

  // ════════════════════════════════════════════════════
  //  SELECT PAYLOAD  (card container — sesuai foto)
  // ════════════════════════════════════════════════════
  Widget _buildBugCards() {
    return Container(
      decoration: BoxDecoration(
        color: cardDark,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: Colors.white.withOpacity(0.07), width: 1),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.45),
            blurRadius: 14,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ── Header row ──────────────────────────
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 14, 14, 10),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(7),
                  decoration: BoxDecoration(
                    color: accentCyan.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(
                        color: accentCyan.withOpacity(0.25), width: 1),
                  ),
                  child: const Icon(Icons.grid_view_rounded,
                      color: accentCyan, size: 16),
                ),
                const SizedBox(width: 10),
                const Text(
                  'SELECT PAYLOAD',
                  style: TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                    fontSize: 13,
                    letterSpacing: 1.2,
                  ),
                ),
                const Spacer(),
                // Badge jumlah selected
                Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: selectedBugId.isNotEmpty
                        ? const Color(0xFF16a34a)
                        : Colors.white.withOpacity(0.06),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    selectedBugId.isNotEmpty ? '1 SELECTED' : '0 SELECTED',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 10,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 0.8,
                    ),
                  ),
                ),
              ],
            ),
          ),

          // ── Horizontal card list ─────────────────
          if (widget.listBug.isEmpty)
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 4, 16, 16),
              child: Container(
                height: 120,
                decoration: BoxDecoration(
                  color: deepBlue,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: accentCyan.withOpacity(0.12)),
                ),
                child: Center(
                  child: Text(
                    'No payload available',
                    style: TextStyle(color: Colors.grey.shade600),
                  ),
                ),
              ),
            )
          else
            SizedBox(
              height: 148,
              child: ListView.separated(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.fromLTRB(14, 0, 14, 4),
                itemCount: widget.listBug.length,
                separatorBuilder: (_, __) => const SizedBox(width: 10),
                itemBuilder: (context, index) {
                  final bug        = widget.listBug[index];
                  final bugId      = bug['bug_id'] as String;
                  final bugName    = bug['bug_name'] as String;
                  final isSelected = selectedBugId == bugId;

                  return GestureDetector(
                    onTap: () {
                      HapticFeedback.selectionClick();
                      setState(() => selectedBugId = bugId);
                    },
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 200),
                      width: 118,
                      decoration: BoxDecoration(
                        color: isSelected
                            ? const Color(0xFF0f2a4a)
                            : const Color(0xFF0a1525),
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(
                          color: isSelected
                              ? accentCyan.withOpacity(0.6)
                              : Colors.white.withOpacity(0.07),
                          width: isSelected ? 1.5 : 1,
                        ),
                        boxShadow: isSelected
                            ? [
                                BoxShadow(
                                  color: accentCyan.withOpacity(0.2),
                                  blurRadius: 14,
                                  spreadRadius: 1,
                                ),
                              ]
                            : [
                                BoxShadow(
                                  color: Colors.black.withOpacity(0.4),
                                  blurRadius: 6,
                                  offset: const Offset(0, 2),
                                ),
                              ],
                      ),
                      child: Stack(
                        children: [
                          // ── Card content ──────────
                          Padding(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 10, vertical: 12),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                // Bug icon circle
                                Container(
                                  width: 44,
                                  height: 44,
                                  decoration: BoxDecoration(
                                    color: isSelected
                                        ? accentCyan.withOpacity(0.12)
                                        : Colors.white.withOpacity(0.05),
                                    shape: BoxShape.circle,
                                    border: Border.all(
                                      color: isSelected
                                          ? accentCyan.withOpacity(0.4)
                                          : Colors.white.withOpacity(0.08),
                                      width: 1,
                                    ),
                                  ),
                                  child: Icon(
                                    Icons.bug_report_rounded,
                                    color: isSelected
                                        ? accentCyan
                                        : Colors.grey.shade500,
                                    size: 22,
                                  ),
                                ),
                                const SizedBox(height: 10),

                                // Bug name
                                Text(
                                  bugName,
                                  maxLines: 2,
                                  overflow: TextOverflow.ellipsis,
                                  style: TextStyle(
                                    color: isSelected
                                        ? Colors.white
                                        : Colors.grey.shade400,
                                    fontSize: 12,
                                    fontWeight: FontWeight.w700,
                                    height: 1.3,
                                  ),
                                ),
                                const SizedBox(height: 5),

                                // Sub-label "Payload"
                                Text(
                                  'Payload',
                                  style: TextStyle(
                                    color: isSelected
                                        ? accentCyan.withOpacity(0.7)
                                        : Colors.grey.shade600,
                                    fontSize: 10,
                                  ),
                                ),
                              ],
                            ),
                          ),

                          // ── Checkmark badge (selected) ──
                          if (isSelected)
                            Positioned(
                              top: 8,
                              right: 8,
                              child: Container(
                                width: 20,
                                height: 20,
                                decoration: const BoxDecoration(
                                  color: Color(0xFF16a34a),
                                  shape: BoxShape.circle,
                                ),
                                child: const Icon(
                                  Icons.check_rounded,
                                  color: Colors.white,
                                  size: 13,
                                ),
                              ),
                            ),
                        ],
                      ),
                    ),
                  );
                },
              ),
            ),

          // ── Footer: count + Clear ────────────────
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 6, 16, 14),
            child: Row(
              children: [
                Icon(Icons.check_circle_outline_rounded,
                    color: selectedBugId.isNotEmpty
                        ? const Color(0xFF16a34a)
                        : Colors.grey.shade700,
                    size: 14),
                const SizedBox(width: 6),
                Text(
                  selectedBugId.isNotEmpty
                      ? '1 payload selected'
                      : 'No payload selected',
                  style: TextStyle(
                    color: selectedBugId.isNotEmpty
                        ? const Color(0xFF16a34a)
                        : Colors.grey.shade600,
                    fontSize: 11,
                  ),
                ),
                const Spacer(),
                GestureDetector(
                  onTap: () => setState(() => selectedBugId = ''),
                  child: Text(
                    'Clear',
                    style: TextStyle(
                      color: accentCyan.withOpacity(0.8),
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
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

  // ════════════════════════════════════════════════════
  //  PROGRESS BAR
  // ════════════════════════════════════════════════════
  Widget _buildProgressBar() {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: cardDark,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: accentCyan.withOpacity(0.18), width: 1),
        boxShadow: [
          BoxShadow(
            color: accentCyan.withOpacity(0.06),
            blurRadius: 14,
            spreadRadius: 1,
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Step circles
          Row(
            children: List.generate(_progressSteps.length, (i) {
              final done    = i < _currentStep;
              final current = i == _currentStep;
              final active  = i <= _currentStep;
              return Expanded(
                child: Row(
                  children: [
                    Expanded(
                      child: Center(
                        child: AnimatedContainer(
                          duration: const Duration(milliseconds: 250),
                          width: 30,
                          height: 30,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            gradient: active
                                ? const LinearGradient(
                                    colors: [mainBlue, accentCyan])
                                : null,
                            color: active ? null : deepBlue,
                            border: Border.all(
                              color: current
                                  ? accentCyan
                                  : accentCyan.withOpacity(0.14),
                              width: current ? 1.8 : 1,
                            ),
                            boxShadow: current
                                ? [
                                    BoxShadow(
                                      color: accentCyan.withOpacity(0.4),
                                      blurRadius: 10,
                                      spreadRadius: 1,
                                    )
                                  ]
                                : null,
                          ),
                          child: Center(
                            child: done
                                ? const Icon(Icons.check_rounded,
                                    color: Colors.white, size: 14)
                                : Text(
                                    '${i + 1}',
                                    style: TextStyle(
                                      color: active
                                          ? Colors.white
                                          : Colors.grey,
                                      fontWeight: FontWeight.bold,
                                      fontSize: 12,
                                    ),
                                  ),
                          ),
                        ),
                      ),
                    ),
                    if (i < _progressSteps.length - 1)
                      Expanded(
                        child: Container(
                          height: 2,
                          decoration: BoxDecoration(
                            gradient: done
                                ? const LinearGradient(
                                    colors: [mainBlue, accentCyan])
                                : null,
                            color: done ? null : const Color(0xFF0e1822),
                            borderRadius: BorderRadius.circular(2),
                          ),
                        ),
                      ),
                  ],
                ),
              );
            }),
          ),

          const SizedBox(height: 16),

          AnimatedBuilder(
            animation: _progressAnimation,
            builder: (_, __) {
              return Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Stack(
                    children: [
                      Container(
                        height: 6,
                        decoration: BoxDecoration(
                          color: const Color(0xFF0e1822),
                          borderRadius: BorderRadius.circular(6),
                        ),
                      ),
                      FractionallySizedBox(
                        widthFactor:
                            _progress * _progressAnimation.value,
                        child: Container(
                          height: 6,
                          decoration: BoxDecoration(
                            gradient: const LinearGradient(
                                colors: [mainBlue, accentCyan]),
                            borderRadius: BorderRadius.circular(6),
                            boxShadow: [
                              BoxShadow(
                                color: accentCyan.withOpacity(0.5),
                                blurRadius: 6,
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        _progressSteps[_currentStep],
                        style: const TextStyle(
                          color: accentCyan,
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      Text(
                        "${(_progress * 100).toInt()}%",
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ],
              );
            },
          ),
        ],
      ),
    );
  }

  // ════════════════════════════════════════════════════
  //  SEND BUTTON  — premium style
  // ════════════════════════════════════════════════════
  Widget _buildSendButton() {
    return AnimatedBuilder(
      animation: _pulseController,
      builder: (_, child) => Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(18),
          boxShadow: _isSending
              ? []
              : [
                  BoxShadow(
                    color: accentCyan
                        .withOpacity(0.28 * _pulseController.value),
                    blurRadius: 28 * _pulseController.value,
                    spreadRadius: 2,
                  ),
                  BoxShadow(
                    color: mainBlue.withOpacity(0.35),
                    blurRadius: 16,
                    offset: const Offset(0, 6),
                  ),
                ],
        ),
        child: child,
      ),
      child: GestureDetector(
        onTap: _isSending ? null : _sendBugNomor,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          width: double.infinity,
          height: 62,
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: _isSending
                  ? [const Color(0xFF1a2030), const Color(0xFF1a2030)]
                  : [
                      const Color(0xFF1565c0),
                      const Color(0xFF0d47a1),
                      const Color(0xFF006db3),
                    ],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(18),
            border: Border.all(
              color: _isSending
                  ? Colors.white.withOpacity(0.05)
                  : accentCyan.withOpacity(0.4),
              width: 1.2,
            ),
          ),
          child: Stack(
            alignment: Alignment.center,
            children: [
              // ── Shimmer line top ──────────────────
              if (!_isSending)
                Positioned(
                  top: 0,
                  left: 30,
                  right: 30,
                  child: Container(
                    height: 1,
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [
                          Colors.transparent,
                          Colors.white.withOpacity(0.35),
                          Colors.transparent,
                        ],
                      ),
                    ),
                  ),
                ),

              // ── Content ───────────────────────────
              _isSending
                  ? Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(
                            color: accentCyan,
                            strokeWidth: 2.5,
                          ),
                        ),
                        const SizedBox(width: 14),
                        Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'SENDING BUG...',
                              style: TextStyle(
                                color: Colors.white70,
                                fontWeight: FontWeight.bold,
                                fontSize: 14,
                                letterSpacing: 1.5,
                              ),
                            ),
                            Text(
                              _progressSteps[_currentStep],
                              style: TextStyle(
                                color: accentCyan.withOpacity(0.8),
                                fontSize: 11,
                              ),
                            ),
                          ],
                        ),
                      ],
                    )
                  : Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        // Left icon
                        Container(
                          width: 36,
                          height: 36,
                          decoration: BoxDecoration(
                            color: Colors.white.withOpacity(0.12),
                            shape: BoxShape.circle,
                            border: Border.all(
                                color: Colors.white.withOpacity(0.2),
                                width: 1),
                          ),
                          child: const Icon(
                            Icons.bug_report_rounded,
                            color: Colors.white,
                            size: 18,
                          ),
                        ),
                        const SizedBox(width: 14),
                        Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'SEND BUG',
                              style: TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.w900,
                                fontSize: 16,
                                letterSpacing: 2,
                              ),
                            ),
                            Text(
                              'Tap to send payload to target',
                              style: TextStyle(
                                color: Colors.white.withOpacity(0.55),
                                fontSize: 10,
                                letterSpacing: 0.3,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(width: 14),
                        // Right arrow
                        Container(
                          width: 32,
                          height: 32,
                          decoration: BoxDecoration(
                            color: Colors.white.withOpacity(0.1),
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(
                            Icons.arrow_forward_rounded,
                            color: Colors.white,
                            size: 16,
                          ),
                        ),
                      ],
                    ),
            ],
          ),
        ),
      ),
    );
  }
}

// ════════════════════════════════════════════════════
//  DOT GRID BACKGROUND PAINTER
// ════════════════════════════════════════════════════
class _DotGridPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = const Color(0xFF00b0ff)
      ..style = PaintingStyle.fill;
    const spacing = 28.0;
    for (double x = 0; x < size.width; x += spacing) {
      for (double y = 0; y < size.height; y += spacing) {
        canvas.drawCircle(Offset(x, y), 0.9, paint);
      }
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
