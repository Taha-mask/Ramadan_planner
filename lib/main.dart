import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'theme/app_theme.dart';
import 'screens/main_scaffold.dart';

import 'package:intl/intl.dart' hide TextDirection;
import 'package:intl/date_symbol_data_local.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import 'dart:io';

import 'providers/worship_provider.dart';
import 'providers/quran_provider.dart';
import 'providers/todo_provider.dart';
import 'providers/assessment_provider.dart';
import 'providers/statistics_provider.dart';
import 'providers/theme_provider.dart';
import 'providers/notification_provider.dart';
import 'services/widget_service.dart';
import 'services/notification_service.dart';
import 'utils/notification_helper.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await SystemChrome.setPreferredOrientations([
    DeviceOrientation.portraitUp,
    DeviceOrientation.portraitDown,
  ]);

  if (Platform.isWindows || Platform.isLinux) {
    sqfliteFfiInit();
    databaseFactory = databaseFactoryFfi;
  }

  await tryInitializeDateFormatting();
  Intl.defaultLocale = 'ar';

  // Initialize Timezones and Notifications Helper
  await initializeNotificationsAndTimeZone();

  // Initialize Notification Service (Strict Order)
  final notificationService = NotificationService();
  await notificationService.init();
  await notificationService.requestPermissions();

  // Initialize HomeWidget
  await WidgetService.init();

  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => ThemeProvider()),
        ChangeNotifierProvider(create: (_) => NotificationProvider()),
        ChangeNotifierProvider(create: (_) => WorshipProvider()),
        ChangeNotifierProvider(create: (_) => QuranProvider()),
        ChangeNotifierProvider(create: (_) => TodoProvider()),
        ChangeNotifierProvider(create: (_) => AssessmentProvider()),
        ChangeNotifierProvider(create: (_) => HistoryProvider()),
      ],
      child: const RamadanPlanner(),
    ),
  );

  // Initialize Widgets
  WidgetsBinding.instance.addPostFrameCallback((_) async {
    // Initial Zikr
    await WidgetService.updateZikrWidget();
  });
}

Future<void> tryInitializeDateFormatting() async {
  try {
    await initializeDateFormatting('ar', null);
    await initializeDateFormatting('ar_SA', null);
    await initializeDateFormatting('en', null);
  } catch (e) {
    debugPrint('Error initializing date formatting: $e');
  }
}

class RamadanPlanner extends StatelessWidget {
  const RamadanPlanner({super.key});

  @override
  Widget build(BuildContext context) {
    final themeProvider = context.watch<ThemeProvider>();
    return MaterialApp(
      title: 'Ramadan Planner',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.lightTheme,
      darkTheme: AppTheme.darkTheme,
      themeMode: themeProvider.themeMode,
      home: const MainScaffold(),
      builder: (context, child) {
        return Directionality(
          textDirection: TextDirection.rtl, // Set default to Arabic RTL
          child: child!,
        );
      },
    );
  }
}
