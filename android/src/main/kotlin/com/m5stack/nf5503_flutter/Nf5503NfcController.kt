package com.m5stack.nf5503_flutter

import android.app.Activity
import android.app.Application
import android.content.BroadcastReceiver
import android.content.Context
import android.content.Intent
import android.content.IntentFilter
import android.net.Uri
import android.nfc.NdefMessage
import android.nfc.NdefRecord
import android.nfc.NfcAdapter
import android.nfc.Tag
import android.nfc.tech.MifareClassic
import android.nfc.tech.Ndef
import android.nfc.tech.NdefFormatable
import android.os.Build
import android.os.Bundle
import android.os.Handler
import android.os.Looper
import android.provider.Settings
import io.flutter.plugin.common.EventChannel
import io.flutter.plugin.common.MethodCall
import io.flutter.plugin.common.MethodChannel
import java.io.IOException
import java.nio.charset.Charset
import java.util.concurrent.ExecutorService
import java.util.concurrent.RejectedExecutionException
import java.util.concurrent.atomic.AtomicBoolean

/**
 * Android NFC bridge based on Reader Mode.
 *
 * Reader Mode is used instead of manifest intent filters so a Flutter route can
 * subscribe and unsubscribe without changing the host activity launch mode.
 */
internal class Nf5503NfcController(
    context: Context,
    private val nfcExecutor: ExecutorService,
) : EventChannel.StreamHandler {
    private val appContext: Context = context.applicationContext
    private val mainHandler = Handler(Looper.getMainLooper())
    private val adapter: NfcAdapter? = NfcAdapter.getDefaultAdapter(appContext)
    private val application = appContext as? Application

    @Volatile
    private var eventSink: EventChannel.EventSink? = null

    @Volatile
    private var activity: Activity? = null

    @Volatile
    private var activityResumed = false

    @Volatile
    private var discoveryRequested = false

    @Volatile
    private var readerModeActive = false

    @Volatile
    private var adapterState = when {
        adapter == null -> STATE_UNKNOWN
        adapter.isEnabled -> NfcAdapter.STATE_ON
        else -> NfcAdapter.STATE_OFF
    }

    @Volatile
    private var currentTag: Tag? = null

    @Volatile
    private var currentMifare: MifareClassic? = null

    private val lifecycleRegistered = AtomicBoolean(false)
    private var adapterReceiverRegistered = false

    private val adapterStateReceiver =
        object : BroadcastReceiver() {
            override fun onReceive(
                context: Context,
                intent: Intent,
            ) {
                if (intent.action != NfcAdapter.ACTION_ADAPTER_STATE_CHANGED) {
                    return
                }
                adapterState =
                    intent.getIntExtra(NfcAdapter.EXTRA_ADAPTER_STATE, STATE_UNKNOWN)
                updateReaderMode()
                postEvent(
                    mapOf(
                        "type" to "adapterState",
                        "state" to adapterState,
                        "status" to statusMap(),
                    ),
                )
            }
        }

    private val lifecycleCallbacks =
        object : Application.ActivityLifecycleCallbacks {
            override fun onActivityCreated(
                activity: Activity,
                savedInstanceState: Bundle?,
            ) = Unit

            override fun onActivityStarted(activity: Activity) = Unit

            override fun onActivityResumed(activity: Activity) {
                if (activity !== this@Nf5503NfcController.activity) {
                    return
                }
                activityResumed = true
                updateReaderMode()
                postStatus()
            }

            override fun onActivityPaused(activity: Activity) {
                if (activity !== this@Nf5503NfcController.activity) {
                    return
                }
                activityResumed = false
                updateReaderMode()
                scheduleMifareClose()
            }

            override fun onActivityStopped(activity: Activity) = Unit

            override fun onActivitySaveInstanceState(
                activity: Activity,
                outState: Bundle,
            ) = Unit

            override fun onActivityDestroyed(activity: Activity) {
                if (activity === this@Nf5503NfcController.activity) {
                    activityResumed = false
                    disableReaderMode()
                    this@Nf5503NfcController.activity = null
                }
            }
        }

    private val readerCallback =
        NfcAdapter.ReaderCallback { tag ->
            handleTagDiscovered(tag)
        }

    fun attach() {
        registerAdapterStateReceiver()
    }

    fun attachActivity(activity: Activity) {
        this.activity = activity
        activityResumed = true
        registerLifecycleCallbacks()
        updateReaderMode()
        postStatus()
    }

    fun detachActivity() {
        activityResumed = false
        disableReaderMode()
        scheduleMifareClose()
        currentTag = null
        currentMifare = null
        unregisterLifecycleCallbacks()
        activity = null
    }

    fun dispose() {
        eventSink = null
        discoveryRequested = false
        unregisterAdapterStateReceiver()
        detachActivity()
        mainHandler.removeCallbacksAndMessages(null)
    }

    override fun onListen(
        arguments: Any?,
        events: EventChannel.EventSink,
    ) {
        eventSink = events
        discoveryRequested = true
        mainHandler.post {
            postStatus()
            updateReaderMode()
        }
    }

    override fun onCancel(arguments: Any?) {
        eventSink = null
        discoveryRequested = false
        mainHandler.post {
            updateReaderMode()
            currentTag = null
            scheduleMifareClose()
        }
    }

    fun handleMethodCall(
        call: MethodCall,
        result: MethodChannel.Result,
    ): Boolean {
        if (!call.method.startsWith("nfc.")) {
            return false
        }
        try {
            when (call.method) {
                "nfc.isSupported" -> result.success(adapter != null)
                "nfc.isEnabled" -> result.success(adapter?.isEnabled == true)
                "nfc.getStatus" -> result.success(statusMap())
                "nfc.openSettings" -> {
                    openNfcSettings()
                    result.success(null)
                }
                "nfc.startDiscovery" -> {
                    discoveryRequested = true
                    mainHandler.post { updateReaderMode() }
                    result.success(null)
                }
                "nfc.stopDiscovery" -> {
                    discoveryRequested = false
                    mainHandler.post {
                        updateReaderMode()
                        currentTag = null
                        scheduleMifareClose()
                    }
                    result.success(null)
                }
                "nfc.getCurrentTag" -> {
                    result.success(
                        currentTag?.let { runCatching { tagToMap(it) }.getOrNull() },
                    )
                }
                "nfc.readNdef" -> {
                    result.success(readNdefMessage())
                }
                "nfc.writeNdefText" -> {
                    val text = call.requireString("text")
                    val languageCode = call.requireString("languageCode")
                    writeNdefMessage(
                        NdefMessage(
                            arrayOf(NdefRecord.createTextRecord(languageCode, text)),
                        ),
                        formatIfNeeded = true,
                    )
                    result.success(null)
                }
                "nfc.writeNdefUri" -> {
                    val uri = Uri.parse(call.requireString("uri"))
                    writeNdefMessage(
                        NdefMessage(arrayOf(NdefRecord.createUri(uri))),
                        formatIfNeeded = true,
                    )
                    result.success(null)
                }
                "nfc.writeNdefMime" -> {
                    val mimeType = call.requireString("mimeType")
                    val data = call.requireBytes("data")
                    writeNdefMessage(
                        NdefMessage(arrayOf(NdefRecord.createMime(mimeType, data))),
                        formatIfNeeded = true,
                    )
                    result.success(null)
                }
                "nfc.writeNdefMessage" -> {
                    writeNdefMessage(
                        NdefMessage(call.requireBytes("message")),
                        formatIfNeeded = call.requireBool("formatIfNeeded"),
                    )
                    result.success(null)
                }
                "nfc.makeNdefReadOnly" -> {
                    makeNdefReadOnly()
                    result.success(null)
                }
                "nfc.mifare.getInfo" -> {
                    result.success(mifareInfoMapOrNull())
                }
                "nfc.mifare.connect" -> {
                    requireMifareClassic().connect()
                    result.success(null)
                }
                "nfc.mifare.close" -> {
                    closeMifareClassic()
                    result.success(null)
                }
                "nfc.mifare.isConnected" -> {
                    result.success(currentMifare?.isConnected == true)
                }
                "nfc.mifare.setTimeout" -> {
                    requireMifareClassic().setTimeout(call.requireInt("milliseconds"))
                    result.success(null)
                }
                "nfc.mifare.authenticate" -> {
                    val sectorIndex = call.requireInt("sectorIndex")
                    val key = call.requireBytes("key")
                    require(key.size == MIFARE_KEY_LENGTH) {
                        "Mifare Classic key must contain exactly 6 bytes."
                    }
                    val card = requireConnectedMifareClassic()
                    val authenticated =
                        when (call.requireInt("keyType")) {
                            MIFARE_KEY_A -> card.authenticateSectorWithKeyA(sectorIndex, key)
                            MIFARE_KEY_B -> card.authenticateSectorWithKeyB(sectorIndex, key)
                            else -> throw IllegalArgumentException("keyType must be 0 (A) or 1 (B).")
                        }
                    result.success(authenticated)
                }
                "nfc.mifare.readBlock" -> {
                    result.success(
                        requireConnectedMifareClassic()
                            .readBlock(call.requireInt("blockIndex")),
                    )
                }
                "nfc.mifare.writeBlock" -> {
                    val blockIndex = call.requireInt("blockIndex")
                    val data = call.requireBytes("data")
                    require(data.size == MIFARE_BLOCK_LENGTH) {
                        "Mifare Classic block data must contain exactly 16 bytes."
                    }
                    requireConnectedMifareClassic().writeBlock(blockIndex, data)
                    result.success(null)
                }
                "nfc.mifare.transceive" -> {
                    result.success(
                        requireConnectedMifareClassic()
                            .transceive(call.requireBytes("data")),
                    )
                }
                "nfc.mifare.increment" -> {
                    requireConnectedMifareClassic()
                        .increment(
                            call.requireInt("blockIndex"),
                            call.requireInt("value"),
                        )
                    result.success(null)
                }
                "nfc.mifare.decrement" -> {
                    requireConnectedMifareClassic()
                        .decrement(
                            call.requireInt("blockIndex"),
                            call.requireInt("value"),
                        )
                    result.success(null)
                }
                "nfc.mifare.restore" -> {
                    requireConnectedMifareClassic()
                        .restore(call.requireInt("blockIndex"))
                    result.success(null)
                }
                "nfc.mifare.transfer" -> {
                    requireConnectedMifareClassic()
                        .transfer(call.requireInt("blockIndex"))
                    result.success(null)
                }
                "nfc.mifare.blockToSector" -> {
                    result.success(
                        requireMifareClassic()
                            .blockToSector(call.requireInt("blockIndex")),
                    )
                }
                "nfc.mifare.sectorToBlock" -> {
                    result.success(
                        requireMifareClassic()
                            .sectorToBlock(call.requireInt("sectorIndex")),
                    )
                }
                "nfc.mifare.blockCountInSector" -> {
                    result.success(
                        requireMifareClassic()
                            .getBlockCountInSector(call.requireInt("sectorIndex")),
                    )
                }
                "nfc.mifare.blockCount" -> {
                    result.success(requireMifareClassic().blockCount)
                }
                "nfc.mifare.sectorCount" -> {
                    result.success(requireMifareClassic().sectorCount)
                }
                "nfc.mifare.size" -> {
                    result.success(requireMifareClassic().size)
                }
                "nfc.mifare.type" -> {
                    result.success(requireMifareClassic().type)
                }
                "nfc.mifare.maxTransceiveLength" -> {
                    result.success(requireMifareClassic().maxTransceiveLength)
                }
                else -> result.notImplemented()
            }
        } catch (error: Throwable) {
            result.error(
                "NF5503_NFC_ERROR",
                error.message ?: error.javaClass.simpleName,
                error.javaClass.name,
            )
        }
        return true
    }

    private fun statusMap(): Map<String, Any?> {
        return linkedMapOf(
            "supported" to (adapter != null),
            "enabled" to (adapter?.isEnabled == true),
            "readerModeActive" to readerModeActive,
            "adapterState" to adapterState,
        )
    }

    private fun postStatus() {
        postEvent(
            mapOf(
                "type" to "adapterState",
                "state" to adapterState,
                "status" to statusMap(),
            ),
        )
    }

    private fun postError(message: String) {
        postEvent(
            mapOf(
                "type" to "error",
                "message" to message,
            ),
        )
    }

    private fun postEvent(event: Map<String, Any?>) {
        mainHandler.post {
            eventSink?.success(event)
        }
    }

    private fun registerAdapterStateReceiver() {
        if (adapterReceiverRegistered) {
            return
        }
        try {
            val filter = IntentFilter(NfcAdapter.ACTION_ADAPTER_STATE_CHANGED)
            if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.TIRAMISU) {
                appContext.registerReceiver(
                    adapterStateReceiver,
                    filter,
                    null,
                    mainHandler,
                    Context.RECEIVER_EXPORTED,
                )
            } else {
                @Suppress("DEPRECATION")
                appContext.registerReceiver(
                    adapterStateReceiver,
                    filter,
                    null,
                    mainHandler,
                )
            }
            adapterReceiverRegistered = true
        } catch (error: Throwable) {
            postError(error.message ?: "Unable to observe NFC adapter state.")
        }
    }

    private fun unregisterAdapterStateReceiver() {
        if (!adapterReceiverRegistered) {
            return
        }
        runCatching { appContext.unregisterReceiver(adapterStateReceiver) }
        adapterReceiverRegistered = false
    }

    private fun registerLifecycleCallbacks() {
        val application = application ?: return
        if (lifecycleRegistered.compareAndSet(false, true)) {
            application.registerActivityLifecycleCallbacks(lifecycleCallbacks)
        }
    }

    private fun unregisterLifecycleCallbacks() {
        val application = application ?: return
        if (lifecycleRegistered.compareAndSet(true, false)) {
            runCatching {
                application.unregisterActivityLifecycleCallbacks(lifecycleCallbacks)
            }
        }
    }

    private fun updateReaderMode() {
        val adapter = adapter
        val activity = activity
        val shouldEnable =
            discoveryRequested &&
                activityResumed &&
                activity != null &&
                adapter?.isEnabled == true

        if (shouldEnable == readerModeActive) {
            return
        }
        if (shouldEnable) {
            try {
                val extras =
                    Bundle().apply {
                        putInt(NfcAdapter.EXTRA_READER_PRESENCE_CHECK_DELAY, 250)
                    }
                adapter.enableReaderMode(
                    activity,
                    readerCallback,
                    READER_FLAGS,
                    extras,
                )
                readerModeActive = true
                postStatus()
            } catch (error: Throwable) {
                readerModeActive = false
                postError(error.message ?: "Unable to enable NFC Reader Mode.")
            }
        } else {
            disableReaderMode()
        }
    }

    private fun disableReaderMode() {
        if (!readerModeActive) {
            return
        }
        val adapter = adapter
        val activity = activity
        if (adapter != null && activity != null) {
            runCatching { adapter.disableReaderMode(activity) }
        }
        val hadTag = currentTag != null
        readerModeActive = false
        scheduleMifareClose()
        currentTag = null
        currentMifare = null
        postStatus()
        if (hadTag) {
            postEvent(mapOf("type" to "tagLost"))
        }
    }

    private fun handleTagDiscovered(tag: Tag) {
        runCatching {
            scheduleMifareClose()
            if (currentTag != null && currentTag !== tag) {
                // Reader Mode does not expose a reliable tag-removed callback when
                // the tag must remain available for transceive operations.
                postEvent(mapOf("type" to "tagLost"))
            }
            currentTag = tag
            currentMifare = null
            postEvent(
                mapOf(
                    "type" to "tag",
                    "tag" to tagToMap(tag),
                ),
            )
        }.onFailure {
            postError(it.message ?: "Unable to parse the discovered NFC tag.")
        }
    }

    private fun openNfcSettings() {
        mainHandler.post {
            runCatching {
                val activity = activity
                val intent = Intent(Settings.ACTION_NFC_SETTINGS)
                if (activity == null) {
                    intent.addFlags(Intent.FLAG_ACTIVITY_NEW_TASK)
                    appContext.startActivity(intent)
                } else {
                    activity.startActivity(intent)
                }
            }.onFailure {
                postError(it.message ?: "Unable to open NFC settings.")
            }
        }
    }

    private fun tagToMap(tag: Tag): Map<String, Any?> {
        val id = tag.id
        val ndef = runCatching { Ndef.get(tag) }.getOrNull()
        val ndefFormatable = runCatching { NdefFormatable.get(tag) }.getOrNull() != null
        val mifare = runCatching { MifareClassic.get(tag) }.getOrNull()

        val result = linkedMapOf<String, Any?>(
            "id" to id,
            "idHex" to bytesToHex(id),
            "techList" to tag.techList.toList(),
            "ndefFormatable" to ndefFormatable,
        )
        if (ndef != null) {
            result["ndef"] =
                linkedMapOf<String, Any?>(
                    "type" to ndef.type.orEmpty(),
                    "maxSize" to runCatching { ndef.maxSize }.getOrDefault(0),
                    "writable" to runCatching { ndef.isWritable }.getOrDefault(false),
                    "canMakeReadOnly" to
                        runCatching { ndef.canMakeReadOnly() }.getOrDefault(false),
                    "cachedMessage" to
                        runCatching { ndef.cachedNdefMessage }
                            .getOrNull()
                            ?.let(::ndefMessageToMap),
                )
        }
        if (mifare != null) {
            result["mifareClassic"] = mifareInfoToMap(mifare)
        }
        return result
    }

    private fun readNdefMessage(): Map<String, Any?>? {
        val tag = requireTag()
        val ndef = Ndef.get(tag) ?: return null
        ndef.connect()
        return try {
            ndef.ndefMessage?.let(::ndefMessageToMap)
        } finally {
            runCatching { ndef.close() }
        }
    }

    private fun writeNdefMessage(
        message: NdefMessage,
        formatIfNeeded: Boolean,
    ) {
        val tag = requireTag()
        val messageSize = message.toByteArray().size
        val ndef = Ndef.get(tag)
        if (ndef != null) {
            ndef.connect()
            try {
                if (!ndef.isWritable) {
                    throw IOException("The NFC tag is read-only.")
                }
                if (ndef.maxSize < messageSize) {
                    throw IOException(
                        "NDEF payload is too large: $messageSize > ${ndef.maxSize}.",
                    )
                }
                ndef.writeNdefMessage(message)
            } finally {
                runCatching { ndef.close() }
            }
            return
        }

        if (!formatIfNeeded) {
            throw UnsupportedOperationException(
                "The tag is not NDEF-formatted and formatIfNeeded is false.",
            )
        }
        val formatable =
            NdefFormatable.get(tag)
                ?: throw UnsupportedOperationException(
                    "The tag does not support NDEF formatting.",
                )
        formatable.connect()
        try {
            formatable.format(message)
        } finally {
            runCatching { formatable.close() }
        }
    }

    private fun makeNdefReadOnly() {
        val tag = requireTag()
        val ndef =
            Ndef.get(tag)
                ?: throw UnsupportedOperationException("The tag is not NDEF-formatted.")
        ndef.connect()
        try {
            if (!ndef.canMakeReadOnly()) {
                throw IOException("The NFC tag cannot be made read-only.")
            }
            if (!ndef.makeReadOnly()) {
                throw IOException("The NFC tag could not be made read-only.")
            }
        } finally {
            runCatching { ndef.close() }
        }
    }

    private fun requireTag(): Tag {
        return currentTag
            ?: throw IllegalStateException(
                "No NFC tag is currently available. Start discovery and place a tag near the device.",
            )
    }

    private fun requireMifareClassic(): MifareClassic {
        val cached = currentMifare
        if (cached != null) {
            return cached
        }
        val tag = requireTag()
        val card =
            MifareClassic.get(tag)
                ?: throw UnsupportedOperationException(
                    "The current tag does not expose MifareClassic.",
                )
        currentMifare = card
        return card
    }

    private fun requireConnectedMifareClassic(): MifareClassic {
        val card = requireMifareClassic()
        if (!card.isConnected) {
            card.connect()
        }
        return card
    }

    private fun closeMifareClassic() {
        val card = currentMifare ?: return
        try {
            if (card.isConnected) {
                card.close()
            }
        } finally {
            currentMifare = null
        }
    }

    private fun closeMifareQuietly() {
        runCatching { closeMifareClassic() }
    }

    private fun scheduleMifareClose(card: MifareClassic? = currentMifare) {
        if (card == null) {
            return
        }
        try {
            nfcExecutor.execute {
                runCatching {
                    if (card.isConnected) {
                        card.close()
                    }
                }
                if (currentMifare === card) {
                    currentMifare = null
                }
            }
        } catch (_: RejectedExecutionException) {
            runCatching {
                if (card.isConnected) {
                    card.close()
                }
            }
            if (currentMifare === card) {
                currentMifare = null
            }
        }
    }

    private fun mifareInfoMapOrNull(): Map<String, Any?>? {
        return runCatching { requireMifareClassic() }
            .getOrNull()
            ?.let(::mifareInfoToMap)
    }

    private fun mifareInfoToMap(card: MifareClassic): Map<String, Any?> {
        return linkedMapOf(
            "type" to card.type,
            "size" to card.size,
            "sectorCount" to card.sectorCount,
            "blockCount" to card.blockCount,
            "maxTransceiveLength" to card.maxTransceiveLength,
        )
    }

    private fun ndefMessageToMap(message: NdefMessage): Map<String, Any?> {
        val records = message.records
        return linkedMapOf(
            "rawData" to message.toByteArray(),
            "records" to
                records.mapIndexed { index, record ->
                    ndefRecordToMap(index, record)
                },
        )
    }

    private fun ndefRecordToMap(
        index: Int,
        record: NdefRecord,
    ): Map<String, Any?> {
        val typeName = String(record.type, Charsets.US_ASCII)
        var text: String? = null
        var uri: String? = null
        var mimeType: String? = null
        var languageCode: String? = null

        when {
            record.tnf == NdefRecord.TNF_WELL_KNOWN &&
                record.type.contentEquals(NdefRecord.RTD_TEXT) -> {
                val parsed = parseNdefTextPayload(record.payload)
                text = parsed?.text
                languageCode = parsed?.languageCode
            }
            record.tnf == NdefRecord.TNF_WELL_KNOWN &&
                record.type.contentEquals(NdefRecord.RTD_URI) -> {
                uri = runCatching { record.toUri()?.toString() }.getOrNull()
                text = uri
            }
            record.tnf == NdefRecord.TNF_MIME_MEDIA -> {
                mimeType = typeName
            }
            record.tnf == NdefRecord.TNF_ABSOLUTE_URI -> {
                uri = String(record.payload, Charsets.UTF_8)
                text = uri
            }
            record.tnf == NdefRecord.TNF_WELL_KNOWN &&
                record.type.contentEquals(NdefRecord.RTD_SMART_POSTER) -> {
                text =
                    runCatching {
                        NdefMessage(record.payload)
                            .records
                            .firstNotNullOfOrNull { nested ->
                                when {
                                    nested.tnf == NdefRecord.TNF_WELL_KNOWN &&
                                        nested.type.contentEquals(NdefRecord.RTD_URI) ->
                                        nested.toUri()?.toString()
                                    nested.tnf == NdefRecord.TNF_WELL_KNOWN &&
                                        nested.type.contentEquals(NdefRecord.RTD_TEXT) ->
                                        parseNdefTextPayload(nested.payload)?.text
                                    else -> null
                                }
                            }
                    }.getOrNull()
            }
        }

        return linkedMapOf<String, Any?>(
            "index" to index,
            "tnf" to record.tnf,
            "type" to record.type,
            "id" to record.id,
            "payload" to record.payload,
            "typeName" to typeName,
            "text" to text,
            "uri" to uri,
            "mimeType" to mimeType,
            "languageCode" to languageCode,
        )
    }
}

