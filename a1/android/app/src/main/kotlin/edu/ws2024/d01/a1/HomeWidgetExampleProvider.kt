package edu.ws2024.d01.a1

import es.antonborri.home_widget.HomeWidgetProvider
import es.antonborri.home_widget.HomeWidgetLaunchIntent

import android.content.Context
import android.content.SharedPreferences
import android.widget.RemoteViews
import android.appwidget.AppWidgetManager
import android.net.Uri

class HomeWidgetExampleProvider : HomeWidgetProvider() {
    override fun onUpdate(
            context: Context,
            appWidgetManager: AppWidgetManager,
            appWidgetIds: IntArray,
            widgetData: SharedPreferences) {
        appWidgetIds.forEach { widgetId ->
            val views = RemoteViews(context.packageName, R.layout.example_layout).apply {
                val genius = widgetData.getInt("valueGenius", 0)
                setTextViewText(R.id.valueGenius, genius.toString())

                val memo = widgetData.getInt("valueMemo", 0)
                setTextViewText(R.id.valueMemo, memo.toString())

                val quiz = widgetData.getInt("valueQuiz", 0)
                setTextViewText(R.id.valueQuiz, quiz.toString())

                val pendingIntentWithData = HomeWidgetLaunchIntent.getActivity(
                        context,
                        MainActivity::class.java,
                        Uri.parse("homeWidgetExample://message?message=ola"))
                setOnClickPendingIntent(R.id.app_widget, pendingIntentWithData)
            }
            appWidgetManager.updateAppWidget(widgetId, views)
        }
    }
}
