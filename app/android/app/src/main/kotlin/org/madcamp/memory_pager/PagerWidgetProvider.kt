package org.madcamp.memory_pager

import android.appwidget.AppWidgetManager
import android.content.Context
import android.content.SharedPreferences
import android.widget.RemoteViews
import es.antonborri.home_widget.HomeWidgetProvider

/**
 * 홈 화면 위젯 — 펫 이름·레벨·말풍선을 보여준다.
 * 데이터는 Flutter 쪽 HomeWidget.saveWidgetData 로 채워진다.
 */
class PagerWidgetProvider : HomeWidgetProvider() {
    override fun onUpdate(
        context: Context,
        appWidgetManager: AppWidgetManager,
        appWidgetIds: IntArray,
        widgetData: SharedPreferences,
    ) {
        appWidgetIds.forEach { widgetId ->
            val views = RemoteViews(context.packageName, R.layout.pager_widget).apply {
                setTextViewText(
                    R.id.widget_pet_name,
                    widgetData.getString("pet_name", "모리") ?: "모리",
                )
                setTextViewText(
                    R.id.widget_pet_level,
                    widgetData.getString("pet_level", "Lv.1") ?: "Lv.1",
                )
                setTextViewText(
                    R.id.widget_pet_bubble,
                    widgetData.getString("pet_bubble", "삐삐! 낙서 기다리는 중") ?: "삐삐!",
                )
            }
            appWidgetManager.updateAppWidget(widgetId, views)
        }
    }
}
