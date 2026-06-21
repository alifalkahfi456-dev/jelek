// chat_page.dart (Dengan Reply & Persegi Panjang - FIXED)
import 'dart:async';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:web_socket_channel/web_socket_channel.dart';

const _kBase = 'http://panel.lynzzofficial.com:2031';

class ChatTheme {
  static const bg = Color(0xFF0A0A0F);
  static const surface = Color(0xFF14141F);
  static const surface2 = Color(0xFF1C1C2A);
  static const surface3 = Color(0xFF242433);
  static const accent1 = Color(0xFF00E5FF);
  static const accent2 = Color(0xFF7C4DFF);
  static const accent3 = Color(0xFFFF4081);
  static const success = Color(0xFF00E676);
  static const warning = Color(0xFFFFAB40);
  static const error = Color(0xFFFF5252);
  static const textPrimary = Color(0xFFF5F5FF);
  static const textSecondary = Color(0xFF9E9EB8);
  static const textMuted = Color(0xFF6B6B8A);
  static const shadowHeavy = Color(0x80000000);
}

class ChatPage extends StatefulWidget {
  final String username;
  final String sessionKey;
  
  const ChatPage({
    super.key,
    required this.username,
    required this.sessionKey,
  });

  @override
  State<ChatPage> createState() => _ChatPageState();
}

