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
  final _notesController = TextEditingController();

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
          _notesController.text = assessmentProv.current!.notes;
        });
      }
    });

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
    final historyProv = context.read<HistoryProvider>();
    await context.read<AssessmentProvider>().saveAssessment(
      rating: historyProv.dailyScore * 10, // Use calculated score
      notes: _notesController.text,
    );
    if (mounted) {
      historyProv.refreshStats();
    }
  }

  @override
  void dispose() {
    _notesController.removeListener(_autoSaveAssessment);
    _todoController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final todoProvider = context.watch<TodoProvider>();
    final historyProvider = context.watch<HistoryProvider>(); // Watch history

    return Scaffold(
      body: NestedScrollView(
        headerSliverBuilder: (context, innerBoxIsScrolled) {
          return [
            SliverAppBar(
              expandedHeight: 200.0,
              floating: false,
              pinned: true,
              stretch: true,
              backgroundColor: AppTheme.primaryEmerald,
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
                    // Gradient Background
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
                    // Content Header
                    SafeArea(
                      child: Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: const [
                            Icon(
                              Icons.edit_calendar_rounded,
                              color: Colors.white,
                              size: 40,
                            ),
                            SizedBox(height: 12),
                            Text(
                              'التخطيط والتقييم',
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
              _buildSectionTitle(
                'قائمة المهام اليومية',
                Icons.task_alt_rounded,
              ),
              const SizedBox(height: 8),
              Container(
                padding: const EdgeInsets.all(12),
                margin: const EdgeInsets.only(bottom: 12),
                decoration: BoxDecoration(
                  color: AppTheme.primaryEmerald.withValues(alpha: 0.08),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: AppTheme.primaryEmerald.withValues(alpha: 0.2),
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

              // Habits to Quit
              _buildSectionTitle(
                'عادات أريد تركها',
                Icons.do_not_disturb_on_total_silence_rounded,
                color: Colors.redAccent,
              ),
              const SizedBox(height: 12),
              _buildHabitInput(
                todoProvider,
                'habit_quit',
                'إضافة عادة سيئة...',
              ),
              const SizedBox(height: 12),
              _buildHabitList(todoProvider, 'habit_quit'),

              const Padding(
                padding: EdgeInsets.symmetric(vertical: 20),
                child: Divider(thickness: 1, color: Colors.black12),
              ),

              // Habits to Acquire
              _buildSectionTitle(
                'عادات أريد اكتسابها',
                Icons.check_circle_outline_rounded,
                color: Colors.green,
              ),
              const SizedBox(height: 12),
              _buildHabitInput(
                todoProvider,
                'habit_acquire',
                'إضافة عادة حسنة...',
              ),
              const SizedBox(height: 12),
              _buildHabitList(todoProvider, 'habit_acquire'),

              const Padding(
                padding: EdgeInsets.symmetric(vertical: 20),
                child: Divider(thickness: 1, color: Colors.black12),
              ),

              _buildSectionTitle('تقييم اليوم (المحاسبة)', Icons.star_rounded),
              const SizedBox(height: 12),
              Card(
                elevation: 0,
                color: AppTheme.primaryEmerald.withValues(alpha: 0.05),
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: _buildAutomatedRating(historyProvider),
                ),
              ),
              const SizedBox(height: 24),
              _buildSectionTitle('خواطر وملاحظات', Icons.edit_note_rounded),
              const SizedBox(height: 8),
              Container(
                padding: const EdgeInsets.all(12),
                margin: const EdgeInsets.only(bottom: 12),
                decoration: BoxDecoration(
                  color: Theme.of(
                    context,
                  ).colorScheme.secondary.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: Theme.of(
                      context,
                    ).colorScheme.secondary.withValues(alpha: 0.4),
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
      ),
    );
  }

  // Helper Methods...
  // (Moving buildAutomatedRating here)

  Widget _buildAutomatedRating(HistoryProvider historyProvider) {
    double automatedScore = historyProvider.dailyScore * 10;

    return Column(
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(
              Icons.auto_awesome,
              color: AppTheme.primaryEmerald,
              size: 28,
            ),
            const SizedBox(width: 8),
            Text(
              '${automatedScore.toStringAsFixed(1)}/10',
              style: const TextStyle(
                fontWeight: FontWeight.w900,
                fontSize: 32,
                color: AppTheme.primaryEmerald,
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        Text(
          'تقييم تلقائي بناءً على إنجازاتك اليوم',
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.bold,
            color: Colors.grey.withOpacity(0.8),
          ),
        ),
        const SizedBox(height: 12),
        LinearProgressIndicator(
          value: historyProvider.dailyScore,
          backgroundColor: AppTheme.primaryEmerald.withValues(alpha: 0.2),
          color: AppTheme.primaryEmerald,
          minHeight: 10,
          borderRadius: BorderRadius.circular(5),
        ),
        const SizedBox(height: 12),
        Text(
          _getRatingLabel(automatedScore.toInt()),
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w600,
            color: AppTheme.primaryEmerald.withValues(alpha: 0.9),
            fontFamily: 'Cairo',
          ),
        ),
      ],
    );
  }

  // ... (Other section builders remain the same) ...

  Widget _buildSectionTitle(String title, IconData icon, {Color? color}) {
    final themeColor = color ?? AppTheme.primaryEmerald;
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: themeColor.withOpacity(0.1),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Icon(icon, color: themeColor, size: 20),
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
        Container(height: 1, width: 50, color: themeColor.withOpacity(0.2)),
      ],
    );
  }

  Widget _buildTodoInput(TodoProvider provider) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Container(
      decoration: BoxDecoration(
        color: isDark
            ? Theme.of(context).cardColor
            : Colors.white.withValues(alpha: 0.95),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: AppTheme.primaryEmerald.withValues(alpha: 0.3),
          width: 1.5,
        ),
        boxShadow: [
          BoxShadow(
            color: AppTheme.primaryEmerald.withValues(
              alpha: isDark ? 0.15 : 0.1,
            ),
            blurRadius: 15,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
      child: Row(
        children: [
          Expanded(
            child: TextField(
              controller: _todoController,
              style: TextStyle(
                fontSize: 16,
                color: Theme.of(context).textTheme.bodyLarge?.color,
              ),
              decoration: InputDecoration(
                hintText: 'إضافة مهمة جديدة...',
                hintStyle: TextStyle(color: Theme.of(context).hintColor),
                border: InputBorder.none,
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 12,
                ),
              ),
            ),
          ),
          Container(
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [AppTheme.primaryEmerald, AppTheme.secondaryTeal],
              ),
              borderRadius: BorderRadius.circular(14),
              boxShadow: [
                BoxShadow(
                  color: AppTheme.primaryEmerald.withValues(alpha: 0.3),
                  blurRadius: 8,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: IconButton(
              onPressed: () async {
                if (_todoController.text.isNotEmpty) {
                  await provider.addTask(_todoController.text, DateTime.now());
                  if (mounted) {
                    context.read<HistoryProvider>().refreshStats();
                  }
                  _todoController.clear();
                }
              },
              icon: const Icon(
                Icons.add_rounded,
                size: 28,
                color: Colors.white,
              ),
            ),
          ),
          const SizedBox(width: 4),
        ],
      ),
    );
  }

  Widget _buildHabitInput(TodoProvider provider, String type, String hint) {
    final controller = TextEditingController();
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.grey.withOpacity(0.2)),
      ),
      child: Row(
        children: [
          Expanded(
            child: TextField(
              controller: controller,
              decoration: InputDecoration(
                hintText: hint,
                border: InputBorder.none,
              ),
              onSubmitted: (val) async {
                if (val.isNotEmpty) {
                  await provider.addTask(val, DateTime.now(), type: type);
                  if (mounted) context.read<HistoryProvider>().refreshStats();
                  controller.clear();
                }
              },
            ),
          ),
          IconButton(
            icon: const Icon(Icons.add_circle_rounded),
            color: type == 'habit_quit' ? Colors.redAccent : Colors.green,
            onPressed: () async {
              if (controller.text.isNotEmpty) {
                await provider.addTask(
                  controller.text,
                  DateTime.now(),
                  type: type,
                );
                if (mounted) context.read<HistoryProvider>().refreshStats();
                controller.clear();
              }
            },
          ),
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
          margin: const EdgeInsets.only(bottom: 10),
          decoration: BoxDecoration(
            gradient: task.isCompleted
                ? LinearGradient(
                    colors: [
                      Colors.grey.withValues(alpha: 0.05),
                      Colors.grey.withValues(alpha: 0.02),
                    ],
                  )
                : LinearGradient(
                    colors: [
                      Colors.white.withValues(alpha: 0.9),
                      AppTheme.primaryEmerald.withValues(alpha: 0.05),
                    ],
                  ),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: task.isCompleted
                  ? Colors.grey.withValues(alpha: 0.2)
                  : AppTheme.primaryEmerald.withValues(alpha: 0.3),
              width: 1.5,
            ),
            boxShadow: [
              BoxShadow(
                color: task.isCompleted
                    ? Colors.black.withValues(alpha: 0.02)
                    : AppTheme.primaryEmerald.withValues(alpha: 0.08),
                blurRadius: 8,
                offset: const Offset(0, 3),
              ),
            ],
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
                borderRadius: BorderRadius.circular(6),
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
                    : FontWeight.w700,
                fontSize: 16,
              ),
            ),
            trailing: IconButton(
              icon: const Icon(
                Icons.delete_outline_rounded,
                color: Colors.redAccent,
                size: 22,
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

  Widget _buildHabitList(TodoProvider provider, String type) {
    final habits = type == 'habit_quit'
        ? provider.habitsToQuit
        : provider.habitsToAcquire;
    final color = type == 'habit_quit' ? Colors.redAccent : Colors.green;

    if (habits.isEmpty) {
      return Padding(
        padding: const EdgeInsets.all(8.0),
        child: Text(
          'لا توجد عادات مسجلة',
          textAlign: TextAlign.center,
          style: TextStyle(color: Colors.grey.withOpacity(0.7)),
        ),
      );
    }

    return ListView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: habits.length,
      itemBuilder: (context, index) {
        final habit = habits[index];
        return Card(
          elevation: 0,
          color: color.withOpacity(0.05),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
            side: BorderSide(color: color.withOpacity(0.2)),
          ),
          margin: const EdgeInsets.only(bottom: 8),
          child: ListTile(
            contentPadding: const EdgeInsets.symmetric(horizontal: 12),
            leading: Checkbox(
              value: habit.isCompleted,
              activeColor: color,
              onChanged: (val) async {
                await provider.toggleTaskById(habit.id!);
                if (mounted) context.read<HistoryProvider>().refreshStats();
              },
            ),
            title: Text(
              habit.title,
              style: TextStyle(
                decoration: habit.isCompleted
                    ? TextDecoration.lineThrough
                    : null,
                color: habit.isCompleted
                    ? Colors.grey
                    : Theme.of(context).textTheme.bodyLarge?.color,
              ),
            ),
            trailing: IconButton(
              icon: const Icon(Icons.delete_outline, size: 20),
              color: Colors.grey,
              onPressed: () async {
                await provider.deleteTask(habit.id!, DateTime.now());
                if (mounted) context.read<HistoryProvider>().refreshStats();
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

  String _getRatingLabel(int rating) {
    if (rating >= 9) return 'يوم مبارك ممتاز! 🌟';
    if (rating >= 7) return 'يوم جيد جداً 👍';
    if (rating >= 5) return 'يوم متوسط';
    if (rating >= 3) return 'يحتاج تحسين';
    return 'شد حيلك يا بطل 💪';
  }
}
