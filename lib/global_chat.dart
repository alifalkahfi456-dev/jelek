import 'dart:async';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'api_config.dart';

// ─── Colors ─────────────────────────────────
const _kBg      = Color(0xFF06131A);
const _kSurface = Color(0xFF0C1D26);
const _kCard    = Color(0xFF122833);
const _kBorder  = Color(0xFF2B5D6A);
const _kRed     = Color(0xFF39C7D9);
const _kRedLit  = Color(0xFF5EEFFF);
const _kText    = Color(0xFFEFFFFF);
const _kTextSub = Color(0xFFA8D7DF);
const _kTextDim = Color(0xFF6F95A0);
const _kGreen   = Color(0xFF55D6C2);

// ─── Role Colors ────────────────────────────
Color _roleColor(String role) {
  switch (role.toLowerCase()) {
    case 'developer':  return const Color(0xFF7CF7ED);
    case 'founder':    return const Color(0xFF67DDE2);
    case 'high_owner': return const Color(0xFF5EEFFF);
    case 'owner':      return const Color(0xFF79E6E6);
    case 'vip':        return const Color(0xFF39C7D9);
    case 'reseller':   return _kGreen;
    case 'full_up':    return _kTextSub;
    default:           return _kTextSub;
  }
}

// ─── Role Badge ─────────────────────────────
Widget _roleBadge(String role) {
  return Container(
    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
    decoration: BoxDecoration(
      color: _roleColor(role).withOpacity(0.15),
      borderRadius: BorderRadius.circular(6),
      border: Border.all(color: _roleColor(role).withOpacity(0.5)),
    ),
    child: Text(
      role.toUpperCase().replaceAll('_', ' '),
      style: TextStyle(
        color: _roleColor(role),
        fontSize: 9,
        fontWeight: FontWeight.bold,
        fontFamily: 'Orbitron',
        letterSpacing: 0.5,
      ),
    ),
  );
}

// ─── Model ──────────────────────────────────
class _ChatMsg {
  final String id;
  final String username;
  final String role;
  final String message;
  final String time;

  _ChatMsg({
    required this.id,
    required this.username,
    required this.role,
    required this.message,
    required this.time,
  });

  factory _ChatMsg.fromJson(Map<String, dynamic> j) => _ChatMsg(
    id:       j['id']?.toString()       ?? '',
    username: j['username']?.toString() ?? 'Unknown',
    role:     j['role']?.toString()     ?? 'full_up',
    message:  j['message']?.toString()  ?? '',
    time:     j['time']?.toString()     ?? '',
  );
}

// ─── Page ───────────────────────────────────
class GlobalChatPage extends StatefulWidget {
  final String sessionKey;
  final String username;
  final String role;

  const GlobalChatPage({
    super.key,
    required this.sessionKey,
    required this.username,
    required this.role,
  });

  @override
  State<GlobalChatPage> createState() => _GlobalChatPageState();
}

