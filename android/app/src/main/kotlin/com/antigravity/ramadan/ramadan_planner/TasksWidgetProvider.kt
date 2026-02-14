package com.antigravity.ramadan.ramadan_planner

import android.appwidget.AppWidgetManager
import android.content.Context
import android.content.Intent
import android.content.SharedPreferences
import android.net.Uri
import android.widget.RemoteViews
import es.antonborri.home_widget.HomeWidgetProvider
import android.app.PendingIntent
import org.json.JSONArray
import org.json.JSONObject

class TasksWidgetProvider : HomeWidgetProvider() {
    private fun getSafeInt(prefs: SharedPreferences, key: String, default: Int): Int {
        return try {
            prefs.getInt(key, default)
        } catch (e: Exception) {
            prefs.all[key]?.toString()?.toIntOrNull() ?: default
        }
    }

    private fun getSafeString(prefs: SharedPreferences, key: String, default: String): String {
        return try {
            prefs.getString(key, default) ?: default
        } catch (e: Exception) {
            prefs.all[key]?.toString() ?: default
        }
    }

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
                val doneCount = getSafeInt(widgetData, "tasks_done_count", 0)
                val totalCount = getSafeInt(widgetData, "tasks_total_count", 0)
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
                val clickIntent = Intent(context, TasksWidgetProvider::class.java).apply {
                    action = "ACTION_TASK_ITEM_CLICK"
                    putExtra(AppWidgetManager.EXTRA_APPWIDGET_ID, widgetId)
                    data = Uri.parse(toUri(Intent.URI_INTENT_SCHEME))
                }
                val clickPendingIntent = PendingIntent.getBroadcast(
                    context, widgetId, clickIntent, 
                    PendingIntent.FLAG_UPDATE_CURRENT or PendingIntent.FLAG_MUTABLE 
                )
                setPendingIntentTemplate(R.id.lv_tasks, clickPendingIntent)
            }
            
            appWidgetManager.updateAppWidget(widgetId, views)
            appWidgetManager.notifyAppWidgetViewDataChanged(widgetId, R.id.lv_tasks)
        }
    }


    override fun onReceive(context: Context, intent: Intent) {
        if (intent.action == "ACTION_TASK_ITEM_CLICK") {
            val taskId = intent.getStringExtra("task_id")
            val clickAction = intent.getStringExtra("click_action")
            
            if (clickAction == "open") {
                 val openIntent = Intent(context, MainActivity::class.java).apply {
                    flags = Intent.FLAG_ACTIVITY_NEW_TASK or Intent.FLAG_ACTIVITY_CLEAR_TASK
                 }
                 context.startActivity(openIntent)
            } else if (clickAction == "toggle") {
                 toggleTask(context, taskId)
            }
        } else {
            super.onReceive(context, intent)
        }
    }

    private fun toggleTask(context: Context, taskId: String?) {
        if (taskId == null) return
        val prefs = context.getSharedPreferences("HomeWidgetPreferences", Context.MODE_PRIVATE)
        val tasksJson = getSafeString(prefs, "tasks_list", "[]")
        try {
            val jsonArray = JSONArray(tasksJson)
            var updated = false
            for (i in 0 until jsonArray.length()) {
                val task = jsonArray.getJSONObject(i)
                val id = task.opt("id").toString()
                if (id == taskId) {
                    val isCompleted = task.optBoolean("isCompleted", false)
                    task.put("isCompleted", !isCompleted)
                    updated = true
                    break
                }
            }
            if (updated) {
                 prefs.edit().putString("tasks_list", jsonArray.toString()).apply()
                 // Update counts
                 var done = 0
                 for (i in 0 until jsonArray.length()) {
                     if (jsonArray.getJSONObject(i).optBoolean("isCompleted")) done++
                 }
                 prefs.edit().putInt("tasks_done_count", done).apply()
                 
                 // Notify widget update
                 val appWidgetManager = AppWidgetManager.getInstance(context)
                 val componentName = android.content.ComponentName(context, TasksWidgetProvider::class.java)
                 val appWidgetIds = appWidgetManager.getAppWidgetIds(componentName)
                 onUpdate(context, appWidgetManager, appWidgetIds, prefs)
                 appWidgetManager.notifyAppWidgetViewDataChanged(appWidgetIds, R.id.lv_tasks)
            }
        } catch (e: Exception) {
            e.printStackTrace()
        }
    }
}
