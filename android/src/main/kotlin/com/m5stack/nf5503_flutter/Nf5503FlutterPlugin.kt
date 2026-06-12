package com.m5stack.nf5503_flutter

import android.bld.PrintManager
import android.bld.ScanManager
import android.bld.print.aidl.PrinterBinderListener
import android.content.BroadcastReceiver
import android.content.Context
import android.content.Intent
import android.content.IntentFilter
import android.graphics.BitmapFactory
import android.os.Build
import android.os.Handler
import android.os.Looper
import com.example.lc_print_sdk.PrintUtil
import io.flutter.embedding.engine.plugins.FlutterPlugin
import io.flutter.plugin.common.EventChannel
import io.flutter.plugin.common.MethodCall
import io.flutter.plugin.common.MethodChannel
import java.lang.reflect.Modifier
import kotlin.math.ceil

/** Flutter plugin bridge for the NF5503 scanner and printer SDKs. */
class Nf5503FlutterPlugin :
    FlutterPlugin,
    MethodChannel.MethodCallHandler {
    private lateinit var appContext: Context
    private lateinit var methodChannel: MethodChannel
    private lateinit var scannerEventChannel: EventChannel
    private lateinit var printerEventChannel: EventChannel

    private val mainHandler = Handler(Looper.getMainLooper())
    private var scanner: ScanManager? = null
    private var printer: PrintManager? = null
    private var printUtil: PrintUtil? = null
    private var scannerEvents: EventChannel.EventSink? = null
    private var printerEvents: EventChannel.EventSink? = null
    private var scanReceiver: BroadcastReceiver? = null
    private var scanAction: String? = null
    private var scanKey: String? = null

    private val printListener =
        object : PrinterBinderListener {
            override fun onPrintCallback(state: Int) {
                postPrinterEvent(
                    mapOf(
                        "type" to "state",
                        "state" to state,
                    ),
                )
            }
        }

    override fun onAttachedToEngine(flutterPluginBinding: FlutterPlugin.FlutterPluginBinding) {
        appContext = flutterPluginBinding.applicationContext
        methodChannel = MethodChannel(flutterPluginBinding.binaryMessenger, "nf5503_flutter")
        scannerEventChannel = EventChannel(flutterPluginBinding.binaryMessenger, "nf5503_flutter/scanner")
        printerEventChannel = EventChannel(flutterPluginBinding.binaryMessenger, "nf5503_flutter/printer")

        methodChannel.setMethodCallHandler(this)
        scannerEventChannel.setStreamHandler(scannerStreamHandler)
        printerEventChannel.setStreamHandler(printerStreamHandler)
    }

    override fun onMethodCall(
        call: MethodCall,
        result: MethodChannel.Result,
    ) {
        try {
            when (call.method) {
                "getPlatformVersion" -> result.success("Android ${Build.VERSION.RELEASE}")

                "scanner.open" -> result.success(ensureScanner().openScanner())
                "scanner.close" -> result.success(ensureScanner().closeScanner())
                "scanner.startDecode" -> result.success(ensureScanner().startDecode())
                "scanner.stopDecode" -> result.success(ensureScanner().stopDecode())
                "scanner.isOpen" -> result.success(ensureScanner().isScannerOpen())
                "scanner.getSymbologyList" -> {
                    result.success(getSymbologyListByReflection())
                }
                "scanner.initSymbologySettings" -> {
                    ensureScanner().initSymbologySettings()
                    result.success(null)
                }
                "scanner.getScannerType" -> result.success(ensureScanner().getScannerType())
                "scanner.isConflicted" -> result.success(ensureScanner().isScannerConflicted())
                "scanner.connectDecoder" -> {
                    ensureScanner().decoderConnect()
                    result.success(null)
                }
                "scanner.disconnectDecoder" -> {
                    ensureScanner().decoderDisconnect()
                    result.success(null)
                }
                "scanner.getDecoderStatus" -> result.success(ensureScanner().getDecoderStatus())
                "scanner.isDecoderConnected" -> result.success(ensureScanner().isDecoderConnected())
                "scanner.setPrefix" -> {
                    ensureScanner().setPrefix(call.stringArg("prefix"))
                    result.success(null)
                }
                "scanner.getPrefix" -> result.success(ensureScanner().prefix.orEmpty())
                "scanner.setSuffix" -> {
                    ensureScanner().setSuffix(call.stringArg("suffix"))
                    result.success(null)
                }
                "scanner.getSuffix" -> result.success(ensureScanner().suffix.orEmpty())
                "scanner.setFilter" -> {
                    ensureScanner().setFilter(call.stringArg("filter"))
                    result.success(null)
                }
                "scanner.getFilter" -> result.success(ensureScanner().filter.orEmpty())
                "scanner.setPlaySound" -> {
                    ensureScanner().setPlaySound(call.boolArg("enabled"))
                    result.success(null)
                }
                "scanner.getPlaySound" -> result.success(ensureScanner().playSound)
                "scanner.setVibrate" -> {
                    ensureScanner().setVibrate(call.boolArg("enabled"))
                    result.success(null)
                }
                "scanner.getVibrate" -> result.success(ensureScanner().vibrate)
                "scanner.setContinueScan" -> {
                    ensureScanner().setContinueScan(call.boolArg("enabled"))
                    result.success(null)
                }
                "scanner.getContinueScan" -> result.success(ensureScanner().continueScan)
                "scanner.setMultiDecode" -> {
                    ensureScanner().setMultiDecode(call.boolArg("enabled"))
                    result.success(null)
                }
                "scanner.getMultiDecode" -> result.success(ensureScanner().multiDecode)
                "scanner.setMultiReadNumber" -> {
                    ensureScanner().setMultiReadNumber(call.intArg("number"))
                    result.success(null)
                }
                "scanner.getMultiReadNumber" -> result.success(ensureScanner().multiReadNumber)
                "scanner.setDisableSameBarcode" -> {
                    ensureScanner().setDisableSameBarcode(call.boolArg("disabled"))
                    result.success(null)
                }
                "scanner.getDisableSameBarcode" -> result.success(ensureScanner().disableSameBarcode)
                "scanner.setBroadcastAction" -> {
                    ensureScanner().setBroadcastAction(call.stringArg("action"))
                    result.success(null)
                }
                "scanner.getBroadcastAction" -> result.success(ensureScanner().broadcastAction.orEmpty())
                "scanner.setBroadcastKey" -> {
                    ensureScanner().setBroadcastKey(call.stringArg("key"))
                    result.success(null)
                }
                "scanner.getBroadcastKey" -> result.success(ensureScanner().broadcastKey.orEmpty())
                "scanner.setOutputMode" -> {
                    ensureScanner().setOPMode(call.intArg("mode"))
                    result.success(null)
                }
                "scanner.getOutputMode" -> result.success(ensureScanner().opMode)
                "scanner.setDecodeMode" -> {
                    ensureScanner().setDecodeMode(call.intArg("mode"))
                    result.success(null)
                }
                "scanner.getDecodeMode" -> result.success(ensureScanner().decodeMode)
                "scanner.setEndMark" -> {
                    ensureScanner().setEndMark(call.intArg("mark"))
                    result.success(null)
                }
                "scanner.getEndMark" -> result.success(ensureScanner().endMark)
                "scanner.setHandleKey" -> {
                    ensureScanner().setHandleKey(call.boolArg("enabled"))
                    result.success(null)
                }
                "scanner.getHandleKey" -> result.success(ensureScanner().handleKey)
                "scanner.setIntervalTime" -> {
                    result.success(ensureScanner().setIntervalTime(call.intArg("milliseconds")))
                }
                "scanner.getIntervalTime" -> result.success(ensureScanner().intervalTime)
                "scanner.setDecodeTimeout" -> {
                    ensureScanner().setDecodeTimeout(call.intArg("milliseconds"))
                    result.success(null)
                }
                "scanner.getDecodeTimeout" -> result.success(ensureScanner().decodeTimeout)
                "scanner.setLiftToStop" -> {
                    ensureScanner().setLiftToStop(call.boolArg("enabled"))
                    result.success(null)
                }
                "scanner.getLiftToStop" -> result.success(ensureScanner().liftToStop)
                "scanner.setSymbologyValues" -> {
                    ensureScanner().setSYMValueInts(
                        call.intListArg("paramIds").toIntArray(),
                        call.intListArg("values").toIntArray(),
                    )
                    result.success(null)
                }
                "scanner.getSymbologyValues" -> {
                    result.success(
                        ensureScanner()
                            .getSYMValueInts(call.intListArg("paramIds").toIntArray())
                            .toList(),
                    )
                }
                "scanner.enableAllSymbologies" -> {
                    ensureScanner().enableAllSYM(call.boolArg("enabled"))
                    result.success(null)
                }
                "scanner.enableSymbology" -> {
                    ensureScanner().enableSYM(
                        call.boolArg("enabled"),
                        call.intArg("symbologyId"),
                    )
                    result.success(null)
                }
                "scanner.enableAll1dSymbologies" -> {
                    ensureScanner().enableSYM1D(call.boolArg("enabled"))
                    result.success(null)
                }
                "scanner.enableAll2dSymbologies" -> {
                    ensureScanner().enableSYM2D(call.boolArg("enabled"))
                    result.success(null)
                }
                "scanner.isSymbologyEnabled" -> {
                    result.success(ensureScanner().isSYMEnabled(call.intArg("symbologyId")))
                }
                "scanner.isSymbologySupported" -> {
                    result.success(ensureScanner().isSYMSupported(call.intArg("symbologyId")))
                }
                "scanner.reset" -> {
                    ensureScanner().resetScan()
                    result.success(null)
                }

                "printer.getVersion" -> result.success(ensurePrinter().printerVer.orEmpty())
                "printer.open" -> result.success(ensurePrinter().open())
                "printer.close" -> result.success(ensurePrinter().close())
                "printer.setConcentration" -> {
                    ensurePrinter().setDensity(densityToNative(call.intArg("density")))
                    result.success(null)
                }
                "printer.getConcentration" -> result.success(ensurePrinter().density * 4)
                "printer.reset" -> result.success(ensurePrinter().reset())
                "printer.setFontType" -> {
                    ensurePrinter().setFontType(call.stringArg("fontType"))
                    result.success(null)
                }
                "printer.getFontType" -> result.success(ensurePrinter().fontType.orEmpty())
                "printer.setFontSize" -> {
                    ensurePrinter().setFontSize(call.intArg("fontSize"))
                    result.success(null)
                }
                "printer.getFontSize" -> result.success(ensurePrinter().fontSize)
                "printer.setBold" -> {
                    ensurePrinter().setFontBold(call.boolArg("enabled"))
                    result.success(null)
                }
                "printer.isBold" -> result.success(ensurePrinter().isFontBold)
                "printer.setBlackMark" -> {
                    ensurePrinter().setBlackLabel(call.boolArg("enabled"))
                    result.success(null)
                }
                "printer.isBlackMark" -> result.success(ensurePrinter().isBlackLabel)
                "printer.setThreshold" -> result.success(ensurePrinter().setThreshold(call.intArg("threshold")))
                "printer.setUnderline" -> {
                    ensurePrinter().setUnderLine(call.boolArg("enabled"))
                    result.success(null)
                }
                "printer.isUnderline" -> result.success(ensurePrinter().isUnderLine)
                "printer.setFeedPaperSpace" -> {
                    ensurePrinter().setFeedPaperSpace(call.intArg("space"))
                    result.success(null)
                }
                "printer.getFeedPaperSpace" -> result.success(ensurePrinter().feedPaperSpace)
                "printer.setUnwindPaperLength" -> {
                    ensurePrinter().setUnwindPaperLen(call.intArg("length"))
                    result.success(null)
                }
                "printer.getUnwindPaperLength" -> result.success(ensurePrinter().unwindPaperLen)
                "printer.addText" -> {
                    ensurePrinter().addText(
                        call.intArg("align"),
                        call.intArg("fontSize"),
                        call.boolArg("isBold"),
                        call.boolArg("isUnderline"),
                        call.stringArg("content"),
                    )
                    result.success(null)
                }
                "printer.addBarcode" -> {
                    ensurePrinter().addBarcode(
                        call.intArg("align"),
                        call.intArg("height"),
                        call.stringArg("content"),
                        call.intArg("type"),
                        call.intArg("hriPosition"),
                    )
                    result.success(null)
                }
                "printer.addQrCode" -> {
                    ensurePrinter().addQRCode(
                        call.intArg("align"),
                        call.intArg("size"),
                        call.stringArg("content"),
                    )
                    result.success(null)
                }
                "printer.addImageBytes" -> {
                    val imageBytes = call.argument<ByteArray>("imageBytes")
                        ?: throw IllegalArgumentException("imageBytes is required")
                    val bitmap = BitmapFactory.decodeByteArray(imageBytes, 0, imageBytes.size)
                        ?: throw IllegalArgumentException("imageBytes could not be decoded")
                    ensurePrinter().addImage(call.intArg("align"), bitmap)
                    result.success(null)
                }
                "printer.addImagePath" -> {
                    ensurePrinter().addImageFile(call.intArg("align"), call.stringArg("imagePath"))
                    result.success(null)
                }
                "printer.addBlankLines" -> {
                    ensurePrinter().addLineFeed(call.intArg("lines"))
                    result.success(null)
                }
                "printer.start" -> {
                    ensurePrinter().start()
                    result.success(null)
                }
                "printer.setReverse" -> {
                    ensurePrinter().setReverse(call.boolArg("enabled"))
                    result.success(null)
                }
                "printer.isReverse" -> result.success(ensurePrinter().isReverse)
                "printer.goToNextMark" -> {
                    val distance = call.optionalIntArg("distance")
                    if (distance == null) {
                        ensurePrintUtil().printGoToNextMark()
                    } else {
                        ensurePrintUtil().printGoToNextMark(distance)
                    }
                    result.success(null)
                }
                "printer.setLineSpacing" -> {
                    ensurePrinter().setLineSpacing(call.doubleArg("spacing").toFloat())
                    result.success(null)
                }
                "printer.getLineSpacing" -> result.success(ensurePrinter().lineSpacing.toDouble())
                "printer.getSupportPrint" -> result.success(PrintUtil.getSupportPrint())
                "printer.getState" -> result.success(ensurePrinter().getPrinterState(call.intArg("stateType")))
                else -> result.notImplemented()
            }
        } catch (error: Throwable) {
            result.error("NF5503_ERROR", error.message, null)
        }
    }

    override fun onDetachedFromEngine(binding: FlutterPlugin.FlutterPluginBinding) {
        unregisterScanReceiver()
        removePrintListener()
        methodChannel.setMethodCallHandler(null)
        scannerEventChannel.setStreamHandler(null)
        printerEventChannel.setStreamHandler(null)
    }

    private fun ensureScanner(): ScanManager {
        return scanner ?: ScanManager.getDefaultInstance(appContext).also { scanner = it }
    }

    private fun ensurePrinter(): PrintManager {
        return printer ?: PrintManager.getDefaultInstance(appContext).also { printer = it }
    }

    private fun ensurePrintUtil(): PrintUtil {
        return printUtil ?: PrintUtil.getInstance(appContext).also { printUtil = it }
    }

    private fun densityToNative(density: Int): Int {
        return ceil(density / 4.0).toInt()
    }

    private fun getSymbologyListByReflection(): List<Map<String, Any?>> {
        val scanner = ensureScanner()
        val values = scanner.javaClass
            .getMethod("getSymbologyList")
            .invoke(scanner) as? Iterable<*> ?: return emptyList()
        return values.map { valueToMap(it) }
    }

    private fun valueToMap(value: Any?): Map<String, Any?> {
        if (value == null) {
            return mapOf("value" to null)
        }
        if (value is Boolean || value is Number || value is String) {
            return mapOf("value" to codecValue(value))
        }

        val result = linkedMapOf<String, Any?>(
            "className" to value.javaClass.name,
            "label" to value.toString(),
        )
        value.javaClass.fields
            .filter { Modifier.isPublic(it.modifiers) }
            .forEach { field ->
                runCatching { result[field.name] = codecValue(field.get(value)) }
            }
        value.javaClass.methods
            .filter {
                Modifier.isPublic(it.modifiers) &&
                    it.parameterTypes.isEmpty() &&
                    it.name != "getClass"
            }
            .forEach { method ->
                val name = propertyName(method.name) ?: return@forEach
                runCatching { result[name] = codecValue(method.invoke(value)) }
            }
        return result
    }

    private fun propertyName(methodName: String): String? {
        val rawName =
            when {
                methodName.startsWith("get") && methodName.length > 3 -> methodName.substring(3)
                methodName.startsWith("is") && methodName.length > 2 -> methodName.substring(2)
                else -> return null
            }
        return rawName.replaceFirstChar { it.lowercaseChar() }
    }

    private fun codecValue(value: Any?): Any? {
        return when (value) {
            null, is Boolean, is Int, is Long, is Double, is String -> value
            is Float -> value.toDouble()
            is Number -> value.toDouble()
            else -> value.toString()
        }
    }

    private val scannerStreamHandler =
        object : EventChannel.StreamHandler {
            override fun onListen(arguments: Any?, events: EventChannel.EventSink) {
                scannerEvents = events
                val args = arguments as? Map<*, *>
                scanAction =
                    args?.get("action")?.toString()?.takeIf { it.isNotBlank() }
                        ?: ensureScanner().broadcastAction?.takeIf { it.isNotBlank() }
                scanKey =
                    args?.get("key")?.toString()?.takeIf { it.isNotBlank() }
                        ?: ensureScanner().broadcastKey?.takeIf { it.isNotBlank() }

                val action = scanAction
                if (action == null) {
                    events.error(
                        "NF5503_SCAN_BROADCAST",
                        "Scanner broadcast action is empty.",
                        null,
                    )
                    return
                }
                registerScanReceiver(action)
            }

            override fun onCancel(arguments: Any?) {
                unregisterScanReceiver()
                scannerEvents = null
            }
        }

    private val printerStreamHandler =
        object : EventChannel.StreamHandler {
            override fun onListen(arguments: Any?, events: EventChannel.EventSink) {
                printerEvents = events
                ensurePrinter().addPrintListener(printListener)
                postPrinterEvent(
                    mapOf(
                        "type" to "version",
                        "version" to ensurePrinter().printerVer.orEmpty(),
                    ),
                )
            }

            override fun onCancel(arguments: Any?) {
                removePrintListener()
                printerEvents = null
            }
        }

    private fun registerScanReceiver(action: String) {
        unregisterScanReceiver()
        val receiver =
            object : BroadcastReceiver() {
                override fun onReceive(
                    context: Context,
                    intent: Intent,
                ) {
                    val extras = bundleToMap(intent)
                    val data = scanKey?.let { intent.extras?.get(it)?.toString() }
                    scannerEvents?.success(
                        mapOf(
                            "action" to intent.action,
                            "data" to (data ?: firstStringExtra(extras).orEmpty()),
                            "extras" to extras,
                        ),
                    )
                }
            }
        scanReceiver = receiver
        val filter = IntentFilter(action)
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.TIRAMISU) {
            appContext.registerReceiver(receiver, filter, Context.RECEIVER_NOT_EXPORTED)
        } else {
            @Suppress("DEPRECATION")
            appContext.registerReceiver(receiver, filter)
        }
    }

    private fun unregisterScanReceiver() {
        val receiver = scanReceiver ?: return
        runCatching { appContext.unregisterReceiver(receiver) }
        scanReceiver = null
    }

    private fun removePrintListener() {
        runCatching { printer?.removePrintListener(printListener) }
    }

    private fun postPrinterEvent(event: Map<String, Any?>) {
        mainHandler.post {
            printerEvents?.success(event)
        }
    }

    private fun bundleToMap(intent: Intent): Map<String, Any?> {
        val bundle = intent.extras ?: return emptyMap()
        val result = mutableMapOf<String, Any?>()
        for (key in bundle.keySet()) {
            val value = bundle.get(key)
            result[key] =
                when (value) {
                    null, is Boolean, is Int, is Long, is Double, is String -> value
                    is Float -> value.toDouble()
                    else -> value.toString()
                }
        }
        return result
    }

    private fun firstStringExtra(extras: Map<String, Any?>): String? {
        return extras.values.firstOrNull { it is String } as? String
    }
}

