import 'dart:typed_data';

import 'package:plugin_platform_interface/plugin_platform_interface.dart';

import 'nf5503_flutter_method_channel.dart';
import 'src/nf5503_types.dart';

/// NF5503 插件的平台接口，供各平台实现 MethodChannel 或其它通信方式。
abstract class Nf5503FlutterPlatform extends PlatformInterface {
  /// 创建平台接口实例。
  Nf5503FlutterPlatform() : super(token: _token);

  static final Object _token = Object();

  static Nf5503FlutterPlatform _instance = MethodChannelNf5503Flutter();

  /// 当前默认平台实现。
  static Nf5503FlutterPlatform get instance => _instance;

  /// 注册平台实现，必须继承 [Nf5503FlutterPlatform] 并通过 token 校验。
  static set instance(Nf5503FlutterPlatform instance) {
    PlatformInterface.verifyToken(instance, _token);
    _instance = instance;
  }

  /// 获取当前 Android 平台版本字符串。
  Future<String?> getPlatformVersion() {
    throw UnimplementedError('platformVersion() has not been implemented.');
  }

  /// 监听扫码广播结果，可传入自定义广播 action 和数据 key。
  Stream<Nf5503ScanResult> scannerResults({String? action, String? key}) {
    throw UnimplementedError('scannerResults() has not been implemented.');
  }

  /// 打开扫码头。
  Future<bool> scannerOpen() {
    throw UnimplementedError('scannerOpen() has not been implemented.');
  }

  /// 关闭扫码头。
  Future<bool> scannerClose() {
    throw UnimplementedError('scannerClose() has not been implemented.');
  }

  /// 触发一次扫码解码。
  Future<bool> scannerStartDecode() {
    throw UnimplementedError('scannerStartDecode() has not been implemented.');
  }

  /// 停止当前扫码解码。
  Future<bool> scannerStopDecode() {
    throw UnimplementedError('scannerStopDecode() has not been implemented.');
  }

  /// 查询扫码头是否已打开。
  Future<bool> scannerIsOpen() {
    throw UnimplementedError('scannerIsOpen() has not been implemented.');
  }

  /// 获取设备支持的码制信息列表，字段由原生 SDK 对象反射得出。
  Future<List<Map<String, Object?>>> scannerGetSymbologyList() {
    throw UnimplementedError(
      'scannerGetSymbologyList() has not been implemented.',
    );
  }

  /// 初始化所有码制参数为 SDK 默认值。
  Future<void> scannerInitSymbologySettings() {
    throw UnimplementedError(
      'scannerInitSymbologySettings() has not been implemented.',
    );
  }

  /// 获取当前扫描头硬件类型。
  Future<Nf5503ScannerType> scannerGetScannerType() {
    throw UnimplementedError(
      'scannerGetScannerType() has not been implemented.',
    );
  }

  /// 查询当前扫描头是否与其它扫描服务冲突。
  Future<bool> scannerIsConflicted() {
    throw UnimplementedError('scannerIsConflicted() has not been implemented.');
  }

  /// 连接底层解码器。
  Future<void> scannerConnectDecoder() {
    throw UnimplementedError(
      'scannerConnectDecoder() has not been implemented.',
    );
  }

  /// 断开底层解码器。
  Future<void> scannerDisconnectDecoder() {
    throw UnimplementedError(
      'scannerDisconnectDecoder() has not been implemented.',
    );
  }

  /// 查询底层解码器状态。
  Future<bool> scannerGetDecoderStatus() {
    throw UnimplementedError(
      'scannerGetDecoderStatus() has not been implemented.',
    );
  }

  /// 查询底层解码器是否已连接。
  Future<bool> scannerIsDecoderConnected() {
    throw UnimplementedError(
      'scannerIsDecoderConnected() has not been implemented.',
    );
  }

  /// 设置扫码结果前缀。
  Future<void> scannerSetPrefix(String prefix) {
    throw UnimplementedError('scannerSetPrefix() has not been implemented.');
  }

  /// 获取扫码结果前缀。
  Future<String> scannerGetPrefix() {
    throw UnimplementedError('scannerGetPrefix() has not been implemented.');
  }

