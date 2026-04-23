import 'package:flutter/foundation.dart';
import 'package:home_widget/home_widget.dart';

/// Service to update the Android home screen widget with health data.
class WidgetService {
  static const String _appGroupId = 'com.medinutri.widget';
  static const String _widgetName = 'HealthWidgetProvider';

  /// Initialize home widget.
  static Future<void> initialize() async {
    try {
      await HomeWidget.setAppGroupId(_appGroupId);
      debugPrint('[WidgetService] Initialized');
    } catch (e) {
      debugPrint('[WidgetService] Init error: $e');
    }
  }

  /// Update widget data and request refresh.
  static Future<void> updateWidget({
    String? userName,
    double? bmi,
    String? bmiCategory,
    int? tdee,
    String? nextMeal,
    String? nextMealTime,
    int? activeMedications,
    String? healthTip,
  }) async {
    try {
      if (userName != null) {
        await HomeWidget.saveWidgetData('user_name', userName);
      }
      if (bmi != null) {
        await HomeWidget.saveWidgetData('bmi', bmi.toStringAsFixed(1));
      }
      if (bmiCategory != null) {
        await HomeWidget.saveWidgetData('bmi_category', bmiCategory);
      }
      if (tdee != null) {
        await HomeWidget.saveWidgetData('tdee', '$tdee kcal');
      }
      if (nextMeal != null) {
        await HomeWidget.saveWidgetData('next_meal', nextMeal);
      }
      if (nextMealTime != null) {
        await HomeWidget.saveWidgetData('next_meal_time', nextMealTime);
      }
      if (activeMedications != null) {
        await HomeWidget.saveWidgetData('medications', '$activeMedications');
      }
      if (healthTip != null) {
        await HomeWidget.saveWidgetData('health_tip', healthTip);
      }

      // Update timestamp
      await HomeWidget.saveWidgetData(
        'last_update',
        DateTime.now().toIso8601String().substring(11, 16),
      );

      await HomeWidget.updateWidget(
        androidName: _widgetName,
        iOSName: _widgetName,
      );
      debugPrint('[WidgetService] Widget updated');
    } catch (e) {
      debugPrint('[WidgetService] Update error: $e');
    }
  }
}
