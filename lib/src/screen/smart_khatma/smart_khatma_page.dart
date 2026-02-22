import "dart:math";

import "package:al_quran_v3/src/resources/quran_resources/quran_pages_info.dart";
import "package:al_quran_v3/src/screen/mushaf/mushaf_screen.dart";
import "package:al_quran_v3/src/core/notifications/khatma_notification_service.dart";
import "package:al_quran_v3/src/theme/controller/theme_cubit.dart";
import "package:al_quran_v3/src/theme/controller/theme_state.dart";
import "package:al_quran_v3/src/utils/basic_functions.dart";
import "package:al_quran_v3/src/utils/number_localization.dart";
import "package:flutter/material.dart";
import "package:flutter_bloc/flutter_bloc.dart";
import "package:gap/gap.dart";
import "package:hive_ce_flutter/hive_flutter.dart";
import "package:percent_indicator/percent_indicator.dart";
import "package:qcf_quran/qcf_quran.dart";

class SmartKhatmaPage extends StatefulWidget {
  const SmartKhatmaPage({super.key});

  @override
  State<SmartKhatmaPage> createState() => _SmartKhatmaPageState();
}

enum SmartKhatmaPlanPreset {
  ramadan30,
  days20,
  days10,
  custom,
}

enum _WahyKhatmaStep {
  empty,
  newKhatma,
  program,
  startFrom,
  active,
  allWirds,
}

class _SmartKhatmaPageState extends State<SmartKhatmaPage> {
  static const String _boxName = "user";

  static const String _kEnabledKey = "smart_khatma_enabled";
  static const String _kPlanDaysKey = "smart_khatma_plan_days";
  static const String _kCurrentDayIndexKey = "smart_khatma_current_day_index";
  static const String _kStartedAtKey = "smart_khatma_started_at";
  static const String _kReminderEnabledKey = "wahy_khatma_reminder_enabled";
  static const String _kReminderTimeKey = "wahy_khatma_reminder_time";

  static const int _totalPages = 604;

  SmartKhatmaPlanPreset _preset = SmartKhatmaPlanPreset.ramadan30;
  int _customDays = 30;

  bool _enabled = false;
  int _planDays = 30;
  int _dayIndex = 0;

  bool _reminderEnabled = false;
  TimeOfDay _reminderTime = const TimeOfDay(hour: 7, minute: 0);

  _WahyKhatmaStep _step = _WahyKhatmaStep.empty;
  int _selectedProgramDays = 29;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _startPlanWithDays(int days) async {
    final box = Hive.box(_boxName);
    final now = DateTime.now();

    await box.put(_kEnabledKey, true);
    await box.put(_kPlanDaysKey, days);
    await box.put(_kCurrentDayIndexKey, 0);
    await box.put(_kStartedAtKey, now.toIso8601String());

    _load();
  }

  void _load() {
    final box = Hive.box(_boxName);

    setState(() {
      _enabled = box.get(_kEnabledKey, defaultValue: false) == true;
      _planDays = (box.get(_kPlanDaysKey, defaultValue: 30) as int?) ?? 30;
      _dayIndex = (box.get(_kCurrentDayIndexKey, defaultValue: 0) as int?) ?? 0;

      _reminderEnabled = box.get(_kReminderEnabledKey, defaultValue: false) == true;
      final rawTime = box.get(_kReminderTimeKey);
      final parsed = _parseTimeOfDay(rawTime);
      if (parsed != null) _reminderTime = parsed;

      _customDays = _planDays;
      _preset = _presetForDays(_planDays);

      if (_enabled) {
        _selectedProgramDays = _planDays;
        _step = _WahyKhatmaStep.active;
      } else {
        _step = _WahyKhatmaStep.empty;
      }
    });
  }

  TimeOfDay? _parseTimeOfDay(dynamic raw) {
    if (raw is! String) return null;
    final parts = raw.split(":");
    if (parts.length != 2) return null;
    final h = int.tryParse(parts[0]);
    final m = int.tryParse(parts[1]);
    if (h == null || m == null) return null;
    if (h < 0 || h > 23 || m < 0 || m > 59) return null;
    return TimeOfDay(hour: h, minute: m);
  }

  String _formatTimeOfDay(TimeOfDay t) {
    final hh = t.hour.toString().padLeft(2, "0");
    final mm = t.minute.toString().padLeft(2, "0");
    return "$hh:$mm";
  }

