import 'package:plugin_platform_interface/plugin_platform_interface.dart';
import 'method_channel.dart';
import 'models.dart';
import 'enums.dart';

abstract class FlutterStorageManagerPlatform extends PlatformInterface {
  FlutterStorageManagerPlatform() : super(token: _token);

  static final Object _token = Object();

  static FlutterStorageManagerPlatform _instance =
      MethodChannelFlutterStorageManager();

  static FlutterStorageManagerPlatform get instance => _instance;

  static set instance(FlutterStorageManagerPlatform instance) {
    PlatformInterface.verifyToken(instance, _token);
    _instance = instance;
  }

  Future<StorageInfo> getStorageInfo() {
    throw UnimplementedError('getStorageInfo() has not been implemented.');
  }

  Future<StorageAnalysis> analyzeStorage() {
    throw UnimplementedError('analyzeStorage() has not been implemented.');
  }

  Future<List<StorageItem>> getItems({StorageCategory? category}) {
    throw UnimplementedError('getItems() has not been implemented.');
  }

  Future<CleanupResult> deleteItems(List<String> paths) {
    throw UnimplementedError('deleteItems() has not been implemented.');
  }

  Future<CleanupResult> clearCategory(StorageCategory category) {
    throw UnimplementedError('clearCategory() has not been implemented.');
  }

  Future<CleanupResult> clearSelected(List<StorageItem> items) {
    throw UnimplementedError('clearSelected() has not been implemented.');
  }

  Future<CleanupResult> clearAllManagedFiles() {
    throw UnimplementedError(
      'clearAllManagedFiles() has not been implemented.',
    );
  }

  Future<bool> fileExists(String path) {
    throw UnimplementedError('fileExists() has not been implemented.');
  }

  Future<StorageItem?> getFileInfo(String path) {
    throw UnimplementedError('getFileInfo() has not been implemented.');
  }

  Future<void> prefetchFile(
    Uri url, {
    String? fileName,
    StorageCategory category = StorageCategory.prefetched,
    bool overwrite = false,
  }) {
    throw UnimplementedError('prefetchFile() has not been implemented.');
  }

  Stream<DownloadProgress> prefetchProgress(String taskId) {
    throw UnimplementedError('prefetchProgress() has not been implemented.');
  }

  Future<void> cancelPrefetch(String taskId) {
    throw UnimplementedError('cancelPrefetch() has not been implemented.');
  }

  Future<CleanupPreview> previewCleanup({List<StorageCategory>? categories}) {
    throw UnimplementedError('previewCleanup() has not been implemented.');
  }

  Future<bool> canDelete(String path) {
    throw UnimplementedError('canDelete() has not been implemented.');
  }

  Future<StoragePermissionStatus> checkPermission() {
    throw UnimplementedError('checkPermission() has not been implemented.');
  }

  Future<StoragePermissionStatus> requestPermission() {
    throw UnimplementedError('requestPermission() has not been implemented.');
  }

  Future<StorageCapabilities> getCapabilities() {
    throw UnimplementedError('getCapabilities() has not been implemented.');
  }
}
