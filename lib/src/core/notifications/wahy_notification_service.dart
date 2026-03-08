import "package:awesome_notifications/awesome_notifications.dart";
import "package:flutter/material.dart";
import "package:hive_ce_flutter/hive_flutter.dart";

/// Central notification service using `awesome_notifications`.
///
/// Manages all notification channels:
/// - Khatma daily reminder
/// - Prayer times alerts
/// - Daily verse (آية اليوم)
/// - Morning & evening Azkar
///
/// Usage:
/// ```dart
/// await WahyNotificationService.instance.init();
/// await WahyNotificationService.instance.scheduleDailyVerse(hour: 8, minute: 0);
/// ```
class WahyNotificationService {
  WahyNotificationService._();

  static final WahyNotificationService instance = WahyNotificationService._();

  // ── Channel Keys ──
  static const String kKhatmaChannel = "khatma_reminder";
  static const String kPrayerChannel = "prayer_alert";
  static const String kDailyVerseChannel = "daily_verse";
  static const String kMorningAzkarChannel = "morning_azkar";
  static const String kEveningAzkarChannel = "evening_azkar";

  // ── Notification IDs ──
  static const int kKhatmaId = 1001;
  static const int kDailyVerseId = 1002;
  static const int kMorningAzkarId = 1003;
  static const int kEveningAzkarId = 1004;
  // Prayer IDs: 2001-2005 (Fajr → Isha)
  static int prayerId(int index) => 2001 + index;

  // ── Action Keys ──
  static const String kActionOpenMushaf = "OPEN_MUSHAF";
  static const String kActionSnooze = "SNOOZE_30MIN";
  static const String kActionMarkRead = "MARK_READ";

  bool _initialized = false;

  // ── Hive Keys for notification settings ──
  static const String _kBox = "user";
  static const String _kKhatmaEnabled = "notif_khatma_enabled";
  static const String _kKhatmaTime = "notif_khatma_time";
  static const String _kDailyVerseEnabled = "notif_daily_verse_enabled";
  static const String _kDailyVerseTime = "notif_daily_verse_time";
  static const String _kMorningAzkarEnabled = "notif_morning_azkar_enabled";
  static const String _kMorningAzkarTime = "notif_morning_azkar_time";
  static const String _kEveningAzkarEnabled = "notif_evening_azkar_enabled";
  static const String _kEveningAzkarTime = "notif_evening_azkar_time";
  static const String _kPrayerEnabled = "notif_prayer_enabled";

  // ─────────────────────────────────────────────────────────────────────
  // Initialization
  // ─────────────────────────────────────────────────────────────────────

  Future<void> init() async {
    if (_initialized) return;

    await AwesomeNotifications().initialize(
      null, // use default app icon
      [
        NotificationChannel(
          channelKey: kKhatmaChannel,
          channelName: "تذكير الختمة",
          channelDescription: "تذكير يومي بورد الختمة",
          importance: NotificationImportance.High,
          defaultPrivacy: NotificationPrivacy.Public,
          enableVibration: true,
          playSound: true,
          defaultColor: const Color(0xFF1B8A6B),
          ledColor: const Color(0xFF1B8A6B),
        ),
        NotificationChannel(
          channelKey: kPrayerChannel,
          channelName: "مواقيت الصلاة",
          channelDescription: "تنبيهات قبل دخول وقت الصلاة",
          importance: NotificationImportance.Max,
          defaultPrivacy: NotificationPrivacy.Public,
          enableVibration: true,
          playSound: true,
          defaultColor: const Color(0xFF4A90D9),
          ledColor: const Color(0xFF4A90D9),
        ),
        NotificationChannel(
          channelKey: kDailyVerseChannel,
          channelName: "آية اليوم",
          channelDescription: "آية عشوائية يومية مع تفسيرها",
          importance: NotificationImportance.Default,
          defaultPrivacy: NotificationPrivacy.Public,
          enableVibration: false,
          playSound: true,
          defaultColor: const Color(0xFFC18D3E),
          ledColor: const Color(0xFFC18D3E),
        ),
        NotificationChannel(
          channelKey: kMorningAzkarChannel,
          channelName: "أذكار الصباح",
          channelDescription: "تذكير بأذكار الصباح",
          importance: NotificationImportance.High,
          defaultPrivacy: NotificationPrivacy.Public,
          enableVibration: true,
          playSound: true,
          defaultColor: const Color(0xFFFF9800),
          ledColor: const Color(0xFFFF9800),
        ),
        NotificationChannel(
          channelKey: kEveningAzkarChannel,
          channelName: "أذكار المساء",
          channelDescription: "تذكير بأذكار المساء",
          importance: NotificationImportance.High,
          defaultPrivacy: NotificationPrivacy.Public,
          enableVibration: true,
          playSound: true,
          defaultColor: const Color(0xFF5C6BC0),
          ledColor: const Color(0xFF5C6BC0),
        ),
      ],
      debug: false,
    );

    // Listen for actions
    AwesomeNotifications().setListeners(
      onActionReceivedMethod: _onActionReceived,
      onNotificationCreatedMethod: _onNotificationCreated,
      onNotificationDisplayedMethod: _onNotificationDisplayed,
      onDismissActionReceivedMethod: _onDismissActionReceived,
    );

    _initialized = true;
  }

