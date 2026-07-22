package com.family.spendwise

import android.Manifest
import android.content.Intent
import android.content.pm.PackageManager
import android.os.Build
import android.os.Bundle
import androidx.core.app.ActivityCompat
import androidx.core.content.ContextCompat
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel

class MainActivity : FlutterActivity() {

    private val CHANNEL = "com.family.spendwise/sms"
    private var pendingTransaction: Map<String, Any?>? = null
    private var methodChannel: MethodChannel? = null

    override fun onCreate(savedInstanceState: Bundle?) {
        super.onCreate(savedInstanceState)
        handleIntent(intent)
    }

    override fun onNewIntent(intent: Intent) {
        super.onNewIntent(intent)
        handleIntent(intent)
        sendTransactionToFlutter()
    }

    private fun handleIntent(intent: Intent?) {
        if (intent != null && intent.getBooleanExtra("isSmsAlert", false)) {
            val tx = mapOf(
                "id" to intent.getStringExtra("id"),
                "amount" to intent.getDoubleExtra("amount", 0.0),
                "accountLast4" to intent.getStringExtra("accountLast4"),
                "toAccountLast4" to intent.getStringExtra("toAccountLast4"),
                "type" to intent.getStringExtra("type"),
                "rawSms" to intent.getStringExtra("rawSms"),
                "date" to intent.getStringExtra("date")
            )
            pendingTransaction = tx
        }
    }

    private fun sendTransactionToFlutter() {
        pendingTransaction?.let {
            methodChannel?.invokeMethod("onTransactionDetected", it)
            pendingTransaction = null
        }
    }

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
        methodChannel = MethodChannel(flutterEngine.dartExecutor.binaryMessenger, CHANNEL)
        methodChannel?.setMethodCallHandler { call, result ->
            when (call.method) {
                "requestPermissions" -> {
                    requestSmsAndNotificationPermissions()
                    result.success(true)
                }
                "hasPermissions" -> {
                    val granted = ContextCompat.checkSelfPermission(
                        this, Manifest.permission.RECEIVE_SMS
                    ) == PackageManager.PERMISSION_GRANTED
                    result.success(granted)
                }
                "getPendingTransaction" -> {
                    val temp = pendingTransaction
                    pendingTransaction = null
                    result.success(temp)
                }
                "showLocalNotification" -> {
                    val title = call.argument<String>("title") ?: "Alert"
                    val body = call.argument<String>("body") ?: ""
                    showSystemNotification(title, body)
                    result.success(true)
                }
                else -> {
                    result.notImplemented()
                }
            }
        }
        
        sendTransactionToFlutter()
    }

    private fun showSystemNotification(title: String, body: String) {
        val channelId = "spendwise_alerts"
        val notificationManager = getSystemService(android.content.Context.NOTIFICATION_SERVICE) as android.app.NotificationManager

        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
            val channel = android.app.NotificationChannel(
                channelId,
                "SpendWise Reminders & Alerts",
                android.app.NotificationManager.IMPORTANCE_HIGH
            ).apply {
                description = "Alerts for bills, recurring transactions, and budgets"
            }
            notificationManager.createNotificationChannel(channel)
        }

        val intent = Intent(this, MainActivity::class.java).apply {
            flags = Intent.FLAG_ACTIVITY_NEW_TASK or Intent.FLAG_ACTIVITY_CLEAR_TOP
        }

        val pendingIntent = android.app.PendingIntent.getActivity(
            this,
            System.currentTimeMillis().toInt(),
            intent,
            android.app.PendingIntent.FLAG_UPDATE_CURRENT or android.app.PendingIntent.FLAG_IMMUTABLE
        )

        val notification = androidx.core.app.NotificationCompat.Builder(this, channelId)
            .setSmallIcon(android.R.drawable.ic_dialog_info)
            .setContentTitle(title)
            .setContentText(body)
            .setAutoCancel(true)
            .setPriority(androidx.core.app.NotificationCompat.PRIORITY_HIGH)
            .setContentIntent(pendingIntent)
            .build()

        notificationManager.notify(System.currentTimeMillis().toInt(), notification)
    }

    private fun requestSmsAndNotificationPermissions() {
        val permissions = mutableListOf<String>()
        
        if (ContextCompat.checkSelfPermission(this, Manifest.permission.RECEIVE_SMS) != PackageManager.PERMISSION_GRANTED) {
            permissions.add(Manifest.permission.RECEIVE_SMS)
        }

        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.TIRAMISU) {
            if (ContextCompat.checkSelfPermission(this, Manifest.permission.POST_NOTIFICATIONS) != PackageManager.PERMISSION_GRANTED) {
                permissions.add(Manifest.permission.POST_NOTIFICATIONS)
            }
        }

        if (permissions.isNotEmpty()) {
            ActivityCompat.requestPermissions(this, permissions.toTypedArray(), 101)
        }
    }
}
