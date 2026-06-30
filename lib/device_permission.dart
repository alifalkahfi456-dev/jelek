import 'app_config.dart';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;

// ─── Config ───────────────────────────────────────────────────────────────────


// ─── Permission Store — data disimpan di SERVER, bukan HP lokal ───────────────
class DevicePermissionStore {

  /// Ambil permission user dari server
  static Future<PermissionResult> getFor(String username, String sessionKey) async {
    if (username.toLowerCase() == 'owner') {
      return PermissionResult(approved: true, allDevices: true, devices: []);
    }
    try {
      final res = await http.get(
        Uri.parse('$kBaseUrl/devicePerms?key=$sessionKey&username=${Uri.encodeComponent(username)}'),
      ).timeout(const Duration(seconds: 8));
      if (res.statusCode == 200) {
        final d = jsonDecode(res.body);
        if (d['valid'] == true) {
          return PermissionResult(
            approved: d['approved'] == true,
            allDevices: d['allDevices'] == true,
            devices: List<String>.from(d['devices'] ?? []),
          );
        }
      }
    } catch (e) {
      debugPrint('[DevicePerm] getFor error: $e');
    }
    return PermissionResult(approved: false, allDevices: false, devices: []);
  }

  /// Owner: set permission user ke server
  static Future<bool> setPerm(String ownerKey, String username,
      {required bool approved, required bool allDevices, required List<String> devices}) async {
    try {
      final res = await http.post(
        Uri.parse('$kBaseUrl/setDevicePerm?key=$ownerKey'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'username': username,
          'approved': approved,
          'allDevices': allDevices,
          'devices': devices,
        }),
      ).timeout(const Duration(seconds: 8));
      final d = jsonDecode(res.body);
      return d['valid'] == true;
    } catch (e) {
      debugPrint('[DevicePerm] setPerm error: $e');
      return false;
    }
  }

  /// Owner: hapus permission user
  static Future<bool> removePerm(String ownerKey, String username) async {
    return setPerm(ownerKey, username,
        approved: false, allDevices: false, devices: []);
  }

  /// Owner: ambil semua permission dari server
  static Future<Map<String, dynamic>> getAll(String ownerKey) async {
    try {
      final res = await http.get(
        Uri.parse('$kBaseUrl/listDevicePerms?key=$ownerKey'),
      ).timeout(const Duration(seconds: 8));
      if (res.statusCode == 200) {
        final d = jsonDecode(res.body);
        if (d['valid'] == true) return Map<String, dynamic>.from(d['perms'] ?? {});
      }
    } catch (e) {
      debugPrint('[DevicePerm] getAll error: $e');
    }
    return {};
  }
}

class PermissionResult {
  final bool approved, allDevices;
  final List<String> devices;
  PermissionResult({required this.approved, required this.allDevices, required this.devices});
  bool canSee(String? deviceId) {
    if (!approved) return false;
    if (allDevices) return true;
    return deviceId != null && devices.contains(deviceId);
  }
}

// ─── Colors ───────────────────────────────────────────────────────────────────
class _C {
  static const bg      = Color(0xFF020818);
  static const s1      = Color(0xFF040F22);
  static const s2      = Color(0xFF051525);
  static const border  = Color(0xFF5C0000);
  static const accent  = Color(0xFF1565C0);
  static const accentL = Color(0xFF42A5F5);
  static const green   = Color(0xFF4CAF50);
  static const red     = Color(0xFF2979FF);
  static const textP   = Color(0xFFFFF0F5);
  static const textS   = Color(0xFFBBDEFB);
  static const textM   = Color(0xFF0A2472);
  static const white   = Color(0xFFFFFFFF);
}

// ─── Owner Permission Manager ─────────────────────────────────────────────────
class DevicePermissionManagerPage extends StatefulWidget {
  final String sessionKey;
  final List<dynamic> allDevices;
  const DevicePermissionManagerPage({
    super.key, required this.sessionKey, required this.allDevices});
  @override State<DevicePermissionManagerPage> createState() => _DPMState();
}

class _DPMState extends State<DevicePermissionManagerPage> {
  Map<String, dynamic> _perms = {};
  String _selectedUser = '';
  final _inputCtrl = TextEditingController();
  String _inputVal = '';
  bool _loading = true;
  bool _saving = false;

  @override void initState() { super.initState(); _load(); }
  @override void dispose() { _inputCtrl.dispose(); super.dispose(); }

  Future<void> _load() async {
    setState(() => _loading = true);
    final data = await DevicePermissionStore.getAll(widget.sessionKey);
    setState(() { _perms = data; _loading = false; });
  }

