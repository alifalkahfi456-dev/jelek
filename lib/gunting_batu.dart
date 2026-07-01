import 'dart:async';
import 'dart:math' as math;
import 'package:flutter/material.dart';

// ─── PALETTE RAINBOW CYBER ──────────────────────────────────────────────
class _C {
  static const bg          = Color(0xFF0A0015);
  static const surface     = Color(0xFF15002A);
  static const card        = Color(0xFF1A0A2E);
  static const border      = Color(0xFF5B2D8E);
  static const purple      = Color(0xFF7C3AED);
  static const purpleL     = Color(0xFFA78BFA);
  static const purpleG     = Color(0xFFF0ABFC);
  static const pink        = Color(0xFFE879F9);
  static const cyan        = Color(0xFF67E8F9);
  static const blue        = Color(0xFF60A5FA);
  static const green       = Color(0xFF34D399);
  static const yellow      = Color(0xFFFBBF24);
  static const orange      = Color(0xFFFB923C);
  static const red         = Color(0xFFF87171);
  static const rose        = Color(0xFFFB7185);
  static const text        = Color(0xFFF3E8FF);
  static const textSub     = Color(0xFFD4C4F0);
  static const textDim     = Color(0xFF8B7AAA);
  static const white       = Color(0xFFFFFFFF);
  static const List<Color> rainbow = [purple, pink, cyan, green, yellow, orange, red, purpleL, blue];
}

class SuitPage extends StatefulWidget {
  final String username;
  const SuitPage({super.key, required this.username});

  @override
  State<SuitPage> createState() => _SuitPageState();
}

class _SuitPageState extends State<SuitPage> with SingleTickerProviderStateMixin {
  // ─── STATE ──────────────────────────────────────────────────────────────
  int playerScore = 0, aiScore = 0;
  String playerChoice = "", aiChoice = "";
  String statusText = "Tekan MULAI untuk Bermain";
  bool isGameStarted = false, isCountingDown = false, canSelect = false, showRoundResult = false, isMatchOver = false;
  String matchResult = "";
  int countdownValue = 0;
  final List<String> choices = ['batu', 'gunting', 'kertas'];
  final math.Random random = math.Random();

  // ─── ANIMATIONS ──────────────────────────────────────────────────────────
  late AnimationController _fadeCtrl, _pulseCtrl, _rotateCtrl, _slideCtrl, _shakeCtrl;
  late Animation<double> _fadeAnim, _pulseAnim, _slideAnimX, _shakeAnim;
  late Animation<Offset> _slideAnim;

  // ─── DIGITAL CLOCK ──────────────────────────────────────────────────────
  Timer? _clockTimer;
  String _timeWIB = '--:--:--', _timeWITA = '--:--:--', _timeWIT = '--:--:--';
  bool _showColon = true;

  @override
  void initState() {
    super.initState();
    _fadeCtrl = AnimationController(vsync: this, duration: const Duration(milliseconds: 800))..forward();
    _fadeAnim = CurvedAnimation(parent: _fadeCtrl, curve: Curves.easeOut);
    _pulseCtrl = AnimationController(vsync: this, duration: const Duration(milliseconds: 1500))..repeat(reverse: true);
    _pulseAnim = CurvedAnimation(parent: _pulseCtrl, curve: Curves.easeInOut);
    _rotateCtrl = AnimationController(vsync: this, duration: const Duration(seconds: 20))..repeat();
    _slideCtrl = AnimationController(vsync: this, duration: const Duration(milliseconds: 500));
    _slideAnim = Tween<Offset>(begin: const Offset(0, 0.3), end: Offset.zero).animate(CurvedAnimation(parent: _slideCtrl, curve: Curves.easeOutCubic));
    _slideAnimX = Tween<double>(begin: -0.3, end: 0).animate(CurvedAnimation(parent: _slideCtrl, curve: Curves.easeOutCubic));
    _shakeCtrl = AnimationController(vsync: this, duration: const Duration(milliseconds: 400));
    _shakeAnim = TweenSequence<double>([
      TweenSequenceItem(tween: Tween(begin: 0, end: -8), weight: 1),
      TweenSequenceItem(tween: Tween(begin: -8, end: 8), weight: 2),
      TweenSequenceItem(tween: Tween(begin: 8, end: -6), weight: 2),
      TweenSequenceItem(tween: Tween(begin: -6, end: 6), weight: 2),
      TweenSequenceItem(tween: Tween(begin: 6, end: 0), weight: 1),
    ]).animate(CurvedAnimation(parent: _shakeCtrl, curve: Curves.easeInOut));

    _updateClock();
    _clockTimer = Timer.periodic(const Duration(seconds: 1), (_) {
      _updateClock();
      setState(() => _showColon = !_showColon);
    });
  }

