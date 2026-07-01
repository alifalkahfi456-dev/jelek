import 'dart:async';
import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:share_plus/share_plus.dart';

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
  static const gold        = Color(0xFFFFD700);
  static const text        = Color(0xFFF3E8FF);
  static const textSub     = Color(0xFFD4C4F0);
  static const textDim     = Color(0xFF8B7AAA);
  static const white       = Color(0xFFFFFFFF);
  static const List<Color> rainbow = [purple, pink, cyan, green, yellow, orange, red, purpleL, blue, gold];
}

// ─── SLOT MACHINE ──────────────────────────────────────────────────────────
class SlotMachineTools extends StatefulWidget {
  final String username;
  const SlotMachineTools({super.key, required this.username});

  @override
  State<SlotMachineTools> createState() => _SlotMachineToolsState();
}

class _SlotMachineToolsState extends State<SlotMachineTools>
    with SingleTickerProviderStateMixin {
  final math.Random _random = math.Random();
  final List<String> _icons = ["🍒", "🍊", "🍋", "🍉", "⭐", "💎", "7️⃣", "🎰"];

  String _reel1 = "🎰", _reel2 = "🎰", _reel3 = "🎰";
  int _score = 100, _bet = 10;
  bool _isSpinning = false;
  String _resultMessage = "Tekan SPIN untuk mulai!";

  late AnimationController _fadeCtrl, _pulseCtrl, _rotateCtrl, _shakeCtrl;
  late Animation<double> _fadeAnim, _pulseAnim, _shakeAnim;

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
    _shakeCtrl = AnimationController(vsync: this, duration: const Duration(milliseconds: 500));
    _shakeAnim = Tween<double>(begin: 0, end: 10).animate(CurvedAnimation(parent: _shakeCtrl, curve: Curves.elasticIn));

    _updateClock();
    _clockTimer = Timer.periodic(const Duration(seconds: 1), (_) {
      _updateClock();
      setState(() => _showColon = !_showColon);
    });
  }

  @override
  void dispose() {
    _clockTimer?.cancel();
    _fadeCtrl.dispose(); _pulseCtrl.dispose(); _rotateCtrl.dispose(); _shakeCtrl.dispose();
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

  void _spin() {
    if (_isSpinning) return;
    if (_score < _bet) {
      setState(() => _resultMessage = "❌ Saldo tidak cukup! Ambil koin gratis!");
      return;
    }
    setState(() { _isSpinning = true; _resultMessage = "🔄 Memutar..."; _score -= _bet; });
    int spinCount = 0;
    Timer.periodic(const Duration(milliseconds: 100), (timer) {
      if (spinCount >= 15) { timer.cancel(); _stopSpin(); }
      else {
        setState(() {
          _reel1 = _icons[_random.nextInt(_icons.length)];
          _reel2 = _icons[_random.nextInt(_icons.length)];
          _reel3 = _icons[_random.nextInt(_icons.length)];
        });
        spinCount++;
      }
    });
  }

  void _stopSpin() {
    final int winAmount = _calculateWin();
    setState(() {
      _isSpinning = false;
      if (winAmount > 0) {
        _score += winAmount;
        _resultMessage = "🎉 MENANG! +$winAmount koin! 🎉";
        _shakeCtrl.forward(from: 0);
      } else if (_reel1 == _reel2 && _reel2 == _reel3) {
        _score += _bet * 5;
        _resultMessage = "✨ JACKPOT! +${_bet * 5} koin! ✨";
        _shakeCtrl.forward(from: 0);
      } else {
        _resultMessage = "😢 Coba lagi!";
      }
    });
  }

  int _calculateWin() {
    if (_reel1 == "7️⃣" && _reel2 == "7️⃣" && _reel3 == "7️⃣") return _bet * 10;
    if (_reel1 == "💎" && _reel2 == "💎" && _reel3 == "💎") return _bet * 8;
    if (_reel1 == "⭐" && _reel2 == "⭐" && _reel3 == "⭐") return _bet * 6;
    if (_reel1 == _reel2 && _reel2 == _reel3) return _bet * 3;
    if (_reel1 == _reel2 || _reel2 == _reel3 || _reel1 == _reel3) return _bet * 1;
    return 0;
  }

  void _changeBet(int amount) {
    if (_isSpinning) return;
    int newBet = _bet + amount;
    if (newBet >= 5 && newBet <= 50) setState(() => _bet = newBet);
  }

  void _takeFreeCoins() {
    if (_isSpinning) return;
    setState(() { _score += 50; _resultMessage = "🎁 +50 koin gratis! 🎁"; });
  }

  void _resetGame() {
    if (_isSpinning) return;
    setState(() { _score = 100; _bet = 10; _reel1 = "🎰"; _reel2 = "🎰"; _reel3 = "🎰"; _resultMessage = "Game direset!"; });
  }

  void _shareScore() {
    Share.share("🎰 SLOT MACHINE SCORE 🎰\n\n💰 Koin: $_score\n🎲 Bet: $_bet\n🎯 Hasil: $_reel1 $_reel2 $_reel3\n📊 Status: $_resultMessage\n\n✨ Main slot seru tanpa judi! ✨");
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _C.bg,
      appBar: AppBar(
        title: const Text("Slot Machine", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontFamily: 'Orbitron')),
        backgroundColor: _C.purple,
        centerTitle: true,
        elevation: 0,
        actions: [
          IconButton(icon: const Icon(Icons.share, color: _C.gold), onPressed: _shareScore),
          IconButton(icon: const Icon(Icons.refresh, color: _C.gold), onPressed: _resetGame),
        ],
      ),
      body: Stack(
        children: [
          _buildAnimatedBackground(),
          _buildGlowOrbs(),
          SafeArea(
            child: FadeTransition(
              opacity: _fadeAnim,
              child: Column(
                children: [
                  _buildDigitalClock(),
                  _buildSlotHeader(),
                  _buildReels(),
                  _buildControls(),
                  _buildResultMessage(),
                ],
              ),
            ),
          ),
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
    children: List.generate(5, (i) {
      final angle = (i / 5) * 2 * math.pi;
      return AnimatedBuilder(
        animation: _rotateCtrl,
        builder: (_, __) {
          final x = math.cos(_rotateCtrl.value * 0.4 + angle) * 140;
          final y = math.sin(_rotateCtrl.value * 0.6 + angle) * 90;
          final color = _C.rainbow[(i * 2) % _C.rainbow.length];
          return Positioned(
            left: MediaQuery.of(context).size.width / 2 + x - 25,
            top: MediaQuery.of(context).size.height / 2 + y - 25,
            child: Container(
              width: 50 + 20 * math.sin(_rotateCtrl.value + i).abs(),
              height: 50 + 20 * math.sin(_rotateCtrl.value + i).abs(),
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

  Widget _buildDigitalClock() => Container(
    margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
    padding: const EdgeInsets.symmetric(vertical: 6, horizontal: 16),
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
        const SizedBox(height: 4),
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
          Text(time, style: TextStyle(color: color.withOpacity(0.08), fontSize: 13, fontWeight: FontWeight.w700, fontFamily: 'Orbitron', letterSpacing: 1.5, shadows: [Shadow(color: color.withOpacity(0.3), blurRadius: 25)])),
          Text(time, style: TextStyle(color: color.withOpacity(0.2), fontSize: 13, fontWeight: FontWeight.w700, fontFamily: 'Orbitron', letterSpacing: 1.5, shadows: [Shadow(color: color.withOpacity(0.6), blurRadius: 40)])),
          Text(time, style: TextStyle(color: Colors.white, fontSize: 13, fontWeight: FontWeight.w700, fontFamily: 'Orbitron', letterSpacing: 1.5, shadows: [Shadow(color: color, blurRadius: 12)])),
        ],
      ),
    ],
  );

  Widget _buildSlotHeader() => Container(
    padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 20),
    decoration: BoxDecoration(
      gradient: LinearGradient(colors: [_C.purple, _C.pink]),
      borderRadius: const BorderRadius.only(bottomLeft: Radius.circular(30), bottomRight: Radius.circular(30)),
    ),
    child: Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        const Icon(Icons.casino, color: _C.gold, size: 28),
        const SizedBox(width: 12),
        Column(
          children: [
            const Text("SLOT MACHINE", style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold, fontFamily: 'Orbitron', letterSpacing: 2)),
            Row(
              children: [
                _buildStatBadge(Icons.monetization_on, "$_score", _C.gold),
                const SizedBox(width: 12),
                _buildStatBadge(Icons.local_play, "$_bet", _C.gold),
              ],
            ),
          ],
        ),
      ],
    ),
  );

  Widget _buildStatBadge(IconData icon, String text, Color color) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
    decoration: BoxDecoration(color: Colors.black.withOpacity(0.3), borderRadius: BorderRadius.circular(20)),
    child: Row(children: [Icon(icon, color: color, size: 14), const SizedBox(width: 4), Text(text, style: TextStyle(color: color, fontSize: 14, fontWeight: FontWeight.bold))]),
  );

  Widget _buildReels() => Expanded(
    child: Center(
      child: AnimatedBuilder(
        animation: _shakeAnim,
        builder: (_, __) => Transform.translate(
          offset: Offset(_shakeAnim.value, 0),
          child: Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              gradient: LinearGradient(colors: [_C.card.withOpacity(0.7), _C.surface.withOpacity(0.5)]),
              borderRadius: BorderRadius.circular(24),
              border: Border.all(color: _C.gold.withOpacity(0.3)),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                _buildReel(_reel1),
                _buildReel(_reel2),
                _buildReel(_reel3),
              ],
            ),
          ),
        ),
      ),
    ),
  );

  Widget _buildReel(String icon) => Container(
    width: 80, height: 80,
    decoration: BoxDecoration(
      color: _C.surface,
      borderRadius: BorderRadius.circular(16),
      border: Border.all(color: _C.gold.withOpacity(0.3)),
      boxShadow: [BoxShadow(color: _C.gold.withOpacity(0.1), blurRadius: 10)],
    ),
    child: Center(child: Text(icon, style: const TextStyle(fontSize: 48))),
  );

  Widget _buildControls() => Padding(
    padding: const EdgeInsets.all(20),
    child: Column(
      children: [
        GestureDetector(
          onTap: _isSpinning ? null : _spin,
          child: AnimatedBuilder(
            animation: _pulseCtrl,
            builder: (_, __) => Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(vertical: 16),
              decoration: BoxDecoration(
                gradient: LinearGradient(colors: [_C.gold, _C.orange]),
                borderRadius: BorderRadius.circular(16),
                boxShadow: [BoxShadow(color: _C.gold.withOpacity(0.3), blurRadius: 20 + _pulseCtrl.value * 10)],
              ),
              child: _isSpinning
                  ? const SizedBox(width: 24, height: 24, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.black))
                  : const Text("SPIN", textAlign: TextAlign.center,
                      style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold, fontSize: 20, fontFamily: 'Orbitron', letterSpacing: 2)),
            ),
          ),
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            _buildSmallButton("- BET", () => _changeBet(-5), _C.pink),
            const SizedBox(width: 8),
            _buildSmallButton("FREE COINS", _takeFreeCoins, _C.green),
            const SizedBox(width: 8),
            _buildSmallButton("+ BET", () => _changeBet(5), _C.pink),
          ],
        ),
      ],
    ),
  );

  Widget _buildSmallButton(String label, VoidCallback onTap, Color color) => Expanded(
    child: GestureDetector(
      onTap: onTap,
      child: AnimatedBuilder(
        animation: _pulseCtrl,
        builder: (_, __) => Container(
          padding: const EdgeInsets.symmetric(vertical: 12),
          decoration: BoxDecoration(
            gradient: LinearGradient(colors: [color.withOpacity(0.15), color.withOpacity(0.05)]),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: color.withOpacity(0.3 + _pulseCtrl.value * 0.2), width: 1.5),
          ),
          child: Text(label, textAlign: TextAlign.center,
            style: TextStyle(color: color, fontSize: 12, fontWeight: FontWeight.bold, fontFamily: 'Orbitron')),
        ),
      ),
    ),
  );

  Widget _buildResultMessage() => Padding(
    padding: const EdgeInsets.symmetric(horizontal: 20),
    child: Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: _C.card,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: _C.rainbow[DateTime.now().second % _C.rainbow.length].withOpacity(0.2)),
      ),
      child: Row(
        children: [
          Icon(_resultMessage.contains("MENANG") || _resultMessage.contains("JACKPOT") ? Icons.emoji_events : _resultMessage.contains("Coba") ? Icons.sentiment_dissatisfied : Icons.info,
            color: _resultMessage.contains("MENANG") || _resultMessage.contains("JACKPOT") ? _C.gold : _C.textDim, size: 18),
          const SizedBox(width: 12),
          Expanded(child: Text(_resultMessage, style: TextStyle(color: _C.text, fontSize: 13, fontFamily: 'ShareTechMono'))),
        ],
      ),
    ),
  );
}

