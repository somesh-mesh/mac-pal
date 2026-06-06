import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../providers/server_provider.dart';
import '../core/constants.dart';

class HomeScreen extends ConsumerWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(serverProvider);

    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [Color(0xFF1E1E26), Color(0xFF141416)],
          ),
        ),
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(20, 24, 20, 20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              _Header(state: state),
              const SizedBox(height: 20),
              _ServerCard(state: state),
              const SizedBox(height: 12),
              if (state.isRunning) ...[
                _OtpCard(state: state),
                const SizedBox(height: 12),
                _IpCard(state: state),
              ],
              if (state.lastConnectedClient != null) ...[
                const SizedBox(height: 12),
                _ConnectedCard(clientIp: state.lastConnectedClient!),
              ],
              if (state.error != null) ...[
                const SizedBox(height: 12),
                _ErrorCard(message: state.error!),
              ],
              const SizedBox(height: 8),
            ],
          ),
        ),
      ),
    );
  }
}

// ── Header ────────────────────────────────────────────────────────────────

class _Header extends StatelessWidget {
  final ServerState state;
  const _Header({required this.state});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
          width: 50,
          height: 50,
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              colors: [Color(0xFF2E8FFF), Color(0xFF0055EE)],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(15),
            boxShadow: [
              BoxShadow(
                color: const Color(0xFF0A84FF).withValues(alpha: 0.55),
                blurRadius: 20,
                offset: const Offset(0, 6),
                spreadRadius: -4,
              ),
            ],
          ),
          child: const Icon(Icons.laptop_mac_rounded,
              color: Colors.white, size: 26),
        ),
        const SizedBox(width: 14),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Mac Launcher',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 20,
                  fontWeight: FontWeight.w700,
                  letterSpacing: -0.5,
                ),
              ),
              const SizedBox(height: 3),
              Row(
                children: [
                  _StatusDot(running: state.isRunning),
                  const SizedBox(width: 6),
                  Text(
                    state.isRunning
                        ? '${state.ipAddress}:$kHttpPort'
                        : 'Server stopped',
                    style: TextStyle(
                      color: state.isRunning
                          ? const Color(0xFF30D158)
                          : Colors.white38,
                      fontSize: 12,
                      letterSpacing: 0.1,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _StatusDot extends StatefulWidget {
  final bool running;
  const _StatusDot({required this.running});

  @override
  State<_StatusDot> createState() => _StatusDotState();
}

class _StatusDotState extends State<_StatusDot>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _anim;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1400),
    );
    _anim = Tween<double>(begin: 0.2, end: 0.75).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeInOut),
    );
    if (widget.running) _controller.repeat(reverse: true);
  }

  @override
  void didUpdateWidget(_StatusDot old) {
    super.didUpdateWidget(old);
    if (widget.running != old.running) {
      if (widget.running) {
        _controller.repeat(reverse: true);
      } else {
        _controller.stop();
        _controller.reset();
      }
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final color = widget.running
        ? const Color(0xFF30D158)
        : const Color(0xFF48484A);

    if (!widget.running) {
      return Container(
        width: 7,
        height: 7,
        decoration: BoxDecoration(shape: BoxShape.circle, color: color),
      );
    }

    return AnimatedBuilder(
      animation: _anim,
      builder: (context, _) {
        return Container(
          width: 7,
          height: 7,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: color,
            boxShadow: [
              BoxShadow(
                color: color.withValues(alpha: _anim.value),
                blurRadius: 10,
                spreadRadius: 2,
              ),
            ],
          ),
        );
      },
    );
  }
}

// ── Server Card ───────────────────────────────────────────────────────────

class _ServerCard extends ConsumerWidget {
  final ServerState state;
  const _ServerCard({required this.state});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isStarting = state.status == ServerStatus.starting;
    final isStopping = state.status == ServerStatus.stopping;
    final busy = isStarting || isStopping;

    final btnColor =
        state.isRunning ? const Color(0xFFFF453A) : const Color(0xFF30D158);

