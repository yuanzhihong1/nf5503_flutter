import 'dart:async';

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

class _MyAppState extends State<MyApp> {
  static const _defaultScanAction = 'com.m5stack.nf5503_flutter.SCAN';
  static const _defaultScanKey = 'barcode';

  final _plugin = Nf5503Flutter();
  final _scanActionController = TextEditingController(text: _defaultScanAction);
  final _scanKeyController = TextEditingController(text: _defaultScanKey);
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
    setState(() {
      _printerOpen = openResult;
      _printerVersion = version;
      _supportPrint = supportPrint;
    });
    _log(
      '打印 SDK 打开: open=$openResult, version=$version, support=$supportPrint, density=$concentration',
    );
  }

  Future<void> _printThermalSample() async {
    await _plugin.printer.open();
    await _plugin.printer.setBlackMark(false);
    await _plugin.printer.setConcentration(25);
    await _plugin.printer.setReverse(false);
    await _plugin.printer.setUnderline(false);
    await _plugin.printer.setBold(false);
    await _plugin.printer.setLineSpacing(1.1);
    await _plugin.printer.addText(
      'NF5503 Flutter SDK',
      align: Nf5503PrintAlign.center,
      fontSize: Nf5503PrintFontSize.large,
      isBold: true,
    );
    await _plugin.printer.addText(
      'Thermal print sample',
      align: Nf5503PrintAlign.center,
      fontSize: Nf5503PrintFontSize.middle,
    );
    await _plugin.printer.addText('Platform: $_platformVersion');
    await _plugin.printer.addText('Time: ${DateTime.now().toIso8601String()}');
    await _plugin.printer.addBlankLines(1);
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
    await _plugin.printer.addBlankLines(4);
    await _plugin.printer.start();
    setState(() => _printerOpen = true);
    _log('已提交热敏打印样张');
  }

  Future<void> _printLabelSample() async {
    await _plugin.printer.open();
    await _plugin.printer.setBlackMark(true);
    await _plugin.printer.setConcentration(25);
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

  Future<void> _readPrinterState() async {
    final version = await _plugin.printer.getVersion();
    final supportPrint = await _plugin.printer.getSupportPrint();
    final state = await _plugin.printer.getState(
      Nf5503PrinterStateType.checkAll,
    );
    final fontSize = await _plugin.printer.getFontSize();
    final concentration = await _plugin.printer.getConcentration();
    setState(() {
      _printerVersion = version;
      _supportPrint = supportPrint;
      _lastPrinterState = state;
    });
    _log(
      '打印状态: version=$version, support=$supportPrint, state=$state, font=${fontSize.name}, density=$concentration',
    );
  }

  Future<void> _closePrinter() async {
    final success = await _plugin.printer.close();
    setState(() => _printerOpen = false);
    _log('closePrinter 返回: $success');
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
    return _SectionCard(
      icon: Icons.print_outlined,
      title: '打印 SDK 测试',
      subtitle: '会调用官方 SDK 打开打印、读取版本、提交文本/条码/二维码样张。',
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
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [
            FilledButton.icon(
              onPressed: _busy ? null : () => _run('打开打印 SDK', _openPrinter),
              icon: const Icon(Icons.sensors),
              label: const Text('打开/监听'),
            ),
            FilledButton.tonalIcon(
              onPressed: _busy
                  ? null
                  : () => _run('热敏打印样张', _printThermalSample),
              icon: const Icon(Icons.receipt_long),
              label: const Text('热敏样张'),
            ),
            FilledButton.tonalIcon(
              onPressed: _busy ? null : () => _run('标签打印样张', _printLabelSample),
              icon: const Icon(Icons.label_outline),
              label: const Text('标签样张'),
            ),
            OutlinedButton.icon(
              onPressed: _busy ? null : () => _run('读取打印状态', _readPrinterState),
              icon: const Icon(Icons.fact_check_outlined),
              label: const Text('读状态'),
            ),
            OutlinedButton.icon(
              onPressed: _busy ? null : () => _run('关闭打印', _closePrinter),
              icon: const Icon(Icons.power_settings_new),
              label: const Text('关闭'),
            ),
          ],
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
