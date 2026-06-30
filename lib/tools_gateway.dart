import 'dart:ui';
import 'package:flutter/material.dart';
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
  String? _expandedCategory;

  // Tema Merah Gelap
  static const Color primaryDark = Color(0xFF050505);
  static const Color primaryRed = Color(0xFFC62828);
  static const Color accentRed = Color(0xFFFF5252);
  static const Color primaryWhite = Colors.white;
  static const Color cardDark = Color(0xFF050505);

  final Map<String, AnimationController> _controllers = {};
  final Map<String, Animation<double>> _animations = {};

  final List<_CategoryItem> _categories = [];

  @override
  void initState() {
    super.initState();
    _initCategories();
    for (final cat in _categories) {
      final controller = AnimationController(
        vsync: this,
        duration: const Duration(milliseconds: 300),
      );
      _controllers[cat.key] = controller;
      _animations[cat.key] = CurvedAnimation(
        parent: controller,
        curve: Curves.easeInOut,
      );
    }
  }

  void _initCategories() {
    _categories.addAll([
      _CategoryItem(
        key: 'ddos',
        icon: Icons.flash_on,
        title: 'NoMercy DDoS Tools',
        subtitle: 'Attack & Server',
        children: [],
      ),
      _CategoryItem(
        key: 'network',
        icon: Icons.wifi,
        title: 'NoMercy Network',
        subtitle: 'WiFi & Spam',
        children: [],
      ),
      _CategoryItem(
        key: 'osint',
        icon: Icons.search,
        title: 'NoMercy OSINT',
        subtitle: 'Investigation',
        children: [],
      ),
      _CategoryItem(
        key: 'downloader',
        icon: Icons.download,
        title: 'NoMercy Downloader',
        subtitle: 'Social Media',
        children: [],
      ),
      _CategoryItem(
        key: 'utilities',
        icon: Icons.build,
        title: 'NoMercy Utilities',
        subtitle: 'Extra Tools',
        children: [],
      ),
      _CategoryItem(
        key: 'watch',
        icon: Icons.video_library,
        title: 'NoMercy Watch',
        subtitle: 'Entertainment & Media',
        children: [],
      ),
      _CategoryItem(
        key: 'quick',
        icon: Icons.rocket_launch,
        title: 'NoMercy Quick Access',
        subtitle: 'Favorites',
        children: [],
      ),
    ]);
  }

  @override
  void dispose() {
    for (final c in _controllers.values) {
      c.dispose();
    }
    super.dispose();
  }

  void _toggleCategory(String key) {
    setState(() {
      if (_expandedCategory == key) {
        _controllers[key]?.reverse();
        _expandedCategory = null;
      } else {
        if (_expandedCategory != null) {
          _controllers[_expandedCategory!]?.reverse();
        }
        _expandedCategory = key;
        _controllers[key]?.forward();
      }
    });
  }

  List<_ToolOption> _getChildren(String key) {
    switch (key) {
      case 'ddos':
        return [
          _ToolOption(
            icon: Icons.flash_on,
            label: 'Attack Panel',
            onTap: () => Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) => AttackPanel(
                  sessionKey: widget.sessionKey,
                  listDoos: widget.listDoos,
                ),
              ),
            ),
          ),
          _ToolOption(
            icon: Icons.dns,
            label: 'Manage Server',
            onTap: () => Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) => ManageServerPage(keyToken: widget.sessionKey),
              ),
            ),
          ),
        ];
      case 'network':
        return [
          _ToolOption(
            icon: Icons.newspaper_outlined,
            label: 'Spam NGL',
            onTap: () => Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => NglPage()),
            ),
          ),
          _ToolOption(
            icon: Icons.wifi_off,
            label: 'WiFi Killer (Internal)',
            onTap: () => Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => WifiKillerPage()),
            ),
          ),
          if (widget.userRole == 'vip' || widget.userRole == 'owner')
            _ToolOption(
              icon: Icons.router,
              label: 'WiFi Killer (External)',
              onTap: () => Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => WifiInternalPage(sessionKey: widget.sessionKey),
                ),
              ),
            ),
        ];
      case 'osint':
        return [
          _ToolOption(
            icon: Icons.badge,
            label: 'NIK Detail',
            onTap: () => Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const NikCheckerPage()),
            ),
          ),
          _ToolOption(
            icon: Icons.domain,
            label: 'Domain OSINT',
            onTap: () => Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const DomainOsintPage()),
            ),
          ),
          _ToolOption(
            icon: Icons.person_search,
            label: 'Phone Lookup',
            onTap: () => _showComingSoon(),
          ),
          _ToolOption(
            icon: Icons.email,
            label: 'Email OSINT',
            onTap: () => _showComingSoon(),
          ),
        ];
      case 'downloader':
        return [
          _ToolOption(
            icon: Icons.video_library,
            label: 'TikTok Downloader',
            onTap: () => Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const TiktokDownloaderPage()),
            ),
          ),
          _ToolOption(
            icon: Icons.camera_alt,
            label: 'Instagram Downloader',
            onTap: () => Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const InstagramDownloaderPage()),
            ),
          ),
        ];
      case 'utilities':
        return [
          _ToolOption(
            icon: Icons.qr_code,
            label: 'QR Generator',
            onTap: () => Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const QrGeneratorPage()),
            ),
          ),
          _ToolOption(
            icon: Icons.security,
            label: 'IP Scanner',
            onTap: () => _showComingSoon(),
          ),
          _ToolOption(
            icon: Icons.network_check,
            label: 'Port Scanner',
            onTap: () => _showComingSoon(),
          ),
        ];
      case 'watch':
        return [
          _ToolOption(
            icon: Icons.live_tv,
            label: 'Live Streams',
            onTap: () => _showComingSoon(),
          ),
          _ToolOption(
            icon: Icons.movie,
            label: 'Media Library',
            onTap: () => _showComingSoon(),
          ),
        ];
      case 'quick':
        return [
          _ToolOption(
            icon: Icons.star,
            label: 'Favorites',
            onTap: () => _showComingSoon(),
          ),
        ];
      default:
        return [];
    }
  }

  void _showComingSoon() {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            const Icon(Icons.hourglass_top, color: primaryWhite),
            const SizedBox(width: 8),
            const Text(
              'Feature Coming Soon!',
              style: TextStyle(
                fontFamily: 'Orbitron',
                fontWeight: FontWeight.bold,
                color: primaryWhite,
              ),
            ),
          ],
        ),
        backgroundColor: primaryRed,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        duration: const Duration(seconds: 2),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: primaryDark,
      body: SafeArea(
        child: Column(
          children: [
            // ---- HEADER ----
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
              decoration: BoxDecoration(
                color: cardDark,
                border: Border(
                  bottom: BorderSide(color: primaryRed.withOpacity(0.3), width: 1),
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'TOOLS DASHBOARD',
                    style: TextStyle(
                      color: accentRed,
                      fontSize: 22,
                      fontFamily: 'Orbitron',
                      fontWeight: FontWeight.bold,
                      letterSpacing: 2,
                      shadows: [
                        Shadow(color: accentRed.withOpacity(0.8), blurRadius: 12),
                      ],
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Advanced Security & OSINT Tools',
                    style: TextStyle(
                      color: primaryWhite.withOpacity(0.5),
                      fontSize: 13,
                      fontFamily: 'ShareTechMono',
                      letterSpacing: 0.5,
                    ),
                  ),
                ],
              ),
            ),

            // ---- LIST ----
            Expanded(
              child: ListView.builder(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                itemCount: _categories.length,
                itemBuilder: (context, index) {
                  final cat = _categories[index];
                  final isExpanded = _expandedCategory == cat.key;
                  final children = _getChildren(cat.key);

                  return Padding(
                    padding: const EdgeInsets.only(bottom: 10),
                    child: Column(
                      children: [
                        // ---- CATEGORY BUTTON ----
                        GestureDetector(
                          onTap: () => _toggleCategory(cat.key),
                          child: AnimatedContainer(
                            duration: const Duration(milliseconds: 200),
                            decoration: BoxDecoration(
                              color: isExpanded
                                  ? primaryRed.withOpacity(0.15)
                                  : cardDark,
                              borderRadius: BorderRadius.only(
                                topLeft: const Radius.circular(14),
                                topRight: const Radius.circular(14),
                                bottomLeft: Radius.circular(isExpanded ? 0 : 14),
                                bottomRight: Radius.circular(isExpanded ? 0 : 14),
                              ),
                              border: Border.all(
                                color: isExpanded
                                    ? primaryRed.withOpacity(0.7)
                                    : primaryRed.withOpacity(0.25),
                                width: 1,
                              ),
                              boxShadow: isExpanded
                                  ? [
                                      BoxShadow(
                                        color: primaryRed.withOpacity(0.15),
                                        blurRadius: 10,
                                        offset: const Offset(0, 2),
                                      )
                                    ]
                                  : [],
                            ),
                            padding: const EdgeInsets.symmetric(
                              horizontal: 16,
                              vertical: 14,
                            ),
                            child: Row(
                              children: [
                                Container(
                                  width: 44,
                                  height: 44,
                                  decoration: BoxDecoration(
                                    color: primaryRed.withOpacity(0.15),
                                    borderRadius: BorderRadius.circular(10),
                                    border: Border.all(
                                      color: primaryRed.withOpacity(0.4),
                                    ),
                                  ),
                                  child: Icon(
                                    cat.icon,
                                    color: accentRed,
                                    size: 22,
                                  ),
                                ),
                                const SizedBox(width: 14),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        cat.title,
                                        style: TextStyle(
                                          color: isExpanded ? accentRed : primaryWhite,
                                          fontSize: 15,
                                          fontFamily: 'Orbitron',
                                          fontWeight: FontWeight.bold,
                                          shadows: isExpanded
                                              ? [
                                                  Shadow(
                                                    color: accentRed.withOpacity(0.7),
                                                    blurRadius: 8,
                                                  )
                                                ]
                                              : [],
                                        ),
                                      ),
                                      const SizedBox(height: 2),
                                      Text(
                                        cat.subtitle,
                                        style: TextStyle(
                                          color: primaryWhite.withOpacity(0.45),
                                          fontSize: 12,
                                          fontFamily: 'ShareTechMono',
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                AnimatedRotation(
                                  turns: isExpanded ? 0.5 : 0,
                                  duration: const Duration(milliseconds: 300),
                                  child: Icon(
                                    Icons.keyboard_arrow_down,
                                    color: isExpanded
                                        ? accentRed
                                        : primaryWhite.withOpacity(0.4),
                                    size: 22,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),

                        // ---- EXPANDED SUBMENU ----
                        SizeTransition(
                          sizeFactor: _animations[cat.key]!,
                          axisAlignment: -1,
                          child: Container(
                            decoration: BoxDecoration(
                              color: const Color(0xFF1A0A0A),
                              borderRadius: const BorderRadius.only(
                                bottomLeft: Radius.circular(14),
                                bottomRight: Radius.circular(14),
                              ),
                              border: Border(
                                left: BorderSide(
                                    color: primaryRed.withOpacity(0.5), width: 1),
                                right: BorderSide(
                                    color: primaryRed.withOpacity(0.5), width: 1),
                                bottom: BorderSide(
                                    color: primaryRed.withOpacity(0.5), width: 1),
                              ),
                            ),
                            child: Column(
                              children: children.map((option) {
                                final isLast = option == children.last;
                                return Column(
                                  children: [
                                    if (children.indexOf(option) == 0)
                                      Divider(
                                        height: 1,
                                        color: primaryRed.withOpacity(0.2),
                                      ),
                                    InkWell(
                                      onTap: option.onTap,
                                      splashColor: primaryRed.withOpacity(0.1),
                                      highlightColor: primaryRed.withOpacity(0.05),
                                      child: Padding(
                                        padding: const EdgeInsets.symmetric(
                                          horizontal: 16,
                                          vertical: 13,
                                        ),
                                        child: Row(
                                          children: [
                                            const SizedBox(width: 6),
                                            Container(
                                              width: 34,
                                              height: 34,
                                              decoration: BoxDecoration(
                                                color: primaryRed.withOpacity(0.1),
                                                borderRadius:
                                                    BorderRadius.circular(8),
                                                border: Border.all(
                                                  color:
                                                      primaryRed.withOpacity(0.25),
                                                ),
                                              ),
                                              child: Icon(
                                                option.icon,
                                                color: accentRed,
                                                size: 17,
                                              ),
                                            ),
                                            const SizedBox(width: 14),
                                            Expanded(
                                              child: Text(
                                                option.label,
                                                style: const TextStyle(
                                                  color: primaryWhite,
                                                  fontSize: 13,
                                                  fontFamily: 'Orbitron',
                                                  fontWeight: FontWeight.w500,
                                                ),
                                              ),
                                            ),
                                            Icon(
                                              Icons.arrow_forward_ios,
                                              color: accentRed.withOpacity(0.6),
                                              size: 13,
                                            ),
                                          ],
                                        ),
                                      ),
                                    ),
                                    if (!isLast)
                                      Divider(
                                        height: 1,
                                        indent: 70,
                                        color: primaryRed.withOpacity(0.1),
                                      ),
                                  ],
                                );
                              }).toList(),
                            ),
                          ),
                        ),
                      ],
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ---- DATA CLASSES ----

class _CategoryItem {
  final String key;
  final IconData icon;
  final String title;
  final String subtitle;
  final List<_ToolOption> children;

  _CategoryItem({
    required this.key,
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.children,
  });
}

class _ToolOption {
  final IconData icon;
  final String label;
  final VoidCallback onTap;

  _ToolOption({
    required this.icon,
    required this.label,
    required this.onTap,
  });
}