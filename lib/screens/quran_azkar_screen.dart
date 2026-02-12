import 'dart:async';
import 'package:flutter/material.dart';

import 'package:provider/provider.dart';
import 'azkar_detail_screen.dart';
import 'free_sebha_screen.dart';
import '../providers/quran_provider.dart';
import '../providers/statistics_provider.dart';
import '../providers/theme_provider.dart';
import '../theme/app_theme.dart';
import '../utils/quran_data.dart';
import '../providers/assessment_provider.dart';

class QuranAzkarScreen extends StatefulWidget {
  const QuranAzkarScreen({super.key});

  @override
  State<QuranAzkarScreen> createState() => _QuranAzkarScreenState();
}

class _QuranAzkarScreenState extends State<QuranAzkarScreen> {
  final _juzController = TextEditingController();
  final _surahController = TextEditingController();

  final _ayahController = TextEditingController();
  final _duaController = TextEditingController();
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
      _ayahController.text = p.ayah > 0 ? p.ayah.toString() : '';

      if (p.juz > 0) {
        _filteredSurahs = QuranData.juzToSurahs[p.juz] ?? [];
      }
    }

    // Load Dua
    final assessProv = context.read<AssessmentProvider>();
    await assessProv.loadAssessment(DateTime.now());
    if (assessProv.current != null) {
      _duaController.text = assessProv.current!.dua;
    }

    // Add listeners for auto-save
    for (var controller in [
      _juzController,
      _surahController,
      _ayahController,
    ]) {
      controller.addListener(_autoSaveQuran);
    }
    _duaController.addListener(_autoSaveDua);
  }

  Timer? _debounce;
  Timer? _duaDebounce;

  Future<void> _autoSaveDua() async {
    if (_duaDebounce?.isActive ?? false) _duaDebounce!.cancel();
    _duaDebounce = Timer(const Duration(milliseconds: 1000), () async {
      await context.read<AssessmentProvider>().saveAssessment(
        dua: _duaController.text,
      );
      if (mounted) {
        context.read<HistoryProvider>().refreshStats();
      }
    });
  }

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
    _duaController.removeListener(_autoSaveDua);
    for (var controller in [
      _juzController,
      _surahController,
      _ayahController,
    ]) {
      controller.removeListener(_autoSaveQuran);
      controller.dispose();
    }
    _duaController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: NestedScrollView(
        headerSliverBuilder: (context, innerBoxIsScrolled) {
          return [
            SliverAppBar(
              expandedHeight: 180.0,
              floating: false,
              pinned: true,
              stretch: true,
              backgroundColor: AppTheme.secondaryTeal,
              elevation: 0,
              actions: [
                IconButton(
                  icon: Icon(
                    context.watch<ThemeProvider>().isDarkMode
                        ? Icons.light_mode_rounded
                        : Icons.dark_mode_rounded,
                    color: Colors.white,
                  ),
                  onPressed: () => context.read<ThemeProvider>().toggleTheme(),
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
                    // Gradient Background (Cyan/Teal/Indigo)
                    Container(
                      decoration: const BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment.topRight,
                          end: Alignment.bottomLeft,
                          colors: [
                            AppTheme.secondaryTeal,
                            AppTheme.primaryEmerald,
                            AppTheme.deepIndigo,
                          ],
                        ),
                      ),
                    ),
                    // Content Header
                    SafeArea(
                      child: Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: const [
                            Icon(
                              Icons.auto_awesome_rounded,
                              color: Colors.white,
                              size: 40,
                            ),
                            SizedBox(height: 12),
                            Text(
                              'الورد اليومي',
                              style: TextStyle(
                                fontSize: 28,
                                color: Colors.white,
                                fontWeight: FontWeight.w900,
                                fontFamily: 'Cairo',
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              bottom: PreferredSize(
                preferredSize: const Size.fromHeight(30),
                child: Container(
                  height: 30,
                  decoration: BoxDecoration(
                    color: Theme.of(context).scaffoldBackgroundColor,
                    borderRadius: const BorderRadius.vertical(
                      top: Radius.circular(30),
                    ),
                  ),
                ),
              ),
            ),
          ];
        },
        body: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(20, 0, 20, 100),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              _buildModernSectionHeader(
                'الورد القرآني',
                Icons.menu_book_rounded,
              ),
              const SizedBox(height: 16),
              _buildModernWirdInputs(),
              const SizedBox(height: 32),
              _buildModernSectionHeader(
                'أذكار المسلم',
                Icons.auto_awesome_rounded,
              ),
              const SizedBox(height: 16),
              _buildModernToolkitGrid(),
              const SizedBox(height: 32),
              _buildModernSectionHeader(
                'دعاء اليوم',
                Icons.volunteer_activism_rounded,
              ),
              const SizedBox(height: 16),
              _buildModernDuaInput(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildModernDuaInput() {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(30),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.03),
            blurRadius: 15,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          TextField(
            controller: _duaController,
            maxLines: 4,
            decoration: InputDecoration(
              hintText: 'اكتب دعاءك اليومي هنا...',
              hintStyle: TextStyle(
                color: Theme.of(context).colorScheme.onSurface.withOpacity(0.5),
                fontSize: 14,
              ),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(15),
                borderSide: BorderSide(color: Colors.grey.withOpacity(0.1)),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(15),
                borderSide: BorderSide(color: Colors.grey.withOpacity(0.1)),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(15),
                borderSide: const BorderSide(
                  color: AppTheme.primaryEmerald,
                  width: 2,
                ),
              ),
              filled: true,
              fillColor: AppTheme.primaryEmerald.withOpacity(0.05),
              contentPadding: const EdgeInsets.all(16),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildModernSectionHeader(String title, IconData icon) {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: AppTheme.primaryEmerald.withOpacity(0.1),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Icon(icon, color: AppTheme.primaryEmerald, size: 20),
        ),
        const SizedBox(width: 12),
        Text(
          title,
          style: const TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.w900,
            fontFamily: 'Cairo',
          ),
        ),
        const Spacer(),
        Container(
          height: 1,
          width: 50,
          color: AppTheme.primaryEmerald.withOpacity(0.2),
        ),
      ],
    );
  }

  Widget _buildModernWirdInputs() {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(30),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.03),
            blurRadius: 15,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: AppTheme.primaryEmerald.withOpacity(0.05),
              borderRadius: BorderRadius.circular(15),
            ),
            child: const Text(
              'إِنَّ هَٰذَا الْقُرْآنَ يَهْدِي لِلَّتِي هِيَ أَقْوَمُ',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.bold,
                color: AppTheme.primaryEmerald,
                fontFamily: 'Amiri',
              ),
            ),
          ),
          const SizedBox(height: 24),
          _buildRowInputs(_juzController, _surahController, _ayahController),
        ],
      ),
    );
  }

  Widget _buildModernToolkitGrid() {
    return GridView.count(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      crossAxisCount: 2,
      mainAxisSpacing: 16,
      crossAxisSpacing: 16,
      childAspectRatio: 1.2,
      children: [
        _buildModernToolkitCard(
          'أذكار الصباح',
          Icons.wb_sunny_rounded,
          const Color(0xFFFF9800),
          () => _navigateToAzkar(context, 'Morning'),
        ),
        _buildModernToolkitCard(
          'أذكار المساء',
          Icons.nightlight_round_rounded,
          const Color(0xFF5C6BC0),
          () => _navigateToAzkar(context, 'Evening'),
        ),
        _buildModernToolkitCard(
          'أذكاري',
          Icons.fingerprint_rounded,
          AppTheme.primaryEmerald,
          () => Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => const FreeSebhaScreen()),
          ),
        ),
        _buildModernToolkitCard(
          'أذكار ما بعد الصلاة',
          Icons.shield_rounded,
          AppTheme.secondaryTeal,
          () => _navigateToAzkar(context, 'PostPrayer'),
        ),
      ],
    );
  }

  Widget _buildModernToolkitCard(
    String title,
    IconData icon,
    Color color,
    VoidCallback onTap,
  ) {
    return Container(
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: color.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(24),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: color.withOpacity(0.1),
                  shape: BoxShape.circle,
                ),
                child: Icon(icon, size: 28, color: color),
              ),
              const SizedBox(height: 12),
              Text(
                title,
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w800,
                  fontFamily: 'Cairo',
                ),
              ),
            ],
          ),
        ),
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
      decoration: _buildModernInputDecoration('جزء'),
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
              if (_surahController.text.isNotEmpty &&
                  !_filteredSurahs.contains(_surahController.text)) {
                _surahController.clear();
              }
            }
          }
        });
      },
    );
  }

  Widget _buildSurahDropdown(
    TextEditingController controller,
    TextEditingController ayahController,
  ) {
    final List<String> itemsToShow = _filteredSurahs.isNotEmpty
        ? _filteredSurahs
        : QuranData.surahs;
    String? currentValue =
        controller.text.isNotEmpty && itemsToShow.contains(controller.text)
        ? controller.text
        : null;

    return DropdownButtonFormField<String>(
      initialValue: currentValue,
      decoration: _buildModernInputDecoration('سورة'),
      isExpanded: true,
      items: itemsToShow
          .map(
            (s) => DropdownMenuItem(
              value: s,
              child: Text(s, style: const TextStyle(fontSize: 14)),
            ),
          )
          .toList(),
      onChanged: (val) {
        if (val != null) {
          setState(() {
            controller.text = val;
            ayahController.clear();
          });
        }
      },
      menuMaxHeight: 400,
    );
  }

  Widget _buildAyahDropdown(
    TextEditingController ayahController,
    TextEditingController surahController,
  ) {
    int maxAyahs = QuranData.surahAyahCounts[surahController.text] ?? 0;
    String? currentValue = ayahController.text;
    if (currentValue.isNotEmpty) {
      int? val = int.tryParse(currentValue);
      if (val == null || val > maxAyahs || val < 1) currentValue = null;
    } else {
      currentValue = null;
    }

    return DropdownButtonFormField<String>(
      initialValue: currentValue,
      decoration: _buildModernInputDecoration('الآية'),
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
              if (val != null)
                setState(() {
                  ayahController.text = val;
                });
            }
          : null,
      menuMaxHeight: 300,
    );
  }

  InputDecoration _buildModernInputDecoration(String label) {
    return InputDecoration(
      labelText: label,
      labelStyle: TextStyle(
        color: Theme.of(context).colorScheme.onSurface.withOpacity(0.5),
        fontSize: 13,
      ),
      floatingLabelBehavior: FloatingLabelBehavior.always,
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(15),
        borderSide: BorderSide(color: Colors.grey.withOpacity(0.1)),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(15),
        borderSide: BorderSide(color: Colors.grey.withOpacity(0.1)),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(15),
        borderSide: const BorderSide(color: AppTheme.primaryEmerald, width: 2),
      ),
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
    );
  }

  void _navigateToAzkar(BuildContext context, String type) {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => AzkarDetailScreen(type: type)),
    );
  }
}
