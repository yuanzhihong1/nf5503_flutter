import 'dart:typed_data';

import 'nf5503_flutter_platform_interface.dart';
import 'src/nf5503_nfc_types.dart';
import 'src/nf5503_scan_constants.dart';
import 'src/nf5503_types.dart';

export 'src/nf5503_nfc_types.dart';
export 'src/nf5503_scan_constants.dart';
export 'src/nf5503_types.dart';

/// NF5503 扫码与打印 Flutter 插件入口。
class Nf5503Flutter {
  /// 创建插件入口，可注入自定义扫码或打印门面便于测试。
  Nf5503Flutter({
    Nf5503Scanner? scanner,
    Nf5503Printer? printer,
    Nf5503Nfc? nfc,
  })  : scanner = scanner ?? const Nf5503Scanner(),
        printer = printer ?? const Nf5503Printer(),
        nfc = nfc ?? const Nf5503Nfc();

  /// 扫码 SDK 操作门面。
  final Nf5503Scanner scanner;

  /// 打印 SDK 操作门面。
  final Nf5503Printer printer;

  /// Android NFC 操作门面。
  final Nf5503Nfc nfc;

  /// 获取当前 Android 平台版本字符串。
  Future<String?> getPlatformVersion() {
    return Nf5503FlutterPlatform.instance.getPlatformVersion();
  }
}

/// NF5503 扫码 SDK 的 Flutter 端 API。
class Nf5503Scanner {
  /// 创建扫码 API 门面。
  const Nf5503Scanner();

  Nf5503FlutterPlatform get _platform => Nf5503FlutterPlatform.instance;

  /// 监听扫码广播结果，可传入自定义广播 [action] 和数据 [key]。
  Stream<Nf5503ScanResult> results({String? action, String? key}) {
    return _platform.scannerResults(action: action, key: key);
  }

  /// 打开扫码头，返回原生 SDK 是否打开成功。
  Future<bool> open() => _platform.scannerOpen();

  /// 关闭扫码头，返回原生 SDK 是否关闭成功。
  Future<bool> close() => _platform.scannerClose();

  /// 触发一次扫码解码。
  Future<bool> startDecode() => _platform.scannerStartDecode();

  /// 停止当前扫码解码。
  Future<bool> stopDecode() => _platform.scannerStopDecode();

  /// 查询扫码头当前是否已打开。
  Future<bool> isOpen() => _platform.scannerIsOpen();

  /// 获取设备支持的码制信息列表，字段由原生 SDK 对象反射得出。
  Future<List<Map<String, Object?>>> getSymbologyList() =>
      _platform.scannerGetSymbologyList();

  /// 初始化所有码制参数为 SDK 默认值。
  Future<void> initSymbologySettings() {
    return _platform.scannerInitSymbologySettings();
  }

  /// 获取当前扫描头硬件类型。
  ///
  /// 厂商 SDK 新增但本插件尚未识别的类型会返回
  /// [Nf5503ScannerType.unknown]；需要原始 ID 时使用 [getScannerTypeId]。
  Future<Nf5503ScannerType> getScannerType() {
    return _platform.scannerGetScannerType();
  }

  /// 获取当前扫描头硬件类型的原始 SDK ID。
  ///
  /// 该方法不会把新增扫描头折叠为 `unknown`，适合做设备能力判断。
  Future<int> getScannerTypeId() {
    return _platform.scannerGetScannerTypeId();
  }

  /// 查询当前扫描头是否与其它扫描服务冲突。
  Future<bool> isConflicted() => _platform.scannerIsConflicted();

  /// 连接底层解码器。
  Future<void> connectDecoder() => _platform.scannerConnectDecoder();

  /// 断开底层解码器。
  Future<void> disconnectDecoder() => _platform.scannerDisconnectDecoder();

  /// 查询底层解码器状态。
  Future<bool> getDecoderStatus() => _platform.scannerGetDecoderStatus();

  /// 查询底层解码器是否已连接。
  Future<bool> isDecoderConnected() => _platform.scannerIsDecoderConnected();

