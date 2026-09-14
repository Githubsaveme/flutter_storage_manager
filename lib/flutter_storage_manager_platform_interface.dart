import 'package:plugin_platform_interface/plugin_platform_interface.dart';

import 'flutter_storage_manager_method_channel.dart';

abstract class FlutterStorageManagerPlatform extends PlatformInterface {
  /// Constructs a FlutterStorageManagerPlatform.
  FlutterStorageManagerPlatform() : super(token: _token);

  static final Object _token = Object();

  static FlutterStorageManagerPlatform _instance =
      MethodChannelFlutterStorageManager();

  /// The default instance of [FlutterStorageManagerPlatform] to use.
  ///
  /// Defaults to [MethodChannelFlutterStorageManager].
  static FlutterStorageManagerPlatform get instance => _instance;

  /// Platform-specific implementations should set this with their own
  /// platform-specific class that extends [FlutterStorageManagerPlatform] when
  /// they register themselves.
  static set instance(FlutterStorageManagerPlatform instance) {
    PlatformInterface.verifyToken(instance, _token);
    _instance = instance;
  }

  Future<String?> getPlatformVersion() {
    throw UnimplementedError('platformVersion() has not been implemented.');
  }
}
