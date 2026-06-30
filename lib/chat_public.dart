// chat_public.dart - LENGKAP DENGAN GROUP CHAT & PRIVATE CHAT

import 'dart:convert';
import 'dart:io';
import 'dart:async';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:image_picker/image_picker.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:permission_handler/permission_handler.dart';

// ==================== COLORS ====================
const Color kBgDark      = Color(0xFF0A0E17);
const Color kBgCard      = Color(0xFF131A26);
const Color kBgCardLight = Color(0xFF1A2333);
const Color kBorderColor = Color(0xFF2A3442);
const Color kNeonBlue    = Color(0xFF00E5FF);
const Color kNeonGreen   = Color(0xFF00FF88);
const Color kNeonPink    = Color(0xFFFF2D75);
const Color kNeonOrange  = Color(0xFFFF6D00);
const Color kNeonPurple  = Color(0xFFB026FF);
const Color kNeonYellow  = Color(0xFFFFD600);
const Color kRed         = Color(0xFFFF3B30);
const Color kWhite       = Colors.white;
const Color kWhite70     = Colors.white70;
const Color kWhite40     = Color(0x66FFFFFF);
const Color kWhite15     = Color(0x26FFFFFF);
const Color kWhite08     = Color(0x14FFFFFF);

// ==================== MODELS ====================
class ChatUser {
  final String id;
  final String username;
  String role;
  final String avatar;
  bool isOnline;
  DateTime lastSeen;

  ChatUser({
    required this.id,
    required this.username,
    required this.role,
    required this.avatar,
    this.isOnline = false,
    required this.lastSeen,
  });

  Map<String, dynamic> toJson() => {
    'id': id,
    'username': username,
    'role': role,
    'avatar': avatar,
    'isOnline': isOnline,
    'lastSeen': lastSeen.toIso8601String(),
  };

  factory ChatUser.fromJson(Map<String, dynamic> json) => ChatUser(
    id: json['id'],
    username: json['username'],
    role: json['role'],
    avatar: json['avatar'],
    isOnline: json['isOnline'] ?? false,
    lastSeen: DateTime.parse(json['lastSeen']),
  );
}

class ChatMessage {
  final String id;
  final String chatId;
  final String chatType;
  final String senderId;
  final String senderName;
  final String senderRole;
  final String senderAvatar;
  final String text;
  final String type;
  final String? mediaUrl;
  final DateTime timestamp;
  final bool isRead;
  final List<String> reactions;

  ChatMessage({
    required this.id,
    required this.chatId,
    required this.chatType,
    required this.senderId,
    required this.senderName,
    required this.senderRole,
    required this.senderAvatar,
    required this.text,
    this.type = 'text',
    this.mediaUrl,
    required this.timestamp,
    this.isRead = false,
    this.reactions = const [],
  });

  Map<String, dynamic> toJson() => {
    'id': id,
    'chatId': chatId,
    'chatType': chatType,
    'senderId': senderId,
    'senderName': senderName,
    'senderRole': senderRole,
    'senderAvatar': senderAvatar,
    'text': text,
    'type': type,
    'mediaUrl': mediaUrl,
    'timestamp': timestamp.toIso8601String(),
    'isRead': isRead,
    'reactions': reactions,
  };

  factory ChatMessage.fromJson(Map<String, dynamic> json) => ChatMessage(
    id: json['id'],
    chatId: json['chatId'],
    chatType: json['chatType'],
    senderId: json['senderId'],
    senderName: json['senderName'],
    senderRole: json['senderRole'],
    senderAvatar: json['senderAvatar'],
    text: json['text'],
    type: json['type'] ?? 'text',
    mediaUrl: json['mediaUrl'],
    timestamp: DateTime.parse(json['timestamp']),
    isRead: json['isRead'] ?? false,
    reactions: List<String>.from(json['reactions'] ?? []),
  );
}

class GroupChat {
  final String id;
  String name;
  String description;
  String avatar;
  String ownerId;
  List<String> members;
  List<String> admins;
  DateTime createdAt;

  GroupChat({
    required this.id,
    required this.name,
    required this.description,
    required this.avatar,
    required this.ownerId,
    required this.members,
    required this.admins,
    required this.createdAt,
  });

  Map<String, dynamic> toJson() => {
    'id': id,
    'name': name,
    'description': description,
    'avatar': avatar,
    'ownerId': ownerId,
    'members': members,
    'admins': admins,
    'createdAt': createdAt.toIso8601String(),
  };

  factory GroupChat.fromJson(Map<String, dynamic> json) => GroupChat(
    id: json['id'],
    name: json['name'],
    description: json['description'],
    avatar: json['avatar'],
    ownerId: json['ownerId'],
    members: List<String>.from(json['members']),
    admins: List<String>.from(json['admins']),
    createdAt: DateTime.parse(json['createdAt']),
  );
}

class PrivateChat {
  final String id;
  final String user1Id;
  final String user2Id;
  String lastMessage;
  DateTime lastMessageTime;
  bool user1Deleted;
  bool user2Deleted;

  PrivateChat({
    required this.id,
    required this.user1Id,
    required this.user2Id,
    this.lastMessage = '',
    required this.lastMessageTime,
    this.user1Deleted = false,
    this.user2Deleted = false,
  });

  Map<String, dynamic> toJson() => {
    'id': id,
    'user1Id': user1Id,
    'user2Id': user2Id,
    'lastMessage': lastMessage,
    'lastMessageTime': lastMessageTime.toIso8601String(),
    'user1Deleted': user1Deleted,
    'user2Deleted': user2Deleted,
  };

  factory PrivateChat.fromJson(Map<String, dynamic> json) => PrivateChat(
    id: json['id'],
    user1Id: json['user1Id'],
    user2Id: json['user2Id'],
    lastMessage: json['lastMessage'],
    lastMessageTime: DateTime.parse(json['lastMessageTime']),
    user1Deleted: json['user1Deleted'] ?? false,
    user2Deleted: json['user2Deleted'] ?? false,
  );
}

