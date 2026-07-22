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

    data class ParsedSms(
        val type: String,
        val amount: Double,
        val accountLast4: String?,
        val toAccountLast4: String?
    )

    fun parseSms(body: String): ParsedSms? {
        val lowerBody = body.lowercase(Locale.ROOT)

        // OTP & Promotional Spam Exclusions
        val isOtp = lowerBody.contains("otp") ||
                    lowerBody.contains("one time password") ||
                    lowerBody.contains("code is") ||
                    lowerBody.contains("verification code") ||
                    lowerBody.contains("do not share") ||
                    lowerBody.contains("secret code") ||
                    lowerBody.contains("claim now") ||
                    lowerBody.contains("apply for") ||
                    lowerBody.contains("pre-approved")

        if (isOtp) return null

        // Debit keywords
        val isDebit = lowerBody.contains("debited") ||
                      lowerBody.contains("debit") ||
                      lowerBody.contains("sent") ||
                      lowerBody.contains("spent") ||
                      lowerBody.contains("paid") ||
                      lowerBody.contains("withdrawn") ||
                      lowerBody.contains("withdrawal") ||
                      lowerBody.contains("transferred") ||
                      lowerBody.contains("deducted") ||
                      lowerBody.contains("txn of") ||
                      lowerBody.contains("purchase") ||
                      lowerBody.contains("purchased") ||
                      lowerBody.contains("auto-debit") ||
                      lowerBody.contains("auto debit") ||
                      lowerBody.contains("autopay") ||
                      lowerBody.contains("swiped") ||
                      lowerBody.contains("billed") ||
                      lowerBody.contains("charged") ||
                      Regex("""(?<![a-z])dr\.?(?![a-z])""", RegexOption.IGNORE_CASE).containsMatchIn(body)

        // Credit keywords
        val isCredit = lowerBody.contains("credited") ||
                       lowerBody.contains("credit") ||
                       lowerBody.contains("received") ||
                       lowerBody.contains("deposited") ||
                       lowerBody.contains("added") ||
                       lowerBody.contains("refunded") ||
                       lowerBody.contains("refund") ||
                       lowerBody.contains("reimbursed") ||
                       lowerBody.contains("cashback") ||
                       lowerBody.contains("salary") ||
                       lowerBody.contains("reversed") ||
                       Regex("""(?<![a-z])cr\.?(?![a-z])""", RegexOption.IGNORE_CASE).containsMatchIn(body)

        if (!isDebit && !isCredit) return null

        val type = if (isDebit) "expense" else "income"

        // Amount extraction: find currency amount matches (Rs/INR/₹/$), ignoring numbers preceded by Bal/Balance/Avbl/Limit
        val amountRegex = Regex(
            """(?:Rs\.?|INR\.?|₹|\$)\s*([\d,]+(?:\.\d{1,2})?)""",
            RegexOption.IGNORE_CASE
        )
        val allAmountMatches = amountRegex.findAll(body).toList()

        var amount: Double? = null
        var amountStr: String? = null

        for (match in allAmountMatches) {
            val fullMatchRange = match.range
            val prefix = body.substring(0, fullMatchRange.first).lowercase(Locale.ROOT)
            val shortPrefix = if (prefix.length > 25) prefix.substring(prefix.length - 25) else prefix
            val isBalanceAmount = shortPrefix.contains("bal") ||
                                  shortPrefix.contains("balance") ||
                                  shortPrefix.contains("lmt") ||
                                  shortPrefix.contains("limit")

            if (!isBalanceAmount) {
                val candidateStr = match.groups[1]?.value?.replace(",", "")
                val candidateVal = candidateStr?.toDoubleOrNull()
                if (candidateVal != null && candidateVal > 0) {
                    amount = candidateVal
                    amountStr = candidateStr
                    break
                }
            }
        }

        if (amount == null && allAmountMatches.isNotEmpty()) {
            val candidateStr = allAmountMatches.first().groups[1]?.value?.replace(",", "")
            amount = candidateStr?.toDoubleOrNull()
            amountStr = candidateStr
        }

        if (amount == null || amount <= 0) return null

        val amountDigits = amountStr?.replace(".", "") ?: ""

        // Account extraction: match account/card keywords followed by digits or masked digits (xx0764, X6971, *1234, ...1234, 1234)
        val accRegex = Regex(
            """(?:A/c|Acct|Account|Card|Ending|VPA|Wallet|UPI|from|to)\s*(?:no\.?|num|number)?\s*[\D]{0,10}?([xX\*N\.]*\d{4})\b""",
            RegexOption.IGNORE_CASE
        )
        val accMatches = accRegex.findAll(body).toList()

        val validAccs = mutableListOf<String>()
        for (m in accMatches) {
            val rawCaptured = m.groups[1]?.value ?: continue
            val digitsOnly = rawCaptured.filter { it.isDigit() }
            if (digitsOnly.length >= 4) {
                val last4 = digitsOnly.takeLast(4)
                if (last4 != amountStr && last4 != amountDigits && !validAccs.contains(last4)) {
                    validAccs.add(last4)
                }
            }
        }

        // Fallback account: search for standalone masked digits like xx0764 or X6971 anywhere in body
        if (validAccs.isEmpty()) {
            val standaloneMaskRegex = Regex("""(?<!\d)[xX\*]{1,6}(\d{4})\b""")
            val maskedMatches = standaloneMaskRegex.findAll(body).toList()
            for (m in maskedMatches) {
                val last4 = m.groups[1]?.value ?: continue
                if (last4 != amountStr && last4 != amountDigits && !validAccs.contains(last4)) {
                    validAccs.add(last4)
                }
            }
        }

        val accountLast4 = validAccs.getOrNull(0)
        val toAccountLast4 = validAccs.getOrNull(1)?.takeIf { it != accountLast4 }

        return ParsedSms(type, amount, accountLast4, toAccountLast4)
    }

    private fun processSms(context: Context, body: String) {
        val parsed = parseSms(body) ?: return

        val txId = UUID.randomUUID().toString()
        val dateStr = SimpleDateFormat("yyyy-MM-dd'T'HH:mm:ss.SSS", Locale.US).format(Date())

        saveUnrecognizedTransaction(context, txId, parsed.amount, parsed.accountLast4, parsed.toAccountLast4, parsed.type, body, dateStr)
        showNotification(context, txId, parsed.amount, parsed.accountLast4, parsed.toAccountLast4, parsed.type, body, dateStr)
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
