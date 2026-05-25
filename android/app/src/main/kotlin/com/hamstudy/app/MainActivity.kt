package com.hamstudy.app

import android.appwidget.AppWidgetManager
import android.content.ComponentName
import android.content.Context
import android.content.Intent
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel

class MainActivity : FlutterActivity() {
    private val CHANNEL = "com.hamstudy/widget"
    private val PREFS_NAME = "com.hamstudy.widget_prefs"

    // 위젯 클릭 시 이동할 탭 인덱스 (-1 = 위젯 클릭 아님)
    private var pendingWidgetTab: Int = -1
    private var methodChannel: MethodChannel? = null

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)

        val channel = MethodChannel(flutterEngine.dartExecutor.binaryMessenger, CHANNEL)
        methodChannel = channel

        // 콜드 스타트 시 intent에서 탭 읽기
        pendingWidgetTab = intent?.getIntExtra("widget_tab", -1) ?: -1

        channel.setMethodCallHandler { call, result ->
            when (call.method) {
                "updateWidget" -> {
                    val args = call.arguments as? Map<*, *>
                    if (args == null) {
                        result.error("INVALID_ARGS", "Arguments missing", null)
                        return@setMethodCallHandler
                    }
                    val prefs = getSharedPreferences(PREFS_NAME, Context.MODE_PRIVATE)
                    val editor = prefs.edit()
                    for ((key, value) in args) {
                        editor.putString(key.toString(), value.toString())
                    }
                    editor.apply()
                    updateWidget(this, HamStudyWidgetProvider::class.java)
                    updateWidget(this, HamStudyDdayWidgetProvider::class.java)
                    result.success(null)
                }
                "getInitialTab" -> {
                    // Flutter가 시작 시 탭 인덱스 요청
                    val tab = if (pendingWidgetTab >= 0) pendingWidgetTab else null
                    pendingWidgetTab = -1
                    result.success(tab)
                }
                else -> result.notImplemented()
            }
        }
    }

    // 앱이 이미 실행 중일 때 위젯 클릭 → onNewIntent 호출
    override fun onNewIntent(intent: Intent) {
        super.onNewIntent(intent)
        setIntent(intent)
        val tab = intent.getIntExtra("widget_tab", -1)
        if (tab >= 0) {
            // Flutter에 직접 탭 이동 명령 전달
            methodChannel?.invokeMethod("navigateToTab", tab)
        }
    }

    private fun updateWidget(context: Context, providerClass: Class<*>) {
        val manager = AppWidgetManager.getInstance(context)
        val ids = manager.getAppWidgetIds(ComponentName(context, providerClass))
        if (ids.isNotEmpty()) {
            val intent = Intent(context, providerClass).apply {
                action = AppWidgetManager.ACTION_APPWIDGET_UPDATE
                putExtra(AppWidgetManager.EXTRA_APPWIDGET_IDS, ids)
            }
            context.sendBroadcast(intent)
        }
    }
}
