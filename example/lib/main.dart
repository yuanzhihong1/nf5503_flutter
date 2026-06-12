import 'dart:async';
import 'dart:ui' as ui;

import 'package:flutter/cupertino.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:nf5503_flutter/nf5503_flutter.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatefulWidget {
  const MyApp({super.key});

  @override
  State<MyApp> createState() => _MyAppState();
}

enum _PrintPaperType { receipt, label }

enum _ActionTone { filled, tinted, plain }

class _MyAppState extends State<MyApp> {
  static const _defaultScanAction = 'com.m5stack.nf5503_flutter.SCAN';
  static const _defaultScanKey = 'barcode';
  static const _thermalCalibrationDensities = <int>[
    4,
    8,
    12,
    16,
    20,
    24,
    28,
    32,
    36,
    40,
  ];

  final _plugin = Nf5503Flutter();
  final _scanActionController = TextEditingController(text: _defaultScanAction);
  final _scanKeyController = TextEditingController(text: _defaultScanKey);
  final _blackMarkThresholdController = TextEditingController(text: '120');
  final _logs = <String>[];

  StreamSubscription<Nf5503ScanResult>? _scanSubscription;
  StreamSubscription<Nf5503PrintEvent>? _printSubscription;

  String _platformVersion = 'Unknown';
  String _scannerMode = '-';
  String _lastScan = '等待扫码结果';
  String _printerVersion = 'Unknown';
  bool? _scannerOpen;
  bool? _printerOpen;
  int? _supportPrint;
  int? _lastPrinterState;
  bool _printServiceEnabled = false;
  bool _blackMarkThresholdEnabled = true;
  _PrintPaperType _printPaperType = _PrintPaperType.receipt;
  String _printFontName = 'Roboto-Regular';
  int _thermalCalibrationDensity = 25;
  bool _busy = false;

  @override
  void initState() {
    super.initState();
    unawaited(_loadPlatformVersion());
  }

  @override
  void dispose() {
    _scanSubscription?.cancel();
    _printSubscription?.cancel();
    _scanActionController.dispose();
    _scanKeyController.dispose();
    _blackMarkThresholdController.dispose();
    super.dispose();
  }

  Future<void> _loadPlatformVersion() async {
    try {
      final version = await _plugin.getPlatformVersion();
      if (!mounted) {
        return;
      }
      setState(() => _platformVersion = version ?? 'Unknown');
      _log('平台版本: $_platformVersion');
    } on PlatformException catch (error) {
      _log('读取平台版本失败: ${error.message ?? error.code}');
    } on MissingPluginException catch (error) {
      _log('当前运行环境未注册插件: ${error.message ?? error.toString()}');
    } catch (error) {
      _log('读取平台版本失败: $error');
    }
  }

  Future<void> _run(String label, Future<void> Function() action) async {
    if (_busy) {
      return;
    }
    setState(() => _busy = true);
    _log('开始: $label');
    try {
      await action();
      _log('完成: $label');
    } catch (error, stackTrace) {
      _log('失败: $label -> $error');
      debugPrintStack(stackTrace: stackTrace);
    } finally {
      if (mounted) {
        setState(() => _busy = false);
      }
    }
  }

  void _log(String message) {
    if (!mounted) {
      return;
    }
    final now = DateTime.now();
    final time =
        '${now.hour.toString().padLeft(2, '0')}:'
        '${now.minute.toString().padLeft(2, '0')}:'
        '${now.second.toString().padLeft(2, '0')}';
    setState(() {
      _logs.insert(0, '[$time] $message');
      if (_logs.length > 80) {
        _logs.removeLast();
      }
    });
  }

  Future<void> _prepareScanner() async {
    final action = _scanActionController.text.trim();
    final key = _scanKeyController.text.trim();
    if (action.isEmpty || key.isEmpty) {
      throw StateError('广播 Action 和 Key 不能为空');
    }

    await _scanSubscription?.cancel();
    await _plugin.scanner.setBroadcastAction(action);
    await _plugin.scanner.setBroadcastKey(key);
    await _plugin.scanner.setOutputMode(Nf5503ScanOutputMode.broadcast);
    await _plugin.scanner.setEndMark(Nf5503ScanEndMark.none);
    await _plugin.scanner.setPlaySound(true);
    await _plugin.scanner.setVibrate(true);

    final openResult = await _plugin.scanner.open();
    final isOpen = await _plugin.scanner.isOpen();
    final mode = await _plugin.scanner.getOutputMode();

    _scanSubscription = _plugin.scanner
        .results(action: action, key: key)
        .listen((result) {
          setState(() => _lastScan = result.data);
          _log('扫码结果: ${result.data}');
        }, onError: (Object error) => _log('扫码监听错误: $error'));

    setState(() {
      _scannerOpen = isOpen;
      _scannerMode = mode.name;
      _lastScan = '已监听 $action / $key，按“开始扫码”或实体扫码键测试';
    });
    _log('扫码 SDK 初始化: open=$openResult, isOpen=$isOpen, mode=${mode.name}');
  }

  Future<void> _startDecode() async {
    final success = await _plugin.scanner.startDecode();
    _log('startDecode 返回: $success');
  }

  Future<void> _stopDecode() async {
    final success = await _plugin.scanner.stopDecode();
    _log('stopDecode 返回: $success');
  }

  Future<void> _readScannerConfig() async {
    final isOpen = await _plugin.scanner.isOpen();
    final mode = await _plugin.scanner.getOutputMode();
    final action = await _plugin.scanner.getBroadcastAction();
    final key = await _plugin.scanner.getBroadcastKey();
    final sound = await _plugin.scanner.getPlaySound();
    final vibrate = await _plugin.scanner.getVibrate();
    setState(() {
      _scannerOpen = isOpen;
      _scannerMode = mode.name;
    });
    _log(
      '扫码配置: open=$isOpen, mode=${mode.name}, action=$action, key=$key, sound=$sound, vibrate=$vibrate',
    );
  }

