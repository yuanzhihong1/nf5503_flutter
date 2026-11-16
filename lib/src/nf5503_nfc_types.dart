import 'dart:typed_data';

/// Android NFC 适配器状态。
enum Nf5503NfcAdapterState {
  /// NFC 已关闭，对应 `NfcAdapter.STATE_OFF`。
  off(1),

  /// NFC 正在开启，对应 `NfcAdapter.STATE_TURNING_ON`。
  turningOn(2),

  /// NFC 已开启，对应 `NfcAdapter.STATE_ON`。
  on(3),

  /// NFC 正在关闭，对应 `NfcAdapter.STATE_TURNING_OFF`。
  turningOff(4),

  /// 当前系统返回了未定义状态。
  unknown(-1);

  const Nf5503NfcAdapterState(this.value);

  /// 原生 SDK 使用的整数值。
  final int value;

  /// 根据原生返回值转换，未知值返回 [unknown]。
  static Nf5503NfcAdapterState fromValue(int value) {
    return values.firstWhere(
      (state) => state.value == value,
      orElse: () => Nf5503NfcAdapterState.unknown,
    );
  }
}

/// NFC 事件类型。
enum Nf5503NfcEventType {
  /// 发现 NFC 标签。
  tag,

  /// 插件发现新标签、停止发现或判定原标签已离开。
  tagLost,

  /// NFC 适配器状态变化。
  adapterState,

  /// 标签发现或 Reader Mode 错误。
  error,

  /// 无法识别的事件。
  unknown,
}

/// Mifare Classic 鉴权密钥类型。
enum Nf5503MifareKeyType {
  /// Key A。
  keyA(0),

  /// Key B。
  keyB(1);

  const Nf5503MifareKeyType(this.value);

  /// 原生 SDK 使用的整数值。
  final int value;
}

/// Mifare Classic 兼容卡片类型。
enum Nf5503MifareClassicType {
  /// Mifare Classic，对应 `MifareClassic.TYPE_CLASSIC`。
  classic(1),

  /// Mifare Plus，对应 `MifareClassic.TYPE_PLUS`。
  plus(2),

  /// Mifare Pro，对应 `MifareClassic.TYPE_PRO`。
  pro(3),

  /// 未知类型。
  unknown(-1);

  const Nf5503MifareClassicType(this.value);

  /// 原生 SDK 使用的整数值。
  final int value;

  /// 根据原生返回值转换，未知值返回 [unknown]。
  static Nf5503MifareClassicType fromValue(int value) {
    return values.firstWhere(
      (type) => type.value == value,
      orElse: () => Nf5503MifareClassicType.unknown,
    );
  }
}

/// Mifare Classic 常用密钥与尺寸常量。
abstract final class Nf5503MifareClassicConstants {
  /// 单块字节数。
  static const int blockLength = 16;

  /// 扇区密钥字节数。
  static const int keyLength = 6;

  /// Android `MifareClassic.KEY_DEFAULT`。
  static Uint8List get keyDefault => Uint8List.fromList(
        <int>[0xFF, 0xFF, 0xFF, 0xFF, 0xFF, 0xFF],
      );

  /// Android `MifareClassic.KEY_MIFARE_APPLICATION_DIRECTORY`。
  static Uint8List get keyMifareApplicationDirectory => Uint8List.fromList(
        <int>[0xA0, 0xA1, 0xA2, 0xA3, 0xA4, 0xA5],
      );

  /// Android `MifareClassic.KEY_NFC_FORUM`。
  static Uint8List get keyNfcForum => Uint8List.fromList(
        <int>[0xD3, 0xF7, 0xD3, 0xF7, 0xD3, 0xF7],
      );
}

/// NFC 硬件与发现状态。
class Nf5503NfcStatus {
  /// 创建状态对象。
  const Nf5503NfcStatus({
    required this.supported,
    required this.enabled,
    required this.readerModeActive,
    required this.adapterState,
  });

