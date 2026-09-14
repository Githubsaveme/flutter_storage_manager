import Flutter
import UIKit

public class FlutterStorageManagerPlugin: NSObject, FlutterPlugin {
  private let queue = DispatchQueue(label: "com.example.flutter_storage_manager.queue", attributes: .concurrent)

  public static func register(with registrar: FlutterPluginRegistrar) {
    let channel = FlutterMethodChannel(name: "flutter_storage_manager", binaryMessenger: registrar.messenger())
    let instance = FlutterStorageManagerPlugin()
    registrar.addMethodCallDelegate(instance, channel: channel)
  }

  public func handle(_ call: FlutterMethodCall, result: @escaping FlutterResult) {
    queue.async {
      do {
        switch call.method {
        case "getStorageInfo":
          let info = try self.getStorageInfo()
          DispatchQueue.main.async { result(info) }
        case "analyzeStorage":
          let analysis = try self.analyzeStorage()
          DispatchQueue.main.async { result(analysis) }
        case "getItems":
          let args = call.arguments as? [String: Any]
          let category = args?["category"] as? String
          let items = try self.getItems(categoryStr: category)
          DispatchQueue.main.async { result(items) }
        case "deleteItems":
          let args = call.arguments as? [String: Any]
          let paths = args?["paths"] as? [String] ?? []
          let res = try self.deleteItems(paths: paths)
          DispatchQueue.main.async { result(res) }
        case "clearCategory":
          let args = call.arguments as? [String: Any]
          let category = args?["category"] as? String
          let res = try self.clearCategory(categoryStr: category)
          DispatchQueue.main.async { result(res) }
        case "clearAllManagedFiles":
          let res = try self.clearAllManagedFiles()
          DispatchQueue.main.async { result(res) }
        case "fileExists":
          let args = call.arguments as? [String: Any]
          let path = args?["path"] as? String ?? ""
          let exists = self.fileExists(path: path)
          DispatchQueue.main.async { result(exists) }
        case "getFileInfo":
          let args = call.arguments as? [String: Any]
          let path = args?["path"] as? String ?? ""
          let info = self.getFileInfo(path: path)
          DispatchQueue.main.async { result(info) }
        case "prefetchFile":
          let args = call.arguments as? [String: Any]
          let url = args?["url"] as? String ?? ""
          let fileName = args?["fileName"] as? String
          let categoryStr = args?["category"] as? String ?? "prefetched"
          let overwrite = args?["overwrite"] as? Bool ?? false
          try self.prefetchFile(urlStr: url, fileName: fileName, categoryStr: categoryStr, overwrite: overwrite)
          DispatchQueue.main.async { result(nil) }
        case "canDelete":
          let args = call.arguments as? [String: Any]
          let path = args?["path"] as? String ?? ""
          let can = self.isSafePath(path: path)
          DispatchQueue.main.async { result(can) }
        case "checkPermission", "requestPermission":
          DispatchQueue.main.async { result("notRequired") }
        case "getCapabilities":
          let caps: [String: Any] = [
            "canAnalyze": true,
            "canClearCache": true,
            "canClearTemporary": true,
            "canPrefetch": true,
            "canAccessUserSelectedFiles": false,
            "canShowExactPaths": true
          ]
          DispatchQueue.main.async { result(caps) }
        default:
          DispatchQueue.main.async { result(FlutterMethodNotImplemented) }
        }
      } catch {
        DispatchQueue.main.async {
          result(FlutterError(code: "unknown", message: error.localizedDescription, details: nil))
        }
      }
    }
  }

  private func getCategoryUrl(_ category: String) throws -> URL {
    let fm = FileManager.default
    let caches = try fm.url(for: .cachesDirectory, in: .userDomainMask, appropriateFor: nil, create: true)
    let appSupport = try fm.url(for: .applicationSupportDirectory, in: .userDomainMask, appropriateFor: nil, create: true)
    let temp = fm.temporaryDirectory

    var url: URL
    switch category {
    case "cache": url = caches
    case "temporary": url = temp.appendingPathComponent("flutter_storage_manager")
    case "prefetched": url = appSupport.appendingPathComponent("prefetched")
    case "downloads": url = appSupport.appendingPathComponent("downloads")
    case "generated": url = appSupport.appendingPathComponent("generated")
    case "thumbnails": url = caches.appendingPathComponent("thumbnails")
    case "pluginManaged": url = appSupport.appendingPathComponent("pluginManaged")
    default: url = appSupport.appendingPathComponent("pluginManaged")
    }

    if !fm.fileExists(atPath: url.path) {
      try fm.createDirectory(at: url, withIntermediateDirectories: true, attributes: nil)
    }
    return url
  }

  private func getAllowedRoots() throws -> [String] {
    let fm = FileManager.default
    let caches = try fm.url(for: .cachesDirectory, in: .userDomainMask, appropriateFor: nil, create: true)
    let appSupport = try fm.url(for: .applicationSupportDirectory, in: .userDomainMask, appropriateFor: nil, create: true)
    let temp = fm.temporaryDirectory

    return [
      caches.resolvingSymlinksInPath().path,
      appSupport.resolvingSymlinksInPath().path,
      temp.resolvingSymlinksInPath().path
    ]
  }