  @override
  void dispose() {
    _clockTimer?.cancel();
    _fadeCtrl.dispose(); _pulseCtrl.dispose(); _rotateCtrl.dispose(); _slideCtrl.dispose(); _shakeCtrl.dispose();
    super.dispose();
  }

  void _updateClock() {
    final now = DateTime.now().toUtc();
    final wib = now.add(const Duration(hours: 7));
    final wita = now.add(const Duration(hours: 8));
    final wit = now.add(const Duration(hours: 9));
    setState(() {
      _timeWIB = _formatTime(wib);
      _timeWITA = _formatTime(wita);
      _timeWIT = _formatTime(wit);
    });
  }

  String _formatTime(DateTime time) => '${time.hour.toString().padLeft(2, '0')}:${time.minute.toString().padLeft(2, '0')}:${time.second.toString().padLeft(2, '0')}';

  void startMatch() {
    setState(() {
      playerScore = 0; aiScore = 0; isMatchOver = false; matchResult = "";
      playerChoice = ""; aiChoice = "";
    });
    startCountdown();
  }

  void startCountdown() async {
    setState(() { isCountingDown = true; canSelect = false; showRoundResult = false; statusText = "Bersiap..."; });
    for (int i = 3; i > 0; i--) {
      setState(() { statusText = i.toString(); countdownValue = i; });
      await Future.delayed(const Duration(seconds: 1));
    }
    setState(() { statusText = "MULAI!"; });
    await Future.delayed(const Duration(milliseconds: 600));
    setState(() { isCountingDown = false; isGameStarted = true; canSelect = true; statusText = "Pilih Senjata!"; });
  }

  void onPlayerSelect(String choice) async {
    if (!canSelect) return;
    setState(() { playerChoice = choice; canSelect = false; statusText = "Lawan Memilih..."; });
    await Future.delayed(const Duration(milliseconds: 800));
    String aiPicked = choices[random.nextInt(3)];
    String roundResult = determineWinner(choice, aiPicked);
    setState(() { aiChoice = aiPicked; showRoundResult = true; });
    if (roundResult == "win") { playerScore++; statusText = "Kamu Menang! 🎉"; }
    else if (roundResult == "lose") { aiScore++; statusText = "Kamu Kalah! 😢"; }
    else { statusText = "Seri! 🤝"; }
    await Future.delayed(const Duration(seconds: 1));
    if (playerScore == 3) endMatch("WIN");
    else if (aiScore == 3) endMatch("LOSE");
    else {
      setState(() { showRoundResult = false; playerChoice = ""; aiChoice = ""; statusText = "Ronde Selanjutnya..."; });
      await Future.delayed(const Duration(milliseconds: 500));
      startCountdown();
    }
  }

  String determineWinner(String p, String a) {
    if (p == a) return "draw";
    if ((p == 'batu' && a == 'gunting') || (p == 'gunting' && a == 'kertas') || (p == 'kertas' && a == 'batu')) return "win";
    return "lose";
  }