class _GlobalChatPageState extends State<GlobalChatPage>
    with TickerProviderStateMixin {

  final _msgCtrl   = TextEditingController();
  final _scrollCtrl = ScrollController();
  final List<_ChatMsg> _messages = [];

  bool _sending  = false;
  bool _loading  = true;
  Timer? _pollTimer;

  late AnimationController _pulseCtrl;

  @override
  void initState() {
    super.initState();
    _pulseCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
    )..repeat(reverse: true);

    _fetchMessages();
    // Poll setiap 3 detik - real-time effect
    _pollTimer = Timer.periodic(const Duration(seconds: 3), (_) => _fetchMessages());
  }

  @override
  void dispose() {
    _pollTimer?.cancel();
    _msgCtrl.dispose();
    _scrollCtrl.dispose();
    _pulseCtrl.dispose();
    super.dispose();
  }

  // ── Fetch Messages ──────────────────────────
  Future<void> _fetchMessages() async {
    try {
      final res = await http.get(
        Uri.parse('http://tirzzadminbaik.pteroqdactyl.my.id:11560/globalChat?key=${widget.sessionKey}'),
      ).timeout(const Duration(seconds: 5));

      if (res.statusCode == 200) {
        final data = jsonDecode(res.body);
        final List rawList = data['messages'] ?? data['chats'] ?? data ?? [];
        final newMsgs = rawList
            .map((e) => _ChatMsg.fromJson(Map<String, dynamic>.from(e)))
            .toList();

        if (mounted) {
          setState(() {
            _messages.clear();
            _messages.addAll(newMsgs);
            _loading = false;
          });
          _scrollToBottom();
        }
      }
    } catch (_) {
      if (mounted) setState(() => _loading = false);
    }
  }

  // ── Send Message ────────────────────────────
  Future<void> _sendMessage() async {
    final text = _msgCtrl.text.trim();
    if (text.isEmpty || _sending) return;

    setState(() => _sending = true);
    _msgCtrl.clear();

    try {
      final res = await http.post(
        Uri.parse('http://tirzzadminbaik.pteroqdactyl.my.id:11560/sendChat'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'key':     widget.sessionKey,
          'message': text,
        }),
      ).timeout(const Duration(seconds: 8));

      if (res.statusCode == 200) {
        await _fetchMessages();
      }
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Gagal kirim pesan'),
            backgroundColor: Color(0xFF8B0000),
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _sending = false);
    }
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollCtrl.hasClients) {
        _scrollCtrl.animateTo(
          _scrollCtrl.position.maxScrollExtent,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });
  }

  bool get _isMe => true;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _kBg,
      appBar: _buildAppBar(),
      body: Column(
        children: [
          Expanded(child: _buildChatList()),
          _buildInputBar(),
        ],
      ),
    );
  }

  // ── AppBar ──────────────────────────────────
  PreferredSizeWidget _buildAppBar() {
    return AppBar(
      backgroundColor: _kSurface,
      elevation: 0,
      leading: IconButton(
        icon: const Icon(Icons.arrow_back_ios_rounded, color: _kRedLit, size: 20),
        onPressed: () => Navigator.pop(context),
      ),
      title: Row(
        children: [
          AnimatedBuilder(
            animation: _pulseCtrl,
            builder: (_, __) => Container(
              width: 8, height: 8,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: _kGreen,
                boxShadow: [
                  BoxShadow(
                    color: _kGreen.withOpacity(0.5 * _pulseCtrl.value),
                    blurRadius: 6,
                    spreadRadius: 2,
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(width: 10),
          const Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'GLOBAL CHAT',
                style: TextStyle(
                  color: _kText,
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                  fontFamily: 'Orbitron',
                  letterSpacing: 2,
                ),
              ),
              Text(
                'Semua user bisa baca & kirim',
                style: TextStyle(color: _kTextSub, fontSize: 10),
              ),
            ],
          ),
        ],
      ),
      bottom: PreferredSize(
        preferredSize: const Size.fromHeight(1),
        child: Container(height: 1, color: _kBorder),
      ),
    );
  }

  // ── Chat List ───────────────────────────────
  Widget _buildChatList() {
    if (_loading) {
      return const Center(
        child: CircularProgressIndicator(color: _kRed),
      );
    }

    if (_messages.isEmpty) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 72, height: 72,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: _kSurface,
                border: Border.all(color: _kBorder),
              ),
              child: const Icon(Icons.chat_bubble_outline_rounded, color: _kTextSub, size: 30),
            ),
            const SizedBox(height: 16),
            const Text('Belum ada pesan', style: TextStyle(color: _kTextSub, fontSize: 14)),
            const SizedBox(height: 6),
            const Text('Jadilah yang pertama kirim!', style: TextStyle(color: _kTextDim, fontSize: 12)),
          ],
        ),
      );
    }

    return ListView.builder(
      controller: _scrollCtrl,
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
      itemCount: _messages.length,
      itemBuilder: (context, index) {
        final msg = _messages[index];
        final isMe = msg.username == widget.username;
        return _buildMsgBubble(msg, isMe);
      },
    );
  }

  // ── Message Bubble ──────────────────────────
  Widget _buildMsgBubble(_ChatMsg msg, bool isMe) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Row(
        mainAxisAlignment: isMe ? MainAxisAlignment.end : MainAxisAlignment.start,
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          if (!isMe) ...[
            // Avatar
            Container(
              width: 34, height: 34,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: _roleColor(msg.role).withOpacity(0.2),
                border: Border.all(color: _roleColor(msg.role).withOpacity(0.5)),
              ),
              child: Center(
                child: Text(
                  msg.username.substring(0, 1).toUpperCase(),
                  style: TextStyle(
                    color: _roleColor(msg.role),
                    fontSize: 13,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ),
            const SizedBox(width: 8),
          ],

          // Bubble
          Flexible(
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: isMe
                      ? [const Color(0xFF5C0000), const Color(0xFF3B0000)]
                      : [_kCard, _kSurface],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.only(
                  topLeft:     const Radius.circular(16),
                  topRight:    const Radius.circular(16),
                  bottomLeft:  Radius.circular(isMe ? 16 : 4),
                  bottomRight: Radius.circular(isMe ? 4  : 16),
                ),
                border: Border.all(
                  color: isMe ? _kRed.withOpacity(0.4) : _kBorder,
                ),
                boxShadow: [
                  BoxShadow(
                    color: isMe ? _kRed.withOpacity(0.15) : Colors.black26,
                    blurRadius: 8,
                    offset: const Offset(0, 3),
                  ),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (!isMe) ...[
                    Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          msg.username,
                          style: TextStyle(
                            color: _roleColor(msg.role),
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(width: 6),
                        _roleBadge(msg.role),
                      ],
                    ),
                    const SizedBox(height: 4),
                  ],
                  Text(
                    msg.message,
                    style: const TextStyle(color: _kText, fontSize: 13, height: 1.5),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    msg.time,
                    style: const TextStyle(color: _kTextDim, fontSize: 10),
                  ),
                ],
              ),
            ),
          ),

          if (isMe) ...[
            const SizedBox(width: 8),
            // Avatar me
            Container(
              width: 34, height: 34,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: _kRed.withOpacity(0.2),
                border: Border.all(color: _kRed.withOpacity(0.5)),
              ),
              child: Center(
                child: Text(
                  widget.username.substring(0, 1).toUpperCase(),
                  style: const TextStyle(
                    color: _kRed,
                    fontSize: 13,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }

  // ── Input Bar ───────────────────────────────
  Widget _buildInputBar() {
    return Container(
      padding: const EdgeInsets.fromLTRB(12, 10, 12, 16),
      decoration: BoxDecoration(
        color: _kSurface,
        border: Border(top: BorderSide(color: _kBorder)),
      ),
      child: Row(
        children: [
          // Input Field
          Expanded(
            child: Container(
              decoration: BoxDecoration(
                color: _kCard,
                borderRadius: BorderRadius.circular(24),
                border: Border.all(color: _kBorder),
              ),
              child: TextField(
                controller: _msgCtrl,
                style: const TextStyle(color: _kText, fontSize: 14),
                maxLines: 3,
                minLines: 1,
                textInputAction: TextInputAction.newline,
                decoration: InputDecoration(
                  hintText: 'Ketik pesan...',
                  hintStyle: const TextStyle(color: _kTextDim),
                  border: InputBorder.none,
                  contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                ),
              ),
            ),
          ),
          const SizedBox(width: 10),
          // Send Button
          GestureDetector(
            onTap: _sendMessage,
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 150),
              width: 48, height: 48,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: LinearGradient(
                  colors: _sending
                      ? [_kBorder, _kBorder]
                      : [_kRed, const Color(0xFF8B0000)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                boxShadow: _sending ? [] : [
                  BoxShadow(
                    color: _kRed.withOpacity(0.4),
                    blurRadius: 12,
                    spreadRadius: 1,
                  ),
                ],
              ),
              child: _sending
                  ? const Padding(
                      padding: EdgeInsets.all(14),
                      child: CircularProgressIndicator(
                        color: _kTextSub,
                        strokeWidth: 2,
                      ),
                    )
                  : const Icon(Icons.send_rounded, color: Colors.white, size: 20),
            ),
          ),
        ],
      ),
    );
  }
}
