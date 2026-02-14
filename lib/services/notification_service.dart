import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/data/latest_all.dart' as tz;
import 'package:timezone/timezone.dart' as tz;
import 'package:flutter_timezone/flutter_timezone.dart';
import 'package:permission_handler/permission_handler.dart';

class NotificationService {
  static final NotificationService _instance = NotificationService._internal();
  factory NotificationService() => _instance;
  NotificationService._internal();

  final FlutterLocalNotificationsPlugin _flutterLocalNotificationsPlugin =
      FlutterLocalNotificationsPlugin();

  bool _isInitialized = false;

  Future<void> init() async {
    if (_isInitialized) return;

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

    if (androidImplementation != null) {
      // Prayer Channel
      await androidImplementation.createNotificationChannel(
        const AndroidNotificationChannel(
          'prayer_channel',
          'الصلاة',
          description: 'تنبيهات مواقيت الصلاة',
          importance: Importance.max,
          playSound: true,
        ),
      );

      // Zikr Channel
      await androidImplementation.createNotificationChannel(
        const AndroidNotificationChannel(
          'zikr_channel',
          'الأذكار',
          description: 'تنبيهات الأذكار والتذكير بالصلاة على النبي',
          importance: Importance.high,
          playSound: true,
        ),
      );

      // Quran Channel
      await androidImplementation.createNotificationChannel(
        const AndroidNotificationChannel(
          'quran_channel',
          'ورد القرآن',
          description: 'تنبيهات ورد القرآن الكريم',
          importance: Importance.high,
          playSound: true,
        ),
      );

      // Good Habits Channel
      await androidImplementation.createNotificationChannel(
        const AndroidNotificationChannel(
          'good_habits_channel',
          'العادات الحسنة',
          description: 'تنبيهات العادات اليومية',
          importance: Importance.defaultImportance,
          playSound: true,
        ),
      );

      // Follow-up Channel
      await androidImplementation.createNotificationChannel(
        const AndroidNotificationChannel(
          'followup_channel',
          'تنبيهات ما بعد الصلاة',
          description: 'اقتراحات السنن والأذكار بعد الصلاة',
          importance: Importance.defaultImportance,
          playSound: true,
        ),
      );
    }

    _isInitialized = true;
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

      // Explicitly request exact alarm permission for Android 12+
      await androidImplementation.requestExactAlarmsPermission();
    } else {
      // Fallback for older Android versions
      granted = await Permission.notification.request().isGranted;
    }

