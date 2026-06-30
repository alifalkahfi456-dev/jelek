// judi_game_page.dart - FULL FIX QRIS + UI MODERN 3D

import 'dart:convert';
import 'dart:async';
import 'dart:math' as math;
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';

// ==================== COLORS ====================
const Color kBgDark      = Color(0xFF0A0E17);
const Color kBgCard      = Color(0xFF131A26);
const Color kBgCardLight = Color(0xFF1A2333);
const Color kBorderColor = Color(0xFF2A3442);
const Color kNeonBlue    = Color(0xFF00E5FF);
const Color kNeonGreen   = Color(0xFF00FF88);
const Color kNeonPink    = Color(0xFFFF2D75);
const Color kNeonOrange  = Color(0xFFFF6D00);
const Color kNeonPurple  = Color(0xFFB026FF);
const Color kNeonYellow  = Color(0xFFFFD600);
const Color kRed         = Color(0xFFFF3B30);
const Color kWhite       = Colors.white;
const Color kWhite70     = Colors.white70;
const Color kWhite40     = Color(0x66FFFFFF);
const Color kWhite15     = Color(0x26FFFFFF);
const Color kWhite08     = Color(0x14FFFFFF);

// ==================== API CONFIG ====================
const String QRISPY_BASE_URL = 'https://api.qrispy.id';
const String QRISPY_API_TOKEN = 'cki_ORrD7n37ZtSZ2N1GL8Zs0LS9BAvV1qJm09jfmnoECWrJt4pO';
const String RETURN_URL = 'https://t.me/Topkacunk';

// ==================== MODELS ====================
class GameModel {
  final String id;
  final String name;
  final String icon;
  final Color color;
  final double minBet;
  final double maxBet;
  final double multiplier;
  final double rtp;
  final String description;
  
  GameModel({
    required this.id,
    required this.name,
    required this.icon,
    required this.color,
    required this.minBet,
    required this.maxBet,
    required this.multiplier,
    this.rtp = 0.65,
    this.description = '',
  });
}

class UserBalance {
  double balance;
  double totalDeposit;
  double totalWithdraw;
  double totalBet;
  double totalWin;
  
  UserBalance({
    this.balance = 0,
    this.totalDeposit = 0,
    this.totalWithdraw = 0,
    this.totalBet = 0,
    this.totalWin = 0,
  });
  
  Map<String, dynamic> toJson() => {
    'balance': balance,
    'totalDeposit': totalDeposit,
    'totalWithdraw': totalWithdraw,
    'totalBet': totalBet,
    'totalWin': totalWin,
  };
  
  factory UserBalance.fromJson(Map<String, dynamic> json) => UserBalance(
    balance: (json['balance'] ?? 0).toDouble(),
    totalDeposit: (json['totalDeposit'] ?? 0).toDouble(),
    totalWithdraw: (json['totalWithdraw'] ?? 0).toDouble(),
    totalBet: (json['totalBet'] ?? 0).toDouble(),
    totalWin: (json['totalWin'] ?? 0).toDouble(),
  );
}

class GameHistory {
  final String id;
  final String gameName;
  final double betAmount;
  final double winAmount;
  final String result;
  final DateTime timestamp;
  
  GameHistory({
    required this.id,
    required this.gameName,
    required this.betAmount,
    required this.winAmount,
    required this.result,
    required this.timestamp,
  });
  
  Map<String, dynamic> toJson() => {
    'id': id,
    'gameName': gameName,
    'betAmount': betAmount,
    'winAmount': winAmount,
    'result': result,
    'timestamp': timestamp.toIso8601String(),
  };
  
  factory GameHistory.fromJson(Map<String, dynamic> json) => GameHistory(
    id: json['id'],
    gameName: json['gameName'],
    betAmount: (json['betAmount'] ?? 0).toDouble(),
    winAmount: (json['winAmount'] ?? 0).toDouble(),
    result: json['result'],
    timestamp: DateTime.parse(json['timestamp']),
  );
}

class PaymentResponse {
  final String qrisId;
  final String qrisImageUrl;
  final String reference;
  final double amount;
  
  PaymentResponse({
    required this.qrisId,
    required this.qrisImageUrl,
    required this.reference,
    required this.amount,
  });
}

// ==================== PAYMENT SERVICE ====================
class QrispyPaymentService {
  static Future<PaymentResponse> createPayment(double amount, String userId) async {
    final reference = 'TZY_${userId}_${DateTime.now().millisecondsSinceEpoch}';
    
    final response = await http.post(
      Uri.parse('$QRISPY_BASE_URL/api/payment/qris/generate'),
      headers: {
        'Content-Type': 'application/json',
        'Accept': 'application/json',
        'X-API-TOKEN': QRISPY_API_TOKEN,
      },
      body: jsonEncode({
        'amount': amount,
        'payment_reference': reference,
        'return_url': RETURN_URL,
      }),
    );
    
    if (response.statusCode != 200) {
      throw Exception('Failed to create payment');
    }
    
    final payload = jsonDecode(response.body);
    if (payload['status'] != 'success' || payload['data'] == null) {
      throw Exception(payload['message'] ?? 'Payment creation failed');
    }
    
    return PaymentResponse(
      qrisId: payload['data']['qris_id'],
      qrisImageUrl: payload['data']['qris_image_url'],
      reference: reference,
      amount: amount,
    );
  }
  
  static Future<Map<String, dynamic>> checkPaymentStatus(String qrisId) async {
    final response = await http.get(
      Uri.parse('$QRISPY_BASE_URL/api/payment/qris/$qrisId/status'),
      headers: {
        'Accept': 'application/json',
        'X-API-TOKEN': QRISPY_API_TOKEN,
      },
    );
    
    if (response.statusCode != 200) {
      throw Exception('Failed to check payment status');
    }
    
    final payload = jsonDecode(response.body);
    if (payload['status'] != 'success') {
      throw Exception(payload['message'] ?? 'Status check failed');
    }
    
    return payload['data'];
  }
  
