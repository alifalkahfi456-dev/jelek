import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'dart:ui';

class SellerPage extends StatefulWidget {
  final String keyToken;

  const SellerPage({super.key, required this.keyToken});

  @override
  State<SellerPage> createState() => _SellerPageState();
}

class _SellerPageState extends State<SellerPage> with SingleTickerProviderStateMixin {
  final _newUser = TextEditingController();
  final _newPass = TextEditingController();
  final _days = TextEditingController();
  final _editUser = TextEditingController();
  final _editDays = TextEditingController();
  
  // Untuk akun permanen (tanpa expired)
  final _permUser = TextEditingController();
  final _permPass = TextEditingController();
  
  bool loading = false;
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;

  final Color deepPurple = const Color(0xFF120000);
  final Color mainPurple = const Color(0xFF2A0000);
  final Color accentPurple = const Color(0xFFCCCCCC);
  final Color deepBlack = const Color(0xFF120000);
  final Color cardDark = const Color(0xFF2A0000);
  final Color greenAccent = const Color(0xFF4CAF50);

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600),
    )..forward();
    _fadeAnimation = CurvedAnimation(parent: _animationController, curve: Curves.easeOut);
  }

  @override
  void dispose() {
    _animationController.dispose();
    _newUser.dispose();
    _newPass.dispose();
    _days.dispose();
    _editUser.dispose();
    _editDays.dispose();
    _permUser.dispose();
    _permPass.dispose();
    super.dispose();
  }

  // Membuat akun dengan durasi (berlaku sampai tanggal tertentu)
  Future<void> _create() async {
    final u = _newUser.text.trim(), p = _newPass.text.trim(), d = _days.text.trim();
    if (u.isEmpty || p.isEmpty || d.isEmpty) return _alert("Semua field wajib diisi");
    setState(() => loading = true);
    final res = await http.get(Uri.parse(
        "http://panel.lynzzofficial.com:2031/createAccount?key=${widget.keyToken}&newUser=$u&pass=$p&day=$d"));
    final data = jsonDecode(res.body);
    if (data['created'] == true) {
      _alert("Akun berhasil dibuat!", isSuccess: true);
      _newUser.clear(); _newPass.clear(); _days.clear();
    } else {
      _alert("${data['message'] ?? 'Gagal membuat akun.'}");
    }
    setState(() => loading = false);
  }

  // MEMBUAT AKUN PERMANEN (tanpa expired date / berlaku selamanya)
  Future<void> _createPermanent() async {
    final u = _permUser.text.trim(), p = _permPass.text.trim();
    if (u.isEmpty || p.isEmpty) return _alert("Username dan Password wajib diisi");
    setState(() => loading = true);
    
    // Kirim day = 0 atau nilai khusus untuk menandakan akun permanen
    // Sesuaikan dengan API backend Anda
    final res = await http.get(Uri.parse(
        "http://panel.lynzzofficial.com:2031/createAccount?key=${widget.keyToken}&newUser=$u&pass=$p&day=0&permanent=true"));
    final data = jsonDecode(res.body);
    if (data['created'] == true) {
      _alert("Akun PERMANEN berhasil dibuat!", isSuccess: true);
      _permUser.clear(); _permPass.clear();
    } else {
      _alert("${data['message'] ?? 'Gagal membuat akun permanen.'}");
    }
    setState(() => loading = false);
  }

  // Mengubah durasi akun (menambah hari)
  Future<void> _edit() async {
    final u = _editUser.text.trim(), d = _editDays.text.trim();
    if (u.isEmpty || d.isEmpty) return _alert("Username dan durasi wajib diisi");
    setState(() => loading = true);
    final res = await http.get(Uri.parse(
        "http://panel.lynzzofficial.com:2031/editUser?key=${widget.keyToken}&username=$u&addDays=$d"));
    final data = jsonDecode(res.body);
    if (data['edited'] == true) {
      _alert("Durasi berhasil diperbarui.", isSuccess: true);
      _editUser.clear(); _editDays.clear();
    } else {
      _alert("${data['message'] ?? 'Gagal mengubah durasi.'}");
    }
    setState(() => loading = false);
  }

  void _alert(String msg, {bool isSuccess = false}) {
    showDialog(
      context: context,
      builder: (_) => BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 15, sigmaY: 15),
        child: AlertDialog(
          backgroundColor: cardDark,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(24),
            side: BorderSide(color: isSuccess ? greenAccent : accentPurple.withOpacity(0.3), width: 1.5),
          ),
          content: Text(
            msg,
            style: const TextStyle(color: Colors.white70),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: Text("OK", style: TextStyle(color: isSuccess ? greenAccent : accentPurple)),
            )
          ],
        ),
      ),
    );
  }

  Widget _buildGlassCard({required Widget child, EdgeInsetsGeometry? padding}) {
    return Container(
      margin: const EdgeInsets.symmetric(vertical: 8),
      padding: padding ?? const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            cardDark,
            cardDark.withOpacity(0.8),
          ],
        ),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: accentPurple.withOpacity(0.3),
          width: 1.5,
        ),
        boxShadow: [
          BoxShadow(
            color: mainPurple.withOpacity(0.15),
            blurRadius: 25,
            spreadRadius: 2,
          ),
        ],
      ),
      child: child,
    );
  }

  Widget _buildGlassInputField({
    required TextEditingController controller,
    required String label,
    required IconData icon,
    TextInputType keyboardType = TextInputType.text,
    bool obscureText = false,
  }) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        gradient: LinearGradient(
          colors: [
            cardDark,
            cardDark.withOpacity(0.8),
          ],
        ),
      ),
      child: TextField(
        controller: controller,
        keyboardType: keyboardType,
        obscureText: obscureText,
        style: const TextStyle(color: Colors.white),
        cursorColor: accentPurple,
        decoration: InputDecoration(
          labelText: label,
          labelStyle: const TextStyle(color: Colors.white70),
          prefixIcon: Icon(icon, color: accentPurple),
          filled: false,
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(16),
            borderSide: BorderSide(color: accentPurple.withOpacity(0.3)),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(16),
            borderSide: BorderSide(color: accentPurple, width: 2),
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(16),
            borderSide: BorderSide(color: accentPurple.withOpacity(0.3)),
          ),
          contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
        ),
      ),
    );
  }

  Widget _buildSectionTitle(String title, IconData icon, {Color? color}) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Row(
        children: [
          Icon(icon, color: color ?? accentPurple, size: 24),
          const SizedBox(width: 12),
          Text(
            title,
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: color ?? Colors.white,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildActionButton({
    required String text,
    required IconData icon,
    required VoidCallback onPressed,
    required Color color,
    bool isLoading = false,
  }) {
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        gradient: LinearGradient(
          colors: [
            color.withOpacity(0.8),
            color.withOpacity(0.6),
          ],
        ),
        boxShadow: [
          BoxShadow(
            color: color.withOpacity(0.3),
            blurRadius: 15,
            spreadRadius: 2,
          ),
        ],
      ),
      child: ElevatedButton(
        onPressed: isLoading ? null : onPressed,
        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.transparent,
          shadowColor: Colors.transparent,
          padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 24),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
        ),
        child: isLoading
            ? const SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  color: Colors.white,
                ),
              )
            : Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(icon, color: Colors.white, size: 20),
                  const SizedBox(width: 8),
                  Text(
                    text,
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                    ),
                  ),
                ],
              ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: deepBlack,
      body: Stack(
        children: [
          // Background decorations
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
                    deepPurple.withOpacity(0.1),
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
                    mainPurple.withOpacity(0.08),
                    Colors.transparent,
                  ],
                ),
              ),
            ),
          ),

          BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20),
            child: SafeArea(
              child: FadeTransition(
                opacity: _fadeAnimation,
                child: SingleChildScrollView(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      // Header
                      _buildGlassCard(
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.store, color: accentPurple, size: 32),
                            const SizedBox(width: 12),
                            const Text(
                              "RESELLER PANEL",
                              style: TextStyle(
                                fontSize: 24,
                                fontWeight: FontWeight.bold,
                                letterSpacing: 1.5,
                                color: Colors.white,
                              ),
                            ),
                          ],
                        ),
                      ),

                      const SizedBox(height: 24),

                      // --- SECTION: BUAT AKUN PERMANEN (BARU) ---
                      _buildGlassCard(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            _buildSectionTitle("Buat Akun Permanen", Icons.star, color: greenAccent),
                            const Text(
                              "Akun member tanpa masa berlaku (selamanya)",
                              style: TextStyle(color: Colors.white54, fontSize: 11),
                            ),
                            const SizedBox(height: 12),

                            _buildGlassInputField(
                              controller: _permUser,
                              label: "Username",
                              icon: Icons.person_outline,
                            ),

                            _buildGlassInputField(
                              controller: _permPass,
                              label: "Password",
                              icon: Icons.lock_outline,
                              obscureText: true,
                            ),

                            const SizedBox(height: 8),

                            _buildActionButton(
                              text: "BUAT AKUN PERMANEN",
                              icon: Icons.star,
                              onPressed: _createPermanent,
                              color: greenAccent,
                              isLoading: loading,
                            ),
                          ],
                        ),
                      ),

                      const SizedBox(height: 24),

                      // --- SECTION: BUAT AKUN BIAYA (dengan durasi) ---
                      _buildGlassCard(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            _buildSectionTitle("Buat Akun Berbayar", Icons.person_add),

                            _buildGlassInputField(
                              controller: _newUser,
                              label: "Username",
                              icon: Icons.person_outline,
                            ),

                            _buildGlassInputField(
                              controller: _newPass,
                              label: "Password",
                              icon: Icons.lock_outline,
                              obscureText: true,
                            ),

                            _buildGlassInputField(
                              controller: _days,
                              label: "Durasi (hari)",
                              icon: Icons.calendar_today,
                              keyboardType: TextInputType.number,
                            ),

                            const SizedBox(height: 8),

                            _buildActionButton(
                              text: "BUAT AKUN",
                              icon: Icons.person_add,
                              onPressed: _create,
                              color: mainPurple,
                              isLoading: loading,
                            ),
                          ],
                        ),
                      ),

                      const SizedBox(height: 24),

                      // --- SECTION: UBAH DURASI ---
                      _buildGlassCard(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            _buildSectionTitle("Tambah Durasi", Icons.edit_calendar),

                            _buildGlassInputField(
                              controller: _editUser,
                              label: "Username",
                              icon: Icons.person_outline,
                            ),

                            _buildGlassInputField(
                              controller: _editDays,
                              label: "Tambah Hari",
                              icon: Icons.calendar_today,
                              keyboardType: TextInputType.number,
                            ),

                            const SizedBox(height: 8),

                            _buildActionButton(
                              text: "TAMBAH DURASI",
                              icon: Icons.edit,
                              onPressed: _edit,
                              color: deepPurple,
                              isLoading: loading,
                            ),
                          ],
                        ),
                      ),

                      const SizedBox(height: 20),

                      // Info card
                      _buildGlassCard(
                        padding: const EdgeInsets.all(16),
                        child: Row(
                          children: [
                            Icon(Icons.info, color: greenAccent, size: 20),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    "Akun Permanen vs Berbayar",
                                    style: TextStyle(
                                      color: greenAccent,
                                      fontSize: 13,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    "• Akun PERMANEN: Tidak ada masa berlaku (selamanya)\n• Akun BERBAYAR: Memiliki masa berlaku sesuai durasi yang dipilih",
                                    style: TextStyle(
                                      color: Colors.white70,
                                      fontSize: 11,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}