  /// 设置扫码结果前缀。
  Future<void> setPrefix(String prefix) => _platform.scannerSetPrefix(prefix);

  /// 获取扫码结果前缀。
  Future<String> getPrefix() => _platform.scannerGetPrefix();

  /// 设置扫码结果后缀。
  Future<void> setSuffix(String suffix) => _platform.scannerSetSuffix(suffix);

  /// 获取扫码结果后缀。
  Future<String> getSuffix() => _platform.scannerGetSuffix();

  /// 设置扫码过滤规则。
  Future<void> setFilter(String filter) => _platform.scannerSetFilter(filter);

  /// 获取扫码过滤规则。
  Future<String> getFilter() => _platform.scannerGetFilter();

  /// 设置扫码成功后是否播放提示音。
  Future<void> setPlaySound(bool enabled) {
    return _platform.scannerSetPlaySound(enabled);
  }

  /// 获取扫码成功提示音开关状态。
  Future<bool> getPlaySound() => _platform.scannerGetPlaySound();

  /// 设置扫码成功后是否震动。
  Future<void> setVibrate(bool enabled) {
    return _platform.scannerSetVibrate(enabled);
  }

  /// 获取扫码成功震动开关状态。
  Future<bool> getVibrate() => _platform.scannerGetVibrate();

  /// 设置是否连续扫码。
  Future<void> setContinueScan(bool enabled) {
    return _platform.scannerSetContinueScan(enabled);
  }

  /// 获取连续扫码开关状态。
  Future<bool> getContinueScan() => _platform.scannerGetContinueScan();

  /// 设置是否启用多码识读。
  Future<void> setMultiDecode(bool enabled) {
    return _platform.scannerSetMultiDecode(enabled);
  }

  /// 获取多码识读开关状态。
  Future<bool> getMultiDecode() => _platform.scannerGetMultiDecode();

  /// 设置多码识读时一次最多读取的条码数量。
  Future<void> setMultiReadNumber(int number) {
    return _platform.scannerSetMultiReadNumber(number);
  }

  /// 获取多码识读的最大读取数量。
  Future<int> getMultiReadNumber() => _platform.scannerGetMultiReadNumber();

  /// 设置是否禁止重复输出同一条码。
  Future<void> setDisableSameBarcode(bool disabled) {
    return _platform.scannerSetDisableSameBarcode(disabled);
  }

  /// 获取禁止重复输出同一条码的开关状态。
  Future<bool> getDisableSameBarcode() {
    return _platform.scannerGetDisableSameBarcode();
  }

  /// 设置扫码结果广播 Action。
  Future<void> setBroadcastAction(String action) {
    return _platform.scannerSetBroadcastAction(action);
  }

  /// 获取扫码结果广播 Action。
  Future<String> getBroadcastAction() {
    return _platform.scannerGetBroadcastAction();
  }

  /// 设置扫码结果广播中承载条码文本的 Key。
  Future<void> setBroadcastKey(String key) {
    return _platform.scannerSetBroadcastKey(key);
  }

  /// 获取扫码结果广播中承载条码文本的 Key。
  Future<String> getBroadcastKey() => _platform.scannerGetBroadcastKey();

  /// 设置扫码结果输出方式。
  Future<void> setOutputMode(Nf5503ScanOutputMode mode) {
    return _platform.scannerSetOutputMode(mode);
  }

  /// 获取扫码结果输出方式。
  Future<Nf5503ScanOutputMode> getOutputMode() {
    return _platform.scannerGetOutputMode();
  }

  /// 设置扫码数据编码模式。
  Future<void> setDecodeMode(Nf5503ScanDecodeMode mode) {
    return _platform.scannerSetDecodeMode(mode);
  }

  /// 获取扫码数据编码模式。
  Future<Nf5503ScanDecodeMode> getDecodeMode() {
    return _platform.scannerGetDecodeMode();
  }

  /// 设置扫码结果末尾追加字符。
  Future<void> setEndMark(Nf5503ScanEndMark mark) {
    return _platform.scannerSetEndMark(mark);
  }

