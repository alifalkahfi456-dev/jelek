import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:device_info_plus/device_info_plus.dart';
import 'package:web_socket_channel/web_socket_channel.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:web_socket_channel/status.dart' as status;

import 'bug_page.dart';
import 'login_page.dart';
import 'tools_gateway.dart';
import 'wifi_internal.dart';
import 'change_password_page.dart';
import 'nik_check.dart';
import 'admin_page.dart';
import 'seller_page.dart';
import 'bug_sender.dart';

class DashboardPage extends StatefulWidget {
  final String username;
  final String password;
  final String role;
  final String sessionKey;
  final String expiredDate;
  final List<Map<String, dynamic>> listBug;
  final List<Map<String, dynamic>> listDoos;

  const DashboardPage({
    super.key,
    required this.username,
    required this.password,
    required this.role,
    required this.sessionKey,
    required this.expiredDate,
    required this.listBug,
    required this.listDoos,
  });

  @override
  State<DashboardPage> createState() => _DashboardPageState();
}

class _DashboardPageState extends State<DashboardPage> {
  static const bannerUrl = 'https://pomf2.lain.la/f/o6rnuqvv.jpg';

  late WebSocketChannel channel;
  String androidId = "unknown";

  int _selectedTabIndex = 0;
  late Widget _selectedPage;

  @override
  void initState() {
    super.initState();
    _initAndroidIdAndConnect();
    _selectedPage = _buildHomePage(); // DEFAULT HOME
  }

  Future<void> _initAndroidIdAndConnect() async {
    final deviceInfo = await DeviceInfoPlugin().androidInfo;
    androidId = deviceInfo.id;
    _connectToWebSocket();
  }

  void _connectToWebSocket() {
    channel = WebSocketChannel.connect(
      Uri.parse('wss://ws-kaiieclipse.privateserverr.web.id:3000'),
    );

    channel.sink.add(jsonEncode({
      "type": "validate",
      "key": widget.sessionKey,
      "androidId": androidId,
    }));
  }

