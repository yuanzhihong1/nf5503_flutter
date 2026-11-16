package com.m5stack.nf5503_flutter

import io.flutter.plugin.common.MethodCall
import io.flutter.plugin.common.MethodChannel
import java.nio.charset.Charset
import org.mockito.Mockito
import kotlin.test.Test
import kotlin.test.assertEquals
import kotlin.test.assertFailsWith

internal class Nf5503FlutterPluginTest {
    @Test
    fun concentrationToNative_matchesSdkMapping() {
        assertEquals(1, concentrationToNative(1))
        assertEquals(1, concentrationToNative(3))
        assertEquals(2, concentrationToNative(4))
        assertEquals(2, concentrationToNative(7))
        assertEquals(3, concentrationToNative(8))
        assertEquals(9, concentrationToNative(35))
        assertEquals(10, concentrationToNative(36))
        assertEquals(10, concentrationToNative(39))
    }

    @Test
    fun concentrationToNative_rejectsValuesOutsideSdkRange() {
        assertFailsWith<IllegalArgumentException> { concentrationToNative(0) }
        assertFailsWith<IllegalArgumentException> { concentrationToNative(40) }
    }

    @Test
    fun decodeScanBytes_matchesEveryOfficialEncodingMode() {
        val text = "NF5503-扫码"
        assertEquals(text, decodeScanBytes(text.toByteArray(Charsets.UTF_8), 0))
        assertEquals("ASCII", decodeScanBytes("ASCII".toByteArray(Charsets.US_ASCII), 1))
        assertEquals(text, decodeScanBytes(text.toByteArray(Charset.forName("GBK")), 2))
        assertEquals(text, decodeScanBytes(text.toByteArray(Charset.forName("GB2312")), 3))
        assertEquals(text, decodeScanBytes(text.toByteArray(Charset.forName("GB18030")), 4))
        assertEquals(text, decodeScanBytes(text.toByteArray(Charsets.UTF_16), 5))
        assertEquals("ISO", decodeScanBytes("ISO".toByteArray(Charsets.ISO_8859_1), 6))
    }

    @Test
    fun scanBroadcastDefaults_matchOfficialScanConfig() {
        assertEquals("scan.rcv.message", DEFAULT_SCAN_ACTION)
        assertEquals("barcodeData", DEFAULT_SCAN_KEY)
    }

    @Test
    fun onMethodCall_getPlatformVersion_returnsExpectedValue() {
        val plugin = Nf5503FlutterPlugin()

        val call = MethodCall("getPlatformVersion", null)
        val mockResult: MethodChannel.Result = Mockito.mock(MethodChannel.Result::class.java)
        plugin.onMethodCall(call, mockResult)

        Mockito.verify(mockResult, Mockito.timeout(1000))
            .success("Android " + android.os.Build.VERSION.RELEASE)
    }
}
