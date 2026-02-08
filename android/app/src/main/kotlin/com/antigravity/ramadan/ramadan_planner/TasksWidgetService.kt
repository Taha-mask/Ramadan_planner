package com.antigravity.ramadan.ramadan_planner

import android.content.Context
import android.content.Intent
import android.content.SharedPreferences
import android.widget.RemoteViews
import android.widget.RemoteViewsService
import org.json.JSONArray
import org.json.JSONObject

class TasksWidgetService : RemoteViewsService() {
    override fun onGetViewFactory(intent: Intent): RemoteViewsFactory {
        return TasksRemoteViewsFactory(this.applicationContext)
    }
}

class TasksRemoteViewsFactory(private val context: Context) : RemoteViewsService.RemoteViewsFactory {
    private var tasks: JSONArray = JSONArray()

    override fun onCreate() {}

    override fun onDataSetChanged() {
        val sharedPrefs: SharedPreferences = context.getSharedPreferences("HomeWidgetPreferences", Context.MODE_PRIVATE)
        val tasksListJson = sharedPrefs.getString("tasks_list", "[]")
        tasks = JSONArray(tasksListJson)
    }

    override fun onDestroy() {}

    override fun getCount(): Int = tasks.length()

    override fun getViewAt(position: Int): RemoteViews {
        val views = RemoteViews(context.packageName, R.layout.task_item_layout)
        try {
            val task = tasks.getJSONObject(position)
            val title = task.getString("title")
            val isCompleted = task.getBoolean("isCompleted")

            views.setTextViewText(R.id.task_item_title, title)
            if (isCompleted) {
                views.setImageViewResource(R.id.task_check_icon, R.drawable.ic_check_mark)
                // Gold Color for checkmark
                views.setInt(R.id.task_check_icon, "setColorFilter", android.graphics.Color.parseColor("#FFD700"))
            } else {
                views.setImageViewResource(R.id.task_check_icon, R.drawable.ic_uncheck_circle)
                // Darker Gray for unchecked circle
                views.setInt(R.id.task_check_icon, "setColorFilter", android.graphics.Color.parseColor("#757575"))
            }

            // Fill-in intent for clicks
            val fillInIntent = Intent().apply {
                putExtra("task_id", task.getInt("id"))
            }
            views.setOnClickFillInIntent(R.id.task_item_container, fillInIntent)
            views.setOnClickFillInIntent(R.id.task_check_icon, fillInIntent)
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
