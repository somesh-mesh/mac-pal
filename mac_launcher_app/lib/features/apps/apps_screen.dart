import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../settings/settings_screen.dart';
import 'app_tile.dart';
import 'apps_provider.dart';

class AppsScreen extends ConsumerStatefulWidget {
  const AppsScreen({super.key});

  @override
  ConsumerState<AppsScreen> createState() => _AppsScreenState();
}

class _AppsScreenState extends ConsumerState<AppsScreen> {
  // Search query — filters the list locally, no server call needed
  String _query = '';

  @override
  Widget build(BuildContext context) {
    final appsAsync  = ref.watch(appsProvider);
    final macOnline  = ref.watch(macStatusProvider);

    return Scaffold(
      appBar: AppBar(
        title: Row(
          children: [
            const Text('Mac Launcher'),
            const SizedBox(width: 8),
            // Green/red dot showing Mac server status
            macOnline.when(
              data:    (online) => Icon(Icons.circle, size: 10,
                  color: online ? Colors.green : Colors.red),
              loading: () => const SizedBox(width: 10, height: 10,
                  child: CircularProgressIndicator(strokeWidth: 2)),
              error:   (e, _) => const Icon(Icons.circle, size: 10, color: Colors.red),
            ),
          ],
        ),
        actions: [
          // Settings gear icon — navigate back to settings
          IconButton(
            icon: const Icon(Icons.settings),
            onPressed: () => Navigator.of(context).pushReplacement(
              MaterialPageRoute(builder: (_) => const SettingsScreen()),
            ),
          ),
        ],
      ),

      body: Column(
        children: [
          // Search bar — filters list locally
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 4),
            child: TextField(
              decoration: const InputDecoration(
                hintText: 'Search apps...',
                prefixIcon: Icon(Icons.search),
                border: OutlineInputBorder(),
                contentPadding: EdgeInsets.symmetric(vertical: 10),
              ),
              onChanged: (v) => setState(() => _query = v.toLowerCase()),
            ),
          ),

          // App list — loading / error / empty / data states
          Expanded(
            child: appsAsync.when(
              // Loading state — centered spinner
              loading: () => const Center(child: CircularProgressIndicator()),

              // Error state — message + retry button
              error: (err, _) => Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.wifi_off, size: 64, color: Colors.grey),
                    const SizedBox(height: 16),
                    const Text('Cannot reach Mac',
                        style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                    const SizedBox(height: 8),
                    const Text('Check IP in settings and make sure\n'
                        'the server is running on your Mac.',
                        textAlign: TextAlign.center,
                        style: TextStyle(color: Colors.grey)),
                    const SizedBox(height: 24),
                    ElevatedButton.icon(
                      icon: const Icon(Icons.refresh),
                      label: const Text('Retry'),
                      onPressed: () => ref.read(appsProvider.notifier).refresh(),
                    ),
                  ],
                ),
              ),

              // Data state — filtered list with pull-to-refresh
              data: (apps) {
                // Filter by search query
                final filtered = _query.isEmpty
                    ? apps
                    : apps.where((a) => a.name.toLowerCase().contains(_query)).toList();

                // Empty state — unlikely but handled
                if (filtered.isEmpty) {
                  return const Center(child: Text('No apps found'));
                }

                return RefreshIndicator(
                  onRefresh: () => ref.read(appsProvider.notifier).refresh(),
                  child: ListView.separated(
                    itemCount: filtered.length,
                    separatorBuilder: (context, index) => const Divider(height: 1),
                    itemBuilder: (_, i) => AppTile(name: filtered[i].name),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
