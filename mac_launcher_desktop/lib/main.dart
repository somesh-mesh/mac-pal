import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:window_manager/window_manager.dart';
import 'screens/home_screen.dart';
import 'providers/server_provider.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await windowManager.ensureInitialized();
  await windowManager.setSize(const Size(400, 580));
  await windowManager.setMinimumSize(const Size(360, 500));
  await windowManager.setMaximumSize(const Size(480, 720));
  await windowManager.setTitle('Mac Launcher');
  await windowManager.center();

  runApp(const ProviderScope(child: MacLauncherApp()));
}

class MacLauncherApp extends ConsumerStatefulWidget {
  const MacLauncherApp({super.key});

  @override
  ConsumerState<MacLauncherApp> createState() => _MacLauncherAppState();
}

class _MacLauncherAppState extends ConsumerState<MacLauncherApp> {
  @override
  void initState() {
    super.initState();
    // Auto-start server when app launches — no manual npm start needed
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(serverProvider.notifier).startServer();
    });
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Mac Launcher',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        brightness: Brightness.dark,
        scaffoldBackgroundColor: const Color(0xFF1C1C1E),
        colorScheme: const ColorScheme.dark(
          primary: Color(0xFF0A84FF),
          surface: Color(0xFF2C2C2E),
        ),
      ),
      home: const HomeScreen(),
    );
  }
}
