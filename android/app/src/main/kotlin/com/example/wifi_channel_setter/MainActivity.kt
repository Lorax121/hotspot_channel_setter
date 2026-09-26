package com.example.wifi_channel_setter

import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine

class MainActivity : FlutterActivity() {
    private var shizukuBridge: ShizukuBridge? = null

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
        shizukuBridge = ShizukuBridge(
            activity = this,
            binaryMessenger = flutterEngine.dartExecutor.binaryMessenger,
        )
    }

    override fun onDestroy() {
        shizukuBridge?.dispose()
        shizukuBridge = null
        super.onDestroy()
    }
}
