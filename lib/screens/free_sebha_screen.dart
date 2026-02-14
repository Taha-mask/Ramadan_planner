import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../providers/statistics_provider.dart';
import '../theme/app_theme.dart';

class CustomZikr {
  final String text;
  final int count;
  int current;

  CustomZikr({required this.text, required this.count, this.current = 0});

  Map<String, dynamic> toMap() => {'text': text, 'count': count};
  factory CustomZikr.fromMap(Map<String, dynamic> map) =>
      CustomZikr(text: map['text'], count: map['count']);
}

class FreeSebhaScreen extends StatefulWidget {
  const FreeSebhaScreen({super.key});

  @override
  State<FreeSebhaScreen> createState() => _FreeSebhaScreenState();
}

class _FreeSebhaScreenState extends State<FreeSebhaScreen> {
  List<CustomZikr> _customAzkar = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadCustomAzkar();
  }

  Future<void> _loadCustomAzkar() async {
    setState(() => _isLoading = true);
    final prefs = await SharedPreferences.getInstance();
    final String? azkarJson = prefs.getString('custom_azkar_list');

    List<CustomZikr> loaded = [];
    if (azkarJson != null) {
      final List<dynamic> decoded = jsonDecode(azkarJson);
      loaded = decoded.map((item) => CustomZikr.fromMap(item)).toList();
    }

    // Load current counts from provider
    if (!mounted) return;
    final historyProv = context.read<HistoryProvider>();
    for (var zikr in loaded) {
      final stat = historyProv.azkarStats.firstWhere(
        (s) => s['zikrText'] == zikr.text,
        orElse: () => {'count': 0},
      );
      zikr.current = stat['count'];
    }

    setState(() {
      _customAzkar = loaded;
      _isLoading = false;
    });
  }

  Future<void> _saveCustomAzkar() async {
    final prefs = await SharedPreferences.getInstance();
    final String encoded = jsonEncode(
      _customAzkar.map((e) => e.toMap()).toList(),
    );
    await prefs.setString('custom_azkar_list', encoded);
  }

  void _addZikr() {
    final nameController = TextEditingController();
    final countController = TextEditingController(text: '33');

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('إضافة ذكر جديد', textAlign: TextAlign.right),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: nameController,
              textAlign: TextAlign.right,
              decoration: const InputDecoration(
                hintText: 'اسم الذكر (مثلاً: سبحان الله)',
              ),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: countController,
              textAlign: TextAlign.right,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(hintText: 'العدد المستهدف'),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('إلغاء'),
          ),
          ElevatedButton(
            onPressed: () {
              if (nameController.text.isNotEmpty) {
                final text = nameController.text.trim();
                // Check if exists
                if (_customAzkar.any((z) => z.text == text)) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('الذكر موجود بالفعل')),
                  );
                  return;
                }

                setState(() {
                  _customAzkar.add(
                    CustomZikr(
                      text: text,
                      count: int.tryParse(countController.text) ?? 33,
                    ),
                  );
                });
                _saveCustomAzkar();
                Navigator.pop(context);
              }
            },
            child: const Text('إضافة'),
          ),
        ],
      ),
    );
  }

  void _deleteZikr(int index) {
    setState(() {
      _customAzkar.removeAt(index);
    });
    _saveCustomAzkar();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('أذكار مخصصة'), elevation: 0),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _customAzkar.isEmpty
          ? _buildEmptyState()
          : ListView.builder(
              padding: const EdgeInsets.all(20),
              itemCount: _customAzkar.length,
              itemBuilder: (context, index) => _buildZikrCard(index),
            ),
      floatingActionButton: FloatingActionButton(
        onPressed: _addZikr,
        backgroundColor: AppTheme.primaryEmerald,
        child: const Icon(Icons.add_rounded, color: Colors.white),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.auto_awesome_rounded,
            size: 64,
            color: AppTheme.primaryEmerald.withValues(alpha: 0.3),
          ),
          const SizedBox(height: 16),
          const Text(
            'لا توجد أذكار مخصصة بعد',
            style: TextStyle(fontSize: 18, color: Colors.grey),
          ),
          const SizedBox(height: 8),
          const Text('اضغط على الزر لإضافة ذكرك الأول'),
        ],
      ),
    );
  }

  Widget _buildZikrCard(int index) {
    final zikr = _customAzkar[index];
    bool isFinished = zikr.current >= zikr.count;

    return Dismissible(
      key: Key(zikr.text),
      direction: DismissDirection.endToStart,
      background: Container(
        alignment: Alignment.centerLeft,
        padding: const EdgeInsets.only(left: 20),
        decoration: BoxDecoration(
          color: Colors.red.shade400,
          borderRadius: BorderRadius.circular(24),
        ),
        child: const Icon(Icons.delete_outline_rounded, color: Colors.white),
      ),
      onDismissed: (_) => _deleteZikr(index),
      child: Card(
        margin: const EdgeInsets.only(bottom: 16),
        elevation: isFinished ? 0 : 2,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        child: InkWell(
          onTap: () async {
            setState(() {
              zikr.current++;
            });
            HapticFeedback.lightImpact();
            await context.read<HistoryProvider>().logZikr(zikr.text);
            if (zikr.current == zikr.count) {
              HapticFeedback.mediumImpact();
            }
          },
          borderRadius: BorderRadius.circular(24),
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Row(
              children: [
                _buildProgressCircle(zikr),
                const SizedBox(width: 20),
                Expanded(
                  child: Text(
                    zikr.text,
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      decoration: isFinished
                          ? TextDecoration.lineThrough
                          : null,
                      color: isFinished ? Colors.grey : null,
                    ),
                  ),
                ),
                Icon(
                  Icons.add_circle_outline_rounded,
                  color: isFinished ? Colors.grey : AppTheme.primaryEmerald,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildProgressCircle(CustomZikr zikr) {
    bool isFinished = zikr.current >= zikr.count;
    double progress = (zikr.current / zikr.count).clamp(0.0, 1.0);

    return Stack(
      alignment: Alignment.center,
      children: [
        SizedBox(
          width: 50,
          height: 50,
          child: CircularProgressIndicator(
            value: progress,
            strokeWidth: 4,
            backgroundColor: AppTheme.primaryEmerald.withValues(alpha: 0.1),
            valueColor: AlwaysStoppedAnimation<Color>(
              isFinished ? Colors.grey : AppTheme.primaryEmerald,
            ),
          ),
        ),
        Text(
          '${zikr.current}',
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w900,
            color: isFinished ? Colors.grey : AppTheme.primaryEmerald,
          ),
        ),
      ],
    );
  }
}