// ─── LUDO KING TOOLS ──────────────────────────────────────────────────────
class LudoKingTools extends StatefulWidget {
  final String username;
  const LudoKingTools({super.key, required this.username});

  @override
  State<LudoKingTools> createState() => _LudoKingToolsState();
}

class _LudoKingToolsState extends State<LudoKingTools>
    with SingleTickerProviderStateMixin {
  final math.Random _random = math.Random();
  int _diceValue = 1, _playerScore = 0, _computerScore = 0;
  bool _isRolling = false;
  String _result = "";
  final List<String> _players = ["Player 1", "Player 2", "Player 3", "Player 4"];
  int _currentPlayer = 0;
  final Map<int, int> _playerPositions = {0: 0, 1: 0, 2: 0, 3: 0};
  String _gameMessage = "Tap dadu untuk mulai!";
  final List<Color> _playerColors = [const Color(0xFFE91E63), const Color(0xFF4CAF50), const Color(0xFFFF9800), const Color(0xFF2196F3)];

  late AnimationController _fadeCtrl, _pulseCtrl, _rotateCtrl, _diceCtrl;
  late Animation<double> _fadeAnim, _pulseAnim, _diceRotate;

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
    _diceCtrl = AnimationController(vsync: this, duration: const Duration(milliseconds: 600));
    _diceRotate = Tween<double>(begin: 0, end: 2 * math.pi).animate(CurvedAnimation(parent: _diceCtrl, curve: Curves.easeOut));

    _updateClock();
    _clockTimer = Timer.periodic(const Duration(seconds: 1), (_) {
      _updateClock();
      setState(() => _showColon = !_showColon);
    });
  }

  @override
  void dispose() {
    _clockTimer?.cancel();
    _fadeCtrl.dispose(); _pulseCtrl.dispose(); _rotateCtrl.dispose(); _diceCtrl.dispose();
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

  void _rollDice() {
    if (_isRolling) return;
    setState(() { _isRolling = true; _result = ""; _diceCtrl.forward(from: 0); });
    int rollCount = 0;
    Timer.periodic(const Duration(milliseconds: 100), (timer) {
      if (rollCount >= 10) {
        timer.cancel();
        final int value = _random.nextInt(6) + 1;
        setState(() { _diceValue = value; _isRolling = false; _processTurn(value); });
      } else {
        setState(() { _diceValue = _random.nextInt(6) + 1; });
        rollCount++;
      }
    });
  }

  void _processTurn(int diceValue) {
    final int currentPos = _playerPositions[_currentPlayer]!;
    int newPos = currentPos + diceValue;
    if (newPos > 57) {
      setState(() { _gameMessage = "${_players[_currentPlayer]} butuh angka pas!"; _nextPlayer(); });
      return;
    }
    _playerPositions[_currentPlayer] = newPos;
    _playerScore += diceValue;
    if (newPos == 57) {
      setState(() {
        _result = "🎉 ${_players[_currentPlayer]} MENANG! 🎉";
        _gameMessage = "Selamat! ${_players[_currentPlayer]} memenangkan permainan!";
        _playerScore = 0; _computerScore = 0;
        for (int i = 0; i < _players.length; i++) _playerPositions[i] = 0;
        _currentPlayer = 0;
      });
      return;
    }
    if (diceValue == 6) setState(() => _gameMessage = "${_players[_currentPlayer]} dapat giliran lagi!");
    else _nextPlayer();
  }

  void _nextPlayer() {
    setState(() { _currentPlayer = (_currentPlayer + 1) % _players.length; _gameMessage = "Giliran ${_players[_currentPlayer]}"; });
  }

  void _resetGame() {
    setState(() {
      _diceValue = 1; _playerScore = 0; _computerScore = 0; _currentPlayer = 0; _result = "";
      _gameMessage = "Game direset! Giliran Player 1";
      for (int i = 0; i < _players.length; i++) _playerPositions[i] = 0;
    });
  }

  void _shareGame() {
    Share.share("🎲 LUDO KING TOOLS 🎲\n\nPlayer: ${_players[_currentPlayer]}\nDadu terakhir: $_diceValue\nScore Player: $_playerScore\nStatus: ${_result.isNotEmpty ? _result : "Sedang bermain"}\n\n✨ Ayo main Ludo King! ✨");
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _C.bg,
      appBar: AppBar(
        title: const Text("Ludo King Tools", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontFamily: 'Orbitron')),
        backgroundColor: _C.purple,
        centerTitle: true,
        elevation: 0,
        actions: [
          IconButton(icon: const Icon(Icons.share, color: _C.gold), onPressed: _shareGame),
          IconButton(icon: const Icon(Icons.refresh, color: _C.gold), onPressed: _resetGame),
        ],
      ),
      body: Stack(
        children: [
          _buildAnimatedBackground(),
          _buildGlowOrbs(),
          SafeArea(
            child: FadeTransition(
              opacity: _fadeAnim,
              child: Column(
                children: [
                  _buildDigitalClock(),
                  _buildLudoHeader(),
                  _buildDice(),
                  _buildPlayerList(),
                  if (_result.isNotEmpty) _buildResultBanner(),
                ],
              ),
            ),
          ),
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
    children: List.generate(5, (i) {
      final angle = (i / 5) * 2 * math.pi;
      return AnimatedBuilder(
        animation: _rotateCtrl,
        builder: (_, __) {
          final x = math.cos(_rotateCtrl.value * 0.4 + angle) * 140;
          final y = math.sin(_rotateCtrl.value * 0.6 + angle) * 90;
          final color = _C.rainbow[(i * 2) % _C.rainbow.length];
          return Positioned(
            left: MediaQuery.of(context).size.width / 2 + x - 25,
            top: MediaQuery.of(context).size.height / 2 + y - 25,
            child: Container(
              width: 50 + 20 * math.sin(_rotateCtrl.value + i).abs(),
              height: 50 + 20 * math.sin(_rotateCtrl.value + i).abs(),
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

  Widget _buildDigitalClock() => Container(
    margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
    padding: const EdgeInsets.symmetric(vertical: 6, horizontal: 16),
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
        const SizedBox(height: 4),
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
          Text(time, style: TextStyle(color: color.withOpacity(0.08), fontSize: 13, fontWeight: FontWeight.w700, fontFamily: 'Orbitron', letterSpacing: 1.5, shadows: [Shadow(color: color.withOpacity(0.3), blurRadius: 25)])),
          Text(time, style: TextStyle(color: color.withOpacity(0.2), fontSize: 13, fontWeight: FontWeight.w700, fontFamily: 'Orbitron', letterSpacing: 1.5, shadows: [Shadow(color: color.withOpacity(0.6), blurRadius: 40)])),
          Text(time, style: TextStyle(color: Colors.white, fontSize: 13, fontWeight: FontWeight.w700, fontFamily: 'Orbitron', letterSpacing: 1.5, shadows: [Shadow(color: color, blurRadius: 12)])),
        ],
      ),
    ],
  );

  Widget _buildLudoHeader() => Container(
    padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 20),
    decoration: BoxDecoration(
      gradient: LinearGradient(colors: [_C.purple, _C.pink]),
      borderRadius: const BorderRadius.only(bottomLeft: Radius.circular(30), bottomRight: Radius.circular(30)),
    ),
    child: Column(
      children: [
        const Icon(Icons.casino, color: _C.gold, size: 32),
        const Text("LUDO KING", style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold, fontFamily: 'Orbitron', letterSpacing: 2)),
        Text(_gameMessage, style: TextStyle(color: Colors.white.withOpacity(0.8), fontSize: 12, fontFamily: 'ShareTechMono')),
      ],
    ),
  );

  Widget _buildDice() => Padding(
    padding: const EdgeInsets.all(16),
    child: Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        AnimatedBuilder(
          animation: _diceRotate,
          builder: (_, __) => Transform.rotate(
            angle: _diceRotate.value,
            child: Container(
              width: 100, height: 100,
              decoration: BoxDecoration(
                gradient: LinearGradient(colors: [Colors.white, Colors.grey.shade200]),
                borderRadius: BorderRadius.circular(20),
                boxShadow: [BoxShadow(color: _C.gold.withOpacity(0.3), blurRadius: 20 + _pulseCtrl.value * 10)],
              ),
              child: Center(
                child: Text("$_diceValue", style: TextStyle(fontSize: 52, fontWeight: FontWeight.bold, color: _C.purple)),
              ),
            ),
          ),
        ),
        const SizedBox(width: 20),
        GestureDetector(
          onTap: _isRolling ? null : _rollDice,
          child: AnimatedBuilder(
            animation: _pulseCtrl,
            builder: (_, __) => Container(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
              decoration: BoxDecoration(
                gradient: LinearGradient(colors: [_C.gold, _C.orange]),
                borderRadius: BorderRadius.circular(16),
                boxShadow: [BoxShadow(color: _C.gold.withOpacity(0.3), blurRadius: 20 + _pulseCtrl.value * 10)],
              ),
              child: _isRolling
                  ? const SizedBox(width: 24, height: 24, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.black))
                  : const Text("GULIR", style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold, fontSize: 16, fontFamily: 'Orbitron', letterSpacing: 2)),
            ),
          ),
        ),
      ],
    ),
  );

  Widget _buildPlayerList() => Expanded(
    child: ListView.builder(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      itemCount: _players.length,
      itemBuilder: (context, index) {
        final isActive = _currentPlayer == index;
        return AnimatedContainer(
          duration: const Duration(milliseconds: 300),
          margin: const EdgeInsets.only(bottom: 10),
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            gradient: isActive ? LinearGradient(colors: [_C.card, _C.surface]) : null,
            color: isActive ? null : _C.card.withOpacity(0.3),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: isActive ? _C.gold : _C.border.withOpacity(0.3),
              width: isActive ? 2 : 1,
            ),
            boxShadow: isActive ? [BoxShadow(color: _C.gold.withOpacity(0.2), blurRadius: 20)] : [],
          ),
          child: Row(
            children: [
              Container(
                width: 40, height: 40,
                decoration: BoxDecoration(color: _playerColors[index], shape: BoxShape.circle),
                child: Center(child: Text("${index + 1}", style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 18))),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(_players[index], style: TextStyle(color: isActive ? _C.gold : Colors.white, fontWeight: FontWeight.bold)),
                    const SizedBox(height: 4),
                    LinearProgressIndicator(
                      value: _playerPositions[index]! / 57,
                      backgroundColor: _C.surface,
                      color: _playerColors[index],
                      borderRadius: BorderRadius.circular(4),
                    ),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: _playerColors[index].withOpacity(0.2),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text("${_playerPositions[index]}/57", style: TextStyle(color: _playerColors[index], fontSize: 12, fontWeight: FontWeight.bold)),
              ),
            ],
          ),
        );
      },
    ),
  );

  Widget _buildResultBanner() => Padding(
    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
    child: Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: _C.gold.withOpacity(0.15),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: _C.gold.withOpacity(0.3)),
      ),
      child: Row(
        children: [
          const Icon(Icons.emoji_events, color: _C.gold),
          const SizedBox(width: 12),
          Expanded(child: Text(_result, style: const TextStyle(color: _C.gold, fontWeight: FontWeight.bold, fontFamily: 'Orbitron'))),
        ],
      ),
    ),
  );
}