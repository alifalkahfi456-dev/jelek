import 'dart:convert';
import 'dart:math' as math;
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:http/http.dart' as http;

// ─────────────────────────────────────────────
//  PALETTE  (sama dengan dashboard & landing)
// ─────────────────────────────────────────────
const Color _spBg      = Color(0xFF0b1120);
const Color _spCard    = Color(0xFF111827);
const Color _spCard2   = Color(0xFF0d1b2e);
const Color _spBorder  = Color(0xFF1e2d45);
const Color _spBlue    = Color(0xFF2563eb);
const Color _spCyan    = Color(0xFF22d3ee);
const Color _spGreen   = Color(0xFF22c55e);
const Color _spRed     = Color(0xFFef4444);
const Color _spAmber   = Color(0xFFf59e0b);
const Color _spWhite   = Colors.white;
const Color _spSub     = Color(0xFF94a3b8);

class SellerPage extends StatefulWidget {
  final String keyToken;
  const SellerPage({super.key, required this.keyToken});

  @override
  State<SellerPage> createState() => _SellerPageState();
}

class _SellerPageState extends State<SellerPage>
    with SingleTickerProviderStateMixin {
  // ── Controllers ───────────────────────────────
  final _newUser  = TextEditingController();
  final _newPass  = TextEditingController();
  final _days     = TextEditingController();
  final _editUser = TextEditingController();
  final _editDays = TextEditingController();

  late AnimationController _hexCtrl;
  late Animation<double>   _hexAnim;

  bool _loading      = false;
  bool _obscurePass  = true;

  // ─────────────────────────────────────────────
  @override
  void initState() {
    super.initState();
    _hexCtrl = AnimationController(
        vsync: this, duration: const Duration(seconds: 4))
      ..repeat(reverse: true);
    _hexAnim = CurvedAnimation(parent: _hexCtrl, curve: Curves.easeInOut);
  }

  @override
  void dispose() {
    _hexCtrl.dispose();
    _newUser.dispose();
    _newPass.dispose();
    _days.dispose();
    _editUser.dispose();
    _editDays.dispose();
    super.dispose();
  }

  // ── API ──────────────────────────────────────
  Future<void> _create() async {
    final u = _newUser.text.trim();
    final p = _newPass.text.trim();
    final d = _days.text.trim();
    if (u.isEmpty || p.isEmpty || d.isEmpty) {
      _alert('Semua field wajib diisi', isError: true);
      return;
    }
    setState(() => _loading = true);
    try {
      final res = await http.get(Uri.parse(
          'http://saitama.omdhancivok.my.id:2001/createAccount'
          '?key=${widget.keyToken}&newUser=$u&pass=$p&day=$d'));
      final data = jsonDecode(res.body) as Map<String, dynamic>;
      if (data['created'] == true) {
        _alert('Akun berhasil dibuat!');
        _newUser.clear();
        _newPass.clear();
        _days.clear();
      } else {
        _alert(data['message'] as String? ?? 'Gagal membuat akun.',
            isError: true);
      }
    } catch (e) {
      _alert('Koneksi gagal: $e', isError: true);
    } finally {
      setState(() => _loading = false);
    }
  }

  Future<void> _edit() async {
    final u = _editUser.text.trim();
    final d = _editDays.text.trim();
    if (u.isEmpty || d.isEmpty) {
      _alert('Username dan durasi wajib diisi', isError: true);
      return;
    }
    setState(() => _loading = true);
    try {
      final res = await http.get(Uri.parse(
          'http://saitama.omdhancivok.my.id:2001/editUser'
          '?key=${widget.keyToken}&username=$u&addDays=$d'));
      final data = jsonDecode(res.body) as Map<String, dynamic>;
      if (data['edited'] == true) {
        _alert('Durasi berhasil diperbarui.');
        _editUser.clear();
        _editDays.clear();
      } else {
        _alert(data['message'] as String? ?? 'Gagal mengubah durasi.',
            isError: true);
      }
    } catch (e) {
      _alert('Koneksi gagal: $e', isError: true);
    } finally {
      setState(() => _loading = false);
    }
  }

  // ── Alert dialog ─────────────────────────────
  void _alert(String msg, {bool isError = false}) {
    final color = isError ? _spRed : _spGreen;
    final icon  = isError
        ? Icons.error_outline_rounded
        : Icons.check_circle_outline_rounded;

    showDialog(
      context: context,
      builder: (_) => BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 12, sigmaY: 12),
        child: Dialog(
          backgroundColor: _spCard,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(22),
            side: BorderSide(color: color.withOpacity(0.35), width: 1.2),
          ),
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(mainAxisSize: MainAxisSize.min, children: [
              Container(
                width: 56,
                height: 56,
                decoration: BoxDecoration(
                  color: color.withOpacity(0.1),
                  shape: BoxShape.circle,
                  border: Border.all(color: color.withOpacity(0.35)),
                ),
                child: Icon(icon, color: color, size: 28),
              ),
              const SizedBox(height: 14),
              Text(
                isError ? 'Gagal' : 'Berhasil',
                style: const TextStyle(
                    color: _spWhite,
                    fontWeight: FontWeight.bold,
                    fontSize: 16),
              ),
              const SizedBox(height: 8),
              Text(
                msg,
                textAlign: TextAlign.center,
                style: const TextStyle(color: _spSub, fontSize: 13, height: 1.5),
              ),
              const SizedBox(height: 20),
              GestureDetector(
                onTap: () => Navigator.pop(context),
                child: Container(
                  width: double.infinity,
                  height: 44,
                  decoration: BoxDecoration(
                    color: color.withOpacity(0.15),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: color.withOpacity(0.4)),
                  ),
                  child: Center(
                    child: Text('OK',
                        style: TextStyle(
                            color: color,
                            fontWeight: FontWeight.bold,
                            letterSpacing: 1)),
                  ),
                ),
              ),
            ]),
          ),
        ),
      ),
    );
  }

  // ─────────────────────────────────────────────
  //  BUILD
  // ─────────────────────────────────────────────
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _spBg,
      body: Stack(children: [
        // ── Honeycomb background ───────────────
        Positioned.fill(
          child: AnimatedBuilder(
            animation: _hexAnim,
            builder: (_, __) => CustomPaint(
              painter: _SpHexPainter(pulse: _hexAnim.value),
            ),
          ),
        ),

        // ── Content ───────────────────────────
        SafeArea(
          child: Column(children: [
            _appBar(),
            Expanded(
              child: SingleChildScrollView(
                physics: const BouncingScrollPhysics(),
                padding: const EdgeInsets.fromLTRB(16, 16, 16, 40),
                child: Column(children: [
                  _headerCard(),
                  const SizedBox(height: 16),
                  _createCard(),
                  const SizedBox(height: 16),
                  _editCard(),
                  const SizedBox(height: 16),
                  _infoCard(),
                ]),
              ),
            ),
          ]),
        ),
      ]),
    );
  }

  // ─────────────────────────────────────────────
  //  APP BAR
  // ─────────────────────────────────────────────
  Widget _appBar() => Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 10),
        decoration: const BoxDecoration(
          color: _spCard,
          border: Border(bottom: BorderSide(color: _spBorder, width: 1)),
        ),
        child: Row(children: [
          // Back btn
          _iconBtn(
            icon: Icons.arrow_back_ios_rounded,
            onTap: () => Navigator.pop(context),
          ),
          const SizedBox(width: 12),

          // Title
          Expanded(
            child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  ShaderMask(
                    shaderCallback: (r) => const LinearGradient(
                            colors: [_spBlue, _spCyan])
                        .createShader(r),
                    child: const Text('SELLER PANEL',
                        style: TextStyle(
                            color: _spWhite,
                            fontWeight: FontWeight.w900,
                            fontSize: 15,
                            letterSpacing: 1.5)),
                  ),
                  const Text('Kelola Akun Reseller',
                      style: TextStyle(color: _spSub, fontSize: 11)),
                ]),
          ),

          // Store icon badge
          Container(
            width: 38,
            height: 38,
            decoration: BoxDecoration(
              color: _spBlue.withOpacity(0.15),
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: _spBlue.withOpacity(0.3)),
            ),
            child: const Icon(Icons.store_rounded, color: _spCyan, size: 20),
          ),
        ]),
      );

  // ─────────────────────────────────────────────
  //  HEADER CARD
  // ─────────────────────────────────────────────
  Widget _headerCard() => _card(
        child: Row(children: [
          // Hex deco
          Column(children: [
            for (int i = 0; i < 3; i++) ...[
              CustomPaint(
                size: const Size(22, 22),
                painter: _SpSingleHex(
                  color: i == 1
                      ? _spCyan.withOpacity(0.7)
                      : _spBlue.withOpacity(0.4),
                  filled: i == 1,
                ),
              ),
              if (i < 2) const SizedBox(height: 4),
            ],
          ]),
          const SizedBox(width: 16),

          Expanded(
            child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  ShaderMask(
                    shaderCallback: (r) => const LinearGradient(
                            colors: [Color(0xFF60a5fa), _spBlue])
                        .createShader(r),
                    child: const Text('RESELLER PANEL',
                        style: TextStyle(
                            color: _spWhite,
                            fontWeight: FontWeight.w900,
                            fontSize: 20,
                            letterSpacing: 2)),
                  ),
                  const SizedBox(height: 4),
                  const Text('Kelola dan buat akun user baru',
                      style: TextStyle(color: _spSub, fontSize: 12)),
                ]),
          ),

          // Badge
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
            decoration: BoxDecoration(
              color: _spGreen.withOpacity(0.12),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: _spGreen.withOpacity(0.3)),
            ),
            child: const Text('ACTIVE',
                style: TextStyle(
                    color: _spGreen,
                    fontSize: 10,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 1)),
          ),
        ]),
      );

  // ─────────────────────────────────────────────
  //  CREATE ACCOUNT CARD
  // ─────────────────────────────────────────────
  Widget _createCard() => _card(
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          // Section header
          _sectionHeader(
            icon: Icons.person_add_rounded,
            title: 'Buat Akun Baru',
            color: _spBlue,
          ),
          const SizedBox(height: 16),

          _inputField(
            ctrl: _newUser,
            label: 'Username',
            hint: 'Masukkan username',
            icon: Icons.person_outline_rounded,
          ),
          const SizedBox(height: 12),

          _inputField(
            ctrl: _newPass,
            label: 'Password',
            hint: 'Masukkan password',
            icon: Icons.lock_outline_rounded,
            obscure: _obscurePass,
            suffix: IconButton(
              icon: Icon(
                _obscurePass
                    ? Icons.visibility_off_rounded
                    : Icons.visibility_rounded,
                color: _spSub,
                size: 18,
              ),
              onPressed: () =>
                  setState(() => _obscurePass = !_obscurePass),
            ),
          ),
          const SizedBox(height: 12),

          _inputField(
            ctrl: _days,
            label: 'Durasi (hari)',
            hint: 'Contoh: 30',
            icon: Icons.calendar_today_rounded,
            keyboard: TextInputType.number,
            inputFormatters: [FilteringTextInputFormatter.digitsOnly],
          ),
          const SizedBox(height: 20),

          _actionBtn(
            label: 'BUAT AKUN',
            icon: Icons.person_add_rounded,
            onTap: _create,
            gradient: const [Color(0xFF1d4ed8), Color(0xFF2563eb)],
            glowColor: _spBlue,
          ),
        ]),
      );

  // ─────────────────────────────────────────────
  //  EDIT DURATION CARD
  // ─────────────────────────────────────────────
  Widget _editCard() => _card(
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          _sectionHeader(
            icon: Icons.edit_calendar_rounded,
            title: 'Ubah Durasi',
            color: _spCyan,
          ),
          const SizedBox(height: 16),

          _inputField(
            ctrl: _editUser,
            label: 'Username',
            hint: 'Username yang ingin diubah',
            icon: Icons.person_search_rounded,
          ),
          const SizedBox(height: 12),

          _inputField(
            ctrl: _editDays,
            label: 'Tambah Durasi (hari)',
            hint: 'Contoh: 7',
            icon: Icons.more_time_rounded,
            keyboard: TextInputType.number,
            inputFormatters: [FilteringTextInputFormatter.digitsOnly],
          ),
          const SizedBox(height: 20),

          _actionBtn(
            label: 'UBAH DURASI',
            icon: Icons.update_rounded,
            onTap: _edit,
            gradient: const [Color(0xFF0891b2), Color(0xFF22d3ee)],
            glowColor: _spCyan,
          ),
        ]),
      );

  // ─────────────────────────────────────────────
  //  INFO CARD
  // ─────────────────────────────────────────────
  Widget _infoCard() => Container(
        width: double.infinity,
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: _spAmber.withOpacity(0.07),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: _spAmber.withOpacity(0.2)),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Icon(Icons.info_outline_rounded,
                color: _spAmber, size: 16),
            const SizedBox(width: 10),
            const Expanded(
              child: Text(
                'Gunakan panel ini untuk mengelola akun reseller Anda. '
                'Pastikan data yang dimasukkan sudah benar sebelum submit.',
                style: TextStyle(
                    color: _spAmber, fontSize: 12, height: 1.5),
              ),
            ),
          ],
        ),
      );

  // ─────────────────────────────────────────────
  //  HELPERS
  // ─────────────────────────────────────────────
  Widget _card({required Widget child}) => Container(
        width: double.infinity,
        padding: const EdgeInsets.all(18),
        decoration: BoxDecoration(
          color: _spCard,
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: _spBorder),
          boxShadow: [
            BoxShadow(
                color: Colors.black.withOpacity(0.3),
                blurRadius: 12,
                offset: const Offset(0, 4)),
          ],
        ),
        child: child,
      );

  Widget _sectionHeader({
    required IconData icon,
    required String title,
    required Color color,
  }) =>
      Row(children: [
        Container(
          width: 36,
          height: 36,
          decoration: BoxDecoration(
            color: color.withOpacity(0.12),
            borderRadius: BorderRadius.circular(10),
            border: Border.all(color: color.withOpacity(0.3)),
          ),
          child: Icon(icon, color: color, size: 18),
        ),
        const SizedBox(width: 12),
        Text(title,
            style: const TextStyle(
                color: _spWhite,
                fontWeight: FontWeight.bold,
                fontSize: 15,
                letterSpacing: 0.3)),
      ]);

  Widget _inputField({
    required TextEditingController ctrl,
    required String label,
    required String hint,
    required IconData icon,
    TextInputType keyboard = TextInputType.text,
    bool obscure = false,
    Widget? suffix,
    List<TextInputFormatter>? inputFormatters,
  }) =>
      TextField(
        controller: ctrl,
        keyboardType: keyboard,
        obscureText: obscure,
        inputFormatters: inputFormatters,
        style: const TextStyle(color: _spWhite, fontSize: 14),
        cursorColor: _spCyan,
        decoration: InputDecoration(
          labelText: label,
          hintText: hint,
          labelStyle: const TextStyle(color: _spSub, fontSize: 13),
          hintStyle: TextStyle(color: _spSub.withOpacity(0.5), fontSize: 13),
          prefixIcon: Icon(icon, color: _spBlue.withOpacity(0.8), size: 20),
          suffixIcon: suffix,
          filled: true,
          fillColor: _spCard2,
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: const BorderSide(color: _spBorder),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: const BorderSide(color: _spCyan, width: 1.5),
          ),
          contentPadding: const EdgeInsets.symmetric(
              horizontal: 16, vertical: 14),
        ),
      );

  Widget _actionBtn({
    required String label,
    required IconData icon,
    required VoidCallback onTap,
    required List<Color> gradient,
    required Color glowColor,
  }) =>
      AnimatedOpacity(
        opacity: _loading ? 0.7 : 1.0,
        duration: const Duration(milliseconds: 200),
        child: GestureDetector(
          onTap: _loading ? null : onTap,
          child: Container(
            width: double.infinity,
            height: 52,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: gradient,
                begin: Alignment.centerLeft,
                end: Alignment.centerRight,
              ),
              borderRadius: BorderRadius.circular(14),
              boxShadow: [
                BoxShadow(
                  color: glowColor.withOpacity(0.4),
                  blurRadius: 18,
                  offset: const Offset(0, 5),
                ),
              ],
            ),
            child: Stack(alignment: Alignment.center, children: [
              // Shimmer top line
              Positioned(
                top: 0,
                left: 30,
                right: 30,
                child: Container(
                  height: 1,
                  decoration: BoxDecoration(
                    gradient: LinearGradient(colors: [
                      Colors.transparent,
                      Colors.white.withOpacity(0.3),
                      Colors.transparent,
                    ]),
                  ),
                ),
              ),
              // Button content
              _loading
                  ? const SizedBox(
                      width: 22,
                      height: 22,
                      child: CircularProgressIndicator(
                          color: _spWhite, strokeWidth: 2.5),
                    )
                  : Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Container(
                          width: 30,
                          height: 30,
                          decoration: BoxDecoration(
                            color: Colors.white.withOpacity(0.12),
                            shape: BoxShape.circle,
                          ),
                          child: Icon(icon, color: _spWhite, size: 15),
                        ),
                        const SizedBox(width: 10),
                        Text(label,
                            style: const TextStyle(
                                color: _spWhite,
                                fontWeight: FontWeight.w900,
                                fontSize: 14,
                                letterSpacing: 1.5)),
                      ],
                    ),
            ]),
          ),
        ),
      );

  Widget _iconBtn({required IconData icon, required VoidCallback onTap}) =>
      Container(
        width: 38,
        height: 38,
        decoration: BoxDecoration(
          color: _spCard2,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: _spBorder),
        ),
        child: IconButton(
          padding: EdgeInsets.zero,
          icon: Icon(icon, color: _spWhite, size: 16),
          onPressed: onTap,
        ),
      );
}

