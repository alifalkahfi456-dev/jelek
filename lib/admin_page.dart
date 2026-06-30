import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';

class AdminPage extends StatefulWidget {
  final String sessionKey;

  const AdminPage({super.key, required this.sessionKey});

  @override
  State<AdminPage> createState() => _AdminPageState();
}

class _AdminPageState extends State<AdminPage> {
  late String sessionKey;
  List<dynamic> fullUserList = [];
  List<dynamic> filteredList = [];

  // Role Options: Hanya Reseller & Member
  final List<String> roleOptions = ['reseller', 'member'];
  String selectedRole = 'member';

  int currentPage = 1;
  int itemsPerPage = 25;

  final deleteController = TextEditingController();
  final createUsernameController = TextEditingController();
  final createPasswordController = TextEditingController();
  final createDayController = TextEditingController();
  String newUserRole = 'member';
  bool isLoading = false;

  // --- TEMA MERAH GELAP ---
  final Color bgDark = const Color(0xFF1A0A0A);
  final Color primaryRed = const Color(0xFFC62828);
  final Color accentRed = const Color(0xFFFF5252);
  final Color primaryWhite = Colors.white;
  final Color accentGrey = Colors.grey.shade400;
  final Color cardGlass = const Color(0xFF1A0A0A);
  final Color borderGlass = const Color(0xFF4A1A1A);

