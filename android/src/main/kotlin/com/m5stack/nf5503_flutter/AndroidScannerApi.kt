package com.m5stack.nf5503_flutter

import android.bld.ScanManager
import android.content.Context

/** 仅在检测到 NF5503 扫码 SDK 后加载的厂商实现。 */
internal class AndroidScannerApi(context: Context) : Nf5503ScannerApi {
    private val scanner = ScanManager.getDefaultInstance(context.applicationContext)

    /** 获取扫描头类型原始 ID。 */
    override fun getScannerType(): Int = scanner.scannerType

    /** 获取扫码头支持的码制对象列表。 */
    override fun getSymbologyList(): List<*> {
        return runCatching {
            scanner.javaClass.getMethod("getSymbologyList").invoke(scanner) as? List<*>
        }.getOrNull().orEmpty()
    }

    /** 初始化扫码头码制参数。 */
    override fun initSymbologySettings() = scanner.initSymbologySettings()

    /** 查询扫码头是否与其它服务冲突。 */
    override fun isScannerConflicted(): Boolean = scanner.isScannerConflicted

    /** 连接底层解码器，并兼容新旧 SDK 方法名。 */
    override fun connectDecoder() {
        try {
            scanner.decoderConnect()
        } catch (_: NoSuchMethodError) {
            scanner.DecoderConnect()
        }
    }

    /** 断开底层解码器，并兼容新旧 SDK 方法名。 */
    override fun disconnectDecoder() {
        try {
            scanner.decoderDisconnect()
        } catch (_: NoSuchMethodError) {
            scanner.DecoderDisconnect()
        }
    }

    /** 查询解码器状态。 */
    override fun getDecoderStatus(): Boolean = scanner.decoderStatus

    /** 查询解码器是否已经连接。 */
    override fun isDecoderConnected(): Boolean = scanner.isDecoderConnected

    /** 打开扫码模块。 */
    override fun openScanner(): Boolean = scanner.openScanner()

    /** 关闭扫码模块。 */
    override fun closeScanner(): Boolean = scanner.closeScanner()

    /** 触发一次解码。 */
    override fun startDecode(): Boolean = scanner.startDecode()

    /** 停止当前解码。 */
    override fun stopDecode(): Boolean = scanner.stopDecode()

    /** 查询扫码模块是否打开。 */
    override fun isScannerOpen(): Boolean = scanner.isScannerOpen

    /** 设置扫码结果前缀。 */
    override fun setPrefix(prefix: String) = scanner.setPrefix(prefix)

    /** 获取扫码结果前缀。 */
    override fun getPrefix(): String? = scanner.prefix

    /** 设置扫码结果后缀。 */
    override fun setSuffix(suffix: String) = scanner.setSuffix(suffix)

    /** 获取扫码结果后缀。 */
    override fun getSuffix(): String? = scanner.suffix

    /** 设置扫码过滤规则。 */
    override fun setFilter(filter: String) = scanner.setFilter(filter)

    /** 获取扫码过滤规则。 */
    override fun getFilter(): String? = scanner.filter

    /** 设置提示音开关。 */
    override fun setPlaySound(enabled: Boolean) = scanner.setPlaySound(enabled)

    /** 查询提示音开关。 */
    override fun getPlaySound(): Boolean = scanner.playSound

    /** 设置震动开关。 */
    override fun setVibrate(enabled: Boolean) = scanner.setVibrate(enabled)

    /** 查询震动开关。 */
    override fun getVibrate(): Boolean = scanner.vibrate

    /** 设置连续扫码开关。 */
    override fun setContinueScan(enabled: Boolean) = scanner.setContinueScan(enabled)

    /** 查询连续扫码开关。 */
    override fun getContinueScan(): Boolean = scanner.continueScan

    /** 设置多码识读开关。 */
    override fun setMultiDecode(enabled: Boolean) = scanner.setMultiDecode(enabled)

    /** 查询多码识读开关。 */
    override fun getMultiDecode(): Boolean = scanner.multiDecode

    /** 设置多码识读数量。 */
    override fun setMultiReadNumber(number: Int) = scanner.setMultiReadNumber(number)

