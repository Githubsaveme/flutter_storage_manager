import 'enums.dart';

class StorageItem {
  final String id;
  final String name;
  final String path;
  final int sizeBytes;
  final StorageCategory category;
  final DateTime? createdAt;
  final DateTime? modifiedAt;
  final bool canDelete;
  final bool isDirectory;

  StorageItem({
    required this.id,
    required this.name,
    required this.path,
    required this.sizeBytes,
    required this.category,
    this.createdAt,
    this.modifiedAt,
    required this.canDelete,
    required this.isDirectory,
  });

  String get formattedSize {
    if (sizeBytes < 1024) {
      return '$sizeBytes B';
    }
    if (sizeBytes < 1024 * 1024) {
      return '${(sizeBytes / 1024).toStringAsFixed(1)} KB';
    }
    if (sizeBytes < 1024 * 1024 * 1024) {
      return '${(sizeBytes / (1024 * 1024)).toStringAsFixed(1)} MB';
    }
    if (sizeBytes < 1024 * 1024 * 1024 * 1024) {
      return '${(sizeBytes / (1024 * 1024 * 1024)).toStringAsFixed(1)} GB';
    }
    return '${(sizeBytes / (1024 * 1024 * 1024 * 1024)).toStringAsFixed(1)} TB';
  }

  factory StorageItem.fromMap(Map<dynamic, dynamic> map) {
    return StorageItem(
      id: map['id'] as String? ?? map['path'] as String,
      name: map['name'] as String,
      path: map['path'] as String,
      sizeBytes: map['sizeBytes'] as int,
      category: StorageCategory.values.firstWhere(
        (e) => e.name == map['category'],
        orElse: () => StorageCategory.pluginManaged,
      ),
      createdAt: map['createdAt'] != null
          ? DateTime.fromMillisecondsSinceEpoch(map['createdAt'] as int)
          : null,
      modifiedAt: map['modifiedAt'] != null
          ? DateTime.fromMillisecondsSinceEpoch(map['modifiedAt'] as int)
          : null,
      canDelete: map['canDelete'] as bool? ?? true,
      isDirectory: map['isDirectory'] as bool? ?? false,
    );
  }
}

class StorageInfo {
  final int? totalBytes;
  final int? usedBytes;
  final int? freeBytes;
  final int? appUsedBytes;
  final int? appCacheBytes;
  final double? usagePercentage;

  StorageInfo({
    this.totalBytes,
    this.usedBytes,
    this.freeBytes,
    this.appUsedBytes,
    this.appCacheBytes,
    this.usagePercentage,
  });

  factory StorageInfo.fromMap(Map<dynamic, dynamic> map) {
    return StorageInfo(
      totalBytes: map['totalBytes'] as int?,
      usedBytes: map['usedBytes'] as int?,
      freeBytes: map['freeBytes'] as int?,
      appUsedBytes: map['appUsedBytes'] as int?,
      appCacheBytes: map['appCacheBytes'] as int?,
      usagePercentage: map['usagePercentage'] as double?,
    );
  }
}

class StorageCategoryInfo {
  final StorageCategory category;
  final int sizeBytes;
  final int itemCount;

  StorageCategoryInfo({
    required this.category,
    required this.sizeBytes,
    required this.itemCount,
  });

  factory StorageCategoryInfo.fromMap(Map<dynamic, dynamic> map) {
    return StorageCategoryInfo(
      category: StorageCategory.values.firstWhere(
        (e) => e.name == map['category'],
        orElse: () => StorageCategory.pluginManaged,
      ),
      sizeBytes: map['sizeBytes'] as int,
      itemCount: map['itemCount'] as int,
    );
  }
}

class StorageAnalysis {
  final List<StorageCategoryInfo> categories;
  final int totalCleanableBytes;
  final List<StorageItem> items;

  StorageAnalysis({
    required this.categories,
    required this.totalCleanableBytes,
    required this.items,
  });

