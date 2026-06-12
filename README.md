# nf5503_flutter

M5Stack NF5503 Android barcode scanning and thermal/label printing Flutter plugin.

This package wraps the NF5503 device SDKs:

- `ScanManager_V202105081630.jar` for barcode scanner control, scan output settings, decoder settings, and symbology configuration.
- `PrinterAPI_V202108242200.jar` for printer state, font, density, black mark, content queue, and print execution.
- `lcprintsdk1.1-classes.jar` for label black-mark movement and print support probing.

Only Android is implemented. The scanner and printer APIs require NF5503 firmware/framework services and are expected to run on the target device.

## Usage

```dart
import 'package:nf5503_flutter/nf5503_flutter.dart';

final nf5503 = Nf5503Flutter();

Future<void> scanOnce() async {
  await nf5503.scanner.setBroadcastAction('com.example.SCAN');
  await nf5503.scanner.setBroadcastKey('barcode');
  await nf5503.scanner.setOutputMode(Nf5503ScanOutputMode.broadcast);

  nf5503.scanner.results(
    action: 'com.example.SCAN',
    key: 'barcode',
  ).listen((result) {
    print('scan: ${result.data}');
  });

  await nf5503.scanner.open();
  await nf5503.scanner.startDecode();
}

Future<void> printSample() async {
  await nf5503.printer.open();
  await nf5503.printer.setConcentration(24);
  await nf5503.printer.addText(
    'NF5503 Flutter',
    align: Nf5503PrintAlign.center,
    fontSize: Nf5503PrintFontSize.large,
    isBold: true,
  );
  await nf5503.printer.addQrCode('https://m5stack.com');
  await nf5503.printer.addBlankLines(3);
  await nf5503.printer.start();
}
```

See `example/lib/main.dart` for a scanner/printer probe UI.

## API coverage

The public Flutter API is split into two facades: `Nf5503Scanner` and `Nf5503Printer`.

### Scanner

| Flutter API | Native SDK alignment |
| --- | --- |
| `results({action, key})` | Listens to scanner result broadcasts and parses `data`, `action`, and raw `extras`. |
| `open()`, `close()`, `isOpen()` | `ScanManager.openScanner`, `closeScanner`, `isScannerOpen`. |
| `startDecode()`, `stopDecode()` | `ScanManager.startDecode`, `stopDecode`. |
| `getSymbologyList()`, `initSymbologySettings()` | `ScanManager.getSymbologyList`, `initSymbologySettings`. |
| `getScannerType()` | `ScanManager.getScannerType`; values map to `Nf5503ScannerType`. |
| `isConflicted()` | `ScanManager.isScannerConflicted`. |
| `connectDecoder()`, `disconnectDecoder()` | `ScanManager.decoderConnect`, `decoderDisconnect`. The SDK also exposes uppercase aliases; the lowercase methods cover the same behavior. |
| `getDecoderStatus()`, `isDecoderConnected()` | `ScanManager.getDecoderStatus`, `isDecoderConnected`. |
| `setPrefix/getPrefix`, `setSuffix/getSuffix`, `setFilter/getFilter` | Scan result text affix/filter settings. |
| `setPlaySound/getPlaySound`, `setVibrate/getVibrate` | Scan success feedback settings. |
| `setContinueScan/getContinueScan` | Continuous scan setting. |
| `setMultiDecode/getMultiDecode`, `setMultiReadNumber/getMultiReadNumber` | Multi-code recognition settings. |
| `setDisableSameBarcode/getDisableSameBarcode` | Duplicate barcode suppression setting. |
| `setBroadcastAction/getBroadcastAction`, `setBroadcastKey/getBroadcastKey` | Broadcast action and data key used by scan results. |
| `setOutputMode/getOutputMode` | `ScanConfig.SCAN_OUTPUTMODE_*`; values map to `Nf5503ScanOutputMode`. |
| `setDecodeMode/getDecodeMode` | `ScanConfig.SCAN_ENCODE_MODE_*`; values map to `Nf5503ScanDecodeMode`. |
| `setEndMark/getEndMark` | `ScanConfig.END_MARK_*_MODE`; values map to `Nf5503ScanEndMark`. |
| `setHandleKey/getHandleKey` | Scanner key handling setting. |
| `setIntervalTime/getIntervalTime` | Continuous scan interval in milliseconds; setter returns whether the SDK accepted the value. |
| `setDecodeTimeout/getDecodeTimeout` | Single decode timeout in milliseconds. |
| `setLiftToStop/getLiftToStop` | Stop scan when the scan key is released. |
| `setSymbologyValues()`, `getSymbologyValues()` | `ScanManager.setSYMValueInts`, `getSYMValueInts`. |
| `enableAllSymbologies()`, `enableSymbology()` | `ScanManager.enableAllSYM`, `enableSYM`. |
| `enableAll1dSymbologies()`, `enableAll2dSymbologies()` | `ScanManager.enableSYM1D`, `enableSYM2D`. |
| `isSymbologyEnabled()`, `isSymbologySupported()` | `ScanManager.isSYMEnabled`, `isSYMSupported`. |
| `reset()` | `ScanManager.resetScan`. |

