
import 'nf5503_flutter_platform_interface.dart';

class Nf5503Flutter {
  Future<String?> getPlatformVersion() {
    return Nf5503FlutterPlatform.instance.getPlatformVersion();
  }
}
