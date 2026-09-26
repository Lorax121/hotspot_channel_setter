package com.example.wifi_channel_setter

import android.os.Build
import androidx.annotation.Keep
import kotlin.system.exitProcess

/**
 * Entry point for root mode, started as
 *
 * su -c "app_process -Djava.class.path=<apk> /system/bin
 *        com.example.wifi_channel_setter.RootChannelSetter <frequency>"
 *
 * It stores the channel in the SoftAP configuration, so unlike
 * "cmd wifi force-softap-channel" the choice survives a reboot.
 */
@Keep
object RootChannelSetter {
    @JvmStatic
    @Keep
    fun main(args: Array<String>) {
        if (Build.VERSION.SDK_INT < Build.VERSION_CODES.R) {
            println("error: storing the channel requires Android 11 or newer")
            exitProcess(EXIT_UNSUPPORTED)
        }

        try {
            val argument = args.firstOrNull()
            when {
                // Without arguments the helper reports the stored configuration.
                argument == null -> println(SoftApChannelConfig.describeStored())
                argument.equals("auto", ignoreCase = true) ->
                    println(SoftApChannelConfig.resetToAuto())
                else -> {
                    val frequency = argument.toIntOrNull()
                        ?: error("Invalid argument: $argument")
                    println(SoftApChannelConfig.apply(frequency))
                }
            }
            exitProcess(0)
        } catch (error: Throwable) {
            val reason = (error.cause ?: error).message ?: error.javaClass.simpleName
            println("error: $reason")
            exitProcess(EXIT_FAILED)
        }
    }

    private const val EXIT_FAILED = 1
    private const val EXIT_UNSUPPORTED = 3
}
