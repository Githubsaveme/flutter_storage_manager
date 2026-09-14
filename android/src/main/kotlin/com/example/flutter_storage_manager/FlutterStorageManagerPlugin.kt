package com.example.flutter_storage_manager

import android.content.Context
import android.os.Build
import android.os.Environment
import android.os.StatFs
import io.flutter.embedding.engine.plugins.FlutterPlugin
import io.flutter.plugin.common.MethodCall
import io.flutter.plugin.common.MethodChannel
import io.flutter.plugin.common.MethodChannel.MethodCallHandler
import io.flutter.plugin.common.MethodChannel.Result
import kotlinx.coroutines.*
import java.io.File
import java.io.FileOutputStream
import java.net.HttpURLConnection
import java.net.URL

class FlutterStorageManagerPlugin: FlutterPlugin, MethodCallHandler {
  private lateinit var channel : MethodChannel
  private lateinit var context: Context
  private val scope = CoroutineScope(Dispatchers.IO + SupervisorJob())
  private val downloadJobs = mutableMapOf<String, Job>()

  override fun onAttachedToEngine(flutterPluginBinding: FlutterPlugin.FlutterPluginBinding) {
    channel = MethodChannel(flutterPluginBinding.binaryMessenger, "flutter_storage_manager")
    channel.setMethodCallHandler(this)
    context = flutterPluginBinding.applicationContext
  }

  override fun onMethodCall(call: MethodCall, result: Result) {
    when (call.method) {
      "getStorageInfo" -> scope.launch {
        try {
          val info = getStorageInfo()
          withContext(Dispatchers.Main) { result.success(info) }
        } catch (e: Exception) {
          withContext(Dispatchers.Main) { result.error("unknown", e.message, null) }
        }
      }
      "analyzeStorage" -> scope.launch {
        try {
          val analysis = analyzeStorage()
          withContext(Dispatchers.Main) { result.success(analysis) }
        } catch (e: Exception) {
          withContext(Dispatchers.Main) { result.error("unknown", e.message, null) }
        }
      }
      "getItems" -> scope.launch {
        val categoryStr = call.argument<String>("category")
        try {
          val items = getItems(categoryStr)
          withContext(Dispatchers.Main) { result.success(items) }
        } catch (e: Exception) {
          withContext(Dispatchers.Main) { result.error("unknown", e.message, null) }
        }
      }
      "deleteItems" -> scope.launch {
        val paths = call.argument<List<String>>("paths") ?: emptyList()
        try {
          val res = deleteItems(paths)
          withContext(Dispatchers.Main) { result.success(res) }
        } catch (e: Exception) {
          withContext(Dispatchers.Main) { result.error("unknown", e.message, null) }
        }
      }
      "clearCategory" -> scope.launch {
        val categoryStr = call.argument<String>("category")
        try {
          val res = clearCategory(categoryStr)
          withContext(Dispatchers.Main) { result.success(res) }
        } catch (e: Exception) {
          withContext(Dispatchers.Main) { result.error("unknown", e.message, null) }
        }
      }
      "clearAllManagedFiles" -> scope.launch {
        try {
          val res = clearAllManagedFiles()
          withContext(Dispatchers.Main) { result.success(res) }
        } catch (e: Exception) {
          withContext(Dispatchers.Main) { result.error("unknown", e.message, null) }
        }
      }
      "fileExists" -> scope.launch {
        val path = call.argument<String>("path") ?: ""
        try {
          val exists = fileExists(path)
          withContext(Dispatchers.Main) { result.success(exists) }
        } catch (e: Exception) {
          withContext(Dispatchers.Main) { result.error("unknown", e.message, null) }
        }
      }
      "getFileInfo" -> scope.launch {
        val path = call.argument<String>("path") ?: ""
        try {
          val info = getFileInfo(path)
          withContext(Dispatchers.Main) { result.success(info) }
        } catch (e: Exception) {
          withContext(Dispatchers.Main) { result.error("unknown", e.message, null) }
        }
      }
      "prefetchFile" -> scope.launch {
        val urlStr = call.argument<String>("url") ?: ""
        val fileName = call.argument<String>("fileName")
        val categoryStr = call.argument<String>("category") ?: "prefetched"
        val overwrite = call.argument<Boolean>("overwrite") ?: false
        try {
          prefetchFile(urlStr, fileName, categoryStr, overwrite)
          withContext(Dispatchers.Main) { result.success(null) }
        } catch (e: Exception) {
          withContext(Dispatchers.Main) { result.error("networkError", e.message, null) }
        }
      }
      "canDelete" -> scope.launch {
        val path = call.argument<String>("path") ?: ""
        try {
          val can = isSafePath(File(path))
          withContext(Dispatchers.Main) { result.success(can) }
        } catch (e: Exception) {
          withContext(Dispatchers.Main) { result.error("unknown", e.message, null) }
        }
      }
      "checkPermission", "requestPermission" -> {
        // We only use internal app dirs, so permission is not required on any modern Android.
        result.success("notRequired")
      }
      "getCapabilities" -> {
        result.success(mapOf(
          "canAnalyze" to true,
          "canClearCache" to true,
          "canClearTemporary" to true,
          "canPrefetch" to true,
          "canAccessUserSelectedFiles" to false,
          "canShowExactPaths" to true
        ))
      }
      else -> result.notImplemented()
    }
  }

