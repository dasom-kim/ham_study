package com.example.ham_study // 앱의 실제 패키지명으로 확인 및 변경해주세요

import android.appwidget.AppWidgetManager
import android.content.Context
import android.content.SharedPreferences
import android.graphics.Color
import android.widget.RemoteViews
import es.antonborri.home_widget.HomeWidgetLaunchIntent
import es.antonborri.home_widget.HomeWidgetProvider

class HamStudyWidgetProvider : HomeWidgetProvider() {
    
    override fun onUpdate(
        context: Context,
        appWidgetManager: AppWidgetManager,
        appWidgetIds: IntArray,
        widgetData: SharedPreferences
    ) {
        for (widgetId in appWidgetIds) {
            val views = RemoteViews(context.packageName, R.layout.widget_layout)

            // Flutter에서 저장한 데이터를 읽어옵니다. (HomeWidget.saveWidgetData)
            views.setTextViewText(R.id.widget_subject_name, widgetData.getString("widget_subjectName", "대기 중"))
            views.setTextViewText(R.id.widget_total_time, widgetData.getString("widget_totalTime", "00:00:00"))

            // 1. 과목 색상을 읽어와서 위젯 텍스트에 반영
            val subjectColorHex = widgetData.getString("widget_subjectColor", "#FF9800")
            try {
                val colorInt = Color.parseColor(subjectColorHex)
                views.setTextColor(R.id.widget_title, colorInt)
                views.setTextColor(R.id.widget_subject_name, colorInt)
            } catch (e: Exception) {
                e.printStackTrace() // 잘못된 색상 코드가 넘어올 경우 방어
            }

            // 2. 위젯 전체(widget_root) 클릭 시 앱 실행 (MainActivity 호출)
            val pendingIntent = HomeWidgetLaunchIntent.getActivity(context, MainActivity::class.java)
            views.setOnClickPendingIntent(R.id.widget_root, pendingIntent)

            // 위젯 업데이트를 수행합니다.
            appWidgetManager.updateAppWidget(widgetId, views)
        }
    }
}