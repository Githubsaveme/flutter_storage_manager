# flutter_storage_manager

[![pub package](https://img.shields.io/pub/v/flutter_storage_manager.svg)](https://pub.dev/packages/flutter_storage_manager)
[![license](https://img.shields.io/badge/license-MIT-blue.svg)](LICENSE)

A production-ready, security-first Flutter plugin for analyzing, categorizing, prefetching, and safely cleaning application-owned storage on **Android** and **iOS**.

---

## 🚀 Features

- 📊 **Storage Analysis**: Accurately calculate overall device storage, app-used storage, and cleanable bytes categorized by type.
- 📁 **Granular Category Management**: Manage `cache`, `temporary`, `prefetched`, `downloads`, `generated`, `thumbnails`, and custom `pluginManaged` files.
- 🔍 **Exact Safe File Paths**: Inspect actual on-disk file paths on Android Scoped Storage and iOS Sandbox bounds.
- 🛡️ **File-by-File Safety & Symlink Protection**: Prevents path traversal (`../`) and symbol link attacks. Individual file failures won't break bulk operations.
- ⚡ **Background Native Execution**: All filesystem scanning, calculations, and recursive deletions run asynchronously in background threads (Kotlin Coroutines / Swift DispatchQueue).
- 📥 **Native File Prefetching**: Fast background HTTPS file prefetching into designated app cache folders without memory overhead.
- 🔍 **Cleanup Preview**: Dry-run preview of files and total byte impact before asking users for deletion confirmation.
- 🛡️ **Zero Unnecessary Permissions**: Operates within app-owned directories requiring zero runtime permissions on Android 10+ and iOS.

---
##  App View
<img width="720" height="1280" alt="screenshot-1789382269401" src="https://github.com/user-attachments/assets/e2488842-f2af-4775-9bcd-5aa4cb969f7b" />

---
## 🔒 Security & Sandbox Guarantees

> [!IMPORTANT]
> This package strictly manages **application-owned and application-managed storage ONLY**. It does **NOT** and **CANNOT** access or clean arbitrary files belonging to other applications or system directories.

- **No Root or Jailbreak Required**: Works cleanly on standard production OS installations.
- **Strict Canonical Path Validation**: Every path is checked against native application sandbox boundaries (`context.cacheDir`, `context.filesDir`, `Library/Caches`, `Application Support`).
- **Symlink Protection**: Traversal via symbolic links pointing outside allowed application root directories is automatically detected and skipped.
- **No Overreaching Permissions**: Does not request `MANAGE_EXTERNAL_STORAGE` or broad device-wide access.

---

## 🛠️ Platform Support & Requirements

| Platform | Minimum Version | Permission Required for App Storage |
| :--- | :--- | :--- |
| **Android** | SDK 21 (Android 5.0+) | **None** (Uses Scoped Storage & Private Dirs) |
| **iOS** | iOS 12.0+ | **None** (Uses Standard App Sandbox) |

---

## 📦 Installation

Add `flutter_storage_manager` to your `pubspec.yaml`:

```yaml
dependencies:
  flutter_storage_manager: ^1.0.0
```

Then run:

```bash
flutter pub get
```

---

## 💻 Usage & Code Examples

### 1. Initialize & Retrieve Overall Storage Info

```dart
import 'package:flutter_storage_manager/flutter_storage_manager.dart';

final manager = FlutterStorageManager.instance;

// Get disk & app storage metrics
final StorageInfo info = await manager.getStorageInfo();

print('Total Device Bytes: ${info.totalBytes}');
print('Free Bytes: ${info.freeBytes}');
print('App Storage Used: ${info.appUsedBytes}');
print('App Cache Used: ${info.appCacheBytes}');
```

---

### 2. Analyze App Storage by Category

```dart
final StorageAnalysis analysis = await manager.analyzeStorage();

print('Total Cleanable Space: ${analysis.totalCleanableBytes} bytes');

for (final cat in analysis.categories) {
  print('Category: ${cat.category.name} | Size: ${cat.sizeBytes} bytes | Items: ${cat.itemCount}');
}

// Inspect cleanable files
for (final item in analysis.items) {
  print('${item.name} (${item.formattedSize}) at ${item.path}');
}
```

---

### 3. Preview Cleanup (Dry-Run)

Show users exactly what will be removed before performing destructive cleanup:

```dart
final CleanupPreview preview = await manager.previewCleanup(
  categories: [
    StorageCategory.cache,
    StorageCategory.temporary,
  ],
);

print('Will delete ${preview.itemCount} files totaling ${preview.totalBytes} bytes.');
```

---

### 4. Perform Category & Selected File Cleanup

```dart
// Option A: Clear an entire category (e.g. Cache)
final CleanupResult cacheResult = await manager.clearCategory(StorageCategory.cache);
print('Freed ${cacheResult.bytesFreed} bytes across ${cacheResult.deletedCount} files.');

// Option B: Delete specific items
final CleanupResult deleteResult = await manager.deleteItems([
  '/data/user/0/com.example.app/cache/thumbnails/thumb_01.jpg',
  '/data/user/0/com.example.app/cache/thumbnails/thumb_02.jpg',
]);

print('Deleted: ${deleteResult.deletedCount}, Failed: ${deleteResult.failedCount}, Skipped: ${deleteResult.skippedCount}');
```

---

### 5. Background File Prefetching

Prefetch large remote assets directly into managed app storage:

```dart
try {
  await manager.prefetchFile(
    Uri.parse('https://example.com/assets/video_cache.mp4'),
    fileName: 'intro_video.mp4',
    category: StorageCategory.prefetched,
    overwrite: true,
  );
  print('Prefetch completed successfully!');
} on StorageException catch (e) {
  print('Prefetch failed: ${e.message} (Code: ${e.code})');
}
```

---

### 6. Robust Error Handling

All errors return strongly-typed exceptions:

```dart
try {
  await manager.deleteItems(['/invalid/path']);
} on FileNotFoundException catch (e) {
  print('File not found: ${e.message}');
} on FileAccessException catch (e) {
  print('Access denied / security boundary violation: ${e.message}');
} on StorageException catch (e) {
  print('Storage error (${e.code}): ${e.message}');
}
```

---

## 🗂️ Storage Categories Reference

| Category | Android Directory Mapping | iOS Directory Mapping |
| :--- | :--- | :--- |
| `cache` | `context.cacheDir` | `Library/Caches` |
| `temporary` | `context.cacheDir/temporary` | `NSTemporaryDirectory()/flutter_storage_manager` |
| `prefetched` | `context.filesDir/prefetched` | `Application Support/prefetched` |
| `downloads` | `context.filesDir/downloads` | `Application Support/downloads` |
| `generated` | `context.filesDir/generated` | `Application Support/generated` |
| `thumbnails` | `context.cacheDir/thumbnails` | `Library/Caches/thumbnails` |
| `pluginManaged` | `context.filesDir/pluginManaged` | `Application Support/pluginManaged` |

---

## ❓ FAQ

#### Q: Can this plugin clean system storage or other installed apps?
**No.** Android and iOS operating system security rules prevent applications from deleting data outside their designated sandboxes.

#### Q: Does this require runtime storage permissions on Android?
**No.** Because all operations occur inside app-specific scoped storage directories (`context.cacheDir` & `context.filesDir`), no runtime permissions like `READ_EXTERNAL_STORAGE` or `MANAGE_EXTERNAL_STORAGE` are required.

#### Q: Is UI thread performance impacted during large cleanup?
**No.** Native scanning, size calculation, and recursive deletion operations execute asynchronously using Kotlin Coroutines on Android and concurrent `DispatchQueue` on iOS.

---

## 📄 License

This project is licensed under the MIT License - see the [LICENSE](LICENSE) file for details.