  /// 获取扫码结果末尾追加字符。
  Future<Nf5503ScanEndMark> getEndMark() {
    return _platform.scannerGetEndMark();
  }

  /// 设置是否由 SDK 接管实体扫码键。
  Future<void> setHandleKey(bool enabled) {
    return _platform.scannerSetHandleKey(enabled);
  }

  /// 获取实体扫码键接管状态。
  Future<bool> getHandleKey() => _platform.scannerGetHandleKey();

  /// 设置连续扫码间隔时间，单位毫秒，返回 SDK 是否接受该值。
  Future<bool> setIntervalTime(int milliseconds) {
    return _platform.scannerSetIntervalTime(milliseconds);
  }

  /// 获取连续扫码间隔时间，单位毫秒。
  Future<int> getIntervalTime() => _platform.scannerGetIntervalTime();

  /// 设置单次解码超时时间，单位毫秒。
  Future<void> setDecodeTimeout(int milliseconds) {
    return _platform.scannerSetDecodeTimeout(milliseconds);
  }

  /// 获取单次解码超时时间，单位毫秒。
  Future<int> getDecodeTimeout() => _platform.scannerGetDecodeTimeout();

  /// 设置松开扫码键时是否停止扫码。
  Future<void> setLiftToStop(bool enabled) {
    return _platform.scannerSetLiftToStop(enabled);
  }

  /// 获取松开扫码键停止扫码的开关状态。
  Future<bool> getLiftToStop() => _platform.scannerGetLiftToStop();

  /// 批量设置码制参数，Map 的 key 为 [Nf5503ScanParamId] 参数 ID。
  Future<void> setSymbologyValues(Map<int, int> values) {
    return _platform.scannerSetSymbologyValues(values);
  }

  /// 批量读取码制参数值，返回顺序与 [paramIds] 一致。
  Future<List<int>> getSymbologyValues(List<int> paramIds) {
    return _platform.scannerGetSymbologyValues(paramIds);
  }

  /// 设置单个码制参数，对应原生 `setSYMValueInts` 的单元素调用。
  Future<void> setParameter(int paramId, int value) {
    return setSymbologyValues(<int, int>{paramId: value});
  }

  /// 读取单个码制参数，对应原生 `getSYMValueInts` 的单元素调用。
  Future<int> getParameter(int paramId) async {
    final values = await getSymbologyValues(<int>[paramId]);
    if (values.isEmpty) {
      throw StateError('The SDK returned no value for parameter $paramId.');
    }
    return values.first;
  }

  /// 设置补光/瞄准灯模式，值使用 [Nf5503ScanLightsMode]。
  Future<void> setLightsMode(int mode) {
    return setParameter(Nf5503ScanParamId.LIGHTS_MODE, mode);
  }

  /// 读取补光/瞄准灯模式，返回值可对照 [Nf5503ScanLightsMode]。
  Future<int> getLightsMode() {
    return getParameter(Nf5503ScanParamId.LIGHTS_MODE);
  }

  /// 一次性启用或禁用全部码制。
  Future<void> enableAllSymbologies(bool enabled) {
    return _platform.scannerEnableAllSymbologies(enabled);
  }

  /// 启用或禁用指定码制。
  Future<void> enableSymbology({
    required int symbologyId,
    required bool enabled,
  }) {
    return _platform.scannerEnableSymbology(
      symbologyId: symbologyId,
      enabled: enabled,
    );
  }

  /// 一次性启用或禁用全部一维码制。
  Future<void> enableAll1dSymbologies(bool enabled) {
    return _platform.scannerEnableAll1dSymbologies(enabled);
  }

  /// 一次性启用或禁用全部二维码制。
  Future<void> enableAll2dSymbologies(bool enabled) {
    return _platform.scannerEnableAll2dSymbologies(enabled);
  }

  /// 查询指定码制是否已启用。
  Future<bool> isSymbologyEnabled(int symbologyId) {
    return _platform.scannerIsSymbologyEnabled(symbologyId);
  }

  /// 查询指定码制是否受当前扫描头支持。
  Future<bool> isSymbologySupported(int symbologyId) {
    return _platform.scannerIsSymbologySupported(symbologyId);
  }

