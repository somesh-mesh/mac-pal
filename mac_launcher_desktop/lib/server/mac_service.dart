import 'dart:io';

class AppInfo {
  final String name;
  final String path;
  const AppInfo({required this.name, required this.path});
  Map<String, dynamic> toJson() => {'name': name, 'path': path};
}

class MacService {
  final _iconCache = <String, List<int>>{};

  Future<List<AppInfo>> listApps() async {
    final home = Platform.environment['HOME'] ?? '';
    final searchDirs = [
      '/Applications',
      '/Applications/Utilities',
      '/System/Applications',
      '/System/Applications/Utilities',
      if (home.isNotEmpty) '$home/Applications',
    ];

    final apps = <AppInfo>[];
    final seen = <String>{};

    for (final dir in searchDirs) {
      final d = Directory(dir);
      if (!d.existsSync()) continue;
      try {
        for (final entity in d.listSync()) {
          if (entity is! Directory) continue;
          final name = entity.path.split('/').last;
          if (!name.endsWith('.app') || seen.contains(name)) continue;
          seen.add(name);
          apps.add(AppInfo(
            name: name.substring(0, name.length - 4),
            path: entity.path,
          ));
        }
      } catch (_) {}
    }

    apps.sort((a, b) => a.name.toLowerCase().compareTo(b.name.toLowerCase()));
    return apps;
  }

  Future<bool> openApp(String appName) async {
    final r = await Process.run('open', ['-a', appName]);
    return r.exitCode == 0;
  }

  Future<List<int>?> getAppIcon(String appPath) async {
    if (_iconCache.containsKey(appPath)) return _iconCache[appPath];

    final iconSrc = await _findIconFile(appPath);
    if (iconSrc == null) return null;

    final tmpFile = '/tmp/ml_icon_${DateTime.now().millisecondsSinceEpoch}.png';
    try {
      final r1 = await Process.run(
        'sips',
        ['-s', 'format', 'png', iconSrc, '--out', tmpFile],
      );
      if (r1.exitCode != 0) return null;

      await Process.run('sips', ['--resampleHeightWidth', '128', '128', tmpFile]);

      final file = File(tmpFile);
      if (!file.existsSync()) return null;

      final bytes = file.readAsBytesSync();
      try { file.deleteSync(); } catch (_) {}

      _iconCache[appPath] = bytes;
      return bytes;
    } catch (_) {
      try { File(tmpFile).deleteSync(); } catch (_) {}
      return null;
    }
  }

  Future<String?> _findIconFile(String appPath) async {
    final plistPath = '$appPath/Contents/Info.plist';
    try {
      final r = await Process.run(
        '/usr/libexec/PlistBuddy',
        ['-c', 'Print CFBundleIconFile', plistPath],
      );
      if (r.exitCode == 0) {
        var iconFile = (r.stdout as String).trim();
        if (!iconFile.endsWith('.icns')) iconFile = '$iconFile.icns';
        final full = '$appPath/Contents/Resources/$iconFile';
        if (File(full).existsSync()) return full;
      }
    } catch (_) {}

    final resourcesDir = Directory('$appPath/Contents/Resources');
    if (!resourcesDir.existsSync()) return null;
    try {
      for (final e in resourcesDir.listSync()) {
        if (e is File && e.path.endsWith('.icns')) return e.path;
      }
    } catch (_) {}
    return null;
  }

  Future<bool> lockScreen() async {
    const script =
        'tell application "System Events" to keystroke "q" using {control down, command down}';
    final r = await Process.run('osascript', ['-e', script]);
    return r.exitCode == 0;
  }

  // Returns null if password not configured, true if succeeded, false if failed
  Future<bool?> unlockScreen() async {
    final password = _readStoredPassword();
    if (password == null) return null;

    final safe =
        password.replaceAll(r'\', r'\\').replaceAll('"', r'\"');
    final script = '''tell application "System Events"
  key code 56
  delay 0.8
  keystroke "$safe"
  key code 36
end tell''';
    final r = await Process.run('osascript', ['-e', script]);
    return r.exitCode == 0;
  }

  Future<bool> isLocked() async {
    try {
      final r = await Process.run('ioreg', ['-n', 'IOHIDSystem'],
          stdoutEncoding: const SystemEncoding());
      return (r.stdout as String).contains('CGSSessionScreenIsLocked = 1');
    } catch (_) {
      return false;
    }
  }

  String? _readStoredPassword() {
    final home = Platform.environment['HOME'] ?? '';
    if (home.isEmpty) return null;
    try {
      final text = File('$home/.mac-launcher.conf').readAsStringSync();
      final match = RegExp(r'^mac_password=(.+)$', multiLine: true)
          .firstMatch(text);
      return match?.group(1)?.trim();
    } catch (_) {
      return null;
    }
  }
}
