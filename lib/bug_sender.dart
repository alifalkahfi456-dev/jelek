import 'dart:convert';
import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:http/http.dart' as http;

// ─────────────────────────────────────────────
//  PALETTE  (sama dengan dashboard & landing)
// ─────────────────────────────────────────────
const Color _bsBg       = Color(0xFF0b1120);
const Color _bsCard     = Color(0xFF111827);
const Color _bsCard2    = Color(0xFF0d1b2e);
const Color _bsBorder   = Color(0xFF1e2d45);
const Color _bsBlue     = Color(0xFF2563eb);
const Color _bsCyan     = Color(0xFF22d3ee);
const Color _bsGreen    = Color(0xFF22c55e);
const Color _bsRed      = Color(0xFFef4444);
const Color _bsAmber    = Color(0xFFf59e0b);
const Color _bsWhite    = Colors.white;
const Color _bsSub      = Color(0xFF94a3b8);

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
  late TabController _tabController;
  late AnimationController _hexCtrl;
  late Animation<double> _hexAnim;

  List<dynamic> privateSenders = [];
  List<dynamic> publicSenders  = [];
  bool isLoadingPrivate = false;
  bool isLoadingPublic  = false;
  String? errorPrivate;
  String? errorPublic;

  bool get canAccessPublic =>
      ['vip', 'owner', 'all_akses'].contains(widget.role.toLowerCase());

  int get tabLen => canAccessPublic ? 2 : 1;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: tabLen, vsync: this);

    _hexCtrl = AnimationController(
        vsync: this, duration: const Duration(seconds: 4))
      ..repeat(reverse: true);
    _hexAnim = CurvedAnimation(parent: _hexCtrl, curve: Curves.easeInOut);

    _fetchPrivateSenders();
    if (canAccessPublic) _fetchPublicSenders();
  }

  @override
  void dispose() {
    _tabController.dispose();
    _hexCtrl.dispose();
    super.dispose();
  }

  // ── API calls (logic tidak diubah) ───────────
  Future<void> _fetchBothSenders() async {
    if (canAccessPublic) {
      await Future.wait([_fetchPrivateSenders(), _fetchPublicSenders()]);
    } else {
      await _fetchPrivateSenders();
    }
  }

  Future<void> _fetchPrivateSenders() async {
    setState(() { isLoadingPrivate = true; errorPrivate = null; });
    try {
      final res = await http.get(Uri.parse(
          'http://saitama.omdhancivok.my.id:2001/mySender?key=${widget.sessionKey}'));
      final data = jsonDecode(res.body) as Map<String, dynamic>;
      if (data['valid'] == true) {
        setState(() => privateSenders = data['connections'] ?? []);
      } else {
        setState(() => errorPrivate = data['error'] ?? 'Failed to fetch');
      }
    } catch (e) {
      setState(() => errorPrivate = 'Connection failed: $e');
    } finally {
      setState(() => isLoadingPrivate = false);
    }
  }

  Future<void> _fetchPublicSenders() async {
    if (!canAccessPublic) return;
    setState(() { isLoadingPublic = true; errorPublic = null; });
    try {
      final res = await http.get(Uri.parse(
          'http://saitama.omdhancivok.my.id:2001/getPublicSenders?key=${widget.sessionKey}'));
      final data = jsonDecode(res.body) as Map<String, dynamic>;
      if (data['valid'] == true) {
        setState(() => publicSenders = data['senders'] ?? []);
      } else {
        setState(() => errorPublic = data['message'] ?? 'Failed to fetch');
      }
    } catch (e) {
      setState(() => errorPublic = 'Connection failed: $e');
    } finally {
      setState(() => isLoadingPublic = false);
    }
  }

  Future<void> _addPrivateSender(String number) async {
    setState(() => isLoadingPrivate = true);
    try {
      final res = await http.get(Uri.parse(
          'http://saitama.omdhancivok.my.id:2001/getPairing?key=${widget.sessionKey}&number=$number'));
      final data = jsonDecode(res.body) as Map<String, dynamic>;
      if (data['valid'] == true) {
        _showPairingDialog(number, data['pairingCode'] as String);
        _snack('Pairing code generated!');
      } else {
        _snack(data['message'] ?? 'Failed to generate pairing code', isError: true);
      }
    } catch (e) {
      _snack('Connection failed: $e', isError: true);
    } finally {
      setState(() => isLoadingPrivate = false);
      _fetchPrivateSenders();
    }
  }

  Future<void> _deletePrivateSender(String name) async {
    final ok = await _confirmDelete();
    if (ok != true) return;
    _snack('Delete feature not implemented in backend yet', isError: true);
  }

  Future<void> _deletePublicSender(String name) async {
    if (widget.role.toLowerCase() != 'owner') {
      _snack('Only owner can delete public senders', isError: true);
      return;
    }
    final ok = await _confirmDelete();
    if (ok != true) return;
    setState(() => isLoadingPublic = true);
    try {
      final res = await http.get(Uri.parse(
          'http://saitama.omdhancivok.my.id:2001/deletePublicSender?key=${widget.sessionKey}&sessionName=$name'));
      final data = jsonDecode(res.body) as Map<String, dynamic>;
      if (data['valid'] == true) {
        _snack('Public sender deleted!');
        _fetchPublicSenders();
      } else {
        _snack(data['message'] ?? 'Failed to delete', isError: true);
      }
    } catch (e) {
      _snack('Connection failed: $e', isError: true);
    } finally {
      setState(() => isLoadingPublic = false);
    }
  }

  void _snack(String msg, {bool isError = false}) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Text(msg, style: const TextStyle(color: _bsWhite)),
      backgroundColor: isError ? _bsRed : _bsGreen,
      behavior: SnackBarBehavior.floating,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      margin: const EdgeInsets.all(16),
    ));
  }

  Future<bool?> _confirmDelete() => showDialog<bool>(
        context: context,
        builder: (_) => _styledDialog(
          icon: Icons.warning_amber_rounded,
          iconColor: _bsAmber,
          title: 'Confirm Delete',
          content: 'Are you sure? This action cannot be undone.',
          actions: [
            _dialogBtn('CANCEL', _bsSub, () => Navigator.pop(context, false)),
            _dialogBtn('DELETE', _bsRed, () => Navigator.pop(context, true),
                filled: true),
          ],
        ),
      );

  // ─────────────────────────────────────────────
  //  BUILD
  // ─────────────────────────────────────────────
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _bsBg,
      body: Stack(children: [
        // Honeycomb bg
        Positioned.fill(
          child: AnimatedBuilder(
            animation: _hexAnim,
            builder: (_, __) => CustomPaint(
              painter: _BsHexPainter(pulse: _hexAnim.value),
            ),
          ),
        ),

        SafeArea(
          child: Column(children: [
            _appBar(),
            if (canAccessPublic) _tabBar(),
            Expanded(
              child: canAccessPublic
                  ? TabBarView(
                      controller: _tabController,
                      children: [
                        _tabContent(isPrivate: true),
                        _tabContent(isPrivate: false),
                      ],
                    )
                  : _tabContent(isPrivate: true),
            ),
          ]),
        ),
      ]),

      floatingActionButton: _fab(),
    );
  }

  // ─────────────────────────────────────────────
  //  APP BAR
  // ─────────────────────────────────────────────
  Widget _appBar() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 10),
      decoration: const BoxDecoration(
        color: _bsCard,
        border: Border(bottom: BorderSide(color: _bsBorder, width: 1)),
      ),
      child: Row(children: [
        // Back
        Container(
          width: 38,
          height: 38,
          decoration: BoxDecoration(
            color: _bsBg,
            borderRadius: BorderRadius.circular(10),
            border: Border.all(color: _bsBorder),
          ),
          child: IconButton(
            padding: EdgeInsets.zero,
            icon: const Icon(Icons.arrow_back_ios_rounded,
                color: _bsWhite, size: 16),
            onPressed: () => Navigator.pop(context),
          ),
        ),
        const SizedBox(width: 12),

        // Title
        Expanded(
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            ShaderMask(
              shaderCallback: (r) => const LinearGradient(
                      colors: [_bsBlue, _bsCyan])
                  .createShader(r),
              child: const Text('MANAGE SENDER',
                  style: TextStyle(
                      color: _bsWhite,
                      fontWeight: FontWeight.w900,
                      fontSize: 15,
                      letterSpacing: 1.5)),
            ),
            Text('Bug Sender Manager',
                style: TextStyle(color: _bsSub, fontSize: 11)),
          ]),
        ),

        // Refresh
        Container(
          width: 38,
          height: 38,
          decoration: BoxDecoration(
            color: _bsBlue.withOpacity(0.15),
            borderRadius: BorderRadius.circular(10),
            border: Border.all(color: _bsBlue.withOpacity(0.3)),
          ),
          child: IconButton(
            padding: EdgeInsets.zero,
            icon: const Icon(Icons.refresh_rounded, color: _bsCyan, size: 20),
            onPressed: _fetchBothSenders,
          ),
        ),
      ]),
    );
  }

  // ─────────────────────────────────────────────
  //  TAB BAR
  // ─────────────────────────────────────────────
  Widget _tabBar() {
    return Container(
      color: _bsCard,
      child: TabBar(
        controller: _tabController,
        indicatorColor: _bsCyan,
        indicatorWeight: 2.5,
        labelColor: _bsCyan,
        unselectedLabelColor: _bsSub,
        labelStyle: const TextStyle(
            fontWeight: FontWeight.bold, fontSize: 12, letterSpacing: 1),
        tabs: const [
          Tab(icon: Icon(Icons.lock_rounded, size: 18), text: 'PRIVATE'),
          Tab(icon: Icon(Icons.public_rounded, size: 18), text: 'PUBLIC'),
        ],
      ),
    );
  }

  // ─────────────────────────────────────────────
  //  FAB
  // ─────────────────────────────────────────────
  Widget _fab() {
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
              color: _bsBlue.withOpacity(0.45),
              blurRadius: 20,
              offset: const Offset(0, 6)),
        ],
      ),
      child: FloatingActionButton.extended(
        backgroundColor: _bsBlue,
        foregroundColor: _bsWhite,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
        icon: const Icon(Icons.add_rounded),
        label: const Text('ADD SENDER',
            style: TextStyle(fontWeight: FontWeight.bold, letterSpacing: 1)),
        onPressed: _showAddDialog,
      ),
    );
  }

  // ─────────────────────────────────────────────
  //  TAB CONTENT
  // ─────────────────────────────────────────────
  Widget _tabContent({required bool isPrivate}) {
    final loading = isPrivate ? isLoadingPrivate : isLoadingPublic;
    final error   = isPrivate ? errorPrivate : errorPublic;
    final list    = isPrivate ? privateSenders : publicSenders;

    if (loading && list.isEmpty) {
      return Center(
        child: Column(mainAxisSize: MainAxisSize.min, children: [
          SizedBox(
            width: 40,
            height: 40,
            child: CircularProgressIndicator(
                color: _bsCyan,
                strokeWidth: 2.5,
                backgroundColor: _bsBorder),
          ),
          const SizedBox(height: 16),
          Text('Loading senders...',
              style: TextStyle(color: _bsSub, fontSize: 13)),
        ]),
      );
    }

    if (error != null && list.isEmpty) {
      return _errorState(error, isPrivate);
    }

    if (list.isEmpty) return _emptyState(isPrivate);

    return RefreshIndicator(
      color: _bsCyan,
      backgroundColor: _bsCard,
      onRefresh: () =>
          isPrivate ? _fetchPrivateSenders() : _fetchPublicSenders(),
      child: ListView.builder(
        padding: const EdgeInsets.fromLTRB(16, 12, 16, 100),
        itemCount: list.length,
        itemBuilder: (_, i) => isPrivate
            ? _privateSenderCard(Map<String, dynamic>.from(list[i]))
            : _publicSenderCard(Map<String, dynamic>.from(list[i])),
      ),
    );
  }

  // ─────────────────────────────────────────────
  //  PRIVATE SENDER CARD
  // ─────────────────────────────────────────────
  Widget _privateSenderCard(Map<String, dynamic> s) {
    final name     = s['sessionName'] as String? ?? 'Unnamed';
    final type     = s['type']        as String? ?? 'Unknown';
    final isActive = s['isActive']    as bool?   ?? false;

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: _bsCard,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isActive
              ? _bsGreen.withOpacity(0.3)
              : _bsBorder,
        ),
        boxShadow: [
          BoxShadow(
              color: Colors.black.withOpacity(0.3),
              blurRadius: 10,
              offset: const Offset(0, 4)),
        ],
      ),
      child: Column(children: [
        // ── Top accent line ──
        Container(
          height: 3,
          decoration: BoxDecoration(
            borderRadius:
                const BorderRadius.vertical(top: Radius.circular(16)),
            gradient: LinearGradient(
              colors: isActive
                  ? [_bsGreen, _bsCyan]
                  : [_bsBorder, _bsBorder],
            ),
          ),
        ),

        Padding(
          padding: const EdgeInsets.all(14),
          child: Column(children: [
            Row(children: [
              // Icon
              Container(
                width: 46,
                height: 46,
                decoration: BoxDecoration(
                  color: isActive
                      ? _bsGreen.withOpacity(0.1)
                      : _bsBorder.withOpacity(0.5),
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: isActive
                        ? _bsGreen.withOpacity(0.4)
                        : _bsBorder,
                  ),
                ),
                child: Icon(Icons.phone_android_rounded,
                    color: isActive ? _bsGreen : _bsSub, size: 22),
              ),
              const SizedBox(width: 12),

              Expanded(
                child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(name,
                          style: const TextStyle(
                              color: _bsWhite,
                              fontSize: 15,
                              fontWeight: FontWeight.bold)),
                      const SizedBox(height: 6),
                      Row(children: [
                        _badge(type.toUpperCase(), _bsBlue),
                        const SizedBox(width: 6),
                        _badge(
                          isActive ? 'ACTIVE' : 'INACTIVE',
                          isActive ? _bsGreen : _bsSub,
                        ),
                      ]),
                    ]),
              ),

              // Status dot
              Container(
                width: 10,
                height: 10,
                decoration: BoxDecoration(
                  color: isActive ? _bsGreen : _bsSub,
                  shape: BoxShape.circle,
                  boxShadow: isActive
                      ? [BoxShadow(
                          color: _bsGreen.withOpacity(0.5),
                          blurRadius: 6, spreadRadius: 1)]
                      : [],
                ),
              ),
            ]),
            const SizedBox(height: 14),

            // Buttons row
            Row(children: [
              Expanded(
                child: _outlineBtn(
                  icon: Icons.refresh_rounded,
                  label: 'REFRESH',
                  color: _bsCyan,
                  onTap: _fetchPrivateSenders,
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: _outlineBtn(
                  icon: Icons.delete_rounded,
                  label: 'DELETE',
                  color: _bsRed,
                  onTap: () => _deletePrivateSender(name),
                ),
              ),
            ]),
          ]),
        ),
      ]),
    );
  }

  // ─────────────────────────────────────────────
  //  PUBLIC SENDER CARD
  // ─────────────────────────────────────────────
  Widget _publicSenderCard(Map<String, dynamic> s) {
    final name      = s['sessionName'] as String? ?? 'Unnamed';
    final type      = s['type']        as String? ?? 'Unknown';
    final isActive  = s['isActive']    as bool?   ?? false;
    final isBiz     = type == 'Business';

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: _bsCard,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isActive
              ? _bsGreen.withOpacity(0.3)
              : _bsBorder,
        ),
        boxShadow: [
          BoxShadow(
              color: Colors.black.withOpacity(0.3),
              blurRadius: 10,
              offset: const Offset(0, 4)),
        ],
      ),
      child: Column(children: [
        Container(
          height: 3,
          decoration: BoxDecoration(
            borderRadius:
                const BorderRadius.vertical(top: Radius.circular(16)),
            gradient: LinearGradient(
              colors: isActive
                  ? [_bsCyan, _bsBlue]
                  : [_bsBorder, _bsBorder],
            ),
          ),
        ),

        Padding(
          padding: const EdgeInsets.all(14),
          child: Column(children: [
            Row(children: [
              Container(
                width: 46,
                height: 46,
                decoration: BoxDecoration(
                  color: isActive
                      ? _bsCyan.withOpacity(0.1)
                      : _bsBorder.withOpacity(0.5),
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: isActive
                        ? _bsCyan.withOpacity(0.4)
                        : _bsBorder,
                  ),
                ),
                child: Icon(Icons.public_rounded,
                    color: isActive ? _bsCyan : _bsSub, size: 22),
              ),
              const SizedBox(width: 12),

              Expanded(
                child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(name,
                          style: const TextStyle(
                              color: _bsWhite,
                              fontSize: 15,
                              fontWeight: FontWeight.bold)),
                      const SizedBox(height: 6),
                      Row(children: [
                        _badge('PUBLIC', _bsGreen),
                        const SizedBox(width: 6),
                        _badge(type.toUpperCase(),
                            isBiz ? _bsBlue : _bsAmber),
                        const SizedBox(width: 6),
                        _badge(
                          isActive ? 'ACTIVE' : 'INACTIVE',
                          isActive ? _bsGreen : _bsSub,
                        ),
                      ]),
                    ]),
              ),

              Container(
                width: 10,
                height: 10,
                decoration: BoxDecoration(
                  color: isActive ? _bsCyan : _bsSub,
                  shape: BoxShape.circle,
                  boxShadow: isActive
                      ? [BoxShadow(
                          color: _bsCyan.withOpacity(0.5),
                          blurRadius: 6, spreadRadius: 1)]
                      : [],
                ),
              ),
            ]),
            const SizedBox(height: 14),

            Row(children: [
              Expanded(
                child: _outlineBtn(
                  icon: Icons.refresh_rounded,
                  label: 'REFRESH',
                  color: _bsCyan,
                  onTap: _fetchPublicSenders,
                ),
              ),
              if (widget.role.toLowerCase() == 'owner') ...[
                const SizedBox(width: 10),
                Expanded(
                  child: _outlineBtn(
                    icon: Icons.delete_rounded,
                    label: 'DELETE',
                    color: _bsRed,
                    onTap: () => _deletePublicSender(name),
                  ),
                ),
              ],
            ]),
          ]),
        ),
      ]),
    );
  }

  // ─────────────────────────────────────────────
  //  EMPTY STATE
  // ─────────────────────────────────────────────
  Widget _emptyState(bool isPrivate) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(mainAxisSize: MainAxisSize.min, children: [
          // Hex icon container
          Container(
            width: 90,
            height: 90,
            decoration: BoxDecoration(
              color: _bsBlue.withOpacity(0.08),
              shape: BoxShape.circle,
              border: Border.all(color: _bsBlue.withOpacity(0.25), width: 1.5),
            ),
            child: Icon(
              isPrivate ? Icons.lock_rounded : Icons.public_rounded,
              color: _bsBlue,
              size: 40,
            ),
          ),
          const SizedBox(height: 20),
          Text(
            isPrivate ? 'No Private Senders' : 'No Public Senders',
            style: const TextStyle(
                color: _bsWhite, fontSize: 18, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 8),
          Text(
            isPrivate
                ? 'Tap the button below to add your first sender'
                : 'Public senders are managed by owner',
            textAlign: TextAlign.center,
            style: const TextStyle(color: _bsSub, fontSize: 13, height: 1.5),
          ),
          if (isPrivate) ...[
            const SizedBox(height: 28),
            GestureDetector(
              onTap: _showAddDialog,
              child: Container(
                padding: const EdgeInsets.symmetric(
                    horizontal: 24, vertical: 14),
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                      colors: [Color(0xFF1d4ed8), Color(0xFF1e40af)]),
                  borderRadius: BorderRadius.circular(14),
                  boxShadow: [
                    BoxShadow(
                        color: _bsBlue.withOpacity(0.4),
                        blurRadius: 16,
                        offset: const Offset(0, 6))
                  ],
                ),
                child: const Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.add_rounded, color: _bsWhite, size: 20),
                      SizedBox(width: 8),
                      Text('ADD SENDER',
                          style: TextStyle(
                              color: _bsWhite,
                              fontWeight: FontWeight.bold,
                              letterSpacing: 1)),
                    ]),
              ),
            ),
          ],
        ]),
      ),
    );
  }

  // ─────────────────────────────────────────────
  //  ERROR STATE
  // ─────────────────────────────────────────────
  Widget _errorState(String msg, bool isPrivate) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(mainAxisSize: MainAxisSize.min, children: [
          Container(
            width: 90,
            height: 90,
            decoration: BoxDecoration(
              color: _bsRed.withOpacity(0.08),
              shape: BoxShape.circle,
              border: Border.all(color: _bsRed.withOpacity(0.25), width: 1.5),
            ),
            child: const Icon(Icons.error_outline_rounded,
                color: _bsRed, size: 40),
          ),
          const SizedBox(height: 20),
          const Text('Failed to Load',
              style: TextStyle(
                  color: _bsWhite,
                  fontSize: 18,
                  fontWeight: FontWeight.bold)),
          const SizedBox(height: 8),
          Text(msg,
              textAlign: TextAlign.center,
              style: const TextStyle(color: _bsSub, fontSize: 13, height: 1.5)),
          const SizedBox(height: 28),
          GestureDetector(
            onTap: () =>
                isPrivate ? _fetchPrivateSenders() : _fetchPublicSenders(),
            child: Container(
              padding: const EdgeInsets.symmetric(
                  horizontal: 24, vertical: 14),
              decoration: BoxDecoration(
                color: _bsRed.withOpacity(0.15),
                borderRadius: BorderRadius.circular(14),
                border:
                    Border.all(color: _bsRed.withOpacity(0.4)),
              ),
              child: const Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.refresh_rounded, color: _bsRed, size: 20),
                    SizedBox(width: 8),
                    Text('TRY AGAIN',
                        style: TextStyle(
                            color: _bsRed,
                            fontWeight: FontWeight.bold,
                            letterSpacing: 1)),
                  ]),
            ),
          ),
        ]),
      ),
    );
  }

  // ─────────────────────────────────────────────
  //  ADD SENDER DIALOG
  // ─────────────────────────────────────────────
  void _showAddDialog() {
    final ctrl = TextEditingController();
    showDialog(
      context: context,
      builder: (_) => _styledDialog(
        icon: Icons.add_circle_rounded,
        iconColor: _bsCyan,
        title: 'Add Private Sender',
        content: null,
        extra: TextField(
          controller: ctrl,
          keyboardType: TextInputType.phone,
          style: const TextStyle(color: _bsWhite),
          cursorColor: _bsCyan,
          decoration: InputDecoration(
            hintText: '62xxx',
            hintStyle: TextStyle(color: _bsSub),
            labelText: 'Phone Number',
            labelStyle: const TextStyle(color: _bsCyan),
            prefixIcon:
                const Icon(Icons.phone_android_rounded, color: _bsCyan),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(color: _bsBorder),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(color: _bsCyan),
            ),
          ),
        ),
        actions: [
          _dialogBtn('CANCEL', _bsSub, () => Navigator.pop(context)),
          _dialogBtn('ADD SENDER', _bsBlue, () async {
            final num = ctrl.text.trim();
            if (num.isEmpty) {
              _snack('Please enter phone number', isError: true);
              return;
            }
            Navigator.pop(context);
            await _addPrivateSender(num);
          }, filled: true),
        ],
      ),
    );
  }

  // ─────────────────────────────────────────────
  //  PAIRING CODE DIALOG
  // ─────────────────────────────────────────────
  void _showPairingDialog(String number, String code) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => Dialog(
        backgroundColor: _bsCard,
        shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(24),
            side: BorderSide(color: _bsBlue.withOpacity(0.3))),
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(mainAxisSize: MainAxisSize.min, children: [
            // Icon
            Container(
              width: 64,
              height: 64,
              decoration: BoxDecoration(
                color: _bsBlue.withOpacity(0.1),
                shape: BoxShape.circle,
                border: Border.all(color: _bsBlue.withOpacity(0.3)),
              ),
              child: const Icon(Icons.qr_code_2_rounded,
                  color: _bsCyan, size: 34),
            ),
            const SizedBox(height: 14),
            const Text('Pairing Required',
                style: TextStyle(
                    color: _bsWhite,
                    fontWeight: FontWeight.bold,
                    fontSize: 17)),
            const SizedBox(height: 6),
            Text('Number: $number',
                style: const TextStyle(color: _bsSub, fontSize: 12)),
            const SizedBox(height: 20),

            // Code box
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(vertical: 20),
              decoration: BoxDecoration(
                color: _bsBg,
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: _bsCyan.withOpacity(0.4)),
              ),
              child: ShaderMask(
                shaderCallback: (r) => const LinearGradient(
                        colors: [_bsBlue, _bsCyan])
                    .createShader(r),
                child: Text(
                  code,
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    color: _bsWhite,
                    fontSize: 36,
                    fontWeight: FontWeight.w900,
                    letterSpacing: 8,
                  ),
                ),
              ),
            ),
            const SizedBox(height: 16),

            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: _bsAmber.withOpacity(0.07),
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: _bsAmber.withOpacity(0.2)),
              ),
              child: const Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Icon(Icons.info_outline_rounded,
                      color: _bsAmber, size: 16),
                  SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'Open WhatsApp → Settings → Linked Devices → Link a Device → enter this code',
                      style: TextStyle(
                          color: _bsAmber,
                          fontSize: 11,
                          height: 1.5),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),

            Row(children: [
              Expanded(
                child: _outlineBtn(
                  icon: Icons.close_rounded,
                  label: 'CLOSE',
                  color: _bsSub,
                  onTap: () => Navigator.pop(context),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: GestureDetector(
                  onTap: () {
                    Navigator.pop(context);
                    _fetchPrivateSenders();
                  },
                  child: Container(
                    height: 44,
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(
                          colors: [Color(0xFF1d4ed8), _bsBlue]),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.refresh_rounded,
                              color: _bsWhite, size: 16),
                          SizedBox(width: 6),
                          Text('REFRESH',
                              style: TextStyle(
                                  color: _bsWhite,
                                  fontWeight: FontWeight.bold,
                                  fontSize: 12,
                                  letterSpacing: 0.8)),
                        ]),
                  ),
                ),
              ),
            ]),
          ]),
        ),
      ),
    );
  }

  // ─────────────────────────────────────────────
  //  HELPERS
  // ─────────────────────────────────────────────
  Widget _badge(String label, Color color) => Container(
        padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
        decoration: BoxDecoration(
          color: color.withOpacity(0.15),
          borderRadius: BorderRadius.circular(6),
          border: Border.all(color: color.withOpacity(0.3), width: 0.8),
        ),
        child: Text(label,
            style: TextStyle(
                color: color,
                fontSize: 9,
                fontWeight: FontWeight.bold,
                letterSpacing: 0.5)),
      );

  Widget _outlineBtn({
    required IconData icon,
    required String label,
    required Color color,
    required VoidCallback onTap,
  }) =>
      GestureDetector(
        onTap: onTap,
        child: Container(
          height: 40,
          decoration: BoxDecoration(
            color: color.withOpacity(0.08),
            borderRadius: BorderRadius.circular(10),
            border: Border.all(color: color.withOpacity(0.35)),
          ),
          child: Row(mainAxisAlignment: MainAxisAlignment.center, children: [
            Icon(icon, color: color, size: 15),
            const SizedBox(width: 6),
            Text(label,
                style: TextStyle(
                    color: color,
                    fontSize: 11,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 0.8)),
          ]),
        ),
      );

  Widget _styledDialog({
    required IconData icon,
    required Color iconColor,
    required String title,
    String? content,
    Widget? extra,
    required List<Widget> actions,
  }) =>
      Dialog(
        backgroundColor: _bsCard,
        shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(22),
            side: BorderSide(color: _bsBorder)),
        child: Padding(
          padding: const EdgeInsets.all(22),
          child: Column(mainAxisSize: MainAxisSize.min, children: [
            Container(
              width: 52,
              height: 52,
              decoration: BoxDecoration(
                color: iconColor.withOpacity(0.1),
                shape: BoxShape.circle,
                border:
                    Border.all(color: iconColor.withOpacity(0.3)),
              ),
              child: Icon(icon, color: iconColor, size: 26),
            ),
            const SizedBox(height: 14),
            Text(title,
                style: const TextStyle(
                    color: _bsWhite,
                    fontWeight: FontWeight.bold,
                    fontSize: 16)),
            if (content != null) ...[
              const SizedBox(height: 8),
              Text(content,
                  textAlign: TextAlign.center,
                  style:
                      const TextStyle(color: _bsSub, fontSize: 13)),
            ],
            if (extra != null) ...[const SizedBox(height: 16), extra],
            const SizedBox(height: 20),
            Row(children: actions
                .map((w) => Expanded(child: w))
                .toList()
                .fold<List<Widget>>([], (acc, w) {
              if (acc.isNotEmpty) acc.add(const SizedBox(width: 10));
              acc.add(w);
              return acc;
            })),
          ]),
        ),
      );

  Widget _dialogBtn(String label, Color color, VoidCallback onTap,
          {bool filled = false}) =>
      GestureDetector(
        onTap: onTap,
        child: Container(
          height: 42,
          decoration: BoxDecoration(
            color: filled ? color : color.withOpacity(0.08),
            borderRadius: BorderRadius.circular(10),
            border:
                filled ? null : Border.all(color: color.withOpacity(0.35)),
          ),
          child: Center(
            child: Text(label,
                style: TextStyle(
                    color: filled ? _bsWhite : color,
                    fontWeight: FontWeight.bold,
                    fontSize: 12,
                    letterSpacing: 0.8)),
          ),
        ),
      );
}

