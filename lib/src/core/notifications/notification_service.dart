import 'package:awesome_notifications/awesome_notifications.dart';
import 'package:flutter/material.dart';

class NotificationService {
  static final NotificationService _instance = NotificationService._internal();

  factory NotificationService() {
    return _instance;
  }

  NotificationService._internal();

  static const String khatmaChannelKey = 'smart_khatma_channel';
  static const String werdChannelKey = 'daily_werd_channel';

  Future<void> initialize() async {
    await AwesomeNotifications().initialize(
      // set the icon to null if you want to use the default app icon
      null,
      [
        NotificationChannel(
          channelGroupKey: 'khatma_group',
          channelKey: khatmaChannelKey,
          channelName: 'إشعارات الختمة الذكية',
          channelDescription: 'تنبيهات لمتابعة الختمة الذكية',
          defaultColor: const Color(0xFF0F8C69), // App default green
          ledColor: Colors.white,
          importance: NotificationImportance.High,
          channelShowBadge: true,
          criticalAlerts: true,
        ),
        NotificationChannel(
          channelGroupKey: 'werd_group',
          channelKey: werdChannelKey,
          channelName: 'إشعارات الورد اليومي',
          channelDescription: 'تذكير بقراءة الورد اليومي من القرآن',
          defaultColor: const Color(0xFF0F8C69),
          ledColor: Colors.white,
          importance: NotificationImportance.Default,
        )
      ],
      channelGroups: [
        NotificationChannelGroup(
            channelGroupKey: 'khatma_group', channelGroupName: 'الختمة الذكية'),
        NotificationChannelGroup(
            channelGroupKey: 'werd_group', channelGroupName: 'الورد اليومي')
      ],
      debug: false,
    );
  }

  Future<bool> requestPermission() async {
    bool isAllowed = await AwesomeNotifications().isNotificationAllowed();
    if (!isAllowed) {
      isAllowed = await AwesomeNotifications().requestPermissionToSendNotifications();
    }
    return isAllowed;
  }

  Future<void> scheduleDailyWerdReminder({
    required TimeOfDay time,
    String title = 'حان وقت الورد اليومي',
    String body = 'لا تنسَ نصيبك من القرآن اليوم، نور قلبك بآياته.',
  }) async {
    await AwesomeNotifications().createNotification(
      content: NotificationContent(
        id: 100, // Fixed ID for daily werd
        channelKey: werdChannelKey,
        title: title,
        body: body,
        category: NotificationCategory.Reminder,
        wakeUpScreen: true,
      ),
      schedule: NotificationCalendar(
        hour: time.hour,
        minute: time.minute,
        second: 0,
        millisecond: 0,
        repeats: true, // Daily repeat
      ),
    );
  }

  Future<void> scheduleKhatmaReminder({
    required int id,
    required DateTime scheduleTime,
    String title = 'تذكير الختمة الذكية',
    String body = 'موعد قراءة الجزء المخصص لختمتك',
  }) async {
    await AwesomeNotifications().createNotification(
      content: NotificationContent(
        id: id,
        channelKey: khatmaChannelKey,
        title: title,
        body: body,
        category: NotificationCategory.Alarm,
        wakeUpScreen: true,
      ),
      schedule: NotificationCalendar.fromDate(date: scheduleTime),
    );
  }

  Future<void> cancelDailyWerdReminder() async {
    await AwesomeNotifications().cancel(100);
  }

  Future<void> cancelKhatmaReminder(int id) async {
    await AwesomeNotifications().cancel(id);
  }

  Future<void> cancelAll() async {
    await AwesomeNotifications().cancelAll();
  }
}
