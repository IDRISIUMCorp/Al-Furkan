import "package:flutter/material.dart";
import "package:awesome_notifications/awesome_notifications.dart";
import "package:hive_ce_flutter/hive_flutter.dart";

class KhatmaNotificationService {
  KhatmaNotificationService._();

  static final KhatmaNotificationService instance = KhatmaNotificationService._();

  static const String _khatmaChannelKey = "khatma_reminder";
  static const String _werdChannelKey = "werd_reminder";
  
  static const int _dailyReminderId = 12072;
  bool _initialized = false;

  Future<void> init() async {
    if (_initialized) return;

    await AwesomeNotifications().initialize(
      null,
      [
        NotificationChannel(
          channelGroupKey: "quran_reminders_group",
          channelKey: _khatmaChannelKey,
          channelName: "إشعارات الختمة",
          channelDescription: "تنبيهات لمتابعة الختمة الذكية",
          defaultColor: const Color(0xFF0F8C69),
          ledColor: Colors.white,
          importance: NotificationImportance.High,
          channelShowBadge: true,
          criticalAlerts: true,
        ),
        NotificationChannel(
          channelGroupKey: "quran_reminders_group",
          channelKey: _werdChannelKey,
          channelName: "إشعارات الورد اليومي",
          channelDescription: "تذكير بقراءة الورد اليومي من القرآن",
          defaultColor: const Color(0xFF0F8C69),
          ledColor: Colors.white,
          importance: NotificationImportance.Default,
        )
      ],
      channelGroups: [
        NotificationChannelGroup(
            channelGroupKey: "quran_reminders_group", channelGroupName: "تنبيهات القرآن")
      ],
      debug: false,
    );

    _initialized = true;
  }

  Future<bool> requestPermissionIfNeeded() async {
    bool isAllowed = await AwesomeNotifications().isNotificationAllowed();
    if (!isAllowed) {
      isAllowed = await AwesomeNotifications().requestPermissionToSendNotifications();
    }
    return isAllowed;
  }

  Future<void> sendTestNotification() async {
    final hasPermission = await requestPermissionIfNeeded();
    if (!hasPermission) return;

    final box = await _openUserBox();
    final lastPage = box.get("wahy_last_page", defaultValue: 0) as int;
    
    String body = "هذا إشعار تجريبي للختمة.";
    if (lastPage > 0) {
      body += " لقد توقفت عند الصفحة رقم $lastPage.";
    }

    await AwesomeNotifications().createNotification(
      content: NotificationContent(
        id: 999,
        channelKey: _khatmaChannelKey,
        title: "تجربة الإشعارات",
        body: body,
        category: NotificationCategory.Message,
        wakeUpScreen: true,
      ),
    );
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
      body += " لقد توقفت عند الصفحة رقم $lastPage.";
    }

    await AwesomeNotifications().createNotification(
      content: NotificationContent(
        id: _dailyReminderId,
        channelKey: _khatmaChannelKey,
        title: "تذكير الختمة - ورد اليوم",
        body: body,
        category: NotificationCategory.Reminder,
        wakeUpScreen: true,
      ),
      schedule: NotificationCalendar(
        hour: time.hour,
        minute: time.minute,
        second: 0,
        millisecond: 0,
        repeats: true,
      ),
    );
  }

  Future<void> cancelDailyReminder() async {
    await init();
    await AwesomeNotifications().cancel(_dailyReminderId);
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

  Future<dynamic> _openUserBox() async {
    if (!Hive.isBoxOpen("user")) {
      return await Hive.openBox("user");
    }
    return Hive.box("user");
  }
}
