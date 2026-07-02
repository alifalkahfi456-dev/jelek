import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'dart:math';
import 'package:video_player/video_player.dart';
import 'dart:ui';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';

class AdminPage extends StatefulWidget {
  final String sessionKey;

  const AdminPage({super.key, required this.sessionKey});

  @override
  State<AdminPage> createState() => _AdminPageState();
}

class _AdminPageState extends State<AdminPage> with TickerProviderStateMixin {
  late String sessionKey;
  List<dynamic> fullUserList = [];
  List<dynamic> filteredList = [];
  final List<String> roleOptions = ['vip', 'reseller', 'owner', 'high admin', 'moderator', 'member', 'founder'];
  String selectedRole = 'member';
  int currentPage = 1;
  int itemsPerPage = 50; 
  bool isLoading = false;

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

  late AnimationController _glowController;
  late AnimationController _rotateController;
  late AnimationController _floatController;
  late Animation<double> _glowAnimation;
  late Animation<double> _rotateAnimation;
  late Animation<double> _floatAnimation;

  VideoPlayerController? _videoController;

  final deleteController = TextEditingController();
  final createUsernameController = TextEditingController();
  final createPasswordController = TextEditingController();
  final createDayController = TextEditingController();
  String newUserRole = 'member';

  @override
  void initState() {
    super.initState();
    sessionKey = widget.sessionKey;
    _initializeAnimations();
    _initVideoBackground();
    _fetchUsers();
  }

  void _initializeAnimations() {
    _glowController = AnimationController(
      duration: const Duration(milliseconds: 2500),
      vsync: this,
    )..repeat(reverse: true);
    _glowAnimation = Tween<double>(begin: 0.3, end: 1.0).animate(
      CurvedAnimation(parent: _glowController, curve: Curves.easeInOutSine),
    );

    _rotateController = AnimationController(
      duration: const Duration(seconds: 20),
      vsync: this,
    )..repeat();
    _rotateAnimation = Tween<double>(begin: 0, end: 1).animate(
      CurvedAnimation(parent: _rotateController, curve: Curves.linear),
    );

    _floatController = AnimationController(
      duration: const Duration(milliseconds: 3000),
      vsync: this,
    )..repeat(reverse: true);
    _floatAnimation = Tween<double>(begin: 0, end: -8).animate(
      CurvedAnimation(parent: _floatController, curve: Curves.easeInOutSine),
    );
  }

  Future<void> _initVideoBackground() async {
    try {
      _videoController = VideoPlayerController.asset('assets/videos/banner.mp4')
        ..initialize().then((_) {
          _videoController?.setLooping(true);
          _videoController?.setVolume(0.0);
          _videoController?.play();
          if (mounted) setState(() {});
        });
    } catch (e) {
      debugPrint("Gagal memuat video: $e");
    }
  }

  TextStyle _cinzel(double size, FontWeight weight, [double opacity = 1.0]) {
    return TextStyle(
      fontFamily: "CinzelDecorative",
      fontSize: size,
      fontWeight: weight,
      color: Colors.white.withOpacity(opacity),
      letterSpacing: 1.2,
    );
  }

