package com.m5stack.nf5503_flutter

import android.bld.PrintManager
import android.app.Activity
import android.bld.ScanManager
import android.bld.scan.configuration.ScanConfig
import android.bld.print.aidl.PrinterBinderListener
import android.content.BroadcastReceiver
import android.content.Context
import android.content.Intent
import android.content.IntentFilter
import android.graphics.BitmapFactory
import android.os.Build
import android.os.Bundle
import android.os.Handler
import android.os.HandlerThread
import android.os.Looper
import com.example.lc_print_sdk.PrintUtil
import io.flutter.embedding.engine.plugins.FlutterPlugin
import io.flutter.embedding.engine.plugins.activity.ActivityAware
import io.flutter.embedding.engine.plugins.activity.ActivityPluginBinding
import io.flutter.plugin.common.EventChannel
import io.flutter.plugin.common.MethodCall
import io.flutter.plugin.common.MethodChannel
import io.flutter.plugin.common.StandardMethodCodec
import java.lang.reflect.Modifier
import java.nio.charset.Charset
import java.util.concurrent.ExecutionException
import java.util.concurrent.ExecutorService
import java.util.concurrent.Executors
import java.util.concurrent.RejectedExecutionException

/** Flutter plugin bridge for the NF5503 scanner and printer SDKs. */
class Nf5503FlutterPlugin :
    FlutterPlugin,
    ActivityAware,
    MethodChannel.MethodCallHandler {
    private lateinit var appContext: Context
    private lateinit var methodChannel: MethodChannel
    private lateinit var scannerEventChannel: EventChannel
    private lateinit var printerEventChannel: EventChannel
    private lateinit var nfcEventChannel: EventChannel
    private var nfcController: Nf5503NfcController? = null

    private val mainHandler by lazy { Handler(Looper.getMainLooper()) }
    // Vendor scanner/printer calls are serialized off the Android main thread.
    @Volatile
    private var apiExecutor: ExecutorService = newApiExecutor()
    private lateinit var scanHandlerThread: HandlerThread
    private lateinit var scanHandler: Handler
    private var scanner: ScanManager? = null
    private var printer: PrintManager? = null
    private var printUtil: PrintUtil? = null
    @Volatile
    private var scannerEvents: EventChannel.EventSink? = null
    @Volatile
    private var printerEvents: EventChannel.EventSink? = null
    @Volatile
    private var scanReceiver: BroadcastReceiver? = null
    @Volatile
    private var scanAction: String? = null
    @Volatile
    private var scanKey: String? = null
    @Volatile
    private var scanDecodeMode: Int = 0

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
        if (apiExecutor.isShutdown) {
            apiExecutor = newApiExecutor()
        }
        scanHandlerThread = HandlerThread("nf5503-scan-broadcast").also { it.start() }
        scanHandler = Handler(scanHandlerThread.looper)
        nfcController = Nf5503NfcController(appContext, apiExecutor).also { it.attach() }

        val messenger = flutterPluginBinding.binaryMessenger
        val taskQueue = messenger.makeBackgroundTaskQueue()
        methodChannel = MethodChannel(
            messenger,
            "nf5503_flutter",
            StandardMethodCodec.INSTANCE,
            taskQueue,
        )
        scannerEventChannel = EventChannel(
            messenger,
            "nf5503_flutter/scanner",
            StandardMethodCodec.INSTANCE,
            taskQueue,
        )
        printerEventChannel = EventChannel(
            messenger,
            "nf5503_flutter/printer",
            StandardMethodCodec.INSTANCE,
            taskQueue,
        )
        nfcEventChannel = EventChannel(
            messenger,
            "nf5503_flutter/nfc",
            StandardMethodCodec.INSTANCE,
            taskQueue,
        )

        methodChannel.setMethodCallHandler(this)
        scannerEventChannel.setStreamHandler(scannerStreamHandler)
        printerEventChannel.setStreamHandler(printerStreamHandler)
        nfcEventChannel.setStreamHandler(nfcController)
    }

    override fun onMethodCall(
        call: MethodCall,
        result: MethodChannel.Result,
    ) {
        runApiAsync(result) {
            handleMethodCall(call, result)
        }
    }

    private fun handleMethodCall(
        call: MethodCall,
        result: MethodChannel.Result,
    ) {
        try {
            if (nfcController?.handleMethodCall(call, result) == true) {
                return
            }
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
                    connectDecoder(ensureScanner())
                    result.success(null)
                }
                "scanner.disconnectDecoder" -> {
                    disconnectDecoder(ensureScanner())
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
                    val mode = call.intArg("mode")
                    ensureScanner().setDecodeMode(mode)
                    scanDecodeMode = mode
                    result.success(null)
                }
                "scanner.getDecodeMode" -> result.success(
                    ensureScanner().decodeMode.also { scanDecodeMode = it },
                )
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
                            ?.toList()
                            ?: emptyList<Int>(),
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
                    ensurePrinter().setDensity(concentrationToNative(call.intArg("density")))
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
        methodChannel.setMethodCallHandler(null)
        scannerEventChannel.setStreamHandler(null)
        printerEventChannel.setStreamHandler(null)
        nfcEventChannel.setStreamHandler(null)
        nfcController?.dispose()
        nfcController = null
        scannerEvents = null
        printerEvents = null
        mainHandler.removeCallbacksAndMessages(null)

        runCatching {
            apiExecutor.execute {
                unregisterScanReceiver()
                removePrintListener()
            }
        }
        apiExecutor.shutdown()
        if (::scanHandlerThread.isInitialized) {
            scanHandlerThread.quitSafely()
        }
    }

    override fun onAttachedToActivity(binding: ActivityPluginBinding) {
        nfcController?.attachActivity(binding.activity)
    }

    override fun onDetachedFromActivityForConfigChanges() {
        nfcController?.detachActivity()
    }

    override fun onReattachedToActivityForConfigChanges(binding: ActivityPluginBinding) {
        nfcController?.attachActivity(binding.activity)
    }

    override fun onDetachedFromActivity() {
        nfcController?.detachActivity()
    }

    private fun runApiAsync(
        result: MethodChannel.Result,
        block: () -> Unit,
    ) {
        try {
            apiExecutor.execute(block)
        } catch (error: RejectedExecutionException) {
            result.error("NF5503_ERROR", error.message, null)
        }
    }

    private fun <T> runApiBlocking(block: () -> T): T {
        return try {
            apiExecutor.submit<T> { block() }.get()
        } catch (error: ExecutionException) {
            val cause = error.cause ?: error
            throw (cause as? RuntimeException) ?: RuntimeException(cause)
        } catch (error: InterruptedException) {
            Thread.currentThread().interrupt()
            throw RuntimeException(error)
        }
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

    private fun getSymbologyListByReflection(): List<Map<String, Any?>> {
        val scanner = ensureScanner()
        val values = scanner.javaClass
            .getMethod("getSymbologyList")
            .invoke(scanner) as? Iterable<*> ?: return emptyList()
        return values.map { valueToMap(it) }
    }

    private fun valueToMap(
        value: Any?,
        depth: Int = 0,
        seen: MutableSet<Int> = mutableSetOf(),
    ): Map<String, Any?> {
        if (value == null) {
            return mapOf("value" to null)
        }
        if (isScalarReflectionValue(value)) {
            return mapOf("value" to codecValue(value))
        }
        if (value is Iterable<*>) {
            return mapOf(
                "value" to value.map { valueToMap(it, depth + 1, seen) },
            )
        }
        if (depth >= MAX_REFLECTION_DEPTH) {
            return mapOf(
                "className" to value.javaClass.name,
                "label" to value.toString(),
                "truncated" to true,
            )
        }

        val identity = System.identityHashCode(value)
        if (!seen.add(identity)) {
            return mapOf(
                "className" to value.javaClass.name,
                "label" to value.toString(),
                "cycle" to true,
            )
        }

        val result = linkedMapOf<String, Any?>(
            "className" to value.javaClass.name,
            "label" to value.toString(),
        )
        value.javaClass.fields
            .filter {
                Modifier.isPublic(it.modifiers) &&
                    !Modifier.isStatic(it.modifiers)
            }
            .sortedBy { it.name }
            .forEach { field ->
                runCatching {
                    result[field.name] =
                        reflectiveValue(field.get(value), depth + 1, seen)
                }
            }
        value.javaClass.methods
            .filter {
                Modifier.isPublic(it.modifiers) &&
                    !Modifier.isStatic(it.modifiers) &&
                    it.parameterTypes.isEmpty() &&
                    it.declaringClass != Any::class.java &&
                    it.name != "getClass" &&
                    !it.isSynthetic &&
                    !it.isBridge
            }
            .sortedBy { it.name }
            .forEach { method ->
                val name = propertyName(method.name) ?: return@forEach
                runCatching {
                    result[name] =
                        reflectiveValue(method.invoke(value), depth + 1, seen)
                }
            }
        seen.remove(identity)
        return result
    }

    private fun reflectiveValue(
        value: Any?,
        depth: Int,
        seen: MutableSet<Int>,
    ): Any? {
        return when {
            value == null -> null
            isScalarReflectionValue(value) -> codecValue(value)
            value is Iterable<*> -> value.map { valueToMap(it, depth, seen) }
            value is Array<*> -> value.map { valueToMap(it, depth, seen) }
            else -> valueToMap(value, depth, seen)
        }
    }

    private fun isScalarReflectionValue(value: Any): Boolean {
        return value is Boolean ||
            value is Number ||
            value is String ||
            value is Char ||
            value is CharSequence ||
            value is ByteArray ||
            value.javaClass.isEnum
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

    private fun codecValue(
        value: Any?,
        depth: Int = 0,
    ): Any? {
        if (depth > MAX_REFLECTION_DEPTH) {
            return value?.toString()
        }
        return when (value) {
            null, is Boolean, is String -> value
            is Byte -> value.toInt()
            is Short -> value.toInt()
            is Int -> value
            is Long -> value
            is Float -> value.toDouble()
            is Double -> value
            is Number -> value
            is Char -> value.toString()
            is CharSequence -> value.toString()
            is ByteArray -> value.copyOf()
            is ShortArray -> value.map { it.toInt() }
            is IntArray -> value.toList()
            is LongArray -> value.toList()
            is FloatArray -> value.map { it.toDouble() }
            is DoubleArray -> value.toList()
            is BooleanArray -> value.toList()
            is CharArray -> String(value)
            is Bundle -> bundleToMap(value, depth + 1)
            is Map<*, *> -> {
                linkedMapOf<String, Any?>().apply {
                    value.forEach { (key, item) ->
                        put(key.toString(), codecValue(item, depth + 1))
                    }
                }
            }
            is Iterable<*> -> value.map { codecValue(it, depth + 1) }
            is Array<*> -> value.map { codecValue(it, depth + 1) }
            else -> value.toString()
        }
    }

    private fun connectDecoder(scanner: ScanManager) {
        try {
            scanner.decoderConnect()
        } catch (_: NoSuchMethodError) {
            scanner.DecoderConnect()
        }
    }

    private fun disconnectDecoder(scanner: ScanManager) {
        try {
            scanner.decoderDisconnect()
        } catch (_: NoSuchMethodError) {
            scanner.DecoderDisconnect()
        }
    }

    private val scannerStreamHandler =
        object : EventChannel.StreamHandler {
            override fun onListen(arguments: Any?, events: EventChannel.EventSink) {
                try {
                    runApiBlocking {
                        scannerEvents = events
                        val args = arguments as? Map<*, *>
                        val scanner = ensureScanner()
                        scanAction =
                            args?.get("action")?.toString()?.takeIf { it.isNotBlank() }
                                ?: runCatching { scanner.broadcastAction }
                                    .getOrNull()
                                    ?.takeIf { it.isNotBlank() }
                                ?: DEFAULT_SCAN_ACTION
                        scanKey =
                            args?.get("key")?.toString()?.takeIf { it.isNotBlank() }
                                ?: runCatching { scanner.broadcastKey }
                                    .getOrNull()
                                    ?.takeIf { it.isNotBlank() }
                                ?: DEFAULT_SCAN_KEY
                        scanDecodeMode =
                            runCatching { scanner.decodeMode }
                                .getOrDefault(scanDecodeMode)

                        registerScanReceiver(scanAction ?: DEFAULT_SCAN_ACTION, events)
                    }
                } catch (error: Throwable) {
                    postScannerError(
                        events,
                        "NF5503_SCAN_LISTENER",
                        error.message ?: "Unable to initialize scanner listener.",
                    )
                }
            }

            override fun onCancel(arguments: Any?) {
                runApiBlocking {
                    unregisterScanReceiver()
                    scannerEvents = null
                }
            }
        }

    private val printerStreamHandler =
        object : EventChannel.StreamHandler {
            override fun onListen(arguments: Any?, events: EventChannel.EventSink) {
                try {
                    runApiBlocking {
                        printerEvents = events
                        val printer = ensurePrinter()
                        printer.addPrintListener(printListener)
                        postPrinterEvent(
                            mapOf(
                                "type" to "version",
                                "version" to printer.printerVer.orEmpty(),
                            ),
                        )
                    }
                } catch (error: Throwable) {
                    postPrinterError(
                        events,
                        "NF5503_PRINT_LISTENER",
                        error.message ?: "Unable to initialize printer listener.",
                    )
                }
            }

            override fun onCancel(arguments: Any?) {
                runApiBlocking {
                    removePrintListener()
                    printerEvents = null
                }
            }
        }

    private fun registerScanReceiver(
        action: String,
        events: EventChannel.EventSink,
    ) {
        unregisterScanReceiver()
        val receiver =
            object : BroadcastReceiver() {
                override fun onReceive(
                    context: Context,
                    intent: Intent,
                ) {
                    postScannerEvent(scanEvent(intent))
                }
            }
        scanReceiver = receiver
        try {
            val filter = IntentFilter(action)
            if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.TIRAMISU) {
                appContext.registerReceiver(
                    receiver,
                    filter,
                    null,
                    scanHandler,
                    // The vendor scan service runs outside this application.
                    Context.RECEIVER_EXPORTED,
                )
            } else {
                @Suppress("DEPRECATION")
                appContext.registerReceiver(receiver, filter, null, scanHandler)
            }
        } catch (error: Throwable) {
            unregisterScanReceiver()
            postScannerError(
                events,
                "NF5503_SCAN_RECEIVER",
                error.message ?: "Unable to register scanner broadcast receiver.",
            )
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

    private fun postScannerEvent(event: Map<String, Any?>) {
        mainHandler.post {
            scannerEvents?.success(event)
        }
    }

    private fun postScannerError(
        events: EventChannel.EventSink,
        code: String,
        message: String,
    ) {
        mainHandler.post {
            events.error(code, message, null)
        }
    }

    private fun postPrinterError(
        events: EventChannel.EventSink,
        code: String,
        message: String,
    ) {
        mainHandler.post {
            events.error(code, message, null)
        }
    }

    private fun scanEvent(intent: Intent): Map<String, Any?> {
        val extras = bundleToMap(intent.extras)
        val configuredKey = scanKey ?: DEFAULT_SCAN_KEY
        val rawData = findScanBytes(extras, configuredKey)
        val data = findScanText(extras, configuredKey, scanDecodeMode).orEmpty()
        val aimIdValue = extras[ScanConfig.BARCODE_AIMID]

        val result = linkedMapOf<String, Any?>(
            "action" to intent.action,
            "key" to configuredKey,
            "data" to data,
            "extras" to extras,
        )
        if (rawData != null) {
            result["rawData"] = rawData
        }
        stringValue(extras[ScanConfig.BARCODE_ID], scanDecodeMode)?.let {
            result["codeId"] = it
        }
        intValue(extras[ScanConfig.BARCODE_TYPE])?.let {
            result["barcodeType"] = it
        }
        stringValue(aimIdValue, scanDecodeMode)?.let {
            result["aimId"] = it
        }
        if (aimIdValue is ByteArray) {
            result["aimIdBytes"] = aimIdValue
        }
        intValue(extras[ScanConfig.BARCODE_DATA_LEN])?.let {
            result["length"] = it
        }
        intValue(extras[ScanConfig.BARCODE_AIM_MODIFIER])?.let {
            result["aimModifier"] = it
        }
        return result
    }

    private fun findScanBytes(
        extras: Map<String, Any?>,
        configuredKey: String,
    ): ByteArray? {
        return scanValueCandidates(extras, configuredKey)
            .firstNotNullOfOrNull { (_, value) -> value as? ByteArray }
    }

    private fun findScanText(
        extras: Map<String, Any?>,
        configuredKey: String,
        decodeMode: Int,
    ): String? {
        for ((_, value) in scanValueCandidates(extras, configuredKey)) {
            val text = stringValue(value, decodeMode)
            if (!text.isNullOrEmpty()) {
                return text
            }
        }
        return null
    }

    private fun scanValueCandidates(
        extras: Map<String, Any?>,
        configuredKey: String,
    ): List<Pair<String, Any?>> {
        val keys =
            listOf(
                configuredKey,
                ScanConfig.BARCODE_DATA,
                ScanConfig.BARCODE_BYTE_DATA,
                ScanConfig.GEEK_BARCODE_BYTE_DATA,
            )
        return keys.distinct().mapNotNull { key ->
            extras[key]?.let { key to it }
        }
    }

    private fun stringValue(
        value: Any?,
        decodeMode: Int,
    ): String? {
        return when (value) {
            null -> null
            is String -> value
            is CharSequence -> value.toString()
            is Char -> value.toString()
            is Byte -> value.toInt().toChar().toString()
            is ByteArray -> decodeScanBytes(value, decodeMode)
            is Number -> value.toString()
            else -> value.toString()
        }
    }

    private fun intValue(value: Any?): Int? {
        return when (value) {
            is Byte -> value.toInt()
            is Short -> value.toInt()
            is Int -> value
            is Long -> value.toInt()
            is Float -> value.toInt()
            is Double -> value.toInt()
            is Number -> value.toInt()
            is String -> value.toIntOrNull()
            else -> null
        }
    }

    private fun bundleToMap(
        bundle: Bundle?,
        depth: Int = 0,
    ): Map<String, Any?> {
        if (bundle == null || depth > MAX_REFLECTION_DEPTH) {
            return emptyMap()
        }
        val result = linkedMapOf<String, Any?>()
        for (key in bundle.keySet()) {
            result[key] = codecValue(bundle.get(key), depth)
        }
        return result
    }
}

private const val MAX_REFLECTION_DEPTH = 8

internal const val DEFAULT_SCAN_ACTION = "scan.rcv.message"
internal const val DEFAULT_SCAN_KEY = "barcodeData"
internal const val MIN_PRINT_CONCENTRATION = 1
internal const val MAX_PRINT_CONCENTRATION = 39

/** Decodes vendor broadcast bytes according to the configured scan encoding mode. */
internal fun decodeScanBytes(
    bytes: ByteArray,
    decodeMode: Int,
): String {
    val charsetName =
        when (decodeMode) {
            0 -> "UTF-8"
            1 -> "US-ASCII"
            2 -> "GBK"
            3 -> "GB2312"
            4 -> "GB18030"
            5 -> "UTF-16"
            6 -> "ISO-8859-1"
            else -> "UTF-8"
        }
    return runCatching { String(bytes, Charset.forName(charsetName)) }
        .getOrElse { String(bytes, Charsets.UTF_8) }
}

/**
 * Matches `PrintUtil.printConcentration(int)` from the NF5502/NF5503 SDK:
 * `density / 4 + 1` using integer division, producing native levels 1..10.
 */
internal fun concentrationToNative(density: Int): Int {
    require(density in MIN_PRINT_CONCENTRATION..MAX_PRINT_CONCENTRATION) {
        "density must be between $MIN_PRINT_CONCENTRATION and $MAX_PRINT_CONCENTRATION"
    }
    return density / 4 + 1
}

private fun newApiExecutor(): ExecutorService {
    return Executors.newSingleThreadExecutor { runnable ->
        Thread(runnable, "nf5503-api").apply {
            isDaemon = true
        }
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