private fun MethodCall.stringArg(name: String): String {
    return argument<String>(name) ?: throw IllegalArgumentException("$name is required")
}

private fun MethodCall.intArg(name: String): Int {
    val value = argument<Any>(name) ?: throw IllegalArgumentException("$name is required")
    return when (value) {
        is Int -> value
        is Long -> value.toInt()
        is Number -> value.toInt()
        else -> value.toString().toInt()
    }
}

private fun MethodCall.optionalIntArg(name: String): Int? {
    val value = argument<Any>(name) ?: return null
    return when (value) {
        is Int -> value
        is Long -> value.toInt()
        is Number -> value.toInt()
        else -> value.toString().toInt()
    }
}

private fun MethodCall.doubleArg(name: String): Double {
    val value = argument<Any>(name) ?: throw IllegalArgumentException("$name is required")
    return when (value) {
        is Double -> value
        is Float -> value.toDouble()
        is Number -> value.toDouble()
        else -> value.toString().toDouble()
    }
}

private fun MethodCall.boolArg(name: String): Boolean {
    return argument<Boolean>(name) ?: throw IllegalArgumentException("$name is required")
}

private fun MethodCall.intListArg(name: String): List<Int> {
    val value = argument<List<Any?>>(name) ?: throw IllegalArgumentException("$name is required")
    return value.map {
        when (it) {
            is Int -> it
            is Long -> it.toInt()
            is Number -> it.toInt()
            else -> it.toString().toInt()
        }
    }
}
