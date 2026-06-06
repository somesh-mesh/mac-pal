import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../apps/apps_repository.dart';
import '../apps/apps_screen.dart';
import 'settings_provider.dart';
import 'otp_discovery_service.dart';

class SettingsScreen extends ConsumerStatefulWidget {
  const SettingsScreen({super.key});

  @override
  ConsumerState<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends ConsumerState<SettingsScreen> {
  final _ipController = TextEditingController();
  final _portController = TextEditingController(text: '3000');

  bool? _connectionResult;
  bool _isTesting = false;

  @override
  void initState() {
    super.initState();
    final settings = ref.read(settingsProvider).valueOrNull;
    if (settings != null) {
      _ipController.text = settings.ip;
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
    await _save();
    setState(() {
      _isTesting = true;
      _connectionResult = null;
    });
    final result = await ref.read(appsRepositoryProvider).ping();
    setState(() {
      _isTesting = false;
      _connectionResult = result;
    });
    if (!result || !mounted) return;
    Navigator.of(context).pushReplacement(
      MaterialPageRoute(builder: (_) => const AppsScreen()),
    );
  }

  Future<void> _save() async {
    final ip = _ipController.text.trim();
    final port = int.tryParse(_portController.text.trim()) ?? 3000;
    await ref.read(settingsProvider.notifier).save(ip, port);
  }

  void _showOtpSheet() {
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: const Color(0xFF1C1C1E),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (_) => _OtpConnectSheet(
        onConnected: (ip, port) async {
          await ref.read(settingsProvider.notifier).save(ip, port);
          if (!mounted) return;
          Navigator.of(context).pushReplacement(
            MaterialPageRoute(builder: (_) => const AppsScreen()),
          );
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF1C1C1E),
      appBar: AppBar(
        backgroundColor: const Color(0xFF1C1C1E),
        surfaceTintColor: Colors.transparent,
        title: const Text(
          'Mac Launcher — Setup',
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.w700),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // ── OTP option (primary, prominent) ────────────────────────
            _ConnectOptionCard(
              icon: Icons.qr_code_rounded,
              title: 'Connect via OTP',
              subtitle:
                  'Auto-discovers your Mac on Wi-Fi.\nOpen Mac Launcher on your Mac, tap Generate OTP, then enter it here.',
              color: const Color(0xFF5E5CE6),
              onTap: _showOtpSheet,
            ),
            const SizedBox(height: 12),

            // ── Divider ─────────────────────────────────────────────────
            Row(
              children: [
                const Expanded(child: Divider(color: Colors.white12)),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 12),
                  child: Text(
                    'or manually',
                    style: TextStyle(
                        color: Colors.white.withValues(alpha: 0.3),
                        fontSize: 12),
                  ),
                ),
                const Expanded(child: Divider(color: Colors.white12)),
              ],
            ),
            const SizedBox(height: 12),

            // ── Manual IP option ────────────────────────────────────────
            const Text(
              'Enter your Mac\'s local IP address.\n'
              'Run this on your Mac to find it:\n'
              'ipconfig getifaddr en0',
              style: TextStyle(color: Colors.white38, fontSize: 13, height: 1.5),
            ),
            const SizedBox(height: 16),

            TextField(
              controller: _ipController,
              style: const TextStyle(color: Colors.white),
              keyboardType:
                  const TextInputType.numberWithOptions(decimal: true),
              decoration: InputDecoration(
                labelText: 'Mac IP Address',
                labelStyle: const TextStyle(color: Colors.white38),
                hintText: '192.168.1.4',
                hintStyle: const TextStyle(color: Colors.white24),
                border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12)),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: const BorderSide(color: Colors.white24),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: const BorderSide(
                      color: Color(0xFF0A84FF), width: 1.5),
                ),
                prefixIcon:
                    const Icon(Icons.computer, color: Colors.white38),
                filled: true,
                fillColor: const Color(0xFF2C2C2E),
              ),
            ),
            const SizedBox(height: 12),

