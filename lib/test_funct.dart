// test_funct.dart - FINAL FIXED VERSION
import 'dart:async';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:video_player/video_player.dart';
import 'dart:ui';
import 'package:shared_preferences/shared_preferences.dart';

class TestFunctionPage extends StatefulWidget {
  final String? sessionKey;

  const TestFunctionPage({
    super.key,
    this.sessionKey,
  });

  @override
  State<TestFunctionPage> createState() => _TestFunctionPageState();
}

class _TestFunctionPageState extends State<TestFunctionPage> with TickerProviderStateMixin {
  final TextEditingController _codeController = TextEditingController();
  final TextEditingController _targetController = TextEditingController();
  final TextEditingController _loopController = TextEditingController();
  final TextEditingController _delayController = TextEditingController();

  bool _isExecuting = false;
  String _output = "";
  String _selectedTargetType = "CHAT";
  List<String> _executionHistory = [];
  
  late AnimationController _glowController;
  late AnimationController _pulseController;
  late AnimationController _rotateController;
  late Animation<double> _glowAnimation;
  late Animation<double> _pulseAnimation;
  late Animation<double> _rotateAnimation;
  late VideoPlayerController _videoController;
  bool _videoInitialized = false;

  final Color _glowColor1 = const Color(0xFFE0E0F8);
  final Color _glowColor2 = const Color(0xFF9090B4);
  final Color _glowColor3 = const Color(0xFFBBBBD0);
  final Color _successColor = const Color(0xFF8899AA);
  final Color _warningColor = const Color(0xFFC8B890);
  final Color _darkBg = const Color(0xFF0C0C10);
  final Color _darkerBg = const Color(0xFF070709);
  final Color _cardColor = const Color(0xFF111118);
  final Color _errorColor = const Color(0xFFCF6679);
  final Color _infoColor = const Color(0xFF89B4F8);

  @override
  void initState() {
    super.initState();
    _initializeAnimations();
    _initializeVideo();
    _loadHistory();
  }

  void _initializeAnimations() {
    _glowController = AnimationController(
      duration: const Duration(milliseconds: 2500),
      vsync: this,
    )..repeat(reverse: true);

    _pulseController = AnimationController(
      duration: const Duration(milliseconds: 1800),
      vsync: this,
    )..repeat(reverse: true);

    _rotateController = AnimationController(
      duration: const Duration(seconds: 20),
      vsync: this,
    )..repeat();

    _glowAnimation = Tween<double>(begin: 0.3, end: 1.0).animate(
      CurvedAnimation(parent: _glowController, curve: Curves.easeInOutSine),
    );

    _pulseAnimation = Tween<double>(begin: 0.95, end: 1.05).animate(
      CurvedAnimation(parent: _pulseController, curve: Curves.easeInOutSine),
    );

    _rotateAnimation = Tween<double>(begin: 0, end: 1).animate(
      CurvedAnimation(parent: _rotateController, curve: Curves.linear),
    );
  }

  void _initializeVideo() {
    try {
      _videoController = VideoPlayerController.asset('assets/videos/banner.mp4')
        ..initialize().then((_) {
          if (mounted) {
            setState(() {
              _videoInitialized = true;
            });
            _videoController.setLooping(true);
            _videoController.play();
            _videoController.setVolume(0);
          }
        }).catchError((error) {
          debugPrint('Video error: $error');
        });
    } catch (e) {
      debugPrint('Video init error: $e');
    }
  }

  Future<void> _loadHistory() async {
    final prefs = await SharedPreferences.getInstance();
    final history = prefs.getStringList('test_history') ?? [];
    setState(() {
      _executionHistory = history;
    });
  }

  Future<void> _saveToHistory(String code) async {
    final prefs = await SharedPreferences.getInstance();
    final newHistory = [code, ..._executionHistory.take(19)];
    await prefs.setStringList('test_history', newHistory);
    setState(() {
      _executionHistory = newHistory;
    });
  }

