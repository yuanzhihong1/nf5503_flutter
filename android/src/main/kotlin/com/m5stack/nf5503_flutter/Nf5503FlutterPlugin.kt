package com.m5stack.nf5503_flutter

import android.app.Activity
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
    private var scanner: Nf5503ScannerApi? = null
    private var printer: Nf5503PrinterApi? = null
    private var scannerLoadAttempted = false
    private var printerLoadAttempted = false
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
                "scanner.getScannerType" -> result.success(
                    scannerOrNull()?.getScannerType() ?: SCANNER_TYPE_NONE,
                )
                "scanner.isConflicted" -> result.success(ensureScanner().isScannerConflicted())
                "scanner.connectDecoder" -> {
                    ensureScanner().connectDecoder()
                    result.success(null)
                }
                "scanner.disconnectDecoder" -> {
                    ensureScanner().disconnectDecoder()
                    result.success(null)
                }
                "scanner.getDecoderStatus" -> result.success(ensureScanner().getDecoderStatus())
                "scanner.isDecoderConnected" -> result.success(ensureScanner().isDecoderConnected())
                "scanner.setPrefix" -> {
                    ensureScanner().setPrefix(call.stringArg("prefix"))
                    result.success(null)
                }
                "scanner.getPrefix" -> result.success(ensureScanner().getPrefix().orEmpty())
                "scanner.setSuffix" -> {
                    ensureScanner().setSuffix(call.stringArg("suffix"))
                    result.success(null)
                }
                "scanner.getSuffix" -> result.success(ensureScanner().getSuffix().orEmpty())
                "scanner.setFilter" -> {
                    ensureScanner().setFilter(call.stringArg("filter"))
                    result.success(null)
                }
                "scanner.getFilter" -> result.success(ensureScanner().getFilter().orEmpty())
                "scanner.setPlaySound" -> {
                    ensureScanner().setPlaySound(call.boolArg("enabled"))
                    result.success(null)
                }
                "scanner.getPlaySound" -> result.success(ensureScanner().getPlaySound())
                "scanner.setVibrate" -> {
                    ensureScanner().setVibrate(call.boolArg("enabled"))
                    result.success(null)
                }
                "scanner.getVibrate" -> result.success(ensureScanner().getVibrate())
                "scanner.setContinueScan" -> {
                    ensureScanner().setContinueScan(call.boolArg("enabled"))
                    result.success(null)
                }
                "scanner.getContinueScan" -> result.success(ensureScanner().getContinueScan())
                "scanner.setMultiDecode" -> {
                    ensureScanner().setMultiDecode(call.boolArg("enabled"))
                    result.success(null)
                }
                "scanner.getMultiDecode" -> result.success(ensureScanner().getMultiDecode())
                "scanner.setMultiReadNumber" -> {
                    ensureScanner().setMultiReadNumber(call.intArg("number"))
                    result.success(null)
                }
                "scanner.getMultiReadNumber" -> result.success(ensureScanner().getMultiReadNumber())
                "scanner.setDisableSameBarcode" -> {
                    ensureScanner().setDisableSameBarcode(call.boolArg("disabled"))
                    result.success(null)
                }
                "scanner.getDisableSameBarcode" -> result.success(ensureScanner().getDisableSameBarcode())
                "scanner.setBroadcastAction" -> {
                    ensureScanner().setBroadcastAction(call.stringArg("action"))
                    result.success(null)
                }
                "scanner.getBroadcastAction" -> result.success(ensureScanner().getBroadcastAction().orEmpty())
                "scanner.setBroadcastKey" -> {
                    ensureScanner().setBroadcastKey(call.stringArg("key"))
                    result.success(null)
                }
                "scanner.getBroadcastKey" -> result.success(ensureScanner().getBroadcastKey().orEmpty())
                "scanner.setOutputMode" -> {
                    ensureScanner().setOutputMode(call.intArg("mode"))
                    result.success(null)
                }
                "scanner.getOutputMode" -> result.success(ensureScanner().getOutputMode())
                "scanner.setDecodeMode" -> {
                    val mode = call.intArg("mode")
                    ensureScanner().setDecodeMode(mode)
                    scanDecodeMode = mode
                    result.success(null)
                }
                "scanner.getDecodeMode" -> result.success(
                    ensureScanner().getDecodeMode().also { scanDecodeMode = it },
                )
                "scanner.setEndMark" -> {
                    ensureScanner().setEndMark(call.intArg("mark"))
                    result.success(null)
                }
                "scanner.getEndMark" -> result.success(ensureScanner().getEndMark())
                "scanner.setHandleKey" -> {
                    ensureScanner().setHandleKey(call.boolArg("enabled"))
                    result.success(null)
                }
                "scanner.getHandleKey" -> result.success(ensureScanner().getHandleKey())
                "scanner.setIntervalTime" -> {
                    result.success(ensureScanner().setIntervalTime(call.intArg("milliseconds")))
                }
                "scanner.getIntervalTime" -> result.success(ensureScanner().getIntervalTime())
                "scanner.setDecodeTimeout" -> {
                    ensureScanner().setDecodeTimeout(call.intArg("milliseconds"))
                    result.success(null)
                }
                "scanner.getDecodeTimeout" -> result.success(ensureScanner().getDecodeTimeout())
                "scanner.setLiftToStop" -> {
                    ensureScanner().setLiftToStop(call.boolArg("enabled"))
                    result.success(null)
                }
                "scanner.getLiftToStop" -> result.success(ensureScanner().getLiftToStop())
                "scanner.setSymbologyValues" -> {
                    ensureScanner().setSymbologyValues(
                        call.intListArg("paramIds").toIntArray(),
                        call.intListArg("values").toIntArray(),
                    )
                    result.success(null)
                }
                "scanner.getSymbologyValues" -> {
                    result.success(
                        ensureScanner()
                            .getSymbologyValues(call.intListArg("paramIds").toIntArray())
                            ?.toList()
                            ?: emptyList<Int>(),
                    )
                }
                "scanner.enableAllSymbologies" -> {
                    ensureScanner().enableAllSymbologies(call.boolArg("enabled"))
                    result.success(null)
                }
                "scanner.enableSymbology" -> {
                    ensureScanner().enableSymbology(
                        call.boolArg("enabled"),
                        call.intArg("symbologyId"),
                    )
                    result.success(null)
                }
                "scanner.enableAll1dSymbologies" -> {
                    ensureScanner().enableAll1dSymbologies(call.boolArg("enabled"))
                    result.success(null)
                }
                "scanner.enableAll2dSymbologies" -> {
                    ensureScanner().enableAll2dSymbologies(call.boolArg("enabled"))
                    result.success(null)
                }
                "scanner.isSymbologyEnabled" -> {
                    result.success(ensureScanner().isSymbologyEnabled(call.intArg("symbologyId")))
                }
                "scanner.isSymbologySupported" -> {
                    result.success(ensureScanner().isSymbologySupported(call.intArg("symbologyId")))
                }
                "scanner.reset" -> {
                    ensureScanner().reset()
                    result.success(null)
                }

                "printer.getVersion" -> result.success(printerOrNull()?.getVersion().orEmpty())
                "printer.open" -> result.success(printerOrNull()?.open() ?: false)
                "printer.close" -> result.success(printerOrNull()?.close() ?: false)
                "printer.setConcentration" -> {
                    ensurePrinter().setDensity(concentrationToNative(call.intArg("density")))
                    result.success(null)
                }
                "printer.getConcentration" -> result.success(ensurePrinter().getDensity() * 4)
                "printer.reset" -> result.success(ensurePrinter().reset())
                "printer.setFontType" -> {
                    ensurePrinter().setFontType(call.stringArg("fontType"))
                    result.success(null)
                }
                "printer.getFontType" -> result.success(ensurePrinter().getFontType().orEmpty())
                "printer.setFontSize" -> {
                    ensurePrinter().setFontSize(call.intArg("fontSize"))
                    result.success(null)
                }
                "printer.getFontSize" -> result.success(ensurePrinter().getFontSize())
                "printer.setBold" -> {
                    ensurePrinter().setBold(call.boolArg("enabled"))
                    result.success(null)
                }
                "printer.isBold" -> result.success(ensurePrinter().isBold())
                "printer.setBlackMark" -> {
                    ensurePrinter().setBlackMark(call.boolArg("enabled"))
                    result.success(null)
                }
                "printer.isBlackMark" -> result.success(ensurePrinter().isBlackMark())
                "printer.setThreshold" -> result.success(ensurePrinter().setThreshold(call.intArg("threshold")))
                "printer.setUnderline" -> {
                    ensurePrinter().setUnderline(call.boolArg("enabled"))
                    result.success(null)
                }
                "printer.isUnderline" -> result.success(ensurePrinter().isUnderline())
                "printer.setFeedPaperSpace" -> {
                    ensurePrinter().setFeedPaperSpace(call.intArg("space"))
                    result.success(null)
                }
                "printer.getFeedPaperSpace" -> result.success(ensurePrinter().getFeedPaperSpace())
                "printer.setUnwindPaperLength" -> {
                    ensurePrinter().setUnwindPaperLength(call.intArg("length"))
                    result.success(null)
                }
                "printer.getUnwindPaperLength" -> result.success(ensurePrinter().getUnwindPaperLength())
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
                    ensurePrinter().addQrCode(
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
                "printer.isReverse" -> result.success(ensurePrinter().isReverse())
                "printer.goToNextMark" -> {
                    ensurePrinter().goToNextMark(call.optionalIntArg("distance"))
                    result.success(null)
                }
                "printer.setLineSpacing" -> {
                    ensurePrinter().setLineSpacing(call.doubleArg("spacing").toFloat())
                    result.success(null)
                }
                "printer.getLineSpacing" -> result.success(ensurePrinter().getLineSpacing().toDouble())
                "printer.getSupportPrint" -> result.success(printerOrNull()?.getSupportPrint() ?: 0)
                "printer.getState" -> result.success(ensurePrinter().getPrinterState(call.intArg("stateType")))
                else -> result.notImplemented()
            }
        } catch (error: Nf5503UnavailableException) {
            result.error("NF5503_UNAVAILABLE", error.message, null)
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

    private fun scannerOrNull(): Nf5503ScannerApi? {
        scanner?.let { return it }
        if (scannerLoadAttempted) {
            return null
        }
        scannerLoadAttempted = true
        scanner = Nf5503VendorAdapterLoader.createScanner(appContext)
        return scanner
    }

    private fun printerOrNull(): Nf5503PrinterApi? {
        printer?.let { return it }
        if (printerLoadAttempted) {
            return null
        }
        printerLoadAttempted = true
        printer = Nf5503VendorAdapterLoader.createPrinter(appContext)
        return printer
    }

    private fun ensureScanner(): Nf5503ScannerApi {
        return scannerOrNull() ?: throw Nf5503UnavailableException("扫码")
    }

    private fun ensurePrinter(): Nf5503PrinterApi {
        return printerOrNull() ?: throw Nf5503UnavailableException("打印")
    }

    private fun getSymbologyListByReflection(): List<Map<String, Any?>> {
        return ensureScanner().getSymbologyList().map { valueToMap(it) }
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

    private val scannerStreamHandler =
        object : EventChannel.StreamHandler {
            override fun onListen(arguments: Any?, events: EventChannel.EventSink) {
                try {
                    runApiBlocking {
                        scannerEvents = events
                        val args = arguments as? Map<*, *>
                        val scanner =
                            scannerOrNull()
                                ?: throw Nf5503UnavailableException("扫码")
                        scanAction =
                            args?.get("action")?.toString()?.takeIf { it.isNotBlank() }
                                ?: runCatching { scanner.getBroadcastAction() }
                                    .getOrNull()
                                    ?.takeIf { it.isNotBlank() }
                                ?: DEFAULT_SCAN_ACTION
                        scanKey =
                            args?.get("key")?.toString()?.takeIf { it.isNotBlank() }
                                ?: runCatching { scanner.getBroadcastKey() }
                                    .getOrNull()
                                    ?.takeIf { it.isNotBlank() }
                                ?: DEFAULT_SCAN_KEY
                        scanDecodeMode =
                            runCatching { scanner.getDecodeMode() }
                                .getOrDefault(scanDecodeMode)

                        registerScanReceiver(scanAction ?: DEFAULT_SCAN_ACTION, events)
                    }
                } catch (error: Throwable) {
                    postScannerError(
                        events,
                        if (error is Nf5503UnavailableException) {
                            "NF5503_UNAVAILABLE"
                        } else {
                            "NF5503_SCAN_LISTENER"
                        },
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
                        val printer =
                            printerOrNull()
                                ?: throw Nf5503UnavailableException("打印")
                        printer.addPrintListener { state ->
                            postPrinterEvent(
                                mapOf(
                                    "type" to "state",
                                    "state" to state,
                                ),
                            )
                        }
                        postPrinterEvent(
                            mapOf(
                                "type" to "version",
                                "version" to printer.getVersion().orEmpty(),
                            ),
                        )
                    }
                } catch (error: Throwable) {
                    postPrinterError(
                        events,
                        if (error is Nf5503UnavailableException) {
                            "NF5503_UNAVAILABLE"
                        } else {
                            "NF5503_PRINT_LISTENER"
                        },
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
        runCatching { printer?.removePrintListener() }
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
        val aimIdValue = extras[SCAN_KEY_AIM_ID]

        val result = linkedMapOf<String, Any?>(
            "action" to intent.action,
            "key" to configuredKey,
            "data" to data,
            "extras" to extras,
        )
        if (rawData != null) {
            result["rawData"] = rawData
        }
        stringValue(extras[SCAN_KEY_CODE_ID], scanDecodeMode)?.let {
            result["codeId"] = it
        }
        intValue(extras[SCAN_KEY_BARCODE_TYPE])?.let {
            result["barcodeType"] = it
        }
        stringValue(aimIdValue, scanDecodeMode)?.let {
            result["aimId"] = it
        }
        if (aimIdValue is ByteArray) {
            result["aimIdBytes"] = aimIdValue
        }
        intValue(extras[SCAN_KEY_LENGTH])?.let {
            result["length"] = it
        }
        intValue(extras[SCAN_KEY_AIM_MODIFIER])?.let {
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
                SCAN_KEY_BARCODE_DATA,
                SCAN_KEY_BARCODE_BYTE_DATA,
                SCAN_KEY_GEEK_BARCODE_BYTE_DATA,
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
internal const val SCANNER_TYPE_NONE = 0
private const val SCAN_KEY_BARCODE_DATA = "barcodeData"
private const val SCAN_KEY_BARCODE_BYTE_DATA = "barocode"
private const val SCAN_KEY_GEEK_BARCODE_BYTE_DATA = "data"
private const val SCAN_KEY_LENGTH = "length"
private const val SCAN_KEY_BARCODE_TYPE = "barcodeType"
private const val SCAN_KEY_CODE_ID = "codeId"
private const val SCAN_KEY_AIM_ID = "aimId"
private const val SCAN_KEY_AIM_MODIFIER = "aimModifier"
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
