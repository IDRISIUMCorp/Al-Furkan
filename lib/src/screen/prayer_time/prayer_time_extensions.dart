import "package:adhan_dart/adhan_dart.dart" hide Prayer;
import "package:al_quran_v3/src/screen/prayer_time/models/prayer_enum.dart";

extension PrayerTimesExtensions on PrayerTimes {

  DateTime get dhuha => sunrise.add(const Duration(minutes: 20));

  DateTime get noon => dhuhr; 

  DateTime get sunset => maghrib;

  DateTime get tahajjud {
    // Calculate night duration: Maghrib (sunset) to Fajr (dawn)
    // Note: This 'fajr' should ideally be tomorrow's Fajr, but for simplicity using today's
    // If strict compliance needed, we need tomorrow's Fajr.
    // Assuming standard approximation for now.
    
    // Duration between Maghrib and Fajr
    Duration nightDuration = fajr.difference(maghrib).abs(); 
    if (maghrib.isAfter(fajr)) {
       // Adjust if crossing midnight
       nightDuration = (const Duration(hours: 24) - maghrib.difference(fajr).abs());
    }

    // Last third starts at Maghrib + 2/3 of night
    int seconds = (nightDuration.inSeconds * (2/3)).round();
    return maghrib.add(Duration(seconds: seconds));
  }
  
  DateTime? timeForCustomPrayer(Prayer prayer) {
    switch (prayer) {
      case Prayer.fajr:
        return fajr;
      case Prayer.sunrise:
        return sunrise;
      case Prayer.dhuhr:
        return dhuhr;
      case Prayer.asr:
        return asr;
      case Prayer.maghrib:
        return maghrib;
      case Prayer.isha:
        return isha;
      case Prayer.dhuha:
        return dhuha;
      case Prayer.noon:
        return noon;
      case Prayer.sunset:
        return sunset;
      case Prayer.tahajjud:
        return tahajjud;
      case Prayer.none:
        return null;
    }
  }

  bool isInsideForbiddenTime(DateTime time) {
    // 1. Sunrise + 15 mins
    if (time.isAfter(sunrise) && time.isBefore(sunrise.add(const Duration(minutes: 15)))) return true;
    
    // 2. Noon (Zenith) - approx 10 mins before Dhuhr
    if (time.isAfter(dhuhr.subtract(const Duration(minutes: 10))) && time.isBefore(dhuhr)) return true;
    
    // 3. Sunset (Maghrib) - approx 15 mins before Maghrib starts
    if (time.isAfter(maghrib.subtract(const Duration(minutes: 15))) && time.isBefore(maghrib)) return true;

    return false;
  }

  double percentageOfTimeLeftUntilNextPrayer({required DateTime now}) {
     Prayer next = nextPrayerExtension(date: now);
     Prayer current = currentPrayerExtension(date: now);
     
     if (next == Prayer.none || current == Prayer.none) return 0.0;
     
     DateTime? nextTime = timeForCustomPrayer(next);
     DateTime? currentTime = timeForCustomPrayer(current); 

     if (nextTime == null || currentTime == null) return 0.0;
     
     // Handle crossing midnight
     if (nextTime.isBefore(currentTime)) {
       nextTime = nextTime.add(const Duration(days: 1));
     }
     
     Duration totalDuration = nextTime.difference(currentTime);
     Duration elapsed = now.difference(currentTime);
     
     if (totalDuration.inSeconds <= 0) return 0.0;
     
     double percentage = elapsed.inSeconds / totalDuration.inSeconds;
     return percentage.clamp(0.0, 1.0);
  }

  Duration timeUntilNextPrayer({required DateTime now}) {
    Prayer next = nextPrayerExtension(date: now);
    DateTime? nextTime = timeForCustomPrayer(next);
    
    if (nextTime == null) return Duration.zero;
    
    if (nextTime.isBefore(now)) {
      // Possible if next prayer is tomorrow (e.g. Fajr)
      nextTime = nextTime.add(const Duration(days: 1));
    }
    
    return nextTime.difference(now);
  }
  
  // Custom Next/Current mapping since package returns its own Enum
  Prayer nextPrayerExtension({required DateTime date}) {
      // Logic to recreate basic nextPrayer but returning our Enum
      // Alternatively, use package's `nextPrayer()` and map it.
      // But package `nextPrayer` returns package's Prayer enum.
      
      // Since we hid Package's Prayer, we can't easily switch on it unless we cast or use dynamic
      // Better to write simple logic:
      
      if (date.isBefore(fajr)) return Prayer.fajr;
      if (date.isBefore(sunrise)) return Prayer.sunrise;
      if (date.isBefore(dhuhr)) return Prayer.dhuhr;
      if (date.isBefore(asr)) return Prayer.asr;
      if (date.isBefore(maghrib)) return Prayer.maghrib;
      if (date.isBefore(isha)) return Prayer.isha;
      
      return Prayer.fajr; // Next is Fajr tomorrow
  }
  
  Prayer currentPrayerExtension({required DateTime date}) {
      if (date.isAfter(isha)) return Prayer.isha;
      if (date.isAfter(maghrib)) return Prayer.maghrib;
      if (date.isAfter(asr)) return Prayer.asr;
      if (date.isAfter(dhuhr)) return Prayer.dhuhr;
      if (date.isAfter(sunrise)) return Prayer.sunrise;
      if (date.isAfter(fajr)) return Prayer.fajr;
      
      return Prayer.isha; // Previous was Isha yesterday
  }
}
