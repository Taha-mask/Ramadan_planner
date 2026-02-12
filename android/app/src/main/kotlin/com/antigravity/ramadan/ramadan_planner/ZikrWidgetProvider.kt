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
import java.util.Calendar
import android.content.ClipData
import android.content.ClipboardManager
import android.widget.Toast

class ZikrWidgetProvider : HomeWidgetProvider() {
    override fun onUpdate(context: Context, appWidgetManager: AppWidgetManager, appWidgetIds: IntArray, widgetData: SharedPreferences) {
        appWidgetIds.forEach { widgetId ->
            val views = RemoteViews(context.packageName, R.layout.widget_zikr)
            
            val zikrListJson = widgetData.getString("zikr_list", "[]")
            // Check for manual index override
            val manualIndex = widgetData.getInt("zikr_manual_index_$widgetId", -1)
            
            val currentZikr = getZikrText(jsonStr = zikrListJson, manualIndex = manualIndex) 
                              ?: widgetData.getString("zikr_text", "سبحان الله وبحمده")

            views.setTextViewText(R.id.tv_zikr_content, currentZikr)
            
            // Next Button
            val nextIntent = Intent(context, ZikrWidgetProvider::class.java).apply {
                action = "ACTION_NEXT_ZIKR"
                putExtra(AppWidgetManager.EXTRA_APPWIDGET_ID, widgetId)
                data = Uri.parse("zikr://next/$widgetId")
            }
            val nextPendingIntent = PendingIntent.getBroadcast(
                context, widgetId, nextIntent, 
                PendingIntent.FLAG_UPDATE_CURRENT or PendingIntent.FLAG_IMMUTABLE
            )
            views.setOnClickPendingIntent(R.id.btn_next, nextPendingIntent)

            // Copy Button
            val copyIntent = Intent(context, ZikrWidgetProvider::class.java).apply {
                action = "ACTION_COPY_ZIKR"
                putExtra(AppWidgetManager.EXTRA_APPWIDGET_ID, widgetId)
                putExtra("EXTRA_TEXT", currentZikr)
                data = Uri.parse("zikr://copy/$widgetId")
            }
            val copyPendingIntent = PendingIntent.getBroadcast(
                context, widgetId + 1000, copyIntent, 
                PendingIntent.FLAG_UPDATE_CURRENT or PendingIntent.FLAG_IMMUTABLE
            )
            views.setOnClickPendingIntent(R.id.btn_copy, copyPendingIntent)
            
            appWidgetManager.updateAppWidget(widgetId, views)
        }
    }

    override fun onReceive(context: Context, intent: Intent) {
        super.onReceive(context, intent)
        val action = intent.action
        val widgetId = intent.getIntExtra(AppWidgetManager.EXTRA_APPWIDGET_ID, AppWidgetManager.INVALID_APPWIDGET_ID)
        
        if (widgetId != AppWidgetManager.INVALID_APPWIDGET_ID) {
            if (action == "ACTION_NEXT_ZIKR") {
                val prefs = context.getSharedPreferences("HomeWidgetPreferences", Context.MODE_PRIVATE)
                var index = prefs.getInt("zikr_manual_index_$widgetId", -1)
                
                // If distinct manual index not set, start from day offset
                if (index == -1) {
                     val calendar = Calendar.getInstance()
                     val dayOfYear = calendar.get(Calendar.DAY_OF_YEAR)
                     index = dayOfYear 
                }
                
                index++
                prefs.edit().putInt("zikr_manual_index_$widgetId", index).apply()
                
                // Update
                val appWidgetManager = AppWidgetManager.getInstance(context)
                onUpdate(context, appWidgetManager, intArrayOf(widgetId), prefs)
            
            } else if (action == "ACTION_COPY_ZIKR") {
                val text = intent.getStringExtra("EXTRA_TEXT") ?: ""
                if (text.isNotEmpty()) {
                    val clipboard = context.getSystemService(Context.CLIPBOARD_SERVICE) as ClipboardManager
                    val clip = ClipData.newPlainText("Zikr", text)
                    clipboard.setPrimaryClip(clip)
                    Toast.makeText(context, "تم النسخ", Toast.LENGTH_SHORT).show()
                }
            }
        }
    }

    private fun getZikrText(jsonStr: String?, manualIndex: Int): String? {
        if (jsonStr == null || jsonStr == "[]") return null
        try {
            val list = JSONArray(jsonStr)
            val len = list.length()
            if (len == 0) return null
            
            var index = manualIndex
            if (index == -1) {
                // Default to day of year
                val calendar = Calendar.getInstance()
                index = calendar.get(Calendar.DAY_OF_YEAR)
            }
            
            // Safe modulo
            val safeIndex = index % len
            return list.getString(safeIndex)
        } catch (e: Exception) {
            e.printStackTrace()
        }
        return null
    }
}
