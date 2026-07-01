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
  static const gold        = Color(0xFFFFD700);
  static const text        = Color(0xFFF3E8FF);
  static const textSub     = Color(0xFFD4C4F0);
  static const textDim     = Color(0xFF8B7AAA);
  static const white       = Color(0xFFFFFFFF);
  static const List<Color> rainbow = [purple, pink, cyan, green, yellow, orange, red, purpleL, blue, gold];
}

class TicTacToePage extends StatefulWidget {
  final String username;
  const TicTacToePage({super.key, required this.username});

  @override
  State<TicTacToePage> createState() => _TicTacToePageState();
}

class _TicTacToePageState extends State<TicTacToePage>
    with SingleTickerProviderStateMixin {
  // ─── GAME STATE ──────────────────────────────────────────────────────────
  late List<String> _board;
  String _currentPlayer = 'X';
  bool _gameOver = false;
  String? _winner;
  int _scoreX = 0, _scoreO = 0, _scoreDraw = 0;
  int _moveCount = 0;
  List<int> _moveHistory = [];
  bool _isAiThinking = false;

  // ─── ANIMATIONS ──────────────────────────────────────────────────────────
  late AnimationController _fadeCtrl, _pulseCtrl, _winCtrl, _boardCtrl, _rotateCtrl;
  late Animation<double> _fadeAnim, _pulseAnim, _winScale, _boardRotate;

  // ─── DIGITAL CLOCK ──────────────────────────────────────────────────────
  Timer? _clockTimer;
  String _timeWIB = '--:--:--', _timeWITA = '--:--:--', _timeWIT = '--:--:--';
  bool _showColon = true;

  static const List<List<int>> _winningCombos = [
    [0, 1, 2], [3, 4, 5], [6, 7, 8],
    [0, 3, 6], [1, 4, 7], [2, 5, 8],
    [0, 4, 8], [2, 4, 6],
  ];

  @override
  void initState() {
    super.initState();
    _resetGame();
    _fadeCtrl = AnimationController(vsync: this, duration: const Duration(milliseconds: 800))..forward();
    _fadeAnim = CurvedAnimation(parent: _fadeCtrl, curve: Curves.easeOut);
    _pulseCtrl = AnimationController(vsync: this, duration: const Duration(milliseconds: 1500))..repeat(reverse: true);
    _pulseAnim = CurvedAnimation(parent: _pulseCtrl, curve: Curves.easeInOut);
    _winCtrl = AnimationController(vsync: this, duration: const Duration(milliseconds: 500));
    _winScale = Tween<double>(begin: 0.0, end: 1.0).animate(CurvedAnimation(parent: _winCtrl, curve: Curves.elasticOut));
    _boardCtrl = AnimationController(vsync: this, duration: const Duration(milliseconds: 300));
    _boardRotate = Tween<double>(begin: 0.0, end: 0.05).animate(CurvedAnimation(parent: _boardCtrl, curve: Curves.easeOut));
    _rotateCtrl = AnimationController(vsync: this, duration: const Duration(seconds: 20))..repeat();
    _updateClock();
    _clockTimer = Timer.periodic(const Duration(seconds: 1), (_) {
      _updateClock();
      setState(() => _showColon = !_showColon);
    });
  }

  @override
  void dispose() {
    _clockTimer?.cancel();
    _fadeCtrl.dispose(); _pulseCtrl.dispose(); _winCtrl.dispose(); _boardCtrl.dispose(); _rotateCtrl.dispose();
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

  void _resetGame() {
    setState(() {
      _board = List.filled(9, '');
      _currentPlayer = 'X';
      _gameOver = false;
      _winner = null;
      _moveCount = 0;
      _moveHistory = [];
      _isAiThinking = false;
    });
    _boardCtrl.forward(from: 0);
  }

  bool _checkWinner(String player) {
    for (var combo in _winningCombos) {
      if (_board[combo[0]] == player && _board[combo[1]] == player && _board[combo[2]] == player) return true;
    }
    return false;
  }

  bool _isBoardFull() => _board.every((cell) => cell.isNotEmpty);

  void _handleMove(int index) {
    if (_gameOver || _isAiThinking || _board[index].isNotEmpty) return;
    setState(() { _board[index] = 'X'; _moveCount++; _moveHistory.add(index); });
    if (_checkWinner('X')) {
      setState(() { _gameOver = true; _winner = 'X'; _scoreX++; _winCtrl.forward(from: 0); });
      return;
    }
    if (_isBoardFull()) {
      setState(() { _gameOver = true; _winner = 'Draw'; _scoreDraw++; _winCtrl.forward(from: 0); });
      return;
    }
    _currentPlayer = 'O';
    _isAiThinking = true;
    Future.delayed(const Duration(milliseconds: 400), _aiMove);
  }

  int _minimax(List<String> board, bool isMaximizing) {
    if (_checkWinnerAI(board, 'X')) return -10;
    if (_checkWinnerAI(board, 'O')) return 10;
    if (board.every((cell) => cell.isNotEmpty)) return 0;
    if (isMaximizing) {
      int bestScore = -1000;
      for (int i = 0; i < 9; i++) {
        if (board[i].isEmpty) {
          board[i] = 'O';
          int score = _minimax(board, false);
          board[i] = '';
          bestScore = math.max(score, bestScore);
        }
      }
      return bestScore;
    } else {
      int bestScore = 1000;
      for (int i = 0; i < 9; i++) {
        if (board[i].isEmpty) {
          board[i] = 'X';
          int score = _minimax(board, true);
          board[i] = '';
          bestScore = math.min(score, bestScore);
        }
      }
      return bestScore;
    }
  }

  bool _checkWinnerAI(List<String> board, String player) {
    for (var combo in _winningCombos) {
      if (board[combo[0]] == player && board[combo[1]] == player && board[combo[2]] == player) return true;
    }
    return false;
  }

  void _aiMove() {
    if (_gameOver) { setState(() => _isAiThinking = false); return; }
    int bestScore = -1000, bestMove = -1;
    for (int i = 0; i < 9; i++) {
      if (_board[i].isEmpty) {
        List<String> boardCopy = List.from(_board);
        boardCopy[i] = 'O';
        int score = _minimax(boardCopy, false);
        if (score > bestScore) { bestScore = score; bestMove = i; }
      }
    }
    if (bestMove != -1) {
      setState(() { _board[bestMove] = 'O'; _moveCount++; _moveHistory.add(bestMove); _isAiThinking = false; });
      if (_checkWinner('O')) {
        setState(() { _gameOver = true; _winner = 'O'; _scoreO++; _winCtrl.forward(from: 0); });
        return;
      }
      if (_isBoardFull()) {
        setState(() { _gameOver = true; _winner = 'Draw'; _scoreDraw++; _winCtrl.forward(from: 0); });
        return;
      }
      setState(() => _currentPlayer = 'X');
    } else {
      setState(() => _isAiThinking = false);
    }
  }

  void _undoMove() {
    if (_moveHistory.isEmpty || _gameOver || _isAiThinking) return;
    final lastIndex = _moveHistory.removeLast();
    setState(() { _board[lastIndex] = ''; _moveCount--; _currentPlayer = 'X'; });
    if (_moveHistory.isNotEmpty && _board[_moveHistory.last] == 'O') {
      final aiIndex = _moveHistory.removeLast();
      setState(() { _board[aiIndex] = ''; _moveCount--; });
    }
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
                  Expanded(child: _buildBoard()),
                  _buildBottomControls(),
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
              child: const Icon(Icons.games_rounded, color: Colors.white, size: 22),
            ),
          ),
        ),
        const SizedBox(width: 12),
        const Text('TIC TAC TOE', style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold, fontFamily: 'Orbitron', letterSpacing: 2)),
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
              Text(_isAiThinking ? 'AI Thinking...' : 'Your Turn', style: TextStyle(color: _isAiThinking ? _C.yellow : _C.green, fontSize: 10, fontWeight: FontWeight.bold, fontFamily: 'Orbitron')),
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
    padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 16),
    decoration: BoxDecoration(
      gradient: LinearGradient(colors: [_C.card.withOpacity(0.5), _C.surface.withOpacity(0.4)]),
      borderRadius: BorderRadius.circular(16),
      border: Border.all(color: _C.border.withOpacity(0.3)),
    ),
    child: Row(
      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
      children: [
        _buildScoreItem('YOU (X)', _scoreX, _C.blue, Icons.emoji_events_rounded),
        _buildScoreItem('DRAW', _scoreDraw, _C.yellow, Icons.remove_rounded),
        _buildScoreItem('AI (O)', _scoreO, _C.red, Icons.computer_rounded),
      ],
    ),
  );

  Widget _buildScoreItem(String label, int score, Color color, IconData icon) => Column(
    children: [
      Container(padding: const EdgeInsets.all(6), decoration: BoxDecoration(color: color.withOpacity(0.15), borderRadius: BorderRadius.circular(10)), child: Icon(icon, color: color, size: 16)),
      const SizedBox(height: 4),
      Text(label, style: TextStyle(color: _C.textDim, fontSize: 9, fontWeight: FontWeight.w600, fontFamily: 'Orbitron')),
      AnimatedSwitcher(
        duration: const Duration(milliseconds: 300),
        transitionBuilder: (child, anim) => ScaleTransition(scale: anim, child: child),
        child: Text('$score', key: ValueKey(score), style: TextStyle(color: color, fontSize: 18, fontWeight: FontWeight.bold, fontFamily: 'Orbitron', shadows: [Shadow(color: color.withOpacity(0.3), blurRadius: 12)])),
      ),
    ],
  );

  Widget _buildBoard() => AnimatedBuilder(
    animation: _boardRotate,
    builder: (_, __) => Transform.rotate(
      angle: _boardRotate.value,
      child: Center(
        child: Container(
          width: MediaQuery.of(context).size.width * 0.85,
          height: MediaQuery.of(context).size.width * 0.85,
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            gradient: LinearGradient(colors: [_C.card.withOpacity(0.7), _C.surface.withOpacity(0.5)]),
            borderRadius: BorderRadius.circular(28),
            border: Border.all(color: _C.purple.withOpacity(0.2), width: 1.5),
            boxShadow: [BoxShadow(color: _C.purple.withOpacity(0.1), blurRadius: 40, spreadRadius: 4, offset: const Offset(0, 12))],
          ),
          child: GridView.builder(
            physics: const NeverScrollableScrollPhysics(),
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(crossAxisCount: 3, childAspectRatio: 1),
            itemCount: 9,
            itemBuilder: (context, index) => _buildCell(index),
          ),
        ),
      ),
    ),
  );

  Widget _buildCell(int index) {
    final value = _board[index];
    final isWinning = _winner != null && _winner != 'Draw' &&
        _winningCombos.any((combo) => combo.contains(index) && combo.every((i) => _board[i] == _winner));
    return Padding(
      padding: const EdgeInsets.all(6),
      child: GestureDetector(
        onTap: () => _handleMove(index),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 300),
          curve: Curves.elasticOut,
          decoration: BoxDecoration(
            gradient: value.isNotEmpty
                ? LinearGradient(colors: value == 'X' ? [_C.blue.withOpacity(0.2), _C.cyan.withOpacity(0.05)] : [_C.red.withOpacity(0.2), _C.rose.withOpacity(0.05)])
                : LinearGradient(colors: [_C.card.withOpacity(0.3), _C.surface.withOpacity(0.2)]),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: isWinning ? _C.gold : value.isNotEmpty ? (value == 'X' ? _C.blue : _C.red).withOpacity(0.4) : _C.border.withOpacity(0.2),
              width: isWinning ? 3 : 1,
            ),
            boxShadow: isWinning ? [BoxShadow(color: _C.gold.withOpacity(0.3), blurRadius: 20, spreadRadius: 2)] : value.isNotEmpty ? [BoxShadow(color: (value == 'X' ? _C.blue : _C.red).withOpacity(0.1), blurRadius: 12)] : [],
          ),
          child: Center(child: value.isNotEmpty ? _buildSymbol(value, isWinning) : null),
        ),
      ),
    );
  }

  Widget _buildSymbol(String symbol, bool isWinning) {
    final isX = symbol == 'X';
    final color = isX ? _C.blue : _C.red;
    final glowColor = isX ? _C.cyan : _C.rose;
    return AnimatedBuilder(
      animation: _pulseCtrl,
      builder: (_, __) {
        final scale = isWinning ? 1.0 + _pulseCtrl.value * 0.08 : 1.0;
        return Transform.scale(
          scale: scale,
          child: ShaderMask(
            shaderCallback: (bounds) => LinearGradient(colors: isX ? [_C.blue, _C.cyan, _C.blue] : [_C.red, _C.rose, _C.red], stops: const [0.0, 0.5, 1.0]).createShader(bounds),
            child: Text(symbol, style: TextStyle(fontSize: 52, fontWeight: FontWeight.bold, color: Colors.white, fontFamily: 'Orbitron', shadows: [Shadow(color: glowColor.withOpacity(0.4), blurRadius: 20 + _pulseCtrl.value * 10)])),
          ),
        );
      },
    );
  }

  Widget _buildBottomControls() => Container(
    padding: const EdgeInsets.fromLTRB(16, 8, 16, 20),
    child: Column(
      children: [
        if (_gameOver)
          AnimatedBuilder(
            animation: _winScale,
            builder: (_, __) => Transform.scale(
              scale: _winScale.value,
              child: Container(
                margin: const EdgeInsets.only(bottom: 8),
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                decoration: BoxDecoration(
                  gradient: LinearGradient(colors: _winner == 'X' ? [_C.blue, _C.cyan] : _winner == 'O' ? [_C.red, _C.rose] : [_C.yellow, _C.orange]),
                  borderRadius: BorderRadius.circular(20),
                  boxShadow: [BoxShadow(color: _winner == 'X' ? _C.blue.withOpacity(0.3) : _winner == 'O' ? _C.red.withOpacity(0.3) : _C.yellow.withOpacity(0.3), blurRadius: 20, spreadRadius: 2)],
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(_winner == 'X' ? Icons.emoji_events_rounded : _winner == 'O' ? Icons.computer_rounded : Icons.remove_rounded, color: Colors.white, size: 18),
                    const SizedBox(width: 8),
                    Text(_winner == 'X' ? '🎉 YOU WIN!' : _winner == 'O' ? '💻 AI WINS!' : '🤝 DRAW!', style: const TextStyle(color: Colors.white, fontSize: 14, fontWeight: FontWeight.bold, fontFamily: 'Orbitron', letterSpacing: 1)),
                  ],
                ),
              ),
            ),
          ),
        Row(
          children: [
            Expanded(
              child: _buildActionButton(Icons.refresh_rounded, 'NEW GAME', _C.purple, () { _resetGame(); _winCtrl.reset(); }),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _buildActionButton(Icons.undo_rounded, 'UNDO', _C.yellow, _undoMove, _moveHistory.isNotEmpty && !_gameOver && !_isAiThinking),
            ),
          ],
        ),
      ],
    ),
  );

  Widget _buildActionButton(IconData icon, String label, Color color, VoidCallback onTap, [bool enabled = true]) => Opacity(
    opacity: enabled ? 1.0 : 0.4,
    child: GestureDetector(
      onTap: enabled ? onTap : null,
      child: AnimatedBuilder(
        animation: _pulseCtrl,
        builder: (_, __) => Container(
          padding: const EdgeInsets.symmetric(vertical: 12),
          decoration: BoxDecoration(
            gradient: LinearGradient(colors: [color.withOpacity(0.15), color.withOpacity(0.05)]),
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: color.withOpacity(enabled ? 0.4 : 0.15), width: 1.5),
            boxShadow: enabled ? [BoxShadow(color: color.withOpacity(0.1), blurRadius: 12)] : [],
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon, color: enabled ? color : _C.textDim, size: 18),
              const SizedBox(width: 8),
              Text(label, style: TextStyle(color: enabled ? color : _C.textDim, fontSize: 12, fontWeight: FontWeight.bold, fontFamily: 'Orbitron', letterSpacing: 1)),
            ],
          ),
        ),
      ),
    ),
  );
}