// ═════════════════════════════════════════════════
//  HONEYCOMB BACKGROUND PAINTER
// ═════════════════════════════════════════════════
class _BsHexPainter extends CustomPainter {
  final double pulse;
  _BsHexPainter({required this.pulse});

  @override
  void paint(Canvas canvas, Size size) {
    const r    = 26.0;
    final hexW = r * math.sqrt(3);
    final hexH = r * 2;
    final cols = (size.width  / hexW).ceil() + 2;
    final rows = (size.height / (hexH * 0.75)).ceil() + 2;

    for (int row = -1; row < rows; row++) {
      for (int col = -1; col < cols; col++) {
        final dx   = col * hexW + (row.isOdd ? hexW / 2 : 0);
        final dy   = row * hexH * 0.75;
        final cx   = size.width  / 2;
        final cy   = size.height / 2;
        final dist = math.sqrt(
            math.pow(dx - cx, 2) + math.pow(dy - cy, 2));
        final maxD = math.sqrt(
            math.pow(size.width, 2) + math.pow(size.height, 2)) / 2;
        final norm  = (dist / maxD).clamp(0.0, 1.0);
        final wave  = math.sin(
            (norm * math.pi * 2) - (pulse * math.pi * 2));
        final alpha = (0.022 + wave * 0.015).clamp(0.006, 0.055);

        final paint = Paint()
          ..color       = const Color(0xFF2563eb).withOpacity(alpha)
          ..style       = PaintingStyle.stroke
          ..strokeWidth = 0.75;

        final path = Path();
        for (int i = 0; i < 6; i++) {
          final angle = (math.pi / 180) * (60 * i - 30);
          final x     = dx + r * math.cos(angle);
          final y     = dy + r * math.sin(angle);
          if (i == 0) path.moveTo(x, y);
          else         path.lineTo(x, y);
        }
        path.close();
        canvas.drawPath(path, paint);
      }
    }
  }

  @override
  bool shouldRepaint(_BsHexPainter old) => old.pulse != pulse;
}