internal data class NdefTextPayload(
    val text: String,
    val languageCode: String,
)

/** Parses the payload of an NDEF RTD_TEXT record. */
internal fun parseNdefTextPayload(payload: ByteArray): NdefTextPayload? {
    if (payload.isEmpty()) {
        return null
    }
    val status = payload[0].toInt() and 0xFF
    val languageLength = status and 0x3F
    val textOffset = 1 + languageLength
    if (textOffset > payload.size) {
        return null
    }
    val charset =
        if (status and 0x80 != 0) {
            Charsets.UTF_16
        } else {
            Charsets.UTF_8
        }
    val languageCode =
        String(payload, 1, languageLength, Charsets.US_ASCII)
    val text =
        String(
            payload,
            textOffset,
            payload.size - textOffset,
            charset,
        )
    return NdefTextPayload(text = text, languageCode = languageCode)
}

/** Uppercase hexadecimal representation used by NFC tag events. */
internal fun bytesToHex(bytes: ByteArray): String {
    val digits = "0123456789ABCDEF"
    val output = StringBuilder(bytes.size * 2)
    for (byte in bytes) {
        val value = byte.toInt() and 0xFF
        output.append(digits[value ushr 4])
        output.append(digits[value and 0x0F])
    }
    return output.toString()
}

