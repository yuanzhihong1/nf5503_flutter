import 'package:flutter_test/flutter_test.dart';
import 'package:nf5503_flutter/nf5503_flutter.dart';
import 'package:nf5503_flutter/nf5503_flutter_platform_interface.dart';
import 'package:nf5503_flutter/nf5503_flutter_method_channel.dart';
import 'package:plugin_platform_interface/plugin_platform_interface.dart';

class MockNf5503FlutterPlatform
    with MockPlatformInterfaceMixin
    implements Nf5503FlutterPlatform {
  @override
  Future<String?> getPlatformVersion() => Future.value('42');

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

void main() {
  final Nf5503FlutterPlatform initialPlatform = Nf5503FlutterPlatform.instance;

  test('$MethodChannelNf5503Flutter is the default instance', () {
    expect(initialPlatform, isInstanceOf<MethodChannelNf5503Flutter>());
  });

  test('getPlatformVersion', () async {
    Nf5503Flutter nf5503FlutterPlugin = Nf5503Flutter();
    MockNf5503FlutterPlatform fakePlatform = MockNf5503FlutterPlatform();
    Nf5503FlutterPlatform.instance = fakePlatform;

    expect(await nf5503FlutterPlugin.getPlatformVersion(), '42');
  });

  test('exposes scanner and printer facades', () {
    final nf5503FlutterPlugin = Nf5503Flutter();

    expect(nf5503FlutterPlugin.scanner, isA<Nf5503Scanner>());
    expect(nf5503FlutterPlugin.printer, isA<Nf5503Printer>());
  });
}
