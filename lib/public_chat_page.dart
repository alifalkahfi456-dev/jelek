import 'dart:convert';
import 'dart:async';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:web_socket_channel/web_socket_channel.dart';
import 'package:image_picker/image_picker.dart';
import 'package:audioplayers/audioplayers.dart';
import 'app_config.dart';

class PublicChatPage extends StatefulWidget {
  final String username;
  final String sessionKey;
  final String role;

  const PublicChatPage({
    super.key,
    required this.username,
    required this.sessionKey,
    required this.role,
  });

  @override
  State<PublicChatPage> createState() => _PublicChatPageState();
}

class _PublicChatPageState extends State<PublicChatPage> {
  // Colors
  static const _bg      = Color(0xFF020818);
  static const _s1      = Color(0xFF040F22);
  static const _s2      = Color(0xFF051525);
  static const _border  = Color(0xFF5C0000);
  static const _accent  = Color(0xFF1565C0);
  static const _accentL = Color(0xFF42A5F5);
  static const _green   = Color(0xFF4CAF50);
  static const _textP   = Color(0xFFFFF0F5);
  static const _textS   = Color(0xFFBBDEFB);
  static const _textM   = Color(0xFF9E9E9E);

  WebSocketChannel? _channel;
  final List<Map<String, dynamic>> _messages = [];
  final _msgCtrl = TextEditingController();
  final _scrollCtrl = ScrollController();
  bool _connected = false;
  bool _connecting = true;
  int _onlineCount = 0;
  Timer? _pingTimer;
  Timer? _reconnectTimer;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(_LifecycleObserver(onResume: _onResume));
    _connect();
  }

  void _onResume() {
    // Balik dari gallery/kamera — pastikan WS masih konek
    if (!_connected && !_connecting) {
      _channel?.sink.close();
      _pingTimer?.cancel();
      _connect();
    }
  }

  void _connect() {
    setState(() { _connecting = true; _connected = false; });
    try {
      final wsUrl = kBaseUrl.replaceFirst('http://', 'ws://').replaceFirst('https://', 'wss://');
      _channel = WebSocketChannel.connect(Uri.parse(wsUrl));

      // Auth
      _channel!.sink.add(jsonEncode({
        'type': 'auth',
        'key': widget.sessionKey,
      }));

      // Join public room
      _channel!.sink.add(jsonEncode({
        'type': 'joinPublicRoom',
        'key': widget.sessionKey,
      }));

      _channel!.stream.listen(
        (raw) {
          try {
            final data = jsonDecode(raw);
            if (!mounted) return;
            if (data['type'] == 'publicMessage') {
              setState(() {
                _messages.add({
                  'from':        data['from'] ?? 'unknown',
                  'message':     data['message'] ?? '',
                  'time':        data['time'] ?? '',
                  'fromMe':      data['from'] == widget.username,
                  'role':        data['role'] ?? 'member',
                  'msgType':     data['type_msg'] ?? data['type'] ?? 'text',
                  'imageBase64': data['imageBase64'],
                  'audioBase64': data['audioBase64'],
                  'imageUrl':    data['imageUrl'],
                  'audioUrl':    data['audioUrl'],
                });
              });
              _scrollToBottom();
            } else if (data['type'] == 'publicHistory') {
              final list = List<Map<String, dynamic>>.from(
                (data['messages'] ?? []).map((m) => {
                  'from': m['from'] ?? '',
                  'message': m['message'] ?? '',
                  'time': m['time'] ?? '',
                  'fromMe': m['from'] == widget.username,
                  'role': m['role'] ?? 'member',
                }),
              );
              setState(() => _messages.addAll(list));
              _scrollToBottom();
            } else if (data['type'] == 'publicOnlineCount') {
              setState(() => _onlineCount = data['count'] ?? 0);
            }
            setState(() { _connected = true; _connecting = false; });
          } catch (_) {}
        },
        onDone: () {
          if (mounted) setState(() { _connected = false; _connecting = false; });
        },
        onError: (_) {
          if (mounted) setState(() { _connected = false; _connecting = false; });
        },
      );

      _pingTimer = Timer.periodic(const Duration(seconds: 20), (_) {
        try { _channel?.sink.add(jsonEncode({'type': 'ping'})); } catch (_) {}
      });

      Future.delayed(const Duration(seconds: 2), () {
        if (mounted) setState(() { _connected = true; _connecting = false; });
      });

    } catch (e) {
      if (mounted) setState(() { _connected = false; _connecting = false; });
    }
  }

  void _sendMessage() {
    final msg = _msgCtrl.text.trim();
    if (msg.isEmpty || !_connected) return;
    try {
      _channel!.sink.add(jsonEncode({
        'type': 'publicChat',
        'key': widget.sessionKey,
        'message': msg,
      }));
      // Optimistic add
      setState(() {
        _messages.add({
          'from': widget.username,
          'message': msg,
          'time': DateTime.now().toIso8601String(),
          'fromMe': true,
          'role': widget.role,
        });
      });
      _msgCtrl.clear();
      _scrollToBottom();
    } catch (_) {}
  }

  Future<void> _sendImage() async {
    if (!_connected) return;
    try {
      final picker = ImagePicker();
      final picked = await picker.pickImage(
        source: ImageSource.gallery,
        imageQuality: 60,
        maxWidth: 800,
      );
      if (picked == null) return;
      final bytes = await picked.readAsBytes();
      final b64 = base64Encode(bytes);
      final ext = picked.name.split('.').last.toLowerCase();
      _channel!.sink.add(jsonEncode({
        'type': 'publicChat',
        'key': widget.sessionKey,
        'message': '',
        'imageBase64': b64,
        'imageExt': ext,
      }));
      setState(() {
        _messages.add({
          'from': widget.username,
          'message': '',
          'imageBase64': b64,
          'time': DateTime.now().toIso8601String(),
          'fromMe': true,
          'role': widget.role,
        });
      });
      _scrollToBottom();
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Gagal kirim foto: $e'), backgroundColor: Colors.red));
    }
  }

  void _scrollToBottom() {
    Future.delayed(const Duration(milliseconds: 100), () {
      if (_scrollCtrl.hasClients) {
        _scrollCtrl.animateTo(
          _scrollCtrl.position.maxScrollExtent,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });
  }

  String _formatTime(String iso) {
    try {
      final dt = DateTime.parse(iso).toLocal();
      return '${dt.hour.toString().padLeft(2,'0')}:${dt.minute.toString().padLeft(2,'0')}';
    } catch (_) { return ''; }
  }

  Color _roleColor(String role) {
    switch (role.toLowerCase()) {
      case 'owner': return const Color(0xFFFFD700);
      case 'dev':   return const Color(0xFF00E5FF);
      case 'admin': return const Color(0xFFE040FB);
      case 'vip':   return const Color(0xFF42A5F5);
      case 'reseller': return const Color(0xFF69F0AE);
      default: return _textS;
    }
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(_LifecycleObserver(onResume: _onResume));
    _pingTimer?.cancel();
    _reconnectTimer?.cancel();
    _channel?.sink.close();
    _msgCtrl.dispose();
    _scrollCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _bg,
      appBar: AppBar(
        backgroundColor: _s1,
        elevation: 0,
        iconTheme: const IconThemeData(color: _accentL),
        title: Row(children: [
          Container(
            width: 10, height: 10,
            decoration: BoxDecoration(
              color: _connected ? _green : Colors.red,
              shape: BoxShape.circle,
            ),
          ),
          const SizedBox(width: 8),
          const Text(
            'Public Chat',
            style: TextStyle(color: _textP, fontSize: 16, fontWeight: FontWeight.bold),
          ),
          const SizedBox(width: 8),
          if (_onlineCount > 0)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
              decoration: BoxDecoration(
                color: _green.withOpacity(0.15),
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: _green.withOpacity(0.4)),
              ),
              child: Text(
                '$_onlineCount online',
                style: TextStyle(color: _green, fontSize: 10, fontWeight: FontWeight.bold),
              ),
            ),
        ]),
        actions: [
          if (!_connected && !_connecting)
            IconButton(
              icon: const Icon(Icons.refresh_rounded, color: _accentL),
              onPressed: () {
                _channel?.sink.close();
                _pingTimer?.cancel();
                _messages.clear();
                _connect();
              },
            ),
          IconButton(
            icon: const Icon(Icons.info_outline_rounded, color: _textM, size: 20),
            onPressed: () => showDialog(
              context: context,
              builder: (_) => AlertDialog(
                backgroundColor: _s1,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                  side: BorderSide(color: _border),
                ),
                title: const Text('Public Chat', style: TextStyle(color: _textP, fontWeight: FontWeight.bold)),
                content: const Text(
                  'Pesan di sini bisa dilihat semua user yang online.\nJangan share info sensitif di sini.',
                  style: TextStyle(color: _textS, fontSize: 13, height: 1.5),
                ),
                actions: [
                  TextButton(onPressed: () => Navigator.pop(context),
                    child: const Text('OK', style: TextStyle(color: _accentL, fontWeight: FontWeight.bold))),
                ],
              ),
            ),
          ),
        ],
      ),
      body: Column(
        children: [
          // Status bar
          if (_connecting)
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(vertical: 8),
              color: _accent.withOpacity(0.1),
              child: const Center(
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    SizedBox(width: 14, height: 14,
                      child: CircularProgressIndicator(color: _accentL, strokeWidth: 2)),
                    SizedBox(width: 8),
                    Text('Connecting...', style: TextStyle(color: _accentL, fontSize: 12)),
                  ],
                ),
              ),
            ),
          if (!_connected && !_connecting)
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(vertical: 8),
              color: Colors.red.withOpacity(0.1),
              child: const Center(
                child: Text('Koneksi terputus. Tekan refresh.',
                  style: TextStyle(color: Colors.redAccent, fontSize: 12)),
              ),
            ),

          // Messages
          Expanded(
            child: _messages.isEmpty
              ? Center(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.chat_bubble_outline_rounded, color: _textM.withOpacity(0.3), size: 52),
                      const SizedBox(height: 12),
                      const Text('Belum ada pesan', style: TextStyle(color: _textM, fontSize: 13)),
                      const SizedBox(height: 4),
                      const Text('Mulai percakapan!', style: TextStyle(color: _textM, fontSize: 11)),
                    ],
                  ),
                )
              : ListView.builder(
                  controller: _scrollCtrl,
                  padding: const EdgeInsets.fromLTRB(12, 12, 12, 8),
                  itemCount: _messages.length,
                  itemBuilder: (_, i) {
                    final m = _messages[i];
                    final fromMe = m['fromMe'] == true;
                    final showSender = i == 0 || _messages[i-1]['from'] != m['from'];
                    return _buildBubble(m, fromMe, showSender);
                  },
                ),
          ),

          // Input
          Container(
            padding: const EdgeInsets.fromLTRB(12, 8, 12, 16),
            decoration: BoxDecoration(
              color: _s1,
              border: Border(top: BorderSide(color: _border.withOpacity(0.5))),
            ),
            child: Row(children: [
              Expanded(
                child: Container(
                  decoration: BoxDecoration(
                    color: _s2,
                    borderRadius: BorderRadius.circular(24),
                    border: Border.all(color: _border),
                  ),
                  child: TextField(
                    controller: _msgCtrl,
                    style: TextStyle(color: _textP, fontSize: 14),
                    maxLength: 250,
                    maxLines: null,
                    textInputAction: TextInputAction.send,
                    onSubmitted: (_) => _sendMessage(),
                    decoration: InputDecoration(
                      hintText: 'Kirim pesan ke semua...',
                      hintStyle: TextStyle(color: _textM, fontSize: 13),
                      border: InputBorder.none,
                      contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                      counterText: '',
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 8),
              // Tombol kirim foto
              GestureDetector(
                onTap: _sendImage,
                child: Container(
                  width: 44, height: 44,
                  decoration: BoxDecoration(
                    color: const Color(0xFF1565C0).withOpacity(0.15),
                    shape: BoxShape.circle,
                    border: Border.all(color: const Color(0xFF42A5F5).withOpacity(0.4)),
                  ),
                  child: const Icon(Icons.image_rounded, color: Color(0xFF42A5F5), size: 20),
                ),
              ),
              const SizedBox(width: 6),
              // Tombol kirim pesan
              GestureDetector(
                onTap: _sendMessage,
                child: Container(
                  width: 44, height: 44,
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [_accent, Color(0xFF800000)],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    shape: BoxShape.circle,
                    boxShadow: [
                      BoxShadow(color: _accent.withOpacity(0.4), blurRadius: 10, offset: Offset(0, 3)),
                    ],
                  ),
                  child: const Icon(Icons.send_rounded, color: Colors.white, size: 18),
                ),
              ),
            ]),
          ),
        ],
      ),
    );
  }

  Widget _buildBubble(Map m, bool fromMe, bool showSender) {
    final role = m['role']?.toString() ?? 'member';
    return Padding(
      padding: EdgeInsets.only(
        bottom: 4,
        left: fromMe ? 50 : 0,
        right: fromMe ? 0 : 50,
      ),
      child: Column(
        crossAxisAlignment: fromMe ? CrossAxisAlignment.end : CrossAxisAlignment.start,
        children: [
          if (!fromMe && showSender)
            Padding(
              padding: const EdgeInsets.only(left: 4, bottom: 2),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    m['from'] ?? '',
                    style: TextStyle(
                      color: _roleColor(role),
                      fontSize: 11,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(width: 4),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1),
                    decoration: BoxDecoration(
                      color: _roleColor(role).withOpacity(0.15),
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: Text(
                      role.toUpperCase(),
                      style: TextStyle(color: _roleColor(role), fontSize: 8, fontWeight: FontWeight.bold),
                    ),
                  ),
                ],
              ),
            ),
          GestureDetector(
            onLongPress: () {
              Clipboard.setData(ClipboardData(text: m['message'] ?? ''));
              ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
                content: Text('Pesan disalin!'),
                backgroundColor: _green,
                behavior: SnackBarBehavior.floating,
                duration: Duration(seconds: 1),
              ));
            },
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
              decoration: BoxDecoration(
                color: fromMe ? _accent.withOpacity(0.25) : _s2,
                borderRadius: BorderRadius.only(
                  topLeft: const Radius.circular(16),
                  topRight: const Radius.circular(16),
                  bottomLeft: Radius.circular(fromMe ? 16 : 4),
                  bottomRight: Radius.circular(fromMe ? 4 : 16),
                ),
                border: Border.all(
                  color: fromMe ? _accent.withOpacity(0.4) : _border.withOpacity(0.4),
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  // Tampilkan foto kalau ada
                  if (m['imageBase64'] != null) ...[
                    ClipRRect(
                      borderRadius: BorderRadius.circular(10),
                      child: Image.memory(
                        base64Decode(m['imageBase64']),
                        width: 200, fit: BoxFit.cover,
                        errorBuilder: (_, __, ___) => const Icon(Icons.broken_image_rounded, color: Colors.white30),
                      ),
                    ),
                    const SizedBox(height: 4),
                  ],
                  // Tampilkan audio player kalau ada
                  if (m['audioBase64'] != null) ...[
                    GestureDetector(
                      onTap: () async {
                        final player = AudioPlayer();
                        final bytes = base64Decode(m['audioBase64']);
                        await player.play(BytesSource(bytes));
                      },
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                        decoration: BoxDecoration(
                          color: Colors.white10,
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Row(mainAxisSize: MainAxisSize.min, children: [
                          const Icon(Icons.play_arrow_rounded, color: Colors.white, size: 20),
                          const SizedBox(width: 6),
                          Text('Rekaman Suara', style: TextStyle(color: Colors.white70, fontSize: 12)),
                        ]),
                      ),
                    ),
                    const SizedBox(height: 4),
                  ],
                  // Teks pesan biasa
                  if (m['message'] != null && m['message'] != '[Foto]' && m['message'] != '[Rekaman Suara]')
                    Text(
                      m['message'] ?? '',
                      style: TextStyle(color: _textP, fontSize: 13, height: 1.4),
                    ),
                  const SizedBox(height: 2),
                  Text(
                    _formatTime(m['time'] ?? ''),
                    style: TextStyle(color: _textM, fontSize: 9),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// Helper lifecycle observer untuk auto-reconnect setelah balik dari gallery
class _LifecycleObserver extends WidgetsBindingObserver {
  final VoidCallback onResume;
  _LifecycleObserver({required this.onResume});

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) onResume();
  }

  @override
  bool operator ==(Object other) => other is _LifecycleObserver;
  @override
  int get hashCode => 0;
}
