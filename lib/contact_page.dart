import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:url_launcher/url_launcher.dart';

class ContactPage extends StatelessWidget {
  const ContactPage({super.key});

  // --- ELEGANT RED ESPORTS THEME ---
  static const Color bgDark = Color(0xFF0A0A0F);
  static const Color primaryRed = Color(0xFFFF0033);
  static const Color primaryDarkRed = Color(0xFFCC0022);
  static const Color accentRed = Color(0xFFFF3366);
  static const Color accentMagenta = Color(0xFFFF006E);
  static const Color cardBg = Color(0xFF151520);
  static const Color borderGlow = Color(0xFF2A2A3A);

  Future<void> _launchUrl(String url) async {
    final Uri uri = Uri.parse(url);
    if (!await launchUrl(uri, mode: LaunchMode.externalApplication)) {
      throw Exception('Could not launch $url');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: bgDark,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: Icon(Icons.arrow_back_ios_new, color: primaryRed),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          "CUSTOMER SERVICE",
          style: TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.w600,
            letterSpacing: 2,
            fontSize: 16,
          ),
        ),
        centerTitle: true,
      ),
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              bgDark,
              Color(0xFF2A0A0A),
              Color(0xFF1A0A0A),
              bgDark,
            ],
            stops: [0.0, 0.3, 0.7, 1.0],
          ),
        ),
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                // Animated glowing icon container
                Container(
                  padding: EdgeInsets.all(24),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [primaryRed, primaryDarkRed],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    shape: BoxShape.circle,
                    boxShadow: [
                      BoxShadow(
                        color: primaryRed.withOpacity(0.4),
                        blurRadius: 30,
                        spreadRadius: 5,
                      ),
                      BoxShadow(
                        color: primaryDarkRed.withOpacity(0.3),
                        blurRadius: 60,
                        spreadRadius: 2,
                      ),
                    ],
                  ),
                  child: Icon(
                    Icons.support_agent_rounded,
                    size: 56,
                    color: Colors.white,
                  ),
                ),
                SizedBox(height: 32),
                // Glitch text effect
                Stack(
                  children: [
                    Text(
                      "NEED ASSISTANCE?",
                      style: TextStyle(
                        color: primaryRed.withOpacity(0.3),
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                        letterSpacing: 3,
                        fontFamily: 'monospace',
                      ),
                    ),
                    Text(
                      "NEED ASSISTANCE?",
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                        letterSpacing: 3,
                        fontFamily: 'monospace',
                        shadows: [
                          Shadow(color: primaryRed, offset: Offset(-1, 0)),
                          Shadow(color: accentMagenta, offset: Offset(1, 0)),
                        ],
                      ),
                    ),
                  ],
                ),
                SizedBox(height: 12),
                Container(
                  width: 60,
                  height: 2,
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [primaryRed, primaryDarkRed],
                    ),
                  ),
                ),
                SizedBox(height: 16),
                Text(
                  "Connect with us through our\ncyber channels",
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: Colors.white60,
                    fontSize: 13,
                    letterSpacing: 0.5,
                    height: 1.5,
                  ),
                ),
                SizedBox(height: 48),
                Column(
                  children: [
                    _buildTelegramButton(),
                    SizedBox(height: 14),
                    _buildWhatsAppButton(),
                    SizedBox(height: 14),
                    _buildTikTokButton(),
                    SizedBox(height: 14),
                    _buildInstagramButton(),
                  ],
                ),
                SizedBox(height: 24),
                Container(
                  padding: EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    border: Border.all(color: primaryRed.withOpacity(0.3)),
                    borderRadius: BorderRadius.circular(30),
                  ),
                  child: Text(
                    "Red Support.",
                    style: TextStyle(
                      color: primaryRed,
                      fontSize: 10,
                      letterSpacing: 1.5,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildTelegramButton() {
    const String url = "https://t.me/RizzXybsRols";
    const Color telegramBlue = Color(0xFF0088CC);
    
    return InkWell(
      onTap: () => _launchUrl(url),
      borderRadius: BorderRadius.circular(12),
      child: Container(
        width: double.infinity,
        padding: EdgeInsets.symmetric(vertical: 14, horizontal: 20),
        decoration: BoxDecoration(
          color: telegramBlue.withOpacity(0.15),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: telegramBlue.withOpacity(0.4),
            width: 1,
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.3),
              blurRadius: 15,
              offset: Offset(0, 8),
            ),
          ],
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Row(
              children: [
                Container(
                  padding: EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: telegramBlue.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(
                      color: telegramBlue.withOpacity(0.5),
                      width: 0.5,
                    ),
                  ),
                  child: FaIcon(FontAwesomeIcons.telegram, color: telegramBlue, size: 22),
                ),
                SizedBox(width: 18),
                Text(
                  "Telegram",
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
                    letterSpacing: 1.2,
                  ),
                ),
              ],
            ),
            Container(
              padding: EdgeInsets.all(6),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.05),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(
                Icons.arrow_forward_ios,
                color: primaryRed.withOpacity(0.7),
                size: 12,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildWhatsAppButton() {
    const String url = "https://whatsapp.com/channel/0029VbCVbgjBadmTh4hF3H1X";
    const Color whatsappGreen = Color(0xFF25D366);
    
    return InkWell(
      onTap: () => _launchUrl(url),
      borderRadius: BorderRadius.circular(12),
      child: Container(
        width: double.infinity,
        padding: EdgeInsets.symmetric(vertical: 14, horizontal: 20),
        decoration: BoxDecoration(
          color: whatsappGreen.withOpacity(0.15),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: whatsappGreen.withOpacity(0.4),
            width: 1,
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.3),
              blurRadius: 15,
              offset: Offset(0, 8),
            ),
          ],
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Row(
              children: [
                Container(
                  padding: EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: whatsappGreen.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(
                      color: whatsappGreen.withOpacity(0.5),
                      width: 0.5,
                    ),
                  ),
                  child: FaIcon(FontAwesomeIcons.whatsapp, color: whatsappGreen, size: 22),
                ),
                SizedBox(width: 18),
                Text(
                  "WhatsApp",
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
                    letterSpacing: 1.2,
                  ),
                ),
              ],
            ),
            Container(
              padding: EdgeInsets.all(6),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.05),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(
                Icons.arrow_forward_ios,
                color: primaryRed.withOpacity(0.7),
                size: 12,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTikTokButton() {
    const String url = "https://www.tiktok.com/@rizzxrat?_r=1&_t=ZS-96b7kLWiaZA";
    
    return InkWell(
      onTap: () => _launchUrl(url),
      borderRadius: BorderRadius.circular(12),
      child: Container(
        width: double.infinity,
        padding: EdgeInsets.symmetric(vertical: 14, horizontal: 20),
        decoration: BoxDecoration(
          color: Colors.white.withOpacity(0.08),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: Colors.white.withOpacity(0.15),
            width: 1,
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.3),
              blurRadius: 15,
              offset: Offset(0, 8),
            ),
          ],
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Row(
              children: [
                Container(
                  padding: EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.12),
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(
                      color: Colors.white.withOpacity(0.2),
                      width: 0.5,
                    ),
                  ),
                  child: FaIcon(FontAwesomeIcons.tiktok, color: Colors.white, size: 22),
                ),
                SizedBox(width: 18),
                Text(
                  "TikTok",
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
                    letterSpacing: 1.2,
                  ),
                ),
              ],
            ),
            Container(
              padding: EdgeInsets.all(6),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.05),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(
                Icons.arrow_forward_ios,
                color: primaryRed.withOpacity(0.7),
                size: 12,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInstagramButton() {
    const String url = "https://www.instagram.com/rizzone";
    const Color instagramPink = Color(0xFFE4405F);
    
    return InkWell(
      onTap: () => _launchUrl(url),
      borderRadius: BorderRadius.circular(12),
      child: Container(
        width: double.infinity,
        padding: EdgeInsets.symmetric(vertical: 14, horizontal: 20),
        decoration: BoxDecoration(
          color: instagramPink.withOpacity(0.15),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: instagramPink.withOpacity(0.4),
            width: 1,
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.3),
              blurRadius: 15,
              offset: Offset(0, 8),
            ),
          ],
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Row(
              children: [
                Container(
                  padding: EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: instagramPink.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(
                      color: instagramPink.withOpacity(0.5),
                      width: 0.5,
                    ),
                  ),
                  child: FaIcon(FontAwesomeIcons.instagram, color: instagramPink, size: 22),
                ),
                SizedBox(width: 18),
                Text(
                  "Instagram",
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
                    letterSpacing: 1.2,
                  ),
                ),
              ],
            ),
            Container(
              padding: EdgeInsets.all(6),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.05),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(
                Icons.arrow_forward_ios,
                color: primaryRed.withOpacity(0.7),
                size: 12,
              ),
            ),
          ],
        ),
      ),
    );
  }
}