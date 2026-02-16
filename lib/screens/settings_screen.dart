import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../theme/app_theme.dart';
import 'package:intl/intl.dart';
import '../providers/notification_provider.dart';
import '../providers/worship_provider.dart';
import 'package:share_plus/share_plus.dart';

class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final notificationProv = context.watch<NotificationProvider>();

    return Scaffold(
      appBar: AppBar(
        title: const Text('الإعدادات والتنبيهات'),
        backgroundColor: AppTheme.primaryEmerald,
        foregroundColor: Colors.white,
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          _buildSectionHeader('تنبيهات الصلاة'),
          _buildSwitchTile(
            'التذكير بالصلاة على النبي ﷺ',
            'تفعيل التذكير الدوري',
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
                  const Text(
                    'التكرار:',
                    style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
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
                      items: const [
                        DropdownMenuItem(
                          value: 'everyMinute',
                          child: Text('كل دقيقة'),
                        ),
                        DropdownMenuItem(
                          value: 'hourly',
                          child: Text('كل ساعة'),
                        ),
                        DropdownMenuItem(value: 'daily', child: Text('كل يوم')),
                        DropdownMenuItem(
                          value: 'weekly',
                          child: Text('كل أسبوع'),
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
            'تنبيهات سنن الصلوات',
            'تذكير بالنوافل والسنن الرواتب',
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
          _buildSectionHeader('الورد القرآني'),
          _buildSwitchTile(
            'تذكير الورد اليومي',
            'تنبيه يومي لقراءة وردك من القرآن',
            notificationProv.quranReminderEnabled,
            (val) => notificationProv.toggleQuranReminder(val),
          ),
          if (notificationProv.quranReminderEnabled)
            ListTile(
              title: const Text('وقت التذكير'),
              subtitle: Text(_formatTime(notificationProv.quranReminderTime)),
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
          _buildSectionHeader('تنبيهات المهام'),
          _buildSwitchTile(
            'تذكير بالمهام',
            'تنبيهات عشوائية للمهام على مدار اليوم',
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
                    'عدد التنبيهات يومياً: ${notificationProv.tasksReminderFrequency}',
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
              label: const Text('شارك التطبيق واكسب الأجر'),
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
          const SizedBox(height: 32),
        ],
      ),
    );
  }

  Widget _buildSectionHeader(String title) {
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

  String _formatTime(TimeOfDay time) {
    final now = DateTime.now();
    final dt = DateTime(now.year, now.month, now.day, time.hour, time.minute);
    return DateFormat('h:mm a', 'ar').format(dt);
  }
}
