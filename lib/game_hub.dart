import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'dart:math';
import 'dart:async';

void main() {
  runApp(const GameHubApp());
}

class GameHubApp extends StatelessWidget {
  const GameHubApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Game Hub',
      theme: ThemeData(
        brightness: Brightness.dark,
        scaffoldBackgroundColor: const Color(0xFF0A0A0F),
        primaryColor: const Color(0xFF9CA3AF),
        useMaterial3: true,
      ),
      home: const GameHub(),
      debugShowCheckedModeBanner: false,
    );
  }
}

// ==================== HOME PAGE ====================
class GameHub extends StatelessWidget {
  const GameHub({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [Color(0xFF0A0A0F), Color(0xFF1A1A2E)],
          ),
        ),
        child: SafeArea(
          child: Column(
            children: [
              const SizedBox(height: 40),
              // Header
              ShaderMask(
                shaderCallback: (bounds) => const LinearGradient(
                  colors: [Color(0xFF9CA3AF), Color(0xFFFFFFFF)],
                ).createShader(bounds),
                child: const Text(
                  'GAME HUB',
                  style: TextStyle(
                    fontSize: 32,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                    letterSpacing: 3,
                  ),
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'Pilih permainan favoritmu',
                style: TextStyle(color: Colors.white.withOpacity(0.5), fontSize: 14),
              ),
              const SizedBox(height: 40),
              // Game Cards
              Expanded(
                child: GridView.count(
                  crossAxisCount: 2,
                  padding: const EdgeInsets.all(20),
                  crossAxisSpacing: 20,
                  mainAxisSpacing: 20,
                  children: [
                    _GameCard(
                      title: 'Tic Tac Toe',
                      icon: Icons.grid_3x3,
                      color: const Color(0xFF3B82F6),
                      onTap: () => Navigator.push(
                        context,
                        MaterialPageRoute(builder: (_) => const TicTacToeGame()),
                      ),
                    ),
                    _GameCard(
                      title: 'Ular Tangga',
                      icon: Icons.casino,
                      color: const Color(0xFF10B981),
                      onTap: () => Navigator.push(
                        context,
                        MaterialPageRoute(builder: (_) => const SnakeLadderGame()),
                      ),
                    ),
                    _GameCard(
                      title: 'Catur',
                      icon: Icons.games,
                      color: const Color(0xFFF59E0B),
                      onTap: () => Navigator.push(
                        context,
                        MaterialPageRoute(builder: (_) => const ChessGame()),
                      ),
                    ),
                    _GameCard(
                      title: 'Mode Multiplayer',
                      icon: Icons.people,
                      color: const Color(0xFF8B5CF6),
                      onTap: () => _showMultiplayerDialog(context),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showMultiplayerDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: const Color(0xFF1A1A2E),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text('Pilih Mode', style: TextStyle(color: Colors.white)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            _DialogButton(
              text: 'Solo (vs computer)',
              icon: Icons.android,
              onTap: () {
                Navigator.pop(ctx);
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const TicTacToeGame(soloMode: true)),
                );
              },
            ),
            const SizedBox(height: 12),
            _DialogButton(
              text: 'Multiplayer (2 Pemain)',
              icon: Icons.two_k,
              onTap: () {
                Navigator.pop(ctx);
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const TicTacToeGame(soloMode: false)),
                );
              },
            ),
          ],
        ),
      ),
    );
  }
}

class _GameCard extends StatelessWidget {
  final String title;
  final IconData icon;
  final Color color;
  final VoidCallback onTap;

  const _GameCard({
    required this.title,
    required this.icon,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [color.withOpacity(0.2), color.withOpacity(0.05)],
          ),
          borderRadius: BorderRadius.circular(24),
          border: Border.all(color: color.withOpacity(0.3), width: 1.5),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: 48, color: color),
            const SizedBox(height: 16),
            Text(
              title,
              style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: 8),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
              decoration: BoxDecoration(
                color: color.withOpacity(0.2),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Text(
                'Play Now →',
                style: TextStyle(color: color, fontSize: 11),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _DialogButton extends StatelessWidget {
  final String text;
  final IconData icon;
  final VoidCallback onTap;

  const _DialogButton({required this.text, required this.icon, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 20),
        decoration: BoxDecoration(
          color: const Color(0xFF2A2A3E),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: Colors.white.withOpacity(0.1)),
        ),
        child: Row(
          children: [
            Icon(icon, color: const Color(0xFF9CA3AF)),
            const SizedBox(width: 12),
            Text(text, style: const TextStyle(color: Colors.white)),
            const Spacer(),
            const Icon(Icons.arrow_forward_ios, size: 14, color: Colors.grey),
          ],
        ),
      ),
    );
  }
}

