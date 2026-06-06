import 'dart:async';
import 'dart:convert';
import 'dart:io';

const int _kDiscoveryPort = 3001;
const String _kDiscoveryMessage = 'MAC_LAUNCHER_DISCOVER';

class DiscoveredMac {
  final String hostname;
  final String ip;
  final int port;

  const DiscoveredMac({
    required this.hostname,
    required this.ip,
    required this.port,
  });
}

/// Sends a UDP broadcast on the local network and collects responses from
/// any Mac running the Mac Launcher desktop app.
Future<List<DiscoveredMac>> discoverMacs({
  Duration timeout = const Duration(seconds: 4),
}) async {
  final results = <String, DiscoveredMac>{};
  RawDatagramSocket? socket;

  try {
    socket = await RawDatagramSocket.bind(InternetAddress.anyIPv4, 0);
    socket.broadcastEnabled = true;

    final broadcastAddr = InternetAddress('255.255.255.255');
    final msg = utf8.encode(_kDiscoveryMessage);
    socket.send(msg, broadcastAddr, _kDiscoveryPort);

    final completer = Completer<void>();
    Timer? timer;

    timer = Timer(timeout, () {
      if (!completer.isCompleted) completer.complete();
    });

    socket.listen((event) {
      if (event != RawSocketEvent.read) return;
      final datagram = socket!.receive();
      if (datagram == null) return;

      try {
        final response =
            jsonDecode(utf8.decode(datagram.data)) as Map<String, dynamic>;
        if (response['type'] == 'mac-launcher') {
          final ip = response['ip'] as String;
          results[ip] = DiscoveredMac(
            hostname: response['hostname'] as String? ?? ip,
            ip: ip,
            port: (response['port'] as num?)?.toInt() ?? 3000,
          );
        }
      } catch (_) {}
    });

    await completer.future;
    timer.cancel();
  } catch (_) {
  } finally {
    socket?.close();
  }

  return results.values.toList();
}

/// Validates an OTP against the server at [baseUrl].
/// Returns true if the OTP is accepted, false otherwise.
Future<bool> validateOtp(String baseUrl, String otp) async {
  final client = HttpClient();
  try {
    final uri = Uri.parse('$baseUrl/validate-otp');
    final req = await client.postUrl(uri);
    req.headers.contentType = ContentType.json;
    req.write(jsonEncode({'otp': otp}));
    final res = await req.close();
    final body = await res.transform(utf8.decoder).join();
    final json = jsonDecode(body) as Map<String, dynamic>;
    return json['valid'] == true;
  } catch (_) {
    return false;
  } finally {
    client.close();
  }
}
