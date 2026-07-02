import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:url_launcher/url_launcher.dart';

class TqtoPage extends StatefulWidget {
  const TqtoPage({super.key});

  @override
  State<TqtoPage> createState() => _TqtoPageState();
}

class _TqtoPageState extends State<TqtoPage> with SingleTickerProviderStateMixin {
  late AnimationController _glowController;
  late Animation<double> _glowAnimation;
  late AnimationController _floatController;

  // Premium dark grey color palette
  final Color premiumGrey = const Color(0xFF3A3F5E);
  final Color premiumGreyLight = const Color(0xFF5C617F);
  final Color premiumGreyDark = const Color(0xFF252736);
  final Color bgDark = const Color(0xFF0E0F17);
  final Color textPrimary = const Color(0xFFF5F5FA);
  final Color textSecondary = const Color(0xFF8E92A8);
  final Color glassColor = const Color(0x1AFFFFFF);

  final List<Map<String, dynamic>> tqtoList = [
  {
    'username': 'hidenxvinzz',
    'fullname': 'Vinz Ganteng',
    'role': 'DEPELONGPER',
    'bio': 'BUILD APPS',
    'icon': FontAwesomeIcons.code,
  },
  {
    'username': 'yesbrok',
    'fullname': 'TZY',
    'role': 'DEPELONGPER 02',
    'bio': 'BUILD APPS',
    'icon': FontAwesomeIcons.palette,
  },
  {
    'username': 'Xzphrznever',
    'fullname': 'Xezpers',
    'role': 'Friend',
    'bio': 'Support',
    'icon': FontAwesomeIcons.bug,
  },
  {
    'username': 'Sekerv3',
    'fullname': 'SEKER',
    'role': 'Friend',
    'bio': 'Support',
    'icon': FontAwesomeIcons.shieldHalved,
  },
  {
    'username': 'maklongemis',
    'fullname': 'Zamz',
    'role': 'Friend',
    'bio': 'Support',
    'icon': FontAwesomeIcons.mobileScreen,
  },
  {
    'username': 'RynseX',
    'fullname': 'Justin Bibir',
    'role': 'Friend',
    'bio': 'Tukang nyanyi🗿🧢',
    'icon': FontAwesomeIcons.server,
  },
  {
    'username': 'NuxckOfficial',
    'fullname': 'Nuxck',
    'role': 'Friend',
    'bio': 'Support',
    'icon': FontAwesomeIcons.bug,
  },
  {
    'username': 'Zavlo',
    'fullname': 'Zavlo',
    'role': 'Bubub Xezpers',
    'bio': 'Dia Fans jmk48',
    'icon': FontAwesomeIcons.crown,
  },
];

  @override
  void initState() {
    super.initState();
    _glowController = AnimationController(
      duration: const Duration(milliseconds: 1500),
      vsync: this,
    );
    _glowController.repeat(reverse: true);
    _glowAnimation = Tween<double>(begin: 0.2, end: 0.6).animate(_glowController);
    _floatController = AnimationController(
      duration: const Duration(milliseconds: 3000),
      vsync: this,
    );
    _floatController.repeat(reverse: true);
  }

  @override
  void dispose() {
    _glowController.dispose();
    _floatController.dispose();
    super.dispose();
  }