  /// 重置扫码 SDK 配置。
  Future<void> reset() => _platform.scannerReset();
}

/// NF5503 打印 SDK 的 Flutter 端 API。
class Nf5503Printer {
  /// 创建打印 API 门面。
  const Nf5503Printer();

  Nf5503FlutterPlatform get _platform => Nf5503FlutterPlatform.instance;

  /// 监听打印机版本和打印状态事件。
  Stream<Nf5503PrintEvent> events() => _platform.printerEvents();

  /// 获取打印机固件或 SDK 版本号。
  Future<String> getVersion() => _platform.printerGetVersion();

  /// 打开打印机，返回原生 SDK 是否打开成功。
  Future<bool> open() => _platform.printerOpen();

  /// 关闭打印机，返回原生 SDK 是否关闭成功。
  Future<bool> close() => _platform.printerClose();

  /// 设置打印浓度，传入官方 1 到 39 的业务值并映射到原生 1 到 10 档。
  Future<void> setConcentration(int density) {
    return _platform.printerSetConcentration(density);
  }

  /// 获取当前打印浓度业务值，原生 1 到 10 档会映射回 4 到 40。
  Future<int> getConcentration() => _platform.printerGetConcentration();

  /// 重置打印机，返回原生 SDK 状态码。
  Future<int> reset() => _platform.printerReset();

  /// 设置字体类型，参数值由设备系统字体或原生 SDK 支持情况决定。
  Future<void> setFontType(String fontType) {
    return _platform.printerSetFontType(fontType);
  }

  /// 获取当前字体类型。
  Future<String> getFontType() => _platform.printerGetFontType();

  /// 设置打印字体大小。
  Future<void> setFontSize(Nf5503PrintFontSize fontSize) {
    return _platform.printerSetFontSize(fontSize);
  }

  /// 获取当前打印字体大小。
  Future<Nf5503PrintFontSize> getFontSize() {
    return _platform.printerGetFontSize();
  }

  /// 设置默认文本是否加粗。
  Future<void> setBold(bool enabled) => _platform.printerSetBold(enabled);

  /// 查询默认文本是否加粗。
  Future<bool> isBold() => _platform.printerIsBold();

  /// 设置是否启用黑标/标签模式。
  Future<void> setBlackMark(bool enabled) {
    return _platform.printerSetBlackMark(enabled);
  }

  /// 查询是否启用黑标/标签模式。
  Future<bool> isBlackMark() => _platform.printerIsBlackMark();

  /// 设置黑标检测阈值，返回原生 SDK 状态码。
  Future<int> setThreshold(int threshold) {
    return _platform.printerSetThreshold(threshold);
  }

  /// 设置默认文本是否带下划线。
  Future<void> setUnderline(bool enabled) {
    return _platform.printerSetUnderline(enabled);
  }

  /// 查询默认文本是否带下划线。
  Future<bool> isUnderline() => _platform.printerIsUnderline();

  /// 设置走纸间距。
  Future<void> setFeedPaperSpace(int space) {
    return _platform.printerSetFeedPaperSpace(space);
  }

  /// 获取走纸间距。
  Future<int> getFeedPaperSpace() => _platform.printerGetFeedPaperSpace();

  /// 设置标签模式回退纸长度。
  Future<void> setUnwindPaperLength(int length) {
    return _platform.printerSetUnwindPaperLength(length);
  }

  /// 获取标签模式回退纸长度。
  Future<int> getUnwindPaperLength() {
    return _platform.printerGetUnwindPaperLength();
  }

  /// 添加文本到打印队列，可覆盖本次文本的对齐、字号、加粗和下划线。
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

  /// 添加一维条码到打印队列。
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

  /// 添加二维码到打印队列。
  Future<void> addQrCode(
    String content, {
    Nf5503PrintAlign align = Nf5503PrintAlign.center,
    int size = 384,
  }) {
    return _platform.printerAddQrCode(content, align: align, size: size);
  }