// ==================== TIC TAC TOE ====================
class TicTacToeGame extends StatefulWidget {
  final bool soloMode;
  const TicTacToeGame({super.key, this.soloMode = true});

  @override
  State<TicTacToeGame> createState() => _TicTacToeGameState();
}

class _TicTacToeGameState extends State<TicTacToeGame> {
  List<String> _board = List.filled(9, '');
  String _currentPlayer = 'X';
  String? _winner;
  bool _isGameOver = false;
  int _scoreX = 0;
  int _scoreO = 0;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0A0A0F),
      appBar: AppBar(
        title: const Text('Tic Tac Toe'),
        backgroundColor: Colors.transparent,
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _resetGame,
          ),
        ],
      ),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // Score Board
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: const Color(0xFF1A1A2E),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    _ScoreTile(player: 'X', score: _scoreX, color: const Color(0xFF3B82F6)),
                    Container(width: 1, height: 40, color: Colors.white24),
                    _ScoreTile(player: 'O', score: _scoreO, color: const Color(0xFF10B981)),
                  ],
                ),
              ),
              const SizedBox(height: 30),
              // Turn Indicator
              if (!_isGameOver)
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                  decoration: BoxDecoration(
                    color: (_currentPlayer == 'X' ? const Color(0xFF3B82F6) : const Color(0xFF10B981)).withOpacity(0.2),
                    borderRadius: BorderRadius.circular(30),
                    border: Border.all(
                      color: (_currentPlayer == 'X' ? const Color(0xFF3B82F6) : const Color(0xFF10B981)).withOpacity(0.5),
                    ),
                  ),
                  child: Text(
                    'Giliran Pemain $_currentPlayer',
                    style: TextStyle(
                      color: _currentPlayer == 'X' ? const Color(0xFF3B82F6) : const Color(0xFF10B981),
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              if (_isGameOver && _winner != null)
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                  decoration: BoxDecoration(
                    color: Colors.amber.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(30),
                  ),
                  child: Text(
                    'Pemenang: Pemain $_winner! 🎉',
                    style: const TextStyle(color: Colors.amber, fontSize: 16, fontWeight: FontWeight.bold),
                  ),
                ),
              if (_isGameOver && _winner == null)
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                  decoration: BoxDecoration(
                    color: Colors.grey.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(30),
                  ),
                  child: const Text(
                    'Draw! 🤝',
                    style: TextStyle(color: Colors.grey, fontSize: 16, fontWeight: FontWeight.bold),
                  ),
                ),
              const SizedBox(height: 30),
              // Board
              Container(
                width: 350,
                height: 350,
                decoration: BoxDecoration(
                  color: const Color(0xFF1A1A2E),
                  borderRadius: BorderRadius.circular(24),
                  boxShadow: [
                    BoxShadow(color: Colors.black.withOpacity(0.3), blurRadius: 20, offset: const Offset(0, 10)),
                  ],
                ),
                child: GridView.builder(
                  padding: const EdgeInsets.all(12),
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 3,
                    childAspectRatio: 1,
                    crossAxisSpacing: 8,
                    mainAxisSpacing: 8,
                  ),
                  itemCount: 9,
                  physics: const NeverScrollableScrollPhysics(),
                  itemBuilder: (context, index) {
                    return _buildCell(index);
                  },
                ),
              ),
              const SizedBox(height: 30),
              // Reset Button
              ElevatedButton.icon(
                onPressed: _resetGame,
                icon: const Icon(Icons.refresh),
                label: const Text('Reset Game'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF9CA3AF),
                  foregroundColor: Colors.black87,
                  padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 12),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(30)),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildCell(int index) {
    final value = _board[index];
    final isX = value == 'X';
    final isO = value == 'O';
    
    return GestureDetector(
      onTap: () => _makeMove(index),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        decoration: BoxDecoration(
          color: value.isEmpty ? const Color(0xFF2A2A3E) : (isX ? const Color(0xFF3B82F6).withOpacity(0.2) : const Color(0xFF10B981).withOpacity(0.2)),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: Colors.white.withOpacity(0.1)),
        ),
        child: Center(
          child: Text(
            value,
            style: TextStyle(
              fontSize: 48,
              fontWeight: FontWeight.bold,
              color: isX ? const Color(0xFF3B82F6) : const Color(0xFF10B981),
            ),
          ),
        ),
      ),
    );
  }

  void _makeMove(int index) {
    if (_board[index].isNotEmpty || _isGameOver) return;
    if (widget.soloMode && _currentPlayer == 'O' && !_isGameOver) return;

    setState(() {
      _board[index] = _currentPlayer;
      _checkWinner();
      
      if (!_isGameOver) {
        _currentPlayer = _currentPlayer == 'X' ? 'O' : 'X';
        
        if (widget.soloMode && _currentPlayer == 'O' && !_isGameOver) {
          _aiMove();
        }
      }
    });
  }

  void _aiMove() {
    Future.delayed(const Duration(milliseconds: 500), () {
      if (_isGameOver) return;
      
      List<int> emptyIndices = [];
      for (int i = 0; i < _board.length; i++) {
        if (_board[i].isEmpty) emptyIndices.add(i);
      }
      
      if (emptyIndices.isNotEmpty) {
        final random = Random();
        final aiIndex = emptyIndices[random.nextInt(emptyIndices.length)];
        
        setState(() {
          _board[aiIndex] = 'O';
          _checkWinner();
          
          if (!_isGameOver) {
            _currentPlayer = 'X';
          }
        });
      }
    });
  }

  void _checkWinner() {
    const winPatterns = [
      [0, 1, 2], [3, 4, 5], [6, 7, 8], // rows
      [0, 3, 6], [1, 4, 7], [2, 5, 8], // columns
      [0, 4, 8], [2, 4, 6], // diagonals
    ];
    
    for (var pattern in winPatterns) {
      final a = _board[pattern[0]];
      final b = _board[pattern[1]];
      final c = _board[pattern[2]];
      
      if (a.isNotEmpty && a == b && b == c) {
        _winner = a;
        _isGameOver = true;
        
        if (a == 'X') {
          setState(() => _scoreX++);
        } else {
          setState(() => _scoreO++);
        }
        return;
      }
    }
    
    if (_board.every((cell) => cell.isNotEmpty)) {
      _isGameOver = true;
      _winner = null;
    }
  }

  void _resetGame() {
    setState(() {
      _board = List.filled(9, '');
      _currentPlayer = 'X';
      _winner = null;
      _isGameOver = false;
    });
  }
}

