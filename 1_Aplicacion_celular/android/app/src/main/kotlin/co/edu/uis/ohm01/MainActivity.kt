package co.edu.uis.ohm01

import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel
import android.content.Context
import android.net.wifi.WifiManager
import android.view.WindowManager

class MainActivity : FlutterActivity() {
    private var multicastLock: WifiManager.MulticastLock? = null

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, "ohm01/network")
            .setMethodCallHandler { call, result ->
                when (call.method) {
                    "acquireMulticastLock" -> {
                        try {
                            if (multicastLock == null) {
                                val wifi = applicationContext.getSystemService(Context.WIFI_SERVICE) as WifiManager
                                multicastLock = wifi.createMulticastLock("ohm01-udp").apply { setReferenceCounted(false) }
                            }
                            if (multicastLock?.isHeld == false) multicastLock?.acquire()
                            window.addFlags(WindowManager.LayoutParams.FLAG_KEEP_SCREEN_ON)
                            result.success(null)
                        } catch (e: Exception) {
                            result.error("WIFI_LOCK", e.message, null)
                        }
                    }
                    "releaseMulticastLock" -> {
                        releaseNetworkLock()
                        result.success(null)
                    }
                    else -> result.notImplemented()
                }
            }
    }

    private fun releaseNetworkLock() {
        if (multicastLock?.isHeld == true) multicastLock?.release()
        window.clearFlags(WindowManager.LayoutParams.FLAG_KEEP_SCREEN_ON)
    }

    override fun onDestroy() {
        releaseNetworkLock()
        multicastLock = null
        super.onDestroy()
    }
}