  /// 添加内存图片到打印队列，支持的图片格式由 Android Bitmap 解码器决定。
  Future<void> addImageBytes(
    Uint8List imageBytes, {
    Nf5503PrintAlign align = Nf5503PrintAlign.center,
  }) {
    return _platform.printerAddImageBytes(imageBytes, align: align);
  }

  /// 添加本地文件图片到打印队列。
  Future<void> addImagePath(
    String imagePath, {
    Nf5503PrintAlign align = Nf5503PrintAlign.center,
  }) {
    return _platform.printerAddImagePath(imagePath, align: align);
  }

  /// 添加指定数量的空行到打印队列。
  Future<void> addBlankLines(int lines) {
    return _platform.printerAddBlankLines(lines);
  }

  /// 开始打印当前队列中的内容。
  Future<void> start() => _platform.printerStart();

  /// 设置是否反白打印。
  Future<void> setReverse(bool enabled) {
    return _platform.printerSetReverse(enabled);
  }

  /// 查询是否反白打印。
  Future<bool> isReverse() => _platform.printerIsReverse();

  /// 标签模式下走纸到下一张黑标，可选指定走纸距离。
  Future<void> goToNextMark({int? distance}) {
    return _platform.printerGoToNextMark(distance: distance);
  }

  /// 设置行间距倍率或间距值，具体含义以原生 SDK 为准。
  Future<void> setLineSpacing(double spacing) {
    return _platform.printerSetLineSpacing(spacing);
  }

  /// 获取当前行间距设置。
  Future<double> getLineSpacing() => _platform.printerGetLineSpacing();

  /// 查询当前设备是否支持打印模块。
  Future<int> getSupportPrint() => _platform.printerGetSupportPrint();

  /// 查询指定类型的打印机状态。
  Future<int> getState(Nf5503PrinterStateType stateType) {
    return _platform.printerGetState(stateType);
  }
}

/// Android NFC 操作门面。
///
/// 使用 Android 前台 Reader Mode 接收标签，适用于 Flutter 页面处于前台时的
/// NDEF 读写和 Mifare Classic 操作。
class Nf5503Nfc {
  /// 创建 NFC API 门面。
  const Nf5503Nfc();

  Nf5503FlutterPlatform get _platform => Nf5503FlutterPlatform.instance;

  /// 监听标签发现、标签离开和 NFC 适配器状态变化。
  ///
  /// 第一个订阅建立时插件会自动启动 NFC Reader Mode，最后一个订阅取消时停止。
  Stream<Nf5503NfcEvent> events() => _platform.nfcEvents();

  /// 查询设备是否具备 NFC 硬件。
  Future<bool> isSupported() => _platform.nfcIsSupported();

  /// 查询 NFC 当前是否启用。
  Future<bool> isEnabled() => _platform.nfcIsEnabled();

  /// 获取 NFC 硬件、开关和 Reader Mode 的完整状态。
  Future<Nf5503NfcStatus> getStatus() => _platform.nfcGetStatus();

  /// 打开系统 NFC 设置页面。
  Future<void> openSettings() => _platform.nfcOpenSettings();

  /// 手动启动前台标签发现。
  ///
  /// 订阅 [events] 时会自动调用；只有需要在无事件订阅时保留当前标签才需手动调用。
  Future<void> startDiscovery() => _platform.nfcStartDiscovery();

  /// 停止前台标签发现。
  Future<void> stopDiscovery() => _platform.nfcStopDiscovery();

  /// 获取最近一次发现且尚未离开的标签。
  Future<Nf5503NfcTagInfo?> getCurrentTag() => _platform.nfcGetCurrentTag();

  /// 读取当前 NDEF 标签消息；没有 NDEF 内容时返回 null。
  Future<Nf5503NdefMessage?> readNdef() => _platform.nfcReadNdef();

  /// 向当前标签写入一条 NDEF 文本记录。
  Future<void> writeNdefText(
    String text, {
    String languageCode = 'en',
  }) {
    return _platform.nfcWriteNdefText(text, languageCode: languageCode);
  }

  /// 向当前标签写入一条 NDEF URI 记录。
  Future<void> writeNdefUri(String uri) => _platform.nfcWriteNdefUri(uri);

