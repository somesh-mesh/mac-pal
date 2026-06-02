import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'app_model.dart';
import 'apps_repository.dart';

// Manages the app list state: loading, error, or data.
// AsyncNotifier gives us AsyncValue<List<AppModel>> automatically.
class AppsNotifier extends AsyncNotifier<List<AppModel>> {
  @override
  Future<List<AppModel>> build() {
    // Runs once when provider is first watched — loads apps from server
    return ref.watch(appsRepositoryProvider).getApps();
  }

  // Called when user taps an app tile
  Future<void> openApp(String appName) async {
    final repo = ref.read(appsRepositoryProvider);
    await repo.openApp(appName); // throws AppOpenException on failure
  }

  // Called on pull-to-refresh
  Future<void> refresh() async {
    state = const AsyncLoading();
    state = await AsyncValue.guard(
      () => ref.read(appsRepositoryProvider).getApps(),
    );
  }
}

final appsProvider = AsyncNotifierProvider<AppsNotifier, List<AppModel>>(
  AppsNotifier.new,
);

// Separate provider for Mac online/offline status (green/red dot in AppBar)
final macStatusProvider = FutureProvider<bool>((ref) {
  return ref.watch(appsRepositoryProvider).ping();
});