class _ScoreTile extends StatelessWidget {
  final String player;
  final int score;
  final Color color;

  const _ScoreTile({required this.player, required this.score, required this.color});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Container(
          width: 40,
          height: 40,
          decoration: BoxDecoration(
            color: color.withOpacity(0.2),
            shape: BoxShape.circle,
            border: Border.all(color: color),
          ),
          child: Center(
            child: Text(player, style: TextStyle(color: color, fontSize: 20, fontWeight: FontWeight.bold)),
          ),
        ),
        const SizedBox(height: 8),
        Text(score.toString(), style: const TextStyle(color: Colors.white, fontSize: 24, fontWeight: FontWeight.bold)),
      ],
    );
  }
}

// ==================== ULAR TANGGA ====================
class SnakeLadderGame extends StatefulWidget {
  const SnakeLadderGame({super.key});

  @override
  State<SnakeLadderGame> createState() => _SnakeLadderGameState();
}

class _SnakeLadderGameState extends State<SnakeLadderGame> {
  int _player1Pos = 0;
  int _player2Pos = 0;
  int _currentPlayer = 0;
  bool _isRolling = false;
  String _winner = '';
  int _diceValue = 1;

  final Map<int, int> _ladders = {4: 14, 9: 31, 20: 38, 28: 84, 40: 59, 63: 81, 71: 93};
  final Map<int, int> _snakes = {17: 7, 54: 34, 62: 19, 64: 60, 87: 24, 93: 73, 95: 75, 99: 78};

  void _rollDice() {
    if (_winner.isNotEmpty || _isRolling) return;
    
    setState(() => _isRolling = true);
    
    // Animasi dadu
    int rollCount = 0;
    Timer.periodic(const Duration(milliseconds: 100), (timer) {
      setState(() {
        _diceValue = Random().nextInt(6) + 1;
      });
      rollCount++;
      
      if (rollCount >= 10) {
        timer.cancel();
        _applyMove();
      }
    });
  }

