import 'dart:convert';
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:device_info_plus/device_info_plus.dart';
import 'package:web_socket_channel/web_socket_channel.dart';
import 'package:web_socket_channel/status.dart' as status;
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:video_player/video_player.dart';
import 'package:url_launcher/url_launcher.dart';

// Import halaman-halaman
import 'anime_home.dart';
import 'change_password.dart';
import 'bug_sender.dart';
import 'nik_check.dart';
import 'admin_page.dart';
import 'home_page.dart'; // Ini file bug nya (Contact & Group)
import 'seller_page.dart';
import 'tools_gateway.dart';
import 'login_page.dart';

class DashboardPage extends StatefulWidget {
  final String username;
  final String password;
  final String role;
  final String expiredDate;
  final String sessionKey;
  final List<Map<String, dynamic>> listBug;
  final List<Map<String, dynamic>> listDoos;
  final List<dynamic> news;

  const DashboardPage({
    super.key,
    required this.username,
    required this.password,
    required this.role,
    required this.expiredDate,
    required this.listBug,
    required this.listDoos,
    required this.sessionKey,
    required this.news,
  });

  @override
  State<DashboardPage> createState() => _DashboardPageState();
}

class _DashboardPageState extends State<DashboardPage>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _animation;
  late WebSocketChannel channel;

  late String sessionKey;
  late String username;
  late String password;
  late String role;
  late String expiredDate;
  late List<Map<String, dynamic>> listBug;
  late List<Map<String, dynamic>> listDoos;
  late List<dynamic> newsList;
  String androidId = "unknown";

  int _bottomNavIndex = 0;
  Widget _selectedPage = const Placeholder();

  // --- PALET WARNA DEEP VIOLET ---
  final Color deepRed = const Color(0xFF2A003D);
  final Color mainRed = const Color(0xFF4A148C);
  final Color lightRed = const Color(0xFFB388FF); 
  final Color bgBlack = const Color(0xFF000000); 
  final Color cardBlack = const Color(0xFF0F0F0F); 

  @override
  void initState() {
    super.initState();
    sessionKey = widget.sessionKey;
    username = widget.username;
    password = widget.password;
    role = widget.role;
    expiredDate = widget.expiredDate;
    listBug = widget.listBug;
    listDoos = widget.listDoos;
    newsList = widget.news;

    _controller = AnimationController(
      duration: const Duration(milliseconds: 1000),
      vsync: this,
    );
    _animation = CurvedAnimation(parent: _controller, curve: Curves.easeInOut);
    _controller.forward();

    // Default Page: Dashboard Home
    _selectedPage = _buildEnhancedDashboard();
    _initAndroidIdAndConnect();
  }

  Future<void> _initAndroidIdAndConnect() async {
    final deviceInfo = await DeviceInfoPlugin().androidInfo;
    androidId = deviceInfo.id;
    _connectToWebSocket();
  }

  void _connectToWebSocket() {
    channel = WebSocketChannel.connect(Uri.parse('http://dianaxyz-offc.hostingercloud.web.id:4042'));
    channel.sink.add(jsonEncode({
      "type": "validate",
      "key": sessionKey,
      "androidId": androidId,
    }));
    channel.sink.add(jsonEncode({"type": "stats"}));

    channel.stream.listen((event) {
      final data = jsonDecode(event);
      if (data['type'] == 'myInfo') {
        if (data['valid'] == false) {
          _handleInvalidSession("Session invalid, please re-login.");
        }
      }
    });
  }

  void _handleInvalidSession(String message) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.clear();
    if (!mounted) return;
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
        child: AlertDialog(
          backgroundColor: bgBlack,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
            side: BorderSide(color: mainRed, width: 1),
          ),
          title: Row(
            children: [
              Icon(Icons.warning_rounded, color: mainRed, size: 28),
              const SizedBox(width: 10),
              Text("Session Expired",
                  style: TextStyle(color: mainRed, fontWeight: FontWeight.bold)),
            ],
          ),
          content: Text(message, style: const TextStyle(color: Colors.white70)),
          actions: [
            Container(
              decoration: BoxDecoration(
                color: mainRed,
                borderRadius: BorderRadius.circular(12),
              ),
              child: TextButton(
                onPressed: () {
                  Navigator.of(context).pushAndRemoveUntil(
                    MaterialPageRoute(builder: (_) => const LoginPage()),
                        (route) => false,
                  );
                },
                child: const Text("OK", style: TextStyle(color: Colors.white)),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // --- MODIFIKASI NAVIGASI DI SINI ---
  void _onBottomNavTapped(int index) {
    if (index == 1) {
      // Jika tombol WhatsApp (Index 1) ditekan, Munculkan Dropdown Menu
      _showWhatsAppMenu();
    } else {
      // Navigasi biasa untuk tombol lain
      setState(() {
        _bottomNavIndex = index;
        if (index == 0) {
          _selectedPage = _buildEnhancedDashboard();
        } else if (index == 2) {
          _selectedPage = ToolsPage(sessionKey: sessionKey, userRole: role, listDoos: listDoos);
        } else if (index == 3) {
          _selectedPage = HomeAnimePage();
        }
      });
    }
  }

  // --- FUNGSI MENAMPILKAN MENU WHATSAPP ---
  void _showWhatsAppMenu() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: const Color(0xFF111111).withOpacity(0.95),
          borderRadius: const BorderRadius.vertical(top: Radius.circular(30)),
          border: Border.all(color: mainRed.withOpacity(0.5)),
          boxShadow: [
            BoxShadow(
              color: deepRed.withOpacity(0.2),
              blurRadius: 20,
              spreadRadius: 5,
            )
          ],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Garis Indikator
            Container(width: 50, height: 4, decoration: BoxDecoration(color: Colors.grey, borderRadius: BorderRadius.circular(2))),
            const SizedBox(height: 20),
            
            // Pilihan 1: Bug Contact
            _buildMenuOption(
              icon: Icons.person,
              title: "Bug Contact",
              subtitle: "Send bug to specific number",
              onTap: () {
                Navigator.pop(context); // Tutup modal
                setState(() {
                  _bottomNavIndex = 1; // Set aktif ke icon WA
                  // Panggil HomePage dengan isGroup: false
                  _selectedPage = HomePage(
                    isGroup: false, 
                    username: username,
                    password: password,
                    sessionKey: sessionKey,
                    listBug: listBug,
                    role: role,
                    expiredDate: expiredDate,
                  );
                });
              },
            ),
            const SizedBox(height: 10),
            
            // Pilihan 2: Bug Group
            _buildMenuOption(
              icon: Icons.groups,
              title: "Bug Group",
              subtitle: "Send bug to group link",
              onTap: () {
                Navigator.pop(context); // Tutup modal
                setState(() {
                  _bottomNavIndex = 1; // Set aktif ke icon WA
                  // Panggil HomePage dengan isGroup: true
                  _selectedPage = HomePage(
                    isGroup: true,
                    username: username,
                    password: password,
                    sessionKey: sessionKey,
                    listBug: listBug,
                    role: role,
                    expiredDate: expiredDate,
                  );
                });
              },
            ),
          ],
        ),
      ),
    );
  }

  // Widget Helper untuk Menu Option
  Widget _buildMenuOption({required IconData icon, required String title, required String subtitle, required VoidCallback onTap}) {
    return ListTile(
      leading: Container(
        padding: const EdgeInsets.all(10),
        decoration: BoxDecoration(
          color: mainRed.withOpacity(0.2),
          shape: BoxShape.circle,
          border: Border.all(color: lightRed.withOpacity(0.3)),
        ),
        child: Icon(icon, color: Colors.white),
      ),
      title: Text(title, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontFamily: 'Orbitron')),
      subtitle: Text(subtitle, style: TextStyle(color: Colors.grey[400], fontSize: 12)),
      trailing: Icon(Icons.arrow_forward_ios, size: 14, color: Colors.grey),
      onTap: onTap,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15), side: BorderSide(color: Colors.white10)),
      tileColor: Colors.white.withOpacity(0.05),
    );
  }

  void _navigateToAdminPage() {
    Navigator.push(context, MaterialPageRoute(builder: (_) => AdminPage(sessionKey: sessionKey)));
  }

  void _navigateToSellerPage() {
    Navigator.push(context, MaterialPageRoute(builder: (_) => SellerPage(keyToken: sessionKey)));
  }

  // --- MAIN DASHBOARD CONTENT (Halaman Utama) ---

  Widget _buildEnhancedDashboard() {
    return Container(
      color: bgBlack,
      child: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(vertical: 20),
        child: Column(
          children: [
            // 1. Banner Slider (Top)
            if (newsList.isNotEmpty)
              SizedBox(
                height: 180,
                child: PageView.builder(
                  controller: PageController(viewportFraction: 0.9),
                  itemCount: newsList.length,
                  itemBuilder: (context, i) {
                    final item = newsList[i];
                    return Container(
                      margin: const EdgeInsets.symmetric(horizontal: 5),
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(color: mainRed.withOpacity(0.3), width: 1),
                        boxShadow: [
                          BoxShadow(color: deepRed.withOpacity(0.1), blurRadius: 10)
                        ],
                      ),
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(20),
                        child: Stack(
                          fit: StackFit.expand,
                          children: [
                            if (item['image'] != null)
                              NewsMedia(url: item['image']),
                            Container(
                              decoration: BoxDecoration(
                                gradient: LinearGradient(
                                  colors: [Colors.transparent, Colors.black.withOpacity(0.9)],
                                  begin: Alignment.topCenter,
                                  end: Alignment.bottomCenter,
                                ),
                              ),
                            ),
                            Positioned(
                              bottom: 15,
                              left: 15,
                              right: 15,
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    item['title'] ?? 'No Title',
                                    style: const TextStyle(
                                      color: Colors.white,
                                      fontWeight: FontWeight.bold,
                                      fontSize: 16,
                                    ),
                                  ),
                                  Text(
                                    item['desc'] ?? '',
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                    style: const TextStyle(color: Colors.white70, fontSize: 12),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                ),
              ),

            const SizedBox(height: 25),

            // 2. User Info Card
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Container(
                width: double.infinity,
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: cardBlack,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: mainRed.withOpacity(0.4)),
                  boxShadow: [
                    BoxShadow(color: mainRed.withOpacity(0.1), blurRadius: 15)
                  ],
                ),
                child: Column(
                  children: [
                    const Text(
                      "Welcome Back",
                      style: TextStyle(
                        color: Colors.white54,
                        fontSize: 12,
                        letterSpacing: 2,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(2),
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            gradient: LinearGradient(colors: [mainRed, deepRed]),
                          ),
                          child: const CircleAvatar(
                            radius: 26,
                            backgroundImage: AssetImage('assets/images/icon.jpg'),
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                username,
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                  fontFamily: 'Orbitron',
                                ),
                              ),
                              const SizedBox(height: 6),
                              Row(
                                children: [
                                  _buildMiniBadge("EXP: $expiredDate", isRole: false),
                                  const SizedBox(width: 8),
                                  _buildMiniBadge(role.toUpperCase(), isRole: true),
                                ],
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 25),

            // 3. New Update Slider (Enhanced Design)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Align(
                alignment: Alignment.centerLeft,
                child: Text(
                  "New Update",
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    shadows: [Shadow(color: mainRed, blurRadius: 10)],
                  ),
                ),
              ),
            ),
            const SizedBox(height: 15),

            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Row(
                children: [
                  _buildEnhancedUpdateCard(Icons.bar_chart, "HOXTEN CLOUD Is Comming", "New Update Session HOXTEN CLOUD"),
                  const SizedBox(width: 15),
                  _buildEnhancedUpdateCard(FontAwesomeIcons.whatsapp, "Bug Group Come", "New Update Fiture Bug"),
                  const SizedBox(width: 15),
                  _buildEnhancedUpdateCard(Icons.public, "Global Network", "Network Stability Improved"),
                ],
              ),
            ),

            const SizedBox(height: 25),

            // 4. TELEGRAM CHANNEL BUTTON (Redesigned Theme)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Container(
                width: double.infinity,
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [cardBlack, deepRed],
                    begin: Alignment.centerLeft,
                    end: Alignment.centerRight,
                  ),
                  borderRadius: BorderRadius.circular(15),
                  border: Border.all(color: mainRed.withOpacity(0.5)), 
                  boxShadow: [
                    BoxShadow(color: deepRed.withOpacity(0.3), blurRadius: 10, offset: const Offset(0, 4)),
                  ],
                ),
                child: Material(
                  color: Colors.transparent,
                  child: InkWell(
                    borderRadius: BorderRadius.circular(15),
                    onTap: () async {
                      const url = 'https://t.me/HoxtenCloud1';
                      final uri = Uri.parse(url);
                      if (await canLaunchUrl(uri)) {
                        await launchUrl(uri, mode: LaunchMode.externalApplication);
                      }
                    },
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(10),
                            decoration: BoxDecoration(
                              color: mainRed.withOpacity(0.2), 
                              shape: BoxShape.circle,
                              border: Border.all(color: lightRed.withOpacity(0.5)),
                            ),
                            child: const Icon(FontAwesomeIcons.telegram, color: Colors.white, size: 24),
                          ),
                          const SizedBox(width: 15),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: const [
                                Text(
                                  "Join Channels To Get Info",
                                  style: TextStyle(
                                    color: Colors.white,
                                    fontSize: 14,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                SizedBox(height: 4),
                                Text(
                                  "Tap here to open Telegram",
                                  style: TextStyle(
                                    color: Colors.white70,
                                    fontSize: 10,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const Icon(Icons.arrow_forward_ios_rounded, color: Colors.white54, size: 16),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ),

            const SizedBox(height: 25),

            // 5. Manage Sender Button
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Container(
                width: double.infinity,
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [deepRed, mainRed, lightRed],
                    begin: Alignment.centerLeft,
                    end: Alignment.centerRight,
                  ),
                  borderRadius: BorderRadius.circular(15),
                  boxShadow: [
                    BoxShadow(color: mainRed.withOpacity(0.4), blurRadius: 15, offset: const Offset(0, 4)),
                  ],
                ),
                child: Material(
                  color: Colors.transparent,
                  child: InkWell(
                    borderRadius: BorderRadius.circular(15),
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => BugSenderPage(
                            sessionKey: sessionKey,
                            username: username,
                            role: role,
                          ),
                        ),
                      );
                    },
                    child: Padding(
                      padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 20),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Icon(Icons.phone_android_rounded, color: Colors.white, size: 24),
                          const SizedBox(width: 12),
                          Text(
                            "Management Sender",
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                              fontFamily: 'Orbitron',
                              letterSpacing: 1,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ),

            const SizedBox(height: 80), // Extra space for floating nav
          ],
        ),
      ),
    );
  }

  // --- HELPER WIDGETS ---

  Widget _buildMiniBadge(String text, {required bool isRole}) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: isRole ? mainRed.withOpacity(0.2) : Colors.black,
        border: Border.all(color: isRole ? lightRed : Colors.grey.shade700),
        borderRadius: BorderRadius.circular(6),
      ),
      child: Text(
        text,
        style: TextStyle(
          color: isRole ? lightRed : Colors.grey.shade400,
          fontSize: 10,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }

  Widget _buildEnhancedUpdateCard(IconData icon, String title, String subtitle) {
    return Container(
      width: 220,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [Colors.black, deepRed.withOpacity(0.2)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: mainRed.withOpacity(0.5),
          width: 1.5,
        ),
        boxShadow: [
          BoxShadow(
            color: mainRed.withOpacity(0.1),
            blurRadius: 10,
            spreadRadius: 1,
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: deepRed.withOpacity(0.2),
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: lightRed.withOpacity(0.3)),
            ),
            child: Icon(icon, color: lightRed, size: 20),
          ),
          const SizedBox(height: 12),
          Text(
            title,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.bold,
              fontSize: 14,
              letterSpacing: 0.5,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            subtitle,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              color: Colors.grey.shade400,
              fontSize: 11,
              height: 1.2,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCustomMenuIcon() {
    return Builder(
      builder: (context) => IconButton(
        icon: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(width: 24, height: 2.5, decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(5))),
            const SizedBox(height: 5),
            Container(width: 16, height: 2.5, decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(5))),
            const SizedBox(height: 5),
            Container(width: 8, height: 2.5, decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(5))),
          ],
        ),
        onPressed: () => Scaffold.of(context).openDrawer(),
      ),
    );
  }

  // --- SCAFFOLD & APPBAR ---

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: bgBlack,
      drawer: _buildDrawer(),
      appBar: AppBar(
        backgroundColor: Colors.black,
        elevation: 0,
        centerTitle: true,
        leading: _buildCustomMenuIcon(),
        title: Padding(
          padding: const EdgeInsets.only(right: 15.0), 
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Transform.translate(
                offset: const Offset(-5, 0),
                child: Image.asset(
                  'assets/images/reven.png',
                  height: 40,
                  fit: BoxFit.contain,
                ),
              ),
              const SizedBox(width: 5), 
              const Text(
                "HOXTEN",
                style: TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.w900,
                  fontSize: 20,
                  fontFamily: 'Orbitron',
                  letterSpacing: 1,
                ),
              ),
            ],
          ),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.help, color: Colors.white, size: 28),
            onPressed: () {
              showDialog(
                context: context,
                builder: (context) => AlertDialog(
                  backgroundColor: const Color(0xFF1A1A1A),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(15),
                    side: BorderSide(color: mainRed, width: 1),
                  ),
                  title: Row(
                    children: [
                      Icon(Icons.info_outline, color: lightRed),
                      const SizedBox(width: 10),
                      const Text("Information", style: TextStyle(color: Colors.white)),
                    ],
                  ),
                  content: const Text(
                    "HOXTEN CLOUD Dashboard v3.0\n\nThis application is designed for management and monitoring tools. Stay tuned for upcoming features!",
                    style: TextStyle(color: Colors.white70),
                  ),
                  actions: [
                    TextButton(
                      onPressed: () => Navigator.pop(context),
                      child: Text("Close", style: TextStyle(color: lightRed)),
                    ),
                  ],
                ),
              );
            },
          ),
          IconButton(
            icon: const Icon(Icons.logout_rounded, color: Colors.white, size: 28),
            onPressed: () => _showLogoutDialog(),
          ),
          const SizedBox(width: 8),
        ],
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(1),
          child: Container(
            color: mainRed.withOpacity(0.2),
            height: 1,
          ),
        ),
      ),
      body: FadeTransition(opacity: _animation, child: _selectedPage),
      extendBody: true,
      bottomNavigationBar: _buildFloatingBottomNav(),
    );
  }

  // --- FLOATING NAV BAR ---
  Widget _buildFloatingBottomNav() {
    return Container(
      margin: const EdgeInsets.only(left: 20, right: 20, bottom: 20),
      decoration: BoxDecoration(
        color: const Color(0xFF111111).withOpacity(0.95),
        borderRadius: BorderRadius.circular(30),
        border: Border.all(color: mainRed.withOpacity(0.5)),
        boxShadow: [
          BoxShadow(
            color: mainRed.withOpacity(0.2),
            blurRadius: 20,
            spreadRadius: 2,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(30),
        child: BottomNavigationBar(
          backgroundColor: Colors.transparent,
          type: BottomNavigationBarType.fixed,
          
          showSelectedLabels: true,
          showUnselectedLabels: false,
          
          selectedItemColor: lightRed,
          unselectedItemColor: Colors.grey.shade600,
          currentIndex: _bottomNavIndex,
          onTap: _onBottomNavTapped,
          elevation: 0,
          items: const [
            BottomNavigationBarItem(
              icon: Icon(Icons.home_filled, size: 28),
              label: "Home",
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.chat_bubble_rounded, size: 26),
              label: "WhatsApp",
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.construction_rounded, size: 26),
              label: "Tools",
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.movie_filter_outlined, size: 26),
              label: "Anime",
            ),
          ],
        ),
      ),
    );
  }

  void _showLogoutDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFF111111),
        shape: RoundedRectangleBorder(
          side: BorderSide(color: mainRed.withOpacity(0.5)),
          borderRadius: BorderRadius.circular(15),
        ),
        title: const Text("Logout", style: TextStyle(color: Colors.white)),
        content: const Text("Are you sure you want to logout?", style: TextStyle(color: Colors.white70)),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text("Cancel", style: TextStyle(color: lightRed)),
          ),
          TextButton(
            onPressed: () async {
              Navigator.pop(context);
              final prefs = await SharedPreferences.getInstance();
              await prefs.clear();
              if (!mounted) return;
              Navigator.of(context).pushAndRemoveUntil(
                MaterialPageRoute(builder: (_) => const LoginPage()),
                    (route) => false,
              );
            },
            child: Text("Logout", style: TextStyle(color: lightRed)),
          ),
        ],
      ),
    );
  }

  // --- REDESIGNED DRAWER ---
  Widget _buildDrawer() {
    return Drawer(
      backgroundColor: bgBlack,
      child: Column(
        children: [
          Container(
            width: double.infinity,
            padding: const EdgeInsets.only(top: 50, bottom: 20, left: 20, right: 20),
            decoration: BoxDecoration(
              image: const DecorationImage(
                image: AssetImage('assets/images/neken.jpg'),
                fit: BoxFit.cover,
                colorFilter: ColorFilter.mode(Colors.black54, BlendMode.darken),
              ),
              border: Border(bottom: BorderSide(color: mainRed, width: 2)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  padding: const EdgeInsets.all(2),
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    border: Border.all(color: Colors.white, width: 2),
                  ),
                  child: const CircleAvatar(
                    radius: 35,
                    backgroundImage: AssetImage('assets/images/icon.jpg'),
                  ),
                ),
                const SizedBox(height: 15),
                Text(
                  "Hallo, $username",
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    shadows: [Shadow(color: Colors.black, blurRadius: 5)],
                  ),
                ),
                const SizedBox(height: 5),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: mainRed,
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: Text(
                    role.toUpperCase(),
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 10,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 1,
                    ),
                  ),
                ),
              ],
            ),
          ),
          
          Expanded(
            child: Container(
              color: bgBlack,
              child: ListView(
                padding: const EdgeInsets.symmetric(vertical: 20),
                children: [
                  if (role == "owner")
                    _buildDrawerItem(Icons.admin_panel_settings, 'Admin Page', _navigateToAdminPage),
                  if (role == "reseller")
                    _buildDrawerItem(Icons.add_shopping_cart, 'Seller Page', _navigateToSellerPage),
                  
                  _buildDrawerItem(Icons.lock_clock, 'Change Password', () {
                    Navigator.pop(context);
                    Navigator.push(context, MaterialPageRoute(builder: (_) => ChangePasswordPage(username: username, sessionKey: sessionKey)));
                  }),
                  _buildDrawerItem(Icons.person, 'NIK Check', () {
                    Navigator.pop(context);
                    Navigator.push(context, MaterialPageRoute(builder: (_) => NikCheckerPage()));
                  }),
                ],
              ),
            ),
          ),
          
          Padding(
            padding: const EdgeInsets.all(20),
            child: Text(
              "HOXTEN CLOUD v3.0",
              style: TextStyle(color: Colors.grey.shade800, fontSize: 10),
            ),
          )
        ],
      ),
    );
  }

  Widget _buildDrawerItem(IconData icon, String title, VoidCallback onTap) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: const Color(0xFF111111),
        borderRadius: BorderRadius.circular(8),
        border: Border(left: BorderSide(color: mainRed, width: 3)),
      ),
      child: ListTile(
        leading: Icon(icon, color: lightRed),
        title: Text(title, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w500)),
        trailing: Icon(Icons.arrow_forward_ios, color: Colors.grey.shade800, size: 14),
        onTap: onTap,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      ),
    );
  }

  @override
  void dispose() {
    channel.sink.close(status.goingAway);
    _controller.dispose();
    super.dispose();
  }
}

class NewsMedia extends StatelessWidget {
  final String url;
  const NewsMedia({super.key, required this.url});

  @override
  Widget build(BuildContext context) {
    return Image.network(
      url, 
      fit: BoxFit.cover,
      errorBuilder: (context, error, stackTrace) => Container(
        color: Colors.black,
        child: const Center(child: Icon(Icons.broken_image, color: Colors.grey)),
      ),
    );
  }
}