  /// 设置扫码结果后缀。
  Future<void> scannerSetSuffix(String suffix) {
    throw UnimplementedError('scannerSetSuffix() has not been implemented.');
  }

  /// 获取扫码结果后缀。
  Future<String> scannerGetSuffix() {
    throw UnimplementedError('scannerGetSuffix() has not been implemented.');
  }

  /// 设置扫码过滤规则。
  Future<void> scannerSetFilter(String filter) {
    throw UnimplementedError('scannerSetFilter() has not been implemented.');
  }

  /// 获取扫码过滤规则。
  Future<String> scannerGetFilter() {
    throw UnimplementedError('scannerGetFilter() has not been implemented.');
  }

  /// 设置扫码成功后是否播放提示音。
  Future<void> scannerSetPlaySound(bool enabled) {
    throw UnimplementedError('scannerSetPlaySound() has not been implemented.');
  }

  /// 获取扫码成功提示音开关状态。
  Future<bool> scannerGetPlaySound() {
    throw UnimplementedError('scannerGetPlaySound() has not been implemented.');
  }

  /// 设置扫码成功后是否震动。
  Future<void> scannerSetVibrate(bool enabled) {
    throw UnimplementedError('scannerSetVibrate() has not been implemented.');
  }

  /// 获取扫码成功震动开关状态。
  Future<bool> scannerGetVibrate() {
    throw UnimplementedError('scannerGetVibrate() has not been implemented.');
  }

  /// 设置是否连续扫码。
  Future<void> scannerSetContinueScan(bool enabled) {
    throw UnimplementedError(
      'scannerSetContinueScan() has not been implemented.',
    );
  }

  /// 获取连续扫码开关状态。
  Future<bool> scannerGetContinueScan() {
    throw UnimplementedError(
      'scannerGetContinueScan() has not been implemented.',
    );
  }

  /// 设置是否启用多码识读。
  Future<void> scannerSetMultiDecode(bool enabled) {
    throw UnimplementedError(
      'scannerSetMultiDecode() has not been implemented.',
    );
  }

  /// 获取多码识读开关状态。
  Future<bool> scannerGetMultiDecode() {
    throw UnimplementedError(
      'scannerGetMultiDecode() has not been implemented.',
    );
  }

  /// 设置多码识读时一次最多读取的条码数量。
  Future<void> scannerSetMultiReadNumber(int number) {
    throw UnimplementedError(
      'scannerSetMultiReadNumber() has not been implemented.',
    );
  }

  /// 获取多码识读的最大读取数量。
  Future<int> scannerGetMultiReadNumber() {
    throw UnimplementedError(
      'scannerGetMultiReadNumber() has not been implemented.',
    );
  }

  /// 设置是否禁止重复输出同一条码。
  Future<void> scannerSetDisableSameBarcode(bool disabled) {
    throw UnimplementedError(
      'scannerSetDisableSameBarcode() has not been implemented.',
    );
  }

  /// 获取禁止重复输出同一条码的开关状态。
  Future<bool> scannerGetDisableSameBarcode() {
    throw UnimplementedError(
      'scannerGetDisableSameBarcode() has not been implemented.',
    );
  }

  /// 设置扫码结果广播 Action。
  Future<void> scannerSetBroadcastAction(String action) {
    throw UnimplementedError(
      'scannerSetBroadcastAction() has not been implemented.',
    );
  }

  /// 获取扫码结果广播 Action。
  Future<String> scannerGetBroadcastAction() {
    throw UnimplementedError(
      'scannerGetBroadcastAction() has not been implemented.',
    );
  }

  /// 设置扫码结果广播中承载条码文本的 Key。
  Future<void> scannerSetBroadcastKey(String key) {
    throw UnimplementedError(
      'scannerSetBroadcastKey() has not been implemented.',
    );
  }

  /// 获取扫码结果广播中承载条码文本的 Key。
  Future<String> scannerGetBroadcastKey() {
    throw UnimplementedError(
      'scannerGetBroadcastKey() has not been implemented.',
    );
  }

