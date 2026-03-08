import "dart:ui" as ui;

import "package:flutter/material.dart";
import "package:flutter_animate/flutter_animate.dart";
import "package:flutter_bloc/flutter_bloc.dart";

import "../../core/notifications/wahy_notification_service.dart";
import "../../theme/controller/theme_cubit.dart";

/// Premium notification settings page (Apple Dark aesthetic).
///
/// Controls:
/// - تذكير الختمة  (Khatma daily reminder)
/// - آية اليوم     (Daily random verse)
/// - أذكار الصباح  (Morning Azkar)
/// - أذكار المساء  (Evening Azkar)
/// - إشعار تجريبي  (Send test notification)
class NotificationSettingsPage extends StatefulWidget {
  const NotificationSettingsPage({super.key});

  @override
  State<NotificationSettingsPage> createState() => _NotificationSettingsPageState();
}

class _NotificationSettingsPageState extends State<NotificationSettingsPage> {
  final _svc = WahyNotificationService.instance;

  late bool _khatmaEnabled;
  late TimeOfDay _khatmaTime;

  late bool _dailyVerseEnabled;
  late TimeOfDay _dailyVerseTime;

  late bool _morningAzkarEnabled;
  late TimeOfDay _morningAzkarTime;

  late bool _eveningAzkarEnabled;
  late TimeOfDay _eveningAzkarTime;

  @override
  void initState() {
    super.initState();
    _khatmaEnabled = _svc.isKhatmaEnabled();
    _khatmaTime = _svc.getKhatmaTime() ?? const TimeOfDay(hour: 20, minute: 0);

    _dailyVerseEnabled = _svc.isDailyVerseEnabled();
    _dailyVerseTime = _svc.getDailyVerseTime() ?? const TimeOfDay(hour: 8, minute: 0);

    _morningAzkarEnabled = _svc.isMorningAzkarEnabled();
    _morningAzkarTime = _svc.getMorningAzkarTime() ?? const TimeOfDay(hour: 6, minute: 0);

    _eveningAzkarEnabled = _svc.isEveningAzkarEnabled();
    _eveningAzkarTime = _svc.getEveningAzkarTime() ?? const TimeOfDay(hour: 17, minute: 0);
  }

  // ── Time Picker ──
  Future<void> _pickTime({
    required TimeOfDay current,
    required ValueChanged<TimeOfDay> onPicked,
  }) async {
    final picked = await showTimePicker(
      context: context,
      initialTime: current,
      builder: (ctx, child) {
        final isDark = Theme.of(ctx).brightness == Brightness.dark;
        return Theme(
          data: isDark
              ? ThemeData.dark().copyWith(
                  colorScheme: ColorScheme.dark(
                    primary: context.read<ThemeCubit>().state.primary,
                    surface: const Color(0xFF1A1A1F),
                  ),
                )
              : ThemeData.light().copyWith(
                  colorScheme: ColorScheme.light(
                    primary: context.read<ThemeCubit>().state.primary,
                  ),
                ),
          child: Directionality(
            textDirection: TextDirection.rtl,
            child: child!,
          ),
        );
      },
    );
    if (picked != null) onPicked(picked);
  }

  String _formatTime(TimeOfDay t) {
    final h = t.hourOfPeriod == 0 ? 12 : t.hourOfPeriod;
    final m = t.minute.toString().padLeft(2, "0");
    final period = t.period == DayPeriod.am ? "ص" : "م";
    return "$h:$m $period";
  }

