import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';

import 'nf5503_flutter_platform_interface.dart';
import 'src/nf5503_types.dart';

/// An implementation of [Nf5503FlutterPlatform] that uses method channels.
class MethodChannelNf5503Flutter extends Nf5503FlutterPlatform {
  /// The method channel used to interact with the native platform.
  @visibleForTesting
  final methodChannel = const MethodChannel('nf5503_flutter');

  @visibleForTesting
  final scannerEventChannel = const EventChannel('nf5503_flutter/scanner');

  @visibleForTesting
  final printerEventChannel = const EventChannel('nf5503_flutter/printer');

  @override
  Future<String?> getPlatformVersion() async {
    return methodChannel.invokeMethod<String>('getPlatformVersion');
  }

  @override
  Stream<Nf5503ScanResult> scannerResults({String? action, String? key}) {
    final arguments = <String, Object?>{};
    if (action != null) {
      arguments['action'] = action;
    }
    if (key != null) {
      arguments['key'] = key;
    }

    return scannerEventChannel
        .receiveBroadcastStream(arguments)
        .map((event) => Nf5503ScanResult.fromMap(_eventMap(event)));
  }

  @override
  Future<bool> scannerOpen() => _invokeBool('scanner.open');

  @override
  Future<bool> scannerClose() => _invokeBool('scanner.close');

  @override
  Future<bool> scannerStartDecode() => _invokeBool('scanner.startDecode');

  @override
  Future<bool> scannerStopDecode() => _invokeBool('scanner.stopDecode');

  @override
  Future<bool> scannerIsOpen() => _invokeBool('scanner.isOpen');

  @override
  Future<List<Map<String, Object?>>> scannerGetSymbologyList() async {
    final values = await methodChannel.invokeMethod<List<Object?>>(
      'scanner.getSymbologyList',
    );
    return (values ?? const <Object?>[])
        .map(_stringObjectMap)
        .toList(growable: false);
  }

  @override
  Future<void> scannerInitSymbologySettings() {
    return _invokeVoid('scanner.initSymbologySettings');
  }

  @override
  Future<Nf5503ScannerType> scannerGetScannerType() async {
    return Nf5503ScannerType.fromValue(
      await _invokeInt('scanner.getScannerType'),
    );
  }

  @override
  Future<bool> scannerIsConflicted() {
    return _invokeBool('scanner.isConflicted');
  }

  @override
  Future<void> scannerConnectDecoder() {
    return _invokeVoid('scanner.connectDecoder');
  }

  @override
  Future<void> scannerDisconnectDecoder() {
    return _invokeVoid('scanner.disconnectDecoder');
  }

  @override
  Future<bool> scannerGetDecoderStatus() {
    return _invokeBool('scanner.getDecoderStatus');
  }

  @override
  Future<bool> scannerIsDecoderConnected() {
    return _invokeBool('scanner.isDecoderConnected');
  }

  @override
  Future<void> scannerSetPrefix(String prefix) {
    return _invokeVoid('scanner.setPrefix', <String, Object?>{
      'prefix': prefix,
    });
  }

  @override
  Future<String> scannerGetPrefix() => _invokeString('scanner.getPrefix');

  @override
  Future<void> scannerSetSuffix(String suffix) {
    return _invokeVoid('scanner.setSuffix', <String, Object?>{
      'suffix': suffix,
    });
  }

  @override
  Future<String> scannerGetSuffix() => _invokeString('scanner.getSuffix');

  @override
  Future<void> scannerSetFilter(String filter) {
    return _invokeVoid('scanner.setFilter', <String, Object?>{
      'filter': filter,
    });
  }

  @override
  Future<String> scannerGetFilter() => _invokeString('scanner.getFilter');

  @override
  Future<void> scannerSetPlaySound(bool enabled) {
    return _invokeVoid('scanner.setPlaySound', <String, Object?>{
      'enabled': enabled,
    });
  }

  @override
  Future<bool> scannerGetPlaySound() => _invokeBool('scanner.getPlaySound');

  @override
  Future<void> scannerSetVibrate(bool enabled) {
    return _invokeVoid('scanner.setVibrate', <String, Object?>{
      'enabled': enabled,
    });
  }

  @override
  Future<bool> scannerGetVibrate() => _invokeBool('scanner.getVibrate');

  @override
  Future<void> scannerSetContinueScan(bool enabled) {
    return _invokeVoid('scanner.setContinueScan', <String, Object?>{
      'enabled': enabled,
    });
  }

  @override
  Future<bool> scannerGetContinueScan() {
    return _invokeBool('scanner.getContinueScan');
  }

  @override
  Future<void> scannerSetMultiDecode(bool enabled) {
    return _invokeVoid('scanner.setMultiDecode', <String, Object?>{
      'enabled': enabled,
    });
  }

