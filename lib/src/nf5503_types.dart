enum Nf5503ScanOutputMode {
  broadcast(0),
  inputBox(1),
  keyboard(2),
  singleInputBox(3),
  clipboard(4);

  const Nf5503ScanOutputMode(this.value);

  final int value;

  static Nf5503ScanOutputMode fromValue(int value) {
    return values.firstWhere(
      (mode) => mode.value == value,
      orElse: () => Nf5503ScanOutputMode.broadcast,
    );
  }
}

enum Nf5503ScanEndMark {
  none(0),
  enter(1),
  tab(2);

  const Nf5503ScanEndMark(this.value);

  final int value;

  static Nf5503ScanEndMark fromValue(int value) {
    return values.firstWhere(
      (mark) => mark.value == value,
      orElse: () => Nf5503ScanEndMark.none,
    );
  }
}

class Nf5503ScanResult {
  const Nf5503ScanResult({
    required this.data,
    this.action,
    this.extras = const <String, Object?>{},
  });

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

  final String data;
  final String? action;
  final Map<String, Object?> extras;
}

enum Nf5503PrintAlign {
  left(1),
  center(2),
  right(3);

  const Nf5503PrintAlign(this.value);

  final int value;

  static Nf5503PrintAlign fromValue(int value) {
    return values.firstWhere(
      (align) => align.value == value,
      orElse: () => Nf5503PrintAlign.left,
    );
  }
}

enum Nf5503PrintFontSize {
  small(1),
  xSmall(2),
  middle(3),
  xMiddle(4),
  large(5),
  xLarge(6),
  superSize(7),
  xSuper(8);

  const Nf5503PrintFontSize(this.value);

  final int value;

  static Nf5503PrintFontSize fromValue(int value) {
    return values.firstWhere(
      (size) => size.value == value,
      orElse: () => Nf5503PrintFontSize.middle,
    );
  }
}

enum Nf5503BarcodeType {
  upca(65),
  upce(66),
  ean13(67),
  ean8(68),
  code39(69),
  itf(70),
  codabar(71),
  code93(72),
  code128(73);

  const Nf5503BarcodeType(this.value);

  final int value;
}

enum Nf5503HriPosition {
  none(1),
  above(2),
  below(3),
  both(4);

  const Nf5503HriPosition(this.value);

  final int value;
}

enum Nf5503PrinterStateType {
  checkAll(1),
  checkBusy(2),
  checkTemp(3),
  checkPaper(4),
  checkFeed(5),
  checkPrint(6),
  checkBlackMark(7);

  const Nf5503PrinterStateType(this.value);

  final int value;
}

enum Nf5503PrintErrorCode {
  noError(0),
  deviceBusy(1),
  printHot(2),
  noPaper(3),
  noBattery(4),
  deviceFeed(5),
  devicePrint(6),
  blackMark(7),
  deviceNotOpen(16),
  noData(17),
  dataInvalid(18),
  command(19),
  densityInvalid(20),
  printText(160),
  printBitmap(161),
  printBarcode(162),
  printQrCode(163),
  bitmapWidthOverflow(164),
  dataInput(165),
  illegalArgument(166),
  dataMac(167),
  resultExists(168),
  timeout(169),
  unknown(255);

  const Nf5503PrintErrorCode(this.value);

  final int value;

  static Nf5503PrintErrorCode? fromValue(int value) {
    for (final code in values) {
      if (code.value == value) {
        return code;
      }
    }
    return null;
  }
}

enum Nf5503PrintEventType { state, version }

class Nf5503PrintEvent {
  const Nf5503PrintEvent({required this.type, this.state, this.version});

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

  final Nf5503PrintEventType type;
  final int? state;
  final String? version;

  Nf5503PrintErrorCode? get errorCode {
    final value = state;
    return value == null ? null : Nf5503PrintErrorCode.fromValue(value);
  }

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
