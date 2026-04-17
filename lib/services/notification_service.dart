import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:timezone/timezone.dart' as tz;
import 'package:timezone/data/latest.dart' as tz_data;

/// Service de notifications pour les rappels de repas MediNutri.
/// Gère les rappels pour le petit-déjeuner, déjeuner et dîner.
class NotificationService {
  static final NotificationService instance = NotificationService._();
  NotificationService._();

  final FlutterLocalNotificationsPlugin _plugin =
      FlutterLocalNotificationsPlugin();

  // ── Clés SharedPreferences ──────────────────────────────
  static const _keyEnabled = 'notif_enabled';
  static const _keyBreakfastHour = 'notif_breakfast_hour';
  static const _keyBreakfastMin = 'notif_breakfast_min';
  static const _keyLunchHour = 'notif_lunch_hour';
  static const _keyLunchMin = 'notif_lunch_min';
  static const _keyDinnerHour = 'notif_dinner_hour';
  static const _keyDinnerMin = 'notif_dinner_min';
  static const _keyBreakfastEnabled = 'notif_breakfast_on';
  static const _keyLunchEnabled = 'notif_lunch_on';
  static const _keyDinnerEnabled = 'notif_dinner_on';
  static const _keyWaterEnabled = 'notif_water_on';

  // ── IDs de notifications ────────────────────────────────
  static const _breakfastId = 100;
  static const _lunchId = 200;
  static const _dinnerId = 300;
  // Water IDs: 400-409

  // ── Messages de notification variés ─────────────────────
  static const _breakfastMessages = [
    '🌅 Bonjour ! C\'est l\'heure du petit-déjeuner. Consultez votre plan MediNutri !',
    '☀️ Bien dormi ? Commencez la journée avec un bon petit-déj tunisien !',
    '🥐 N\'oubliez pas votre petit-déjeuner ! Votre plan nutritionnel vous attend.',
    '🍳 Votre corps a besoin d\'énergie ! Petit-déjeuner = santé.',
  ];

  static const _lunchMessages = [
    '🍽️ C\'est l\'heure du déjeuner ! Découvrez votre repas du jour.',
    '🥘 Pause midi ! Votre plan nutrition tunisien est prêt.',
    '🫒 Il est temps de manger ! Suivez votre programme MediNutri.',
    '🍲 Le déjeuner vous attend ! Un bon plat tunisien pour recharger.',
  ];

  static const _dinnerMessages = [
    '🌙 C\'est l\'heure du dîner ! Votre repas du soir est planifié.',
    '🍴 Bon appétit ! Consultez votre dîner dans MediNutri.',
    '🥗 Dîner léger et équilibré ce soir — votre plan est prêt !',
    '✨ Dernière dose de nutrition pour aujourd\'hui !',
  ];

  static const _waterMessages = [
    '💧 N\'oubliez pas de boire de l\'eau ! Votre corps en a besoin.',
    '🚰 Pause hydratation ! Buvez un verre d\'eau.',
    '💦 Restez hydraté ! Un verre d\'eau pour votre santé.',
    '🥤 Rappel : boire de l\'eau = plus d\'énergie !',
  ];

  /// Initialise le plugin de notifications.
  Future<void> initialize() async {
    tz_data.initializeTimeZones();

    const androidSettings = AndroidInitializationSettings('@mipmap/launcher_icon');
    const iosSettings = DarwinInitializationSettings(
      requestAlertPermission: true,
      requestBadgePermission: true,
      requestSoundPermission: true,
    );

    const initSettings = InitializationSettings(
      android: androidSettings,
      iOS: iosSettings,
    );

    await _plugin.initialize(
      settings: initSettings,
      onDidReceiveNotificationResponse: _onNotificationTapped,
    );

    // Demander la permission sur Android 13+
    await _requestPermissions();

    // Restaurer les notifications programmées si activées
    await _restoreScheduledNotifications();
  }

  Future<void> _requestPermissions() async {
    final androidPlugin = _plugin.resolvePlatformSpecificImplementation<
        AndroidFlutterLocalNotificationsPlugin>();
    if (androidPlugin != null) {
      await androidPlugin.requestNotificationsPermission();
      await androidPlugin.requestExactAlarmsPermission();
    }
  }

  void _onNotificationTapped(NotificationResponse response) {
    debugPrint('[NotificationService] Notification tapped: ${response.payload}');
  }

  // ─────────────────────────────────────────────────────────
  //  GETTERS / SETTERS — Préférences
  // ─────────────────────────────────────────────────────────