  Future<void> _closeScanner() async {
    await _scanSubscription?.cancel();
    _scanSubscription = null;
    final success = await _plugin.scanner.close();
    setState(() => _scannerOpen = false);
    _log('closeScanner 返回: $success');
  }

  Future<void> _listenPrinterEvents() async {
    await _printSubscription?.cancel();
    _printSubscription = _plugin.printer.events().listen((event) {
      if (event.type == Nf5503PrintEventType.version) {
        setState(() => _printerVersion = event.version ?? 'Unknown');
        _log('打印版本回调: ${event.version ?? 'Unknown'}');
        return;
      }
      setState(() => _lastPrinterState = event.state);
      _log(
        '打印状态回调: state=${event.state}, code=${event.errorCode?.name ?? 'unknown'}',
      );
    }, onError: (Object error) => _log('打印监听错误: $error'));
    _log('已启动打印事件监听');
  }

  Future<void> _openPrinter() async {
    await _listenPrinterEvents();
    final openResult = await _plugin.printer.open();
    final version = await _plugin.printer.getVersion();
    final supportPrint = await _plugin.printer.getSupportPrint();
    final concentration = await _plugin.printer.getConcentration();
    final fontType = await _plugin.printer.getFontType();
    setState(() {
      _printerOpen = openResult;
      _printServiceEnabled = openResult;
      _printerVersion = version;
      _supportPrint = supportPrint;
      _printFontName = fontType.isEmpty ? _printFontName : fontType;
      _thermalCalibrationDensity = concentration.clamp(1, 40).toInt();
    });
    _log(
      '打印 SDK 打开: open=$openResult, version=$version, support=$supportPrint, density=$concentration',
    );
  }

  Future<void> _setPrintServiceEnabled(bool enabled) async {
    if (enabled) {
      await _openPrinter();
      await _applyPrinterCommonSettings();
      return;
    }
    await _closePrinter();
  }

  Future<void> _setPaperType(_PrintPaperType type) async {
    setState(() => _printPaperType = type);
    await _plugin.printer.open();
    await _plugin.printer.setBlackMark(type == _PrintPaperType.label);
    setState(() {
      _printerOpen = true;
      _printServiceEnabled = true;
    });
    _log('打印纸类型: ${type == _PrintPaperType.label ? '热敏标签纸' : '热敏小票纸'}');
  }

  Future<void> _setPrintDensity(int density) async {
    await _plugin.printer.open();
    await _plugin.printer.setConcentration(density);
    setState(() {
      _printerOpen = true;
      _printServiceEnabled = true;
    });
    _log('当前打印浓度已设置: $density');
  }

