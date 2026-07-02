import 'dart:convert';
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:math';

class ReportScamPage extends StatefulWidget {
  final String sessionKey;
  
  const ReportScamPage({super.key, required this.sessionKey});

  @override
  State<ReportScamPage> createState() => _ReportScamPageState();
}

class _ReportScamPageState extends State<ReportScamPage> with SingleTickerProviderStateMixin {
  late String sessionKey;
  
  // Settings
  final TextEditingController _targetUsernameController = TextEditingController();
  final TextEditingController _emailSenderController = TextEditingController();
  final TextEditingController _emailPasswordController = TextEditingController();
  final TextEditingController _botTokenController = TextEditingController();
  final TextEditingController _delayController = TextEditingController();
  final TextEditingController _amountController = TextEditingController();
  
  String _selectedReportType = 'EMAIL';
  bool _isLoading = false;
  String _resultMessage = '';
  
  late AnimationController _glowController;
  late AnimationController _pulseController;
  late Animation<double> _glowAnimation;
  late Animation<double> _pulseAnimation;
  
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
  
  final List<String> _targetEmails = [
    'abuse@telegram.org',
    'support@telegram.org',
    'report@telegram.org',
    'dmca@telegram.org',
    'privacy@telegram.org',
    'security@telegram.org',
    'press@telegram.org',
    'business@telegram.org',
    'developers@telegram.org',
    'login@stel.com',
    'support@stel.com',
    'abuse@stel.com',
    'security@stel.com',
    'dmca@stel.com',
    'reclaim@telegram.org',
    'copyright@telegram.org',
    'complaints@telegram.org',
    'legal@telegram.org',
    'ios@telegram.org',
    'android@telegram.org',
    'desktop@telegram.org',
    'web@telegram.org',
    'api@telegram.org',
    'feedback@telegram.org',
    'spam@telegram.org',
    'scam@telegram.org',
    'moderator@telegram.org',
    'admin@telegram.org',
    'noreply@telegram.org',
    'sms@telegram.org',
  ];
  
  final List<String> _targetBots = [
    'BotFather', 'SpamBot', 'NoBot', 'notoscam', 'official_scam_report_bot',
    'scamcoin_bot', 'report_bot', 'tme_support_bot', 'telegram_scams_bot',
    'scam_report_center_bot', 'antiscam_global_bot', 'scamalert_bot',
    'report_scam_bot', 'security_bot', 'tme_team_bot', 'moderator_bot',
    'admin_bot', 'scam_report_bot', 'telegram_admin_bot', 'support_bot',
    'help_bot', 'abuse_bot', 'dmca_bot', 'copyright_bot', 'complaint_bot',
    'feedback_bot', 'telegram_team_bot', 'official_telegram_bot',
    'telegram_support_bot', 'telegram_security_bot', 'telegram_abuse_bot',
    'telegram_dmca_bot', 'telegram_scam_report_bot', 'telegram_moderator_bot',
  ];
  
  final List<String> _mtApiEndpoints = [
    'https://api.ikyyxd.my.id/ai/gemini?message=',
    'https://api.vezionz.my.id/api/gemini?text=',
    'https://api.vanzapi.my.id/api/ai/gemini?text=',
    'https://api.ryzendesu.xyz/api/ai/gemini?text=',
    'https://api.siputzx.my.id/api/ai/gemini?text=',
    'https://api.agatz.xyz/api/gemini?text=',
  ];
  
  @override
  void initState() {
    super.initState();
    sessionKey = widget.sessionKey;
    _loadSettings();
    _glowController = AnimationController(
      duration: const Duration(milliseconds: 2500),
      vsync: this,
    )..repeat(reverse: true);
    _glowAnimation = Tween<double>(begin: 0.3, end: 1.0).animate(
      CurvedAnimation(parent: _glowController, curve: Curves.easeInOutSine),
    );
    _pulseController = AnimationController(
      duration: const Duration(milliseconds: 2000),
      vsync: this,
    )..repeat(reverse: true);
    _pulseAnimation = Tween<double>(begin: 0.92, end: 1.08).animate(
      CurvedAnimation(parent: _pulseController, curve: Curves.easeInOutSine),
    );
    _delayController.text = '1000';
    _amountController.text = '1';
  }
  
