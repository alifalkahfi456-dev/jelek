import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:video_player/video_player.dart';
import 'package:http/http.dart' as http;

class BugPage extends StatefulWidget {
  final String username;
  final String password;
  final String role;
  final String expiredDate;
  final String sessionKey;
  final List<Map<String, dynamic>> listBug;
  final List<Map<String, dynamic>> listDoos;

  const BugPage({
    super.key,
    required this.username,
    required this.password,
    required this.role,
    required this.expiredDate,
    required this.sessionKey,
    required this.listBug,
    required this.listDoos,
  });

  @override
  State<BugPage> createState() => _BugPageState();
}

class _BugPageState extends State<BugPage> {
  late VideoPlayerController _vc;

  // ===== LOGIC STATE =====
  final TextEditingController targetController = TextEditingController();
  bool _isSending = false;
  String selectedBugId = "";

 // --- Tema Hitam – Abu (tanpa ubah nama const) ---
final Color primaryDark   = const Color(0xFF050505); // background utama
final Color primaryBlue   = const Color(0xFF1A1A1A); // abu sangat gelap
final Color accentBlue    = const Color(0xFF2E2E2E); // abu gelap (border / accent)
final Color lightBlue     = const Color(0xFF6F6F6F); // abu terang (icon / highlight)
final Color cardDark      = const Color(0xFF121212); // card
final Color cardDarker    = const Color(0xFF0B0B0B); // card lebih dalam

// Status colors → tetap nama, jadi abu
final Color successGreen  = const Color(0xFF8A8A8A); // success → abu netral
final Color warningOrange = const Color(0xFF5C5C5C); // warning → abu sedang
final Color dangerRed     = const Color(0xFF3A3A3A); // danger → abu gelap
  
  @override
  void initState() {
    super.initState();
    _vc = VideoPlayerController.asset('assets/videos/bg.mp4')
      ..initialize().then((_) {
        _vc
          ..setLooping(true)
          ..setVolume(0)
          ..play();
        setState(() {});
      });

    if (widget.listBug.isNotEmpty) {
  selectedBugId = widget.listBug.first['bug_id']?.toString() ?? '';
}
  }

  @override
  void dispose() {
    _vc.dispose();
    targetController.dispose();
    super.dispose();
  }

  // ===== FORMAT & SEND =====
  String? formatPhoneNumber(String input) {
    final cleaned = input.replaceAll(RegExp(r'[^\d+]'), '');
    if (!cleaned.startsWith('+') || cleaned.length < 8) return null;
    return cleaned;
  }

  Future<bool> _sendBug() async {
  final rawInput = targetController.text.trim();
  final target = formatPhoneNumber(rawInput);
  final key = widget.sessionKey;

  if (target == null || key.isEmpty || selectedBugId.isEmpty) {
    _showNotification(
      "Invalid Number",
      "Gunakan nomor internasional (contoh +62xxxx)",
      dangerRed,
    );
    return false;
  }

  try {
    final res = await http.get(Uri.parse(
      "http://kaiieclipse.privateserverr.web.id:3000/sendBug"
      "?key=$key&target=$target&bug=$selectedBugId",
    ));

    final data = jsonDecode(res.body);

    if (data["cooldown"] == true) {
      _showNotification("Cooldown", "Tunggu beberapa saat.", dangerRed);
      return false;
    }

    if (data["valid"] == false) {
      _showNotification("Invalid Key", "Silakan login ulang.", dangerRed);
      return false;
    }

    if (data["sended"] == false) {
      _showNotification("Gagal", "Server maintenance.", dangerRed);
      return false;
    }

    _showNotification(
      "Success",
      "Bug berhasil dikirim ke $target",
      successGreen,
    );
    targetController.clear();
    return true;
  } catch (_) {
    _showNotification("Error", "Terjadi kesalahan.", dangerRed);
    return false;
  }
}

