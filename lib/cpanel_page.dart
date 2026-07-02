import 'dart:convert';
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:shared_preferences/shared_preferences.dart';

class CPanelPage extends StatefulWidget {
  final String sessionKey;
  
  const CPanelPage({super.key, required this.sessionKey});

  @override
  State<CPanelPage> createState() => _CPanelPageState();
}

class _CPanelPageState extends State<CPanelPage> with SingleTickerProviderStateMixin {
  late String sessionKey;
  final TextEditingController _usernameController = TextEditingController();
  final TextEditingController _telegramIdController = TextEditingController();
  final TextEditingController _receiverIdController = TextEditingController();
  
  // Settings controllers
  final TextEditingController _domainController = TextEditingController();
  final TextEditingController _pltaController = TextEditingController();
  final TextEditingController _pltcController = TextEditingController();
  final TextEditingController _botTokenController = TextEditingController();
  final TextEditingController _ownerIdController = TextEditingController();
  final TextEditingController _locationController = TextEditingController();
  final TextEditingController _eggController = TextEditingController();
  
  String _selectedRam = '1GB';
  bool _isLoading = false;
  bool _showSettings = false;
  String _resultMessage = '';
  
  late AnimationController _glowController;
  late AnimationController _floatController;
  late Animation<double> _glowAnimation;
  late Animation<double> _floatAnimation;
  
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
  
  final Map<String, Map<String, String>> _ramOptions = {
    '1GB': {'memo': '1024', 'cpu': '30', 'disk': '1024'},
    '2GB': {'memo': '2048', 'cpu': '60', 'disk': '2048'},
    '3GB': {'memo': '3072', 'cpu': '90', 'disk': '3072'},
    '4GB': {'memo': '4048', 'cpu': '110', 'disk': '4048'},
    '5GB': {'memo': '5048', 'cpu': '140', 'disk': '5048'},
    '6GB': {'memo': '6048', 'cpu': '170', 'disk': '6048'},
    '7GB': {'memo': '7048', 'cpu': '200', 'disk': '7048'},
    '8GB': {'memo': '8048', 'cpu': '230', 'disk': '8048'},
    '9GB': {'memo': '9048', 'cpu': '260', 'disk': '9048'},
    '10GB': {'memo': '10000', 'cpu': '290', 'disk': '10000'},
    'UNLIMITED': {'memo': '0', 'cpu': '0', 'disk': '0'},
  };
  
  @override
  void initState() {
    super.initState();
    sessionKey = widget.sessionKey;
    _glowController = AnimationController(
      duration: const Duration(milliseconds: 2500),
      vsync: this,
    )..repeat(reverse: true);
    _glowAnimation = Tween<double>(begin: 0.3, end: 1.0).animate(
      CurvedAnimation(parent: _glowController, curve: Curves.easeInOutSine),
    );
    _floatController = AnimationController(
      duration: const Duration(milliseconds: 3000),
      vsync: this,
    )..repeat(reverse: true);
    _floatAnimation = Tween<double>(begin: 0, end: -8).animate(
      CurvedAnimation(parent: _floatController, curve: Curves.easeInOutSine),
    );
    _loadSettings();
  }
  
