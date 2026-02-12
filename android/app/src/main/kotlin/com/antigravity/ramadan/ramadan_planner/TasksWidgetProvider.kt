package com.antigravity.ramadan.ramadan_planner

import android.appwidget.AppWidgetManager
import android.content.Context
import android.content.Intent
import android.content.SharedPreferences
import android.net.Uri
import android.widget.RemoteViews
import es.antonborri.home_widget.HomeWidgetProvider
import android.app.PendingIntent

class TasksWidgetProvider : HomeWidgetProvider() {
    override fun onUpdate(context: Context, appWidgetManager: AppWidgetManager, appWidgetIds: IntArray, widgetData: SharedPreferences) {
        appWidgetIds.forEach { widgetId ->
            val views = RemoteViews(context.packageName, R.layout.widget_tasks).apply {
                // Set Adapter
                val intent = Intent(context, TasksWidgetService::class.java).apply {
                    putExtra(AppWidgetManager.EXTRA_APPWIDGET_ID, widgetId)
                    data = Uri.parse(toUri(Intent.URI_INTENT_SCHEME))
                }
                setRemoteAdapter(R.id.lv_tasks, intent)
                setEmptyView(R.id.lv_tasks, R.id.tv_empty)
                
                // Set Counts and Title
                val doneCount = widgetData.getInt("tasks_done_count", 0)
                val totalCount = widgetData.getInt("tasks_total_count", 0)
                val remaining = totalCount - doneCount
                setTextViewText(R.id.tv_subtitle, "$remaining مهام متبقية")
                
                // Add Task Button Click -> Open Add Task Screen
                val addIntent = Intent(context, MainActivity::class.java).apply {
                    action = "ADD_TASK"
                    flags = Intent.FLAG_ACTIVITY_NEW_TASK or Intent.FLAG_ACTIVITY_CLEAR_TASK
                }
                val addPendingIntent = PendingIntent.getActivity(
                    context, 2, addIntent,
                    PendingIntent.FLAG_UPDATE_CURRENT or PendingIntent.FLAG_IMMUTABLE
                )
                setOnClickPendingIntent(R.id.btn_add_task, addPendingIntent)

                // List Item Click Template
                val clickIntent = Intent(context, MainActivity::class.java).apply {
                    action = "OPEN_TASK"
                }
                val clickPendingIntent = PendingIntent.getActivity(
                    context, 1, clickIntent, 
                    PendingIntent.FLAG_UPDATE_CURRENT or PendingIntent.FLAG_MUTABLE 
                )
                setPendingIntentTemplate(R.id.lv_tasks, clickPendingIntent)
            }
            
            appWidgetManager.updateAppWidget(widgetId, views)
            appWidgetManager.notifyAppWidgetViewDataChanged(widgetId, R.id.lv_tasks)
        }
    }
}
