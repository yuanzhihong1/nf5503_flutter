/// 扫码结果输出方式，对应原生 ScanConfig.SCAN_OUTPUTMODE_* 常量。
enum Nf5503ScanOutputMode {
  /// 通过 Android 广播输出扫码结果。
  broadcast(0),

  /// 将扫码结果输入到当前输入框。
  inputBox(1),

  /// 以键盘模拟方式输出扫码结果。
  keyboard(2),

  /// 仅输入一次到当前输入框。
  singleInputBox(3),

  /// 将扫码结果写入剪贴板。
  clipboard(4);

  const Nf5503ScanOutputMode(this.value);

  /// 原生 SDK 使用的整数值。
  final int value;

  /// 根据原生 SDK 返回值转换为 Flutter 枚举，未知值默认按广播模式处理。
  static Nf5503ScanOutputMode fromValue(int value) {
    return values.firstWhere(
      (mode) => mode.value == value,
      orElse: () => Nf5503ScanOutputMode.broadcast,
    );
  }
}

/// 扫码结果末尾追加字符类型。
enum Nf5503ScanEndMark {
  /// 不追加结束符。
  none(0),

  /// 追加回车符。
  enter(1),

  /// 追加 Tab 符。
  tab(2);

  const Nf5503ScanEndMark(this.value);

  /// 原生 SDK 使用的整数值。
  final int value;

  /// 根据原生 SDK 返回值转换为 Flutter 枚举，未知值默认按不追加处理。
  static Nf5503ScanEndMark fromValue(int value) {
    return values.firstWhere(
      (mark) => mark.value == value,
      orElse: () => Nf5503ScanEndMark.none,
    );
  }
}

/// 扫码数据编码模式，对应原生 ScanConfig.SCAN_ENCODE_MODE_* 常量。
enum Nf5503ScanDecodeMode {
  /// UTF-8 编码。
  utf8(0),

  /// ASCII 编码。
  ascii(1),

  /// GBK 编码。
  gbk(2),

  /// GB2312 编码。
  gb2312(3),

  /// GB18030 编码。
  gb18030(4),

  /// UTF-16 编码。
  utf16(5),

  /// ISO-8859-1 编码。
  iso88591(6);

  const Nf5503ScanDecodeMode(this.value);

  /// 原生 SDK 使用的整数值。
  final int value;

  /// 根据原生 SDK 返回值转换为 Flutter 枚举，未知值默认按 UTF-8 处理。
  static Nf5503ScanDecodeMode fromValue(int value) {
    return values.firstWhere(
      (mode) => mode.value == value,
      orElse: () => Nf5503ScanDecodeMode.utf8,
    );
  }
}

/// 扫描头硬件类型，对应原生 ScannerType.SCAN_TYPE_ID_* 常量。
enum Nf5503ScannerType {
  /// 未检测到扫描头。
  none(0),

  /// UE966 扫描头。
  ue966(1),

  /// SE955 扫描头。
  se955(2),

  /// N4313 扫描头。
  n4313(3),

  /// N3680 扫描头。
  n3680(4),

  /// EM3096 扫描头。
  em3096(5),

  /// EM1300 扫描头。
  em1300(6),

  /// EM1395 扫描头。
  em1395(7),

  /// EM3090 扫描头。
  em3090(8),

  /// EM1365 扫描头。
  em1365(9),

  /// 9600 波特率串口扫描头。
  b9600(16),

  /// 115200 波特率串口扫描头。
  b115200(17),

  /// N6603 扫描头。
  n6603(33),

  /// IA181S 扫描头。
  ia181s(34),

  /// CM60 扫描头。
  cm60(35),

  /// HIK 扫描头。
  hik(36),

  /// 当前 SDK 未定义的扫描头类型。
  unknown(-1);

  const Nf5503ScannerType(this.value);

  /// 原生 SDK 使用的整数值。
  final int value;