class Story {
  final String id;
  final String userId;
  final String userName;
  final String userRole;
  final String userAvatar;
  final String mediaUrl;
  final String type;
  final DateTime createdAt;
  final List<String> viewers;

  Story({
    required this.id,
    required this.userId,
    required this.userName,
    required this.userRole,
    required this.userAvatar,
    required this.mediaUrl,
    required this.type,
    required this.createdAt,
    this.viewers = const [],
  });

  Map<String, dynamic> toJson() => {
    'id': id,
    'userId': userId,
    'userName': userName,
    'userRole': userRole,
    'userAvatar': userAvatar,
    'mediaUrl': mediaUrl,
    'type': type,
    'createdAt': createdAt.toIso8601String(),
    'viewers': viewers,
  };

  factory Story.fromJson(Map<String, dynamic> json) => Story(
    id: json['id'],
    userId: json['userId'],
    userName: json['userName'],
    userRole: json['userRole'],
    userAvatar: json['userAvatar'],
    mediaUrl: json['mediaUrl'],
    type: json['type'],
    createdAt: DateTime.parse(json['createdAt']),
    viewers: List<String>.from(json['viewers'] ?? []),
  );
}

// ==================== MESSAGE WIDGET ====================
class ChatMessageWidget extends StatelessWidget {
  final ChatMessage message;
  final bool isMe;

  const ChatMessageWidget({
    super.key,
    required this.message,
    required this.isMe,
  });

  String _formatTime(DateTime time) {
    final now = DateTime.now();
    if (now.difference(time).inHours < 24) {
      return '${time.hour.toString().padLeft(2, '0')}:${time.minute.toString().padLeft(2, '0')}';
    } else {
      return '${time.day}/${time.month} ${time.hour.toString().padLeft(2, '0')}:${time.minute.toString().padLeft(2, '0')}';
    }
  }

