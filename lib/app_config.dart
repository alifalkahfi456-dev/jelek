import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

// ═══════════════════════════════════════════════════════════════════════
// APP CONFIG — AUTO GANTI SERVER TANPA BUILD ULANG
//
// Cara kerja:
// 1. App buka → fetch /getServerConfig dari server aktif
// 2. Kalau server mati → fetch config dari Telegram Bot API
//    (owner kirim /setserver di bot → config tersimpan di Telegram)
// 3. Kalau keduanya gagal → pakai config terakhir yang tersimpan di HP
// 4. Kalau tidak ada sama sekali → pakai default di sini
//
// Untuk ganti server: kirim /setserver domain.com:port ke bot
// ═══════════════════════════════════════════════════════════════════════

// ── DEFAULT CONFIG — ubah di sini saat pertama build ──────────────────
const String _kDefaultDomain = 'rezzagntk.jserver.web.id';
const int    _kDefaultPort   = 2172;

// ── TOKEN BOT TELEGRAM — untuk fallback fetch config ──────────────────
// Tidak perlu ganti, sudah otomatis dipakai saat server mati
const String _kBotToken  = '8751814756:AAFHe-VYxQOVRPsYTwfc76yKHodOPTk-hxA';
const int    _kOwnerId   = 8792779558; // chat_id owner tempat config dikirim

// ── Runtime values — jangan ubah manual ───────────────────────────────
String _kDomain = _kDefaultDomain;
int    _kPort   = _kDefaultPort;

String get kDomain  => _kDomain;
int    get kPort    => _kPort;
String get kBaseUrl => 'http://$_kDomain:$_kPort';

/// Panggil di main() sebelum runApp()
Future<void> initServerConfig() async {
  final prefs = await SharedPreferences.getInstance();

  // Langkah 1: Pakai config tersimpan di HP dulu (agar tidak tunggu network)
  final cachedDomain    = prefs.getString('cfg_domain');
  final cachedPort      = prefs.getInt('cfg_port');
  final cachedUpdatedAt = prefs.getInt('cfg_updated_at') ?? 0;
  if (cachedDomain != null && cachedPort != null) {
    _kDomain = cachedDomain;
    _kPort   = cachedPort;
  }

  // Langkah 2: Coba fetch dari server aktif
  bool fetchedFromServer = false;
  try {
    final res = await http.get(
      Uri.parse('http://$_kDomain:$_kPort/getServerConfig'),
    ).timeout(const Duration(seconds: 4));

    if (res.statusCode == 200) {
      final data = jsonDecode(res.body);
      if (data['valid'] == true) {
        final serverUpdatedAt = (data['updatedAt'] ?? 0) as int;
        // Hanya update kalau config server lebih baru
        if (serverUpdatedAt >= cachedUpdatedAt) {
          _kDomain = data['domain'] ?? _kDomain;
          _kPort   = (data['port'] is int) ? data['port'] : int.tryParse('${data["port"]}') ?? _kPort;
          await prefs.setString('cfg_domain', _kDomain);
          await prefs.setInt('cfg_port', _kPort);
          await prefs.setInt('cfg_updated_at', serverUpdatedAt);
          fetchedFromServer = true;
        }
      }
    }
  } catch (_) {
    // Server mati atau tidak bisa dijangkau — lanjut ke fallback
  }

  // Langkah 3: Kalau server gagal → fetch dari Telegram Bot API
  // Owner /setserver → bot kirim pesan ##AXCONFIG##{"domain":"...","port":...}##END##
  // Flutter baca pesan itu dari Telegram getUpdates
  if (!fetchedFromServer) {
    try {
      final tgRes = await http.get(
        Uri.parse(
          'https://api.telegram.org/bot$_kBotToken/getUpdates'
          '?limit=100&offset=-100',
        ),
      ).timeout(const Duration(seconds: 6));

      if (tgRes.statusCode == 200) {
        final tgData = jsonDecode(tgRes.body);
        final results = (tgData['result'] as List?) ?? [];

        // Cari pesan ##AXCONFIG## terbaru dari owner
        Map<String, dynamic>? latestCfg;
        int latestTs = cachedUpdatedAt;

        for (final update in results.reversed) {
          try {
            final msg   = update['message'];
            if (msg == null) continue;
            final from  = msg['from']?['id'] as int?;
            final text  = msg['text'] as String? ?? '';
            if (from != _kOwnerId) continue;
            if (!text.contains('##AXCONFIG##')) continue;

            final start = text.indexOf('##AXCONFIG##') + '##AXCONFIG##'.length;
            final end   = text.indexOf('##END##');
            if (start < 0 || end < 0 || end <= start) continue;

            final cfgJson = text.substring(start, end);
            final cfg     = jsonDecode(cfgJson);
            final ts      = (cfg['updatedAt'] ?? 0) as int;

            if (ts > latestTs) {
              latestTs  = ts;
              latestCfg = cfg;
            }
          } catch (_) {}
        }

        if (latestCfg != null) {
          final newDomain = latestCfg['domain'] as String?;
          final newPort   = latestCfg['port'] is int
              ? latestCfg['port'] as int
              : int.tryParse('${latestCfg["port"]}');

          if (newDomain != null && newPort != null) {
            _kDomain = newDomain;
            _kPort   = newPort;
            await prefs.setString('cfg_domain', _kDomain);
            await prefs.setInt('cfg_port', _kPort);
            await prefs.setInt('cfg_updated_at', latestTs);
          }
        }
      }
    } catch (_) {
      // Telegram juga gagal — tetap pakai cache/default
    }
  }
}