  Widget _buildAnimatedBackground() {
    return Stack(
      children: [
        if (_videoController != null && _videoController!.value.isInitialized)
          SizedBox.expand(
            child: FittedBox(
              fit: BoxFit.cover,
              child: SizedBox(
                width: _videoController!.value.size.width,
                height: _videoController!.value.size.height,
                child: Opacity(opacity: 0.08, child: VideoPlayer(_videoController!)),
              ),
            ),
          ),
        
        AnimatedBuilder(
          animation: _rotateAnimation,
          builder: (context, _) {
            final size = MediaQuery.of(context).size;
            return Stack(
              children: [
                Positioned(
                  bottom: -size.height * 0.15,
                  right: -size.width * 0.2,
                  child: Transform.rotate(
                    angle: _rotateAnimation.value * pi * 2,
                    child: Container(
                      width: size.width * 0.7,
                      height: size.width * 0.7,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        border: Border.all(color: _glowColor1.withOpacity(0.05), width: 1.5),
                        boxShadow: [
                          BoxShadow(
                            color: _glowColor1.withOpacity(0.03),
                            blurRadius: 30,
                            spreadRadius: 10,
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
                Positioned(
                  top: -size.height * 0.08,
                  left: -size.width * 0.15,
                  child: Transform.rotate(
                    angle: -_rotateAnimation.value * pi,
                    child: Container(
                      width: size.width * 0.5,
                      height: size.width * 0.5,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        border: Border.all(color: _glowColor2.withOpacity(0.06), width: 1),
                      ),
                    ),
                  ),
                ),
                Positioned(
                  top: size.height * 0.3,
                  right: -size.width * 0.1,
                  child: Transform.rotate(
                    angle: _rotateAnimation.value * pi * 1.5,
                    child: Container(
                      width: size.width * 0.4,
                      height: size.width * 0.4,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        border: Border.all(color: _glowColor3.withOpacity(0.04), width: 0.8),
                      ),
                    ),
                  ),
                ),
              ],
            );
          },
        ),
        
        Container(
          decoration: BoxDecoration(
            gradient: RadialGradient(
              center: Alignment.center,
              radius: 1.2,
              colors: [
                Colors.transparent,
                Colors.black.withOpacity(0.6),
                _darkerBg.withOpacity(0.9),
              ],
              stops: const [0.3, 0.7, 1.0],
            ),
          ),
        ),
        
        // Grid pattern overlay
        Container(
          decoration: BoxDecoration(
            backgroundBlendMode: BlendMode.overlay,
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                Colors.white.withOpacity(0.02),
                Colors.transparent,
                Colors.white.withOpacity(0.01),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildGlassCard({required Widget child, double elevation = 0}) {
    return Transform(
      transform: Matrix4.identity()
        ..translate(0, elevation)
        ..rotateX(elevation * 0.01),
      child: Container(
        decoration: BoxDecoration(
          color: _cardColor.withOpacity(0.85),
          borderRadius: BorderRadius.circular(24),
          border: Border.all(
            color: _glowColor1.withOpacity(0.15),
            width: 1.5,
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.4),
              blurRadius: 20,
              offset: const Offset(0, 8),
            ),
            BoxShadow(
              color: _glowColor1.withOpacity(0.08),
              blurRadius: 30,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(24),
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
            child: child,
          ),
        ),
      ),
    );
  }

  Future<void> _fetchUsers() async {
    if (isLoading) return;
    setState(() => isLoading = true);
    try {
      final res = await http.get(Uri.parse('http://server.sanzyoffc.panelantirusuh.biz.id:10604/api/user/listUsers?key=$sessionKey'));
      final data = jsonDecode(res.body);
      if (data['valid'] == true && data['authorized'] == true) {
        fullUserList = data['users'] ?? [];
        _filterAndPaginate();
      } else {
        _showSnackBar(data['message'] ?? 'Unauthorized.', isError: true);
      }
    } catch (_) {
      _showSnackBar("Failed to load users.", isError: true);
    }
    setState(() => isLoading = false);
  }

  void _filterAndPaginate() {
    setState(() {
      currentPage = 1;
      filteredList = fullUserList.where((u) => u['role'] == selectedRole).toList();
    });
  }

  List<dynamic> _getCurrentPageData() {
    if (filteredList.isEmpty) return [];
    final start = (currentPage - 1) * itemsPerPage;
    final end = (start + itemsPerPage);
    return filteredList.sublist(start, end > filteredList.length ? filteredList.length : end);
  }

  int get totalPages => (filteredList.length / itemsPerPage).ceil();

  Future<void> _deleteUser(String username) async {
    setState(() => isLoading = true);
    try {
      final res = await http.get(Uri.parse('http://server.sanzyoffc.panelantirusuh.biz.id:10604/api/user/deleteUser?key=$sessionKey&username=$username'));
      final data = jsonDecode(res.body);
      if (data['deleted'] == true) {
        _showSnackBar("User '${data['user']['username']}' deleted.");
        _fetchUsers();
      } else {
        _showSnackBar(data['message'] ?? 'Delete failed.', isError: true);
      }
    } catch (_) {
      _showSnackBar("Server error.", isError: true);
    }
    setState(() => isLoading = false);
  }

  Future<void> _createAccount() async {
    final username = createUsernameController.text.trim();
    final password = createPasswordController.text.trim();
    final day = createDayController.text.trim();

    if (username.isEmpty || password.isEmpty || day.isEmpty) {
      _showSnackBar("All fields required.", isError: true);
      return;
    }

    setState(() => isLoading = true);
    if (mounted) Navigator.pop(context); 
    try {
      final url = Uri.parse('http://server.sanzyoffc.panelantirusuh.biz.id:10604/api/user/userAdd?key=$sessionKey&username=$username&password=$password&day=$day&role=$newUserRole');
      final res = await http.get(url);
      final data = jsonDecode(res.body);

      if (data['created'] == true) {
        _showSnackBar("Account '${data['user']['username']}' created.");
        _fetchUsers();
      } else {
        _showSnackBar(data['message'] ?? 'Create failed.', isError: true);
      }
    } catch (_) {
      _showSnackBar("Server error.", isError: true);
    }
    if (mounted) setState(() => isLoading = false);
  }

  void _showSnackBar(String message, {bool isError = false}) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message, style: _cinzel(12, FontWeight.w600, isError ? 1.0 : 0.9)),
        backgroundColor: isError ? _roseColor.withOpacity(0.95) : _glowColor1.withOpacity(0.95),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        margin: const EdgeInsets.all(16),
      ),
    );
  }

  Widget _buildNeonHeader() {
    return AnimatedBuilder(
      animation: _floatAnimation,
      builder: (context, _) {
        return Transform.translate(
          offset: Offset(0, _floatAnimation.value),
          child: Padding(
            padding: const EdgeInsets.fromLTRB(20, 20, 20, 12),
            child: _buildGlassCard(
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(14),
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: [_glowColor1.withOpacity(0.2), _glowColor2.withOpacity(0.1)],
                        ),
                        borderRadius: BorderRadius.circular(18),
                        border: Border.all(color: _glowColor1.withOpacity(0.3), width: 1.5),
                      ),
                      child: Icon(FontAwesomeIcons.userShield, color: _glowColor1, size: 28),
                    ),
                    const SizedBox(width: 20),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          ShaderMask(
                            shaderCallback: (bounds) => LinearGradient(
                              colors: [_glowColor1, _accentColor, _glowColor2],
                            ).createShader(bounds),
                            child: Text(
                              "ADMIN PANEL",
                              style: _cinzel(20, FontWeight.w900, 1.0),
                            ),
                          ),
                          const SizedBox(height: 6),
                          Text(
                            "User Management • DEATHXRAT v4.1",
                            style: _cinzel(11, FontWeight.w600, 0.5),
                          ),
                        ],
                      ),
                    ),
                    GestureDetector(
                      onTap: _fetchUsers,
                      child: Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            colors: [_glowColor1.withOpacity(0.1), Colors.transparent],
                          ),
                          shape: BoxShape.circle,
                          border: Border.all(color: _glowColor1.withOpacity(0.2), width: 1),
                        ),
                        child: Icon(Icons.refresh, color: _glowColor1, size: 22),
                      ),
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

  Widget _buildActionCards() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Row(
        children: [
          Expanded(
            child: _build3DCard(
              title: 'CREATE USER',
              icon: FontAwesomeIcons.userPlus,
              gradient: [Colors.green.shade400, Colors.green.shade800],
              onTap: () => _showCreateUserDialog(),
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: _build3DCard(
              title: 'DELETE USER',
              icon: FontAwesomeIcons.userMinus,
              gradient: [Colors.red.shade400, Colors.red.shade800],
              onTap: () => _showDeleteUserDialog(),
            ),
          ),
        ],
      ),
    );
  }

