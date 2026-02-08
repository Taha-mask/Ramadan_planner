package com.antigravity.ramadan.ramadan_planner

import android.content.BroadcastReceiver
import android.content.Context
import android.content.Intent
import android.content.SharedPreferences
import android.appwidget.AppWidgetManager
import org.json.JSONArray
import org.json.JSONObject

class TasksWidgetReceiver : BroadcastReceiver() {
    override fun onReceive(context: Context, intent: Intent) {
        if (intent.action == "com.antigravity.ramadan.ACTION_TOGGLE_TASK") {
            val taskId = intent.getIntExtra("task_id", -1)
            if (taskId != -1) {
                toggleTaskInBackground(context, taskId)
            }
        }
    }

    private fun toggleTaskInBackground(context: Context, taskId: Int) {
        val sharedPrefs: SharedPreferences = context.getSharedPreferences("HomeWidgetPreferences", Context.MODE_PRIVATE)
        val tasksListJson = sharedPrefs.getString("tasks_list", "[]")
        val tasks = JSONArray(tasksListJson)
        
        var found = false
        var doneCount = 0
        for (i in 0 until tasks.length()) {
            val task = tasks.getJSONObject(i)
            if (task.getInt("id") == taskId) {
                task.put("isCompleted", !task.getBoolean("isCompleted"))
                found = true
            }
            if (task.getBoolean("isCompleted")) {
                doneCount++
            }
        }

        if (found) {
            sharedPrefs.edit().apply {
                putString("tasks_list", tasks.toString())
                putInt("tasks_done_count", doneCount)
                apply()
            }
            
            // Notify system to update widgets
            val manager = AppWidgetManager.getInstance(context)
            val tasksWidget = android.content.ComponentName(context, TasksWidgetProvider::class.java)
            val ids = manager.getAppWidgetIds(tasksWidget)
            val intentUpdate = Intent(context, TasksWidgetProvider::class.java).apply {
                action = AppWidgetManager.ACTION_APPWIDGET_UPDATE
                putExtra(AppWidgetManager.EXTRA_APPWIDGET_IDS, ids)
            }
            context.sendBroadcast(intentUpdate)
        }
    }
}
