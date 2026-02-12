package com.antigravity.ramadan.ramadan_planner

import android.content.Context
import android.content.Intent
import android.widget.RemoteViews
import android.widget.RemoteViewsService
import android.content.SharedPreferences
import android.view.View
import org.json.JSONArray
import org.json.JSONObject

class TasksWidgetService : RemoteViewsService() {
    override fun onGetViewFactory(intent: Intent): RemoteViewsFactory {
        val appWidgetId = intent.getIntExtra(android.appwidget.AppWidgetManager.EXTRA_APPWIDGET_ID,
            android.appwidget.AppWidgetManager.INVALID_APPWIDGET_ID)
        return TasksRemoteViewsFactory(this.applicationContext, appWidgetId)
    }
}

class TasksRemoteViewsFactory(private val context: Context, private val appWidgetId: Int) : RemoteViewsService.RemoteViewsFactory {
    private var filteredTasks: JSONArray = JSONArray()

    override fun onCreate() {}

    override fun onDataSetChanged() {
        val sharedPrefs: SharedPreferences = context.getSharedPreferences("HomeWidgetPreferences", Context.MODE_PRIVATE)
        val tasksListJson = sharedPrefs.getString("tasks_list", "[]")
        
        try {
            val allTasks = JSONArray(tasksListJson)
            filteredTasks = allTasks // Use all by default or implement filtering logic here
        } catch (e: Exception) {
            filteredTasks = JSONArray()
        }
    }

    override fun onDestroy() {}

    override fun getCount(): Int = filteredTasks.length()

    override fun getViewAt(position: Int): RemoteViews {
        val views = RemoteViews(context.packageName, R.layout.task_item_layout)
        try {
            val task = filteredTasks.getJSONObject(position)
            val title = task.optString("title", "")
            val isCompleted = task.optBoolean("isCompleted", false)
            val type = task.optString("type", "todo")

            views.setTextViewText(R.id.tv_task_title, title)
            views.setTextViewText(R.id.tv_task_type, if (type == "habit_quit") "عادة للإقلاع" else if (type == "habit_acquire") "عادة للاكتساب" else "مهمة")
            
            if (isCompleted) {
                 views.setImageViewResource(R.id.iv_checkmark, android.R.drawable.checkbox_on_background)
                 views.setInt(R.id.iv_checkmark, "setColorFilter", android.graphics.Color.parseColor("#10B981")) // Emerald
                 // views.setInt(R.id.tv_task_title, "setPaintFlags", 16) // Strikethrough
            } else {
                 views.setImageViewResource(R.id.iv_checkmark, android.R.drawable.checkbox_off_background)
                 views.setInt(R.id.iv_checkmark, "setColorFilter", android.graphics.Color.parseColor("#9E9E9E")) // Grey
                 // views.setInt(R.id.tv_task_title, "setPaintFlags", 0)
            }

            // Fill-in intent for Deep Link
            val fillInIntent = Intent().apply {
                putExtra("task_id", task.optString("id"))
                putExtra("route", "tasks")
            }
            views.setOnClickFillInIntent(R.id.item_container, fillInIntent)
            
        } catch (e: Exception) {
            e.printStackTrace()
        }
        return views
    }

    override fun getLoadingView(): RemoteViews? = null
    override fun getViewTypeCount(): Int = 1
    override fun getItemId(position: Int): Long = position.toLong()
    override fun hasStableIds(): Boolean = true
}
