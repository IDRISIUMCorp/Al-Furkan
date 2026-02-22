import "package:flutter/material.dart";
import "package:flutter_local_notifications/flutter_local_notifications.dart";
import "package:flutter_timezone/flutter_timezone.dart";
import "package:permission_handler/permission_handler.dart";
import "package:hive_ce_flutter/hive_flutter.dart";
import "package:timezone/data/latest_all.dart" as tz;
import "package:timezone/timezone.dart" as tz;

class KhatmaNotificationService {
  KhatmaNotificationService._();

  static final KhatmaNotificationService instance = KhatmaNotificationService._();

  static const String _channelId = "khatma_reminder";
  static const String _channelName = "Khatma Reminders";
  static const String _channelDescription = "Daily reminder for Khatma";

  static const int _dailyReminderId = 12072;

  final FlutterLocalNotificationsPlugin _plugin = FlutterLocalNotificationsPlugin();
  bool _initialized = false;

  Future<void> init() async {
    if (_initialized) return;

    tz.initializeTimeZones();
    try {
      final localTimezone = await FlutterTimezone.getLocalTimezone();
      tz.setLocalLocation(tz.getLocation(localTimezone));
    } catch (_) {
      // Keep default tz.local if the device timezone cannot be resolved.
    }

    const androidInit = AndroidInitializationSettings("@mipmap/ic_launcher");
    const initSettings = InitializationSettings(android: androidInit);

    await _plugin.initialize(initSettings);

    final android = _plugin
        .resolvePlatformSpecificImplementation<AndroidFlutterLocalNotificationsPlugin>();

    await android?.createNotificationChannel(
      const AndroidNotificationChannel(
        _channelId,
        _channelName,
        description: _channelDescription,
        importance: Importance.max,
        showBadge: true,
        enableVibration: true,
        playSound: true,
      ),
    );

    _initialized = true;
  }

  Future<bool> requestPermissionIfNeeded() async {
    bool isGranted = true;
    final status = await Permission.notification.status;
    if (!status.isGranted) {
      final result = await Permission.notification.request();
      isGranted = result.isGranted;
    }

    // Also request exact alarms if possible (Android 12+)
    try {
      final android = _plugin
          .resolvePlatformSpecificImplementation<AndroidFlutterLocalNotificationsPlugin>();
      // On some versions we need to explicitly request it
      final exactStatus = await Permission.scheduleExactAlarm.status;
      if (!exactStatus.isGranted) {
        await Permission.scheduleExactAlarm.request();
      }
    } catch (_) {}

    return isGranted;
  }

  Future<void> sendTestNotification() async {
    final hasPermission = await requestPermissionIfNeeded();
    if (!hasPermission) return;

    final box = await _openUserBox();
    final lastPage = box.get("wahy_last_page", defaultValue: 0) as int;
    
    String body = "هذا إشعار تجريبي للختمة.";
    if (lastPage > 0) {
      body += "\nلقد توقفت عند الصفحة رقم $lastPage.";
    }

    final bigTextStyleInformation = BigTextStyleInformation(
      body,
      htmlFormatBigText: true,
      contentTitle: "تجربة الإشعارات",
      htmlFormatContentTitle: true,
    );

    try {
      await _plugin.show(
        999,
        "تجربة الإشعارات",
        body,
        NotificationDetails(
          android: AndroidNotificationDetails(
            _channelId,
            _channelName,
            channelDescription: _channelDescription,
            importance: Importance.max,
            priority: Priority.max,
            styleInformation: bigTextStyleInformation,
          ),
        ),
      );
    } catch (_) {}
  }

  Future<void> scheduleDailyReminder({
    required TimeOfDay time,
  }) async {
    await init();

    final hasPermission = await requestPermissionIfNeeded();
    if (!hasPermission) return;

    final box = await _openUserBox();
    final lastPage = box.get("wahy_last_page", defaultValue: 0) as int;
    
    String body = "افتح المصحف وأكمل وردك النهارده";
    if (lastPage > 0) {
      body += "\nلقد توقفت عند الصفحة رقم $lastPage.";
    }

    final bigTextStyleInformation = BigTextStyleInformation(
      body,
      htmlFormatBigText: true,
      contentTitle: "تذكير الختمة",
      htmlFormatContentTitle: true,
      summaryText: "ورد اليوم",
      htmlFormatSummaryText: true,
    );

    try {
      await _plugin.zonedSchedule(
        _dailyReminderId,
        "تذكير الختمة",
        body,
        _nextInstanceOfTime(time),
        NotificationDetails(
          android: AndroidNotificationDetails(
            _channelId,
            _channelName,
            channelDescription: _channelDescription,
            importance: Importance.max,
            priority: Priority.max,
            styleInformation: bigTextStyleInformation,
            visibility: NotificationVisibility.public,
          ),
        ),
        androidScheduleMode: AndroidScheduleMode.inexactAllowWhileIdle,
        matchDateTimeComponents: DateTimeComponents.time,
      );
    } catch (e) {
      debugPrint("Khatma scheduling failed (inexact): $e");
      // Fallback: try exact if inexact fails
      try {
        await _plugin.zonedSchedule(
          _dailyReminderId,
          "تذكير الختمة",
          body,
          _nextInstanceOfTime(time),
          NotificationDetails(
            android: AndroidNotificationDetails(
              _channelId,
              _channelName,
              channelDescription: _channelDescription,
              importance: Importance.max,
              priority: Priority.max,
              styleInformation: bigTextStyleInformation,
              visibility: NotificationVisibility.public,
            ),
          ),
          androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
          matchDateTimeComponents: DateTimeComponents.time,
        );
      } catch (e2) {
        debugPrint("Khatma scheduling failed (exact fallback): $e2");
      }
    }
  }

  Future<void> cancelDailyReminder() async {
    await init();
    await _plugin.cancel(_dailyReminderId);
  }

  Future<void> updateReminderTextIfNeeded() async {
    final box = await _openUserBox();
    final enabled = box.get("wahy_khatma_reminder_enabled", defaultValue: false) == true;
    if (!enabled) return;

    final rawTime = box.get("wahy_khatma_reminder_time");
    if (rawTime is! String) return;
    
    final parts = rawTime.split(":");
    if (parts.length != 2) return;
    final h = int.tryParse(parts[0]);
    final m = int.tryParse(parts[1]);
    if (h == null || m == null) return;

    await scheduleDailyReminder(time: TimeOfDay(hour: h, minute: m));
  }

  tz.TZDateTime _nextInstanceOfTime(TimeOfDay time) {
    final now = tz.TZDateTime.now(tz.local);
    var scheduled = tz.TZDateTime(
      tz.local,
      now.year,
      now.month,
      now.day,
      time.hour,
      time.minute,
    );

    if (scheduled.isBefore(now)) {
      scheduled = scheduled.add(const Duration(days: 1));
    }

    return scheduled;
  }

  Future<dynamic> _openUserBox() async {
    if (!Hive.isBoxOpen("user")) {
      return await Hive.openBox("user");
    }
    return Hive.box("user");
  }
}