  Widget _build3DCard({required String title, required IconData icon, required List<Color> gradient, required VoidCallback onTap}) {
    return AnimatedBuilder(
      animation: _floatAnimation,
      builder: (context, _) {
        return Transform.translate(
          offset: Offset(0, _floatAnimation.value * 0.5),
          child: GestureDetector(
            onTap: onTap,
            child: Container(
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(20),
                boxShadow: [
                  BoxShadow(
                    color: gradient[0].withOpacity(0.3),
                    blurRadius: 20,
                    offset: const Offset(0, 8),
                  ),
                ],
              ),
              child: Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: gradient.map((c) => c.withOpacity(0.85)).toList(),
                  ),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: Colors.white.withOpacity(0.2), width: 1),
                ),
                child: Column(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(14),
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.15),
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: Colors.white.withOpacity(0.3), width: 1),
                      ),
                      child: Icon(icon, color: Colors.white, size: 28),
                    ),
                    const SizedBox(height: 12),
                    Text(
                      title,
                      style: _cinzel(13, FontWeight.w800, 1.0),
                    ),
                    const SizedBox(height: 4),
                    Container(
                      width: 40,
                      height: 2,
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.3),
                        borderRadius: BorderRadius.circular(2),
                      ),
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

  Widget _buildFilterChips() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: Row(
          children: roleOptions.map((role) {
            final isSelected = selectedRole == role;
            Color chipColor;
            switch (role.toLowerCase()) {
              case 'vip': chipColor = const Color(0xFFFFD700); break;
              case 'reseller': chipColor = const Color(0xFF2196F3); break;
              case 'owner': chipColor = const Color(0xFF9C27B0); break;
              case 'founder': chipColor = const Color(0xFFE91E63); break;
              case 'high admin': chipColor = const Color(0xFFFF5722); break;
              default: chipColor = _glowColor1;
            }
            return Padding(
              padding: const EdgeInsets.only(right: 12),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                transform: Matrix4.identity()..scale(isSelected ? 1.05 : 1.0),
                child: GestureDetector(
                  onTap: () => setState(() {
                    selectedRole = role;
                    _filterAndPaginate();
                  }),
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                    decoration: BoxDecoration(
                      gradient: isSelected 
                        ? LinearGradient(
                            colors: [chipColor.withOpacity(0.2), chipColor.withOpacity(0.05)],
                          )
                        : null,
                      color: isSelected ? Colors.transparent : _cardColor.withOpacity(0.6),
                      borderRadius: BorderRadius.circular(30),
                      border: Border.all(
                        color: isSelected ? chipColor : chipColor.withOpacity(0.2),
                        width: isSelected ? 1.5 : 1,
                      ),
                      boxShadow: isSelected ? [
                        BoxShadow(
                          color: chipColor.withOpacity(0.3),
                          blurRadius: 12,
                          offset: const Offset(0, 4),
                        ),
                      ] : null,
                    ),
                    child: Text(
                      role.toUpperCase(),
                      style: _cinzel(11, FontWeight.w800, isSelected ? 1.0 : 0.5),
                    ),
                  ),
                ),
              ),
            );
          }).toList(),
        ),
      ),
    );
  }

  Widget _buildUserTable() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: _buildGlassCard(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Container(
              padding: const EdgeInsets.all(18),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [_glowColor1.withOpacity(0.08), Colors.transparent],
                ),
                borderRadius: const BorderRadius.only(topLeft: Radius.circular(24), topRight: Radius.circular(24)),
              ),
              child: Row(
                children: [
                  Icon(FontAwesomeIcons.users, color: _glowColor1, size: 18),
                  const SizedBox(width: 12),
                  Text(
                    'USER REGISTRY (${filteredList.length})',
                    style: _cinzel(13, FontWeight.w800, 0.9),
                  ),
                  const Spacer(),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: _glowColor1.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: _glowColor1.withOpacity(0.2), width: 1),
                    ),
                    child: Text(
                      'Page $currentPage/$totalPages',
                      style: _cinzel(10, FontWeight.w700, 0.6),
                    ),
                  ),
                ],
              ),
            ),
            _buildCompactListView(),
            _buildPaginationControls(),
          ],
        ),
      ),
    );
  }

  Widget _buildCompactListView() {
    if (filteredList.isEmpty) {
      return const Padding(
        padding: EdgeInsets.all(60),
        child: Center(
          child: Column(
            children: [
              Icon(Icons.person_off, color: Colors.white24, size: 48),
              SizedBox(height: 16),
              Text('No users found for this role.', style: TextStyle(color: Colors.white24, fontFamily: 'CinzelDecorative', fontSize: 12)),
            ],
          ),
        ),
      );
    }

    return SizedBox(
      height: 450,
      child: ListView.separated(
        padding: const EdgeInsets.symmetric(vertical: 8),
        itemCount: _getCurrentPageData().length,
        separatorBuilder: (context, index) => Divider(
          color: Colors.white.withOpacity(0.03),
          height: 1,
        ),
        itemBuilder: (context, index) {
          final user = _getCurrentPageData()[index];
          final roleColor = _getRoleColor(user['role'] ?? 'member');
          return AnimatedBuilder(
            animation: _floatAnimation,
            builder: (context, _) {
              return Transform.translate(
                offset: Offset(0, sin(index * 0.5) * 2),
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                  margin: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(12),
                    color: Colors.white.withOpacity(0.02),
                  ),
                  child: Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            colors: [roleColor.withOpacity(0.2), Colors.transparent],
                          ),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: roleColor.withOpacity(0.2), width: 1),
                        ),
                        child: Icon(FontAwesomeIcons.user, color: roleColor, size: 16),
                      ),
                      const SizedBox(width: 14),
                      Expanded(
                        flex: 3,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              user['username'] ?? 'N/A',
                              style: _cinzel(13, FontWeight.w700, 0.9),
                              overflow: TextOverflow.ellipsis,
                            ),
                            const SizedBox(height: 2),
                            Text(
                              user['parent'] ?? 'SYSTEM',
                              style: _cinzel(9, FontWeight.w500, 0.3),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ],
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            colors: [roleColor.withOpacity(0.15), roleColor.withOpacity(0.05)],
                          ),
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(color: roleColor.withOpacity(0.2), width: 1),
                        ),
                        child: Text(
                          (user['role'] ?? 'N/A').toUpperCase(),
                          style: _cinzel(10, FontWeight.w800, 0.9),
                        ),
                      ),
                      const SizedBox(width: 12),
                      GestureDetector(
                        onTap: () => _showDeleteConfirmationDialog(user['username']),
                        child: Container(
                          padding: const EdgeInsets.all(10),
                          decoration: BoxDecoration(
                            color: _roseColor.withOpacity(0.1),
                            shape: BoxShape.circle,
                            border: Border.all(color: _roseColor.withOpacity(0.2), width: 1),
                          ),
                          child: Icon(Icons.delete_outline, color: _roseColor.withOpacity(0.7), size: 18),
                        ),
                      ),
                    ],
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }

  Color _getRoleColor(String role) {
    switch (role.toLowerCase()) {
      case 'vip': return const Color(0xFFFFD700);
      case 'reseller': return const Color(0xFF2196F3);
      case 'moderator': return const Color(0xFF00BCD4);
      case 'high admin': return const Color(0xFFFF5722);
      case 'owner': return const Color(0xFF9C27B0);
      case 'founder': return const Color(0xFFE91E63);
      default: return _glowColor1;
    }
  }

  Widget _buildPaginationControls() {
    if (totalPages <= 1) return const SizedBox.shrink();

    return Padding(
      padding: const EdgeInsets.all(20),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          GestureDetector(
            onTap: currentPage > 1 ? () => setState(() => currentPage--) : null,
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: currentPage > 1 ? _glowColor1.withOpacity(0.1) : Colors.white.withOpacity(0.03),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: currentPage > 1 ? _glowColor1.withOpacity(0.2) : Colors.white.withOpacity(0.05), width: 1),
              ),
              child: Icon(Icons.chevron_left, color: currentPage > 1 ? _glowColor1 : Colors.white24, size: 20),
            ),
          ),
          const SizedBox(width: 20),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [_glowColor1.withOpacity(0.1), _glowColor2.withOpacity(0.05)],
              ),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: _glowColor1.withOpacity(0.2), width: 1),
            ),
            child: Text(
              '$currentPage / $totalPages',
              style: _cinzel(12, FontWeight.w800, 0.8),
            ),
          ),
          const SizedBox(width: 20),
          GestureDetector(
            onTap: currentPage < totalPages ? () => setState(() => currentPage++) : null,
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: currentPage < totalPages ? _glowColor1.withOpacity(0.1) : Colors.white.withOpacity(0.03),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: currentPage < totalPages ? _glowColor1.withOpacity(0.2) : Colors.white.withOpacity(0.05), width: 1),
              ),
              child: Icon(Icons.chevron_right, color: currentPage < totalPages ? _glowColor1 : Colors.white24, size: 20),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPremiumTextField({
    required TextEditingController controller,
    required String label,
    required IconData icon,
    bool isPassword = false,
    TextInputType? keyboardType,
  }) {
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
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
        obscureText: isPassword,
        keyboardType: keyboardType,
        style: _cinzel(13, FontWeight.w600, 0.9),
        cursorColor: _glowColor1,
        decoration: InputDecoration(
          labelText: label,
          labelStyle: _cinzel(11, FontWeight.w600, 0.5),
          prefixIcon: Icon(icon, color: _glowColor2.withOpacity(0.5), size: 20),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(16),
            borderSide: BorderSide.none,
          ),
          filled: true,
          fillColor: _cardColor.withOpacity(0.6),
          contentPadding: const EdgeInsets.symmetric(horizontal: 18, vertical: 16),
        ),
      ),
    );
  }

  void _showCreateUserDialog() {
    createUsernameController.clear();
    createPasswordController.clear();
    createDayController.clear();
    newUserRole = 'member';

    showDialog(
      context: context,
      builder: (_) => _buildCreateUserDialog(),
    );
  }

  Widget _buildCreateUserDialog() {
    return Dialog(
      backgroundColor: Colors.transparent,
      insetPadding: const EdgeInsets.all(20),
      child: _buildGlassCard(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(28),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [_glowColor1.withOpacity(0.2), _glowColor2.withOpacity(0.1)],
                      ),
                      borderRadius: BorderRadius.circular(18),
                      border: Border.all(color: _glowColor1.withOpacity(0.3), width: 1.5),
                    ),
                    child: Icon(FontAwesomeIcons.userPlus, color: _glowColor1, size: 24),
                  ),
                  const SizedBox(width: 18),
                  ShaderMask(
                    shaderCallback: (bounds) => LinearGradient(
                      colors: [_glowColor1, _accentColor, _glowColor2],
                    ).createShader(bounds),
                    child: Text(
                      'CREATE USER',
                      style: _cinzel(18, FontWeight.w900, 1.0),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 28),
              _buildPremiumTextField(controller: createUsernameController, label: 'Username', icon: Icons.person),
              const SizedBox(height: 18),
              _buildPremiumTextField(controller: createPasswordController, label: 'Password', icon: Icons.lock, isPassword: true),
              const SizedBox(height: 18),
              _buildPremiumTextField(controller: createDayController, label: 'Duration (days)', icon: Icons.calendar_today, keyboardType: TextInputType.number),
              const SizedBox(height: 18),
              Container(
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: _glowColor1.withOpacity(0.2), width: 1),
                ),
                child: DropdownButtonFormField<String>(
                  value: newUserRole,
                  dropdownColor: _cardColor,
                  style: _cinzel(13, FontWeight.w600, 0.9),
                  decoration: InputDecoration(
                    labelText: 'Role',
                    labelStyle: _cinzel(11, FontWeight.w600, 0.5),
                    prefixIcon: Icon(Icons.admin_panel_settings, color: _glowColor2.withOpacity(0.5), size: 20),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(16),
                      borderSide: BorderSide.none,
                    ),
                    filled: true,
                    fillColor: _cardColor.withOpacity(0.6),
                    contentPadding: const EdgeInsets.symmetric(horizontal: 18, vertical: 16),
                  ),
                  items: roleOptions.map((role) {
                    return DropdownMenuItem(value: role, child: Text(role.toUpperCase(), style: _cinzel(12, FontWeight.w700, 0.8)));
                  }).toList(),
                  onChanged: (val) => setState(() => newUserRole = val ?? 'member'),
                ),
              ),
              const SizedBox(height: 28),
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  TextButton(
                    onPressed: () => Navigator.pop(context),
                    style: TextButton.styleFrom(
                      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                    ),
                    child: Text('Cancel', style: _cinzel(12, FontWeight.w600, 0.6)),
                  ),
                  const SizedBox(width: 16),
                  GestureDetector(
                    onTap: _createAccount,
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 12),
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: [_glowColor1, _glowColor2],
                        ),
                        borderRadius: BorderRadius.circular(16),
                        boxShadow: [
                          BoxShadow(
                            color: _glowColor1.withOpacity(0.4),
                            blurRadius: 20,
                            offset: const Offset(0, 6),
                          ),
                        ],
                      ),
                      child: Text(
                        'CREATE',
                        style: _cinzel(12, FontWeight.w900, 1.0).copyWith(color: _darkerBg),
                      ),
                    ),
                  ),
                ],
              )
            ],
          ),
        ),
      ),
    );
  }

  void _showDeleteUserDialog() {
    deleteController.clear();
    showDialog(
      context: context,
      builder: (_) => Dialog(
        backgroundColor: Colors.transparent,
        insetPadding: const EdgeInsets.all(20),
        child: _buildGlassCard(
          child: Padding(
            padding: const EdgeInsets.all(28),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(14),
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: [_roseColor.withOpacity(0.2), _roseColor.withOpacity(0.1)],
                        ),
                        borderRadius: BorderRadius.circular(18),
                        border: Border.all(color: _roseColor.withOpacity(0.3), width: 1.5),
                      ),
                      child: Icon(FontAwesomeIcons.userMinus, color: _roseColor, size: 24),
                    ),
                    const SizedBox(width: 18),
                    Text(
                      'DELETE USER',
                      style: _cinzel(18, FontWeight.w900, 1.0).copyWith(color: _roseColor),
                    ),
                  ],
                ),
                const SizedBox(height: 28),
                _buildPremiumTextField(controller: deleteController, label: 'Username', icon: Icons.person),
                const SizedBox(height: 28),
                Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    TextButton(
                      onPressed: () => Navigator.pop(context),
                      style: TextButton.styleFrom(
                        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                      ),
                      child: Text('Cancel', style: _cinzel(12, FontWeight.w600, 0.6)),
                    ),
                    const SizedBox(width: 16),
                    GestureDetector(
                      onTap: () {
                        Navigator.pop(context);
                        _deleteUser(deleteController.text.trim());
                      },
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 12),
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            colors: [_roseColor, _roseColor.withOpacity(0.7)],
                          ),
                          borderRadius: BorderRadius.circular(16),
                          boxShadow: [
                            BoxShadow(
                              color: _roseColor.withOpacity(0.4),
                              blurRadius: 20,
                              offset: const Offset(0, 6),
                            ),
                          ],
                        ),
                        child: Text(
                          'DELETE',
                          style: _cinzel(12, FontWeight.w900, 1.0).copyWith(color: _darkerBg),
                        ),
                      ),
                    ),
                  ],
                )
              ],
            ),
          ),
        ),
      ),
    );
  }

  void _showDeleteConfirmationDialog(String username) {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        backgroundColor: _cardColor,
        shape: RoundedRectangleBorder(
          side: BorderSide(color: _roseColor.withOpacity(0.3), width: 1.5),
          borderRadius: BorderRadius.circular(24),
        ),
        title: Row(
          children: [
            Icon(Icons.warning_amber_rounded, color: _roseColor),
            const SizedBox(width: 12),
            Text('Confirm Delete', style: _cinzel(16, FontWeight.w800, 1.0)),
          ],
        ),
        content: Text('Delete user "$username" permanently?', style: _cinzel(13, FontWeight.w600, 0.7)),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('Cancel', style: _cinzel(12, FontWeight.w600, 0.6)),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              _deleteUser(username);
            },
            child: Text('Delete', style: _cinzel(12, FontWeight.w800, 1.0).copyWith(color: _roseColor)),
          ),
        ],
      ),
    );
  }

  Widget _buildFooter() {
    return Padding(
      padding: const EdgeInsets.all(20),
      child: Column(
        children: [
          Container(
            height: 1,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [Colors.transparent, _glowColor1.withOpacity(0.15), Colors.transparent],
              ),
            ),
          ),
          const SizedBox(height: 16),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              _buildFooterDot(_successColor),
              const SizedBox(width: 10),
              _buildFooterText("SECURE CONNECTION"),
              const SizedBox(width: 24),
              Container(width: 1, height: 12, color: Colors.white.withOpacity(0.08)),
              const SizedBox(width: 24),
              Icon(Icons.fingerprint, color: Colors.white.withOpacity(0.15), size: 14),
              const SizedBox(width: 24),
              _buildFooterDot(_glowColor2),
              const SizedBox(width: 10),
              _buildFooterText("ENCRYPTED CHANNEL"),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            "DEATHXRAT ADMIN PORTAL • V4.1 • ENCRYPTED",
            style: _cinzel(8, FontWeight.w600, 0.15),
          ),
        ],
      ),
    );
  }

  Widget _buildFooterDot(Color color) {
    return Container(
      width: 6,
      height: 6,
      decoration: BoxDecoration(
        color: color,
        shape: BoxShape.circle,
        boxShadow: [BoxShadow(color: color, blurRadius: 8)],
      ),
    );
  }

  Widget _buildFooterText(String text) {
    return Text(
      text,
      style: _cinzel(9, FontWeight.w700, 0.25),
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
            child: isLoading
                ? Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const SizedBox(
                          width: 48,
                          height: 48,
                          child: CircularProgressIndicator(
                            color: Color(0xFFE0E0F8),
                            strokeWidth: 3,
                          ),
                        ),
                        const SizedBox(height: 20),
                        Text(
                          "LOADING ADMIN PANEL...",
                          style: _cinzel(12, FontWeight.w700, 0.5),
                        ),
                      ],
                    ),
                  )
                : Column(
                    children: [
                      _buildNeonHeader(),
                      const SizedBox(height: 16),
                      _buildActionCards(),
                      const SizedBox(height: 24),
                      _buildFilterChips(),
                      const SizedBox(height: 20),
                      Expanded(child: _buildUserTable()),
                      _buildFooter(),
                    ],
                  ),
          ),
        ],
      ),
    );
  }

  @override
  void dispose() {
    _glowController.dispose();
    _rotateController.dispose();
    _floatController.dispose();
    _videoController?.dispose();
    deleteController.dispose();
    createUsernameController.dispose();
    createPasswordController.dispose();
    createDayController.dispose();
    super.dispose();
  }
}