    return _Card(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _SectionLabel(
            icon: Icons.dns_rounded,
            label: 'Server',
            color: const Color(0xFF0A84FF),
          ),
          const SizedBox(height: 14),
          GestureDetector(
            onTap: busy
                ? null
                : () {
                    if (state.isRunning) {
                      ref.read(serverProvider.notifier).stopServer();
                    } else {
                      ref.read(serverProvider.notifier).startServer();
                    }
                  },
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 250),
              width: double.infinity,
              height: 48,
              decoration: BoxDecoration(
                gradient: busy
                    ? null
                    : LinearGradient(
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                        colors: state.isRunning
                            ? [
                                const Color(0xFFFF453A).withValues(alpha: 0.2),
                                const Color(0xFFFF6060).withValues(alpha: 0.08),
                              ]
                            : [
                                const Color(0xFF30D158).withValues(alpha: 0.2),
                                const Color(0xFF34C759).withValues(alpha: 0.08),
                              ],
                      ),
                color: busy ? Colors.white.withValues(alpha: 0.04) : null,
                borderRadius: BorderRadius.circular(14),
                border: Border.all(
                  color: busy
                      ? Colors.white12
                      : btnColor.withValues(alpha: 0.45),
                  width: 1.5,
                ),
              ),
              child: Center(
                child: busy
                    ? SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: state.isRunning
                              ? const Color(0xFFFF453A)
                              : const Color(0xFF30D158),
                        ),
                      )
                    : Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            state.isRunning
                                ? Icons.stop_circle_rounded
                                : Icons.play_circle_rounded,
                            size: 22,
                            color: btnColor,
                          ),
                          const SizedBox(width: 8),
                          Text(
                            state.isRunning ? 'Stop Server' : 'Start Server',
                            style: TextStyle(
                              fontSize: 15,
                              fontWeight: FontWeight.w600,
                              color: btnColor,
                            ),
                          ),
                        ],
                      ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ── OTP Card ─────────────────────────────────────────────────────────────

class _OtpCard extends ConsumerStatefulWidget {
  final ServerState state;
  const _OtpCard({required this.state});

  @override
  ConsumerState<_OtpCard> createState() => _OtpCardState();
}

