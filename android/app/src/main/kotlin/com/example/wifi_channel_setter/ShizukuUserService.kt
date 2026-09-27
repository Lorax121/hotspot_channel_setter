package com.example.wifi_channel_setter

import android.content.Context
import android.os.Build
import android.os.Bundle
import androidx.annotation.Keep
import java.io.File
import java.util.concurrent.Callable
import java.util.concurrent.Executors
import java.util.concurrent.TimeUnit

@Keep
class ShizukuUserService : IShizukuUserService.Stub {
    private var context: Context? = null

    @Keep
    constructor()

    @Keep
    constructor(context: Context) {
        this.context = context
    }

    override fun getAllowedChannels(timeoutMillis: Long): Bundle {
        val serviceContext = context
            ?: return commandResult(
                exitCode = EXECUTION_ERROR_EXIT_CODE,
                stderr = "The Android context is unavailable",
            )

        return try {
            commandResult(
                exitCode = 0,
                stdout = SoftApCapabilityReader.describeSupportedChannels(serviceContext),
            )
        } catch (error: Throwable) {
            val cause = error.cause ?: error
            val fallback = standardChannelList()
            if (fallback != null) {
                commandResult(exitCode = 0, stdout = fallback)
            } else {
                commandResult(
                    exitCode = EXECUTION_ERROR_EXIT_CODE,
                    stderr = cause.message ?: cause.javaClass.simpleName,
                )
            }
        }
    }

    override fun getSoftApCapability(timeoutMillis: Long): Bundle = execute(
        command = listOf(SH_EXECUTABLE, "-c", SOFT_AP_CAPABILITY_COMMAND),
        timeoutMillis = timeoutMillis,
    )

    override fun getSoftApState(timeoutMillis: Long): Bundle = try {
        commandResult(exitCode = 0, stdout = SoftApChannelConfig.describeStored())
    } catch (error: Throwable) {
        commandResult(
            exitCode = EXECUTION_ERROR_EXIT_CODE,
            stderr = (error.cause ?: error).message ?: error.javaClass.simpleName,
        )
    }

    override fun resetChannel(timeoutMillis: Long): Bundle = try {
        commandResult(exitCode = 0, stdout = SoftApChannelConfig.resetToAuto())
    } catch (error: Throwable) {
        commandResult(
            exitCode = EXECUTION_ERROR_EXIT_CODE,
            stderr = (error.cause ?: error).message ?: error.javaClass.simpleName,
        )
    }

    override fun setChannel(frequency: Int, timeoutMillis: Long, persistent: Boolean): Bundle {
        if (frequency !in MIN_WIFI_FREQUENCY_MHZ..MAX_WIFI_FREQUENCY_MHZ) {
            return commandResult(
                exitCode = INVALID_ARGUMENT_EXIT_CODE,
                stderr = "Invalid Wi-Fi frequency: $frequency MHz",
            )
        }

        if (!persistent) {
            return forceSoftApChannel(frequency, timeoutMillis)
        }

        if (Build.VERSION.SDK_INT < Build.VERSION_CODES.R) {
            return commandResult(
                exitCode = UNSUPPORTED_EXIT_CODE,
                stderr = "Storing the channel requires Android 11 or newer",
            )
        }

        return try {
            commandResult(exitCode = 0, stdout = SoftApChannelConfig.apply(frequency))
        } catch (error: Throwable) {
            commandResult(
                exitCode = EXECUTION_ERROR_EXIT_CODE,
                stderr = (error.cause ?: error).message ?: error.javaClass.simpleName,
            )
        }
    }

    private fun forceSoftApChannel(frequency: Int, timeoutMillis: Long): Bundle = execute(
        command = listOf(
            CMD_EXECUTABLE,
            "wifi",
            "force-softap-channel",
            "enabled",
            frequency.toString(),
        ),
        timeoutMillis = timeoutMillis,
    )

