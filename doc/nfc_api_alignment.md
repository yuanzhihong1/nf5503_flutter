# NF5503 NFC API 对齐审计

## 审计基线

- 中文文档：`6、NFC/Document/NFC开发指南.pdf` V1.0
- 英文文档：`6、NFC/Document/NFC-Development-Guide.pdf` V1.0
- 官方 Demo：`6、NFC/NFCDemo/NFC`
- 重点参考：
  - `NFCActivity.java`
  - `MifareClassicCard.java`
  - `util/NfcUtils.java`
  - `util/UriRecord.java`
  - `util/Converter.java`
  - `AndroidManifest.xml`

文档仅描述 Android NFC 权限、Intent 机制和调用入口，具体能力以 Demo 代码为准。

## 实现策略

官方 Demo 使用 Manifest Intent Filter 和前台 Dispatch。Flutter 插件改为 Android 原生 `NfcAdapter.enableReaderMode`：

- 不要求宿主 Activity 使用 `singleTop`。
- 不污染宿主的 Manifest Intent Filter。
- Flutter EventChannel 订阅时自动启动，取消订阅时自动停止。
- 通过 ActivityAware 和 ActivityLifecycleCallbacks 在前后台切换时正确启停。
- 支持 NFC-A、NFC-B、NFC-F、NFC-V 和 NFC Barcode。

插件 Manifest 自动合并：

```xml
<uses-permission android:name="android.permission.NFC" />
<uses-feature android:name="android.hardware.nfc" android:required="false" />
```

## Demo 能力覆盖

| Demo 能力 | Flutter API |
| --- | --- |
| `NfcUtils.hasNfc()` / `NfcAdapter.isEnabled()` | `isSupported()`、`isEnabled()`、`getStatus()` |
| `checkNfc()` 跳转 NFC 设置 | `openSettings()` |
| `enableForegroundDispatch()` / `disableForegroundDispatch()` | `events()`、`startDiscovery()`、`stopDiscovery()` |
| `onNewIntent()` 标签 UID | `Nf5503NfcEvent.tag` / `Nf5503NfcTagInfo.idHex` |
| UID 翻转十六进制并转十进制 | `Nf5503NfcTagInfo.reversedDecimalId` |
| 技术列表 `tag.getTechList()` | `Nf5503NfcTagInfo.techList` |
| 读取 NDEF 消息 | `readNdef()`、`Nf5503NdefInfo.cachedMessage`、`Nf5503NdefMessage` |
| URI Record 解析 | `Nf5503NdefRecord.uri`、`Nf5503NdefMessage.firstText` |
| Text Record 解析 | `Nf5503NdefRecord.text/languageCode`，支持 UTF-8/UTF-16 |
| MIME Record | `Nf5503NdefRecord.mimeType/payload` |
| Smart Poster | 提取嵌套 URI/Text，同时保留原始记录 |
| `writeTag()` 写 URI | `writeNdefUri()` |
| 写普通 NDEF 内容 | `writeNdefText()`、`writeNdefMime()`、`writeNdefMessage()` |
| `NdefFormatable.format()` | `writeNdefMessage(formatIfNeeded: true)` |
| `MifareClassic.get(tag)` | `getMifareClassicInfo()`、`connectMifare()` |
| `connect()` / `colse()` | `connectMifare()` / `closeMifare()` |
| `authenticateSectorWithKeyA/B()` | `authenticateMifareSector(keyType:)` |
| `readBlock()` / `writeBlock()` | `readMifareBlock()` / `writeMifareBlock()` |
| `transceive()` | `transceiveMifare()` |
| `increment()` / `decrement()` | `incrementMifareBlock()` / `decrementMifareBlock()` |
| `restore()` / `transfer()` | `restoreMifareBlock()` / `transferMifareBlock()` |
| `blockToSector()` / `sectorToBlock()` | `mifareBlockToSector()` / `mifareSectorToBlock()` |
| `getBlockCount()` | `mifareBlockCount()`、`Nf5503MifareClassicInfo.blockCount` |
| `getBlockCountInSector()` | `mifareBlockCountInSector()` |
| `getSectorCount()` | `mifareSectorCount()`、`Nf5503MifareClassicInfo.sectorCount` |
| `getSize()` | `mifareSize()`、`Nf5503MifareClassicInfo.size` |
| `getType()` | `mifareType()`、`Nf5503MifareClassicInfo.type` |
| `getMaxTransceiveLength()` | `mifareMaxTransceiveLength()` |
| `readCarCode()` | `readMifareBlockWithKey()` |
| `wirteCarCode()` 自动补零到 16 字节 | `writeMifareBlockWithKey()` |
| `modifyPassword()` 修改扇区 Key | `changeMifareSectorKey()`，支持 Key A/B 并保留访问位 |
| `Converter.ByteArrayToHexString()` | `idHex`、读取块返回的 `Uint8List` |
| `KEY_DEFAULT` / `KEY_NFC_FORUM` | `Nf5503MifareClassicConstants` |

## 修正 Demo 中的问题

- Demo 的 `getSectorCount()` 错误返回 `getMaxTransceiveLength()`；插件直接返回 Android 正确值。
- Demo 写块在鉴权失败后仍可能继续写；插件以 `PlatformException` 中止。
- Demo 修改 Key 只处理 Key A；插件支持 Key A/B，并保留访问位和另一把 Key。
- Demo 依赖 Activity `singleTop` 和 Manifest 过滤；插件改用 Reader Mode，不要求宿主改启动模式。
- 原始字节全程保留为 `Uint8List`，不经过有损字符串转换。

## 使用限制

- Reader Mode 仅在包含 Flutter 页面的 Activity 处于前台时工作。
- 写入、格式化和只读锁定会永久修改标签，业务界面应自行二次确认。
- Android Reader Mode 不提供稳定的公开标签离开回调；`tagLost` 在发现新标签、停止发现或 Reader Mode 关闭时进行尽力通知。
