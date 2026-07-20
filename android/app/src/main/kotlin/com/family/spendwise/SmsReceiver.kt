package com.family.spendwise

import android.app.NotificationChannel
import android.app.NotificationManager
import android.app.PendingIntent
import android.content.BroadcastReceiver
import android.content.Context
import android.content.Intent
import android.os.Build
import android.telephony.SmsMessage
import androidx.core.app.NotificationCompat
import org.json.JSONArray
import org.json.JSONObject
import java.io.File
import java.text.SimpleDateFormat
import java.util.Date
import java.util.Locale
import java.util.UUID

class SmsReceiver : BroadcastReceiver() {

    override fun onReceive(context: Context, intent: Intent) {
        if (intent.action == "android.provider.Telephony.SMS_RECEIVED") {
            val bundle = intent.extras
            if (bundle != null) {
                try {
                    val pdus = bundle.get("pdus") as Array<*>
                    for (i in pdus.indices) {
                        val format = bundle.getString("format")
                        val smsMessage = if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.M) {
                            SmsMessage.createFromPdu(pdus[i] as ByteArray, format)
                        } else {
                            @Suppress("DEPRECATION")
                            SmsMessage.createFromPdu(pdus[i] as ByteArray)
                        }
                        val messageBody = smsMessage.messageBody
                        processSms(context, messageBody)
                    }
                } catch (e: Exception) {
                    e.printStackTrace()
                }
            }
        }
    }

    private fun processSms(context: Context, body: String) {
        // Basic transaction check
        val isDebit = body.contains("debited", ignoreCase = true) || 
                      body.contains("spent", ignoreCase = true) || 
                      body.contains("withdrawal", ignoreCase = true) || 
                      body.contains("paid", ignoreCase = true) || 
                      body.contains("txn of", ignoreCase = true)

        val isCredit = body.contains("credited", ignoreCase = true) ||
                       body.contains("received", ignoreCase = true) ||
                       body.contains("salary", ignoreCase = true)

        val isOtp = body.contains("otp", ignoreCase = true) || 
                    body.contains("one time password", ignoreCase = true) || 
                    body.contains("code is", ignoreCase = true)

        if ((isDebit || isCredit) && !isOtp) {
            val type = if (isCredit) "income" else "expense"

            // Extract amount using regex: Rs. 500 or Rs 500 or INR 500
            val amountRegex = Regex("""(?:Rs\.?|INR)\s*([\d,]+\.?\d*)""", RegexOption.IGNORE_CASE)
            val amountMatch = amountRegex.find(body)
            val amountStr = amountMatch?.groups?.get(1)?.value?.replace(",", "")
            val amount = amountStr?.toDoubleOrNull() ?: return

            // Extract account/card numbers (using negative lookarounds to match exactly 4 digits)
            val accRegex = Regex("""(?:A/c|Acct|account|card|to|credited|ending)\s*\D*(?<!\d)(\d{4})(?!\d)""", RegexOption.IGNORE_CASE)
            val accMatches = accRegex.findAll(body).toList()
            val validAccs = accMatches.mapNotNull { it.groups[1]?.value }.filter { it != amountStr }
            val accountLast4 = if (validAccs.isNotEmpty()) validAccs[0] else null
            val toAccountLast4 = if (validAccs.size > 1) {
                val secVal = validAccs[1]
                if (secVal != accountLast4) secVal else null
            } else null

            val txId = UUID.randomUUID().toString()
            val dateStr = SimpleDateFormat("yyyy-MM-dd'T'HH:mm:ss.SSS", Locale.US).format(Date())

            // Save unrecognized transaction to json file in filesDir
            saveUnrecognizedTransaction(context, txId, amount, accountLast4, toAccountLast4, type, body, dateStr)

            // Trigger dynamic local notification
            showNotification(context, txId, amount, accountLast4, toAccountLast4, type, body, dateStr)
        }
    }

    private fun saveUnrecognizedTransaction(
        context: Context,
        id: String,
        amount: Double,
        accountLast4: String?,
        toAccountLast4: String?,
        type: String,
        rawSms: String,
        date: String
    ) {
        try {
            val oldFile = File(context.filesDir, "unrecognized_transactions.json")
            val appFlutterDir = File(context.filesDir.parentFile, "app_flutter")
            if (!appFlutterDir.exists()) {
                appFlutterDir.mkdirs()
            }
            val file = File(appFlutterDir, "unrecognized_transactions.json")
            val jsonArray = if (file.exists()) {
                JSONArray(file.readText())
            } else {
                JSONArray()
            }

            // Migrate old entries if old file exists
            if (oldFile.exists()) {
                try {
                    val oldArray = JSONArray(oldFile.readText())
                    val existingIds = HashSet<String>()
                    for (i in 0 until jsonArray.length()) {
                        val obj = jsonArray.optJSONObject(i)
                        val idVal = obj?.optString("id")
                        if (idVal != null) {
                            existingIds.add(idVal)
                        }
                    }
                    for (i in 0 until oldArray.length()) {
                        val obj = oldArray.optJSONObject(i)
                        if (obj != null) {
                            val idVal = obj.optString("id")
                            if (idVal != null && !existingIds.contains(idVal)) {
                                jsonArray.put(obj)
                            }
                        }
                    }
                    oldFile.delete()
                } catch (migrationEx: Exception) {
                    migrationEx.printStackTrace()
                }
            }

            val newTx = JSONObject()
            newTx.put("id", id)
            newTx.put("amount", amount)
            newTx.put("accountLast4", accountLast4 ?: JSONObject.NULL)
            newTx.put("toAccountLast4", toAccountLast4 ?: JSONObject.NULL)
            newTx.put("type", type)
            newTx.put("rawSms", rawSms)
            newTx.put("date", date)

            jsonArray.put(newTx)
            file.writeText(jsonArray.toString())
        } catch (e: Exception) {
            e.printStackTrace()
        }
    }

    private fun showNotification(
        context: Context,
        id: String,
        amount: Double,
        accountLast4: String?,
        toAccountLast4: String?,
        type: String,
        rawSms: String,
        date: String
    ) {
        val channelId = "sms_transactions"
        val notificationId = System.currentTimeMillis().toInt()

        val notificationManager = context.getSystemService(Context.NOTIFICATION_SERVICE) as NotificationManager

        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
            val channel = NotificationChannel(
                channelId,
                "Transaction Alerts",
                NotificationManager.IMPORTANCE_HIGH
            ).apply {
                description = "Alerts for detected transactions"
            }
            notificationManager.createNotificationChannel(channel)
        }

        // Open MainActivity when notification is tapped
        val intent = Intent(context, MainActivity::class.java).apply {
            flags = Intent.FLAG_ACTIVITY_NEW_TASK or Intent.FLAG_ACTIVITY_CLEAR_TOP
            putExtra("id", id)
            putExtra("amount", amount)
            putExtra("accountLast4", accountLast4)
            putExtra("toAccountLast4", toAccountLast4)
            putExtra("type", type)
            putExtra("rawSms", rawSms)
            putExtra("date", date)
            putExtra("isSmsAlert", true)
        }

        val pendingIntent = PendingIntent.getActivity(
            context,
            notificationId,
            intent,
            PendingIntent.FLAG_UPDATE_CURRENT or PendingIntent.FLAG_IMMUTABLE
        )

        val accountText = if (toAccountLast4 != null && accountLast4 != null) {
            "from Account ending $accountLast4 to $toAccountLast4"
        } else if (accountLast4 != null) {
            "from Account ending $accountLast4"
        } else {
            ""
        }

        val contentTitle = if (toAccountLast4 != null) "New Transfer Detected" else "New Transaction Detected"
        val actionText = if (type == "income") "received" else "spent"

        val notification = NotificationCompat.Builder(context, channelId)
            .setContentTitle(contentTitle)
            .setContentText("₹${String.format(Locale.US, "%.2f", amount)} $actionText $accountText. Tap to categorize.")
            .setSmallIcon(android.R.drawable.ic_dialog_info)
            .setAutoCancel(true)
            .setContentIntent(pendingIntent)
            .setPriority(NotificationCompat.PRIORITY_HIGH)
            .build()

        notificationManager.notify(notificationId, notification)
    }
}
