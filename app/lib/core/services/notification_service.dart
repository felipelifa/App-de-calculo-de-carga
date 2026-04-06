import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/timezone.dart' as tz;
import 'package:timezone/data/latest.dart' as tz;

class NotificationService {
  static final _notifications = FlutterLocalNotificationsPlugin();
  static bool _initialized = false;

  // IDs de notificao
  static const int _idInactivity = 1;
  static const int _idDeload = 2;
  static const int _idPr = 3;

  // Channels
  static const _channelGeneral = AndroidNotificationChannel(
    'general',
    'Notificaes',
    description: 'Notificaes gerais do app',
    importance: Importance.high,
  );
  static const _channelInactivity = AndroidNotificationChannel(
    'inactivity',
    'Lembrete de treino',
    description: 'Lembretes quando voc no treina',
    importance: Importance.high,
  );

  // Inicializao
  static Future<void> initialize() async {
    if (_initialized) return;
    _initialized = true;

    tz.initializeTimeZones();

    const android = AndroidInitializationSettings('@mipmap/ic_launcher');
    const ios = DarwinInitializationSettings();
    const config = InitializationSettings(android: android, iOS: ios);
    await _notifications.initialize(config);

    // Registrar canais
    await _notifications
        .resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin>()
        ?.createNotificationChannel(_channelGeneral);
    await _notifications
        .resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin>()
        ?.createNotificationChannel(_channelInactivity);
  }

  // Notificao imediata
  static Future<void> showLocalNotification({
    required String title,
    required String body,
    String? payload,
    int id = 0,
  }) async {
    await initialize();
    const androidDetails = AndroidNotificationDetails(
      'general',
      'Notificaes',
      channelDescription: 'Notificaes gerais do app',
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

  // Agendar notificao
  static Future<void> _scheduleNotification({
    required int id,
    required String title,
    required String body,
    required tz.TZDateTime scheduledDate,
    String channel = 'general',
  }) async {
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
          'Notificaes',
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

  static Future<void> cancel(int id) => _notifications.cancel(id);
  static Future<void> cancelAll() => _notifications.cancelAll();

  // Lembrete de inatividade (se no treinou)
  static Future<void> scheduleInactivityReminder({
    int reminderHour = 19,
    int reminderMinute = 0,
    int daysSinceLastWorkout = 3,
  }) async {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) return;

    // Verifica ltimo treino
    final snap = await FirebaseFirestore.instance
        .collection('users/$uid/workouts')
        .orderBy('date', descending: true)
        .limit(1)
        .get();

    if (snap.docs.isNotEmpty) {
      final lastDate = (snap.docs.first.data()['date'] as Timestamp?)?.toDate();
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
      body:
          'Vocs est h alguns dias sem treinar. Volte rotina e mantenha seu progresso!',
      scheduledDate: scheduledDate,
      channel: 'inactivity',
    );
  }

  // Aviso de deload
  static Future<void> scheduleDeloadAlert() async {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) return;

    final doc = await FirebaseFirestore.instance
        .doc('users/$uid/progression_state/current')
        .get();

    if (!doc.exists || doc.data() == null) return;
    final data = doc.data()!;
    if (data['isDeloadWeek'] != true) return;

    await showLocalNotification(
      id: _idDeload,
      title: 'Semana de Deload',
      body: 'Esta sua semana de descanso ativo! '
          'Reduza o volume em 45% e mantenha a carga. '
          'Seu corpo precisa se recuperar.',
    );
  }

  // Notificao de PR (imediata)
  static Future<void> notifyPersonalRecord({
    required String exerciseName,
    required String recordType,
    required String value,
  }) async {
    await initialize();
    await showLocalNotification(
      id: _idPr,
      title: 'Novo Recorde Pessoal!',
      body: '$exerciseName - $recordType: $value',
    );
  }
}
