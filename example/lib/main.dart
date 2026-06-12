import 'dart:async';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
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
    final selectedFont = await showModalBottomSheet<String>(
      context: context,
      builder: (context) {
        return SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const ListTile(
                title: Text('选择打印字体'),
                subtitle: Text('与官方 demo 的字体配置项保持一致'),
              ),
              for (final font in const ['Roboto-Regular', 'default'])
                ListTile(
                  title: Text(font),
                  trailing: font == _printFontName
                      ? const Icon(Icons.check, color: Color(0xFF0284C7))
                      : null,
                  onTap: () => Navigator.of(context).pop(font),
                ),
            ],
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
          color: Colors.black,
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
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xFF0F766E),
          brightness: Brightness.light,
        ),
        useMaterial3: true,
        fontFamily: 'Avenir Next',
      ),
      home: Scaffold(
        body: Container(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [Color(0xFF0B1F1E), Color(0xFF123D37), Color(0xFFF6E8C8)],
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
      icon: Icons.document_scanner_outlined,
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
        TextField(
          controller: _scanActionController,
          decoration: const InputDecoration(
            labelText: '广播 Action',
            border: OutlineInputBorder(),
            isDense: true,
          ),
        ),
        const SizedBox(height: 10),
        TextField(
          controller: _scanKeyController,
          decoration: const InputDecoration(
            labelText: '广播 Key',
            border: OutlineInputBorder(),
            isDense: true,
          ),
        ),
        const SizedBox(height: 12),
        _ResultBox(title: '最近扫码', value: _lastScan),
        const SizedBox(height: 12),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [
            FilledButton.icon(
              onPressed: _busy ? null : () => _run('初始化扫码并监听', _prepareScanner),
              icon: const Icon(Icons.settings_input_antenna),
              label: const Text('初始化/监听'),
            ),
            FilledButton.tonalIcon(
              onPressed: _busy ? null : () => _run('开始扫码', _startDecode),
              icon: const Icon(Icons.play_arrow),
              label: const Text('开始扫码'),
            ),
            OutlinedButton.icon(
              onPressed: _busy ? null : () => _run('停止扫码', _stopDecode),
              icon: const Icon(Icons.stop),
              label: const Text('停止'),
            ),
            OutlinedButton.icon(
              onPressed: _busy
                  ? null
                  : () => _run('读取扫码配置', _readScannerConfig),
              icon: const Icon(Icons.fact_check_outlined),
              label: const Text('读配置'),
            ),
            OutlinedButton.icon(
              onPressed: _busy ? null : () => _run('关闭扫码', _closeScanner),
              icon: const Icon(Icons.power_settings_new),
              label: const Text('关闭'),
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
      icon: Icons.print_outlined,
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

class _Header extends StatelessWidget {
  const _Header({required this.platformVersion, required this.busy});

  final String platformVersion;
  final bool busy;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(28),
        border: Border.all(color: Colors.white.withValues(alpha: 0.24)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.memory, color: Color(0xFFFDE68A), size: 34),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  'NF5503 SDK Probe',
                  style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                    color: Colors.white,
                    fontWeight: FontWeight.w800,
                    letterSpacing: -0.6,
                  ),
                ),
              ),
              if (busy)
                const SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    color: Colors.white,
                  ),
                ),
            ],
          ),
          const SizedBox(height: 10),
          Text(
            '用于真机验证扫码与打印官方 SDK 是否能被 Flutter 插件正确调用。',
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              color: Colors.white.withValues(alpha: 0.82),
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
        color: const Color(0xFFFFFCF5).withValues(alpha: 0.94),
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            blurRadius: 24,
            offset: const Offset(0, 12),
            color: Colors.black.withValues(alpha: 0.16),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              CircleAvatar(
                backgroundColor: const Color(0xFF0F766E),
                foregroundColor: Colors.white,
                child: Icon(icon),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: Theme.of(context).textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.w800,
                        color: const Color(0xFF102A27),
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      subtitle,
                      style: Theme.of(context).textTheme.bodySmall,
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
          Expanded(
            child: Text(
              '打印服务开关',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                color: const Color(0xFF1F2933),
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
          Switch(value: value, onChanged: enabled ? onChanged : null),
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
          const _OfficialPanelHeader(icon: Icons.build_circle, title: '通用设置'),
          const SizedBox(height: 14),
          _ConfigLine(
            label: '打印纸类型:',
            child: Wrap(
              spacing: 10,
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
              children: [
                _RadioDot(selected: true, enabled: enabled),
                const SizedBox(width: 8),
                const Text('2寸(58mm)'),
              ],
            ),
          ),
          const SizedBox(height: 12),
          _ConfigLine(
            label: '当前打印浓度:',
            child: Row(
              children: [
                Expanded(
                  child: Slider(
                    value: density.toDouble(),
                    min: 1,
                    max: 40,
                    divisions: 39,
                    label: '$density',
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
                    style: Theme.of(context).textTheme.bodyLarge,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),
          InkWell(
            onTap: enabled ? onFontTap : null,
            borderRadius: BorderRadius.circular(10),
            child: _ConfigLine(
              label: '打印字体:',
              child: Row(
                children: [
                  Expanded(child: Text(fontName)),
                  const Icon(Icons.chevron_right, color: Color(0xFF0284C7)),
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
          Row(
            children: [
              const Icon(Icons.auto_fix_high, color: Color(0xFF0284C7)),
              const SizedBox(width: 12),
              Text('标签校准', style: Theme.of(context).textTheme.titleMedium),
              const SizedBox(width: 8),
              const Icon(Icons.help, color: Color(0xFF0284C7)),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              const Expanded(child: Text('黑标阈值启用开关')),
              Switch(
                value: thresholdEnabled,
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
                width: 92,
                child: TextField(
                  controller: thresholdController,
                  enabled: enabled && thresholdEnabled,
                  keyboardType: TextInputType.number,
                  textAlign: TextAlign.center,
                  inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                  decoration: const InputDecoration(
                    isDense: true,
                    border: OutlineInputBorder(),
                    contentPadding: EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 10,
                    ),
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
            child: _OfficialPanelHeader(icon: Icons.print, title: '打印测试项'),
          ),
          _PrintTestTile(title: '文本打印', enabled: enabled, onTap: onTextPrint),
          _PrintTestTile(
            title: '条码打印',
            enabled: enabled,
            onTap: onBarcodePrint,
          ),
          _PrintTestTile(title: '图片打印', enabled: enabled, onTap: onImagePrint),
          _PrintTestTile(title: '标签打印', enabled: enabled, onTap: onLabelPrint),
          _PrintTestTile(
            title: '热敏浓度尺',
            enabled: enabled,
            onTap: onCalibrationScale,
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
        color: const Color(0xFFF7F7F7),
        borderRadius: BorderRadius.circular(4),
        border: Border.all(color: const Color(0xFFE8E8E8)),
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
        Icon(icon, color: const Color(0xFF0284C7)),
        const SizedBox(width: 12),
        Text(title, style: Theme.of(context).textTheme.titleMedium),
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
    return Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        SizedBox(
          width: 112,
          child: Text(label, style: Theme.of(context).textTheme.bodyMedium),
        ),
        Expanded(child: child),
      ],
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
    return InkWell(
      onTap: enabled ? () => onChanged(value) : null,
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          _RadioDot(selected: value == groupValue, enabled: enabled),
          const SizedBox(width: 8),
          Text(title),
        ],
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
    final active = enabled ? const Color(0xFF0284C7) : const Color(0xFF9CA3AF);
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
    return FilledButton(
      onPressed: onPressed,
      style: FilledButton.styleFrom(
        backgroundColor: const Color(0xFF2F95D0),
        disabledBackgroundColor: const Color(0xFFB6C8D5),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 12),
      ),
      child: Text(label),
    );
  }
}

class _PrintTestTile extends StatelessWidget {
  const _PrintTestTile({
    required this.title,
    required this.enabled,
    required this.onTap,
  });

  final String title;
  final bool enabled;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        ListTile(
          enabled: enabled,
          title: Text(title),
          trailing: const Icon(Icons.chevron_right, color: Color(0xFF0284C7)),
          onTap: enabled ? onTap : null,
        ),
        const Divider(height: 1),
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
        color: const Color(0xFFE7F3EF),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label, style: Theme.of(context).textTheme.labelSmall),
          const SizedBox(height: 4),
          Text(
            value,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: Theme.of(
              context,
            ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w800),
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
        color: const Color(0xFF102A27),
        borderRadius: BorderRadius.circular(18),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: const TextStyle(
              color: Color(0xFFFDE68A),
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 8),
          SelectableText(
            value,
            style: const TextStyle(color: Colors.white, height: 1.35),
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
        color: Colors.white.withValues(alpha: 0.16),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        '$label  $value',
        style: const TextStyle(
          color: Colors.white,
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
      icon: Icons.terminal,
      title: '调用日志',
      subtitle: '每一步 MethodChannel/EventChannel 调用结果都会记录在这里。',
      children: [
        Align(
          alignment: Alignment.centerRight,
          child: TextButton.icon(
            onPressed: onClear,
            icon: const Icon(Icons.clear_all),
            label: const Text('清空'),
          ),
        ),
        Container(
          constraints: const BoxConstraints(minHeight: 180, maxHeight: 320),
          width: double.infinity,
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: const Color(0xFF081816),
            borderRadius: BorderRadius.circular(18),
          ),
          child: logs.isEmpty
              ? const Text('暂无日志', style: TextStyle(color: Colors.white70))
              : ListView.separated(
                  shrinkWrap: true,
                  itemCount: logs.length,
                  separatorBuilder: (_, _) => const SizedBox(height: 8),
                  itemBuilder: (context, index) => SelectableText(
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