  Future<bool> get isEnabled async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(_keyEnabled) ?? false;
  }

  Future<bool> get isBreakfastEnabled async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(_keyBreakfastEnabled) ?? true;
  }

  Future<bool> get isLunchEnabled async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(_keyLunchEnabled) ?? true;
  }

  Future<bool> get isDinnerEnabled async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(_keyDinnerEnabled) ?? true;
  }

  Future<bool> get isWaterEnabled async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(_keyWaterEnabled) ?? false;
  }

  Future<TimeOfDay> getBreakfastTime() async {
    final prefs = await SharedPreferences.getInstance();
    return TimeOfDay(
      hour: prefs.getInt(_keyBreakfastHour) ?? 7,
      minute: prefs.getInt(_keyBreakfastMin) ?? 30,
    );
  }

  Future<TimeOfDay> getLunchTime() async {
    final prefs = await SharedPreferences.getInstance();
    return TimeOfDay(
      hour: prefs.getInt(_keyLunchHour) ?? 12,
      minute: prefs.getInt(_keyLunchMin) ?? 30,
    );
  }

  Future<TimeOfDay> getDinnerTime() async {
    final prefs = await SharedPreferences.getInstance();
    return TimeOfDay(
      hour: prefs.getInt(_keyDinnerHour) ?? 19,
      minute: prefs.getInt(_keyDinnerMin) ?? 30,
    );
  }

  // ─────────────────────────────────────────────────────────
  //  ACTIVER / DÉSACTIVER GLOBALEMENT
  // ─────────────────────────────────────────────────────────

  Future<void> setEnabled(bool value) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_keyEnabled, value);
    if (value) {
      await scheduleAllMealReminders();
    } else {
      await cancelAllNotifications();
    }
  }

  Future<void> setBreakfastEnabled(bool value) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_keyBreakfastEnabled, value);
    if (value && await isEnabled) {
      await _scheduleBreakfast();
    } else {
      await _plugin.cancel(id: _breakfastId);
    }
  }

  Future<void> setLunchEnabled(bool value) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_keyLunchEnabled, value);
    if (value && await isEnabled) {
      await _scheduleLunch();
    } else {
      await _plugin.cancel(id: _lunchId);
    }
  }

  Future<void> setDinnerEnabled(bool value) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_keyDinnerEnabled, value);
    if (value && await isEnabled) {
      await _scheduleDinner();
    } else {
      await _plugin.cancel(id: _dinnerId);
    }
  }

  Future<void> setWaterEnabled(bool value) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_keyWaterEnabled, value);
    if (value && await isEnabled) {
      await _scheduleWaterReminders();
    } else {
      for (int i = 0; i < 10; i++) {
        await _plugin.cancel(id: 400 + i);
      }
    }
  }

  // ─────────────────────────────────────────────────────────
  //  METTRE À JOUR LES HEURES
  // ─────────────────────────────────────────────────────────

  Future<void> setBreakfastTime(TimeOfDay time) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt(_keyBreakfastHour, time.hour);
    await prefs.setInt(_keyBreakfastMin, time.minute);
    if (await isEnabled && await isBreakfastEnabled) {
      await _scheduleBreakfast();
    }
  }

  Future<void> setLunchTime(TimeOfDay time) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt(_keyLunchHour, time.hour);
    await prefs.setInt(_keyLunchMin, time.minute);
    if (await isEnabled && await isLunchEnabled) {
      await _scheduleLunch();
    }
  }

  Future<void> setDinnerTime(TimeOfDay time) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt(_keyDinnerHour, time.hour);
    await prefs.setInt(_keyDinnerMin, time.minute);
    if (await isEnabled && await isDinnerEnabled) {
      await _scheduleDinner();
    }
  }

  // ─────────────────────────────────────────────────────────
  //  PROGRAMMER LES NOTIFICATIONS
  // ─────────────────────────────────────────────────────────

  Future<void> scheduleAllMealReminders() async {
    if (await isBreakfastEnabled) await _scheduleBreakfast();
    if (await isLunchEnabled) await _scheduleLunch();
    if (await isDinnerEnabled) await _scheduleDinner();
    if (await isWaterEnabled) await _scheduleWaterReminders();
  }

  Future<void> _scheduleBreakfast() async {
    final time = await getBreakfastTime();
    final msg = _breakfastMessages[DateTime.now().day % _breakfastMessages.length];
    await _scheduleDailyNotification(
      id: _breakfastId,
      title: '🌅 Petit-déjeuner',
      body: msg,
      hour: time.hour,
      minute: time.minute,
      payload: 'breakfast',
    );
  }

  Future<void> _scheduleLunch() async {
    final time = await getLunchTime();
    final msg = _lunchMessages[DateTime.now().day % _lunchMessages.length];
    await _scheduleDailyNotification(
      id: _lunchId,
      title: '🍽️ Déjeuner',
      body: msg,
      hour: time.hour,
      minute: time.minute,
      payload: 'lunch',
    );
  }

  Future<void> _scheduleDinner() async {
    final time = await getDinnerTime();
    final msg = _dinnerMessages[DateTime.now().day % _dinnerMessages.length];
    await _scheduleDailyNotification(
      id: _dinnerId,
      title: '🌙 Dîner',
      body: msg,
      hour: time.hour,
      minute: time.minute,
      payload: 'dinner',
    );
  }

  Future<void> _scheduleWaterReminders() async {
    // Rappels d'eau toutes les 2h entre 8h et 22h
    final hours = [8, 10, 12, 14, 16, 18, 20, 22];
    for (int i = 0; i < hours.length; i++) {
      final msg = _waterMessages[i % _waterMessages.length];
      await _scheduleDailyNotification(
        id: 400 + i,
        title: '💧 Hydratation',
        body: msg,
        hour: hours[i],
        minute: 0,
        payload: 'water',
      );
    }
  }

  Future<void> _scheduleDailyNotification({
    required int id,
    required String title,
    required String body,
    required int hour,
    required int minute,
    required String payload,
  }) async {
    await _plugin.cancel(id: id);

    final androidDetails = AndroidNotificationDetails(
      'medinutri_meals',
      'Rappels de repas',
      channelDescription: 'Notifications pour les rappels de repas MediNutri',
      importance: Importance.high,
      priority: Priority.high,
      icon: '@mipmap/launcher_icon',
      color: const Color(0xFF448AFF),
      enableLights: true,
      ledColor: const Color(0xFF448AFF),
      ledOnMs: 1000,
      ledOffMs: 500,
      styleInformation: BigTextStyleInformation(
        body,
        contentTitle: title,
      ),
    );

    const iosDetails = DarwinNotificationDetails(
      presentAlert: true,
      presentBadge: true,
      presentSound: true,
    );

    final details = NotificationDetails(
      android: androidDetails,
      iOS: iosDetails,
    );

    final scheduledDate = _nextInstanceOfTime(hour, minute);

    await _plugin.zonedSchedule(
      id: id,
      title: title,
      body: body,
      scheduledDate: scheduledDate,
      notificationDetails: details,
      androidScheduleMode: AndroidScheduleMode.inexactAllowWhileIdle,
      matchDateTimeComponents: DateTimeComponents.time,
      payload: payload,
    );

    debugPrint(
        '[NotificationService] Scheduled: $title at $hour:${minute.toString().padLeft(2, '0')} (ID=$id)');
  }

  tz.TZDateTime _nextInstanceOfTime(int hour, int minute) {
    final now = tz.TZDateTime.now(tz.local);
    var scheduled = tz.TZDateTime(tz.local, now.year, now.month, now.day, hour, minute);
    if (scheduled.isBefore(now)) {
      scheduled = scheduled.add(const Duration(days: 1));
    }
    return scheduled;
  }

  // ─────────────────────────────────────────────────────────
  //  ANNULER
  // ─────────────────────────────────────────────────────────

  Future<void> cancelAllNotifications() async {
    await _plugin.cancelAll();
    debugPrint('[NotificationService] All notifications cancelled');
  }

  // ─────────────────────────────────────────────────────────
  //  RESTAURER AU DÉMARRAGE
  // ─────────────────────────────────────────────────────────

  Future<void> _restoreScheduledNotifications() async {
    if (await isEnabled) {
      await scheduleAllMealReminders();
      debugPrint('[NotificationService] Restored scheduled notifications');
    }
  }

  /// Envoie une notification immédiate (pour le test).
  Future<void> showTestNotification() async {
    const androidDetails = AndroidNotificationDetails(
      'medinutri_meals',
      'Rappels de repas',
      channelDescription: 'Test de notification MediNutri',
      importance: Importance.high,
      priority: Priority.high,
      icon: '@mipmap/launcher_icon',
      color: Color(0xFF448AFF),
    );

    const iosDetails = DarwinNotificationDetails(
      presentAlert: true,
      presentBadge: true,
      presentSound: true,
    );

    const details = NotificationDetails(
      android: androidDetails,
      iOS: iosDetails,
    );

    await _plugin.show(
      id: 999,
      title: '✅ MediNutri — Test réussi !',
      body: 'Les notifications fonctionnent parfaitement. Vos rappels de repas sont actifs.',
      notificationDetails: details,
    );
  }
}
