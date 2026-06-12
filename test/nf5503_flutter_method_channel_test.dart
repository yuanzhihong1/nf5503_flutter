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
            'scanner.getDecodeMode' => 4,
            'scanner.getScannerType' => 33,
            'scanner.getSymbologyList' => <Map<String, Object?>>[
              <String, Object?>{'id': 1, 'name': 'CODE128'},
            ],
            'printer.getFontSize' => 5,
            'printer.getFontType' => 'default',
            'printer.setThreshold' => 0,
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

  test('scannerSetDecodeMode passes official SDK value', () async {
    await platform.scannerSetDecodeMode(Nf5503ScanDecodeMode.gb18030);

    expect(methodCalls.single.method, 'scanner.setDecodeMode');
    expect(methodCalls.single.arguments, <String, Object?>{'mode': 4});
  });

  test('scannerGetDecodeMode maps official SDK value', () async {
    expect(await platform.scannerGetDecodeMode(), Nf5503ScanDecodeMode.gb18030);
  });

  test('scannerGetScannerType maps official SDK value', () async {
    expect(await platform.scannerGetScannerType(), Nf5503ScannerType.n6603);
  });

  test('scannerGetSymbologyList maps raw object maps', () async {
    expect(await platform.scannerGetSymbologyList(), <Map<String, Object?>>[
      <String, Object?>{'id': 1, 'name': 'CODE128'},
    ]);
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

  test('printerSetFontType passes font type', () async {
    await platform.printerSetFontType('default');

    expect(methodCalls.single.method, 'printer.setFontType');
    expect(methodCalls.single.arguments, <String, Object?>{
      'fontType': 'default',
    });
  });

  test('printerSetThreshold passes threshold and returns state', () async {
    expect(await platform.printerSetThreshold(120), 0);

    expect(methodCalls.single.method, 'printer.setThreshold');
    expect(methodCalls.single.arguments, <String, Object?>{'threshold': 120});
  });

  test('printerGoToNextMark passes optional distance', () async {
    await platform.printerGoToNextMark(distance: 120);

    expect(methodCalls.single.method, 'printer.goToNextMark');
    expect(methodCalls.single.arguments, <String, Object?>{'distance': 120});
  });
}
