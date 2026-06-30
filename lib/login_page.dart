import 'app_config.dart';
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:url_launcher/url_launcher.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:device_info_plus/device_info_plus.dart';
import 'dashboard_page.dart';
import 'splash.dart';

class LoginPage extends StatefulWidget {
  const LoginPage({super.key});
  @override State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> with SingleTickerProviderStateMixin {
  final _userCtrl = TextEditingController();
  final _passCtrl = TextEditingController();
  final _formKey  = GlobalKey<FormState>();
  bool _loading = false;
  bool _obscure = true;
  String? _androidId;

  late AnimationController _animCtrl;
  late Animation<double>   _fadeAnim;
  late Animation<Offset>   _slideAnim;

  // ── TEMA HITAM PREMIUM ────────────────────────────────────────────────────
  static const _bg      = Color(0xFF000000);
  static const _card    = Color(0xFF020A18);
  static const _field   = Color(0xFF040F22);
  static const _brd     = Color(0xFF1E1E1E);
  static const _acc     = Color(0xFF1565C0);
  static const _accL    = Color(0xFF42A5F5);
  static const _txt     = Color(0xFFFFFFFF);
  static const _sub     = Color(0xFF555555);
  static const _label   = Color(0xFFCCCCCC);

  @override
  void initState() {
    super.initState();
    _animCtrl = AnimationController(vsync: this, duration: const Duration(milliseconds: 700))..forward();
    _fadeAnim  = CurvedAnimation(parent: _animCtrl, curve: Curves.easeOut);
    _slideAnim = Tween<Offset>(begin: const Offset(0, 0.12), end: Offset.zero)
        .animate(CurvedAnimation(parent: _animCtrl, curve: Curves.easeOutCubic));
    _initLogin();
  }

  @override
  void dispose() { _animCtrl.dispose(); _userCtrl.dispose(); _passCtrl.dispose(); super.dispose(); }

  Future<String> _getAndroidId() async {
    try {
      final di = DeviceInfoPlugin();
      final a = await di.androidInfo;
      return '${a.brand}-${a.model}-${a.id}'.replaceAll(' ', '_');
    } catch (_) { return 'unknown_device'; }
  }

  Future<void> _initLogin() async {
    _androidId = await _getAndroidId();
    final prefs = await SharedPreferences.getInstance();
    final u = prefs.getString('username');
    final p = prefs.getString('password');
    final k = prefs.getString('key');
    if (u != null && p != null && k != null) {
      try {
        final res = await http.get(Uri.parse('$kBaseUrl/myInfo?username=$u&password=$p&androidId=$_androidId&key=$k'))
            .timeout(const Duration(seconds: 10));
        final d = jsonDecode(res.body);
        if (d['valid'] == true && mounted) _navSplash(d);
      } catch (_) {}
    }
  }

  Future<void> _login() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _loading = true);
    try {
      final res = await http.post(Uri.parse('$kBaseUrl/validate'),
        headers: {'Content-Type': 'application/x-www-form-urlencoded'},
        body: {'username': _userCtrl.text.trim(), 'password': _passCtrl.text.trim(), 'androidId': _androidId ?? 'unknown'},
      ).timeout(const Duration(seconds: 15));
      final d = jsonDecode(res.body);
      if (!mounted) return;
      if (d['expired'] == true) {
        _snack('Akses kamu sudah habis. Hubungi admin.', Colors.orange);
      } else if (d['valid'] != true) {
        _snack('Username atau password salah.', _acc);
      } else {
        final prefs = await SharedPreferences.getInstance();
        prefs.setString('username', _userCtrl.text.trim());
        prefs.setString('password', _passCtrl.text.trim());
        prefs.setString('key', d['key'] ?? '');
        _navSplash(d);
      }
    } catch (e) {
      _snack(e.toString().contains('timeout') ? 'Server timeout.' : 'Gagal konek ke server.', Colors.orange);
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  void _navSplash(Map d) {
    Navigator.pushReplacement(context, MaterialPageRoute(builder: (_) => SplashScreen(
      username: d['username'] ?? '', password: d['password'] ?? '',
      role: d['role'] ?? 'member', sessionKey: d['key'] ?? '',
      expiredDate: d['expiredDate'] ?? '',
      listBug:  List<Map<String,dynamic>>.from((d['listBug']  ?? []).map((e) => Map<String,dynamic>.from(e is Map ? e : {}))),
      listDoos: List<Map<String,dynamic>>.from((d['listDoos'] ?? []).map((e) => Map<String,dynamic>.from(e is Map ? e : {}))),
      news: List<dynamic>.from(d['news'] ?? []),
    )));
  }

  void _snack(String msg, Color c) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      backgroundColor: c, behavior: SnackBarBehavior.floating,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      content: Text(msg, style: TextStyle(color: Colors.white, fontWeight: FontWeight.w600))));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _bg,
      body: Stack(children: [
        // Background: pure black + subtle red glow top
        Positioned(top: -80, left: MediaQuery.of(context).size.width / 2 - 120,
          child: Container(width: 240, height: 240,
            decoration: BoxDecoration(shape: BoxShape.circle,
              gradient: RadialGradient(colors: [_acc.withOpacity(0.12), Colors.transparent])))),

        SafeArea(child: FadeTransition(opacity: _fadeAnim, child: SlideTransition(position: _slideAnim,
          child: SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(28, 60, 28, 40),
            child: Form(key: _formKey, child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              // ── Logo / Title ────────────────────────────────────────────
              Row(children: [
                Container(width: 44, height: 44,
                  decoration: BoxDecoration(
                    gradient: LinearGradient(colors: [_acc, Color(0xFF0A2472)]),
                    borderRadius: BorderRadius.circular(12)),
                  child: const Icon(Icons.security_rounded, color: Colors.white, size: 22)),
                const SizedBox(width: 14),
                Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  const Text('CHAN XITER', style: TextStyle(
                    color: Colors.white, fontSize: 26, fontWeight: FontWeight.w900,
                    fontFamily: 'Orbitron', letterSpacing: 2,
                    shadows: [Shadow(color: Color(0xAAFF1744), blurRadius: 12)])),
                  Text('SYSTEM GATEWAY', style: TextStyle(
                    color: _acc.withOpacity(0.7), fontSize: 9, letterSpacing: 3, fontWeight: FontWeight.w600)),
                ]),
              ]),
              const SizedBox(height: 10),
              Text('Otentikasi kredensial untuk melanjutkan.',
                style: TextStyle(color: _sub, fontSize: 12, height: 1.5)),
              const SizedBox(height: 48),

              // ── Form card ────────────────────────────────────────────────
              Container(
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(
                  color: _card,
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: _brd, width: 0.5),
                  boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.8), blurRadius: 30, offset: Offset(0, 10))],
                ),
                child: Column(children: [
                  // Username
                  TextFormField(
                    controller: _userCtrl,
                    style: TextStyle(color: _txt, fontSize: 14, fontWeight: FontWeight.w500),
                    validator: (v) => v == null || v.isEmpty ? 'Masukkan username' : null,
                    decoration: InputDecoration(
                      labelText: 'Username',
                      labelStyle: TextStyle(color: _sub, fontSize: 12),
                      prefixIcon: const Icon(Icons.person_outline_rounded, color: _acc, size: 20),
                      filled: true, fillColor: _field,
                      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: _brd)),
                      enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: _brd, width: 0.5)),
                      focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: _acc, width: 1.5)),
                      errorBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: Colors.redAccent)),
                      focusedErrorBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: Colors.redAccent)),
                      errorStyle: TextStyle(color: Colors.redAccent, fontSize: 10),
                    )),
                  const SizedBox(height: 14),
                  // Password
                  TextFormField(
                    controller: _passCtrl,
                    obscureText: _obscure,
                    style: TextStyle(color: _txt, fontSize: 14, fontWeight: FontWeight.w500),
                    validator: (v) => v == null || v.isEmpty ? 'Masukkan password' : null,
                    decoration: InputDecoration(
                      labelText: 'Password',
                      labelStyle: TextStyle(color: _sub, fontSize: 12),
                      prefixIcon: const Icon(Icons.lock_outline_rounded, color: _acc, size: 20),
                      suffixIcon: GestureDetector(
                        onTap: () => setState(() => _obscure = !_obscure),
                        child: Icon(_obscure ? Icons.visibility_off_outlined : Icons.visibility_outlined, color: _sub, size: 20)),
                      filled: true, fillColor: _field,
                      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: _brd)),
                      enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: _brd, width: 0.5)),
                      focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: _acc, width: 1.5)),
                      errorBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: Colors.redAccent)),
                      focusedErrorBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: Colors.redAccent)),
                      errorStyle: TextStyle(color: Colors.redAccent, fontSize: 10),
                    )),
                  const SizedBox(height: 24),
                  // Login button
                  SizedBox(width: double.infinity, height: 52,
                    child: ElevatedButton(
                      onPressed: _loading ? null : _login,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.transparent, shadowColor: Colors.transparent,
                        padding: EdgeInsets.zero,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14))),
                      child: Ink(
                        decoration: BoxDecoration(
                          gradient: _loading
                            ? LinearGradient(colors: [Color(0xFF051525), Color(0xFF051525)])
                            : LinearGradient(colors: [Color(0xFF1565C0), Color(0xFF0A2472)], begin: Alignment.centerLeft, end: Alignment.centerRight),
                          borderRadius: BorderRadius.circular(14),
                          boxShadow: _loading ? [] : [BoxShadow(color: _acc.withOpacity(0.35), blurRadius: 18, offset: Offset(0, 6))]),
                        child: Center(child: _loading
                          ? const SizedBox(width: 22, height: 22, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2.5))
                          : const Row(mainAxisSize: MainAxisSize.min, children: [
                              Icon(Icons.fingerprint_rounded, color: Colors.white, size: 20),
                              SizedBox(width: 10),
                              Text('AUTHORIZE', style: TextStyle(
                                color: Colors.white, fontSize: 14, fontWeight: FontWeight.w900, letterSpacing: 2,
                                shadows: [Shadow(color: Colors.black54, blurRadius: 4)])),
                            ])),
                      ))),
                ]),
              ),
              const SizedBox(height: 28),
              Center(child: GestureDetector(
                onTap: () => launchUrl(Uri.parse('https://t.me/pemxx08'), mode: LaunchMode.externalApplication),
                child: RichText(text: TextSpan(children: [
                  TextSpan(text: 'Belum punya lisensi? ', style: TextStyle(color: _sub, fontSize: 12)),
                  TextSpan(text: 'Beli Disini', style: TextStyle(
                    color: _accL, fontSize: 12, fontWeight: FontWeight.bold,
                    decoration: TextDecoration.underline, decorationColor: _accL)),
                ])))),
            ])),
          ),
        ))),
      ]),
    );
  }
}
