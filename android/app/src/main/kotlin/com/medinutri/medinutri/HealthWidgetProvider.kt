package com.medinutri.medinutri

import android.appwidget.AppWidgetManager
import android.content.Context
import android.content.SharedPreferences
import android.widget.RemoteViews
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

            val userName = widgetData.getString("user_name", "MediNutri") ?: "MediNutri"
            val bmi = widgetData.getString("bmi", "--") ?: "--"
            val bmiCategory = widgetData.getString("bmi_category", "") ?: ""
            val tdee = widgetData.getString("tdee", "-- kcal") ?: "-- kcal"
            val nextMeal = widgetData.getString("next_meal", "Aucun plan") ?: "Aucun plan"
            val nextMealTime = widgetData.getString("next_meal_time", "") ?: ""
            val medications = widgetData.getString("medications", "0") ?: "0"
            val lastUpdate = widgetData.getString("last_update", "--:--") ?: "--:--"

            views.setTextViewText(R.id.widget_title, "🩺 $userName")
            views.setTextViewText(R.id.widget_bmi_value, bmi)
            views.setTextViewText(R.id.widget_bmi_label, bmiCategory)
            views.setTextViewText(R.id.widget_tdee, "🔥 $tdee")
            views.setTextViewText(R.id.widget_next_meal, "🍽️ $nextMeal")
            views.setTextViewText(R.id.widget_meal_time, nextMealTime)
            views.setTextViewText(R.id.widget_medications, "💊 $medications médicament(s)")
            views.setTextViewText(R.id.widget_last_update, "⏱ $lastUpdate")

            appWidgetManager.updateAppWidget(appWidgetId, views)
        }
    }
}