  Future<void> _selectPrintFont() async {
    final selectedFont = await showCupertinoModalPopup<String>(
      context: context,
      builder: (context) {
        return CupertinoActionSheet(
          title: const Text('选择打印字体'),
          message: const Text('与官方 demo 的字体配置项保持一致'),
          actions: [
            for (final font in const ['Roboto-Regular', 'default'])
              CupertinoActionSheetAction(
                onPressed: () => Navigator.of(context).pop(font),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(font),
                    if (font == _printFontName) ...[
                      const SizedBox(width: 8),
                      const Icon(CupertinoIcons.checkmark_alt, size: 18),
                    ],
                  ],
                ),
              ),
          ],
          cancelButton: CupertinoActionSheetAction(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('取消'),
          ),
        );
      },
    );
    if (selectedFont == null) {
      return;
    }
    await _plugin.printer.open();
    await _plugin.printer.setFontType(selectedFont);
    setState(() {
      _printFontName = selectedFont;
      _printerOpen = true;
      _printServiceEnabled = true;
    });
    _log('当前打印字体: $_printFontName');
  }

  Future<void> _applyPrinterCommonSettings() async {
    await _plugin.printer.open();
    await _plugin.printer.setBlackMark(
      _printPaperType == _PrintPaperType.label,
    );
    await _plugin.printer.setConcentration(_thermalCalibrationDensity);
    await _plugin.printer.setReverse(false);
    await _plugin.printer.setUnderline(false);
    await _plugin.printer.setBold(false);
    await _plugin.printer.setLineSpacing(1.0);
    if (_printPaperType == _PrintPaperType.label &&
        _blackMarkThresholdEnabled) {
      await _setBlackMarkThreshold(logResult: false);
    }
    setState(() {
      _printerOpen = true;
      _printServiceEnabled = true;
    });
  }

  Future<void> _setBlackMarkThresholdEnabled(bool enabled) async {
    final targetPaperType = enabled ? _PrintPaperType.label : _printPaperType;
    setState(() => _blackMarkThresholdEnabled = enabled);
    await _plugin.printer.open();
    await _plugin.printer.setBlackMark(
      targetPaperType == _PrintPaperType.label,
    );
    setState(() {
      _printerOpen = true;
      _printServiceEnabled = true;
      _printPaperType = targetPaperType;
    });
    _log('黑标阈值启用开关: $enabled');
  }

  Future<void> _getBlackMarkThreshold() async {
    final blackMark = await _plugin.printer.isBlackMark();
    final state = await _plugin.printer.getState(
      Nf5503PrinterStateType.checkBlackMark,
    );
    setState(() => _lastPrinterState = state);
    _log(
      '黑标状态: enabled=$blackMark, state=$state, 当前输入阈值=${_blackMarkThresholdController.text}',
    );
  }

  Future<void> _setBlackMarkThreshold({bool logResult = true}) async {
    final threshold = _blackMarkThreshold();
    await _plugin.printer.open();
    await _plugin.printer.setBlackMark(true);
    final state = await _plugin.printer.setThreshold(threshold);
    setState(() {
      _printerOpen = true;
      _printServiceEnabled = true;
      _printPaperType = _PrintPaperType.label;
      _lastPrinterState = state;
    });
    if (logResult) {
      _log('黑标阈值已设置: threshold=$threshold, state=$state');
    }
  }

  Future<void> _printBlackMarkTest() async {
    await _applyPrinterCommonSettings();
    await _plugin.printer.addText(
      'Black Mark Threshold Test',
      align: Nf5503PrintAlign.center,
      fontSize: Nf5503PrintFontSize.middle,
      isBold: true,
    );
    await _plugin.printer.addText(
      'Threshold: ${_blackMarkThreshold()}',
      align: Nf5503PrintAlign.center,
    );
    await _plugin.printer.addText(
      DateTime.now().toIso8601String(),
      align: Nf5503PrintAlign.center,
    );
    await _plugin.printer.goToNextMark();
    _log('已提交黑标阈值打印测试');
  }

  Future<void> _autoCalibrateBlackMark() async {
    await _setBlackMarkThreshold(logResult: false);
    await _plugin.printer.goToNextMark();
    final state = await _plugin.printer.getState(
      Nf5503PrinterStateType.checkBlackMark,
    );
    setState(() => _lastPrinterState = state);
    _log('已执行自动校准: threshold=${_blackMarkThreshold()}, state=$state');
  }

  Future<void> _printTextTest() async {
    await _applyPrinterCommonSettings();
    await _plugin.printer.addText(
      'NF5503 Text Print',
      align: Nf5503PrintAlign.center,
      fontSize: Nf5503PrintFontSize.large,
      isBold: true,
    );
    await _plugin.printer.addText('Paper: ${_paperTypeLabel(_printPaperType)}');
    await _plugin.printer.addText('Density: $_thermalCalibrationDensity/40');
    await _plugin.printer.addText('ABCDEFGHIJKLMNOPQRSTUVWXYZ');
    await _plugin.printer.addText('abcdefghijklmnopqrstuvwxyz');
    await _plugin.printer.addText('0123456789');
    await _plugin.printer.addBlankLines(3);
    await _plugin.printer.start();
    _log('已提交文本打印测试');
  }

  Future<void> _printBarcodeTest() async {
    await _applyPrinterCommonSettings();
    await _plugin.printer.addText(
      'Barcode Print',
      align: Nf5503PrintAlign.center,
      fontSize: Nf5503PrintFontSize.middle,
      isBold: true,
    );
    await _plugin.printer.addBarcode(
      content: 'NF5503-123456',
      height: 80,
      type: Nf5503BarcodeType.code128,
      align: Nf5503PrintAlign.center,
      hriPosition: Nf5503HriPosition.below,
    );
    await _plugin.printer.addQrCode(
      'NF5503 Flutter SDK test ${DateTime.now().millisecondsSinceEpoch}',
      align: Nf5503PrintAlign.center,
      size: 240,
    );
    await _plugin.printer.addBlankLines(3);
    await _plugin.printer.start();
    _log('已提交条码打印测试');
  }

  Future<void> _printImageTest() async {
    await _applyPrinterCommonSettings();
    final imageBytes = await _buildPrintImageBytes();
    await _plugin.printer.addImageBytes(
      imageBytes,
      align: Nf5503PrintAlign.center,
    );
    await _plugin.printer.addBlankLines(3);
    await _plugin.printer.start();
    _log('已提交图片打印测试');
  }

  Future<void> _printThermalCalibrationScale() async {
    await _listenPrinterEvents();
    await _plugin.printer.open();
    await _plugin.printer.setBlackMark(false);
    await _plugin.printer.setReverse(false);
    await _plugin.printer.setUnderline(false);
    await _plugin.printer.setBold(false);
    await _plugin.printer.setLineSpacing(1.0);

    for (final density in _thermalCalibrationDensities) {
      await _waitForPrinterIdle();
      await _plugin.printer.setConcentration(density);
      await _plugin.printer.addText(
        'Density $density/40  gray ${_nativeDensityStep(density)}/10',
        align: Nf5503PrintAlign.center,
        fontSize: Nf5503PrintFontSize.small,
        isBold: true,
      );
      await _plugin.printer.addText('The quick brown fox 1234567890');
      await _plugin.printer.addText('############################');
      await _plugin.printer.addText('||||||||||||||||||||||||||||');
      await _plugin.printer.addBlankLines(1);
      await _plugin.printer.start();
      await Future<void>.delayed(const Duration(milliseconds: 600));
      await _waitForPrinterIdle(timeout: const Duration(seconds: 5));
    }

    setState(() => _printerOpen = true);
    _log('已提交热敏浓度校准尺: 4/8/.../40');
  }

  Future<void> _printLabelSample() async {
    setState(() => _printPaperType = _PrintPaperType.label);
    await _applyPrinterCommonSettings();
    await _plugin.printer.setUnwindPaperLength(120);
    await _plugin.printer.addText(
      'NF5503 Label Test',
      align: Nf5503PrintAlign.center,
      fontSize: Nf5503PrintFontSize.middle,
      isBold: true,
    );
    await _plugin.printer.addText(
      DateTime.now().toIso8601String(),
      align: Nf5503PrintAlign.center,
    );
    await _plugin.printer.goToNextMark();
    setState(() => _printerOpen = true);
    _log('已提交标签打印样张并走到下一黑标');
  }

  Future<void> _closePrinter() async {
    final success = await _plugin.printer.close();
    setState(() {
      _printerOpen = false;
      _printServiceEnabled = false;
    });
    _log('closePrinter 返回: $success');
  }

  Future<void> _waitForPrinterIdle({
    Duration timeout = const Duration(seconds: 8),
  }) async {
    final deadline = DateTime.now().add(timeout);
    while (DateTime.now().isBefore(deadline)) {
      final state = await _plugin.printer.getState(
        Nf5503PrinterStateType.checkBusy,
      );
      if (state == Nf5503PrintErrorCode.noError.value) {
        return;
      }
      await Future<void>.delayed(const Duration(milliseconds: 350));
    }
    _log('等待打印机空闲超时，继续提交后续校准内容');
  }

  int _nativeDensityStep(int density) {
    final step = (density / 4).ceil();
    if (step < 1) {
      return 1;
    }
    if (step > 10) {
      return 10;
    }
    return step;
  }

  int _blackMarkThreshold() {
    final value =
        int.tryParse(_blackMarkThresholdController.text.trim()) ?? 120;
    return value.clamp(0, 255).toInt();
  }

  String _paperTypeLabel(_PrintPaperType type) {
    return type == _PrintPaperType.label ? '热敏标签纸' : '热敏小票纸';
  }

  Future<Uint8List> _buildPrintImageBytes() async {
    const width = 384;
    const height = 160;
    final recorder = ui.PictureRecorder();
    final canvas = ui.Canvas(recorder);
    final whitePaint = ui.Paint()..color = const ui.Color(0xFFFFFFFF);
    final blackPaint = ui.Paint()..color = const ui.Color(0xFF000000);
    final borderPaint = ui.Paint()
      ..color = const ui.Color(0xFF000000)
      ..style = ui.PaintingStyle.stroke
      ..strokeWidth = 4;

    canvas.drawRect(
      ui.Rect.fromLTWH(0, 0, width.toDouble(), height.toDouble()),
      whitePaint,
    );
    canvas.drawRect(
      ui.Rect.fromLTWH(
        12,
        12,
        (width - 24).toDouble(),
        (height - 24).toDouble(),
      ),
      borderPaint,
    );

    final title = TextPainter(
      text: const TextSpan(
        text: 'NF5503 IMAGE TEST',
        style: TextStyle(
          color: Color(0xFF000000),
          fontSize: 28,
          fontWeight: FontWeight.w800,
        ),
      ),
      textDirection: TextDirection.ltr,
    )..layout(maxWidth: width - 48);
    title.paint(canvas, const ui.Offset(24, 28));

    for (var index = 0; index < 9; index++) {
      final left = 24.0 + index * 38;
      final top = index.isEven ? 86.0 : 104.0;
      canvas.drawRect(ui.Rect.fromLTWH(left, top, 26, 26), blackPaint);
    }

    final picture = recorder.endRecording();
    final image = await picture.toImage(width, height);
    final byteData = await image.toByteData(format: ui.ImageByteFormat.png);
    return byteData!.buffer.asUint8List();
  }

  @override
  Widget build(BuildContext context) {
    return CupertinoApp(
      debugShowCheckedModeBanner: false,
      title: 'NF5503 Flutter Example',
      theme: const CupertinoThemeData(
        brightness: Brightness.light,
        primaryColor: _AppColors.primary,
        scaffoldBackgroundColor: _AppColors.paper,
        textTheme: CupertinoTextThemeData(
          textStyle: TextStyle(
            color: _AppColors.ink,
            fontSize: 15,
            height: 1.35,
            fontFamily: '.SF Pro Text',
          ),
        ),
      ),
      home: CupertinoPageScaffold(
        child: DecoratedBox(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [_AppColors.ink, _AppColors.deepTeal, _AppColors.paper],
            ),
          ),
          child: SafeArea(
            child: CustomScrollView(
              slivers: [
                SliverPadding(
                  padding: const EdgeInsets.fromLTRB(18, 18, 18, 28),
                  sliver: SliverList.list(
                    children: [
                      _Header(platformVersion: _platformVersion, busy: _busy),
                      const SizedBox(height: 16),
                      _scannerCard(),
                      const SizedBox(height: 14),
                      _printerCard(),
                      const SizedBox(height: 14),
                      _LogCard(
                        logs: _logs,
                        onClear: () => setState(_logs.clear),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _scannerCard() {
    return _SectionCard(
      icon: CupertinoIcons.barcode_viewfinder,
      title: '扫码 SDK 测试',
      subtitle: '先初始化广播并监听，再点击开始扫码或按设备扫码键。',
      children: [
        Row(
          children: [
            Expanded(
              child: _InfoTile(
                label: '扫描头',
                value: _scannerOpen == true ? 'Open' : 'Closed',
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: _InfoTile(label: '输出模式', value: _scannerMode),
            ),
          ],
        ),
        const SizedBox(height: 12),
        _CupertinoField(
          label: '广播 Action',
          controller: _scanActionController,
          enabled: !_busy,
        ),
        const SizedBox(height: 10),
        _CupertinoField(
          label: '广播 Key',
          controller: _scanKeyController,
          enabled: !_busy,
        ),
        const SizedBox(height: 12),
        _ResultBox(title: '最近扫码', value: _lastScan),
        const SizedBox(height: 12),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [
            _ActionButton(
              label: '初始化/监听',
              icon: CupertinoIcons.antenna_radiowaves_left_right,
              tone: _ActionTone.filled,
              onPressed: _busy ? null : () => _run('初始化扫码并监听', _prepareScanner),
            ),
            _ActionButton(
              label: '开始扫码',
              icon: CupertinoIcons.play_arrow_solid,
              onPressed: _busy ? null : () => _run('开始扫码', _startDecode),
            ),
            _ActionButton(
              label: '停止',
              icon: CupertinoIcons.stop_fill,
              tone: _ActionTone.plain,
              onPressed: _busy ? null : () => _run('停止扫码', _stopDecode),
            ),
            _ActionButton(
              label: '读配置',
              icon: CupertinoIcons.doc_text_search,
              tone: _ActionTone.plain,
              onPressed: _busy
                  ? null
                  : () => _run('读取扫码配置', _readScannerConfig),
            ),
            _ActionButton(
              label: '关闭',
              icon: CupertinoIcons.power,
              tone: _ActionTone.plain,
              onPressed: _busy ? null : () => _run('关闭扫码', _closeScanner),
            ),
          ],
        ),
      ],
    );
  }

  Widget _printerCard() {
    final state = _lastPrinterState;
    final code = state == null
        ? '-'
        : (Nf5503PrintErrorCode.fromValue(state)?.name ?? '$state');
    final isLabelPaper = _printPaperType == _PrintPaperType.label;
    return _SectionCard(
      icon: CupertinoIcons.printer,
      title: '打印 SDK 测试',
      subtitle: '按官方 demo 的打印服务配置组织：通用设置、标签校准和打印测试项。',
      children: [
        Row(
          children: [
            Expanded(
              child: _InfoTile(
                label: '打印机',
                value: _printerOpen == true ? 'Open' : 'Closed',
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: _InfoTile(label: '支持模块', value: '${_supportPrint ?? '-'}'),
            ),
          ],
        ),
        const SizedBox(height: 10),
        Row(
          children: [
            Expanded(
              child: _InfoTile(label: '版本', value: _printerVersion),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: _InfoTile(label: '状态', value: code),
            ),
          ],
        ),
        const SizedBox(height: 12),
        _PrintServiceSwitchPanel(
          value: _printServiceEnabled,
          enabled: !_busy,
          onChanged: (value) => _run(
            value ? '开启打印服务' : '关闭打印服务',
            () => _setPrintServiceEnabled(value),
          ),
        ),
        const SizedBox(height: 12),
        _PrinterCommonSettingsPanel(
          paperType: _printPaperType,
          density: _thermalCalibrationDensity,
          fontName: _printFontName,
          enabled: !_busy,
          onPaperTypeChanged: (type) =>
              _run('设置打印纸类型', () => _setPaperType(type)),
          onDensityChanged: (value) {
            setState(() => _thermalCalibrationDensity = value);
          },
          onDensityChangeEnd: (value) =>
              _run('设置打印浓度', () => _setPrintDensity(value)),
          onFontTap: () => _run('读取打印字体', _selectPrintFont),
        ),
        const SizedBox(height: 12),
        if (isLabelPaper) ...[
          _LabelCalibrationPanel(
            enabled: !_busy,
            thresholdEnabled: _blackMarkThresholdEnabled,
            thresholdController: _blackMarkThresholdController,
            onThresholdEnabledChanged: (value) =>
                _run('设置黑标阈值启用开关', () => _setBlackMarkThresholdEnabled(value)),
            onGetThreshold: () => _run('获取黑标阈值', _getBlackMarkThreshold),
            onSetThreshold: () => _run('设置黑标阈值', _setBlackMarkThreshold),
            onPrintTest: () => _run('黑标阈值打印测试', _printBlackMarkTest),
            onAutoCalibrate: () => _run('自动校准黑标', _autoCalibrateBlackMark),
          ),
          const SizedBox(height: 12),
        ],
        _PrintTestItemsPanel(
          enabled: !_busy,
          onTextPrint: () => _run('文本打印', _printTextTest),
          onBarcodePrint: () => _run('条码打印', _printBarcodeTest),
          onImagePrint: () => _run('图片打印', _printImageTest),
          onLabelPrint: () => _run('标签打印', _printLabelSample),
          onCalibrationScale: () =>
              _run('热敏浓度校准尺', _printThermalCalibrationScale),
        ),
      ],
    );
  }
}

class _AppColors {
  const _AppColors._();

  static const ink = Color(0xFF081816);
  static const deepTeal = Color(0xFF123D37);
  static const primary = Color(0xFF087568);
  static const accent = Color(0xFFF6C453);
  static const paper = Color(0xFFFFF5DC);
  static const card = Color(0xFFFFFCF5);
  static const mist = Color(0xFFE7F3EF);
  static const line = Color(0xFFE7DED0);
  static const panel = Color(0xFFF7F7F7);
  static const blue = Color(0xFF0A84FF);
  static const white = Color(0xFFFFFFFF);
  static const white70 = Color(0xB3FFFFFF);
}

class _Header extends StatelessWidget {
  const _Header({required this.platformVersion, required this.busy});

  final String platformVersion;
  final bool busy;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: _AppColors.white.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(28),
        border: Border.all(color: _AppColors.white.withValues(alpha: 0.24)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const _IconBadge(
                icon: CupertinoIcons.waveform_path_ecg,
                backgroundColor: _AppColors.accent,
                foregroundColor: _AppColors.ink,
                size: 48,
              ),
              const SizedBox(width: 12),
              const Expanded(
                child: Text(
                  'NF5503 SDK Probe',
                  style: TextStyle(
                    color: _AppColors.white,
                    fontSize: 26,
                    fontWeight: FontWeight.w800,
                    letterSpacing: -0.8,
                    height: 1.05,
                  ),
                ),
              ),
              if (busy)
                const SizedBox(
                  width: 24,
                  height: 24,
                  child: CupertinoActivityIndicator(color: _AppColors.white),
                ),
            ],
          ),
          const SizedBox(height: 10),
          Text(
            '用于真机验证扫码与打印官方 SDK 是否能被 Flutter 插件正确调用。',
            style: TextStyle(
              color: _AppColors.white.withValues(alpha: 0.82),
              fontSize: 14,
              height: 1.45,
            ),
          ),
          const SizedBox(height: 14),
          _GlassPill(label: 'Platform', value: platformVersion),
        ],
      ),
    );
  }
}

class _SectionCard extends StatelessWidget {
  const _SectionCard({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.children,
  });

  final IconData icon;
  final String title;
  final String subtitle;
  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: _AppColors.card.withValues(alpha: 0.96),
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            blurRadius: 24,
            offset: const Offset(0, 12),
            color: _AppColors.ink.withValues(alpha: 0.16),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              _IconBadge(icon: icon),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: const TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.w800,
                        color: _AppColors.ink,
                        letterSpacing: -0.2,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      subtitle,
                      style: const TextStyle(
                        color: Color(0xFF55615E),
                        fontSize: 13,
                        height: 1.35,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          ...children,
        ],
      ),
    );
  }
}

class _IconBadge extends StatelessWidget {
  const _IconBadge({
    required this.icon,
    this.backgroundColor = _AppColors.primary,
    this.foregroundColor = _AppColors.white,
    this.size = 42,
  });

  final IconData icon;
  final Color backgroundColor;
  final Color foregroundColor;
  final double size;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(color: backgroundColor, shape: BoxShape.circle),
      child: Icon(icon, color: foregroundColor, size: size * 0.52),
    );
  }
}

