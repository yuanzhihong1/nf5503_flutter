## 0.0.3

- 修正打印浓度 API：范围与官方 SDK 对齐为 1~39，并采用 `density / 4 + 1` 的原生档位映射。
- 更新示例中的浓度滑杆和校准尺，避免传入官方范围外的 40。
- 补充打印浓度原生与 MethodChannel 测试，并完善打印扩展 API 和扫码结束符的文档说明。

## 0.0.2

- Android 原生 MethodChannel/EventChannel 切换到后台 TaskQueue，并通过专用串行线程执行所有 ScanManager、PrintManager 和 PrintUtil 调用，避免阻塞主线程。
- 扫码广播接收改为后台 HandlerThread 处理，减少扫码结果解析对 UI 的影响。
- 打印事件和扫码事件继续安全派发到 Flutter 事件流，同时保持打印监听移除等清理动作在后台执行。

## 0.0.1

- 首个 Android 版本，封装 NF5503 设备的扫码与热敏/标签打印能力。
- 提供 `ScanManager` 相关 API：扫码开关、广播结果监听、输出模式、解码配置与码制配置。
- 提供 `PrintManager`/`PrintUtil` 相关 API：打印状态、浓度、字体、文本、条码、二维码、图片、黑标与行距操作。
- 示例应用改为纯 Cupertino 组件，便于在真机上验证插件调用链路。

## 0.0.4

- 从官方 `ScanManager_V202105081630.jar` 自动生成 466 个公开常量，覆盖 ParamID、SymbologyID、SymbologyFlags、Engine、Lights、OCR、Postal、ScannerType 和 ScanConfig。
- 新增 `setParameter/getParameter`、`setLightsMode/getLightsMode` 与 `getScannerTypeId`，高级码制配置不再依赖业务方手写原生整数。
- 扫码结果新增原始字节、Code ID、条码类型、AIM ID、AIM Modifier 和长度，并保留完整广播 extras。
- 默认广播 Action/Key 对齐官方 `scan.rcv.message` / `barcodeData`。
- Android 13+ 广播接收器改为 `RECEIVER_EXPORTED`，修复无法接收厂商扫描服务广播的兼容性问题。
- 广播字节按官方编码模式解码，`getSymbologyList()` 递归展开嵌套对象并防护循环引用。
- 未知输出模式、编码模式与结束符改为显式 `unknown`，避免静默错配。
- 解码器连接/断开增加大小写历史别名回退，空数组返回值增加安全处理。
- 示例工程升级到 Gradle 9.5.0、AGP 9.3.1、Kotlin 2.4.20，并迁移到 `cupertino_ui`；补充 Dart、Kotlin 测试和 61 项扫描 API 对齐审计文档。
