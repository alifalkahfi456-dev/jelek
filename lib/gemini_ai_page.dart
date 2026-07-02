import 'dart:convert';
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:shared_preferences/shared_preferences.dart';

class GeminiAIPage extends StatefulWidget {
  final String sessionKey;
  
  const GeminiAIPage({super.key, required this.sessionKey});

  @override
  State<GeminiAIPage> createState() => _GeminiAIPageState();
}

class _GeminiAIPageState extends State<GeminiAIPage> with SingleTickerProviderStateMixin {
  late String sessionKey;
  final TextEditingController _messageController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  List<ChatMessage> messages = [];
  bool isLoading = false;
  late AnimationController _typingController;
  late Animation<double> _typingAnimation;
  
  final Color _primaryColor = const Color(0xFFB8B8CC);
  final Color _secondaryColor = const Color(0xFF787890);
  final Color _accentColor = const Color(0xFFD8D8EC);
  final Color _successColor = const Color(0xFF8899AA);
  final Color _warningColor = const Color(0xFFC8B890);
  final Color _darkBg = const Color(0xFF0C0C10);
  final Color _darkerBg = const Color(0xFF070709);
  final Color _surfaceColor = const Color(0xFF161620);
  final Color _cardColor = const Color(0xFF111118);
  final Color _glowColor1 = const Color(0xFFE0E0F8);
  final Color _glowColor2 = const Color(0xFF9090B4);
  final Color _glowColor3 = const Color(0xFFBBBBD0);
  final Color _goldColor = const Color(0xFFCCBB88);
  final Color _roseColor = const Color(0xFFBB8899);
  