class _PrintServiceSwitchPanel extends StatelessWidget {
  const _PrintServiceSwitchPanel({
    required this.value,
    required this.enabled,
    required this.onChanged,
  });

  final bool value;
  final bool enabled;
  final ValueChanged<bool> onChanged;

  @override
  Widget build(BuildContext context) {
    return _OfficialPanel(
      child: Row(
        children: [
          const Expanded(
            child: Text(
              '打印服务开关',
              style: TextStyle(
                color: Color(0xFF1F2933),
                fontWeight: FontWeight.w700,
                fontSize: 16,
              ),
            ),
          ),
          CupertinoSwitch(
            value: value,
            activeTrackColor: _AppColors.primary,
            onChanged: enabled ? onChanged : null,
          ),
        ],
      ),
    );
  }
}

class _PrinterCommonSettingsPanel extends StatelessWidget {
  const _PrinterCommonSettingsPanel({
    required this.paperType,
    required this.density,
    required this.fontName,
    required this.enabled,
    required this.onPaperTypeChanged,
    required this.onDensityChanged,
    required this.onDensityChangeEnd,
    required this.onFontTap,
  });

  final _PrintPaperType paperType;
  final int density;
  final String fontName;
  final bool enabled;
  final ValueChanged<_PrintPaperType> onPaperTypeChanged;
  final ValueChanged<int> onDensityChanged;
  final ValueChanged<int> onDensityChangeEnd;
  final VoidCallback onFontTap;

