import 'package:adhan/adhan.dart';
import 'package:intl/intl.dart';
import 'package:flutter/foundation.dart';
import 'location_service.dart';

class PrayerService {
  // Cairo Coordinates (Default)
  // Cairo Coordinates (Default)
  static const double _defaultLat = 30.0444;
  static const double _defaultLong = 31.2357;

  Coordinates _coordinates = Coordinates(_defaultLat, _defaultLong);

  // Update coordinates from LocationService
  Future<void> initLocation() async {
    try {
      final position = await LocationService().determinePosition();
      if (position != null) {
        _coordinates = Coordinates(position.latitude, position.longitude);
      }
    } catch (e) {
      debugPrint("Error initializing location: $e");
    }
  }

  // Update coordinates manually if we implement GPS later
  void updateCoordinates(double lat, double long) {
    _coordinates = Coordinates(lat, long);
  }

  PrayerTimes getPrayerTimes(DateTime date) {
    final params = CalculationMethod.egyptian.getParameters();
    params.madhab = Madhab.shafi;

    final dateComponents = DateComponents.from(date);
    return PrayerTimes(_coordinates, dateComponents, params);
  }

  // Map Adhan Prayer names to our app's prayer names (Faraid)
  Map<String, DateTime> getFaraidTimes(DateTime date) {
    final prayerTimes = getPrayerTimes(date);

    return {
      'فجر': prayerTimes.fajr,
      'ظهر (فرض)': prayerTimes.dhuhr,
      'عصر': prayerTimes.asr,
      'مغرب': prayerTimes.maghrib,
      'عشاء': prayerTimes.isha,
    };
  }

  // Calculate Sunnah times relative to Faraid
  // Note: These are approximations or fixed offsets typically used
  Map<String, DateTime> getSunnahTimes(DateTime date) {
    final prayerTimes = getPrayerTimes(date);

    return {
      'تهجد': prayerTimes.fajr.subtract(const Duration(minutes: 45)), // Approx
      'صبح': prayerTimes.sunrise, // Shorooq
      'ضحى': prayerTimes.sunrise.add(const Duration(minutes: 20)),
      'ظهر (سنة قبلية)': prayerTimes.dhuhr.subtract(
        const Duration(minutes: 10),
      ),
      'ظهر (سنة بعدية)': prayerTimes.dhuhr.add(const Duration(minutes: 10)),
      'مغرب (سنة)': prayerTimes.maghrib.add(const Duration(minutes: 5)),
      'عشاء (سنة)': prayerTimes.isha.add(const Duration(minutes: 10)),
    };
  }

  String formatTime(DateTime time) {
    return DateFormat('hh:mm a', 'ar').format(time);
  }
}
