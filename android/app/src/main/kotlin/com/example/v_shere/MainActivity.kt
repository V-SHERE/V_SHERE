package com.example.v_shere

import android.content.Context
import android.net.wifi.WifiManager
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel

class MainActivity : FlutterActivity() {
    private val multicastChannel = "v_shere/wifi_multicast"
    private var multicastLock: WifiManager.MulticastLock? = null

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, multicastChannel)
            .setMethodCallHandler { call, result ->
                when (call.method) {
                    "acquire" -> {
                        try {
                            val wifiManager =
                                applicationContext.getSystemService(Context.WIFI_SERVICE) as WifiManager
                            val lock = multicastLock
                                ?: wifiManager.createMulticastLock("v_shere_discovery").also {
                                    multicastLock = it
                                    it.setReferenceCounted(false)
                                }
                            if (!lock.isHeld) lock.acquire()
                            result.success(null)
                        } catch (error: Exception) {
                            result.error(
                                "MULTICAST_LOCK_FAILED",
                                error.message,
                                null,
                            )
                        }
                    }
                    "release" -> {
                        multicastLock?.let { lock ->
                            if (lock.isHeld) lock.release()
                        }
                        multicastLock = null
                        result.success(null)
                    }
                    else -> result.notImplemented()
                }
            }
    }

    override fun onDestroy() {
        multicastLock?.let { lock ->
            if (lock.isHeld) lock.release()
        }
        multicastLock = null
        super.onDestroy()
    }
}
