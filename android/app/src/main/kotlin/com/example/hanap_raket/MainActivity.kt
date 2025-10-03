package com.algovision.serbisyo

import io.flutter.embedding.android.FlutterActivity
import android.content.pm.PackageManager
import android.util.Base64
import android.util.Log
import java.security.MessageDigest
import java.security.NoSuchAlgorithmException

class MainActivity: FlutterActivity() {
    override fun onCreate(savedInstanceState: android.os.Bundle?) {
        super.onCreate(savedInstanceState)
        
        // Print key hash for Facebook
        printKeyHash()
    }
    
    private fun printKeyHash() {
        try {
            val info = packageManager.getPackageInfo("com.algovision.serbisyo", PackageManager.GET_SIGNATURES)
            for (signature in info.signatures) {
                val md = MessageDigest.getInstance("SHA")
                md.update(signature.toByteArray())
                val hash = Base64.encodeToString(md.digest(), Base64.DEFAULT)
                Log.d("KeyHash:", "Facebook Key Hash: $hash")
                println("Facebook Key Hash: $hash")
            }
        } catch (e: NoSuchAlgorithmException) {
            Log.e("KeyHash", "Error: $e")
        } catch (e: Exception) {
            Log.e("KeyHash", "Error: $e")
        }
    }
}
