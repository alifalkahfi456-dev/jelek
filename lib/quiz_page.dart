import 'dart:async';
import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter_staggered_animations/flutter_staggered_animations.dart';

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
  
  static const List<Color> rainbow = [
    purple, pink, cyan, green, yellow, orange, red, purpleL, blue,
  ];
}

class QuizPage extends StatefulWidget {
  final String username;
  const QuizPage({super.key, required this.username});

  @override
  State<QuizPage> createState() => _QuizPageState();
}

class _QuizPageState extends State<QuizPage>
    with SingleTickerProviderStateMixin {
  // ─── STATE ──────────────────────────────────────────────────────────────
  String? selectedCategory;
  int currentQuestionIndex = 0;
  int score = 0;
  int? selectedAnswerIndex;
  bool isAnswered = false;
  String gameState = 'menu';
  int totalQuestions = 0;
  List<Map<String, dynamic>> currentQuestions = [];
  
  // ─── ANIMATIONS ──────────────────────────────────────────────────────
  late AnimationController _fadeCtrl;
  late Animation<double> _fadeAnim;
  late AnimationController _pulseCtrl;
  late Animation<double> _pulseAnim;
  late AnimationController _rotateCtrl;
  late AnimationController _slideCtrl;
  late Animation<Offset> _slideAnim;
  late AnimationController _confettiCtrl;
  late List<ConfettiParticle> _confettiParticles = [];

  // ─── DIGITAL CLOCK ──────────────────────────────────────────────────
  Timer? _clockTimer;
  String _timeWIB = '--:--:--';
  String _timeWITA = '--:--:--';
  String _timeWIT = '--:--:--';
  bool _showColon = true;

  final Map<String, List<Map<String, dynamic>>> quizData = {
    "Matematika": [
      {"question": "Berapa hasil dari 15 x 4?", "options": ["50", "60", "70", "45"], "answer": 1},
      {"question": "Akar kuadrat dari 81 adalah...", "options": ["7", "8", "9", "10"], "answer": 2},
      {"question": "Jika x + 5 = 12, berapa nilai x?", "options": ["5", "6", "7", "8"], "answer": 2},
      {"question": "Berapa 100 - 37?", "options": ["53", "63", "73", "43"], "answer": 1},
      {"question": "Luas persegi dengan sisi 7 adalah?", "options": ["14", "28", "49", "56"], "answer": 2},
    ],
    "IPA": [
      {"question": "H2O adalah rumus kimia dari?", "options": ["Garam", "Gula", "Air", "Minyak"], "answer": 2},
      {"question": "Planet terdekat dengan Matahari adalah?", "options": ["Venus", "Merkurius", "Mars", "Bumi"], "answer": 1},
      {"question": "Apa yang dimaksud dengan fotosintesis?", "options": ["Proses bernapas", "Proses membuat makanan", "Proses bergerak", "Proses tidur"], "answer": 1},
      {"question": "Hewan yang hidup di darat dan air disebut?", "options": ["Amfibi", "Reptil", "Mamalia", "Aves"], "answer": 0},
    ],
    "Agama": [
      {"question": "Rukun Islam yang pertama adalah?", "options": ["Sholat", "Puasa", "Syahadat", "Zakat"], "answer": 2},
      {"question": "Kitab suci umat Islam adalah?", "options": ["Injil", "Zabur", "Taurat", "Al-Quran"], "answer": 3},
      {"question": "Berapa jumlah rakaat sholat Subuh?", "options": ["2", "3", "4", "5"], "answer": 0},
    ],
    "Umum": [
      {"question": "Ibu kota Indonesia adalah?", "options": ["Bandung", "Surabaya", "Jakarta", "Medan"], "answer": 2},
      {"question": "Gunung tertinggi di dunia?", "options": ["Kilimanjaro", "Everest", "Fuji", "Kerinci"], "answer": 1},
      {"question": "Benua terluas di dunia?", "options": ["Asia", "Afrika", "Eropa", "Amerika"], "answer": 0},
      {"question": "Negara dengan populasi terbanyak?", "options": ["India", "China", "AS", "Indonesia"], "answer": 0},
    ],
  };

  @override
  void initState() {
    super.initState();
    _fadeCtrl = AnimationController(vsync: this, duration: const Duration(milliseconds: 800))..forward();
    _fadeAnim = CurvedAnimation(parent: _fadeCtrl, curve: Curves.easeOut);
    _pulseCtrl = AnimationController(vsync: this, duration: const Duration(milliseconds: 1500))..repeat(reverse: true);
    _pulseAnim = CurvedAnimation(parent: _pulseCtrl, curve: Curves.easeInOut);
    _rotateCtrl = AnimationController(vsync: this, duration: const Duration(seconds: 20))..repeat();
    _slideCtrl = AnimationController(vsync: this, duration: const Duration(milliseconds: 500));
    _slideAnim = Tween<Offset>(begin: const Offset(0, 0.3), end: Offset.zero)
        .animate(CurvedAnimation(parent: _slideCtrl, curve: Curves.easeOutCubic));
    _confettiCtrl = AnimationController(vsync: this, duration: const Duration(seconds: 3));
    _updateClock();
    _clockTimer = Timer.periodic(const Duration(seconds: 1), (_) {
      _updateClock();
      setState(() => _showColon = !_showColon);
    });
  }

  @override
  void dispose() {
    _clockTimer?.cancel();
    _fadeCtrl.dispose();
    _pulseCtrl.dispose();
    _rotateCtrl.dispose();
    _slideCtrl.dispose();
    _confettiCtrl.dispose();
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

  void startQuiz(String category) {
    setState(() {
      selectedCategory = category;
      currentQuestions = quizData[category]!;
      totalQuestions = currentQuestions.length;
      currentQuestionIndex = 0;
      score = 0;
      selectedAnswerIndex = null;
      isAnswered = false;
      gameState = 'play';
      _slideCtrl.forward(from: 0);
    });
  }

  void checkAnswer(int selectedIndex) {
    if (isAnswered) return;
    final correctIndex = currentQuestions[currentQuestionIndex]['answer'];
    setState(() {
      selectedAnswerIndex = selectedIndex;
      isAnswered = true;
    });
    if (selectedIndex == correctIndex) score++;
    Future.delayed(const Duration(milliseconds: 800), () => nextQuestion());
  }

  void nextQuestion() {
    if (currentQuestionIndex < totalQuestions - 1) {
      setState(() {
        currentQuestionIndex++;
        selectedAnswerIndex = null;
        isAnswered = false;
        _slideCtrl.forward(from: 0);
      });
    } else {
      setState(() => gameState = 'result');
      _spawnConfetti();
    }
  }

  void _spawnConfetti() {
    _confettiParticles.clear();
    final random = math.Random();
    for (int i = 0; i < 80; i++) {
      _confettiParticles.add(ConfettiParticle(
        x: random.nextDouble(),
        y: random.nextDouble(),
        size: random.nextDouble() * 8 + 4,
        speedX: (random.nextDouble() - 0.5) * 0.02,
        speedY: -(random.nextDouble() * 0.03 + 0.01),
        color: _C.rainbow[random.nextInt(_C.rainbow.length)],
        rotation: random.nextDouble() * 6.28,
        rotationSpeed: (random.nextDouble() - 0.5) * 0.05,
      ));
    }
    _confettiCtrl.forward(from: 0);
  }

  void goToMenu() {
    setState(() {
      gameState = 'menu';
      selectedCategory = null;
      _confettiParticles.clear();
      _confettiCtrl.reset();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _C.bg,
      body: Stack(
        children: [
          _buildAnimatedBackground(),
          _buildGlowOrbs(),
          if (gameState == 'result') _buildConfetti(),
          SafeArea(
            child: FadeTransition(
              opacity: _fadeAnim,
              child: Column(
                children: [
                  _buildHeader(),
                  _buildDigitalClock(),
                  Expanded(child: gameState == 'menu' ? _buildMenuView() : gameState == 'play' ? _buildPlayView() : _buildResultView()),
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
              child: const Icon(Icons.quiz_rounded, color: Colors.white, size: 22),
            ),
          ),
        ),
        const SizedBox(width: 12),
        const Text('QUIZ MASTER', style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold, fontFamily: 'Orbitron', letterSpacing: 2)),
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

  Widget _buildMenuView() => Padding(
    padding: const EdgeInsets.all(20),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text("Pilih Kategori:", style: TextStyle(color: Colors.white, fontSize: 22, fontWeight: FontWeight.w300, fontFamily: 'Orbitron')),
        const SizedBox(height: 20),
        Expanded(
          child: AnimationLimiter(
            child: GridView.count(
              crossAxisCount: 2,
              crossAxisSpacing: 20,
              mainAxisSpacing: 20,
              childAspectRatio: 1.2,
              children: quizData.keys.map((category) {
                return AnimationConfiguration.staggeredGrid(
                  position: quizData.keys.toList().indexOf(category),
                  duration: const Duration(milliseconds: 600),
                  child: SlideAnimation(
                    verticalOffset: 50,
                    child: FadeInAnimation(
                      child: _buildCategoryCard(category),
                    ),
                  ),
                );
              }).toList(),
            ),
          ),
        ),
      ],
    ),
  );

  Widget _buildCategoryCard(String category) {
    final iconMap = {"Matematika": Icons.calculate, "IPA": Icons.science, "Agama": Icons.menu_book, "Umum": Icons.public};
    final colorIndex = quizData.keys.toList().indexOf(category) % _C.rainbow.length;
    return GestureDetector(
      onTap: () => startQuiz(category),
      child: AnimatedBuilder(
        animation: _pulseCtrl,
        builder: (_, __) => Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(colors: [_C.card, _C.surface]),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: _C.rainbow[colorIndex].withOpacity(0.4), width: 2),
            boxShadow: [BoxShadow(color: _C.rainbow[colorIndex].withOpacity(0.15), blurRadius: 20 + _pulseCtrl.value * 10)],
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(iconMap[category] ?? Icons.quiz, size: 40, color: _C.rainbow[colorIndex]),
              const SizedBox(height: 10),
              Text(category, style: const TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold, fontFamily: 'Orbitron')),
              Text("${quizData[category]!.length} Soal", style: TextStyle(color: _C.textDim, fontSize: 12)),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildPlayView() => Padding(
    padding: const EdgeInsets.all(20),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        AnimatedBuilder(
          animation: _pulseCtrl,
          builder: (_, __) => LinearProgressIndicator(
            value: (currentQuestionIndex + 1) / totalQuestions,
            backgroundColor: _C.card,
            color: _C.rainbow[currentQuestionIndex % _C.rainbow.length],
            minHeight: 6,
            borderRadius: BorderRadius.circular(3),
          ),
        ),
        const SizedBox(height: 20),
        Text("Soal ${currentQuestionIndex + 1} dari $totalQuestions", style: TextStyle(color: _C.textDim, fontSize: 12, fontFamily: 'Orbitron')),
        const SizedBox(height: 10),
        Container(
          padding: const EdgeInsets.all(18),
          width: double.infinity,
          decoration: BoxDecoration(
            gradient: LinearGradient(colors: [_C.card.withOpacity(0.7), _C.surface.withOpacity(0.5)]),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: _C.rainbow[currentQuestionIndex % _C.rainbow.length].withOpacity(0.2)),
          ),
          child: Text(currentQuestions[currentQuestionIndex]['question'], style: const TextStyle(fontSize: 20, color: Colors.white, height: 1.4, fontFamily: 'ShareTechMono')),
        ),
        const SizedBox(height: 24),
        Expanded(
          child: SlideTransition(
            position: _slideAnim,
            child: ListView.builder(
              itemCount: 4,
              itemBuilder: (context, index) => _buildOptionButton(index),
            ),
          ),
        ),
        Center(
          child: Text("Skor: $score", style: TextStyle(color: _C.textSub, fontSize: 16, fontFamily: 'Orbitron')),
        ),
      ],
    ),
  );

  Widget _buildOptionButton(int index) {
    final options = currentQuestions[currentQuestionIndex]['options'];
    final correctIndex = currentQuestions[currentQuestionIndex]['answer'];
    Color bgColor = _C.card;
    Color textColor = Colors.white;
    IconData? iconData;

    if (isAnswered) {
      if (index == correctIndex) {
        bgColor = _C.green.withOpacity(0.2);
        textColor = _C.green;
        iconData = Icons.check_circle_rounded;
      } else if (index == selectedAnswerIndex) {
        bgColor = _C.red.withOpacity(0.15);
        textColor = _C.red;
        iconData = Icons.cancel_rounded;
      }
    } else {
      bgColor = _C.card;
    }

    return AnimatedContainer(
      duration: const Duration(milliseconds: 300),
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: isAnswered && (index == correctIndex) ? _C.green : isAnswered && index == selectedAnswerIndex ? _C.red : _C.border.withOpacity(0.3)),
        boxShadow: isAnswered && index == correctIndex ? [BoxShadow(color: _C.green.withOpacity(0.2), blurRadius: 16)] : [],
      ),
      child: GestureDetector(
        onTap: () => checkAnswer(index),
        child: Row(
          children: [
            if (iconData != null) ...[
              Icon(iconData, color: textColor, size: 20),
              const SizedBox(width: 12),
            ],
            Expanded(child: Text(options[index], style: TextStyle(fontSize: 16, color: textColor, fontFamily: 'ShareTechMono'))),
          ],
        ),
      ),
    );
  }

  Widget _buildResultView() {
    final percentage = (score / totalQuestions) * 100;
    final message = percentage >= 80 ? "🏆 LUAR BIASA!" : percentage >= 50 ? "👍 BAGUS!" : "💪 COBA LAGI!";
    final color = percentage >= 80 ? _C.green : percentage >= 50 ? _C.yellow : _C.red;

    return Center(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            AnimatedBuilder(
              animation: _pulseCtrl,
              builder: (_, __) => Transform.scale(
                scale: 1 + _pulseCtrl.value * 0.03,
                child: Text(message, style: TextStyle(fontSize: 34, fontWeight: FontWeight.bold, color: color, fontFamily: 'Orbitron', shadows: [Shadow(color: color.withOpacity(0.3), blurRadius: 20)])),
              ),
            ),
            const SizedBox(height: 20),
            const Text("Skor Akhir:", style: TextStyle(color: _C.textDim, fontSize: 18, fontFamily: 'Orbitron')),
            const SizedBox(height: 16),
            AnimatedBuilder(
              animation: _pulseCtrl,
              builder: (_, __) => Container(
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(color: color.withOpacity(0.5), width: 4),
                  boxShadow: [BoxShadow(color: color.withOpacity(0.2), blurRadius: 30)],
                ),
                child: Text("$score/$totalQuestions", style: TextStyle(fontSize: 40, fontWeight: FontWeight.bold, color: color, fontFamily: 'Orbitron')),
              ),
            ),
            const SizedBox(height: 40),
            GestureDetector(
              onTap: goToMenu,
              child: AnimatedBuilder(
                animation: _pulseCtrl,
                builder: (_, __) => Container(
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  width: double.infinity,
                  decoration: BoxDecoration(
                    gradient: LinearGradient(colors: [_C.purple, _C.pink]),
                    borderRadius: BorderRadius.circular(16),
                    boxShadow: [BoxShadow(color: _C.purple.withOpacity(0.3), blurRadius: 20 + _pulseCtrl.value * 10)],
                  ),
                  child: const Text("Kembali ke Menu", textAlign: TextAlign.center, style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold, fontFamily: 'Orbitron', letterSpacing: 2)),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildConfetti() => AnimatedBuilder(
    animation: _confettiCtrl,
    builder: (_, __) {
      return CustomPaint(
        painter: _ConfettiPainter(_confettiParticles, _confettiCtrl.value),
        size: Size.infinite,
      );
    },
  );
}

class ConfettiParticle {
  double x, y, size, speedX, speedY, rotation, rotationSpeed;
  Color color;
  ConfettiParticle({required this.x, required this.y, required this.size, required this.speedX, required this.speedY, required this.color, required this.rotation, required this.rotationSpeed});
}

class _ConfettiPainter extends CustomPainter {
  final List<ConfettiParticle> particles;
  final double time;
  _ConfettiPainter(this.particles, this.time);

  @override
  void paint(Canvas canvas, Size size) {
    for (var p in particles) {
      final x = (p.x + time * p.speedX) * size.width;
      final y = (p.y + time * p.speedY) * size.height;
      if (y < 0 || y > size.height) continue;
      final paint = Paint()..color = p.color.withOpacity(1 - time / 3);
      canvas.save();
      canvas.translate(x, y);
      canvas.rotate(p.rotation + time * p.rotationSpeed);
      canvas.drawRect(Rect.fromCenter(center: Offset.zero, width: p.size, height: p.size * 0.4), paint);
      canvas.restore();
    }
  }

  @override
  bool shouldRepaint(_ConfettiPainter old) => old.time != time;
}