    // Also request exact alarm permission via permission_handler as secondary
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
            icon: 'ic_notification_small',
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
      debugPrint('Scheduled prayer notification: $id at $scheduledTime');
    } catch (e) {
      debugPrint('Error scheduling prayer notification: $e');
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
              icon: 'ic_notification_small',
            ),
          ),
          androidScheduleMode: AndroidScheduleMode.inexactAllowWhileIdle,
        );
        debugPrint('Scheduled fallback prayer notification: $id');
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
      icon: 'ic_notification_small',
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
          icon: 'ic_notification_small',
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
          icon: 'ic_notification_small',
          largeIcon: DrawableResourceAndroidBitmap('ic_notification_large'),
        ),
      ),
      androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
    );
  }

  Future<void> scheduleQuranReminder({
    required TimeOfDay time,
    bool forceTomorrow = false,
  }) async {
    final now = DateTime.now();
    var scheduledDate = DateTime(
      now.year,
      now.month,
      now.day,
      time.hour,
      time.minute,
    );

    if (forceTomorrow || scheduledDate.isBefore(now)) {
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
          icon: 'ic_notification_small',
          largeIcon: DrawableResourceAndroidBitmap('ic_notification_large'),
        ),
      ),
      androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
      matchDateTimeComponents: DateTimeComponents.time,
    );
  }

  Future<void> cancelNotification(int id) async {
    await _flutterLocalNotificationsPlugin.cancel(id: id);
  }

  Future<void> cancelAll() async {
    await _flutterLocalNotificationsPlugin.cancelAll();
  }

  Future<void> scheduleRandomHabitReminders({required int frequency}) async {
    // Cancel existing good habit reminders (ID range 9900-9999)
    for (int i = 0; i < 20; i++) {
      await _flutterLocalNotificationsPlugin.cancel(id: 9900 + i);
    }

    if (frequency <= 0) return;

    final now = DateTime.now();
    final random = Random();

    // Define window: 9 AM to 9 PM
    final startHour = 9;
    final endHour = 21;
    final windowMinutes =
        (endHour - startHour) * 60; // 12 hours * 60 = 720 minutes

    List<int> randomOffsets = [];
    for (int i = 0; i < frequency; i++) {
      randomOffsets.add(random.nextInt(windowMinutes));
    }
    randomOffsets.sort();

    // Ensure some spacing? For now simple random is fine, but maybe ensure distinct hours if possible.
    // Let's just use the random offsets from 9 AM.

    for (int i = 0; i < frequency; i++) {
      int offsetMinutes = randomOffsets[i];

      var scheduledDate = DateTime(
        now.year,
        now.month,
        now.day,
        startHour,
        0,
      ).add(Duration(minutes: offsetMinutes));

      // If text/habit names are needed we can pass them, but generic message is fine for now
      // "Have you done your good habits?"

      // If time passed for today, schedule for tomorrow?
      // User requested "random times", usually this implies refreshing daily.
      // For now, if passed, we can add a day.
      if (scheduledDate.isBefore(now)) {
        scheduledDate = scheduledDate.add(const Duration(days: 1));
      }

      await _flutterLocalNotificationsPlugin.zonedSchedule(
        id: 9900 + i,
        title: 'تذكير بالعادات الحسنة 🌱',
        body: 'هل قمت بإنجاز عاداتك اليوم؟',
        scheduledDate: tz.TZDateTime.from(scheduledDate, tz.local),
        notificationDetails: const NotificationDetails(
          android: AndroidNotificationDetails(
            'good_habits_channel',
            'Good Habits Reminders',
            channelDescription: 'Daily random reminders for good habits',
            importance: Importance.defaultImportance,
            priority: Priority.defaultPriority,
            icon: 'ic_notification_small',
            largeIcon: DrawableResourceAndroidBitmap('ic_notification_large'),
          ),
        ),
        androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
        matchDateTimeComponents: DateTimeComponents
            .time, // Repeats daily at this random time (until rescheduled)
      );
    }
  }

  Future<void> scheduleRandomTaskReminders({required int frequency}) async {
    // Cancel existing task reminders (ID range 9800-9899)
    for (int i = 0; i < 20; i++) {
      await _flutterLocalNotificationsPlugin.cancel(id: 9800 + i);
    }

    if (frequency <= 0) return;

    final now = DateTime.now();
    final random = Random();

    // Define window: 9 AM to 9 PM
    final startHour = 9;
    final endHour = 21;
    final windowMinutes =
        (endHour - startHour) * 60; // 12 hours * 60 = 720 minutes

    List<int> randomOffsets = [];
    for (int i = 0; i < frequency; i++) {
      randomOffsets.add(random.nextInt(windowMinutes));
    }
    randomOffsets.sort();

    for (int i = 0; i < frequency; i++) {
      int offsetMinutes = randomOffsets[i];

      var scheduledDate = DateTime(
        now.year,
        now.month,
        now.day,
        startHour,
        0,
      ).add(Duration(minutes: offsetMinutes));

      if (scheduledDate.isBefore(now)) {
        scheduledDate = scheduledDate.add(const Duration(days: 1));
      }

      await _flutterLocalNotificationsPlugin.zonedSchedule(
        id: 9800 + i,
        title: 'تذكير بالمهام 📝',
        body: 'لا تنسَ إنجاز مهامك اليوم!',
        scheduledDate: tz.TZDateTime.from(scheduledDate, tz.local),
        notificationDetails: const NotificationDetails(
          android: AndroidNotificationDetails(
            'good_habits_channel',
            'Task Reminders',
            channelDescription: 'Daily random reminders for tasks',
            importance: Importance.defaultImportance,
            priority: Priority.defaultPriority,
            icon: 'ic_notification_small',
            largeIcon: DrawableResourceAndroidBitmap('ic_notification_large'),
          ),
        ),
        androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
        matchDateTimeComponents: DateTimeComponents.time,
      );
    }
  }

  Future<void> showImmediateNotification({
    required String title,
    required String body,
  }) async {
    const androidDetails = AndroidNotificationDetails(
      'zikr_channel',
      'تنبيه تجريبي',
      channelDescription: 'تنبيه للتأكد من عمل الخدمة',
      importance: Importance.max,
      priority: Priority.high,
      icon: 'ic_notification_small',
    );

    await _flutterLocalNotificationsPlugin.show(
      id: 0,
      title: title,
      body: body,
      notificationDetails: NotificationDetails(android: androidDetails),
    );
  }
}
