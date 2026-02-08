import 'dart:async';
import 'package:flutter/material.dart';

import 'package:provider/provider.dart';
import 'azkar_detail_screen.dart';
import '../providers/quran_provider.dart';
import '../providers/statistics_provider.dart';
import '../providers/theme_provider.dart';
import '../theme/app_theme.dart';
import '../utils/quran_data.dart';

class QuranAzkarScreen extends StatefulWidget {
  const QuranAzkarScreen({super.key});

  @override
  State<QuranAzkarScreen> createState() => _QuranAzkarScreenState();
}

class _QuranAzkarScreenState extends State<QuranAzkarScreen> {
  final _juzController = TextEditingController();
  final _surahController = TextEditingController();

  final _ayahController = TextEditingController();
  List<String> _filteredSurahs = [];

  @override
  void initState() {
    super.initState();
    _initData();
  }

  Future<void> _initData() async {
    final quranProv = context.read<QuranProvider>();
    await quranProv.loadProgress(DateTime.now());

    if (quranProv.current != null) {
      final p = quranProv.current!;
      _juzController.text = p.juz > 0 ? p.juz.toString() : '';
      _surahController.text = p.surah;
      _surahController.text = p.surah;
      _ayahController.text = p.ayah > 0 ? p.ayah.toString() : '';

      if (p.juz > 0) {
        _filteredSurahs = QuranData.juzToSurahs[p.juz] ?? [];
      }
    }

    // Add listeners for auto-save
    for (var controller in [
      _juzController,
      _surahController,
      _ayahController,
    ]) {
      controller.addListener(_autoSaveQuran);
    }
  }

  Timer? _debounce;

  Future<void> _autoSaveQuran() async {
    if (_debounce?.isActive ?? false) _debounce!.cancel();
    _debounce = Timer(const Duration(milliseconds: 500), () async {
      await context.read<QuranProvider>().saveProgress(
        juz: int.tryParse(_juzController.text) ?? 0,
        surah: _surahController.text,
        page: 0,
        ayah: int.tryParse(_ayahController.text) ?? 0,
      );
      if (mounted) {
        context.read<HistoryProvider>().refreshStats();
      }
    });
  }

