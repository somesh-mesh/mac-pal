import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../core/exceptions.dart';
import '../settings/settings_provider.dart';
import '../settings/settings_screen.dart';
import 'app_tile.dart';
import 'apps_provider.dart';
import 'apps_repository.dart';

class AppsScreen extends ConsumerStatefulWidget {
  const AppsScreen({super.key});

  @override
  ConsumerState<AppsScreen> createState() => _AppsScreenState();
}

class _AppsScreenState extends ConsumerState<AppsScreen> {
  String _query = '';
  final _searchController = TextEditingController();

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final appsAsync = ref.watch(appsProvider);
    final macOnline = ref.watch(macStatusProvider);

    return Scaffold(
      backgroundColor: const Color(0xFF1C1C1E),
      body: RefreshIndicator(
        color: const Color(0xFF0A84FF),
        backgroundColor: const Color(0xFF2C2C2E),
        onRefresh: () => ref.read(appsProvider.notifier).refresh(),
        child: CustomScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          slivers: [
            _buildAppBar(context, macOnline),
            _buildSearchBar(),
            const SliverToBoxAdapter(child: _MacControlBar()),
            appsAsync.when(
              loading: () => const SliverFillRemaining(
                child: Center(
                  child: CircularProgressIndicator(color: Color(0xFF0A84FF)),
                ),
              ),
              error: (e, _) => SliverFillRemaining(child: _buildError()),
              data: (apps) {
                final filtered = _query.isEmpty
                    ? apps
                    : apps
                        .where((a) => a.name.toLowerCase().contains(_query))
                        .toList();

                if (filtered.isEmpty) {
                  return SliverFillRemaining(
                    child: Center(
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(Icons.search_off_rounded,
                              size: 48, color: Colors.white24),
                          const SizedBox(height: 12),
                          Text(
                            'No results for "$_query"',
                            style: const TextStyle(
                                color: Colors.white38, fontSize: 16),
                          ),
                        ],
                      ),
                    ),
                  );
                }

                return SliverPadding(
                  padding: const EdgeInsets.fromLTRB(20, 4, 20, 40),
                  sliver: SliverGrid(
                    delegate: SliverChildBuilderDelegate(
                      (_, i) => AppTile(
                        name: filtered[i].name,
                        path: filtered[i].path,
                      ),
                      childCount: filtered.length,
                    ),
                    gridDelegate:
                        const SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: 4,
                      mainAxisSpacing: 22,
                      crossAxisSpacing: 10,
                      childAspectRatio: 0.76,
                    ),
                  ),
                );
              },
            ),
          ],
        ),
      ),
    );
  }

  SliverAppBar _buildAppBar(
      BuildContext context, AsyncValue<bool> macOnline) {
    return SliverAppBar(
      backgroundColor: const Color(0xFF1C1C1E),
      surfaceTintColor: Colors.transparent,
      pinned: true,
      titleSpacing: 20,
      title: Row(
        children: [
          Container(
            width: 32,
            height: 32,
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [Color(0xFF0A84FF), Color(0xFF0040DD)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(9),
              boxShadow: [
                BoxShadow(
                  color: const Color(0xFF0A84FF).withValues(alpha: 0.4),
                  blurRadius: 8,
                  offset: const Offset(0, 3),
                ),
              ],
            ),
            child: const Icon(Icons.laptop_mac_rounded,
                color: Colors.white, size: 18),
          ),
          const SizedBox(width: 10),
          const Text(
            'Mac Launcher',
            style: TextStyle(
              fontWeight: FontWeight.w700,
              fontSize: 20,
              color: Colors.white,
              letterSpacing: -0.3,
            ),
          ),
        ],
      ),
      actions: [
        macOnline.when(
          data: (online) => Padding(
            padding: const EdgeInsets.only(top: 2),
            child: Row(
              children: [
                _GlowDot(online: online),
                const SizedBox(width: 4),
                Text(
                  online ? 'Online' : 'Offline',
                  style: TextStyle(
                    fontSize: 12,
                    color: online
                        ? const Color(0xFF30D158)
                        : const Color(0xFFFF453A),
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
          loading: () => const SizedBox(
            width: 16,
            height: 16,
            child: CircularProgressIndicator(strokeWidth: 2),
          ),
          error: (e, s) => const _GlowDot(online: false),
        ),
        const SizedBox(width: 4),
        IconButton(
          icon: const Icon(Icons.settings_outlined,
              color: Colors.white54, size: 22),
          onPressed: () => Navigator.of(context).pushReplacement(
            MaterialPageRoute(builder: (_) => const SettingsScreen()),
          ),
        ),
      ],
    );
  }

  SliverToBoxAdapter _buildSearchBar() {
    return SliverToBoxAdapter(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 6, 16, 8),
        child: TextField(
          controller: _searchController,
          style: const TextStyle(color: Colors.white, fontSize: 16),
          decoration: InputDecoration(
            hintText: 'Search apps…',
            hintStyle: const TextStyle(color: Colors.white38, fontSize: 16),
            prefixIcon: const Icon(Icons.search_rounded,
                color: Colors.white38, size: 20),
            suffixIcon: _query.isNotEmpty
                ? IconButton(
                    icon: const Icon(Icons.cancel_rounded,
                        color: Colors.white38, size: 18),
                    onPressed: () {
                      _searchController.clear();
                      setState(() => _query = '');
                    },
                  )
                : null,
            filled: true,
            fillColor: const Color(0xFF2C2C2E),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(14),
              borderSide: BorderSide.none,
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(14),
              borderSide: BorderSide.none,
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(14),
              borderSide:
                  const BorderSide(color: Color(0xFF0A84FF), width: 1.5),
            ),
            contentPadding:
                const EdgeInsets.symmetric(vertical: 13, horizontal: 16),
          ),
          onChanged: (v) => setState(() => _query = v.toLowerCase()),
        ),
      ),
    );
  }

  Widget _buildError() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 88,
              height: 88,
              decoration: BoxDecoration(
                color: const Color(0xFF2C2C2E),
                borderRadius: BorderRadius.circular(24),
              ),
              child: const Icon(Icons.wifi_off_rounded,
                  size: 44, color: Colors.white24),
            ),
            const SizedBox(height: 24),
            const Text(
              'Cannot reach Mac',
              style: TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.w700,
                color: Colors.white,
                letterSpacing: -0.3,
              ),
            ),
            const SizedBox(height: 10),
            const Text(
              'Check IP in settings and make sure\nthe server is running on your Mac.',
              textAlign: TextAlign.center,
              style: TextStyle(color: Colors.white38, fontSize: 15, height: 1.5),
            ),
            const SizedBox(height: 32),
            SizedBox(
              height: 50,
              child: ElevatedButton.icon(
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF0A84FF),
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(horizontal: 28),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14)),
                  elevation: 0,
                ),
                icon: const Icon(Icons.refresh_rounded, size: 20),
                label: const Text('Retry',
                    style:
                        TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
                onPressed: () => ref.read(appsProvider.notifier).refresh(),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ── Mac Control Bar ────────────────────────────────────────────────────────
class _MacControlBar extends ConsumerStatefulWidget {
  const _MacControlBar();

  @override
  ConsumerState<_MacControlBar> createState() => _MacControlBarState();
}

class _MacControlBarState extends ConsumerState<_MacControlBar> {
  bool? _isLocked;
  bool _locking   = false;
  bool _unlocking = false;

  @override
  void initState() {
    super.initState();
    _fetchStatus();
  }

  Future<void> _fetchStatus() async {
    final locked = await ref.read(appsRepositoryProvider).getLockStatus();
    if (mounted) setState(() => _isLocked = locked);
  }

  Future<void> _lock() async {
    HapticFeedback.mediumImpact();
    setState(() => _locking = true);
    try {
      await ref.read(appsRepositoryProvider).lockMac();
      if (mounted) setState(() => _isLocked = true);
    } catch (_) {
      if (mounted) _showError('Could not lock Mac');
    } finally {
      if (mounted) setState(() => _locking = false);
    }
  }

  Future<void> _unlock() async {
    HapticFeedback.mediumImpact();
    setState(() => _unlocking = true);
    try {
      await ref.read(appsRepositoryProvider).unlockMac();
      if (mounted) setState(() => _isLocked = false);
    } on UnlockNotConfiguredException catch (e) {
      if (mounted) _showSetupDialog(e.setupCommand);
    } catch (_) {
      if (mounted) _showError('Could not unlock Mac');
    } finally {
      if (mounted) setState(() => _unlocking = false);
    }
  }

  void _showRemoteDesktopSheet() {
    final macIp = ref.read(settingsProvider).valueOrNull?.ip ?? '';
    showModalBottomSheet<void>(
      context: context,
      backgroundColor: const Color(0xFF2C2C2E),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      isScrollControlled: true,
      builder: (_) => _RemoteDesktopSheet(macIp: macIp),
    );
  }

  void _showError(String msg) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Text(msg),
      backgroundColor: const Color(0xFFFF453A),
      margin: const EdgeInsets.all(16),
      behavior: SnackBarBehavior.floating,
    ));
  }

  void _showSetupDialog(String command) {
    showDialog<void>(
      context: context,
      builder: (_) => AlertDialog(
        backgroundColor: const Color(0xFF2C2C2E),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
        title: const Text('One-time setup needed',
            style: TextStyle(color: Colors.white, fontSize: 17)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Run this once in Terminal on your Mac to store your login password:',
              style: TextStyle(color: Colors.white60, fontSize: 14, height: 1.5),
            ),
            const SizedBox(height: 14),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: const Color(0xFF1C1C1E),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Text(
                command.isNotEmpty
                    ? command
                    : "echo 'mac_password=YOUR_PASSWORD' > ~/.mac-launcher.conf\nchmod 600 ~/.mac-launcher.conf",
                style: const TextStyle(
                  color: Color(0xFF0A84FF),
                  fontSize: 12,
                  fontFamily: 'monospace',
                  height: 1.6,
                ),
              ),
            ),
            const SizedBox(height: 12),
            const Text(
              'The password stays on your Mac — it is never sent over the network.',
              style: TextStyle(color: Colors.white38, fontSize: 12, height: 1.5),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Got it',
                style: TextStyle(color: Color(0xFF0A84FF))),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
      child: Container(
        decoration: BoxDecoration(
          color: const Color(0xFF2C2C2E),
          borderRadius: BorderRadius.circular(16),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // ── Status header ──
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
              child: Row(
                children: [
                  Icon(
                    _isLocked == null
                        ? Icons.lock_clock_rounded
                        : _isLocked!
                            ? Icons.lock_rounded
                            : Icons.lock_open_rounded,
                    size: 15,
                    color: _isLocked == null
                        ? Colors.white38
                        : _isLocked!
                            ? const Color(0xFFFF9F0A)
                            : const Color(0xFF30D158),
                  ),
                  const SizedBox(width: 6),
                  Text(
                    _isLocked == null
                        ? 'Checking…'
                        : _isLocked!
                            ? 'Screen is locked'
                            : 'Screen is unlocked',
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w500,
                      color: _isLocked == null
                          ? Colors.white38
                          : _isLocked!
                              ? const Color(0xFFFF9F0A)
                              : const Color(0xFF30D158),
                    ),
                  ),
                  const Spacer(),
                  GestureDetector(
                    onTap: _fetchStatus,
                    child: const Icon(Icons.refresh_rounded,
                        size: 16, color: Colors.white38),
                  ),
                ],
              ),
            ),
            const Divider(height: 1, color: Colors.white10),
            // ── Lock / Unlock buttons ──
            Padding(
              padding: const EdgeInsets.fromLTRB(10, 10, 10, 8),
              child: Row(
                children: [
                  Expanded(
                    child: _ActionButton(
                      icon: Icons.lock_rounded,
                      label: 'Lock',
                      color: const Color(0xFFFF9F0A),
                      isLoading: _locking,
                      onTap: (_locking || _unlocking) ? null : _lock,
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: _ActionButton(
                      icon: Icons.lock_open_rounded,
                      label: 'Unlock',
                      color: const Color(0xFF30D158),
                      isLoading: _unlocking,
                      onTap: (_locking || _unlocking) ? null : _unlock,
                    ),
                  ),
                ],
              ),
            ),
            const Divider(height: 1, color: Colors.white10),
            // ── Remote Desktop button ──
            Padding(
              padding: const EdgeInsets.fromLTRB(10, 8, 10, 10),
              child: _ActionButton(
                icon: Icons.cast_rounded,
                label: 'Remote Desktop',
                color: const Color(0xFF5E5CE6),
                isLoading: false,
                onTap: _showRemoteDesktopSheet,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ── Single action button ───────────────────────────────────────────────────
class _ActionButton extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;
  final bool isLoading;
  final VoidCallback? onTap;

  const _ActionButton({
    required this.icon,
    required this.label,
    required this.color,
    required this.isLoading,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final active = onTap != null;
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        padding: const EdgeInsets.symmetric(vertical: 12),
        decoration: BoxDecoration(
          color: active
              ? color.withValues(alpha: 0.13)
              : Colors.white.withValues(alpha: 0.04),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: active
                ? color.withValues(alpha: 0.3)
                : Colors.white.withValues(alpha: 0.08),
          ),
        ),
        child: isLoading
            ? Center(
                child: SizedBox(
                  width: 18,
                  height: 18,
                  child: CircularProgressIndicator(
                      strokeWidth: 2, color: color),
                ),
              )
            : Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(icon,
                      size: 16,
                      color: active ? color : Colors.white24),
                  const SizedBox(width: 6),
                  Text(
                    label,
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: active ? color : Colors.white24,
                    ),
                  ),
                ],
              ),
      ),
    );
  }
}