  /// 从原生 Map 解析状态。
  factory Nf5503NfcStatus.fromMap(Map<Object?, Object?> map) {
    return Nf5503NfcStatus(
      supported: _boolFromObject(map['supported']) ?? false,
      enabled: _boolFromObject(map['enabled']) ?? false,
      readerModeActive: _boolFromObject(map['readerModeActive']) ?? false,
      adapterState: Nf5503NfcAdapterState.fromValue(
        _intFromObject(map['adapterState']) ?? -1,
      ),
    );
  }

  /// 设备是否具备 NFC 硬件。
  final bool supported;

  /// NFC 当前是否启用。
  final bool enabled;

  /// 插件当前是否启用了前台 Reader Mode。
  final bool readerModeActive;

  /// 当前 NFC 适配器状态。
  final Nf5503NfcAdapterState adapterState;
}

/// 解析后的 NDEF 记录。
class Nf5503NdefRecord {
  /// 创建 NDEF 记录。
  const Nf5503NdefRecord({
    required this.index,
    required this.tnf,
    required this.type,
    required this.id,
    required this.payload,
    this.typeName,
    this.text,
    this.uri,
    this.mimeType,
    this.languageCode,
  });

  /// 从原生 Map 解析记录。
  factory Nf5503NdefRecord.fromMap(Map<Object?, Object?> map) {
    return Nf5503NdefRecord(
      index: _intFromObject(map['index']) ?? 0,
      tnf: _intFromObject(map['tnf']) ?? 0,
      type: _bytesFromObject(map['type']),
      id: _bytesFromObject(map['id']),
      payload: _bytesFromObject(map['payload']),
      typeName: _stringFromObject(map['typeName']),
      text: _stringFromObject(map['text']),
      uri: _stringFromObject(map['uri']),
      mimeType: _stringFromObject(map['mimeType']),
      languageCode: _stringFromObject(map['languageCode']),
    );
  }

  /// 记录在消息中的下标。
  final int index;

  /// NDEF TNF 值。
  final int tnf;

  /// 记录类型原始字节。
  final Uint8List type;

  /// 记录 ID。
  final Uint8List id;

  /// 记录负载原始字节。
  final Uint8List payload;

  /// 类型字节的 ASCII 文本表示。
  final String? typeName;

  /// 文本记录或可读记录内容。
  final String? text;

  /// URI 记录内容。
  final String? uri;

  /// MIME 类型。
  final String? mimeType;

  /// 文本记录语言代码。
  final String? languageCode;
}

/// 完整 NDEF 消息。
class Nf5503NdefMessage {
  /// 创建 NDEF 消息。
  const Nf5503NdefMessage({required this.rawData, required this.records});

  /// 从原生 Map 解析消息。
  factory Nf5503NdefMessage.fromMap(Map<Object?, Object?> map) {
    final records = <Nf5503NdefRecord>[];
    final rawRecords = map['records'];
    if (rawRecords is List) {
      for (final item in rawRecords) {
        final recordMap = _mapFromObject(item);
        if (recordMap != null) {
          records.add(Nf5503NdefRecord.fromMap(recordMap));
        }
      }
    }
    return Nf5503NdefMessage(
      rawData: _bytesFromObject(map['rawData']),
      records: List<Nf5503NdefRecord>.unmodifiable(records),
    );
  }

  /// 完整 NDEF 消息字节。
  final Uint8List rawData;

  /// 按顺序解析的记录。
  final List<Nf5503NdefRecord> records;

  /// 第一条可读文本；URI 记录会返回 URI。
  String? get firstText {
    for (final record in records) {
      final value = record.text ?? record.uri;
      if (value != null && value.isNotEmpty) {
        return value;
      }
    }
    return null;
  }
}

/// NDEF 标签能力与缓存消息。
class Nf5503NdefInfo {
  /// 创建 NDEF 信息。
  const Nf5503NdefInfo({
    required this.type,
    required this.maxSize,
    required this.writable,
    required this.canMakeReadOnly,
    this.cachedMessage,
  });

