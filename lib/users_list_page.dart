import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'app_config.dart';
import 'private_chat_page.dart';

class UsersListPage extends StatefulWidget {
  final String username;
  final String sessionKey;
  final String role;

  const UsersListPage({
    super.key,
    required this.username,
    required this.sessionKey,
    required this.role,
  });

  @override
  State<UsersListPage> createState() => _UsersListPageState();
}

class _UsersListPageState extends State<UsersListPage> {
  List<Map<String, dynamic>> _users = [];
  bool _loading = true;

  // Colors
  static const Color bgDark = Color(0xFF03080f);
  static const Color deepBlue = Color(0xFF060d18);
  static const Color cardBlue = Color(0xFF091525);
  static const Color accentCyan = Color(0xFF00b0ff);
  static const Color neonGreen = Color(0xFF00ff41);

  @override
  void initState() {
    super.initState();
    _loadUsers();
  }

  Future<void> _loadUsers() async {
    try {
      final apiUrl = kBaseUrl;
      final uri = Uri.parse('$apiUrl/api/chatv2/users').replace(
        queryParameters: {'key': widget.sessionKey},
      );

      final response = await http.get(uri);

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (data['success'] == true) {
          final users = List<Map<String, dynamic>>.from(data['users'] ?? []);
          if (mounted) {
            setState(() {
              _users = users;
              _loading = false;
            });
          }
        }
      }
    } catch (e) {
      if (mounted) {
        setState(() => _loading = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error loading users: $e')),
        );
      }
    }
  }

  void _openPrivateChat(String targetUsername) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => PrivateChatPage(
          username: widget.username,
          targetUsername: targetUsername,
          sessionKey: widget.sessionKey,
          role: widget.role,
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
        title: const Text(
          'DIRECT MESSAGES',
          style: TextStyle(
            color: accentCyan,
            fontSize: 14,
            fontWeight: FontWeight.w900,
            letterSpacing: 2,
          ),
        ),
        centerTitle: true,
      ),
      body: _loading
          ? Center(
              child: CircularProgressIndicator(
                valueColor: AlwaysStoppedAnimation(accentCyan),
              ),
            )
          : _users.isEmpty
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.people_outline,
                        size: 48,
                        color: accentCyan.withOpacity(0.5),
                      ),
                      const SizedBox(height: 16),
                      Text(
                        'No users available',
                        style: TextStyle(
                          color: Colors.white.withOpacity(0.5),
                          fontSize: 13,
                        ),
                      ),
                    ],
                  ),
                )
              : ListView.builder(
                  padding: const EdgeInsets.symmetric(vertical: 8),
                  itemCount: _users.length,
                  itemBuilder: (context, index) {
                    final user = _users[index];
                    final username = user['username'] as String;
                    final role = user['role'] as String? ?? 'member';
                    final isOwner = role == 'owner';

                    return GestureDetector(
                      onTap: () => _openPrivateChat(username),
                      child: Container(
                        margin: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 6,
                        ),
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: cardBlue,
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(
                            color: Colors.white.withOpacity(0.1),
                          ),
                        ),
                        child: Row(
                          children: [
                            // Avatar
                            Container(
                              width: 48,
                              height: 48,
                              decoration: BoxDecoration(
                                color: accentCyan.withOpacity(0.2),
                                shape: BoxShape.circle,
                                border: Border.all(
                                  color: accentCyan.withOpacity(0.5),
                                ),
                              ),
                              child: Center(
                                child: Text(
                                  username.substring(0, 1).toUpperCase(),
                                  style: const TextStyle(
                                    color: accentCyan,
                                    fontSize: 18,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                            ),
                            const SizedBox(width: 12),
                            // User info
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    children: [
                                      Text(
                                        username,
                                        style: const TextStyle(
                                          color: Colors.white,
                                          fontSize: 13,
                                          fontWeight: FontWeight.w600,
                                          letterSpacing: 0.5,
                                        ),
                                      ),
                                      if (isOwner)
                                        Container(
                                          margin: const EdgeInsets.only(left: 6),
                                          padding: const EdgeInsets.symmetric(
                                            horizontal: 6,
                                            vertical: 2,
                                          ),
                                          decoration: BoxDecoration(
                                            color: Colors.red.withOpacity(0.2),
                                            borderRadius:
                                                BorderRadius.circular(3),
                                            border: Border.all(
                                              color: Colors.red.withOpacity(0.5),
                                            ),
                                          ),
                                          child: const Text(
                                            'OWNER',
                                            style: TextStyle(
                                              color: Colors.red,
                                              fontSize: 8,
                                              fontWeight: FontWeight.bold,
                                            ),
                                          ),
                                        ),
                                    ],
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    'Tap to chat',
                                    style: TextStyle(
                                      color: Colors.white.withOpacity(0.5),
                                      fontSize: 11,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            // Arrow
                            Icon(
                              Icons.arrow_forward_rounded,
                              color: accentCyan.withOpacity(0.7),
                              size: 18,
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                ),
    );
  }
}