  String _formatTimeForUi(TimeOfDay t) {
    final h12 = (t.hourOfPeriod == 0 ? 12 : t.hourOfPeriod);
    final mm = t.minute.toString().padLeft(2, "0");
    final suffix = t.period == DayPeriod.am ? "ص" : "م";
    return "${localizedNumber(context, h12)}:$mm $suffix";
  }

  Future<void> _setReminderEnabled(bool value) async {
    final box = Hive.box(_boxName);
    if (value) {
      final granted = await KhatmaNotificationService.instance.requestPermissionIfNeeded();
      if (!granted) {
        setState(() => _reminderEnabled = false);
        await box.put(_kReminderEnabledKey, false);
        return;
      }
      await KhatmaNotificationService.instance.scheduleDailyReminder(time: _reminderTime);
      await box.put(_kReminderEnabledKey, true);
      await box.put(_kReminderTimeKey, _formatTimeOfDay(_reminderTime));
      setState(() => _reminderEnabled = true);
      return;
    }

    await KhatmaNotificationService.instance.cancelDailyReminder();
    await box.put(_kReminderEnabledKey, false);
    setState(() => _reminderEnabled = false);
  }

  Future<void> _pickReminderTime() async {
    final picked = await showTimePicker(
      context: context,
      initialTime: _reminderTime,
      builder: (ctx, child) {
        return Directionality(
          textDirection: TextDirection.rtl,
          child: child ?? const SizedBox.shrink(),
        );
      },
    );
    if (picked == null) return;

    final box = Hive.box(_boxName);
    setState(() => _reminderTime = picked);
    await box.put(_kReminderTimeKey, _formatTimeOfDay(picked));

    if (_reminderEnabled) {
      await KhatmaNotificationService.instance.scheduleDailyReminder(time: picked);
    }
  }

  SmartKhatmaPlanPreset _presetForDays(int days) {
    if (days == 30) return SmartKhatmaPlanPreset.ramadan30;
    if (days == 20) return SmartKhatmaPlanPreset.days20;
    if (days == 10) return SmartKhatmaPlanPreset.days10;
    return SmartKhatmaPlanPreset.custom;
  }

  int _daysForPreset(SmartKhatmaPlanPreset p) {
    switch (p) {
      case SmartKhatmaPlanPreset.ramadan30:
        return 30;
      case SmartKhatmaPlanPreset.days20:
        return 20;
      case SmartKhatmaPlanPreset.days10:
        return 10;
      case SmartKhatmaPlanPreset.custom:
        return max(2, _customDays);
    }
  }

  int _pagesPerDay(int days) {
    return (_totalPages / days).ceil();
  }

  ({int startPage, int endPage}) _rangeForDay(int dayIndex, int days) {
    final perDay = _pagesPerDay(days);
    final start = (dayIndex * perDay) + 1;
    final end = min(_totalPages, start + perDay - 1);
    return (startPage: start, endPage: end);
  }

  String _ayahKeyForPageStart(int pageNumber) {
    final idx = (pageNumber - 1).clamp(0, quranPagesInfo.length - 1);
    final startAyahNumber = quranPagesInfo[idx]["s"] ?? 1;
    return convertAyahNumberToKey(startAyahNumber) ?? "1:1";
  }

  String _ayahKeyForPageEnd(int pageNumber) {
    final idx = (pageNumber - 1).clamp(0, quranPagesInfo.length - 1);
    final endAyahNumber = quranPagesInfo[idx]["e"] ?? 7;
    return convertAyahNumberToKey(endAyahNumber) ?? "1:7";
  }

  Future<void> _startPlan() async {
    final days = _daysForPreset(_preset);
    final box = Hive.box(_boxName);
    final now = DateTime.now();

    await box.put(_kEnabledKey, true);
    await box.put(_kPlanDaysKey, days);
    await box.put(_kCurrentDayIndexKey, 0);
    await box.put(_kStartedAtKey, now.toIso8601String());

    _load();
  }

  Future<void> _markTodayDone() async {
    if (!_enabled) return;
    final box = Hive.box(_boxName);
    final next = min(_planDays, _dayIndex + 1);
    await box.put(_kCurrentDayIndexKey, next);
    _load();
  }

  Future<void> _resetPlan() async {
    final box = Hive.box(_boxName);
    await box.put(_kEnabledKey, false);
    await box.delete(_kPlanDaysKey);
    await box.delete(_kCurrentDayIndexKey);
    await box.delete(_kStartedAtKey);
    await KhatmaNotificationService.instance.cancelDailyReminder();
    await box.put(_kReminderEnabledKey, false);
    _load();
  }