  private func isSafePath(path: String) -> Bool {
    let fm = FileManager.default
    let canonical = URL(fileURLWithPath: path).resolvingSymlinksInPath().path
    do {
      let roots = try getAllowedRoots()
      for root in roots {
        if canonical.hasPrefix(root) {
          return true
        }
      }
    } catch {
      return false
    }
    return false
  }

  private func getFolderSize(url: URL) -> Int {
    let fm = FileManager.default
    var size = 0
    if let enumerator = fm.enumerator(at: url, includingPropertiesForKeys: [.totalFileAllocatedSizeKey, .fileAllocatedSizeKey], options: []) {
      for case let fileURL as URL in enumerator {
        do {
          let resourceValues = try fileURL.resourceValues(forKeys: [.totalFileAllocatedSizeKey, .fileAllocatedSizeKey])
          size += resourceValues.totalFileAllocatedSize ?? resourceValues.fileAllocatedSize ?? 0
        } catch { }
      }
    }
    return size
  }

  private func fileToMap(url: URL, category: String) -> [String: Any]? {
    let fm = FileManager.default
    do {
      let attrs = try fm.attributesOfItem(atPath: url.path)
      let isDir = (attrs[.type] as? FileAttributeType) == .typeDirectory
      let size = isDir ? getFolderSize(url: url) : (attrs[.size] as? Int ?? 0)

      return [
        "id": url.path,
        "name": url.lastPathComponent,
        "path": url.path,
        "sizeBytes": size,
        "category": category,
        "createdAt": (attrs[.creationDate] as? Date)?.timeIntervalSince1970 ?? 0 * 1000,
        "modifiedAt": (attrs[.modificationDate] as? Date)?.timeIntervalSince1970 ?? 0 * 1000,
        "canDelete": true,
        "isDirectory": isDir
      ]
    } catch {
      return nil
    }
  }

  private func getStorageInfo() throws -> [String: Any] {
    let fm = FileManager.default
    let caches = try fm.url(for: .cachesDirectory, in: .userDomainMask, appropriateFor: nil, create: true)
    let appSupport = try fm.url(for: .applicationSupportDirectory, in: .userDomainMask, appropriateFor: nil, create: true)

    let sysAttrs = try fm.attributesOfFileSystem(forPath: caches.path)
    let totalBytes = sysAttrs[.systemSize] as? Int ?? 0
    let freeBytes = sysAttrs[.systemFreeSize] as? Int ?? 0
    let usedBytes = totalBytes - freeBytes

    let appCacheBytes = getFolderSize(url: caches)
    let appUsedBytes = appCacheBytes + getFolderSize(url: appSupport)

    return [
      "totalBytes": totalBytes,
      "usedBytes": usedBytes,
      "freeBytes": freeBytes,
      "appUsedBytes": appUsedBytes,
      "appCacheBytes": appCacheBytes,
      "usagePercentage": totalBytes > 0 ? (Double(usedBytes) / Double(totalBytes)) * 100.0 : 0.0
    ]
  }

  private func analyzeStorage() throws -> [String: Any] {
    let categories = ["cache", "temporary", "prefetched", "downloads", "generated", "thumbnails", "pluginManaged"]
    var catInfos = [[String: Any]]()
    var allItems = [[String: Any]]()
    var totalCleanable = 0
    let fm = FileManager.default

    for cat in categories {
      let url = try getCategoryUrl(cat)
      var size = 0
      var count = 0

      if let contents = try? fm.contentsOfDirectory(at: url, includingPropertiesForKeys: nil, options: .skipsHiddenFiles) {
        for fileUrl in contents {
          if fileUrl.lastPathComponent == "thumbnails" || fileUrl.lastPathComponent == "flutter_storage_manager" {
            continue
          }
          if let map = fileToMap(url: fileUrl, category: cat) {
            allItems.append(map)
            size += map["sizeBytes"] as? Int ?? 0
            count += 1
          }
        }
      }
      totalCleanable += size
      catInfos.append([
        "category": cat,
        "sizeBytes": size,
        "itemCount": count
      ])
    }

    return [
      "categories": catInfos,
      "totalCleanableBytes": totalCleanable,
      "items": allItems
    ]
  }

