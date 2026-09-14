import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_storage_manager/flutter_storage_manager.dart';
import 'package:flutter_storage_manager/src/platform_interface.dart';
import 'package:plugin_platform_interface/plugin_platform_interface.dart';

class MockFlutterStorageManagerPlatform
    with MockPlatformInterfaceMixin
    implements FlutterStorageManagerPlatform {
  @override
  Future<StorageInfo> getStorageInfo() async {
    return StorageInfo(
      totalBytes: 1000,
      usedBytes: 500,
      freeBytes: 500,
      appUsedBytes: 100,
      appCacheBytes: 50,
      usagePercentage: 50.0,
    );
  }

  @override
  Future<StorageAnalysis> analyzeStorage() async {
    return StorageAnalysis(
      categories: [
        StorageCategoryInfo(
            category: StorageCategory.cache, sizeBytes: 50, itemCount: 1),
      ],
      totalCleanableBytes: 50,
      items: [
        StorageItem(
          id: '/path',
          name: 'file.txt',
          path: '/path',
          sizeBytes: 50,
          category: StorageCategory.cache,
          canDelete: true,
          isDirectory: false,
        )
      ],
    );
  }

  @override
  Future<List<StorageItem>> getItems({StorageCategory? category}) async {
    return [
      StorageItem(
        id: '/path',
        name: 'file.txt',
        path: '/path',
        sizeBytes: 50,
        category: StorageCategory.cache,
        canDelete: true,
        isDirectory: false,
      )
    ];
  }

  @override
  Future<CleanupResult> deleteItems(List<String> paths) async {
    return CleanupResult(
      deletedCount: 1,
      failedCount: 0,
      skippedCount: 0,
      bytesFreed: 50,
      results: [
        CleanupItemResult(
          path: '/path',
          success: true,
          bytes: 50,
        )
      ],
    );
  }

  @override
  Future<CleanupResult> clearCategory(StorageCategory category) async {
    return deleteItems(['/path']);
  }

  @override
  Future<CleanupResult> clearSelected(List<StorageItem> items) async {
    return deleteItems(items.map((e) => e.path).toList());
  }

  @override
  Future<CleanupResult> clearAllManagedFiles() async {
    return deleteItems(['/path']);
  }

  @override
  Future<bool> fileExists(String path) async {
    return true;
  }

  @override
  Future<StorageItem?> getFileInfo(String path) async {
    return StorageItem(
      id: path,
      name: 'file.txt',
      path: path,
      sizeBytes: 50,
      category: StorageCategory.cache,
      canDelete: true,
      isDirectory: false,
    );
  }

  @override
  Future<void> prefetchFile(
    Uri url, {
    String? fileName,
    StorageCategory category = StorageCategory.prefetched,
    bool overwrite = false,
  }) async {
    return;
  }

  @override
  Stream<DownloadProgress> prefetchProgress(String taskId) {
    return Stream.value(DownloadProgress(
        receivedBytes: 100, totalBytes: 100, percentage: 100.0));
  }

  @override
  Future<void> cancelPrefetch(String taskId) async {
    return;
  }

  @override
  Future<CleanupPreview> previewCleanup(
      {List<StorageCategory>? categories}) async {
    return CleanupPreview(
      itemCount: 1,
      totalBytes: 50,
      items: await getItems(),
    );
  }

  @override
  Future<bool> canDelete(String path) async {
    return true;
  }

  @override
  Future<StoragePermissionStatus> checkPermission() async {
    return StoragePermissionStatus.notRequired;
  }

  @override
  Future<StoragePermissionStatus> requestPermission() async {
    return StoragePermissionStatus.notRequired;
  }

  @override
  Future<StorageCapabilities> getCapabilities() async {
    return StorageCapabilities(
      canAnalyze: true,
      canClearCache: true,
      canClearTemporary: true,
      canPrefetch: true,
      canAccessUserSelectedFiles: false,
      canShowExactPaths: true,
    );
  }
}

void main() {
  test('getStorageInfo', () async {
    MockFlutterStorageManagerPlatform fakePlatform =
        MockFlutterStorageManagerPlatform();
    FlutterStorageManagerPlatform.instance = fakePlatform;

    final info = await FlutterStorageManager.instance.getStorageInfo();
    expect(info.totalBytes, 1000);
    expect(info.usedBytes, 500);
  });

  test('analyzeStorage', () async {
    MockFlutterStorageManagerPlatform fakePlatform =
        MockFlutterStorageManagerPlatform();
    FlutterStorageManagerPlatform.instance = fakePlatform;

    final analysis = await FlutterStorageManager.instance.analyzeStorage();
    expect(analysis.totalCleanableBytes, 50);
    expect(analysis.categories.first.category, StorageCategory.cache);
  });
}
