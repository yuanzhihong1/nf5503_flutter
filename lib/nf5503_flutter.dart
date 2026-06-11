import 'dart:typed_data';

import 'nf5503_flutter_platform_interface.dart';
import 'src/nf5503_types.dart';

export 'src/nf5503_types.dart';

class Nf5503Flutter {
  Nf5503Flutter({Nf5503Scanner? scanner, Nf5503Printer? printer})
    : scanner = scanner ?? const Nf5503Scanner(),
      printer = printer ?? const Nf5503Printer();

  final Nf5503Scanner scanner;
  final Nf5503Printer printer;

  Future<String?> getPlatformVersion() {
    return Nf5503FlutterPlatform.instance.getPlatformVersion();
  }
}

class Nf5503Scanner {
  const Nf5503Scanner();

  Nf5503FlutterPlatform get _platform => Nf5503FlutterPlatform.instance;

  Stream<Nf5503ScanResult> results({String? action, String? key}) {
    return _platform.scannerResults(action: action, key: key);
  }

  Future<bool> open() => _platform.scannerOpen();

  Future<bool> close() => _platform.scannerClose();

  Future<bool> startDecode() => _platform.scannerStartDecode();

  Future<bool> stopDecode() => _platform.scannerStopDecode();

  Future<bool> isOpen() => _platform.scannerIsOpen();

  Future<void> setPrefix(String prefix) => _platform.scannerSetPrefix(prefix);

  Future<String> getPrefix() => _platform.scannerGetPrefix();

  Future<void> setSuffix(String suffix) => _platform.scannerSetSuffix(suffix);

  Future<String> getSuffix() => _platform.scannerGetSuffix();

  Future<void> setFilter(String filter) => _platform.scannerSetFilter(filter);

  Future<String> getFilter() => _platform.scannerGetFilter();

  Future<void> setPlaySound(bool enabled) {
    return _platform.scannerSetPlaySound(enabled);
  }

  Future<bool> getPlaySound() => _platform.scannerGetPlaySound();

  Future<void> setVibrate(bool enabled) {
    return _platform.scannerSetVibrate(enabled);
  }

  Future<bool> getVibrate() => _platform.scannerGetVibrate();

  Future<void> setContinueScan(bool enabled) {
    return _platform.scannerSetContinueScan(enabled);
  }

  Future<bool> getContinueScan() => _platform.scannerGetContinueScan();

  Future<void> setMultiDecode(bool enabled) {
    return _platform.scannerSetMultiDecode(enabled);
  }

  Future<bool> getMultiDecode() => _platform.scannerGetMultiDecode();

  Future<void> setMultiReadNumber(int number) {
    return _platform.scannerSetMultiReadNumber(number);
  }

  Future<int> getMultiReadNumber() => _platform.scannerGetMultiReadNumber();

  Future<void> setDisableSameBarcode(bool disabled) {
    return _platform.scannerSetDisableSameBarcode(disabled);
  }

  Future<bool> getDisableSameBarcode() {
    return _platform.scannerGetDisableSameBarcode();
  }

  Future<void> setBroadcastAction(String action) {
    return _platform.scannerSetBroadcastAction(action);
  }

  Future<String> getBroadcastAction() {
    return _platform.scannerGetBroadcastAction();
  }

  Future<void> setBroadcastKey(String key) {
    return _platform.scannerSetBroadcastKey(key);
  }

  Future<String> getBroadcastKey() => _platform.scannerGetBroadcastKey();

  Future<void> setOutputMode(Nf5503ScanOutputMode mode) {
    return _platform.scannerSetOutputMode(mode);
  }

  Future<Nf5503ScanOutputMode> getOutputMode() {
    return _platform.scannerGetOutputMode();
  }

  Future<void> setEndMark(Nf5503ScanEndMark mark) {
    return _platform.scannerSetEndMark(mark);
  }

  Future<Nf5503ScanEndMark> getEndMark() {
    return _platform.scannerGetEndMark();
  }

  Future<void> setHandleKey(bool enabled) {
    return _platform.scannerSetHandleKey(enabled);
  }

  Future<bool> getHandleKey() => _platform.scannerGetHandleKey();

  Future<bool> setIntervalTime(int milliseconds) {
    return _platform.scannerSetIntervalTime(milliseconds);
  }

  Future<int> getIntervalTime() => _platform.scannerGetIntervalTime();

  Future<void> setDecodeTimeout(int milliseconds) {
    return _platform.scannerSetDecodeTimeout(milliseconds);
  }

  Future<int> getDecodeTimeout() => _platform.scannerGetDecodeTimeout();

  Future<void> setLiftToStop(bool enabled) {
    return _platform.scannerSetLiftToStop(enabled);
  }

  Future<bool> getLiftToStop() => _platform.scannerGetLiftToStop();

  Future<void> setSymbologyValues(Map<int, int> values) {
    return _platform.scannerSetSymbologyValues(values);
  }

  Future<List<int>> getSymbologyValues(List<int> paramIds) {
    return _platform.scannerGetSymbologyValues(paramIds);
  }

