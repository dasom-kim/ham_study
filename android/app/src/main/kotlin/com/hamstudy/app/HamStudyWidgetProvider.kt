package com.hamstudy.app

import android.appwidget.AppWidgetManager
import android.appwidget.AppWidgetProvider
import android.content.Context
import android.graphics.Color
import android.widget.RemoteViews

class HamStudyWidgetProvider : AppWidgetProvider() {

    override fun onUpdate(
        context: Context,
        appWidgetManager: AppWidgetManager,
        appWidgetIds: IntArray
    ) {
        val prefs = context.getSharedPreferences("com.hamstudy.widget_prefs", Context.MODE_PRIVATE)
        val subjectName = prefs.getString("widget_subjectName", "대기 중") ?: "대기 중"
        val totalTime = prefs.getString("widget_totalTime", "00:00:00") ?: "00:00:00"
        val colorHex = prefs.getString("widget_subjectColor", "#FF9800") ?: "#FF9800"

        val color = try { Color.parseColor("#$colorHex") } catch (e: Exception) { Color.parseColor("#FF9800") }

        for (widgetId in appWidgetIds) {
            val views = RemoteViews(context.packageName, R.layout.widget_layout)
            views.setTextViewText(R.id.widget_subject_name, subjectName)
            views.setTextViewText(R.id.widget_total_time, totalTime)
            views.setTextColor(R.id.widget_title, color)
            views.setTextColor(R.id.widget_subject_name, color)

            // 타이머 탭(0)으로 이동
            val intent = context.packageManager.getLaunchIntentForPackage(context.packageName)
            if (intent != null) {
                intent.putExtra("widget_tab", 0)
                intent.addFlags(android.content.Intent.FLAG_ACTIVITY_SINGLE_TOP)
                val pendingIntent = android.app.PendingIntent.getActivity(
                    context, 10, intent,
                    android.app.PendingIntent.FLAG_UPDATE_CURRENT or android.app.PendingIntent.FLAG_IMMUTABLE
                )
                views.setOnClickPendingIntent(R.id.widget_root, pendingIntent)
            }

            appWidgetManager.updateAppWidget(widgetId, views)
        }
    }
}