  // ─────────────────────────────────────────────────────────────────────
  // Static Callbacks (must be top-level or static)
  // ─────────────────────────────────────────────────────────────────────

  @pragma("vm:entry-point")
  static Future<void> _onActionReceived(ReceivedAction action) async {
    final key = action.buttonKeyPressed;

    if (key == kActionOpenMushaf) {
      // Will be handled by the app navigation when foregrounded
      debugPrint("[WahyNotif] Action: Open Mushaf");
    } else if (key == kActionSnooze) {
      // Re-schedule same notification 30 minutes later
      await AwesomeNotifications().createNotification(
        content: NotificationContent(
          id: action.id ?? 0,
          channelKey: action.channelKey ?? kKhatmaChannel,
          title: action.title,
          body: action.body,
          notificationLayout: NotificationLayout.BigText,
          wakeUpScreen: true,
        ),
        schedule: NotificationInterval(
          interval: const Duration(minutes: 30),
          allowWhileIdle: true,
          preciseAlarm: true,
        ),
      );
      debugPrint("[WahyNotif] Action: Snoozed 30 min");
    } else if (key == kActionMarkRead) {
      debugPrint("[WahyNotif] Action: Marked as read");
    }
  }

  @pragma("vm:entry-point")
  static Future<void> _onNotificationCreated(
    ReceivedNotification notification,
  ) async {}

  @pragma("vm:entry-point")
  static Future<void> _onNotificationDisplayed(
    ReceivedNotification notification,
  ) async {}

  @pragma("vm:entry-point")
  static Future<void> _onDismissActionReceived(ReceivedAction action) async {}

  // ─────────────────────────────────────────────────────────────────────
  // Permission
  // ─────────────────────────────────────────────────────────────────────

  Future<bool> requestPermission() async {
    return await AwesomeNotifications().requestPermissionToSendNotifications();
  }

  Future<bool> isPermissionGranted() async {
    return await AwesomeNotifications().isNotificationAllowed();
  }

  // ─────────────────────────────────────────────────────────────────────
  // Test / Instant Notifications
  // ─────────────────────────────────────────────────────────────────────

  Future<void> sendTestNotification() async {
    final allowed = await isPermissionGranted();
    if (!allowed) {
      final granted = await requestPermission();
      if (!granted) return;
    }

    final box = Hive.box(_kBox);
    final lastPage = box.get("wahy_last_page", defaultValue: 0) as int;

    String body = "هذا إشعار تجريبي من نظام الإشعارات الجديد";
    if (lastPage > 0) {
      body += "\nتوقفت عند الصفحة $lastPage";
    }

    await AwesomeNotifications().createNotification(
      content: NotificationContent(
        id: 999,
        channelKey: kKhatmaChannel,
        title: "🔔 اختبار الإشعارات",
        body: body,
        notificationLayout: NotificationLayout.BigText,
        wakeUpScreen: true,
        category: NotificationCategory.Reminder,
      ),
      actionButtons: [
        NotificationActionButton(key: kActionOpenMushaf, label: "📖 افتح المصحف"),
        NotificationActionButton(
          key: kActionSnooze,
          label: "⏰ تأجيل ٣٠ دقيقة",
          actionType: ActionType.SilentBackgroundAction,
        ),
      ],
    );
  }

  // ─────────────────────────────────────────────────────────────────────
  // Scheduled: Daily Khatma Reminder
  // ─────────────────────────────────────────────────────────────────────

