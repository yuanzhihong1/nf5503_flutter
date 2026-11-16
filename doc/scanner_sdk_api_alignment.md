# NF5503 扫描 SDK API 对齐审计

## 审计基线

- 厂商 SDK：`Scanner2.0/Code/new/app/libs/ScanManager_V202105081630.jar`
- SHA-256：`ba8942aa17d35d392aec0c56588f273b1afc304cc1d615de02cb703edf94d064`
- 开发文档：`Scanner2.0/文档/扫描开发指南 - v2.docx`
- 厂商示例：`Scanner2.0/Code/new/app/src/main/java/com/example/testscan_v2/MainActivity.java`
- 审计方式：`javap -public -constants` 提取 JAR 的公开方法、内部配置类和常量，再与文档、示例调用链及 Flutter 实现交叉核对。

## 公开方法覆盖

`android.bld.ScanManager` 共有 61 个公开方法。以下每一项均有对应 Flutter 能力；两个历史大小写别名通过运行时回退兼容。

| 原生方法 | Flutter API / 实现 |
| --- | --- |
| `getDefaultInstance(Context)` | 插件内部 `ensureScanner()`，使用 Application Context |
| `getSymbologyList()` | `getSymbologyList()`，反射递归展开 `FatherData` 树 |
| `initSymbologySettings()` | `initSymbologySettings()` |
| `getScannerType()` | `getScannerType()` + `getScannerTypeId()` |
| `isScannerConflicted()` | `isConflicted()` |
| `DecoderConnect()` | `connectDecoder()`，小写方法缺失时回退该别名 |
| `decoderConnect()` | `connectDecoder()` 首选实现 |
| `DecoderDisconnect()` | `disconnectDecoder()`，小写方法缺失时回退该别名 |
| `decoderDisconnect()` | `disconnectDecoder()` 首选实现 |
| `getDecoderStatus()` | `getDecoderStatus()` |
| `isDecoderConnected()` | `isDecoderConnected()` |
| `openScanner()` | `open()` |
| `closeScanner()` | `close()` |
| `startDecode()` | `startDecode()` |
| `stopDecode()` | `stopDecode()` |
| `isScannerOpen()` | `isOpen()` |
| `setPrefix(String)` | `setPrefix()` |
| `getPrefix()` | `getPrefix()` |
| `setSuffix(String)` | `setSuffix()` |
| `getSuffix()` | `getSuffix()` |
| `setFilter(String)` | `setFilter()` |
| `getFilter()` | `getFilter()` |
| `setPlaySound(boolean)` | `setPlaySound()` |
| `getPlaySound()` | `getPlaySound()` |
| `setVibrate(boolean)` | `setVibrate()` |
| `getVibrate()` | `getVibrate()` |
| `setContinueScan(boolean)` | `setContinueScan()` |
| `getContinueScan()` | `getContinueScan()` |
| `setMultiDecode(boolean)` | `setMultiDecode()` |
| `getMultiDecode()` | `getMultiDecode()` |
| `setMultiReadNumber(int)` | `setMultiReadNumber()` |
| `getMultiReadNumber()` | `getMultiReadNumber()` |
| `setDisableSameBarcode(boolean)` | `setDisableSameBarcode()` |
| `getDisableSameBarcode()` | `getDisableSameBarcode()` |
| `setBroadcastAction(String)` | `setBroadcastAction()` |
| `getBroadcastAction()` | `getBroadcastAction()` |
| `setBroadcastKey(String)` | `setBroadcastKey()` |
| `getBroadcastKey()` | `getBroadcastKey()` |
| `setDecodeMode(int)` | `setDecodeMode(Nf5503ScanDecodeMode)` |
| `getDecodeMode()` | `getDecodeMode()` |
| `setOPMode(int)` | `setOutputMode(Nf5503ScanOutputMode)` |
| `getOPMode()` | `getOutputMode()` |
| `setEndMark(int)` | `setEndMark(Nf5503ScanEndMark)` |
| `getEndMark()` | `getEndMark()` |
| `setHandleKey(boolean)` | `setHandleKey()` |
| `getHandleKey()` | `getHandleKey()` |
| `setIntervalTime(int)` | `setIntervalTime()`，保留原生 boolean 返回值 |
| `getIntervalTime()` | `getIntervalTime()` |
| `setDecodeTimeout(int)` | `setDecodeTimeout()` |
| `getDecodeTimeout()` | `getDecodeTimeout()` |
| `setLiftToStop(boolean)` | `setLiftToStop()` |
| `getLiftToStop()` | `getLiftToStop()` |
| `setSYMValueInts(int[], int[])` | `setSymbologyValues()` / `setParameter()` |
| `getSYMValueInts(int[])` | `getSymbologyValues()` / `getParameter()` |
| `enableAllSYM(boolean)` | `enableAllSymbologies()` |
| `enableSYM(boolean, int)` | `enableSymbology(enabled:, symbologyId:)` |
| `enableSYM1D(boolean)` | `enableAll1dSymbologies()` |
| `enableSYM2D(boolean)` | `enableAll2dSymbologies()` |
| `isSYMEnabled(int)` | `isSymbologyEnabled()` |
| `isSYMSupported(int)` | `isSymbologySupported()` |
| `resetScan()` | `reset()` |