  void _showNotification(String title, String msg, Color color) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        behavior: SnackBarBehavior.floating,
        margin: const EdgeInsets.all(16),
        content: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: cardDarker,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: color.withOpacity(0.5)),
          ),
          child: Text(msg, style: const TextStyle(color: Colors.white)),
        ),
      ),
    );
  }

  // ===== BUILD =====
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          if (_vc.value.isInitialized)
            SizedBox.expand(
              child: FittedBox(
                fit: BoxFit.cover,
                child: SizedBox(
                  width: _vc.value.size.width,
                  height: _vc.value.size.height,
                  child: VideoPlayer(_vc),
                ),
              ),
            ),
          Container(color: Colors.black.withOpacity(0.55)),
          SafeArea(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Column(
                children: [
                  _userCard(),
                  const SizedBox(height: 14),
                  _inputCard(
                    icon: Icons.call,
                    title: 'Target Number',
                    hint: 'e.g. +62xxxxxxxxx',
                  ),
                  const SizedBox(height: 14),
                  _dropdownCard(),
                  const SizedBox(height: 18),
                  _quickIcons(),
                  const SizedBox(height: 18),
                  _sendButton(),
                  const SizedBox(height: 12),
                  const Text(
                    'Use responsibly. We are not responsible for misuse.',
                    style: TextStyle(fontSize: 11, color: Colors.white54),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ===== UI =====
  Widget _glass({required Widget child}) => Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white.withOpacity(0.12),
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: Colors.white24),
        ),
        child: child,
      );

  Widget _buildModernDropdown({
  required String label,
  required String value,
  required List<Map<String, dynamic>> items,
  required Function(String?) onChanged,
}) {
  final bool hasValue =
      items.any((e) => e['bug_id']?.toString() == value);

  return Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      // ===== TITLE =====
      Row(
        children: const [
          Icon(Icons.bug_report, color: Colors.white70, size: 18),
          SizedBox(width: 8),
          Text(
            "Bug Type",
            style: TextStyle(
              color: Colors.white,
              fontSize: 15,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
      const SizedBox(height: 10),

      // ===== TRANSPARENT DROPDOWN (NO BLUR) =====
      ClipRRect(
        borderRadius: BorderRadius.circular(20),
        child: Container(
          height: 56,
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.12), // 🔥 OPACITY ONLY
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
              color: Colors.white.withOpacity(0.25),
            ),
          ),
          child: DropdownButtonHideUnderline(
            child: DropdownButton<String>(
              value: hasValue ? value : null,
              isExpanded: true,
              dropdownColor: const Color(0xFF2A2A2A),
              icon: const Padding(
                padding: EdgeInsets.only(right: 16),
                child: Icon(
                  Icons.keyboard_arrow_down_rounded,
                  color: Colors.white70,
                  size: 26,
                ),
              ),
              hint: Row(
                children: const [
                  SizedBox(width: 16),
                  Icon(Icons.settings, color: Colors.white60, size: 18),
                  SizedBox(width: 10),
                  Text(
                    "Select Bug",
                    style: TextStyle(
                      color: Colors.white60,
                      fontSize: 14,
                    ),
                  ),
                ],
              ),
              items: items.map((bug) {
                final id = bug['bug_id']?.toString() ?? '';
                final name = bug['bug_name']?.toString() ?? 'Bug';

                return DropdownMenuItem<String>(
                  value: id,
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    child: Row(
                      children: [
                        const Icon(
                          Icons.settings,
                          color: Colors.white70,
                          size: 18,
                        ),
                        const SizedBox(width: 10),
                        Text(
                          name,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 14,
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              }).toList(),
              onChanged: onChanged,
            ),
          ),
        ),
      ),
    ],
  );
}

  Widget _userCard() => _glass(
        child: Row(
          children: [
            const CircleAvatar(
              backgroundColor: Colors.white24,
              child: Icon(Icons.admin_panel_settings),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(widget.username),
                  Text(
                    widget.role.toUpperCase(),
                    style:
                        const TextStyle(fontSize: 11, color: Colors.white60),
                  ),
                ],
              ),
            ),
            Container(
              padding:
                  const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
              decoration: BoxDecoration(
                color: Colors.white12,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Text(
                'EXP: ${widget.expiredDate}',
                style: const TextStyle(fontSize: 11),
              ),
            ),
          ],
        ),
      );

  Widget _inputCard({
    required IconData icon,
    required String title,
    required String hint,
  }) =>
      _glass(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(icon, size: 18),
                const SizedBox(width: 8),
                Text(title),
              ],
            ),
            const SizedBox(height: 10),
            TextField(
              controller: targetController,
              decoration: InputDecoration(
                hintText: hint,
                hintStyle: const TextStyle(color: Colors.white38),
                border: InputBorder.none,
              ),
            ),
          ],
        ),
      );

  Widget _dropdownCard() => _buildModernDropdown(
      label: "Choose Bugs",
      value: selectedBugId,
      items: widget.listBug,
      onChanged: (value) {
        setState(() {
          selectedBugId = value ?? '';
        });
      },
    );

  Widget _quickIcons() => Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: const [
          _QI(Icons.dns, 'Server'),
          _QI(Icons.security, 'Security'),
          _QI(Icons.storage, 'Database'),
        ],
      );

  // ===== SEND BUTTON =====
  Widget _sendButton() => GestureDetector(
  onTap: _isSending
      ? null
      : () async {
          setState(() => _isSending = true);

          // ===== SEND BUG =====
          final success = await _sendBug();
          if (!mounted) return;

          if (!success) {
            setState(() => _isSending = false);
            return;
          }

          // ===== VIDEO LOADING NOTIF =====
          final vc = VideoPlayerController.asset(
            'assets/videos/loading.mp4',
          );
          await vc.initialize();
          vc.setVolume(0);
          vc.play();

          bool finished = false;

          await showDialog(
  context: context,
  barrierDismissible: false,
  builder: (_) {
    return StatefulBuilder(
      builder: (context, setDialogState) {
        vc.addListener(() {
          if (!finished &&
              vc.value.position >= vc.value.duration) {
            finished = true;
            setDialogState(() {});
          }
        });

        return Center(
          child: Material(
            color: Colors.transparent,
            child: Container(
              width: 280,
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: const Color(0xFF0E0E0E),
                borderRadius: BorderRadius.circular(18),
                border: Border.all(
                  color: Colors.white.withOpacity(0.35),
                ),
              ),
              child: finished
                  // ===== SUCCESS (TENGAH) =====
                  ? Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(
                          Icons.check_circle,
                          color: Colors.greenAccent,
                          size: 40,
                        ),
                        const SizedBox(height: 8),
                        const Text(
                          'WhatsApp Bug Sent',
                          style: TextStyle(
                            fontFamily: 'Orbitron',
                          ),
                        ),
                        const SizedBox(height: 4),
                        const Text(
                          'Successfully sent to target',
                          style: TextStyle(
                            color: Colors.white70,
                            fontSize: 12,
                          ),
                          textAlign: TextAlign.center,
                        ),
                        const SizedBox(height: 10),
                        GestureDetector(
                          onTap: () => Navigator.pop(context),
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 24,
                              vertical: 8,
                            ),
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(
                                color: Colors.white.withOpacity(0.35),
                              ),
                            ),
                            child: const Text(
                              'DONE',
                              style: TextStyle(
                                fontFamily: 'Orbitron',
                                fontSize: 12,
                              ),
                            ),
                          ),
                        ),
                      ],
                    )
                  // ===== LOADING VIDEO (TENGAH) =====
                  : ClipRRect(
                      borderRadius: BorderRadius.circular(14),
                      child: AspectRatio(
                        aspectRatio: vc.value.aspectRatio,
                        child: VideoPlayer(vc),
                      ),
                    ),
            ),
          ),
        );
      },
    );
  },
);

          vc.dispose();
          if (!mounted) return;
          setState(() => _isSending = false);
        },
  child: Container(
    width: double.infinity,
    height: 52,
    decoration: BoxDecoration(
      borderRadius: BorderRadius.circular(16),
      border: Border.all(color: Colors.white24),
    ),
    child: Center(
      child: _isSending
          ? const CircularProgressIndicator(strokeWidth: 2)
          : const Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.send),
                SizedBox(width: 8),
                Text(
                  'SEND',
                  style: TextStyle(
                    fontFamily: 'Orbitron',
                    letterSpacing: 1.5,
                  ),
                ),
              ],
            ),
    ),
  ),
 );
}

class _QI extends StatelessWidget {
  final IconData i;
  final String t;
  const _QI(this.i, this.t);

  @override
  Widget build(BuildContext context) => Column(
        children: [
          Container(
            width: 46,
            height: 46,
            decoration: BoxDecoration(
              color: Colors.white12,
              borderRadius: BorderRadius.circular(14),
            ),
            child: Icon(i),
          ),
          const SizedBox(height: 6),
          Text(t, style: const TextStyle(fontSize: 11)),
        ],
      );
}