package com.example.wifi_channel_setter

import android.content.Context
import android.net.wifi.SoftApConfiguration
import android.net.wifi.WifiManager
import java.lang.reflect.Proxy
import java.util.concurrent.CountDownLatch
import java.util.concurrent.Executor
import java.util.concurrent.TimeUnit
import java.util.concurrent.atomic.AtomicReference

/**
 * Reads the channel list the framework received from the Wi-Fi HAL for the hotspot.
 *
 * Registering a soft AP callback delivers the capability right away, without the hotspot being
 * started, and it works from Android 11. "cmd wifi get-allowed-channel" exists only from Android 14
 * and the framework dump prints the capability only from Android 13, so this is the only source
 * that covers Android 11 and 12 with the shell identity Shizuku provides.
 */
object SoftApCapabilityReader {
    private const val CALLBACK_TIMEOUT_MILLIS = 2000L

    fun describeSupportedChannels(context: Context): String {
        val wifiManager = context.getSystemService(Context.WIFI_SERVICE) as? WifiManager
            ?: error("Wi-Fi service is unavailable")

        val capability = readCapability(wifiManager)
        val frequencies = supportedFrequencies(capability)
        if (frequencies.isEmpty()) {
            error("The device reported no hotspot channels")
        }

        return "Allowed ch in SAP mode:\n" + frequencies.joinToString(" ")
    }

    private fun readCapability(wifiManager: WifiManager): Any {
        val callbackClass = Class.forName("android.net.wifi.WifiManager\$SoftApCallback")
        val capability = AtomicReference<Any?>()
        val delivered = CountDownLatch(1)

        val callback = Proxy.newProxyInstance(
            callbackClass.classLoader,
            arrayOf(callbackClass),
        ) { _, method, arguments ->
            if (method.name == "onCapabilityChanged") {
                capability.compareAndSet(null, arguments?.firstOrNull())
                delivered.countDown()
            }
            null
        }

        val register = WifiManager::class.java.getMethod(
            "registerSoftApCallback",
            Executor::class.java,
            callbackClass,
        )
        val unregister = WifiManager::class.java.getMethod(
            "unregisterSoftApCallback",
            callbackClass,
        )

        register.invoke(wifiManager, Executor { it.run() }, callback)
        try {
            if (!delivered.await(CALLBACK_TIMEOUT_MILLIS, TimeUnit.MILLISECONDS)) {
                error("The system did not report the hotspot capabilities")
            }
        } finally {
            runCatching { unregister.invoke(wifiManager, callback) }
        }

        return capability.get() ?: error("The system returned no hotspot capabilities")
    }

    private fun supportedFrequencies(capability: Any): List<Int> {
        val method = capability.javaClass.getMethod(
            "getSupportedChannelList",
            Int::class.javaPrimitiveType,
        )
        val frequencies = mutableListOf<Int>()

        for (band in intArrayOf(SoftApConfiguration.BAND_2GHZ, SoftApConfiguration.BAND_5GHZ)) {
            val channels = runCatching { method.invoke(capability, band) as? IntArray }
                .getOrNull() ?: continue

            for (channel in channels) {
                val frequency = frequencyOf(band, channel)
                if (frequency > 0) frequencies.add(frequency)
            }
        }

        return frequencies
    }

    private fun frequencyOf(band: Int, channel: Int): Int = when (band) {
        SoftApConfiguration.BAND_2GHZ -> if (channel == 14) 2484 else 2407 + 5 * channel
        SoftApConfiguration.BAND_5GHZ -> 5000 + 5 * channel
        else -> 0
    }
}
