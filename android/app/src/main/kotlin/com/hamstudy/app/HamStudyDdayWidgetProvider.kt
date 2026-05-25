package com.hamstudy.app

import android.appwidget.AppWidgetManager
import android.appwidget.AppWidgetProvider
import android.content.Context
import android.graphics.Color
import android.widget.RemoteViews
import org.json.JSONArray

class HamStudyDdayWidgetProvider : AppWidgetProvider() {

    override fun onUpdate(
        context: Context,
        appWidgetManager: AppWidgetManager,
        appWidgetIds: IntArray
    ) {
        val prefs = context.getSharedPreferences("com.hamstudy.widget_prefs", Context.MODE_PRIVATE)
        val ddayJson = prefs.getString("widget_ddayList", "[]") ?: "[]"

        val ddayList = parseDdayList(ddayJson)

        for (widgetId in appWidgetIds) {
            val views = RemoteViews(context.packageName, R.layout.dday_widget_layout)

            if (ddayList.isEmpty()) {
                views.setTextViewText(R.id.dday_empty, "즐겨찾기 디데이 없음")
                views.setViewVisibility(R.id.dday_empty, android.view.View.VISIBLE)
                views.setViewVisibility(R.id.dday_list_container, android.view.View.GONE)
            } else {
                views.setViewVisibility(R.id.dday_empty, android.view.View.GONE)
                views.setViewVisibility(R.id.dday_list_container, android.view.View.VISIBLE)

                // 최대 4개 표시
                val displayList = ddayList.take(4)
                val rowIds = listOf(
                    Pair(R.id.dday_row1, Pair(R.id.dday_title1, R.id.dday_value1)),
                    Pair(R.id.dday_row2, Pair(R.id.dday_title2, R.id.dday_value2)),
                    Pair(R.id.dday_row3, Pair(R.id.dday_title3, R.id.dday_value3)),
                    Pair(R.id.dday_row4, Pair(R.id.dday_title4, R.id.dday_value4)),
                )

                rowIds.forEachIndexed { index, (rowId, textIds) ->
                    if (index < displayList.size) {
                        val item = displayList[index]
                        views.setViewVisibility(rowId, android.view.View.VISIBLE)
                        views.setTextViewText(textIds.first, item.first)
                        views.setTextViewText(textIds.second, item.second)
                        val color = ddayColor(item.second)
                        views.setTextColor(textIds.second, color)
                    } else {
                        views.setViewVisibility(rowId, android.view.View.GONE)
                    }
                }
            }

            // 디데이 탭(1)으로 이동
            val intent = context.packageManager.getLaunchIntentForPackage(context.packageName)
            if (intent != null) {
                intent.putExtra("widget_tab", 1)
                intent.addFlags(android.content.Intent.FLAG_ACTIVITY_SINGLE_TOP)
                val pendingIntent = android.app.PendingIntent.getActivity(
                    context, 11, intent,
                    android.app.PendingIntent.FLAG_UPDATE_CURRENT or android.app.PendingIntent.FLAG_IMMUTABLE
                )
                views.setOnClickPendingIntent(R.id.dday_root, pendingIntent)
            }

            appWidgetManager.updateAppWidget(widgetId, views)
        }
    }

    private fun parseDdayList(json: String): List<Pair<String, String>> {
        return try {
            val array = JSONArray(json)
            (0 until array.length()).map { i ->
                val obj = array.getJSONObject(i)
                Pair(obj.getString("title"), obj.getString("dday"))
            }
        } catch (e: Exception) {
            emptyList()
        }
    }

    private fun ddayColor(text: String): Int {
        return when {
            text == "D-Day" -> Color.RED
            text.startsWith("D+") -> Color.GRAY
            else -> Color.parseColor("#FF5722") // deepOrange
        }
    }
}