  factory StorageAnalysis.fromMap(Map<dynamic, dynamic> map) {
    return StorageAnalysis(
      categories: (map['categories'] as List<dynamic>?)
              ?.map(
                (e) => StorageCategoryInfo.fromMap(e as Map<dynamic, dynamic>),
              )
              .toList() ??
          [],
      totalCleanableBytes: map['totalCleanableBytes'] as int? ?? 0,
      items: (map['items'] as List<dynamic>?)
              ?.map((e) => StorageItem.fromMap(e as Map<dynamic, dynamic>))
              .toList() ??
          [],
    );
  }
}

class CleanupPreview {
  final int itemCount;
  final int totalBytes;
  final List<StorageItem> items;

  CleanupPreview({
    required this.itemCount,
    required this.totalBytes,
    required this.items,
  });
}

class CleanupResult {
  final int deletedCount;
  final int failedCount;
  final int skippedCount;
  final int bytesFreed;
  final List<CleanupItemResult> results;

  CleanupResult({
    required this.deletedCount,
    required this.failedCount,
    required this.skippedCount,
    required this.bytesFreed,
    required this.results,
  });

  factory CleanupResult.fromMap(Map<dynamic, dynamic> map) {
    return CleanupResult(
      deletedCount: map['deletedCount'] as int? ?? 0,
      failedCount: map['failedCount'] as int? ?? 0,
      skippedCount: map['skippedCount'] as int? ?? 0,
      bytesFreed: map['bytesFreed'] as int? ?? 0,
      results: (map['results'] as List<dynamic>?)
              ?.map(
                (e) => CleanupItemResult.fromMap(e as Map<dynamic, dynamic>),
              )
              .toList() ??
          [],
    );
  }
}

class CleanupItemResult {
  final String path;
  final bool success;
  final int bytes;
  final StorageErrorCode? errorCode;
  final String? message;

  CleanupItemResult({
    required this.path,
    required this.success,
    required this.bytes,
    this.errorCode,
    this.message,
  });

  factory CleanupItemResult.fromMap(Map<dynamic, dynamic> map) {
    StorageErrorCode? code;
    if (map['errorCode'] != null) {
      code = StorageErrorCode.values.firstWhere(
        (e) => e.name == map['errorCode'],
        orElse: () => StorageErrorCode.unknown,
      );
    }
    return CleanupItemResult(
      path: map['path'] as String,
      success: map['success'] as bool? ?? false,
      bytes: map['bytes'] as int? ?? 0,
      errorCode: code,
      message: map['message'] as String?,
    );
  }
}

class DownloadProgress {
  final int receivedBytes;
  final int? totalBytes;
  final double? percentage;

  DownloadProgress({
    required this.receivedBytes,
    this.totalBytes,
    this.percentage,
  });
}

class CleanupProgress {
  final int processed;
  final int total;
  final String currentPath;
  final int bytesFreed;

  CleanupProgress({
    required this.processed,
    required this.total,
    required this.currentPath,
    required this.bytesFreed,
  });
}

class StorageCapabilities {
  final bool canAnalyze;
  final bool canClearCache;
  final bool canClearTemporary;
  final bool canPrefetch;
  final bool canAccessUserSelectedFiles;
  final bool canShowExactPaths;

  StorageCapabilities({
    required this.canAnalyze,
    required this.canClearCache,
    required this.canClearTemporary,
    required this.canPrefetch,
    required this.canAccessUserSelectedFiles,
    required this.canShowExactPaths,
  });

  factory StorageCapabilities.fromMap(Map<dynamic, dynamic> map) {
    return StorageCapabilities(
      canAnalyze: map['canAnalyze'] as bool? ?? true,
      canClearCache: map['canClearCache'] as bool? ?? true,
      canClearTemporary: map['canClearTemporary'] as bool? ?? true,
      canPrefetch: map['canPrefetch'] as bool? ?? true,
      canAccessUserSelectedFiles:
          map['canAccessUserSelectedFiles'] as bool? ?? false,
      canShowExactPaths: map['canShowExactPaths'] as bool? ?? true,
    );
  }
}