  /// 设置扫码结果输出方式。
  Future<void> scannerSetOutputMode(Nf5503ScanOutputMode mode) {
    throw UnimplementedError(
      'scannerSetOutputMode() has not been implemented.',
    );
  }

  /// 获取扫码结果输出方式。
  Future<Nf5503ScanOutputMode> scannerGetOutputMode() {
    throw UnimplementedError(
      'scannerGetOutputMode() has not been implemented.',
    );
  }

  /// 设置扫码数据编码模式。
  Future<void> scannerSetDecodeMode(Nf5503ScanDecodeMode mode) {
    throw UnimplementedError(
      'scannerSetDecodeMode() has not been implemented.',
    );
  }

  /// 获取扫码数据编码模式。
  Future<Nf5503ScanDecodeMode> scannerGetDecodeMode() {
    throw UnimplementedError(
      'scannerGetDecodeMode() has not been implemented.',
    );
  }

  /// 设置扫码结果末尾追加字符。
  Future<void> scannerSetEndMark(Nf5503ScanEndMark mark) {
    throw UnimplementedError('scannerSetEndMark() has not been implemented.');
  }

  /// 获取扫码结果末尾追加字符。
  Future<Nf5503ScanEndMark> scannerGetEndMark() {
    throw UnimplementedError('scannerGetEndMark() has not been implemented.');
  }

  /// 设置是否由 SDK 接管实体扫码键。
  Future<void> scannerSetHandleKey(bool enabled) {
    throw UnimplementedError('scannerSetHandleKey() has not been implemented.');
  }

  /// 获取实体扫码键接管状态。
  Future<bool> scannerGetHandleKey() {
    throw UnimplementedError('scannerGetHandleKey() has not been implemented.');
  }

  /// 设置连续扫码间隔时间，单位毫秒。
  Future<bool> scannerSetIntervalTime(int milliseconds) {
    throw UnimplementedError(
      'scannerSetIntervalTime() has not been implemented.',
    );
  }

  /// 获取连续扫码间隔时间，单位毫秒。
  Future<int> scannerGetIntervalTime() {
    throw UnimplementedError(
      'scannerGetIntervalTime() has not been implemented.',
    );
  }

  /// 设置单次解码超时时间，单位毫秒。
  Future<void> scannerSetDecodeTimeout(int milliseconds) {
    throw UnimplementedError(
      'scannerSetDecodeTimeout() has not been implemented.',
    );
  }

  /// 获取单次解码超时时间，单位毫秒。
  Future<int> scannerGetDecodeTimeout() {
    throw UnimplementedError(
      'scannerGetDecodeTimeout() has not been implemented.',
    );
  }

  /// 设置松开扫码键时是否停止扫码。
  Future<void> scannerSetLiftToStop(bool enabled) {
    throw UnimplementedError(
      'scannerSetLiftToStop() has not been implemented.',
    );
  }

  /// 获取松开扫码键停止扫码的开关状态。
  Future<bool> scannerGetLiftToStop() {
    throw UnimplementedError(
      'scannerGetLiftToStop() has not been implemented.',
    );
  }

  /// 批量设置码制参数。
  Future<void> scannerSetSymbologyValues(Map<int, int> values) {
    throw UnimplementedError(
      'scannerSetSymbologyValues() has not been implemented.',
    );
  }

  /// 批量读取码制参数值。
  Future<List<int>> scannerGetSymbologyValues(List<int> paramIds) {
    throw UnimplementedError(
      'scannerGetSymbologyValues() has not been implemented.',
    );
  }

  /// 一次性启用或禁用全部码制。
  Future<void> scannerEnableAllSymbologies(bool enabled) {
    throw UnimplementedError(
      'scannerEnableAllSymbologies() has not been implemented.',
    );
  }

  /// 启用或禁用指定码制。
  Future<void> scannerEnableSymbology({
    required int symbologyId,
    required bool enabled,
  }) {
    throw UnimplementedError(
      'scannerEnableSymbology() has not been implemented.',
    );
  }