  private fun getCategoryDir(category: String): File {
    return when (category) {
      "cache" -> context.cacheDir
      "temporary" -> File(context.cacheDir, "temporary").apply { mkdirs() }
      "prefetched" -> File(context.filesDir, "prefetched").apply { mkdirs() }
      "downloads" -> File(context.filesDir, "downloads").apply { mkdirs() }
      "generated" -> File(context.filesDir, "generated").apply { mkdirs() }
      "thumbnails" -> File(context.cacheDir, "thumbnails").apply { mkdirs() }
      "pluginManaged" -> File(context.filesDir, "pluginManaged").apply { mkdirs() }
      else -> File(context.filesDir, "pluginManaged").apply { mkdirs() }
    }
  }

  private fun getAllowedRoots(): List<String> {
    return listOf(
      context.cacheDir.canonicalPath,
      context.filesDir.canonicalPath
    )
  }

  private fun isSafePath(file: File): Boolean {
    val canonicalPath = file.canonicalPath
    for (root in getAllowedRoots()) {
      if (canonicalPath.startsWith(root)) {
        return true
      }
    }
    return false
  }

  private fun fileToMap(file: File, category: String): Map<String, Any?> {
    return mapOf(
      "id" to file.canonicalPath,
      "name" to file.name,
      "path" to file.canonicalPath,
      "sizeBytes" to (if (file.isDirectory) getFolderSize(file) else file.length()),
      "category" to category,
      "createdAt" to file.lastModified(), // Android doesn't expose creation time easily
      "modifiedAt" to file.lastModified(),
      "canDelete" to true,
      "isDirectory" to file.isDirectory
    )
  }

  private fun getFolderSize(folder: File): Long {
    var length: Long = 0
    folder.listFiles()?.forEach { file ->
      length += if (file.isDirectory) getFolderSize(file) else file.length()
    }
    return length
  }

  private fun getStorageInfo(): Map<String, Any?> {
    val stat = StatFs(context.filesDir.path)
    val blockSize = stat.blockSizeLong
    val totalBlocks = stat.blockCountLong
    val availableBlocks = stat.availableBlocksLong

    val totalBytes = totalBlocks * blockSize
    val freeBytes = availableBlocks * blockSize
    val usedBytes = totalBytes - freeBytes

    val appUsedBytes = getFolderSize(context.filesDir) + getFolderSize(context.cacheDir)
    val appCacheBytes = getFolderSize(context.cacheDir)

    return mapOf(
      "totalBytes" to totalBytes,
      "usedBytes" to usedBytes,
      "freeBytes" to freeBytes,
      "appUsedBytes" to appUsedBytes,
      "appCacheBytes" to appCacheBytes,
      "usagePercentage" to if (totalBytes > 0) (usedBytes.toDouble() / totalBytes.toDouble()) * 100.0 else 0.0
    )
  }

  private fun analyzeStorage(): Map<String, Any?> {
    val categories = listOf("cache", "temporary", "prefetched", "downloads", "generated", "thumbnails", "pluginManaged")
    val catInfos = mutableListOf<Map<String, Any>>()
    val allItems = mutableListOf<Map<String, Any?>>()
    var totalCleanable = 0L

    for (cat in categories) {
      val dir = getCategoryDir(cat)
      var size = 0L
      var count = 0
      if (dir.exists()) {
        dir.listFiles()?.forEach { file ->
          if (file.name != "temporary" && file.name != "thumbnails") { // don't double count if inside cacheDir
             val fSize = if (file.isDirectory) getFolderSize(file) else file.length()
             size += fSize
             count += 1
             allItems.add(fileToMap(file, cat))
          }
        }
      }
      totalCleanable += size
      catInfos.add(mapOf(
        "category" to cat,
        "sizeBytes" to size,
        "itemCount" to count
      ))
    }

    return mapOf(
      "categories" to catInfos,
      "totalCleanableBytes" to totalCleanable,
      "items" to allItems
    )
  }

