import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/timezone.dart' as tz;
import 'package:timezone/data/latest.dart' as tz;
import 'api_service.dart';

class NotificationService {
  static final _notifications = FlutterLocalNotificationsPlugin();
  static bool _initialized = false;

  static const int _idInactivity = 1;
  static const int _idDeload = 2;
  static const int _idPr = 3;

  static const _channelGeneral = AndroidNotificationChannel(
    'general',
    'Notificações',
    description: 'Notificações gerais do app',
    importance: Importance.high,
  );
  static const _channelInactivity = AndroidNotificationChannel(
    'inactivity',
    'Lembrete de treino',
    description: 'Lembretes quando você não treina',
    importance: Importance.high,
  );

  static Future<void> initialize() async {
    if (kIsWeb) return;
    if (_initialized) return;
    _initialized = true;

    tz.initializeTimeZones();

    const android = AndroidInitializationSettings('@mipmap/ic_launcher');
    const ios = DarwinInitializationSettings();
    const config = InitializationSettings(android: android, iOS: ios);
    await _notifications.initialize(config);

    await _notifications
        .resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin>()
        ?.createNotificationChannel(_channelGeneral);
    await _notifications
        .resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin>()
        ?.createNotificationChannel(_channelInactivity);
  }

  static Future<void> showLocalNotification({
    required String title,
    required String body,
    String? payload,
    int id = 0,
  }) async {
    if (kIsWeb) return;
    await initialize();
    const androidDetails = AndroidNotificationDetails(
      'general',
      'Notificações',
      channelDescription: 'Notificações gerais do app',
      importance: Importance.high,
      priority: Priority.high,
    );
    const ios = DarwinNotificationDetails();
    await _notifications.show(
      id,
      title,
      body,
      NotificationDetails(android: androidDetails, iOS: ios),
      payload: payload,
    );
  }

  static Future<void> _scheduleNotification({
    required int id,
    required String title,
    required String body,
    required tz.TZDateTime scheduledDate,
    String channel = 'general',
  }) async {
    if (kIsWeb) return;
    await initialize();

    final now = tz.TZDateTime.now(tz.local);
    if (scheduledDate.isBefore(now)) return;

    AndroidNotificationDetails androidDetails;
    switch (channel) {
      case 'inactivity':
        androidDetails = const AndroidNotificationDetails(
          'inactivity',
          'Lembrete de treino',
          importance: Importance.high,
          priority: Priority.high,
        );
        break;
      default:
        androidDetails = const AndroidNotificationDetails(
          'general',
          'Notificações',
          importance: Importance.high,
          priority: Priority.high,
        );
    }

    const ios = DarwinNotificationDetails();
    await _notifications.zonedSchedule(
      id,
      title,
      body,
      scheduledDate,
      NotificationDetails(android: androidDetails, iOS: ios),
      androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
      uiLocalNotificationDateInterpretation:
          UILocalNotificationDateInterpretation.absoluteTime,
      matchDateTimeComponents: DateTimeComponents.time,
    );
  }

  static Future<void> cancel(int id) async {
    if (kIsWeb) return;
    await _notifications.cancel(id);
  }

  static Future<void> cancelAll() async {
    if (kIsWeb) return;
    await _notifications.cancelAll();
  }

  static Future<void> scheduleInactivityReminder({
    int reminderHour = 19,
    int reminderMinute = 0,
    int daysSinceLastWorkout = 3,
  }) async {
    if (kIsWeb) return;

    try {
      final api = ApiService();
      if (!api.isAuthenticated) return;

      final workouts = await api.get<List>('/workouts', queryParams: {'limit': '1'});
      if (workouts != null && workouts.isNotEmpty) {
        final lastDate = DateTime.tryParse(workouts[0]['date'] ?? '');
        if (lastDate != null) {
          final daysAgo = DateTime.now().difference(lastDate).inDays;
          if (daysAgo < daysSinceLastWorkout) return;
        }
      }

      final now = tz.TZDateTime.now(tz.local);
      var scheduledDate = tz.TZDateTime(
          tz.local, now.year, now.month, now.day, reminderHour, reminderMinute);
      if (scheduledDate.isBefore(now)) {
        scheduledDate = scheduledDate.add(const Duration(days: 1));
      }

      await _scheduleNotification(
        id: _idInactivity,
        title: 'Hora de treinar!',
        body: 'Você está há alguns dias sem treinar. Volte à rotina e mantenha seu progresso!',
        scheduledDate: scheduledDate,
        channel: 'inactivity',
      );
    } catch (_) {
      // Silenciosamente falhar se a API não estiver disponível
    }
  }

  static Future<void> scheduleDeloadAlert() async {
    if (kIsWeb) return;

    try {
      final api = ApiService();
      if (!api.isAuthenticated) return;

      final state = await api.get('/progression/state');
      if (state == null || state['isDeloadWeek'] != true) return;

      await showLocalNotification(
        id: _idDeload,
        title: 'Semana de Deload',
        body: 'Esta é sua semana de descanso ativo! '
            'Reduza o volume em 45% e mantenha a carga. '
            'Seu corpo precisa se recuperar.',
      );
    } catch (_) {
      // Silenciosamente falhar
    }
  }

  static Future<void> notifyPersonalRecord({
    required String exerciseName,
    required String recordType,
    required String value,
  }) async {
    if (kIsWeb) return;
    await initialize();
    await showLocalNotification(
      id: _idPr,
      title: 'Novo Recorde Pessoal!',
      body: '$exerciseName - $recordType: $value',
    );
  }
}
