import 'src/platform_interface.dart';
import 'src/models.dart';
import 'src/enums.dart';

export 'src/models.dart';
export 'src/enums.dart';
export 'src/exceptions.dart';

/// Main class for interacting with the Flutter Storage Manager.
class FlutterStorageManager {
  FlutterStorageManager._();

  static final FlutterStorageManager instance = FlutterStorageManager._();

  static bool get loggingEnabled => _loggingEnabled;
  static bool _loggingEnabled = false;

  /// Configure global settings for the plugin.
  static void configure({bool enableLogging = false}) {
    _loggingEnabled = enableLogging;
  }

  /// Retrieves overall storage information.
  Future<StorageInfo> getStorageInfo() {
    return FlutterStorageManagerPlatform.instance.getStorageInfo();
  }

  /// Analyzes application storage and returns categorized usage.
  Future<StorageAnalysis> analyzeStorage() {
    return FlutterStorageManagerPlatform.instance.analyzeStorage();
  }

  /// Gets a list of storage items, optionally filtered by category.
  Future<List<StorageItem>> getItems({StorageCategory? category}) {
    return FlutterStorageManagerPlatform.instance.getItems(category: category);
  }

  /// Safely deletes specific files by path.
  Future<CleanupResult> deleteItems(List<String> paths) {
    return FlutterStorageManagerPlatform.instance.deleteItems(paths);
  }

  /// Clears an entire category of managed storage.
  Future<CleanupResult> clearCategory(StorageCategory category) {
    return FlutterStorageManagerPlatform.instance.clearCategory(category);
  }

  /// Clears selected items.
  Future<CleanupResult> clearSelected(List<StorageItem> items) {
    return FlutterStorageManagerPlatform.instance.clearSelected(items);
  }

  /// Clears all plugin-managed files across all categories.
  Future<CleanupResult> clearAllManagedFiles() {
    return FlutterStorageManagerPlatform.instance.clearAllManagedFiles();
  }

  /// Checks if a file exists safely.
  Future<bool> fileExists(String path) {
    return FlutterStorageManagerPlatform.instance.fileExists(path);
  }

  /// Gets information about a specific file.
  Future<StorageItem?> getFileInfo(String path) {
    return FlutterStorageManagerPlatform.instance.getFileInfo(path);
  }

  /// Downloads and caches a file in the managed storage.
  Future<void> prefetchFile(
    Uri url, {
    String? fileName,
    StorageCategory category = StorageCategory.prefetched,
    bool overwrite = false,
  }) {
    return FlutterStorageManagerPlatform.instance.prefetchFile(
      url,
      fileName: fileName,
      category: category,
      overwrite: overwrite,
    );
  }

  /// Previews a cleanup operation before performing it.
  Future<CleanupPreview> previewCleanup({List<StorageCategory>? categories}) {
    return FlutterStorageManagerPlatform.instance.previewCleanup(
      categories: categories,
    );
  }

  /// Checks if a path is allowed to be deleted.
  Future<bool> canDelete(String path) {
    return FlutterStorageManagerPlatform.instance.canDelete(path);
  }

  /// Checks storage permissions if required by the platform.
  Future<StoragePermissionStatus> checkPermission() {
    return FlutterStorageManagerPlatform.instance.checkPermission();
  }

  /// Requests storage permissions if required by the platform.
  Future<StoragePermissionStatus> requestPermission() {
    return FlutterStorageManagerPlatform.instance.requestPermission();
  }

  /// Gets the specific capabilities of the current platform.
  Future<StorageCapabilities> getCapabilities() {
    return FlutterStorageManagerPlatform.instance.getCapabilities();
  }
}
