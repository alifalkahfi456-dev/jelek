import 'dart:convert';
import 'dart:async';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:image_picker/image_picker.dart';
import 'package:mime/mime.dart';
import 'app_config.dart';

class PrivateChatPage extends StatefulWidget {
  final String username;
  final String targetUsername;
  final String sessionKey;
  final String role;

  const PrivateChatPage({
    super.key,
    required this.username,
    required this.targetUsername,
    required this.sessionKey,
    required this.role,
  });

  @override
  State<PrivateChatPage> createState() => _PrivateChatPageState();
}

class _PrivateChatPageState extends State<PrivateChatPage> with TickerProviderStateMixin {
  final _messageCtrl = TextEditingController();
  final _scrollCtrl = ScrollController();
  final _focusNode = FocusNode();

  List<Map<String, dynamic>> _messages = [];
  bool _loading = true;
  bool _sending = false;

  File? _selectedMedia;
  String? _mediaType;
  bool _isMediaLoading = false;

  late AnimationController _fadeAnim;
  StreamSubscription? _sseSubscription;
  final _imagePicker = ImagePicker();

  // Colors
  static const Color bgDark = Color(0xFF03080f);
  static const Color deepBlue = Color(0xFF060d18);
  static const Color cardBlue = Color(0xFF091525);
  static const Color accentCyan = Color(0xFF00b0ff);
  static const Color neonGreen = Color(0xFF00ff41);