  /// 从原生 Map 解析。
  factory Nf5503NdefInfo.fromMap(Map<Object?, Object?> map) {
    final cachedMessage = _mapFromObject(map['cachedMessage']);
    return Nf5503NdefInfo(
      type: _stringFromObject(map['type']) ?? '',
      maxSize: _intFromObject(map['maxSize']) ?? 0,
      writable: _boolFromObject(map['writable']) ?? false,
      canMakeReadOnly: _boolFromObject(map['canMakeReadOnly']) ?? false,
      cachedMessage: cachedMessage == null
          ? null
          : Nf5503NdefMessage.fromMap(cachedMessage),
    );
  }

  /// 标签技术类型，例如 `NfcA`、`MifareClassic`。
  final String type;

  /// 标签可承载的最大 NDEF 字节数。
  final int maxSize;

  /// 标签当前是否可写。
  final bool writable;

  /// 标签是否可以设置为只读。
  final bool canMakeReadOnly;

  /// Android 平台缓存的上一条 NDEF 消息。
  final Nf5503NdefMessage? cachedMessage;
}

/// Mifare Classic 标签能力。
class Nf5503MifareClassicInfo {
  /// 创建 Mifare Classic 信息。
  const Nf5503MifareClassicInfo({
    required this.type,
    required this.size,
    required this.sectorCount,
    required this.blockCount,
    required this.maxTransceiveLength,
  });

  /// 从原生 Map 解析。
  factory Nf5503MifareClassicInfo.fromMap(Map<Object?, Object?> map) {
    return Nf5503MifareClassicInfo(
      type: Nf5503MifareClassicType.fromValue(
        _intFromObject(map['type']) ?? -1,
      ),
      size: _intFromObject(map['size']) ?? 0,
      sectorCount: _intFromObject(map['sectorCount']) ?? 0,
      blockCount: _intFromObject(map['blockCount']) ?? 0,
      maxTransceiveLength: _intFromObject(map['maxTransceiveLength']) ?? 0,
    );
  }

  /// Mifare Classic 兼容卡片类型。
  final Nf5503MifareClassicType type;

  /// 标签容量，单位字节。
  final int size;

  /// 扇区数量。
  final int sectorCount;

  /// 块数量。
  final int blockCount;

  /// 单次 transceive 最大字节数。
  final int maxTransceiveLength;
}

/// 一次标签发现结果。
class Nf5503NfcTagInfo {
  /// 创建标签信息。
  const Nf5503NfcTagInfo({
    required this.id,
    required this.idHex,
    required this.techList,
    this.ndef,
    this.ndefFormatable = false,
    this.mifareClassic,
  });

  /// 从原生 Map 解析。
  factory Nf5503NfcTagInfo.fromMap(Map<Object?, Object?> map) {
    final ndefMap = _mapFromObject(map['ndef']);
    final mifareMap = _mapFromObject(map['mifareClassic']);
    final techList = <String>[];
    final rawTechList = map['techList'];
    if (rawTechList is List) {
      for (final item in rawTechList) {
        final tech = _stringFromObject(item);
        if (tech != null) {
          techList.add(tech);
        }
      }
    }
    return Nf5503NfcTagInfo(
      id: _bytesFromObject(map['id']),
      idHex: _stringFromObject(map['idHex']) ?? '',
      techList: List<String>.unmodifiable(techList),
      ndef: ndefMap == null ? null : Nf5503NdefInfo.fromMap(ndefMap),
      ndefFormatable: _boolFromObject(map['ndefFormatable']) ?? false,
      mifareClassic:
          mifareMap == null ? null : Nf5503MifareClassicInfo.fromMap(mifareMap),
    );
  }

  /// 标签 UID 原始字节。
  final Uint8List id;

  /// 标签 UID 的大写十六进制表示。
  final String idHex;

