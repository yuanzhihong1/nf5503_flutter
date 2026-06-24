## 0.0.2

- Android 原生 MethodChannel/EventChannel 切换到后台 TaskQueue，并通过专用串行线程执行所有 ScanManager、PrintManager 和 PrintUtil 调用，避免阻塞主线程。
- 扫码广播接收改为后台 HandlerThread 处理，减少扫码结果解析对 UI 的影响。
- 打印事件和扫码事件继续安全派发到 Flutter 事件流，同时保持打印监听移除等清理动作在后台执行。

## 0.0.1

- 首个 Android 版本，封装 NF5503 设备的扫码与热敏/标签打印能力。
- 提供 `ScanManager` 相关 API：扫码开关、广播结果监听、输出模式、解码配置与码制配置。
- 提供 `PrintManager`/`PrintUtil` 相关 API：打印状态、浓度、字体、文本、条码、二维码、图片、黑标与行距操作。
- 示例应用改为纯 Cupertino 组件，便于在真机上验证插件调用链路。
