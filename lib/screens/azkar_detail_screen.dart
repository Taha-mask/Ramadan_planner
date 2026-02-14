import 'package:flutter/material.dart';
import '../theme/app_theme.dart';
import '../utils/azkar_data.dart';
import '../providers/statistics_provider.dart';
import 'package:provider/provider.dart';

class AzkarDetailScreen extends StatefulWidget {
  final String type; // 'Morning' or 'Evening'

  const AzkarDetailScreen({super.key, required this.type});

  @override
  State<AzkarDetailScreen> createState() => _AzkarDetailScreenState();
}

class _AzkarDetailScreenState extends State<AzkarDetailScreen> {
  late List<Map<String, dynamic>> _azkar;

  @override
  void initState() {
    super.initState();
    // Load data from AzkarData and initialize 'current' progress
    final source = widget.type == 'Morning'
        ? AzkarData.morningAzkar
        : widget.type == 'Evening'
        ? AzkarData.eveningAzkar
        : AzkarData.postPrayerAzkar;

    _azkar = source.map((item) => {...item, 'current': 0}).toList();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(_getTitle()), elevation: 0),
      body: ListView.builder(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
        itemCount: _azkar.length,
        itemBuilder: (context, index) {
          final zikr = _azkar[index];
          bool isFinished = zikr['current'] >= zikr['count'];

          return AnimatedOpacity(
            duration: const Duration(milliseconds: 300),
            opacity: isFinished ? 0.6 : 1.0,
            child: Card(
              margin: const EdgeInsets.only(bottom: 20),
              elevation: isFinished ? 0 : 6,
              shadowColor: Theme.of(
                context,
              ).shadowColor.withValues(alpha: 0.05),
              color: isFinished
                  ? Theme.of(context).cardColor.withValues(alpha: 0.5)
                  : Theme.of(context).cardColor,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(24),
                side: BorderSide(
                  color: isFinished
                      ? Colors.transparent
                      : Theme.of(context).dividerColor.withValues(alpha: 0.1),
                ),
              ),
              child: InkWell(
                onTap: isFinished
                    ? null
                    : () {
                        setState(() {
                          _azkar[index]['current']++;
                        });
                        // Log to statistics
                        context.read<HistoryProvider>().logZikr(
                          _azkar[index]['text'],
                        );

                        if (_azkar[index]['current'] ==
                            _azkar[index]['count']) {
                          Feedback.forTap(context);
                        }
                      },
                borderRadius: BorderRadius.circular(24),
                child: Padding(
                  padding: const EdgeInsets.all(24),
                  child: Column(
                    children: [
                      Text(
                        zikr['text'],
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontSize: 20,
                          height: 1.6,
                          fontWeight: FontWeight.w600,
                          color: isFinished
                              ? Theme.of(
                                  context,
                                ).colorScheme.onSurface.withValues(alpha: 0.4)
                              : Theme.of(context).colorScheme.onSurface,
                        ),
                      ),
                      const SizedBox(height: 24),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 16,
                              vertical: 8,
                            ),
                            decoration: BoxDecoration(
                              color: Theme.of(
                                context,
                              ).dividerColor.withValues(alpha: 0.05),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Text(
                              'التكرار: ${zikr['count']}',
                              style: TextStyle(
                                fontWeight: FontWeight.w800,
                                color: Theme.of(
                                  context,
                                ).colorScheme.onSurface.withValues(alpha: 0.6),
                              ),
                            ),
                          ),
                          Container(
                            width: 50,
                            height: 50,
                            decoration: BoxDecoration(
                              color: isFinished
                                  ? AppTheme.primaryEmerald
                                  : const Color(0xFFFFD700),
                              shape: BoxShape.circle,
                              boxShadow: isFinished
                                  ? []
                                  : [
                                      BoxShadow(
                                        color: const Color(
                                          0xFFFFD700,
                                        ).withValues(alpha: 0.3),
                                        blurRadius: 10,
                                        offset: const Offset(0, 4),
                                      ),
                                    ],
                            ),
                            child: Center(
                              child: Text(
                                '${zikr['current']}',
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontWeight: FontWeight.w900,
                                  fontSize: 20,
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  String _getTitle() {
    switch (widget.type) {
      case 'Morning':
        return 'أذكار الصباح';
      case 'Evening':
        return 'أذكار المساء';
      case 'PostPrayer':
        return 'أذكار ما بعد الصلاة';
      default:
        return 'الأذكار';
    }
  }
}