  @override
  void dispose() {
    for (var controller in [
      _juzController,
      _surahController,
      _ayahController,
    ]) {
      controller.removeListener(_autoSaveQuran);
      controller.dispose();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('الورد اليومي'),
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
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            _buildSectionHeader('الورد القرآني اليـومي'),
            const SizedBox(height: 16),
            _buildWirdInputs(),
            const SizedBox(height: 48),
            _buildSectionHeader('الأذكار اليـومية'),
            const SizedBox(height: 8),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              decoration: BoxDecoration(
                color: AppTheme.secondaryTeal.withOpacity(0.08),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                  color: AppTheme.secondaryTeal.withOpacity(0.2),
                ),
              ),
              child: const Text(
                'أَلَا بِذِكْرِ اللَّهِ تَطْمَئِنُّ الْقُلُوبُ',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w900,
                  color: AppTheme.secondaryTeal,
                  fontFamily: 'Amiri',
                ),
              ),
            ),
            const SizedBox(height: 20),
            Row(
              children: [
                Expanded(
                  child: _buildAzkarButton(
                    'أذكار الصباح',
                    Icons.wb_sunny_rounded,
                    const Color(0xFFFF9800),
                    () => _navigateToAzkar(context, 'Morning'),
                  ),
                ),
                const SizedBox(width: 20),
                Expanded(
                  child: _buildAzkarButton(
                    'أذكار المساء',
                    Icons.nightlight_round_rounded,
                    const Color(0xFF5C6BC0),
                    () => _navigateToAzkar(context, 'Evening'),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 40),
          ],
        ),
      ),
    );
  }

  Widget _buildSectionHeader(String title) {
    return Text(
      title,
      style: TextStyle(
        fontSize: 22,
        fontWeight: FontWeight.w800,
        color: Theme.of(context).colorScheme.onSurface,
      ),
      textAlign: TextAlign.right,
    );
  }

  Widget _buildWirdInputs() {
    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(24),
        side: BorderSide(
          color: Theme.of(context).dividerColor.withOpacity(0.1),
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          children: [
            Container(
              width: double.infinity,
              margin: const EdgeInsets.only(bottom: 24),
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              decoration: BoxDecoration(
                color: AppTheme.primaryEmerald.withOpacity(0.08),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                  color: AppTheme.primaryEmerald.withOpacity(0.2),
                ),
              ),
              child: const Text(
                'إِنَّ هَٰذَا الْقُرْآنَ يَهْدِي لِلَّتِي هِيَ أَقْوَمُ',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w900,
                  color: AppTheme.primaryEmerald,
                  height: 1.6,
                ),
              ),
            ),
            _buildInputTitle('لقد وصلت اليوم إلى:'),
            _buildRowInputs(_juzController, _surahController, _ayahController),
          ],
        ),
      ),
    );
  }

  Widget _buildInputTitle(String title) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        children: [
          Container(
            width: 4,
            height: 20,
            decoration: BoxDecoration(
              color: AppTheme.primaryEmerald,
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          const SizedBox(width: 10),
          Text(
            title,
            style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 16),
          ),
        ],
      ),
    );
  }

  Widget _buildRowInputs(
    TextEditingController juz,
    TextEditingController surah,
    TextEditingController ayah,
  ) {
    return Column(
      children: [
        Row(
          children: [
            Expanded(flex: 1, child: _buildJuzDropdown(juz)),
            const SizedBox(width: 8),
            Expanded(flex: 2, child: _buildSurahDropdown(surah, ayah)),
          ],
        ),

        const SizedBox(height: 12),
        _buildAyahDropdown(ayah, surah),
      ],
    );
  }

  Widget _buildJuzDropdown(TextEditingController controller) {
    return DropdownButtonFormField<String>(
      initialValue: controller.text.isEmpty ? null : controller.text,
      decoration: _buildInputDecoration('جزء'),
      items: List.generate(
        30,
        (i) => (i + 1).toString(),
      ).map((j) => DropdownMenuItem(value: j, child: Text(j))).toList(),
      onChanged: (val) {
        setState(() {
          controller.text = val ?? '';
          if (val != null && val.isNotEmpty) {
            final juzNum = int.tryParse(val);
            if (juzNum != null) {
              _filteredSurahs = QuranData.juzToSurahs[juzNum] ?? [];
              // Reset Surah selection if it's not in the new filtered list
              if (_surahController.text.isNotEmpty &&
                  !_filteredSurahs.contains(_surahController.text)) {
                _surahController.clear();
              }
            } else {
              _filteredSurahs = [];
            }
          } else {
            _filteredSurahs = [];
          }
        });
      },
      alignment: Alignment.center,
    );
  }

  Widget _buildSurahDropdown(
    TextEditingController controller,
    TextEditingController ayahController,
  ) {
    // Determine the list of Surahs to show
    // If a Juz is selected (and has filtered surahs), show them.
    // Otherwise, show ALL Surahs.
    final List<String> itemsToShow = _filteredSurahs.isNotEmpty
        ? _filteredSurahs
        : QuranData.surahs;

    // Check if current text is valid in the list
    String? currentValue =
        controller.text.isNotEmpty && itemsToShow.contains(controller.text)
        ? controller.text
        : null;

    return DropdownButtonFormField<String>(
      initialValue: currentValue,
      decoration: _buildInputDecoration('سورة'),
      isExpanded: true,
      items: itemsToShow.map((s) {
        return DropdownMenuItem(
          value: s,
          child: Text(
            s,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
          ),
        );
      }).toList(),
      onChanged: (val) {
        if (val != null) {
          setState(() {
            controller.text = val;
            // Reset Ayah when Surah changes
            ayahController.clear();
          });
        }
      },
      alignment: Alignment.centerRight,
      menuMaxHeight: 400,
    );
  }

  Widget _buildAyahDropdown(
    TextEditingController ayahController,
    TextEditingController surahController,
  ) {
    int maxAyahs = QuranData.surahAyahCounts[surahController.text] ?? 0;

    // Validate current selection
    String? currentValue = ayahController.text;
    if (currentValue.isNotEmpty) {
      int? val = int.tryParse(currentValue);
      if (val == null || val > maxAyahs || val < 1) {
        currentValue = null;
      }
    } else {
      currentValue = null;
    }

    return DropdownButtonFormField<String>(
      initialValue: currentValue,
      decoration: _buildInputDecoration('الآية'),
      isExpanded: true,
      items: maxAyahs > 0
          ? List.generate(maxAyahs, (index) {
              String numStr = (index + 1).toString();
              return DropdownMenuItem(
                value: numStr,
                child: Text('آية $numStr'),
              );
            })
          : [],
      onChanged: maxAyahs > 0
          ? (val) {
              if (val != null) {
                setState(() {
                  ayahController.text = val;
                });
              }
            }
          : null,
      menuMaxHeight: 300,
    );
  }

  InputDecoration _buildInputDecoration(String label) {
    final theme = Theme.of(context);
    return InputDecoration(
      labelText: label,
      labelStyle: TextStyle(
        color: theme.colorScheme.onSurface.withOpacity(0.6),
        fontSize: 14,
      ),
      floatingLabelBehavior: FloatingLabelBehavior.always,
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide(color: theme.dividerColor.withOpacity(0.1)),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide(color: theme.dividerColor.withOpacity(0.1)),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: AppTheme.primaryEmerald, width: 2),
      ),
      contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
    );
  }

  Widget _buildAzkarButton(
    String title,
    IconData icon,
    Color color,
    VoidCallback onTap,
  ) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(24),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 32),
          decoration: BoxDecoration(
            color: color.withOpacity(0.05),
            borderRadius: BorderRadius.circular(24),
            border: Border.all(color: color.withOpacity(0.2), width: 1),
          ),
          child: Column(
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: color.withOpacity(0.1),
                  shape: BoxShape.circle,
                ),
                child: Icon(icon, size: 36, color: color),
              ),
              const SizedBox(height: 16),
              Text(
                title,
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w800,
                  color: color,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _navigateToAzkar(BuildContext context, String type) {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => AzkarDetailScreen(type: type)),
    );
  }
}