  void _showImagePreview(BuildContext context, String url) {
    showDialog(
      context: context,
      builder: (_) => Dialog(
        backgroundColor: Colors.transparent,
        child: Stack(
          children: [
            Center(
              child: InteractiveViewer(
                child: Image.network(url),
              ),
            ),
            Positioned(
              top: 20,
              right: 20,
              child: GestureDetector(
                onTap: () => Navigator.pop(context),
                child: Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: Colors.black.withOpacity(0.5),
                  ),
                  child: const Icon(Icons.close, color: kWhite),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: EdgeInsets.only(
        left: isMe ? 60 : 16,
        right: isMe ? 16 : 60,
        top: 8,
        bottom: 8,
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (!isMe) ...[
            CircleAvatar(
              radius: 20,
              backgroundColor: kNeonBlue.withOpacity(0.3),
              child: Text(
                message.senderName[0].toUpperCase(),
                style: const TextStyle(color: kWhite, fontWeight: FontWeight.bold),
              ),
            ),
            const SizedBox(width: 8),
          ],
          Expanded(
            child: Column(
              crossAxisAlignment: isMe ? CrossAxisAlignment.end : CrossAxisAlignment.start,
              children: [
                if (!isMe) ...[
                  Row(
                    children: [
                      Text(
                        message.senderName,
                        style: TextStyle(
                          color: message.senderRole == 'admin' ? kNeonOrange : kNeonBlue,
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(width: 4),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(8),
                          color: message.senderRole == 'admin'
                              ? kNeonOrange.withOpacity(0.2)
                              : kNeonGreen.withOpacity(0.2),
                        ),
                        child: Text(
                          message.senderRole.toUpperCase(),
                          style: TextStyle(
                            color: message.senderRole == 'admin' ? kNeonOrange : kNeonGreen,
                            fontSize: 8,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                ],
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: isMe
                          ? [kNeonBlue, kNeonGreen]
                          : [kBgCard, kBgCardLight],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    borderRadius: BorderRadius.only(
                      topLeft: const Radius.circular(16),
                      topRight: const Radius.circular(16),
                      bottomLeft: isMe ? const Radius.circular(16) : const Radius.circular(4),
                      bottomRight: isMe ? const Radius.circular(4) : const Radius.circular(16),
                    ),
                    border: Border.all(
                      color: isMe ? kNeonGreen.withOpacity(0.5) : kNeonBlue.withOpacity(0.3),
                    ),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      if (message.type == 'text') ...[
                        SelectableText(
                          message.text,
                          style: TextStyle(
                            color: isMe ? Colors.black : kWhite,
                            fontSize: 14,
                          ),
                        ),
                      ] else if (message.type == 'image' && message.mediaUrl != null) ...[
                        GestureDetector(
                          onTap: () => _showImagePreview(context, message.mediaUrl!),
                          child: ClipRRect(
                            borderRadius: BorderRadius.circular(12),
                            child: Image.network(
                              message.mediaUrl!,
                              height: 200,
                              width: double.infinity,
                              fit: BoxFit.cover,
                              errorBuilder: (_, __, ___) => Container(
                                height: 200,
                                color: kWhite08,
                                child: const Icon(Icons.broken_image, color: kWhite40),
                              ),
                            ),
                          ),
                        ),
                      ],
                      if (message.text.isNotEmpty && message.type != 'text')
                        Padding(
                          padding: const EdgeInsets.only(top: 8),
                          child: Text(
                            message.text,
                            style: TextStyle(
                              color: isMe ? Colors.black87 : kWhite70,
                              fontSize: 12,
                            ),
                          ),
                        ),
                    ],
                  ),
                ),
                const SizedBox(height: 4),
                Align(
                  alignment: isMe ? Alignment.centerRight : Alignment.centerLeft,
                  child: Text(
                    _formatTime(message.timestamp),
                    style: const TextStyle(color: kWhite40, fontSize: 10),
                  ),
                ),
              ],
            ),
          ),
          if (isMe) ...[
            const SizedBox(width: 8),
            CircleAvatar(
              radius: 20,
              backgroundColor: kNeonGreen.withOpacity(0.3),
              child: Text(
                message.senderName[0].toUpperCase(),
                style: const TextStyle(color: kWhite, fontWeight: FontWeight.bold),
              ),
            ),
          ],
        ],
      ),
    );
  }
}

// ==================== STORY WIDGET ====================
class StoryWidget extends StatelessWidget {
  final Story story;
  final bool isViewed;

  const StoryWidget({
    super.key,
    required this.story,
    required this.isViewed,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(right: 12),
      child: Column(
        children: [
          Container(
            width: 70, height: 70,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: isViewed
                  ? LinearGradient(colors: [kWhite40, kWhite15])
                  : LinearGradient(colors: [kNeonPink, kNeonOrange]),
              border: Border.all(color: isViewed ? kWhite40 : kNeonPink, width: 2),
            ),
            child: ClipOval(
              child: story.mediaUrl.isNotEmpty && story.type == 'image'
                  ? Image.network(story.mediaUrl, fit: BoxFit.cover)
                  : Container(
                      color: kBgCard,
                      child: Center(
                        child: Text(
                          story.userName[0].toUpperCase(),
                          style: const TextStyle(color: kWhite, fontSize: 24, fontWeight: FontWeight.bold),
                        ),
                      ),
                    ),
            ),
          ),
          const SizedBox(height: 4),
          Text(
            story.userName.length > 10 ? '${story.userName.substring(0, 10)}...' : story.userName,
            style: TextStyle(color: isViewed ? kWhite40 : kWhite, fontSize: 10),
          ),
        ],
      ),
    );
  }
}

// ==================== PRIVATE CHAT PAGE ====================
class PrivateChatPage extends StatefulWidget {
  final String currentUserId;
  final String currentUserName;
  final String currentUserRole;
  final String targetUserId;
  final String targetUserName;
  final String targetUserRole;

  const PrivateChatPage({
    super.key,
    required this.currentUserId,
    required this.currentUserName,
    required this.currentUserRole,
    required this.targetUserId,
    required this.targetUserName,
    required this.targetUserRole,
  });

  @override
  State<PrivateChatPage> createState() => _PrivateChatPageState();
}

class _PrivateChatPageState extends State<PrivateChatPage> {
  List<ChatMessage> _messages = [];
  final TextEditingController _messageCtrl = TextEditingController();
  final ScrollController _scrollCtrl = ScrollController();
  bool _isLoading = true;
  String _chatId = '';
  final ImagePicker _picker = ImagePicker();

  @override
  void initState() {
    super.initState();
    _chatId = _getChatId();
    _loadMessages();
    _startMessageListener();
  }

  @override
  void dispose() {
    _scrollCtrl.dispose();
    _messageCtrl.dispose();
    super.dispose();
  }

  String _getChatId() {
    final ids = [widget.currentUserId, widget.targetUserId]..sort();
    return 'private_${ids.join('_')}';
  }

  Future<void> _loadMessages() async {
    final prefs = await SharedPreferences.getInstance();
    final messagesStr = prefs.getString('private_messages_$_chatId');
    if (messagesStr != null) {
      final List<dynamic> list = jsonDecode(messagesStr);
      setState(() {
        _messages = list.map((e) => ChatMessage.fromJson(e)).toList();
        _isLoading = false;
      });
    } else {
      setState(() => _isLoading = false);
    }
    _scrollToBottom();
  }

  Future<void> _saveMessages() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('private_messages_$_chatId', jsonEncode(_messages.map((e) => e.toJson()).toList()));
  }

  void _startMessageListener() {
    Timer.periodic(const Duration(seconds: 2), (timer) async {
      final prefs = await SharedPreferences.getInstance();
      final messagesStr = prefs.getString('private_messages_$_chatId');
      if (messagesStr != null) {
        final List<dynamic> list = jsonDecode(messagesStr);
        final newMessages = list.map((e) => ChatMessage.fromJson(e)).toList();
        if (newMessages.length != _messages.length) {
          setState(() {
            _messages = newMessages;
          });
          _scrollToBottom();
        }
      }
    });
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

  Future<void> _sendMessage({String? text, String? type, String? mediaUrl}) async {
    if (text == null && mediaUrl == null) return;
    
    final message = ChatMessage(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      chatId: _chatId,
      chatType: 'private',
      senderId: widget.currentUserId,
      senderName: widget.currentUserName,
      senderRole: widget.currentUserRole,
      senderAvatar: '',
      text: text ?? '',
      type: type ?? 'text',
      mediaUrl: mediaUrl,
      timestamp: DateTime.now(),
    );
    
    setState(() {
      _messages.add(message);
    });
    await _saveMessages();
    _scrollToBottom();
    _messageCtrl.clear();
  }

  Future<void> _pickImage() async {
    final XFile? image = await _picker.pickImage(source: ImageSource.gallery);
    if (image != null) {
      final bytes = await File(image.path).readAsBytes();
      final base64Image = base64Encode(bytes);
      await _sendMessage(type: 'image', mediaUrl: 'data:image/jpeg;base64,$base64Image');
    }
  }

  Future<void> _pickCamera() async {
    final XFile? image = await _picker.pickImage(source: ImageSource.camera);
    if (image != null) {
      final bytes = await File(image.path).readAsBytes();
      final base64Image = base64Encode(bytes);
      await _sendMessage(type: 'image', mediaUrl: 'data:image/jpeg;base64,$base64Image');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: kBgDark,
      appBar: AppBar(
        backgroundColor: kBgDark.withOpacity(0.95),
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_rounded, color: kWhite),
          onPressed: () => Navigator.pop(context),
        ),
        title: Row(
          children: [
            CircleAvatar(
              radius: 20,
              backgroundColor: kNeonBlue.withOpacity(0.3),
              child: Text(
                widget.targetUserName[0].toUpperCase(),
                style: const TextStyle(color: kWhite),
              ),
            ),
            const SizedBox(width: 12),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  widget.targetUserName,
                  style: const TextStyle(color: kWhite, fontWeight: FontWeight.bold),
                ),
                Text(
                  widget.targetUserRole.toUpperCase(),
                  style: TextStyle(color: kNeonBlue, fontSize: 10),
                ),
              ],
            ),
          ],
        ),
        flexibleSpace: Container(
          decoration: BoxDecoration(
            border: Border(bottom: BorderSide(color: kNeonBlue.withOpacity(0.3))),
          ),
        ),
      ),
      body: Column(
        children: [
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator(color: kNeonBlue))
                : ListView.builder(
                    controller: _scrollCtrl,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    itemCount: _messages.length,
                    itemBuilder: (ctx, i) {
                      final msg = _messages[i];
                      return ChatMessageWidget(
                        message: msg,
                        isMe: msg.senderId == widget.currentUserId,
                      );
                    },
                  ),
          ),
          _buildInputBar(),
        ],
      ),
    );
  }

  Widget _buildInputBar() {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: kBgCard,
        border: Border(top: BorderSide(color: kNeonBlue.withOpacity(0.3))),
      ),
      child: Row(
        children: [
          IconButton(
            icon: const Icon(Icons.image_rounded, color: kNeonGreen),
            onPressed: _pickImage,
          ),
          IconButton(
            icon: const Icon(Icons.photo_camera_rounded, color: kNeonBlue),
            onPressed: _pickCamera,
          ),
          const SizedBox(width: 8),
          Expanded(
            child: TextField(
              controller: _messageCtrl,
              style: const TextStyle(color: kWhite),
              decoration: InputDecoration(
                hintText: 'Type a message...',
                hintStyle: const TextStyle(color: kWhite40),
                filled: true,
                fillColor: kWhite08,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(30),
                  borderSide: BorderSide.none,
                ),
                contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
              ),
            ),
          ),
          const SizedBox(width: 8),
          Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(colors: [kNeonBlue, kNeonGreen]),
              shape: BoxShape.circle,
            ),
            child: IconButton(
              icon: const Icon(Icons.send_rounded, color: Colors.black, size: 20),
              onPressed: () => _sendMessage(text: _messageCtrl.text),
            ),
          ),
        ],
      ),
    );
  }
}

