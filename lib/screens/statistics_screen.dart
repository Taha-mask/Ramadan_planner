import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/statistics_provider.dart';
import '../providers/theme_provider.dart';
import '../theme/app_theme.dart';
import 'package:intl/intl.dart';

class StatisticsScreen extends StatefulWidget {
  const StatisticsScreen({super.key});

  @override
  State<StatisticsScreen> createState() => _StatisticsScreenState();
}

class _StatisticsScreenState extends State<StatisticsScreen> {
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';

  @override
  void initState() {
    super.initState();
    Future.microtask(() {
      if (mounted) {
        context.read<HistoryProvider>().refreshStats();
      }
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _selectDate() async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: DateTime.now(),
      firstDate: DateTime(2024),
      lastDate: DateTime.now(),
      locale: const Locale('ar'),
    );
    if (picked != null) {
      setState(() {
        _searchController.text = DateFormat('yyyy-MM-dd').format(picked);
        _searchQuery = _searchController.text;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final stats = context.watch<HistoryProvider>();

    return Scaffold(
      appBar: AppBar(
        title: const Text('التاريخ'),
        elevation: 0,
        actions: [
          IconButton(
            icon: Icon(
              context.watch<ThemeProvider>().isDarkMode
                  ? Icons.light_mode_rounded
                  : Icons.dark_mode_rounded,
            ),
            onPressed: () => context.read<ThemeProvider>().toggleTheme(),
          ),
        ],
      ),
      body: stats.totalPrayers30Days == 0 && stats.azkarStats.isEmpty
          ? _buildEmptyState()
          : SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildSummarySection(stats),
                  const SizedBox(height: 32),
                  _buildSectionHeader('سجل العبادات اليومي'),
                  const SizedBox(height: 16),
                  _buildSearchBar(),
                  const SizedBox(height: 16),
                  _buildHistoryList(stats),
                  const SizedBox(height: 40),
                ],
              ),
            ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.history_toggle_off_rounded,
            size: 80,
            color: AppTheme.primaryEmerald.withOpacity(0.2),
          ),
          const SizedBox(height: 20),
          Text(
            'لا توجد بيانات مسجلة بعد',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: AppTheme.deepIndigo.withOpacity(0.5),
            ),
          ),
          const SizedBox(height: 10),
          const Text(
            'ابدأ بتسجيل عباداتك لتراها هنا',
            style: TextStyle(color: Colors.grey),
          ),
        ],
      ),
    );
  }

  Widget _buildSectionHeader(String title) {
    return Text(
      title,
      style: TextStyle(
        fontSize: 20,
        fontWeight: FontWeight.w800,
        color: Theme.of(context).colorScheme.onSurface,
      ),
    );
  }

  Widget _buildSummarySection(HistoryProvider stats) {
    return Column(
      children: [
        _buildStatCard(
          'إجمالي الصلوات (30 يوم)',
          '${stats.totalPrayers30Days}',
          Icons.mosque_outlined,
          AppTheme.primaryEmerald,
        ),
        const SizedBox(height: 12),
        _buildStatCard(
          'متوسط الإنجاز اليومي',
          '${(stats.last30DaysAverage * 100).toInt()}%',
          Icons.analytics_outlined,
          Colors.blueAccent,
        ),
        const SizedBox(height: 12),
        _buildStatCard(
          'سلسلة الإنجاز (Streak)',
          '${stats.currentStreak} يوم',
          Icons.local_fire_department_rounded,
          Colors.orange,
        ),
      ],
    );
  }

  Widget _buildStatCard(
    String title,
    String value,
    IconData icon,
    Color color,
  ) {
    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20),
        side: BorderSide(color: color.withOpacity(0.1), width: 1),
      ),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: color.withOpacity(0.1),
                shape: BoxShape.circle,
              ),
              child: Icon(icon, color: color, size: 28),
            ),
            const SizedBox(width: 20),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: const TextStyle(
                      color: Colors.grey,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  Text(
                    value,
                    style: TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.w900,
                      color: color,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSearchBar() {
    return Row(
      children: [
        Expanded(
          child: TextField(
            controller: _searchController,
            decoration: InputDecoration(
              hintText: 'ابحث بالتاريخ (مثلاً: 2024-02-08)',
              prefixIcon: const Icon(Icons.search_rounded),
              suffixIcon: _searchQuery.isNotEmpty
                  ? IconButton(
                      icon: const Icon(Icons.clear_rounded),
                      onPressed: () {
                        _searchController.clear();
                        setState(() => _searchQuery = '');
                      },
                    )
                  : null,
            ),
            onChanged: (val) => setState(() => _searchQuery = val),
          ),
        ),
        const SizedBox(width: 12),
        Container(
          decoration: BoxDecoration(
            color: AppTheme.primaryEmerald.withOpacity(0.1),
            borderRadius: BorderRadius.circular(16),
          ),
          child: IconButton(
            icon: const Icon(
              Icons.calendar_month_rounded,
              color: AppTheme.primaryEmerald,
            ),
            onPressed: _selectDate,
          ),
        ),
      ],
    );
  }

  Widget _buildHistoryList(HistoryProvider stats) {
    var history = stats.history;
    if (_searchQuery.isNotEmpty) {
      history = history.where((entry) {
        final dateObj = DateTime.parse(entry.date);
        final formattedDate = DateFormat(
          'EEEE, d MMMM yyyy',
          'ar',
        ).format(dateObj);
        return entry.date.contains(_searchQuery) ||
            formattedDate.contains(_searchQuery) ||
            (entry.assessment?.notes.contains(_searchQuery) ?? false) ||
            (entry.assessment?.dua.contains(_searchQuery) ?? false);
      }).toList();
    }

    if (history.isEmpty) {
      return const Center(
        child: Padding(
          padding: EdgeInsets.all(32.0),
          child: Text('لم يتم العثور على نتائج'),
        ),
      );
    }

    return Column(
      children: history.map((entry) {
        final dateObj = DateTime.parse(entry.date);
        final formattedDate = DateFormat(
          'EEEE, d MMMM yyyy',
          'ar',
        ).format(dateObj);

        // Prayer stats
        final completedPrayers = entry.prayers.where((p) => p.isCompleted);
        final prayerCount = completedPrayers.length;
        final tasksList = entry.tasks;
        final completedTasks = tasksList.where((t) => t.isCompleted).length;
        final totalTasks = tasksList.length;

        // Assessment
        final hasAssessment = entry.assessment != null;
        final rating = hasAssessment ? entry.assessment!.rating : 0.0;
        final hasDua = hasAssessment && entry.assessment!.dua.isNotEmpty;
        final notes = hasAssessment ? entry.assessment!.notes : '';

        // Status color based on completeness
        Color statusColor = Colors.grey;
        if (prayerCount >= 10) {
          statusColor = AppTheme.primaryEmerald;
        } else if (prayerCount >= 6) {
          statusColor = Colors.orange;
        } else if (prayerCount > 0) {
          statusColor = Colors.red;
        }

        return Card(
          margin: const EdgeInsets.only(bottom: 16),
          elevation: 0,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(24),
            side: BorderSide(color: statusColor.withOpacity(0.2), width: 1.5),
          ),
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      formattedDate,
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: statusColor.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Text(
                        '$prayerCount صلاة',
                        style: TextStyle(
                          color: statusColor,
                          fontWeight: FontWeight.bold,
                          fontSize: 12,
                        ),
                      ),
                    ),
                  ],
                ),
                const Divider(height: 30),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceAround,
                  children: [
                    _buildMiniStat('المهام', '$completedTasks/$totalTasks'),
                    _buildMiniStat('التقييم', '${rating.toInt()}/10'),
                    _buildMiniStat('الأذكار', '${entry.azkar.length}'),
                  ],
                ),
                if (hasDua ||
                    notes.isNotEmpty ||
                    prayerCount > 0 ||
                    totalTasks > 0) ...[
                  const Divider(height: 30),
                  if (prayerCount > 0) ...[
                    const Text(
                      'الصلوات المكتملة:',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                        color: Colors.grey,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Wrap(
                      spacing: 8,
                      runSpacing: 4,
                      children: completedPrayers
                          .map(
                            (p) => Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 8,
                                vertical: 2,
                              ),
                              decoration: BoxDecoration(
                                color: AppTheme.primaryEmerald.withOpacity(0.1),
                                borderRadius: BorderRadius.circular(4),
                              ),
                              child: Text(
                                p.prayerName,
                                style: const TextStyle(
                                  fontSize: 10,
                                  color: AppTheme.primaryEmerald,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                          )
                          .toList(),
                    ),
                    const SizedBox(height: 12),
                  ],
                  if (totalTasks > 0) ...[
                    const Text(
                      'المهام:',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                        color: Colors.grey,
                      ),
                    ),
                    const SizedBox(height: 4),
                    ...tasksList.map(
                      (t) => Padding(
                        padding: const EdgeInsets.only(bottom: 2),
                        child: Row(
                          children: [
                            Icon(
                              t.isCompleted
                                  ? Icons.check_circle_rounded
                                  : Icons.radio_button_unchecked_rounded,
                              size: 14,
                              color: t.isCompleted
                                  ? AppTheme.primaryEmerald
                                  : Colors.grey,
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                t.title,
                                style: TextStyle(
                                  fontSize: 11,
                                  decoration: t.isCompleted
                                      ? TextDecoration.lineThrough
                                      : null,
                                  color: t.isCompleted ? Colors.grey : null,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 12),
                  ],
                  if (hasDua) ...[
                    const Divider(height: 20, indent: 20, endIndent: 20),
                    _buildReflectionBox(
                      Icons.favorite_rounded,
                      'الدعاء:',
                      entry.assessment!.dua,
                      Colors.pinkAccent,
                    ),
                  ],
                  if (notes.isNotEmpty) ...[
                    const SizedBox(height: 12),
                    _buildReflectionBox(
                      Icons.edit_note_rounded,
                      'الخواطر:',
                      notes,
                      Colors.amber,
                    ),
                  ],
                ],
              ],
            ),
          ),
        );
      }).toList(),
    );
  }

  Widget _buildReflectionBox(
    IconData icon,
    String label,
    String text,
    Color color,
  ) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: color.withOpacity(0.05),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withOpacity(0.1)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, size: 16, color: color),
              const SizedBox(width: 8),
              Text(
                label,
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                  color: color,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            text,
            style: TextStyle(
              fontSize: 13,
              fontStyle: FontStyle.italic,
              color: Theme.of(context).colorScheme.onSurface.withOpacity(0.8),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMiniStat(String label, String value) {
    return Column(
      children: [
        Text(
          value,
          style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 18),
        ),
        Text(label, style: const TextStyle(color: Colors.grey, fontSize: 12)),
      ],
    );
  }

  Widget _buildDetailRow(IconData icon, String text) {
    return Padding(
      padding: const EdgeInsets.only(top: 4),
      child: Row(
        children: [
          Icon(icon, size: 14, color: AppTheme.primaryEmerald),
          const SizedBox(width: 6),
          Text(
            text,
            style: TextStyle(
              fontSize: 12,
              color: AppTheme.primaryEmerald.withOpacity(0.8),
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}
