# nf5503_flutter

`nf5503_flutter` 是面向 M5Stack NF5503 Android 设备的 Flutter 插件，封装条码扫码、热敏小票打印和标签黑标打印能力。

插件当前仅实现 Android 平台。扫码和打印 API 依赖 NF5503 固件/系统框架服务，请在 NF5503 真机上运行；普通模拟器或其它 Android 设备通常无法提供对应能力。

## 功能特性

- 扫码：打开/关闭扫描头、开始/停止解码、广播结果监听、输出模式、编码模式、前后缀、提示音、震动、连续扫码、多码识读、码制启停与参数配置。
- 完整 SDK 常量：自动镜像官方 JAR 中 ParamID、SymbologyID、灯光、OCR、引擎、Postal、SymbologyFlags 和 ScanConfig 的全部 466 个公开常量。
- 原始广播数据：同时提供文本、原始字节、Code ID、条码类型、AIM ID、AIM Modifier、长度和完整 extras。
- 打印：打开/关闭打印服务、版本/状态回调、浓度、字体、字号、加粗、下划线、反白、文本、条码、二维码、图片、走纸、黑标和行距设置。
- 示例：`example/lib/main.dart` 提供纯 Cupertino 组件的真机调试界面，可验证扫码、打印、黑标和浓度校准流程。
- 原生 SDK：项目随包包含 NF5503 官方 SDK jar，用于编译期对齐原生接口。

## 安装

在业务项目的 `pubspec.yaml` 中添加依赖：

```yaml
dependencies:
  nf5503_flutter: ^0.0.4
```

本仓库内运行示例时，示例应用通过 path 依赖引用插件源码：

```yaml
dependencies:
  nf5503_flutter:
    path: ../
```

## 快速开始