    /** 查询多码识读数量。 */
    override fun getMultiReadNumber(): Int = scanner.multiReadNumber

    /** 设置重复条码过滤开关。 */
    override fun setDisableSameBarcode(disabled: Boolean) =
        scanner.setDisableSameBarcode(disabled)

    /** 查询重复条码过滤开关。 */
    override fun getDisableSameBarcode(): Boolean = scanner.disableSameBarcode

    /** 设置扫码广播 Action。 */
    override fun setBroadcastAction(action: String) = scanner.setBroadcastAction(action)

    /** 获取扫码广播 Action。 */
    override fun getBroadcastAction(): String? = scanner.broadcastAction

    /** 设置扫码广播数据 Key。 */
    override fun setBroadcastKey(key: String) = scanner.setBroadcastKey(key)

    /** 获取扫码广播数据 Key。 */
    override fun getBroadcastKey(): String? = scanner.broadcastKey

    /** 设置扫码输出模式。 */
    override fun setOutputMode(mode: Int) = scanner.setOPMode(mode)

    /** 获取扫码输出模式。 */
    override fun getOutputMode(): Int = scanner.opMode

    /** 设置扫码文本编码模式。 */
    override fun setDecodeMode(mode: Int) = scanner.setDecodeMode(mode)

    /** 获取扫码文本编码模式。 */
    override fun getDecodeMode(): Int = scanner.decodeMode

    /** 设置扫码结束符。 */
    override fun setEndMark(mark: Int) = scanner.setEndMark(mark)

    /** 获取扫码结束符。 */
    override fun getEndMark(): Int = scanner.endMark

    /** 设置是否由 SDK 接管扫码实体键。 */
    override fun setHandleKey(enabled: Boolean) = scanner.setHandleKey(enabled)

    /** 查询是否由 SDK 接管扫码实体键。 */
    override fun getHandleKey(): Boolean = scanner.handleKey

    /** 设置连续扫码间隔。 */
    override fun setIntervalTime(milliseconds: Int): Boolean =
        scanner.setIntervalTime(milliseconds)

    /** 获取连续扫码间隔。 */
    override fun getIntervalTime(): Int = scanner.intervalTime

    /** 设置解码超时时间。 */
    override fun setDecodeTimeout(milliseconds: Int) =
        scanner.setDecodeTimeout(milliseconds)

    /** 获取解码超时时间。 */
    override fun getDecodeTimeout(): Int = scanner.decodeTimeout

    /** 设置抬枪停止解码开关。 */
    override fun setLiftToStop(enabled: Boolean) = scanner.setLiftToStop(enabled)

    /** 查询抬枪停止解码开关。 */
    override fun getLiftToStop(): Boolean = scanner.liftToStop

    /** 按参数 ID 写入码制配置。 */
    override fun setSymbologyValues(paramIds: IntArray, values: IntArray) =
        scanner.setSYMValueInts(paramIds, values)

    /** 按参数 ID 读取码制配置。 */
    override fun getSymbologyValues(paramIds: IntArray): IntArray? =
        scanner.getSYMValueInts(paramIds)

    /** 启用或禁用全部码制。 */
    override fun enableAllSymbologies(enabled: Boolean) = scanner.enableAllSYM(enabled)

    /** 启用或禁用指定码制。 */
    override fun enableSymbology(enabled: Boolean, symbologyId: Int) =
        scanner.enableSYM(enabled, symbologyId)

    /** 启用或禁用全部一维码。 */
    override fun enableAll1dSymbologies(enabled: Boolean) = scanner.enableSYM1D(enabled)

    /** 启用或禁用全部二维码。 */
    override fun enableAll2dSymbologies(enabled: Boolean) = scanner.enableSYM2D(enabled)

    /** 查询指定码制是否启用。 */
    override fun isSymbologyEnabled(symbologyId: Int): Boolean =
        scanner.isSYMEnabled(symbologyId)

    /** 查询指定码制是否受扫描头支持。 */
    override fun isSymbologySupported(symbologyId: Int): Boolean =
        scanner.isSYMSupported(symbologyId)

    /** 重置扫码配置。 */
    override fun reset() = scanner.resetScan()
}
