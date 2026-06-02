// Custom exceptions used throughout the app.
// Using typed exceptions (instead of raw strings) lets us show
// different UI messages for different failure modes.

// Thrown when the Mac server cannot be reached (offline, wrong IP, timeout)
class MacOfflineException implements Exception {
  final String message;
  const MacOfflineException([this.message = 'Mac is offline or unreachable']);

  @override
  String toString() => message;
}

// Thrown when the server responded but failed to open the app
class AppOpenException implements Exception {
  final String appName;
  const AppOpenException(this.appName);

  @override
  String toString() => 'Could not open $appName';
}
