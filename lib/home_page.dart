import 'app_config.dart';
import 'dart:async';
import 'package:video_player/video_player.dart';
import 'dart:convert';
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;

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
  final targetController = TextEditingController();
  final linkController   = TextEditingController();

  late AnimationController _slideController;
  late AnimationController _pulseController;
  late AnimationController _progressController;
  late Animation<Offset>   _slideAnimation;
  late Animation<double>   _progressAnimation;

  String selectedBugId = '';
  String _senderType   = 'private';

  // Video banner
  VideoPlayerController? _videoCtrl;
  bool _videoReady = false;

  // Private sender count (tidak hilang)
  int _privateSenderCount = 0;
  Timer? _senderRefreshTimer;
  bool   _isSending    = false;
  bool   _isNomorMode  = true;

  int    _currentStep  = 0;
  double _progress     = 0.0;
  List<String> _progressSteps = [];

  List<dynamic> _globalSenders = [];
  bool _loadingGlobal = false;
  bool _isOwner = false;

  // Bug list difilter sesuai mode WA (is_group=false) vs Grup (is_group=true)
  List<Map<String, dynamic>> get _filteredBugs {
    return widget.listBug.where((b) {
      final ig = b['is_group'];
      if (ig == null) return true;
      return _isNomorMode ? ig == false : ig == true;
    }).toList();
  }

  // ── Tema Merah ────────────────────────────────────────────────────────────
  static const _bg        = Color(0xFF000000);
  static const _card      = Color(0xFF020A18);
  static const _red       = Color(0xFF0D47A1);
  static const _redL      = Color(0xFF4FC3F7);
  static const _border    = Color(0xFF550000);
  static const _textSub   = Color(0xFF888888);

  @override
  void initState() {
    super.initState();
    _isNomorMode = !widget.isGroup;

    _slideController = AnimationController(vsync: this, duration: const Duration(milliseconds: 800))..forward();
    _slideAnimation  = Tween<Offset>(begin: const Offset(0, 0.3), end: Offset.zero)
        .animate(CurvedAnimation(parent: _slideController, curve: Curves.easeOutCubic));

    _pulseController = AnimationController(vsync: this, duration: const Duration(milliseconds: 1500))
      ..repeat(reverse: true);

    _progressController = AnimationController(vsync: this, duration: const Duration(milliseconds: 800));
    _progressAnimation  = Tween<double>(begin: 0.0, end: 1.0)
        .animate(CurvedAnimation(parent: _progressController, curve: Curves.easeInOut));

    _isOwner = widget.role.toLowerCase() == 'owner';

    if (widget.listBug.isNotEmpty) selectedBugId = widget.listBug[0]['bug_id'];

    _progressSteps = [
      'Initializing...', 'Connecting to server...', 'Validating session...',
      'Preparing payload...', 'Sending bug...', 'Success!'
    ];

    _fetchGlobalSenders();
  }

  Future<void> _fetchGlobalSenders() async {
    setState(() => _loadingGlobal = true);
    try {
      final res = await http.get(
        Uri.parse('$kBaseUrl/getPublicSenders?key=${widget.sessionKey}'),
      ).timeout(const Duration(seconds: 10));
      final d = jsonDecode(res.body);
      if (d['valid'] == true) {
        setState(() {
          _globalSenders = List<dynamic>.from(d['senders'] ?? []);
          // server juga kirim isOwner, tapi fallback ke role local
          _isOwner = (d['isOwner'] == true) || widget.role.toLowerCase() == 'owner';
        });
      }
    } catch (_) {}
    setState(() => _loadingGlobal = false);
  }

  @override
  void dispose() {
    _slideController.dispose();
    _pulseController.dispose();
    _progressController.dispose();
    targetController.dispose();
    linkController.dispose();
    _videoCtrl?.dispose();
    _senderRefreshTimer?.cancel();
    super.dispose();
  }

  Future<void> _fetchPrivateSenderCount() async {
    try {
      final res = await http.get(
        Uri.parse('$kBaseUrl/mySender?key=${widget.sessionKey}'),
      ).timeout(const Duration(seconds: 8));
      final d = jsonDecode(res.body);
      if (mounted) {
        final senders = d['senders'] as List? ?? d['data'] as List? ?? [];
        setState(() => _privateSenderCount = senders.length);
      }
    } catch (_) {}
  }


  Future<void> _updateProgress(int step) async {
    setState(() { _currentStep = step; _progress = (step + 1) / _progressSteps.length; });
    _progressController.reset();
    _progressController.forward();
    await Future.delayed(const Duration(milliseconds: 600));
  }

  // ── SEND BUG NOMOR ────────────────────────────────────────────────────────
  Future<void> _sendBugNomor() async {
    final target = targetController.text.trim();
    if (target.isEmpty) { _showPopup('Error', 'Nomor target tidak boleh kosong!', isError: true); return; }

    setState(() { _isSending = true; _currentStep = 0; _progress = 0.0; });
    try {
      await _updateProgress(0); await _updateProgress(1);
      await _updateProgress(2); await _updateProgress(3);
      final url = '$kBaseUrl/sendBug?key=${widget.sessionKey}&target=$target&bug=$selectedBugId&senderType=$_senderType';
      await _updateProgress(4);
      final res  = await http.get(Uri.parse(url));
      final data = jsonDecode(res.body);
      bool isSuccess = false;
      String msg = '';
      if (data['cooldown'] == true) {
        msg = 'Cooldown: Tunggu ${data["wait"]} detik.';
      } else if (data['valid'] == false) {
        msg = 'Sesi Invalid.';
      } else if (data['sended'] == false) {
        msg = 'Gagal: Server Maintenance.';
      } else {
        isSuccess = true; msg = 'Bug berhasil dikirim!';
        await _updateProgress(5);
      }
      await Future.delayed(const Duration(milliseconds: 500));
      if (isSuccess) { _showPopup('Success', msg); targetController.clear(); }
      else _showPopup('Failed', msg, isError: true);
    } catch (_) {
      _showPopup('Connection Error', 'Gagal menghubungi server.', isError: true);
    } finally {
      setState(() { _isSending = false; _currentStep = 0; _progress = 0.0; });
    }
  }

  // ── SEND BUG GROUP (pakai crashGroup1 via /raidGroup) ────────────────────
  Future<void> _sendBugGroup() async {
    final link = linkController.text.trim();
    if (link.isEmpty) { _showPopup('Error', 'Link group tidak boleh kosong!', isError: true); return; }
    if (!link.contains('chat.whatsapp.com')) { _showPopup('Invalid Link', 'Link Group tidak valid!', isError: true); return; }

    setState(() { _isSending = true; _currentStep = 0; _progress = 0.0; });
    try {
      await _updateProgress(0); await _updateProgress(1);
      await _updateProgress(2); await _updateProgress(3);
      final encodedLink = Uri.encodeComponent(link);
      final url = '$kBaseUrl/raidGroup?key=${widget.sessionKey}&link=$encodedLink&bug=$selectedBugId&senderType=$_senderType';
      await _updateProgress(4);
      final res  = await http.get(Uri.parse(url));
      final data = jsonDecode(res.body);
      bool isSuccess = false;
      String msg = '';
      if (data['valid'] == false) {
        msg = data['message'] ?? 'Session Invalid.';
      } else if (data['cooldown'] == true) {
        msg = 'Cooldown: Tunggu ${data["wait"]} detik.';
      } else if (data['sended'] == true) {
        isSuccess = true; msg = 'Bug berhasil dikirim ke Group!';
        await _updateProgress(5);
      } else {
        msg = data['message'] ?? 'Gagal mengirim bug.';
      }
      await Future.delayed(const Duration(milliseconds: 500));
      if (isSuccess) { _showPopup('Success', msg); linkController.clear(); }
      else _showPopup('Failed', msg, isError: true);
    } catch (_) {
      _showPopup('Connection Error', 'Gagal menghubungi server.', isError: true);
    } finally {
      setState(() { _isSending = false; _currentStep = 0; _progress = 0.0; });
    }
  }

  // ── BAN NOMOR WA ─────────────────────────────────────────────────────────
  Future<void> _banNomor() async {
    final target = targetController.text.trim();
    if (target.isEmpty) { _showPopup('Error', 'Masukkan nomor target', isError: true); return; }

    setState(() { _isSending = true; _currentStep = 0; _progress = 0.0; });
    try {
      await _updateProgress(0);
      final url = '$kBaseUrl/banNumber?key=${widget.sessionKey}&target=$target';
      await _updateProgress(1);
      final res = await http.get(Uri.parse(url)).timeout(const Duration(seconds: 30));
      await _updateProgress(2);
      final body = jsonDecode(res.body);
      final isSuccess = body['status'] == true || body['valid'] == true || (body['message'] != null && body['message'].toString().contains('berhasil'));
      final msg = body['message'] ?? (isSuccess ? 'Nomor berhasil di-ban' : 'Gagal ban nomor');
      if (isSuccess) { _showPopup('Ban Berhasil', msg); targetController.clear(); }
      else _showPopup('Ban Gagal', msg, isError: true);
    } catch (_) {
      _showPopup('Error', 'Gagal menghubungi server', isError: true);
    } finally {
      setState(() { _isSending = false; _currentStep = 0; _progress = 0.0; });
    }
  }

  // ── BOBOL WIFI ────────────────────────────────────────────────────────────
  List<Map<String, dynamic>> _wifiResults = [];
  bool _wifiLoading = false;

  Future<void> _scanWifi() async {
    setState(() { _wifiLoading = true; _wifiResults = []; });
    try {
      final res = await http.get(
        Uri.parse('$kBaseUrl/scanWifi?key=${widget.sessionKey}'),
      ).timeout(const Duration(seconds: 20));
      if (res.statusCode == 200) {
        final data = jsonDecode(res.body);
        if (data['valid'] == true && data['networks'] != null) {
          setState(() {
            _wifiResults = List<Map<String, dynamic>>.from(data['networks']);
          });
        } else {
          _showPopup('Gagal', data['message'] ?? 'Tidak ada hasil', isError: true);
        }
      }
    } catch (_) {
      _showPopup('Error', 'Gagal menghubungi server', isError: true);
    } finally {
      setState(() => _wifiLoading = false);
    }
  }

  Widget _buildWifiBobolButton() {
    return Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
      GestureDetector(
        onTap: _wifiLoading ? null : _scanWifi,
        child: Container(
          height: 52,
          decoration: BoxDecoration(
            gradient: LinearGradient(colors: [Color(0xFF004D8C), Color(0xFF001F3F)]),
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: Color(0x440080FF)),
          ),
          child: Row(mainAxisAlignment: MainAxisAlignment.center, children: [
            _wifiLoading
                ? SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                : Icon(Icons.wifi_password_rounded, color: Colors.white, size: 18),
            SizedBox(width: 10),
            Text(
              _wifiLoading ? 'SCANNING WIFI...' : 'BOBOL WIFI TERDEKAT',
              style: TextStyle(color: Colors.white, fontWeight: FontWeight.w900, fontSize: 12, fontFamily: 'Orbitron', letterSpacing: 1),
            ),
          ]),
        ),
      ),
      if (_wifiResults.isNotEmpty) ...[
        SizedBox(height: 10),
        Container(
          decoration: BoxDecoration(
            color: Color(0xFF020818),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: Color(0xFF051525)),
          ),
          child: Column(children: _wifiResults.map((wifi) {
            final ssid = wifi['ssid'] ?? 'Unknown';
            final pass = wifi['password'] ?? 'Tidak ditemukan';
            final signal = wifi['signal'] ?? '-';
            return Container(
              padding: EdgeInsets.symmetric(horizontal: 14, vertical: 10),
              decoration: BoxDecoration(
                border: Border(bottom: BorderSide(color: Color(0xFF040F22))),
              ),
              child: Row(children: [
                Icon(Icons.wifi_rounded, color: Color(0xFF0080FF), size: 18),
                SizedBox(width: 10),
                Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Text(ssid, style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 13)),
                  Text('Password: $pass', style: TextStyle(color: Color(0xFF00FF88), fontSize: 12, fontFamily: 'Orbitron')),
                  Text('Signal: $signal dBm', style: TextStyle(color: Color(0xFF555555), fontSize: 10)),
                ])),
                GestureDetector(
                  onTap: () {
                    // Copy password
                  },
                  child: Icon(Icons.copy_rounded, color: Color(0xFF555555), size: 16),
                ),
              ]),
            );
          }).toList()),
        ),
      ],
    ]);
  }

  void _showPopup(String title, String message, {bool isError = false}) {
    showDialog(
      context: context,
      builder: (_) => BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
        child: AlertDialog(
          backgroundColor: _card.withOpacity(0.97),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
            side: BorderSide(color: isError ? Colors.redAccent : _red, width: 1.5),
          ),
          title: Row(children: [
            Icon(isError ? Icons.error_outline : Icons.check_circle_outline,
                color: isError ? Colors.redAccent : Colors.greenAccent),
            const SizedBox(width: 10),
            Text(title, style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
          ]),
          content: Text(message, style: TextStyle(color: Colors.white70)),
          actions: [TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('OK', style: TextStyle(color: _redL)),
          )],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _bg,
      body: Stack(children: [
        // Background merah gelap
        Container(
          decoration: BoxDecoration(
            gradient: RadialGradient(
              center: Alignment(0, -0.5),
              radius: 1.4,
              colors: [Color(0xFF041845), _bg],
            ),
          ),
        ),

        SafeArea(
          child: SingleChildScrollView(
            padding: EdgeInsets.zero,
            child: SlideTransition(
              position: _slideAnimation,
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [

                // ── GAMBAR/VIDEO BANNER FULLWIDTH DI PALING ATAS ─────────
                _buildHeroBanner(),

                // ── BUG NOMOR & BUG GROUP — besar seperti screenshot ─────
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 0, 16, 0),
                  child: _buildModeButtons()),
                const SizedBox(height: 16),

                Padding(padding: const EdgeInsets.symmetric(horizontal: 16), child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start, children: [

                // Profile card
                _buildProfileCard(),
                const SizedBox(height: 14),

                // Sender count
                _buildSenderCount(),
                const SizedBox(height: 20),

                // Input field
                if (_isNomorMode) ...[
                  _buildSectionTitle(Icons.phone_android, 'TARGET NUMBER'),
                  const SizedBox(height: 10),
                  _buildTextField(controller: targetController, hint: '628xxxxxxxx', prefixIcon: Icons.phone),
                  const SizedBox(height: 25),
                ] else ...[
                  _buildSectionTitle(Icons.link, 'LINK GROUP WA'),
                  const SizedBox(height: 10),
                  _buildTextField(controller: linkController, hint: 'https://chat.whatsapp.com/...', prefixIcon: Icons.link),
                  const SizedBox(height: 25),
                ],

                // Send button
                _buildSendButton(
                  onPressed: _isNomorMode ? _sendBugNomor : _sendBugGroup,
                  label: _isNomorMode ? 'KIRIM BUG' : 'KIRIM BUG GROUP',
                ),
                const SizedBox(height: 30),
              ])), // close Column + Padding
              ]),
            ),
          ),
        ),
      ]),
    );
  }


  // ── HERO BANNER — gambar/video fullwidth di atas ─────────────────────────
  Widget _buildHeroBanner() {
    return Stack(children: [
      // Gambar atau video
      ClipRRect(
        borderRadius: const BorderRadius.only(
          bottomLeft: Radius.circular(0), bottomRight: Radius.circular(0)),
        child: SizedBox(
          width: double.infinity,
          height: 220,
          child: _videoReady && _videoCtrl != null
            ? AspectRatio(
                aspectRatio: _videoCtrl!.value.aspectRatio,
                child: VideoPlayer(_videoCtrl!))
            : Image.asset(
                'assets/images/back.jpg',
                fit: BoxFit.cover,
                errorBuilder: (_, __, ___) => Container(
                  color: const Color(0xFF020A18),
                  child: const Center(
                    child: Icon(Icons.image_rounded, color: Colors.white12, size: 48))),
              ))),

      // Gradient overlay bawah
      Positioned.fill(
        child: DecoratedBox(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [Colors.transparent, const Color(0xFF000000)],
              stops: const [0.4, 1.0])))),

      // Sender count di pojok kiri atas
      Positioned(top: 12, left: 12,
        child: GestureDetector(
          onTap: _fetchPrivateSenderCount,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
            decoration: BoxDecoration(
              color: Colors.black.withOpacity(0.7),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: Color(0x801565C0))),
            child: Row(mainAxisSize: MainAxisSize.min, children: [
              const Icon(Icons.wifi_tethering_rounded, color: Color(0xFF1565C0), size: 12),
              const SizedBox(width: 6),
              Text('$_privateSenderCount SENDER',
                style: TextStyle(
                  color: Color(0xFF1565C0), fontSize: 10,
                  fontWeight: FontWeight.w900, fontFamily: 'Orbitron', letterSpacing: 1)),
            ])))),
    ]);
  }

  // ── BAN WA & BOBOL WIFI — row 2 tombol jelas ─────────────────────────────
  Widget _buildBanWifiRow() {
    return Row(children: [
      // BAN WA
      Expanded(child: GestureDetector(
        onTap: _isSending ? null : _banNomor,
        child: Container(
          height: 52,
          decoration: BoxDecoration(
            color: const Color(0xFF110000),
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: const Color(0xFF0D47A1), width: 1.5),
            boxShadow: [BoxShadow(color: Color(0x330D47A1), blurRadius: 10)]),
          child: Row(mainAxisAlignment: MainAxisAlignment.center, children: [
            const Icon(Icons.block_rounded, color: Color(0xFF4FC3F7), size: 18),
            const SizedBox(width: 8),
            const Text('BAN WA',
              style: TextStyle(
                color: Color(0xFF4FC3F7), fontWeight: FontWeight.w900,
                fontSize: 12, fontFamily: 'Orbitron', letterSpacing: 1)),
          ])))),
      const SizedBox(width: 10),
      // BOBOL WIFI
      Expanded(child: GestureDetector(
        onTap: _wifiLoading ? null : _scanWifi,
        child: Container(
          height: 52,
          decoration: BoxDecoration(
            color: const Color(0xFF001122),
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: const Color(0xFF0055AA), width: 1.5),
            boxShadow: [BoxShadow(color: Color(0x330055AA), blurRadius: 10)]),
          child: Row(mainAxisAlignment: MainAxisAlignment.center, children: [
            _wifiLoading
              ? const SizedBox(width: 16, height: 16,
                  child: CircularProgressIndicator(strokeWidth: 2, color: Color(0xFF0088FF)))
              : const Icon(Icons.wifi_password_rounded, color: Color(0xFF0088FF), size: 18),
            const SizedBox(width: 8),
            Text(_wifiLoading ? 'SCANNING...' : 'BOBOL WIFI',
              style: TextStyle(
                color: Color(0xFF0088FF), fontWeight: FontWeight.w900,
                fontSize: 12, fontFamily: 'Orbitron', letterSpacing: 0.8)),
          ])))),
    ]);
  }

  // ── WIFI RESULTS ──────────────────────────────────────────────────────────
  Widget _buildWifiResults() {
    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFF020814),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFF001A33))),
      child: Column(
        children: _wifiResults.map((wifi) {
          final ssid = wifi['ssid'] ?? 'Unknown';
          final pass = wifi['password'] ?? '-';
          return Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
            decoration: BoxDecoration(
              border: Border(bottom: BorderSide(color: Color(0xFF0D0D1A)))),
            child: Row(children: [
              const Icon(Icons.wifi_rounded, color: Color(0xFF0080FF), size: 16),
              const SizedBox(width: 10),
              Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text(ssid, style: TextStyle(
                  color: Colors.white, fontWeight: FontWeight.bold, fontSize: 12)),
                Text(pass, style: TextStyle(
                  color: Color(0xFF00FF88), fontSize: 11, fontFamily: 'Orbitron')),
              ])),
              GestureDetector(
                onTap: () {
                  // copy password
                },
                child: const Icon(Icons.copy_rounded, color: Color(0xFF444444), size: 14)),
            ]));
        }).toList()));
  }

  // ── SENDER COUNT card ─────────────────────────────────────────────────────
  Widget _buildSenderCount() {
    return GestureDetector(
      onTap: _fetchPrivateSenderCount,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        decoration: BoxDecoration(
          color: const Color(0xFF020A18),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Color(0x401565C0))),
        child: Row(children: [
          Container(
            width: 40, height: 40,
            decoration: BoxDecoration(
              color: Color(0x1F1565C0),
              borderRadius: BorderRadius.circular(10)),
            child: const Icon(Icons.wifi_tethering_rounded,
              color: Color(0xFF1565C0), size: 20)),
          const SizedBox(width: 12),
          Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            const Text('PRIVATE SENDER', style: TextStyle(
              color: Color(0xFF888888), fontSize: 9,
              fontFamily: 'ShareTechMono', letterSpacing: 2)),
            const SizedBox(height: 3),
            Text('$_privateSenderCount sender aktif',
              style: TextStyle(
                color: Color(0xFF1565C0), fontSize: 14,
                fontWeight: FontWeight.w900, fontFamily: 'Orbitron')),
          ])),
          const Icon(Icons.refresh_rounded, color: Color(0xFF333333), size: 16),
        ])));
  }

  Widget _buildModeButtons() {
    return Column(children: [
      // 2 tombol besar merah seperti screenshot
      Row(children: [
        // BUG NOMOR
        Expanded(child: GestureDetector(
          onTap: () => setState(() {
            _isNomorMode = true;
            final wabugs = widget.listBug.where((b) => b['is_group'] == false || b['is_group'] == null).toList();
            if (wabugs.isNotEmpty) selectedBugId = wabugs[0]['bug_id'];
          }),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 220),
            height: 64,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: _isNomorMode
                  ? [const Color(0xFF0D47A1), const Color(0xFF880000)]
                  : [const Color(0xFF000D1A), const Color(0xFF110000)],
                begin: Alignment.topLeft, end: Alignment.bottomRight),
              borderRadius: BorderRadius.circular(18),
              border: Border.all(
                color: _isNomorMode ? const Color(0xFFFF2222) : const Color(0xFF550000),
                width: _isNomorMode ? 1.5 : 1),
              boxShadow: _isNomorMode
                ? [BoxShadow(color: Color(0x8C0D47A1),
                    blurRadius: 20, spreadRadius: 1, offset: const Offset(0, 4))]
                : []),
            child: Row(mainAxisAlignment: MainAxisAlignment.center, children: [
              Icon(Icons.phone_rounded,
                color: _isNomorMode ? Colors.white : const Color(0xFF993333), size: 22),
              const SizedBox(width: 10),
              Text('BUG NOMOR', style: TextStyle(
                color: _isNomorMode ? Colors.white : const Color(0xFF993333),
                fontWeight: FontWeight.w900, fontSize: 13,
                fontFamily: 'Orbitron', letterSpacing: 1.5)),
            ])))),
        const SizedBox(width: 12),
        // BUG GROUP
        Expanded(child: GestureDetector(
          onTap: () => setState(() {
            _isNomorMode = false;
            final grpbugs = widget.listBug.where((b) => b['is_group'] == true).toList();
            if (grpbugs.isNotEmpty) selectedBugId = grpbugs[0]['bug_id'];
          }),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 220),
            height: 64,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: !_isNomorMode
                  ? [const Color(0xFF0D47A1), const Color(0xFF880000)]
                  : [const Color(0xFF000D1A), const Color(0xFF110000)],
                begin: Alignment.topLeft, end: Alignment.bottomRight),
              borderRadius: BorderRadius.circular(18),
              border: Border.all(
                color: !_isNomorMode ? const Color(0xFFFF2222) : const Color(0xFF550000),
                width: !_isNomorMode ? 1.5 : 1),
              boxShadow: !_isNomorMode
                ? [BoxShadow(color: Color(0x8C0D47A1),
                    blurRadius: 20, spreadRadius: 1, offset: const Offset(0, 4))]
                : []),
            child: Row(mainAxisAlignment: MainAxisAlignment.center, children: [
              Icon(Icons.groups_rounded,
                color: !_isNomorMode ? Colors.white : const Color(0xFF993333), size: 22),
              const SizedBox(width: 10),
              Text('BUG GROUP', style: TextStyle(
                color: !_isNomorMode ? Colors.white : const Color(0xFF993333),
                fontWeight: FontWeight.w900, fontSize: 13,
                fontFamily: 'Orbitron', letterSpacing: 1.5)),
            ])))),
      ]),
    ]);
  }

  Widget _buildProfileCard() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(colors: [_card.withOpacity(0.8), _bg.withOpacity(0.6)]),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: _border),
        boxShadow: [BoxShadow(color: _red.withOpacity(0.15), blurRadius: 15)],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(20),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
          child: Row(children: [
            Container(
              padding: const EdgeInsets.all(3),
              decoration: BoxDecoration(shape: BoxShape.circle, border: Border.all(color: _redL, width: 2)),
              child: const CircleAvatar(radius: 32, backgroundImage: AssetImage('assets/images/icon.jpg')),
            ),
            const SizedBox(width: 15),
            Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text(widget.username, style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 20)),
              const SizedBox(height: 8),
              Row(children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(colors: [_red.withOpacity(0.6), Color(0x99880000)]),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Text('Role: ${widget.role.toUpperCase()}',
                      style: TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.bold)),
                ),
                const SizedBox(width: 8),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: _bg.withOpacity(0.6),
                    borderRadius: BorderRadius.circular(6),
                    border: Border.all(color: _textSub.withOpacity(0.3)),
                  ),
                  child: Text('Exp: ${widget.expiredDate}',
                      style: TextStyle(color: _textSub, fontSize: 10, fontWeight: FontWeight.bold)),
                ),
              ]),
            ])),
          ]),
        ),
      ),
    );
  }

  Widget _buildSectionTitle(IconData icon, String title) {
    return Row(children: [
      Icon(icon, color: _redL, size: 20),
      const SizedBox(width: 10),
      Text(title, style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 14, letterSpacing: 1)),
    ]);
  }

  Widget _buildTextField({required TextEditingController controller, required String hint, IconData? prefixIcon}) {
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(colors: [_card.withOpacity(0.6), _bg.withOpacity(0.4)]),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: _border),
      ),
      child: TextField(
        controller: controller,
        style: TextStyle(color: Colors.white),
        cursorColor: _redL,
        decoration: InputDecoration(
          hintText: hint,
          hintStyle: TextStyle(color: Colors.grey.shade600, fontSize: 13),
          border: InputBorder.none,
          contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          prefixIcon: prefixIcon != null ? Icon(prefixIcon, color: _redL, size: 20) : null,
          suffixIcon: IconButton(icon: const Icon(Icons.clear, color: Colors.white54, size: 20), onPressed: controller.clear),
        ),
      ),
    );
  }

  Widget _buildDropdown() {
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      // Sender type card
      Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(color: _card, borderRadius: BorderRadius.circular(14), border: Border.all(color: Colors.white12)),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Row(children: [
            Container(padding: const EdgeInsets.all(8), decoration: BoxDecoration(color: Colors.white10, borderRadius: BorderRadius.circular(8)),
                child: const Icon(Icons.dns_rounded, color: Colors.white, size: 18)),
            const SizedBox(width: 10),
            const Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text('Sender Type', style: TextStyle(color: Colors.white, fontSize: 13, fontWeight: FontWeight.bold)),
              Text('Pilih sumber nomor pengirim', style: TextStyle(color: Colors.white38, fontSize: 10)),
            ]),
          ]),
          const SizedBox(height: 14),
          Row(children: [
            Expanded(child: _senderTypeCard('Global', 'public', Icons.language_rounded, 'Public Sender', Colors.green)),
            const SizedBox(width: 10),
            Expanded(child: _senderTypeCard('Private', 'private', Icons.person_rounded, 'Session pribadi', Colors.white60)),
          ]),
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
            decoration: BoxDecoration(color: _bg, borderRadius: BorderRadius.circular(10)),
            child: Row(children: [
              Container(width: 8, height: 8, decoration: BoxDecoration(color: Colors.green, shape: BoxShape.circle)),
              const SizedBox(width: 8),
              Text(_senderType == 'public' ? 'Public sender aktif' : 'Private sender aktif',
                  style: TextStyle(color: Colors.white70, fontSize: 11, fontWeight: FontWeight.w600)),
            ]),
          ),
        ]),
      ),
      const SizedBox(height: 14),
      // Global sender list
      Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(color: _card, borderRadius: BorderRadius.circular(14), border: Border.all(color: Colors.green.withOpacity(0.25))),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Row(children: [
            Container(padding: const EdgeInsets.all(7), decoration: BoxDecoration(color: Colors.green.withOpacity(0.15), borderRadius: BorderRadius.circular(8)),
                child: const Icon(Icons.language_rounded, color: Colors.green, size: 16)),
            const SizedBox(width: 10),
            Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              const Text('Global Sender', style: TextStyle(color: Colors.white, fontSize: 13, fontWeight: FontWeight.bold)),
              const Text('Sender aktif tersedia', style: TextStyle(color: Colors.white38, fontSize: 10)),
            ])),
            GestureDetector(
              onTap: _fetchGlobalSenders,
              child: Container(padding: const EdgeInsets.all(6), decoration: BoxDecoration(color: Colors.white10, borderRadius: BorderRadius.circular(8)),
                child: _loadingGlobal
                    ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.green))
                    : const Icon(Icons.refresh_rounded, color: Colors.white60, size: 16)),
            ),
            const SizedBox(width: 8),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(color: Colors.green.withOpacity(0.15), borderRadius: BorderRadius.circular(8)),
              child: Text('${_globalSenders.length}', style: TextStyle(color: Colors.green, fontSize: 11, fontWeight: FontWeight.bold))),
          ]),
          const SizedBox(height: 12),
          if (_globalSenders.isEmpty)
            const Padding(padding: EdgeInsets.symmetric(vertical: 14),
                child: Center(child: Text('Belum ada global sender aktif', style: TextStyle(color: Colors.white24, fontSize: 11))))
          else if (!_isOwner)
            // Member / Reseller: hanya tampilkan jumlah, nomor disembunyikan
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
              decoration: BoxDecoration(color: Colors.green.withOpacity(0.06), borderRadius: BorderRadius.circular(10), border: Border.all(color: Colors.green.withOpacity(0.2))),
              child: Row(children: [
                const Icon(Icons.lock_rounded, color: Colors.green, size: 14),
                const SizedBox(width: 8),
                Text('${_globalSenders.length} global sender aktif dan siap pakai',
                    style: TextStyle(color: Colors.green, fontSize: 12, fontWeight: FontWeight.w600)),
              ]),
            )
          else
            // Owner: tampilkan semua nomor lengkap
            Wrap(
              spacing: 8, runSpacing: 8,
              children: List.generate(_globalSenders.length, (i) {
                final s = _globalSenders[i];
                final isConn = (s['status']?.toString() ?? 'connected') == 'connected';
                final nomor  = s['number']?.toString() ?? s['sessionName']?.toString() ?? 'Unknown';
                return Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  decoration: BoxDecoration(color: const Color(0xFF1A0008), borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: isConn ? Colors.green.withOpacity(0.3) : Colors.white12)),
                  child: Row(mainAxisSize: MainAxisSize.min, children: [
                    Container(width: 7, height: 7, decoration: BoxDecoration(color: isConn ? Colors.green : Colors.red, shape: BoxShape.circle)),
                    const SizedBox(width: 6),
                    Text(nomor, style: TextStyle(color: Colors.white70, fontSize: 11, fontWeight: FontWeight.w600)),
                  ]),
                );
              }),
            ),
        ]),
      ),
      const SizedBox(height: 14),
      Wrap(
        spacing: 8, runSpacing: 8,
        children: _filteredBugs.map((bug) {
          final isSel = selectedBugId == bug['bug_id'];
          return GestureDetector(
            onTap: () => setState(() => selectedBugId = bug['bug_id']!),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
              decoration: BoxDecoration(
                color: isSel ? _red.withOpacity(0.15) : Colors.transparent,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: isSel ? _redL : Colors.white.withOpacity(0.15), width: isSel ? 1.5 : 1),
              ),
              child: Text(bug['bug_name']?.toString() ?? '',
                  style: TextStyle(color: isSel ? _redL : Colors.white70, fontSize: 12, fontWeight: isSel ? FontWeight.bold : FontWeight.normal)),
            ),
          );
        }).toList(),
      ),
    ]);
  }

  Widget _buildProgressIndicator() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(colors: [_card.withOpacity(0.8), _bg.withOpacity(0.6)]),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: _border),
        boxShadow: [BoxShadow(color: _red.withOpacity(0.2), blurRadius: 15)],
      ),
      child: Column(children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: List.generate(_progressSteps.length, (index) {
            final isActive  = index <= _currentStep;
            final isCurrent = index == _currentStep;
            return Expanded(child: Column(children: [
              Container(
                width: 40, height: 40,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: isActive ? LinearGradient(colors: [Color(0xFF0D47A1), Color(0xFF880000)]) : null,
                  color: isActive ? null : _card.withOpacity(0.5),
                  border: Border.all(color: isCurrent ? _redL : _border, width: isCurrent ? 2 : 1),
                  boxShadow: isCurrent ? [BoxShadow(color: _redL.withOpacity(0.5), blurRadius: 10, spreadRadius: 2)] : null,
                ),
                child: Center(child: isActive && index < _currentStep
                    ? const Icon(Icons.check, color: Colors.white, size: 20)
                    : Text('${index + 1}', style: TextStyle(color: isActive ? Colors.white : Colors.grey, fontWeight: FontWeight.bold, fontSize: 16))),
              ),
              if (index < _progressSteps.length - 1)
                Container(margin: const EdgeInsets.only(top: 5), height: 2, color: isActive ? _red : _card),
            ]));
          }),
        ),
        const SizedBox(height: 20),
        AnimatedBuilder(
          animation: _progressAnimation,
          builder: (context, child) => Column(children: [
            ClipRRect(borderRadius: BorderRadius.circular(10),
              child: LinearProgressIndicator(
                value: _progress * _progressAnimation.value,
                minHeight: 10,
                backgroundColor: _card,
                valueColor: const AlwaysStoppedAnimation<Color>(_redL),
              )),
            const SizedBox(height: 10),
            Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
              Text(_progressSteps[_currentStep], style: TextStyle(color: _redL, fontSize: 14, fontWeight: FontWeight.bold)),
              Text('${(_progress * 100).toInt()}%', style: TextStyle(color: Colors.white, fontSize: 14, fontWeight: FontWeight.bold)),
            ]),
          ]),
        ),
      ]),
    );
  }

  Widget _buildSendButton({required VoidCallback onPressed, required String label}) {
    return AnimatedBuilder(
      animation: _pulseController,
      builder: (context, child) => Container(
        decoration: BoxDecoration(borderRadius: BorderRadius.circular(15),
          boxShadow: [BoxShadow(color: _red.withOpacity(0.35 * _pulseController.value),
              blurRadius: 18 * _pulseController.value, spreadRadius: 2 * _pulseController.value)]),
        child: child,
      ),
      child: SizedBox(
        width: double.infinity, height: 55,
        child: ElevatedButton(
          onPressed: _isSending ? null : onPressed,
          style: ElevatedButton.styleFrom(backgroundColor: Colors.transparent, padding: EdgeInsets.zero,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)), elevation: 0),
          child: Ink(
            decoration: BoxDecoration(
              gradient: LinearGradient(colors: [Color(0xFF0D47A1), Color(0xFF880000)]),
              borderRadius: BorderRadius.circular(15),
            ),
            child: Container(
              alignment: Alignment.center,
              child: _isSending
                  ? const Row(mainAxisAlignment: MainAxisAlignment.center, children: [
                      SizedBox(width: 24, height: 24, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2)),
                      SizedBox(width: 15),
                      Text('SENDING...', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 14, letterSpacing: 1)),
                    ])
                  : Row(mainAxisAlignment: MainAxisAlignment.center, children: [
                      const Icon(Icons.send_rounded, color: Colors.white),
                      const SizedBox(width: 10),
                      Text(label, style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16, letterSpacing: 1)),
                    ]),
            ),
          ),
        ),
      ),
    );
  }

  Widget _senderTypeCard(String label, String value, IconData icon, String sub, Color activeColor) {
    final bool isSel = _senderType == value;
    final bool isDisabled = value == 'public' && widget.role != 'owner' && widget.role != 'vip' && widget.role != 'admin';
    return GestureDetector(
      onTap: isDisabled ? null : () => setState(() => _senderType = value),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 12),
        decoration: BoxDecoration(
          color: isDisabled ? Colors.white.withOpacity(0.03) : isSel ? activeColor.withOpacity(0.12) : Color(0xFF030D1F),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: isDisabled ? Colors.white10 : isSel ? activeColor : Colors.white12, width: isSel ? 1.5 : 1),
        ),
        child: Column(children: [
          Icon(icon, color: isDisabled ? Colors.white12 : isSel ? activeColor : Colors.white38, size: 30),
          const SizedBox(height: 8),
          Text(label, style: TextStyle(color: isDisabled ? Colors.white12 : isSel ? activeColor : Colors.white60,
              fontWeight: isSel ? FontWeight.bold : FontWeight.normal, fontSize: 14)),
          const SizedBox(height: 4),
          Text(isDisabled ? 'Khusus Owner / VIP' : sub, style: TextStyle(color: isDisabled ? Colors.white12 : Colors.white38, fontSize: 10)),
          const SizedBox(height: 6),
          Container(height: 3, width: 30, decoration: BoxDecoration(color: isSel && !isDisabled ? activeColor : Colors.transparent, borderRadius: BorderRadius.circular(2))),
        ]),
      ),
    );
  }
}