// ── Remote desktop bottom sheet ───────────────────────────────────────────
class _RemoteDesktopSheet extends StatelessWidget {
  final String macIp;
  const _RemoteDesktopSheet({required this.macIp});

  Future<void> _open(BuildContext ctx, String url, String fallback) async {
    final uri = Uri.parse(url);
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    } else if (fallback.isNotEmpty) {
      await launchUrl(Uri.parse(fallback), mode: LaunchMode.externalApplication);
    } else if (ctx.mounted) {
      ScaffoldMessenger.of(ctx).showSnackBar(
        const SnackBar(
          content: Text('Could not open — check the app is installed'),
          backgroundColor: Color(0xFFFF453A),
          margin: EdgeInsets.all(16),
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(20, 12, 20, 24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: Colors.white24,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            const SizedBox(height: 20),
            const Text(
              'Remote Desktop',
              style: TextStyle(
                  color: Colors.white,
                  fontSize: 18,
                  fontWeight: FontWeight.w700),
            ),
            const SizedBox(height: 4),
            const Text(
              'View and control your Mac screen from iPhone',
              style: TextStyle(color: Colors.white38, fontSize: 13),
            ),
            const SizedBox(height: 20),
            _RDOption(
              icon: Icons.open_in_browser_rounded,
              title: 'Chrome Remote Desktop',
              subtitle: 'Opens in browser — no extra app needed',
              color: const Color(0xFF0A84FF),
              onTap: () => _open(
                context,
                'https://remotedesktop.google.com/access',
                '',
              ),
            ),
            const SizedBox(height: 10),
            _RDOption(
              icon: Icons.desktop_windows_rounded,
              title: 'Microsoft Remote Desktop',
              subtitle: 'Opens app if installed, else App Store',
              color: const Color(0xFF0078D4),
              onTap: () => _open(
                context,
                'msrdp://',
                'https://apps.apple.com/app/microsoft-remote-desktop/id714464092',
              ),
            ),
            const SizedBox(height: 10),
            _RDOption(
              icon: Icons.flight_rounded,
              title: 'Jump Desktop',
              subtitle: 'Opens app if installed, else App Store',
              color: const Color(0xFFFF9F0A),
              onTap: () => _open(
                context,
                'jump://',
                'https://apps.apple.com/app/jump-desktop-rdp-vnc-fluid/id364876095',
              ),
            ),
            if (macIp.isNotEmpty) ...[
              const SizedBox(height: 10),
              _RDOption(
                icon: Icons.computer_rounded,
                title: 'VNC Viewer',
                subtitle: 'Connects to $macIp (Screen Sharing must be on)',
                color: const Color(0xFF30D158),
                onTap: () => _open(
                  context,
                  'vnc://$macIp',
                  'https://apps.apple.com/app/vnc-viewer-remote-desktop/id352019548',
                ),
              ),
            ],
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.05),
                borderRadius: BorderRadius.circular(10),
              ),
              child: const Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Icon(Icons.info_outline_rounded,
                      color: Colors.white38, size: 15),
                  SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'Enable Screen Sharing on Mac:\nSystem Settings → General → Sharing → Screen Sharing',
                      style: TextStyle(
                          color: Colors.white38, fontSize: 12, height: 1.5),
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

class _RDOption extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final Color color;
  final VoidCallback onTap;

  const _RDOption({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.08),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: color.withValues(alpha: 0.2)),
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(icon, color: color, size: 20),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title,
                      style: const TextStyle(
                          color: Colors.white,
                          fontSize: 15,
                          fontWeight: FontWeight.w600)),
                  const SizedBox(height: 2),
                  Text(subtitle,
                      style: const TextStyle(
                          color: Colors.white38, fontSize: 12)),
                ],
              ),
            ),
            Icon(Icons.chevron_right_rounded,
                color: color.withValues(alpha: 0.6), size: 20),
          ],
        ),
      ),
    );
  }
}

// ── Glow dot ──────────────────────────────────────────────────────────────
class _GlowDot extends StatelessWidget {
  final bool online;
  const _GlowDot({required this.online});

  @override
  Widget build(BuildContext context) {
    final color =
        online ? const Color(0xFF30D158) : const Color(0xFFFF453A);
    return Container(
      width: 8,
      height: 8,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: color,
        boxShadow: [
          BoxShadow(
            color: color.withValues(alpha: 0.6),
            blurRadius: 5,
            spreadRadius: 1,
          ),
        ],
      ),
    );
  }
}