  static Future<void> cancelPayment(String qrisId) async {
    final response = await http.post(
      Uri.parse('$QRISPY_BASE_URL/api/payment/qris/$qrisId/cancel'),
      headers: {
        'Accept': 'application/json',
        'X-API-TOKEN': QRISPY_API_TOKEN,
      },
    );
    
    if (response.statusCode != 200) {
      throw Exception('Failed to cancel payment');
    }
  }
}

// ==================== GAME SERVICE ====================
class GameService {
  static final math.Random _random = math.Random();
  
  static Future<double> playGame(String gameId, double betAmount, double rtp) async {
    await Future.delayed(Duration(milliseconds: 500 + _random.nextInt(1500)));
    
    // Very low chance to win (susah menang)
    final double winChance = rtp * 0.3;
    
    if (_random.nextDouble() < winChance) {
      // Small win (scatter)
      if (_random.nextDouble() < 0.1) {
        // Big win (jackpot)
        final double multiplier = 5.0 + _random.nextDouble() * 30.0;
        return betAmount * multiplier;
      } else {
        // Small win
        final double multiplier = 1.1 + _random.nextDouble() * 3.0;
        return betAmount * multiplier;
      }
    }
    
    return 0;
  }
}

// ==================== PAGE GAMES ====================
class MahjongGamePage extends StatelessWidget {
  final Function(double) onBet;
  final double currentBalance;
  
  const MahjongGamePage({super.key, required this.onBet, required this.currentBalance});
  
  @override
  Widget build(BuildContext context) {
    return _buildGameContent('MAHJONG', '🀄', kNeonPurple, 5000, 1000000, 2.5, onBet, currentBalance);
  }
}

class SpacemanGamePage extends StatelessWidget {
  final Function(double) onBet;
  final double currentBalance;
  
  const SpacemanGamePage({super.key, required this.onBet, required this.currentBalance});
  
  @override
  Widget build(BuildContext context) {
    return _buildGameContent('SPACEMAN', '🚀', kNeonBlue, 5000, 500000, 10.0, onBet, currentBalance);
  }
}

class SlotsGamePage extends StatelessWidget {
  final Function(double) onBet;
  final double currentBalance;
  
  const SlotsGamePage({super.key, required this.onBet, required this.currentBalance});
  
  @override
  Widget build(BuildContext context) {
    return _buildGameContent('SLOTS', '🎰', kNeonYellow, 5000, 1000000, 5.0, onBet, currentBalance);
  }
}

class DiceGamePage extends StatelessWidget {
  final Function(double) onBet;
  final double currentBalance;
  
  const DiceGamePage({super.key, required this.onBet, required this.currentBalance});
  
  @override
  Widget build(BuildContext context) {
    return _buildGameContent('DICE', '🎲', kNeonGreen, 5000, 500000, 1.5, onBet, currentBalance);
  }
}

class RouletteGamePage extends StatelessWidget {
  final Function(double) onBet;
  final double currentBalance;
  
  const RouletteGamePage({super.key, required this.onBet, required this.currentBalance});
  
  @override
  Widget build(BuildContext context) {
    return _buildGameContent('ROULETTE', '🎡', kNeonOrange, 10000, 1000000, 35.0, onBet, currentBalance);
  }
}

class PokerGamePage extends StatelessWidget {
  final Function(double) onBet;
  final double currentBalance;
  
  const PokerGamePage({super.key, required this.onBet, required this.currentBalance});
  
  @override
  Widget build(BuildContext context) {
    return _buildGameContent('POKER', '🃏', kNeonPink, 10000, 1000000, 3.0, onBet, currentBalance);
  }
}

class BlackjackGamePage extends StatelessWidget {
  final Function(double) onBet;
  final double currentBalance;
  
  const BlackjackGamePage({super.key, required this.onBet, required this.currentBalance});
  
  @override
  Widget build(BuildContext context) {
    return _buildGameContent('BLACKJACK', '♠', kRed, 10000, 1000000, 2.0, onBet, currentBalance);
  }
}

class BaccaratGamePage extends StatelessWidget {
  final Function(double) onBet;
  final double currentBalance;
  
  const BaccaratGamePage({super.key, required this.onBet, required this.currentBalance});
  
  @override
  Widget build(BuildContext context) {
    return _buildGameContent('BACCARAT', '🎴', kNeonPurple, 10000, 1000000, 1.8, onBet, currentBalance);
  }
}

class CricketGamePage extends StatelessWidget {
  final Function(double) onBet;
  final double currentBalance;
  
  const CricketGamePage({super.key, required this.onBet, required this.currentBalance});
  
  @override
  Widget build(BuildContext context) {
    return _buildGameContent('CRICKET', '🏏', kNeonGreen, 10000, 500000, 4.0, onBet, currentBalance);
  }
}

class FootballGamePage extends StatelessWidget {
  final Function(double) onBet;
  final double currentBalance;
  
  const FootballGamePage({super.key, required this.onBet, required this.currentBalance});
  
  @override
  Widget build(BuildContext context) {
    return _buildGameContent('FOOTBALL', '⚽', kNeonBlue, 10000, 1000000, 5.0, onBet, currentBalance);
  }
}

