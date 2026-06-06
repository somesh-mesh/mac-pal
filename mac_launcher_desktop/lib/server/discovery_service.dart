import 'dart:async';
import 'dart:convert';
import 'dart:io';
import '../core/constants.dart';
import '../core/network_utils.dart';

/// Listens on UDP port [kDiscoveryPort] and responds to mobile discovery
/// broadcasts with this machine's IP so the phone can locate the server
/// without the user typing an IP address.
class DiscoveryService {
  RawDatagramSocket? _socket;
  bool get isRunning => _socket != null;

  Future<void> start() async {
    _socket = await RawDatagramSocket.bind(
      InternetAddress.anyIPv4,
      kDiscoveryPort,
    );
    _socket!.broadcastEnabled = true;

    final myIp = await getLocalIpAddress();
    final hostname = Platform.localHostname;

    _socket!.listen((event) {
      if (event != RawSocketEvent.read) return;
      final datagram = _socket!.receive();
      if (datagram == null) return;

      final msg = utf8.decode(datagram.data, allowMalformed: true).trim();
      if (msg != kDiscoveryMessage) return;

      final response = jsonEncode({
        'type': 'mac-launcher',
        'hostname': hostname,
        'ip': myIp,
        'port': kHttpPort,
      });
      _socket!.send(
        utf8.encode(response),
        datagram.address,
        datagram.port,
      );
    });
  }

  void stop() {
    _socket?.close();
    _socket = null;
  }
}