  @override
  void dispose() {
    channel.sink.close(status.goingAway);
    super.dispose();
  }

// ================= Sidebar By GPT =====================
Widget _buildDrawer() {
  return Drawer(
    backgroundColor: Colors.black.withOpacity(0.92),
    child: ListView(
      padding: EdgeInsets.zero,
      children: [
        DrawerHeader(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [
                Colors.black.withOpacity(0.95),
                Colors.black.withOpacity(0.85),
              ],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            border: Border(
              bottom: BorderSide(
                color: Colors.white.withOpacity(0.08),
              ),
            ),
          ),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(4),
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: Colors.white.withOpacity(0.15),
                    width: 2,
                  ),
                ),
                child: const CircleAvatar(
                  radius: 28,
                  backgroundColor: Colors.black,
                  backgroundImage: AssetImage('assets/images/logo.jpg'),
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Text(
                  'RavenXTeam',
                  style: TextStyle(
                    color: Colors.white.withOpacity(0.95),
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                    fontFamily: 'Orbitron',
                  ),
                ),
              ),
            ],
          ),
        ),

        // ===== ADMIN =====
        if (widget.role == "owner")
  ListTile(
    leading: Icon(
      Icons.admin_panel_settings,
      color: Colors.white.withOpacity(0.85),
    ),
    title: Text(
      'Admin Page',
      style: TextStyle(color: Colors.white.withOpacity(0.9)),
    ),
    onTap: () {
      Navigator.pop(context);
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => AdminPage(
            sessionKey: widget.sessionKey,
          ),
        ),
      );
    },
  ),

        // ===== SELLER =====
        if (widget.role == "reseller")
  ListTile(
    leading: Icon(
      Icons.add_shopping_cart,
      color: Colors.white.withOpacity(0.85),
    ),
    title: Text(
      'Seller Page',
      style: TextStyle(color: Colors.white.withOpacity(0.9)),
    ),
    onTap: () {
      Navigator.pop(context);
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => SellerPage(
            keyToken: widget.sessionKey,
          ),
        ),
      );
    },
  ),

        // ===== COMMON MENU =====
        ListTile(
          leading: Icon(
            Icons.lock_clock,
            color: Colors.white.withOpacity(0.85),
          ),
          title: Text(
            'Change Password',
            style: TextStyle(color: Colors.white.withOpacity(0.9)),
          ),
          onTap: () {
            Navigator.pop(context);
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) => ChangePasswordPage(
                  username: widget.username,
                  sessionKey: widget.sessionKey,
                ),
              ),
            );
          },
        ),

        ListTile(
          leading: Icon(
            Icons.person,
            color: Colors.white.withOpacity(0.85),
          ),
          title: Text(
            'NIK Check',
            style: TextStyle(color: Colors.white.withOpacity(0.9)),
          ),
          onTap: () {
            Navigator.pop(context);
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) => NikCheckerPage(),
              ),
            );
          },
        ),

        // ===== THANKS TO (TIDAK DIUBAH) =====
        const Divider(
          color: Colors.white24,
          thickness: 1,
          height: 24,
        ),

        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: const [
              Text(
                'Thanks To',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
              SizedBox(height: 8),
              Text('- KaiiOfficial (Creators)', style: TextStyle(color: Colors.white70)),
              Text('- PermenMD (Inspired)', style: TextStyle(color: Colors.white70)),
              Text('- Zyrex (User Ghostfin)', style: TextStyle(color: Colors.white70)),
              Text('- Zsnz (User Element)', style: TextStyle(color: Colors.white70)),
              Text('- Aii Sigma (My Bini😘)', style: TextStyle(color: Colors.white70)),
              Text('- Yayz (70%)', style: TextStyle(color: Colors.white70)),
              SizedBox(height: 16),
            ],
          ),
        ),
      ],
    ),
  );
}

  // ================== NAVBAR LOGIC (INI YANG LU MINTA) ==================
  void _onTabTapped(int index) {
    setState(() {
      _selectedTabIndex = index;

      if (index == 0) {
        _selectedPage = _buildHomePage();
      } else if (index == 1) {
        _selectedPage = BugPage(
          username: widget.username,
          password: widget.password,
          role: widget.role,
          expiredDate: widget.expiredDate,
          sessionKey: widget.sessionKey,
          listBug: widget.listBug,
          listDoos: widget.listDoos,
        );
      } else if (index == 2) {
  _selectedPage = WifiKillerPage();
      } else if (index == 3) {
  _selectedPage = ToolsPage(
    sessionKey: widget.sessionKey,
    userRole: widget.role,
    listDoos: widget.listDoos,
  );
}
    });
  }

  // ================= BUILD =================
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();