// ==================== MAIN GROUP CHAT PAGE ====================
class ChatPublicPage extends StatefulWidget {
  final String username;
  final String sessionKey;

  const ChatPublicPage({
    super.key,
    required this.username,
    required this.sessionKey,
  });

  @override
  State<ChatPublicPage> createState() => _ChatPublicPageState();
}

class _ChatPublicPageState extends State<ChatPublicPage> with SingleTickerProviderStateMixin {
  List<ChatMessage> _messages = [];
  List<ChatUser> _users = [];
  List<PrivateChat> _privateChats = [];
  List<Story> _stories = [];
  final TextEditingController _messageCtrl = TextEditingController();
  final ScrollController _scrollCtrl = ScrollController();
  bool _isLoading = true;
  bool _isTyping = false;
  Timer? _typingTimer;
  String _currentUserRole = 'member';
  String _currentUserId = '';
  String _groupName = 'BELLION CHAT';
  String _groupDescription = 'Public group chat for all members';
  String _groupAvatar = '';
  bool _showPrivateChats = false;
  
  late TabController _tabController;
  final ImagePicker _picker = ImagePicker();

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _currentUserId = widget.username;
    _loadCurrentUser();
    _loadMessages();
    _loadUsers();
    _loadPrivateChats();
    _loadStories();
    _loadGroupInfo();
    _startMessageListener();
  }

  @override
  void dispose() {
    _typingTimer?.cancel();
    _scrollCtrl.dispose();
    _messageCtrl.dispose();
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _loadCurrentUser() async {
    final prefs = await SharedPreferences.getInstance();
    final role = prefs.getString('user_role_${widget.username}') ?? 'member';
    setState(() {
      _currentUserRole = role;
    });
  }

  Future<void> _loadGroupInfo() async {
    final prefs = await SharedPreferences.getInstance();
    final name = prefs.getString('group_name');
    final desc = prefs.getString('group_description');
    final avatar = prefs.getString('group_avatar');
    if (name != null) setState(() => _groupName = name);
    if (desc != null) setState(() => _groupDescription = desc);
    if (avatar != null) setState(() => _groupAvatar = avatar);
  }

  Future<void> _saveGroupInfo() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('group_name', _groupName);
    await prefs.setString('group_description', _groupDescription);
    if (_groupAvatar.isNotEmpty) await prefs.setString('group_avatar', _groupAvatar);
  }

  Future<void> _loadMessages() async {
    final prefs = await SharedPreferences.getInstance();
    final messagesStr = prefs.getString('chat_messages');
    if (messagesStr != null) {
      final List<dynamic> list = jsonDecode(messagesStr);
      setState(() {
        _messages = list.map((e) => ChatMessage.fromJson(e)).toList();
        _isLoading = false;
      });
    } else {
      final welcomeMsg = ChatMessage(
        id: DateTime.now().millisecondsSinceEpoch.toString(),
        chatId: 'group_public',
        chatType: 'group',
        senderId: 'system',
        senderName: 'SYSTEM',
        senderRole: 'system',
        senderAvatar: '',
        text: 'Welcome to $_groupName! Be respectful to others.',
        timestamp: DateTime.now(),
      );
      _messages.add(welcomeMsg);
      await _saveMessages();
      setState(() => _isLoading = false);
    }
    _scrollToBottom();
  }

  Future<void> _saveMessages() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('chat_messages', jsonEncode(_messages.map((e) => e.toJson()).toList()));
  }

  Future<void> _loadUsers() async {
    final prefs = await SharedPreferences.getInstance();
    final usersStr = prefs.getString('chat_users');
    if (usersStr != null) {
      final List<dynamic> list = jsonDecode(usersStr);
      setState(() {
        _users = list.map((e) => ChatUser.fromJson(e)).toList();
      });
    } else {
      final adminUser = ChatUser(
        id: 'tzy',
        username: 'tzy',
        role: 'owner',
        avatar: '',
        lastSeen: DateTime.now(),
      );
      _users.add(adminUser);
      await _saveUsers();
    }
  }

  Future<void> _saveUsers() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('chat_users', jsonEncode(_users.map((e) => e.toJson()).toList()));
  }

  Future<void> _loadPrivateChats() async {
    final prefs = await SharedPreferences.getInstance();
    final chatsStr = prefs.getString('private_chats_${widget.username}');
    if (chatsStr != null) {
      final List<dynamic> list = jsonDecode(chatsStr);
      setState(() {
        _privateChats = list.map((e) => PrivateChat.fromJson(e)).toList();
      });
    }
  }

  Future<void> _savePrivateChats() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('private_chats_${widget.username}', jsonEncode(_privateChats.map((e) => e.toJson()).toList()));
  }

  Future<void> _loadStories() async {
    final prefs = await SharedPreferences.getInstance();
    final storiesStr = prefs.getString('stories');
    if (storiesStr != null) {
      final List<dynamic> list = jsonDecode(storiesStr);
      setState(() {
        _stories = list.map((e) => Story.fromJson(e)).toList();
      });
    }
    _removeExpiredStories();
  }

  Future<void> _saveStories() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('stories', jsonEncode(_stories.map((e) => e.toJson()).toList()));
  }

  void _removeExpiredStories() {
    final now = DateTime.now();
    _stories.removeWhere((story) => now.difference(story.createdAt).inHours >= 24);
    _saveStories();
    setState(() {});
  }

  void _startMessageListener() {
    Timer.periodic(const Duration(seconds: 2), (timer) async {
      final prefs = await SharedPreferences.getInstance();
      final messagesStr = prefs.getString('chat_messages');
      if (messagesStr != null) {
        final List<dynamic> list = jsonDecode(messagesStr);
        final newMessages = list.map((e) => ChatMessage.fromJson(e)).toList();
        if (newMessages.length != _messages.length) {
          setState(() {
            _messages = newMessages;
          });
          _scrollToBottom();
        }
      }
    });
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

  Future<void> _sendMessage({String? text, String? type, String? mediaUrl}) async {
    if (text == null && mediaUrl == null) return;
    
    final message = ChatMessage(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      chatId: 'group_public',
      chatType: 'group',
      senderId: widget.username,
      senderName: widget.username,
      senderRole: _currentUserRole,
      senderAvatar: '',
      text: text ?? '',
      type: type ?? 'text',
      mediaUrl: mediaUrl,
      timestamp: DateTime.now(),
    );
    
    setState(() {
      _messages.add(message);
    });
    await _saveMessages();
    _scrollToBottom();
    _messageCtrl.clear();
  }

  Future<void> _pickImage() async {
    final XFile? image = await _picker.pickImage(source: ImageSource.gallery);
    if (image != null) {
      final bytes = await File(image.path).readAsBytes();
      final base64Image = base64Encode(bytes);
      await _sendMessage(type: 'image', mediaUrl: 'data:image/jpeg;base64,$base64Image');
    }
  }

  Future<void> _pickCamera() async {
    final XFile? image = await _picker.pickImage(source: ImageSource.camera);
    if (image != null) {
      final bytes = await File(image.path).readAsBytes();
      final base64Image = base64Encode(bytes);
      await _sendMessage(type: 'image', mediaUrl: 'data:image/jpeg;base64,$base64Image');
    }
  }

  Future<void> _uploadStory() async {
    final XFile? image = await _picker.pickImage(source: ImageSource.gallery);
    if (image != null) {
      final bytes = await File(image.path).readAsBytes();
      final base64Image = base64Encode(bytes);
      final story = Story(
        id: DateTime.now().millisecondsSinceEpoch.toString(),
        userId: widget.username,
        userName: widget.username,
        userRole: _currentUserRole,
        userAvatar: '',
        mediaUrl: 'data:image/jpeg;base64,$base64Image',
        type: 'image',
        createdAt: DateTime.now(),
      );
      setState(() {
        _stories.insert(0, story);
      });
      await _saveStories();
      _showSnackBar('Story uploaded!', kNeonGreen);
    }
  }

  void _startPrivateChat(ChatUser targetUser) {
    final existingChat = _privateChats.firstWhere(
      (chat) => (chat.user1Id == widget.username && chat.user2Id == targetUser.id) ||
                (chat.user1Id == targetUser.id && chat.user2Id == widget.username),
      orElse: () => PrivateChat(
        id: '',
        user1Id: '',
        user2Id: '',
        lastMessageTime: DateTime.now(),
      ),
    );
    
    if (existingChat.id.isEmpty) {
      final newChat = PrivateChat(
        id: 'chat_${DateTime.now().millisecondsSinceEpoch}',
        user1Id: widget.username,
        user2Id: targetUser.id,
        lastMessageTime: DateTime.now(),
      );
      _privateChats.add(newChat);
      _savePrivateChats();
    }
    
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => PrivateChatPage(
          currentUserId: widget.username,
          currentUserName: widget.username,
          currentUserRole: _currentUserRole,
          targetUserId: targetUser.id,
          targetUserName: targetUser.username,
          targetUserRole: targetUser.role,
        ),
      ),
    );
  }

  void _showGroupSettings() async {
    final nameCtrl = TextEditingController(text: _groupName);
    final descCtrl = TextEditingController(text: _groupDescription);
    
    await showDialog(
      context: context,
      builder: (_) => Dialog(
        backgroundColor: Colors.transparent,
        child: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(colors: [kBgCard, kBgCardLight]),
            borderRadius: BorderRadius.circular(24),
            border: Border.all(color: kNeonBlue.withOpacity(0.5)),
          ),
          padding: const EdgeInsets.all(20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.group_rounded, color: kNeonBlue, size: 50),
              const SizedBox(height: 16),
              const Text(
                'GROUP SETTINGS',
                style: TextStyle(color: kNeonBlue, fontSize: 16, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: nameCtrl,
                style: const TextStyle(color: kWhite),
                decoration: InputDecoration(
                  labelText: 'GROUP NAME',
                  labelStyle: const TextStyle(color: kWhite70),
                  filled: true,
                  fillColor: kWhite08,
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                ),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: descCtrl,
                style: const TextStyle(color: kWhite),
                maxLines: 3,
                decoration: InputDecoration(
                  labelText: 'DESCRIPTION',
                  labelStyle: const TextStyle(color: kWhite70),
                  filled: true,
                  fillColor: kWhite08,
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                ),
              ),
              const SizedBox(height: 20),
              Row(
                children: [
                  Expanded(
                    child: GestureDetector(
                      onTap: () => Navigator.pop(context),
                      child: Container(
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(30),
                          border: Border.all(color: kWhite40),
                        ),
                        child: const Text('CANCEL', textAlign: TextAlign.center, style: TextStyle(color: kWhite70)),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: GestureDetector(
                      onTap: () {
                        setState(() {
                          _groupName = nameCtrl.text;
                          _groupDescription = descCtrl.text;
                        });
                        _saveGroupInfo();
                        Navigator.pop(context);
                        _showSnackBar('Group updated!', kNeonGreen);
                      },
                      child: Container(
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        decoration: BoxDecoration(
                          gradient: LinearGradient(colors: [kNeonBlue, kNeonGreen]),
                          borderRadius: BorderRadius.circular(30),
                        ),
                        child: const Text('SAVE', textAlign: TextAlign.center, style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold)),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _kickUser(ChatUser user) async {
    if (user.role == 'owner') {
      _showSnackBar('Cannot kick owner!', kRed);
      return;
    }
    if (_currentUserRole != 'owner' && _currentUserRole != 'admin') {
      _showSnackBar('Only owner/admin can kick users!', kRed);
      return;
    }
    if (user.role == 'admin' && _currentUserRole != 'owner') {
      _showSnackBar('Only owner can kick admin!', kRed);
      return;
    }
    
    final confirm = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        backgroundColor: kBgCard,
        title: const Text('KICK USER', style: TextStyle(color: kRed)),
        content: Text('Kick ${user.username} from group?', style: const TextStyle(color: kWhite70)),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('CANCEL', style: TextStyle(color: kWhite70))),
          TextButton(onPressed: () => Navigator.pop(context, true), child: const Text('KICK', style: TextStyle(color: kRed))),
        ],
      ),
    );
    
    if (confirm == true) {
      final sysMsg = ChatMessage(
        id: DateTime.now().millisecondsSinceEpoch.toString(),
        chatId: 'group_public',
        chatType: 'group',
        senderId: 'system',
        senderName: 'SYSTEM',
        senderRole: 'system',
        senderAvatar: '',
        text: '${user.username} has been kicked from the group',
        timestamp: DateTime.now(),
      );
      setState(() {
        _messages.add(sysMsg);
        _users.removeWhere((u) => u.id == user.id);
      });
      await _saveMessages();
      await _saveUsers();
      _showSnackBar('${user.username} kicked!', kNeonOrange);
    }
  }

  void _promoteUser(ChatUser user) async {
    if (_currentUserRole != 'owner') {
      _showSnackBar('Only owner can promote users!', kRed);
      return;
    }
    
    if (user.role == 'admin') {
      _showSnackBar('User is already admin!', kNeonOrange);
      return;
    }
    
    setState(() {
      user.role = 'admin';
    });
    await _saveUsers();
    
    final sysMsg = ChatMessage(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      chatId: 'group_public',
      chatType: 'group',
      senderId: 'system',
      senderName: 'SYSTEM',
      senderRole: 'system',
      senderAvatar: '',
      text: '${user.username} has been promoted to ADMIN',
      timestamp: DateTime.now(),
    );
    setState(() {
      _messages.add(sysMsg);
    });
    await _saveMessages();
    _showSnackBar('${user.username} promoted to ADMIN', kNeonGreen);
  }

  void _showUserMenu(ChatUser user) {
    if (user.id == widget.username) return;
    
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (_) => Container(
        decoration: BoxDecoration(
          color: kBgCard,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 50, height: 4,
              margin: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(2),
                color: kWhite40,
              ),
            ),
            ListTile(
              leading: const Icon(Icons.chat_rounded, color: kNeonBlue),
              title: const Text('PRIVATE CHAT', style: TextStyle(color: kWhite)),
              onTap: () {
                Navigator.pop(context);
                _startPrivateChat(user);
              },
            ),
            if (_currentUserRole == 'owner' || (_currentUserRole == 'admin' && user.role != 'admin'))
              ListTile(
                leading: const Icon(Icons.person_remove_rounded, color: kRed),
                title: const Text('KICK FROM GROUP', style: TextStyle(color: kRed)),
                onTap: () {
                  Navigator.pop(context);
                  _kickUser(user);
                },
              ),
            if (_currentUserRole == 'owner' && user.role != 'admin' && user.role != 'owner')
              ListTile(
                leading: const Icon(Icons.admin_panel_settings_rounded, color: kNeonOrange),
                title: const Text('PROMOTE TO ADMIN', style: TextStyle(color: kNeonOrange)),
                onTap: () {
                  Navigator.pop(context);
                  _promoteUser(user);
                },
              ),
          ],
        ),
      ),
    );
  }

  void _showUsersList() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (_) => Container(
        decoration: BoxDecoration(
          color: kBgCard,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 50, height: 4,
              margin: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(2),
                color: kWhite40,
              ),
            ),
            const Padding(
              padding: EdgeInsets.all(16),
              child: Text('MEMBERS', style: TextStyle(color: kNeonBlue, fontSize: 16, fontWeight: FontWeight.bold)),
            ),
            Flexible(
              child: ListView.builder(
                shrinkWrap: true,
                itemCount: _users.length,
                itemBuilder: (ctx, i) {
                  final user = _users[i];
                  return ListTile(
                    onTap: () => _showUserMenu(user),
                    leading: CircleAvatar(
                      backgroundColor: kNeonBlue.withOpacity(0.2),
                      child: Text(user.username[0].toUpperCase(), style: const TextStyle(color: kNeonBlue)),
                    ),
                    title: Text(user.username, style: const TextStyle(color: kWhite)),
                    subtitle: Text(user.role.toUpperCase(), style: TextStyle(color: user.role == 'admin' ? kNeonOrange : kNeonGreen, fontSize: 10)),
                    trailing: Icon(Icons.more_vert_rounded, color: kWhite40),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showPrivateChatsList() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (_) => DraggableScrollableSheet(
        initialChildSize: 0.7,
        maxChildSize: 0.9,
        minChildSize: 0.4,
        builder: (_, scrollCtrl) => Container(
          decoration: BoxDecoration(
            color: kBgCard,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
          ),
          child: Column(
            children: [
              Container(
                width: 50, height: 4,
                margin: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(2),
                  color: kWhite40,
                ),
              ),
              const Padding(
                padding: EdgeInsets.all(16),
                child: Text('PRIVATE CHATS', style: TextStyle(color: kNeonBlue, fontSize: 16, fontWeight: FontWeight.bold)),
              ),
              Expanded(
                child: _privateChats.isEmpty
                    ? Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.chat_bubble_outline_rounded, color: kWhite40, size: 50),
                            const SizedBox(height: 16),
                            const Text('No private chats yet', style: TextStyle(color: kWhite40)),
                          ],
                        ),
                      )
                    : ListView.builder(
                        controller: scrollCtrl,
                        itemCount: _privateChats.length,
                        itemBuilder: (ctx, i) {
                          final chat = _privateChats[i];
                          final otherId = chat.user1Id == widget.username ? chat.user2Id : chat.user1Id;
                          final otherUser = _users.firstWhere((u) => u.id == otherId, orElse: () => ChatUser(id: otherId, username: otherId, role: 'member', avatar: '', lastSeen: DateTime.now()));
                          return ListTile(
                            onTap: () {
                              Navigator.pop(context);
                              _startPrivateChat(otherUser);
                            },
                            leading: CircleAvatar(
                              backgroundColor: kNeonBlue.withOpacity(0.2),
                              child: Text(otherUser.username[0].toUpperCase(), style: const TextStyle(color: kNeonBlue)),
                            ),
                            title: Text(otherUser.username, style: const TextStyle(color: kWhite)),
                            subtitle: Text(chat.lastMessage.isNotEmpty ? chat.lastMessage : 'Start conversation', style: const TextStyle(color: kWhite40, fontSize: 11)),
                            trailing: const Icon(Icons.arrow_forward_ios_rounded, color: kWhite40, size: 14),
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

  void _showSnackBar(String msg, Color color) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(msg), backgroundColor: color),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: kBgDark,
      appBar: _buildAppBar(),
      body: Column(
        children: [
          _buildStoriesBar(),
          _buildTabBar(),
          Expanded(
            child: TabBarView(
              controller: _tabController,
              children: [
                _buildGroupChatTab(),
                _buildPrivateChatsTab(),
              ],
            ),
          ),
        ],
      ),
    );
  }

  PreferredSizeWidget _buildAppBar() {
    return AppBar(
      backgroundColor: kBgDark.withOpacity(0.95),
      elevation: 0,
      title: Row(
        children: [
          Container(
            width: 40, height: 40,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: LinearGradient(colors: [kNeonBlue, kNeonGreen]),
            ),
            child: const Center(child: Icon(Icons.chat_rounded, color: Colors.black, size: 22)),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  _groupName,
                  style: const TextStyle(color: kWhite, fontSize: 16, fontWeight: FontWeight.bold),
                  overflow: TextOverflow.ellipsis,
                ),
                Text(
                  '${_users.length} members',
                  style: const TextStyle(color: kWhite70, fontSize: 10),
                ),
              ],
            ),
          ),
        ],
      ),
      actions: [
        IconButton(
          icon: const Icon(Icons.camera_alt_rounded, color: kNeonYellow),
          onPressed: _uploadStory,
        ),
        if (_currentUserRole == 'owner')
          IconButton(
            icon: const Icon(Icons.settings_rounded, color: kNeonBlue),
            onPressed: _showGroupSettings,
          ),
        IconButton(
          icon: const Icon(Icons.people_rounded, color: kNeonBlue),
          onPressed: _showUsersList,
        ),
        const SizedBox(width: 8),
      ],
      flexibleSpace: Container(
        decoration: BoxDecoration(
          border: Border(bottom: BorderSide(color: kNeonBlue.withOpacity(0.3))),
        ),
      ),
    );
  }

  Widget _buildStoriesBar() {
    if (_stories.isEmpty) return const SizedBox.shrink();
    
    return Container(
      height: 100,
      padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        itemCount: _stories.length,
        itemBuilder: (ctx, i) {
          final story = _stories[i];
          final isViewed = story.viewers.contains(widget.username);
          return GestureDetector(
            onTap: () {
              setState(() {
                if (!isViewed) {
                  story.viewers.add(widget.username);
                  _saveStories();
                }
              });
              // Show story viewer
            },
            child: StoryWidget(story: story, isViewed: isViewed),
          );
        },
      ),
    );
  }

  Widget _buildTabBar() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(30),
        color: kBgCard,
        border: Border.all(color: kNeonBlue.withOpacity(0.3)),
      ),
      child: TabBar(
        controller: _tabController,
        indicator: BoxDecoration(
          borderRadius: BorderRadius.circular(30),
          gradient: LinearGradient(colors: [kNeonBlue, kNeonGreen]),
        ),
        labelColor: Colors.black,
        unselectedLabelColor: kWhite70,
        tabs: const [
          Tab(text: 'GROUP'),
          Tab(text: 'PRIVATE'),
        ],
      ),
    );
  }

  Widget _buildGroupChatTab() {
    return Column(
      children: [
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          decoration: BoxDecoration(
            color: kBgCardLight.withOpacity(0.5),
            border: Border(bottom: BorderSide(color: kNeonBlue.withOpacity(0.2))),
          ),
          child: Row(
            children: [
              const Icon(Icons.info_outline_rounded, color: kNeonBlue, size: 16),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  _groupDescription,
                  style: const TextStyle(color: kWhite70, fontSize: 11),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
        ),
        Expanded(
          child: _isLoading
              ? const Center(child: CircularProgressIndicator(color: kNeonBlue))
              : ListView.builder(
                  controller: _scrollCtrl,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  itemCount: _messages.length,
                  itemBuilder: (ctx, i) {
                    final msg = _messages[i];
                    return ChatMessageWidget(
                      message: msg,
                      isMe: msg.senderId == widget.username,
                    );
                  },
                ),
        ),
        _buildInputBar(),
      ],
    );
  }

  Widget _buildPrivateChatsTab() {
    if (_privateChats.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.chat_bubble_outline_rounded, color: kWhite40, size: 60),
            const SizedBox(height: 16),
            const Text('No private chats yet', style: TextStyle(color: kWhite40)),
            const SizedBox(height: 8),
            const Text('Tap on a user to start chatting', style: TextStyle(color: kWhite40, fontSize: 12)),
          ],
        ),
      );
    }
    
    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: _privateChats.length,
      itemBuilder: (ctx, i) {
        final chat = _privateChats[i];
        final otherId = chat.user1Id == widget.username ? chat.user2Id : chat.user1Id;
        final otherUser = _users.firstWhere(
          (u) => u.id == otherId,
          orElse: () => ChatUser(id: otherId, username: otherId, role: 'member', avatar: '', lastSeen: DateTime.now()),
        );
        return Container(
          margin: const EdgeInsets.only(bottom: 12),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            gradient: LinearGradient(colors: [kBgCard, kBgCardLight]),
            border: Border.all(color: kNeonBlue.withOpacity(0.3)),
          ),
          child: ListTile(
            onTap: () => _startPrivateChat(otherUser),
            leading: CircleAvatar(
              radius: 25,
              backgroundColor: kNeonBlue.withOpacity(0.2),
              child: Text(otherUser.username[0].toUpperCase(), style: const TextStyle(color: kNeonBlue, fontSize: 18)),
            ),
            title: Text(otherUser.username, style: const TextStyle(color: kWhite, fontWeight: FontWeight.bold)),
            subtitle: Row(
              children: [
                Container(
                  width: 8, height: 8,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: otherUser.isOnline ? kNeonGreen : kWhite40,
                  ),
                ),
                const SizedBox(width: 6),
                Expanded(
                  child: Text(
                    otherUser.isOnline ? 'Online' : 'Offline',
                    style: TextStyle(color: otherUser.isOnline ? kNeonGreen : kWhite40, fontSize: 11),
                  ),
                ),
              ],
            ),
            trailing: const Icon(Icons.arrow_forward_ios_rounded, color: kWhite40),
          ),
        );
      },
    );
  }

  Widget _buildInputBar() {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: kBgCard,
        border: Border(top: BorderSide(color: kNeonBlue.withOpacity(0.3))),
      ),
      child: Row(
        children: [
          IconButton(
            icon: const Icon(Icons.image_rounded, color: kNeonGreen),
            onPressed: _pickImage,
          ),
          IconButton(
            icon: const Icon(Icons.photo_camera_rounded, color: kNeonBlue),
            onPressed: _pickCamera,
          ),
          const SizedBox(width: 8),
          Expanded(
            child: TextField(
              controller: _messageCtrl,
              style: const TextStyle(color: kWhite),
              decoration: InputDecoration(
                hintText: 'Type a message...',
                hintStyle: const TextStyle(color: kWhite40),
                filled: true,
                fillColor: kWhite08,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(30),
                  borderSide: BorderSide.none,
                ),
                contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
              ),
              onChanged: (text) {
                if (_typingTimer != null) _typingTimer!.cancel();
                setState(() => _isTyping = true);
                _typingTimer = Timer(const Duration(seconds: 2), () {
                  setState(() => _isTyping = false);
                });
              },
            ),
          ),
          const SizedBox(width: 8),
          Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(colors: [kNeonBlue, kNeonGreen]),
              shape: BoxShape.circle,
            ),
            child: IconButton(
              icon: const Icon(Icons.send_rounded, color: Colors.black, size: 20),
              onPressed: () => _sendMessage(text: _messageCtrl.text),
            ),
          ),
        ],
      ),
    );
  }
}