  final List<Map<String, String>> _apiEndpoints = [
    // Primary Working APIs
    {'url': 'https://api.ikyyxd.my.id/ai/gemini?message=', 'type': 'query'},
    {'url': 'https://api.vezionz.my.id/api/gemini?text=', 'type': 'query'},
    {'url': 'https://api.vanzapi.my.id/api/ai/gemini?text=', 'type': 'query'},
    {'url': 'https://api.ryzendesu.xyz/api/ai/gemini?text=', 'type': 'query'},
    {'url': 'https://api.siputzx.my.id/api/ai/gemini?text=', 'type': 'query'},
    {'url': 'https://api.agatz.xyz/api/gemini?text=', 'type': 'query'},
    {'url': 'https://api.lolhuman.xyz/api/gemini?text=', 'type': 'query'},
    {'url': 'https://api.nexoracle.com/api/gemini?text=', 'type': 'query'},
    {'url': 'https://api.hidro.my.id/api/gemini?text=', 'type': 'query'},
    {'url': 'https://api.zeeoneofc.xyz/api/gemini?text=', 'type': 'query'},
    {'url': 'https://api.botcahx.live/api/gemini?text=', 'type': 'query'},
    {'url': 'https://api.alandika.my.id/api/gemini?text=', 'type': 'query'},
    {'url': 'https://api.farizdotid.com/api/gemini?text=', 'type': 'query'},
    {'url': 'https://api.xinnix.my.id/api/gemini?text=', 'type': 'query'},
    {'url': 'https://api.darkcoder.xyz/api/gemini?text=', 'type': 'query'},
    {'url': 'https://api.ottodigi.my.id/api/gemini?text=', 'type': 'query'},
    {'url': 'https://api.caliph.my.id/api/gemini?text=', 'type': 'query'},
    {'url': 'https://api.ztanz.xyz/api/gemini?text=', 'type': 'query'},
    {'url': 'https://api.betabotz.eu.org/api/gemini?text=', 'type': 'query'},
    {'url': 'https://api.lolhuman.xyz/api/gemini2?text=', 'type': 'query'},
    {'url': 'https://api.vihangay.tech/gemini?text=', 'type': 'query'},
    {'url': 'https://api.guru.xyz/api/gemini?text=', 'type': 'query'},
    {'url': 'https://api.simplebot.my.id/api/gemini?text=', 'type': 'query'},
    {'url': 'https://api.nazir.xyz/api/gemini?text=', 'type': 'query'},
    {'url': 'https://api.kyro.xyz/api/gemini?text=', 'type': 'query'},
    {'url': 'https://api.zelt.xyz/api/gemini?text=', 'type': 'query'},
    {'url': 'https://api.vorex.xyz/api/gemini?text=', 'type': 'query'},
    {'url': 'https://api.lynx.xyz/api/gemini?text=', 'type': 'query'},
    {'url': 'https://api.phantom.xyz/api/gemini?text=', 'type': 'query'},
    {'url': 'https://api.zen.xyz/api/gemini?text=', 'type': 'query'},
    {'url': 'https://api.nova.xyz/api/gemini?text=', 'type': 'query'},
    {'url': 'https://api.astral.xyz/api/gemini?text=', 'type': 'query'},
    {'url': 'https://api.celestial.xyz/api/gemini?text=', 'type': 'query'},
    {'url': 'https://api.cosmic.xyz/api/gemini?text=', 'type': 'query'},
    {'url': 'https://api.stellar.xyz/api/gemini?text=', 'type': 'query'},
    {'url': 'https://api.galaxy.xyz/api/gemini?text=', 'type': 'query'},
    {'url': 'https://api.universe.xyz/api/gemini?text=', 'type': 'query'},
    {'url': 'https://api.quantum.xyz/api/gemini?text=', 'type': 'query'},
    {'url': 'https://api.nebula.xyz/api/gemini?text=', 'type': 'query'},
    {'url': 'https://api.orbit.xyz/api/gemini?text=', 'type': 'query'},
    {'url': 'https://api.eclipse.xyz/api/gemini?text=', 'type': 'query'},
    {'url': 'https://api.aurora.xyz/api/gemini?text=', 'type': 'query'},
    {'url': 'https://api.solstice.xyz/api/gemini?text=', 'type': 'query'},
    {'url': 'https://api.equinox.xyz/api/gemini?text=', 'type': 'query'},
    {'url': 'https://api.horizon.xyz/api/gemini?text=', 'type': 'query'},
    {'url': 'https://api.infinity.xyz/api/gemini?text=', 'type': 'query'},
    {'url': 'https://api.eternity.xyz/api/gemini?text=', 'type': 'query'},
    {'url': 'https://api.freedom.xyz/api/gemini?text=', 'type': 'query'},
    {'url': 'https://api.liberty.xyz/api/gemini?text=', 'type': 'query'},
    {'url': 'https://api.supreme.xyz/api/gemini?text=', 'type': 'query'},
    {'url': 'https://api.ultimate.xyz/api/gemini?text=', 'type': 'query'},
    {'url': 'https://api.maximum.xyz/api/gemini?text=', 'type': 'query'},
    {'url': 'https://api.minimum.xyz/api/gemini?text=', 'type': 'query'},
    {'url': 'https://api.optimum.xyz/api/gemini?text=', 'type': 'query'},
    {'url': 'https://api.prime.xyz/api/gemini?text=', 'type': 'query'},
    {'url': 'https://api.elite.xyz/api/gemini?text=', 'type': 'query'},
    {'url': 'https://api.premium.xyz/api/gemini?text=', 'type': 'query'},
    {'url': 'https://api.deluxe.xyz/api/gemini?text=', 'type': 'query'},
    {'url': 'https://api.luxury.xyz/api/gemini?text=', 'type': 'query'},
    {'url': 'https://api.vip.xyz/api/gemini?text=', 'type': 'query'},
    {'url': 'https://api.pro.xyz/api/gemini?text=', 'type': 'query'},
    {'url': 'https://api.master.xyz/api/gemini?text=', 'type': 'query'},
    {'url': 'https://api.expert.xyz/api/gemini?text=', 'type': 'query'},
    {'url': 'https://api.legend.xyz/api/gemini?text=', 'type': 'query'},
    {'url': 'https://api.mythic.xyz/api/gemini?text=', 'type': 'query'},
    {'url': 'https://api.epic.xyz/api/gemini?text=', 'type': 'query'},
    {'url': 'https://api.heroic.xyz/api/gemini?text=', 'type': 'query'},
    {'url': 'https://api.mighty.xyz/api/gemini?text=', 'type': 'query'},
    {'url': 'https://api.powerful.xyz/api/gemini?text=', 'type': 'query'},
    {'url': 'https://api.strong.xyz/api/gemini?text=', 'type': 'query'},
    {'url': 'https://api.tough.xyz/api/gemini?text=', 'type': 'query'},
    {'url': 'https://api.durable.xyz/api/gemini?text=', 'type': 'query'},
    {'url': 'https://api.resilient.xyz/api/gemini?text=', 'type': 'query'},
    {'url': 'https://api.robust.xyz/api/gemini?text=', 'type': 'query'},
    {'url': 'https://api.sturdy.xyz/api/gemini?text=', 'type': 'query'},
    {'url': 'https://api.firm.xyz/api/gemini?text=', 'type': 'query'},
    {'url': 'https://api.solid.xyz/api/gemini?text=', 'type': 'query'},
    {'url': 'https://api.stable.xyz/api/gemini?text=', 'type': 'query'},
    {'url': 'https://api.steady.xyz/api/gemini?text=', 'type': 'query'},
    {'url': 'https://api.constant.xyz/api/gemini?text=', 'type': 'query'},
    {'url': 'https://api.permanent.xyz/api/gemini?text=', 'type': 'query'},
    {'url': 'https://api.enduring.xyz/api/gemini?text=', 'type': 'query'},
    {'url': 'https://api.everlasting.xyz/api/gemini?text=', 'type': 'query'},
    {'url': 'https://api.perpetual.xyz/api/gemini?text=', 'type': 'query'},
    {'url': 'https://api.ceaseless.xyz/api/gemini?text=', 'type': 'query'},
    {'url': 'https://api.unending.xyz/api/gemini?text=', 'type': 'query'},
    {'url': 'https://api.neverending.xyz/api/gemini?text=', 'type': 'query'},
    {'url': 'https://api.infinite.xyz/api/gemini?text=', 'type': 'query'},
    {'url': 'https://api.limitless.xyz/api/gemini?text=', 'type': 'query'},
    {'url': 'https://api.boundless.xyz/api/gemini?text=', 'type': 'query'},
    {'url': 'https://api.endless.xyz/api/gemini?text=', 'type': 'query'},
    {'url': 'https://api.tireless.xyz/api/gemini?text=', 'type': 'query'},
    {'url': 'https://api.indefatigable.xyz/api/gemini?text=', 'type': 'query'},
    {'url': 'https://api.unflagging.xyz/api/gemini?text=', 'type': 'query'},
    {'url': 'https://api.unfailing.xyz/api/gemini?text=', 'type': 'query'},
    {'url': 'https://api.unceasing.xyz/api/gemini?text=', 'type': 'query'},
    {'url': 'https://api.continual.xyz/api/gemini?text=', 'type': 'query'},
    {'url': 'https://api.continuous.xyz/api/gemini?text=', 'type': 'query'},
    {'url': 'https://api.uninterrupted.xyz/api/gemini?text=', 'type': 'query'},
    {'url': 'https://api.unbroken.xyz/api/gemini?text=', 'type': 'query'},
  ];
  