  final LinearGradient redGradient = const LinearGradient(
    colors: [Color(0xFF8B0000), Color(0xFFC62828), Color(0xFFFF5252)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  @override
  void initState() {
    super.initState();
    sessionKey = widget.sessionKey;
    _fetchUsers();
  }

  Future<void> _fetchUsers() async {
    setState(() => isLoading = true);
    try {
      final res = await http.get(
        Uri.parse('http://senzlinodepriv.senzhosting.my.id:10791/listUsers?key=$sessionKey'),
      );
      final data = jsonDecode(res.body);
      if (data['valid'] == true && data['authorized'] == true) {
        fullUserList = data['users'] ?? [];
        _filterAndPaginate();
      } else {
        _alert("⚠️ Error", data['message'] ?? 'Tidak diizinkan melihat daftar user.');
      }
    } catch (_) {
      _alert("🌐 Error", "Gagal memuat user list.");
    }
    setState(() => isLoading = false);
  }

  void _filterAndPaginate() {
    setState(() {
      currentPage = 1;
      filteredList = fullUserList
          .where((u) => u['role'] == selectedRole)
          .toList();
    });
  }

  List<dynamic> _getCurrentPageData() {
    final start = (currentPage - 1) * itemsPerPage;
    final end = (start + itemsPerPage);
    return filteredList.sublist(
      start,
      end > filteredList.length ? filteredList.length : end,
    );
  }

  int get totalPages => (filteredList.length / itemsPerPage).ceil();

  Future<void> _deleteUser() async {
    final username = deleteController.text.trim();
    if (username.isEmpty) {
      _alert("⚠️ Error", "Masukkan username yang ingin dihapus.");
      return;
    }

    setState(() => isLoading = true);
    try {
      final res = await http.get(
        Uri.parse(
          'http://senzlinodepriv.senzhosting.my.id:10791/deleteUser?key=$sessionKey&username=$username',
        ),
      );
      final data = jsonDecode(res.body);
      if (data['deleted'] == true) {
        _alert("✅ Berhasil", "User '${data['user']['username']}' telah dihapus.");
        deleteController.clear();
        _fetchUsers();
      } else {
        _alert("❌ Gagal", data['message'] ?? 'Gagal menghapus user.');
      }
    } catch (_) {
      _alert("🌐 Error", "Tidak dapat menghubungi server.");
    }
    setState(() => isLoading = false);
  }

  Future<void> _createAccount() async {
    final username = createUsernameController.text.trim();
    final password = createPasswordController.text.trim();
    final day = createDayController.text.trim();

    if (username.isEmpty || password.isEmpty || day.isEmpty) {
      _alert("⚠️ Error", "Semua field wajib diisi.");
      return;
    }

    setState(() => isLoading = true);
    try {
      final url = Uri.parse(
        'http://senzlinodepriv.senzhosting.my.id:10791/userAdd?key=$sessionKey&username=$username&password=$password&day=$day&role=$newUserRole',
      );
      final res = await http.get(url);
      final data = jsonDecode(res.body);

      if (data['created'] == true) {
        _alert("✅ Sukses", "Akun '${data['user']['username']}' berhasil dibuat.");
        createUsernameController.clear();
        createPasswordController.clear();
        createDayController.clear();
        newUserRole = 'member';
        _fetchUsers();
      } else {
        _alert("❌ Gagal", data['message'] ?? 'Gagal membuat akun.');
      }
    } catch (_) {
      _alert("🌐 Error", "Gagal menghubungi server.");
    }
    setState(() => isLoading = false);
  }

  void _alert(String title, String message) {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        backgroundColor: bgDark,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
          side: BorderSide(color: accentRed.withOpacity(0.3)),
        ),
        title: Row(
          children: [
            Icon(Icons.info_outline, color: accentRed),
            const SizedBox(width: 10),
            Text(title, style: TextStyle(color: primaryWhite)),
          ],
        ),
        content: Text(message, style: TextStyle(color: accentGrey)),
        actions: [
          Center(
            child: Container(
              decoration: BoxDecoration(
                gradient: redGradient,
                borderRadius: BorderRadius.circular(12),
              ),
              child: TextButton(
                onPressed: () => Navigator.pop(context),
                child: Text("OK", style: TextStyle(color: primaryWhite, fontWeight: FontWeight.bold)),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInput({
    required String label,
    required TextEditingController controller,
    required IconData icon,
    TextInputType type = TextInputType.text,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 20),
      child: TextField(
        controller: controller,
        keyboardType: type,
        style: TextStyle(color: primaryWhite),
        decoration: InputDecoration(
          labelText: label,
          labelStyle: TextStyle(color: accentRed),
          prefixIcon: Icon(icon, color: accentRed),
          filled: true,
          fillColor: cardGlass,
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide(color: borderGlass),
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide(color: borderGlass),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide(color: accentRed, width: 2),
          ),
        ),
      ),
    );
  }

  Widget _buildGlassCard({
    required String title,
    required IconData icon,
    required List<Widget> children,
  }) {
    return Container(
      margin: EdgeInsets.only(bottom: 30),
      padding: EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: cardGlass,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: borderGlass),
        boxShadow: [
          BoxShadow(
            color: primaryRed.withOpacity(0.1),
            blurRadius: 15,
            offset: Offset(0, 5),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Container(
                padding: EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: primaryRed.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(icon, color: accentRed),
              ),
              SizedBox(width: 12),
              Text(
                title,
                style: TextStyle(
                  color: primaryWhite,
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  fontFamily: 'Orbitron',
                  letterSpacing: 1,
                ),
              ),
            ],
          ),
          SizedBox(height: 24),
          ...children,
        ],
      ),
    );
  }

  Widget _buildUserItem(Map user) {
    return Container(
      margin: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      padding: EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: cardGlass,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: borderGlass),
      ),
      child: Row(
        children: [
          Container(
            padding: EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: primaryRed.withOpacity(0.2),
              shape: BoxShape.circle,
            ),
            child: Icon(Icons.person, color: accentRed),
          ),
          SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  user['username'],
                  style: TextStyle(
                    color: primaryWhite,
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                  ),
                ),
                SizedBox(height: 4),
                Text(
                  "${user['role'].toUpperCase()} | Exp: ${user['expiredDate']}",
                  style: TextStyle(color: accentGrey, fontSize: 13),
                ),
                SizedBox(height: 2),
                Text(
                  "Parent: ${user['parent'] ?? 'SYSTEM'}",
                  style: TextStyle(color: accentGrey, fontSize: 12),
                ),
              ],
            ),
          ),
          Container(
            decoration: BoxDecoration(
              color: Colors.redAccent.withOpacity(0.1),
              shape: BoxShape.circle,
              border: Border.all(color: Colors.redAccent.withOpacity(0.3)),
            ),
            child: IconButton(
              icon: Icon(Icons.delete_outline, color: Colors.redAccent),
              onPressed: () async {
                final confirm = await showDialog<bool>(
                  context: context,
                  builder: (_) => AlertDialog(
                    backgroundColor: bgDark,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(20),
                      side: BorderSide(color: accentRed.withOpacity(0.3)),
                    ),
                    title: Row(
                      children: [
                        Icon(Icons.info_outline, color: accentRed),
                        const SizedBox(width: 10),
                        Text("Konfirmasi", style: TextStyle(color: primaryWhite)),
                      ],
                    ),
                    content: Text(
                      "Yakin ingin menghapus user '${user['username']}'?",
                      style: TextStyle(color: accentGrey),
                    ),
                    actions: [
                      Container(
                        width: double.infinity,
                        margin: EdgeInsets.symmetric(horizontal: 24),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Container(
                              decoration: BoxDecoration(
                                gradient: redGradient,
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: TextButton(
                                onPressed: () => Navigator.pop(context, false),
                                child: Text("Batal", style: TextStyle(color: primaryWhite, fontWeight: FontWeight.bold)),
                              ),
                            ),
                            Container(
                              decoration: BoxDecoration(
                                gradient: const LinearGradient(colors: [Colors.redAccent, Colors.red]),
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: TextButton(
                                onPressed: () => Navigator.pop(context, true),
                                child: Text("Hapus", style: TextStyle(color: primaryWhite, fontWeight: FontWeight.bold)),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                );
                if (confirm == true) {
                  deleteController.text = user['username'];
                  _deleteUser();
                }
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPagination() {
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: List.generate(totalPages, (index) {
        final page = index + 1;
        return ElevatedButton(
          onPressed: () => setState(() => currentPage = page),
          style: ElevatedButton.styleFrom(
            backgroundColor: currentPage == page ? accentRed : Colors.transparent,
            foregroundColor: currentPage == page ? primaryWhite : accentGrey,
            padding: EdgeInsets.symmetric(horizontal: 16),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(8),
              side: BorderSide(color: borderGlass),
            ),
          ),
          child: Text("$page", style: TextStyle(fontSize: 12)),
        );
      }),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: bgDark,
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [bgDark, primaryRed.withOpacity(0.1), bgDark],
          ),
        ),
        child: SafeArea(
          child: SingleChildScrollView(
            physics: BouncingScrollPhysics(),
            padding: EdgeInsets.symmetric(horizontal: 20, vertical: 20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                Icon(Icons.admin_panel_settings, color: accentRed, size: 50),
                SizedBox(height: 10),
                Text(
                  "ADMIN DASHBOARD",
                  style: TextStyle(
                    color: primaryWhite,
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    fontFamily: 'Orbitron',
                    letterSpacing: 2,
                    shadows: [
                      Shadow(color: primaryRed.withOpacity(0.8), blurRadius: 10),
                    ],
                  ),
                ),
                SizedBox(height: 40),

                // SECTION 1: DELETE USER
                _buildGlassCard(
                  title: "DELETE USER",
                  icon: FontAwesomeIcons.userSlash,
                  children: [
                    _buildInput(
                      label: "Username Target",
                      controller: deleteController,
                      icon: FontAwesomeIcons.user,
                    ),
                    SizedBox(height: 10),
                    Container(
                      height: 50,
                      decoration: BoxDecoration(
                        gradient: const LinearGradient(colors: [Colors.redAccent, Colors.red]),
                        borderRadius: BorderRadius.circular(12),
                        boxShadow: [
                          BoxShadow(color: Colors.red.withOpacity(0.3), blurRadius: 10, offset: Offset(0, 4)),
                        ],
                      ),
                      child: ElevatedButton(
                        onPressed: isLoading ? null : _deleteUser,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.transparent,
                          shadowColor: Colors.transparent,
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        ),
                        child: const Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(Icons.delete, size: 18, color: Colors.white),
                            SizedBox(width: 8),
                            Text("DELETE ACCOUNT", style: TextStyle(fontWeight: FontWeight.bold, letterSpacing: 1)),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),

                // SECTION 2: CREATE ACCOUNT
                _buildGlassCard(
                  title: "CREATE ACCOUNT",
                  icon: FontAwesomeIcons.userPlus,
                  children: [
                    _buildInput(label: "Username", controller: createUsernameController, icon: FontAwesomeIcons.user),
                    _buildInput(label: "Password", controller: createPasswordController, icon: FontAwesomeIcons.lock),
                    _buildInput(label: "Durasi (Hari)", controller: createDayController, icon: FontAwesomeIcons.calendarDay, type: TextInputType.number),
                    Container(
                      padding: EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                      decoration: BoxDecoration(
                        color: Colors.black.withOpacity(0.2),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: borderGlass),
                      ),
                      child: DropdownButtonHideUnderline(
                        child: DropdownButton<String>(
                          value: newUserRole,
                          dropdownColor: bgDark,
                          style: TextStyle(color: primaryWhite),
                          items: roleOptions.map((role) {
                            return DropdownMenuItem(value: role, child: Text(role.toUpperCase()));
                          }).toList(),
                          onChanged: (val) => setState(() => newUserRole = val ?? 'member'),
                        ),
                      ),
                    ),
                    SizedBox(height: 20),
                    Container(
                      height: 50,
                      decoration: BoxDecoration(
                        gradient: redGradient,
                        borderRadius: BorderRadius.circular(12),
                        boxShadow: [
                          BoxShadow(color: primaryRed.withOpacity(0.4), blurRadius: 10, offset: Offset(0, 4)),
                        ],
                      ),
                      child: ElevatedButton(
                        onPressed: isLoading ? null : _createAccount,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.transparent,
                          shadowColor: Colors.transparent,
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        ),
                        child: isLoading
                            ? SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2, color: primaryWhite))
                            : Text("CREATE ACCOUNT", style: TextStyle(color: primaryWhite, fontWeight: FontWeight.bold, letterSpacing: 1)),
                      ),
                    ),
                  ],
                ),

                // SECTION 3: USER LIST
                _buildGlassCard(
                  title: "USER MANAGEMENT",
                  icon: FontAwesomeIcons.users,
                  children: [
                    Container(
                      padding: EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                      decoration: BoxDecoration(
                        color: Colors.black.withOpacity(0.2),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: borderGlass),
                      ),
                      child: DropdownButtonHideUnderline(
                        child: DropdownButton<String>(
                          value: selectedRole,
                          dropdownColor: bgDark,
                          style: TextStyle(color: primaryWhite),
                          items: roleOptions.map((role) {
                            return DropdownMenuItem(value: role, child: Text(role.toUpperCase()));
                          }).toList(),
                          onChanged: (val) {
                            if (val != null) {
                              selectedRole = val;
                              _filterAndPaginate();
                            }
                          },
                        ),
                      ),
                    ),
                    SizedBox(height: 20),
                    isLoading
                        ? Center(child: CircularProgressIndicator(color: accentRed))
                        : Column(
                            children: [
                              ..._getCurrentPageData().map((u) => _buildUserItem(u)).toList(),
                              SizedBox(height: 20),
                              _buildPagination(),
                            ],
                          ),
                  ],
                ),
                SizedBox(height: 30),
              ],
            ),
          ),
        ),
      ),
    );
  }
}