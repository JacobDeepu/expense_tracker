package com.example.expense_tracker

import android.content.BroadcastReceiver
import android.content.Context
import android.content.Intent
import android.content.IntentFilter
import android.os.Build
import android.os.Bundle
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.EventChannel

class MainActivity : FlutterActivity() {
    private val CHANNEL_NAME = "com.example.expense_tracker/notifications"
    private val ACTION_NOTIFICATION_RECEIVED = "com.example.expense_tracker.NOTIFICATION_RECEIVED"

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)

        EventChannel(flutterEngine.dartExecutor.binaryMessenger, CHANNEL_NAME).setStreamHandler(
            object : EventChannel.StreamHandler {
                private var receiver: BroadcastReceiver? = null

                override fun onListen(arguments: Any?, events: EventChannel.EventSink?) {
                    if (events == null) return

                    receiver = object : BroadcastReceiver() {
                        override fun onReceive(context: Context?, intent: Intent?) {
                            if (intent?.action == ACTION_NOTIFICATION_RECEIVED) {
                                val data = mapOf(
                                    "package" to intent.getStringExtra("package"),
                                    "title" to intent.getStringExtra("title"),
                                    "text" to intent.getStringExtra("text"),
                                    "timestamp" to intent.getLongExtra("timestamp", 0L)
                                )
                                events.success(data)
                            }
                        }
                    }

                    val filter = IntentFilter(ACTION_NOTIFICATION_RECEIVED)
                    if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.TIRAMISU) {
                        context.registerReceiver(receiver, filter, Context.RECEIVER_NOT_EXPORTED)
                    } else {
                        context.registerReceiver(receiver, filter)
                    }
                }

                override fun onCancel(arguments: Any?) {
                    if (receiver != null) {
                        context.unregisterReceiver(receiver)
                        receiver = null
                    }
                }
            }
        )
    }
}