  Future<void> _loadSettings() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _domainController.text = prefs.getString('cpanel_domain') ?? '';
      _pltaController.text = prefs.getString('cpanel_plta') ?? '';
      _pltcController.text = prefs.getString('cpanel_pltc') ?? '';
      _botTokenController.text = prefs.getString('cpanel_bot_token') ?? '';
      _ownerIdController.text = prefs.getString('cpanel_owner_id') ?? '';
      _locationController.text = prefs.getString('cpanel_location') ?? '1';
      _eggController.text = prefs.getString('cpanel_egg') ?? '15';
    });
  }
  
  Future<void> _saveSettings() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('cpanel_domain', _domainController.text.trim());
    await prefs.setString('cpanel_plta', _pltaController.text.trim());
    await prefs.setString('cpanel_pltc', _pltcController.text.trim());
    await prefs.setString('cpanel_bot_token', _botTokenController.text.trim());
    await prefs.setString('cpanel_owner_id', _ownerIdController.text.trim());
    await prefs.setString('cpanel_location', _locationController.text.trim());
    await prefs.setString('cpanel_egg', _eggController.text.trim());
    
    setState(() {
      _showSettings = false;
    });
    
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('SETTINGS SAVED', style: _cinzel(12, FontWeight.w600, 1.0)),
        backgroundColor: _successColor.withOpacity(0.9),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
    );
  }
  
  String _generateRandomPassword(String username) {
    return '${username}xGerzx';
  }
  
  Future<void> _sendViaBot(String telegramId, String message) async {
    final botToken = _botTokenController.text.trim();
    if (botToken.isEmpty) return;
    
    try {
      await http.post(
        Uri.parse('https://api.telegram.org/bot$botToken/sendMessage'),
        body: {
          'chat_id': telegramId,
          'text': message,
          'parse_mode': 'HTML',
        },
      );
    } catch (e) {
      debugPrint('Failed to send via bot: $e');
    }
  }
  
  Future<void> _sendToOwner(String message) async {
    final botToken = _botTokenController.text.trim();
    final ownerId = _ownerIdController.text.trim();
    if (botToken.isEmpty || ownerId.isEmpty) return;
    
    try {
      await http.post(
        Uri.parse('https://api.telegram.org/bot$botToken/sendMessage'),
        body: {
          'chat_id': ownerId,
          'text': message,
          'parse_mode': 'HTML',
        },
      );
    } catch (e) {
      debugPrint('Failed to send to owner: $e');
    }
  }
  
  Future<void> _createPanel() async {
    final username = _usernameController.text.trim();
    final telegramId = _telegramIdController.text.trim();
    final receiverId = _receiverIdController.text.trim();
    final domain = _domainController.text.trim();
    final plta = _pltaController.text.trim();
    final pltc = _pltcController.text.trim();
    final loc = _locationController.text.trim();
    final egg = _eggController.text.trim();
    final ownerId = _ownerIdController.text.trim();
    
    if (username.isEmpty || telegramId.isEmpty) {
      setState(() {
        _resultMessage = 'PLEASE FILL ALL FIELDS';
      });
      return;
    }
    
    if (domain.isEmpty || plta.isEmpty || pltc.isEmpty) {
      setState(() {
        _resultMessage = 'PLEASE CONFIGURE SETTINGS FIRST';
        _showSettings = true;
      });
      return;
    }
    
    setState(() {
      _isLoading = true;
      _resultMessage = '';
    });
    
    final ramData = _ramOptions[_selectedRam]!;
    final name = '${username}_${_selectedRam.replaceAll('GB', 'gb')}';
    final email = '$username@buyer.panel';
    final password = _generateRandomPassword(username);
    final spc = 'if [[ -d .git ]] && [[ {{AUTO_UPDATE}} == "1" ]]; then git pull; fi; if [[ ! -z \${NODE_PACKAGES} ]]; then /usr/local/bin/npm install \${NODE_PACKAGES}; fi; if [[ ! -z \${UNNODE_PACKAGES} ]]; then /usr/local/bin/npm uninstall \${UNNODE_PACKAGES}; fi; if [ -f /home/container/package.json ]; then /usr/local/bin/npm install; fi; /usr/local/bin/\${CMD_RUN}';
    
    try {
      final userResponse = await http.post(
        Uri.parse('$domain/api/application/users'),
        headers: {
          'Accept': 'application/json',
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $plta',
        },
        body: json.encode({
          'email': email,
          'username': username,
          'first_name': username,
          'last_name': username,
          'language': 'en',
          'password': password,
        }),
      );
      
      if (userResponse.statusCode != 200 && userResponse.statusCode != 201) {
        final errorData = json.decode(userResponse.body);
        setState(() {
          _resultMessage = 'USER CREATION FAILED: ${errorData['errors']?[0]['detail'] ?? 'UNKNOWN ERROR'}';
          _isLoading = false;
        });
        return;
      }
      
      final userData = json.decode(userResponse.body);
      final userId = userData['attributes']['id'];
      
      final serverResponse = await http.post(
        Uri.parse('$domain/api/application/servers'),
        headers: {
          'Accept': 'application/json',
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $plta',
        },
        body: json.encode({
          'name': name,
          'description': '',
          'user': userId,
          'egg': int.parse(egg),
          'docker_image': 'ghcr.io/parkervcp/yolks:nodejs_18',
          'startup': spc,
          'environment': {
            'INST': 'npm',
            'USER_UPLOAD': '0',
            'AUTO_UPDATE': '0',
            'CMD_RUN': 'npm start',
          },
          'limits': {
            'memory': ramData['memo'],
            'swap': 0,
            'disk': ramData['disk'],
            'io': 500,
            'cpu': ramData['cpu'],
          },
          'feature_limits': {
            'databases': 5,
            'backups': 5,
            'allocations': 1,
          },
          'deploy': {
            'locations': [int.parse(loc)],
            'dedicated_ip': false,
            'port_range': [],
          },
        }),
      );
      
      if (serverResponse.statusCode != 200 && serverResponse.statusCode != 201) {
        setState(() {
          _resultMessage = 'SERVER CREATION FAILED';
          _isLoading = false;
        });
        return;
      }
      
      final serverData = json.decode(serverResponse.body);
      final server = serverData['attributes'];
      
      final resultText = '''
╔══════════════════════════════╗
║       PANEL CREATED          ║
╠══════════════════════════════╣
║ USERNAME: $username
║ EMAIL: $email
║ PASSWORD: $password
║ MEMORY: ${server['limits']['memory'] == 0 ? 'UNLIMITED' : '${server['limits']['memory']} MB'}
║ DISK: ${server['limits']['disk'] == 0 ? 'UNLIMITED' : '${server['limits']['disk']} MB'}
║ CPU: ${server['limits']['cpu']}%
║ LOGIN: $domain
╚══════════════════════════════╝
      ''';
      
      final ownerText = '''
╔══════════════════════════════════════╗
║         NEW PANEL CREATED            ║
╠══════════════════════════════════════╣
║ CREATED BY: $username
║ RECEIVER ID: ${receiverId.isNotEmpty ? receiverId : telegramId}
║ RAM: $_selectedRam
║ DOMAIN: $domain
║ TIME: ${DateTime.now().toString()}
╚══════════════════════════════════════╝
      ''';
      
      setState(() {
        _resultMessage = resultText;
        _isLoading = false;
      });
      
      final targetId = receiverId.isNotEmpty ? receiverId : telegramId;
      await _sendViaBot(targetId, resultText);
      await _sendToOwner(ownerText);
      
      _usernameController.clear();
      _telegramIdController.clear();
      _receiverIdController.clear();
      
    } catch (e) {
      setState(() {
        _resultMessage = 'CONNECTION ERROR: ${e.toString()}';
        _isLoading = false;
      });
    }
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
                      _buildSettingsToggle(),
                      if (_showSettings) ...[
                        const SizedBox(height: 16),
                        _buildSettingsPanel(),
                      ],
                      const SizedBox(height: 16),
                      _buildRamSelector(),
                      const SizedBox(height: 20),
                      _buildInputForm(),
                      const SizedBox(height: 16),
                      _buildReceiverField(),
                      const SizedBox(height: 24),
                      _buildCreateButton(),
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
      animation: _floatAnimation,
      builder: (context, _) {
        return Transform.translate(
          offset: Offset(0, _floatAnimation.value),
          child: Padding(
            padding: const EdgeInsets.all(16),
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
                      color: _glowColor1.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(18),
                      border: Border.all(color: _glowColor1.withOpacity(0.25), width: 1),
                    ),
                    child: Icon(FontAwesomeIcons.server, color: _glowColor1, size: 28),
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
                            'CREATE PANEL',
                            style: _cinzel(18, FontWeight.w900, 1.0),
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'Pterodactyl Panel Creator',
                          style: _cinzel(10, FontWeight.w600, 0.5),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
  
  Widget _buildSettingsToggle() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: GestureDetector(
        onTap: () => setState(() => _showSettings = !_showSettings),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
          decoration: BoxDecoration(
            color: _cardColor,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: _glowColor2.withOpacity(0.2), width: 1),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                _showSettings ? Icons.keyboard_arrow_up : Icons.settings,
                color: _glowColor2,
                size: 18,
              ),
              const SizedBox(width: 12),
              Text(
                _showSettings ? 'HIDE SETTINGS' : 'SHOW SETTINGS',
                style: _cinzel(12, FontWeight.w700, 0.7),
              ),
            ],
          ),
        ),
      ),
    );
  }
  
  Widget _buildSettingsPanel() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: _cardColor,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: _glowColor1.withOpacity(0.2), width: 1),
        ),
        child: Column(
          children: [
            _buildSettingField(
              controller: _domainController,
              label: 'PANEL DOMAIN',
              hint: 'https://your-panel.com',
              icon: FontAwesomeIcons.globe,
            ),
            const SizedBox(height: 12),
            _buildSettingField(
              controller: _pltaController,
              label: 'PLTA KEY',
              hint: 'ptla_xxxxxxxxxxxxx',
              icon: FontAwesomeIcons.key,
            ),
            const SizedBox(height: 12),
            _buildSettingField(
              controller: _pltcController,
              label: 'PLTC KEY',
              hint: 'ptlc_xxxxxxxxxxxxx',
              icon: FontAwesomeIcons.lock,
            ),
            const SizedBox(height: 12),
            _buildSettingField(
              controller: _botTokenController,
              label: 'TELEGRAM BOT TOKEN',
              hint: '1234567890:ABCdefGHIjklMNOpqrsTUVwxyz',
              icon: FontAwesomeIcons.robot,
            ),
            const SizedBox(height: 12),
            _buildSettingField(
              controller: _ownerIdController,
              label: 'OWNER TELEGRAM ID',
              hint: '1234567890',
              icon: FontAwesomeIcons.crown,
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: _buildSettingField(
                    controller: _locationController,
                    label: 'LOCATION ID',
                    hint: '1',
                    icon: FontAwesomeIcons.mapPin,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _buildSettingField(
                    controller: _eggController,
                    label: 'EGG ID',
                    hint: '15',
                    icon: FontAwesomeIcons.egg,
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
                  child: Text(
                    'SAVE SETTINGS',
                    style: _cinzel(12, FontWeight.w800, 0.9).copyWith(color: _successColor),
                  ),
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
  }) {
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: _glowColor2.withOpacity(0.15), width: 1),
      ),
      child: TextField(
        controller: controller,
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
  
  Widget _buildRamSelector() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.only(left: 8, bottom: 12),
            child: Row(
              children: [
                Icon(FontAwesomeIcons.memory, color: _glowColor1, size: 14),
                const SizedBox(width: 8),
                Text(
                  'SELECT RAM',
                  style: _cinzel(12, FontWeight.w700, 0.7),
                ),
              ],
            ),
          ),
          SizedBox(
            height: 50,
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              itemCount: _ramOptions.keys.length,
              itemBuilder: (context, index) {
                final ram = _ramOptions.keys.elementAt(index);
                final isSelected = _selectedRam == ram;
                Color ramColor = isSelected ? _glowColor1 : _glowColor2;
                if (ram == 'UNLIMITED') {
                  ramColor = isSelected ? _goldColor : _glowColor3;
                }
                return Padding(
                  padding: const EdgeInsets.only(right: 10),
                  child: GestureDetector(
                    onTap: () => setState(() => _selectedRam = ram),
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 200),
                      padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 12),
                      decoration: BoxDecoration(
                        color: isSelected ? ramColor.withOpacity(0.15) : _cardColor,
                        borderRadius: BorderRadius.circular(30),
                        border: Border.all(
                          color: isSelected ? ramColor : ramColor.withOpacity(0.2),
                          width: isSelected ? 1.5 : 1,
                        ),
                        boxShadow: isSelected ? [
                          BoxShadow(
                            color: ramColor.withOpacity(0.2),
                            blurRadius: 12,
                          ),
                        ] : null,
                      ),
                      child: Text(
                        ram,
                        style: _cinzel(12, FontWeight.w700, isSelected ? 1.0 : 0.5),
                      ),
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
  
  Widget _buildInputForm() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Column(
        children: [
          _buildPremiumTextField(
            controller: _usernameController,
            label: 'PANEL NAME',
            hint: 'Enter panel username',
            icon: FontAwesomeIcons.user,
          ),
          const SizedBox(height: 16),
          _buildPremiumTextField(
            controller: _telegramIdController,
            label: 'YOUR TELEGRAM ID',
            hint: 'Enter your telegram user ID',
            icon: FontAwesomeIcons.telegram,
            keyboardType: TextInputType.number,
          ),
        ],
      ),
    );
  }
  
  Widget _buildReceiverField() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: _buildPremiumTextField(
        controller: _receiverIdController,
        label: 'RECEIVER TELEGRAM ID (OPTIONAL)',
        hint: 'Enter receiver ID or leave empty',
        icon: FontAwesomeIcons.users,
        keyboardType: TextInputType.number,
      ),
    );
  }
  
  Widget _buildPremiumTextField({
    required TextEditingController controller,
    required String label,
    required String hint,
    required IconData icon,
    TextInputType? keyboardType,
  }) {
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: _glowColor1.withOpacity(0.2), width: 1),
        boxShadow: [
          BoxShadow(
            color: _glowColor1.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: TextField(
        controller: controller,
        keyboardType: keyboardType,
        style: _cinzel(13, FontWeight.w600, 0.9),
        cursorColor: _glowColor1,
        decoration: InputDecoration(
          labelText: label,
          labelStyle: _cinzel(11, FontWeight.w600, 0.5),
          hintText: hint,
          hintStyle: _cinzel(11, FontWeight.w500, 0.3),
          prefixIcon: Icon(icon, color: _glowColor2.withOpacity(0.5), size: 20),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(18),
            borderSide: BorderSide.none,
          ),
          filled: true,
          fillColor: _cardColor.withOpacity(0.6),
          contentPadding: const EdgeInsets.symmetric(horizontal: 18, vertical: 16),
        ),
      ),
    );
  }
  
  Widget _buildCreateButton() {
    return AnimatedBuilder(
      animation: _glowAnimation,
      builder: (context, _) {
        return Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: GestureDetector(
            onTap: _isLoading ? null : _createPanel,
            child: Container(
              width: double.infinity,
              height: 56,
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [_glowColor1, _glowColor2],
                ),
                borderRadius: BorderRadius.circular(18),
                boxShadow: [
                  BoxShadow(
                    color: _glowColor1.withOpacity(0.3 * _glowAnimation.value),
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
                          Icon(FontAwesomeIcons.play, color: _darkerBg, size: 18),
                          const SizedBox(width: 12),
                          Text(
                            'CREATE PANEL',
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
    final isSuccess = _resultMessage.contains('PANEL CREATED');
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: isSuccess ? _successColor.withOpacity(0.1) : _roseColor.withOpacity(0.1),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: isSuccess ? _successColor.withOpacity(0.3) : _roseColor.withOpacity(0.3),
            width: 1,
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  isSuccess ? FontAwesomeIcons.checkCircle : FontAwesomeIcons.exclamationCircle,
                  color: isSuccess ? _successColor : _roseColor,
                  size: 20,
                ),
                const SizedBox(width: 12),
                Text(
                  isSuccess ? 'SUCCESS' : 'ERROR',
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
        const SizedBox(height: 16),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            _buildFooterDot(_successColor),
            const SizedBox(width: 10),
            _buildFooterText('PANEL READY'),
            const SizedBox(width: 20),
            Container(width: 1, height: 12, color: Colors.white.withOpacity(0.06)),
            const SizedBox(width: 20),
            Icon(Icons.fingerprint, color: Colors.white.withOpacity(0.12), size: 12),
            const SizedBox(width: 20),
            _buildFooterDot(_glowColor3),
            const SizedBox(width: 10),
            _buildFooterText('SECURE'),
          ],
        ),
        const SizedBox(height: 12),
        Text(
          'PTERODACTYL PANEL CREATOR V2.0',
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
    _floatController.dispose();
    _usernameController.dispose();
    _telegramIdController.dispose();
    _receiverIdController.dispose();
    _domainController.dispose();
    _pltaController.dispose();
    _pltcController.dispose();
    _botTokenController.dispose();
    _ownerIdController.dispose();
    _locationController.dispose();
    _eggController.dispose();
    super.dispose();
  }
}