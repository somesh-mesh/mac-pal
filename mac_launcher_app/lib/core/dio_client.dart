import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../features/settings/settings_provider.dart';

// Riverpod provider that creates a configured Dio HTTP client.
// Watches settingsProvider — when the user changes IP, Dio rebuilds
// automatically with the new baseUrl.
final dioProvider = Provider<Dio>((ref) {
  // Watch settings — if IP/port changes, this provider re-creates Dio
  final settings = ref.watch(settingsProvider).valueOrNull;

  // Fallback to localhost while settings are still loading
  final baseUrl = settings?.baseUrl ?? 'http://localhost:3000';

  return Dio(
    BaseOptions(
      baseUrl: baseUrl,
      // 3 seconds to connect — shows "offline" error quickly if Mac unreachable
      connectTimeout: const Duration(seconds: 3),
      // 5 seconds to receive response — covers slow WiFi
      receiveTimeout: const Duration(seconds: 5),
    ),
  );
});