  Future<void> _openTelegram(String username) async {
    final Uri url = Uri.parse('https://t.me/$username');
    if (await canLaunchUrl(url)) {
      await launchUrl(url, mode: LaunchMode.externalApplication);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: bgDark,
      body: Stack(
        children: <Widget>[
          _buildBackgroundGradient(),
          _buildNeonParticles(),
          SafeArea(
            child: CustomScrollView(
              slivers: <Widget>[
                SliverAppBar(
                  floating: true,
                  backgroundColor: Colors.transparent,
                  elevation: 0,
                  centerTitle: true,
                  title: Text(
                    "CREATORS & CONTRIBUTORS",
                    style: TextStyle(
                      fontFamily: 'Orbitron',
                      fontSize: 14,
                      color: premiumGreyLight,
                      letterSpacing: 2,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  leading: IconButton(
                    icon: Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: glassColor,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: premiumGrey.withOpacity(0.3)),
                      ),
                      child: const Icon(Icons.arrow_back_rounded, color: Colors.white, size: 20),
                    ),
                    onPressed: () => Navigator.pop(context),
                  ),
                ),
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      children: <Widget>[
                        _buildHeaderCard(),
                        const SizedBox(height: 24),
                        _buildHeroBanner(),
                        const SizedBox(height: 24),
                        _buildTqtoGrid(),
                        const SizedBox(height: 32),
                        _buildFooter(),
                        const SizedBox(height: 20),
                      ],
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

  Widget _buildBackgroundGradient() {
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: const <Color>[
            Color(0xFF0B0C12),
            Color(0xFF15171F),
            Color(0xFF090A10),
          ],
        ),
      ),
    );
  }

  Widget _buildNeonParticles() {
    return IgnorePointer(
      child: AnimatedBuilder(
        animation: _glowAnimation,
        builder: (BuildContext context, Widget? child) {
          return Container(
            decoration: BoxDecoration(
              gradient: RadialGradient(
                center: Alignment.topRight,
                radius: 0.8,
                colors: <Color>[
                  premiumGrey.withOpacity(0.08 * _glowAnimation.value),
                  Colors.transparent,
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildHeaderCard() {
    return AnimatedBuilder(
      animation: _floatController,
      builder: (BuildContext context, Widget? child) {
        return Transform.translate(
          offset: Offset(0, 4 * (_floatController.value - 0.5)),
          child: Container(
            width: double.infinity,
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: <Color>[
                  glassColor,
                  glassColor.withOpacity(0.03),
                ],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(28),
              border: Border.all(
                color: premiumGrey.withOpacity(0.5),
                width: 1.5,
              ),
              boxShadow: <BoxShadow>[
                BoxShadow(
                  color: premiumGrey.withOpacity(0.2),
                  blurRadius: 30,
                  spreadRadius: 5,
                  offset: const Offset(0, 10),
                ),
              ],
            ),
            child: Column(
              children: <Widget>[
                Container(
                  width: 80,
                  height: 80,
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: <Color>[premiumGrey, premiumGreyDark],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    borderRadius: BorderRadius.circular(24),
                    boxShadow: <BoxShadow>[
                      BoxShadow(
                        color: premiumGrey.withOpacity(0.5),
                        blurRadius: 20,
                        spreadRadius: 2,
                      ),
                    ],
                  ),
                  child: const Icon(
                    FontAwesomeIcons.peopleGroup,
                    color: Colors.white,
                    size: 40,
                  ),
                ),
                const SizedBox(height: 20),
                Text(
                  "THANKS TO",
                  style: TextStyle(
                    fontFamily: 'Orbitron',
                    fontSize: 24,
                    color: premiumGreyLight,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 4,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  "ELITE TEAM BEHIND CosmicX",
                  style: TextStyle(
                    fontFamily: 'Orbitron',
                    fontSize: 11,
                    color: textSecondary,
                    letterSpacing: 2,
                  ),
                ),
                const SizedBox(height: 16),
                Container(
                  width: 60,
                  height: 2,
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: <Color>[premiumGrey, Colors.transparent],
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildHeroBanner() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: <Color>[
            premiumGrey.withOpacity(0.15),
            premiumGrey.withOpacity(0.04),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: premiumGrey.withOpacity(0.3)),
      ),
      child: Row(
        children: <Widget>[
          Container(
            width: 50,
            height: 50,
            decoration: BoxDecoration(
              color: premiumGrey.withOpacity(0.2),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: premiumGrey.withOpacity(0.4)),
            ),
            child: const Icon(FontAwesomeIcons.bullhorn, color: Colors.white, size: 24),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Text(
                  "COLLABORATIVE EFFORT",
                  style: TextStyle(
                    fontFamily: 'Orbitron',
                    fontSize: 12,
                    color: premiumGreyLight,
                    letterSpacing: 1,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  "CosmicX was built through dedication and collective expertise of these amazing individuals",
                  style: TextStyle(
                    fontSize: 12,
                    color: textSecondary,
                    height: 1.4,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTqtoGrid() {
    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        crossAxisSpacing: 14,
        mainAxisSpacing: 14,
        childAspectRatio: 0.85,
      ),
      itemCount: tqtoList.length,
      itemBuilder: (BuildContext context, int index) {
        final Map<String, dynamic> person = tqtoList[index];
        return _buildTqtoCard(person);
      },
    );
  }

  Widget _buildTqtoCard(Map<String, dynamic> person) {
    return GestureDetector(
      onTap: () {
        _openTelegram(person['username'] as String);
      },
      child: AnimatedBuilder(
        animation: _glowAnimation,
        builder: (BuildContext context, Widget? child) {
          return Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: <Color>[
                  glassColor,
                  glassColor.withOpacity(0.02),
                ],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(
                color: premiumGrey.withOpacity(0.3 + (0.15 * _glowAnimation.value)),
                width: 1.2,
              ),
            ),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: <Widget>[
                Container(
                  width: 60,
                  height: 60,
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: <Color>[
                        premiumGrey.withOpacity(0.25),
                        premiumGrey.withOpacity(0.08)
                      ],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    borderRadius: BorderRadius.circular(18),
                    border: Border.all(color: premiumGrey.withOpacity(0.5)),
                  ),
                  child: Icon(
                    person['icon'] as IconData,
                    color: premiumGreyLight,
                    size: 28,
                  ),
                ),
                const SizedBox(height: 14),
                Text(
                  "@${person['username']}",
                  style: TextStyle(
                    fontFamily: 'Orbitron',
                    fontSize: 13,
                    color: textPrimary,
                    fontWeight: FontWeight.bold,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 4),
                Text(
                  person['role'] as String,
                  style: TextStyle(
                    fontSize: 10,
                    color: premiumGreyLight,
                    fontWeight: FontWeight.w600,
                    letterSpacing: 0.5,
                  ),
                ),
                const SizedBox(height: 6),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 12),
                  child: Text(
                    person['bio'] as String,
                    style: TextStyle(
                      fontSize: 10,
                      color: textSecondary,
                      height: 1.3,
                    ),
                    textAlign: TextAlign.center,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                const SizedBox(height: 8),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: premiumGrey.withOpacity(0.15),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: premiumGrey.withOpacity(0.3)),
                  ),
                  child: const Row(
                    mainAxisSize: MainAxisSize.min,
                    children: <Widget>[
                      Icon(FontAwesomeIcons.telegram, size: 10, color: Colors.white70),
                      SizedBox(width: 4),
                      Text(
                        "CONTACT",
                        style: TextStyle(
                          fontSize: 8,
                          color: Colors.white70,
                          fontWeight: FontWeight.bold,
                          letterSpacing: 1,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildFooter() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: <Color>[
            premiumGrey.withOpacity(0.1),
            Colors.transparent,
          ],
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
        ),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: premiumGrey.withOpacity(0.2)),
      ),
      child: Column(
        children: <Widget>[
          const Icon(FontAwesomeIcons.codePullRequest, color: Colors.white54, size: 28),
          const SizedBox(height: 12),
          Text(
            "BUILT WITH DEDICATION",
            style: TextStyle(
              fontFamily: 'Orbitron',
              fontSize: 11,
              color: textSecondary,
              letterSpacing: 2,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            "CosmicX",
            style: TextStyle(
              fontFamily: 'ShareTechMono',
              fontSize: 10,
              color: premiumGreyLight.withOpacity(0.8),
              letterSpacing: 1,
            ),
          ),
          const SizedBox(height: 12),
          Container(
            width: 40,
            height: 1,
            color: premiumGrey.withOpacity(0.4),
          ),
        ],
      ),
    );
  }
}