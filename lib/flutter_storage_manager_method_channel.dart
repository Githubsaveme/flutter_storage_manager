import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';

import 'flutter_storage_manager_platform_interface.dart';

/// An implementation of [FlutterStorageManagerPlatform] that uses method channels.
class MethodChannelFlutterStorageManager extends FlutterStorageManagerPlatform {
  /// The method channel used to interact with the native platform.
  @visibleForTesting
  final methodChannel = const MethodChannel('flutter_storage_manager');

  @override
  Future<String?> getPlatformVersion() async {
    final version = await methodChannel.invokeMethod<String>(
      'getPlatformVersion',
    );
    return version;
  }
}
