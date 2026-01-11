package com.example.expense_tracker

import android.content.Intent
import android.service.notification.NotificationListenerService
import android.service.notification.StatusBarNotification
import android.util.Log

class TransactionListenerService : NotificationListenerService() {

    companion object {
        private const val TAG = "TransactionListener"
        const val ACTION_NOTIFICATION_RECEIVED = "com.example.expense_tracker.NOTIFICATION_RECEIVED"
    }

    // List of target financial apps to monitor
    private val targetPackages = setOf(
        "com.google.android.apps.nbu.paisa.user", // Google Pay
        "com.phonepe.app",                        // PhonePe
        "net.one97.paytm",                        // Paytm
        "in.amazon.mShop.android.shopping",       // Amazon Pay (often bundled)
        "com.whatsapp",                           // WhatsApp Payments
        "com.freecharge.android"                  // Freecharge
    )

    override fun onNotificationPosted(sbn: StatusBarNotification) {
        val packageName = sbn.packageName

        if (packageName in targetPackages) {
            val extras = sbn.notification.extras
            val title = extras.getString("android.title")
            val text = extras.getString("android.text")
            val bigText = extras.getCharSequence("android.bigText")?.toString()

            val content = bigText ?: text ?: ""

            Log.d(TAG, "Transaction detected from $packageName: $title - $content")

            // Send broadcast to be picked up by MainActivity (or a Receiver)
            val intent = Intent(ACTION_NOTIFICATION_RECEIVED).apply {
                putExtra("package", packageName)
                putExtra("title", title ?: "")
                putExtra("text", content)
                putExtra("timestamp", sbn.postTime)
                setPackage(this@TransactionListenerService.packageName) // Restrict to own app
            }
            sendBroadcast(intent)
        }
    }

    override fun onNotificationRemoved(sbn: StatusBarNotification) {
        // Optional: Handle removal if needed
    }
}
