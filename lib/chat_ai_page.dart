// chat_ai_page.dart — Fixed: auto-create session on open

import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;

class ChatAIPage extends StatefulWidget {
  final String sessionKey;

  const ChatAIPage({super.key, required this.sessionKey});

  @override
  State<ChatAIPage> createState() => _ChatAIPageState();
}

class _ChatAIPageState extends State<ChatAIPage> {
  final TextEditingController _messageController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  final List<ChatMessage> _messages = [];
  bool _isLoading = false;
  bool _isInitializing = true;
  String? _currentSessionId;
  List<ChatSession> _chatSessions = [];
  bool _showSessionList = false;

  final String _baseUrl = 'http://saitama.omdhancivok.my.id:2001';

  @override
  void initState() {
    super.initState();
    _initChat();
  }

  @override
  void dispose() {
    _messageController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  // Auto-create session langsung saat buka
  Future<void> _initChat() async {
    setState(() => _isInitializing = true);
    await _loadChatSessions();

    // Kalau sudah ada session, pakai yang terakhir
    if (_chatSessions.isNotEmpty) {
      await _loadChatSession(_chatSessions.first.sessionId);
    } else {
      // Belum ada session sama sekali, buat baru otomatis
      await _createNewSession(silent: true);
    }

    setState(() => _isInitializing = false);
  }

  Future<void> _loadChatSessions() async {
    try {
      final response = await http.get(
        Uri.parse('$_baseUrl/api/tools/chat/list?key=${widget.sessionKey}'),
      ).timeout(const Duration(seconds: 10));

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (data['valid'] == true) {
          setState(() {
            _chatSessions = (data['chatHistoryList'] as List)
                .map((s) => ChatSession.fromJson(s))
                .toList();
          });
        }
      }
    } catch (e) {
      // silent fail, tetap lanjut
    }
  }

