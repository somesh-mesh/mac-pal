import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/exceptions.dart';
import '../settings/settings_provider.dart';
import 'apps_provider.dart';

class AppTile extends ConsumerStatefulWidget {
  final String name;
  final String path;
  const AppTile({super.key, required this.name, required this.path});

  @override
  ConsumerState<AppTile> createState() => _AppTileState();
}

class _AppTileState extends ConsumerState<AppTile> {
  bool _isOpening = false;
  bool _isPressed = false;

  Future<void> _open() async {
    if (_isOpening) return;
    await HapticFeedback.mediumImpact();
    setState(() => _isOpening = true);
    try {
      await ref.read(appsProvider.notifier).openApp(widget.name);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                const Icon(Icons.check_circle_outline_rounded,
                    color: Colors.white, size: 18),
                const SizedBox(width: 8),
                Text('Opening ${widget.name}…'),
              ],
            ),
            backgroundColor: const Color(0xFF30D158),
            margin: const EdgeInsets.all(16),
            duration: const Duration(seconds: 2),
          ),
        );
      }
    } on AppOpenException {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Could not open ${widget.name}'),
            backgroundColor: const Color(0xFFFF453A),
            margin: const EdgeInsets.all(16),
          ),
        );
      }
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Could not reach Mac'),
            backgroundColor: Color(0xFFFF453A),
            margin: EdgeInsets.all(16),
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isOpening = false);
    }
  }

  Widget _buildIcon(double size) {
    final baseUrl = ref.watch(settingsProvider).valueOrNull?.baseUrl;
    final radius = BorderRadius.circular(size * 0.225);

    final placeholder = Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: const Color(0xFF3A3A3C),
        borderRadius: radius,
      ),
      child: Icon(Icons.apps_rounded, color: Colors.white24, size: size * 0.46),
    );

    if (baseUrl == null) return placeholder;

    final url = '$baseUrl/icon?path=${Uri.encodeComponent(widget.path)}';
    return ClipRRect(
      borderRadius: radius,
      child: Image.network(
        url,
        width: size,
        height: size,
        fit: BoxFit.cover,
        errorBuilder: (_, e, s) => placeholder,
        loadingBuilder: (_, child, progress) => progress == null
            ? child
            : Container(
                width: size,
                height: size,
                decoration: BoxDecoration(
                  color: const Color(0xFF3A3A3C),
                  borderRadius: radius,
                ),
              ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    const iconSize = 62.0;

    return GestureDetector(
      onTapDown: (_) => setState(() => _isPressed = true),
      onTapUp: (_) {
        setState(() => _isPressed = false);
        _open();
      },
      onTapCancel: () => setState(() => _isPressed = false),
      child: AnimatedScale(
        scale: _isPressed ? 0.86 : 1.0,
        duration: const Duration(milliseconds: 110),
        curve: Curves.easeOut,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Stack(
              alignment: Alignment.center,
              children: [
                Container(
                  width: iconSize,
                  height: iconSize,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(iconSize * 0.225),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.35),
                        blurRadius: 10,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                ),
                _buildIcon(iconSize),
                if (_isOpening)
                  Container(
                    width: iconSize,
                    height: iconSize,
                    decoration: BoxDecoration(
                      color: Colors.black.withValues(alpha: 0.5),
                      borderRadius: BorderRadius.circular(iconSize * 0.225),
                    ),
                    child: const Center(
                      child: SizedBox(
                        width: 22,
                        height: 22,
                        child: CircularProgressIndicator(
                          strokeWidth: 2.5,
                          color: Colors.white,
                        ),
                      ),
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 7),
            Text(
              widget.name,
              style: const TextStyle(
                fontSize: 11,
                color: Colors.white,
                fontWeight: FontWeight.w400,
                height: 1.25,
              ),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}
