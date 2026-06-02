import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'features/apps/apps_screen.dart';
import 'features/settings/settings_provider.dart';
import 'features/settings/settings_screen.dart';

void main() {
  runApp(
    // ProviderScope is required — root container for all Riverpod providers
    const ProviderScope(child: MacLauncherApp()),
  );
}

class MacLauncherApp extends ConsumerWidget {
  const MacLauncherApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // Watch settings — determines which screen to show on launch
    final settings = ref.watch(settingsProvider);

    return MaterialApp(
      title: 'Mac Launcher',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorSchemeSeed: Colors.blue,
        useMaterial3: true,
      ),
      home: settings.when(
        // IP saved → go straight to apps screen
        // Not configured → show settings screen to enter IP
        data:    (s) => s.isConfigured ? const AppsScreen() : const SettingsScreen(),
        // While SharedPreferences loads from disk
        loading: () => const Scaffold(
          body: Center(child: CircularProgressIndicator()),
        ),
        // SharedPreferences failed (very unlikely) — show settings
        error:   (e, _) => const SettingsScreen(),
      ),
    );
  }
}
