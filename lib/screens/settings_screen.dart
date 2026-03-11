import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../theme/app_theme.dart';
import 'package:intl/intl.dart';
import '../providers/notification_provider.dart';
import '../providers/worship_provider.dart';
import 'package:share_plus/share_plus.dart';
import 'package:url_launcher/url_launcher.dart';
import '../utils/localization_helper.dart';
import '../providers/locale_provider.dart';

class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final notificationProv = context.watch<NotificationProvider>();
    final localeProvider = context.watch<LocaleProvider>();

    return Scaffold(
      appBar: AppBar(
        title: Text('الإعدادات والتنبيهات'.tr(context)),
        backgroundColor: AppTheme.primaryEmerald,
        foregroundColor: Colors.white,
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          _buildSectionHeader('اللغة'.tr(context), context),
          _buildLanguageSelector(context, localeProvider),
          const Divider(height: 32),
          
          _buildSectionHeader('تنبيهات الصلاة'.tr(context), context),
          _buildSwitchTile(
            'التذكير بالصلاة على النبي ﷺ'.tr(context),
            'تفعيل التذكير الدوري'.tr(context),
            notificationProv.prophetReminderEnabled,
            (val) => notificationProv.toggleProphetReminder(val),
          ),
          if (notificationProv.prophetReminderEnabled)
            Padding(
              padding: const EdgeInsets.symmetric(
                horizontal: 16.0,
                vertical: 8,
              ),
              child: Row(
                children: [
                  Text(
                    'التكرار:'.tr(context),
                    style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                  ),
                  const Spacer(),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12),
                    decoration: BoxDecoration(
                      border: Border.all(color: AppTheme.primaryEmerald),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: DropdownButton<String>(
                      value: notificationProv.prophetReminderInterval,
                      underline: const SizedBox(),
                      icon: const Icon(
                        Icons.arrow_drop_down,
                        color: AppTheme.primaryEmerald,
                      ),
                      items: [
                        DropdownMenuItem(
                          value: 'everyMinute',
                          child: Text('كل دقيقة'.tr(context)),
                        ),
                        DropdownMenuItem(
                          value: 'hourly',
                          child: Text('كل ساعة'.tr(context)),
                        ),
                        DropdownMenuItem(
                          value: 'daily',
                          child: Text('كل يوم'.tr(context))
                        ),
                        DropdownMenuItem(
                          value: 'weekly',
                          child: Text('كل أسبوع'.tr(context)),
                        ),
                      ],
                      onChanged: (val) {
                        if (val != null) {
                          notificationProv.setProphetInterval(val);
                        }
                      },
                    ),
                  ),
                ],
              ),
            ),

          _buildSwitchTile(
            'تنبيهات سنن الصلوات'.tr(context),
            'تذكير بالنوافل والسنن الرواتب'.tr(context),
            notificationProv.sunnahReminderEnabled,
            (val) async {
              await notificationProv.toggleSunnahReminder(val);
              // Trigger reschedule in WorshipProvider
              if (context.mounted) {
                context.read<WorshipProvider>().loadEntries(DateTime.now());
              }
            },
          ),

          const Divider(height: 32),
          _buildSectionHeader('الورد القرآني'.tr(context), context),
          _buildSwitchTile(
            'تذكير الورد اليومي'.tr(context),
            'تنبيه يومي لقراءة وردك من القرآن'.tr(context),
            notificationProv.quranReminderEnabled,
            (val) => notificationProv.toggleQuranReminder(val),
          ),
          if (notificationProv.quranReminderEnabled)
            ListTile(
              title: Text('وقت التذكير'.tr(context)),
              subtitle: Text(_formatTime(notificationProv.quranReminderTime, localeProvider)),
              leading: const Icon(
                Icons.access_time,
                color: AppTheme.primaryEmerald,
              ),
              onTap: () async {
                final createTime = await showTimePicker(
                  context: context,
                  initialTime: notificationProv.quranReminderTime,
                );
                if (createTime != null) {
                  notificationProv.setQuranTime(createTime);
                }
              },
            ),

          const Divider(height: 32),
          _buildSectionHeader('تنبيهات المهام'.tr(context), context),
          _buildSwitchTile(
            'تذكير بالمهام'.tr(context),
            'تنبيهات عشوائية للمهام على مدار اليوم'.tr(context),
            notificationProv.tasksReminderEnabled,
            (val) => notificationProv.toggleTasksReminder(val),
          ),
          if (notificationProv.tasksReminderEnabled)
            Padding(
              padding: const EdgeInsets.symmetric(
                horizontal: 16.0,
                vertical: 8.0,
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '${'عدد التنبيهات يومياً: '.tr(context)}${notificationProv.tasksReminderFrequency}',
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                  Slider(
                    value: notificationProv.tasksReminderFrequency.toDouble(),
                    min: 1,
                    max: 10,
                    divisions: 9,
                    label: '${notificationProv.tasksReminderFrequency}',
                    activeColor: AppTheme.primaryEmerald,
                    onChanged: (val) {
                      // Visual feedback during drag
                    },
                    onChangeEnd: (val) {
                      notificationProv.setTasksFrequency(val.round());
                    },
                  ),
                ],
              ),
            ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16.0),
            child: ElevatedButton.icon(
              onPressed: () {
                const String shareText = """
قال رسول الله ﷺ: (الدال على الخير كفاعله)
شارك تطبيق "رفيق الصائم" لتنظيم عباداتك في رمضان!

✨ مميزات التطبيق:
✅ بدون إعلانات نهائياً (راحتك تهمنا)
✅ مواقيت الصلاة دقيقة 🕌
✅ أذكار وتنبيهات مخصصة 📿
✅ ورد قرآني يومي 📖
✅ متابعة العادات والمهام 📝

حمله الآن وشاركه مع أحبابك!
📥 رابط التحميل:
https://drive.google.com/file/d/1_gjcx5ubK2dY9ySdjOhHfFqNVKw2Qe3j/view?usp=drive_link
""";
                Share.share(shareText);
              },
              icon: const Icon(Icons.share),
              label: Text('شارك التطبيق واكسب الأجر'.tr(context)),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppTheme.primaryEmerald,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 12),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
            ),
          ),
          const SizedBox(height: 24),
          Center(
            child: Column(
              children: [
                Text(
                  'تصميم وتطوير'.tr(context),
                  style: TextStyle(color: Colors.grey[600], fontSize: 12),
                ),
                const SizedBox(height: 4),
                const Text(
                  'Taha Mahmoud Ahmed',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                    color: AppTheme.primaryEmerald,
                  ),
                ),
                const SizedBox(height: 8),
                InkWell(
                  borderRadius: BorderRadius.circular(20),
                  onTap: () async {
                    final Uri launchUri = Uri(
                      scheme: 'tel',
                      path: '01120927249',
                    );
                    if (await canLaunchUrl(launchUri)) {
                      await launchUrl(launchUri);
                    }
                  },
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 8,
                    ),
                    decoration: BoxDecoration(
                      color: AppTheme.primaryEmerald.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(
                          Icons.phone,
                          size: 16,
                          color: AppTheme.primaryEmerald,
                        ),
                        const SizedBox(width: 8),
                        const Text(
                          '01120927249',
                          style: TextStyle(
                            color: AppTheme.primaryEmerald,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'تواصل معنا للدعم الفني والاقتراحات'.tr(context),
                  style: TextStyle(color: Colors.grey[500], fontSize: 10),
                ),
              ],
            ),
          ),
          const SizedBox(height: 32),
        ],
      ),
    );
  }

  Widget _buildLanguageSelector(BuildContext context, LocaleProvider provider) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16.0),
      child: SegmentedButton<String>(
        segments: const [
          ButtonSegment(
            value: 'ar',
            label: Text('العربية'),
          ),
          ButtonSegment(
            value: 'en',
            label: Text('English'),
          ),
          ButtonSegment(
            value: 'id',
            label: Text('Indonesia'),
          ),
        ],
        selected: {provider.locale.languageCode},
        onSelectionChanged: (Set<String> newSelection) {
          provider.setLocale(Locale(newSelection.first));
        },
        style: ButtonStyle(
          visualDensity: VisualDensity.compact,
        ),
      ),
    );
  }

  Widget _buildSectionHeader(String title, BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Text(
        title,
        style: const TextStyle(
          fontSize: 18,
          fontWeight: FontWeight.bold,
          color: AppTheme.primaryEmerald,
        ),
      ),
    );
  }

  Widget _buildSwitchTile(
    String title,
    String subtitle,
    bool value,
    Function(bool) onChanged,
  ) {
    return SwitchListTile(
      title: Text(title, style: const TextStyle(fontWeight: FontWeight.w600)),
      subtitle: Text(
        subtitle,
        style: const TextStyle(fontSize: 12, color: Colors.grey),
      ),
      value: value,
      activeThumbColor: AppTheme.primaryEmerald,
      onChanged: onChanged,
    );
  }

  String _formatTime(TimeOfDay time, LocaleProvider localeProvider) {
    final now = DateTime.now();
    final dt = DateTime(now.year, now.month, now.day, time.hour, time.minute);
    return DateFormat('h:mm a', localeProvider.locale.languageCode).format(dt);
  }
}
