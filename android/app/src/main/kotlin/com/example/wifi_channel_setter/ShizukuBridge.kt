package com.example.wifi_channel_setter

import android.content.ComponentName
import android.content.ServiceConnection
import android.content.pm.PackageManager
import android.os.IBinder
import io.flutter.plugin.common.BinaryMessenger
import io.flutter.plugin.common.MethodCall
import io.flutter.plugin.common.MethodChannel
import rikka.shizuku.Shizuku
import java.util.ArrayDeque
import java.util.concurrent.Executors

class ShizukuBridge(
    private val activity: MainActivity,
    binaryMessenger: BinaryMessenger,
) : MethodChannel.MethodCallHandler {
    private val channel = MethodChannel(binaryMessenger, CHANNEL_NAME)
    private val commandExecutor = Executors.newSingleThreadExecutor()
    private val pendingOperations = ArrayDeque<PendingOperation>()

    private var userService: IShizukuUserService? = null
    private var isBindingUserService = false
    private var permissionRequest: MethodChannel.Result? = null
    private var disposed = false

    private val permissionResultListener =
        Shizuku.OnRequestPermissionResultListener { requestCode, grantResult ->
            if (requestCode != PERMISSION_REQUEST_CODE) return@OnRequestPermissionResultListener

            val request = permissionRequest ?: return@OnRequestPermissionResultListener
            permissionRequest = null

            if (grantResult == PackageManager.PERMISSION_GRANTED) {
                request.success(true)
            } else {
                request.error(
                    ERROR_PERMISSION_DENIED,
                    "Shizuku permission was denied",
                    null,
                )
            }
        }

    private val binderDeadListener = Shizuku.OnBinderDeadListener {
        userService = null
        isBindingUserService = false
        failPendingOperations(
            code = ERROR_NOT_RUNNING,
            message = "Shizuku stopped while a command was pending",
        )
    }

    private val userServiceConnection = object : ServiceConnection {
        override fun onServiceConnected(componentName: ComponentName, binder: IBinder?) {
            isBindingUserService = false
            if (binder == null || !binder.pingBinder()) {
                failPendingOperations(
                    code = ERROR_SERVICE_CONNECTION,
                    message = "Shizuku returned an invalid UserService binder",
                )
                return
            }

            userService = IShizukuUserService.Stub.asInterface(binder)
            drainPendingOperations()
        }

        override fun onServiceDisconnected(componentName: ComponentName) {
            userService = null
            isBindingUserService = false
        }
    }

    private val userServiceArgs by lazy {
        Shizuku.UserServiceArgs(
            ComponentName(activity.packageName, ShizukuUserService::class.java.name),
        )
            .tag(USER_SERVICE_TAG)
            .daemon(false)
            .processNameSuffix("shizuku")
            .debuggable(BuildConfig.DEBUG)
            .version(BuildConfig.VERSION_CODE)
    }

    init {
        channel.setMethodCallHandler(this)
        // Shizuku throws when its binder has not been received, for example when Shizuku is not
        // installed at all. Root mode has to keep working in that case.
        runCatching { Shizuku.addBinderDeadListener(binderDeadListener) }
        runCatching { Shizuku.addRequestPermissionResultListener(permissionResultListener) }
    }

    override fun onMethodCall(call: MethodCall, result: MethodChannel.Result) {
        when (call.method) {
            METHOD_GET_STATUS -> result.success(status())
            METHOD_REQUEST_PERMISSION -> requestPermission(result)
            METHOD_GET_APP_INFO -> result.success(
                mapOf(
                    "packageName" to activity.packageName,
                    "sourceDir" to activity.applicationInfo.sourceDir,
                ),
            )
            METHOD_GET_IW_LIST -> execute(Operation.GetIwList, result)
            METHOD_GET_ALLOWED_CHANNELS -> execute(Operation.GetAllowedChannels, result)
            METHOD_GET_SOFT_AP_CAPABILITY -> execute(Operation.GetSoftApCapability, result)
            METHOD_GET_SOFT_AP_STATE -> execute(Operation.GetSoftApState, result)
            METHOD_RESET_CHANNEL -> execute(Operation.ResetChannel, result)
            METHOD_SET_CHANNEL -> {
                val frequency = call.argument<Int>(ARG_FREQUENCY)
                if (frequency == null || frequency !in MIN_WIFI_FREQUENCY_MHZ..MAX_WIFI_FREQUENCY_MHZ) {
                    result.error(ERROR_INVALID_ARGUMENT, "Invalid Wi-Fi frequency", frequency)
                    return
                }
                val persistent = call.argument<Boolean>(ARG_PERSISTENT) ?: true
                execute(Operation.SetChannel(frequency, persistent), result)
            }
            else -> result.notImplemented()
        }
    }

    fun dispose() {
        if (disposed) return
        disposed = true
        channel.setMethodCallHandler(null)
        runCatching { Shizuku.removeBinderDeadListener(binderDeadListener) }
        runCatching { Shizuku.removeRequestPermissionResultListener(permissionResultListener) }
        failPendingOperations(ERROR_DISPOSED, "Android bridge was disposed")
        commandExecutor.shutdownNow()
    }

    private fun status(): Map<String, Any> {
        val running = runCatching { Shizuku.pingBinder() }.getOrDefault(false)
        val authorized = running && runCatching {
            !Shizuku.isPreV11() &&
                Shizuku.checkSelfPermission() == PackageManager.PERMISSION_GRANTED
        }.getOrDefault(false)

        return mapOf(
            "installed" to isShizukuInstalled(),
            "running" to running,
            "authorized" to authorized,
            "uid" to (if (running) runCatching { Shizuku.getUid() }.getOrDefault(-1) else -1),
        )
    }

    private fun execute(operation: Operation, result: MethodChannel.Result) {
        if (disposed) {
            result.error(ERROR_DISPOSED, "Android bridge was disposed", null)
            return
        }

        if (!runCatching { Shizuku.pingBinder() }.getOrDefault(false)) {
            result.error(
                if (isShizukuInstalled()) ERROR_NOT_RUNNING else ERROR_NOT_INSTALLED,
                if (isShizukuInstalled()) "Shizuku is not running" else "Shizuku is not installed",
                null,
            )
            return
        }

        try {
            if (Shizuku.isPreV11()) {
                result.error(ERROR_UNSUPPORTED, "Shizuku versions before 11 are unsupported", null)
                return
            }

            if (Shizuku.checkSelfPermission() == PackageManager.PERMISSION_GRANTED) {
                enqueueForUserService(PendingOperation(operation, result))
            } else {
                result.error(
                    ERROR_PERMISSION_DENIED,
                    "Shizuku permission was not granted",
                    null,
                )
            }
        } catch (error: Throwable) {
            result.error(
                ERROR_EXECUTION,
                error.message ?: error.javaClass.simpleName,
                null,
            )
        }
    }

    private fun requestPermission(result: MethodChannel.Result) {
        if (disposed) {
            result.error(ERROR_DISPOSED, "Android bridge was disposed", null)
            return
        }

        if (!runCatching { Shizuku.pingBinder() }.getOrDefault(false)) {
            val installed = isShizukuInstalled()
            result.error(
                if (installed) ERROR_NOT_RUNNING else ERROR_NOT_INSTALLED,
                if (installed) "Shizuku is not running" else "Shizuku is not installed",
                null,
            )
            return
        }

        try {
            if (Shizuku.isPreV11()) {
                result.error(ERROR_UNSUPPORTED, "Shizuku versions before 11 are unsupported", null)
                return
            }

            when {
                Shizuku.checkSelfPermission() == PackageManager.PERMISSION_GRANTED -> {
                    result.success(true)
                }
                Shizuku.shouldShowRequestPermissionRationale() -> {
                    result.error(ERROR_PERMISSION_DENIED, "Shizuku permission was denied", null)
                }
                permissionRequest != null -> {
                    result.error(ERROR_BUSY, "A Shizuku permission request is already active", null)
                }
                else -> {
                    permissionRequest = result
                    Shizuku.requestPermission(PERMISSION_REQUEST_CODE)
                }
            }
        } catch (error: Throwable) {
            if (permissionRequest === result) {
                permissionRequest = null
            }
            result.error(
                ERROR_EXECUTION,
                error.message ?: error.javaClass.simpleName,
                null,
            )
        }
    }

    private fun enqueueForUserService(operation: PendingOperation) {
        val service = userService
        if (service != null && service.asBinder().pingBinder()) {
            runOperation(service, operation)
            return
        }

        userService = null
        pendingOperations.addLast(operation)
        if (isBindingUserService) return

        isBindingUserService = true
        try {
            Shizuku.bindUserService(userServiceArgs, userServiceConnection)
        } catch (error: Throwable) {
            isBindingUserService = false
            failPendingOperations(
                code = ERROR_SERVICE_CONNECTION,
                message = error.message ?: "Unable to bind Shizuku UserService",
            )
        }
    }

    private fun drainPendingOperations() {
        val service = userService ?: return
        while (pendingOperations.isNotEmpty()) {
            runOperation(service, pendingOperations.removeFirst())
        }
    }

    private fun runOperation(service: IShizukuUserService, pending: PendingOperation) {
        commandExecutor.execute {
            try {
                val bundle = when (val operation = pending.operation) {
                    Operation.GetIwList -> service.getIwList(IW_TIMEOUT_MILLIS)
                    Operation.GetAllowedChannels -> service.getAllowedChannels(
                        IW_TIMEOUT_MILLIS,
                    )
                    Operation.GetSoftApCapability -> service.getSoftApCapability(
                        IW_TIMEOUT_MILLIS,
                    )
                    Operation.GetSoftApState -> service.getSoftApState(
                        IW_TIMEOUT_MILLIS,
                    )
                    Operation.ResetChannel -> service.resetChannel(
                        SET_CHANNEL_TIMEOUT_MILLIS,
                    )
                    is Operation.SetChannel -> service.setChannel(
                        operation.frequency,
                        SET_CHANNEL_TIMEOUT_MILLIS,
                        operation.persistent,
                    )
                }
                val response = mapOf(
                    "exitCode" to bundle.getInt("exitCode", -1),
                    "stdout" to (bundle.getString("stdout") ?: ""),
                    "stderr" to (bundle.getString("stderr") ?: ""),
                    "timedOut" to bundle.getBoolean("timedOut", false),
                )
                activity.runOnUiThread { pending.result.success(response) }
            } catch (error: Throwable) {
                userService = null
                activity.runOnUiThread {
                    pending.result.error(
                        ERROR_EXECUTION,
                        error.message ?: error.javaClass.simpleName,
                        null,
                    )
                }
            }
        }
    }

    private fun failPendingOperations(code: String, message: String) {
        permissionRequest?.error(code, message, null)
        permissionRequest = null
        while (pendingOperations.isNotEmpty()) {
            pendingOperations.removeFirst().result.error(code, message, null)
        }
    }

    @Suppress("DEPRECATION")
    private fun isShizukuInstalled(): Boolean = try {
        activity.packageManager.getPackageInfo(SHIZUKU_PACKAGE_NAME, 0)
        true
    } catch (_: PackageManager.NameNotFoundException) {
        false
    }

    private data class PendingOperation(
        val operation: Operation,
        val result: MethodChannel.Result,
    )

    private sealed interface Operation {
        data object GetIwList : Operation
        data object GetAllowedChannels : Operation
        data object GetSoftApCapability : Operation
        data object GetSoftApState : Operation
        data object ResetChannel : Operation
        data class SetChannel(val frequency: Int, val persistent: Boolean) : Operation
    }

    private companion object {
        const val CHANNEL_NAME = "wifi_channel_setter/shizuku"
        const val USER_SERVICE_TAG = "wifi_channel_setter_user_service"
        const val SHIZUKU_PACKAGE_NAME = "moe.shizuku.privileged.api"
        const val PERMISSION_REQUEST_CODE = 4821

        const val METHOD_GET_STATUS = "getStatus"
        const val METHOD_REQUEST_PERMISSION = "requestPermission"
        const val METHOD_GET_APP_INFO = "getAppInfo"
        const val METHOD_GET_IW_LIST = "getIwList"
        const val METHOD_GET_ALLOWED_CHANNELS = "getAllowedChannels"
        const val METHOD_GET_SOFT_AP_CAPABILITY = "getSoftApCapability"
        const val METHOD_GET_SOFT_AP_STATE = "getSoftApState"
        const val METHOD_RESET_CHANNEL = "resetChannel"
        const val METHOD_SET_CHANNEL = "setChannel"
        const val ARG_FREQUENCY = "frequency"
        const val ARG_PERSISTENT = "persistent"

        const val ERROR_NOT_INSTALLED = "shizuku_not_installed"
        const val ERROR_NOT_RUNNING = "shizuku_not_running"
        const val ERROR_PERMISSION_DENIED = "shizuku_permission_denied"
        const val ERROR_UNSUPPORTED = "shizuku_unsupported"
        const val ERROR_SERVICE_CONNECTION = "shizuku_service_connection"
        const val ERROR_EXECUTION = "shizuku_execution"
        const val ERROR_INVALID_ARGUMENT = "invalid_argument"
        const val ERROR_BUSY = "busy"
        const val ERROR_DISPOSED = "disposed"

        const val MIN_WIFI_FREQUENCY_MHZ = 2300
        const val MAX_WIFI_FREQUENCY_MHZ = 5900
        const val IW_TIMEOUT_MILLIS = 10_000L
        const val SET_CHANNEL_TIMEOUT_MILLIS = 15_000L
    }
}
