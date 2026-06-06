import 'dart:io';

Future<String> getLocalIpAddress() async {
  try {
    final interfaces = await NetworkInterface.list(
      type: InternetAddressType.IPv4,
      includeLoopback: false,
    );
    for (final iface in interfaces) {
      // Prefer en0 (Wi-Fi) on macOS
      if (iface.name == 'en0') {
        for (final addr in iface.addresses) {
          if (!addr.isLoopback) return addr.address;
        }
      }
    }
    // Fallback: any non-loopback IPv4
    for (final iface in interfaces) {
      for (final addr in iface.addresses) {
        if (!addr.isLoopback) return addr.address;
      }
    }
  } catch (_) {}
  return '127.0.0.1';
}
