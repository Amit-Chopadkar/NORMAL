package com.example.tourist_safety_hub

import android.app.NotificationChannel
import android.app.NotificationManager
import android.content.Context
import android.os.Build
import androidx.core.app.NotificationCompat
import androidx.core.app.NotificationManagerCompat
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel

class MainActivity : FlutterActivity() {
	private val CHANNEL = "tourapp/notifications"

	override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
		super.configureFlutterEngine(flutterEngine)
		MethodChannel(flutterEngine.dartExecutor.binaryMessenger, CHANNEL).setMethodCallHandler { call, result ->
			when (call.method) {
				"showNotification" -> {
					val title = call.argument<String>("title") ?: "Notification"
					val body = call.argument<String>("body") ?: ""
					showNotification(title, body)
					result.success(null)
				}
				else -> result.notImplemented()
			}
		}
	}

	private fun showNotification(title: String, body: String) {
		val channelId = "geofence_channel"
		val manager = getSystemService(Context.NOTIFICATION_SERVICE) as NotificationManager
		if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
			val channel = NotificationChannel(channelId, "Geofence", NotificationManager.IMPORTANCE_HIGH)
			channel.description = "Geofence enter/exit notifications"
			manager.createNotificationChannel(channel)
		}

		val builder = NotificationCompat.Builder(this, channelId)
			.setSmallIcon(R.mipmap.ic_launcher)
			.setContentTitle(title)
			.setContentText(body)
			.setPriority(NotificationCompat.PRIORITY_HIGH)
			.setAutoCancel(true)

		NotificationManagerCompat.from(this).notify(0, builder.build())
	}
}
