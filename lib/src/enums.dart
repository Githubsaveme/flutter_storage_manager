/// Categories of storage managed by the plugin.
enum StorageCategory {
  cache,
  temporary,
  prefetched,
  downloads,
  generated,
  thumbnails,
  pluginManaged,
}

/// Strongly typed error codes for storage operations.
enum StorageErrorCode {
  permissionDenied,
  fileNotFound,
  accessDenied,
  protectedFile,
  invalidPath,
  ioError,
  insufficientStorage,
  networkError,
  timeout,
  cancelled,
  unsupported,
  unknown,
}

/// Permissions related to storage (mostly for accessing external/user directories).
enum StoragePermissionStatus {
  granted,
  denied,
  permanentlyDenied,
  restricted,
  notRequired,
}
