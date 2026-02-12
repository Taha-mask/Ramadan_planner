import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import '../theme/app_theme.dart';
import '../services/notification_service.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  bool _prophetReminderEnabled = true;
  String _prophetReminderInterval =
      'everyMinute'; // everyMinute, hourly, daily, weekly
  bool _sunnahReminderEnabled = true;
  bool _quranReminderEnabled = false;
  TimeOfDay _quranReminderTime = const TimeOfDay(hour: 21, minute: 0);

  @override
  void initState() {
    super.initState();
    _loadSettings();
  }

  Future<void> _loadSettings() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _prophetReminderEnabled = prefs.getBool('notify_prophet') ?? true;
      _prophetReminderInterval =
          prefs.getString('notify_prophet_interval') ?? 'everyMinute';
      _sunnahReminderEnabled = prefs.getBool('notify_sunnah') ?? true;
      _quranReminderEnabled = prefs.getBool('notify_quran') ?? false;

      final qHours = prefs.getInt('notify_quran_hour') ?? 21;
      final qMinutes = prefs.getInt('notify_quran_minute') ?? 0;
      _quranReminderTime = TimeOfDay(hour: qHours, minute: qMinutes);
    });
  }

  Future<void> _saveSetting(String key, dynamic value) async {
    final prefs = await SharedPreferences.getInstance();
    if (value is bool) {
      await prefs.setBool(key, value);
    } else if (value is int) {
      await prefs.setInt(key, value);
    } else if (value is String) {
      await prefs.setString(key, value);
    }

    // Refresh notifications configuration
    if (key == 'notify_prophet' || key == 'notify_prophet_interval') {
      if (_prophetReminderEnabled) {
        // Use current state (or new value if passed, but key is split)
        // If we just toggled to false, cancel. If true, schedule.
        // If we changed interval, reschedule.

        // We need the effective values
        bool enabled = key == 'notify_prophet'
            ? value
            : _prophetReminderEnabled;
        String intervalStr = key == 'notify_prophet_interval'
            ? value
            : _prophetReminderInterval;

        if (enabled) {
          RepeatInterval interval = RepeatInterval.everyMinute;
          if (intervalStr == 'hourly') interval = RepeatInterval.hourly;
          if (intervalStr == 'daily') interval = RepeatInterval.daily;
          if (intervalStr == 'weekly') interval = RepeatInterval.weekly;

          await NotificationService().scheduleProphetPrayerReminder(
            interval: interval,
          );
        } else {
          await NotificationService().cancelNotification(777);
        }
      } else {
        // If enabled is false (and we didn't just turn it on), ensure it's cancelled
        await NotificationService().cancelNotification(777);
      }
    }

    // Quran Reminder Logic
    if (key.startsWith('notify_quran')) {
      // Get effective values
      bool enabled = key == 'notify_quran' ? value : _quranReminderEnabled;
      int hour = key == 'notify_quran_hour' ? value : _quranReminderTime.hour;
      int minute = key == 'notify_quran_minute'
          ? value
          : _quranReminderTime.minute;

      if (enabled) {
        await NotificationService().scheduleQuranReminder(
          time: TimeOfDay(hour: hour, minute: minute),
        );
      } else {
        await NotificationService().cancelNotification(8888);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
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
            _prophetReminderEnabled,
            (val) {
              setState(() => _prophetReminderEnabled = val);
              _saveSetting('notify_prophet', val);
            },
          ),
          if (_prophetReminderEnabled)
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
                      value: _prophetReminderInterval,
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
                          setState(() => _prophetReminderInterval = val);
                          _saveSetting('notify_prophet_interval', val);
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
            _sunnahReminderEnabled,
            (val) {
              setState(() => _sunnahReminderEnabled = val);
              _saveSetting('notify_sunnah', val);
            },
          ),

          const Divider(height: 32),
          _buildSectionHeader('الورد القرآني'),
          _buildSwitchTile(
            'تذكير الورد اليومي',
            'تنبيه يومي لقراءة وردك من القرآن',
            _quranReminderEnabled,
            (val) {
              setState(() => _quranReminderEnabled = val);
              _saveSetting('notify_quran', val);
            },
          ),
          if (_quranReminderEnabled)
            ListTile(
              title: const Text('وقت التذكير'),
              subtitle: Text(_formatTime(_quranReminderTime)),
              leading: const Icon(
                Icons.access_time,
                color: AppTheme.primaryEmerald,
              ),
              onTap: () async {
                final createTime = await showTimePicker(
                  context: context,
                  initialTime: _quranReminderTime,
                );
                if (createTime != null) {
                  setState(() => _quranReminderTime = createTime);
                  await _saveSetting('notify_quran_hour', createTime.hour);
                  await _saveSetting('notify_quran_minute', createTime.minute);
                  // Reschedule logic would go here
                }
              },
            ),

          const Divider(height: 32),
          _buildSectionHeader('العادات والمهام'),
          ListTile(
            title: const Text('تنبيهات المهام'),
            subtitle: const Text(
              'يتم ضبط التنبيه لكل مهمة على حدة عند إنشائها',
            ),
            leading: const Icon(
              Icons.notifications_active_outlined,
              color: Colors.grey,
            ),
          ),
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
      activeColor: AppTheme.primaryEmerald,
      onChanged: onChanged,
    );
  }

  String _formatTime(TimeOfDay time) {
    // Simple formatting
    return "${time.hour}:${time.minute.toString().padLeft(2, '0')}";
  }
}