  private func getItems(categoryStr: String?) throws -> [[String: Any]] {
    var items = [[String: Any]]()
    let fm = FileManager.default

    if let cat = categoryStr {
      let url = try getCategoryUrl(cat)
      if let contents = try? fm.contentsOfDirectory(at: url, includingPropertiesForKeys: nil, options: .skipsHiddenFiles) {
        for fileUrl in contents {
          if let map = fileToMap(url: fileUrl, category: cat) {
            items.append(map)
          }
        }
      }
    } else {
      let categories = ["cache", "temporary", "prefetched", "downloads", "generated", "thumbnails", "pluginManaged"]
      for cat in categories {
        let url = try getCategoryUrl(cat)
        if let contents = try? fm.contentsOfDirectory(at: url, includingPropertiesForKeys: nil, options: .skipsHiddenFiles) {
          for fileUrl in contents {
            if fileUrl.lastPathComponent == "thumbnails" || fileUrl.lastPathComponent == "flutter_storage_manager" {
              continue
            }
            if let map = fileToMap(url: fileUrl, category: cat) {
              items.append(map)
            }
          }
        }
      }
    }
    return items
  }

  private func deleteItems(paths: [String]) throws -> [String: Any] {
    let fm = FileManager.default
    var deletedCount = 0
    var failedCount = 0
    var skippedCount = 0
    var bytesFreed = 0
    var results = [[String: Any]]()

    for path in paths {
      if !fm.fileExists(atPath: path) {
        skippedCount += 1
        results.append(["path": path, "success": false, "bytes": 0, "errorCode": "fileNotFound", "message": "File does not exist"])
        continue
      }
      if !isSafePath(path: path) {
        skippedCount += 1
        results.append(["path": path, "success": false, "bytes": 0, "errorCode": "accessDenied", "message": "Path is outside allowed directories"])
        continue
      }

      let url = URL(fileURLWithPath: path)
      let attrs = try? fm.attributesOfItem(atPath: path)
      let isDir = (attrs?[.type] as? FileAttributeType) == .typeDirectory
      let size = isDir ? getFolderSize(url: url) : (attrs?[.size] as? Int ?? 0)

      do {
        try fm.removeItem(at: url)
        deletedCount += 1
        bytesFreed += size
        results.append(["path": path, "success": true, "bytes": size])
      } catch {
        failedCount += 1
        results.append(["path": path, "success": false, "bytes": 0, "errorCode": "ioError", "message": error.localizedDescription])
      }
    }

    return [
      "deletedCount": deletedCount,
      "failedCount": failedCount,
      "skippedCount": skippedCount,
      "bytesFreed": bytesFreed,
      "results": results
    ]
  }

  private func clearCategory(categoryStr: String?) throws -> [String: Any] {
    guard let cat = categoryStr else { return [:] }
    let url = try getCategoryUrl(cat)
    let fm = FileManager.default
    var paths = [String]()

    if let contents = try? fm.contentsOfDirectory(at: url, includingPropertiesForKeys: nil, options: .skipsHiddenFiles) {
      for fileUrl in contents {
        paths.append(fileUrl.path)
      }
    }
    return try deleteItems(paths: paths)
  }

  private func clearAllManagedFiles() throws -> [String: Any] {
    let categories = ["cache", "temporary", "prefetched", "downloads", "generated", "thumbnails", "pluginManaged"]
    var paths = [String]()
    let fm = FileManager.default

    for cat in categories {
      let url = try getCategoryUrl(cat)
      if let contents = try? fm.contentsOfDirectory(at: url, includingPropertiesForKeys: nil, options: .skipsHiddenFiles) {
        for fileUrl in contents {
          if fileUrl.lastPathComponent == "thumbnails" || fileUrl.lastPathComponent == "flutter_storage_manager" {
            continue
          }
          paths.append(fileUrl.path)
        }
      }
    }
    return try deleteItems(paths: paths)
  }

  private func fileExists(path: String) -> Bool {
    return FileManager.default.fileExists(atPath: path) && isSafePath(path: path)
  }

  private func getFileInfo(path: String) -> [String: Any]? {
    if !fileExists(path: path) { return nil }
    return fileToMap(url: URL(fileURLWithPath: path), category: "pluginManaged")
  }

  private func prefetchFile(urlStr: String, fileName: String?, categoryStr: String, overwrite: Bool) throws {
    guard let url = URL(string: urlStr) else { throw NSError(domain: "", code: -1, userInfo: nil) }
    let dir = try getCategoryUrl(categoryStr)
    let safeFileName = fileName ?? url.lastPathComponent
    let dest = dir.appendingPathComponent(safeFileName == "" ? "downloaded_file" : safeFileName)

    let fm = FileManager.default
    if fm.fileExists(atPath: dest.path) && !overwrite {
      return
    }

    let semaphore = DispatchSemaphore(value: 0)
    var downloadError: Error?

    let task = URLSession.shared.downloadTask(with: url) { tempLocalUrl, response, error in
      if let error = error {
        downloadError = error
      } else if let tempLocalUrl = tempLocalUrl {
        do {
          if fm.fileExists(atPath: dest.path) {
            try fm.removeItem(at: dest)
          }
          try fm.moveItem(at: tempLocalUrl, to: dest)
        } catch let e {
          downloadError = e
        }
      }
      semaphore.signal()
    }

    task.resume()
    semaphore.wait()

    if let error = downloadError {
      throw error
    }
  }
}