  @override
  Future<bool> scannerGetMultiDecode() {
    return _invokeBool('scanner.getMultiDecode');
  }

  @override
  Future<void> scannerSetMultiReadNumber(int number) {
    return _invokeVoid('scanner.setMultiReadNumber', <String, Object?>{
      'number': number,
    });
  }

  @override
  Future<int> scannerGetMultiReadNumber() {
    return _invokeInt('scanner.getMultiReadNumber');
  }

  @override
  Future<void> scannerSetDisableSameBarcode(bool disabled) {
    return _invokeVoid('scanner.setDisableSameBarcode', <String, Object?>{
      'disabled': disabled,
    });
  }

  @override
  Future<bool> scannerGetDisableSameBarcode() {
    return _invokeBool('scanner.getDisableSameBarcode');
  }

  @override
  Future<void> scannerSetBroadcastAction(String action) {
    return _invokeVoid('scanner.setBroadcastAction', <String, Object?>{
      'action': action,
    });
  }

  @override
  Future<String> scannerGetBroadcastAction() {
    return _invokeString('scanner.getBroadcastAction');
  }

  @override
  Future<void> scannerSetBroadcastKey(String key) {
    return _invokeVoid('scanner.setBroadcastKey', <String, Object?>{
      'key': key,
    });
  }

  @override
  Future<String> scannerGetBroadcastKey() {
    return _invokeString('scanner.getBroadcastKey');
  }

  @override
  Future<void> scannerSetOutputMode(Nf5503ScanOutputMode mode) {
    return _invokeVoid('scanner.setOutputMode', <String, Object?>{
      'mode': mode.value,
    });
  }

  @override
  Future<Nf5503ScanOutputMode> scannerGetOutputMode() async {
    return Nf5503ScanOutputMode.fromValue(
      await _invokeInt('scanner.getOutputMode'),
    );
  }

  @override
  Future<void> scannerSetDecodeMode(Nf5503ScanDecodeMode mode) {
    return _invokeVoid('scanner.setDecodeMode', <String, Object?>{
      'mode': mode.value,
    });
  }

  @override
  Future<Nf5503ScanDecodeMode> scannerGetDecodeMode() async {
    return Nf5503ScanDecodeMode.fromValue(
      await _invokeInt('scanner.getDecodeMode'),
    );
  }

  @override
  Future<void> scannerSetEndMark(Nf5503ScanEndMark mark) {
    return _invokeVoid('scanner.setEndMark', <String, Object?>{
      'mark': mark.value,
    });
  }

  @override
  Future<Nf5503ScanEndMark> scannerGetEndMark() async {
    return Nf5503ScanEndMark.fromValue(await _invokeInt('scanner.getEndMark'));
  }

  @override
  Future<void> scannerSetHandleKey(bool enabled) {
    return _invokeVoid('scanner.setHandleKey', <String, Object?>{
      'enabled': enabled,
    });
  }

  @override
  Future<bool> scannerGetHandleKey() => _invokeBool('scanner.getHandleKey');

  @override
  Future<bool> scannerSetIntervalTime(int milliseconds) {
    return _invokeBool('scanner.setIntervalTime', <String, Object?>{
      'milliseconds': milliseconds,
    });
  }

  @override
  Future<int> scannerGetIntervalTime() {
    return _invokeInt('scanner.getIntervalTime');
  }

  @override
  Future<void> scannerSetDecodeTimeout(int milliseconds) {
    return _invokeVoid('scanner.setDecodeTimeout', <String, Object?>{
      'milliseconds': milliseconds,
    });
  }

  @override
  Future<int> scannerGetDecodeTimeout() {
    return _invokeInt('scanner.getDecodeTimeout');
  }

  @override
  Future<void> scannerSetLiftToStop(bool enabled) {
    return _invokeVoid('scanner.setLiftToStop', <String, Object?>{
      'enabled': enabled,
    });
  }

  @override
  Future<bool> scannerGetLiftToStop() => _invokeBool('scanner.getLiftToStop');

  @override
  Future<void> scannerSetSymbologyValues(Map<int, int> values) {
    return _invokeVoid('scanner.setSymbologyValues', <String, Object?>{
      'paramIds': values.keys.toList(growable: false),
      'values': values.values.toList(growable: false),
    });
  }

  @override
  Future<List<int>> scannerGetSymbologyValues(List<int> paramIds) async {
    final values = await methodChannel.invokeMethod<List<Object?>>(
      'scanner.getSymbologyValues',
      <String, Object?>{'paramIds': paramIds},
    );
    return (values ?? const <Object?>[]).map(_intFromObject).toList();
  }

  @override
  Future<void> scannerEnableAllSymbologies(bool enabled) {
    return _invokeVoid('scanner.enableAllSymbologies', <String, Object?>{
      'enabled': enabled,
    });
  }