  @override
  Widget build(BuildContext context) {
    return _OfficialPanel(
      child: Column(
        children: [
          const _OfficialPanelHeader(
            icon: CupertinoIcons.slider_horizontal_3,
            title: '通用设置',
          ),
          const SizedBox(height: 14),
          _ConfigLine(
            label: '打印纸类型:',
            child: Wrap(
              spacing: 10,
              runSpacing: 8,
              children: [
                _PaperRadio(
                  title: '热敏小票纸',
                  value: _PrintPaperType.receipt,
                  groupValue: paperType,
                  enabled: enabled,
                  onChanged: onPaperTypeChanged,
                ),
                _PaperRadio(
                  title: '热敏标签纸',
                  value: _PrintPaperType.label,
                  groupValue: paperType,
                  enabled: enabled,
                  onChanged: onPaperTypeChanged,
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),
          _ConfigLine(
            label: '打印机尺寸:',
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: const [
                _RadioDot(selected: true, enabled: true),
                SizedBox(width: 8),
                Text('2寸(58mm)'),
              ],
            ),
          ),
          const SizedBox(height: 12),
          _ConfigLine(
            label: '当前打印浓度:',
            child: Row(
              children: [
                Expanded(
                  child: CupertinoSlider(
                    value: density.toDouble(),
                    min: 1,
                    max: 40,
                    divisions: 39,
                    activeColor: _AppColors.primary,
                    onChanged: enabled
                        ? (value) => onDensityChanged(value.round())
                        : null,
                    onChangeEnd: enabled
                        ? (value) => onDensityChangeEnd(value.round())
                        : null,
                  ),
                ),
                SizedBox(
                  width: 34,
                  child: Text(
                    '$density',
                    textAlign: TextAlign.right,
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),
          _Pressable(
            enabled: enabled,
            onTap: onFontTap,
            borderRadius: BorderRadius.circular(10),
            child: _ConfigLine(
              label: '打印字体:',
              child: Row(
                children: [
                  Expanded(child: Text(fontName)),
                  const Icon(
                    CupertinoIcons.chevron_right,
                    color: _AppColors.blue,
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _LabelCalibrationPanel extends StatelessWidget {
  const _LabelCalibrationPanel({
    required this.enabled,
    required this.thresholdEnabled,
    required this.thresholdController,
    required this.onThresholdEnabledChanged,
    required this.onGetThreshold,
    required this.onSetThreshold,
    required this.onPrintTest,
    required this.onAutoCalibrate,
  });

  final bool enabled;
  final bool thresholdEnabled;
  final TextEditingController thresholdController;
  final ValueChanged<bool> onThresholdEnabledChanged;
  final VoidCallback onGetThreshold;
  final VoidCallback onSetThreshold;
  final VoidCallback onPrintTest;
  final VoidCallback onAutoCalibrate;

  @override
  Widget build(BuildContext context) {
    return _OfficialPanel(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(
            children: [
              Icon(CupertinoIcons.sparkles, color: _AppColors.blue),
              SizedBox(width: 12),
              Text(
                '标签校准',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
              ),
              SizedBox(width: 8),
              Icon(CupertinoIcons.question_circle, color: _AppColors.blue),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              const Expanded(child: Text('黑标阈值启用开关')),
              CupertinoSwitch(
                value: thresholdEnabled,
                activeTrackColor: _AppColors.primary,
                onChanged: enabled ? onThresholdEnabledChanged : null,
              ),
            ],
          ),
          const SizedBox(height: 8),
          Wrap(
            spacing: 10,
            runSpacing: 10,
            crossAxisAlignment: WrapCrossAlignment.center,
            children: [
              const Text('黑标阈值'),
              SizedBox(
                width: 94,
                child: CupertinoTextField(
                  controller: thresholdController,
                  enabled: enabled && thresholdEnabled,
                  keyboardType: TextInputType.number,
                  textAlign: TextAlign.center,
                  inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 10,
                  ),
                  decoration: BoxDecoration(
                    color: _AppColors.white,
                    border: Border.all(color: _AppColors.line),
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
              ),
              _OfficialButton(
                label: '获取',
                onPressed: enabled ? onGetThreshold : null,
              ),
              _OfficialButton(
                label: '设置',
                onPressed: enabled && thresholdEnabled ? onSetThreshold : null,
              ),
              _OfficialButton(
                label: '打印测试',
                onPressed: enabled ? onPrintTest : null,
              ),
              _OfficialButton(
                label: '自动校准',
                onPressed: enabled && thresholdEnabled ? onAutoCalibrate : null,
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _PrintTestItemsPanel extends StatelessWidget {
  const _PrintTestItemsPanel({
    required this.enabled,
    required this.onTextPrint,
    required this.onBarcodePrint,
    required this.onImagePrint,
    required this.onLabelPrint,
    required this.onCalibrationScale,
  });

  final bool enabled;
  final VoidCallback onTextPrint;
  final VoidCallback onBarcodePrint;
  final VoidCallback onImagePrint;
  final VoidCallback onLabelPrint;
  final VoidCallback onCalibrationScale;

  @override
  Widget build(BuildContext context) {
    return _OfficialPanel(
      padding: EdgeInsets.zero,
      child: Column(
        children: [
          const Padding(
            padding: EdgeInsets.fromLTRB(16, 16, 16, 10),
            child: _OfficialPanelHeader(
              icon: CupertinoIcons.printer_fill,
              title: '打印测试项',
            ),
          ),
          _PrintTestTile(
            icon: CupertinoIcons.text_alignleft,
            title: '文本打印',
            enabled: enabled,
            onTap: onTextPrint,
          ),
          _PrintTestTile(
            icon: CupertinoIcons.barcode,
            title: '条码打印',
            enabled: enabled,
            onTap: onBarcodePrint,
          ),
          _PrintTestTile(
            icon: CupertinoIcons.photo,
            title: '图片打印',
            enabled: enabled,
            onTap: onImagePrint,
          ),
          _PrintTestTile(
            icon: CupertinoIcons.tag,
            title: '标签打印',
            enabled: enabled,
            onTap: onLabelPrint,
          ),
          _PrintTestTile(
            icon: CupertinoIcons.chart_bar,
            title: '热敏浓度尺',
            enabled: enabled,
            onTap: onCalibrationScale,
            showDivider: false,
          ),
        ],
      ),
    );
  }
}

class _OfficialPanel extends StatelessWidget {
  const _OfficialPanel({
    required this.child,
    this.padding = const EdgeInsets.all(16),
  });

  final Widget child;
  final EdgeInsetsGeometry padding;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: padding,
      decoration: BoxDecoration(
        color: _AppColors.panel,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: _AppColors.line),
      ),
      child: child,
    );
  }
}

class _OfficialPanelHeader extends StatelessWidget {
  const _OfficialPanelHeader({required this.icon, required this.title});

  final IconData icon;
  final String title;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(icon, color: _AppColors.blue),
        const SizedBox(width: 12),
        Text(
          title,
          style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
        ),
      ],
    );
  }
}

class _ConfigLine extends StatelessWidget {
  const _ConfigLine({required this.label, required this.child});

  final String label;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final narrow = constraints.maxWidth < 360;
        if (narrow) {
          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(label, style: const TextStyle(fontWeight: FontWeight.w600)),
              const SizedBox(height: 8),
              child,
            ],
          );
        }
        return Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            SizedBox(
              width: 112,
              child: Text(
                label,
                style: const TextStyle(fontWeight: FontWeight.w600),
              ),
            ),
            Expanded(child: child),
          ],
        );
      },
    );
  }
}

class _PaperRadio extends StatelessWidget {
  const _PaperRadio({
    required this.title,
    required this.value,
    required this.groupValue,
    required this.enabled,
    required this.onChanged,
  });

  final String title;
  final _PrintPaperType value;
  final _PrintPaperType groupValue;
  final bool enabled;
  final ValueChanged<_PrintPaperType> onChanged;

  @override
  Widget build(BuildContext context) {
    return _Pressable(
      enabled: enabled,
      onTap: () => onChanged(value),
      borderRadius: BorderRadius.circular(999),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 4),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            _RadioDot(selected: value == groupValue, enabled: enabled),
            const SizedBox(width: 8),
            Text(title),
          ],
        ),
      ),
    );
  }
}

class _RadioDot extends StatelessWidget {
  const _RadioDot({required this.selected, required this.enabled});

  final bool selected;
  final bool enabled;

  @override
  Widget build(BuildContext context) {
    final active = enabled ? _AppColors.blue : const Color(0xFF9CA3AF);
    return Container(
      width: 22,
      height: 22,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        border: Border.all(
          color: selected ? active : const Color(0xFF111827),
          width: 2,
        ),
      ),
      child: selected
          ? Center(
              child: Container(
                width: 10,
                height: 10,
                decoration: BoxDecoration(
                  color: active,
                  shape: BoxShape.circle,
                ),
              ),
            )
          : null,
    );
  }
}

class _OfficialButton extends StatelessWidget {
  const _OfficialButton({required this.label, required this.onPressed});

  final String label;
  final VoidCallback? onPressed;

  @override
  Widget build(BuildContext context) {
    return CupertinoButton(
      onPressed: onPressed,
      color: _AppColors.blue,
      disabledColor: const Color(0xFFB6C8D5),
      borderRadius: BorderRadius.circular(10),
      padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 10),
      minimumSize: const Size(0, 38),
      child: Text(label, style: const TextStyle(color: _AppColors.white)),
    );
  }
}

class _PrintTestTile extends StatelessWidget {
  const _PrintTestTile({
    required this.icon,
    required this.title,
    required this.enabled,
    required this.onTap,
    this.showDivider = true,
  });

  final IconData icon;
  final String title;
  final bool enabled;
  final VoidCallback onTap;
  final bool showDivider;

  @override
  Widget build(BuildContext context) {
    final content = _Pressable(
      enabled: enabled,
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        child: Row(
          children: [
            Icon(
              icon,
              color: enabled ? _AppColors.primary : const Color(0xFF9CA3AF),
              size: 22,
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                title,
                style: TextStyle(
                  color: enabled ? _AppColors.ink : const Color(0xFF9CA3AF),
                  fontSize: 16,
                ),
              ),
            ),
            const Icon(
              CupertinoIcons.chevron_right,
              color: _AppColors.blue,
              size: 18,
            ),
          ],
        ),
      ),
    );
    if (!showDivider) {
      return content;
    }
    return Column(children: [content, const _Hairline()]);
  }
}

class _CupertinoField extends StatelessWidget {
  const _CupertinoField({
    required this.label,
    required this.controller,
    required this.enabled,
  });

  final String label;
  final TextEditingController controller;
  final bool enabled;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w700,
            color: Color(0xFF55615E),
          ),
        ),
        const SizedBox(height: 6),
        CupertinoTextField(
          controller: controller,
          enabled: enabled,
          clearButtonMode: OverlayVisibilityMode.editing,
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
          decoration: BoxDecoration(
            color: _AppColors.white,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: _AppColors.line),
          ),
          style: const TextStyle(fontSize: 14, color: _AppColors.ink),
        ),
      ],
    );
  }
}

