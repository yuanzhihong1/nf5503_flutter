# nf5503_flutter

`nf5503_flutter` 是面向 M5Stack NF5503 Android 设备的 Flutter 插件，封装条码扫码、热敏小票打印和标签黑标打印能力。

插件当前仅实现 Android 平台。扫码和打印 API 依赖 NF5503 固件/系统框架服务，请在 NF5503 真机上运行；普通模拟器或其它 Android 设备通常无法提供对应能力。

## 功能特性

- 扫码：打开/关闭扫描头、开始/停止解码、广播结果监听、输出模式、编码模式、前后缀、提示音、震动、连续扫码、多码识读、码制启停与参数配置。
- 打印：打开/关闭打印服务、版本/状态回调、浓度、字体、字号、加粗、下划线、反白、文本、条码、二维码、图片、走纸、黑标和行距设置。
- 示例：`example/lib/main.dart` 提供纯 Cupertino 组件的真机调试界面，可验证扫码、打印、黑标和浓度校准流程。
- 原生 SDK：项目随包包含 NF5503 官方 SDK jar，用于编译期对齐原生接口。

## 安装

在业务项目的 `pubspec.yaml` 中添加依赖：

```yaml
dependencies:
  nf5503_flutter: ^0.0.1
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
  await nf5503.scanner.setBroadcastAction('com.example.SCAN');
  await nf5503.scanner.setBroadcastKey('barcode');
  await nf5503.scanner.setOutputMode(Nf5503ScanOutputMode.broadcast);

  nf5503.scanner.results(
    action: 'com.example.SCAN',
    key: 'barcode',
  ).listen((result) {
    print('scan: ${result.data}');
  });

  await nf5503.scanner.open();
  await nf5503.scanner.startDecode();
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
| `results({action, key})` | 监听扫码广播，解析 `data`、`action` 和原始 `extras`。 |
| `open()`、`close()`、`isOpen()` | `ScanManager.openScanner`、`closeScanner`、`isScannerOpen`。 |
| `startDecode()`、`stopDecode()` | `ScanManager.startDecode`、`stopDecode`。 |
| `getSymbologyList()`、`initSymbologySettings()` | 获取/初始化码制配置。 |
| `getScannerType()`、`isConflicted()` | 读取扫描头类型与冲突状态。 |
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
| `setConcentration()`、`getConcentration()` | 设置/读取打印浓度；Flutter 层使用 1-40 的业务值并映射到原生 1-10 档。 |
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

## 值类型

- `Nf5503ScanOutputMode`、`Nf5503ScanEndMark`、`Nf5503ScanDecodeMode` 和 `Nf5503ScannerType` 对齐 NF5503 扫码常量。
- `Nf5503PrintAlign`、`Nf5503PrintFontSize`、`Nf5503BarcodeType`、`Nf5503HriPosition`、`Nf5503PrinterStateType` 和 `Nf5503PrintErrorCode` 对齐打印常量。
- `Nf5503ScanResult.extras` 保留 Android 广播中的原始 extras，方便业务读取条码类型、Code ID 等固件特定字段。
- `Nf5503PrintEvent.errorCode` 会在状态值可识别时转换为 `Nf5503PrintErrorCode`。

## Android SDK 说明

- `ScanManager_V202105081630.jar` 与 `PrinterAPI_V202108242200.jar` 作为 `compileOnly` 引入，因为 NF5503 设备系统会提供真实实现。
- `lcprintsdk1.1-classes.jar` 随插件打包，用于 `PrintUtil` 的标签黑标走纸和打印支持探测。
- 高级码制参数仍以整数透传，便于和原生 SDK 的 `DecoderConfigValues` 常量保持一致。

## 开发与验证

```bash
flutter analyze
flutter test
cd example && flutter analyze
```

如需验证原生 Android 单元测试，可在示例 Android 工程中执行对应 Gradle 测试任务。

## 许可证

本项目采用 MIT License，详见 [LICENSE](LICENSE)。