  Future<void> _confirmResetPlan(BuildContext context) async {
    final bool? confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => Directionality(
        textDirection: TextDirection.rtl,
        child: AlertDialog(
          backgroundColor: Theme.of(context).colorScheme.surface,
          title: const Text("حذف الختمة", style: TextStyle(fontWeight: FontWeight.bold)),
          content: const Text("هل أنت متأكد من حذف الختمة الحالية ومسح جميع بيانات تقدمك؟"),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: const Text("إلغاء", style: TextStyle(color: Colors.grey)),
            ),
            TextButton(
              onPressed: () => Navigator.pop(ctx, true),
              child: const Text("حذف", style: TextStyle(color: Colors.red, fontWeight: FontWeight.bold)),
            ),
          ],
        ),
      ),
    );
    if (confirm == true) {
      await _resetPlan();
    }
  }

  void _openTodayMushaf() {
    final days = _enabled ? _planDays : _daysForPreset(_preset);
    final day = _enabled ? _dayIndex : 0;
    final range = _rangeForDay(day, days);

    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => _KhatmaMushafPage(
          startPage: range.startPage,
          endPage: range.endPage,
        ),
      ),
    );
  }

  String _rangeLabelForDay(int dayIndex, int days) {
    final r = _rangeForDay(dayIndex, days);
    final startKey = _ayahKeyForPageStart(r.startPage);
    final endKey = _ayahKeyForPageEnd(r.endPage);

    final sp = startKey.split(":");
    final ep = endKey.split(":");
    final ss = int.tryParse(sp.first) ?? 1;
    final sv = int.tryParse(sp.last) ?? 1;
    final es = int.tryParse(ep.first) ?? 1;
    final ev = int.tryParse(ep.last) ?? 1;

    return "من ${getSurahNameArabic(ss)}: ${localizedNumber(context, sv)}\nإلى ${getSurahNameArabic(es)}: ${localizedNumber(context, ev)}";
  }

  Widget _topTitle(String title, {VoidCallback? onBack}) {
    final themeState = context.read<ThemeCubit>().state;
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 10, 16, 6),
      child: Row(
        children: [
          if (onBack != null)
            IconButton(
              onPressed: onBack,
              icon: Icon(
                Icons.arrow_forward_ios_rounded,
                color: themeState.primary,
              ),
            )
          else
            const SizedBox(width: 44),
          Expanded(
            child: Text(
              title,
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontSize: 26,
                fontWeight: FontWeight.w900,
              ),
            ),
          ),
          const SizedBox(width: 44),
        ],
      ),
    );
  }

  Widget _card(Widget child) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Container(
      margin: const EdgeInsets.fromLTRB(16, 10, 16, 0),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1E1E1E) : const Color(0xFFFFF9F2),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(
          color: isDark ? Colors.white10 : Colors.black.withValues(alpha: 0.06),
        ),
      ),
      child: child,
    );
  }

  @override
  Widget build(BuildContext context) {
    final themeState = context.watch<ThemeCubit>().state;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    Widget empty() {
      return Column(
        children: [

          const Spacer(),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 26),
            child: Text(
              "حدد وردك اليومي أو المدة التي تريد ختم القرآن فيها، وتابع ختمتك في شهر رمضان وطوال العام.",
              textAlign: TextAlign.center,
              style: TextStyle(
                height: 1.7,
                fontSize: 16,
                fontWeight: FontWeight.w800,
                color: isDark ? Colors.white70 : Colors.black54,
              ),
            ),
          ),
          const Gap(18),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 26),
            child: SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: themeState.primary,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(18),
                  ),
                ),
                onPressed: () => setState(() => _step = _WahyKhatmaStep.newKhatma),
                child: const Text(
                  "بدء ختمة جديدة",
                  style: TextStyle(fontWeight: FontWeight.w900),
                ),
              ),
            ),
          ),
          const Spacer(flex: 2),
        ],
      );
    }

    Widget newKhatma() {
      return ListView(
        padding: EdgeInsets.only(
          top: 6,
          bottom: 18 + MediaQuery.of(context).padding.bottom,
        ),
        children: [
          _topTitle(
            "ختمة جديدة",
            onBack: () => setState(() => _step = _WahyKhatmaStep.empty),
          ),
          const Gap(6),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 18),
            child: Text(
              "ختمة مقترحة",
              style: TextStyle(
                fontWeight: FontWeight.w900,
                color: isDark ? Colors.white60 : Colors.black45,
              ),
            ),
          ),
          _card(
            ListTile(
              contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
              title: const Text(
                "ختمة شهر (29 يوماً)",
                style: TextStyle(fontWeight: FontWeight.w900),
              ),
              subtitle: Text(
                "الورد اليومي: ${localizedNumber(context, 21)} صفحة تقريباً",
                style: TextStyle(
                  fontWeight: FontWeight.w700,
                  color: isDark ? Colors.white60 : Colors.black45,
                ),
              ),
              onTap: () {
                _selectedProgramDays = 29;
                setState(() => _step = _WahyKhatmaStep.program);
              },
            ),
          ),
          const Gap(10),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 18),
            child: Text(
              "أخرى",
              style: TextStyle(
                fontWeight: FontWeight.w900,
                color: isDark ? Colors.white60 : Colors.black45,
              ),
            ),
          ),
          _card(
            Column(
              children: [
                ListTile(
                  title: const Text(
                    "ختمة مقسمة بالمعنى",
                    style: TextStyle(fontWeight: FontWeight.w900),
                  ),
                  onTap: () {
                    _selectedProgramDays = 60;
                    setState(() => _step = _WahyKhatmaStep.program);
                  },
                ),
                const Divider(height: 1),
                ListTile(
                  title: const Text(
                    "ختمة مقسمة بالأجزاء والأرباع",
                    style: TextStyle(fontWeight: FontWeight.w900),
                  ),
                  onTap: () {
                    _selectedProgramDays = 7;
                    setState(() => _step = _WahyKhatmaStep.program);
                  },
                ),
              ],
            ),
          ),
        ],
      );
    }

    Widget program() {
      return ListView(
        padding: EdgeInsets.only(
          top: 6,
          bottom: 18 + MediaQuery.of(context).padding.bottom,
        ),
        children: [
          _topTitle(
            "برنامج الختمة",
            onBack: () => setState(() => _step = _WahyKhatmaStep.newKhatma),
          ),
          _card(
            Column(
              children: [
                ListTile(
                  title: const Text(
                    "ختمة شهرين (60 يوماً)",
                    style: TextStyle(fontWeight: FontWeight.w900),
                  ),
                  subtitle: Text(
                    "الورد اليومي: ${localizedNumber(context, 10)} صفحات تقريباً",
                    style: TextStyle(
                      fontWeight: FontWeight.w700,
                      color: isDark ? Colors.white60 : Colors.black45,
                    ),
                  ),
                  onTap: () {
                    _selectedProgramDays = 60;
                    setState(() => _step = _WahyKhatmaStep.startFrom);
                  },
                ),
                const Divider(height: 1),
                ListTile(
                  title: const Text(
                    "ختمة شهر (29 يوماً)",
                    style: TextStyle(fontWeight: FontWeight.w900),
                  ),
                  subtitle: Text(
                    "الورد اليومي: ${localizedNumber(context, 21)} صفحة تقريباً",
                    style: TextStyle(
                      fontWeight: FontWeight.w700,
                      color: isDark ? Colors.white60 : Colors.black45,
                    ),
                  ),
                  onTap: () {
                    _selectedProgramDays = 29;
                    setState(() => _step = _WahyKhatmaStep.startFrom);
                  },
                ),
                const Divider(height: 1),
                ListTile(
                  title: const Text(
                    "ختمة أسبوع (7 أيام)",
                    style: TextStyle(fontWeight: FontWeight.w900),
                  ),
                  subtitle: Text(
                    "الورد اليومي: ${localizedNumber(context, 5)} أجزاء تقريباً",
                    style: TextStyle(
                      fontWeight: FontWeight.w700,
                      color: isDark ? Colors.white60 : Colors.black45,
                    ),
                  ),
                  onTap: () {
                    _selectedProgramDays = 7;
                    setState(() => _step = _WahyKhatmaStep.startFrom);
                  },
                ),
              ],
            ),
          ),
        ],
      );
    }

    Widget startFrom() {
      final daysLocal = _selectedProgramDays;
      return ListView(
        padding: EdgeInsets.only(
          top: 6,
          bottom: 18 + MediaQuery.of(context).padding.bottom,
        ),
        children: [
          _topTitle(
            "بدء الختمة من",
            onBack: () => setState(() => _step = _WahyKhatmaStep.program),
          ),
          _card(
            Column(
              children: [
                ListTile(
                  title: const Text(
                    "بداية المصحف",
                    style: TextStyle(fontWeight: FontWeight.w900),
                  ),
                  onTap: () async {
                    await _startPlanWithDays(daysLocal);
                    setState(() => _step = _WahyKhatmaStep.active);
                  },
                ),
                const Divider(height: 1),
                ListTile(
                  title: const Text(
                    "ورد محدد",
                    style: TextStyle(fontWeight: FontWeight.w900),
                  ),
                  onTap: () => setState(() => _step = _WahyKhatmaStep.allWirds),
                ),
              ],
            ),
          ),
        ],
      );
    }

    Widget active() {
      final todayLabel = _rangeLabelForDay(_dayIndex, _planDays);
      final yesterdayLabel = _rangeLabelForDay(max(0, _dayIndex - 1), _planDays);
      
      final totalPagesRead = _dayIndex * _pagesPerDay(_planDays);
      final pagesRemaining = max(0, _totalPages - totalPagesRead);
      final percentTotal = (_dayIndex / _planDays).clamp(0.0, 1.0);
      final daysRemaining = max(0, _planDays - _dayIndex);
      
      // Calculate daily progress 
      // Assuming today is done if we hit _markTodayDone, we'll give 100% for today if _dayIndex increased.
      // Since this is a simple tracker, we mimic daily completion by checking if today's index > actual days passed.
      // For visual flair, we will assume daily ring is full if they are on track, otherwise 0%.
      final DateTime? startTime = Hive.box(_boxName).get(_kStartedAtKey) != null 
          ? DateTime.tryParse(Hive.box(_boxName).get(_kStartedAtKey)) 
          : null;
      
      double percentDaily = 0.0;
      double percentPacing = 0.0;
      
      if (startTime != null) {
        final int actualDaysPassed = DateTime.now().difference(startTime).inDays;
        
        // Daily Progress Ring (Orange)
        if (_dayIndex > actualDaysPassed) {
          percentDaily = 1.0; // Ahead or Finished today
        } else if (_dayIndex == actualDaysPassed) {
          percentDaily = 0.1; // Just started today
        } else {
          percentDaily = 0.0; // Behind on daily
        }
        
        // Pacing / Commitment Ring (Blue)
        if (actualDaysPassed == 0) {
           percentPacing = 1.0; 
        } else {
           percentPacing = (_dayIndex / actualDaysPassed).clamp(0.0, 1.0);
        }
      } else {
        percentDaily = 0.1;
        percentPacing = 1.0;
      }

      return ListView(
        padding: EdgeInsets.only(
          top: 6,
          bottom: 18 + MediaQuery.of(context).padding.bottom,
        ),
        children: [
          _topTitle("إحصائيات الختمة"),
          _card(
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 28),
              child: Column(
                children: [
                  // 3 Concentric Rings (Apple Fitness Style)
                  CircularPercentIndicator(
                    radius: 95.0,
                    lineWidth: 18.0,
                    animation: true,
                    animateFromLastPercent: true,
                    animationDuration: 1200,
                    curve: Curves.easeOutCubic,
                    percent: percentTotal,
                    circularStrokeCap: CircularStrokeCap.round,
                    backgroundColor: isDark ? Colors.white10 : Colors.black12,
                    linearGradient: const LinearGradient(colors: [Colors.greenAccent, Colors.green]),
                    center: CircularPercentIndicator(
                      radius: 75.0,
                      lineWidth: 16.0,
                      animation: true,
                      animateFromLastPercent: true,
                      animationDuration: 1400,
                      curve: Curves.easeOutCubic,
                      percent: percentDaily,
                      circularStrokeCap: CircularStrokeCap.round,
                      backgroundColor: isDark ? Colors.white10 : Colors.black12,
                      linearGradient: const LinearGradient(colors: [Colors.orangeAccent, Colors.deepOrange]),
                      center: CircularPercentIndicator(
                        radius: 56.0,
                        lineWidth: 14.0,
                        animation: true,
                        animateFromLastPercent: true,
                        animationDuration: 1600,
                        curve: Curves.easeOutCubic,
                        percent: percentPacing,
                        circularStrokeCap: CircularStrokeCap.round,
                        backgroundColor: isDark ? Colors.white10 : Colors.black12,
                        linearGradient: const LinearGradient(colors: [Colors.cyanAccent, Colors.blue]),
                        center: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Text(
                              "${(percentTotal * 100).toInt()}%",
                              style: TextStyle(
                                fontWeight: FontWeight.w900,
                                fontSize: 24,
                                color: isDark ? Colors.white : Colors.black87,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                  const Gap(24),
                  Wrap(
                    alignment: WrapAlignment.center,
                    spacing: 16,
                    runSpacing: 10,
                    children: [
                       _LegendItem(color: Colors.green, label: "الختمة", value: "${(percentTotal * 100).toInt()}%", isDark: isDark),
                       _LegendItem(color: Colors.deepOrange, label: "اليوم", value: percentDaily >= 1.0 ? "مكتمل" : "جاري", isDark: isDark),
                       _LegendItem(color: Colors.blue, label: "الالتزام", value: "${(percentPacing * 100).toInt()}%", isDark: isDark),
                    ],
                  ),
                  const Gap(30),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: [
                      _StatItem(title: "أيام باقية", value: "$daysRemaining", isDark: isDark),
                      Container(width: 1, height: 40, color: isDark ? Colors.white10 : Colors.black12),
                      _StatItem(title: "صفحات قرأت", value: "$totalPagesRead", isDark: isDark),
                      Container(width: 1, height: 40, color: isDark ? Colors.white10 : Colors.black12),
                      _StatItem(title: "باقي (ص)", value: "$pagesRemaining", isDark: isDark, isPrimary: true, themeState: themeState),
                    ],
                  ),
                ],
              ),
            ),
          ),
          const Gap(12),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 18),
            child: Row(
              children: [
                const Expanded(
                  child: Text(
                    "ورد اليوم",
                    style: TextStyle(
                      fontWeight: FontWeight.w900,
                      fontSize: 16,
                    ),
                  ),
                ),
                Text(
                  "أمس",
                  style: TextStyle(
                    fontWeight: FontWeight.w900,
                    fontSize: 16,
                    color: isDark ? Colors.white54 : Colors.black38,
                  ),
                ),
              ],
            ),
          ),
          _card(
            Padding(
              padding: const EdgeInsets.all(14),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Text(
                    todayLabel,
                    style: const TextStyle(
                      height: 1.5,
                      fontWeight: FontWeight.w900,
                      fontSize: 16,
                    ),
                  ),
                  const Gap(6),
                  Text(
                    yesterdayLabel,
                    style: TextStyle(
                      height: 1.5,
                      fontWeight: FontWeight.w700,
                      fontSize: 12,
                      color: isDark ? Colors.white60 : Colors.black45,
                    ),
                  ),
                  const Gap(14),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton.icon(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF0A7A36),
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(999),
                        ),
                      ),
                      onPressed: _markTodayDone,
                      icon: const Icon(Icons.check_circle_rounded),
                      label: const Text(
                        "أكملت هذا الورد",
                        style: TextStyle(fontWeight: FontWeight.w900),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
          const Gap(10),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 18),
            child: Text(
              "تذكير",
              style: TextStyle(
                fontWeight: FontWeight.w900,
                color: isDark ? Colors.white60 : Colors.black45,
              ),
            ),
          ),
          _card(
            Padding(
              padding: const EdgeInsets.all(14),
              child: Row(
                children: [
                  Switch(
                    value: _reminderEnabled,
                    activeColor: themeState.primary,
                    onChanged: (v) async {
                      await _setReminderEnabled(v);
                    },
                  ),
                  const Spacer(),
                  InkWell(
                    onTap: _reminderEnabled ? _pickReminderTime : null,
                    borderRadius: BorderRadius.circular(12),
                    child: Padding(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 10,
                      ),
                      child: Text(
                        _formatTimeForUi(_reminderTime),
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w900,
                          color: _reminderEnabled
                              ? (isDark ? Colors.white : Colors.black87)
                              : (isDark ? Colors.white38 : Colors.black38),
                        ),
                      ),
                    ),
                  ),
                  const Gap(10),
                  Text(
                    "الورد اليومي",
                    style: TextStyle(
                      fontWeight: FontWeight.w800,
                      color: isDark ? Colors.white70 : Colors.black54,
                    ),
                  ),
                  if (_reminderEnabled)
                    IconButton(
                      onPressed: () {
                        KhatmaNotificationService.instance.sendTestNotification();
                      },
                      icon: const Icon(Icons.notifications_active_outlined, size: 20, color: Colors.blue),
                      tooltip: "تجرية الإشعار الآن",
                    ),
                ],
              ),
            ),
          ),
          const Gap(12),
          _card(
            Column(
              children: [
                ListTile(
                  title: const Text(
                    "جميع الأوراد",
                    style: TextStyle(fontWeight: FontWeight.w900),
                  ),
                  onTap: () => setState(() => _step = _WahyKhatmaStep.allWirds),
                ),
                const Divider(height: 1),
                ListTile(
                  title: const Text(
                    "حذف الختمة",
                    style: TextStyle(
                      fontWeight: FontWeight.w900,
                      color: Colors.red,
                    ),
                  ),
                  onTap: () => _confirmResetPlan(context),
                ),
              ],
            ),
          ),
        ],
      );
    }

    Widget allWirds() {
      final daysLocal = _enabled ? _planDays : _selectedProgramDays;
      return ListView.builder(
        padding: EdgeInsets.only(
          top: 6,
          bottom: 18 + MediaQuery.of(context).padding.bottom,
        ),
        itemCount: daysLocal + 1,
        itemBuilder: (c, i) {
          if (i == 0) {
            return _topTitle(
              "بدء الختمة من",
              onBack: () => setState(
                () => _step = _enabled ? _WahyKhatmaStep.active : _WahyKhatmaStep.startFrom,
              ),
            );
          }
          final dayIdx = i - 1;
          return _card(
            ListTile(
              contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
              title: Text(
                "ورد اليوم ${localizedNumber(context, dayIdx + 1)}",
                style: const TextStyle(fontWeight: FontWeight.w900),
              ),
              subtitle: Text(
                _rangeLabelForDay(dayIdx, daysLocal),
                style: TextStyle(
                  height: 1.4,
                  fontWeight: FontWeight.w700,
                  color: isDark ? Colors.white60 : Colors.black45,
                ),
              ),
              onTap: !_enabled
                  ? () async {
                      await _startPlanWithDays(daysLocal);
                      final box = Hive.box(_boxName);
                      await box.put(_kCurrentDayIndexKey, dayIdx);
                      _load();
                      setState(() => _step = _WahyKhatmaStep.active);
                    }
                  : null,
            ),
          );
        },
      );
    }

    Widget current() {
      switch (_step) {
        case _WahyKhatmaStep.empty:
          return empty();
        case _WahyKhatmaStep.newKhatma:
          return newKhatma();
        case _WahyKhatmaStep.program:
          return program();
        case _WahyKhatmaStep.startFrom:
          return startFrom();
        case _WahyKhatmaStep.active:
          return active();
        case _WahyKhatmaStep.allWirds:
          return allWirds();
      }
    }

    return AnimatedSwitcher(
      duration: const Duration(milliseconds: 260),
      switchInCurve: Curves.easeOutCubic,
      switchOutCurve: Curves.easeInCubic,
      child: Container(
        key: ValueKey(_step),
        color: Colors.transparent,
        child: current(),
      ),
    );
  }
}

