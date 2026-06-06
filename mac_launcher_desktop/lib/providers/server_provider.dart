import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../server/embedded_server.dart';
import '../server/discovery_service.dart';
import '../server/mac_service.dart';
import '../server/otp_service.dart';
import '../core/network_utils.dart';
import '../core/constants.dart';

enum ServerStatus { stopped, starting, running, stopping }

@immutable
class ServerState {
  final ServerStatus status;
  final String ipAddress;
  final String? otp;
  final DateTime? otpExpiresAt;
  final String? lastConnectedClient;
  final String? error;

  const ServerState({
    this.status = ServerStatus.stopped,
    this.ipAddress = '',
    this.otp,
    this.otpExpiresAt,
    this.lastConnectedClient,
    this.error,
  });

  bool get isRunning => status == ServerStatus.running;

  Duration? get otpRemaining {
    if (otpExpiresAt == null) return null;
    final d = otpExpiresAt!.difference(DateTime.now());
    return d.isNegative ? null : d;
  }

  bool get isOtpExpired =>
      otp != null && (otpExpiresAt == null || DateTime.now().isAfter(otpExpiresAt!));

  ServerState copyWith({
    ServerStatus? status,
    String? ipAddress,
    String? otp,
    DateTime? otpExpiresAt,
    String? lastConnectedClient,
    String? error,
    bool clearOtp = false,
    bool clearError = false,
    bool clearConnectedClient = false,
  }) =>
      ServerState(
        status: status ?? this.status,
        ipAddress: ipAddress ?? this.ipAddress,
        otp: clearOtp ? null : (otp ?? this.otp),
        otpExpiresAt: clearOtp ? null : (otpExpiresAt ?? this.otpExpiresAt),
        lastConnectedClient: clearConnectedClient
            ? null
            : (lastConnectedClient ?? this.lastConnectedClient),
        error: clearError ? null : (error ?? this.error),
      );
}

class ServerNotifier extends Notifier<ServerState> {
  late final OtpService _otpService;
  late final MacService _macService;
  late final EmbeddedServer _server;
  late final DiscoveryService _discovery;
  StreamSubscription<String>? _connectionSub;
  Timer? _otpTimer;

  @override
  ServerState build() {
    _otpService = OtpService();
    _macService = MacService();
    _server = EmbeddedServer(otpService: _otpService, macService: _macService);
    _discovery = DiscoveryService();

    // Watch for OTP-validated connections from phone
    _connectionSub = _server.onClientConnected.listen((clientIp) {
      state = state.copyWith(
        lastConnectedClient: clientIp,
        clearOtp: true,
      );
      _stopOtpTimer();
    });

    ref.onDispose(() {
      _connectionSub?.cancel();
      _otpTimer?.cancel();
      _server.stop();
      _discovery.stop();
    });

    return const ServerState();
  }

  Future<void> startServer() async {
    state = state.copyWith(status: ServerStatus.starting, clearError: true);
    try {
      await _server.start();
      await _discovery.start();
      final ip = await getLocalIpAddress();
      state = state.copyWith(
        status: ServerStatus.running,
        ipAddress: ip,
      );
    } catch (e) {
      state = state.copyWith(
        status: ServerStatus.stopped,
        error: 'Failed to start: $e',
      );
    }
  }

  Future<void> stopServer() async {
    state = state.copyWith(status: ServerStatus.stopping);
    _stopOtpTimer();
    await _server.stop();
    _discovery.stop();
    state = state.copyWith(
      status: ServerStatus.stopped,
      clearOtp: true,
      clearConnectedClient: true,
    );
  }

  void generateOtp() {
    final otp = _otpService.generate();
    state = state.copyWith(
      otp: otp,
      otpExpiresAt: DateTime.now().add(kOtpExpiry),
    );
    _startOtpTimer();
  }

  void _startOtpTimer() {
    _otpTimer?.cancel();
    _otpTimer = Timer.periodic(const Duration(seconds: 1), (_) {
      if (_otpService.isExpired) {
        state = state.copyWith(clearOtp: true);
        _stopOtpTimer();
      } else {
        // Re-emit to force countdown update in UI
        state = state.copyWith(
          otpExpiresAt: state.otpExpiresAt,
        );
      }
    });
  }

  void _stopOtpTimer() {
    _otpTimer?.cancel();
    _otpTimer = null;
  }
}

final serverProvider = NotifierProvider<ServerNotifier, ServerState>(
  ServerNotifier.new,
);
