import 'dart:async';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;

const _kBase = 'http://xterclose.zorryxhostz.my.id:2000';

// ─── Colors ──────────────────────────────────────────────────────────────────
class _C {
  static const bg      = Color(0xFF120000);
  static const s1      = Color(0xFF2A0000);
  static const s2      = Color(0xFF3D0000);
  static const border  = Color(0xFF5C0000);
  static const accent  = Color(0xFFE53935);
  static const accentL = Color(0xFFFF5252);
  static const green   = Color(0xFF4CAF50);
  static const red     = Color(0xFFFF1744);
  static const textP   = Color(0xFFFFF0F5);
  static const textS   = Color(0xFFFFCDD2);
  static const textM   = Color(0xFF8B0000);
  static const white   = Color(0xFFFFFFFF);
}

class BugSenderPage extends StatefulWidget {
  final String sessionKey;
  final String username;
  final String role;

  const BugSenderPage({
    super.key,
    required this.sessionKey,
    required this.username,
    required this.role,
  });

  @override
  State<BugSenderPage> createState() => _BugSenderPageState();
}

class _BugSenderPageState extends State<BugSenderPage>
    with SingleTickerProviderStateMixin {
  late TabController _tab;

  bool get _isOwner => widget.role.toLowerCase() == 'owner';
  bool get _isVip   => widget.role.toLowerCase() == 'vip';
  bool get _canUsePublic => _isOwner || _isVip;

  // ─ Sender data ─────────────────────────────────────────────
  List<dynamic> _privateSenders = [];
  List<dynamic> _publicSenders  = [];
  bool _loadingPrivate = true;
  bool _loadingPublic  = true;
  String? _errPrivate;
  String? _errPublic;

  // ─ Add sender ──────────────────────────────────────────────
  final _numCtrl = TextEditingController();
  bool _addingPrivate = false;
  String? _pairingCode;

  // ─ Delete ──────────────────────────────────────────────────
  String? _deleting;

  Timer? _publicRefreshTimer;

  @override
  void initState() {
    super.initState();
    _tab = TabController(length: 2, vsync: this);
    _fetchPrivate();
    _fetchPublic();
    // Auto refresh public senders setiap 10 detik
    _publicRefreshTimer = Timer.periodic(const Duration(seconds: 10), (_) => _fetchPublic());
  }

  @override
  void dispose() {
    _tab.dispose();
    _numCtrl.dispose();
    _publicRefreshTimer?.cancel();
    super.dispose();
  }

  // ─── Fetch ─────────────────────────────────────────────────
  Future<void> _fetchPrivate() async {
    setState(() { _loadingPrivate = true; _errPrivate = null; });
    try {
      final res = await http.get(
        Uri.parse('$_kBase/mySender?key=${widget.sessionKey}'),
      ).timeout(const Duration(seconds: 10));
      final d = jsonDecode(res.body);
      if (d['valid'] == true) {
        final conn = d['connections'];
        setState(() {
          if (conn is Map) {
            _privateSenders = List<dynamic>.from(conn['private'] ?? []);
          } else if (conn is List) {
            _privateSenders = List<dynamic>.from(conn);
          } else {
            _privateSenders = [];
          }
          _loadingPrivate = false;
        });
      } else {
        setState(() { _errPrivate = d['error'] ?? 'Gagal'; _loadingPrivate = false; });
      }
    } catch (e) {
      setState(() { _errPrivate = e.toString(); _loadingPrivate = false; });
    }
  }

  Future<void> _fetchPublic() async {
    setState(() { _loadingPublic = true; _errPublic = null; });
    try {
      final res = await http.get(
        Uri.parse('$_kBase/getPublicSenders?key=${widget.sessionKey}'),
      ).timeout(const Duration(seconds: 10));
      final d = jsonDecode(res.body);
      if (d['valid'] == true) {
        setState(() {
          _publicSenders = List<dynamic>.from(d['senders'] ?? []);
          _loadingPublic = false;
        });
      } else {
        setState(() { _errPublic = d['message'] ?? 'Gagal'; _loadingPublic = false; });
      }
    } catch (e) {
      setState(() { _errPublic = e.toString(); _loadingPublic = false; });
    }
  }

  // ─── Add Private Sender ────────────────────────────────────
  Future<void> _addPrivate() async {
    final num = _numCtrl.text.trim().replaceAll(RegExp(r'\D'), '');
    if (num.isEmpty) { _snack('Masukkan nomor WA dulu!', true); return; }
    setState(() { _addingPrivate = true; _pairingCode = null; });
    try {
      final res = await http.get(
        Uri.parse('$_kBase/getPairing?key=${widget.sessionKey}&number=$num'),
      ).timeout(const Duration(seconds: 20));
      final d = jsonDecode(res.body);
      if (d['valid'] == true) {
        setState(() => _pairingCode = d['pairingCode']?.toString() ?? '-');
        _numCtrl.clear();
        await Future.delayed(const Duration(seconds: 30));
        _fetchPrivate();
      } else {
        _snack(d['message'] ?? 'Gagal generate pairing code', true);
      }
    } catch (e) {
      _snack('Error: $e', true);
    }
    setState(() => _addingPrivate = false);
  }

  // ─── Delete ────────────────────────────────────────────────
  Future<void> _deletePrivate(String sessionName) async {
    setState(() => _deleting = sessionName);
    try {
      final res = await http.get(
        Uri.parse('$_kBase/deleteSender?key=${widget.sessionKey}&session=$sessionName'),
      ).timeout(const Duration(seconds: 10));
      final d = jsonDecode(res.body);
      if (d['valid'] == true) {
        _snack('Sender dihapus', false);
        _fetchPrivate();
      } else {
        _snack(d['message'] ?? 'Gagal hapus', true);
      }
    } catch (e) {
      _snack('Error: $e', true);
    }
    setState(() => _deleting = null);
  }

  Future<void> _deletePublic(String sessionName) async {
    setState(() => _deleting = sessionName);
    try {
      final res = await http.get(
        Uri.parse('$_kBase/deletePublicSender?key=${widget.sessionKey}&session=$sessionName'),
      ).timeout(const Duration(seconds: 10));
      final d = jsonDecode(res.body);
      if (d['valid'] == true) {
        _snack('Public sender dihapus', false);
        _fetchPublic();
      } else {
        _snack(d['message'] ?? 'Gagal hapus', true);
      }
    } catch (e) {
      _snack('Error: $e', true);
    }
    setState(() => _deleting = null);
  }

  // ─── Toggle Public ─────────────────────────────────────────
  Future<void> _togglePublic(String sessionName, bool makePublic) async {
    try {
      final res = await http.get(
        Uri.parse('$_kBase/setSenderPublic?key=${widget.sessionKey}&session=$sessionName&public=$makePublic'),
      ).timeout(const Duration(seconds: 10));
      final d = jsonDecode(res.body);
      _snack(d['message'] ?? (makePublic ? 'Dijadikan public' : 'Dijadikan private'), !d['valid']);
      _fetchPrivate();
      _fetchPublic();
    } catch (e) {
      _snack('Error: $e', true);
    }
  }

  void _snack(String msg, bool isErr) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Text(msg, style: const TextStyle(color: _C.white)),
      backgroundColor: isErr ? _C.red : _C.green,
      behavior: SnackBarBehavior.floating,
      duration: const Duration(seconds: 3),
    ));
  }

  // ─── BUILD ─────────────────────────────────────────────────
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF1A0015),
      appBar: AppBar(
        backgroundColor: _C.s1,
        elevation: 0,
        title: Row(children: [
          const Icon(Icons.router_rounded, color: _C.accentL, size: 18),
          const SizedBox(width: 8),
          const Text('Manage Sender', style: TextStyle(color: _C.textP, fontSize: 15, fontWeight: FontWeight.bold)),
        ]),
        iconTheme: const IconThemeData(color: _C.accentL),
        actions: [
          // Stats chip owner
          if (_isOwner)
            Padding(padding: const EdgeInsets.only(right: 14), child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Row(children: [
                  _badge('${_privateSenders.length}', _C.accent),
                  const SizedBox(width: 6),
                  _badge('${_publicSenders.length}', _C.green),
                ]),
              ],
            )),
        ],
        bottom: TabBar(
          controller: _tab,
          indicatorColor: _C.red,
          labelColor: _C.accentL,
          unselectedLabelColor: _C.textS,
          tabs: const [
            Tab(icon: Icon(Icons.lock_rounded, size: 16), text: 'Private'),
            Tab(icon: Icon(Icons.public_rounded, size: 16), text: 'Public'),
          ],
        ),

      ),
      body: TabBarView(controller: _tab, children: [
              _buildPrivateTab(),
              _buildPublicTab(),
            ]),
      floatingActionButton: FloatingActionButton.extended(
        backgroundColor: _C.accent,
        icon: _addingPrivate
            ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(color: _C.white, strokeWidth: 2))
            : const Icon(Icons.add_rounded, color: _C.white),
        label: const Text('Tambah Sender', style: TextStyle(color: _C.white, fontWeight: FontWeight.bold)),
        onPressed: _addingPrivate ? null : _showAddDialog,
      ),
    );
  }

  // ─── Private Tab ───────────────────────────────────────────
  Widget _buildPrivateTab() {
    return Column(children: [
      // Pairing code display
      if (_pairingCode != null)
        Container(
          margin: const EdgeInsets.all(14),
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: _C.accent.withOpacity(0.15),
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: _C.accentL.withOpacity(0.5)),
          ),
          child: Column(children: [
            const Text('PAIRING CODE', style: TextStyle(color: _C.accentL, fontSize: 11, letterSpacing: 2, fontWeight: FontWeight.bold)),
            const SizedBox(height: 10),
            Text(_pairingCode!, style: const TextStyle(color: _C.white, fontSize: 28, fontWeight: FontWeight.w900, letterSpacing: 6)),
            const SizedBox(height: 8),
            const Text('Masukkan kode ini di WhatsApp → Perangkat Tertaut → Tautkan dengan nomor telepon', style: TextStyle(color: _C.textS, fontSize: 11), textAlign: TextAlign.center),
            const SizedBox(height: 10),
            GestureDetector(
              onTap: () => setState(() => _pairingCode = null),
              child: const Text('Tutup', style: TextStyle(color: _C.red, fontSize: 12)),
            ),
          ]),
        ),

      // Summary
      Padding(padding: const EdgeInsets.fromLTRB(14, 10, 14, 4), child: Row(children: [
        _badge('${_privateSenders.length} Private Sender', _C.accent),
        const Spacer(),
        GestureDetector(
          onTap: () { setState(() => _loadingPrivate = true); _fetchPrivate(); },
          child: const Icon(Icons.refresh_rounded, color: _C.accentL, size: 18)),
      ])),

      Expanded(child: _loadingPrivate
          ? const Center(child: CircularProgressIndicator(color: _C.accentL))
          : _errPrivate != null
              ? _errorWidget(_errPrivate!, _fetchPrivate)
              : _privateSenders.isEmpty
                  ? _emptyWidget('Belum ada private sender', Icons.lock_outlined)
                  : ListView.separated(
                      padding: const EdgeInsets.fromLTRB(14, 6, 14, 100),
                      itemCount: _privateSenders.length,
                      separatorBuilder: (_, __) => const SizedBox(height: 8),
                      itemBuilder: (_, i) {
                        final s = _privateSenders[i];
                        return _senderCard(s, isPublic: false);
                      })),
    ]);
  }

  // ─── Public Tab (Owner + VIP only) ─────────────────────────
  Widget _buildPublicTab() {
    // Tampilkan pesan akses khusus untuk role selain owner/vip
    if (!_canUsePublic) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Column(mainAxisSize: MainAxisSize.min, children: [
            Container(
              padding: const EdgeInsets.all(18),
              decoration: BoxDecoration(
                color: const Color(0xFFF06292).withOpacity(0.1),
                shape: BoxShape.circle,
                border: Border.all(color: const Color(0xFFF06292).withOpacity(0.3)),
              ),
              child: const Icon(Icons.lock_rounded, color: Color(0xFFF06292), size: 42),
            ),
            const SizedBox(height: 20),
            const Text('Akses Terbatas', style: TextStyle(color: Color(0xFFFFF0F5), fontSize: 18, fontWeight: FontWeight.bold)),
            const SizedBox(height: 10),
            const Text(
              'Fitur Public Sender hanya tersedia\nuntuk akun Owner dan VIP.',
              style: TextStyle(color: Color(0xFFA48888), fontSize: 13, height: 1.6),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 20),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 10),
              decoration: BoxDecoration(
                color: const Color(0xFFF06292).withOpacity(0.08),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: const Color(0xFFF06292).withOpacity(0.3)),
              ),
              child: const Text('Hubungi reseller untuk upgrade akun',
                style: TextStyle(color: Color(0xFFFF5252), fontSize: 12)),
            ),
          ]),
        ),
      );
    }

    return Column(children: [
      // Info banner
      Container(
        margin: const EdgeInsets.all(14),
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: _C.green.withOpacity(0.08),
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: _C.green.withOpacity(0.3)),
        ),
        child: const Row(children: [
          Icon(Icons.info_rounded, color: Color(0xFF00C853), size: 16),
          SizedBox(width: 8),
          Expanded(child: Text(
            'Sender public bisa dipakai semua user untuk kirim bug. Toggle dari private sender ke sini.',
            style: TextStyle(color: Color(0xFF00C853), fontSize: 11),
          )),
        ]),
      ),

      Padding(padding: const EdgeInsets.fromLTRB(14, 0, 14, 4), child: Row(children: [
        _badge('${_publicSenders.length} Public Sender', _C.green),
        const Spacer(),
        GestureDetector(
          onTap: () { setState(() => _loadingPublic = true); _fetchPublic(); },
          child: const Icon(Icons.refresh_rounded, color: _C.accentL, size: 18)),
      ])),

      Expanded(child: _loadingPublic
          ? const Center(child: CircularProgressIndicator(color: _C.accentL))
          : _errPublic != null
              ? _errorWidget(_errPublic!, _fetchPublic)
              : _publicSenders.isEmpty
                  ? _emptyWidget('Belum ada public sender\nToggle dari tab Private', Icons.public_off_rounded)
                  : ListView.separated(
                      padding: const EdgeInsets.fromLTRB(14, 6, 14, 100),
                      itemCount: _publicSenders.length,
                      separatorBuilder: (_, __) => const SizedBox(height: 8),
                      itemBuilder: (_, i) {
                        final s = _publicSenders[i];
                        return _senderCard(s, isPublic: true);
                      })),
    ]);
  }

  // ─── Sender Card ───────────────────────────────────────────
  Widget _senderCard(Map<String, dynamic> s, {required bool isPublic}) {
    final name    = s['sessionName'] ?? s['number'] ?? 'Unknown';
    final status  = s['status'] ?? 'connected';
    final isConn  = status == 'connected';
    final owner   = s['owner']?.toString();
    final deleting = _deleting == name;

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: _C.s1,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: isConn ? _C.accentL.withOpacity(0.3) : _C.border),
      ),
      child: Row(children: [
        // Status dot
        Container(width: 36, height: 36,
          decoration: BoxDecoration(
            color: (isConn ? _C.green : _C.textM).withOpacity(0.15),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Icon(Icons.phone_android_rounded,
            color: isConn ? _C.green : _C.textM, size: 18)),
        const SizedBox(width: 12),
        // Info
        Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text(name, style: const TextStyle(color: _C.textP, fontWeight: FontWeight.bold, fontSize: 13),
            maxLines: 1, overflow: TextOverflow.ellipsis),
          const SizedBox(height: 3),
          Row(children: [
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
              decoration: BoxDecoration(
                color: (isConn ? _C.green : _C.textM).withOpacity(0.15),
                borderRadius: BorderRadius.circular(5)),
              child: Text(isConn ? 'CONNECTED' : 'OFFLINE',
                style: TextStyle(color: isConn ? _C.green : _C.textM, fontSize: 9, fontWeight: FontWeight.bold))),
            if (isPublic && owner != null) ...[
              const SizedBox(width: 8),
              Text('by $owner', style: const TextStyle(color: _C.textM, fontSize: 10)),
            ],
          ]),
        ])),
        // Actions
        if (!deleting)
          Row(children: [
            // Toggle public (semua role bisa add ke public)
            if (!isPublic)
              GestureDetector(
                onTap: () => _togglePublic(name, true),
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                  decoration: BoxDecoration(
                    color: _C.green.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: _C.green.withOpacity(0.3))),
                  child: const Row(children: [
                    Icon(Icons.public_rounded, color: Color(0xFF00C853), size: 12),
                    SizedBox(width: 4),
                    Text('Publik', style: TextStyle(color: Color(0xFF00C853), fontSize: 10)),
                  ]))),
            if (_isOwner && !isPublic) const SizedBox(width: 6),
            // Toggle private (owner only)
            if (_isOwner && isPublic)
              GestureDetector(
                onTap: () => _togglePublic(name, false),
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                  decoration: BoxDecoration(
                    color: _C.accent.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: _C.accent.withOpacity(0.3))),
                  child: const Row(children: [
                    Icon(Icons.lock_rounded, color: _C.accentL, size: 12),
                    SizedBox(width: 4),
                    Text('Private', style: TextStyle(color: _C.accentL, fontSize: 10)),
                  ]))),
            if (_isOwner && isPublic) const SizedBox(width: 6),
            // Delete
            GestureDetector(
              onTap: () => _confirmDelete(name, isPublic),
              child: Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: _C.red.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: _C.red.withOpacity(0.3))),
                child: const Icon(Icons.delete_outline_rounded, color: _C.red, size: 16))),
          ])
        else
          const SizedBox(width: 24, height: 24,
            child: CircularProgressIndicator(color: _C.accentL, strokeWidth: 2)),
      ]),
    );
  }

  void _confirmDelete(String name, bool isPublic) {
    showDialog(context: context, builder: (_) => AlertDialog(
      backgroundColor: _C.s1,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14), side: BorderSide(color: _C.border)),
      title: const Text('Hapus Sender?', style: TextStyle(color: _C.textP)),
      content: Text('$name akan dihapus.', style: const TextStyle(color: _C.textS)),
      actions: [
        TextButton(onPressed: () => Navigator.pop(context), child: const Text('Batal', style: TextStyle(color: _C.textS))),
        TextButton(
          onPressed: () {
            Navigator.pop(context);
            if (isPublic) _deletePublic(name);
            else _deletePrivate(name);
          },
          child: const Text('Hapus', style: TextStyle(color: _C.red, fontWeight: FontWeight.bold))),
      ],
    ));
  }

  void _showAddDialog() {
    _pairingCode = null;
    showDialog(context: context, builder: (_) => AlertDialog(
      backgroundColor: _C.s1,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14), side: BorderSide(color: _C.border)),
      title: const Text('Tambah Sender', style: TextStyle(color: _C.textP, fontWeight: FontWeight.bold)),
      content: Column(mainAxisSize: MainAxisSize.min, children: [
        const Text('Masukkan nomor WA (dengan kode negara, tanpa +)', style: TextStyle(color: _C.textS, fontSize: 12)),
        const SizedBox(height: 12),
        TextField(
          controller: _numCtrl,
          keyboardType: TextInputType.phone,
          style: const TextStyle(color: _C.textP),
          decoration: InputDecoration(
            hintText: 'Contoh: 628123456789',
            hintStyle: const TextStyle(color: _C.textM),
            filled: true,
            fillColor: _C.s2,
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: BorderSide(color: _C.border)),
            enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: BorderSide(color: _C.border)),
            focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: BorderSide(color: _C.accentL)),
          ),
        ),
      ]),
      actions: [
        TextButton(onPressed: () => Navigator.pop(context), child: const Text('Batal', style: TextStyle(color: _C.textS))),
        ElevatedButton(
          style: ElevatedButton.styleFrom(backgroundColor: _C.accent, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8))),
          onPressed: () {
            Navigator.pop(context);
            _addPrivate();
          },
          child: const Text('Generate Pairing', style: TextStyle(color: _C.white, fontWeight: FontWeight.bold))),
      ],
    ));
  }

  Widget _badge(String text, Color color) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
    decoration: BoxDecoration(color: color.withOpacity(0.15), borderRadius: BorderRadius.circular(20), border: Border.all(color: color.withOpacity(0.4))),
    child: Text(text, style: TextStyle(color: color, fontSize: 11, fontWeight: FontWeight.bold)),
  );

  Widget _emptyWidget(String msg, IconData icon) => Center(child: Column(mainAxisSize: MainAxisSize.min, children: [
    Icon(icon, color: _C.textM, size: 52),
    const SizedBox(height: 14),
    Text(msg, style: const TextStyle(color: _C.textS, fontSize: 13), textAlign: TextAlign.center),
  ]));

  Widget _errorWidget(String err, VoidCallback retry) => Center(child: Column(mainAxisSize: MainAxisSize.min, children: [
    const Icon(Icons.error_outline_rounded, color: _C.red, size: 40),
    const SizedBox(height: 10),
    Text(err, style: const TextStyle(color: _C.textS, fontSize: 12), textAlign: TextAlign.center),
    const SizedBox(height: 14),
    GestureDetector(onTap: retry, child: Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(color: _C.accent.withOpacity(0.2), borderRadius: BorderRadius.circular(8), border: Border.all(color: _C.accentL.withOpacity(0.4))),
      child: const Text('Coba Lagi', style: TextStyle(color: _C.accentL, fontWeight: FontWeight.bold)))),
  ]));
}

