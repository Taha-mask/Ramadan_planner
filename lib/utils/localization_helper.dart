import 'package:flutter/material.dart';
import '../providers/locale_provider.dart';
import 'package:provider/provider.dart';

class LocalizationHelper {
  static const Map<String, Map<String, String>> _translations = {
    'en': {
      'الإعدادات والتنبيهات': 'Settings & Alerts',
      'تنبيهات الصلاة': 'Prayer Alerts',
      'التذكير بالصلاة على النبي ﷺ': 'Remind to Pray upon the Prophet ﷺ',
      'تفعيل التذكير الدوري': 'Enable periodic reminder',
      'التكرار:': 'Frequency:',
      'كل دقيقة': 'Every minute',
      'كل ساعة': 'Every hour',
      'كل يوم': 'Every day',
      'كل أسبوع': 'Every week',
      'تنبيهات سنن الصلوات': 'Sunnah Prayers Alerts',
      'تذكير بالنوافل والسنن الرواتب': 'Remind of Nafl and Sunnah Prayers',
      'الورد القرآني': 'Quran Recitation',
      'تذكير الورد اليومي': 'Daily Quran Reminder',
      'تنبيه يومي لقراءة وردك من القرآن': 'Daily alert to read your Quran portion',
      'وقت التذكير': 'Reminder Time',
      'تنبيهات المهام': 'Task Alerts',
      'تذكير بالمهام': 'Task Reminder',
      'تنبيهات عشوائية للمهام على مدار اليوم': 'Random task alerts throughout the day',
      'عدد التنبيهات يومياً: ': 'Number of alerts per day: ',
      'شارك التطبيق واكسب الأجر': 'Share the App & Earn Reward',
      'تصميم وتطوير': 'Designed & Developed by',
      'تواصل معنا للدعم الفني والاقتراحات': 'Contact us for Technical Support & Suggestions',
      'اللغة': 'Language',
      'الصلوات': 'Prayers',
      'الورد': 'Quran',
      'المهام': 'Tasks',
      'الدروس': 'Lessons',
      'التاريخ': 'History',
    },
    'id': {
      'الإعدادات والتنبيهات': 'Pengaturan & Peringatan',
      'تنبيهات الصلاة': 'Peringatan Shalat',
      'التذكير بالصلاة على النبي ﷺ': 'Pengingat Shalawat Nabi ﷺ',
      'تفعيل التذكير الدوري': 'Aktifkan pengingat berkala',
      'التكرار:': 'Frekuensi:',
      'كل دقيقة': 'Setiap menit',
      'كل ساعة': 'Setiap jam',
      'كل يوم': 'Setiap hari',
      'كل أسبوع': 'Setiap minggu',
      'تنبيهات سنن الصلوات': 'Peringatan Shalat Sunnah',
      'تذكير بالنوافل والسنن الرواتب': 'Pengingat Shalat Nafl & Sunnah',
      'الورد القرآني': 'Bacaan Al-Quran',
      'تذكير الورد اليومي': 'Pengingat Al-Quran Harian',
      'تنبيه يومي لقراءة وردك من القرآن': 'Peringatan harian untuk membaca bagian Al-Quran Anda',
      'وقت التذكير': 'Waktu Pengingat',
      'تنبيهات المهام': 'Peringatan Tugas',
      'تذكير بالمهام': 'Pengingat Tugas',
      'تنبيهات عشوائية للمهام على مدار اليوم': 'Peringatan tugas acak sepanjang hari',
      'عدد التنبيهات يومياً: ': 'Jumlah peringatan per hari: ',
      'شارك التطبيق واكسب الأجر': 'Bagikan Aplikasi & Dapatkan Pahala',
      'تصميم وتطوير': 'Dirancang & Dikembangkan oleh',
      'تواصل معنا للدعم الفني والاقتراحات': 'Hubungi kami untuk Dukungan Teknis & Saran',
      'اللغة': 'Bahasa',
      'الصلوات': 'Shalat',
      'الورد': 'Al-Quran',
      'المهام': 'Tugas',
      'الدروس': 'Pelajaran',
      'التاريخ': 'Riwayat',
    }
  };

  static String translate(BuildContext context, String key) {
    if (!context.mounted) return key;
    try {
      final localeProvider = context.read<LocaleProvider>();
      final langCode = localeProvider.locale.languageCode;
      
      if (langCode == 'ar') return key;

      if (_translations.containsKey(langCode) && _translations[langCode]!.containsKey(key)) {
        return _translations[langCode]![key]!;
      }
      return key; // Fallback to Arabic original key if translation not found
    } catch (_) {
      return key;
    }
  }
}

extension LocalizationExtension on String {
  String tr(BuildContext context) {
    return LocalizationHelper.translate(context, this);
  }
}
