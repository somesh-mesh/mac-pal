import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/dio_client.dart';
import '../../core/exceptions.dart';
import 'app_model.dart';

// All communication with the Mac server lives here.
// Screens and providers never call Dio directly — they go through this class.
class AppsRepository {
  final Dio _dio;
  AppsRepository(this._dio);

  // GET /apps — fetches the list of installed Mac apps
  Future<List<AppModel>> getApps() async {
    try {
      final res  = await _dio.get('/apps');
      final list = res.data['apps'] as List;
      return list.map((e) => AppModel.fromJson(e)).toList();
    } on DioException {
      // Network error, timeout, or server unreachable
      throw const MacOfflineException();
    }
  }

  // POST /open — tells the Mac server to open the given app
  Future<void> openApp(String appName) async {
    try {
      await _dio.post('/open', data: {'appName': appName});
    } on DioException {
      throw AppOpenException(appName);
    }
  }

  // GET /ping — returns true if server is reachable, false otherwise
  // Used by Settings screen connection test and Apps screen status dot
  Future<bool> ping() async {
    try {
      await _dio.get('/ping');
      return true;
    } catch (_) {
      return false;
    }
  }
}

// Provider — injects Dio into the repository
final appsRepositoryProvider = Provider<AppsRepository>((ref) {
  final dio = ref.watch(dioProvider);
  return AppsRepository(dio);
});