  /// 向当前标签写入一条 MIME 记录。
  Future<void> writeNdefMime(String mimeType, Uint8List data) {
    return _platform.nfcWriteNdefMime(mimeType, data);
  }

  /// 写入完整 NDEF 消息原始字节。
  ///
  /// [formatIfNeeded] 为 true 时，非 NDEF 但支持格式化的标签会先被格式化。
  Future<void> writeNdefMessage(
    Uint8List message, {
    bool formatIfNeeded = true,
  }) {
    return _platform.nfcWriteNdefMessage(
      message,
      formatIfNeeded: formatIfNeeded,
    );
  }

  /// 将当前 NDEF 标签设置为只读。
  Future<void> makeNdefReadOnly() => _platform.nfcMakeNdefReadOnly();

  /// 获取当前标签的 Mifare Classic 能力；不是 Mifare Classic 时返回 null。
  Future<Nf5503MifareClassicInfo?> getMifareClassicInfo() {
    return _platform.nfcGetMifareClassicInfo();
  }

  /// 连接 Mifare Classic 标签。
  Future<void> connectMifare() => _platform.nfcMifareConnect();

  /// 断开 Mifare Classic 标签。
  Future<void> closeMifare() => _platform.nfcMifareClose();

  /// 查询 Mifare Classic 是否已连接。
  Future<bool> isMifareConnected() => _platform.nfcMifareIsConnected();

  /// 设置 Mifare Classic transceive 超时，单位毫秒。
  Future<void> setMifareTimeout(int milliseconds) {
    return _platform.nfcMifareSetTimeout(milliseconds);
  }

  /// 使用 Key A 或 Key B 鉴权指定扇区。
  Future<bool> authenticateMifareSector({
    required int sectorIndex,
    required Uint8List key,
    Nf5503MifareKeyType keyType = Nf5503MifareKeyType.keyA,
  }) {
    return _platform.nfcMifareAuthenticate(
      sectorIndex: sectorIndex,
      key: key,
      keyType: keyType,
    );
  }

  /// 读取已连接且已鉴权扇区中的 16 字节块。
  Future<Uint8List> readMifareBlock(int blockIndex) {
    return _platform.nfcMifareReadBlock(blockIndex);
  }

  /// 写入已连接且已鉴权扇区中的 16 字节块。
  Future<void> writeMifareBlock(int blockIndex, Uint8List data) {
    return _platform.nfcMifareWriteBlock(blockIndex, data);
  }

  /// 向 Mifare Classic 发送原始厂商指令。
  Future<Uint8List> transceiveMifare(Uint8List data) {
    return _platform.nfcMifareTransceive(data);
  }

  /// 递增指定值块。
  Future<void> incrementMifareBlock(int blockIndex, int value) {
    return _platform.nfcMifareIncrement(blockIndex, value);
  }

  /// 递减指定值块。
  Future<void> decrementMifareBlock(int blockIndex, int value) {
    return _platform.nfcMifareDecrement(blockIndex, value);
  }

  /// 将值块恢复到临时块。
  Future<void> restoreMifareBlock(int blockIndex) {
    return _platform.nfcMifareRestore(blockIndex);
  }

  /// 将临时块转移至目标值块。
  Future<void> transferMifareBlock(int blockIndex) {
    return _platform.nfcMifareTransfer(blockIndex);
  }

  /// 查询块所属扇区。
  Future<int> mifareBlockToSector(int blockIndex) {
    return _platform.nfcMifareBlockToSector(blockIndex);
  }

  /// 查询扇区首块。
  Future<int> mifareSectorToBlock(int sectorIndex) {
    return _platform.nfcMifareSectorToBlock(sectorIndex);
  }

  /// 查询指定扇区的块数量。
  Future<int> mifareBlockCountInSector(int sectorIndex) {
    return _platform.nfcMifareBlockCountInSector(sectorIndex);
  }

  /// 查询标签总块数。
  Future<int> mifareBlockCount() => _platform.nfcMifareBlockCount();

  /// 查询标签扇区数。
  Future<int> mifareSectorCount() => _platform.nfcMifareSectorCount();

