import 'dart:async';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;

class InfoPage extends StatefulWidget {
  final String sessionKey;

  const InfoPage({super.key, required this.sessionKey});

  @override
  State<InfoPage> createState() => _InfoPageState();
}

class _InfoPageState extends State<InfoPage> with SingleTickerProviderStateMixin {
  Map<String, dynamic>? serverInfo;
  bool isLoading = true;

  bool isApiOnline = false;
  int apiPingMs = 0;
  Color apiStatusColor = Colors.grey;
  String apiStatusText = "Checking...";
  Timer? _pingTimer;
  late AnimationController _glowController;

  // --- TEMA MERAH GELAP ---
  final Color bgDark = const Color(0xFF050505);
  final Color primaryRed = const Color(0xFFC62828);
  final Color accentRed = const Color(0xFFFF5252);
  final Color primaryWhite = Colors.white;
  final Color textGrey = Colors.grey.shade400;
  final Color cardGlass = const Color(0xFF1A0A0A);
  final Color borderGlass = const Color(0xFF4A1A1A);

  @override
  void initState() {
    super.initState();
    _fetchServerInfo();
    _startApiPingLoop();
    _glowController = AnimationController(
      duration: const Duration(milliseconds: 1500),
      vsync: this,
    )..repeat(reverse: true);
  }

  @override
  void dispose() {
    _pingTimer?.cancel();
    _glowController.dispose();
    super.dispose();
  }

  Future<void> _fetchServerInfo() async {
    try {
      final res = await http.get(
        Uri.parse('http://senzlinodepriv.senzhosting.my.id:10791/getServerInfo?key=${widget.sessionKey}'),
      );
      if (res.statusCode == 200) {
        setState(() {
          serverInfo = jsonDecode(res.body);
          isLoading = false;
        });
      } else {
        setState(() => isLoading = false);
      }
    } catch (e) {
      setState(() => isLoading = false);
    }
  }

  void _startApiPingLoop() {
    _checkApiPing();
    _pingTimer = Timer.periodic(const Duration(seconds: 5), (_) => _checkApiPing());
  }