  Future<void> _createNewSession({bool silent = false}) async {
    try {
      final response = await http.get(
        Uri.parse('$_baseUrl/api/tools/chat/new-session?key=${widget.sessionKey}'),
      ).timeout(const Duration(seconds: 10));

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (data['valid'] == true) {
          setState(() {
            _currentSessionId = data['sessionId'];
            _messages.clear();
            _showSessionList = false;
          });
          await _loadChatSessions();
          if (!silent) _showSnackBar('Session baru dibuat');
        } else {
          if (!silent) _showSnackBar('Gagal membuat session', isError: true);
        }
      }
    } catch (e) {
      if (!silent) _showSnackBar('Koneksi gagal', isError: true);
    }
  }

  Future<void> _loadChatSession(String sessionId) async {
    try {
      final response = await http.get(
        Uri.parse('$_baseUrl/api/tools/chat/history?key=${widget.sessionKey}&session=$sessionId'),
      ).timeout(const Duration(seconds: 10));

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (data['valid'] == true) {
          final history = data['chatHistory'] as List;
          setState(() {
            _currentSessionId = sessionId;
            _messages.clear();
            for (var msg in history) {
              _messages.add(ChatMessage(
                text: msg['message'] ?? '',
                isAI: msg['isAI'] == true,
                timestamp: DateTime.tryParse(msg['timestamp'] ?? '') ?? DateTime.now(),
              ));
            }
            _showSessionList = false;
          });
          _scrollToBottom();
        }
      }
    } catch (e) {
      _showSnackBar('Gagal load riwayat chat', isError: true);
    }
  }

  Future<void> _deleteChatSession(String sessionId) async {
    try {
      final response = await http.get(
        Uri.parse('$_baseUrl/api/tools/chat/delete?key=${widget.sessionKey}&session=$sessionId'),
      ).timeout(const Duration(seconds: 10));

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (data['valid'] == true) {
          _showSnackBar('Session dihapus');
          await _loadChatSessions();
          if (_currentSessionId == sessionId) {
            setState(() {
              _currentSessionId = null;
              _messages.clear();
            });
            // Auto buat session baru setelah hapus
            await _createNewSession(silent: true);
          }
        }
      }
    } catch (e) {
      _showSnackBar('Gagal hapus session', isError: true);
    }
  }

  Future<void> _sendMessage() async {
    final text = _messageController.text.trim();
    if (text.isEmpty || _isLoading) return;

    // Auto buat session jika belum ada
    if (_currentSessionId == null) {
      await _createNewSession(silent: true);
      if (_currentSessionId == null) {
        _showSnackBar('Gagal membuat session, coba lagi', isError: true);
        return;
      }
    }

    setState(() {
      _messages.add(ChatMessage(text: text, isAI: false, timestamp: DateTime.now()));
      _isLoading = true;
    });
    _messageController.clear();
    _scrollToBottom();

    try {
      final response = await http.get(
        Uri.parse(
          '$_baseUrl/api/tools/chat/send?key=${widget.sessionKey}&session=$_currentSessionId&message=${Uri.encodeComponent(text)}',
        ),
      ).timeout(const Duration(seconds: 30));

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (data['status'] == true) {
          setState(() {
            _messages.add(ChatMessage(
              text: data['data']['message'] ?? '',
              isAI: true,
              timestamp: DateTime.now(),
            ));
          });
          _scrollToBottom();
        } else {
          _showSnackBar('AI tidak merespons, coba lagi', isError: true);
        }
      } else {
        _showSnackBar('Server error: ${response.statusCode}', isError: true);
      }
    } catch (e) {
      _showSnackBar('Koneksi timeout, coba lagi', isError: true);
    } finally {
      setState(() => _isLoading = false);
    }
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 250),
          curve: Curves.easeOut,
        );
      }
    });
  }

  void _showSnackBar(String message, {bool isError = false}) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Text(message),
      backgroundColor: isError ? Colors.red.shade800 : const Color(0xFF0ea5e9),
      behavior: SnackBarBehavior.floating,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      duration: const Duration(seconds: 2),
    ));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0b1120),
      appBar: AppBar(
        backgroundColor: const Color(0xFF111827),
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Chat AI',
                style: TextStyle(color: Colors.lightBlue, fontSize: 16, fontWeight: FontWeight.bold)),
            if (_currentSessionId != null)
              Text(
                'Session: ${_currentSessionId!.length > 12 ? _currentSessionId!.substring(0, 12) + '...' : _currentSessionId}',
                style: TextStyle(color: Colors.lightBlue.withOpacity(0.6), fontSize: 11),
              ),
          ],
        ),
        iconTheme: const IconThemeData(color: Colors.lightBlue),
        actions: [
          IconButton(
            icon: const Icon(Icons.history, color: Colors.lightBlue),
            tooltip: 'Riwayat Session',
            onPressed: () => setState(() => _showSessionList = !_showSessionList),
          ),
          IconButton(
            icon: const Icon(Icons.add_comment_outlined, color: Colors.lightBlue),
            tooltip: 'Session Baru',
            onPressed: () => _createNewSession(),
          ),
        ],
      ),
      body: _isInitializing
          ? const Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  CircularProgressIndicator(color: Colors.lightBlue),
                  SizedBox(height: 16),
                  Text('Memulai Chat AI...', style: TextStyle(color: Colors.lightBlue)),
                ],
              ),
            )
          : _showSessionList
              ? _buildSessionList()
              : _buildChatInterface(),
    );
  }

  Widget _buildSessionList() {
    return Column(
      children: [
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          color: const Color(0xFF111827),
          child: Row(
            children: [
              const Text('Riwayat Chat',
                  style: TextStyle(color: Colors.lightBlue, fontSize: 16, fontWeight: FontWeight.bold)),
              const Spacer(),
              TextButton.icon(
                onPressed: () => _createNewSession(),
                icon: const Icon(Icons.add, color: Colors.lightBlue, size: 16),
                label: const Text('Baru', style: TextStyle(color: Colors.lightBlue)),
              ),
            ],
          ),
        ),
        Expanded(
          child: _chatSessions.isEmpty
              ? const Center(
                  child: Text('Belum ada riwayat chat',
                      style: TextStyle(color: Colors.lightBlue)))
              : ListView.builder(
                  itemCount: _chatSessions.length,
                  itemBuilder: (context, index) {
                    final session = _chatSessions[index];
                    final isActive = session.sessionId == _currentSessionId;
                    return Container(
                      margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                      decoration: BoxDecoration(
                        color: isActive
                            ? Colors.lightBlue.withOpacity(0.15)
                            : const Color(0xFF1e2d45),
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(
                          color: isActive ? Colors.lightBlue : Colors.transparent,
                        ),
                      ),
                      child: ListTile(
                        leading: Icon(
                          Icons.chat_bubble_outline,
                          color: isActive ? Colors.lightBlue : Colors.lightBlue.withOpacity(0.5),
                        ),
                        title: Text(
                          'Session ${index + 1}',
                          style: TextStyle(
                            color: isActive ? Colors.lightBlue : Colors.white,
                            fontWeight: isActive ? FontWeight.bold : FontWeight.normal,
                          ),
                        ),
                        subtitle: Text(
                          '${session.messageCount} pesan',
                          style: TextStyle(color: Colors.lightBlue.withOpacity(0.6), fontSize: 11),
                        ),
                        trailing: IconButton(
                          icon: const Icon(Icons.delete_outline, color: Colors.redAccent, size: 20),
                          onPressed: () => _deleteChatSession(session.sessionId),
                        ),
                        onTap: () => _loadChatSession(session.sessionId),
                      ),
                    );
                  },
                ),
        ),
      ],
    );
  }

  Widget _buildChatInterface() {
    return Column(
      children: [
        Expanded(
          child: _messages.isEmpty
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.smart_toy_outlined, size: 64, color: Colors.lightBlue.withOpacity(0.4)),
                      const SizedBox(height: 16),
                      Text(
                        'Halo! Ada yang bisa saya bantu?',
                        style: TextStyle(color: Colors.lightBlue.withOpacity(0.7), fontSize: 16),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Ketik pesan untuk mulai chat',
                        style: TextStyle(color: Colors.lightBlue.withOpacity(0.4), fontSize: 12),
                      ),
                    ],
                  ),
                )
              : ListView.builder(
                  controller: _scrollController,
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 16),
                  itemCount: _messages.length,
                  itemBuilder: (context, index) => _buildMessageBubble(_messages[index]),
                ),
        ),
        if (_isLoading)
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Colors.lightBlue.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const SizedBox(
                        width: 14,
                        height: 14,
                        child: CircularProgressIndicator(color: Colors.lightBlue, strokeWidth: 2),
                      ),
                      const SizedBox(width: 8),
                      Text('AI sedang mengetik...',
                          style: TextStyle(color: Colors.lightBlue.withOpacity(0.8), fontSize: 12)),
                    ],
                  ),
                ),
              ],
            ),
          ),
        _buildMessageInput(),
      ],
    );
  }

  Widget _buildMessageBubble(ChatMessage message) {
    final isUser = !message.isAI;
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      child: Row(
        mainAxisAlignment: isUser ? MainAxisAlignment.end : MainAxisAlignment.start,
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          if (!isUser) ...[
            Container(
              width: 32,
              height: 32,
              decoration: const BoxDecoration(
                color: Color(0xFF2563eb),
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.smart_toy, color: Colors.white, size: 16),
            ),
            const SizedBox(width: 8),
          ],
          Flexible(
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
              decoration: BoxDecoration(
                color: isUser ? Colors.lightBlue : const Color(0xFF1e2d45),
                borderRadius: BorderRadius.only(
                  topLeft: const Radius.circular(16),
                  topRight: const Radius.circular(16),
                  bottomLeft: isUser ? const Radius.circular(16) : const Radius.circular(4),
                  bottomRight: isUser ? const Radius.circular(4) : const Radius.circular(16),
                ),
              ),
              child: Text(
                message.text,
                style: TextStyle(
                  color: isUser ? Colors.black : Colors.white,
                  fontSize: 14,
                ),
              ),
            ),
          ),
          if (isUser) ...[
            const SizedBox(width: 8),
            Container(
              width: 32,
              height: 32,
              decoration: const BoxDecoration(
                color: Colors.lightBlue,
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.person, color: Colors.black, size: 16),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildMessageInput() {
    return Container(
      padding: const EdgeInsets.fromLTRB(12, 8, 12, 12),
      decoration: BoxDecoration(
        color: const Color(0xFF111827),
        border: Border(top: BorderSide(color: Colors.lightBlue.withOpacity(0.2))),
      ),
      child: Row(
        children: [
          Expanded(
            child: TextField(
              controller: _messageController,
              style: const TextStyle(color: Colors.white),
              maxLines: null,
              textInputAction: TextInputAction.send,
              onSubmitted: (_) => _sendMessage(),
              decoration: InputDecoration(
                hintText: 'Ketik pesan...',
                hintStyle: TextStyle(color: Colors.white.withOpacity(0.3)),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(24),
                  borderSide: BorderSide.none,
                ),
                filled: true,
                fillColor: const Color(0xFF1e2d45),
                contentPadding: const EdgeInsets.symmetric(horizontal: 18, vertical: 10),
              ),
            ),
          ),
          const SizedBox(width: 8),
          GestureDetector(
            onTap: _isLoading ? null : _sendMessage,
            child: Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                color: _isLoading ? Colors.grey : Colors.lightBlue,
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.send_rounded, color: Colors.black, size: 20),
            ),
          ),
        ],
      ),
    );
  }
}

class ChatMessage {
  final String text;
  final bool isAI;
  final DateTime timestamp;
  ChatMessage({required this.text, required this.isAI, required this.timestamp});
}

class ChatSession {
  final String sessionId;
  final String username;
  final DateTime lastModified;
  final int messageCount;
  final String preview;

  ChatSession({
    required this.sessionId,
    required this.username,
    required this.lastModified,
    required this.messageCount,
    required this.preview,
  });

  factory ChatSession.fromJson(Map<String, dynamic> json) {
    return ChatSession(
      sessionId: json['sessionId'] ?? '',
      username: json['username'] ?? '',
      lastModified: DateTime.tryParse(json['lastModified'] ?? '') ?? DateTime.now(),
      messageCount: json['messageCount'] ?? 0,
      preview: json['preview'] ?? '',
    );
  }
}
