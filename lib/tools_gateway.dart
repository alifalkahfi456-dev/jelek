import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

// ─── Import lokal ──────────────────────────────
import 'tiktok_page.dart';
import 'instagram_page.dart';
import 'domain_page.dart';
import 'spam_ngl.dart';
import 'game_hub.dart';
import 'dracin_app.dart';
import 'home_anime_page.dart';
import 'comic_page.dart';
import 'iqc.dart';
import 'kalkulator.dart';
import 'yts.dart';      // YouTube
import 'meme.dart';     // MEME

// ─── PALETTE ────────────────────────────────────
const Color _tgBg     = Color(0xFF0b1120);
const Color _tgCard   = Color(0xFF111827);
const Color _tgBorder = Color(0xFF1e2d45);
const Color _tgBlue   = Color(0xFF2563eb);
const Color _tgCyan   = Color(0xFF22d3ee);
const Color _tgGreen  = Color(0xFF22c55e);
const Color _tgAmber  = Color(0xFFf59e0b);
const Color _tgRed    = Color(0xFFef4444);
const Color _tgPurple = Color(0xFF7c3aed);
const Color _tgWhite  = Colors.white;
const Color _tgSub    = Color(0xFF94a3b8);

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

class _ToolsPageState extends State<ToolsPage>
    with SingleTickerProviderStateMixin {
  late AnimationController _hexCtrl;
  late Animation<double>   _hexAnim;

  @override
  void initState() {
    super.initState();
    _hexCtrl = AnimationController(
        vsync: this, duration: const Duration(seconds: 4))
      ..repeat(reverse: true);
    _hexAnim =
        CurvedAnimation(parent: _hexCtrl, curve: Curves.easeInOut);
  }

  @override
  void dispose() {
    _hexCtrl.dispose();
    super.dispose();
  }

  void _navTo(Widget page) => Navigator.push(
      context, MaterialPageRoute(builder: (_) => page));

  void _comingSoon() {
    HapticFeedback.lightImpact();
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: const Row(children: [
        Icon(Icons.hourglass_top_rounded,
            color: _tgWhite, size: 16),
        SizedBox(width: 10),
        Text('Feature Coming Soon!',
            style: TextStyle(
                color: _tgWhite, fontWeight: FontWeight.bold)),
      ]),
      backgroundColor: _tgBlue,
      behavior: SnackBarBehavior.floating,
      shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12)),
      margin: const EdgeInsets.all(16),
    ));
  }

  void _openGameHub() {
    try {
      HapticFeedback.mediumImpact();
      _navTo(const GameHubApp());
    } catch (e) {
      _showError('Game Hub Error: $e');
    }
  }

  void _openDracin() {
    try {
      HapticFeedback.mediumImpact();
      _navTo(const DracinApp());
    } catch (e) {
      _showError('Dracin Error: $e');
    }
  }

  void _openHomeAnime() {
    try {
      HapticFeedback.mediumImpact();
      _navTo(const HomeAnimePage());
    } catch (e) {
      _showError('Home Anime Error: $e');
    }
  }

  void _openComic() {
    try {
      HapticFeedback.mediumImpact();
      _navTo(const ComicPage());
    } catch (e) {
      _showError('Comic Error: $e');
    }
  }

  void _openIqc() {
    try {
      HapticFeedback.mediumImpact();
      _navTo(const MyApp());
    } catch (e) {
      _showError('IQC Error: $e');
    }
  }

  void _openCalculator() {
    try {
      HapticFeedback.mediumImpact();
      _navTo(const KalkulatorApp());
    } catch (e) {
      _showError('Calculator Error: $e');
    }
  }

  void _showError(String msg) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(msg, style: const TextStyle(color: _tgWhite)),
        backgroundColor: _tgRed,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        margin: const EdgeInsets.all(16),
      ),
    );
  }

  // ─── Category definitions (GABUNGAN Game Hub + Nonton) ──
  List<Map<String, dynamic>> get _categories => [
        {
          'title':    '🎮 Hiburan',
          'subtitle': 'Games & Streaming',
          'icon':     Icons.gamepad_rounded,
          'color':    _tgPurple,
          'items': [
            _mkItem('GAME', Icons.gamepad_rounded, _openGameHub),
            _mkItem('Arcade Games', Icons.emoji_events_rounded, _comingSoon),
            _mkItem('DRACIN', Icons.flash_on_rounded, _openDracin),
            _mkItem('ANIME', Icons.home_rounded, _openHomeAnime),
            _mkItem('KOMIK', Icons.menu_book_rounded, _openComic),
            _mkItem('MEME', Icons.insert_emoticon_rounded,
                () => _navTo(const MemeGeneratorPage())),
            _mkItem('Favorites', Icons.favorite_rounded, _comingSoon),
          ],
        },
        {
          'title':    'Network Tools',
          'subtitle': 'WiFi & Spamming',
          'icon':     Icons.wifi_rounded,
          'color':    _tgCyan,
          'items': [
            _mkItem('SPAM NGL', Icons.newspaper_rounded,
                () => _navTo(NglPage())),
          ],
        },
        {
          'title':    'OSINT Tools',
          'subtitle': 'Information Gathering',
          'icon':     Icons.search_rounded,
          'color':    _tgGreen,
          'items': [
            _mkItem('Domain Check', Icons.domain_rounded,
                () => _navTo(const DomainOsintPage())),
            _mkItem('Phone Lookup', Icons.phone_iphone_rounded, _comingSoon),
          ],
        },
        {
          'title':    'Downloader',
          'subtitle': 'Social Media',
          'icon':     Icons.download_rounded,
          'color':    _tgAmber,
          'items': [
            _mkItem('TIKTOK', Icons.tiktok,
                () => _navTo(const TiktokDownloaderPage())),
            _mkItem('INSTAGRAM', Icons.camera_alt_rounded,
                () => _navTo(const InstagramDownloaderPage())),
            _mkItem('YOUTUBE', Icons.youtube_searched_for,
                () => _navTo(const YouTubeS())),
          ],
        },
        {
          'title':    'Utilities',
          'subtitle': 'Helper Tools',
          'icon':     Icons.build_rounded,
          'color':    _tgPurple,
          'items': [
            _mkItem('IP Scanner', Icons.lan_rounded, _comingSoon),
            _mkItem('IQC', Icons.phone_iphone_rounded, _openIqc),
            _mkItem('Calculator', Icons.calculate_rounded, _openCalculator),
          ],
        },
      ];

  Map<String, dynamic> _mkItem(
          String label, IconData icon, VoidCallback onTap) =>
      {'label': label, 'icon': icon, 'onTap': onTap};

  // ─── Flatten all items with color ────────────
  List<Map<String, dynamic>> get _allItems {
    List<Map<String, dynamic>> result = [];
    for (var cat in _categories) {
      final color = cat['color'] as Color;
      for (var item in cat['items'] as List<Map<String, dynamic>>) {
        result.add({
          ...item,
          'color': color,
        });
      }
    }
    return result;
  }

  // ─── Build grid item ──────────────────────────
  Widget _buildGridItem(Map<String, dynamic> item) {
    final label = item['label'] as String;
    final icon = item['icon'] as IconData;
    final onTap = item['onTap'] as VoidCallback;
    final color = item['color'] as Color;

    return GestureDetector(
      onTap: onTap,
      child: Container(
        decoration: BoxDecoration(
          color: _tgCard,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: color.withOpacity(0.3), width: 1),
          boxShadow: [
            BoxShadow(
              color: color.withOpacity(0.1),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 56,
              height: 56,
              decoration: BoxDecoration(
                color: color.withOpacity(0.15),
                shape: BoxShape.circle,
              ),
              child: Icon(icon, color: color, size: 32),
            ),
            const SizedBox(height: 10),
            Text(
              label,
              textAlign: TextAlign.center,
              style: const TextStyle(
                  color: _tgWhite,
                  fontSize: 14,
                  fontWeight: FontWeight.w600),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ),
      ),
    );
  }

  // ─────────────────────────────────────────────
  @override
  Widget build(BuildContext context) {
    final totalModules = _allItems.length;

    return Scaffold(
      backgroundColor: _tgBg,
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              Color(0xFF0a1628),
              Color(0xFF0b1120),
              Color(0xFF0f1a2e),
            ],
          ),
        ),
        child: SafeArea(
          child: ListView(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
            physics: const BouncingScrollPhysics(),
            children: [
              // ─── HEADER ──────────────────────────────
              const Text(
                'CHAN XITER TOOLS',
                style: TextStyle(
                  color: _tgWhite,
                  fontSize: 32,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 1.2,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                'Pusat akses berbagai menu aplikasi CHAN XITER untuk kebutuhan harian Anda.',
                style: TextStyle(
                  color: _tgSub,
                  fontSize: 15,
                  height: 1.4,
                ),
              ),
              const SizedBox(height: 20),

              // ─── TOOLS GATEWAY CARD ─────────────────
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: _tgCard.withOpacity(0.7),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: _tgBorder, width: 1),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceAround,
                  children: [
                    _buildInfoTile(Icons.person, 'ROLE', widget.userRole),
                    _buildInfoTile(Icons.apps, 'JUMLAH MENU',
                        '$totalModules TOOLS'),
                    _buildInfoTile(
                        Icons.wifi, 'SESSION', widget.sessionKey),
                  ],
                ),
              ),
              const SizedBox(height: 24),

              // ─── KATEGORI MENU ──────────────────────
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    'KATEGORI MENU',
                    style: TextStyle(
                      color: _tgWhite,
                      fontSize: 18,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 12, vertical: 4),
                    decoration: BoxDecoration(
                      color: _tgBlue.withOpacity(0.2),
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(color: _tgBlue.withOpacity(0.3)),
                    ),
                    child: Text(
                      '$totalModules Modules',
                      style: const TextStyle(
                        color: _tgWhite,
                        fontSize: 13,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),

              // ─── GRID ──────────────────────────────
              GridView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 3,
                  childAspectRatio: 0.9,
                  crossAxisSpacing: 14,
                  mainAxisSpacing: 14,
                ),
                itemCount: totalModules,
                itemBuilder: (context, index) =>
                    _buildGridItem(_allItems[index]),
              ),
              const SizedBox(height: 20),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildInfoTile(IconData icon, String label, String value) {
    return Column(
      children: [
        Icon(icon, color: _tgCyan, size: 22),
        const SizedBox(height: 4),
        Text(
          label,
          style: const TextStyle(
            color: _tgSub,
            fontSize: 11,
            fontWeight: FontWeight.w500,
          ),
        ),
        Text(
          value,
          style: const TextStyle(
            color: _tgWhite,
            fontSize: 14,
            fontWeight: FontWeight.bold,
          ),
        ),
      ],
    );
  }
}

// ═════════════════════════════════════════════════
//  HONEYCOMB PAINTER (tidak dipakai)
// ═════════════════════════════════════════════════
class _TgHexPainter extends CustomPainter {
  final double pulse;
  _TgHexPainter({required this.pulse});

  @override
  void paint(Canvas canvas, Size size) {}

  @override
  bool shouldRepaint(_TgHexPainter old) => old.pulse != pulse;
}