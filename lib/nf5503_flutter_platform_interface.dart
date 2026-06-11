import 'dart:typed_data';

import 'package:plugin_platform_interface/plugin_platform_interface.dart';

import 'nf5503_flutter_method_channel.dart';
import 'src/nf5503_types.dart';

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

  Stream<Nf5503ScanResult> scannerResults({String? action, String? key}) {
    throw UnimplementedError('scannerResults() has not been implemented.');
  }

  Future<bool> scannerOpen() {
    throw UnimplementedError('scannerOpen() has not been implemented.');
  }

  Future<bool> scannerClose() {
    throw UnimplementedError('scannerClose() has not been implemented.');
  }

  Future<bool> scannerStartDecode() {
    throw UnimplementedError('scannerStartDecode() has not been implemented.');
  }

  Future<bool> scannerStopDecode() {
    throw UnimplementedError('scannerStopDecode() has not been implemented.');
  }

  Future<bool> scannerIsOpen() {
    throw UnimplementedError('scannerIsOpen() has not been implemented.');
  }

  Future<void> scannerSetPrefix(String prefix) {
    throw UnimplementedError('scannerSetPrefix() has not been implemented.');
  }

  Future<String> scannerGetPrefix() {
    throw UnimplementedError('scannerGetPrefix() has not been implemented.');
  }

  Future<void> scannerSetSuffix(String suffix) {
    throw UnimplementedError('scannerSetSuffix() has not been implemented.');
  }

  Future<String> scannerGetSuffix() {
    throw UnimplementedError('scannerGetSuffix() has not been implemented.');
  }

  Future<void> scannerSetFilter(String filter) {
    throw UnimplementedError('scannerSetFilter() has not been implemented.');
  }

  Future<String> scannerGetFilter() {
    throw UnimplementedError('scannerGetFilter() has not been implemented.');
  }

  Future<void> scannerSetPlaySound(bool enabled) {
    throw UnimplementedError('scannerSetPlaySound() has not been implemented.');
  }

  Future<bool> scannerGetPlaySound() {
    throw UnimplementedError('scannerGetPlaySound() has not been implemented.');
  }

  Future<void> scannerSetVibrate(bool enabled) {
    throw UnimplementedError('scannerSetVibrate() has not been implemented.');
  }

  Future<bool> scannerGetVibrate() {
    throw UnimplementedError('scannerGetVibrate() has not been implemented.');
  }

  Future<void> scannerSetContinueScan(bool enabled) {
    throw UnimplementedError(
      'scannerSetContinueScan() has not been implemented.',
    );
  }

  Future<bool> scannerGetContinueScan() {
    throw UnimplementedError(
      'scannerGetContinueScan() has not been implemented.',
    );
  }

  Future<void> scannerSetMultiDecode(bool enabled) {
    throw UnimplementedError(
      'scannerSetMultiDecode() has not been implemented.',
    );
  }

  Future<bool> scannerGetMultiDecode() {
    throw UnimplementedError(
      'scannerGetMultiDecode() has not been implemented.',
    );
  }

  Future<void> scannerSetMultiReadNumber(int number) {
    throw UnimplementedError(
      'scannerSetMultiReadNumber() has not been implemented.',
    );
  }

  Future<int> scannerGetMultiReadNumber() {
    throw UnimplementedError(
      'scannerGetMultiReadNumber() has not been implemented.',
    );
  }

  Future<void> scannerSetDisableSameBarcode(bool disabled) {
    throw UnimplementedError(
      'scannerSetDisableSameBarcode() has not been implemented.',
    );
  }

  Future<bool> scannerGetDisableSameBarcode() {
    throw UnimplementedError(
      'scannerGetDisableSameBarcode() has not been implemented.',
    );
  }

  Future<void> scannerSetBroadcastAction(String action) {
    throw UnimplementedError(
      'scannerSetBroadcastAction() has not been implemented.',
    );
  }

  Future<String> scannerGetBroadcastAction() {
    throw UnimplementedError(
      'scannerGetBroadcastAction() has not been implemented.',
    );
  }

  Future<void> scannerSetBroadcastKey(String key) {
    throw UnimplementedError(
      'scannerSetBroadcastKey() has not been implemented.',
    );
  }

  Future<String> scannerGetBroadcastKey() {
    throw UnimplementedError(
      'scannerGetBroadcastKey() has not been implemented.',
    );
  }

  Future<void> scannerSetOutputMode(Nf5503ScanOutputMode mode) {
    throw UnimplementedError(
      'scannerSetOutputMode() has not been implemented.',
    );
  }

  Future<Nf5503ScanOutputMode> scannerGetOutputMode() {
    throw UnimplementedError(
      'scannerGetOutputMode() has not been implemented.',
    );
  }

  Future<void> scannerSetEndMark(Nf5503ScanEndMark mark) {
    throw UnimplementedError('scannerSetEndMark() has not been implemented.');
  }

  Future<Nf5503ScanEndMark> scannerGetEndMark() {
    throw UnimplementedError('scannerGetEndMark() has not been implemented.');
  }

  Future<void> scannerSetHandleKey(bool enabled) {
    throw UnimplementedError('scannerSetHandleKey() has not been implemented.');
  }

  Future<bool> scannerGetHandleKey() {
    throw UnimplementedError('scannerGetHandleKey() has not been implemented.');
  }

  Future<bool> scannerSetIntervalTime(int milliseconds) {
    throw UnimplementedError(
      'scannerSetIntervalTime() has not been implemented.',
    );
  }

  Future<int> scannerGetIntervalTime() {
    throw UnimplementedError(
      'scannerGetIntervalTime() has not been implemented.',
    );
  }

  Future<void> scannerSetDecodeTimeout(int milliseconds) {
    throw UnimplementedError(
      'scannerSetDecodeTimeout() has not been implemented.',
    );
  }

  Future<int> scannerGetDecodeTimeout() {
    throw UnimplementedError(
      'scannerGetDecodeTimeout() has not been implemented.',
    );
  }

  Future<void> scannerSetLiftToStop(bool enabled) {
    throw UnimplementedError(
      'scannerSetLiftToStop() has not been implemented.',
    );
  }

  Future<bool> scannerGetLiftToStop() {
    throw UnimplementedError(
      'scannerGetLiftToStop() has not been implemented.',
    );
  }

  Future<void> scannerSetSymbologyValues(Map<int, int> values) {
    throw UnimplementedError(
      'scannerSetSymbologyValues() has not been implemented.',
    );
  }

  Future<List<int>> scannerGetSymbologyValues(List<int> paramIds) {
    throw UnimplementedError(
      'scannerGetSymbologyValues() has not been implemented.',
    );
  }

  Future<void> scannerEnableAllSymbologies(bool enabled) {
    throw UnimplementedError(
      'scannerEnableAllSymbologies() has not been implemented.',
    );
  }

  Future<void> scannerEnableSymbology({
    required int symbologyId,
    required bool enabled,
  }) {
    throw UnimplementedError(
      'scannerEnableSymbology() has not been implemented.',
    );
  }

  Future<void> scannerEnableAll1dSymbologies(bool enabled) {
    throw UnimplementedError(
      'scannerEnableAll1dSymbologies() has not been implemented.',
    );
  }

  Future<void> scannerEnableAll2dSymbologies(bool enabled) {
    throw UnimplementedError(
      'scannerEnableAll2dSymbologies() has not been implemented.',
    );
  }

  Future<bool> scannerIsSymbologyEnabled(int symbologyId) {
    throw UnimplementedError(
      'scannerIsSymbologyEnabled() has not been implemented.',
    );
  }

  Future<bool> scannerIsSymbologySupported(int symbologyId) {
    throw UnimplementedError(
      'scannerIsSymbologySupported() has not been implemented.',
    );
  }

  Future<void> scannerReset() {
    throw UnimplementedError('scannerReset() has not been implemented.');
  }

  Stream<Nf5503PrintEvent> printerEvents() {
    throw UnimplementedError('printerEvents() has not been implemented.');
  }

  Future<String> printerGetVersion() {
    throw UnimplementedError('printerGetVersion() has not been implemented.');
  }

  Future<bool> printerOpen() {
    throw UnimplementedError('printerOpen() has not been implemented.');
  }

  Future<bool> printerClose() {
    throw UnimplementedError('printerClose() has not been implemented.');
  }

  Future<void> printerSetConcentration(int density) {
    throw UnimplementedError(
      'printerSetConcentration() has not been implemented.',
    );
  }

  Future<int> printerGetConcentration() {
    throw UnimplementedError(
      'printerGetConcentration() has not been implemented.',
    );
  }

  Future<int> printerReset() {
    throw UnimplementedError('printerReset() has not been implemented.');
  }

  Future<void> printerSetFontSize(Nf5503PrintFontSize fontSize) {
    throw UnimplementedError('printerSetFontSize() has not been implemented.');
  }

  Future<Nf5503PrintFontSize> printerGetFontSize() {
    throw UnimplementedError('printerGetFontSize() has not been implemented.');
  }

  Future<void> printerSetBold(bool enabled) {
    throw UnimplementedError('printerSetBold() has not been implemented.');
  }

  Future<bool> printerIsBold() {
    throw UnimplementedError('printerIsBold() has not been implemented.');
  }

  Future<void> printerSetBlackMark(bool enabled) {
    throw UnimplementedError('printerSetBlackMark() has not been implemented.');
  }

  Future<bool> printerIsBlackMark() {
    throw UnimplementedError('printerIsBlackMark() has not been implemented.');
  }

  Future<void> printerSetUnderline(bool enabled) {
    throw UnimplementedError('printerSetUnderline() has not been implemented.');
  }

  Future<bool> printerIsUnderline() {
    throw UnimplementedError('printerIsUnderline() has not been implemented.');
  }

  Future<void> printerSetFeedPaperSpace(int space) {
    throw UnimplementedError(
      'printerSetFeedPaperSpace() has not been implemented.',
    );
  }

  Future<int> printerGetFeedPaperSpace() {
    throw UnimplementedError(
      'printerGetFeedPaperSpace() has not been implemented.',
    );
  }

  Future<void> printerSetUnwindPaperLength(int length) {
    throw UnimplementedError(
      'printerSetUnwindPaperLength() has not been implemented.',
    );
  }

  Future<int> printerGetUnwindPaperLength() {
    throw UnimplementedError(
      'printerGetUnwindPaperLength() has not been implemented.',
    );
  }

  Future<void> printerAddText(
    String content, {
    Nf5503PrintAlign align = Nf5503PrintAlign.left,
    Nf5503PrintFontSize fontSize = Nf5503PrintFontSize.middle,
    bool isBold = false,
    bool isUnderline = false,
  }) {
    throw UnimplementedError('printerAddText() has not been implemented.');
  }

  Future<void> printerAddBarcode({
    required String content,
    required int height,
    required Nf5503BarcodeType type,
    Nf5503PrintAlign align = Nf5503PrintAlign.center,
    Nf5503HriPosition hriPosition = Nf5503HriPosition.below,
  }) {
    throw UnimplementedError('printerAddBarcode() has not been implemented.');
  }

  Future<void> printerAddQrCode(
    String content, {
    Nf5503PrintAlign align = Nf5503PrintAlign.center,
    int size = 384,
  }) {
    throw UnimplementedError('printerAddQrCode() has not been implemented.');
  }

  Future<void> printerAddImageBytes(
    Uint8List imageBytes, {
    Nf5503PrintAlign align = Nf5503PrintAlign.center,
  }) {
    throw UnimplementedError(
      'printerAddImageBytes() has not been implemented.',
    );
  }

  Future<void> printerAddImagePath(
    String imagePath, {
    Nf5503PrintAlign align = Nf5503PrintAlign.center,
  }) {
    throw UnimplementedError('printerAddImagePath() has not been implemented.');
  }

  Future<void> printerAddBlankLines(int lines) {
    throw UnimplementedError(
      'printerAddBlankLines() has not been implemented.',
    );
  }

  Future<void> printerStart() {
    throw UnimplementedError('printerStart() has not been implemented.');
  }

  Future<void> printerSetReverse(bool enabled) {
    throw UnimplementedError('printerSetReverse() has not been implemented.');
  }

  Future<bool> printerIsReverse() {
    throw UnimplementedError('printerIsReverse() has not been implemented.');
  }

  Future<void> printerGoToNextMark({int? distance}) {
    throw UnimplementedError('printerGoToNextMark() has not been implemented.');
  }

  Future<void> printerSetLineSpacing(double spacing) {
    throw UnimplementedError(
      'printerSetLineSpacing() has not been implemented.',
    );
  }

  Future<double> printerGetLineSpacing() {
    throw UnimplementedError(
      'printerGetLineSpacing() has not been implemented.',
    );
  }

  Future<int> printerGetSupportPrint() {
    throw UnimplementedError(
      'printerGetSupportPrint() has not been implemented.',
    );
  }

  Future<int> printerGetState(Nf5503PrinterStateType stateType) {
    throw UnimplementedError('printerGetState() has not been implemented.');
  }
}