### Printer

| Flutter API | Native SDK alignment |
| --- | --- |
| `events()` | Emits version and `PrinterBinderListener` state callbacks as `Nf5503PrintEvent`. |
| `getVersion()` | `PrintManager.getPrinterVer`. |
| `open()`, `close()` | `PrintManager.open`, `close`. |
| `setConcentration()`, `getConcentration()` | Wraps `PrintManager.setDensity/getDensity`. The Flutter API accepts a 1-40 business value and maps each 4-step band to native `PrintConfig.Density` 1-10. |
| `reset()` | `PrintManager.reset`. |
| `setFontType/getFontType` | `PrintManager.setFontType`, `getFontType`. |
| `setFontSize/getFontSize` | `PrintConfig.FontSize.TOP_FONT_SIZE_*`; values map to `Nf5503PrintFontSize`. |
| `setBold/isBold` | `PrintManager.setFontBold`, `isFontBold`. |
| `setBlackMark/isBlackMark` | `PrintManager.setBlackLabel`, `isBlackLabel`. |
| `setThreshold()` | `PrintManager.setThreshold`; returns the native status/error code. |
| `setUnderline/isUnderline` | `PrintManager.setUnderLine`, `isUnderLine`. |
| `setFeedPaperSpace/getFeedPaperSpace` | `PrintManager.setFeedPaperSpace`, `getFeedPaperSpace`. |
| `setUnwindPaperLength/getUnwindPaperLength` | `PrintManager.setUnwindPaperLen`, `getUnwindPaperLen`. |
| `addText()` | `PrintManager.addText`. |
| `addBarcode()` | `PrintManager.addBarcode`; type and HRI values map to `Nf5503BarcodeType` and `Nf5503HriPosition`. |
| `addQrCode()` | `PrintManager.addQRCode`. |
| `addImageBytes()`, `addImagePath()` | `PrintManager.addImage`, `addImageFile`. |
| `addBlankLines()` | `PrintManager.addLineFeed`. |
| `start()` | `PrintManager.start`. |
| `setReverse/isReverse` | `PrintManager.setReverse`, `isReverse`. |
| `goToNextMark({distance})` | `PrintUtil.printGoToNextMark()` or `printGoToNextMark(distance)`. |
| `setLineSpacing/getLineSpacing` | `PrintManager.setLineSpacing`, `getLineSpacing`. |
| `getSupportPrint()` | `PrintUtil.getSupportPrint`. |
| `getState()` | `PrintManager.getPrinterState`; query values map to `Nf5503PrinterStateType`. |

PrintUtil overloads such as `printText(String)`, `printQR(String)`, and `printBitmap(Bitmap)` are intentionally represented by the richer queue APIs above.

## Value types

- `Nf5503ScanOutputMode`, `Nf5503ScanEndMark`, `Nf5503ScanDecodeMode`, and `Nf5503ScannerType` map to the NF5503 scan constants.
- `Nf5503PrintAlign`, `Nf5503PrintFontSize`, `Nf5503BarcodeType`, `Nf5503HriPosition`, `Nf5503PrinterStateType`, and `Nf5503PrintErrorCode` map to `PrintConfig` constants.
- `Nf5503ScanResult.extras` keeps the raw Android broadcast extras for barcode type, code ID, or other firmware-specific fields.
- `Nf5503PrintEvent.errorCode` converts printer callback states to `Nf5503PrintErrorCode` when the value is known.

## Notes

- The Android compile-time `ScanManager` and `PrintManager` jars are configured as `compileOnly` because the NF5503 framework provides the real implementations on device.
- `lcprintsdk1.1-classes.jar` is packaged because `PrintUtil` provides helper methods that are not present on `PrintManager`.
- Symbology IDs and parameter IDs are passed as integers to stay aligned with the native SDK. Use `getSymbologyList()` or the NF5503 `DecoderConfigValues` constants from the device SDK when configuring advanced symbology options.