            TextField(
              controller: _portController,
              style: const TextStyle(color: Colors.white),
              keyboardType: TextInputType.number,
              decoration: InputDecoration(
                labelText: 'Port',
                labelStyle: const TextStyle(color: Colors.white38),
                hintText: '3000',
                hintStyle: const TextStyle(color: Colors.white24),
                border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12)),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: const BorderSide(color: Colors.white24),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: const BorderSide(
                      color: Color(0xFF0A84FF), width: 1.5),
                ),
                prefixIcon: const Icon(Icons.settings_ethernet,
                    color: Colors.white38),
                filled: true,
                fillColor: const Color(0xFF2C2C2E),
              ),
            ),
            const SizedBox(height: 16),

            OutlinedButton(
              onPressed: () async {
                await _save();
                if (!mounted) return;
                // ignore: use_build_context_synchronously
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Settings saved'),
                    backgroundColor: Color(0xFF2C2C2E),
                  ),
                );
              },
              style: OutlinedButton.styleFrom(
                foregroundColor: Colors.white54,
                side: const BorderSide(color: Colors.white24),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12)),
              ),
              child: const Text('Save'),
            ),
            const SizedBox(height: 10),

            ElevatedButton(
              onPressed: _isTesting ? null : _testConnection,
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF0A84FF),
                foregroundColor: Colors.white,
                elevation: 0,
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12)),
              ),
              child: _isTesting
                  ? const SizedBox(
                      height: 20,
                      width: 20,
                      child: CircularProgressIndicator(
                          strokeWidth: 2, color: Colors.white),
                    )
                  : const Text('Test Connection & Continue',
                      style: TextStyle(fontWeight: FontWeight.w600)),
            ),

            if (_connectionResult != null) ...[
              const SizedBox(height: 14),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: _connectionResult!
                      ? const Color(0xFF30D158).withValues(alpha: 0.1)
                      : const Color(0xFFFF453A).withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(
                    color: _connectionResult!
                        ? const Color(0xFF30D158).withValues(alpha: 0.3)
                        : const Color(0xFFFF453A).withValues(alpha: 0.3),
                  ),
                ),
                child: Row(
                  children: [
                    Icon(
                      _connectionResult!
                          ? Icons.check_circle
                          : Icons.error_outline,
                      color: _connectionResult!
                          ? const Color(0xFF30D158)
                          : const Color(0xFFFF453A),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        _connectionResult!
                            ? 'Connected! Opening app list...'
                            : 'Cannot reach Mac — check IP and make sure Mac Launcher desktop is running.',
                        style: TextStyle(
                          color: _connectionResult!
                              ? const Color(0xFF30D158)
                              : const Color(0xFFFF453A),
                          fontSize: 13,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

// ── Connect option card ───────────────────────────────────────────────────

class _ConnectOptionCard extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final Color color;
  final VoidCallback onTap;

  const _ConnectOptionCard({
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
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.08),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: color.withValues(alpha: 0.3)),
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(icon, color: color, size: 22),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: TextStyle(
                      color: color,
                      fontSize: 15,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 3),
                  Text(
                    subtitle,
                    style: const TextStyle(
                        color: Colors.white38, fontSize: 12, height: 1.4),
                  ),
                ],
              ),
            ),
            Icon(Icons.chevron_right_rounded,
                color: color.withValues(alpha: 0.6)),
          ],
        ),
      ),
    );
  }
}

// ── OTP Connect Bottom Sheet ───────────────────────────────────────────────

class _OtpConnectSheet extends StatefulWidget {
  final Future<void> Function(String ip, int port) onConnected;
  const _OtpConnectSheet({required this.onConnected});

  @override
  State<_OtpConnectSheet> createState() => _OtpConnectSheetState();
}

class _OtpConnectSheetState extends State<_OtpConnectSheet> {
  final _otpController = TextEditingController();

