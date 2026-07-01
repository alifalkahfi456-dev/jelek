import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

class SellerPage extends StatefulWidget {
  final String keyToken;

  const SellerPage({super.key, required this.keyToken});

  @override
  State<SellerPage> createState() => _SellerPageState();
}

class _SellerPageState extends State<SellerPage> with TickerProviderStateMixin {
  final _newUser = TextEditingController();
  final _newPass = TextEditingController();
  final _days = TextEditingController();
  final _editUser = TextEditingController();
  final _editDays = TextEditingController();
  bool loading = false;
  bool isCreating = false;

  late AnimationController _fadeController;
  late AnimationController _slideController;
  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation;

  // Tema warna hitam-abu-abu-transparan
  final Color pureBlack = const Color(0xFF000000);           // HITAM MURNI
  final Color deepBlack = const Color(0xFF0A0A0A);           // HITAM PEKAT
  final Color darkGray = const Color(0xFF1A1A1A);            // ABU GELAP
  final Color mediumGray = const Color(0xFF2D2D2D);          // ABU SEDANG
  final Color lightGray = const Color(0xFF4A4A4A);           // ABU TERANG
  final Color accentGray = const Color(0xFF6B6B6B);          // ABU ACCENT
  final Color textGray = const Color(0xFFB0B0B0);            // ABU TEXT
  final Color whiteText = const Color(0xFFFFFFFF);           // PUTIH
  final Color successGray = const Color(0xFF5A5A5A);         // ABU SUCCESS
  final Color warningGray = const Color(0xFF7A7A7A);         // ABU WARNING
  final Color dangerGray = const Color(0xFF3A3A3A);          // ABU DANGER