class _OtpCardState extends ConsumerState<_OtpCard>
    with SingleTickerProviderStateMixin {
  late AnimationController _pulseController;
  late Animation<double> _pulseAnim;

  @override
  void initState() {
    super.initState();
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
    )..repeat(reverse: true);
    _pulseAnim =
        Tween<double>(begin: 0.6, end: 1.0).animate(_pulseController);
  }

  @override
  void dispose() {
    _pulseController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final state = widget.state;
    final hasOtp = state.otp != null && !state.isOtpExpired;

    return _Card(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _SectionLabel(
            icon: Icons.key_rounded,
            label: 'One-Time Password',
            color: const Color(0xFF5E5CE6),
          ),
          const SizedBox(height: 8),
          const Text(
            'Open iPhone app → Settings → Connect via OTP and enter this code.',
            style: TextStyle(
              color: Colors.white38,
              fontSize: 12,
              height: 1.5,
            ),
          ),
          const SizedBox(height: 16),
          if (hasOtp) ...[
            _OtpDisplay(otp: state.otp!, remaining: state.otpRemaining),
            const SizedBox(height: 14),
          ],
          GestureDetector(
            onTap: () => ref.read(serverProvider.notifier).generateOtp(),
            child: Container(
              width: double.infinity,
              height: 48,
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [
                    const Color(0xFF5E5CE6).withValues(alpha: 0.2),
                    const Color(0xFF7B79F0).withValues(alpha: 0.08),
                  ],
                ),
                borderRadius: BorderRadius.circular(14),
                border: Border.all(
                  color: const Color(0xFF5E5CE6).withValues(alpha: 0.45),
                  width: 1.5,
                ),
              ),
              child: Center(
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    FadeTransition(
                      opacity: _pulseAnim,
                      child: const Icon(
                        Icons.refresh_rounded,
                        size: 18,
                        color: Color(0xFF5E5CE6),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      hasOtp ? 'Regenerate OTP' : 'Generate OTP',
                      style: const TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w600,
                        color: Color(0xFF5E5CE6),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _OtpDisplay extends StatelessWidget {
  final String otp;
  final Duration? remaining;
  const _OtpDisplay({required this.otp, this.remaining});

  @override
  Widget build(BuildContext context) {
    const totalSeconds = 5 * 60;
    final remainingSeconds = remaining?.inSeconds ?? 0;
    final expired = remaining == null;
    final urgency = remainingSeconds < 60 && !expired;
    final progress = expired ? 0.0 : remainingSeconds / totalSeconds;

    final accentColor = expired
        ? Colors.white24
        : urgency
            ? const Color(0xFFFF9F0A)
            : const Color(0xFF5E5CE6);

    final mins = remainingSeconds ~/ 60;
    final secs = remainingSeconds % 60;

    return Container(
      padding: const EdgeInsets.fromLTRB(16, 20, 16, 16),
      decoration: BoxDecoration(
        color: const Color(0xFF1A1A1E),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: expired
              ? Colors.white.withValues(alpha: 0.06)
              : urgency
                  ? const Color(0xFFFF9F0A).withValues(alpha: 0.35)
                  : const Color(0xFF5E5CE6).withValues(alpha: 0.25),
          width: 1.5,
        ),
      ),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: otp.split('').asMap().entries.map((e) {
              final isMiddleGap = e.key == 3;
              return Row(
                children: [
                  if (isMiddleGap) const SizedBox(width: 12),
                  _OtpDigit(digit: e.value, urgency: urgency),
                  if (!isMiddleGap && e.key < 5) const SizedBox(width: 5),
                ],
              );
            }).toList(),
          ),
          const SizedBox(height: 14),
          if (!expired) ...[
            ClipRRect(
              borderRadius: BorderRadius.circular(3),
              child: LinearProgressIndicator(
                value: progress,
                minHeight: 3,
                backgroundColor: Colors.white.withValues(alpha: 0.07),
                valueColor: AlwaysStoppedAnimation<Color>(accentColor),
              ),
            ),
            const SizedBox(height: 9),
          ],
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                expired ? Icons.timer_off_rounded : Icons.hourglass_top_rounded,
                size: 12,
                color: accentColor,
              ),
              const SizedBox(width: 5),
              Text(
                expired
                    ? 'Expired'
                    : '$mins:${secs.toString().padLeft(2, '0')} remaining',
                style: TextStyle(
                  fontSize: 11,
                  color: accentColor,
                  fontWeight: FontWeight.w500,
                  letterSpacing: 0.2,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _OtpDigit extends StatelessWidget {
  final String digit;
  final bool urgency;
  const _OtpDigit({required this.digit, this.urgency = false});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 40,
      height: 52,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: urgency
              ? [
                  const Color(0xFFFF9F0A).withValues(alpha: 0.14),
                  const Color(0xFFFF9F0A).withValues(alpha: 0.04),
                ]
              : [
                  const Color(0xFF5E5CE6).withValues(alpha: 0.12),
                  const Color(0xFF5E5CE6).withValues(alpha: 0.03),
                ],
        ),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: urgency
              ? const Color(0xFFFF9F0A).withValues(alpha: 0.3)
              : const Color(0xFF5E5CE6).withValues(alpha: 0.22),
          width: 1.5,
        ),
      ),
      alignment: Alignment.center,
      child: Text(
        digit,
        style: const TextStyle(
          color: Colors.white,
          fontSize: 28,
          fontWeight: FontWeight.w700,
          letterSpacing: 0,
        ),
      ),
    );
  }
}

// ── IP Card ───────────────────────────────────────────────────────────────

class _IpCard extends StatelessWidget {
  final ServerState state;
  const _IpCard({required this.state});

  void _copy(BuildContext context, String text) {
    Clipboard.setData(ClipboardData(text: text));
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: const Row(
          children: [
            Icon(Icons.check_rounded, color: Color(0xFF30D158), size: 16),
            SizedBox(width: 8),
            Text('Copied to clipboard',
                style: TextStyle(color: Colors.white, fontSize: 13)),
          ],
        ),
        backgroundColor: const Color(0xFF2C2C2E),
        margin: const EdgeInsets.all(16),
        behavior: SnackBarBehavior.floating,
        duration: const Duration(milliseconds: 1500),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        elevation: 8,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final fullAddress = '${state.ipAddress}:$kHttpPort';

    return _Card(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _SectionLabel(
            icon: Icons.wifi_rounded,
            label: 'IP Address',
            color: const Color(0xFF0A84FF),
          ),
          const SizedBox(height: 8),
          const Text(
            'Enter this address manually in iPhone app Settings.',
            style: TextStyle(color: Colors.white38, fontSize: 12, height: 1.5),
          ),
          const SizedBox(height: 14),
          GestureDetector(
            onTap: () => _copy(context, state.ipAddress),
            child: Container(
              padding:
                  const EdgeInsets.symmetric(vertical: 14, horizontal: 16),
              decoration: BoxDecoration(
                color: const Color(0xFF1A1A1E),
                borderRadius: BorderRadius.circular(14),
                border: Border.all(
                  color: const Color(0xFF0A84FF).withValues(alpha: 0.3),
                  width: 1.5,
                ),
              ),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: const Color(0xFF0A84FF).withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(9),
                    ),
                    child: const Icon(Icons.router_rounded,
                        color: Color(0xFF0A84FF), size: 16),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Server Address',
                          style: TextStyle(color: Colors.white38, fontSize: 11),
                        ),
                        const SizedBox(height: 3),
                        Text(
                          fullAddress,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                            letterSpacing: 0.4,
                            fontFamily: 'monospace',
                          ),
                        ),
                      ],
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.all(7),
                    decoration: BoxDecoration(
                      color: const Color(0xFF0A84FF).withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: const Icon(Icons.copy_rounded,
                        color: Color(0xFF0A84FF), size: 15),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ── Connected Card ────────────────────────────────────────────────────────

class _ConnectedCard extends StatelessWidget {
  final String clientIp;
  const _ConnectedCard({required this.clientIp});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            const Color(0xFF30D158).withValues(alpha: 0.14),
            const Color(0xFF30D158).withValues(alpha: 0.04),
          ],
        ),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(
          color: const Color(0xFF30D158).withValues(alpha: 0.3),
          width: 1.5,
        ),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF30D158).withValues(alpha: 0.08),
            blurRadius: 24,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: const Color(0xFF30D158).withValues(alpha: 0.18),
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Icon(Icons.smartphone_rounded,
                color: Color(0xFF30D158), size: 22),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'iPhone Connected',
                  style: TextStyle(
                    color: Color(0xFF30D158),
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  clientIp,
                  style: const TextStyle(
                    color: Colors.white38,
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ),
          _StatusDot(running: true),
        ],
      ),
    );
  }
}