  void _applyMove() {
    int newPos = _currentPlayer == 0 ? _player1Pos + _diceValue : _player2Pos + _diceValue;
    
    if (newPos > 100) {
      setState(() {
        _isRolling = false;
        _currentPlayer = _currentPlayer == 0 ? 1 : 0;
      });
      return;
    }
    
    // Cek ladder
    if (_ladders.containsKey(newPos)) {
      newPos = _ladders[newPos]!;
    }
    // Cek snake
    else if (_snakes.containsKey(newPos)) {
      newPos = _snakes[newPos]!;
    }
    
    setState(() {
      if (_currentPlayer == 0) {
        _player1Pos = newPos;
      } else {
        _player2Pos = newPos;
      }
      
      if (newPos == 100) {
        _winner = _currentPlayer == 0 ? 'Pemain 1' : 'Pemain 2';
      } else {
        _currentPlayer = _currentPlayer == 0 ? 1 : 0;
      }
      _isRolling = false;
    });
  }

  void _resetGame() {
    setState(() {
      _player1Pos = 0;
      _player2Pos = 0;
      _currentPlayer = 0;
      _winner = '';
      _diceValue = 1;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0A0A0F),
      appBar: AppBar(
        title: const Text('Ular Tangga'),
        backgroundColor: Colors.transparent,
        elevation: 0,
        actions: [
          IconButton(onPressed: _resetGame, icon: const Icon(Icons.refresh)),
        ],
      ),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            children: [
              // Score Board
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: const Color(0xFF1A1A2E),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    _PlayerScore(
                      player: 'Pemain 1',
                      position: _player1Pos,
                      isActive: _winner.isEmpty && _currentPlayer == 0,
                      color: const Color(0xFF3B82F6),
                    ),
                    Container(width: 1, height: 40, color: Colors.white24),
                    _PlayerScore(
                      player: 'Pemain 2',
                      position: _player2Pos,
                      isActive: _winner.isEmpty && _currentPlayer == 1,
                      color: const Color(0xFF10B981),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 20),
              // Dice
              Container(
                width: 100,
                height: 100,
                decoration: BoxDecoration(
                  color: const Color(0xFF1A1A2E),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: const Color(0xFF9CA3AF).withOpacity(0.3)),
                ),
                child: Center(
                  child: Text(
                    _diceValue.toString(),
                    style: const TextStyle(fontSize: 48, fontWeight: FontWeight.bold, color: Color(0xFF9CA3AF)),
                  ),
                ),
              ),
              const SizedBox(height: 20),
              // Roll Button
              ElevatedButton.icon(
                onPressed: _winner.isEmpty ? _rollDice : null,
                icon: const Icon(Icons.casino),
                label: Text(_winner.isNotEmpty ? 'Game Over - $_winner Menang!' : 'Roll Dice'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF9CA3AF),
                  foregroundColor: Colors.black87,
                  padding: const EdgeInsets.symmetric(horizontal: 40, vertical: 14),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(30)),
                ),
              ),
              const SizedBox(height: 20),
              // Board (Sederhana)
              Expanded(
                child: Container(
                  decoration: BoxDecoration(
                    color: const Color(0xFF1A1A2E),
                    borderRadius: BorderRadius.circular(24),
                  ),
                  child: GridView.builder(
                    padding: const EdgeInsets.all(12),
                    gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: 10,
                      childAspectRatio: 1,
                    ),
                    itemCount: 100,
                    itemBuilder: (context, index) {
                      final cell = 100 - index;
                      final hasPlayer1 = _player1Pos == cell;
                      final hasPlayer2 = _player2Pos == cell;
                      final isLadder = _ladders.containsKey(cell);
                      final isSnake = _snakes.containsKey(cell);
                      
                      return Container(
                        margin: const EdgeInsets.all(2),
                        decoration: BoxDecoration(
                          color: isLadder
                              ? Colors.green.withOpacity(0.3)
                              : isSnake
                                  ? Colors.red.withOpacity(0.3)
                                  : const Color(0xFF2A2A3E),
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(color: Colors.white.withOpacity(0.05)),
                        ),
                        child: Stack(
                          children: [
                            Center(
                              child: Text(
                                cell.toString(),
                                style: TextStyle(color: Colors.white.withOpacity(0.4), fontSize: 10),
                              ),
                            ),
                            if (hasPlayer1)
                              Positioned(
                                top: 2,
                                left: 2,
                                child: Container(
                                  width: 12,
                                  height: 12,
                                  decoration: const BoxDecoration(
                                    color: Color(0xFF3B82F6),
                                    shape: BoxShape.circle,
                                  ),
                                ),
                              ),
                            if (hasPlayer2)
                              Positioned(
                                bottom: 2,
                                right: 2,
                                child: Container(
                                  width: 12,
                                  height: 12,
                                  decoration: const BoxDecoration(
                                    color: Color(0xFF10B981),
                                    shape: BoxShape.circle,
                                  ),
                                ),
                              ),
                          ],
                        ),
                      );
                    },
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _PlayerScore extends StatelessWidget {
  final String player;
  final int position;
  final bool isActive;
  final Color color;

  const _PlayerScore({required this.player, required this.position, required this.isActive, required this.color});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          decoration: BoxDecoration(
            color: isActive ? color.withOpacity(0.2) : Colors.transparent,
            borderRadius: BorderRadius.circular(20),
            border: isActive ? Border.all(color: color) : null,
          ),
          child: Text(player, style: TextStyle(color: color, fontWeight: FontWeight.bold)),
        ),
        const SizedBox(height: 8),
        Text('Posisi: $position', style: const TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold)),
      ],
    );
  }
}

