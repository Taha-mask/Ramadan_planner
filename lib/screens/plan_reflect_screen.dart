import 'dart:async';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/todo_provider.dart';
import '../providers/assessment_provider.dart';
import '../providers/statistics_provider.dart';
import '../providers/theme_provider.dart';
import '../theme/app_theme.dart';

class PlanReflectScreen extends StatefulWidget {
  const PlanReflectScreen({super.key});

  @override
  State<PlanReflectScreen> createState() => _PlanReflectScreenState();
}

class _PlanReflectScreenState extends State<PlanReflectScreen> {
  final _todoController = TextEditingController();
  final _duaController = TextEditingController();
  final _notesController = TextEditingController();
  double _rating = 5.0;

  @override
  void initState() {
    super.initState();
    Future.microtask(() async {
      if (!mounted) return;
      final date = DateTime.now();
      await context.read<TodoProvider>().loadTasks(date);
      if (!mounted) return;
      final assessmentProv = context.read<AssessmentProvider>();
      await assessmentProv.loadAssessment(date);

      if (mounted && assessmentProv.current != null) {
        setState(() {
          _rating = assessmentProv.current!.rating;
          _duaController.text = assessmentProv.current!.dua;
          _notesController.text = assessmentProv.current!.notes;
        });
      }
    });

    _duaController.addListener(_autoSaveAssessment);
    _notesController.addListener(_autoSaveAssessment);
  }

  Timer? _debounce;

  Future<void> _autoSaveAssessment({bool debounce = true}) async {
    if (_debounce?.isActive ?? false) _debounce!.cancel();

    if (debounce) {
      _debounce = Timer(const Duration(milliseconds: 500), () async {
        await _performSave();
      });
    } else {
      await _performSave();
    }
  }

  Future<void> _performSave() async {
    if (!mounted) return;
    await context.read<AssessmentProvider>().saveAssessment(
      rating: _rating,
      dua: _duaController.text,
      notes: _notesController.text,
    );
    if (mounted) {
      context.read<HistoryProvider>().refreshStats();
    }
  }