class _ChatPageState extends State<ChatPage> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  WebSocketChannel? _channel;
  
  // Global chat
  List<dynamic> _globalMessages = [];
  bool _globalLoading = true;
  final TextEditingController _globalInputCtrl = TextEditingController();
  final ScrollController _globalScrollCtrl = ScrollController();
  Map<String, dynamic>? _globalReplyTo;
  
  // Private chat
  List<dynamic> _privateChats = [];
  List<dynamic> _privateMessages = [];
  String? _selectedUser;
  bool _privateLoading = true;
  final TextEditingController _privateInputCtrl = TextEditingController();
  final ScrollController _privateScrollCtrl = ScrollController();
  Map<String, dynamic>? _privateReplyTo;
  
  // Profile
  Map<String, dynamic> _myProfile = {};
  
  // Search
  final TextEditingController _searchCtrl = TextEditingController();
  List<dynamic> _searchResults = [];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _loadProfile();
    _connectWebSocket();
    _loadGlobalMessages();
    _loadPrivateChats();
  }

  @override
  void dispose() {
    _tabController.dispose();
    _channel?.sink.close();
    _globalInputCtrl.dispose();
    _globalScrollCtrl.dispose();
    _privateInputCtrl.dispose();
    _privateScrollCtrl.dispose();
    _searchCtrl.dispose();
    super.dispose();
  }

  Future<void> _loadProfile() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final sessionKey = prefs.getString('session_key') ?? widget.sessionKey;
      final res = await http.get(Uri.parse('$_kBase/chat/profile?key=$sessionKey'));
      if (res.statusCode == 200) {
        final data = jsonDecode(res.body);
        if (data['valid'] == true) {
          setState(() => _myProfile = data['profile']);
        }
      }
    } catch (e) { print('Profile load error: $e'); }
  }

  void _connectWebSocket() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final sessionKey = prefs.getString('session_key') ?? widget.sessionKey;
      
      _channel = WebSocketChannel.connect(Uri.parse('ws://serverku.lynzzofficial.com:2099'));
      _channel!.stream.listen(_handleWebSocketMessage, onError: (e) {
        print('WebSocket error: $e');
      });
      _channel!.sink.add(jsonEncode({ 'type': 'auth', 'key': sessionKey }));
    } catch (e) { print('Connection error: $e'); }
  }
  
  void _handleWebSocketMessage(dynamic data) {
    try {
      final msg = jsonDecode(data);
      if (msg['type'] == 'global_message') {
        _addGlobalMessage(msg['message']);
      } else if (msg['type'] == 'private_message') {
        _addPrivateMessage(msg['message']);
      } else if (msg['type'] == 'refresh_chat_list') {
        _loadPrivateChats();
      }
    } catch (e) { print('Parse error: $e'); }
  }

  // ==================== GLOBAL CHAT METHODS ====================
  
  Future<void> _loadGlobalMessages() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final sessionKey = prefs.getString('session_key') ?? widget.sessionKey;
      final res = await http.get(Uri.parse('$_kBase/chat/global/messages?key=$sessionKey&limit=100'));
      if (res.statusCode == 200) {
        final data = jsonDecode(res.body);
        if (data['valid'] == true) {
          setState(() {
            // Pesan dari API sudah dalam urutan ascending (terlama ke terbaru)
            _globalMessages = data['messages'];
            _globalLoading = false;
          });
          // Scroll ke bawah (pesan terbaru)
          WidgetsBinding.instance.addPostFrameCallback((_) {
            _scrollToBottom(_globalScrollCtrl);
          });
        }
      }
    } catch (e) { if (mounted) setState(() => _globalLoading = false); }
  }
  
  void _addGlobalMessage(dynamic msg) {
    setState(() => _globalMessages.add(msg));
    // Scroll ke bawah saat pesan baru masuk
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _scrollToBottom(_globalScrollCtrl);
    });
  }
  
  void _scrollToBottom(ScrollController controller) {
    if (controller.hasClients) {
      controller.animateTo(
        controller.position.maxScrollExtent,
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeOut,
      );
    }
  }
  
  Future<void> _sendGlobalMessage() async {
    String text = _globalInputCtrl.text.trim();
    if (text.isEmpty && _globalReplyTo == null) return;
    
    // Jika reply, tambahkan prefix
    String finalText = text;
    if (_globalReplyTo != null) {
      finalText = '@${_globalReplyTo!['sender']} ${text}';
    }
    
    setState(() => _globalInputCtrl.text = '');
    
    try {
      final prefs = await SharedPreferences.getInstance();
      final sessionKey = prefs.getString('session_key') ?? widget.sessionKey;
      final body = jsonEncode({ 
        'message': finalText, 
        'type': 'text',
        'replyTo': _globalReplyTo?['id']
      });
      
      final res = await http.post(
        Uri.parse('$_kBase/chat/global/send?key=$sessionKey'),
        headers: {'Content-Type': 'application/json'},
        body: body,
      );
      
      if (res.statusCode == 200) {
        final data = jsonDecode(res.body);
        if (data['valid'] == true) {
          setState(() => _globalReplyTo = null);
          _loadGlobalMessages();
        }
      }
    } catch (e) { print('Send error: $e'); }
  }

  // ==================== PRIVATE CHAT METHODS ====================
  
  Future<void> _loadPrivateChats() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final sessionKey = prefs.getString('session_key') ?? widget.sessionKey;
      final res = await http.get(Uri.parse('$_kBase/chat/private/users?key=$sessionKey'));
      if (res.statusCode == 200) {
        final data = jsonDecode(res.body);
        if (data['valid'] == true) {
          setState(() {
            _privateChats = data['users'];
            _privateLoading = false;
          });
        }
      }
    } catch (e) { if (mounted) setState(() => _privateLoading = false); }
  }
  
  Future<void> _loadPrivateMessages(String withUser) async {
    setState(() => _privateLoading = true);
    try {
      final prefs = await SharedPreferences.getInstance();
      final sessionKey = prefs.getString('session_key') ?? widget.sessionKey;
      final res = await http.get(Uri.parse('$_kBase/chat/private/messages/$withUser?key=$sessionKey&limit=100'));
      if (res.statusCode == 200) {
        final data = jsonDecode(res.body);
        if (data['valid'] == true) {
          setState(() {
            _privateMessages = data['messages'];
            _privateLoading = false;
          });
          // Scroll ke bawah (pesan terbaru)
          WidgetsBinding.instance.addPostFrameCallback((_) {
            _scrollToBottom(_privateScrollCtrl);
          });
          
          // Mark as read
          await http.post(Uri.parse('$_kBase/chat/private/mark-read/$withUser?key=$sessionKey'));
        }
      }
    } catch (e) { setState(() => _privateLoading = false); }
  }
  
  void _addPrivateMessage(dynamic msg) {
    final isCurrentChat = _selectedUser == msg['sender'] || _selectedUser == msg['receiver'];
    if (isCurrentChat) {
      setState(() => _privateMessages.add(msg));
      // Scroll ke bawah saat pesan baru masuk
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _scrollToBottom(_privateScrollCtrl);
      });
    }
    _loadPrivateChats(); // Refresh chat list untuk update last message
  }
  
  Future<void> _sendPrivateMessage() async {
    String text = _privateInputCtrl.text.trim();
    if (text.isEmpty || _selectedUser == null) return;
    
    // Jika reply, tambahkan prefix
    String finalText = text;
    if (_privateReplyTo != null) {
      finalText = '@${_privateReplyTo!['sender']} ${text}';
    }
    
    setState(() => _privateInputCtrl.text = '');
    
    try {
      final prefs = await SharedPreferences.getInstance();
      final sessionKey = prefs.getString('session_key') ?? widget.sessionKey;
      final body = jsonEncode({ 
        'message': finalText, 
        'type': 'text',
        'replyTo': _privateReplyTo?['id']
      });
      
      final res = await http.post(
        Uri.parse('$_kBase/chat/private/send/${_selectedUser}?key=$sessionKey'),
        headers: {'Content-Type': 'application/json'},
        body: body,
      );
      
      if (res.statusCode == 200) {
        final data = jsonDecode(res.body);
        if (data['valid'] == true) {
          setState(() => _privateReplyTo = null);
          // Reload messages after sending
          _loadPrivateMessages(_selectedUser!);
        } else {
          // Jika gagal, tampilkan error
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(data['error'] ?? 'Gagal mengirim pesan')),
          );
        }
      }
    } catch (e) { 
      print('Send error: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: $e')),
      );
    }
  }
  
  Future<void> _searchAndStartChat() async {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => _SearchUserSheet(
        sessionKey: widget.sessionKey,
        currentUsername: widget.username,
        onSelectUser: (user) {
          Navigator.pop(ctx);
          setState(() {
            _selectedUser = user['username'];
            _privateReplyTo = null;
          });
          _loadPrivateMessages(user['username']);
          _tabController.animateTo(1);
        },
      ),
    );
  }

  String _formatTime(String? timestamp) {
    if (timestamp == null) return '';
    try {
      final time = DateTime.parse(timestamp);
      final now = DateTime.now();
      final diff = now.difference(time);
      if (diff.inSeconds < 60) return 'Just now';
      if (diff.inMinutes < 60) return '${diff.inMinutes}m ago';
      if (diff.inHours < 24) return '${diff.inHours}h ago';
      return '${diff.inDays}d ago';
    } catch (_) { return ''; }
  }

  // ==================== BUILD WIDGETS ====================
  
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: ChatTheme.bg,
      appBar: _buildAppBar(),
      body: Column(
        children: [
          // Tab Bar - PERSEGI PANJANG SETENGAH KOTAK
          Container(
            margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            height: 48,
            decoration: BoxDecoration(
              color: ChatTheme.surface2,
              borderRadius: BorderRadius.circular(12),
            ),
            child: TabBar(
              controller: _tabController,
              indicator: BoxDecoration(
                borderRadius: BorderRadius.circular(12),
                gradient: const LinearGradient(
                  colors: [ChatTheme.accent1, ChatTheme.accent2],
                ),
              ),
              labelColor: Colors.white,
              unselectedLabelColor: ChatTheme.textMuted,
              dividerColor: Colors.transparent,
              labelStyle: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600),
              unselectedLabelStyle: const TextStyle(fontSize: 13),
              indicatorSize: TabBarIndicatorSize.tab,
              tabs: const [
                Tab(icon: Icon(Icons.public_rounded, size: 18), text: 'GLOBAL'),
                Tab(icon: Icon(Icons.lock_rounded, size: 18), text: 'PRIVATE'),
              ],
            ),
          ),
          // Tab View
          Expanded(
            child: TabBarView(
              controller: _tabController,
              children: [
                _buildGlobalChat(),
                _buildPrivateChat(),
              ],
            ),
          ),
        ],
      ),
    );
  }

  AppBar _buildAppBar() {
    return AppBar(
      backgroundColor: ChatTheme.surface,
      elevation: 0,
      leading: IconButton(
        icon: const Icon(Icons.arrow_back_rounded, color: ChatTheme.textPrimary),
        onPressed: () => Navigator.pop(context),
      ),
      title: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'CELTICS CHAT',
            style: TextStyle(
              color: ChatTheme.textMuted,
              fontSize: 10,
              letterSpacing: 1.5,
              fontWeight: FontWeight.w600,
            ),
          ),
          Text(
            '@${widget.username}',
            style: TextStyle(color: ChatTheme.textSecondary, fontSize: 11),
          ),
        ],
      ),
      actions: [
        IconButton(
          icon: const Icon(Icons.refresh_rounded, color: ChatTheme.accent1),
          onPressed: () {
            _loadGlobalMessages();
            _loadPrivateChats();
            if (_selectedUser != null) _loadPrivateMessages(_selectedUser!);
          },
        ),
      ],
    );
  }

  // ==================== GLOBAL CHAT TAB ====================
  
  Widget _buildGlobalChat() {
    return Column(
      children: [
        // Reply Preview Bar
        if (_globalReplyTo != null) _buildReplyPreviewBar(isGlobal: true),
        Expanded(
          child: _globalLoading
              ? const Center(child: CircularProgressIndicator(color: ChatTheme.accent1))
              : _globalMessages.isEmpty
                  ? _buildEmptyState('Belum ada pesan', 'Jadilah yang pertama mengirim pesan!')
                  : ListView.builder(
                      controller: _globalScrollCtrl,
                      padding: const EdgeInsets.only(bottom: 80),
                      itemCount: _globalMessages.length,
                      itemBuilder: (ctx, i) => _buildGlobalMessageBubble(_globalMessages[i]),
                    ),
        ),
        _buildInputBar(
          controller: _globalInputCtrl,
          onSend: _sendGlobalMessage,
          hint: 'Type a message...',
          isGlobal: true,
        ),
      ],
    );
  }

  Widget _buildGlobalMessageBubble(dynamic msg) {
    final isMe = msg['sender'] == widget.username;
    final profile = msg['senderProfile'] ?? {};
    final name = profile['name'] ?? msg['sender'];
    final replyTo = msg['replyTo'];
    
    return GestureDetector(
      onLongPress: () {
        setState(() {
          _globalReplyTo = {
            'id': msg['id'],
            'sender': msg['sender'],
            'message': msg['message'],
          };
        });
      },
      child: Container(
        margin: EdgeInsets.only(
          left: isMe ? 60 : 12,
          right: isMe ? 12 : 60,
          top: 8,
          bottom: 8,
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (!isMe) ...[
              GestureDetector(
                onTap: () {
                  if (msg['sender'] != widget.username) {
                    setState(() {
                      _selectedUser = msg['sender'];
                      _privateReplyTo = null;
                    });
                    _loadPrivateMessages(msg['sender']);
                    _tabController.animateTo(1);
                  }
                },
                child: CircleAvatar(
                  radius: 18,
                  backgroundColor: ChatTheme.surface3,
                  child: Text(name[0].toUpperCase(), style: TextStyle(color: ChatTheme.accent1)),
                ),
              ),
              const SizedBox(width: 8),
            ],
            Expanded(
              child: Column(
                crossAxisAlignment: isMe ? CrossAxisAlignment.end : CrossAxisAlignment.start,
                children: [
                  if (!isMe)
                    Padding(
                      padding: const EdgeInsets.only(left: 4, bottom: 4),
                      child: Text(name, style: TextStyle(color: ChatTheme.textSecondary, fontSize: 11)),
                    ),
                  // Reply Preview
                  if (replyTo != null)
                    Container(
                      margin: const EdgeInsets.only(bottom: 6),
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: ChatTheme.surface3,
                        borderRadius: BorderRadius.circular(8),
                        border: Border(left: BorderSide(color: isMe ? ChatTheme.accent2 : ChatTheme.accent1, width: 3)),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Replying to @${replyTo['sender']}',
                            style: TextStyle(color: isMe ? ChatTheme.accent2 : ChatTheme.accent1, fontSize: 10),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            replyTo['message'] ?? '',
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(color: ChatTheme.textMuted, fontSize: 11),
                          ),
                        ],
                      ),
                    ),
                  // Main Message
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                    decoration: BoxDecoration(
                      color: isMe ? ChatTheme.accent2.withOpacity(0.2) : ChatTheme.surface2,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: isMe ? ChatTheme.accent2.withOpacity(0.3) : ChatTheme.surface3),
                    ),
                    child: Text(
                      msg['message'] ?? '',
                      style: TextStyle(
                        color: isMe ? ChatTheme.accent1 : ChatTheme.textPrimary,
                        fontSize: 13,
                      ),
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.only(left: 8, right: 8, top: 4),
                    child: Text(
                      _formatTime(msg['timestamp']),
                      style: TextStyle(color: ChatTheme.textMuted, fontSize: 9),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ==================== PRIVATE CHAT TAB ====================
  
  Widget _buildPrivateChat() {
    return _selectedUser == null
        ? _buildChatList()
        : Column(
            children: [
              _buildChatHeader(),
              // Reply Preview Bar
              if (_privateReplyTo != null) _buildReplyPreviewBar(isGlobal: false),
              Expanded(
                child: _privateLoading
                    ? const Center(child: CircularProgressIndicator(color: ChatTheme.accent1))
                    : _privateMessages.isEmpty
                        ? _buildEmptyState('Belum ada pesan', 'Kirim pesan pertama untuk memulai!')
                        : ListView.builder(
                            controller: _privateScrollCtrl,
                            padding: const EdgeInsets.only(bottom: 80),
                            itemCount: _privateMessages.length,
                            itemBuilder: (ctx, i) => _buildPrivateMessageBubble(_privateMessages[i]),
                          ),
              ),
              _buildInputBar(
                controller: _privateInputCtrl,
                onSend: _sendPrivateMessage,
                hint: 'End-to-End Encrypted message...',
                isGlobal: false,
              ),
            ],
          );
  }

  Widget _buildChatList() {
    return Column(
      children: [
        // Search Bar - PERSEGI PANJANG
        Padding(
          padding: const EdgeInsets.all(12),
          child: GestureDetector(
            onTap: _searchAndStartChat,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              decoration: BoxDecoration(
                color: ChatTheme.surface2,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: ChatTheme.surface3),
              ),
              child: Row(
                children: [
                  Icon(Icons.search_rounded, color: ChatTheme.textMuted),
                  const SizedBox(width: 12),
                  Text('Cari user baru...', style: TextStyle(color: ChatTheme.textMuted)),
                ],
              ),
            ),
          ),
        ),
        Expanded(
          child: _privateChats.isEmpty
              ? _buildEmptyState('Belum ada chat', 'Cari user untuk memulai percakapan private!')
              : ListView.builder(
                  padding: const EdgeInsets.all(12),
                  itemCount: _privateChats.length,
                  itemBuilder: (ctx, i) => _buildChatListItem(_privateChats[i]),
                ),
        ),
      ],
    );
  }

  Widget _buildChatListItem(dynamic chat) {
    final profile = chat['profile'] ?? {};
    final lastMsg = chat['lastMessage'];
    final isUnread = lastMsg != null && lastMsg['sender'] != widget.username && lastMsg['read'] != true;
    
    return GestureDetector(
      onTap: () {
        setState(() {
          _selectedUser = chat['username'];
          _privateReplyTo = null;
        });
        _loadPrivateMessages(chat['username']);
      },
      child: Container(
        margin: const EdgeInsets.only(bottom: 8),
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: isUnread ? ChatTheme.accent1.withOpacity(0.1) : ChatTheme.surface2,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: isUnread ? ChatTheme.accent1.withOpacity(0.3) : ChatTheme.surface3),
        ),
        child: Row(
          children: [
            CircleAvatar(
              radius: 24,
              backgroundColor: ChatTheme.surface3,
              child: Text(chat['username'][0].toUpperCase(),
                  style: TextStyle(color: ChatTheme.accent1, fontSize: 18)),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Text(
                        profile['name'] ?? chat['username'],
                        style: TextStyle(
                          color: ChatTheme.textPrimary,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      if (isUnread)
                        Container(
                          margin: const EdgeInsets.only(left: 8),
                          width: 8,
                          height: 8,
                          decoration: BoxDecoration(
                            color: ChatTheme.accent1,
                            shape: BoxShape.circle,
                          ),
                        ),
                    ],
                  ),
                  if (lastMsg != null)
                    Text(
                      '${lastMsg['sender'] == widget.username ? "You: " : ""}${lastMsg['message'] ?? ''}',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        color: isUnread ? ChatTheme.textSecondary : ChatTheme.textMuted,
                        fontSize: 12,
                        fontWeight: isUnread ? FontWeight.w500 : FontWeight.normal,
                      ),
                    ),
                ],
              ),
            ),
            if (lastMsg != null)
              Text(
                _formatTime(lastMsg['timestamp']),
                style: TextStyle(color: ChatTheme.textMuted, fontSize: 10),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildChatHeader() {
    final profile = _privateChats.firstWhere(
      (c) => c['username'] == _selectedUser,
      orElse: () => ({'profile': {}}),
    )['profile'] ?? {};
    
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: ChatTheme.surface,
        border: Border(bottom: BorderSide(color: ChatTheme.surface2)),
      ),
      child: Row(
        children: [
          IconButton(
            icon: const Icon(Icons.arrow_back_rounded, color: ChatTheme.textPrimary),
            onPressed: () => setState(() {
              _selectedUser = null;
              _privateReplyTo = null;
            }),
          ),
          CircleAvatar(
            radius: 20,
            backgroundColor: ChatTheme.surface3,
            child: Text(_selectedUser![0].toUpperCase(),
                style: TextStyle(color: ChatTheme.accent1, fontSize: 16)),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  profile['name'] ?? _selectedUser!,
                  style: TextStyle(color: ChatTheme.textPrimary, fontWeight: FontWeight.w600),
                ),
                if (profile['bio'] != null && profile['bio'].isNotEmpty)
                  Text(
                    profile['bio'],
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(color: ChatTheme.textMuted, fontSize: 10),
                  ),
              ],
            ),
          ),
          // Indikator private - PERSEGI PANJANG SETENGAH KOTAK
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              color: ChatTheme.accent2.withOpacity(0.15),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: ChatTheme.accent2.withOpacity(0.3)),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.lock_rounded, color: ChatTheme.accent2, size: 12),
                const SizedBox(width: 4),
                Text('PRIVATE', style: TextStyle(color: ChatTheme.accent2, fontSize: 9, fontWeight: FontWeight.w600)),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPrivateMessageBubble(dynamic msg) {
    final isMe = msg['fromMe'] == true;
    final replyTo = msg['replyTo'];
    
    return GestureDetector(
      onLongPress: () {
        setState(() {
          _privateReplyTo = {
            'id': msg['id'],
            'sender': msg['sender'],
            'message': msg['message'],
          };
        });
      },
      child: Container(
        margin: EdgeInsets.only(
          left: isMe ? 60 : 12,
          right: isMe ? 12 : 60,
          top: 8,
          bottom: 8,
        ),
        child: Column(
          crossAxisAlignment: isMe ? CrossAxisAlignment.end : CrossAxisAlignment.start,
          children: [
            // Reply Preview
            if (replyTo != null)
              Container(
                margin: const EdgeInsets.only(bottom: 6),
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: ChatTheme.surface3,
                  borderRadius: BorderRadius.circular(8),
                  border: Border(left: BorderSide(color: isMe ? ChatTheme.accent2 : ChatTheme.accent1, width: 3)),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Replying to @${replyTo['sender']}',
                      style: TextStyle(color: isMe ? ChatTheme.accent2 : ChatTheme.accent1, fontSize: 10),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      replyTo['message'] ?? '',
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(color: ChatTheme.textMuted, fontSize: 11),
                    ),
                  ],
                ),
              ),
            // Main Message
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
              decoration: BoxDecoration(
                color: isMe ? ChatTheme.accent2.withOpacity(0.2) : ChatTheme.surface2,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: isMe ? ChatTheme.accent2.withOpacity(0.3) : ChatTheme.surface3),
              ),
              child: Text(
                msg['message'] ?? '',
                style: TextStyle(
                  color: isMe ? ChatTheme.accent1 : ChatTheme.textPrimary,
                  fontSize: 13,
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.only(left: 8, right: 8, top: 4),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Indikator encrypted - PERSEGI PANJANG
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
                    decoration: BoxDecoration(
                      color: ChatTheme.accent2.withOpacity(0.15),
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.lock_outline_rounded, color: ChatTheme.accent2, size: 8),
                        const SizedBox(width: 2),
                        Text('E2EE', style: TextStyle(color: ChatTheme.accent2, fontSize: 7)),
                      ],
                    ),
                  ),
                  const SizedBox(width: 4),
                  Text(
                    _formatTime(msg['timestamp']),
                    style: TextStyle(color: ChatTheme.textMuted, fontSize: 9),
                  ),
                  if (isMe && msg['read'] == true)
                    const Padding(
                      padding: EdgeInsets.only(left: 4),
                      child: Icon(Icons.done_all_rounded, color: ChatTheme.accent1, size: 10),
                    ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ==================== REPLY PREVIEW BAR ====================
  
  Widget _buildReplyPreviewBar({required bool isGlobal}) {
    final replyData = isGlobal ? _globalReplyTo : _privateReplyTo;
    if (replyData == null) return const SizedBox();
    
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: ChatTheme.surface2,
        borderRadius: BorderRadius.circular(12),
        border: Border(left: BorderSide(color: ChatTheme.accent1, width: 3)),
      ),
      child: Row(
        children: [
          Icon(Icons.reply_rounded, color: ChatTheme.accent1, size: 16),
          const SizedBox(width: 8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Replying to @${replyData['sender']}',
                  style: TextStyle(color: ChatTheme.accent1, fontSize: 10),
                ),
                Text(
                  replyData['message'] ?? '',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(color: ChatTheme.textSecondary, fontSize: 11),
                ),
              ],
            ),
          ),
          GestureDetector(
            onTap: () => setState(() {
              if (isGlobal) _globalReplyTo = null;
              else _privateReplyTo = null;
            }),
            child: Icon(Icons.close_rounded, color: ChatTheme.textMuted, size: 16),
          ),
        ],
      ),
    );
  }

  // ==================== INPUT BAR ====================
  
  Widget _buildInputBar({
    required TextEditingController controller,
    required VoidCallback onSend,
    required String hint,
    required bool isGlobal,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: ChatTheme.surface,
        boxShadow: [
          BoxShadow(color: ChatTheme.shadowHeavy, blurRadius: 8, offset: const Offset(0, -2)),
        ],
      ),
      child: Row(
        children: [
          Expanded(
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              decoration: BoxDecoration(
                color: ChatTheme.surface2,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: ChatTheme.surface3),
              ),
              child: TextField(
                controller: controller,
                style: TextStyle(color: ChatTheme.textPrimary),
                decoration: InputDecoration(
                  hintText: hint,
                  hintStyle: TextStyle(color: ChatTheme.textMuted),
                  border: InputBorder.none,
                ),
                onSubmitted: (_) => onSend(),
              ),
            ),
          ),
          const SizedBox(width: 8),
          GestureDetector(
            onTap: onSend,
            child: Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                gradient: const LinearGradient(colors: [ChatTheme.accent1, ChatTheme.accent2]),
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Icon(Icons.send_rounded, color: Colors.white, size: 20),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState(String title, String message) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.chat_bubble_outline_rounded, color: ChatTheme.textMuted, size: 48),
          const SizedBox(height: 16),
          Text(title, style: TextStyle(color: ChatTheme.textSecondary, fontSize: 16)),
          const SizedBox(height: 8),
          Text(message, style: TextStyle(color: ChatTheme.textMuted, fontSize: 12)),
        ],
      ),
    );
  }
}