// ==================== CATUR (CHESS) ====================
class ChessGame extends StatefulWidget {
  const ChessGame({super.key});

  @override
  State<ChessGame> createState() => _ChessGameState();
}

class _ChessGameState extends State<ChessGame> {
  late List<List<String?>> _board;
  int? _selectedRow;
  int? _selectedCol;
  String _currentPlayer = 'white';
  String? _winner;
  
  final Map<String, String> _pieceIcons = {
    'white_king': '♔', 'white_queen': '♕', 'white_rook': '♖', 'white_bishop': '♗', 'white_knight': '♘', 'white_pawn': '♙',
    'black_king': '♚', 'black_queen': '♛', 'black_rook': '♜', 'black_bishop': '♝', 'black_knight': '♞', 'black_pawn': '♟',
  };

  @override
  void initState() {
    super.initState();
    _initBoard();
  }

  void _initBoard() {
    _board = List.generate(8, (i) => List.filled(8, null));
    
    // Pawns
    for (int i = 0; i < 8; i++) {
      _board[1][i] = 'black_pawn';
      _board[6][i] = 'white_pawn';
    }
    
    // Pieces
    final pieces = ['rook', 'knight', 'bishop', 'queen', 'king', 'bishop', 'knight', 'rook'];
    for (int i = 0; i < 8; i++) {
      _board[0][i] = 'black_${pieces[i]}';
      _board[7][i] = 'white_${pieces[i]}';
    }
  }

  void _selectPiece(int row, int col) {
    if (_winner != null) return;
    
    final piece = _board[row][col];
    if (piece == null) return;
    
    final pieceColor = piece.split('_')[0];
    if (pieceColor != _currentPlayer) return;
    
    setState(() {
      _selectedRow = row;
      _selectedCol = col;
    });
  }

  void _movePiece(int row, int col) {
    if (_selectedRow == null || _selectedCol == null || _winner != null) return;
    
    final piece = _board[_selectedRow!][_selectedCol!];
    if (piece == null) return;
    
    // Validasi gerakan sederhana
    if (_isValidMove(_selectedRow!, _selectedCol!, row, col, piece)) {
      setState(() {
        _board[row][col] = piece;
        _board[_selectedRow!][_selectedCol!] = null;
        _selectedRow = null;
        _selectedCol = null;
        
        // Cek king capture
        if (_board[row][col]?.contains('king') ?? false) {
          _winner = _currentPlayer == 'white' ? 'Putih Menang!' : 'Hitam Menang!';
        } else {
          _currentPlayer = _currentPlayer == 'white' ? 'black' : 'white';
        }
      });
    } else {
      setState(() {
        _selectedRow = null;
        _selectedCol = null;
      });
    }
  }

