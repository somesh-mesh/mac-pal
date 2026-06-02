import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

// SharedPreferences keys
const _kIp   = 'mac_ip';
const _kPort = 'mac_port';

// Data class that holds IP + port and exposes a baseUrl getter
class MacSettings {
  final String ip;
  final int port;

  const MacSettings({required this.ip, required this.port});

  // Builds the full base URL used by Dio: "http://192.168.1.4:3000"
  String get baseUrl => 'http://$ip:$port';

  // True only when the user has entered an IP — used in main.dart routing
  bool get isConfigured => ip.isNotEmpty;
}

// Riverpod provider — reads/writes settings to SharedPreferences
// AsyncNotifier because loading from SharedPreferences is async
class SettingsNotifier extends AsyncNotifier<MacSettings> {
  @override
  Future<MacSettings> build() async {
    // Called once when provider is first read — loads saved values from disk
    final prefs = await SharedPreferences.getInstance();
    return MacSettings(
      ip:   prefs.getString(_kIp)  ?? '',
      port: prefs.getInt(_kPort)   ?? 3000,
    );
  }

  // Called when user taps Save in SettingsScreen
  Future<void> save(String ip, int port) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_kIp,  ip);
    await prefs.setInt(_kPort, port);

    // Update in-memory state so UI rebuilds immediately
    state = AsyncData(MacSettings(ip: ip, port: port));
  }
}

// The provider — every widget that needs settings watches this
final settingsProvider = AsyncNotifierProvider<SettingsNotifier, MacSettings>(
  SettingsNotifier.new,
);