  void endMatch(String result) {
    setState(() { isMatchOver = true; isGameStarted = false; canSelect = false; matchResult = result; });
    _shakeCtrl.forward(from: 0);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _C.bg,
      body: Stack(
        children: [
          _buildAnimatedBackground(),
          _buildGlowOrbs(),
          SafeArea(
            child: FadeTransition(
              opacity: _fadeAnim,
              child: Column(
                children: [
                  _buildHeader(),
                  _buildDigitalClock(),
                  _buildScoreBoard(),
                  Expanded(child: _buildArena()),
                  _buildControls(),
                ],
              ),
            ),
          ),
          if (isMatchOver) _buildGameOverOverlay(),
        ],
      ),
    );
  }

  Widget _buildAnimatedBackground() => AnimatedBuilder(
    animation: _rotateCtrl,
    builder: (_, __) => Container(
      decoration: BoxDecoration(
        gradient: RadialGradient(
          center: Alignment(math.sin(_rotateCtrl.value * 0.5) * 0.3, math.cos(_rotateCtrl.value * 0.7) * 0.3),
          radius: 1.5,
          colors: [
            _C.rainbow[_rotateCtrl.value.toInt() % _C.rainbow.length].withOpacity(0.06),
            _C.rainbow[(_rotateCtrl.value.toInt() + 3) % _C.rainbow.length].withOpacity(0.04),
            _C.bg,
          ],
          stops: const [0.0, 0.5, 1.0],
        ),
      ),
    ),
  );

  Widget _buildGlowOrbs() => Stack(
    children: List.generate(6, (i) {
      final angle = (i / 6) * 2 * math.pi;
      return AnimatedBuilder(
        animation: _rotateCtrl,
        builder: (_, __) {
          final x = math.cos(_rotateCtrl.value * 0.4 + angle) * 160;
          final y = math.sin(_rotateCtrl.value * 0.6 + angle) * 100;
          final color = _C.rainbow[(i * 2) % _C.rainbow.length];
          return Positioned(
            left: MediaQuery.of(context).size.width / 2 + x - 30,
            top: MediaQuery.of(context).size.height / 2 + y - 30,
            child: Container(
              width: 60 + 20 * math.sin(_rotateCtrl.value + i).abs(),
              height: 60 + 20 * math.sin(_rotateCtrl.value + i).abs(),
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: RadialGradient(colors: [color.withOpacity(0.05), Colors.transparent], radius: 0.7),
              ),
            ),
          );
        },
      );
    }),
  );

  Widget _buildHeader() => Container(
    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
    child: Row(
      children: [
        AnimatedBuilder(
          animation: _pulseCtrl,
          builder: (_, __) => Transform.scale(
            scale: 1 + _pulseCtrl.value * 0.05,
            child: Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                gradient: LinearGradient(colors: [_C.purple, _C.pink]),
                borderRadius: BorderRadius.circular(12),
                boxShadow: [BoxShadow(color: _C.purple.withOpacity(0.3), blurRadius: 16 + _pulseCtrl.value * 8)],
              ),
              child: const Icon(Icons.gamepad_rounded, color: Colors.white, size: 22),
            ),
          ),
        ),
        const SizedBox(width: 12),
        const Text('SUIT GAME', style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold, fontFamily: 'Orbitron', letterSpacing: 2)),
        const Spacer(),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: _C.green.withOpacity(0.5)),
            color: _C.green.withOpacity(0.1),
          ),
          child: Row(
            children: [
              Container(width: 6, height: 6, decoration: BoxDecoration(color: _C.green, shape: BoxShape.circle, boxShadow: [BoxShadow(color: _C.green.withOpacity(0.5), blurRadius: 8)])),
              const SizedBox(width: 6),
              Text('LIVE', style: TextStyle(color: _C.green, fontSize: 10, fontWeight: FontWeight.bold, fontFamily: 'Orbitron')),
            ],
          ),
        ),
      ],
    ),
  );

  Widget _buildDigitalClock() => Container(
    margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
    padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
    decoration: BoxDecoration(
      color: _C.card.withOpacity(0.4),
      borderRadius: BorderRadius.circular(14),
      border: Border.all(color: _C.rainbow[DateTime.now().second % _C.rainbow.length].withOpacity(0.2), width: 1),
    ),
    child: Column(
      children: [
        AnimatedBuilder(
          animation: _pulseCtrl,
          builder: (_, __) => Container(
            height: 2,
            width: double.infinity,
            decoration: BoxDecoration(
              gradient: LinearGradient(colors: [Colors.transparent, ..._C.rainbow, Colors.transparent]),
              borderRadius: BorderRadius.circular(2),
              boxShadow: [BoxShadow(color: _C.purple.withOpacity(0.5), blurRadius: 14)],
            ),
          ),
        ),
        const SizedBox(height: 6),
        Row(mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: [
            _clockItem('WIB', _timeWIB, _C.purpleL),
            _clockItem('WITA', _timeWITA, _C.pink),
            _clockItem('WIT', _timeWIT, _C.cyan),
          ],
        ),
        const SizedBox(height: 4),
        Row(mainAxisAlignment: MainAxisAlignment.center,
          children: [
            AnimatedContainer(duration: const Duration(milliseconds: 500), width: 5, height: 5,
              decoration: BoxDecoration(color: _showColon ? _C.green : _C.green.withOpacity(0.15), shape: BoxShape.circle,
                boxShadow: [BoxShadow(color: _C.green.withOpacity(_showColon ? 0.8 : 0.05), blurRadius: 8)])),
            const SizedBox(width: 6),
            Text('LIVE', style: TextStyle(color: _C.green.withOpacity(_showColon ? 0.9 : 0.2), fontSize: 8, fontWeight: FontWeight.w700, letterSpacing: 1.5, fontFamily: 'Orbitron')),
          ],
        ),
      ],
    ),
  );

  Widget _clockItem(String label, String time, Color color) => Column(
    children: [
      Text(label, style: TextStyle(color: _C.textDim.withOpacity(0.5), fontSize: 8, fontWeight: FontWeight.w600, letterSpacing: 1.2, fontFamily: 'Orbitron')),
      const SizedBox(height: 2),
      Stack(
        children: [
          Text(time, style: TextStyle(color: color.withOpacity(0.08), fontSize: 14, fontWeight: FontWeight.w700, fontFamily: 'Orbitron', letterSpacing: 1.5, shadows: [Shadow(color: color.withOpacity(0.3), blurRadius: 25)])),
          Text(time, style: TextStyle(color: color.withOpacity(0.2), fontSize: 14, fontWeight: FontWeight.w700, fontFamily: 'Orbitron', letterSpacing: 1.5, shadows: [Shadow(color: color.withOpacity(0.6), blurRadius: 40)])),
          Text(time, style: TextStyle(color: Colors.white, fontSize: 14, fontWeight: FontWeight.w700, fontFamily: 'Orbitron', letterSpacing: 1.5, shadows: [Shadow(color: color, blurRadius: 12)])),
        ],
      ),
    ],
  );

  Widget _buildScoreBoard() => Container(
    margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
    padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 20),
    decoration: BoxDecoration(
      gradient: LinearGradient(colors: [_C.card.withOpacity(0.5), _C.surface.withOpacity(0.4)]),
      borderRadius: BorderRadius.circular(16),
      border: Border.all(color: _C.border.withOpacity(0.3)),
    ),
    child: Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        _buildScoreItem("PLAYER", playerScore, _C.blue, Icons.person_rounded),
        AnimatedBuilder(
          animation: _pulseCtrl,
          builder: (_, __) => Text("⚔️", style: TextStyle(fontSize: 24, shadows: [Shadow(color: _C.purple.withOpacity(0.3 * _pulseCtrl.value), blurRadius: 20)])),
        ),
        _buildScoreItem("AI", aiScore, _C.red, Icons.computer_rounded),
      ],
    ),
  );

  Widget _buildScoreItem(String label, int score, Color color, IconData icon) => Column(
    children: [
      Row(children: [Icon(icon, color: color, size: 14), const SizedBox(width: 4), Text(label, style: TextStyle(color: _C.textDim, fontSize: 10, fontWeight: FontWeight.w600, fontFamily: 'Orbitron'))]),
      const SizedBox(height: 4),
      AnimatedSwitcher(
        duration: const Duration(milliseconds: 300),
        transitionBuilder: (child, anim) => ScaleTransition(scale: anim, child: child),
        child: Text('$score', key: ValueKey(score),
          style: TextStyle(color: color, fontSize: 24, fontWeight: FontWeight.bold, fontFamily: 'Orbitron', shadows: [Shadow(color: color.withOpacity(0.3), blurRadius: 12)])),
      ),
    ],
  );

  Widget _buildArena() => Center(
    child: Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          AnimatedBuilder(
            animation: _pulseCtrl,
            builder: (_, __) => Text(
              statusText,
              textAlign: TextAlign.center,
              style: TextStyle(
                color: _C.text,
                fontSize: isCountingDown ? 64 : 28,
                fontWeight: FontWeight.bold,
                fontFamily: isCountingDown ? 'Orbitron' : 'ShareTechMono',
                shadows: [Shadow(color: _C.purple.withOpacity(0.3 * _pulseCtrl.value), blurRadius: 20)],
              ),
            ),
          ),
          const SizedBox(height: 20),
          if (showRoundResult || (isGameStarted && !canSelect && playerChoice.isNotEmpty))
            SlideTransition(
              position: _slideAnim,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  _buildChoiceCard("Kamu", playerChoice, _C.blue),
                  const Text("⚔️", style: TextStyle(fontSize: 30, color: Colors.white)),
                  _buildChoiceCard("AI", aiChoice, _C.red),
                ],
              ),
            ),
        ],
      ),
    ),
  );

  Widget _buildChoiceCard(String label, String choice, Color color) {
    final iconMap = {'batu': Icons.panorama_fish_eye, 'gunting': Icons.content_cut, 'kertas': Icons.description};
    return Column(
      children: [
        Text(label, style: TextStyle(color: _C.textDim, fontSize: 12, fontFamily: 'Orbitron')),
        const SizedBox(height: 8),
        AnimatedBuilder(
          animation: _pulseCtrl,
          builder: (_, __) => Container(
            width: 90, height: 90,
            decoration: BoxDecoration(
              gradient: LinearGradient(colors: [color.withOpacity(0.2), color.withOpacity(0.05)]),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: color.withOpacity(0.4), width: 2),
              boxShadow: [BoxShadow(color: color.withOpacity(0.2), blurRadius: 20 + _pulseCtrl.value * 10)],
            ),
            child: Icon(iconMap[choice] ?? Icons.help, size: 44, color: color),
          ),
        ),
        const SizedBox(height: 4),
        Text(choice.toUpperCase(), style: TextStyle(color: _C.textSub, fontWeight: FontWeight.bold, fontFamily: 'Orbitron', fontSize: 12)),
      ],
    );
  }

  Widget _buildControls() => Padding(
    padding: const EdgeInsets.all(20),
    child: Column(
      children: [
        if (!isGameStarted && !isCountingDown && !isMatchOver)
          GestureDetector(
            onTap: startMatch,
            child: AnimatedBuilder(
              animation: _pulseCtrl,
              builder: (_, __) => Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(vertical: 16),
                decoration: BoxDecoration(
                  gradient: LinearGradient(colors: [_C.purple, _C.pink]),
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: [BoxShadow(color: _C.purple.withOpacity(0.3), blurRadius: 20 + _pulseCtrl.value * 10)],
                ),
                child: const Text("MULAI GAME", textAlign: TextAlign.center,
                  style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold, fontFamily: 'Orbitron', letterSpacing: 2)),
              ),
            ),
          ),
        if (canSelect)
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: choices.map((choice) => _buildSelectButton(choice)).toList(),
          ),
      ],
    ),
  );

  Widget _buildSelectButton(String choice) {
    final iconMap = {'batu': Icons.panorama_fish_eye, 'gunting': Icons.content_cut, 'kertas': Icons.description};
    return GestureDetector(
      onTap: () => onPlayerSelect(choice),
      child: AnimatedBuilder(
        animation: _pulseCtrl,
        builder: (_, __) => Container(
          width: 80, height: 80,
          decoration: BoxDecoration(
            gradient: LinearGradient(colors: [_C.card, _C.surface]),
            shape: BoxShape.circle,
            border: Border.all(color: _C.rainbow[choices.indexOf(choice) % _C.rainbow.length].withOpacity(0.5), width: 2),
            boxShadow: [BoxShadow(color: _C.purple.withOpacity(0.15 * _pulseCtrl.value), blurRadius: 20 + _pulseCtrl.value * 10)],
          ),
          child: Icon(iconMap[choice] ?? Icons.help, size: 40, color: _C.rainbow[choices.indexOf(choice) % _C.rainbow.length]),
        ),
      ),
    );
  }

  Widget _buildGameOverOverlay() => AnimatedBuilder(
    animation: _shakeAnim,
    builder: (_, __) => Transform.translate(
      offset: Offset(_shakeAnim.value, 0),
      child: Container(
        width: double.infinity,
        height: double.infinity,
        color: Colors.black.withOpacity(0.85),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            AnimatedBuilder(
              animation: _pulseCtrl,
              builder: (_, __) => Transform.scale(
                scale: 1 + _pulseCtrl.value * 0.03,
                child: Icon(
                  matchResult == "WIN" ? Icons.emoji_events : Icons.close,
                  size: 100,
                  color: matchResult == "WIN" ? _C.yellow : _C.red,
                ),
              ),
            ),
            const SizedBox(height: 20),
            Text(
              matchResult == "WIN" ? "🏆 YOU WIN!" : "💀 LOSE!",
              style: TextStyle(
                fontSize: 42,
                fontWeight: FontWeight.bold,
                color: matchResult == "WIN" ? _C.yellow : _C.red,
                fontFamily: 'Orbitron',
                shadows: [Shadow(color: (matchResult == "WIN" ? _C.yellow : _C.red).withOpacity(0.3), blurRadius: 30)],
              ),
            ),
            const SizedBox(height: 10),
            Text("Skor Akhir: $playerScore - $aiScore", style: TextStyle(color: _C.textSub, fontSize: 18, fontFamily: 'Orbitron')),
            const SizedBox(height: 40),
            GestureDetector(
              onTap: startMatch,
              child: AnimatedBuilder(
                animation: _pulseCtrl,
                builder: (_, __) => Container(
                  padding: const EdgeInsets.symmetric(horizontal: 50, vertical: 16),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(colors: [_C.purple, _C.pink]),
                    borderRadius: BorderRadius.circular(16),
                    boxShadow: [BoxShadow(color: _C.purple.withOpacity(0.3), blurRadius: 20 + _pulseCtrl.value * 10)],
                  ),
                  child: const Text("MAIN LAGI", style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold, fontFamily: 'Orbitron', letterSpacing: 2)),
                ),
              ),
            ),
          ],
        ),
      ),
    ),
  );
}