  Future<void> _checkApiPing() async {
    final start = DateTime.now();
    try {
      final res = await http.get(
        Uri.parse('http://senzlinodepriv.senzhosting.my.id:10791/ping?key=${widget.sessionKey}'),
      ).timeout(const Duration(seconds: 3));

      final end = DateTime.now();
      final duration = end.difference(start).inMilliseconds;

      if (res.statusCode == 200) {
        setState(() {
          isApiOnline = true;
          apiPingMs = duration;
          if (duration < 200) {
            apiStatusColor = Colors.greenAccent;
          } else if (duration < 500) {
            apiStatusColor = Colors.amber;
          } else {
            apiStatusColor = Colors.orangeAccent;
          }
          apiStatusText = "Online (${duration}ms)";
        });
      } else {
        throw Exception("Failed");
      }
    } catch (e) {
      setState(() {
        isApiOnline = false;
        apiPingMs = 0;
        apiStatusColor = Colors.redAccent;
        apiStatusText = "Offline";
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    if (isLoading) {
      return Scaffold(
        backgroundColor: bgDark,
        appBar: _buildAppBar(),
        body: const Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              SizedBox(
                width: 40,
                height: 40,
                child: CircularProgressIndicator(
                  color: Color(0xFFFF5252),
                  strokeWidth: 2.5,
                ),
              ),
              SizedBox(height: 16),
              Text(
                "Memuat informasi",
                style: TextStyle(color: Colors.grey, fontSize: 13),
              ),
            ],
          ),
        ),
      );
    }

    final List<Map<String, String>> rulesList = [
      {"title": "Larangan Barter Akun", "desc": "Akun tidak boleh ditukar dengan barang, jasa, atau akun lain dalam bentuk apa pun."},
      {"title": "Larangan Membagikan Akun", "desc": "Setiap akun bersifat pribadi dan hanya boleh digunakan oleh pemilik akun yang terdaftar."},
      {"title": "Larangan Menjual Akun", "desc": "Member TIDAK diperbolehkan menjual akun. Penjualan akun hanya boleh dilakukan oleh role yang diizinkan secara resmi."},
      {"title": "Larangan Jual Durasi Ilegal", "desc": "Dilarang menjual akses harian, mingguan, trial, atau sejenisnya di luar ketentuan yang telah ditetapkan."},
      {"title": "Larangan Banting Harga", "desc": "Dilarang merusak atau menurunkan harga yang telah ditentukan (banting harga) di bawah ketentuan NoMercy Project."},
    ];

    return Scaffold(
      backgroundColor: bgDark,
      appBar: _buildAppBar(),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildApiStatus(),
            const SizedBox(height: 24),
            _buildSectionHeader("Peraturan Pengguna"),
            const SizedBox(height: 16),
            ...rulesList.asMap().entries.map((entry) {
              int index = entry.key + 1;
              Map<String, String> rule = entry.value;
              return _buildRuleCard(index, rule['title']!, rule['desc']!);
            }).toList(),
            const SizedBox(height: 24),
            _buildSanctionCard(),
            const SizedBox(height: 24),
            _buildFooter(),
          ],
        ),
      ),
    );
  }

  AppBar _buildAppBar() {
    return AppBar(
      backgroundColor: Colors.transparent,
      elevation: 0,
      automaticallyImplyLeading: false,
      centerTitle: true,
      title: const Text(
        "Informasi & Peraturan",
        style: TextStyle(
          color: Colors.white,
          fontSize: 18,
          fontWeight: FontWeight.w600,
          letterSpacing: 0.5,
        ),
      ),
      bottom: PreferredSize(
        preferredSize: const Size.fromHeight(1),
        child: Container(height: 1, color: primaryRed.withOpacity(0.3)),
      ),
    );
  }

  Widget _buildApiStatus() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: cardGlass,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: borderGlass, width: 0.8),
      ),
      child: Row(
        children: [
          AnimatedContainer(
            duration: const Duration(milliseconds: 300),
            width: 8,
            height: 8,
            decoration: BoxDecoration(
              color: apiStatusColor,
              shape: BoxShape.circle,
              boxShadow: [
                BoxShadow(color: apiStatusColor.withOpacity(0.4), blurRadius: 4),
              ],
            ),
          ),
          const SizedBox(width: 12),
          Text(
            "Status Sistem",
            style: TextStyle(color: textGrey, fontSize: 13),
          ),
          const SizedBox(width: 8),
          Container(
            width: 1,
            height: 12,
            color: borderGlass,
          ),
          const SizedBox(width: 8),
          Text(
            apiStatusText,
            style: TextStyle(
              color: apiStatusColor,
              fontSize: 13,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSectionHeader(String title) {
    return Row(
      children: [
        Container(
          width: 3,
          height: 18,
          decoration: BoxDecoration(
            color: accentRed,
            borderRadius: BorderRadius.circular(2),
          ),
        ),
        const SizedBox(width: 10),
        Text(
          title,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 16,
            fontWeight: FontWeight.w600,
            letterSpacing: 0.5,
          ),
        ),
      ],
    );
  }

  Widget _buildRuleCard(int index, String title, String desc) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: cardGlass,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: borderGlass, width: 0.8),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: 28,
              height: 28,
              decoration: BoxDecoration(
                color: primaryRed.withOpacity(0.15),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Center(
                child: Text(
                  "$index",
                  style: TextStyle(
                    color: accentRed,
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.w600,
                      fontSize: 14,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    desc,
                    style: TextStyle(
                      color: textGrey,
                      fontSize: 12,
                      height: 1.4,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSanctionCard() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            primaryRed.withOpacity(0.08),
            primaryRed.withOpacity(0.02),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: accentRed.withOpacity(0.3), width: 1),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Icon(Icons.warning_amber_rounded, color: accentRed, size: 32),
          const SizedBox(height: 12),
          const Text(
            "SANKSI",
            style: TextStyle(
              color: Color(0xFFFF5252),
              fontSize: 18,
              fontWeight: FontWeight.w700,
              letterSpacing: 1,
            ),
          ),
          const SizedBox(height: 12),
          const Text(
            "Jika pengguna terbukti melanggar salah satu peraturan di atas:",
            style: TextStyle(color: Colors.white70, fontSize: 13),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 10),
          const Text(
            "Akun akan dihapus secara permanen",
            style: TextStyle(
              color: Colors.white,
              fontSize: 15,
              fontWeight: FontWeight.w600,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 4),
          const Text(
            "Tanpa pengembalian akun, saldo, atau kompensasi",
            style: TextStyle(color: Color(0xFFFF5252), fontSize: 12),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildFooter() {
    return Column(
      children: [
        Icon(Icons.shield_outlined, color: accentRed.withOpacity(0.5), size: 28),
        const SizedBox(height: 12),
        Text(
          "Dengan menggunakan aplikasi ini, Anda dianggap telah menyetujui seluruh peraturan di atas.",
          style: TextStyle(color: textGrey, fontSize: 11, height: 1.4),
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 16),
        Container(
          height: 2,
          width: 40,
          decoration: BoxDecoration(
            color: accentRed.withOpacity(0.3),
            borderRadius: BorderRadius.circular(1),
          ),
        ),
        const SizedBox(height: 20),
      ],
    );
  }
}