class _InfoTile extends StatelessWidget {
  const _InfoTile({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: _AppColors.mist,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: const TextStyle(
              color: Color(0xFF596863),
              fontSize: 12,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            value,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              color: _AppColors.ink,
              fontSize: 16,
              fontWeight: FontWeight.w800,
            ),
          ),
        ],
      ),
    );
  }
}

class _ResultBox extends StatelessWidget {
  const _ResultBox({required this.title, required this.value});

  final String title;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: _AppColors.ink,
        borderRadius: BorderRadius.circular(18),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: const TextStyle(
              color: _AppColors.accent,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            value,
            style: const TextStyle(color: _AppColors.white, height: 1.35),
          ),
        ],
      ),
    );
  }
}

class _GlassPill extends StatelessWidget {
  const _GlassPill({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: _AppColors.white.withValues(alpha: 0.16),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        '$label  $value',
        style: const TextStyle(
          color: _AppColors.white,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }
}

class _LogCard extends StatelessWidget {
  const _LogCard({required this.logs, required this.onClear});

  final List<String> logs;
  final VoidCallback onClear;

  @override
  Widget build(BuildContext context) {
    return _SectionCard(
      icon: CupertinoIcons.rectangle_stack,
      title: '调用日志',
      subtitle: '每一步 MethodChannel/EventChannel 调用结果都会记录在这里。',
      children: [
        Align(
          alignment: Alignment.centerRight,
          child: _ActionButton(
            label: '清空',
            icon: CupertinoIcons.trash,
            tone: _ActionTone.plain,
            onPressed: onClear,
          ),
        ),
        Container(
          constraints: const BoxConstraints(minHeight: 180, maxHeight: 320),
          width: double.infinity,
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: _AppColors.ink,
            borderRadius: BorderRadius.circular(18),
          ),
          child: logs.isEmpty
              ? const Text('暂无日志', style: TextStyle(color: _AppColors.white70))
              : ListView.separated(
                  shrinkWrap: true,
                  itemCount: logs.length,
                  separatorBuilder: (_, _) => const SizedBox(height: 8),
                  itemBuilder: (context, index) => Text(
                    logs[index],
                    style: const TextStyle(
                      color: Color(0xFFD1FAE5),
                      fontSize: 12,
                      height: 1.25,
                    ),
                  ),
                ),
        ),
      ],
    );
  }
}

class _ActionButton extends StatelessWidget {
  const _ActionButton({
    required this.label,
    required this.icon,
    required this.onPressed,
    this.tone = _ActionTone.tinted,
  });