  /// 一次性启用或禁用全部一维码制。
  Future<void> scannerEnableAll1dSymbologies(bool enabled) {
    throw UnimplementedError(
      'scannerEnableAll1dSymbologies() has not been implemented.',
    );
  }

  /// 一次性启用或禁用全部二维码制。
  Future<void> scannerEnableAll2dSymbologies(bool enabled) {
    throw UnimplementedError(
      'scannerEnableAll2dSymbologies() has not been implemented.',
    );
  }

  /// 查询指定码制是否已启用。
  Future<bool> scannerIsSymbologyEnabled(int symbologyId) {
    throw UnimplementedError(
      'scannerIsSymbologyEnabled() has not been implemented.',
    );
  }

  /// 查询指定码制是否受当前扫描头支持。
  Future<bool> scannerIsSymbologySupported(int symbologyId) {
    throw UnimplementedError(
      'scannerIsSymbologySupported() has not been implemented.',
    );
  }

  /// 重置扫码 SDK 配置。
  Future<void> scannerReset() {
    throw UnimplementedError('scannerReset() has not been implemented.');
  }

  /// 监听打印机版本和打印状态事件。
  Stream<Nf5503PrintEvent> printerEvents() {
    throw UnimplementedError('printerEvents() has not been implemented.');
  }

  /// 获取打印机固件或 SDK 版本号。
  Future<String> printerGetVersion() {
    throw UnimplementedError('printerGetVersion() has not been implemented.');
  }

  /// 打开打印机。
  Future<bool> printerOpen() {
    throw UnimplementedError('printerOpen() has not been implemented.');
  }

  /// 关闭打印机。
  Future<bool> printerClose() {
    throw UnimplementedError('printerClose() has not been implemented.');
  }

  /// 设置打印浓度。
  Future<void> printerSetConcentration(int density) {
    throw UnimplementedError(
      'printerSetConcentration() has not been implemented.',
    );
  }

  /// 获取当前打印浓度。
  Future<int> printerGetConcentration() {
    throw UnimplementedError(
      'printerGetConcentration() has not been implemented.',
    );
  }

  /// 重置打印机。
  Future<int> printerReset() {
    throw UnimplementedError('printerReset() has not been implemented.');
  }

  /// 设置字体类型。
  Future<void> printerSetFontType(String fontType) {
    throw UnimplementedError('printerSetFontType() has not been implemented.');
  }

  /// 获取当前字体类型。
  Future<String> printerGetFontType() {
    throw UnimplementedError('printerGetFontType() has not been implemented.');
  }

  /// 设置打印字体大小。
  Future<void> printerSetFontSize(Nf5503PrintFontSize fontSize) {
    throw UnimplementedError('printerSetFontSize() has not been implemented.');
  }

  /// 获取当前打印字体大小。
  Future<Nf5503PrintFontSize> printerGetFontSize() {
    throw UnimplementedError('printerGetFontSize() has not been implemented.');
  }

  /// 设置默认文本是否加粗。
  Future<void> printerSetBold(bool enabled) {
    throw UnimplementedError('printerSetBold() has not been implemented.');
  }

  /// 查询默认文本是否加粗。
  Future<bool> printerIsBold() {
    throw UnimplementedError('printerIsBold() has not been implemented.');
  }

  /// 设置是否启用黑标/标签模式。
  Future<void> printerSetBlackMark(bool enabled) {
    throw UnimplementedError('printerSetBlackMark() has not been implemented.');
  }

  /// 查询是否启用黑标/标签模式。
  Future<bool> printerIsBlackMark() {
    throw UnimplementedError('printerIsBlackMark() has not been implemented.');
  }

  /// 设置黑标检测阈值。
  Future<int> printerSetThreshold(int threshold) {
    throw UnimplementedError('printerSetThreshold() has not been implemented.');
  }

  /// 设置默认文本是否带下划线。
  Future<void> printerSetUnderline(bool enabled) {
    throw UnimplementedError('printerSetUnderline() has not been implemented.');
  }

  /// 查询默认文本是否带下划线。
  Future<bool> printerIsUnderline() {
    throw UnimplementedError('printerIsUnderline() has not been implemented.');
  }