// ── Error Card ────────────────────────────────────────────────────────────

class _ErrorCard extends StatelessWidget {
  final String message;
  const _ErrorCard({required this.message});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            const Color(0xFFFF453A).withValues(alpha: 0.12),
            const Color(0xFFFF453A).withValues(alpha: 0.04),
          ],
        ),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: const Color(0xFFFF453A).withValues(alpha: 0.3),
          width: 1.5,
        ),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(7),
            decoration: BoxDecoration(
              color: const Color(0xFFFF453A).withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(8),
            ),
            child: const Icon(Icons.error_outline_rounded,
                color: Color(0xFFFF453A), size: 16),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              message,
              style: const TextStyle(color: Color(0xFFFF453A), fontSize: 13),
            ),
          ),
        ],
      ),
    );
  }
}

// ── Shared Widgets ────────────────────────────────────────────────────────

class _Card extends StatelessWidget {
  final Widget child;
  const _Card({required this.child});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFF242428),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: Colors.white.withValues(alpha: 0.07)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.35),
            blurRadius: 24,
            offset: const Offset(0, 6),
            spreadRadius: -6,
          ),
        ],
      ),
      child: child,
    );
  }
}

class _SectionLabel extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;
  const _SectionLabel(
      {required this.icon, required this.label, required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color.withValues(alpha: 0.2)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: color, size: 13),
          const SizedBox(width: 5),
          Text(
            label,
            style: TextStyle(
              color: color,
              fontSize: 11,
              fontWeight: FontWeight.w700,
              letterSpacing: 0.4,
            ),
          ),
        ],
      ),
    );
  }
}
