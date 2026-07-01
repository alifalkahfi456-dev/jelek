import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

/// AdminPage — Tampilan biru modern, support penuh, tanpa error build
class AdminPage extends StatefulWidget {
  final String sessionKey;
  final String currentUserRole;

  const AdminPage({
    super.key,
    required this.sessionKey,
    required this.currentUserRole,
  });

  @override
  State<AdminPage> createState() => _AdminPageState();
}

class _AdminPageState extends State<AdminPage>
    with SingleTickerProviderStateMixin {
  // Data
  List<dynamic> fullUserList = [];
  List<dynamic> filteredList = [];
  int currentPage = 1;
  final int itemsPerPage = 10;
  bool isLoading = false;

  // Controllers
  final deleteController = TextEditingController();
  final createUsernameController = TextEditingController();
  final createPasswordController = TextEditingController();
  final createDayController = TextEditingController();

  // Role state
  late String newUserRole;
  late String selectedFilterRole;

  // Animation
  late AnimationController _animController;
  late Animation<double> _fadeAnimation;

  // Warna biru (semua non-konstan, aman)
  final Color navyBlue = const Color(0xFF0A192F);
  final Color darkBlue = const Color(0xFF112240);
  final Color cardBlue = const Color(0xFF1E3A5F);
  final Color accentBlue = const Color(0xFF4B9CD3);
  final Color lightBlue = const Color(0xFF64B5F6);
  final Color cyanAccent = const Color(0xFF00D2FF);
  final Color whiteText = const Color(0xFFE6F1FF);
  final Color greyText = const Color(0xFF8892B0);

  // Role constants
  static const String kAllAkses  = 'all_akses';
  static const String kOwner     = 'owner';
  static const String kModerator = 'moderator';
  static const String kTK        = 'TK';
  static const String kPT        = 'PT';
  static const String kReseller  = 'reseller';
  static const String kFullUp    = 'fullup';
  static const String kMember    = 'member';

  List<String> get creatableRoles {
    switch (widget.currentUserRole) {
      case kAllAkses:
      case kOwner:
        return [kModerator, kTK, kPT, kReseller, kFullUp, kMember];
      case kModerator:
        return [kTK, kPT, kReseller, kFullUp, kMember];
      case kTK:
        return [kPT, kReseller, kFullUp, kMember];
      case kPT:
        return [kReseller, kFullUp, kMember];
      default:
        return [];
    }
  }

  List<String> get filterRoles {
    if (widget.currentUserRole == kAllAkses || widget.currentUserRole == kOwner) {
      return [kAllAkses, kOwner, kModerator, kTK, kPT, kReseller, kFullUp, kMember];
    } else if (widget.currentUserRole == kModerator) {
      return [kModerator, kTK, kPT, kReseller, kFullUp, kMember];
    } else if (widget.currentUserRole == kTK) {
      return [kTK, kPT, kReseller, kFullUp, kMember];
    } else if (widget.currentUserRole == kPT) {
      return [kPT, kReseller, kFullUp, kMember];
    }
    return [];
  }

  bool get hasAdminAccess =>
      [kOwner, kAllAkses, kModerator, kTK, kPT].contains(widget.currentUserRole);

  @override
  void initState() {
    super.initState();
    selectedFilterRole = filterRoles.first;
    newUserRole = creatableRoles.isNotEmpty ? creatableRoles.first : kMember;

    _animController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    )..forward();
    _fadeAnimation = CurvedAnimation(parent: _animController, curve: Curves.easeOut);

    if (!hasAdminAccess) {
      WidgetsBinding.instance.addPostFrameCallback((_) => _showAccessDenied());
    } else {
      _fetchUsers();
    }
  }

  @override
  void dispose() {
    _animController.dispose();
    deleteController.dispose();
    createUsernameController.dispose();
    createPasswordController.dispose();
    createDayController.dispose();
    super.dispose();
  }

  void _showAccessDenied() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => AlertDialog(
        backgroundColor: darkBlue,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Row(children: [
          Icon(Icons.block, color: Colors.red[400]),
          const SizedBox(width: 10),
          const Text('Akses Ditolak', style: TextStyle(color: Colors.white, fontSize: 18)),
        ]),
        content: const Text(
          'Anda tidak memiliki izin mengakses Admin Panel.\n\n'
          'Role yang diizinkan: PT, TK, Moderator, Owner.',
          style: TextStyle(color: Colors.white70),
        ),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.of(context).pop();
              Navigator.of(context).pop();
            },
            child: Text('Kembali', style: TextStyle(color: accentBlue)),
          ),
        ],
      ),
    );
  }

  Future<void> _fetchUsers() async {
    setState(() => isLoading = true);
    try {
      final res = await http.get(Uri.parse(
          'http://saitama.omdhancivok.my.id:2001/listUsers?key=${widget.sessionKey}'));
      if (res.statusCode == 200) {
        final data = jsonDecode(res.body);
        if (data['valid'] == true && data['authorized'] == true) {
          setState(() {
            fullUserList = data['users'] ?? [];
            _applyFilter();
          });
        } else {
          _snack("⚠️ ${data['message'] ?? 'Akses ditolak.'}");
        }
      } else {
        _snack("🌐 Server error: ${res.statusCode}");
      }
    } catch (e) {
      _snack("🌐 Gagal memuat data: $e");
    }
    setState(() => isLoading = false);
  }

  Future<void> _deleteUser() async {
    final username = deleteController.text.trim();
    if (username.isEmpty) {
      _snack("⚠️ Masukkan username!");
      return;
    }

    setState(() => isLoading = true);
    try {
      final res = await http.get(Uri.parse(
          'http://saitama.omdhancivok.my.id:2001/deleteUser?key=${widget.sessionKey}&username=$username'));
      if (res.statusCode == 200) {
        final data = jsonDecode(res.body);
        if (data['deleted'] == true) {
          _snack("✅ User '${data['user']?['username'] ?? username}' dihapus!", ok: true);
          deleteController.clear();
          _fetchUsers();
        } else {
          _snack("❌ ${data['message'] ?? 'Gagal menghapus.'}");
        }
      } else {
        _snack("🌐 Server error: ${res.statusCode}");
      }
    } catch (e) {
      _snack("🌐 Error: $e");
    }
    setState(() => isLoading = false);
  }

  Future<void> _createAccount() async {
    final username = createUsernameController.text.trim();
    final password = createPasswordController.text.trim();
    final day = createDayController.text.trim();

    if (username.isEmpty || password.isEmpty || day.isEmpty) {
      _snack("⚠️ Semua field wajib diisi!");
      return;
    }
    if (int.tryParse(day) == null) {
      _snack("⚠️ Days harus berupa angka!");
      return;
    }
    if (!creatableRoles.contains(newUserRole)) {
      _snack("⛔ Anda tidak berhak membuat akun role '$newUserRole'!");
      return;
    }

    setState(() => isLoading = true);
    try {
      final res = await http.get(Uri.parse(
          'http://saitama.omdhancivok.my.id:2001/userAdd'
          '?key=${widget.sessionKey}'
          '&username=$username'
          '&password=$password'
          '&day=$day'
          '&role=$newUserRole'));
      if (res.statusCode == 200) {
        final data = jsonDecode(res.body);
        if (data['created'] == true) {
          _snack("✅ Akun '${data['user']?['username'] ?? username}' berhasil dibuat!", ok: true);
          createUsernameController.clear();
          createPasswordController.clear();
          createDayController.clear();
          setState(() =>
              newUserRole = creatableRoles.isNotEmpty ? creatableRoles.first : kMember);
          _fetchUsers();
        } else {
          _snack("❌ ${data['message'] ?? 'Gagal membuat akun.'}");
        }
      } else {
        _snack("🌐 Server error: ${res.statusCode}");
      }
    } catch (e) {
      _snack("🌐 Error: $e");
    }
    setState(() => isLoading = false);
  }

  void _applyFilter() {
    setState(() {
      currentPage = 1;
      filteredList = fullUserList.where((u) => u['role'] == selectedFilterRole).toList();
    });
  }

  List<dynamic> get _pageData {
    final start = (currentPage - 1) * itemsPerPage;
    final end = start + itemsPerPage;
    if (start >= filteredList.length) return [];
    return filteredList.sublist(start, end > filteredList.length ? filteredList.length : end);
  }

  int get totalPages => filteredList.isEmpty ? 1 : (filteredList.length / itemsPerPage).ceil();

  void _snack(String msg, {bool ok = false}) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Text(msg, style: const TextStyle(color: Colors.white)),
      backgroundColor: ok ? Colors.green[800] : navyBlue,
      behavior: SnackBarBehavior.floating,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
    ));
  }

  @override
  Widget build(BuildContext context) {
    if (!hasAdminAccess) {
      return Scaffold(
        backgroundColor: navyBlue,
        body: Center(child: Icon(Icons.lock, color: Colors.red[400], size: 60)),
      );
    }

    return Scaffold(
      backgroundColor: navyBlue,
      body: Stack(
        children: [
          // Background decorative
          Positioned(
            top: -80,
            right: -80,
            child: Container(
              width: 250,
              height: 250,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: RadialGradient(colors: [
                  accentBlue.withOpacity(0.15),
                  Colors.transparent,
                ]),
              ),
            ),
          ),
          Positioned(
            bottom: -50,
            left: -50,
            child: Container(
              width: 200,
              height: 200,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: RadialGradient(colors: [
                  cyanAccent.withOpacity(0.1),
                  Colors.transparent,
                ]),
              ),
            ),
          ),
          SafeArea(
            child: FadeTransition(
              opacity: _fadeAnimation,
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(20),
                child: Column(
                  children: [
                    _header(),
                    const SizedBox(height: 25),
                    if (creatableRoles.isNotEmpty) ...[
                      _sectionTitle("Buat User Baru", Icons.person_add),
                      const SizedBox(height: 10),
                      _createCard(),
                      const SizedBox(height: 30),
                      _dangerZone(),
                      const SizedBox(height: 30),
                    ],
                    _sectionTitle("Database Users", Icons.storage),
                    const SizedBox(height: 10),
                    _userListSection(),
                    const SizedBox(height: 20),
                  ],
                ),
              ),
            ),
          ),
          if (isLoading)
            Container(
              color: Colors.black54,
              child: Center(child: CircularProgressIndicator(color: accentBlue)),
            ),
        ],
      ),
    );
  }

  Widget _header() {
    final isAllAkses = widget.currentUserRole == kAllAkses;
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: isAllAkses
              ? [const Color(0xFF0A2F44), navyBlue]
              : [cardBlue, navyBlue],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: (isAllAkses ? cyanAccent : lightBlue).withOpacity(0.2),
            blurRadius: 20,
            offset: const Offset(0, 8),
          )
        ],
        border: Border.all(color: (isAllAkses ? cyanAccent : lightBlue).withOpacity(0.3)),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.black26,
              borderRadius: BorderRadius.circular(18),
              border: Border.all(color: isAllAkses ? cyanAccent : lightBlue),
            ),
            child: Icon(
              isAllAkses ? Icons.verified_user : Icons.admin_panel_settings,
              color: isAllAkses ? cyanAccent : lightBlue,
              size: 32,
            ),
          ),
          const SizedBox(width: 15),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                "ADMIN PANEL",
                style: TextStyle(
                  color: isAllAkses ? cyanAccent : whiteText,
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 1.5,
                ),
              ),
              const SizedBox(height: 4),
              _roleBadge(widget.currentUserRole),
            ],
          ),
        ],
      ),
    );
  }

  Widget _roleBadge(String role) {
    Color c;
    IconData ic;
    String label;
    switch (role) {
      case kAllAkses:
        c = cyanAccent;
        ic = Icons.star;
        label = 'ALL AKSES';
        break;
      case kOwner:
        c = lightBlue;
        ic = Icons.manage_accounts;
        label = 'OWNER';
        break;
      case kModerator:
        c = const Color(0xFFa855f7);
        ic = Icons.shield;
        label = 'MODERATOR';
        break;
      case kTK:
        c = const Color(0xFFf97316);
        ic = Icons.supervised_user_circle;
        label = 'TK';
        break;
      case kPT:
        c = const Color(0xFF22c55e);
        ic = Icons.badge;
        label = 'PT';
        break;
      case kReseller:
        c = const Color(0xFFf59e0b);
        ic = Icons.store;
        label = 'RESELLER';
        break;
      case kFullUp:
        c = const Color(0xFF38bdf8);
        ic = Icons.flash_on;
        label = 'FULL UP';
        break;
      default:
        c = greyText;
        ic = Icons.person;
        label = role.toUpperCase();
    }
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: c.withOpacity(0.15),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: c.withOpacity(0.6)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(ic, color: c, size: 12),
          const SizedBox(width: 4),
          Text(
            label,
            style: TextStyle(color: c, fontSize: 11, fontWeight: FontWeight.bold, letterSpacing: 1),
          ),
        ],
      ),
    );
  }

  Widget _sectionTitle(String title, IconData icon) {
    return Row(
      children: [
        Icon(icon, color: lightBlue, size: 18),
        const SizedBox(width: 8),
        Text(
          title.toUpperCase(),
          style: TextStyle(
            color: lightBlue,
            fontWeight: FontWeight.bold,
            fontSize: 14,
            letterSpacing: 1,
          ),
        ),
        const SizedBox(width: 10),
        Expanded(child: Container(height: 1, color: cardBlue.withOpacity(0.5))),
      ],
    );
  }

  Widget _createCard() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: darkBlue,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: cardBlue),
        boxShadow: [
          BoxShadow(color: Colors.black12, blurRadius: 10, offset: const Offset(0, 4)),
        ],
      ),
      child: Column(
        children: [
          _input(createUsernameController, "Username", Icons.person_outline),
          const SizedBox(height: 15),
          _input(createPasswordController, "Password", Icons.lock_outline),
          const SizedBox(height: 15),
          Row(
            children: [
              Expanded(
                flex: 1,
                child: _input(createDayController, "Days", Icons.calendar_today, isNumber: true),
              ),
              const SizedBox(width: 15),
              Expanded(
                flex: 2,
                child: _dropdown(newUserRole, creatableRoles, (val) => setState(() => newUserRole = val!)),
              ),
            ],
          ),
          const SizedBox(height: 10),
          _permissionInfo(),
          const SizedBox(height: 14),
          _gradientButton("BUAT AKUN", Icons.add_circle, _createAccount),
        ],
      ),
    );
  }

  Widget _permissionInfo() {
    final isAllAkses = widget.currentUserRole == kAllAkses;
    final c = isAllAkses ? cyanAccent : lightBlue;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: c.withOpacity(0.08),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: c.withOpacity(0.3)),
      ),
      child: Row(
        children: [
          Icon(isAllAkses ? Icons.star : Icons.info_outline, color: c, size: 14),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              isAllAkses
                  ? 'All Akses: bisa buat Owner, Reseller1, Reseller, Member'
                  : 'Owner: bisa buat Reseller1, Reseller, Member',
              style: TextStyle(color: c.withOpacity(0.9), fontSize: 11),
            ),
          ),
        ],
      ),
    );
  }

  Widget _dangerZone() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 15),
      decoration: BoxDecoration(
        color: Colors.red.withOpacity(0.05),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.red.withOpacity(0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.warning_amber_rounded, color: Colors.redAccent, size: 20),
              const SizedBox(width: 10),
              Text("Danger Zone",
                  style: TextStyle(color: Colors.redAccent, fontWeight: FontWeight.bold)),
            ],
          ),
          const SizedBox(height: 15),
          Row(
            children: [
              Expanded(
                  child: _input(deleteController, "Username to Delete", Icons.delete_outline)),
              const SizedBox(width: 10),
              Container(
                decoration: BoxDecoration(
                    gradient: LinearGradient(colors: [Colors.red.shade800, Colors.red.shade900]),
                    borderRadius: BorderRadius.circular(15)),
                child: IconButton(
                  onPressed: _deleteUser,
                  icon: const Icon(Icons.delete_forever, color: Colors.white),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _userListSection() {
    return Column(
      children: [
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          decoration: BoxDecoration(
            color: darkBlue,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: cardBlue),
          ),
          child: DropdownButtonHideUnderline(
            child: DropdownButton<String>(
              dropdownColor: darkBlue,
              value: selectedFilterRole,
              isExpanded: true,
              icon: Icon(Icons.filter_list, color: lightBlue),
              items: filterRoles.map((role) {
                return DropdownMenuItem(
                  value: role,
                  child: Row(
                    children: [
                      if (role == kAllAkses)
                        Padding(
                          padding: const EdgeInsets.only(right: 6),
                          child: Icon(Icons.star, color: cyanAccent, size: 14),
                        ),
                      Text(
                        "Filter: ${role.toUpperCase()}",
                        style: TextStyle(
                          color: role == kAllAkses ? cyanAccent : whiteText,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                );
              }).toList(),
              onChanged: (val) {
                setState(() {
                  selectedFilterRole = val!;
                  _applyFilter();
                });
              },
            ),
          ),
        ),
        const SizedBox(height: 15),
        if (filteredList.isEmpty)
          Padding(
            padding: const EdgeInsets.all(30),
            child: Column(
              children: [
                Icon(Icons.person_off, color: greyText, size: 40),
                const SizedBox(height: 10),
                Text("Tidak ada user dengan role '$selectedFilterRole'",
                    style: TextStyle(color: greyText)),
              ],
            ),
          )
        else
          ListView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: _pageData.length,
            itemBuilder: (_, i) => _userItem(_pageData[i]),
          ),
        const SizedBox(height: 20),
        if (totalPages > 1) _pagination(),
      ],
    );
  }

  Widget _userItem(Map user) {
    final role = user['role']?.toString() ?? 'member';
    final isAllAksesU = role == kAllAkses;
    final isOwnerU = role == kOwner;
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: darkBlue,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(
          color: isAllAksesU
              ? cyanAccent.withOpacity(0.4)
              : isOwnerU
                  ? lightBlue.withOpacity(0.3)
                  : cardBlue,
        ),
        boxShadow: [BoxShadow(color: Colors.black26, blurRadius: 6, offset: const Offset(0, 2))],
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: (isAllAksesU ? cyanAccent : lightBlue).withOpacity(0.1),
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: (isAllAksesU ? cyanAccent : lightBlue).withOpacity(0.3)),
            ),
            child: Icon(
              isAllAksesU ? Icons.verified_user : isOwnerU ? Icons.manage_accounts : Icons.person,
              color: isAllAksesU ? cyanAccent : lightBlue,
              size: 20,
            ),
          ),
          const SizedBox(width: 15),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  user['username']?.toString() ?? 'Unknown',
                  style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16),
                ),
                const SizedBox(height: 4),
                Row(
                  children: [
                    _miniBadge(
                      role,
                      isAllAksesU ? cyanAccent : isOwnerU ? lightBlue : Colors.grey,
                    ),
                    const SizedBox(width: 8),
                    _miniBadge("Exp: ${user['expiredDate'] ?? 'N/A'}", greyText),
                  ],
                ),
              ],
            ),
          ),
          IconButton(
            icon: Icon(Icons.delete_outline, color: greyText),
            onPressed: () {
              deleteController.text = user['username']?.toString() ?? '';
              _snack("Tekan tombol hapus di Danger Zone untuk konfirmasi.");
            },
          ),
        ],
      ),
    );
  }

  Widget _pagination() {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: List.generate(totalPages, (i) {
          final page = i + 1;
          final active = currentPage == page;
          return GestureDetector(
            onTap: () => setState(() => currentPage = page),
            child: Container(
              margin: const EdgeInsets.symmetric(horizontal: 4),
              width: 38,
              height: 38,
              decoration: BoxDecoration(
                gradient: active
                    ? LinearGradient(colors: [accentBlue, lightBlue])
                    : null,
                color: active ? null : darkBlue,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: active ? accentBlue : cardBlue),
                boxShadow: active
                    ? [BoxShadow(color: accentBlue.withOpacity(0.4), blurRadius: 8)]
                    : [],
              ),
              child: Center(
                child: Text(
                  "$page",
                  style: TextStyle(
                    color: active ? Colors.white : greyText,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ),
          );
        }),
      ),
    );
  }

  Widget _input(TextEditingController ctrl, String hint, IconData icon,
      {bool isNumber = false}) {
    return Container(
      decoration: BoxDecoration(
        color: navyBlue,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: cardBlue),
      ),
      child: TextField(
        controller: ctrl,
        keyboardType: isNumber ? TextInputType.number : TextInputType.text,
        style: const TextStyle(color: Colors.white),
        cursorColor: accentBlue,
        decoration: InputDecoration(
          hintText: hint,
          hintStyle: TextStyle(color: greyText),
          prefixIcon: Icon(icon, color: lightBlue, size: 20),
          border: InputBorder.none,
          contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
        ),
      ),
    );
  }

  Widget _dropdown(String val, List<String> options, Function(String?) onChanged) {
    final safe = options.contains(val) ? val : (options.isNotEmpty ? options.first : val);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      decoration: BoxDecoration(
        color: navyBlue,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: cardBlue),
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<String>(
          dropdownColor: darkBlue,
          value: safe,
          isExpanded: true,
          icon: Icon(Icons.arrow_drop_down, color: lightBlue),
          items: options
              .map((role) => DropdownMenuItem(
                    value: role,
                    child: Text(role.toUpperCase(),
                        style: const TextStyle(color: Colors.white, fontSize: 13)),
                  ))
              .toList(),
          onChanged: onChanged,
        ),
      ),
    );
  }

  Widget _gradientButton(String text, IconData icon, VoidCallback onTap) {
    return Container(
      width: double.infinity,
      height: 52,
      decoration: BoxDecoration(
        gradient: LinearGradient(colors: [accentBlue, lightBlue]),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(color: accentBlue.withOpacity(0.4), blurRadius: 12, offset: const Offset(0, 4))
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(20),
          onTap: onTap,
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon, color: Colors.white, size: 20),
              const SizedBox(width: 10),
              Text(
                text,
                style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                    letterSpacing: 1),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _miniBadge(String text, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: color.withOpacity(0.15),
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: color.withOpacity(0.4), width: 0.5),
      ),
      child: Text(
        text,
        style: TextStyle(color: color, fontSize: 10, fontWeight: FontWeight.bold),
      ),
    );
  }
}
