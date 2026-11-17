package com.m5stack.nf5503_flutter

import android.bld.PrintManager
import android.bld.print.aidl.PrinterBinderListener
import android.content.Context
import android.graphics.Bitmap
import com.example.lc_print_sdk.PrintUtil

/** 仅在检测到 NF5503 打印 SDK 后加载的厂商实现。 */
internal class AndroidPrinterApi(context: Context) : Nf5503PrinterApi {
    private val appContext = context.applicationContext
    private val printer = PrintManager.getDefaultInstance(appContext)

    // PrintUtil.getInstance() 会主动打开打印服务，仅在黑标走纸时延迟初始化。
    private val printUtil by lazy { PrintUtil.getInstance(appContext) }
    private var printListener: PrinterBinderListener? = null

    /** 获取打印机版本。 */
    override fun getVersion(): String? = printer.printerVer

    /** 打开打印机。 */
    override fun open(): Boolean = printer.open()

    /** 关闭打印机。 */
    override fun close(): Boolean = printer.close()

    /** 设置打印浓度。 */
    override fun setDensity(density: Int) = printer.setDensity(density)

    /** 获取打印浓度。 */
    override fun getDensity(): Int = printer.density

    /** 重置打印机。 */
    override fun reset(): Int = printer.reset()

    /** 设置字体类型。 */
    override fun setFontType(fontType: String) = printer.setFontType(fontType)

    /** 获取字体类型。 */
    override fun getFontType(): String? = printer.fontType

    /** 设置字体大小。 */
    override fun setFontSize(fontSize: Int) = printer.setFontSize(fontSize)

    /** 获取字体大小。 */
    override fun getFontSize(): Int = printer.fontSize

    /** 设置默认文本加粗开关。 */
    override fun setBold(enabled: Boolean) = printer.setFontBold(enabled)

    /** 查询默认文本加粗开关。 */
    override fun isBold(): Boolean = printer.isFontBold

    /** 设置黑标模式。 */
    override fun setBlackMark(enabled: Boolean) = printer.setBlackLabel(enabled)

    /** 查询黑标模式。 */
    override fun isBlackMark(): Boolean = printer.isBlackLabel

    /** 设置黑标阈值。 */
    override fun setThreshold(threshold: Int): Int = printer.setThreshold(threshold)

    /** 设置下划线开关。 */
    override fun setUnderline(enabled: Boolean) = printer.setUnderLine(enabled)

    /** 查询下划线开关。 */
    override fun isUnderline(): Boolean = printer.isUnderLine

    /** 设置走纸间距。 */
    override fun setFeedPaperSpace(space: Int) = printer.setFeedPaperSpace(space)

    /** 获取走纸间距。 */
    override fun getFeedPaperSpace(): Int = printer.feedPaperSpace

    /** 设置标签模式回退纸长度。 */
    override fun setUnwindPaperLength(length: Int) = printer.setUnwindPaperLen(length)

    /** 获取标签模式回退纸长度。 */
    override fun getUnwindPaperLength(): Int = printer.unwindPaperLen

    /** 添加文本。 */
    override fun addText(
        align: Int,
        fontSize: Int,
        bold: Boolean,
        underline: Boolean,
        content: String,
    ) = printer.addText(align, fontSize, bold, underline, content)

    /** 添加一维条码。 */
    override fun addBarcode(
        align: Int,
        height: Int,
        content: String,
        type: Int,
        hriPosition: Int,
    ) = printer.addBarcode(align, height, content, type, hriPosition)

    /** 添加二维码。 */
    override fun addQrCode(align: Int, size: Int, content: String) =
        printer.addQRCode(align, size, content)

    /** 添加位图。 */
    override fun addImage(align: Int, bitmap: Bitmap) = printer.addImage(align, bitmap)

    /** 添加图片文件。 */
    override fun addImageFile(align: Int, imagePath: String) =
        printer.addImageFile(align, imagePath)

    /** 添加空行。 */
    override fun addLineFeed(lines: Int) = printer.addLineFeed(lines)

    /** 提交打印任务。 */
    override fun start() = printer.start()

    /** 设置反色打印。 */
    override fun setReverse(enabled: Boolean) = printer.setReverse(enabled)

    /** 查询反色打印状态。 */
    override fun isReverse(): Boolean = printer.isReverse

    /** 移动到下一个黑标。 */
    override fun goToNextMark(distance: Int?) {
        if (distance == null) {
            printUtil.printGoToNextMark()
        } else {
            printUtil.printGoToNextMark(distance)
        }
    }

    /** 设置行间距。 */
    override fun setLineSpacing(spacing: Float) = printer.setLineSpacing(spacing)

    /** 获取行间距。 */
    override fun getLineSpacing(): Float = printer.lineSpacing

    /** 查询系统打印能力。 */
    override fun getSupportPrint(): Int = PrintUtil.getSupportPrint()

    /** 查询打印机状态。 */
    override fun getPrinterState(stateType: Int): Int = printer.getPrinterState(stateType)

    /** 注册打印状态监听。 */
    override fun addPrintListener(onState: (Int) -> Unit) {
        removePrintListener()
        val listener =
            object : PrinterBinderListener {
                override fun onPrintCallback(state: Int) {
                    onState(state)
                }
            }
        printListener = listener
        printer.addPrintListener(listener)
    }

    /** 移除打印状态监听。 */
    override fun removePrintListener() {
        val listener = printListener ?: return
        runCatching { printer.removePrintListener(listener) }
        printListener = null
    }
}
