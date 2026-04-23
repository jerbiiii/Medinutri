import 'dart:typed_data';
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
      
  /// Callback quand une notification est pressée ou déclenchée
  Function(String?)? onNotificationPayload;

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
    
    // On calcule le décalage local manuellement (Ultra-stable pour Xiaomi)
    final DateTime now = DateTime.now();
    final Duration offset = now.timeZoneOffset;
    
    // Créer un ID compatible avec Android (ex: +01:00) au lieu de 'Local'
    final String sign = offset.isNegative ? '-' : '+';
    final String hours = offset.inHours.abs().toString().padLeft(2, '0');
    final String minutes = (offset.inMinutes.abs() % 60).toString().padLeft(2, '0');
    final String offsetId = '$sign$hours:$minutes';
    
    final location = tz.Location(offsetId, [0], [0], [
      tz.TimeZone(offset, isDst: false, abbreviation: 'LOC')
    ]);
    tz.setLocalLocation(location);

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
      // Création forcée des canaux pour qu'ils apparaissent dans les réglages Android
      const medicationChannel = AndroidNotificationChannel(
        'medinutri_meds_v3',
        '💊 Médicaments',
        description: 'Alarmes et rappels pour vos traitements médicaux',
        importance: Importance.max,
        playSound: true,
        enableVibration: true,
      );

      const mealChannel = AndroidNotificationChannel(
        'medinutri_meals',
        '🥗 Rappels de repas',
        description: 'Notifications pour le petit-déjeuner, déjeuner et dîner',
        importance: Importance.high,
      );

      const waterChannel = AndroidNotificationChannel(
        'medinutri_water',
        '💧 Hydratation',
        description: 'Rappels pour boire de l\'eau',
        importance: Importance.low,
      );

      await androidPlugin.createNotificationChannel(medicationChannel);
      await androidPlugin.createNotificationChannel(mealChannel);
      await androidPlugin.createNotificationChannel(waterChannel);

      await androidPlugin.requestNotificationsPermission();
      await androidPlugin.requestExactAlarmsPermission();
    }
  }

  void _onNotificationTapped(NotificationResponse response) {
    debugPrint('[NotificationService] Notification tapped: ${response.payload}');
    onNotificationPayload?.call(response.payload);
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

    try {
      await _plugin.zonedSchedule(
        id: id,
        title: title,
        body: body,
        scheduledDate: scheduledDate,
        notificationDetails: details,
        androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
        matchDateTimeComponents: DateTimeComponents.time,
        payload: payload,
      );
      debugPrint(
          '[NotificationService] Scheduled: $title at $hour:${minute.toString().padLeft(2, '0')} (ID=$id)');
    } catch (e) {
      debugPrint('[NotificationService] Error scheduling notification $id: $e');
    }
  }

  tz.TZDateTime _nextInstanceOfTime(int hour, int minute) {
    final tz.TZDateTime now = tz.TZDateTime.now(tz.local);
    tz.TZDateTime scheduledDate =
        tz.TZDateTime(tz.local, now.year, now.month, now.day, hour, minute);
    
    if (scheduledDate.isBefore(now)) {
      scheduledDate = scheduledDate.add(const Duration(days: 1));
    }
    
    return scheduledDate;
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

  // ─────────────────────────────────────────────────────────
  //  MEDICATION REMINDERS
  // ─────────────────────────────────────────────────────────

  static const _medicationMessages = [
    '💊 C\'est l\'heure de votre médicament !',
    '💊 N\'oubliez pas votre traitement !',
    '💊 Rappel : prenez votre médicament maintenant.',
    '💊 Votre santé compte — prenez votre médicament.',
  ];

  /// Schedule reminders for a single medication.
  /// Uses IDs 500 + (hash % 100) to avoid collisions.
  Future<void> scheduleMedicationReminders({
    required String medicationId,
    required String medicationName,
    required String dosage,
    required List<String> times,
  }) async {
    final baseId = 500 + (medicationId.hashCode.abs() % 100);

    for (int i = 0; i < times.length; i++) {
      final parts = times[i].split(':');
      if (parts.length != 2) continue;
      final hour = int.tryParse(parts[0]) ?? 8;
      final minute = int.tryParse(parts[1]) ?? 0;

      final msg = _medicationMessages[DateTime.now().day % _medicationMessages.length];
      final body = dosage.isNotEmpty
          ? '$msg\n$medicationName — $dosage'
          : '$msg\n$medicationName';

      await _scheduleMedicationNotification(
        id: baseId + i,
        title: '💊 $medicationName',
        body: body,
        hour: hour,
        minute: minute,
        payload: 'medication_$medicationId',
      );
    }
  }

  /// Cancel all reminders for a medication.
  Future<void> cancelMedicationReminders(String medicationId) async {
    final baseId = 500 + (medicationId.hashCode.abs() % 100);
    // Cancel up to 5 time slots
    for (int i = 0; i < 5; i++) {
      await _plugin.cancel(id: baseId + i);
    }
    debugPrint('[NotificationService] Cancelled medication reminders for $medicationId');
  }

  Future<void> _scheduleMedicationNotification({
    required int id,
    required String title,
    required String body,
    required int hour,
    required int minute,
    required String payload,
  }) async {
    await _plugin.cancel(id: id);

    final androidDetails = AndroidNotificationDetails(
      'medinutri_meds_v3', // Nouveau ID pour forcer la mise à jour système
      'Alertes Médicales Urgentes',
      channelDescription: 'Canal pour les alarmes de santé critiques',
      importance: Importance.max,
      priority: Priority.high,
      ticker: 'Rappel Médicament',
      category: AndroidNotificationCategory.alarm,
      audioAttributesUsage: AudioAttributesUsage.alarm,
      playSound: true,
      enableVibration: true,
      vibrationPattern: Int64List.fromList([0, 1000, 500, 1000]),
      icon: '@mipmap/launcher_icon',
      color: const Color(0xFF0D9488),
      fullScreenIntent: false, // On désactive le plein écran pour l'instant pour tester la notif simple
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

    try {
      await _plugin.zonedSchedule(
        id: id,
        title: title,
        body: body,
        scheduledDate: scheduledDate,
        notificationDetails: details,
        androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
        matchDateTimeComponents: DateTimeComponents.time,
        payload: payload,
      );
      debugPrint(
          '[NotificationService] Medication scheduled: $title at $hour:${minute.toString().padLeft(2, '0')} (ID=$id)');
    } catch (e) {
      debugPrint('[NotificationService] Error scheduling medication $id: $e');
    }
  }
}
