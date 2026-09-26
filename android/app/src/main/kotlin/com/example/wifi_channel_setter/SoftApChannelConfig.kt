package com.example.wifi_channel_setter

import android.net.wifi.SoftApConfiguration
import android.os.IBinder
import android.os.Process
import android.os.SystemClock
import android.util.SparseIntArray

/**
 * Reads and writes the stored SoftAP configuration through the Wi-Fi framework.
 *
 * The shell user (uid 2000) and root (uid 0) are allowed to do this, while
 * "cmd wifi force-softap-channel" has been limited to root since Android 12. The channel written
 * here is the one the system hotspot uses and it survives a reboot, unlike the forced channel of
 * the shell command which only applies to the next hotspot start.
 */
object SoftApChannelConfig {
    private const val WIFI_SERVICE_NAME = "wifi"
    private const val SHELL_PACKAGE_NAME = "com.android.shell"
    private const val ROOT_PACKAGE_NAME = "root"
    private const val UID_ROOT = 0
    private const val UID_SHELL = 2000
    private const val STORE_SETTLE_TIMEOUT_MILLIS = 1500L
    private const val STORE_SETTLE_POLL_MILLIS = 150L

    /** Channel of the stored configuration, in the same form the framework dump uses. */
    fun describeStored(): String {
        val stored = storedChannels().firstOrNull { it.second != 0 }
            ?: return "Channels = {1=0}"

        return "Channels = {${stored.first}=${stored.second}}"
    }

    fun apply(frequency: Int, fallbackPackageName: String? = null): String {
        val service = wifiService()
        val current = read(service)
            ?: error("Stored SoftAP configuration is unavailable")
        val updated = withChannel(current, frequency)
            ?: error("Unsupported frequency: $frequency MHz")

        if (!store(service, updated, packageNameFor(fallbackPackageName))) {
            error("The system rejected the new SoftAP configuration")
        }

        // The framework stores the configuration on its own thread, so wait until it is visible
        // instead of reporting success for a value the next read would not show yet.
        awaitStoredChannel(channelOf(frequency))

        return "channel ${channelOf(frequency)} (${frequency} MHz) stored in the SoftAP configuration"
    }

    /** Hands the channel back to the device, so it picks one by itself when the hotspot starts. */
    fun resetToAuto(fallbackPackageName: String? = null): String {
        val service = wifiService()
        val current = read(service)
            ?: error("Stored SoftAP configuration is unavailable")
        val band = storedChannels().firstOrNull()?.first ?: SoftApConfiguration.BAND_2GHZ
        val updated = withAutoChannel(current, band)
            ?: error("This Android version cannot restore the automatic channel")

        if (!store(service, updated, packageNameFor(fallbackPackageName))) {
            error("The system rejected the new SoftAP configuration")
        }

        awaitStoredChannel(0)
        return "automatic channel restored"
    }

    private fun withAutoChannel(
        current: SoftApConfiguration,
        band: Int,
    ): SoftApConfiguration? = runCatching {
        val builderClass = SoftApConfiguration.Builder::class.java
        val builder = builderClass
            .getDeclaredConstructor(SoftApConfiguration::class.java)
            .newInstance(current)

        val channels = SparseIntArray(1)
        channels.put(band, 0)
        builderClass
            .getMethod("setChannels", SparseIntArray::class.java)
            .invoke(builder, channels)

        builderClass.getMethod("build").invoke(builder) as SoftApConfiguration
    }.getOrNull()

    private fun awaitStoredChannel(channel: Int) {
        val deadline = SystemClock.elapsedRealtime() + STORE_SETTLE_TIMEOUT_MILLIS
        while (SystemClock.elapsedRealtime() < deadline) {
            if (storedChannelNumber() == channel) return
            Thread.sleep(STORE_SETTLE_POLL_MILLIS)
        }
    }

    private fun storedChannelNumber(): Int =
        storedChannels().firstOrNull { it.second != 0 }?.second ?: 0

    private fun storedChannels(): List<Pair<Int, Int>> {
        val config = runCatching { read(wifiService()) }.getOrNull() ?: return emptyList()

        val channels = runCatching {
            config.javaClass.getMethod("getChannels").invoke(config) as? SparseIntArray
        }.getOrNull()
        if (channels != null) {
            return (0 until channels.size()).map {
                channels.keyAt(it) to channels.valueAt(it)
            }
        }

        val channel = runCatching {
            config.javaClass.getMethod("getChannel").invoke(config) as? Int
        }.getOrNull() ?: return emptyList()
        val band = runCatching {
            config.javaClass.getMethod("getBand").invoke(config) as? Int
        }.getOrNull() ?: return emptyList()

        return listOf(band to channel)
    }

    private fun frequencyOf(band: Int, channel: Int): Int = when (band) {
        SoftApConfiguration.BAND_2GHZ -> if (channel == 14) 2484 else 2407 + 5 * channel
        SoftApConfiguration.BAND_5GHZ -> 5000 + 5 * channel
        else -> 0
    }

    private fun wifiService(): Any {
        val binder = Class.forName("android.os.ServiceManager")
            .getMethod("getService", String::class.java)
            .invoke(null, WIFI_SERVICE_NAME) as? IBinder
            ?: error("Wi-Fi service is not running")

        return Class.forName("android.net.wifi.IWifiManager\$Stub")
            .getMethod("asInterface", IBinder::class.java)
            .invoke(null, binder)
            ?: error("Wi-Fi service is not available")
    }

    private fun read(service: Any): SoftApConfiguration? = iWifiManager()
        .getMethod("getSoftApConfiguration")
        .invoke(service) as? SoftApConfiguration

    private fun store(
        service: Any,
        configuration: SoftApConfiguration,
        packageName: String,
    ): Boolean = iWifiManager()
        .getMethod(
            "setSoftApConfiguration",
            SoftApConfiguration::class.java,
            String::class.java,
        )
        .invoke(service, configuration, packageName) as Boolean

    private fun iWifiManager(): Class<*> = Class.forName("android.net.wifi.IWifiManager")

    private fun withChannel(
        current: SoftApConfiguration,
        frequency: Int,
    ): SoftApConfiguration? {
        val channel = channelOf(frequency)
        val band = bandOf(frequency)
        if (channel == 0 || band == 0) return null

        val builderClass = SoftApConfiguration.Builder::class.java
        val builder = builderClass
            .getDeclaredConstructor(SoftApConfiguration::class.java)
            .newInstance(current)

        builderClass
            .getMethod("setChannel", Int::class.javaPrimitiveType, Int::class.javaPrimitiveType)
            .invoke(builder, channel, band)

        return builderClass.getMethod("build").invoke(builder) as SoftApConfiguration
    }

    private fun packageNameFor(fallbackPackageName: String?): String = when (Process.myUid()) {
        UID_SHELL -> SHELL_PACKAGE_NAME
        UID_ROOT -> ROOT_PACKAGE_NAME
        else -> fallbackPackageName ?: SHELL_PACKAGE_NAME
    }

    private fun bandOf(frequency: Int): Int = when {
        frequency in 2400..2500 -> SoftApConfiguration.BAND_2GHZ
        frequency in 5150..5895 -> SoftApConfiguration.BAND_5GHZ
        frequency >= 5925 -> SoftApConfiguration.BAND_6GHZ
        else -> 0
    }

    private fun channelOf(frequency: Int): Int = when {
        frequency == 2484 -> 14
        frequency in 2412..2472 -> (frequency - 2412) / 5 + 1
        frequency % 5 == 0 -> (frequency - 5000) / 5
        else -> 0
    }
}
