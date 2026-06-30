import 'app_config.dart';
import 'dart:convert';
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;

class BugPage extends StatefulWidget {
  final String username, password, role, expiredDate, sessionKey;
  final List<Map<String, dynamic>> listBug;
  final int initialTab;
  const BugPage({super.key, required this.username, required this.password,
    required this.role, required this.expiredDate, required this.sessionKey,
    required this.listBug, this.initialTab = 0});
  @override State<BugPage> createState() => _BugPageState();
}

class _BugPageState extends State<BugPage> with TickerProviderStateMixin {
  final _targetCtrl = TextEditingController();
  final _linkCtrl   = TextEditingController();

  late TabController _tabs;
  String _selectedBugId = '';
  String _senderType = 'private';
  bool _isSending = false;

  // ── TEMA HITAM ─────────────────────────────────────────────────────────────
  static const _bg   = Color(0xFF000000);
  static const _card = Color(0xFF030D1F);
  static const _brd  = Color(0xFF051525);
  static const _acc  = Color(0xFF1565C0);
  static const _accL = Color(0xFF42A5F5);
  static const _grn  = Color(0xFF00C853);
  static const _txt  = Color(0xFFFFFFFF);
  static const _sub  = Color(0xFF555555);

  List<dynamic> _globalSenders  = [];
  List<dynamic> _privateSenders = [];
  bool _globalOnline = false;

  @override
  void initState() {
    super.initState();
    _tabs = TabController(length: 2, vsync: this, initialIndex: widget.initialTab);
    if (widget.listBug.isNotEmpty) _selectedBugId = widget.listBug[0]['bug_id'] ?? '';
    _fetchGlobal();
    _fetchPrivate();
  }

  @override
  void dispose() { _tabs.dispose(); _targetCtrl.dispose(); _linkCtrl.dispose(); super.dispose(); }

  Future<void> _fetchGlobal() async {
    try {
      final r = await http.get(Uri.parse('$kBaseUrl/getPublicSenders?key=${widget.sessionKey}')).timeout(const Duration(seconds: 8));
      final d = jsonDecode(r.body);
      if (d['valid'] == true && mounted) {
        final senders = List<dynamic>.from(d['senders'] ?? []);
        setState(() {
          _globalSenders = senders;
          _globalOnline = senders.isNotEmpty;
        });
      }
    } catch (_) {}
  }

  Future<void> _fetchPrivate() async {
    try {
      final r = await http.get(Uri.parse('$kBaseUrl/mySender?key=${widget.sessionKey}')).timeout(const Duration(seconds: 8));
      final d = jsonDecode(r.body);
      if (mounted) {
        List<dynamic> priv = [];
        if (d is List) priv = d;
        else if (d['private'] != null) priv = d['private'];
        else if (d['senders'] != null) priv = d['senders'];
        setState(() => _privateSenders = priv);
      }
    } catch (_) {}
  }

  Future<void> _sendBugNomor() async {
    final target = _targetCtrl.text.trim();
    if (target.isEmpty) { _toast('Nomor target tidak boleh kosong!'); return; }
    setState(() => _isSending = true);
    try {
      final url = '$kBaseUrl/sendBug?key=${widget.sessionKey}&target=$target&bug=$_selectedBugId&senderType=$_senderType';
      final res = await http.get(Uri.parse(url)).timeout(const Duration(seconds: 20));
      final d = jsonDecode(res.body);
      if (d['cooldown'] == true) { _toast('Cooldown: Tunggu ${d["wait"]} detik.'); }
      else if (d['sended'] == true) { _toast('✅ Bug berhasil dikirim!', ok: true); _targetCtrl.clear(); }
      else { _toast('❌ Gagal: ${d["message"] ?? "Server error"}'); }
    } catch (_) { _toast('❌ Gagal konek ke server'); }
    finally { if (mounted) setState(() => _isSending = false); }
  }

