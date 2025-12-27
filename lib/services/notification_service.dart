import 'package:flutter_local_notifications/flutter_local_notifications.dart'
    as fln;
import 'package:timezone/data/latest.dart' as tz;
import 'package:timezone/timezone.dart' as tz;
import 'package:audioplayers/audioplayers.dart';
import 'package:notio/models/reminder.dart';

class NotificationService {
  static final NotificationService _instance = NotificationService._internal();
  factory NotificationService() => _instance;
  NotificationService._internal();

  final fln.FlutterLocalNotificationsPlugin _notificationsPlugin =
      fln.FlutterLocalNotificationsPlugin();

  final AudioPlayer _audioPlayer = AudioPlayer();

  Future<void> init() async {
    tz.initializeTimeZones();

    // Android Init
    const fln.AndroidInitializationSettings initializationSettingsAndroid =
        fln.AndroidInitializationSettings('@mipmap/ic_launcher');

    // iOS/Web Init (Web support requires separate handling in index.html usually,
    // but this prevents crashes on init)
    const fln.DarwinInitializationSettings initializationSettingsDarwin =
        fln.DarwinInitializationSettings();

    final fln.InitializationSettings initializationSettings =
        fln.InitializationSettings(
      android: initializationSettingsAndroid,
      iOS: initializationSettingsDarwin,
    );

    await _notificationsPlugin.initialize(
      initializationSettings,
      onDidReceiveNotificationResponse: (details) async {
        // Handle notification tap
        // Stop audio if playing
        await _instance.stopAlarmSound();
      },
    );

    // Create the channel for Android
    const fln.AndroidNotificationChannel channel =
        fln.AndroidNotificationChannel(
      'premium_reminders', // id
      'Premium Reminders', // title
      description: 'Alerts for your important tasks',
      importance: fln.Importance.max,
      sound: fln.RawResourceAndroidNotificationSound('alarm_sound'),
      playSound: true,
    );

    await _notificationsPlugin
        .resolvePlatformSpecificImplementation<
            fln.AndroidFlutterLocalNotificationsPlugin>()
        ?.createNotificationChannel(channel);

    // Request permissions
    await _notificationsPlugin
        .resolvePlatformSpecificImplementation<
            fln.AndroidFlutterLocalNotificationsPlugin>()
        ?.requestNotificationsPermission();

    await _notificationsPlugin
        .resolvePlatformSpecificImplementation<
            fln.IOSFlutterLocalNotificationsPlugin>()
        ?.requestPermissions(
          alert: true,
          badge: true,
          sound: true,
        );
  }

  // Schedule a notification
  Future<void> scheduleReminder(Reminder reminder) async {
    if (!reminder.isActive) return;

    final scheduledDate = tz.TZDateTime.from(reminder.dateTime, tz.local);

    // Ensure we don't schedule in the past
    if (scheduledDate.isBefore(tz.TZDateTime.now(tz.local))) return;

    await _notificationsPlugin.zonedSchedule(
      reminder.hashCode,
      'Reminder: ${reminder.title}',
      'It\'s time! ${reminder.title}',
      scheduledDate,
      const fln.NotificationDetails(
        android: fln.AndroidNotificationDetails(
          'premium_reminders',
          'Premium Reminders',
          channelDescription: 'Alerts for your important tasks',
          importance: fln.Importance.max,
          priority: fln.Priority.high,
          fullScreenIntent: true,
          audioAttributesUsage: fln.AudioAttributesUsage.alarm,
        ),
        iOS: fln.DarwinNotificationDetails(
          sound: 'alarm_sound.aiff',
          presentSound: true,
        ),
      ),
      androidScheduleMode: fln.AndroidScheduleMode.exactAllowWhileIdle,
      matchDateTimeComponents: _getRepeatMatch(reminder.repeat),
    );

    // Schedule the audio player to play at that time?
    // Actually, background audio is complex.
    // We will rely on the notification sound for the actual alarm.
    // But IF the app is open, we play the custom sound.
  }

  fln.DateTimeComponents? _getRepeatMatch(String repeat) {
    switch (repeat.toLowerCase()) {
      case 'daily':
        return fln.DateTimeComponents.time;
      case 'weekly':
        return fln.DateTimeComponents.dayOfWeekAndTime;
      default:
        return null;
    }
  }

  Future<void> cancelReminder(Reminder reminder) async {
    await _notificationsPlugin.cancel(reminder.hashCode);
  }

  // Audio Player Logic
  Future<void> playAlarmSound() async {
    try {
      // Play a nice alarm sound from a URL (since we don't have assets set up)
      // Using a short, pleasant notification sound.
      await _audioPlayer.play(UrlSource(
          'https://assets.mixkit.co/active_storage/sfx/2869/2869-preview.mp3'));
    } catch (e) {
      // Ignore audio errors
    }
  }

  Future<void> stopAlarmSound() async {
    await _audioPlayer.stop();
  }
}
