package com.medinutri.medinutri

import android.app.PendingIntent
import android.appwidget.AppWidgetManager
import android.content.Context
import android.content.Intent
import android.content.SharedPreferences
import android.widget.RemoteViews
import com.medinutri.medinutri.R
import es.antonborri.home_widget.HomeWidgetProvider

class HealthWidgetProvider : HomeWidgetProvider() {
    override fun onUpdate(
        context: Context,
        appWidgetManager: AppWidgetManager,
        appWidgetIds: IntArray,
        widgetData: SharedPreferences
    ) {
        for (appWidgetId in appWidgetIds) {
            val views = RemoteViews(context.packageName, R.layout.health_widget_layout)

            // Data extraction
            val userName = widgetData.getString("user_name", "MediNutri") ?: "MediNutri"
            val bmi = widgetData.getString("bmi", "--") ?: "--"
            val bmiCategory = widgetData.getString("bmi_category", "") ?: ""
            val tdee = widgetData.getString("tdee", "-- kcal") ?: "-- kcal"
            
            val breakfast = widgetData.getString("breakfast", "--") ?: "--"
            val lunch = widgetData.getString("lunch", "--") ?: "--"
            val dinner = widgetData.getString("dinner", "--") ?: "--"
            
            val medications = widgetData.getString("medications", "0") ?: "0"
            val lastUpdate = widgetData.getString("last_update", "--:--") ?: "--:--"

            // UI Update
            views.setTextViewText(R.id.widget_title, "🩺 $userName")
            views.setTextViewText(R.id.widget_bmi_value, bmi)
            views.setTextViewText(R.id.widget_bmi_label, bmiCategory)
            views.setTextViewText(R.id.widget_tdee, "🔥 $tdee")
            
            views.setTextViewText(R.id.widget_breakfast, "☕ $breakfast")
            views.setTextViewText(R.id.widget_lunch, "🍱 $lunch")
            views.setTextViewText(R.id.widget_dinner, "🥣 $dinner")
            
            views.setTextViewText(R.id.widget_medications, "💊 $medications")
            views.setTextViewText(R.id.widget_last_update, "⏱ $lastUpdate")

            // Click Redirection to App
            val intent = Intent(context, MainActivity::class.java)
            val pendingIntent = PendingIntent.getActivity(
                context, 
                0, 
                intent, 
                PendingIntent.FLAG_UPDATE_CURRENT or PendingIntent.FLAG_IMMUTABLE
            )
            views.setOnClickPendingIntent(R.id.widget_container, pendingIntent)

            appWidgetManager.updateAppWidget(appWidgetId, views)
        }
    }
}