    /**
     * Android 11 does not always report the hotspot capabilities and has no other source, so the
     * channels almost every hotspot-capable device offers are used, marked as the standard list.
     */
    private fun standardChannelList(): String? {
        if (Build.VERSION.SDK_INT != Build.VERSION_CODES.R) return null

        return buildString {
            append(STANDARD_LIST_MARKER)
            append('\n')
            append(SOFT_AP_CHANNEL_LIST_HEADER)
            append('\n')
            append(STANDARD_CHANNEL_FREQUENCIES.joinToString(" "))
        }
    }

    override fun destroy() {
        System.exit(0)
    }

    private fun execute(
        command: List<String>,
        timeoutMillis: Long,
    ): Bundle {
        var process: Process? = null

        return try {
            process = ProcessBuilder(command).start()
            val stdoutFuture = streamExecutor.submit(Callable {
                process.inputStream.bufferedReader().use { it.readText() }
            })
            val stderrFuture = streamExecutor.submit(Callable {
                process.errorStream.bufferedReader().use { it.readText() }
            })

            val completed = process.waitFor(timeoutMillis, TimeUnit.MILLISECONDS)
            if (!completed) {
                process.destroyForcibly()
                commandResult(
                    exitCode = TIMEOUT_EXIT_CODE,
                    stderr = "Command timed out after $timeoutMillis ms",
                    timedOut = true,
                )
            } else {
                commandResult(
                    exitCode = process.exitValue(),
                    stdout = stdoutFuture.get(STREAM_DRAIN_TIMEOUT_SECONDS, TimeUnit.SECONDS),
                    stderr = stderrFuture.get(STREAM_DRAIN_TIMEOUT_SECONDS, TimeUnit.SECONDS),
                )
            }
        } catch (error: Throwable) {
            process?.destroyForcibly()
            commandResult(
                exitCode = EXECUTION_ERROR_EXIT_CODE,
                stderr = error.message ?: error.javaClass.simpleName,
            )
        }
    }

    private fun commandResult(
        exitCode: Int,
        stdout: String = "",
        stderr: String = "",
        timedOut: Boolean = false,
    ) = Bundle().apply {
        putInt(KEY_EXIT_CODE, exitCode)
        putString(KEY_STDOUT, stdout)
        putString(KEY_STDERR, stderr)
        putBoolean(KEY_TIMED_OUT, timedOut)
    }

    private companion object {
        const val KEY_EXIT_CODE = "exitCode"
        const val KEY_STDOUT = "stdout"
        const val KEY_STDERR = "stderr"
        const val KEY_TIMED_OUT = "timedOut"

        const val MIN_WIFI_FREQUENCY_MHZ = 2300
        const val MAX_WIFI_FREQUENCY_MHZ = 5900
        const val CMD_EXECUTABLE = "/system/bin/cmd"
        const val SH_EXECUTABLE = "/system/bin/sh"
        const val SOFT_AP_CAPABILITY_COMMAND =
            "dumpsys wifi 2>/dev/null | grep mCurrentSoftApCapability | head -n 1"
        const val INVALID_ARGUMENT_EXIT_CODE = 2
        const val UNSUPPORTED_EXIT_CODE = 3
        const val TIMEOUT_EXIT_CODE = 124
        const val EXECUTION_ERROR_EXIT_CODE = 126
        const val STREAM_DRAIN_TIMEOUT_SECONDS = 2L

        const val STANDARD_LIST_MARKER = "standard"
        const val SOFT_AP_CHANNEL_LIST_HEADER = "Allowed ch in SAP mode:"

        val STANDARD_CHANNEL_FREQUENCIES = intArrayOf(
            2412, 2417, 2422, 2427, 2432, 2437, 2442, 2447, 2452, 2457, 2462, 2467, 2472,
            5180, 5200, 5220, 5240, 5260, 5280, 5300, 5320,
            5500, 5520, 5540, 5560, 5580, 5600, 5620, 5640, 5660, 5680, 5700,
            5745, 5765, 5785, 5805, 5825,
        )

        val streamExecutor = Executors.newCachedThreadPool()
    }
}