Widget _buildGameContent(String name, String icon, Color color, double minBet, double maxBet, double multiplier, Function(double) onBet, double currentBalance) {
  double betAmount = minBet;
  
  return Container(
    decoration: BoxDecoration(
      gradient: LinearGradient(
        colors: [kBgCard, kBgCardLight],
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
      ),
      borderRadius: BorderRadius.circular(24),
      border: Border.all(color: color.withOpacity(0.5), width: 2),
    ),
    child: Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Container(
          width: 100, height: 100,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            gradient: LinearGradient(
              colors: [color.withOpacity(0.3), color.withOpacity(0.1)],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            border: Border.all(color: color, width: 2),
            boxShadow: [
              BoxShadow(color: color.withOpacity(0.4), blurRadius: 20, spreadRadius: 5),
            ],
          ),
          child: Center(
            child: Text(icon, style: const TextStyle(fontSize: 48)),
          ),
        ),
        const SizedBox(height: 20),
        Text(
          name,
          style: TextStyle(
            color: color,
            fontSize: 24,
            fontWeight: FontWeight.bold,
            fontFamily: 'Orbitron',
            letterSpacing: 2,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          'MULTIPLIER: ${multiplier.toStringAsFixed(1)}x',
          style: const TextStyle(color: kNeonYellow, fontSize: 14, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 16),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(20),
                color: kWhite08,
                border: Border.all(color: color.withOpacity(0.3)),
              ),
              child: Text('MIN: Rp ${(minBet / 1000).toInt()}K', style: TextStyle(color: kWhite70, fontSize: 11)),
            ),
            const SizedBox(width: 8),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(20),
                color: kWhite08,
                border: Border.all(color: color.withOpacity(0.3)),
              ),
              child: Text('MAX: Rp ${maxBet >= 1000000 ? '${(maxBet / 1000000).toInt()}M' : '${(maxBet / 1000).toInt()}K'}', style: TextStyle(color: kWhite70, fontSize: 11)),
            ),
          ],
        ),
        const SizedBox(height: 20),
        Row(
          children: [
            Expanded(
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(16),
                  color: kWhite08,
                  border: Border.all(color: color.withOpacity(0.3)),
                ),
                child: Row(
                  children: [
                    const Text('Rp ', style: TextStyle(color: kNeonOrange, fontWeight: FontWeight.bold)),
                    Expanded(
                      child: StatefulBuilder(
                        builder: (context, setState) {
                          return TextField(
                            keyboardType: TextInputType.number,
                            style: const TextStyle(color: kWhite, fontSize: 16, fontWeight: FontWeight.bold),
                            decoration: const InputDecoration(border: InputBorder.none, isDense: true),
                            onChanged: (value) {
                              final val = double.tryParse(value);
                              if (val != null) betAmount = val.clamp(minBet, maxBet);
                            },
                          );
                        },
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(width: 12),
            GestureDetector(
              onTap: () => betAmount = (betAmount * 2).clamp(minBet, maxBet),
              child: Container(
                width: 50, height: 50,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: LinearGradient(colors: [kNeonOrange, kNeonPink]),
                  boxShadow: [BoxShadow(color: kNeonOrange.withOpacity(0.4), blurRadius: 10)],
                ),
                child: const Icon(Icons.add_rounded, color: Colors.black, size: 28),
              ),
            ),
            const SizedBox(width: 8),
            GestureDetector(
              onTap: () => betAmount = (betAmount / 2).clamp(minBet, maxBet),
              child: Container(
                width: 50, height: 50,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: LinearGradient(colors: [kNeonOrange, kNeonPink]),
                  boxShadow: [BoxShadow(color: kNeonOrange.withOpacity(0.4), blurRadius: 10)],
                ),
                child: const Icon(Icons.remove_rounded, color: Colors.black, size: 28),
              ),
            ),
          ],
        ),
        const SizedBox(height: 20),
        Row(
          children: [
            _buildBetChip(minBet, minBet),
            _buildBetChip(25000, minBet),
            _buildBetChip(50000, minBet),
            _buildBetChip(100000, minBet),
            _buildBetChip(250000, minBet),
            _buildBetChip(500000, minBet),
            _buildBetChip(maxBet, minBet),
          ],
        ),
        const SizedBox(height: 24),
        GestureDetector(
          onTap: () {
            if (currentBalance >= betAmount) {
              onBet(betAmount);
            }
          },
          child: Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(vertical: 16),
            decoration: BoxDecoration(
              gradient: LinearGradient(colors: [color, color.withOpacity(0.7)]),
              borderRadius: BorderRadius.circular(30),
              boxShadow: [BoxShadow(color: color.withOpacity(0.4), blurRadius: 16)],
            ),
            child: Text(
              'BET NOW',
              textAlign: TextAlign.center,
              style: const TextStyle(color: Colors.black, fontWeight: FontWeight.bold, fontSize: 16, letterSpacing: 2),
            ),
          ),
        ),
      ],
    ),
  );
}

Widget _buildBetChip(double amount, double minBet) {
  return Expanded(
    child: GestureDetector(
      onTap: () {},
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 8),
        margin: const EdgeInsets.only(right: 4),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(12),
          color: kWhite08,
          border: Border.all(color: kNeonOrange.withOpacity(0.3)),
        ),
        child: Text(
          amount >= 1000000 ? '${(amount / 1000000).toInt()}M' : '${(amount / 1000).toInt()}K',
          textAlign: TextAlign.center,
          style: const TextStyle(color: kNeonOrange, fontSize: 10, fontWeight: FontWeight.bold),
        ),
      ),
    ),
  );
}

// ==================== MAIN PAGE ====================
class JudiGamePage extends StatefulWidget {
  final String username;
  final String sessionKey;
  
  const JudiGamePage({
    super.key,
    required this.username,
    required this.sessionKey,
  });
  
  @override
  State<JudiGamePage> createState() => _JudiGamePageState();
}

class _JudiGamePageState extends State<JudiGamePage> with SingleTickerProviderStateMixin {
  late UserBalance _balance;
  List<GameHistory> _history = [];
  List<GameModel> _games = [];
  bool _isLoading = true;
  int _selectedGameIndex = 0;
  bool _isPlaying = false;
  String _gameResult = '';
  double _lastWin = 0;
  
  late PageController _pageController;
  late TabController _tabController;
  
  // Deposit
  bool _isDepositing = false;
  String _depositQrisImage = '';
  String _currentQrisId = '';
  Timer? _paymentChecker;
  double _depositAmount = 50000;
  final TextEditingController _depositAmountCtrl = TextEditingController(text: '50000');
  