  /// 根据原生 SDK 返回值转换为 Flutter 枚举，无法识别时返回 [unknown]。
  static Nf5503ScannerType fromValue(int value) {
    return values.firstWhere(
      (type) => type.value == value,
      orElse: () => Nf5503ScannerType.unknown,
    );
  }
}

/// 一次扫码广播解析后的结果。
class Nf5503ScanResult {
  /// 创建扫码结果对象。
  const Nf5503ScanResult({
    required this.data,
    this.action,
    this.extras = const <String, Object?>{},
  });

  /// 从原生 EventChannel 返回的 Map 中解析扫码结果。
  factory Nf5503ScanResult.fromMap(Map<Object?, Object?> map) {
    final extras = <String, Object?>{};
    final rawExtras = map['extras'];
    if (rawExtras is Map) {
      rawExtras.forEach((key, value) {
        extras[key.toString()] = value;
      });
    }

    return Nf5503ScanResult(
      data: map['data']?.toString() ?? '',
      action: map['action']?.toString(),
      extras: extras,
    );
  }

  /// 扫码文本内容。
  final String data;

  /// 收到结果的 Android 广播 Action。
  final String? action;

  /// 原始广播携带的 extras，方便业务读取条码类型等附加信息。
  final Map<String, Object?> extras;
}

/// 打印内容对齐方式，对应原生 PrintConfig.Align 常量。
enum Nf5503PrintAlign {
  /// 左对齐。
  left(1),

  /// 居中对齐。
  center(2),

  /// 右对齐。
  right(3);

  const Nf5503PrintAlign(this.value);

  /// 原生 SDK 使用的整数值。
  final int value;

  /// 根据原生 SDK 返回值转换为 Flutter 枚举，未知值默认左对齐。
  static Nf5503PrintAlign fromValue(int value) {
    return values.firstWhere(
      (align) => align.value == value,
      orElse: () => Nf5503PrintAlign.left,
    );
  }
}

/// 打印字体大小，对应原生 PrintConfig.FontSize 常量。
enum Nf5503PrintFontSize {
  /// 小号字体。
  small(1),

  /// XSmall 字号。
  xSmall(2),

  /// 中号字体。
  middle(3),

  /// XMiddle 字号。
  xMiddle(4),

  /// 大号字体。
  large(5),

  /// XLarge 字号。
  xLarge(6),

  /// 超大字体。
  superSize(7),

  /// XSuper 字号。
  xSuper(8);

  const Nf5503PrintFontSize(this.value);

  /// 原生 SDK 使用的整数值。
  final int value;

  /// 根据原生 SDK 返回值转换为 Flutter 枚举，未知值默认中号字体。
  static Nf5503PrintFontSize fromValue(int value) {
    return values.firstWhere(
      (size) => size.value == value,
      orElse: () => Nf5503PrintFontSize.middle,
    );
  }
}

/// 一维条码类型，对应原生 PrintConfig.BarCodeType 常量。
enum Nf5503BarcodeType {
  /// UPC-A 条码。
  upca(65),

  /// UPC-E 条码。
  upce(66),

  /// EAN-13 条码。
  ean13(67),

  /// EAN-8 条码。
  ean8(68),

  /// Code39 条码。
  code39(69),

  /// ITF 条码。
  itf(70),

  /// Codabar 条码。
  codabar(71),

  /// Code93 条码。
  code93(72),

  /// Code128 条码。
  code128(73);

  const Nf5503BarcodeType(this.value);

  /// 原生 SDK 使用的整数值。
  final int value;
}

/// 条码可读文本 HRI 的显示位置。
enum Nf5503HriPosition {
  /// 不显示 HRI 文本。
  none(1),

  /// 在条码上方显示 HRI 文本。
  above(2),

  /// 在条码下方显示 HRI 文本。
  below(3),

  /// 在条码上下方都显示 HRI 文本。
  both(4);

  const Nf5503HriPosition(this.value);

  /// 原生 SDK 使用的整数值。
  final int value;
}

