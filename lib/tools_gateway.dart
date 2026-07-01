import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'manage_server.dart';
import 'wifi_internal.dart';
import 'wifi_external.dart';
import 'ddos_panel.dart';
import 'nik_check.dart';
import 'tiktok_page.dart';
import 'instagram_page.dart';
import 'qr_gen.dart';
import 'domain_page.dart';
import 'spam_ngl.dart';

class ToolsPage extends StatefulWidget {
  final String sessionKey;
  final String userRole;
  final List<Map<String, dynamic>> listDoos;

  const ToolsPage({
    super.key,
    required this.sessionKey,
    required this.userRole,
    required this.listDoos,
  });

  @override
  State<ToolsPage> createState() => _ToolsPageState();
}

class _ToolsPageState extends State<ToolsPage> with TickerProviderStateMixin {
  late AnimationController _cardController;
  late Animation<double> _cardAnimation;

  final Color primaryDark = const Color(0xFF000000);
  final Color primaryRed = const Color(0xFFB71C1C);
  final Color accentRed = const Color(0xFFFF1744);
  final Color primaryWhite = Colors.white;
  final Color cardDark = const Color(0xFF1A1A1A);
  final Color borderGrey = const Color(0xFF2A2A2A);

  @override
  void initState() {
    super.initState();
    _cardController = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );

    _cardAnimation = Tween<double>(begin: 0, end: 1).animate(
      CurvedAnimation(
        parent: _cardController,
        curve: Curves.easeOutCubic,
      ),
    );