  // Withdraw
  bool _isWithdrawing = false;
  final TextEditingController _withdrawAmountCtrl = TextEditingController();
  final TextEditingController _bankAccountCtrl = TextEditingController();
  final TextEditingController _bankNameCtrl = TextEditingController();
  final TextEditingController _accountHolderCtrl = TextEditingController();
  
  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _pageController = PageController();
    _initGames();
    _loadBalance();
    _loadHistory();
  }
  
  @override
  void dispose() {
    _paymentChecker?.cancel();
    _tabController.dispose();
    _pageController.dispose();
    _depositAmountCtrl.dispose();
    _withdrawAmountCtrl.dispose();
    _bankAccountCtrl.dispose();
    _bankNameCtrl.dispose();
    _accountHolderCtrl.dispose();
    super.dispose();
  }
  
  void _initGames() {
    _games = [
      GameModel(id: 'mahjong', name: 'MAHJONG', icon: '🀄', color: kNeonPurple, minBet: 5000, maxBet: 1000000, multiplier: 2.5, rtp: 0.60, description: 'Classic tile matching'),
      GameModel(id: 'spaceman', name: 'SPACEMAN', icon: '🚀', color: kNeonBlue, minBet: 5000, maxBet: 500000, multiplier: 10.0, rtp: 0.55, description: 'Crash game high multiplier'),
      GameModel(id: 'slots', name: 'SLOTS', icon: '🎰', color: kNeonYellow, minBet: 5000, maxBet: 1000000, multiplier: 5.0, rtp: 0.58, description: 'Classic slot machine'),
      GameModel(id: 'dice', name: 'DICE', icon: '🎲', color: kNeonGreen, minBet: 5000, maxBet: 500000, multiplier: 1.5, rtp: 0.65, description: 'Roll the dice'),
      GameModel(id: 'roulette', name: 'ROULETTE', icon: '🎡', color: kNeonOrange, minBet: 10000, maxBet: 1000000, multiplier: 35.0, rtp: 0.50, description: 'European roulette'),
      GameModel(id: 'poker', name: 'POKER', icon: '🃏', color: kNeonPink, minBet: 10000, maxBet: 1000000, multiplier: 3.0, rtp: 0.55, description: 'Texas holdem'),
      GameModel(id: 'blackjack', name: 'BLACKJACK', icon: '♠', color: kRed, minBet: 10000, maxBet: 1000000, multiplier: 2.0, rtp: 0.60, description: '21 card game'),
      GameModel(id: 'baccarat', name: 'BACCARAT', icon: '🎴', color: kNeonPurple, minBet: 10000, maxBet: 1000000, multiplier: 1.8, rtp: 0.58, description: 'Player vs banker'),
      GameModel(id: 'cricket', name: 'CRICKET', icon: '🏏', color: kNeonGreen, minBet: 10000, maxBet: 500000, multiplier: 4.0, rtp: 0.55, description: 'Fantasy cricket'),
      GameModel(id: 'football', name: 'FOOTBALL', icon: '⚽', color: kNeonBlue, minBet: 10000, maxBet: 1000000, multiplier: 5.0, rtp: 0.52, description: 'Match result betting'),
    ];
  }
  
  Future<void> _loadBalance() async {
    final prefs = await SharedPreferences.getInstance();
    final balanceStr = prefs.getString('gaming_balance_${widget.username}');
    if (balanceStr != null) {
      _balance = UserBalance.fromJson(jsonDecode(balanceStr));
    } else {
      _balance = UserBalance();
    }
    setState(() {});
  }
  
  Future<void> _saveBalance() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('gaming_balance_${widget.username}', jsonEncode(_balance.toJson()));
  }
  
  Future<void> _loadHistory() async {
    final prefs = await SharedPreferences.getInstance();
    final historyStr = prefs.getString('gaming_history_${widget.username}');
    if (historyStr != null) {
      final List<dynamic> list = jsonDecode(historyStr);
      _history = list.map((e) => GameHistory.fromJson(e)).toList();
    }
    setState(() {});
  }
  
  Future<void> _saveHistory() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('gaming_history_${widget.username}', jsonEncode(_history.map((e) => e.toJson()).toList()));
  }
  
  void _addHistory(String gameName, double betAmount, double winAmount, String result) {
    _history.insert(0, GameHistory(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      gameName: gameName,
      betAmount: betAmount,
      winAmount: winAmount,
      result: result,
      timestamp: DateTime.now(),
    ));
    if (_history.length > 100) _history.removeLast();
    _saveHistory();
    setState(() {});
  }
  
  Future<void> _startDeposit() async {
    if (_isDepositing) return;
    
    final amount = double.tryParse(_depositAmountCtrl.text);
    if (amount == null || amount < 5000) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('MINIMUM DEPOSIT: 5.000'), backgroundColor: kRed),
      );
      return;
    }
    
    setState(() {
      _isDepositing = true;
      _depositQrisImage = '';
      _currentQrisId = '';
      _depositAmount = amount;
    });
    
    try {
      final payment = await QrispyPaymentService.createPayment(amount, widget.username);
      setState(() {
        _depositQrisImage = payment.qrisImageUrl;
        _currentQrisId = payment.qrisId;
      });
      
      _paymentChecker = Timer.periodic(const Duration(seconds: 3), (timer) async {
        try {
          final status = await QrispyPaymentService.checkPaymentStatus(_currentQrisId);
          if (status['payment_status'] == 'paid') {
            timer.cancel();
            final paidAmount = (status['amount'] ?? amount).toDouble();
            setState(() {
              _balance.balance += paidAmount;
              _balance.totalDeposit += paidAmount;
            });
            await _saveBalance();
            _addHistory('DEPOSIT', paidAmount, 0, 'SUCCESS');
            setState(() {
              _isDepositing = false;
              _depositQrisImage = '';
              _currentQrisId = '';
            });
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text('DEPOSIT SUCCESS: Rp ${paidAmount.toInt()}'), backgroundColor: kNeonGreen),
            );
          }
        } catch (e) {}
      });
      
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('QRIS GENERATED'), backgroundColor: kNeonBlue),
      );
    } catch (e) {
      setState(() => _isDepositing = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('DEPOSIT FAILED: ${e.toString()}'), backgroundColor: kRed),
      );
    }
  }
  
  Future<void> _shareQris() async {
    if (_depositQrisImage.isEmpty) return;
    
    try {
      final response = await http.get(Uri.parse(_depositQrisImage));
      if (response.statusCode == 200) {
        final tempDir = await getTemporaryDirectory();
        final file = File('${tempDir.path}/qris_${DateTime.now().millisecondsSinceEpoch}.png');
        await file.writeAsBytes(response.bodyBytes);
        
        await Share.shareXFiles(
          [XFile(file.path)],
          text: 'QRIS PAYMENT - Rp ${_depositAmount.toInt()}',
        );
        
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('QRIS SHARED'), backgroundColor: kNeonGreen),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('SHARE FAILED: $e'), backgroundColor: kRed),
      );
    }
  }
  
  Future<void> _playGame(double betAmount) async {
    if (_isPlaying) return;
    
    final game = _games[_selectedGameIndex];
    
    if (_balance.balance < betAmount) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('INSUFFICIENT BALANCE'), backgroundColor: kRed),
      );
      return;
    }
    
    setState(() {
      _isPlaying = true;
      _gameResult = '';
      _lastWin = 0;
    });
    
    _balance.balance -= betAmount;
    _balance.totalBet += betAmount;
    await _saveBalance();
    
    final winAmount = await GameService.playGame(game.id, betAmount, game.rtp);
    String resultText = 'LOSE';
    
    if (winAmount > 0) {
      _balance.balance += winAmount;
      _balance.totalWin += winAmount;
      _lastWin = winAmount;
      _gameResult = '+${winAmount.toInt()}';
      resultText = winAmount > betAmount * 3 ? 'JACKPOT' : 'WIN';
    } else {
      _gameResult = '-${betAmount.toInt()}';
    }
    
    await _saveBalance();
    _addHistory(game.name, betAmount, winAmount, resultText);
    
    setState(() => _isPlaying = false);
    
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(winAmount > 0 ? 'WIN: +${winAmount.toInt()}' : 'LOSE: -${betAmount.toInt()}'),
        backgroundColor: winAmount > 0 ? kNeonGreen : kRed,
      ),
    );
  }
  
  Future<void> _requestWithdraw() async {
    if (_isWithdrawing) return;
    
    final amount = double.tryParse(_withdrawAmountCtrl.text);
    if (amount == null || amount < 50000) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('MIN WITHDRAW: 50.000'), backgroundColor: kRed),
      );
      return;
    }
    if (_balance.balance < amount) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('INSUFFICIENT BALANCE'), backgroundColor: kRed),
      );
      return;
    }
    if (_bankNameCtrl.text.isEmpty || _bankAccountCtrl.text.isEmpty || _accountHolderCtrl.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('COMPLETE BANK DETAILS'), backgroundColor: kRed),
      );
      return;
    }
    
    setState(() => _isWithdrawing = true);
    
    await Future.delayed(const Duration(seconds: 3));
    
    setState(() {
      _balance.balance -= amount;
      _balance.totalWithdraw += amount;
    });
    await _saveBalance();
    _addHistory('WITHDRAW', amount, 0, 'PENDING');
    
    setState(() {
      _isWithdrawing = false;
      _withdrawAmountCtrl.clear();
    });
    
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('WITHDRAW REQUEST: Rp ${amount.toInt()} (1-24 HOURS)'), backgroundColor: kNeonOrange),
    );
  }
  
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: kBgDark,
      appBar: _buildAppBar(),
      body: Column(
        children: [
          _buildBalanceCard(),
          _buildGameCarousel(),
          _buildTabBar(),
          Expanded(
            child: TabBarView(
              controller: _tabController,
              children: [
                _buildGameDetail(),
                _buildDepositTab(),
                _buildHistoryTab(),
              ],
            ),
          ),
        ],
      ),
    );
  }
  
  PreferredSizeWidget _buildAppBar() {
    return AppBar(
      backgroundColor: kBgDark.withOpacity(0.95),
      elevation: 0,
      title: const Text(
        'KNIGHT GAMING',
        style: TextStyle(
          color: kNeonGreen,
          fontSize: 18,
          fontWeight: FontWeight.bold,
          fontFamily: 'Orbitron',
          letterSpacing: 2,
        ),
      ),
      centerTitle: true,
      leading: IconButton(
        icon: const Icon(Icons.arrow_back_rounded, color: kWhite),
        onPressed: () => Navigator.pop(context),
      ),
      flexibleSpace: Container(
        decoration: BoxDecoration(
          border: Border(bottom: BorderSide(color: kNeonBlue.withOpacity(0.3))),
        ),
      ),
    );
  }
  
  Widget _buildBalanceCard() {
    return Container(
      margin: const EdgeInsets.all(16),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [kBgCard, kBgCardLight],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: kNeonGreen.withOpacity(0.5)),
        boxShadow: [
          BoxShadow(color: kNeonGreen.withOpacity(0.2), blurRadius: 20, offset: const Offset(0, 8)),
        ],
      ),
      child: Row(
        children: [
          Container(
            width: 60, height: 60,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: LinearGradient(colors: [kNeonGreen, kNeonBlue]),
              boxShadow: [BoxShadow(color: kNeonGreen.withOpacity(0.5), blurRadius: 12)],
            ),
            child: const Center(
              child: Icon(Icons.account_balance_wallet_rounded, color: Colors.black, size: 30),
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'TOTAL BALANCE',
                  style: TextStyle(color: kWhite70, fontSize: 12, letterSpacing: 1),
                ),
                const SizedBox(height: 4),
                Text(
                  'Rp ${_balance.balance.toInt()}',
                  style: const TextStyle(
                    color: kNeonGreen,
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    fontFamily: 'Orbitron',
                  ),
                ),
                const SizedBox(height: 4),
                Row(
                  children: [
                    _buildStatChip('DEP: ${_balance.totalDeposit.toInt()}', kNeonBlue),
                    const SizedBox(width: 8),
                    _buildStatChip('WIN: ${_balance.totalWin.toInt()}', kNeonYellow),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
  
  Widget _buildStatChip(String text, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(12),
        color: color.withOpacity(0.15),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Text(text, style: TextStyle(color: color, fontSize: 10, fontWeight: FontWeight.bold)),
    );
  }
  
  Widget _buildGameCarousel() {
    return SizedBox(
      height: 100,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 16),
        itemCount: _games.length,
        itemBuilder: (context, index) {
          final game = _games[index];
          final isSelected = _selectedGameIndex == index;
          return GestureDetector(
            onTap: () {
              setState(() {
                _selectedGameIndex = index;
                _pageController.jumpToPage(index);
              });
            },
            child: Container(
              width: 80,
              margin: const EdgeInsets.only(right: 12),
              padding: const EdgeInsets.symmetric(vertical: 12),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(16),
                gradient: isSelected
                    ? LinearGradient(colors: [game.color, game.color.withOpacity(0.5)])
                    : null,
                border: Border.all(color: isSelected ? game.color : kWhite15, width: isSelected ? 2 : 1),
                color: isSelected ? Colors.transparent : kWhite08,
              ),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(game.icon, style: const TextStyle(fontSize: 28)),
                  const SizedBox(height: 4),
                  Text(
                    game.name,
                    style: TextStyle(
                      color: isSelected ? Colors.black : kWhite,
                      fontWeight: FontWeight.bold,
                      fontSize: 10,
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
  
  Widget _buildTabBar() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(30),
        color: kBgCard,
        border: Border.all(color: kNeonBlue.withOpacity(0.3)),
      ),
      child: TabBar(
        controller: _tabController,
        indicator: BoxDecoration(
          borderRadius: BorderRadius.circular(30),
          gradient: LinearGradient(colors: [kNeonBlue, kNeonGreen]),
        ),
        labelColor: Colors.black,
        unselectedLabelColor: kWhite70,
        tabs: const [
          Tab(text: 'GAMES'),
          Tab(text: 'DEPOSIT'),
          Tab(text: 'HISTORY'),
        ],
      ),
    );
  }
  
  Widget _buildGameDetail() {
    final game = _games[_selectedGameIndex];
    
    return Container(
      margin: const EdgeInsets.all(16),
      child: Transform(
        transform: Matrix4.identity()..setEntry(3, 2, 0.001)..rotateX(0.01),
        child: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [kBgCard, kBgCardLight],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(24),
            border: Border.all(color: game.color.withOpacity(0.5), width: 2),
            boxShadow: [
              BoxShadow(color: game.color.withOpacity(0.3), blurRadius: 20, offset: const Offset(0, 10)),
            ],
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const SizedBox(height: 30),
              Container(
                width: 120, height: 120,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: LinearGradient(
                    colors: [game.color.withOpacity(0.3), game.color.withOpacity(0.1)],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  border: Border.all(color: game.color, width: 3),
                  boxShadow: [
                    BoxShadow(color: game.color.withOpacity(0.5), blurRadius: 25, spreadRadius: 5),
                  ],
                ),
                child: Center(
                  child: Text(game.icon, style: const TextStyle(fontSize: 60)),
                ),
              ),
              const SizedBox(height: 24),
              Text(
                game.name,
                style: TextStyle(
                  color: game.color,
                  fontSize: 28,
                  fontWeight: FontWeight.bold,
                  fontFamily: 'Orbitron',
                  letterSpacing: 3,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                game.description,
                style: const TextStyle(color: kWhite70, fontSize: 12),
              ),
              const SizedBox(height: 16),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(20),
                      color: game.color.withOpacity(0.2),
                      border: Border.all(color: game.color.withOpacity(0.3)),
                    ),
                    child: Text('MIN: ${(game.minBet / 1000).toInt()}K', style: TextStyle(color: game.color, fontSize: 12, fontWeight: FontWeight.bold)),
                  ),
                  const SizedBox(width: 12),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(20),
                      color: game.color.withOpacity(0.2),
                      border: Border.all(color: game.color.withOpacity(0.3)),
                    ),
                    child: Text('MAX: ${game.maxBet >= 1000000 ? '${(game.maxBet / 1000000).toInt()}M' : '${(game.maxBet / 1000).toInt()}K'}', style: TextStyle(color: game.color, fontSize: 12, fontWeight: FontWeight.bold)),
                  ),
                  const SizedBox(width: 12),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(20),
                      color: kNeonYellow.withOpacity(0.2),
                      border: Border.all(color: kNeonYellow.withOpacity(0.3)),
                    ),
                    child: Text('MULTI: ${game.multiplier}x', style: const TextStyle(color: kNeonYellow, fontSize: 12, fontWeight: FontWeight.bold)),
                  ),
                ],
              ),
              const SizedBox(height: 30),
              _buildBetControls(game),
              const SizedBox(height: 30),
              if (_gameResult.isNotEmpty)
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(16),
                    gradient: LinearGradient(
                      colors: _lastWin > 0 ? [kNeonGreen.withOpacity(0.2), kNeonGreen.withOpacity(0.05)] : [kRed.withOpacity(0.2), kRed.withOpacity(0.05)],
                    ),
                    border: Border.all(color: _lastWin > 0 ? kNeonGreen : kRed, width: 2),
                  ),
                  child: Text(
                    _gameResult,
                    style: TextStyle(
                      color: _lastWin > 0 ? kNeonGreen : kRed,
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      fontFamily: 'Orbitron',
                    ),
                  ),
                ),
              const SizedBox(height: 30),
            ],
          ),
        ),
      ),
    );
  }
  
  Widget _buildBetControls(GameModel game) {
    double betAmount = game.minBet;
    
    return Column(
      children: [
        Row(
          children: [
            Expanded(
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(16),
                  color: kWhite08,
                  border: Border.all(color: game.color.withOpacity(0.3)),
                ),
                child: Row(
                  children: [
                    const Text('Rp ', style: TextStyle(color: kNeonOrange, fontWeight: FontWeight.bold)),
                    Expanded(
                      child: StatefulBuilder(
                        builder: (context, setStateBet) {
                          return TextField(
                            keyboardType: TextInputType.number,
                            style: const TextStyle(color: kWhite, fontSize: 16, fontWeight: FontWeight.bold),
                            decoration: const InputDecoration(border: InputBorder.none, isDense: true),
                            onChanged: (value) {
                              final val = double.tryParse(value);
                              if (val != null) betAmount = val.clamp(game.minBet, game.maxBet);
                            },
                          );
                        },
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(width: 12),
            GestureDetector(
              onTap: () => betAmount = (betAmount * 2).clamp(game.minBet, game.maxBet),
              child: Container(
                width: 50, height: 50,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: LinearGradient(colors: [kNeonOrange, kNeonPink]),
                  boxShadow: [BoxShadow(color: kNeonOrange.withOpacity(0.4), blurRadius: 10)],
                ),
                child: const Icon(Icons.add_rounded, color: Colors.black, size: 28),
              ),
            ),
            const SizedBox(width: 8),
            GestureDetector(
              onTap: () => betAmount = (betAmount / 2).clamp(game.minBet, game.maxBet),
              child: Container(
                width: 50, height: 50,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: LinearGradient(colors: [kNeonOrange, kNeonPink]),
                  boxShadow: [BoxShadow(color: kNeonOrange.withOpacity(0.4), blurRadius: 10)],
                ),
                child: const Icon(Icons.remove_rounded, color: Colors.black, size: 28),
              ),
            ),
          ],
        ),
        const SizedBox(height: 20),
        GestureDetector(
          onTap: () => _playGame(betAmount),
          child: Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(vertical: 16),
            decoration: BoxDecoration(
              gradient: LinearGradient(colors: [game.color, game.color.withOpacity(0.7)]),
              borderRadius: BorderRadius.circular(30),
              boxShadow: [BoxShadow(color: game.color.withOpacity(0.5), blurRadius: 20)],
            ),
            child: _isPlaying
                ? const SizedBox(height: 20, width: 20, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.black))
                : Text(
                    'SPIN NOW',
                    textAlign: TextAlign.center,
                    style: const TextStyle(color: Colors.black, fontWeight: FontWeight.bold, fontSize: 18, letterSpacing: 2),
                  ),
          ),
        ),
      ],
    );
  }
  
  Widget _buildDepositTab() {
    return SingleChildScrollView(
      physics: const BouncingScrollPhysics(),
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          Transform(
            transform: Matrix4.identity()..setEntry(3, 2, 0.001)..rotateX(0.005),
            child: Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [kBgCard, kBgCardLight],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(24),
                border: Border.all(color: kNeonBlue.withOpacity(0.5)),
                boxShadow: [
                  BoxShadow(color: kNeonBlue.withOpacity(0.2), blurRadius: 20, offset: const Offset(0, 10)),
                ],
              ),
              child: Column(
                children: [
                  const Icon(Icons.qr_code_scanner_rounded, color: kNeonBlue, size: 60),
                  const SizedBox(height: 16),
                  const Text(
                    'CUSTOM DEPOSIT',
                    style: TextStyle(color: kNeonBlue, fontSize: 18, fontWeight: FontWeight.bold, letterSpacing: 2),
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    'Enter deposit amount',
                    style: TextStyle(color: kWhite70, fontSize: 12),
                  ),
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      const Text('Rp ', style: TextStyle(color: kNeonGreen, fontSize: 20, fontWeight: FontWeight.bold)),
                      Expanded(
                        child: TextField(
                          controller: _depositAmountCtrl,
                          keyboardType: TextInputType.number,
                          style: const TextStyle(color: kWhite, fontSize: 20, fontWeight: FontWeight.bold),
                          decoration: InputDecoration(
                            hintText: '50000',
                            hintStyle: const TextStyle(color: kWhite40),
                            border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                            enabledBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                              borderSide: BorderSide(color: kNeonBlue.withOpacity(0.3)),
                            ),
                            focusedBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                              borderSide: const BorderSide(color: kNeonBlue),
                            ),
                            contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: [
                      _buildDepositPreset(10000),
                      _buildDepositPreset(25000),
                      _buildDepositPreset(50000),
                      _buildDepositPreset(100000),
                      _buildDepositPreset(250000),
                      _buildDepositPreset(500000),
                      _buildDepositPreset(1000000),
                    ],
                  ),
                  const SizedBox(height: 24),
                  GestureDetector(
                    onTap: _startDeposit,
                    child: Container(
                      width: double.infinity,
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      decoration: BoxDecoration(
                        gradient: const LinearGradient(colors: [kNeonGreen, kNeonBlue]),
                        borderRadius: BorderRadius.circular(30),
                        boxShadow: [BoxShadow(color: kNeonGreen.withOpacity(0.4), blurRadius: 15)],
                      ),
                      child: _isDepositing
                          ? const SizedBox(height: 24, width: 24, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.black))
                          : const Text(
                              'GENERATE QRIS',
                              textAlign: TextAlign.center,
                              style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold, fontSize: 16, letterSpacing: 2),
                            ),
                    ),
                  ),
                  if (_depositQrisImage.isNotEmpty) ...[
                    const SizedBox(height: 24),
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(20),
                        color: kWhite08,
                        border: Border.all(color: kNeonBlue.withOpacity(0.3)),
                      ),
                      child: Column(
                        children: [
                          const Text(
                            'SCAN QRIS TO PAY',
                            style: TextStyle(color: kNeonBlue, fontSize: 12, fontWeight: FontWeight.bold),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            'Amount: Rp ${_depositAmount.toInt()}',
                            style: const TextStyle(color: kNeonGreen, fontSize: 14, fontWeight: FontWeight.bold),
                          ),
                          const SizedBox(height: 12),
                          ClipRRect(
                            borderRadius: BorderRadius.circular(16),
                            child: Image.network(_depositQrisImage, height: 200),
                          ),
                          const SizedBox(height: 12),
                          GestureDetector(
                            onTap: _shareQris,
                            child: Container(
                              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                              decoration: BoxDecoration(
                                borderRadius: BorderRadius.circular(20),
                                color: kNeonBlue,
                              ),
                              child: const Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Icon(Icons.share_rounded, color: Colors.black, size: 18),
                                  SizedBox(width: 8),
                                  Text('SHARE QRIS', style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold)),
                                ],
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ),
          const SizedBox(height: 20),
          _buildWithdrawCard(),
        ],
      ),
    );
  }
  
  Widget _buildDepositPreset(int amount) {
    return GestureDetector(
      onTap: () => _depositAmountCtrl.text = amount.toString(),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(20),
          color: kWhite08,
          border: Border.all(color: kNeonBlue.withOpacity(0.3)),
        ),
        child: Text(
          'Rp ${amount >= 1000000 ? '${(amount / 1000000).toInt()}JT' : '${(amount / 1000).toInt()}K'}',
          style: const TextStyle(color: kNeonBlue, fontSize: 12, fontWeight: FontWeight.bold),
        ),
      ),
    );
  }
  
  Widget _buildWithdrawCard() {
    return Transform(
      transform: Matrix4.identity()..setEntry(3, 2, 0.001)..rotateX(0.005),
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [kBgCard, kBgCardLight],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(24),
          border: Border.all(color: kNeonOrange.withOpacity(0.5)),
          boxShadow: [
            BoxShadow(color: kNeonOrange.withOpacity(0.2), blurRadius: 20, offset: const Offset(0, 10)),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(Icons.wallet_rounded, color: kNeonOrange),
                const SizedBox(width: 8),
                const Text(
                  'WITHDRAW',
                  style: TextStyle(color: kNeonOrange, fontSize: 18, fontWeight: FontWeight.bold, letterSpacing: 1),
                ),
              ],
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _withdrawAmountCtrl,
              keyboardType: TextInputType.number,
              style: const TextStyle(color: kWhite),
              decoration: InputDecoration(
                labelText: 'WITHDRAW AMOUNT',
                labelStyle: const TextStyle(color: kWhite70),
                prefixText: 'Rp ',
                prefixStyle: const TextStyle(color: kNeonOrange),
                filled: true,
                fillColor: kWhite08,
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: kNeonOrange.withOpacity(0.3))),
              ),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _bankNameCtrl,
              style: const TextStyle(color: kWhite),
              decoration: InputDecoration(
                labelText: 'BANK NAME',
                labelStyle: const TextStyle(color: kWhite70),
                hintText: 'BCA / MANDIRI / BRI / BNI',
                hintStyle: const TextStyle(color: kWhite40),
                filled: true,
                fillColor: kWhite08,
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
              ),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _accountHolderCtrl,
              style: const TextStyle(color: kWhite),
              decoration: InputDecoration(
                labelText: 'ACCOUNT HOLDER',
                labelStyle: const TextStyle(color: kWhite70),
                filled: true,
                fillColor: kWhite08,
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
              ),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _bankAccountCtrl,
              style: const TextStyle(color: kWhite),
              decoration: InputDecoration(
                labelText: 'ACCOUNT NUMBER',
                labelStyle: const TextStyle(color: kWhite70),
                filled: true,
                fillColor: kWhite08,
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
              ),
            ),
            const SizedBox(height: 20),
            GestureDetector(
              onTap: _requestWithdraw,
              child: Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(vertical: 14),
                decoration: BoxDecoration(
                  gradient: LinearGradient(colors: [kNeonOrange, kNeonPink]),
                  borderRadius: BorderRadius.circular(30),
                  boxShadow: [BoxShadow(color: kNeonOrange.withOpacity(0.4), blurRadius: 15)],
                ),
                child: _isWithdrawing
                    ? const SizedBox(height: 20, width: 20, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.black))
                    : const Text(
                        'REQUEST WITHDRAW',
                        textAlign: TextAlign.center,
                        style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold, letterSpacing: 2),
                      ),
              ),
            ),
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(12),
                color: kRed.withOpacity(0.1),
                border: Border.all(color: kRed.withOpacity(0.3)),
              ),
              child: const Row(
                children: [
                  Icon(Icons.warning_rounded, color: kRed, size: 16),
                  SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'WITHDRAW PROCESSED IN 1-24 HOURS. MINIMUM WITHDRAW 50.000',
                      style: TextStyle(color: kRed, fontSize: 10),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
  
  Widget _buildHistoryTab() {
    if (_history.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.history_rounded, color: kWhite40, size: 60),
            const SizedBox(height: 16),
            const Text(
              'NO TRANSACTION HISTORY',
              style: TextStyle(color: kWhite40, fontSize: 14, fontFamily: 'Orbitron'),
            ),
          ],
        ),
      );
    }
    
    return ListView.builder(
      physics: const BouncingScrollPhysics(),
      padding: const EdgeInsets.all(16),
      itemCount: _history.length,
      itemBuilder: (context, index) {
        final h = _history[index];
        final isWin = h.winAmount > h.betAmount;
        return Container(
          margin: const EdgeInsets.only(bottom: 12),
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            gradient: LinearGradient(
              colors: [kBgCard, kBgCardLight],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            border: Border.all(color: (isWin ? kNeonGreen : kRed).withOpacity(0.3)),
          ),
          child: Row(
            children: [
              Container(
                width: 50, height: 50,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: (isWin ? kNeonGreen : kRed).withOpacity(0.15),
                ),
                child: Icon(isWin ? Icons.trending_up_rounded : Icons.trending_down_rounded, color: isWin ? kNeonGreen : kRed, size: 28),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(h.gameName, style: const TextStyle(color: kWhite, fontWeight: FontWeight.bold)),
                    const SizedBox(height: 4),
                    Text(
                      '${h.timestamp.day}/${h.timestamp.month}/${h.timestamp.year} ${h.timestamp.hour.toString().padLeft(2, '0')}:${h.timestamp.minute.toString().padLeft(2, '0')}',
                      style: const TextStyle(color: kWhite40, fontSize: 10),
                    ),
                  ],
                ),
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    'Rp ${h.betAmount.toInt()}',
                    style: const TextStyle(color: kWhite70, fontSize: 12),
                  ),
                  const SizedBox(height: 4),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(8),
                      color: (isWin ? kNeonGreen : kRed).withOpacity(0.2),
                    ),
                    child: Text(
                      h.winAmount > 0 ? '+${h.winAmount.toInt()}' : 'LOSE',
                      style: TextStyle(color: isWin ? kNeonGreen : kRed, fontSize: 11, fontWeight: FontWeight.bold),
                    ),
                  ),
                ],
              ),
            ],
          ),
        );
      },
    );
  }
}