## 常量覆盖

`lib/src/nf5503_scan_constants.dart` 由 `tool/generate_scan_constants.py` 从 JAR 自动生成，共镜像 466 个公开常量：

- `Nf5503ScanParamId`：214 个 `DecoderConfigValues.ParamID`
- `Nf5503ScanSymbologyId`：72 个 `DecoderConfigValues.SymbologyID`
- `Nf5503ScanSymbologyFlags`：37 个符号标志
- `Nf5503ScanEngineId` / `Nf5503ScanEngineType`
- `Nf5503ScanLightsMode`
- `Nf5503ScanOcrMode` / `Nf5503ScanOcrTemplate`
- `Nf5503ScanPostalConfig`
- `Nf5503ScannerTypeId`
- `Nf5503ScanConfig`：Action、广播字段、服务配置键和输出/编码常量

例如：

```dart
await scanner.setParameter(Nf5503ScanParamId.CODE128_MIN_LEN, 4);
await scanner.setLightsMode(Nf5503ScanLightsMode.CONCURRENT);
await scanner.enableSymbology(
  enabled: true,
  symbologyId: Nf5503ScanSymbologyId.SYM_QR,
);
```

## 广播结果对齐

官方 `ScanConfig` 中与扫码结果相关的字段已完整保留：

- 文本：`barcodeData`
- 原始字节：`barocode`
- 部分固件字节字段：`data`
- 长度：`length`
- 条码类型：`barcodeType`
- Code ID：`codeId`
- AIM ID / Modifier：`aimId` / `aimModifier`

`Nf5503ScanResult` 同时提供结构化字段与完整 `extras`：

```dart
stream.listen((result) {
  print(result.data);
  print(result.rawData);
  print(result.codeId);
  print(result.barcodeType);
  print(result.aimId);
});
```

未显式配置 Action/Key 时，插件默认使用官方值：

- Action：`scan.rcv.message`
- Key：`barcodeData`

## 兼容性修正

- Android 13+ 动态广播接收器使用 `RECEIVER_EXPORTED`，因为广播由设备厂商扫描服务发送，不属于 Flutter 应用自身。
- 字节数组不再被转换为无意义的 `[B@...` 字符串；其保留为 `Uint8List`/`ByteArray`。
- 原始字节会按照 `setDecodeMode` 配置的 UTF-8、ASCII、GBK、GB2312、GB18030、UTF-16 或 ISO-8859-1 解码。
- `getSymbologyList()` 使用有深度和循环保护的递归映射，嵌套 `FatherData` 不再被压平成 `toString()`。
- 未知输出模式、编码模式和结束符返回显式 `unknown`，不再静默伪装成某个合法值。
- 原始扫描头 ID 可通过 `getScannerTypeId()` 获取，避免新扫描头被枚举折叠为 `unknown`。
