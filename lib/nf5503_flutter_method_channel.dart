import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';

import 'nf5503_flutter_platform_interface.dart';

/// An implementation of [Nf5503FlutterPlatform] that uses method channels.
class MethodChannelNf5503Flutter extends Nf5503FlutterPlatform {
  /// The method channel used to interact with the native platform.
  @visibleForTesting
  final methodChannel = const MethodChannel('nf5503_flutter');

  @override
  Future<String?> getPlatformVersion() async {
    final version = await methodChannel.invokeMethod<String>(
      'getPlatformVersion',
    );
    return version;
  }
}
