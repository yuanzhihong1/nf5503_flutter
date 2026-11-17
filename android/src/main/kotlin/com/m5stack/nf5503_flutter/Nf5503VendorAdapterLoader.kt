package com.m5stack.nf5503_flutter

import android.content.Context
import java.lang.reflect.InvocationTargetException

/** 延迟加载厂商 SDK 适配器，避免普通 Android 设备在插件注册阶段崩溃。 */
internal object Nf5503VendorAdapterLoader {
    private const val SCAN_MANAGER_CLASS = "android.bld.ScanManager"
    private const val PRINT_MANAGER_CLASS = "android.bld.PrintManager"
    private const val PRINTER_LISTENER_CLASS = "android.bld.print.aidl.PrinterBinderListener"
    private const val SCANNER_ADAPTER_CLASS =
        "com.m5stack.nf5503_flutter.AndroidScannerApi"
    private const val PRINTER_ADAPTER_CLASS =
        "com.m5stack.nf5503_flutter.AndroidPrinterApi"

    /** 创建扫码适配器；未安装厂商 SDK 时返回 null。 */
    fun createScanner(context: Context): Nf5503ScannerApi? {
        if (!isClassAvailable(SCAN_MANAGER_CLASS)) {
            return null
        }
        return instantiateAdapter(SCANNER_ADAPTER_CLASS, context)
    }

    /** 创建打印适配器；未安装厂商 SDK 时返回 null。 */
    fun createPrinter(context: Context): Nf5503PrinterApi? {
        if (!isClassAvailable(PRINT_MANAGER_CLASS) ||
            !isClassAvailable(PRINTER_LISTENER_CLASS)
        ) {
            return null
        }
        return instantiateAdapter(PRINTER_ADAPTER_CLASS, context)
    }

    /** 判断指定厂商类是否可由当前进程加载。 */
    fun isClassAvailable(className: String): Boolean {
        return runCatching { Class.forName(className, false, javaClass.classLoader) }.isSuccess
    }

    /** 通过类名反射创建适配器，并还原构造异常。 */
    private inline fun <reified T> instantiateAdapter(
        className: String,
        context: Context,
    ): T? {
        return try {
            val adapterClass = Class.forName(className)
            val constructor = adapterClass.getDeclaredConstructor(Context::class.java)
            constructor.isAccessible = true
            constructor.newInstance(context) as? T
        } catch (error: InvocationTargetException) {
            throw Nf5503VendorLoadException(
                error.targetException.message ?: "厂商 SDK 适配器初始化失败",
                error.targetException,
            )
        } catch (error: Throwable) {
            throw Nf5503VendorLoadException(
                error.message ?: "厂商 SDK 适配器初始化失败",
                error,
            )
        }
    }
}

/** 厂商 SDK 存在但初始化失败时使用的明确异常。 */
internal class Nf5503VendorLoadException(
    message: String,
    cause: Throwable,
) : IllegalStateException(message, cause)

/** 当前设备不支持指定厂商能力时使用的异常。 */
internal class Nf5503UnavailableException(component: String) :
    IllegalStateException("当前设备未安装 NF5503 $component 服务")