private fun MethodCall.requireString(name: String): String {
    return argument<String>(name) ?: throw IllegalArgumentException("$name is required.")
}

private fun MethodCall.requireInt(name: String): Int {
    val value = argument<Any>(name) ?: throw IllegalArgumentException("$name is required.")
    return when (value) {
        is Int -> value
        is Long -> value.toInt()
        is Number -> value.toInt()
        else -> value.toString().toInt()
    }
}

private fun MethodCall.requireBool(name: String): Boolean {
    return argument<Boolean>(name)
        ?: throw IllegalArgumentException("$name is required.")
}

private fun MethodCall.requireBytes(name: String): ByteArray {
    return argument<ByteArray>(name)
        ?: throw IllegalArgumentException("$name is required.")
}

private const val STATE_UNKNOWN = -1
private const val MIFARE_KEY_A = 0
private const val MIFARE_KEY_B = 1
private const val MIFARE_KEY_LENGTH = 6
private const val MIFARE_BLOCK_LENGTH = 16
private const val READER_FLAGS =
    NfcAdapter.FLAG_READER_NFC_A or
        NfcAdapter.FLAG_READER_NFC_B or
        NfcAdapter.FLAG_READER_NFC_F or
        NfcAdapter.FLAG_READER_NFC_V or
        NfcAdapter.FLAG_READER_NFC_BARCODE