  Future<void> scheduleKhatmaReminder({
    required int hour,
    required int minute,
  }) async {
    await _ensurePermission();

    final box = Hive.box(_kBox);
    final lastPage = box.get("wahy_last_page", defaultValue: 0) as int;

    String body = "📖 افتح المصحف وأكمل وردك اليوم";
    if (lastPage > 0) {
      body += "\nآخر صفحة: $lastPage";
    }

    final String localTimeZone =
        await AwesomeNotifications().getLocalTimeZoneIdentifier();

    await AwesomeNotifications().createNotification(
      content: NotificationContent(
        id: kKhatmaId,
        channelKey: kKhatmaChannel,
        title: "📿 تذكير الختمة",
        body: body,
        notificationLayout: NotificationLayout.BigText,
        wakeUpScreen: true,
        category: NotificationCategory.Reminder,
      ),
      schedule: NotificationCalendar(
        hour: hour,
        minute: minute,
        second: 0,
        timeZone: localTimeZone,
        repeats: true,
        allowWhileIdle: true,
        preciseAlarm: true,
      ),
      actionButtons: [
        NotificationActionButton(key: kActionOpenMushaf, label: "📖 ابدأ القراءة"),
        NotificationActionButton(
          key: kActionMarkRead,
          label: "تم",
          actionType: ActionType.DismissAction,
        ),
      ],
    );

    // Save settings
    await box.put(_kKhatmaEnabled, true);
    await box.put(_kKhatmaTime, "$hour:$minute");
  }

  Future<void> cancelKhatmaReminder() async {
    await AwesomeNotifications().cancel(kKhatmaId);
    final box = Hive.box(_kBox);
    await box.put(_kKhatmaEnabled, false);
  }

  // ─────────────────────────────────────────────────────────────────────
  // Scheduled: Daily Verse (آية اليوم)
  // ─────────────────────────────────────────────────────────────────────

  Future<void> scheduleDailyVerse({
    required int hour,
    required int minute,
  }) async {
    await _ensurePermission();

    final String localTimeZone =
        await AwesomeNotifications().getLocalTimeZoneIdentifier();

    await AwesomeNotifications().createNotification(
      content: NotificationContent(
        id: kDailyVerseId,
        channelKey: kDailyVerseChannel,
        title: "✨ آية اليوم",
        body: "﴿ إِنَّ مَعَ الْعُسْرِ يُسْرًا ﴾\n📍 الشرح: ٦",
        notificationLayout: NotificationLayout.BigText,
        wakeUpScreen: false,
        category: NotificationCategory.Recommendation,
      ),
      schedule: NotificationCalendar(
        hour: hour,
        minute: minute,
        second: 0,
        timeZone: localTimeZone,
        repeats: true,
        allowWhileIdle: true,
      ),
      actionButtons: [
        NotificationActionButton(key: kActionOpenMushaf, label: "📖 اقرأ المزيد"),
      ],
    );

    final box = Hive.box(_kBox);
    await box.put(_kDailyVerseEnabled, true);
    await box.put(_kDailyVerseTime, "$hour:$minute");
  }

  Future<void> cancelDailyVerse() async {
    await AwesomeNotifications().cancel(kDailyVerseId);
    final box = Hive.box(_kBox);
    await box.put(_kDailyVerseEnabled, false);
  }

  // ─────────────────────────────────────────────────────────────────────
  // Scheduled: Morning Azkar
  // ─────────────────────────────────────────────────────────────────────

  Future<void> scheduleMorningAzkar({
    required int hour,
    required int minute,
  }) async {
    await _ensurePermission();

    final String localTimeZone =
        await AwesomeNotifications().getLocalTimeZoneIdentifier();

    await AwesomeNotifications().createNotification(
      content: NotificationContent(
        id: kMorningAzkarId,
        channelKey: kMorningAzkarChannel,
        title: "🌅 أذكار الصباح",
        body: "☀️ حان وقت أذكار الصباح. ابدأ يومك بذكر الله.",
        notificationLayout: NotificationLayout.BigText,
        wakeUpScreen: true,
        category: NotificationCategory.Reminder,
      ),
      schedule: NotificationCalendar(
        hour: hour,
        minute: minute,
        second: 0,
        timeZone: localTimeZone,
        repeats: true,
        allowWhileIdle: true,
        preciseAlarm: true,
      ),
    );

    final box = Hive.box(_kBox);
    await box.put(_kMorningAzkarEnabled, true);
    await box.put(_kMorningAzkarTime, "$hour:$minute");
  }

  Future<void> cancelMorningAzkar() async {
    await AwesomeNotifications().cancel(kMorningAzkarId);
    final box = Hive.box(_kBox);
    await box.put(_kMorningAzkarEnabled, false);
  }

  // ─────────────────────────────────────────────────────────────────────
  // Scheduled: Evening Azkar
  // ─────────────────────────────────────────────────────────────────────