  _Phase _phase = _Phase.scanning;
  List<DiscoveredMac> _macs = [];
  DiscoveredMac? _selected;
  bool _validating = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    _startDiscovery();
  }

  @override
  void dispose() {
    _otpController.dispose();
    super.dispose();
  }

  Future<void> _startDiscovery() async {
    setState(() {
      _phase = _Phase.scanning;
      _error = null;
    });
    final found = await discoverMacs();
    if (!mounted) return;
    if (found.isEmpty) {
      setState(() {
        _phase = _Phase.notFound;
      });
    } else {
      setState(() {
        _macs = found;
        _selected = found.first;
        _phase = _Phase.enterOtp;
      });
    }
  }

  Future<void> _connect() async {
    final mac = _selected;
    if (mac == null) return;
    final otp = _otpController.text.trim();
    if (otp.length != 6) {
      setState(() => _error = 'Enter the 6-digit code shown on your Mac');
      return;
    }

    setState(() {
      _validating = true;
      _error = null;
    });

    final baseUrl = 'http://${mac.ip}:${mac.port}';
    final valid = await validateOtp(baseUrl, otp);

    if (!mounted) return;
    if (valid) {
      Navigator.of(context).pop();
      await widget.onConnected(mac.ip, mac.port);
    } else {
      setState(() {
        _validating = false;
        _error = 'Incorrect code — check the code shown on your Mac';
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).viewInsets.bottom,
      ),
      child: SafeArea(
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
                'Connect via OTP',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 20,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: 20),
              _buildBody(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildBody() {
    switch (_phase) {
      case _Phase.scanning:
        return _ScanningView(onRetry: _startDiscovery);
      case _Phase.notFound:
        return _NotFoundView(onRetry: _startDiscovery);
      case _Phase.enterOtp:
        return _OtpEntryView(
          macs: _macs,
          selected: _selected!,
          otpController: _otpController,
          validating: _validating,
          error: _error,
          onMacSelected: (m) => setState(() => _selected = m),
          onConnect: _connect,
        );
    }
  }
}

enum _Phase { scanning, notFound, enterOtp }

class _ScanningView extends StatelessWidget {
  final VoidCallback onRetry;
  const _ScanningView({required this.onRetry});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        const SizedBox(height: 20),
        const CircularProgressIndicator(color: Color(0xFF5E5CE6)),
        const SizedBox(height: 16),
        const Text(
          'Scanning for Mac Launcher…',
          style: TextStyle(color: Colors.white54, fontSize: 15),
        ),
        const SizedBox(height: 6),
        const Text(
          'Make sure Mac Launcher is running on your Mac and both devices are on the same Wi-Fi.',
          textAlign: TextAlign.center,
          style: TextStyle(color: Colors.white24, fontSize: 12, height: 1.5),
        ),
        const SizedBox(height: 24),
      ],
    );
  }
}

class _NotFoundView extends StatelessWidget {
  final VoidCallback onRetry;
  const _NotFoundView({required this.onRetry});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        const SizedBox(height: 10),
        Container(
          padding: const EdgeInsets.all(18),
          decoration: BoxDecoration(
            color: const Color(0xFFFF9F0A).withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(14),
            border: Border.all(
                color: const Color(0xFFFF9F0A).withValues(alpha: 0.3)),
          ),
          child: Column(
            children: [
              const Icon(Icons.search_off_rounded,
                  color: Color(0xFFFF9F0A), size: 36),
              const SizedBox(height: 12),
              const Text(
                'Mac not found',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 6),
              const Text(
                'Make sure:\n• Mac Launcher desktop app is open on your Mac\n• Server is started (green status)\n• Both devices are on the same Wi-Fi network',
                textAlign: TextAlign.center,
                style: TextStyle(
                    color: Colors.white38, fontSize: 13, height: 1.5),
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),
        SizedBox(
          width: double.infinity,
          child: ElevatedButton.icon(
            onPressed: onRetry,
            icon: const Icon(Icons.refresh_rounded),
            label: const Text('Scan Again'),
            style: ElevatedButton.styleFrom(
              backgroundColor:
                  const Color(0xFF5E5CE6).withValues(alpha: 0.15),
              foregroundColor: const Color(0xFF5E5CE6),
              elevation: 0,
              padding: const EdgeInsets.symmetric(vertical: 14),
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12)),
            ),
          ),
        ),
        const SizedBox(height: 10),
      ],
    );
  }
}