class _KeyValueRow extends StatelessWidget {
  final String title;
  final String value;
  final ThemeState themeState;

  const _KeyValueRow({
    required this.title,
    required this.value,
    required this.themeState,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Row(
        children: [
          Expanded(
            child: Text(
              title,
              textDirection: TextDirection.rtl,
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w800,
                color: isDark ? Colors.white70 : Colors.black54,
              ),
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
            decoration: BoxDecoration(
              color: themeState.primary.withValues(alpha: 0.10),
              borderRadius: BorderRadius.circular(999),
              border: Border.all(color: themeState.primary.withValues(alpha: 0.20)),
            ),
            child: Text(
              value,
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w900,
                color: themeState.primary,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _KhatmaMushafPage extends StatelessWidget {
  final int startPage;
  final int endPage;

  const _KhatmaMushafPage({
    required this.startPage,
    required this.endPage,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: MushafView(
          useDefaultAppBar: true,
          initialPageNumber: startPage,
        ),
      ),
    );
  }
}

class _StatItem extends StatelessWidget {
  final String title;
  final String value;
  final bool isDark;
  final bool isPrimary;
  final ThemeState? themeState;

  const _StatItem({
    required this.title,
    required this.value,
    required this.isDark,
    this.isPrimary = false,
    this.themeState,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Text(
          value,
          style: TextStyle(
            fontSize: 22,
            fontWeight: FontWeight.w900,
            color: isPrimary && themeState != null ? themeState!.primary : (isDark ? Colors.white : Colors.black87),
          ),
        ),
        const Gap(4),
        Text(
          title,
          style: TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w700,
            color: isDark ? Colors.white54 : Colors.black45,
          ),
        ),
      ],
    );
  }
}

class _LegendItem extends StatelessWidget {
  final Color color;
  final String label;
  final String value;
  final bool isDark;

  const _LegendItem({
    required this.color,
    required this.label,
    required this.value,
    required this.isDark,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 8,
          height: 8,
          decoration: BoxDecoration(shape: BoxShape.circle, color: color),
        ),
        const Gap(6),
        Text(
          "$label:",
          style: TextStyle(
            fontSize: 11,
            fontWeight: FontWeight.w700,
            color: isDark ? Colors.white54 : Colors.black45,
          ),
        ),
        const Gap(4),
        Text(
          value,
          style: TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w900,
            color: isDark ? Colors.white : Colors.black87,
          ),
        ),
      ],
    );
  }
}

class _PlanPicker extends StatelessWidget {
  final ThemeState themeState;
  final SmartKhatmaPlanPreset preset;
  final int customDays;
  final ValueChanged<SmartKhatmaPlanPreset> onPresetChanged;
  final ValueChanged<int> onCustomDaysChanged;