  /// 查询标签容量，单位字节。
  Future<int> mifareSize() => _platform.nfcMifareSize();

  /// 查询 Mifare Classic 兼容类型。
  Future<Nf5503MifareClassicType> mifareType() {
    return _platform.nfcMifareType();
  }

  /// 查询 transceive 最大长度。
  Future<int> mifareMaxTransceiveLength() {
    return _platform.nfcMifareMaxTransceiveLength();
  }

  /// 一次性连接、鉴权并读取块，完成后自动断开。
  Future<Uint8List> readMifareBlockWithKey({
    required int blockIndex,
    required Uint8List key,
    Nf5503MifareKeyType keyType = Nf5503MifareKeyType.keyA,
  }) async {
    await connectMifare();
    try {
      final sector = await mifareBlockToSector(blockIndex);
      final authenticated = await authenticateMifareSector(
        sectorIndex: sector,
        key: key,
        keyType: keyType,
      );
      if (!authenticated) {
        throw StateError('Mifare Classic authentication failed.');
      }
      return await readMifareBlock(blockIndex);
    } finally {
      await _closeMifareQuietly();
    }
  }

  /// 一次性连接、鉴权并写入块，完成后自动断开。
  ///
  /// [data] 为 1 到 16 字节；不足 16 字节时补零，与官方 Demo 的
  /// `Arrays.copyOf(bytes, 16)` 行为一致。
  Future<void> writeMifareBlockWithKey({
    required int blockIndex,
    required Uint8List data,
    required Uint8List key,
    Nf5503MifareKeyType keyType = Nf5503MifareKeyType.keyA,
  }) async {
    if (data.isEmpty || data.length > 16) {
      throw ArgumentError.value(data.length, 'data.length', 'must be 1..16');
    }
    final blockData = Uint8List(16)..setRange(0, data.length, data);
    await connectMifare();
    try {
      final sector = await mifareBlockToSector(blockIndex);
      final authenticated = await authenticateMifareSector(
        sectorIndex: sector,
        key: key,
        keyType: keyType,
      );
      if (!authenticated) {
        throw StateError('Mifare Classic authentication failed.');
      }
      await writeMifareBlock(blockIndex, blockData);
    } finally {
      await _closeMifareQuietly();
    }
  }

  /// 修改扇区尾块的 Key A 或 Key B，保留访问位和另一把密钥。
  Future<void> changeMifareSectorKey({
    required int sectorIndex,
    required Uint8List currentKey,
    required Uint8List newKey,
    Nf5503MifareKeyType keyType = Nf5503MifareKeyType.keyA,
  }) async {
    if (currentKey.length != 6) {
      throw ArgumentError.value(
        currentKey.length,
        'currentKey.length',
        'must be 6',
      );
    }
    if (newKey.length != 6) {
      throw ArgumentError.value(newKey.length, 'newKey.length', 'must be 6');
    }
    await connectMifare();
    try {
      final authenticated = await authenticateMifareSector(
        sectorIndex: sectorIndex,
        key: currentKey,
        keyType: keyType,
      );
      if (!authenticated) {
        throw StateError('Mifare Classic authentication failed.');
      }
      final firstBlock = await mifareSectorToBlock(sectorIndex);
      final blockCount = await mifareBlockCountInSector(sectorIndex);
      final trailerBlock = firstBlock + blockCount - 1;
      final trailer = Uint8List.fromList(
        await readMifareBlock(trailerBlock),
      );
      if (trailer.length != 16) {
        throw StateError('Mifare sector trailer must contain 16 bytes.');
      }
      final keyOffset = keyType == Nf5503MifareKeyType.keyA ? 0 : 10;
      trailer.setRange(keyOffset, keyOffset + 6, newKey);
      await writeMifareBlock(trailerBlock, trailer);
    } finally {
      await _closeMifareQuietly();
    }
  }

  Future<void> _closeMifareQuietly() async {
    try {
      await closeMifare();
    } catch (_) {
      // Closing after a lost tag or a failed operation must not mask the
      // original PlatformException.
    }
  }
}
