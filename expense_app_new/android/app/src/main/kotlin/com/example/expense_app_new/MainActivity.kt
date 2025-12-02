package com.example.expense_app_new

import android.content.Intent
import android.net.Uri
import io.flutter.embedding.android.FlutterFragmentActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel

class MainActivity : FlutterFragmentActivity() {
    private val CHANNEL = "expense_app_new/upi"
    private var pendingResult: MethodChannel.Result? = null
    private val UPI_REQUEST = 200

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, CHANNEL).setMethodCallHandler { call, result ->
            if (call.method == "startUPI") {
                pendingResult = result
                val uri = call.argument<String>("uri")
                startPayment(uri)
            } else {
                result.notImplemented()
            }
        }
    }

    private fun startPayment(uri: String?) {
        if (uri == null) return
        val intent = Intent(Intent.ACTION_VIEW)
        intent.data = Uri.parse(uri)
        val chooser = Intent.createChooser(intent, "Pay with...")
        startActivityForResult(chooser, UPI_REQUEST)
    }

    override fun onActivityResult(requestCode: Int, resultCode: Int, data: Intent?) {
        if (requestCode == UPI_REQUEST) {
            if (pendingResult == null) return

            if (data != null) {
                val response = data.getStringExtra("response") ?: "Status=FAILED"
                pendingResult?.success(response)
            } else {
                pendingResult?.success("Status=FAILED")
            }
            pendingResult = null
        } else {
            super.onActivityResult(requestCode, resultCode, data)
        }
    }
}