    _cardController.forward();
  }

  @override
  void dispose() {
    _cardController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: primaryDark,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header Section
              _buildHeader(),
              
              const SizedBox(height: 30),

              // Digital Tools Section
              Expanded(
                child: SingleChildScrollView(
                  child: Column(
                    children: [
                      _buildDigitalToolsSection(),
                      
                      const SizedBox(height: 30),
                      
                      // Tools Grid
                      _buildToolsGrid(),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Row(
      children: [
        Icon(
          Icons.apps,
          color: primaryWhite,
          size: 28,
        ),
        const Spacer(),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
          decoration: BoxDecoration(
            color: primaryRed.withOpacity(0.2),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: primaryRed.withOpacity(0.5)),
          ),
          child: Row(
            children: [
              Icon(
                Icons.person,
                color: accentRed,
                size: 16,
              ),
              const SizedBox(width: 6),
              Text(
                widget.userRole.toUpperCase(),
                style: TextStyle(
                  color: accentRed,
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildDigitalToolsSection() {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: cardDark,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: borderGrey, width: 1),
      ),
      child: Row(
        children: [
          Container(
            width: 50,
            height: 50,
            decoration: BoxDecoration(
              color: primaryDark,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(
              Icons.grid_view,
              color: primaryWhite,
              size: 24,
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  "Digital Tools",
                  style: TextStyle(
                    color: primaryWhite,
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 1,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  "Select a tool to begin",
                  style: TextStyle(
                    color: Colors.grey.shade500,
                    fontSize: 14,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildToolsGrid() {
    final List<Map<String, dynamic>> tools = [
      {
        "icon": Icons.chat_bubble_outline,
        "title": "Chat AI",
        "subtitle": "AI-powered conversation assistant",
        "onTap": () => _showComingSoon(context),
      },
      {
        "icon": Icons.badge_outlined,
        "title": "NIK Check",
        "subtitle": "Validate Indonesian identity numbers",
        "onTap": () => Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => const NikCheckerPage()),
        ),
      },
      {
        "icon": Icons.phone_outlined,
        "title": "Phone Lookup",
        "subtitle": "Find information about phone numbers",
        "onTap": () => _showComingSoon(context),
      },
      {
        "icon": Icons.public,
        "title": "Subdomain Finder",
        "subtitle": "Discover subdomains of any domain",
        "onTap": () => Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => const DomainOsintPage()),
        ),
      },
      {
        "icon": Icons.movie_outlined,
        "title": "Anime",
        "subtitle": "Tempat Nya Para Wibu Marathon Anime",
        "onTap": () => _showComingSoon(context),
      },
      {
        "icon": Icons.group_outlined,
        "title": "Group Chat",
        "subtitle": "Connect with community",
        "onTap": () => _showComingSoon(context),
      },
      {
        "icon": Icons.flash_on,
        "title": "DDoS Tools",
        "subtitle": "Network attack tools",
        "onTap": () => _showDDoSTools(context),
      },
      {
        "icon": Icons.wifi,
        "title": "Network Tools",
        "subtitle": "WiFi & Network utilities",
        "onTap": () => _showNetworkTools(context),
      },
      {
        "icon": Icons.download,
        "title": "Media Downloader",
        "subtitle": "Download from social media",
        "onTap": () => _showDownloaderTools(context),
      },
      {
        "icon": Icons.qr_code,
        "title": "QR Generator",
        "subtitle": "Create QR codes",
        "onTap": () => Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => const QrGeneratorPage()),
        ),
      },
    ];

    return AnimatedBuilder(
      animation: _cardAnimation,
      builder: (context, child) {
        return Opacity(
          opacity: _cardAnimation.value,
          child: Column(
            children: List.generate(
              tools.length,
              (index) => _buildToolCard(tools[index], index),
            ),
          ),
        );
      },
    );
  }

  Widget _buildToolCard(Map<String, dynamic> tool, int index) {
    return TweenAnimationBuilder(
      tween: Tween<double>(begin: 0, end: 1),
      duration: Duration(milliseconds: 400 + (index * 50)),
      curve: Curves.easeOutCubic,
      builder: (context, double value, child) {
        return Transform.translate(
          offset: Offset((1 - value) * 50, 0),
          child: Opacity(
            opacity: value,
            child: Container(
              margin: const EdgeInsets.only(bottom: 16),
              decoration: BoxDecoration(
                color: cardDark,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: borderGrey, width: 1),
              ),
              child: Material(
                color: Colors.transparent,
                child: InkWell(
                  onTap: () {
                    HapticFeedback.lightImpact();
                    tool["onTap"]();
                  },
                  borderRadius: BorderRadius.circular(16),
                  child: Padding(
                    padding: const EdgeInsets.all(20),
                    child: Row(
                      children: [
                        Container(
                          width: 50,
                          height: 50,
                          decoration: BoxDecoration(
                            color: primaryDark,
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(
                              color: primaryRed.withOpacity(0.3),
                              width: 1,
                            ),
                          ),
                          child: Icon(
                            tool["icon"],
                            color: primaryWhite,
                            size: 24,
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                tool["title"],
                                style: TextStyle(
                                  color: primaryWhite,
                                  fontSize: 16,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                tool["subtitle"],
                                style: TextStyle(
                                  color: Colors.grey.shade500,
                                  fontSize: 13,
                                ),
                              ),
                            ],
                          ),
                        ),
                        Icon(
                          Icons.chevron_right,
                          color: Colors.grey.shade600,
                          size: 24,
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  void _showDDoSTools(BuildContext context) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (context) => _buildModalSheet(
        context,
        "DDoS Tools",
        Icons.flash_on,
        [
          _buildModalOption(
            icon: Icons.flash_on,
            label: "Attack Panel",
            onTap: () {
              Navigator.pop(context);
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => AttackPanel(
                    sessionKey: widget.sessionKey,
                    listDoos: widget.listDoos,
                  ),
                ),
              );
            },
          ),
          _buildModalOption(
            icon: Icons.dns,
            label: "Manage Server",
            onTap: () {
              Navigator.pop(context);
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => ManageServerPage(keyToken: widget.sessionKey),
                ),
              );
            },
          ),
        ],
      ),
    );
  }

  void _showNetworkTools(BuildContext context) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (context) => _buildModalSheet(
        context,
        "Network Tools",
        Icons.wifi,
        [
          _buildModalOption(
            icon: Icons.newspaper_outlined,
            label: "Spam NGL",
            onTap: () {
              Navigator.pop(context);
              Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => NglPage()),
              );
            },
          ),
          _buildModalOption(
            icon: Icons.wifi_off,
            label: "WiFi Killer (Internal)",
            onTap: () {
              Navigator.pop(context);
              Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => WifiKillerPage()),
              );
            },
          ),
          if (widget.userRole == "vip" || widget.userRole == "owner")
            _buildModalOption(
              icon: Icons.router,
              label: "WiFi Killer (External)",
              onTap: () {
                Navigator.pop(context);
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => WifiInternalPage(sessionKey: widget.sessionKey),
                  ),
                );
              },
            ),
        ],
      ),
    );
  }

  void _showDownloaderTools(BuildContext context) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (context) => _buildModalSheet(
        context,
        "Media Downloader",
        Icons.download,
        [
          _buildModalOption(
            icon: Icons.video_library,
            label: "TikTok Downloader",
            onTap: () {
              Navigator.pop(context);
              Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const TiktokDownloaderPage()),
              );
            },
          ),
          _buildModalOption(
            icon: Icons.camera_alt,
            label: "Instagram Downloader",
            onTap: () {
              Navigator.pop(context);
              Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const InstagramDownloaderPage()),
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _buildModalSheet(
    BuildContext context,
    String title,
    IconData icon,
    List<Widget> options,
  ) {
    return Container(
      height: MediaQuery.of(context).size.height * 0.5,
      decoration: BoxDecoration(
        color: cardDark,
        borderRadius: const BorderRadius.only(
          topLeft: Radius.circular(30),
          topRight: Radius.circular(30),
        ),
        border: Border.all(color: borderGrey),
      ),
      child: Column(
        children: [
          // Drag handle
          Container(
            margin: const EdgeInsets.only(top: 12),
            width: 40,
            height: 4,
            decoration: BoxDecoration(
              color: Colors.grey.shade700,
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          
          // Header
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              border: Border(
                bottom: BorderSide(color: borderGrey),
              ),
            ),
            child: Row(
              children: [
                Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    color: primaryRed.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Icon(icon, color: accentRed, size: 22),
                ),
                const SizedBox(width: 16),
                Text(
                  title,
                  style: TextStyle(
                    color: primaryWhite,
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ),

          // Options
          Expanded(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: ListView(
                children: options,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildModalOption({
    required IconData icon,
    required String label,
    required VoidCallback onTap,
  }) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: primaryDark,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: borderGrey),
      ),
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
        leading: Container(
          width: 40,
          height: 40,
          decoration: BoxDecoration(
            color: primaryRed.withOpacity(0.2),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Icon(icon, color: accentRed, size: 20),
        ),
        title: Text(
          label,
          style: TextStyle(
            color: primaryWhite,
            fontWeight: FontWeight.w500,
          ),
        ),
        trailing: Icon(
          Icons.arrow_forward_ios,
          color: Colors.grey.shade600,
          size: 16,
        ),
        onTap: () {
          HapticFeedback.lightImpact();
          onTap();
        },
      ),
    );
  }

  void _showComingSoon(BuildContext context) {
    HapticFeedback.lightImpact();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            Icon(Icons.info_outline, color: primaryWhite),
            const SizedBox(width: 12),
            Text(
              'Feature Coming Soon!',
              style: TextStyle(
                fontWeight: FontWeight.w600,
                color: primaryWhite,
              ),
            ),
          ],
        ),
        backgroundColor: primaryRed,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
        margin: const EdgeInsets.all(16),
        duration: const Duration(seconds: 2),
      ),
    );
  }
}