  @override
  Future<void> scannerEnableSymbology({
    required int symbologyId,
    required bool enabled,
  }) {
    return _invokeVoid('scanner.enableSymbology', <String, Object?>{
      'symbologyId': symbologyId,
      'enabled': enabled,
    });
  }

  @override
  Future<void> scannerEnableAll1dSymbologies(bool enabled) {
    return _invokeVoid('scanner.enableAll1dSymbologies', <String, Object?>{
      'enabled': enabled,
    });
  }

  @override
  Future<void> scannerEnableAll2dSymbologies(bool enabled) {
    return _invokeVoid('scanner.enableAll2dSymbologies', <String, Object?>{
      'enabled': enabled,
    });
  }

  @override
  Future<bool> scannerIsSymbologyEnabled(int symbologyId) {
    return _invokeBool('scanner.isSymbologyEnabled', <String, Object?>{
      'symbologyId': symbologyId,
    });
  }

  @override
  Future<bool> scannerIsSymbologySupported(int symbologyId) {
    return _invokeBool('scanner.isSymbologySupported', <String, Object?>{
      'symbologyId': symbologyId,
    });
  }

  @override
  Future<void> scannerReset() => _invokeVoid('scanner.reset');

  @override
  Stream<Nf5503PrintEvent> printerEvents() {
    return printerEventChannel.receiveBroadcastStream().map(
      (event) => Nf5503PrintEvent.fromMap(_eventMap(event)),
    );
  }

  @override
  Future<String> printerGetVersion() => _invokeString('printer.getVersion');

  @override
  Future<bool> printerOpen() => _invokeBool('printer.open');

  @override
  Future<bool> printerClose() => _invokeBool('printer.close');

  @override
  Future<void> printerSetConcentration(int density) {
    return _invokeVoid('printer.setConcentration', <String, Object?>{
      'density': density,
    });
  }

  @override
  Future<int> printerGetConcentration() {
    return _invokeInt('printer.getConcentration');
  }

  @override
  Future<int> printerReset() => _invokeInt('printer.reset');

  @override
  Future<void> printerSetFontType(String fontType) {
    return _invokeVoid('printer.setFontType', <String, Object?>{
      'fontType': fontType,
    });
  }

  @override
  Future<String> printerGetFontType() => _invokeString('printer.getFontType');

  @override
  Future<void> printerSetFontSize(Nf5503PrintFontSize fontSize) {
    return _invokeVoid('printer.setFontSize', <String, Object?>{
      'fontSize': fontSize.value,
    });
  }

  @override
  Future<Nf5503PrintFontSize> printerGetFontSize() async {
    return Nf5503PrintFontSize.fromValue(
      await _invokeInt('printer.getFontSize'),
    );
  }

  @override
  Future<void> printerSetBold(bool enabled) {
    return _invokeVoid('printer.setBold', <String, Object?>{
      'enabled': enabled,
    });
  }

  @override
  Future<bool> printerIsBold() => _invokeBool('printer.isBold');

  @override
  Future<void> printerSetBlackMark(bool enabled) {
    return _invokeVoid('printer.setBlackMark', <String, Object?>{
      'enabled': enabled,
    });
  }

  @override
  Future<bool> printerIsBlackMark() => _invokeBool('printer.isBlackMark');

  @override
  Future<int> printerSetThreshold(int threshold) {
    return _invokeInt('printer.setThreshold', <String, Object?>{
      'threshold': threshold,
    });
  }

  @override
  Future<void> printerSetUnderline(bool enabled) {
    return _invokeVoid('printer.setUnderline', <String, Object?>{
      'enabled': enabled,
    });
  }

  @override
  Future<bool> printerIsUnderline() => _invokeBool('printer.isUnderline');

  @override
  Future<void> printerSetFeedPaperSpace(int space) {
    return _invokeVoid('printer.setFeedPaperSpace', <String, Object?>{
      'space': space,
    });
  }

  @override
  Future<int> printerGetFeedPaperSpace() {
    return _invokeInt('printer.getFeedPaperSpace');
  }

  @override
  Future<void> printerSetUnwindPaperLength(int length) {
    return _invokeVoid('printer.setUnwindPaperLength', <String, Object?>{
      'length': length,
    });
  }

  @override
  Future<int> printerGetUnwindPaperLength() {
    return _invokeInt('printer.getUnwindPaperLength');
  }

  @override
  Future<void> printerAddText(
    String content, {
    Nf5503PrintAlign align = Nf5503PrintAlign.left,
    Nf5503PrintFontSize fontSize = Nf5503PrintFontSize.middle,
    bool isBold = false,
    bool isUnderline = false,
  }) {
    return _invokeVoid('printer.addText', <String, Object?>{
      'content': content,
      'align': align.value,
      'fontSize': fontSize.value,
      'isBold': isBold,
      'isUnderline': isUnderline,
    });
  }

