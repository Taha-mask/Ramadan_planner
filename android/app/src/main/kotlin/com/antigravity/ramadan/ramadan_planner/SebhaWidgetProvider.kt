package com.antigravity.ramadan.ramadan_planner

import android.appwidget.AppWidgetManager
import android.content.Context
import android.content.SharedPreferences
import android.widget.RemoteViews
import es.antonborri.home_widget.HomeWidgetProvider
import android.app.PendingIntent
import android.content.Intent
import android.net.Uri

class SebhaWidgetProvider : HomeWidgetProvider() {
    override fun onUpdate(context: Context, appWidgetManager: AppWidgetManager, appWidgetIds: IntArray, widgetData: SharedPreferences) {
        appWidgetIds.forEach { widgetId ->
            val views = RemoteViews(context.packageName, R.layout.widget_sebha).apply {
                // Get count
                val count = widgetData.getInt("sebha_count", 0)
                setTextViewText(R.id.tv_counter, count.toString())
                
                // Update Target Text (Removed)
                // val target = 33
                // val cycle = (count / target) + 1
                // setTextViewText(R.id.tv_target, "/ $target")

                // Increment Intent
                val incrementIntent = Intent(context, SebhaWidgetProvider::class.java).apply {
                    action = "ACTION_INCREMENT"
                    putExtra(AppWidgetManager.EXTRA_APPWIDGET_ID, widgetId)
                    data = Uri.parse("sebha://increment/$widgetId")
                }
                val incrementPendingIntent = PendingIntent.getBroadcast(
                    context, 
                    widgetId, 
                    incrementIntent, 
                    PendingIntent.FLAG_UPDATE_CURRENT or PendingIntent.FLAG_IMMUTABLE
                )
                setOnClickPendingIntent(R.id.btn_increment, incrementPendingIntent)

                // Reset Intent
                val resetIntent = Intent(context, SebhaWidgetProvider::class.java).apply {
                    action = "ACTION_RESET"
                    putExtra(AppWidgetManager.EXTRA_APPWIDGET_ID, widgetId)
                    data = Uri.parse("sebha://reset/$widgetId")
                }
                val resetPendingIntent = PendingIntent.getBroadcast(
                    context, 
                    widgetId + 1000, 
                    resetIntent, 
                    PendingIntent.FLAG_UPDATE_CURRENT or PendingIntent.FLAG_IMMUTABLE
                )
                setOnClickPendingIntent(R.id.btn_reset, resetPendingIntent)
            }
            appWidgetManager.updateAppWidget(widgetId, views)
        }
    }

    override fun onReceive(context: Context, intent: Intent) {
        super.onReceive(context, intent)
        val action = intent.action
        
        if (action == "ACTION_INCREMENT" || action == "ACTION_RESET") {
            val widgetData = context.getSharedPreferences("HomeWidgetPreferences", Context.MODE_PRIVATE)
            var count = widgetData.getInt("sebha_count", 0)
            
            if (action == "ACTION_INCREMENT") {
                count++
            } else {
                count = 0
            }
            
            widgetData.edit().putInt("sebha_count", count).apply()
            
            val appWidgetManager = AppWidgetManager.getInstance(context)
            val componentName = android.content.ComponentName(context, SebhaWidgetProvider::class.java)
            val appWidgetIds = appWidgetManager.getAppWidgetIds(componentName)
            onUpdate(context, appWidgetManager, appWidgetIds, widgetData)
        }
    }
}