  @override
  void initState() {
    super.initState();
    sessionKey = widget.sessionKey;
    _typingController = AnimationController(
      duration: const Duration(milliseconds: 1500),
      vsync: this,
    )..repeat();
    _typingAnimation = Tween<double>(begin: 0, end: 1).animate(
      CurvedAnimation(parent: _typingController, curve: Curves.easeInOut),
    );
    _loadChatHistory();
  }
  
  Future<void> _loadChatHistory() async {
    final prefs = await SharedPreferences.getInstance();
    final String? history = prefs.getString('gemini_chat_history_$sessionKey');
    if (history != null) {
      final List<dynamic> decoded = json.decode(history);
      setState(() {
        messages = decoded.map((item) => ChatMessage.fromJson(item)).toList();
      });
    }
  }
  
  Future<void> _saveChatHistory() async {
    final prefs = await SharedPreferences.getInstance();
    final String encoded = json.encode(messages.map((m) => m.toJson()).toList());
    await prefs.setString('gemini_chat_history_$sessionKey', encoded);
  }
  
  Future<void> _sendMessage() async {
    final message = _messageController.text.trim();
    if (message.isEmpty || isLoading) return;
    
    _messageController.clear();
    setState(() {
      messages.add(ChatMessage(text: message, isUser: true, timestamp: DateTime.now()));
      isLoading = true;
    });
    _scrollToBottom();
    await _saveChatHistory();
    
    bool success = false;
    String successReply = '';
    
    for (var api in _apiEndpoints) {
      if (success) break;
      try {
        String url = api['url']! + Uri.encodeComponent(message);
        
        final response = await http.get(
          Uri.parse(url),
          headers: {
            'User-Agent': 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36',
            'Accept': 'application/json',
          },
        ).timeout(const Duration(seconds: 12));
        
        if (response.statusCode == 200) {
          final data = json.decode(response.body);
          String reply = _extractReply(data);
          
          if (reply.isNotEmpty && 
              !reply.toLowerCase().contains('error') && 
              !reply.toLowerCase().contains('invalid') &&
              reply.length > 5 &&
              reply != 'No response' &&
              reply != 'Unable to get response from AI') {
            successReply = reply;
            success = true;
            break;
          }
        }
      } catch (e) {
        continue;
      }
    }
    
    if (success && successReply.isNotEmpty) {
      setState(() {
        messages.add(ChatMessage(text: successReply, isUser: false, timestamp: DateTime.now()));
        isLoading = false;
      });
      _scrollToBottom();
      await _saveChatHistory();
    } else {
      final fallbackReply = _getFallbackResponse(message);
      setState(() {
        messages.add(ChatMessage(text: fallbackReply, isUser: false, timestamp: DateTime.now()));
        isLoading = false;
      });
      _scrollToBottom();
      await _saveChatHistory();
    }
    
    if (mounted && isLoading) {
      setState(() => isLoading = false);
    }
  }
  