  @override
  Future<void> printerAddBarcode({
    required String content,
    required int height,
    required Nf5503BarcodeType type,
    Nf5503PrintAlign align = Nf5503PrintAlign.center,
    Nf5503HriPosition hriPosition = Nf5503HriPosition.below,
  }) {
    return _invokeVoid('printer.addBarcode', <String, Object?>{
      'content': content,
      'height': height,
      'type': type.value,
      'align': align.value,
      'hriPosition': hriPosition.value,
    });
  }

  @override
  Future<void> printerAddQrCode(
    String content, {
    Nf5503PrintAlign align = Nf5503PrintAlign.center,
    int size = 384,
  }) {
    return _invokeVoid('printer.addQrCode', <String, Object?>{
      'content': content,
      'align': align.value,
      'size': size,
    });
  }

  @override
  Future<void> printerAddImageBytes(
    Uint8List imageBytes, {
    Nf5503PrintAlign align = Nf5503PrintAlign.center,
  }) {
    return _invokeVoid('printer.addImageBytes', <String, Object?>{
      'imageBytes': imageBytes,
      'align': align.value,
    });
  }

  @override
  Future<void> printerAddImagePath(
    String imagePath, {
    Nf5503PrintAlign align = Nf5503PrintAlign.center,
  }) {
    return _invokeVoid('printer.addImagePath', <String, Object?>{
      'imagePath': imagePath,
      'align': align.value,
    });
  }

  @override
  Future<void> printerAddBlankLines(int lines) {
    return _invokeVoid('printer.addBlankLines', <String, Object?>{
      'lines': lines,
    });
  }

  @override
  Future<void> printerStart() => _invokeVoid('printer.start');

  @override
  Future<void> printerSetReverse(bool enabled) {
    return _invokeVoid('printer.setReverse', <String, Object?>{
      'enabled': enabled,
    });
  }

  @override
  Future<bool> printerIsReverse() => _invokeBool('printer.isReverse');

  @override
  Future<void> printerGoToNextMark({int? distance}) {
    final arguments = <String, Object?>{};
    if (distance != null) {
      arguments['distance'] = distance;
    }
    return _invokeVoid('printer.goToNextMark', arguments);
  }

  @override
  Future<void> printerSetLineSpacing(double spacing) {
    return _invokeVoid('printer.setLineSpacing', <String, Object?>{
      'spacing': spacing,
    });
  }

  @override
  Future<double> printerGetLineSpacing() {
    return _invokeDouble('printer.getLineSpacing');
  }

  @override
  Future<int> printerGetSupportPrint() {
    return _invokeInt('printer.getSupportPrint');
  }

  @override
  Future<int> printerGetState(Nf5503PrinterStateType stateType) {
    return _invokeInt('printer.getState', <String, Object?>{
      'stateType': stateType.value,
    });
  }

  Future<void> _invokeVoid(String method, [Map<String, Object?>? arguments]) {
    return methodChannel.invokeMethod<void>(method, arguments);
  }

  Future<bool> _invokeBool(
    String method, [
    Map<String, Object?>? arguments,
  ]) async {
    return await methodChannel.invokeMethod<bool>(method, arguments) ?? false;
  }

  Future<int> _invokeInt(
    String method, [
    Map<String, Object?>? arguments,
  ]) async {
    return _intFromObject(
      await methodChannel.invokeMethod<Object?>(method, arguments),
    );
  }

  Future<double> _invokeDouble(
    String method, [
    Map<String, Object?>? arguments,
  ]) async {
    final value = await methodChannel.invokeMethod<Object?>(method, arguments);
    if (value is num) {
      return value.toDouble();
    }
    return double.tryParse(value?.toString() ?? '') ?? 0;
  }

  Future<String> _invokeString(
    String method, [
    Map<String, Object?>? arguments,
  ]) async {
    return await methodChannel.invokeMethod<String>(method, arguments) ?? '';
  }
}

Map<Object?, Object?> _eventMap(Object? event) {
  if (event is Map<Object?, Object?>) {
    return event;
  }
  if (event is Map) {
    return event.cast<Object?, Object?>();
  }
  return <Object?, Object?>{};
}

Map<String, Object?> _stringObjectMap(Object? value) {
  if (value is Map) {
    return value.map((key, value) => MapEntry(key.toString(), value));
  }
  return <String, Object?>{'value': value};
}

int _intFromObject(Object? value) {
  if (value is int) {
    return value;
  }
  if (value is num) {
    return value.toInt();
  }
  return int.tryParse(value?.toString() ?? '') ?? 0;
}