  /// Android 返回的技术列表。
  final List<String> techList;

  /// NDEF 能力；非 NDEF 标签为空。
  final Nf5503NdefInfo? ndef;

  /// 标签是否可通过 `NdefFormatable` 格式化。
  final bool ndefFormatable;

  /// Mifare Classic 能力；不兼容时为空。
  final Nf5503MifareClassicInfo? mifareClassic;

  /// 按小端字节顺序解释 UID 后得到的十进制字符串。
  ///
  /// 该值对应官方 Demo 中 `flipHexStr(ByteArrayToHexString(tag.getId()))`
  /// 后转换为十进制的结果。
  String get reversedDecimalId {
    if (idHex.isEmpty || idHex.length.isOdd) {
      return '';
    }
    final reversed = <String>[];
    for (var index = 0; index < idHex.length; index += 2) {
      reversed.add(idHex.substring(index, index + 2));
    }
    final littleEndianHex = reversed.reversed.join();
    return BigInt.parse(littleEndianHex, radix: 16).toString();
  }
}

/// NFC EventChannel 推送的事件。
class Nf5503NfcEvent {
  /// 创建事件。
  const Nf5503NfcEvent({
    required this.type,
    this.tag,
    this.adapterState,
    this.status,
    this.message,
  });

  /// 从原生 Map 解析事件。
  factory Nf5503NfcEvent.fromMap(Map<Object?, Object?> map) {
    final rawType = map['type']?.toString();
    final type = switch (rawType) {
      'tag' => Nf5503NfcEventType.tag,
      'tagLost' => Nf5503NfcEventType.tagLost,
      'adapterState' => Nf5503NfcEventType.adapterState,
      'error' => Nf5503NfcEventType.error,
      _ => Nf5503NfcEventType.unknown,
    };
    final tagMap = _mapFromObject(map['tag']);
    final statusMap = _mapFromObject(map['status']);
    final state = _intFromObject(map['state']);
    return Nf5503NfcEvent(
      type: type,
      tag: tagMap == null ? null : Nf5503NfcTagInfo.fromMap(tagMap),
      adapterState:
          state == null ? null : Nf5503NfcAdapterState.fromValue(state),
      status: statusMap == null ? null : Nf5503NfcStatus.fromMap(statusMap),
      message: _stringFromObject(map['message']),
    );
  }

  /// 事件类型。
  final Nf5503NfcEventType type;

  /// 标签事件携带的信息。
  final Nf5503NfcTagInfo? tag;

  /// 适配器状态事件携带的状态。
  final Nf5503NfcAdapterState? adapterState;

  /// 适配器状态事件携带的完整状态快照。
  final Nf5503NfcStatus? status;

  /// 错误事件携带的错误信息。
  final String? message;
}

Map<Object?, Object?>? _mapFromObject(Object? value) {
  if (value is Map<Object?, Object?>) {
    return value;
  }
  if (value is Map) {
    return value.cast<Object?, Object?>();
  }
  return null;
}

Uint8List _bytesFromObject(Object? value) {
  if (value is Uint8List) {
    return value;
  }
  if (value is ByteData) {
    return value.buffer.asUint8List(value.offsetInBytes, value.lengthInBytes);
  }
  if (value is List) {
    final bytes = <int>[];
    for (final item in value) {
      if (item is! num) {
        return Uint8List(0);
      }
      bytes.add(item.toInt());
    }
    return Uint8List.fromList(bytes);
  }
  return Uint8List(0);
}

String? _stringFromObject(Object? value) {
  if (value == null) {
    return null;
  }
  return value.toString();
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

bool? _boolFromObject(Object? value) {
  if (value is bool) {
    return value;
  }
  if (value is num) {
    return value != 0;
  }
  final text = value?.toString().toLowerCase();
  if (text == 'true' || text == '1') {
    return true;
  }
  if (text == 'false' || text == '0') {
    return false;
  }
  return null;
}