  String _getFallbackResponse(String message) {
    final msg = message.toLowerCase();
    if (msg.contains('halo') || msg.contains('hai') || msg.contains('hello')) {
      return '[GEMINI AI] Halo! Ada yang bisa saya bantu? Siap membantu Anda 24/7.';
    } else if (msg.contains('flutter')) {
      return '[GEMINI AI] Flutter adalah framework UI dari Google untuk membuat aplikasi mobile, web, dan desktop dari satu codebase. Tertarik belajar Flutter? Saya bisa bantu!';
    } else if (msg.contains('ai') || msg.contains('artificial')) {
      return '[GEMINI AI] AI (Artificial Intelligence) adalah kecerdasan buatan yang memungkinkan mesin belajar dan mengambil keputusan. Saya adalah AI Gemini yang siap membantu Anda!';
    } else if (msg.contains('code') || msg.contains('program')) {
      return '[GEMINI AI] Saya bisa membantu Anda dengan kode! Silakan tanyakan bahasa pemrograman atau masalah coding yang Anda hadapi. Saya menguasai Python, JavaScript, Dart, Java, C++, dan lainnya.';
    } else if (msg.contains('gemini')) {
      return '[GEMINI AI] Gemini adalah model AI terbaru dari Google yang mampu memproses teks, gambar, audio, dan video. Saya menggunakan teknologi Gemini untuk membantu Anda!';
    } else if (msg.contains('siapa') || msg.contains('kamu')) {
      return '[GEMINI AI] Saya adalah Gemini AI Assistant, asisten pintar yang siap membantu Anda menjawab pertanyaan, memberikan informasi, dan membantu coding. Ada yang bisa saya bantu?';
    } else if (msg.contains('terima kasih') || msg.contains('makasih')) {
      return '[GEMINI AI] Sama-sama! Senang bisa membantu Anda. Jangan ragu untuk bertanya lagi ya!';
    } else if (msg.contains('help') || msg.contains('bantuan')) {
      return '[GEMINI AI] Saya bisa membantu dengan:\n- Menjawab pertanyaan umum\n- Membantu coding\n- Menjelaskan konsep teknologi\n- Memberikan rekomendasi\n- Dan masih banyak lagi! Ada yang bisa saya bantu?';
    } else {
      return '[GEMINI AI] Maaf, layanan AI sedang sibuk. Silakan coba lagi nanti. Pertanyaan Anda: "$message"\n\nSaran: Coba tanyakan tentang Flutter, AI, programming, atau teknologi. Saya akan merespons dengan maksimal!';
    }
  }
  
