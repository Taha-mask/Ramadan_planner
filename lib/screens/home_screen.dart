import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import 'package:hijri/hijri_calendar.dart';
import '../providers/worship_provider.dart';
import '../providers/statistics_provider.dart';
import '../providers/theme_provider.dart';
import '../theme/app_theme.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  @override
  void initState() {
    super.initState();
    Future.microtask(() {
      if (mounted) {
        context.read<WorshipProvider>().loadEntries(DateTime.now());
      }
    });
  }

  @override
  @override
  Widget build(BuildContext context) {
    final worshipProvider = context.watch<WorshipProvider>();
    final hDate = HijriCalendar.now();
    final gDate = DateFormat('dd MMMM yyyy', 'ar').format(DateTime.now());

    return DefaultTabController(
      length: 2,
      child: NestedScrollView(
        headerSliverBuilder: (context, innerBoxIsScrolled) {
          return [
            SliverOverlapAbsorber(
              handle: NestedScrollView.sliverOverlapAbsorberHandleFor(context),
              sliver: SliverAppBar(
                expandedHeight: 220.0,
                floating: false,
                pinned: true,
                backgroundColor: AppTheme.primaryEmerald,
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
                  background: Stack(
                    fit: StackFit.expand,
                    children: [
                      Container(
                        decoration: const BoxDecoration(
                          gradient: LinearGradient(
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                            colors: [
                              AppTheme.primaryEmerald,
                              AppTheme.secondaryTeal,
                            ],
                          ),
                        ),
                      ),
                      SafeArea(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            const SizedBox(height: 20),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 16,
                                vertical: 8,
                              ),
                              margin: const EdgeInsets.symmetric(
                                horizontal: 24,
                              ),
                              decoration: BoxDecoration(
                                color: Colors.white.withOpacity(0.15),
                                borderRadius: BorderRadius.circular(16),
                                border: Border.all(
                                  color: Colors.white.withOpacity(0.2),
                                ),
                              ),
                              child: const Text(
                                'إِنَّ الصَّلَاةَ كَانَتْ عَلَى الْمُؤْمِنِينَ كِتَابًا مَّوْقُوتًا',
                                style: TextStyle(
                                  fontSize: 15,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.white,
                                  fontFamily: 'Amiri',
                                ),
                                textAlign: TextAlign.center,
                              ),
                            ),
                            const SizedBox(height: 12),
                            Text(
                              '${hDate.hDay} ${hDate.longMonthName} ${hDate.hYear}',
                              style: const TextStyle(
                                fontSize: 18,
                                color: Colors.white,
                                fontWeight: FontWeight.w900,
                              ),
                            ),
                            Text(
                              gDate,
                              style: TextStyle(
                                fontSize: 12,
                                color: Colors.white.withOpacity(0.8),
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                            const SizedBox(height: 8),
                            _buildProgressCircle(
                              worshipProvider.completionPercentage,
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                bottom: const TabBar(
                  indicatorColor: Colors.white,
                  labelColor: Colors.white,
                  unselectedLabelColor: Colors.white70,
                  labelStyle: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontFamily: 'Amiri',
                  ),
                  tabs: [
                    Tab(text: 'الفرائض'),
                    Tab(text: 'السنن'),
                  ],
                ),
              ),
            ),
          ];
        },
        body: TabBarView(
          children: [
            Builder(
              builder: (context) {
                return CustomScrollView(
                  slivers: [
                    SliverOverlapInjector(
                      handle: NestedScrollView.sliverOverlapAbsorberHandleFor(
                        context,
                      ),
                    ),
                    SliverPadding(
                      padding: const EdgeInsets.all(20),
                      sliver: SliverList(
                        delegate: SliverChildBuilderDelegate((context, index) {
                          final entry = worshipProvider.faraidEntries[index];
                          return _buildPrayerItem(worshipProvider, entry);
                        }, childCount: worshipProvider.faraidEntries.length),
                      ),
                    ),
                  ],
                );
              },
            ),
            Builder(
              builder: (context) {
                return CustomScrollView(
                  slivers: [
                    SliverOverlapInjector(
                      handle: NestedScrollView.sliverOverlapAbsorberHandleFor(
                        context,
                      ),
                    ),
                    SliverPadding(
                      padding: const EdgeInsets.all(20),
                      sliver: SliverList(
                        delegate: SliverChildBuilderDelegate((context, index) {
                          final entry = worshipProvider.sunnahEntries[index];
                          return _buildPrayerItem(worshipProvider, entry);
                        }, childCount: worshipProvider.sunnahEntries.length),
                      ),
                    ),
                  ],
                );
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPrayerItem(WorshipProvider provider, dynamic entry) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 300),
      margin: const EdgeInsets.only(bottom: 10),
      child: Card(
        elevation: entry.isCompleted ? 1 : 4,
        shadowColor: AppTheme.primaryEmerald.withOpacity(0.2),
        child: ListTile(
          contentPadding: const EdgeInsets.symmetric(
            horizontal: 16,
            vertical: 4,
          ),
          leading: Checkbox(
            value: entry.isCompleted,
            onChanged: (val) async {
              await provider.toggleWorshipEntry(entry);
              if (mounted) {
                context.read<HistoryProvider>().refreshStats();
              }
            },
            activeColor: AppTheme.primaryEmerald,
            checkColor: Colors.white,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(4),
            ),
          ),
          title: Text(
            entry.prayerName,
            style: TextStyle(
              fontSize: 17,
              fontWeight: entry.isCompleted ? FontWeight.w500 : FontWeight.w700,
              color: entry.isCompleted
                  ? AppTheme.primaryEmerald.withOpacity(0.6)
                  : Theme.of(context).colorScheme.onSurface,
              decoration: entry.isCompleted ? TextDecoration.lineThrough : null,
            ),
          ),
          subtitle: entry.time != null
              ? Text(
                  DateFormat('hh:mm a', 'ar').format(entry.time!),
                  style: TextStyle(
                    color: Theme.of(
                      context,
                    ).colorScheme.onSurface.withOpacity(0.6),
                    fontWeight: FontWeight.w500,
                  ),
                )
              : null,
          trailing: IconButton(
            icon: const Icon(Icons.notifications_active_outlined),
            color: AppTheme.secondaryTeal,
            onPressed: () {
              provider.scheduleNotification(entry);
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text('تم تفعيل التنبيه لـ ${entry.prayerName}'),
                ),
              );
            },
          ),
        ),
      ),
    );
  }

  Widget _buildProgressCircle(double percentage) {
    return Container(
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.12),
        shape: BoxShape.circle,
        border: Border.all(color: Colors.white.withOpacity(0.2), width: 1),
      ),
      child: Stack(
        alignment: Alignment.center,
        children: [
          SizedBox(
            width: 60,
            height: 60,
            child: CircularProgressIndicator(
              value: percentage,
              strokeWidth: 6,
              backgroundColor: Colors.white.withOpacity(0.1),
              valueColor: const AlwaysStoppedAnimation<Color>(Colors.white),
              strokeCap: StrokeCap.round,
            ),
          ),
          Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                '${(percentage * 100).toInt()}%',
                style: const TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w900,
                  color: Colors.white,
                ),
              ),
              const Text(
                'الإنجاز',
                style: TextStyle(
                  fontSize: 7,
                  color: Colors.white70,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