  Future<void> _loadSettings() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _targetUsernameController.text = prefs.getString('scam_target_username') ?? 'ib_gruop_gy_X2';
      _emailSenderController.text = prefs.getString('scam_email_sender') ?? '';
      _emailPasswordController.text = prefs.getString('scam_email_password') ?? '';
      _botTokenController.text = prefs.getString('scam_bot_token') ?? '';
    });
  }
  
  Future<void> _saveSettings() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('scam_target_username', _targetUsernameController.text.trim());
    await prefs.setString('scam_email_sender', _emailSenderController.text.trim());
    await prefs.setString('scam_email_password', _emailPasswordController.text.trim());
    await prefs.setString('scam_bot_token', _botTokenController.text.trim());
    
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('SETTINGS SAVED', style: _cinzel(12, FontWeight.w600, 1.0)),
        backgroundColor: _successColor.withOpacity(0.9),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
    );
  }
  
  Future<String> _generateMTReport(String username) async {
    String prompt = 'Generate a detailed scam report for Telegram user @$username. Include scam evidence, victim impact, and violation of Telegram Terms of Service. Make it formal and professional.';
    
    for (var api in _mtApiEndpoints) {
      try {
        final response = await http.get(
          Uri.parse('$api${Uri.encodeComponent(prompt)}'),
          headers: {
            'User-Agent': 'Mozilla/5.0',
            'Accept': 'application/json',
          },
        ).timeout(const Duration(seconds: 15));
        
        if (response.statusCode == 200) {
          final data = json.decode(response.body);
          String reply = _extractMTResponse(data);
          if (reply.isNotEmpty && reply.length > 100) {
            return _formatReport(reply, username);
          }
        }
      } catch (e) {
        continue;
      }
    }
    
    return _getDefaultReport(username);
  }
  
  String _extractMTResponse(Map<String, dynamic> data) {
    List<String> possibleKeys = [
      'response', 'message', 'result', 'text', 'reply', 
      'content', 'answer', 'data', 'output', 'generated_text'
    ];
    
    for (String key in possibleKeys) {
      if (data.containsKey(key)) {
        if (data[key] is String && data[key].toString().isNotEmpty) {
          return data[key].toString();
        }
      }
    }
    return '';
  }
  
  String _formatReport(String mtResponse, String username) {
    return '''
╔══════════════════════════════════════════════════════════╗
║                    SCAM REPORT                          ║
╠══════════════════════════════════════════════════════════╣
║ TARGET: @$username
║ LINK: https://t.me/$username
╠══════════════════════════════════════════════════════════╣
║ EVIDENCE:
║ $mtResponse
╠══════════════════════════════════════════════════════════╣
║ VIOLATION: Telegram Terms of Service
║ - Section 3: Fraudulent Activities
║ - Section 5: Scamming and Impersonation
║ - Section 8: Harmful Content
╠══════════════════════════════════════════════════════════╣
║ REQUESTED ACTION:
║ 1. Immediate SCAM tag on profile
║ 2. Immediate FAKE tag on profile  
║ 3. Account restriction or permanent ban
║ 4. IP address blacklisting
╠══════════════════════════════════════════════════════════╣
║ REPORT ID: ${DateTime.now().millisecondsSinceEpoch}
║ REPORT DATE: ${DateTime.now().toIso8601String()}
╚══════════════════════════════════════════════════════════╝
''';
  }
  
  String _getDefaultReport(String username) {
    return '''
Telegram User @$username is a confirmed scammer and fraudster who operates by tricking victims into sending money with false promises of help. Once payment is received, the user immediately blocks all communication and disappears with the funds.

Multiple victims have come forward with:
- Screenshot evidence of conversations
- Payment receipts showing transfers
- Proof of being blocked after payment
- Similar modus operandi across all cases

This user has been reported multiple times but continues to operate under the same username, indicating an urgent need for Telegram to take action. The total estimated financial damage from this scammer exceeds thousands of dollars from numerous victims worldwide.

We urge Telegram to immediately:
- Label @$username as SCAM
- Label @$username as FAKE
- Permanently ban this account
- Blacklist associated IP addresses
''';
  }
  
  Future<bool> _sendEmail(String targetEmail, String subject, String body) async {
    final sender = _emailSenderController.text.trim();
    final password = _emailPasswordController.text.trim();
    
    if (sender.isEmpty || password.isEmpty) return false;
    
    try {
      final response = await http.post(
        Uri.parse('https://smtp.gmail.com'),
        headers: {'Content-Type': 'application/json'},
        body: json.encode({
          'from': sender,
          'to': targetEmail,
          'subject': subject,
          'body': body,
          'password': password,
        }),
      ).timeout(const Duration(seconds: 10));
      
      return response.statusCode == 200;
    } catch (e) {
      return false;
    }
  }
  
  Future<bool> _sendToBot(String botUsername, String message) async {
    final botToken = _botTokenController.text.trim();
    if (botToken.isEmpty) return false;
    
    try {
      final response = await http.post(
        Uri.parse('https://api.telegram.org/bot$botToken/sendMessage'),
        body: {
          'chat_id': '@$botUsername',
          'text': message,
          'parse_mode': 'HTML',
        },
      ).timeout(const Duration(seconds: 10));
      
      return response.statusCode == 200;
    } catch (e) {
      return false;
    }
  }
  
  Future<void> _startReport() async {
    final target = _targetUsernameController.text.trim();
    final delay = int.tryParse(_delayController.text.trim()) ?? 1000;
    final amount = int.tryParse(_amountController.text.trim()) ?? 1;
    
    if (target.isEmpty) {
      _showError('ENTER TARGET USERNAME');
      return;
    }
    
    if (_selectedReportType == 'EMAIL' && _emailSenderController.text.trim().isEmpty) {
      _showError('CONFIGURE EMAIL SENDER FIRST');
      return;
    }
    
    if (_selectedReportType == 'BOT' && _botTokenController.text.trim().isEmpty) {
      _showError('CONFIGURE BOT TOKEN FIRST');
      return;
    }
    
    setState(() {
      _isLoading = true;
      _resultMessage = '';
    });
    
    final reportText = await _generateMTReport(target);
    final targets = _selectedReportType == 'EMAIL' ? _targetEmails : _targetBots;
    
    int success = 0;
    int failed = 0;
    
    for (int i = 1; i <= amount; i++) {
      for (int j = 0; j < targets.length; j++) {
        final targetAddr = targets[j];
        
        if (_selectedReportType == 'EMAIL') {
          final subject = '[URGENT] SCAM REPORT @$target - VIOLATION OF TOS';
          if (await _sendEmail(targetAddr, subject, reportText)) {
            success++;
          } else {
            failed++;
          }
        } else {
          if (await _sendToBot(targetAddr, reportText)) {
            success++;
          } else {
            failed++;
          }
        }
        
        await Future.delayed(Duration(milliseconds: delay));
        
        if (mounted) {
          setState(() {
            _resultMessage = 'PROGRESS: ${success + failed}/${targets.length * amount} | SUCCESS: $success | FAILED: $failed';
          });
        }
      }
    }
    
    setState(() {
      _resultMessage = '''
REPORT COMPLETED

TARGET: @$target
TYPE: ${_selectedReportType == 'EMAIL' ? 'EMAIL' : 'BOT'}
SUCCESS: $success
FAILED: $failed
TOTAL: ${targets.length * amount}

SCAM TAG REQUEST SUBMITTED
FAKE TAG REQUEST SUBMITTED
''';
      _isLoading = false;
    });
  }
  
  void _showError(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message, style: _cinzel(12, FontWeight.w600, 1.0)),
        backgroundColor: _roseColor.withOpacity(0.9),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
    );
  }
  
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _darkerBg,
      body: Stack(
        children: [
          _buildAnimatedBackground(),
          SafeArea(
            child: CustomScrollView(
              physics: const BouncingScrollPhysics(),
              slivers: [
                SliverToBoxAdapter(
                  child: Column(
                    children: [
                      _buildHeader(),
                      const SizedBox(height: 16),
                      _buildTargetSection(),
                      const SizedBox(height: 20),
                      _buildReportTypeSelector(),
                      const SizedBox(height: 20),
                                      _buildSettingsPanel(),
                      const SizedBox(height: 24),
                      _buildActionButton(),
                      if (_resultMessage.isNotEmpty) ...[
                        const SizedBox(height: 20),
                        _buildResultCard(),
                      ],
                      const SizedBox(height: 30),
                      _buildFooter(),
                    ],
                  ),
                ),
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
    return AnimatedBuilder(
      animation: _pulseAnimation,
      builder: (context, _) {
        return Padding(
          padding: const EdgeInsets.all(20),
          child: Container(
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
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: _roseColor.withOpacity(0.15),
                    borderRadius: BorderRadius.circular(18),
                    border: Border.all(color: _roseColor.withOpacity(0.3), width: 1),
                  ),
                  child: Icon(FontAwesomeIcons.flag, color: _roseColor, size: 28),
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
                          'SCAM REPORTER',
                          style: _cinzel(18, FontWeight.w900, 1.0),
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Get SCAM + FAKE Tags on Scammers',
                        style: _cinzel(10, FontWeight.w600, 0.5),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
  
  Widget _buildTargetSection() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('TARGET USERNAME', style: _cinzel(11, FontWeight.w700, 0.5)),
          const SizedBox(height: 8),
          Container(
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: _glowColor1.withOpacity(0.2), width: 1),
            ),
            child: TextField(
              controller: _targetUsernameController,
              style: _cinzel(13, FontWeight.w600, 0.9),
              cursorColor: _glowColor1,
              decoration: InputDecoration(
                prefixIcon: Icon(FontAwesomeIcons.user, color: _glowColor2.withOpacity(0.5), size: 18),
                hintText: '@username',
                hintStyle: _cinzel(12, FontWeight.w500, 0.3),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(16),
                  borderSide: BorderSide.none,
                ),
                filled: true,
                fillColor: _cardColor.withOpacity(0.6),
                contentPadding: const EdgeInsets.symmetric(horizontal: 18, vertical: 16),
              ),
            ),
          ),
        ],
      ),
    );
  }
  
  Widget _buildReportTypeSelector() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('REPORT TYPE', style: _cinzel(11, FontWeight.w700, 0.5)),
          const SizedBox(height: 8),
          Row(
            children: [
              Expanded(
                child: GestureDetector(
                  onTap: () => setState(() => _selectedReportType = 'EMAIL'),
                  child: Container(
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    decoration: BoxDecoration(
                      color: _selectedReportType == 'EMAIL' ? _glowColor1.withOpacity(0.15) : _cardColor,
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(
                        color: _selectedReportType == 'EMAIL' ? _glowColor1 : _glowColor1.withOpacity(0.2),
                        width: _selectedReportType == 'EMAIL' ? 1.5 : 1,
                      ),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(FontAwesomeIcons.envelope, color: _selectedReportType == 'EMAIL' ? _glowColor1 : _glowColor2, size: 18),
                        const SizedBox(width: 8),
                        Text('EMAIL', style: _cinzel(12, FontWeight.w800, _selectedReportType == 'EMAIL' ? 0.9 : 0.5)),
                      ],
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: GestureDetector(
                  onTap: () => setState(() => _selectedReportType = 'BOT'),
                  child: Container(
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    decoration: BoxDecoration(
                      color: _selectedReportType == 'BOT' ? _glowColor1.withOpacity(0.15) : _cardColor,
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(
                        color: _selectedReportType == 'BOT' ? _glowColor1 : _glowColor1.withOpacity(0.2),
                        width: _selectedReportType == 'BOT' ? 1.5 : 1,
                      ),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(FontAwesomeIcons.robot, color: _selectedReportType == 'BOT' ? _glowColor1 : _glowColor2, size: 18),
                        const SizedBox(width: 8),
                        Text('BOT', style: _cinzel(12, FontWeight.w800, _selectedReportType == 'BOT' ? 0.9 : 0.5)),
                      ],
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
  
  Widget _buildSettingsPanel() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: _cardColor,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: _glowColor1.withOpacity(0.2), width: 1),
        ),
        child: Column(
          children: [
            if (_selectedReportType == 'EMAIL') ...[
              _buildSettingField(
                controller: _emailSenderController,
                label: 'EMAIL SENDER',
                hint: 'your.email@gmail.com',
                icon: FontAwesomeIcons.envelope,
              ),
              const SizedBox(height: 12),
              _buildSettingField(
                controller: _emailPasswordController,
                label: 'APP PASSWORD',
                hint: 'xxxx xxxx xxxx xxxx',
                icon: FontAwesomeIcons.lock,
                isPassword: true,
              ),
            ],
            if (_selectedReportType == 'BOT') ...[
              _buildSettingField(
                controller: _botTokenController,
                label: 'BOT TOKEN',
                hint: '1234567890:ABCdefGHIjklMNOpqrsTUVwxyz',
                icon: FontAwesomeIcons.robot,
              ),
            ],
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: _buildSettingField(
                    controller: _delayController,
                    label: 'DELAY (MS)',
                    hint: '1000',
                    icon: FontAwesomeIcons.clock,
                    keyboardType: TextInputType.number,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _buildSettingField(
                    controller: _amountController,
                    label: 'AMOUNT',
                    hint: '1',
                    icon: FontAwesomeIcons.repeat,
                    keyboardType: TextInputType.number,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            GestureDetector(
              onTap: _saveSettings,
              child: Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(vertical: 12),
                decoration: BoxDecoration(
                  color: _successColor.withOpacity(0.15),
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: _successColor.withOpacity(0.3), width: 1),
                ),
                child: Center(
                  child: Text('SAVE SETTINGS', style: _cinzel(12, FontWeight.w800, 0.9).copyWith(color: _successColor)),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
  
  Widget _buildSettingField({
    required TextEditingController controller,
    required String label,
    required String hint,
    required IconData icon,
    bool isPassword = false,
    TextInputType? keyboardType,
  }) {
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: _glowColor2.withOpacity(0.15), width: 1),
      ),
      child: TextField(
        controller: controller,
        obscureText: isPassword,
        keyboardType: keyboardType,
        style: _cinzel(12, FontWeight.w600, 0.9),
        cursorColor: _glowColor1,
        decoration: InputDecoration(
          labelText: label,
          labelStyle: _cinzel(10, FontWeight.w600, 0.5),
          hintText: hint,
          hintStyle: _cinzel(10, FontWeight.w500, 0.3),
          prefixIcon: Icon(icon, color: _glowColor2.withOpacity(0.4), size: 16),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(14),
            borderSide: BorderSide.none,
          ),
          filled: true,
          fillColor: _surfaceColor.withOpacity(0.5),
          contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        ),
      ),
    );
  }
  
  Widget _buildActionButton() {
    return AnimatedBuilder(
      animation: _glowAnimation,
      builder: (context, _) {
        return Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20),
          child: GestureDetector(
            onTap: _isLoading ? null : _startReport,
            child: Container(
              width: double.infinity,
              height: 56,
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [_roseColor, _roseColor.withOpacity(0.7)],
                ),
                borderRadius: BorderRadius.circular(18),
                boxShadow: [
                  BoxShadow(
                    color: _roseColor.withOpacity(0.3 * _glowAnimation.value),
                    blurRadius: 20,
                    offset: const Offset(0, 6),
                  ),
                ],
              ),
              child: _isLoading
                  ? Center(
                      child: SizedBox(
                        width: 24,
                        height: 24,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: _darkerBg,
                        ),
                      ),
                    )
                  : Center(
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(FontAwesomeIcons.flag, color: _darkerBg, size: 18),
                          const SizedBox(width: 12),
                          Text(
                            'REPORT SCAMMER',
                            style: _cinzel(13, FontWeight.w900, 1.0).copyWith(color: _darkerBg),
                          ),
                        ],
                      ),
                    ),
            ),
          ),
        );
      },
    );
  }
  
  Widget _buildResultCard() {
    final isSuccess = _resultMessage.contains('COMPLETED');
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: isSuccess ? _successColor.withOpacity(0.1) : _warningColor.withOpacity(0.1),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: isSuccess ? _successColor.withOpacity(0.3) : _warningColor.withOpacity(0.3),
            width: 1,
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  isSuccess ? FontAwesomeIcons.checkCircle : FontAwesomeIcons.exclamationTriangle,
                  color: isSuccess ? _successColor : _warningColor,
                  size: 20,
                ),
                const SizedBox(width: 12),
                Text(
                  isSuccess ? 'REPORT STATUS' : 'PROGRESS',
                  style: _cinzel(14, FontWeight.w800, 1.0),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Text(
              _resultMessage,
              style: _cinzel(11, FontWeight.w600, 0.8),
            ),
          ],
        ),
      ),
    );
  }
  
  Widget _buildFooter() {
    return Column(
      children: [
        Container(
          height: 1,
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [Colors.transparent, _glowColor1.withOpacity(0.1), Colors.transparent],
            ),
          ),
        ),
        const SizedBox(height: 20),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            _buildFooterDot(_successColor),
            const SizedBox(width: 10),
            _buildFooterText('SCAM TAG'),
            const SizedBox(width: 20),
            Container(width: 1, height: 12, color: Colors.white.withOpacity(0.06)),
            const SizedBox(width: 20),
            Icon(Icons.fingerprint, color: Colors.white.withOpacity(0.12), size: 12),
            const SizedBox(width: 20),
            _buildFooterDot(_warningColor),
            const SizedBox(width: 10),
            _buildFooterText('FAKE TAG'),
          ],
        ),
        const SizedBox(height: 12),
        Text(
          'SCAM REPORTER V1.0',
          style: TextStyle(
            color: Colors.white.withOpacity(0.1),
            fontSize: 8,
            letterSpacing: 3,
            fontFamily: 'CinzelDecorative',
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 20),
      ],
    );
  }
  
  Widget _buildFooterDot(Color color) {
    return Container(
      width: 5,
      height: 5,
      decoration: BoxDecoration(
        color: color,
        shape: BoxShape.circle,
        boxShadow: [BoxShadow(color: color, blurRadius: 5)],
      ),
    );
  }
  
  Widget _buildFooterText(String text) {
    return Text(
      text,
      style: TextStyle(
        color: Colors.white.withOpacity(0.25),
        fontSize: 8,
        fontWeight: FontWeight.w700,
        letterSpacing: 2.5,
        fontFamily: 'CinzelDecorative',
      ),
    );
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
    _glowController.dispose();
    _pulseController.dispose();
    _targetUsernameController.dispose();
    _emailSenderController.dispose();
    _emailPasswordController.dispose();
    _botTokenController.dispose();
    _delayController.dispose();
    _amountController.dispose();
    super.dispose();
  }
}