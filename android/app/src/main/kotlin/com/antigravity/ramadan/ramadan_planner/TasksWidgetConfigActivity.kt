package com.antigravity.ramadan.ramadan_planner

import android.app.Activity
import android.appwidget.AppWidgetManager
import android.content.Context
import android.content.Intent
import android.os.Bundle
import android.widget.Button
import android.widget.RadioGroup

class TasksWidgetConfigActivity : Activity() {

    private var appWidgetId = AppWidgetManager.INVALID_APPWIDGET_ID

    override fun onCreate(savedInstanceState: Bundle?) {
        super.onCreate(savedInstanceState)
        setContentView(R.layout.activity_tasks_widget_config)

        val intent = intent
        val extras = intent.extras
        if (extras != null) {
            appWidgetId = extras.getInt(
                AppWidgetManager.EXTRA_APPWIDGET_ID,
                AppWidgetManager.INVALID_APPWIDGET_ID
            )
        }

        if (appWidgetId == AppWidgetManager.INVALID_APPWIDGET_ID) {
            finish()
            return
        }

        val btnSave = findViewById<Button>(R.id.btn_save_config)
        val radioGroup = findViewById<RadioGroup>(R.id.radio_group_filter)

        btnSave.setOnClickListener {
            val selectedId = radioGroup.checkedRadioButtonId
            val filterType = when (selectedId) {
                R.id.option_todos -> "todo"
                R.id.option_habits -> "habit"
                else -> "all"
            }

            val prefs = getSharedPreferences("HomeWidgetPreferences", Context.MODE_PRIVATE)
            val edit = prefs.edit()
            edit.putString("filter_type_$appWidgetId", filterType)
            edit.apply()

            // Update widget
            val appWidgetManager = AppWidgetManager.getInstance(this)
            val provider = TasksWidgetProvider()
            provider.onUpdate(this, appWidgetManager, intArrayOf(appWidgetId), prefs)

            val resultValue = Intent()
            resultValue.putExtra(AppWidgetManager.EXTRA_APPWIDGET_ID, appWidgetId)
            setResult(RESULT_OK, resultValue)
            finish()
        }
    }
}
