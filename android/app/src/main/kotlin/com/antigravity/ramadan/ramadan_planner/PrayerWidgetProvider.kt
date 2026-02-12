package com.antigravity.ramadan.ramadan_planner

import android.appwidget.AppWidgetManager
import android.content.Context
import android.content.SharedPreferences
import android.widget.RemoteViews
import android.os.SystemClock
import es.antonborri.home_widget.HomeWidgetProvider
import org.json.JSONArray
import org.json.JSONObject
import android.view.View
import android.graphics.Color

class PrayerWidgetProvider : HomeWidgetProvider() {
    override fun onUpdate(context: Context, appWidgetManager: AppWidgetManager, appWidgetIds: IntArray, widgetData: SharedPreferences) {
        appWidgetIds.forEach { widgetId ->
            val views = RemoteViews(context.packageName, R.layout.widget_prayer)
            
            // 1. Get Data
            var nextPrayerName = widgetData.getString("next_prayer_name", "--")
            // Map "Dhuhr (Fard)" to "Dhuhr" if needed
            if (nextPrayerName == "ظهر (فرض)") nextPrayerName = "ظهر"
            
            val nextPrayerTime = widgetData.getString("next_prayer_time", "--:--")
            val nextPrayerMillis = widgetData.getLong("next_prayer_millis", 0L)
            
            val hijriDate = widgetData.getString("hijri_date", "")
            val location = widgetData.getString("location", "حدد موقعك")

            // 2. Format Date (Gregorian + Hijri)
            val now = System.currentTimeMillis()
            val dateFormat = java.text.SimpleDateFormat("EEE, MMM dd", java.util.Locale.ENGLISH)
            val dateStr = dateFormat.format(java.util.Date(now))
            val fullDate = "$dateStr • $hijriDate"

            // 3. Bind Views
            views.setTextViewText(R.id.tv_full_date, fullDate)
            views.setTextViewText(R.id.tv_location, location)
            
            views.setTextViewText(R.id.tv_next_prayer_name, nextPrayerName)
            views.setTextViewText(R.id.tv_next_prayer_time, nextPrayerTime)

            // 4. Countdown
            if (nextPrayerMillis > now) {
                views.setChronometer(R.id.chronometer_countdown, SystemClock.elapsedRealtime() + (nextPrayerMillis - now), null, true)
                views.setViewVisibility(R.id.chronometer_countdown, View.VISIBLE)
                views.setChronometerCountDown(R.id.chronometer_countdown, true)
            } else {
                 views.setTextViewText(R.id.chronometer_countdown, "--:--:--")
            }

            appWidgetManager.updateAppWidget(widgetId, views)
        }
    }

    private fun findNextPrayer(jsonStr: String?): JSONObject? {
        if (jsonStr == null) return null
        try {
            val prayers = JSONArray(jsonStr)
            val now = System.currentTimeMillis()
            for (i in 0 until prayers.length()) {
                val prayer = prayers.getJSONObject(i)
                if (prayer.optLong("millis", 0L) > now) return prayer
            }
        } catch (e: Exception) {}
        return null
    }
}
