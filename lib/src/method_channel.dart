import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'platform_interface.dart';
import 'models.dart';
import 'enums.dart';
import 'exceptions.dart';

class MethodChannelFlutterStorageManager extends FlutterStorageManagerPlatform {
  @visibleForTesting
  final methodChannel = const MethodChannel('flutter_storage_manager');

  @visibleForTesting
  final eventChannel = const EventChannel('flutter_storage_manager/events');

  StorageException _mapException(PlatformException e) {
    final codeStr = e.code;
    final message = e.message ?? 'Unknown error';
    final details = e.details;
    final path = details is Map ? details['path'] as String? : null;

    final code = StorageErrorCode.values.firstWhere(
      (c) => c.name == codeStr,
      orElse: () => StorageErrorCode.unknown,
    );

    switch (code) {
      case StorageErrorCode.permissionDenied:
        return PermissionException(message, path: path, details: details);
      case StorageErrorCode.fileNotFound:
        return FileNotFoundException(message, path: path, details: details);
      case StorageErrorCode.accessDenied:
        return FileAccessException(message, path: path, details: details);
      case StorageErrorCode.ioError:
        return FileDeletionException(message, path: path, details: details);
      case StorageErrorCode.invalidPath:
        return InvalidPathException(message, path: path, details: details);
      case StorageErrorCode.networkError:
        return NetworkException(message, path: path, details: details);
      case StorageErrorCode.unsupported:
        return UnsupportedOperationException(
          message,
          path: path,
          details: details,
        );
      default:
        return StorageException(code, message, path: path, details: details);
    }
  }

  @override
  Future<StorageInfo> getStorageInfo() async {
    try {
      final result = await methodChannel.invokeMapMethod<String, dynamic>(
        'getStorageInfo',
      );
      return StorageInfo.fromMap(result!);
    } on PlatformException catch (e) {
      throw _mapException(e);
    }
  }

  @override
  Future<StorageAnalysis> analyzeStorage() async {
    try {
      final result = await methodChannel.invokeMapMethod<String, dynamic>(
        'analyzeStorage',
      );
      return StorageAnalysis.fromMap(result!);
    } on PlatformException catch (e) {
      throw _mapException(e);
    }
  }

  @override
  Future<List<StorageItem>> getItems({StorageCategory? category}) async {
    try {
      final result =
          await methodChannel.invokeListMethod<Map<dynamic, dynamic>>(
        'getItems',
        category != null ? {'category': category.name} : null,
      );
      return result?.map((e) => StorageItem.fromMap(e)).toList() ?? [];
    } on PlatformException catch (e) {
      throw _mapException(e);
    }
  }

  @override
  Future<CleanupResult> deleteItems(List<String> paths) async {
    try {
      final result = await methodChannel.invokeMapMethod<String, dynamic>(
        'deleteItems',
        {'paths': paths},
      );
      return CleanupResult.fromMap(result!);
    } on PlatformException catch (e) {
      throw _mapException(e);
    }
  }

  @override
  Future<CleanupResult> clearCategory(StorageCategory category) async {
    try {
      final result = await methodChannel.invokeMapMethod<String, dynamic>(
        'clearCategory',
        {'category': category.name},
      );
      return CleanupResult.fromMap(result!);
    } on PlatformException catch (e) {
      throw _mapException(e);
    }
  }

  @override
  Future<CleanupResult> clearSelected(List<StorageItem> items) async {
    return deleteItems(items.map((e) => e.path).toList());
  }

  @override
  Future<CleanupResult> clearAllManagedFiles() async {
    try {
      final result = await methodChannel.invokeMapMethod<String, dynamic>(
        'clearAllManagedFiles',
      );
      return CleanupResult.fromMap(result!);
    } on PlatformException catch (e) {
      throw _mapException(e);
    }
  }

  @override
  Future<bool> fileExists(String path) async {
    try {
      final result = await methodChannel.invokeMethod<bool>('fileExists', {
        'path': path,
      });
      return result ?? false;
    } on PlatformException catch (e) {
      throw _mapException(e);
    }
  }

  @override
  Future<StorageItem?> getFileInfo(String path) async {
    try {
      final result = await methodChannel.invokeMapMethod<String, dynamic>(
        'getFileInfo',
        {'path': path},
      );
      if (result == null) return null;
      return StorageItem.fromMap(result);
    } on PlatformException catch (e) {
      throw _mapException(e);
    }
  }

  @override
  Future<void> prefetchFile(
    Uri url, {
    String? fileName,
    StorageCategory category = StorageCategory.prefetched,
    bool overwrite = false,
  }) async {
    try {
      await methodChannel.invokeMethod('prefetchFile', {
        'url': url.toString(),
        'fileName': fileName,
        'category': category.name,
        'overwrite': overwrite,
      });
    } on PlatformException catch (e) {
      throw _mapException(e);
    }
  }

  @override
  Stream<DownloadProgress> prefetchProgress(String taskId) {
    return eventChannel.receiveBroadcastStream({'taskId': taskId}).map((event) {
      final map = event as Map<dynamic, dynamic>;
      return DownloadProgress(
        receivedBytes: map['receivedBytes'] as int,
        totalBytes: map['totalBytes'] as int?,
        percentage: map['percentage'] as double?,
      );
    });
  }

  @override
  Future<void> cancelPrefetch(String taskId) async {
    try {
      await methodChannel.invokeMethod('cancelPrefetch', {'taskId': taskId});
    } on PlatformException catch (e) {
      throw _mapException(e);
    }
  }

  @override
  Future<CleanupPreview> previewCleanup({
    List<StorageCategory>? categories,
  }) async {
    try {
      final items = <StorageItem>[];
      int totalBytes = 0;

      final catsToPreview = categories ?? StorageCategory.values;
      for (var cat in catsToPreview) {
        final catItems = await getItems(category: cat);
        items.addAll(catItems);
      }

      for (var item in items) {
        totalBytes += item.sizeBytes;
      }

      return CleanupPreview(
        itemCount: items.length,
        totalBytes: totalBytes,
        items: items,
      );
    } catch (e) {
      rethrow;
    }
  }

  @override
  Future<bool> canDelete(String path) async {
    try {
      final result = await methodChannel.invokeMethod<bool>('canDelete', {
        'path': path,
      });
      return result ?? false;
    } on PlatformException catch (e) {
      throw _mapException(e);
    }
  }

  @override
  Future<StoragePermissionStatus> checkPermission() async {
    try {
      final result = await methodChannel.invokeMethod<String>(
        'checkPermission',
      );
      return StoragePermissionStatus.values.firstWhere(
        (e) => e.name == result,
        orElse: () => StoragePermissionStatus.notRequired,
      );
    } on PlatformException catch (e) {
      throw _mapException(e);
    }
  }

  @override
  Future<StoragePermissionStatus> requestPermission() async {
    try {
      final result = await methodChannel.invokeMethod<String>(
        'requestPermission',
      );
      return StoragePermissionStatus.values.firstWhere(
        (e) => e.name == result,
        orElse: () => StoragePermissionStatus.notRequired,
      );
    } on PlatformException catch (e) {
      throw _mapException(e);
    }
  }

  @override
  Future<StorageCapabilities> getCapabilities() async {
    try {
      final result = await methodChannel.invokeMapMethod<String, dynamic>(
        'getCapabilities',
      );
      return StorageCapabilities.fromMap(result!);
    } on PlatformException catch (e) {
      throw _mapException(e);
    }
  }
}
