import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../apps/apps_repository.dart';
import '../apps/apps_screen.dart';
import 'settings_provider.dart';

class SettingsScreen extends ConsumerStatefulWidget {
  const SettingsScreen({super.key});

  @override
  ConsumerState<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends ConsumerState<SettingsScreen> {
  final _ipController   = TextEditingController();
  final _portController = TextEditingController(text: '3000');

  // null = not tested yet, true = connected, false = failed
  bool? _connectionResult;
  bool _isTesting = false;

  @override
  void initState() {
    super.initState();
    // Pre-fill fields with saved values (if any)
    final settings = ref.read(settingsProvider).valueOrNull;
    if (settings != null) {
      _ipController.text   = settings.ip;
      _portController.text = settings.port.toString();
    }
  }

  @override
  void dispose() {
    _ipController.dispose();
    _portController.dispose();
    super.dispose();
  }

  Future<void> _testConnection() async {
    // Save current values before testing
    await _save();

    setState(() {
      _isTesting        = true;
      _connectionResult = null;
    });

    // Ping the server — AppsRepository handles the HTTP call
    final repo   = ref.read(appsRepositoryProvider);
    final result = await repo.ping();

    setState(() {
      _isTesting        = false;
      _connectionResult = result;
    });

    // Navigate to apps screen on successful connection
    if (!result || !mounted) return;
    Navigator.of(context).pushReplacement(
      MaterialPageRoute(builder: (_) => const AppsScreen()),
    );
  }

  Future<void> _save() async {
    final ip   = _ipController.text.trim();
    final port = int.tryParse(_portController.text.trim()) ?? 3000;
    await ref.read(settingsProvider.notifier).save(ip, port);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Mac Launcher — Setup')),
      body: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Instruction text
            const Text(
              'Enter your Mac\'s local IP address.\n'
              'Run this on your Mac to find it:\n'
              'ipconfig getifaddr en0',
              style: TextStyle(color: Colors.grey),
            ),
            const SizedBox(height: 24),

            // IP address input
            TextField(
              controller: _ipController,
              keyboardType: TextInputType.numberWithOptions(decimal: true),
              decoration: const InputDecoration(
                labelText: 'Mac IP Address',
                hintText: '192.168.1.4',
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.computer),
              ),
            ),
            const SizedBox(height: 16),

            // Port input
            TextField(
              controller: _portController,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(
                labelText: 'Port',
                hintText: '3000',
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.settings_ethernet),
              ),
            ),
            const SizedBox(height: 24),

            // Save button
            OutlinedButton(
              onPressed: () async {
                await _save();
                if (!mounted) return;
                // ignore: use_build_context_synchronously
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Settings saved')),
                );
              },
              child: const Text('Save'),
            ),
            const SizedBox(height: 12),

            // Test Connection button
            ElevatedButton(
              onPressed: _isTesting ? null : _testConnection,
              child: _isTesting
                  ? const SizedBox(
                      height: 20,
                      width: 20,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Text('Test Connection & Continue'),
            ),
            const SizedBox(height: 16),

            // Inline result — shown below button, not in a dialog
            // User can still edit IP while seeing the result
            if (_connectionResult != null)
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: _connectionResult!
                      ? Colors.green.shade50
                      : Colors.red.shade50,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(
                    color: _connectionResult!
                        ? Colors.green.shade300
                        : Colors.red.shade300,
                  ),
                ),
                child: Row(
                  children: [
                    Icon(
                      _connectionResult! ? Icons.check_circle : Icons.error,
                      color: _connectionResult!
                          ? Colors.green.shade700
                          : Colors.red.shade700,
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        _connectionResult!
                            ? 'Connected! Opening app list...'
                            : 'Cannot reach Mac — check IP and make sure server is running.',
                        style: TextStyle(
                          color: _connectionResult!
                              ? Colors.green.shade800
                              : Colors.red.shade800,
                        ),
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
}