  const _PlanPicker({
    required this.themeState,
    required this.preset,
    required this.customDays,
    required this.onPresetChanged,
    required this.onCustomDaysChanged,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(
          "اختر خطة",
          textDirection: TextDirection.rtl,
          style: TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w900,
            color: isDark ? Colors.white70 : Colors.black54,
          ),
        ),
        const Gap(10),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [
            _PresetChip(
              label: "رمضان (30 يوم)",
              selected: preset == SmartKhatmaPlanPreset.ramadan30,
              themeState: themeState,
              onTap: () => onPresetChanged(SmartKhatmaPlanPreset.ramadan30),
            ),
            _PresetChip(
              label: "20 يوم",
              selected: preset == SmartKhatmaPlanPreset.days20,
              themeState: themeState,
              onTap: () => onPresetChanged(SmartKhatmaPlanPreset.days20),
            ),
            _PresetChip(
              label: "10 أيام",
              selected: preset == SmartKhatmaPlanPreset.days10,
              themeState: themeState,
              onTap: () => onPresetChanged(SmartKhatmaPlanPreset.days10),
            ),
            _PresetChip(
              label: "مخصص",
              selected: preset == SmartKhatmaPlanPreset.custom,
              themeState: themeState,
              onTap: () => onPresetChanged(SmartKhatmaPlanPreset.custom),
            ),
          ],
        ),
        if (preset == SmartKhatmaPlanPreset.custom) ...[
          const Gap(12),
          Row(
            children: [
              Expanded(
                child: Text(
                  "عدد الأيام",
                  textDirection: TextDirection.rtl,
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w900,
                    color: isDark ? Colors.white70 : Colors.black54,
                  ),
                ),
              ),
              SizedBox(
                width: 140,
                child: TextFormField(
                  initialValue: customDays.toString(),
                  keyboardType: TextInputType.number,
                  textDirection: TextDirection.rtl,
                  decoration: const InputDecoration(
                    isDense: true,
                    filled: true,
                    fillColor: Color(0xFFF7F1E6),
                    border: OutlineInputBorder(
                      borderSide: BorderSide.none,
                      borderRadius: BorderRadius.all(Radius.circular(12)),
                    ),
                  ),
                  onChanged: (v) {
                    final parsed = int.tryParse(v.trim());
                    if (parsed == null) return;
                    onCustomDaysChanged(parsed);
                  },
                ),
              ),
            ],
          ),
        ],
      ],
    );
  }
}

class _PresetChip extends StatelessWidget {
  final String label;
  final bool selected;
  final ThemeState themeState;
  final VoidCallback onTap;

  const _PresetChip({
    required this.label,
    required this.selected,
    required this.themeState,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final bg = selected
        ? themeState.primary.withValues(alpha: 0.14)
        : Colors.black.withValues(alpha: 0.04);
    final border = selected
        ? themeState.primary.withValues(alpha: 0.45)
        : Colors.black.withValues(alpha: 0.08);

    return InkWell(
      borderRadius: BorderRadius.circular(999),
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        decoration: BoxDecoration(
          color: bg,
          borderRadius: BorderRadius.circular(999),
          border: Border.all(color: border),
        ),
        child: Text(
          label,
          textDirection: TextDirection.rtl,
          style: TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w900,
            color: selected ? themeState.primary : const Color(0xFF1B1B1B),
          ),
        ),
      ),
    );
  }
}