  List<String> get _users => _perms.keys.toList();
  bool _approved(String u) => _perms[u]?['approved'] == true;
  bool _hasAll(String u) => _perms[u]?['allDevices'] == true;
  List<String> _devices(String u) => List<String>.from(_perms[u]?['devices'] ?? []);

  Future<void> _addUser(String username) async {
    if (username.trim().isEmpty) return;
    final key = username.trim().toLowerCase();
    final ok = await DevicePermissionStore.setPerm(
      widget.sessionKey, key,
      approved: true, allDevices: true, devices: [],
    );
    if (ok) {
      await _load();
      setState(() { _selectedUser = key; _inputVal = ''; _inputCtrl.clear(); });
    }
  }

  Future<void> _update(String u, {bool? approved, bool? allDevices, List<String>? devices}) async {
    setState(() => _saving = true);
    final ok = await DevicePermissionStore.setPerm(
      widget.sessionKey, u,
      approved: approved ?? _approved(u),
      allDevices: allDevices ?? _hasAll(u),
      devices: devices ?? _devices(u),
    );
    if (ok) await _load();
    setState(() => _saving = false);
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    backgroundColor: _C.bg,
    appBar: AppBar(
      backgroundColor: _C.s1,
      elevation: 0,
      title: Text('Kelola Akses Device', style: TextStyle(color: _C.textP, fontSize: 15, fontWeight: FontWeight.bold)),
      iconTheme: IconThemeData(color: _C.accentL),
      actions: [
        if (_saving) const Padding(padding: EdgeInsets.only(right: 16),
          child: SizedBox(width: 18, height: 18, child: CircularProgressIndicator(color: _C.accentL, strokeWidth: 2))),
      ],
      bottom: PreferredSize(preferredSize: Size.fromHeight(1), child: Container(height: 1, color: _C.border)),
    ),
    body: _loading
        ? Center(child: CircularProgressIndicator(color: _C.accentL))
        : Column(children: [
      // ─ Add user ──────────────────────────────────────────────────────
      Padding(padding: const EdgeInsets.all(14), child: Row(children: [
        Expanded(child: Container(
          decoration: BoxDecoration(color: _C.s1, borderRadius: BorderRadius.circular(10), border: Border.all(color: _C.border)),
          child: TextField(
            controller: _inputCtrl,
            onChanged: (v) => setState(() => _inputVal = v),
            style: TextStyle(color: _C.textP, fontSize: 13),
            decoration: InputDecoration(hintText: 'Ketik username...', hintStyle: TextStyle(color: _C.textM),
              prefixIcon: Icon(Icons.person_rounded, color: _C.textS, size: 18),
              border: InputBorder.none, contentPadding: EdgeInsets.symmetric(vertical: 11, horizontal: 4)),
          ),
        )),
        const SizedBox(width: 10),
        GestureDetector(
          onTap: () => _addUser(_inputVal),
          child: Container(padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 11),
            decoration: BoxDecoration(color: _C.accent, borderRadius: BorderRadius.circular(10)),
            child: Text('Tambah', style: TextStyle(color: _C.white, fontSize: 13, fontWeight: FontWeight.bold))),
        ),
      ])),

      if (_users.isEmpty)
        Expanded(child: Center(child: Column(mainAxisSize: MainAxisSize.min, children: [
          Icon(Icons.group_off_rounded, color: _C.textM, size: 48),
          const SizedBox(height: 12),
          Text('Belum ada user ditambahkan', style: TextStyle(color: _C.textS)),
          const SizedBox(height: 6),
          Text('Ketik username untuk memberi akses', style: TextStyle(color: _C.textM, fontSize: 11)),
        ])))
      else
        Expanded(child: SingleChildScrollView(padding: const EdgeInsets.fromLTRB(14, 0, 14, 20), child: Column(
          crossAxisAlignment: CrossAxisAlignment.start, children: [
          // User chips
          Text('Pilih User:', style: TextStyle(color: _C.textS, fontSize: 11, letterSpacing: 1)),
          const SizedBox(height: 8),
          Wrap(spacing: 8, runSpacing: 8, children: _users.map((u) {
            final active = u == _selectedUser;
            final appr = _approved(u);
            return GestureDetector(
              onTap: () => setState(() => _selectedUser = u),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
                decoration: BoxDecoration(
                  color: active ? _C.accent : _C.s2,
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: active ? _C.accentL : (appr ? _C.accent.withOpacity(0.4) : _C.border))),
                child: Row(mainAxisSize: MainAxisSize.min, children: [
                  CircleAvatar(radius: 3.5, backgroundColor: appr ? Colors.greenAccent : Colors.pinkAccent),
                  const SizedBox(width: 6),
                  Text(u, style: TextStyle(color: active ? _C.white : _C.textS, fontSize: 12, fontWeight: FontWeight.bold)),
                ]),
              ),
            );
          }).toList()),

          if (_selectedUser.isNotEmpty) ...[
            const SizedBox(height: 16),
            Container(padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(color: _C.s1, borderRadius: BorderRadius.circular(14), border: Border.all(color: _C.border)),
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                // Header + hapus
                Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
                  Row(children: [
                    Icon(Icons.person_rounded, color: _C.accentL, size: 16),
                    const SizedBox(width: 8),
                    Text(_selectedUser, style: TextStyle(color: _C.textP, fontWeight: FontWeight.bold, fontSize: 15)),
                  ]),
                  GestureDetector(
                    onTap: () async {
                      await DevicePermissionStore.removePerm(widget.sessionKey, _selectedUser);
                      setState(() => _selectedUser = '');
                      await _load();
                    },
                    child: Container(padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                      decoration: BoxDecoration(color: Colors.pinkAccent.withOpacity(0.1), borderRadius: BorderRadius.circular(8), border: Border.all(color: Colors.pinkAccent.withOpacity(0.3))),
                      child: const Text('Hapus', style: TextStyle(color: Colors.pinkAccent, fontSize: 11))),
                  ),
                ]),
                Divider(color: _C.border, height: 20),
                // Toggle approve
                Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
                  Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                    Text('Setujui Akses', style: TextStyle(color: _C.textP, fontSize: 13)),
                    Text(_approved(_selectedUser) ? 'User dapat akses sadap device' : 'Akses ditolak',
                      style: TextStyle(color: _approved(_selectedUser) ? Colors.greenAccent : Colors.pinkAccent, fontSize: 11)),
                  ]),
                  Switch(value: _approved(_selectedUser), activeColor: _C.accentL,
                    onChanged: (v) => _update(_selectedUser, approved: v)),
                ]),
                // Akses Semua Device otomatis saat approved
              ])),

            // Device checklist
            if (_approved(_selectedUser) && !_hasAll(_selectedUser)) ...[
              const SizedBox(height: 12),
              Container(padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(color: _C.s1, borderRadius: BorderRadius.circular(14), border: Border.all(color: _C.border)),
                child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Row(children: [
                    Text('Pilih Device', style: TextStyle(color: _C.textS, fontSize: 11, letterSpacing: 1)),
                    const Spacer(),
                    Text('${_devices(_selectedUser).length} dipilih', style: TextStyle(color: _C.accentL, fontSize: 11)),
                  ]),
                  const SizedBox(height: 10),
                  if (widget.allDevices.isEmpty)
                    const Center(child: Padding(padding: EdgeInsets.symmetric(vertical: 16),
                      child: Text('Belum ada device', style: TextStyle(color: _C.textM))))
                  else
                    ...widget.allDevices.map((d) {
                      final id = d['id']?.toString() ?? '';
                      final model = d['model']?.toString() ?? 'Unknown';
                      final ip = d['ip']?.toString() ?? '-';
                      final allowed = _devices(_selectedUser).contains(id);
                      return Container(margin: const EdgeInsets.only(bottom: 8),
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                        decoration: BoxDecoration(
                          color: allowed ? _C.accent.withOpacity(0.1) : _C.s2,
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(color: allowed ? _C.accentL.withOpacity(0.4) : _C.border)),
                        child: Row(children: [
                          Icon(Icons.phone_android_rounded, color: allowed ? _C.accentL : _C.textS, size: 16),
                          const SizedBox(width: 10),
                          Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                            Text(model, style: TextStyle(color: allowed ? _C.textP : _C.textS, fontSize: 13, fontWeight: FontWeight.bold)),
                            Text('ID: $id  •  IP: $ip', style: TextStyle(color: _C.textM, fontSize: 10)),
                          ])),
                          Checkbox(
                            value: allowed, activeColor: _C.accentL, checkColor: _C.bg,
                            side: BorderSide(color: _C.border),
                            onChanged: (v) async {
                              final cur = List<String>.from(_devices(_selectedUser));
                              if (v == true) { if (!cur.contains(id)) cur.add(id); }
                              else cur.remove(id);
                              await _update(_selectedUser, devices: cur);
                            }),
                        ]));
                    }).toList(),
                ])),
            ],
          ],
        ]))),
    ]),
  );
}