  // ── Build ──
  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bg = isDark ? const Color(0xFF0B0B0F) : const Color(0xFFF7F1E6);
    final cardBg = isDark ? const Color(0xFF1A1A1F) : Colors.white;
    final textColor = isDark ? Colors.white : const Color(0xFF1B1B1B);
    final subtitleColor = isDark ? Colors.grey.shade500 : Colors.grey.shade600;
    final primary = context.read<ThemeCubit>().state.primary;
    final borderColor = isDark ? Colors.white.withValues(alpha: 0.06) : Colors.black.withValues(alpha: 0.06);

    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        backgroundColor: bg,
        extendBodyBehindAppBar: true,
        appBar: AppBar(
          title: Text(
            "الإشعارات",
            style: TextStyle(fontWeight: FontWeight.w900, color: textColor),
          ),
          backgroundColor: Colors.transparent,
          elevation: 0,
          flexibleSpace: ClipRRect(
            child: BackdropFilter(
              filter: ui.ImageFilter.blur(sigmaX: 15, sigmaY: 15),
              child: Container(color: Colors.transparent),
            ),
          ),
          iconTheme: IconThemeData(color: primary),
        ),
        body: SafeArea(
          child: ListView(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 80),
            physics: const BouncingScrollPhysics(),
            children: [
              // ── Header ──
              Text(
                "تحكم في إشعاراتك",
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w700,
                  color: subtitleColor,
                ),
              ).animate().fadeIn(duration: 300.ms),
              const SizedBox(height: 16),

              // ── Khatma Reminder ──
              _buildNotifCard(
                index: 0,
                icon: Icons.menu_book_rounded,
                iconColor: const Color(0xFF1B8A6B),
                title: "تذكير الختمة",
                subtitle: "تذكير يومي بورد القراءة",
                enabled: _khatmaEnabled,
                time: _khatmaTime,
                cardBg: cardBg,
                textColor: textColor,
                subtitleColor: subtitleColor,
                borderColor: borderColor,
                primary: primary,
                onToggle: (v) async {
                  setState(() => _khatmaEnabled = v);
                  if (v) {
                    await _svc.scheduleKhatmaReminder(hour: _khatmaTime.hour, minute: _khatmaTime.minute);
                  } else {
                    await _svc.cancelKhatmaReminder();
                  }
                },
                onTimeTap: () => _pickTime(
                  current: _khatmaTime,
                  onPicked: (t) async {
                    setState(() => _khatmaTime = t);
                    if (_khatmaEnabled) {
                      await _svc.scheduleKhatmaReminder(hour: t.hour, minute: t.minute);
                    }
                  },
                ),
              ),
              const SizedBox(height: 12),

              // ── Daily Verse ──
              _buildNotifCard(
                index: 1,
                icon: Icons.auto_awesome_rounded,
                iconColor: const Color(0xFFC18D3E),
                title: "آية اليوم",
                subtitle: "آية عشوائية يومياً مع تفسيرها",
                enabled: _dailyVerseEnabled,
                time: _dailyVerseTime,
                cardBg: cardBg,
                textColor: textColor,
                subtitleColor: subtitleColor,
                borderColor: borderColor,
                primary: primary,
                onToggle: (v) async {
                  setState(() => _dailyVerseEnabled = v);
                  if (v) {
                    await _svc.scheduleDailyVerse(hour: _dailyVerseTime.hour, minute: _dailyVerseTime.minute);
                  } else {
                    await _svc.cancelDailyVerse();
                  }
                },
                onTimeTap: () => _pickTime(
                  current: _dailyVerseTime,
                  onPicked: (t) async {
                    setState(() => _dailyVerseTime = t);
                    if (_dailyVerseEnabled) {
                      await _svc.scheduleDailyVerse(hour: t.hour, minute: t.minute);
                    }
                  },
                ),
              ),
              const SizedBox(height: 12),

              // ── Morning Azkar ──
              _buildNotifCard(
                index: 2,
                icon: Icons.wb_sunny_rounded,
                iconColor: const Color(0xFFFF9800),
                title: "أذكار الصباح",
                subtitle: "تذكير بأذكار الصباح يومياً",
                enabled: _morningAzkarEnabled,
                time: _morningAzkarTime,
                cardBg: cardBg,
                textColor: textColor,
                subtitleColor: subtitleColor,
                borderColor: borderColor,
                primary: primary,
                onToggle: (v) async {
                  setState(() => _morningAzkarEnabled = v);
                  if (v) {
                    await _svc.scheduleMorningAzkar(hour: _morningAzkarTime.hour, minute: _morningAzkarTime.minute);
                  } else {
                    await _svc.cancelMorningAzkar();
                  }
                },
                onTimeTap: () => _pickTime(
                  current: _morningAzkarTime,
                  onPicked: (t) async {
                    setState(() => _morningAzkarTime = t);
                    if (_morningAzkarEnabled) {
                      await _svc.scheduleMorningAzkar(hour: t.hour, minute: t.minute);
                    }
                  },
                ),
              ),
              const SizedBox(height: 12),

              // ── Evening Azkar ──
              _buildNotifCard(
                index: 3,
                icon: Icons.nights_stay_rounded,
                iconColor: const Color(0xFF5C6BC0),
                title: "أذكار المساء",
                subtitle: "تذكير بأذكار المساء يومياً",
                enabled: _eveningAzkarEnabled,
                time: _eveningAzkarTime,
                cardBg: cardBg,
                textColor: textColor,
                subtitleColor: subtitleColor,
                borderColor: borderColor,
                primary: primary,
                onToggle: (v) async {
                  setState(() => _eveningAzkarEnabled = v);
                  if (v) {
                    await _svc.scheduleEveningAzkar(hour: _eveningAzkarTime.hour, minute: _eveningAzkarTime.minute);
                  } else {
                    await _svc.cancelEveningAzkar();
                  }
                },
                onTimeTap: () => _pickTime(
                  current: _eveningAzkarTime,
                  onPicked: (t) async {
                    setState(() => _eveningAzkarTime = t);
                    if (_eveningAzkarEnabled) {
                      await _svc.scheduleEveningAzkar(hour: t.hour, minute: t.minute);
                    }
                  },
                ),
              ),
              const SizedBox(height: 24),

              // ── Test Button ──
              _buildTestButton(primary, textColor, cardBg, borderColor),
            ],
          ),
        ),
      ),
    );
  }

  // ─────────────────────────────────────────────────────────────────────
  // Card Builder
  // ─────────────────────────────────────────────────────────────────────

  Widget _buildNotifCard({
    required int index,
    required IconData icon,
    required Color iconColor,
    required String title,
    required String subtitle,
    required bool enabled,
    required TimeOfDay time,
    required Color cardBg,
    required Color textColor,
    required Color subtitleColor,
    required Color borderColor,
    required Color primary,
    required ValueChanged<bool> onToggle,
    required VoidCallback onTimeTap,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: cardBg,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: borderColor),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            Row(
              children: [
                // Icon
                Container(
                  width: 44,
                  height: 44,
                  decoration: BoxDecoration(
                    color: iconColor.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: Icon(icon, color: iconColor, size: 22),
                ),
                const SizedBox(width: 14),
                // Title + subtitle
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        title,
                        style: TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w900,
                          color: textColor,
                        ),
                      ),
                      Text(
                        subtitle,
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: subtitleColor,
                        ),
                      ),
                    ],
                  ),
                ),
                // Toggle
                Switch.adaptive(
                  value: enabled,
                  onChanged: onToggle,
                  activeColor: primary,
                ),
              ],
            ),
            // Time picker row
            AnimatedSize(
              duration: const Duration(milliseconds: 250),
              curve: Curves.easeOut,
              child: enabled
                  ? Padding(
                      padding: const EdgeInsets.only(top: 12),
                      child: InkWell(
                        onTap: onTimeTap,
                        borderRadius: BorderRadius.circular(12),
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                          decoration: BoxDecoration(
                            color: primary.withValues(alpha: 0.08),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Row(
                            children: [
                              Icon(Icons.access_time_rounded, color: primary, size: 20),
                              const SizedBox(width: 10),
                              Text(
                                "الوقت: ${_formatTime(time)}",
                                style: TextStyle(
                                  fontSize: 14,
                                  fontWeight: FontWeight.w800,
                                  color: primary,
                                ),
                              ),
                              const Spacer(),
                              Icon(Icons.edit_rounded, color: primary.withValues(alpha: 0.5), size: 18),
                            ],
                          ),
                        ),
                      ),
                    )
                  : const SizedBox.shrink(),
            ),
          ],
        ),
      ),
    )
        .animate(delay: Duration(milliseconds: 80 * index))
        .fadeIn(duration: 350.ms)
        .slideY(begin: 0.08, end: 0, duration: 350.ms, curve: Curves.easeOut);
  }

  // ─────────────────────────────────────────────────────────────────────
  // Test Button
  // ─────────────────────────────────────────────────────────────────────

  Widget _buildTestButton(Color primary, Color textColor, Color cardBg, Color borderColor) {
    return GestureDetector(
      onTap: () async {
        await _svc.sendTestNotification();
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text(
              "تم إرسال إشعار تجريبي ✅",
              textDirection: TextDirection.rtl,
              style: TextStyle(fontWeight: FontWeight.w800),
            ),
            backgroundColor: primary,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          ),
        );
      },
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(vertical: 16),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [primary, primary.withValues(alpha: 0.75)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(18),
          boxShadow: [
            BoxShadow(
              color: primary.withValues(alpha: 0.3),
              blurRadius: 16,
              offset: const Offset(0, 6),
            ),
          ],
        ),
        child: const Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.notifications_active_rounded, color: Colors.white, size: 22),
            SizedBox(width: 10),
            Text(
              "جرب الإشعار الآن",
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w900,
                color: Colors.white,
              ),
            ),
          ],
        ),
      ),
    )
        .animate(delay: 400.ms)
        .fadeIn(duration: 400.ms)
        .scaleXY(begin: 0.95, end: 1.0, duration: 400.ms, curve: Curves.easeOutBack);
  }
}
