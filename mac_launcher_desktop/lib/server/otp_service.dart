import 'dart:math';

class OtpService {
  String? _currentOtp;
  DateTime? _expiresAt;

  String generate() {
    final rng = Random.secure();
    _currentOtp = List.generate(6, (_) => rng.nextInt(10)).join();
    _expiresAt = DateTime.now().add(const Duration(minutes: 5));
    return _currentOtp!;
  }

  bool validate(String otp) {
    if (_currentOtp == null || _expiresAt == null) return false;
    if (DateTime.now().isAfter(_expiresAt!)) return false;
    return otp.trim() == _currentOtp;
  }

  Duration? get remainingTime {
    if (_expiresAt == null) return null;
    final remaining = _expiresAt!.difference(DateTime.now());
    return remaining.isNegative ? null : remaining;
  }

  bool get isExpired {
    if (_expiresAt == null) return true;
    return DateTime.now().isAfter(_expiresAt!);
  }

  void invalidate() {
    _currentOtp = null;
    _expiresAt = null;
  }

  String? get currentOtp => _currentOtp;
}