  private fun getItems(categoryStr: String?): List<Map<String, Any?>> {
    val items = mutableListOf<Map<String, Any?>>()
    if (categoryStr != null) {
      val dir = getCategoryDir(categoryStr)
      dir.listFiles()?.forEach { file ->
        items.add(fileToMap(file, categoryStr))
      }
    } else {
      val categories = listOf("cache", "temporary", "prefetched", "downloads", "generated", "thumbnails", "pluginManaged")
      for (cat in categories) {
        val dir = getCategoryDir(cat)
        dir.listFiles()?.forEach { file ->
           items.add(fileToMap(file, cat))
        }
      }
    }
    return items
  }

  private fun deleteItems(paths: List<String>): Map<String, Any?> {
    var deletedCount = 0
    var failedCount = 0
    var skippedCount = 0
    var bytesFreed = 0L
    val results = mutableListOf<Map<String, Any?>>()

    for (path in paths) {
      val file = File(path)
      if (!file.exists()) {
        skippedCount++
        results.add(mapOf("path" to path, "success" to false, "bytes" to 0, "errorCode" to "fileNotFound", "message" to "File does not exist"))
        continue
      }
      if (!isSafePath(file)) {
        skippedCount++
        results.add(mapOf("path" to path, "success" to false, "bytes" to 0, "errorCode" to "accessDenied", "message" to "Path is outside allowed directories"))
        continue
      }
      val size = if (file.isDirectory) getFolderSize(file) else file.length()
      val success = file.deleteRecursively()
      if (success) {
        deletedCount++
        bytesFreed += size
        results.add(mapOf("path" to path, "success" to true, "bytes" to size))
      } else {
        failedCount++
        results.add(mapOf("path" to path, "success" to false, "bytes" to 0, "errorCode" to "ioError", "message" to "Failed to delete file"))
      }
    }
    return mapOf(
      "deletedCount" to deletedCount,
      "failedCount" to failedCount,
      "skippedCount" to skippedCount,
      "bytesFreed" to bytesFreed,
      "results" to results
    )
  }

  private fun clearCategory(categoryStr: String?): Map<String, Any?> {
    if (categoryStr == null) return mapOf()
    val dir = getCategoryDir(categoryStr)
    val paths = dir.listFiles()?.map { it.absolutePath } ?: emptyList()
    return deleteItems(paths)
  }

  private fun clearAllManagedFiles(): Map<String, Any?> {
    val categories = listOf("cache", "temporary", "prefetched", "downloads", "generated", "thumbnails", "pluginManaged")
    val paths = mutableListOf<String>()
    for (cat in categories) {
      val dir = getCategoryDir(cat)
      dir.listFiles()?.forEach { file ->
        if (file.name != "temporary" && file.name != "thumbnails") { // Prevent deleting sub-category folders by mistake if scanning root
          paths.add(file.absolutePath)
        }
      }
    }
    return deleteItems(paths)
  }

  private fun fileExists(path: String): Boolean {
    val file = File(path)
    return file.exists() && isSafePath(file)
  }

  private fun getFileInfo(path: String): Map<String, Any?>? {
    val file = File(path)
    if (!file.exists() || !isSafePath(file)) return null
    return fileToMap(file, "pluginManaged") // Unknown cat
  }

  private fun prefetchFile(urlStr: String, fileName: String?, categoryStr: String, overwrite: Boolean) {
    val url = URL(urlStr)
    val dir = getCategoryDir(categoryStr)
    val safeFileName = fileName ?: urlStr.substringAfterLast("/").takeIf { it.isNotEmpty() } ?: "downloaded_file"
    val file = File(dir, safeFileName)
    
    if (file.exists() && !overwrite) {
      return
    }

    val connection = url.openConnection() as HttpURLConnection
    connection.requestMethod = "GET"
    connection.connectTimeout = 15000
    connection.readTimeout = 15000
    connection.connect()

    if (connection.responseCode != HttpURLConnection.HTTP_OK) {
      throw Exception("HTTP \${connection.responseCode}")
    }

    val input = connection.inputStream
    val output = FileOutputStream(file)

    try {
      val buffer = ByteArray(4096)
      var bytesRead: Int
      while (input.read(buffer).also { bytesRead = it } != -1) {
        output.write(buffer, 0, bytesRead)
      }
    } finally {
      output.close()
      input.close()
      connection.disconnect()
    }
  }

  override fun onDetachedFromEngine(binding: FlutterPlugin.FlutterPluginBinding) {
    channel.setMethodCallHandler(null)
    scope.cancel()
  }
}