// ==================== SEARCH USER SHEET ====================

class _SearchUserSheet extends StatefulWidget {
  final String sessionKey;
  final String currentUsername;
  final Function(Map<String, dynamic>) onSelectUser;
  
  const _SearchUserSheet({
    required this.sessionKey,
    required this.currentUsername,
    required this.onSelectUser,
  });

  @override
  State<_SearchUserSheet> createState() => _SearchUserSheetState();
}

class _SearchUserSheetState extends State<_SearchUserSheet> {
  final TextEditingController _searchCtrl = TextEditingController();
  List<dynamic> _results = [];
  bool _loading = false;
  Timer? _debounce;

  @override
  void dispose() {
    _debounce?.cancel();
    _searchCtrl.dispose();
    super.dispose();
  }

  void _search(String query) {
    _debounce?.cancel();
    _debounce = Timer(const Duration(milliseconds: 500), () async {
      if (query.length < 2) {
        setState(() => _results = []);
        return;
      }
      setState(() => _loading = true);
      try {
        final prefs = await SharedPreferences.getInstance();
        final sessionKey = prefs.getString('session_key') ?? widget.sessionKey;
        final res = await http.get(Uri.parse('$_kBase/chat/search-users?key=$sessionKey&q=$query'));
        if (res.statusCode == 200) {
          final data = jsonDecode(res.body);
          if (data['valid'] == true) {
            setState(() => _results = data['users'] ?? []);
          }
        }
      } catch (e) { print('Search error: $e'); }
      setState(() => _loading = false);
    });
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
      child: ClipRRect(
        borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
        child: Container(
          height: MediaQuery.of(context).size.height * 0.7,
          decoration: BoxDecoration(
            color: ChatTheme.surface,
            boxShadow: [BoxShadow(color: ChatTheme.shadowHeavy, blurRadius: 20)],
          ),
          child: Column(
            children: [
              // Handle bar
              Container(
                margin: const EdgeInsets.only(top: 12),
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: ChatTheme.textMuted,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              // Header
              Padding(
                padding: const EdgeInsets.all(16),
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        gradient: const LinearGradient(colors: [ChatTheme.accent1, ChatTheme.accent2]),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: const Icon(Icons.search_rounded, color: Colors.white, size: 22),
                    ),
                    const SizedBox(width: 14),
                    const Expanded(
                      child: Text(
                        'CARI USER',
                        style: TextStyle(
                          color: ChatTheme.textPrimary,
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          letterSpacing: 1,
                        ),
                      ),
                    ),
                    GestureDetector(
                      onTap: () => Navigator.pop(context),
                      child: Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: ChatTheme.surface2,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: const Icon(Icons.close_rounded, color: ChatTheme.textMuted, size: 20),
                      ),
                    ),
                  ],
                ),
              ),
              // Search Field
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: TextField(
                  controller: _searchCtrl,
                  onChanged: _search,
                  style: TextStyle(color: ChatTheme.textPrimary),
                  decoration: InputDecoration(
                    hintText: 'Masukkan username...',
                    hintStyle: TextStyle(color: ChatTheme.textMuted),
                    prefixIcon: Icon(Icons.person_search_rounded, color: ChatTheme.accent1),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide(color: ChatTheme.surface3),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide(color: ChatTheme.accent1),
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 16),
              // Results
              Expanded(
                child: _loading
                    ? const Center(child: CircularProgressIndicator(color: ChatTheme.accent1))
                    : _results.isEmpty
                        ? Center(
                            child: Column(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(Icons.person_off_rounded, color: ChatTheme.textMuted, size: 48),
                                const SizedBox(height: 12),
                                Text('Tidak ada user ditemukan', style: TextStyle(color: ChatTheme.textSecondary)),
                              ],
                            ),
                          )
                        : ListView.builder(
                            padding: const EdgeInsets.symmetric(horizontal: 16),
                            itemCount: _results.length,
                            itemBuilder: (ctx, i) {
                              final user = _results[i];
                              final profile = user['profile'] ?? {};
                              return GestureDetector(
                                onTap: () => widget.onSelectUser(user),
                                child: Container(
                                  margin: const EdgeInsets.only(bottom: 8),
                                  padding: const EdgeInsets.all(12),
                                  decoration: BoxDecoration(
                                    color: ChatTheme.surface2,
                                    borderRadius: BorderRadius.circular(12),
                                    border: Border.all(color: ChatTheme.surface3),
                                  ),
                                  child: Row(
                                    children: [
                                      CircleAvatar(
                                        radius: 24,
                                        backgroundColor: ChatTheme.surface3,
                                        child: Text(user['username'][0].toUpperCase(),
                                            style: TextStyle(color: ChatTheme.accent1, fontSize: 18)),
                                      ),
                                      const SizedBox(width: 12),
                                      Expanded(
                                        child: Column(
                                          crossAxisAlignment: CrossAxisAlignment.start,
                                          children: [
                                            Text(
                                              profile['name'] ?? user['username'],
                                              style: TextStyle(
                                                color: ChatTheme.textPrimary,
                                                fontWeight: FontWeight.w600,
                                              ),
                                            ),
                                            if (profile['bio'] != null && profile['bio'].isNotEmpty)
                                              Text(
                                                profile['bio'],
                                                maxLines: 1,
                                                overflow: TextOverflow.ellipsis,
                                                style: TextStyle(color: ChatTheme.textMuted, fontSize: 11),
                                              ),
                                          ],
                                        ),
                                      ),
                                      Container(
                                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                                        decoration: BoxDecoration(
                                          color: ChatTheme.accent2.withOpacity(0.1),
                                          borderRadius: BorderRadius.circular(8),
                                        ),
                                        child: Text(
                                          user['role']?.toUpperCase() ?? 'MEMBER',
                                          style: TextStyle(color: ChatTheme.accent2, fontSize: 9),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              );
                            },
                          ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}