  bool _isValidMove(int fromRow, int fromCol, int toRow, int toCol, String piece) {
    final targetPiece = _board[toRow][toCol];
    if (targetPiece != null && targetPiece.split('_')[0] == piece.split('_')[0]) {
      return false;
    }
    
    final dr = (toRow - fromRow).abs();
    final dc = (toCol - fromCol).abs();
    
    if (piece.contains('pawn')) {
      final direction = piece.contains('white') ? -1 : 1;
      if (fromCol == toCol && dr == 1 && targetPiece == null) return true;
      if (fromCol == toCol && dr == 2 && fromRow == (piece.contains('white') ? 6 : 1) && targetPiece == null) return true;
      if (dr == 1 && dc == 1 && targetPiece != null) return true;
      return false;
    }
    
    if (piece.contains('rook')) {
      if (fromRow == toRow) {
        for (int c = min(fromCol, toCol) + 1; c < max(fromCol, toCol); c++) {
          if (_board[fromRow][c] != null) return false;
        }
        return true;
      }
      if (fromCol == toCol) {
        for (int r = min(fromRow, toRow) + 1; r < max(fromRow, toRow); r++) {
          if (_board[r][fromCol] != null) return false;
        }
        return true;
      }
      return false;
    }
    
    if (piece.contains('knight')) {
      return (dr == 2 && dc == 1) || (dr == 1 && dc == 2);
    }
    
    if (piece.contains('bishop')) {
      if (dr != dc) return false;
      for (int i = 1; i < dr; i++) {
        final r = fromRow + (toRow > fromRow ? i : -i);
        final c = fromCol + (toCol > fromCol ? i : -i);
        if (_board[r][c] != null) return false;
      }
      return true;
    }
    
    if (piece.contains('queen')) {
      if (fromRow == toRow || fromCol == toCol) {
        if (fromRow == toRow) {
          for (int c = min(fromCol, toCol) + 1; c < max(fromCol, toCol); c++) {
            if (_board[fromRow][c] != null) return false;
          }
        } else {
          for (int r = min(fromRow, toRow) + 1; r < max(fromRow, toRow); r++) {
            if (_board[r][fromCol] != null) return false;
          }
        }
        return true;
      }
      if (dr == dc) {
        for (int i = 1; i < dr; i++) {
          final r = fromRow + (toRow > fromRow ? i : -i);
          final c = fromCol + (toCol > fromCol ? i : -i);
          if (_board[r][c] != null) return false;
        }
        return true;
      }
      return false;
    }
    
    if (piece.contains('king')) {
      return dr <= 1 && dc <= 1;
    }
    
    return false;
  }

  void _resetGame() {
    setState(() {
      _initBoard();
      _selectedRow = null;
      _selectedCol = null;
      _currentPlayer = 'white';
      _winner = null;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0A0A0F),
      appBar: AppBar(
        title: const Text('Catur'),
        backgroundColor: Colors.transparent,
        elevation: 0,
        actions: [
          IconButton(onPressed: _resetGame, icon: const Icon(Icons.refresh)),
        ],
      ),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            children: [
              // Turn Indicator
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                decoration: BoxDecoration(
                  color: (_currentPlayer == 'white' ? const Color(0xFF3B82F6) : const Color(0xFF10B981)).withOpacity(0.2),
                  borderRadius: BorderRadius.circular(30),
                ),
                child: Text(
                  _winner ?? 'Giliran: ${_currentPlayer == 'white' ? 'Putih' : 'Hitam'}',
                  style: TextStyle(
                    color: _currentPlayer == 'white' ? const Color(0xFF3B82F6) : const Color(0xFF10B981),
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              const SizedBox(height: 20),
              // Chess Board
              Container(
                width: 380,
                height: 380,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.3), blurRadius: 20)],
                ),
                child: GridView.builder(
                  physics: const NeverScrollableScrollPhysics(),
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 8,
                  ),
                  itemCount: 64,
                  itemBuilder: (context, index) {
                    final row = index ~/ 8;
                    final col = index % 8;
                    final piece = _board[row][col];
                    final isSelected = _selectedRow == row && _selectedCol == col;
                    final isLightSquare = (row + col) % 2 == 0;
                    
                    return GestureDetector(
                      onTap: () {
                        if (_selectedRow == null) {
                          _selectPiece(row, col);
                        } else {
                          _movePiece(row, col);
                        }
                      },
                      child: Container(
                        decoration: BoxDecoration(
                          color: isLightSquare
                              ? (isSelected ? const Color(0xFFFCD34D) : const Color(0xFFF3F4F6))
                              : (isSelected ? const Color(0xFFF59E0B) : const Color(0xFF374151)),
                          border: Border.all(color: Colors.white.withOpacity(0.1), width: 0.5),
                        ),
                        child: Center(
                          child: Text(
                            piece != null ? _pieceIcons[piece]! : '',
                            style: TextStyle(
                              fontSize: 28,
                              color: piece?.contains('white') == true ? Colors.white : Colors.black87,
                            ),
                          ),
                        ),
                      ),
                    );
                  },
                ),
              ),
              const SizedBox(height: 20),
              if (_winner != null)
                ElevatedButton.icon(
                  onPressed: _resetGame,
                  icon: const Icon(Icons.refresh),
                  label: const Text('Main Lagi'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF9CA3AF),
                    foregroundColor: Colors.black87,
                    padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 12),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(30)),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}