  final String label;
  final IconData icon;
  final VoidCallback? onPressed;
  final _ActionTone tone;

  @override
  Widget build(BuildContext context) {
    final child = Row(
      mainAxisSize: MainAxisSize.min,
      children: [Icon(icon, size: 18), const SizedBox(width: 6), Text(label)],
    );

    return switch (tone) {
      _ActionTone.filled => CupertinoButton.filled(
        onPressed: onPressed,
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        minimumSize: const Size(0, 40),
        borderRadius: BorderRadius.circular(12),
        child: child,
      ),
      _ActionTone.tinted => CupertinoButton.tinted(
        onPressed: onPressed,
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        minimumSize: const Size(0, 40),
        borderRadius: BorderRadius.circular(12),
        child: child,
      ),
      _ActionTone.plain => CupertinoButton(
        onPressed: onPressed,
        color: _AppColors.white,
        foregroundColor: _AppColors.primary,
        disabledColor: const Color(0xFFE5E7EB),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        minimumSize: const Size(0, 40),
        borderRadius: BorderRadius.circular(12),
        child: child,
      ),
    };
  }
}

class _Pressable extends StatefulWidget {
  const _Pressable({
    required this.child,
    this.enabled = true,
    this.onTap,
    this.borderRadius,
  });

  final Widget child;
  final bool enabled;
  final VoidCallback? onTap;
  final BorderRadius? borderRadius;

  @override
  State<_Pressable> createState() => _PressableState();
}

class _PressableState extends State<_Pressable> {
  bool _pressed = false;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: widget.enabled ? widget.onTap : null,
      onTapDown: widget.enabled ? (_) => setState(() => _pressed = true) : null,
      onTapCancel: widget.enabled
          ? () => setState(() => _pressed = false)
          : null,
      onTapUp: widget.enabled ? (_) => setState(() => _pressed = false) : null,
      child: AnimatedOpacity(
        duration: const Duration(milliseconds: 120),
        opacity: _pressed ? 0.62 : (widget.enabled ? 1 : 0.48),
        child: DecoratedBox(
          decoration: BoxDecoration(borderRadius: widget.borderRadius),
          child: widget.child,
        ),
      ),
    );
  }
}

class _Hairline extends StatelessWidget {
  const _Hairline();

  @override
  Widget build(BuildContext context) {
    return Container(height: 1, color: _AppColors.line);
  }
}