// ═════════════════════════════════════════════════
//  HONEYCOMB BACKGROUND PAINTER
// ═════════════════════════════════════════════════
class _SpHexPainter extends CustomPainter {
  final double pulse;
  _SpHexPainter({required this.pulse});

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
        final wave  =
            math.sin((norm * math.pi * 2) - (pulse * math.pi * 2));
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
  bool shouldRepaint(_SpHexPainter old) => old.pulse != pulse;
}

// ═════════════════════════════════════════════════
//  SINGLE HEX PAINTER  (deco kecil di header)
// ═════════════════════════════════════════════════
class _SpSingleHex extends CustomPainter {
  final Color color;
  final bool  filled;
  _SpSingleHex({required this.color, required this.filled});

  @override
  void paint(Canvas canvas, Size size) {
    final r     = size.width / 2;
    final paint = Paint()
      ..color       = color
      ..style       = filled ? PaintingStyle.fill : PaintingStyle.stroke
      ..strokeWidth = 1.2;
    final path = Path();
    for (int i = 0; i < 6; i++) {
      final angle = (math.pi / 180) * (60 * i - 30);
      final x     = size.width  / 2 + r * math.cos(angle);
      final y     = size.height / 2 + r * math.sin(angle);
      if (i == 0) path.moveTo(x, y);
      else         path.lineTo(x, y);
    }
    path.close();
    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(_SpSingleHex old) =>
      old.color != color || old.filled != filled;
}