  Future<void> scheduleEveningAzkar({
    required int hour,
    required int minute,
  }) async {
    await _ensurePermission();

    final String localTimeZone =
        await AwesomeNotifications().getLocalTimeZoneIdentifier();

    await AwesomeNotifications().createNotification(
      content: NotificationContent(
        id: kEveningAzkarId,
        channelKey: kEveningAzkarChannel,
        title: "🌙 أذكار المساء",
        body: "🌟 حان وقت أذكار المساء. اختم يومك بذكر الله.",
        notificationLayout: NotificationLayout.BigText,
        wakeUpScreen: true,
        category: NotificationCategory.Reminder,
      ),
      schedule: NotificationCalendar(
        hour: hour,
        minute: minute,
        second: 0,
        timeZone: localTimeZone,
        repeats: true,
        allowWhileIdle: true,
        preciseAlarm: true,
      ),
    );

    final box = Hive.box(_kBox);
    await box.put(_kEveningAzkarEnabled, true);
    await box.put(_kEveningAzkarTime, "$hour:$minute");
  }

  Future<void> cancelEveningAzkar() async {
    await AwesomeNotifications().cancel(kEveningAzkarId);
    final box = Hive.box(_kBox);
    await box.put(_kEveningAzkarEnabled, false);
  }

  // ─────────────────────────────────────────────────────────────────────
  // Cancel All
  // ─────────────────────────────────────────────────────────────────────

  Future<void> cancelAll() async {
    await AwesomeNotifications().cancelAll();
  }

  // ─────────────────────────────────────────────────────────────────────
  // Restore scheduled notifications (call on app start)
  // ─────────────────────────────────────────────────────────────────────

  Future<void> restoreScheduledNotifications() async {
    if (!Hive.isBoxOpen(_kBox)) {
      // Background isolate might hit this
      return; 
    }

    final box = Hive.box(_kBox);

    if (box.get(_kKhatmaEnabled, defaultValue: false) == true) {
      final time = _parseTime(box.get(_kKhatmaTime) as String?);
      if (time != null) {
        await scheduleKhatmaReminder(hour: time.hour, minute: time.minute);
      }
    }

    if (box.get(_kDailyVerseEnabled, defaultValue: false) == true) {
      final time = _parseTime(box.get(_kDailyVerseTime) as String?);
      if (time != null) {
        await scheduleDailyVerse(hour: time.hour, minute: time.minute);
      }
    }

    if (box.get(_kMorningAzkarEnabled, defaultValue: false) == true) {
      final time = _parseTime(box.get(_kMorningAzkarTime) as String?);
      if (time != null) {
        await scheduleMorningAzkar(hour: time.hour, minute: time.minute);
      }
    }

    if (box.get(_kEveningAzkarEnabled, defaultValue: false) == true) {
      final time = _parseTime(box.get(_kEveningAzkarTime) as String?);
      if (time != null) {
        await scheduleEveningAzkar(hour: time.hour, minute: time.minute);
      }
    }
  }

  // ─────────────────────────────────────────────────────────────────────
  // Settings Helpers (used by the Settings UI)
  // ─────────────────────────────────────────────────────────────────────

  bool isKhatmaEnabled() =>
      Hive.box(_kBox).get(_kKhatmaEnabled, defaultValue: false) == true;
  TimeOfDay? getKhatmaTime() =>
      _parseTime(Hive.box(_kBox).get(_kKhatmaTime) as String?);

  bool isDailyVerseEnabled() =>
      Hive.box(_kBox).get(_kDailyVerseEnabled, defaultValue: false) == true;
  TimeOfDay? getDailyVerseTime() =>
      _parseTime(Hive.box(_kBox).get(_kDailyVerseTime) as String?);

  bool isMorningAzkarEnabled() =>
      Hive.box(_kBox).get(_kMorningAzkarEnabled, defaultValue: false) == true;
  TimeOfDay? getMorningAzkarTime() =>
      _parseTime(Hive.box(_kBox).get(_kMorningAzkarTime) as String?);

  bool isEveningAzkarEnabled() =>
      Hive.box(_kBox).get(_kEveningAzkarEnabled, defaultValue: false) == true;
  TimeOfDay? getEveningAzkarTime() =>
      _parseTime(Hive.box(_kBox).get(_kEveningAzkarTime) as String?);

  bool isPrayerEnabled() =>
      Hive.box(_kBox).get(_kPrayerEnabled, defaultValue: false) == true;

  // ─────────────────────────────────────────────────────────────────────
  // Internal Helpers
  // ─────────────────────────────────────────────────────────────────────

  TimeOfDay? _parseTime(String? raw) {
    if (raw == null || raw.isEmpty) return null;
    final parts = raw.split(":");
    if (parts.length != 2) return null;
    final h = int.tryParse(parts[0]);
    final m = int.tryParse(parts[1]);
    if (h == null || m == null) return null;
    return TimeOfDay(hour: h, minute: m);
  }

  Future<void> _ensurePermission() async {
    final allowed = await isPermissionGranted();
    if (!allowed) await requestPermission();
  }
}
