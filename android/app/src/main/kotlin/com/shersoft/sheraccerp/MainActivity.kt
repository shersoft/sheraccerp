package com.shersoft.sheraccerp

import android.Manifest
import android.content.Intent
import android.content.pm.PackageManager
import android.os.Build
import android.os.Bundle
import android.telephony.SmsManager
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.BinaryMessenger
import io.flutter.plugin.common.MethodChannel
import io.flutter.plugins.GeneratedPluginRegistrant
import org.json.JSONArray
import org.json.JSONObject
import java.text.SimpleDateFormat
import java.util.*


class MainActivity: FlutterActivity() {

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        GeneratedPluginRegistrant.registerWith(flutterEngine)
    }

    override fun onCreate(savedInstanceState: Bundle?) {
        super.onCreate(savedInstanceState)
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.M) {
            if (checkSelfPermission(
                            Manifest.permission.SEND_SMS)
                    != PackageManager.PERMISSION_GRANTED) {

                if (shouldShowRequestPermissionRationale(
                                Manifest.permission.SEND_SMS)) {
                } else {
                    requestPermissions(arrayOf(Manifest.permission.SEND_SMS),
                            0)
                }
            }
        }
        MethodChannel(getBinaryMessenger()!!, CHANNEL).setMethodCallHandler { call, result ->
            when (call.method) {
                "sendSMS" -> {
                    val num = call.argument<String>("phone")
                    val msg = call.argument<String>("msg")
                    sendSMS(num, msg, result)
                }
                "sentPrintUrovo" -> {
                    val content = call.argument<String>("content")
                    printUrovoPOSService(content,result);
                }
                "PrinterUrovoAppInstalled" -> {
                    val packageManager = packageManager
                    if (isPackageInstalled("com.example.printersample", packageManager)) {
                        result.success(true)
                    } else {
                        result.success(false)
                    }
                }
                else -> {
                    result.notImplemented()
                }
            }
        }
    }

    private fun printUrovoPOSService(content: String?, result: MethodChannel.Result) {
        try{
            val intent = Intent()
            intent.setClassName("com.example.printersample", "com.example.printersample.PrintData")
            intent.putExtra("data", content)
            startService(intent)
            result.success("print started")
        } catch(ex:Exception){
            ex.message
        }
    }

    private fun isPackageInstalled(packageName: String, packageManager: PackageManager): Boolean {
        return try {
            packageManager.getPackageGids(packageName)
            true
        } catch (e: PackageManager.NameNotFoundException) {
            false
        }
    }

    private fun getBinaryMessenger(): BinaryMessenger? {
        return flutterEngine!!.dartExecutor.binaryMessenger
    }

    private fun sendSMS(phoneNo: String?, msg: String?, result: MethodChannel.Result) {
        try {
            val smsManager = SmsManager.getDefault()
            smsManager.sendTextMessage(phoneNo, null, msg, null, null)
            result.success("SMS Sent")
        } catch (ex: Exception) {
            ex.printStackTrace()
            result.error("Err", "Sms Not Sent", "")
        }
    }

    override fun onRequestPermissionsResult(requestCode: Int,
                                            permissions: Array<String>, grantResults: IntArray) {
        when (requestCode) {
            0 -> {

                // If request is cancelled, the result arrays are empty.
                if (grantResults.isNotEmpty()
                        && grantResults[0] == PackageManager.PERMISSION_GRANTED) {

                    // permission was granted, yay! Do the
                    // contacts-related task you need to do.
                } else {

                    // permission denied, boo! Disable the
                    // functionality that depends on this permission.
                }
                return
            }
        }
    }

    companion object {
        private const val CHANNEL = "sherAccChannel"
    }

}

