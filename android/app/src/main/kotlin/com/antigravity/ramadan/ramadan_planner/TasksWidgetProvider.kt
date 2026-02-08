package com.antigravity.ramadan.ramadan_planner

import android.appwidget.AppWidgetManager
import android.content.Context
import android.content.Intent
import android.content.SharedPreferences
import android.net.Uri
import android.widget.RemoteViews
import es.antonborri.home_widget.HomeWidgetProvider

class TasksWidgetProvider : HomeWidgetProvider() {
    override fun onUpdate(context: Context, appWidgetManager: AppWidgetManager, appWidgetIds: IntArray, widgetData: SharedPreferences) {
        appWidgetIds.forEach { widgetId ->
            val intent = Intent(context, TasksWidgetService::class.java).apply {
                putExtra(AppWidgetManager.EXTRA_APPWIDGET_ID, widgetId)
                data = Uri.parse(toUri(Intent.URI_INTENT_SCHEME))
            }

            val doneCount = widgetData.getInt("tasks_done_count", 0)
            val totalCount = widgetData.getInt("tasks_total_count", 0)

            val views = RemoteViews(context.packageName, R.layout.tasks_widget_layout).apply {
                setRemoteAdapter(R.id.tasks_list_view, intent)
                setEmptyView(R.id.tasks_list_view, R.id.tasks_empty_view)
                setTextViewText(R.id.tasks_done_counter, "$doneCount/$totalCount مكتمل")
                
                // Click template for items
                val clickIntent = Intent(context, TasksWidgetReceiver::class.java).apply {
                    action = "com.antigravity.ramadan.ACTION_TOGGLE_TASK"
                }
                val clickPendingIntent = android.app.PendingIntent.getBroadcast(
                    context, 0, clickIntent,
                    android.app.PendingIntent.FLAG_UPDATE_CURRENT or android.app.PendingIntent.FLAG_MUTABLE
                )
                setPendingIntentTemplate(R.id.tasks_list_view, clickPendingIntent)
            }
            appWidgetManager.updateAppWidget(widgetId, views)
            appWidgetManager.notifyAppWidgetViewDataChanged(widgetId, R.id.tasks_list_view)
        }
    }
}
