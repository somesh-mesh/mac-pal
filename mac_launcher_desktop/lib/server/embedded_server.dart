import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:shelf/shelf.dart';
import 'package:shelf/shelf_io.dart' as shelf_io;
import 'package:shelf_router/shelf_router.dart';
import 'otp_service.dart';
import 'mac_service.dart';
import '../core/constants.dart';

class EmbeddedServer {
  HttpServer? _server;
  final OtpService otpService;
  final MacService _macService;

  // Notifies UI when an OTP is successfully validated (phone connected)
  final _connectionController = StreamController<String>.broadcast();
  Stream<String> get onClientConnected => _connectionController.stream;

  EmbeddedServer({
    required this.otpService,
    required MacService macService,
  }) : _macService = macService;

  Future<void> start() async {
    final router = Router()
      ..get('/ping', _ping)
      ..get('/apps', _getApps)
      ..post('/open', _openApp)
      ..get('/icon', _getIcon)
      ..post('/lock', _lock)
      ..post('/unlock', _unlock)
      ..get('/lock-status', _getLockStatus)
      ..post('/validate-otp', _validateOtp);

    final handler = Pipeline()
        .addMiddleware(_cors())
        .addHandler(router.call);

    _server = await shelf_io.serve(
      handler,
      InternetAddress.anyIPv4,
      kHttpPort,
    );
  }

  Future<void> stop() async {
    await _server?.close(force: true);
    _server = null;
  }

  bool get isRunning => _server != null;

  // ── Middleware ────────────────────────────────────────────────────────────

  Middleware _cors() => (Handler inner) => (Request req) async {
        if (req.method == 'OPTIONS') {
          return Response.ok('', headers: _corsHeaders);
        }
        final res = await inner(req);
        return res.change(headers: _corsHeaders);
      };

  static const _corsHeaders = {
    'Access-Control-Allow-Origin': '*',
    'Access-Control-Allow-Methods': 'GET, POST, OPTIONS',
    'Access-Control-Allow-Headers': 'Content-Type',
  };

  Response _json(Object data, {int status = 200}) => Response(
        status,
        body: jsonEncode(data),
        headers: {'Content-Type': 'application/json'},
      );

  // ── Endpoints ─────────────────────────────────────────────────────────────

  Future<Response> _ping(Request req) async =>
      _json({'status': 'ok', 'machine': Platform.localHostname});

  Future<Response> _getApps(Request req) async {
    final apps = await _macService.listApps();
    return _json({'apps': apps.map((a) => a.toJson()).toList()});
  }

  Future<Response> _openApp(Request req) async {
    final body = jsonDecode(await req.readAsString()) as Map<String, dynamic>;
    final appName = body['appName'] as String?;
    if (appName == null) {
      return _json({'error': 'appName is required'}, status: 400);
    }
    final ok = await _macService.openApp(appName);
    return ok
        ? _json({'status': 'opened', 'app': appName})
        : _json({'error': 'Could not open $appName'}, status: 500);
  }

  Future<Response> _getIcon(Request req) async {
    final appPath = req.url.queryParameters['path'];
    if (appPath == null) {
      return _json({'error': 'path query param required'}, status: 400);
    }
    final iconData = await _macService.getAppIcon(appPath);
    if (iconData == null) {
      return _json({'error': 'icon not found'}, status: 404);
    }
    return Response.ok(iconData, headers: {
      'Content-Type': 'image/png',
      'Cache-Control': 'public, max-age=3600',
    });
  }

  Future<Response> _lock(Request req) async {
    final ok = await _macService.lockScreen();
    return ok
        ? _json({'status': 'locked'})
        : _json({'error': 'Lock failed'}, status: 500);
  }

  Future<Response> _unlock(Request req) async {
    final result = await _macService.unlockScreen();
    if (result == null) {
      return _json({
        'error': 'Password not configured',
        'setup':
            "echo 'mac_password=YOUR_PASSWORD' > ~/.mac-launcher.conf && chmod 600 ~/.mac-launcher.conf",
      }, status: 503);
    }
    return result
        ? _json({'status': 'unlocked'})
        : _json({'error': 'Unlock failed'}, status: 500);
  }

  Future<Response> _getLockStatus(Request req) async {
    final locked = await _macService.isLocked();
    return _json({'locked': locked});
  }

  Future<Response> _validateOtp(Request req) async {
    final body = jsonDecode(await req.readAsString()) as Map<String, dynamic>;
    final otp = body['otp'] as String?;
    if (otp == null) {
      return _json({'error': 'otp is required'}, status: 400);
    }

    final valid = otpService.validate(otp);
    if (valid) {
      otpService.invalidate(); // single-use
      final clientIp = req.context['shelf.io.connection_info'] != null
          ? (req.context['shelf.io.connection_info'] as HttpConnectionInfo)
              .remoteAddress
              .address
          : 'unknown';
      _connectionController.add(clientIp);
    }

    return _json({'valid': valid});
  }
}