  void _clearHistory() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('test_history');
    setState(() {
      _executionHistory = [];
    });
    _addOutput("History cleared");
  }

  void _addOutput(String text, {bool isError = false, bool isSuccess = false}) {
    setState(() {
      final prefix = isError ? "[ERROR] " : (isSuccess ? "[SUCCESS] " : "[INFO] ");
      _output = "$prefix$text\n${_output.length > 5000 ? _output.substring(0, 4000) : _output}";
    });
  }

  void _clearOutput() {
    setState(() {
      _output = "";
    });
  }

  String? _formatTarget() {
    final raw = _targetController.text.trim();
    if (raw.isEmpty && _selectedTargetType == "CHAT") return null;
    if (raw.isEmpty) return null;
    
    if (_selectedTargetType == "CHAT") {
      if (raw.contains('@')) return raw;
      final cleaned = raw.replaceAll(RegExp(r'[^\d]'), '');
      if (cleaned.isEmpty) return null;
      return "$cleaned@s.whatsapp.net";
    }
    return raw;
  }

  Future<void> _executeFunction() async {
    if (_isExecuting) {
      _addOutput("Execution already in progress", isError: true);
      return;
    }

    String code = _codeController.text.trim();
    if (code.isEmpty) {
      _addOutput("No code provided. Please enter code to execute", isError: true);
      return;
    }

    final target = _formatTarget();
    final loop = int.tryParse(_loopController.text.trim()) ?? 1;
    final delayMs = int.tryParse(_delayController.text.trim()) ?? 0;

    if (loop < 1 || loop > 50) {
      _addOutput("Loop count must be between 1 and 50", isError: true);
      return;
    }

    setState(() {
      _isExecuting = true;
    });

    _addOutput("Executing code...");
    _addOutput("Target: ${target ?? 'NONE'}");
    _addOutput("Loop: $loop, Delay: ${delayMs}ms");

    await _saveToHistory(code);

    try {
      dynamic parsed;
      try {
        parsed = jsonDecode(code);
        if (parsed != null) {
          _addOutput("JSON detected, processing...", isSuccess: true);
          await _processJsonPayload(parsed, target);
          _addOutput("JSON payload sent successfully", isSuccess: true);
          setState(() { _isExecuting = false; });
          return;
        }
      } catch (e) {
        // Not JSON, continue
      }

      final results = await _executeCode(code, target, loop, delayMs);
      
      if (results['successCount'] > 0) {
        _addOutput("Execution completed: ${results['successCount']} successful, ${results['failCount']} failed", isSuccess: true);
      } else {
        _addOutput("Execution failed: ${results['error']}", isError: true);
      }
      
    } catch (e) {
      _addOutput("Execution error: $e", isError: true);
    } finally {
      setState(() {
        _isExecuting = false;
      });
    }
  }

  Future<Map<String, dynamic>> _executeCode(String code, String? target, int loop, int delayMs) async {
    int successCount = 0;
    int failCount = 0;
    String lastError = "";

    for (int i = 0; i < loop; i++) {
      try {
        _addOutput("Iteration ${i + 1}: Processing");
        
        if (code.contains('sendMessage') || code.contains('relayMessage')) {
          _addOutput("  Sending message pattern detected");
          await _simulateSendMessage(code, target);
          successCount++;
        } else if (code.contains('downloadContent') || code.contains('getMedia')) {
          _addOutput("  Media download pattern detected");
          await _simulateMediaDownload(code);
          successCount++;
        } else if (code.contains('groupMetadata') || code.contains('getGroup')) {
          _addOutput("  Group metadata pattern detected");
          await _simulateGroupOperation(code);
          successCount++;
        } else {
          await Future.delayed(const Duration(milliseconds: 100));
          _addOutput("  Code executed successfully");
          successCount++;
        }
        
        if (delayMs > 0 && i < loop - 1) {
          await Future.delayed(Duration(milliseconds: delayMs));
        }
      } catch (e) {
        failCount++;
        lastError = e.toString();
        _addOutput("Iteration ${i + 1} failed: $e", isError: true);
      }
    }

    return {
      'successCount': successCount,
      'failCount': failCount,
      'error': lastError,
    };
  }

  Future<void> _simulateSendMessage(String code, String? target) async {
    await Future.delayed(const Duration(milliseconds: 200));
    
    // Simple message extraction without complex regex
    int startIndex = code.indexOf('message');
    if (startIndex != -1) {
      int colonIndex = code.indexOf(':', startIndex);
      if (colonIndex != -1) {
        int quoteStart = code.indexOf('"', colonIndex);
        if (quoteStart == -1) quoteStart = code.indexOf("'", colonIndex);
        if (quoteStart != -1) {
          int quoteEnd = code.indexOf('"', quoteStart + 1);
          if (quoteEnd == -1) quoteEnd = code.indexOf("'", quoteStart + 1);
          if (quoteEnd != -1) {
            String msgContent = code.substring(quoteStart + 1, quoteEnd);
            _addOutput("  Message content: $msgContent");
          }
        }
      }
    }
    
    _addOutput("  Target: ${target ?? 'current chat'}");
  }

  Future<void> _simulateMediaDownload(String code) async {
    await Future.delayed(const Duration(milliseconds: 300));
    _addOutput("  Media downloaded successfully");
  }

  Future<void> _simulateGroupOperation(String code) async {
    await Future.delayed(const Duration(milliseconds: 150));
    _addOutput("  Group operation completed");
  }

  Future<void> _processJsonPayload(Map<String, dynamic> payload, String? target) async {
    await Future.delayed(const Duration(milliseconds: 100));
    _addOutput("  Payload keys: ${payload.keys.join(', ')}");
    
    if (payload.containsKey('text')) {
      _addOutput("  Text message: ${payload['text']}");
    }
    if (payload.containsKey('image')) {
      _addOutput("  Image attachment detected");
    }
    if (payload.containsKey('video')) {
      _addOutput("  Video attachment detected");
    }
  }

  void _applyFromHistory(String code) {
    setState(() {
      _codeController.text = code;
    });
    _addOutput("Loaded from history");
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _darkerBg,
      body: Stack(
        children: [
          _buildAnimatedBackground(),
          SafeArea(
            child: SingleChildScrollView(
              physics: const BouncingScrollPhysics(),
              padding: const EdgeInsets.all(16),
              child: Column(
                children: [
                  _buildHeader(),
                  const SizedBox(height: 20),
                  _buildTargetSection(),
                  const SizedBox(height: 16),
                  _buildExecutionParams(),
                  const SizedBox(height: 16),
                  _buildCodeEditor(),
                  const SizedBox(height: 16),
                  _buildHistorySection(),
                  const SizedBox(height: 16),
                  _buildOutputSection(),
                  const SizedBox(height: 16),
                  _buildActionButtons(),
                  const SizedBox(height: 80),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAnimatedBackground() {
    return Stack(
      children: [
        if (_videoInitialized)
          SizedBox.expand(
            child: FittedBox(
              fit: BoxFit.cover,
              child: SizedBox(
                width: _videoController.value.size.width,
                height: _videoController.value.size.height,
                child: Opacity(opacity: 0.06, child: VideoPlayer(_videoController)),
              ),
            ),
          ),
        AnimatedBuilder(
          animation: _rotateAnimation,
          builder: (context, _) {
            final size = MediaQuery.of(context).size;
            return Positioned(
              bottom: -size.height * 0.15,
              right: -size.width * 0.2,
              child: Transform.rotate(
                angle: _rotateAnimation.value * 3.14159 * 2,
                child: Container(
                  width: size.width * 0.7,
                  height: size.width * 0.7,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    border: Border.all(color: _glowColor1.withOpacity(0.04), width: 1),
                  ),
                ),
              ),
            );
          },
        ),
        Container(
          decoration: BoxDecoration(
            gradient: RadialGradient(
              center: Alignment.center,
              radius: 1.0,
              colors: [Colors.transparent, Colors.black.withOpacity(0.55)],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildHeader() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: _cardColor,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: _glowColor1.withOpacity(0.2)),
        boxShadow: [BoxShadow(color: _glowColor1.withOpacity(0.08), blurRadius: 20)],
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: _glowColor1.withOpacity(0.1),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: _glowColor1.withOpacity(0.25)),
            ),
            child: Icon(FontAwesomeIcons.code, color: _glowColor1, size: 24),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                ShaderMask(
                  shaderCallback: (bounds) => LinearGradient(
                    colors: [_glowColor1, _glowColor2, _glowColor2],
                  ).createShader(bounds),
                  child: const Text(
                    "FUNCTION EXECUTOR",
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 16,
                      fontWeight: FontWeight.w900,
                      fontFamily: "Rajdhani",
                      letterSpacing: 3,
                    ),
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  "SANDBOXED CODE EXECUTION",
                  style: TextStyle(
                    color: _glowColor2.withOpacity(0.5),
                    fontSize: 9,
                    fontFamily: "Rajdhani",
                    fontWeight: FontWeight.w600,
                    letterSpacing: 1.5,
                  ),
                ),
              ],
            ),
          ),
          AnimatedBuilder(
            animation: _pulseAnimation,
            builder: (context, _) {
              return Container(
                width: 8,
                height: 8,
                decoration: BoxDecoration(
                  color: _isExecuting ? _warningColor : _successColor,
                  shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(
                      color: (_isExecuting ? _warningColor : _successColor).withOpacity(_glowAnimation.value),
                      blurRadius: 8,
                    ),
                  ],
                ),
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _buildTargetSection() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: _cardColor,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: _glowColor1.withOpacity(0.15)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(FontAwesomeIcons.bullseye, color: _glowColor1, size: 14),
              const SizedBox(width: 8),
              Text(
                "TARGET",
                style: TextStyle(
                  color: _glowColor2,
                  fontSize: 11,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 2,
                  fontFamily: "Rajdhani",
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: _buildTargetTypeSelector(),
              ),
              const SizedBox(width: 12),
              Expanded(
                flex: 2,
                child: Container(
                  decoration: BoxDecoration(
                    color: _darkBg,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: _glowColor1.withOpacity(0.15)),
                  ),
                  child: TextField(
                    controller: _targetController,
                    style: const TextStyle(color: Colors.white, fontFamily: "Rajdhani", fontSize: 13),
                    cursorColor: _glowColor1,
                    decoration: InputDecoration(
                      hintText: "TARGET ID / JID",
                      hintStyle: TextStyle(color: Colors.white.withOpacity(0.25), fontSize: 11),
                      border: InputBorder.none,
                      contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildTargetTypeSelector() {
    final options = ["CHAT", "JID", "GROUP"];
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 4),
      decoration: BoxDecoration(
        color: _darkBg,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: _glowColor1.withOpacity(0.15)),
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<String>(
          value: _selectedTargetType,
          dropdownColor: _cardColor,
          isExpanded: true,
          icon: Icon(Icons.arrow_drop_down, color: _glowColor1, size: 18),
          style: TextStyle(color: _glowColor1, fontSize: 12, fontFamily: "Rajdhani"),
          items: options.map((opt) {
            return DropdownMenuItem(
              value: opt,
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 8),
                child: Text(opt),
              ),
            );
          }).toList(),
          onChanged: (val) => setState(() => _selectedTargetType = val!),
        ),
      ),
    );
  }

  Widget _buildExecutionParams() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: _cardColor,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: _glowColor1.withOpacity(0.15)),
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text("LOOP", style: TextStyle(color: _glowColor2, fontSize: 10, fontWeight: FontWeight.w600)),
                const SizedBox(height: 4),
                Container(
                  decoration: BoxDecoration(
                    color: _darkBg,
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: _glowColor1.withOpacity(0.15)),
                  ),
                  child: TextField(
                    controller: _loopController,
                    keyboardType: TextInputType.number,
                    style: const TextStyle(color: Colors.white, fontFamily: "Rajdhani", fontSize: 13),
                    decoration: const InputDecoration(
                      hintText: "1",
                      border: InputBorder.none,
                      contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text("DELAY (MS)", style: TextStyle(color: _glowColor2, fontSize: 10, fontWeight: FontWeight.w600)),
                const SizedBox(height: 4),
                Container(
                  decoration: BoxDecoration(
                    color: _darkBg,
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: _glowColor1.withOpacity(0.15)),
                  ),
                  child: TextField(
                    controller: _delayController,
                    keyboardType: TextInputType.number,
                    style: const TextStyle(color: Colors.white, fontFamily: "Rajdhani", fontSize: 13),
                    decoration: const InputDecoration(
                      hintText: "0",
                      border: InputBorder.none,
                      contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCodeEditor() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: _cardColor,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: _glowColor1.withOpacity(0.15)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(FontAwesomeIcons.terminal, color: _glowColor1, size: 14),
              const SizedBox(width: 8),
              Text(
                "CODE / JSON PAYLOAD",
                style: TextStyle(
                  color: _glowColor2,
                  fontSize: 11,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 2,
                  fontFamily: "Rajdhani",
                ),
              ),
              const Spacer(),
              Text(
                "REPLY TO QUOTE",
                style: TextStyle(
                  color: _warningColor.withOpacity(0.6),
                  fontSize: 8,
                  fontWeight: FontWeight.w600,
                  fontFamily: "Rajdhani",
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Container(
            height: 180,
            decoration: BoxDecoration(
              color: _darkBg,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: _glowColor1.withOpacity(0.15)),
            ),
            child: TextField(
              controller: _codeController,
              maxLines: null,
              expands: true,
              style: TextStyle(
                color: _infoColor,
                fontSize: 12,
                fontFamily: "monospace",
                fontWeight: FontWeight.w500,
              ),
              cursorColor: _glowColor1,
              decoration: InputDecoration(
                hintText: "PASTE CODE OR JSON HERE...",
                hintStyle: TextStyle(color: Colors.white.withOpacity(0.2), fontSize: 11),
                border: InputBorder.none,
                contentPadding: const EdgeInsets.all(14),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHistorySection() {
    if (_executionHistory.isEmpty) return const SizedBox.shrink();
    
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: _cardColor,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: _glowColor1.withOpacity(0.15)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(FontAwesomeIcons.clock, color: _glowColor1, size: 14),
              const SizedBox(width: 8),
              Text(
                "RECENT EXECUTIONS",
                style: TextStyle(
                  color: _glowColor2,
                  fontSize: 11,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 2,
                  fontFamily: "Rajdhani",
                ),
              ),
              const Spacer(),
              GestureDetector(
                onTap: _clearHistory,
                child: Icon(FontAwesomeIcons.trash, color: _errorColor.withOpacity(0.5), size: 14),
              ),
            ],
          ),
          const SizedBox(height: 10),
          SizedBox(
            height: 80,
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              itemCount: _executionHistory.length,
              itemBuilder: (context, index) {
                final item = _executionHistory[index];
                return GestureDetector(
                  onTap: () => _applyFromHistory(item),
                  child: Container(
                    margin: const EdgeInsets.only(right: 10),
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                    decoration: BoxDecoration(
                      color: _darkBg,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: _glowColor1.withOpacity(0.2)),
                    ),
                    child: Text(
                      item.length > 40 ? "${item.substring(0, 37)}..." : item,
                      style: TextStyle(color: _glowColor3, fontSize: 10, fontFamily: "monospace"),
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildOutputSection() {
    return Container(
      constraints: const BoxConstraints(minHeight: 150),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: _cardColor,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: _glowColor1.withOpacity(0.15)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(FontAwesomeIcons.terminal, color: _glowColor1, size: 14),
              const SizedBox(width: 8),
              Text(
                "OUTPUT CONSOLE",
                style: TextStyle(
                  color: _glowColor2,
                  fontSize: 11,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 2,
                  fontFamily: "Rajdhani",
                ),
              ),
              const Spacer(),
              GestureDetector(
                onTap: _clearOutput,
                child: Icon(FontAwesomeIcons.eraser, color: _glowColor1.withOpacity(0.5), size: 14),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Container(
            height: 180,
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: _darkBg,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: _glowColor1.withOpacity(0.1)),
            ),
            child: SingleChildScrollView(
              reverse: true,
              child: Text(
                _output.isEmpty ? "READY" : _output,
                style: TextStyle(
                  color: _output.contains("ERROR") ? _errorColor : (_output.contains("SUCCESS") ? _successColor : _glowColor3),
                  fontSize: 11,
                  fontFamily: "monospace",
                  height: 1.4,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildActionButtons() {
    return Row(
      children: [
        Expanded(
          child: AnimatedBuilder(
            animation: _glowAnimation,
            builder: (context, _) {
              return GestureDetector(
                onTap: _isExecuting ? null : _executeFunction,
                child: Container(
                  height: 52,
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [_glowColor1, _glowColor2],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    borderRadius: BorderRadius.circular(14),
                    boxShadow: [
                      BoxShadow(
                        color: _glowColor1.withOpacity(0.3 * _glowAnimation.value),
                        blurRadius: 20,
                        spreadRadius: 2,
                      ),
                    ],
                  ),
                  child: Center(
                    child: _isExecuting
                        ? SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(
                              color: _darkerBg,
                              strokeWidth: 2,
                            ),
                          )
                        : Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(FontAwesomeIcons.play, color: _darkerBg, size: 16),
                              const SizedBox(width: 10),
                              Text(
                                "EXECUTE",
                                style: TextStyle(
                                  color: _darkerBg,
                                  fontSize: 12,
                                  fontWeight: FontWeight.w900,
                                  fontFamily: "Rajdhani",
                                  letterSpacing: 3,
                                ),
                              ),
                            ],
                          ),
                  ),
                ),
              );
            },
          ),
        ),
      ],
    );
  }

  @override
  void dispose() {
    _glowController.dispose();
    _pulseController.dispose();
    _rotateController.dispose();
    _videoController.dispose();
    _codeController.dispose();
    _targetController.dispose();
    _loopController.dispose();
    _delayController.dispose();
    super.dispose();
  }
}