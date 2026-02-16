import 'dart:async';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import 'package:hijri/hijri_calendar.dart';
import '../providers/worship_provider.dart';
import '../providers/statistics_provider.dart';
import '../providers/theme_provider.dart';
import '../theme/app_theme.dart';

import '../services/location_service.dart';
import 'settings_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    // Update UI every second for the countdown
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (mounted) {
        setState(() {});
      }
    });

    // Check for day change less frequently or on init
    Future.microtask(() {
      if (mounted) {
        context.read<WorshipProvider>().checkDayChange();
      }
    });
  }

  // Monitor app lifecycle to refresh data when returning from background
  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    // Ensure data is fresh when widget is verifiable
    context.read<WorshipProvider>().checkDayChange();
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final worshipProvider = context.watch<WorshipProvider>();
    final hDate = HijriCalendar.now();
    final gDate = DateFormat('dd MMMM yyyy', 'ar').format(DateTime.now());

    return Scaffold(
      body: DefaultTabController(
        length: 2,
        child: NestedScrollView(
          headerSliverBuilder: (context, innerBoxIsScrolled) {
            return [
              SliverAppBar(
                expandedHeight: 380.0,
                floating: false,
                pinned: true,
                stretch: true,
                backgroundColor: AppTheme.primaryEmerald,
                elevation: 0,
                leading: IconButton(
                  icon: const Icon(
                    Icons.settings_outlined,
                    color: Colors.white,
                  ),
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => const SettingsScreen(),
                      ),
                    );
                  },
                ),
                actions: [
                  IconButton(
                    icon: Icon(
                      context.watch<ThemeProvider>().isDarkMode
                          ? Icons.light_mode_rounded
                          : Icons.dark_mode_rounded,
                      color: Colors.white,
                    ),
                    onPressed: () =>
                        context.read<ThemeProvider>().toggleTheme(),
                  ),
                ],
                flexibleSpace: FlexibleSpaceBar(
                  stretchModes: const [
                    StretchMode.zoomBackground,
                    StretchMode.blurBackground,
                  ],
                  background: Stack(
                    fit: StackFit.expand,
                    children: [
                      // Premium Gradient Background
                      Container(
                        decoration: const BoxDecoration(
                          gradient: LinearGradient(
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                            colors: [
                              AppTheme.primaryEmerald,
                              AppTheme.secondaryTeal,
                              AppTheme.deepIndigo,
                            ],
                          ),
                        ),
                      ),
                      // Glassmorphism Overlay for content
                      SafeArea(
                        child: Column(
                          children: [
                            const SizedBox(height: 20),
                            _buildTopInfoSection(hDate, gDate),
                            const SizedBox(height: 20),
                            _buildPrayerCountdownHero(worshipProvider),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                bottom: PreferredSize(
                  preferredSize: const Size.fromHeight(48),
                  child: Container(
                    decoration: BoxDecoration(
                      color: Theme.of(context).scaffoldBackgroundColor,
                      borderRadius: const BorderRadius.vertical(
                        top: Radius.circular(30),
                      ),
                    ),
                    child: TabBar(
                      indicatorSize: TabBarIndicatorSize.tab,
                      indicator: BoxDecoration(
                        borderRadius: const BorderRadius.vertical(
                          top: Radius.circular(30),
                        ),
                        color: AppTheme.primaryEmerald.withValues(alpha: 0.1),
                      ),
                      labelColor: AppTheme.primaryEmerald,
                      unselectedLabelColor: Colors.grey,
                      labelStyle: const TextStyle(
                        fontWeight: FontWeight.w900,
                        fontFamily: 'Cairo',
                      ),
                      tabs: const [
                        Tab(text: 'الفرائض'),
                        Tab(text: 'السنن'),
                      ],
                    ),
                  ),
                ),
              ),
            ];
          },
          body: Container(
            color: Theme.of(context).scaffoldBackgroundColor,
            child: TabBarView(
              children: [
                _buildPrayerList(
                  worshipProvider,
                  worshipProvider.faraidEntries,
                ),
                _buildPrayerList(
                  worshipProvider,
                  worshipProvider.sunnahEntries,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildTopInfoSection(HijriCalendar hDate, String gDate) {
    return Column(
      children: [
        Text(
          '${hDate.hDay} ${hDate.longMonthName} ${hDate.hYear}',
          style: const TextStyle(
            fontSize: 22,
            color: Colors.white,
            fontWeight: FontWeight.w900,
            letterSpacing: 0.5,
          ),
        ),
        Text(
          gDate,
          style: TextStyle(
            fontSize: 14,
            color: Colors.white.withValues(alpha: 0.7),
            fontWeight: FontWeight.w500,
          ),
        ),
        const SizedBox(height: 8),
        _buildLocationWidget(),
      ],
    );
  }

  Widget _buildPrayerCountdownHero(WorshipProvider provider) {
    final next = provider.nextPrayer;
    final timeRemaining = provider.timeToNextPrayer;

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 24),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(30),
        border: Border.all(color: Colors.white.withValues(alpha: 0.2)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.1),
            blurRadius: 20,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'الصلاة القادمة',
                    style: TextStyle(
                      color: Colors.white.withValues(alpha: 0.8),
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  Text(
                    next?.prayerName ?? 'تمت جميع الصلوات',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 24,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                ],
              ),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.2),
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.timer_outlined,
                  color: Colors.white,
                  size: 30,
                ),
              ),
            ],
          ),
          const Divider(color: Colors.white24, height: 30),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              _buildCountdownUnit(
                (timeRemaining?.inSeconds.remainder(60) ?? 0)
                    .toString()
                    .padLeft(2, '0'),
                'ثانية',
              ),
              _buildCountdownSeparator(),
              _buildCountdownUnit(
                (timeRemaining?.inMinutes.remainder(60) ?? 0)
                    .toString()
                    .padLeft(2, '0'),
                'دقيقة',
              ),
              _buildCountdownSeparator(),
              _buildCountdownUnit(
                timeRemaining?.inHours.toString().padLeft(2, '0') ?? '00',
                'ساعة',
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildCountdownUnit(String value, String label) {
    return Column(
      children: [
        Text(
          value,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 28,
            fontWeight: FontWeight.w900,
            fontFamily: 'monospace',
          ),
        ),
        Text(
          label,
          style: TextStyle(
            color: Colors.white.withValues(alpha: 0.6),
            fontSize: 10,
            fontWeight: FontWeight.bold,
          ),
        ),
      ],
    );
  }

  Widget _buildCountdownSeparator() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 10),
      child: Text(
        ':',
        style: TextStyle(
          color: Colors.white.withValues(alpha: 0.5),
          fontSize: 24,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }

  Widget _buildPrayerList(WorshipProvider provider, List<dynamic> entries) {
    return ListView.builder(
      padding: const EdgeInsets.fromLTRB(20, 20, 20, 100),
      itemCount: entries.length + 1, // +1 for spiritual card
      itemBuilder: (context, index) {
        if (index == 0) {
          return _buildSpiritualInsightCard();
        }
        final entry = entries[index - 1];
        return _buildModernPrayerItem(provider, entry);
      },
    );
  }

  Widget _buildSpiritualInsightCard() {
    return Container(
      margin: const EdgeInsets.only(bottom: 20),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            AppTheme.primaryEmerald.withValues(alpha: 0.05),
            AppTheme.secondaryTeal.withValues(alpha: 0.1),
          ],
        ),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(
          color: AppTheme.primaryEmerald.withValues(alpha: 0.1),
        ),
      ),
      child: Column(
        children: [
          Row(
            children: [
              Icon(
                Icons.auto_awesome,
                color: AppTheme.primaryEmerald,
                size: 20,
              ),
              const SizedBox(width: 8),
              const Text(
                'خاطرة اليوم',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                  color: AppTheme.primaryEmerald,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          const Text(
            ' "الصلاة هي عماد الدين، فمن أقامها فقد أقام الدين، ومن هدمها فقد هدم الدين" ',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 15,
              fontStyle: FontStyle.italic,
              fontFamily: 'Amiri',
              height: 1.5,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildModernPrayerItem(WorshipProvider provider, dynamic entry) {
    final bool isNext = provider.nextPrayer?.id == entry.id;

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(20),
        border: isNext
            ? Border.all(color: AppTheme.primaryEmerald, width: 2)
            : Border.all(color: Colors.transparent),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.03),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
        leading: GestureDetector(
          onTap: () async {
            await provider.toggleWorshipEntry(entry);
            if (mounted) {
              context.read<HistoryProvider>().refreshStats();
            }
          },
          child: AnimatedSwitcher(
            duration: const Duration(milliseconds: 300),
            child: entry.isCompleted
                ? const Icon(
                    Icons.check_circle,
                    color: AppTheme.primaryEmerald,
                    size: 32,
                  )
                : Icon(
                    Icons.radio_button_unchecked,
                    color: Colors.grey.withValues(alpha: 0.5),
                    size: 32,
                  ),
          ),
        ),
        title: Text(
          entry.prayerName,
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.w800,
            color: entry.isCompleted
                ? AppTheme.primaryEmerald.withValues(alpha: 0.5)
                : null,
            decoration: entry.isCompleted ? TextDecoration.lineThrough : null,
          ),
        ),
        subtitle: Text(
          entry.time != null
              ? DateFormat('hh:mm a', 'ar').format(entry.time!)
              : '--:--',
          style: TextStyle(fontWeight: FontWeight.bold, color: Colors.grey),
        ),
        trailing: isNext
            ? Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 4,
                ),
                decoration: BoxDecoration(
                  color: AppTheme.primaryEmerald,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Text(
                  'التالية',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 10,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              )
            : null,
      ),
    );
  }

  Widget _buildLocationWidget() {
    return FutureBuilder<String?>(
      future: LocationService().getSavedAddress(),
      builder: (context, snapshot) {
        final address = snapshot.data ?? 'اضغط لتحديد الموقع';
        return InkWell(
          onTap: _pickLocation,
          onLongPress: _manualAddressEntry,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: Colors.white.withValues(alpha: 0.3)),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(
                  Icons.location_on_rounded,
                  size: 16,
                  color: Colors.white,
                ),
                const SizedBox(width: 8),
                Text(
                  address,
                  style: const TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Future<void> _pickLocation() async {
    try {
      final address = await LocationService().getCurrentAddress();
      if (address != null && mounted) {
        setState(() {}); // Refresh to show new address
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text('تم تحديث الموقع بنجاح')));
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('فشل في الحصول على الموقع: $e')));
      }
    }
  }

  Future<void> _manualAddressEntry() async {
    final controller = TextEditingController();
    final saved = await LocationService().getSavedAddress();
    controller.text = saved ?? '';

    if (!mounted) return;

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('إدخال العنوان يدوياً', textAlign: TextAlign.right),
        content: TextField(
          controller: controller,
          textAlign: TextAlign.right,
          decoration: const InputDecoration(hintText: 'أدخل عنوانك هنا...'),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('إلغاء'),
          ),
          ElevatedButton(
            onPressed: () async {
              if (controller.text.isNotEmpty) {
                await LocationService().saveAddress(controller.text);
                if (context.mounted) {
                  setState(() {});
                  Navigator.pop(context);
                }
              }
            },
            child: const Text('حفظ'),
          ),
        ],
      ),
    );
  }
}