@override
Widget build(BuildContext context) {
  return Scaffold(
    key: _scaffoldKey,
    drawer: _buildDrawer(), // sidebar
    backgroundColor: const Color(0xFF0A0A0A),
      appBar: PreferredSize(
  preferredSize: const Size.fromHeight(62),
  child: AppBar(
    backgroundColor: Colors.black,
    elevation: 0,

    // ☰ MENU → BUKA SIDEBAR
    leading: IconButton(
      icon: const Icon(Icons.menu),
      onPressed: () {
        _scaffoldKey.currentState?.openDrawer();
      },
    ),

    // 🔥 PAKSA CENTER ABSOLUT
    titleSpacing: 0,
    title: Stack(
      children: [
        Center(
          child: Image.asset(
            'assets/images/rapen.jpg',
            height: 60, // 🔥 BESAR & KELIHATAN JELAS
            fit: BoxFit.contain,
          ),
        ),
      ],
    ),

    // 👤 ACCOUNT
    actions: [
      Padding(
        padding: const EdgeInsets.only(right: 12),
        child: IconButton(
          icon: const Icon(Icons.account_circle),
          onPressed: () {
            debugPrint("Account icon tapped");
          },
        ),
      ),
    ],
  ),
),

      // 🔥 BODY DIGANTI TOTAL KE _selectedPage
      body: _selectedPage,

      // ===== NAVBAR (UI TIDAK DIUBAH) =====
      bottomNavigationBar: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          
          BottomNavigationBar(
            backgroundColor: const Color(0xFF151515),
            type: BottomNavigationBarType.fixed,
            selectedItemColor: Colors.white,
            unselectedItemColor: Colors.grey,
            currentIndex: _selectedTabIndex,
            onTap: _onTabTapped,
            items: const [
              BottomNavigationBarItem(
                icon: Icon(Icons.home),
                label: 'Home',
              ),
              BottomNavigationBarItem(
                icon: Icon(Icons.chat),
                label: 'WhatsApp',
              ),
              BottomNavigationBarItem(
                icon: Icon(Icons.rocket_launch_outlined),
                label: 'Wi-Fi Killers',
              ),
              BottomNavigationBarItem(
                icon: Icon(Icons.build_circle_outlined),
                label: 'Tools',
              ),
            ],
          ),
          
        ],
      ),
    );
  }

  // ================= HOME PAGE (ASLI LU, GA DIUBAH) =================
  Widget _buildHomePage() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          _banner(),
          const SizedBox(height: 18),
          GestureDetector(
  onTap: () async {
    final uri = Uri(
      scheme: 'https',
      host: 't.me',
      path: 'RavenChannels',
    );
    await launchUrl(uri, mode: LaunchMode.externalApplication);
  },
  child: _menuTile(
    icon: Icons.telegram,
    text: "Join channel official of the Developer!",
  ),
),
          const SizedBox(height: 14),
          _iconsPhone(
  icon: Icons.phone_android,
  text: "Manage Bug Senders",
  iconColor: Colors.white,
  onTap: () {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => BugSenderPage(
          sessionKey: widget.sessionKey,
          username: widget.username,
          role: widget.role,
        ),
      ),
    );
  },
),
        ],
      ),
    );
  }

  // ================= UI (AMAN) =================
  Widget _banner() {
  return ClipRRect(
    borderRadius: BorderRadius.circular(22),
    child: Stack(
      children: [
        SizedBox(
          height: 240,
          width: double.infinity,
          child: Image.network(bannerUrl, fit: BoxFit.cover),
        ),
        Container(
          height: 240,
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [
                Colors.black.withOpacity(0.85),
                Colors.black.withOpacity(0.25),
              ],
              begin: Alignment.bottomCenter,
              end: Alignment.topCenter,
            ),
          ),
        ),

        // ===== TEKS BANNER (TAMBAHAN SAJA) =====
        Positioned(
          left: 20,
          bottom: 18,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: const [
              Text(
                "RavenXTeam",
                style: TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.w600,
                  color: Colors.white,
                  letterSpacing: 1.2,
                ),
              ),
              SizedBox(height: 4),
              Text(
                "Powered By @KaiiOfficial",
                style: TextStyle(
                  fontSize: 12,
                  color: Colors.white70,
                  letterSpacing: 1.1,
                ),
              ),
            ],
          ),
        ),
      ],
    ),
  );
}

  Widget _menuTile({
    required IconData icon,
    required String text,
    Color iconColor = Colors.white,
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFF0E0E0E),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: Colors.white12),
      ),
      child: Row(
        children: [
          Icon(icon, color: iconColor),
          const SizedBox(width: 14),
          Expanded(child: Text(text)),
          const Icon(Icons.arrow_forward_ios, size: 14, color: Colors.grey),
        ],
      ),
    );
  }
}

// ================= ICON TILE (AMAN) =================
Widget _iconsPhone({
  required IconData icon,
  required String text,
  required VoidCallback onTap,
  Color bgColor = const Color(0xFF2B123F),
  Color iconColor = Colors.white,
}) {
  return GestureDetector(
    onTap: onTap,
    child: Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFF0E0E0E),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: Colors.white12),
      ),
      child: Row(
        children: [
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: bgColor,
              borderRadius: BorderRadius.circular(14),
            ),
            child: Icon(icon, color: iconColor),
          ),
          const SizedBox(width: 16),
          Expanded(child: Text(text)),
          const Icon(Icons.arrow_forward_ios, size: 14, color: Colors.grey),
        ],
      ),
    ),
  );
}