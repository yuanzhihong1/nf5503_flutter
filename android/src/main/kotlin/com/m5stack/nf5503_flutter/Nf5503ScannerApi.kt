package com.m5stack.nf5503_flutter

/** 普通手机可安全加载的扫码能力接口，不暴露厂商 SDK 类型。 */
internal interface Nf5503ScannerApi {
    /** 获取扫描头类型原始 ID。 */
    fun getScannerType(): Int

    /** 获取扫码头支持的码制对象列表。 */
    fun getSymbologyList(): List<*>

    /** 初始化扫码头码制参数。 */
    fun initSymbologySettings()

    /** 查询扫码头是否与其它服务冲突。 */
    fun isScannerConflicted(): Boolean

    /** 连接底层解码器。 */
    fun connectDecoder()

    /** 断开底层解码器。 */
    fun disconnectDecoder()

    /** 查询解码器状态。 */
    fun getDecoderStatus(): Boolean

    /** 查询解码器是否已经连接。 */
    fun isDecoderConnected(): Boolean

    /** 打开扫码模块。 */
    fun openScanner(): Boolean

    /** 关闭扫码模块。 */
    fun closeScanner(): Boolean

    /** 触发一次解码。 */
    fun startDecode(): Boolean

    /** 停止当前解码。 */
    fun stopDecode(): Boolean

    /** 查询扫码模块是否打开。 */
    fun isScannerOpen(): Boolean

    /** 设置扫码结果前缀。 */
    fun setPrefix(prefix: String)

    /** 获取扫码结果前缀。 */
    fun getPrefix(): String?

    /** 设置扫码结果后缀。 */
    fun setSuffix(suffix: String)

    /** 获取扫码结果后缀。 */
    fun getSuffix(): String?

    /** 设置扫码过滤规则。 */
    fun setFilter(filter: String)

    /** 获取扫码过滤规则。 */
    fun getFilter(): String?

    /** 设置提示音开关。 */
    fun setPlaySound(enabled: Boolean)

    /** 查询提示音开关。 */
    fun getPlaySound(): Boolean

    /** 设置震动开关。 */
    fun setVibrate(enabled: Boolean)

    /** 查询震动开关。 */
    fun getVibrate(): Boolean

    /** 设置连续扫码开关。 */
    fun setContinueScan(enabled: Boolean)

    /** 查询连续扫码开关。 */
    fun getContinueScan(): Boolean

    /** 设置多码识读开关。 */
    fun setMultiDecode(enabled: Boolean)

    /** 查询多码识读开关。 */
    fun getMultiDecode(): Boolean

    /** 设置多码识读数量。 */
    fun setMultiReadNumber(number: Int)

    /** 查询多码识读数量。 */
    fun getMultiReadNumber(): Int

    /** 设置重复条码过滤开关。 */
    fun setDisableSameBarcode(disabled: Boolean)

    /** 查询重复条码过滤开关。 */
    fun getDisableSameBarcode(): Boolean

    /** 设置扫码广播 Action。 */
    fun setBroadcastAction(action: String)

    /** 获取扫码广播 Action。 */
    fun getBroadcastAction(): String?

    /** 设置扫码广播数据 Key。 */
    fun setBroadcastKey(key: String)

    /** 获取扫码广播数据 Key。 */
    fun getBroadcastKey(): String?

    /** 设置扫码输出模式。 */
    fun setOutputMode(mode: Int)

    /** 获取扫码输出模式。 */
    fun getOutputMode(): Int

    /** 设置扫码文本编码模式。 */
    fun setDecodeMode(mode: Int)

    /** 获取扫码文本编码模式。 */
    fun getDecodeMode(): Int

    /** 设置扫码结束符。 */
    fun setEndMark(mark: Int)

    /** 获取扫码结束符。 */
    fun getEndMark(): Int

    /** 设置是否由 SDK 接管扫码实体键。 */
    fun setHandleKey(enabled: Boolean)

    /** 查询是否由 SDK 接管扫码实体键。 */
    fun getHandleKey(): Boolean

    /** 设置连续扫码间隔。 */
    fun setIntervalTime(milliseconds: Int): Boolean

    /** 获取连续扫码间隔。 */
    fun getIntervalTime(): Int

    /** 设置解码超时时间。 */
    fun setDecodeTimeout(milliseconds: Int)

    /** 获取解码超时时间。 */
    fun getDecodeTimeout(): Int

    /** 设置抬枪停止解码开关。 */
    fun setLiftToStop(enabled: Boolean)

    /** 查询抬枪停止解码开关。 */
    fun getLiftToStop(): Boolean

    /** 按参数 ID 写入码制配置。 */
    fun setSymbologyValues(paramIds: IntArray, values: IntArray)

    /** 按参数 ID 读取码制配置。 */
    fun getSymbologyValues(paramIds: IntArray): IntArray?

    /** 启用或禁用全部码制。 */
    fun enableAllSymbologies(enabled: Boolean)

    /** 启用或禁用指定码制。 */
    fun enableSymbology(enabled: Boolean, symbologyId: Int)

    /** 启用或禁用全部一维码。 */
    fun enableAll1dSymbologies(enabled: Boolean)

    /** 启用或禁用全部二维码。 */
    fun enableAll2dSymbologies(enabled: Boolean)

    /** 查询指定码制是否启用。 */
    fun isSymbologyEnabled(symbologyId: Int): Boolean

    /** 查询指定码制是否受扫描头支持。 */
    fun isSymbologySupported(symbologyId: Int): Boolean

    /** 重置扫码配置。 */
    fun reset()
}
