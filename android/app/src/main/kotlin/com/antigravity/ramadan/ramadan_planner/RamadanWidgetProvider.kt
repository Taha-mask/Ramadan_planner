package com.antigravity.ramadan.ramadan_planner

import android.appwidget.AppWidgetManager
import android.content.Context
import android.content.SharedPreferences
import android.widget.RemoteViews
import es.antonborri.home_widget.HomeWidgetProvider

class RamadanWidgetProvider : HomeWidgetProvider() {
    override fun onUpdate(context: Context, appWidgetManager: AppWidgetManager, appWidgetIds: IntArray, widgetData: SharedPreferences) {
        appWidgetIds.forEach { widgetId ->
            val views = RemoteViews(context.packageName, R.layout.widget_layout).apply {
                val nextPrayerName = widgetData.getString("next_prayer_name", "Next Prayer")
                val nextPrayerTime = widgetData.getString("next_prayer_time", "--:--")
                val tasksSummary = widgetData.getString("tasks_summary", "No pending tasks")

                setTextViewText(R.id.widget_next_prayer_name, nextPrayerName)
                setTextViewText(R.id.widget_next_prayer_time, nextPrayerTime)
                setTextViewText(R.id.widget_tasks_summary, tasksSummary)
            }
            appWidgetManager.updateAppWidget(widgetId, views)
        }
    }
}
