import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/exceptions.dart';
import 'apps_provider.dart';

class AppTile extends ConsumerStatefulWidget {
  final String name;
  const AppTile({super.key, required this.name});

  @override
  ConsumerState<AppTile> createState() => _AppTileState();
}

class _AppTileState extends ConsumerState<AppTile> {
  bool _isOpening = false;

  Future<void> _open() async {
    if (_isOpening) return; // prevent double-tap

    // Haptic feedback before async call — feels responsive
    await HapticFeedback.mediumImpact();

    setState(() => _isOpening = true);

    try {
      await ref.read(appsProvider.notifier).openApp(widget.name);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Opening ${widget.name}...'),
            duration: const Duration(seconds: 2),
          ),
        );
      }
    } on AppOpenException {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Could not open ${widget.name}'),
            backgroundColor: Colors.red.shade700,
          ),
        );
      }
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Could not reach Mac'),
            backgroundColor: Colors.red.shade700,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isOpening = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return ListTile(
      leading: const Icon(Icons.apps, size: 32),
      title: Text(widget.name),
      trailing: _isOpening
          ? const SizedBox(
              width: 20,
              height: 20,
              child: CircularProgressIndicator(strokeWidth: 2),
            )
          : const Icon(Icons.chevron_right),
      onTap: _isOpening ? null : _open,
    );
  }
}