class _OtpEntryView extends StatelessWidget {
  final List<DiscoveredMac> macs;
  final DiscoveredMac selected;
  final TextEditingController otpController;
  final bool validating;
  final String? error;
  final ValueChanged<DiscoveredMac> onMacSelected;
  final VoidCallback onConnect;

  const _OtpEntryView({
    required this.macs,
    required this.selected,
    required this.otpController,
    required this.validating,
    required this.error,
    required this.onMacSelected,
    required this.onConnect,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Found Mac indicator
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
          decoration: BoxDecoration(
            color: const Color(0xFF30D158).withValues(alpha: 0.08),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
                color: const Color(0xFF30D158).withValues(alpha: 0.25)),
          ),
          child: Row(
            children: [
              const Icon(Icons.laptop_mac_rounded,
                  color: Color(0xFF30D158), size: 18),
              const SizedBox(width: 10),
              Expanded(
                child: macs.length == 1
                    ? Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            selected.hostname,
                            style: const TextStyle(
                              color: Color(0xFF30D158),
                              fontWeight: FontWeight.w600,
                              fontSize: 14,
                            ),
                          ),
                          Text(
                            '${selected.ip}:${selected.port}',
                            style: const TextStyle(
                                color: Colors.white38, fontSize: 11),
                          ),
                        ],
                      )
                    : DropdownButton<DiscoveredMac>(
                        value: selected,
                        isExpanded: true,
                        dropdownColor: const Color(0xFF2C2C2E),
                        style: const TextStyle(
                            color: Color(0xFF30D158), fontSize: 14),
                        underline: const SizedBox(),
                        items: macs
                            .map((m) => DropdownMenuItem(
                                  value: m,
                                  child: Text('${m.hostname} (${m.ip})'),
                                ))
                            .toList(),
                        onChanged: (m) {
                          if (m != null) onMacSelected(m);
                        },
                      ),
              ),
              Container(
                width: 8,
                height: 8,
                decoration: const BoxDecoration(
                  shape: BoxShape.circle,
                  color: Color(0xFF30D158),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 20),

        const Text(
          'Enter the 6-digit OTP shown on your Mac',
          style: TextStyle(
              color: Colors.white, fontSize: 15, fontWeight: FontWeight.w600),
        ),
        const SizedBox(height: 6),
        const Text(
          'In Mac Launcher desktop app, tap "Generate OTP" and enter the code below.',
          style: TextStyle(color: Colors.white38, fontSize: 12, height: 1.5),
        ),
        const SizedBox(height: 14),

        TextField(
          controller: otpController,
          autofocus: true,
          keyboardType: TextInputType.number,
          maxLength: 6,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 32,
            fontWeight: FontWeight.w700,
            letterSpacing: 8,
          ),
          textAlign: TextAlign.center,
          decoration: InputDecoration(
            counterText: '',
            hintText: '000000',
            hintStyle: TextStyle(
              color: Colors.white.withValues(alpha: 0.15),
              fontSize: 32,
              fontWeight: FontWeight.w700,
              letterSpacing: 8,
            ),
            filled: true,
            fillColor: const Color(0xFF2C2C2E),
            border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(14)),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(14),
              borderSide: const BorderSide(color: Colors.white12),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(14),
              borderSide: const BorderSide(
                  color: Color(0xFF5E5CE6), width: 1.5),
            ),
            errorBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(14),
              borderSide: const BorderSide(color: Color(0xFFFF453A)),
            ),
            errorText: error,
            errorStyle: const TextStyle(color: Color(0xFFFF453A)),
          ),
          onSubmitted: (_) => onConnect(),
        ),
        const SizedBox(height: 16),

        SizedBox(
          width: double.infinity,
          height: 52,
          child: ElevatedButton(
            onPressed: validating ? null : onConnect,
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF5E5CE6),
              foregroundColor: Colors.white,
              elevation: 0,
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14)),
            ),
            child: validating
                ? const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(
                        strokeWidth: 2, color: Colors.white),
                  )
                : const Text(
                    'Connect',
                    style: TextStyle(
                        fontSize: 16, fontWeight: FontWeight.w700),
                  ),
          ),
        ),
        const SizedBox(height: 8),
      ],
    );
  }
}