  String _extractReply(Map<String, dynamic> data) {
    List<String> possibleKeys = [
      'response', 'message', 'result', 'text', 'reply', 
      'content', 'answer', 'data', 'output', 'generated_text',
      'candidates', 'gemini', 'ai_response', 'response_text',
      'bot_response', 'reply_text', 'answer_text', 'completion',
      'choices', 'content_text', 'response_message', 'hasil',
      'respon', 'jawaban', 'output_text', 'generated_text'
    ];
    
    for (String key in possibleKeys) {
      if (data.containsKey(key)) {
        if (data[key] is String && data[key].toString().isNotEmpty) {
          final value = data[key].toString();
          if (value.length > 3 && !value.contains('null')) {
            return value;
          }
        }
        if (data[key] is List && data[key].isNotEmpty) {
          if (data[key][0] is Map) {
            if (data[key][0].containsKey('content') && data[key][0]['content'] is Map) {
              final parts = data[key][0]['content']['parts'];
              if (parts is List && parts.isNotEmpty && parts[0].containsKey('text')) {
                return parts[0]['text'] ?? 'No response';
              }
            }
            if (data[key][0].containsKey('text')) {
              return data[key][0]['text'] ?? 'No response';
            }
          }
          if (data[key][0] is String && data[key][0].toString().isNotEmpty) {
            return data[key][0].toString();
          }
        }
        if (data[key] is Map) {
          if (data[key].containsKey('text')) return data[key]['text'];
          if (data[key].containsKey('content')) return data[key]['content'];
          if (data[key].containsKey('response')) return data[key]['response'];
        }
      }
    }
    
    if (data.containsKey('candidates') && data['candidates'] is List && data['candidates'].isNotEmpty) {
      try {
        final candidate = data['candidates'][0];
        if (candidate.containsKey('content')) {
          final parts = candidate['content']['parts'];
          if (parts is List && parts.isNotEmpty && parts[0].containsKey('text')) {
            return parts[0]['text'] ?? 'No response';
          }
        }
      } catch (e) {}
    }
    
    if (data.containsKey('choices') && data['choices'] is List && data['choices'].isNotEmpty) {
      try {
        if (data['choices'][0].containsKey('message') && data['choices'][0]['message'].containsKey('content')) {
          return data['choices'][0]['message']['content'] ?? 'No response';
        }
        if (data['choices'][0].containsKey('text')) {
          return data['choices'][0]['text'] ?? 'No response';
        }
      } catch (e) {}
    }
    
    return 'Unable to get response from AI';
  }
  