  @override
  void dispose() {
    _duaController.removeListener(_autoSaveAssessment);
    _notesController.removeListener(_autoSaveAssessment);
    _todoController.dispose();
    _duaController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final todoProvider = context.watch<TodoProvider>();

    return Scaffold(
      appBar: AppBar(
        title: const Text('التخطيط والتقييم'),
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
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            _buildSectionTitle('قائمة المهام اليومية'),
            const SizedBox(height: 8),
            Container(
              padding: const EdgeInsets.all(12),
              margin: const EdgeInsets.only(bottom: 12),
              decoration: BoxDecoration(
                color: AppTheme.primaryEmerald.withOpacity(0.08),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: AppTheme.primaryEmerald.withOpacity(0.2),
                ),
              ),
              child: const Text(
                'وَلَا تَقُولَنَّ لِشَيْءٍ إِنِّي فَاعِلٌ ذَٰلِكَ غَدًا إِلَّا أَن يَشَاءَ اللَّهُ',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: AppTheme.primaryEmerald,
                  fontFamily: 'Amiri',
                ),
              ),
            ),
            const SizedBox(height: 12),
            _buildTodoInput(todoProvider),
            const SizedBox(height: 12),
            _buildTodoList(todoProvider),
            const Padding(
              padding: EdgeInsets.symmetric(vertical: 20),
              child: Divider(thickness: 1, color: Colors.black12),
            ),
            _buildSectionTitle('دعاء اليـوم'),
            const SizedBox(height: 8),
            Container(
              padding: const EdgeInsets.all(12),
              margin: const EdgeInsets.only(bottom: 12),
              decoration: BoxDecoration(
                color: AppTheme.primaryEmerald.withOpacity(0.08),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: AppTheme.primaryEmerald.withOpacity(0.2),
                ),
              ),
              child: const Text(
                'وَإِذَا سَأَلَكَ عِبَادِي عَنِّي فَإِنِّي قَرِيبٌ ۖ أُجِيبُ دَعْوَةَ الدَّاعِ إِذَا دَعَانِ',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: AppTheme.primaryEmerald,
                  fontFamily: 'Amiri',
                ),
              ),
            ),
            _buildTextArea(_duaController, 'اكتب دعاءك هنا...'),
            const SizedBox(height: 24),
            _buildSectionTitle('تقييم اليوم (المحاسبة)'),
            const SizedBox(height: 12),
            Card(
              elevation: 0,
              color: AppTheme.primaryEmerald.withOpacity(0.05),
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: _buildRatingSlider(),
              ),
            ),
            const SizedBox(height: 24),
            _buildSectionTitle('خواطر وملاحظات'),
            const SizedBox(height: 8),
            Container(
              padding: const EdgeInsets.all(12),
              margin: const EdgeInsets.only(bottom: 12),
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.secondary.withOpacity(0.1),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: Theme.of(
                    context,
                  ).colorScheme.secondary.withOpacity(0.4),
                ),
              ),
              child: Text(
                'لحظات التفكر هي حياة للقلب',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: Theme.of(context).colorScheme.secondary,
                  fontFamily: 'Amiri',
                ),
              ),
            ),
            _buildTextArea(_notesController, 'كيف كان يومك في طاعة الله؟'),
            const SizedBox(height: 32),
            SizedBox(
              width: double.infinity,
              height: 55,
              child: ElevatedButton.icon(
                onPressed: () async {
                  await _autoSaveAssessment(debounce: false);
                  if (mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: const Text(
                          'تم الحفظ وإرسال البيانات للسجل بنجاح',
                          textAlign: TextAlign.center,
                          style: TextStyle(fontFamily: 'Cairo'),
                        ),
                        backgroundColor: AppTheme.primaryEmerald,
                        behavior: SnackBarBehavior.floating,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                      ),
                    );
                  }
                },
                icon: const Icon(Icons.cloud_upload_outlined),
                label: const Text(
                  'حفظ وإرسال للتاريخ',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppTheme.primaryEmerald,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                  elevation: 4,
                ),
              ),
            ),
            const SizedBox(height: 40),
          ],
        ),
      ),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Text(
      title,
      style: TextStyle(
        fontSize: 20,
        fontWeight: FontWeight.w800,
        color: Theme.of(context).colorScheme.onSurface,
      ),
    );
  }

  Widget _buildTodoInput(TodoProvider provider) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 4),
      child: Row(
        children: [
          Expanded(
            child: TextField(
              controller: _todoController,
              decoration: const InputDecoration(
                hintText: 'إضافة مهمة جديدة...',
                border: InputBorder.none,
                contentPadding: EdgeInsets.symmetric(horizontal: 16),
              ),
            ),
          ),
          IconButton(
            onPressed: () async {
              if (_todoController.text.isNotEmpty) {
                await provider.addTask(_todoController.text, DateTime.now());
                if (mounted) {
                  context.read<HistoryProvider>().refreshStats();
                }
                _todoController.clear();
              }
            },
            icon: const Icon(Icons.add_rounded, size: 28),
            style: IconButton.styleFrom(
              backgroundColor: AppTheme.primaryEmerald,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
          ),
          const SizedBox(width: 4),
        ],
      ),
    );
  }

  Widget _buildTodoList(TodoProvider provider) {
    return ListView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: provider.tasks.length,
      itemBuilder: (context, index) {
        final task = provider.tasks[index];
        return Container(
          margin: const EdgeInsets.only(bottom: 8),
          decoration: BoxDecoration(
            color: task.isCompleted
                ? Colors.black.withOpacity(0.02)
                : Colors.white,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: Colors.black.withOpacity(0.05)),
          ),
          child: ListTile(
            leading: Checkbox(
              value: task.isCompleted,
              onChanged: (val) async {
                await provider.toggleTask(index);
                if (mounted) {
                  context.read<HistoryProvider>().refreshStats();
                }
              },
              activeColor: AppTheme.primaryEmerald,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(4),
              ),
            ),
            title: Text(
              task.title,
              style: TextStyle(
                decoration: task.isCompleted
                    ? TextDecoration.lineThrough
                    : null,
                color: task.isCompleted ? Colors.grey : AppTheme.deepIndigo,
                fontWeight: task.isCompleted
                    ? FontWeight.normal
                    : FontWeight.w600,
              ),
            ),
            trailing: IconButton(
              icon: const Icon(
                Icons.delete_outline_rounded,
                color: Colors.redAccent,
                size: 20,
              ),
              onPressed: () async {
                await provider.deleteTask(task.id!, DateTime.now());
                if (mounted) {
                  context.read<HistoryProvider>().refreshStats();
                }
              },
            ),
          ),
        );
      },
    );
  }

  Widget _buildTextArea(TextEditingController controller, String hint) {
    return TextField(
      controller: controller,
      maxLines: 3,
      decoration: InputDecoration(
        hintText: hint,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: const BorderSide(color: Colors.black12),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: const BorderSide(color: Colors.black12),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: const BorderSide(
            color: AppTheme.primaryEmerald,
            width: 2,
          ),
        ),
        filled: true,
      ),
    );
  }

  Widget _buildRatingSlider() {
    return Column(
      children: [
        Slider(
          value: _rating,
          min: 1,
          max: 10,
          divisions: 9,
          label: _rating.round().toString(),
          onChanged: (val) {
            setState(() => _rating = val);
            _autoSaveAssessment(debounce: false);
          },
          activeColor: AppTheme.primaryEmerald,
          inactiveColor: AppTheme.primaryEmerald.withOpacity(0.2),
        ),
        Text(
          'التقييم: ${_rating.toInt()}/10',
          style: const TextStyle(
            fontWeight: FontWeight.w800,
            fontSize: 18,
            color: AppTheme.primaryEmerald,
          ),
        ),
      ],
    );
  }
}