/// 打印机状态查询类型。
enum Nf5503PrinterStateType {
  /// 查询所有状态。
  checkAll(1),

  /// 查询忙碌状态。
  checkBusy(2),

  /// 查询温度状态。
  checkTemp(3),

  /// 查询缺纸状态。
  checkPaper(4),

  /// 查询走纸状态。
  checkFeed(5),

  /// 查询打印状态。
  checkPrint(6),

  /// 查询黑标状态。
  checkBlackMark(7);

  const Nf5503PrinterStateType(this.value);

  /// 原生 SDK 使用的整数值。
  final int value;
}

/// 打印 SDK 返回的错误码。
enum Nf5503PrintErrorCode {
  /// 无错误。
  noError(0),

  /// 设备忙。
  deviceBusy(1),

  /// 打印头过热。
  printHot(2),

  /// 缺纸。
  noPaper(3),

  /// 电量不足。
  noBattery(4),

  /// 走纸异常。
  deviceFeed(5),

  /// 打印异常。
  devicePrint(6),

  /// 黑标异常。
  blackMark(7),

  /// 设备未打开。
  deviceNotOpen(16),

  /// 无待打印数据。
  noData(17),

  /// 数据无效。
  dataInvalid(18),

  /// 指令错误。
  command(19),

  /// 浓度参数无效。
  densityInvalid(20),

  /// 文本打印错误。
  printText(160),

  /// 位图打印错误。
  printBitmap(161),

  /// 条码打印错误。
  printBarcode(162),

  /// 二维码打印错误。
  printQrCode(163),

  /// 位图宽度超出限制。
  bitmapWidthOverflow(164),

  /// 数据输入错误。
  dataInput(165),

  /// 参数非法。
  illegalArgument(166),

  /// 数据 MAC 校验错误。
  dataMac(167),

  /// 已存在打印结果。
  resultExists(168),

  /// 打印超时。
  timeout(169),

  /// 未知错误。
  unknown(255);

  const Nf5503PrintErrorCode(this.value);

  /// 原生 SDK 使用的整数值。
  final int value;

  /// 根据原生 SDK 返回值转换为错误码，无法识别时返回 null。
  static Nf5503PrintErrorCode? fromValue(int value) {
    for (final code in values) {
      if (code.value == value) {
        return code;
      }
    }
    return null;
  }
}

/// 打印 EventChannel 事件类型。
enum Nf5503PrintEventType {
  /// 打印状态回调事件。
  state,

  /// 打印机版本回调事件。
  version,
}

/// 打印 SDK 通过 EventChannel 推送的事件。
class Nf5503PrintEvent {
  /// 创建打印事件对象。
  const Nf5503PrintEvent({required this.type, this.state, this.version});

  /// 从原生 EventChannel 返回的 Map 中解析打印事件。
  factory Nf5503PrintEvent.fromMap(Map<Object?, Object?> map) {
    final type = map['type']?.toString() == 'version'
        ? Nf5503PrintEventType.version
        : Nf5503PrintEventType.state;

    return Nf5503PrintEvent(
      type: type,
      state: _intFromObject(map['state']),
      version: map['version']?.toString(),
    );
  }

  /// 事件类型。
  final Nf5503PrintEventType type;

  /// 打印状态或错误码，版本事件通常为空。
  final int? state;

  /// 打印机版本号，仅版本事件有值。
  final String? version;

  /// 将 [state] 转换为可读错误码，无法识别时返回 null。
  Nf5503PrintErrorCode? get errorCode {
    final value = state;
    return value == null ? null : Nf5503PrintErrorCode.fromValue(value);
  }

  /// 当前状态是否表示打印成功。
  bool get isSuccess => state == Nf5503PrintErrorCode.noError.value;
}

int? _intFromObject(Object? value) {
  if (value is int) {
    return value;
  }
  if (value is num) {
    return value.toInt();
  }
  return int.tryParse(value?.toString() ?? '');
}
