import 'enums.dart';

/// Base exception for all storage-related errors.
class StorageException implements Exception {
  final StorageErrorCode code;
  final String message;
  final String? path;
  final dynamic details;

  StorageException(this.code, this.message, {this.path, this.details});

  @override
  String toString() =>
      'StorageException($code): $message ${path != null ? "[\\$path]" : ""}';
}

class PermissionException extends StorageException {
  PermissionException(String message, {String? path, dynamic details})
      : super(StorageErrorCode.permissionDenied, message,
            path: path, details: details);
}

class FileNotFoundException extends StorageException {
  FileNotFoundException(String message, {String? path, dynamic details})
      : super(StorageErrorCode.fileNotFound, message,
            path: path, details: details);
}

class FileAccessException extends StorageException {
  FileAccessException(String message, {String? path, dynamic details})
      : super(StorageErrorCode.accessDenied, message,
            path: path, details: details);
}

class FileDeletionException extends StorageException {
  FileDeletionException(String message, {String? path, dynamic details})
      : super(StorageErrorCode.ioError, message, path: path, details: details);
}

class StorageUnavailableException extends StorageException {
  StorageUnavailableException(String message, {String? path, dynamic details})
      : super(StorageErrorCode.ioError, message, path: path, details: details);
}

class UnsupportedOperationException extends StorageException {
  UnsupportedOperationException(String message, {String? path, dynamic details})
      : super(StorageErrorCode.unsupported, message,
            path: path, details: details);
}

class InvalidPathException extends StorageException {
  InvalidPathException(String message, {String? path, dynamic details})
      : super(StorageErrorCode.invalidPath, message,
            path: path, details: details);
}

class NetworkException extends StorageException {
  NetworkException(String message, {String? path, dynamic details})
      : super(StorageErrorCode.networkError, message,
            path: path, details: details);
}

class DownloadException extends StorageException {
  DownloadException(String message, {String? path, dynamic details})
      : super(StorageErrorCode.networkError, message,
            path: path, details: details);
}

class AlreadyExistsException extends StorageException {
  AlreadyExistsException(String message, {String? path, dynamic details})
      : super(StorageErrorCode.ioError, message, path: path, details: details);
}