  Future<void> enableAllSymbologies(bool enabled) {
    return _platform.scannerEnableAllSymbologies(enabled);
  }

  Future<void> enableSymbology({
    required int symbologyId,
    required bool enabled,
  }) {
    return _platform.scannerEnableSymbology(
      symbologyId: symbologyId,
      enabled: enabled,
    );
  }

  Future<void> enableAll1dSymbologies(bool enabled) {
    return _platform.scannerEnableAll1dSymbologies(enabled);
  }

  Future<void> enableAll2dSymbologies(bool enabled) {
    return _platform.scannerEnableAll2dSymbologies(enabled);
  }

  Future<bool> isSymbologyEnabled(int symbologyId) {
    return _platform.scannerIsSymbologyEnabled(symbologyId);
  }

  Future<bool> isSymbologySupported(int symbologyId) {
    return _platform.scannerIsSymbologySupported(symbologyId);
  }

  Future<void> reset() => _platform.scannerReset();
}

class Nf5503Printer {
  const Nf5503Printer();

  Nf5503FlutterPlatform get _platform => Nf5503FlutterPlatform.instance;

  Stream<Nf5503PrintEvent> events() => _platform.printerEvents();

  Future<String> getVersion() => _platform.printerGetVersion();

  Future<bool> open() => _platform.printerOpen();

  Future<bool> close() => _platform.printerClose();

  Future<void> setConcentration(int density) {
    return _platform.printerSetConcentration(density);
  }

  Future<int> getConcentration() => _platform.printerGetConcentration();

  Future<int> reset() => _platform.printerReset();

  Future<void> setFontSize(Nf5503PrintFontSize fontSize) {
    return _platform.printerSetFontSize(fontSize);
  }

  Future<Nf5503PrintFontSize> getFontSize() {
    return _platform.printerGetFontSize();
  }

  Future<void> setBold(bool enabled) => _platform.printerSetBold(enabled);

  Future<bool> isBold() => _platform.printerIsBold();

  Future<void> setBlackMark(bool enabled) {
    return _platform.printerSetBlackMark(enabled);
  }

  Future<bool> isBlackMark() => _platform.printerIsBlackMark();

  Future<void> setUnderline(bool enabled) {
    return _platform.printerSetUnderline(enabled);
  }

  Future<bool> isUnderline() => _platform.printerIsUnderline();

  Future<void> setFeedPaperSpace(int space) {
    return _platform.printerSetFeedPaperSpace(space);
  }

  Future<int> getFeedPaperSpace() => _platform.printerGetFeedPaperSpace();

  Future<void> setUnwindPaperLength(int length) {
    return _platform.printerSetUnwindPaperLength(length);
  }

  Future<int> getUnwindPaperLength() {
    return _platform.printerGetUnwindPaperLength();
  }

  Future<void> addText(
    String content, {
    Nf5503PrintAlign align = Nf5503PrintAlign.left,
    Nf5503PrintFontSize fontSize = Nf5503PrintFontSize.middle,
    bool isBold = false,
    bool isUnderline = false,
  }) {
    return _platform.printerAddText(
      content,
      align: align,
      fontSize: fontSize,
      isBold: isBold,
      isUnderline: isUnderline,
    );
  }

  Future<void> addBarcode({
    required String content,
    required int height,
    required Nf5503BarcodeType type,
    Nf5503PrintAlign align = Nf5503PrintAlign.center,
    Nf5503HriPosition hriPosition = Nf5503HriPosition.below,
  }) {
    return _platform.printerAddBarcode(
      content: content,
      height: height,
      type: type,
      align: align,
      hriPosition: hriPosition,
    );
  }

  Future<void> addQrCode(
    String content, {
    Nf5503PrintAlign align = Nf5503PrintAlign.center,
    int size = 384,
  }) {
    return _platform.printerAddQrCode(content, align: align, size: size);
  }

  Future<void> addImageBytes(
    Uint8List imageBytes, {
    Nf5503PrintAlign align = Nf5503PrintAlign.center,
  }) {
    return _platform.printerAddImageBytes(imageBytes, align: align);
  }

  Future<void> addImagePath(
    String imagePath, {
    Nf5503PrintAlign align = Nf5503PrintAlign.center,
  }) {
    return _platform.printerAddImagePath(imagePath, align: align);
  }

  Future<void> addBlankLines(int lines) {
    return _platform.printerAddBlankLines(lines);
  }

  Future<void> start() => _platform.printerStart();

  Future<void> setReverse(bool enabled) {
    return _platform.printerSetReverse(enabled);
  }

  Future<bool> isReverse() => _platform.printerIsReverse();

  Future<void> goToNextMark({int? distance}) {
    return _platform.printerGoToNextMark(distance: distance);
  }

  Future<void> setLineSpacing(double spacing) {
    return _platform.printerSetLineSpacing(spacing);
  }

  Future<double> getLineSpacing() => _platform.printerGetLineSpacing();

  Future<int> getSupportPrint() => _platform.printerGetSupportPrint();

  Future<int> getState(Nf5503PrinterStateType stateType) {
    return _platform.printerGetState(stateType);
  }
}