  @override
  void initState() {
    super.initState();
    _fadeAnim = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600),
    )..forward();
    _loadMessages();
    _subscribeToUpdates();
  }

  @override
  void dispose() {
    _sseSubscription?.cancel();
    _fadeAnim.dispose();
    _messageCtrl.dispose();
    _scrollCtrl.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  Future<void> _loadMessages() async {
    try {
      final apiUrl = kBaseUrl;
      final uri = Uri.parse('$apiUrl/api/chatv2/private/messages').replace(
        queryParameters: {
          'key': widget.sessionKey,
          'with': widget.targetUsername,
        },
      );

      final response = await http.get(uri);

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (data['success'] == true) {
          final messages = List<Map<String, dynamic>>.from(data['messages'] ?? []);
          if (mounted) {
            setState(() {
              _messages = messages;
              _loading = false;
            });
            _scrollToBottom();
          }
        }
      }
    } catch (e) {
      if (mounted) {
        setState(() => _loading = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error loading messages: $e')),
        );
      }
    }
  }

  void _subscribeToUpdates() async {
    try {
      final apiUrl = kBaseUrl;
      final uri = Uri.parse('$apiUrl/api/chatv2/private/stream').replace(
        queryParameters: {
          'key': widget.sessionKey,
          'with': widget.targetUsername,
        },
      );

      final request = http.Request('GET', uri);
      final response = await http.Client().send(request);

      if (response.statusCode == 200) {
        _sseSubscription = response.stream
            .transform(utf8.decoder)
            .transform(const LineSplitter())
            .listen((line) {
          if (line.startsWith('data: ')) {
            try {
              final data = jsonDecode(line.substring(6));
              if (data['type'] == 'new_message' && mounted) {
                setState(() {
                  _messages.add(data['message']);
                });
                _scrollToBottom();
              } else if (data['type'] == 'delete_message' && mounted) {
                setState(() {
                  _messages.removeWhere((m) => m['id'] == data['id']);
                });
              }
            } catch (_) {}
          }
        });
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error connecting to chat: $e')),
        );
      }
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

  Future<void> _sendMessage() async {
    final text = _messageCtrl.text.trim();
    if (text.isEmpty && _selectedMedia == null) return;

    setState(() => _sending = true);

    try {
      final apiUrl = kBaseUrl;
      final uri = Uri.parse('$apiUrl/api/chatv2/private/send').replace(
        queryParameters: {'key': widget.sessionKey},
      );

      String? mediaBase64;
      if (_selectedMedia != null) {
        final bytes = await _selectedMedia!.readAsBytes();
        mediaBase64 = base64Encode(bytes);
      }

      final response = await http.post(
        uri,
        headers: {
          'Content-Type': 'application/json',
        },
        body: jsonEncode({
          'to': widget.targetUsername,
          'text': text,
          'mediaType': _mediaType,
          'mediaBase64': mediaBase64,
          'replyTo': null,
        }),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (data['success'] == true) {
          _messageCtrl.clear();
          setState(() {
            _selectedMedia = null;
            _mediaType = null;
          });
          _focusNode.unfocus();
        } else {
          _showError('Failed to send message');
        }
      } else {
        _showError('Error sending message');
      }
    } catch (e) {
      _showError('Error: $e');
    } finally {
      if (mounted) setState(() => _sending = false);
    }
  }

  Future<void> _pickMedia(bool isImage) async {
    try {
      XFile? pickedFile;

      if (isImage) {
        pickedFile = await _imagePicker.pickImage(source: ImageSource.gallery);
      } else {
        pickedFile = await _imagePicker.pickVideo(source: ImageSource.gallery);
      }

      if (pickedFile != null) {
        setState(() => _isMediaLoading = true);

        final file = File(pickedFile.path);
        final bytes = await file.readAsBytes();
        final base64 = base64Encode(bytes);
        final mimeType = lookupMimeType(pickedFile.path) ?? 'application/octet-stream';

        setState(() {
          _selectedMedia = file;
          _mediaType = mimeType;
        });

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Media selected: ${pickedFile.name}'),
              backgroundColor: Colors.green.shade800,
            ),
          );
        }

        setState(() => _isMediaLoading = false);
      }
    } catch (e) {
      _showError('Error picking media: $e');
      setState(() => _isMediaLoading = false);
    }
  }

  Future<void> _deleteMessage(String msgId) async {
    try {
      final apiUrl = kBaseUrl;
      final uri = Uri.parse('$apiUrl/api/chatv2/private/delete').replace(
        queryParameters: {'key': widget.sessionKey},
      );

      final response = await http.delete(
        uri,
        headers: {
          'Content-Type': 'application/json',
        },
        body: jsonEncode({
          'msgId': msgId,
          'with': widget.targetUsername,
        }),
      );

      if (response.statusCode != 200) {
        _showError('Cannot delete message');
      }
    } catch (e) {
      _showError('Error: $e');
    }
  }

  void _showError(String msg) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(msg), backgroundColor: Colors.red.shade800),
    );
  }

  void _showMessageOptions(Map<String, dynamic> msg) {
    showModalBottomSheet(
      context: context,
      backgroundColor: cardBlue,
      builder: (context) => Container(
        padding: const EdgeInsets.all(16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.copy, color: accentCyan),
              title: const Text('Copy', style: TextStyle(color: Colors.white)),
              onTap: () {
                Navigator.pop(context);
                final text = msg['text'] ?? '';
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Copied to clipboard')),
                );
              },
            ),
            if (widget.username == msg['from'] || widget.role == 'owner')
              ListTile(
                leading: const Icon(Icons.delete, color: Colors.red),
                title: const Text('Delete', style: TextStyle(color: Colors.white)),
                onTap: () {
                  Navigator.pop(context);
                  _deleteMessage(msg['id']);
                },
              ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: bgDark,
      appBar: AppBar(
        backgroundColor: deepBlue,
        elevation: 1,
        shadowColor: accentCyan.withOpacity(0.3),
        leading: BackButton(color: accentCyan, onPressed: () => Navigator.pop(context)),
        title: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text(
              'PRIVATE CHAT',
              style: TextStyle(
                color: accentCyan,
                fontSize: 11,
                fontWeight: FontWeight.w900,
                letterSpacing: 2,
              ),
            ),
            Text(
              widget.targetUsername,
              style: const TextStyle(
                color: neonGreen,
                fontSize: 12,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
        centerTitle: true,
      ),
      body: FadeTransition(
        opacity: _fadeAnim,
        child: Column(
          children: [
            // Messages
            Expanded(
              child: _loading
                  ? Center(
                      child: CircularProgressIndicator(
                        valueColor: AlwaysStoppedAnimation(accentCyan),
                      ),
                    )
                  : _messages.isEmpty
                      ? Center(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(
                                Icons.chat_bubble_outline,
                                size: 48,
                                color: accentCyan.withOpacity(0.5),
                              ),
                              const SizedBox(height: 16),
                              Text(
                                'No messages yet',
                                style: TextStyle(
                                  color: Colors.white.withOpacity(0.5),
                                  fontSize: 13,
                                ),
                              ),
                              const SizedBox(height: 8),
                              Text(
                                'Start a conversation',
                                style: TextStyle(
                                  color: Colors.white.withOpacity(0.3),
                                  fontSize: 11,
                                ),
                              ),
                            ],
                          ),
                        )
                      : ListView.builder(
                          controller: _scrollCtrl,
                          padding: const EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 16,
                          ),
                          itemCount: _messages.length,
                          itemBuilder: (context, index) {
                            final msg = _messages[index];
                            final isOwn = msg['from'] == widget.username;

                            return GestureDetector(
                              onLongPress: () => _showMessageOptions(msg),
                              child: Container(
                                margin: const EdgeInsets.only(bottom: 12),
                                child: Row(
                                  mainAxisAlignment: isOwn
                                      ? MainAxisAlignment.end
                                      : MainAxisAlignment.start,
                                  children: [
                                    if (!isOwn)
                                      Container(
                                        width: 32,
                                        height: 32,
                                        margin: const EdgeInsets.only(right: 8),
                                        decoration: BoxDecoration(
                                          color: accentCyan.withOpacity(0.2),
                                          shape: BoxShape.circle,
                                          border: Border.all(
                                            color: accentCyan.withOpacity(0.5),
                                          ),
                                        ),
                                        child: Center(
                                          child: Text(
                                            widget.targetUsername
                                                    .substring(0, 1)
                                                    .toUpperCase() ??
                                                '?',
                                            style: const TextStyle(
                                              color: accentCyan,
                                              fontSize: 12,
                                              fontWeight: FontWeight.bold,
                                            ),
                                          ),
                                        ),
                                      ),
                                    Flexible(
                                      child: Container(
                                        padding: const EdgeInsets.symmetric(
                                          horizontal: 12,
                                          vertical: 10,
                                        ),
                                        decoration: BoxDecoration(
                                          color: isOwn
                                              ? accentCyan.withOpacity(0.15)
                                              : cardBlue,
                                          border: Border.all(
                                            color: isOwn
                                                ? accentCyan.withOpacity(0.3)
                                                : Colors.white.withOpacity(0.1),
                                            width: 1,
                                          ),
                                          borderRadius: BorderRadius.circular(8),
                                        ),
                                        child: Column(
                                          crossAxisAlignment:
                                              CrossAxisAlignment.start,
                                          children: [
                                            Text(
                                              isOwn ? 'You' : widget.targetUsername,
                                              style: TextStyle(
                                                color: isOwn ? accentCyan : neonGreen,
                                                fontSize: 11,
                                                fontWeight: FontWeight.bold,
                                                letterSpacing: 1,
                                              ),
                                            ),
                                            const SizedBox(height: 4),
                                            if (msg['mediaBase64'] != null && msg['mediaBase64'].toString().isNotEmpty)
                                              Container(
                                                margin: const EdgeInsets.only(top: 8, bottom: 8),
                                                constraints: const BoxConstraints(maxWidth: 250),
                                                child: ClipRRect(
                                                  borderRadius: BorderRadius.circular(6),
                                                  child: Image.memory(
                                                    base64Decode(msg['mediaBase64']),
                                                    fit: BoxFit.cover,
                                                  ),
                                                ),
                                              ),
                                            if ((msg['text'] ?? '').toString().isNotEmpty)
                                              Text(
                                                msg['text'] ?? '',
                                                style: TextStyle(
                                                  color: Colors.white
                                                      .withOpacity(0.9),
                                                  fontSize: 13,
                                                ),
                                              ),
                                            const SizedBox(height: 4),
                                            Text(
                                              msg['time'] ?? '',
                                              style: TextStyle(
                                                color: Colors.white
                                                    .withOpacity(0.4),
                                                fontSize: 10,
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                    ),
                                    if (isOwn)
                                      Container(
                                        width: 32,
                                        height: 32,
                                        margin: const EdgeInsets.only(left: 8),
                                        decoration: BoxDecoration(
                                          color: accentCyan.withOpacity(0.3),
                                          shape: BoxShape.circle,
                                          border: Border.all(
                                            color: accentCyan.withOpacity(0.7),
                                          ),
                                        ),
                                        child: const Center(
                                          child: Icon(
                                            Icons.check_circle,
                                            color: neonGreen,
                                            size: 16,
                                          ),
                                        ),
                                      ),
                                  ],
                                ),
                              ),
                            );
                          },
                        ),
            ),
            // Input
            Column(
              children: [
                if (_selectedMedia != null)
                  Container(
                    margin: const EdgeInsets.all(12),
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: cardBlue,
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: neonGreen.withOpacity(0.5)),
                    ),
                    child: Row(
                      children: [
                        Icon(
                          _mediaType?.contains('image') ?? false
                              ? Icons.image
                              : Icons.video_library,
                          color: neonGreen,
                          size: 20,
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            _selectedMedia!.path.split('/').last,
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 12,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        InkWell(
                          onTap: () => setState(() {
                            _selectedMedia = null;
                            _mediaType = null;
                          }),
                          child: const Icon(
                            Icons.close,
                            color: Colors.red,
                            size: 18,
                          ),
                        ),
                      ],
                    ),
                  ),
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: deepBlue,
                    border: Border(
                      top: BorderSide(
                        color: accentCyan.withOpacity(0.2),
                      ),
                    ),
                  ),
                  child: SafeArea(
                    child: Row(
                      children: [
                        IconButton(
                          icon: const Icon(Icons.image_rounded, color: accentCyan),
                          onPressed: _isMediaLoading ? null : () => _pickMedia(true),
                          tooltip: 'Pick image',
                        ),
                        IconButton(
                          icon: const Icon(Icons.videocam_rounded, color: accentCyan),
                          onPressed: _isMediaLoading ? null : () => _pickMedia(false),
                          tooltip: 'Pick video',
                        ),
                        Expanded(
                          child: TextField(
                            controller: _messageCtrl,
                            focusNode: _focusNode,
                            maxLines: 1,
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 13,
                            ),
                            decoration: InputDecoration(
                              hintText: 'Type message...',
                              hintStyle: TextStyle(
                                color: Colors.white.withOpacity(0.4),
                              ),
                              filled: true,
                              fillColor: cardBlue,
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(8),
                                borderSide: BorderSide(
                                  color: accentCyan.withOpacity(0.2),
                                ),
                              ),
                              enabledBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(8),
                                borderSide: BorderSide(
                                  color: accentCyan.withOpacity(0.2),
                                ),
                              ),
                              focusedBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(8),
                                borderSide: const BorderSide(
                                  color: accentCyan,
                                  width: 1.5,
                                ),
                              ),
                              contentPadding: const EdgeInsets.symmetric(
                                horizontal: 12,
                                vertical: 10,
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Container(
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              colors: [
                                accentCyan.withOpacity(0.8),
                                accentCyan.withOpacity(0.6),
                              ],
                            ),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Material(
                            color: Colors.transparent,
                            child: InkWell(
                              borderRadius: BorderRadius.circular(8),
                              onTap: _sending ? null : _sendMessage,
                              child: Padding(
                                padding: const EdgeInsets.all(10),
                                child: _sending
                                    ? const SizedBox(
                                        width: 20,
                                        height: 20,
                                        child: CircularProgressIndicator(
                                          strokeWidth: 2,
                                          valueColor: AlwaysStoppedAnimation(
                                              Colors.white),
                                        ),
                                      )
                                    : const Icon(
                                        Icons.send_rounded,
                                        color: Colors.white,
                                        size: 20,
                                      ),
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