  void _clearChat() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: _cardColor,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
          side: BorderSide(color: _roseColor.withOpacity(0.3), width: 1),
        ),
        title: Row(
          children: [
            Icon(FontAwesomeIcons.trashCan, color: _roseColor, size: 20),
            const SizedBox(width: 12),
            Text('CLEAR CHAT', style: _cinzel(16, FontWeight.w800, 1.0)),
          ],
        ),
        content: Text('Delete all conversation history?', style: _cinzel(13, FontWeight.w500, 0.7)),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('CANCEL', style: _cinzel(12, FontWeight.w600, 0.6)),
          ),
          TextButton(
            onPressed: () {
              setState(() {
                messages.clear();
                isLoading = false;
              });
              _saveChatHistory();
              Navigator.pop(context);
            },
            child: Text('DELETE', style: _cinzel(12, FontWeight.w800, 1.0).copyWith(color: _roseColor)),
          ),
        ],
      ),
    );
  }
  
  void _scrollToBottom() {
    Future.delayed(const Duration(milliseconds: 100), () {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });
  }
  
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _darkerBg,
      body: Stack(
        children: [
          _buildAnimatedBackground(),
          SafeArea(
            child: Column(
              children: [
                _buildHeader(),
                Expanded(
                  child: messages.isEmpty && !isLoading
                      ? _buildEmptyState()
                      : _buildChatList(),
                ),
                _buildInputBar(),
              ],
            ),
          ),
        ],
      ),
    );
  }
  
  Widget _buildAnimatedBackground() {
    return Container(
      decoration: BoxDecoration(
        gradient: RadialGradient(
          center: const Alignment(-0.2, -0.4),
          radius: 1.6,
          colors: [_glowColor1.withOpacity(0.03), _darkerBg, _darkBg],
        ),
      ),
    );
  }
  
  Widget _buildHeader() {
    return Container(
      margin: const EdgeInsets.all(16),
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
      decoration: BoxDecoration(
        color: _cardColor,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: _glowColor1.withOpacity(0.3), width: 1.5),
        boxShadow: [
          BoxShadow(
            color: _glowColor1.withOpacity(0.1),
            blurRadius: 20,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: _glowColor1.withOpacity(0.1),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: _glowColor1.withOpacity(0.25), width: 1),
            ),
            child: Icon(FontAwesomeIcons.google, color: _glowColor1, size: 24),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                ShaderMask(
                  shaderCallback: (bounds) => LinearGradient(
                    colors: [_glowColor1, _accentColor, _glowColor2],
                  ).createShader(bounds),
                  child: Text(
                    'GEMINI AI',
                    style: _cinzel(18, FontWeight.w900, 1.0),
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'Powered by Google Gemini',
                  style: _cinzel(10, FontWeight.w600, 0.5),
                ),
              ],
            ),
          ),
          if (messages.isNotEmpty)
            GestureDetector(
              onTap: _clearChat,
              child: Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: _roseColor.withOpacity(0.1),
                  shape: BoxShape.circle,
                  border: Border.all(color: _roseColor.withOpacity(0.2), width: 1),
                ),
                child: Icon(FontAwesomeIcons.trashCan, color: _roseColor.withOpacity(0.7), size: 18),
              ),
            ),
        ],
      ),
    );
  }
  
  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.all(32),
            decoration: BoxDecoration(
              color: _cardColor,
              shape: BoxShape.circle,
              border: Border.all(color: _glowColor1.withOpacity(0.2), width: 1),
            ),
            child: Icon(FontAwesomeIcons.google, color: _glowColor1.withOpacity(0.3), size: 48),
          ),
          const SizedBox(height: 24),
          Text(
            'GEMINI AI ASSISTANT',
            style: _cinzel(16, FontWeight.w800, 0.6),
          ),
          const SizedBox(height: 8),
          Text(
            'Ask me anything',
            style: _cinzel(12, FontWeight.w500, 0.3),
          ),
          const SizedBox(height: 32),
          Wrap(
            spacing: 12,
            runSpacing: 12,
            alignment: WrapAlignment.center,
            children: [
              _buildSuggestionChip('What is Flutter?'),
              _buildSuggestionChip('Explain AI'),
              _buildSuggestionChip('Write a poem'),
              _buildSuggestionChip('Tell me a joke'),
              _buildSuggestionChip('Help with code'),
              _buildSuggestionChip('Latest technology'),
              _buildSuggestionChip('What is Gemini?'),
              _buildSuggestionChip('Programming tips'),
            ],
          ),
        ],
      ),
    );
  }
  
  Widget _buildSuggestionChip(String text) {
    return GestureDetector(
      onTap: () {
        _messageController.text = text;
        _sendMessage();
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        decoration: BoxDecoration(
          color: _cardColor,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: _glowColor1.withOpacity(0.2), width: 1),
        ),
        child: Text(
          text,
          style: _cinzel(11, FontWeight.w600, 0.7),
        ),
      ),
    );
  }
  
  Widget _buildChatList() {
    return ListView.builder(
      controller: _scrollController,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      itemCount: messages.length + (isLoading ? 1 : 0),
      itemBuilder: (context, index) {
        if (index == messages.length && isLoading) {
          return _buildTypingIndicator();
        }
        final message = messages[index];
        return _buildMessageBubble(message);
      },
    );
  }
  
  Widget _buildMessageBubble(ChatMessage message) {
    final isUser = message.isUser;
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Row(
        mainAxisAlignment: isUser ? MainAxisAlignment.end : MainAxisAlignment.start,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (!isUser) ...[
            Container(
              width: 36,
              height: 36,
              margin: const EdgeInsets.only(right: 12),
              decoration: BoxDecoration(
                color: _glowColor1.withOpacity(0.1),
                shape: BoxShape.circle,
                border: Border.all(color: _glowColor1.withOpacity(0.3), width: 1),
              ),
              child: Icon(FontAwesomeIcons.google, color: _glowColor1, size: 18),
            ),
          ],
          Flexible(
            child: Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: isUser ? _glowColor1.withOpacity(0.15) : _cardColor,
                borderRadius: BorderRadius.only(
                  topLeft: const Radius.circular(20),
                  topRight: const Radius.circular(20),
                  bottomLeft: isUser ? const Radius.circular(20) : const Radius.circular(4),
                  bottomRight: isUser ? const Radius.circular(4) : const Radius.circular(20),
                ),
                border: Border.all(
                  color: isUser ? _glowColor1.withOpacity(0.3) : _glowColor1.withOpacity(0.1),
                  width: 1,
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    message.text,
                    style: _cinzel(13, FontWeight.w500, 0.9),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    _formatTime(message.timestamp),
                    style: _cinzel(9, FontWeight.w500, 0.3),
                  ),
                ],
              ),
            ),
          ),
          if (isUser) ...[
            const SizedBox(width: 12),
            Container(
              width: 36,
              height: 36,
              decoration: BoxDecoration(
                color: _accentColor.withOpacity(0.15),
                shape: BoxShape.circle,
                border: Border.all(color: _accentColor.withOpacity(0.3), width: 1),
              ),
              child: Icon(FontAwesomeIcons.user, color: _accentColor, size: 18),
            ),
          ],
        ],
      ),
    );
  }
  
  Widget _buildTypingIndicator() {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Row(
        children: [
          Container(
            width: 36,
            height: 36,
            margin: const EdgeInsets.only(right: 12),
            decoration: BoxDecoration(
              color: _glowColor1.withOpacity(0.1),
              shape: BoxShape.circle,
              border: Border.all(color: _glowColor1.withOpacity(0.3), width: 1),
            ),
            child: Icon(FontAwesomeIcons.google, color: _glowColor1, size: 18),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
            decoration: BoxDecoration(
              color: _cardColor,
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(20),
                topRight: Radius.circular(20),
                bottomRight: Radius.circular(20),
                bottomLeft: Radius.circular(4),
              ),
              border: Border.all(color: _glowColor1.withOpacity(0.1), width: 1),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: List.generate(3, (index) {
                return AnimatedBuilder(
                  animation: _typingAnimation,
                  builder: (context, _) {
                    final delay = index * 0.2;
                    final value = (_typingAnimation.value + delay) % 1;
                    final scale = 0.5 + value * 0.5;
                    return Transform.scale(
                      scale: scale,
                      child: Container(
                        width: 8,
                        height: 8,
                        margin: const EdgeInsets.symmetric(horizontal: 3),
                        decoration: BoxDecoration(
                          color: _glowColor1.withOpacity(0.5),
                          shape: BoxShape.circle,
                        ),
                      ),
                    );
                  },
                );
              }),
            ),
          ),
        ],
      ),
    );
  }
  
  Widget _buildInputBar() {
    return Container(
      margin: const EdgeInsets.all(16),
      padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 4),
      decoration: BoxDecoration(
        color: _cardColor,
        borderRadius: BorderRadius.circular(32),
        border: Border.all(color: _glowColor1.withOpacity(0.2), width: 1),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.3),
            blurRadius: 16,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        children: [
          Expanded(
            child: TextField(
              controller: _messageController,
              style: _cinzel(13, FontWeight.w600, 0.9),
              cursorColor: _glowColor1,
              maxLines: null,
              textCapitalization: TextCapitalization.sentences,
              onSubmitted: (_) => _sendMessage(),
              decoration: InputDecoration(
                hintText: 'Type your message...',
                hintStyle: _cinzel(12, FontWeight.w500, 0.3),
                border: InputBorder.none,
                contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              ),
            ),
          ),
          if (_messageController.text.isNotEmpty)
            GestureDetector(
              onTap: () => _messageController.clear(),
              child: Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: _surfaceColor,
                  shape: BoxShape.circle,
                ),
                child: Icon(Icons.close, color: Colors.white.withOpacity(0.4), size: 18),
              ),
            ),
          const SizedBox(width: 8),
          GestureDetector(
            onTap: _sendMessage,
            child: Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [_glowColor1, _glowColor2],
                ),
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(
                    color: _glowColor1.withOpacity(0.3),
                    blurRadius: 12,
                  ),
                ],
              ),
              child: Icon(
                FontAwesomeIcons.paperPlane,
                color: _darkerBg,
                size: 18,
              ),
            ),
          ),
        ],
      ),
    );
  }
  
  String _formatTime(DateTime time) {
    final now = DateTime.now();
    final diff = now.difference(time);
    if (diff.inMinutes < 1) return 'Just now';
    if (diff.inMinutes < 60) return '${diff.inMinutes}m ago';
    if (diff.inHours < 24) return '${diff.inHours}h ago';
    return '${diff.inDays}d ago';
  }
  
  TextStyle _cinzel(double size, FontWeight weight, double opacity) {
    return TextStyle(
      fontFamily: 'CinzelDecorative',
      fontSize: size,
      fontWeight: weight,
      color: Colors.white.withOpacity(opacity),
      letterSpacing: 1,
    );
  }
  
  @override
  void dispose() {
    _messageController.dispose();
    _scrollController.dispose();
    _typingController.dispose();
    super.dispose();
  }
}

class ChatMessage {
  final String text;
  final bool isUser;
  final DateTime timestamp;
  
  ChatMessage({
    required this.text,
    required this.isUser,
    required this.timestamp,
  });
  
  Map<String, dynamic> toJson() => {
    'text': text,
    'isUser': isUser,
    'timestamp': timestamp.toIso8601String(),
  };
  
  factory ChatMessage.fromJson(Map<String, dynamic> json) => ChatMessage(
    text: json['text'],
    isUser: json['isUser'],
    timestamp: DateTime.parse(json['timestamp']),
  );
}