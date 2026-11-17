package com.m5stack.nf5503_flutter

import android.graphics.Bitmap

/** 普通手机可安全加载的打印能力接口，不暴露厂商 SDK 类型。 */
internal interface Nf5503PrinterApi {
    /** 获取打印机版本。 */
    fun getVersion(): String?

    /** 打开打印机。 */
    fun open(): Boolean

    /** 关闭打印机。 */
    fun close(): Boolean

    /** 设置打印浓度。 */
    fun setDensity(density: Int)

    /** 获取打印浓度。 */
    fun getDensity(): Int

    /** 重置打印机。 */
    fun reset(): Int

    /** 设置字体类型。 */
    fun setFontType(fontType: String)

    /** 获取字体类型。 */
    fun getFontType(): String?

    /** 设置字体大小。 */
    fun setFontSize(fontSize: Int)

    /** 获取字体大小。 */
    fun getFontSize(): Int

    /** 设置默认文本加粗开关。 */
    fun setBold(enabled: Boolean)

    /** 查询默认文本加粗开关。 */
    fun isBold(): Boolean

    /** 设置黑标模式。 */
    fun setBlackMark(enabled: Boolean)

    /** 查询黑标模式。 */
    fun isBlackMark(): Boolean

    /** 设置黑标阈值。 */
    fun setThreshold(threshold: Int): Int

    /** 设置下划线开关。 */
    fun setUnderline(enabled: Boolean)

    /** 查询下划线开关。 */
    fun isUnderline(): Boolean

    /** 设置走纸间距。 */
    fun setFeedPaperSpace(space: Int)

    /** 获取走纸间距。 */
    fun getFeedPaperSpace(): Int

    /** 设置标签模式回退纸长度。 */
    fun setUnwindPaperLength(length: Int)

    /** 获取标签模式回退纸长度。 */
    fun getUnwindPaperLength(): Int

    /** 添加文本。 */
    fun addText(align: Int, fontSize: Int, bold: Boolean, underline: Boolean, content: String)

    /** 添加一维条码。 */
    fun addBarcode(align: Int, height: Int, content: String, type: Int, hriPosition: Int)

    /** 添加二维码。 */
    fun addQrCode(align: Int, size: Int, content: String)

    /** 添加位图。 */
    fun addImage(align: Int, bitmap: Bitmap)

    /** 添加图片文件。 */
    fun addImageFile(align: Int, imagePath: String)

    /** 添加空行。 */
    fun addLineFeed(lines: Int)

    /** 提交打印任务。 */
    fun start()

    /** 设置反色打印。 */
    fun setReverse(enabled: Boolean)

    /** 查询反色打印状态。 */
    fun isReverse(): Boolean

    /** 移动到下一个黑标。 */
    fun goToNextMark(distance: Int?)

    /** 设置行间距。 */
    fun setLineSpacing(spacing: Float)

    /** 获取行间距。 */
    fun getLineSpacing(): Float

    /** 查询系统打印能力。 */
    fun getSupportPrint(): Int

    /** 查询打印机状态。 */
    fun getPrinterState(stateType: Int): Int

    /** 注册打印状态监听。 */
    fun addPrintListener(onState: (Int) -> Unit)

    /** 移除打印状态监听。 */
    fun removePrintListener()
}
