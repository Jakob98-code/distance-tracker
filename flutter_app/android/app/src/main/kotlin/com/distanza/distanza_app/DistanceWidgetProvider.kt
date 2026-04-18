package com.distanza.distanza_app

import android.appwidget.AppWidgetManager
import android.appwidget.AppWidgetProvider
import android.content.Context
import android.widget.RemoteViews
import com.google.firebase.database.FirebaseDatabase
import java.text.SimpleDateFormat
import java.util.*
import kotlin.math.*

class DistanceWidgetProvider : AppWidgetProvider() {

    override fun onUpdate(context: Context, appWidgetManager: AppWidgetManager, appWidgetIds: IntArray) {
        for (appWidgetId in appWidgetIds) {
            updateWidget(context, appWidgetManager, appWidgetId)
        }
    }

    private fun updateWidget(context: Context, appWidgetManager: AppWidgetManager, appWidgetId: Int) {
        val views = RemoteViews(context.packageName, R.layout.widget_distance)

        // Read config from SharedPreferences (home_widget uses this key)
        val prefs = context.getSharedPreferences("HomeWidgetPreferences", Context.MODE_PRIVATE)
        val coupleId = prefs.getString("coupleId", null)
        val person1Name = prefs.getString("person1Name", "J")
        val person2Name = prefs.getString("person2Name", "D")

        views.setTextViewText(R.id.widget_initial1, person1Name?.firstOrNull()?.uppercase() ?: "J")
        views.setTextViewText(R.id.widget_initial2, person2Name?.firstOrNull()?.uppercase() ?: "D")

        if (coupleId == null) {
            views.setTextViewText(R.id.widget_distance, "Apri l'app")
            views.setTextViewText(R.id.widget_countdown, "")
            views.setTextViewText(R.id.widget_updated, "")
            appWidgetManager.updateAppWidget(appWidgetId, views)
            return
        }

        val db = FirebaseDatabase.getInstance("https://distance-tracker-c8bbf-default-rtdb.europe-west1.firebasedatabase.app")

        // Fetch locations
        db.getReference("couples/$coupleId/locations").get().addOnSuccessListener { snapshot ->
            val p1 = snapshot.child("person1")
            val p2 = snapshot.child("person2")

            if (p1.exists() && p2.exists()) {
                val lat1 = p1.child("lat").getValue(Double::class.java) ?: 0.0
                val lon1 = p1.child("lon").getValue(Double::class.java) ?: 0.0
                val lat2 = p2.child("lat").getValue(Double::class.java) ?: 0.0
                val lon2 = p2.child("lon").getValue(Double::class.java) ?: 0.0
                val dist = haversineKm(lat1, lon1, lat2, lon2)
                views.setTextViewText(R.id.widget_distance, "${dist.roundToInt()} km")
            } else {
                views.setTextViewText(R.id.widget_distance, "-- km")
            }

            val sdf = SimpleDateFormat("HH:mm", Locale.getDefault())
            views.setTextViewText(R.id.widget_updated, "Agg. ${sdf.format(Date())}")
            appWidgetManager.updateAppWidget(appWidgetId, views)
        }

        // Fetch countdown
        db.getReference("couples/$coupleId/nextMeetDate").get().addOnSuccessListener { snapshot ->
            val dateStr = snapshot.getValue(String::class.java)
            if (dateStr != null) {
                try {
                    val fmt = SimpleDateFormat("yyyy-MM-dd", Locale.getDefault())
                    val meetDate = fmt.parse(dateStr)
                    if (meetDate != null) {
                        val diff = meetDate.time - System.currentTimeMillis()
                        if (diff > 0) {
                            val days = diff / (1000 * 60 * 60 * 24)
                            views.setTextViewText(R.id.widget_countdown, "Ci vediamo tra ${days}g")
                        } else {
                            views.setTextViewText(R.id.widget_countdown, "Presto \u2728")
                        }
                    }
                } catch (_: Exception) {
                    views.setTextViewText(R.id.widget_countdown, "Presto \u2728")
                }
            } else {
                views.setTextViewText(R.id.widget_countdown, "Presto \u2728")
            }
            appWidgetManager.updateAppWidget(appWidgetId, views)
        }
    }

    private fun haversineKm(lat1: Double, lon1: Double, lat2: Double, lon2: Double): Double {
        val r = 6371.0
        val dLat = Math.toRadians(lat2 - lat1)
        val dLon = Math.toRadians(lon2 - lon1)
        val a = sin(dLat / 2).pow(2) +
                cos(Math.toRadians(lat1)) * cos(Math.toRadians(lat2)) * sin(dLon / 2).pow(2)
        return r * 2 * asin(sqrt(a))
    }
}
