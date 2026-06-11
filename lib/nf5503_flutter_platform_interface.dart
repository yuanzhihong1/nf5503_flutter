import 'package:plugin_platform_interface/plugin_platform_interface.dart';

import 'nf5503_flutter_method_channel.dart';

abstract class Nf5503FlutterPlatform extends PlatformInterface {
  /// Constructs a Nf5503FlutterPlatform.
  Nf5503FlutterPlatform() : super(token: _token);

  static final Object _token = Object();

  static Nf5503FlutterPlatform _instance = MethodChannelNf5503Flutter();

  /// The default instance of [Nf5503FlutterPlatform] to use.
  ///
  /// Defaults to [MethodChannelNf5503Flutter].
  static Nf5503FlutterPlatform get instance => _instance;

  /// Platform-specific implementations should set this with their own
  /// platform-specific class that extends [Nf5503FlutterPlatform] when
  /// they register themselves.
  static set instance(Nf5503FlutterPlatform instance) {
    PlatformInterface.verifyToken(instance, _token);
    _instance = instance;
  }

  Future<String?> getPlatformVersion() {
    throw UnimplementedError('platformVersion() has not been implemented.');
  }
}