  @override
  void initState() {
    super.initState();

    _fadeController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1000),
    );

    _slideController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    );

    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _fadeController, curve: Curves.easeInOut),
    );

    _slideAnimation = Tween<Offset>(
      begin: const Offset(0, 0.3),
      end: Offset.zero,
    ).animate(CurvedAnimation(parent: _slideController, curve: Curves.easeOut));

    _fadeController.forward();
    _slideController.forward();
  }

  @override
  void dispose() {
    _fadeController.dispose();
    _slideController.dispose();
    _newUser.dispose();
    _newPass.dispose();
    _days.dispose();
    _editUser.dispose();
    _editDays.dispose();
    super.dispose();
  }

  Future<void> _create() async {
    final u = _newUser.text.trim(), p = _newPass.text.trim(), d = _days.text.trim();
    if (u.isEmpty || p.isEmpty || d.isEmpty) {
      _showNotification("Error", "Semua field wajib diisi", dangerGray);
      return;
    }

    setState(() {
      loading = true;
      isCreating = true;
    });

    final res = await http.get(Uri.parse(
        "http://panelbyxiaonotdev.zarxsft.my.id:2033/createAccount?key=${widget.keyToken}&newUser=$u&pass=$p&day=$d"));
    final data = jsonDecode(res.body);

    if (data['created'] == true) {
      _showNotification("Success", "Akun berhasil dibuat!", successGray);
      _newUser.clear();
      _newPass.clear();
      _days.clear();
    } else {
      _showNotification("Error", data['message'] ?? 'Gagal membuat akun.', dangerGray);
    }

    setState(() {
      loading = false;
      isCreating = false;
    });
  }

  Future<void> _edit() async {
    final u = _editUser.text.trim(), d = _editDays.text.trim();
    if (u.isEmpty || d.isEmpty) {
      _showNotification("Error", "Username dan durasi wajib diisi", dangerGray);
      return;
    }

    setState(() {
      loading = true;
      isCreating = false;
    });

    final res = await http.get(Uri.parse(
        "http://panelbyxiaonotdev.zarxsft.my.id:2033/editUser?key=${widget.keyToken}&username=$u&addDays=$d"));
    final data = jsonDecode(res.body);

    if (data['edited'] == true) {
      _showNotification("Success", "Durasi berhasil diperbarui.", successGray);
      _editUser.clear();
      _editDays.clear();
    } else {
      _showNotification("Error", data['message'] ?? 'Gagal mengubah durasi.', dangerGray);
    }

    setState(() {
      loading = false;
      isCreating = false;
    });
  }

  void _showNotification(String title, String message, Color color) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        content: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [
                darkGray.withOpacity(0.95),
                mediumGray.withOpacity(0.9),
              ],
            ),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: lightGray.withOpacity(0.3)),
            boxShadow: [
              BoxShadow(
                color: pureBlack.withOpacity(0.5),
                blurRadius: 10,
                spreadRadius: 2,
              ),
            ],
          ),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: color.withOpacity(0.3),
                  shape: BoxShape.circle,
                  border: Border.all(color: textGray.withOpacity(0.5)),
                ),
                child: Icon(
                  color == successGray ? Icons.check_circle :
                  color == dangerGray ? Icons.error : Icons.info,
                  color: whiteText,
                  size: 20,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      title,
                      style: TextStyle(
                        color: whiteText,
                        fontWeight: FontWeight.bold,
                        fontSize: 14,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      message,
                      style: TextStyle(
                        color: textGray,
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
        behavior: SnackBarBehavior.floating,
        margin: const EdgeInsets.all(16),
        duration: const Duration(seconds: 4),
      ),
    );
  }

  Widget _buildModernInput({
    required String label,
    required TextEditingController controller,
    required IconData icon,
    TextInputType keyboardType = TextInputType.text,
    bool obscureText = false,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: TextStyle(
            color: textGray,
            fontSize: 14,
            fontWeight: FontWeight.w500,
          ),
        ),
        const SizedBox(height: 8),
        Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [
                mediumGray.withOpacity(0.5),
                darkGray.withOpacity(0.7),
              ],
            ),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: lightGray.withOpacity(0.3)),
            boxShadow: [
              BoxShadow(
                color: pureBlack.withOpacity(0.3),
                blurRadius: 5,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: TextField(
            controller: controller,
            keyboardType: keyboardType,
            obscureText: obscureText,
            style: TextStyle(color: whiteText),
            decoration: InputDecoration(
              prefixIcon: Icon(icon, color: textGray),
              border: InputBorder.none,
              contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildActionCard({
    required String title,
    required String description,
    required IconData icon,
    required List<Widget> inputs,
    required VoidCallback onPressed,
    required String buttonText,
    Color? buttonColor,
  }) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      margin: const EdgeInsets.only(bottom: 24),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            darkGray.withOpacity(0.8),
            mediumGray.withOpacity(0.6),
          ],
        ),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: lightGray.withOpacity(0.2)),
        boxShadow: [
          BoxShadow(
            color: pureBlack.withOpacity(0.5),
            blurRadius: 15,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      lightGray.withOpacity(0.3),
                      mediumGray.withOpacity(0.5),
                    ],
                  ),
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: accentGray.withOpacity(0.3)),
                ),
                child: Icon(icon, color: textGray, size: 24),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: TextStyle(
                        color: whiteText,
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      description,
                      style: TextStyle(
                        color: textGray,
                        fontSize: 14,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          ...inputs,
          const SizedBox(height: 20),
          Container(
            width: double.infinity,
            height: 50,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(12),
              gradient: LinearGradient(
                colors: [
                  lightGray.withOpacity(0.8),
                  mediumGray.withOpacity(0.9),
                ],
                begin: Alignment.centerLeft,
                end: Alignment.centerRight,
              ),
              border: Border.all(color: accentGray.withOpacity(0.3)),
              boxShadow: [
                BoxShadow(
                  color: pureBlack.withOpacity(0.4),
                  blurRadius: 8,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: ElevatedButton(
              onPressed: loading ? null : onPressed,
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.transparent,
                foregroundColor: whiteText,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                elevation: 0,
              ),
              child: loading && isCreating == (buttonText == "CREATE ACCOUNT")
                  ? SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(
                  color: whiteText,
                  strokeWidth: 2,
                ),
              )
                  : loading && isCreating == (buttonText == "UPDATE DURATION")
                  ? SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(
                  color: whiteText,
                  strokeWidth: 2,
                ),
              )
                  : Text(
                buttonText,
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: whiteText,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: pureBlack,
      body: Stack(
        children: [
          // Background subtle effects
          Positioned(
            top: -100,
            right: -100,
            child: Container(
              width: 300,
              height: 300,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: RadialGradient(
                  colors: [
                    darkGray.withOpacity(0.2),
                    Colors.transparent,
                  ],
                ),
              ),
            ),
          ),
          Positioned(
            bottom: -150,
            left: -100,
            child: Container(
              width: 400,
              height: 400,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: RadialGradient(
                  colors: [
                    mediumGray.withOpacity(0.15),
                    Colors.transparent,
                  ],
                ),
              ),
            ),
          ),
          
          // Main content
          FadeTransition(
            opacity: _fadeAnimation,
            child: SlideTransition(
              position: _slideAnimation,
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(16),
                child: Column(
                  children: [
                    // Header Section
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(24),
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(16),
                        gradient: LinearGradient(
                          colors: [
                            mediumGray.withOpacity(0.8),
                            darkGray.withOpacity(0.9),
                          ],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        ),
                        border: Border.all(color: lightGray.withOpacity(0.3)),
                        boxShadow: [
                          BoxShadow(
                            color: pureBlack.withOpacity(0.5),
                            blurRadius: 15,
                            offset: const Offset(0, 5),
                          ),
                        ],
                      ),
                      child: Column(
                        children: [
                          Text(
                            "Account Management",
                            style: TextStyle(
                              color: whiteText,
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
                              letterSpacing: 1.2,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            "Create new accounts or extend existing ones",
                            style: TextStyle(
                              color: textGray,
                              fontSize: 14,
                            ),
                            textAlign: TextAlign.center,
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(height: 24),

                    // Create Account Card
                    _buildActionCard(
                      title: "Create New Account",
                      description: "Create a new user account with specified duration",
                      icon: Icons.person_add,
                      inputs: [
                        _buildModernInput(
                          label: "Username",
                          controller: _newUser,
                          icon: Icons.person,
                        ),
                        const SizedBox(height: 16),
                        _buildModernInput(
                          label: "Password",
                          controller: _newPass,
                          icon: Icons.lock,
                          obscureText: true,
                        ),
                        const SizedBox(height: 16),
                        _buildModernInput(
                          label: "Duration (days)",
                          controller: _days,
                          icon: Icons.calendar_today,
                          keyboardType: TextInputType.number,
                        ),
                      ],
                      onPressed: _create,
                      buttonText: "CREATE ACCOUNT",
                      buttonColor: successGray,
                    ),

                    // Edit Duration Card
                    _buildActionCard(
                      title: "Extend Account Duration",
                      description: "Add more days to an existing user account",
                      icon: Icons.update,
                      inputs: [
                        _buildModernInput(
                          label: "Username",
                          controller: _editUser,
                          icon: Icons.person,
                        ),
                        const SizedBox(height: 16),
                        _buildModernInput(
                          label: "Additional Days",
                          controller: _editDays,
                          icon: Icons.add_circle,
                          keyboardType: TextInputType.number,
                        ),
                      ],
                      onPressed: _edit,
                      buttonText: "UPDATE DURATION",
                      buttonColor: warningGray,
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}