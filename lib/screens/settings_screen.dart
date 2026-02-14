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
                    'عدد التنبيهات يومياً: ${notificationProv.tasksFrequency}',
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                  Slider(
                    value: notificationProv.tasksFrequency.toDouble(),
                    min: 1,
                    max: 10,
                    divisions: 9,
                    label: '${notificationProv.tasksFrequency}',
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
          const Divider(height: 32),
          _buildSectionHeader('مشاركة التطبيق'),
          Card(
            elevation: 2,
            margin: const EdgeInsets.symmetric(vertical: 8),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                children: [
                  const Text(
                    '«مَنْ دَلَّ عَلَى خَيْرٍ فَلَهُ مِثْلُ أَجْرِ فَاعِلِهِ»',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      fontFamily: 'Amiri',
                      color: AppTheme.primaryEmerald,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'رواه مسلم',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 14,
                      color: Colors.grey[600],
                      fontFamily: 'Cairo',
                    ),
                  ),
                  const SizedBox(height: 16),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton.icon(
                      onPressed: () {
                        _shareApp(context);
                      },
                      icon: const Icon(Icons.share_rounded),
                      label: const Text(
                        'شارك التطبيق مع الأصدقاء',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppTheme.primaryEmerald,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),

          const Divider(height: 32),
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

  static void _shareApp(BuildContext context) {
    const String shareMessage = '''
السلام عليكم ورحمة الله وبركاته 🌙

أحب أن أشارككم تطبيق "مخطط رمضان" - تطبيق إسلامي شامل يساعدك على:
✅ تنظيم مهامك اليومية
✅ متابعة أذكارك وعباداتك
✅ مواقيت الصلاة والتنبيهات
✅ ورد القرآن الكريم
✅ تقييم يومك ومحاسبة النفس

«مَنْ دَلَّ عَلَى خَيْرٍ فَلَهُ مِثْلُ أَجْرِ فَاعِلِهِ» - رواه مسلم

حمّل التطبيق الآن وابدأ رحلتك الإيمانية! 🌟

رابط التحميل:
https://drive.google.com/file/d/11nLdAAS5LvQibFOeDk7GXYWKwraAUXEP/view?usp=drive_link
''';

    Share.share(shareMessage, subject: 'تطبيق مخطط رمضان - تطبيق إسلامي شامل');
  }
}
