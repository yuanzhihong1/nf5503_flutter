import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:nf5503_flutter/nf5503_flutter.dart';
import 'package:nf5503_flutter/nf5503_flutter_method_channel.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  MethodChannelNf5503Flutter platform = MethodChannelNf5503Flutter();
  const MethodChannel channel = MethodChannel('nf5503_flutter');
  final methodCalls = <MethodCall>[];

  setUp(() {
    methodCalls.clear();
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(channel, (MethodCall methodCall) async {
          methodCalls.add(methodCall);
          return switch (methodCall.method) {
            'getPlatformVersion' => '42',
            'scanner.open' => true,
            'scanner.getOutputMode' => 2,
            'printer.getFontSize' => 5,
            _ => null,
          };
        });
  });

  tearDown(() {
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(channel, null);
  });

  test('getPlatformVersion', () async {
    expect(await platform.getPlatformVersion(), '42');
  });

  test('scannerOpen invokes scanner channel method', () async {
    expect(await platform.scannerOpen(), true);
    expect(methodCalls.single.method, 'scanner.open');
  });

  test('scannerSetOutputMode passes official SDK value', () async {
    await platform.scannerSetOutputMode(Nf5503ScanOutputMode.clipboard);

    expect(methodCalls.single.method, 'scanner.setOutputMode');
    expect(methodCalls.single.arguments, <String, Object?>{'mode': 4});
  });

  test('scannerGetOutputMode maps official SDK value', () async {
    expect(
      await platform.scannerGetOutputMode(),
      Nf5503ScanOutputMode.keyboard,
    );
  });

  test('printerAddText passes text options', () async {
    await platform.printerAddText(
      'hello',
      align: Nf5503PrintAlign.center,
      fontSize: Nf5503PrintFontSize.large,
      isBold: true,
      isUnderline: true,
    );

    expect(methodCalls.single.method, 'printer.addText');
    expect(methodCalls.single.arguments, <String, Object?>{
      'content': 'hello',
      'align': 2,
      'fontSize': 5,
      'isBold': true,
      'isUnderline': true,
    });
  });

  test('printerGetFontSize maps official SDK value', () async {
    expect(await platform.printerGetFontSize(), Nf5503PrintFontSize.large);
  });
}