```dart
import 'package:nf5503_flutter/nf5503_flutter.dart';

final nf5503 = Nf5503Flutter();

Future<void> scanOnce() async {
  await nf5503.scanner.setBroadcastAction(Nf5503ScanBroadcast.defaultAction);
  await nf5503.scanner.setBroadcastKey(Nf5503ScanBroadcast.defaultKey);
  await nf5503.scanner.setOutputMode(Nf5503ScanOutputMode.broadcast);

  nf5503.scanner.results().listen((result) {
    print('scan: ${result.data}');
    print('raw: ${result.rawData}');
    print('codeId: ${result.codeId}, type: ${result.barcodeType}');
  });

  await nf5503.scanner.open();
  await nf5503.scanner.startDecode();
}

Future<void> configureScanner() async {
  // 高级参数使用完整镜像的官方 ParamID / SymbologyID 常量。
  await nf5503.scanner.setParameter(
    Nf5503ScanParamId.CODE128_MIN_LEN,
    4,
  );
  await nf5503.scanner.setLightsMode(Nf5503ScanLightsMode.CONCURRENT);
  await nf5503.scanner.enableSymbology(
    enabled: true,
    symbologyId: Nf5503ScanSymbologyId.SYM_QR,
  );

  final scannerTypeId = await nf5503.scanner.getScannerTypeId();
  final symbologies = await nf5503.scanner.getSymbologyList();
  print('scanner=$scannerTypeId, symbologies=${symbologies.length}');
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

## 示例应用

```bash
cd example
flutter pub get
flutter run
```

示例应用用于真机联调，主要包含：

- 初始化扫码广播并监听结果。
- 手动开始/停止扫码，读取当前扫码配置。
- 开关打印服务，读取版本、状态和支持模块。
- 设置热敏小票纸/标签纸、打印浓度、字体和黑标阈值。
- 打印文本、条码、二维码、图片、标签样张和热敏浓度校准尺。

## API 结构

公共 API 由两个门面组成：

- `Nf5503Scanner`：扫码相关能力。
- `Nf5503Printer`：打印相关能力。

### 扫码 API

| Flutter API | 对齐的原生能力 |
| --- | --- |
| `results({action, key})` | 监听扫码广播，解析文本、原始字节、条码元数据和完整 `extras`。 |
| `open()`、`close()`、`isOpen()` | `ScanManager.openScanner`、`closeScanner`、`isScannerOpen`。 |
| `startDecode()`、`stopDecode()` | `ScanManager.startDecode`、`stopDecode`。 |
| `getSymbologyList()`、`initSymbologySettings()` | 获取/初始化码制配置；反射结果递归保留嵌套属性与字节字段。 |
| `getScannerType()`、`getScannerTypeId()`、`isConflicted()` | 读取扫描头枚举、原始 ID 与冲突状态。 |
| `connectDecoder()`、`disconnectDecoder()` | 连接/断开底层解码器。 |
| `getDecoderStatus()`、`isDecoderConnected()` | 读取解码器状态。 |
| `setPrefix/getPrefix`、`setSuffix/getSuffix`、`setFilter/getFilter` | 设置扫码文本前缀、后缀与过滤规则。 |
| `setPlaySound/getPlaySound`、`setVibrate/getVibrate` | 设置扫码成功后的声音和震动反馈。 |
| `setContinueScan/getContinueScan` | 设置连续扫码。 |
| `setMultiDecode/getMultiDecode`、`setMultiReadNumber/getMultiReadNumber` | 设置多码识读及最大读取数量。 |
| `setDisableSameBarcode/getDisableSameBarcode` | 设置重复码抑制。 |
| `setBroadcastAction/getBroadcastAction`、`setBroadcastKey/getBroadcastKey` | 设置扫码广播 Action 和数据 Key。 |
| `setOutputMode/getOutputMode` | 对齐 `ScanConfig.SCAN_OUTPUTMODE_*`。 |
| `setDecodeMode/getDecodeMode` | 对齐 `ScanConfig.SCAN_ENCODE_MODE_*`。 |
| `setEndMark/getEndMark` | 对齐 `ScanConfig.END_MARK_*_MODE`。 |
| `setHandleKey/getHandleKey` | 设置是否由 SDK 接管实体扫码键。 |
| `setIntervalTime/getIntervalTime` | 设置连续扫码间隔，单位毫秒。 |
| `setDecodeTimeout/getDecodeTimeout` | 设置单次解码超时，单位毫秒。 |
| `setLiftToStop/getLiftToStop` | 设置松开扫码键时停止扫码。 |
| `setSymbologyValues()`、`getSymbologyValues()` | 对齐 `setSYMValueInts`、`getSYMValueInts`。 |
| `setParameter()`、`getParameter()` | 单参数便捷调用，底层复用 `setSYMValueInts` / `getSYMValueInts`。 |
| `setLightsMode()`、`getLightsMode()` | 使用 `ParamID.LIGHTS_MODE` 读写补光/瞄准灯模式。 |
| `enableAllSymbologies()`、`enableSymbology()` | 启停全部或指定码制。 |
| `enableAll1dSymbologies()`、`enableAll2dSymbologies()` | 启停全部一维码或二维码码制。 |
| `isSymbologyEnabled()`、`isSymbologySupported()` | 查询码制是否启用/支持。 |
| `reset()` | 恢复扫码配置。 |

### 打印 API

| Flutter API | 对齐的原生能力 |
| --- | --- |
| `events()` | 监听版本回调和 `PrinterBinderListener` 状态回调。 |
| `getVersion()` | 读取打印机版本。 |
| `open()`、`close()` | 打开/关闭打印服务。 |
| `setConcentration()`、`getConcentration()` | 设置/读取打印浓度；Flutter 层使用官方 1-39 的浓度值，并按 SDK 的 `density / 4 + 1` 规则映射到原生 1-10 档。 |
| `reset()` | 重置打印机。 |
| `setFontType/getFontType` | 设置/读取字体。 |
| `setFontSize/getFontSize` | 设置/读取字号。 |
| `setBold/isBold` | 设置/读取加粗。 |
| `setBlackMark/isBlackMark` | 设置/读取黑标模式。 |
| `setThreshold()` | 设置黑标阈值并返回原生状态码。 |
| `setUnderline/isUnderline` | 设置/读取下划线。 |
| `setFeedPaperSpace/getFeedPaperSpace` | 设置/读取走纸间距。 |
| `setUnwindPaperLength/getUnwindPaperLength` | 设置/读取回退纸长度。 |
| `addText()` | 添加文本到打印队列。 |
| `addBarcode()` | 添加条码到打印队列。 |
| `addQrCode()` | 添加二维码到打印队列。 |
| `addImageBytes()`、`addImagePath()` | 添加图片到打印队列。 |
| `addBlankLines()` | 添加空行。 |
| `start()` | 开始执行打印队列。 |
| `setReverse/isReverse` | 设置/读取反白打印。 |
| `goToNextMark({distance})` | 黑标模式下走到下一标记。 |
| `setLineSpacing/getLineSpacing` | 设置/读取行距。 |
| `getSupportPrint()` | 查询设备打印支持状态。 |
| `getState()` | 查询指定打印状态。 |

> `setFontType/getFontType`、`setThreshold()`、`getState()` 是本插件对系统 `PrintManager` 的扩展能力；`5502A` 的公开 `PrintUtil` 指南未定义这三组接口，但底层 `PrinterAPI` JAR 支持。

## 值类型

- `Nf5503ScanOutputMode`、`Nf5503ScanEndMark`、`Nf5503ScanDecodeMode` 和 `Nf5503ScannerType` 对齐 NF5503 扫码常量。
- `Nf5503PrintAlign`、`Nf5503PrintFontSize`、`Nf5503BarcodeType`、`Nf5503HriPosition`、`Nf5503PrinterStateType` 和 `Nf5503PrintErrorCode` 对齐打印常量。
- `Nf5503ScanResult` 提供 `data`、`rawData`、`codeId`、`barcodeType`、`aimId`、`aimIdBytes`、`length`、`aimModifier` 和完整 `extras`。
- `Nf5503ScanParamId`、`Nf5503ScanSymbologyId`、`Nf5503ScanLightsMode`、`Nf5503ScanEngineId`、`Nf5503ScanOcrMode`、`Nf5503ScanConfig` 等常量类完整镜像官方 JAR。
- 未配置广播 Action/Key 时默认使用 `Nf5503ScanBroadcast.defaultAction`（`scan.rcv.message`）和 `defaultKey`（`barcodeData`）。
- `Nf5503PrintEvent.errorCode` 会在状态值可识别时转换为 `Nf5503PrintErrorCode`。

## Android SDK 说明

- `ScanManager_V202105081630.jar` 与 `PrinterAPI_V202108242200.jar` 作为 `compileOnly` 引入，因为 NF5503 设备系统会提供真实实现。
- `lcprintsdk1.1-classes.jar` 随插件打包，用于 `PrintUtil` 的标签黑标走纸和打印支持探测。
- 高级码制参数以整数透传，并由生成器从官方 JAR 同步全部 `DecoderConfigValues` 常量，避免业务代码手写魔法数。
- 完整逐方法审计见 [`doc/scanner_sdk_api_alignment.md`](doc/scanner_sdk_api_alignment.md)。

## 开发与验证

```bash
flutter analyze
flutter test
python3 tool/generate_scan_constants.py

(cd example && flutter analyze)
(cd example && flutter test)

# 原生编译与 Kotlin 单元测试
(cd example/android && ./gradlew :nf5503_flutter:testDebugUnitTest)
(cd example/android && ./gradlew :app:assembleDebug)
(cd example && flutter build apk --release)
```

示例工程使用 `cupertino_ui`，需 Flutter 3.47 或更高版本；Android 构建使用 Gradle 9.5.0、AGP 9.3.1 和 Java 17。

## 许可证

本项目采用 MIT License，详见 [LICENSE](LICENSE)。
