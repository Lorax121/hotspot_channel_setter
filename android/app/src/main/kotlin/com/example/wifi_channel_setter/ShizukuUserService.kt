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
    @Keep
    constructor()

    @Keep
    @Suppress("UNUSED_PARAMETER")
    constructor(context: Context)

    override fun getIwList(timeoutMillis: Long): Bundle = execute(
        command = listOf(findIwExecutable(), "list"),
        timeoutMillis = timeoutMillis,
    )

    override fun getAllowedChannels(timeoutMillis: Long): Bundle = execute(
        command = listOf(CMD_EXECUTABLE, "wifi", "get-allowed-channel"),
        timeoutMillis = timeoutMillis,
    )

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

    private fun findIwExecutable(): String = IW_EXECUTABLE_CANDIDATES
        .firstOrNull { File(it).canExecute() }
        ?: "iw"

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

        val IW_EXECUTABLE_CANDIDATES = listOf(
            "/system/bin/iw",
            "/vendor/bin/iw",
            "/system/xbin/iw",
        )

        val streamExecutor = Executors.newCachedThreadPool()
    }
}