  /// 设置走纸间距。
  Future<void> printerSetFeedPaperSpace(int space) {
    throw UnimplementedError(
      'printerSetFeedPaperSpace() has not been implemented.',
    );
  }

  /// 获取走纸间距。
  Future<int> printerGetFeedPaperSpace() {
    throw UnimplementedError(
      'printerGetFeedPaperSpace() has not been implemented.',
    );
  }

  /// 设置标签模式回退纸长度。
  Future<void> printerSetUnwindPaperLength(int length) {
    throw UnimplementedError(
      'printerSetUnwindPaperLength() has not been implemented.',
    );
  }

  /// 获取标签模式回退纸长度。
  Future<int> printerGetUnwindPaperLength() {
    throw UnimplementedError(
      'printerGetUnwindPaperLength() has not been implemented.',
    );
  }

  /// 添加文本到打印队列。
  Future<void> printerAddText(
    String content, {
    Nf5503PrintAlign align = Nf5503PrintAlign.left,
    Nf5503PrintFontSize fontSize = Nf5503PrintFontSize.middle,
    bool isBold = false,
    bool isUnderline = false,
  }) {
    throw UnimplementedError('printerAddText() has not been implemented.');
  }

  /// 添加一维条码到打印队列。
  Future<void> printerAddBarcode({
    required String content,
    required int height,
    required Nf5503BarcodeType type,
    Nf5503PrintAlign align = Nf5503PrintAlign.center,
    Nf5503HriPosition hriPosition = Nf5503HriPosition.below,
  }) {
    throw UnimplementedError('printerAddBarcode() has not been implemented.');
  }

  /// 添加二维码到打印队列。
  Future<void> printerAddQrCode(
    String content, {
    Nf5503PrintAlign align = Nf5503PrintAlign.center,
    int size = 384,
  }) {
    throw UnimplementedError('printerAddQrCode() has not been implemented.');
  }

  /// 添加内存图片到打印队列。
  Future<void> printerAddImageBytes(
    Uint8List imageBytes, {
    Nf5503PrintAlign align = Nf5503PrintAlign.center,
  }) {
    throw UnimplementedError(
      'printerAddImageBytes() has not been implemented.',
    );
  }

  /// 添加本地文件图片到打印队列。
  Future<void> printerAddImagePath(
    String imagePath, {
    Nf5503PrintAlign align = Nf5503PrintAlign.center,
  }) {
    throw UnimplementedError('printerAddImagePath() has not been implemented.');
  }

  /// 添加指定数量的空行到打印队列。
  Future<void> printerAddBlankLines(int lines) {
    throw UnimplementedError(
      'printerAddBlankLines() has not been implemented.',
    );
  }

  /// 开始打印当前队列中的内容。
  Future<void> printerStart() {
    throw UnimplementedError('printerStart() has not been implemented.');
  }

  /// 设置是否反白打印。
  Future<void> printerSetReverse(bool enabled) {
    throw UnimplementedError('printerSetReverse() has not been implemented.');
  }

  /// 查询是否反白打印。
  Future<bool> printerIsReverse() {
    throw UnimplementedError('printerIsReverse() has not been implemented.');
  }

  /// 标签模式下走纸到下一张黑标。
  Future<void> printerGoToNextMark({int? distance}) {
    throw UnimplementedError('printerGoToNextMark() has not been implemented.');
  }

  /// 设置行间距。
  Future<void> printerSetLineSpacing(double spacing) {
    throw UnimplementedError(
      'printerSetLineSpacing() has not been implemented.',
    );
  }

  /// 获取当前行间距设置。
  Future<double> printerGetLineSpacing() {
    throw UnimplementedError(
      'printerGetLineSpacing() has not been implemented.',
    );
  }

  /// 查询当前设备是否支持打印模块。
  Future<int> printerGetSupportPrint() {
    throw UnimplementedError(
      'printerGetSupportPrint() has not been implemented.',
    );
  }

  /// 查询指定类型的打印机状态。
  Future<int> printerGetState(Nf5503PrinterStateType stateType) {
    throw UnimplementedError('printerGetState() has not been implemented.');
  }
}