  Future<void> _sendBugGroup() async {
    final link = _linkCtrl.text.trim();
    if (link.isEmpty || !link.contains('chat.whatsapp.com')) { _toast('Link group tidak valid!'); return; }
    setState(() => _isSending = true);
    try {
      final url = '$kBaseUrl/raidGroup?key=${widget.sessionKey}&link=${Uri.encodeComponent(link)}&bug=$_selectedBugId&senderType=$_senderType';
      final res = await http.get(Uri.parse(url)).timeout(const Duration(seconds: 20));
      final d = jsonDecode(res.body);
      if (d['sended'] == true) { _toast('✅ Bug berhasil dikirim ke Group!', ok: true); _linkCtrl.clear(); }
      else { _toast('❌ Gagal: ${d["message"] ?? "Server error"}'); }
    } catch (_) { _toast('❌ Gagal konek ke server'); }
    finally { if (mounted) setState(() => _isSending = false); }
  }

  void _toast(String msg, {bool ok = false}) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      backgroundColor: ok ? _grn : _acc,
      behavior: SnackBarBehavior.floating,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      content: Text(msg, style: TextStyle(color: Colors.white, fontWeight: FontWeight.w600))));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _bg,
      body: Column(children: [
        // ── BANNER IMAGE / VIDEO di atas ────────────────────────────────────
        Stack(children: [
          ClipRRect(
            child: SizedBox(
              width: double.infinity, height: 200,
              child: Image.asset('assets/images/back.jpg',
                fit: BoxFit.cover,
                errorBuilder: (_, __, ___) => Container(
                  color: const Color(0xFF000814),
                  child: const Center(child: Icon(Icons.image_rounded, color: Colors.white12, size: 48)))))),
          // Gradient overlay
          Positioned.fill(child: DecoratedBox(decoration: BoxDecoration(
            gradient: LinearGradient(begin: Alignment.topCenter, end: Alignment.bottomCenter,
              colors: [Colors.transparent, _bg], stops: const [0.3, 1.0])))),
          // 2 tombol besar di bawah banner
          Positioned(bottom: 0, left: 16, right: 16,
            child: Row(children: [
              // BUG NOMOR
              Expanded(child: GestureDetector(
                onTap: () { _tabs.animateTo(0); setState(() {}); },
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  height: 56,
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: _tabs.index == 0
                        ? [const Color(0xFF0D47A1), const Color(0xFF880000)]
                        : [const Color(0xFF000D1A), const Color(0xFF0D0000)],
                      begin: Alignment.topLeft, end: Alignment.bottomRight),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: _tabs.index == 0 ? _acc : const Color(0xFF0A2550), width: 1.5),
                    boxShadow: _tabs.index == 0
                      ? [BoxShadow(color: _acc.withOpacity(0.5), blurRadius: 16, offset: const Offset(0,4))]
                      : []),
                  child: Row(mainAxisAlignment: MainAxisAlignment.center, children: [
                    Icon(Icons.phone_rounded,
                      color: _tabs.index == 0 ? Colors.white : const Color(0xFF880000), size: 20),
                    const SizedBox(width: 10),
                    Text('BUG NOMOR', style: TextStyle(
                      color: _tabs.index == 0 ? Colors.white : const Color(0xFF880000),
                      fontWeight: FontWeight.w900, fontSize: 13,
                      fontFamily: 'Orbitron', letterSpacing: 1.5)),
                  ])))),
              const SizedBox(width: 12),
              // BUG GROUP
              Expanded(child: GestureDetector(
                onTap: () { _tabs.animateTo(1); setState(() {}); },
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  height: 56,
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: _tabs.index == 1
                        ? [const Color(0xFF0D47A1), const Color(0xFF880000)]
                        : [const Color(0xFF000D1A), const Color(0xFF0D0000)],
                      begin: Alignment.topLeft, end: Alignment.bottomRight),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: _tabs.index == 1 ? _acc : const Color(0xFF0A2550), width: 1.5),
                    boxShadow: _tabs.index == 1
                      ? [BoxShadow(color: _acc.withOpacity(0.5), blurRadius: 16, offset: const Offset(0,4))]
                      : []),
                  child: Row(mainAxisAlignment: MainAxisAlignment.center, children: [
                    Icon(Icons.groups_rounded,
                      color: _tabs.index == 1 ? Colors.white : const Color(0xFF880000), size: 20),
                    const SizedBox(width: 10),
                    Text('BUG GROUP', style: TextStyle(
                      color: _tabs.index == 1 ? Colors.white : const Color(0xFF880000),
                      fontWeight: FontWeight.w900, fontSize: 13,
                      fontFamily: 'Orbitron', letterSpacing: 1.5)),
                  ])))),
            ])),
        ]),

        // ── Content ─────────────────────────────────────────────────────────
        Expanded(child: TabBarView(controller: _tabs, children: [
          _buildBugNomor(),
          _buildBugGroup(),
        ])),
      ]),
    );
  }

  Widget _buildBugNomor() => _buildBugContent(
    inputCtrl: _targetCtrl,
    hint: '628xxxxxxxx',
    icon: Icons.phone_rounded,
    label: 'NOMOR TARGET',
    onSend: _sendBugNomor);

  Widget _buildBugGroup() => _buildBugContent(
    inputCtrl: _linkCtrl,
    hint: 'https://chat.whatsapp.com/...',
    icon: Icons.link_rounded,
    label: 'LINK GROUP WA',
    onSend: _sendBugGroup);

  Widget _buildBugContent({
    required TextEditingController inputCtrl,
    required String hint, required IconData icon,
    required String label, required VoidCallback onSend,
  }) {
    return ListView(padding: const EdgeInsets.fromLTRB(16, 16, 16, 40), children: [
      // Input
      _section(label),
      const SizedBox(height: 8),
      Container(
        decoration: BoxDecoration(
          color: _card, borderRadius: BorderRadius.circular(12),
          border: Border.all(color: _brd, width: 0.5)),
        child: TextField(
          controller: inputCtrl,
          style: TextStyle(color: _txt, fontSize: 14, fontWeight: FontWeight.w500),
          decoration: InputDecoration(
            hintText: hint, hintStyle: TextStyle(color: _sub, fontSize: 12),
            prefixIcon: Icon(icon, color: _acc, size: 18),
            suffixIcon: IconButton(icon: const Icon(Icons.clear_rounded, size: 16), color: _sub, onPressed: inputCtrl.clear),
            border: InputBorder.none, contentPadding: const EdgeInsets.symmetric(vertical: 14, horizontal: 14)))),
      const SizedBox(height: 20),

      // Sender section - like screenshot
      _section('PILIH SENDER'),
      const SizedBox(height: 8),
      // Global status badge
      Row(mainAxisAlignment: MainAxisAlignment.end, children: [
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
          decoration: BoxDecoration(
            color: (_globalOnline ? _grn : _sub).withOpacity(0.12),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: (_globalOnline ? _grn : _sub).withOpacity(0.4), width: 0.5)),
          child: Row(mainAxisSize: MainAxisSize.min, children: [
            Container(width: 6, height: 6, decoration: BoxDecoration(
              color: _globalOnline ? _grn : _sub, shape: BoxShape.circle)),
            const SizedBox(width: 5),
            Text(_globalOnline ? 'Global online' : 'Global offline',
              style: TextStyle(color: _globalOnline ? _grn : _sub, fontSize: 10, fontWeight: FontWeight.w600)),
          ])),
      ]),
      const SizedBox(height: 6),
      Row(children: [
        Expanded(child: _senderChip('private', 'Pribadi', Icons.person_rounded, Colors.cyanAccent)),
        const SizedBox(width: 8),
        Expanded(child: _senderChip('public', 'Global', Icons.language_rounded, _grn)),
      ]),
      const SizedBox(height: 10),
      // Private sender details
      if (_senderType == 'private' && _privateSenders.isNotEmpty)
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          decoration: BoxDecoration(color: _card, borderRadius: BorderRadius.circular(8), border: Border.all(color: _brd, width: 0.5)),
          child: Row(children: [
            Container(width: 6, height: 6, decoration: BoxDecoration(color: Colors.cyanAccent, shape: BoxShape.circle)),
            const SizedBox(width: 8),
            Text('${_privateSenders.length} Private sender aktif', style: TextStyle(color: Colors.cyanAccent, fontSize: 11, fontWeight: FontWeight.w600)),
          ]))
      else if (_senderType == 'private' && _privateSenders.isEmpty)
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          decoration: BoxDecoration(color: _card, borderRadius: BorderRadius.circular(8), border: Border.all(color: _brd, width: 0.5)),
          child: const Row(children: [
            Icon(Icons.info_outline_rounded, color: Colors.orange, size: 14),
            SizedBox(width: 8),
            Text('Belum ada private sender', style: TextStyle(color: Colors.orange, fontSize: 11)),
          ])),
      // Global sender dots like screenshot
      if (_senderType == 'public' && _globalSenders.isNotEmpty)
        Wrap(spacing: 6, runSpacing: 6, children: List.generate(_globalSenders.length, (i) {
          final ok = (_globalSenders[i]['status']?.toString() ?? 'connected') == 'connected';
          return Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
            decoration: BoxDecoration(
              color: (ok ? _grn : _sub).withOpacity(0.1),
              borderRadius: BorderRadius.circular(6),
              border: Border.all(color: (ok ? _grn : _sub).withOpacity(0.3), width: 0.5)),
            child: Row(mainAxisSize: MainAxisSize.min, children: [
              Container(width: 6, height: 6, decoration: BoxDecoration(color: ok ? _grn : _sub, shape: BoxShape.circle)),
              const SizedBox(width: 5),
              Text('Sender ${i+1}', style: TextStyle(color: ok ? _grn : _sub, fontSize: 10, fontWeight: FontWeight.w600)),
            ]));
        }))
      else if (_senderType == 'public' && _globalSenders.isEmpty)
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          decoration: BoxDecoration(color: _card, borderRadius: BorderRadius.circular(8), border: Border.all(color: _brd, width: 0.5)),
          child: const Row(children: [
            Icon(Icons.wifi_off_rounded, color: Colors.orange, size: 14),
            SizedBox(width: 8),
            Text('Tidak ada global sender aktif', style: TextStyle(color: Colors.orange, fontSize: 11)),
          ])),
      const SizedBox(height: 20),

      // Daily limit info
      Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(color: Color(0xFF020A18), borderRadius: BorderRadius.circular(8), border: Border.all(color: _brd, width: 0.5)),
        child: Row(children: [
          Icon(Icons.info_outline_rounded, color: _sub, size: 13),
          const SizedBox(width: 8),
          Text('Sisa kirim global hari ini: ${_globalSenders.length > 0 ? "10 / 10" : "0 / 10"}',
            style: TextStyle(color: _sub, fontSize: 10)),
        ])),
      const SizedBox(height: 20),

      // Bug selector
      _section('PILIH BUG'),
      const SizedBox(height: 8),
      if (widget.listBug.isEmpty)
        Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(color: _card, borderRadius: BorderRadius.circular(10), border: Border.all(color: _brd, width: 0.5)),
          child: Center(child: Text('Tidak ada bug tersedia', style: TextStyle(color: _sub, fontSize: 12))))
      else
        SizedBox(
          height: 110,
          child: PageView.builder(
            controller: PageController(viewportFraction: 0.46),
            itemCount: widget.listBug.length,
            itemBuilder: (ctx, i) {
              final bug = widget.listBug[i];
              final sel = _selectedBugId == bug['bug_id'];
              return GestureDetector(
                onTap: () => setState(() => _selectedBugId = bug['bug_id'] ?? ''),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 180),
                  margin: const EdgeInsets.only(right: 10),
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: sel ? _acc.withOpacity(0.12) : _card,
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(color: sel ? _acc : _brd, width: sel ? 1.8 : 0.8),
                    boxShadow: sel ? [BoxShadow(color: _acc.withOpacity(0.3), blurRadius: 10)] : []),
                  child: Column(crossAxisAlignment: CrossAxisAlignment.start, mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
                    Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
                      Icon(Icons.shield_rounded, color: sel ? _acc : _sub, size: 18),
                      if (sel) Container(width: 8, height: 8, decoration: BoxDecoration(color: Color(0xFF00E676), shape: BoxShape.circle)),
                    ]),
                    Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                      Text(bug['bug_name']?.toString().toUpperCase() ?? '',
                        style: TextStyle(color: sel ? _acc : Colors.white70, fontSize: 11, fontWeight: FontWeight.w900, height: 1.3),
                        maxLines: 2, overflow: TextOverflow.ellipsis),
                      const SizedBox(height: 4),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
                        decoration: BoxDecoration(
                          color: (sel ? _acc : _sub).withOpacity(0.12),
                          borderRadius: BorderRadius.circular(4)),
                        child: Text(bug['bug_id']?.toString() ?? '', style: TextStyle(color: sel ? _acc : _sub, fontSize: 8, fontWeight: FontWeight.w600))),
                    ]),
                  ])),
              );
            },
          ),
        ),
      const SizedBox(height: 24),



      // SEND button
      GestureDetector(
        onTap: _isSending ? null : onSend,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          width: double.infinity, height: 54,
          decoration: BoxDecoration(
            gradient: _isSending
              ? LinearGradient(colors: [Color(0xFF051525), Color(0xFF051525)])
              : LinearGradient(colors: [_acc, Color(0xFF0A2472)], begin: Alignment.centerLeft, end: Alignment.centerRight),
            borderRadius: BorderRadius.circular(14),
            boxShadow: _isSending ? [] : [BoxShadow(color: _acc.withOpacity(0.35), blurRadius: 16, offset: Offset(0, 6))]),
          child: Center(child: _isSending
            ? const Row(mainAxisSize: MainAxisSize.min, children: [
                SizedBox(width: 18, height: 18, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2)),
                SizedBox(width: 12),
                Text('MENGIRIM...', style: TextStyle(color: Colors.white, fontWeight: FontWeight.w900, fontSize: 13, letterSpacing: 2)),
              ])
            : const Row(mainAxisSize: MainAxisSize.min, children: [
                Icon(Icons.send_rounded, color: Colors.white, size: 18),
                SizedBox(width: 10),
                Text('KIRIM BUG', style: TextStyle(
                  color: Colors.white, fontWeight: FontWeight.w900, fontSize: 15, letterSpacing: 2,
                  shadows: [Shadow(color: Colors.black54, blurRadius: 4, offset: Offset(0, 2))])),
              ]))),
      ),
    ]);
  }

  Widget _section(String title) => Row(children: [
    Container(width: 3, height: 14, decoration: BoxDecoration(color: _acc, borderRadius: BorderRadius.circular(2))),
    const SizedBox(width: 8),
    Text(title, style: TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.w800, letterSpacing: 1.5)),
  ]);

  Widget _senderChip(String val, String label, IconData icon, Color color) {
    final sel = _senderType == val;
    final canUse = val != 'public' || widget.role == 'owner' || widget.role == 'vip' || widget.role == 'admin';
    return GestureDetector(
      onTap: canUse ? () => setState(() => _senderType = val) : null,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        padding: const EdgeInsets.symmetric(vertical: 12),
        decoration: BoxDecoration(
          color: !canUse ? Color(0xFF020818) : sel ? color.withOpacity(0.12) : _card,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: !canUse ? _brd : sel ? color : _brd, width: sel ? 1.5 : 0.5)),
        child: Column(children: [
          Icon(icon, color: !canUse ? _sub : sel ? color : _sub, size: 22),
          const SizedBox(height: 6),
          Text(label, style: TextStyle(
            color: !canUse ? _sub : sel ? color : _sub,
            fontWeight: sel ? FontWeight.w800 : FontWeight.normal, fontSize: 12)),
          if (!canUse) Text('Khusus Owner', style: TextStyle(color: _sub, fontSize: 9)),
        ])));
  }
}
