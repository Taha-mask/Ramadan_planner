import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/data/latest_all.dart' as tz;
import 'package:timezone/timezone.dart' as tz;
import 'package:flutter_timezone/flutter_timezone.dart';
import 'package:permission_handler/permission_handler.dart';

class NotificationService {
  final FlutterLocalNotificationsPlugin _flutterLocalNotificationsPlugin =
      FlutterLocalNotificationsPlugin();

  Future<void> init() async {
    const AndroidInitializationSettings initializationSettingsAndroid =
        AndroidInitializationSettings('@mipmap/ic_launcher');

    final InitializationSettings initializationSettings =
        InitializationSettings(android: initializationSettingsAndroid);

    // Initialize timezones
    tz.initializeTimeZones();
    final String timeZoneName = await FlutterTimezone.getLocalTimezone();
    tz.setLocalLocation(tz.getLocation(timeZoneName));

    await _flutterLocalNotificationsPlugin.initialize(
      settings: initializationSettings,
      onDidReceiveNotificationResponse:
          (NotificationResponse notificationResponse) async {
            if (notificationResponse.actionId == 'mark_as_prayed') {
              await showFollowUpNotification(
                notificationResponse.payload ?? 'الصلاة',
              );
            }
          },
    );

    // Create channels
    final AndroidFlutterLocalNotificationsPlugin? androidImplementation =
        _flutterLocalNotificationsPlugin
            .resolvePlatformSpecificImplementation<
              AndroidFlutterLocalNotificationsPlugin
            >();

    await androidImplementation?.createNotificationChannel(
      const AndroidNotificationChannel(
        'prayer_channel',
        'Prayer Notifications',
        description: 'Notifications for prayer times',
        importance: Importance.max,
        playSound: true,
      ),
    );
  }

  Future<bool> requestPermissions() async {
    bool granted = false;

    // Check if Android 13+
    final AndroidFlutterLocalNotificationsPlugin? androidImplementation =
        _flutterLocalNotificationsPlugin
            .resolvePlatformSpecificImplementation<
              AndroidFlutterLocalNotificationsPlugin
            >();

    if (androidImplementation != null) {
      granted =
          await androidImplementation.requestNotificationsPermission() ?? false;
    } else {
      // Fallback for older Android versions
      granted = await Permission.notification.request().isGranted;
    }

    // Also request exact alarm permission
    if (await Permission.scheduleExactAlarm.isDenied) {
      await Permission.scheduleExactAlarm.request();
    }

    return granted;
  }

  Future<void> schedulePrayerNotification({
    required int id,
    required String title,
    required String body,
    required DateTime scheduledTime,
  }) async {
    // Ensure the scheduled time is in the future
    if (scheduledTime.isBefore(DateTime.now())) {
      return;
    }

    try {
      await _flutterLocalNotificationsPlugin.zonedSchedule(
        id: id,
        title: title,
        body: body,
        scheduledDate: tz.TZDateTime.from(scheduledTime, tz.local),
        notificationDetails: const NotificationDetails(
          android: AndroidNotificationDetails(
            'prayer_channel',
            'Prayer Notifications',
            channelDescription: 'Notifications for prayer times',
            importance: Importance.max,
            priority: Priority.high,
            actions: <AndroidNotificationAction>[
              AndroidNotificationAction(
                'mark_as_prayed',
                'صليت ✅',
                showsUserInterface: true,
                cancelNotification: true,
              ),
            ],
          ),
        ),
        androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
      );
    } catch (e) {
      // If exact alarms aren't permitted, fallback to inexact scheduling
      if (e.toString().contains('exact_alarms_not_permitted')) {
        await _flutterLocalNotificationsPlugin.zonedSchedule(
          id: id,
          title: title,
          body: body,
          scheduledDate: tz.TZDateTime.from(scheduledTime, tz.local),
          notificationDetails: const NotificationDetails(
            android: AndroidNotificationDetails(
              'prayer_channel',
              'Prayer Notifications',
              channelDescription: 'Notifications for prayer times',
              importance: Importance.max,
              priority: Priority.high,
            ),
          ),
          androidScheduleMode: AndroidScheduleMode.inexactAllowWhileIdle,
        );
      } else {
        rethrow;
      }
    }
  }

  Future<void> showFollowUpNotification(String prayerName) async {
    const androidDetails = AndroidNotificationDetails(
      'followup_channel',
      'Follow-up Suggestions',
      channelDescription: 'Suggestions for Sunnah and Azkar after prayer',
      importance: Importance.defaultImportance,
      priority: Priority.defaultPriority,
    );

    await _flutterLocalNotificationsPlugin.show(
      id: 888,
      title: 'تقبل الله صلاتك',
      body: 'لا تنسَ أذكار بعد $prayerName والسنن الرواتب ✨',
      notificationDetails: NotificationDetails(android: androidDetails),
    );
  }

  Future<void> schedulePeriodicZikr({
    required int id,
    required String title,
    required String body,
    RepeatInterval interval = RepeatInterval.hourly,
  }) async {
    await _flutterLocalNotificationsPlugin.periodicallyShow(
      id: id,
      title: title,
      body: body,
      repeatInterval: interval,
      notificationDetails: const NotificationDetails(
        android: AndroidNotificationDetails(
          'zikr_channel',
          'Zikr Reminders',
          channelDescription: 'Periodic reminders for zikr',
          importance: Importance.low,
          priority: Priority.low,
        ),
      ),
      androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
    );
  }

  Future<void> scheduleProphetPrayerReminder({
    RepeatInterval interval = RepeatInterval.everyMinute,
  }) async {
    await _flutterLocalNotificationsPlugin.periodicallyShow(
      id: 777,
      title: 'تذكير',
      body: 'صلِ على النبي ﷺ',
      repeatInterval: interval,
      notificationDetails: const NotificationDetails(
        android: AndroidNotificationDetails(
          'zikr_channel',
          'Zikr Reminders',
          channelDescription: 'Periodic reminders for zikr',
          importance: Importance.high,
          priority: Priority.high,
        ),
      ),
      androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
    );
  }

  Future<void> scheduleQuranReminder({required TimeOfDay time}) async {
    final now = DateTime.now();
    var scheduledDate = DateTime(
      now.year,
      now.month,
      now.day,
      time.hour,
      time.minute,
    );

    if (scheduledDate.isBefore(now)) {
      scheduledDate = scheduledDate.add(const Duration(days: 1));
    }

    await _flutterLocalNotificationsPlugin.zonedSchedule(
      id: 8888, // Quran Reminder ID
      title: 'ورد القرآن اليومي',
      body: 'حان موعد قراءة وردك اليومي من القرآن الكريم 📖',
      scheduledDate: tz.TZDateTime.from(scheduledDate, tz.local),
      notificationDetails: const NotificationDetails(
        android: AndroidNotificationDetails(
          'quran_channel',
          'Quran Reminders',
          channelDescription: 'Daily reminder to read Quran',
          importance: Importance.high,
          priority: Priority.high,
        ),
      ),
      androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
      matchDateTimeComponents:
          DateTimeComponents.time, // Repeats daily at this time
    );
  }

  Future<void> cancelNotification(int id) async {
    await _flutterLocalNotificationsPlugin.cancel(id: id);
  }

  Future<void> cancelAll() async {
    await _flutterLocalNotificationsPlugin.cancelAll();
  }
}
